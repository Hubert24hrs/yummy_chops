"""FastAPI application factory."""

from __future__ import annotations

import asyncio
import contextlib
import logging
import time
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from . import lan
from .api.v1 import (
    admin,
    channels,
    customer,
    discover,
    growth,
    partner,
    places,
    public,
    rider,
    system,
    wallet,
    waybills,
)
from .config import Settings, get_settings
from .container import Container, build_container
from .errors import DomainError
from .logging_setup import configure_logging, log_event, request_id_var

logger = logging.getLogger("gudmeal_api")


async def _demo_rider_heartbeat(c: Container) -> None:
    from .seed.lagos import refresh_demo_riders

    while True:
        await asyncio.sleep(60)
        with contextlib.suppress(Exception):
            await refresh_demo_riders(c.repos)


async def _demo_shop_autopilot(c: Container) -> None:
    """Local testing: demo shops accept and pack orders nobody at the dashboard has answered."""
    from .seed.autopilot import run_demo_shops

    while True:
        await asyncio.sleep(4)
        with contextlib.suppress(Exception):
            await run_demo_shops(c)


def _too_large(content_length: str | None, limit: int) -> bool:
    if content_length is None:
        return False
    try:
        return int(content_length) > limit
    except ValueError:
        return True  # not a number: refuse rather than guess


def create_app(settings: Settings | None = None, *, container: Container | None = None) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        configure_logging(settings.log_level)
        owned = container is None
        c = container or await build_container(settings)
        app.state.container = c
        heartbeat: asyncio.Task[None] | None = None
        autopilot: asyncio.Task[None] | None = None
        if owned and settings.data_backend == "memory" and settings.seed_demo_data:
            from .seed import seed

            counts = await seed(c.repos)
            log_event(logger, "seeded demo data", **counts)
            if settings.environment == "local":
                from .seed.lagos import park_extra_demo_riders

                await park_extra_demo_riders(c.repos)
                if settings.demo_shops_always_open:
                    from .seed.lagos import open_demo_shops_all_day

                    opened = await open_demo_shops_all_day(c.repos)
                    log_event(logger, "demo shops open around the clock (local testing)", shops=opened)
                heartbeat = asyncio.create_task(_demo_rider_heartbeat(c))
                if settings.demo_shop_autopilot:
                    autopilot = asyncio.create_task(_demo_shop_autopilot(c))
                    log_event(logger, "demo shop autopilot on (local testing)")
        log_event(
            logger,
            "api started",
            environment=settings.environment,
            data_backend=settings.data_backend,
            payment_providers=sorted(c.providers),
        )
        try:
            yield
        finally:
            for background in (heartbeat, autopilot):
                if background:
                    background.cancel()
            if owned:
                await c.close()

    app = FastAPI(
        title="Yummy Chops API",
        version="0.1.0",
        description="Core API for the Yummy Chops food delivery platform (catalog, pricing, orders, payments, "
        "ledger, dispatch). All money values are integer kobo.",
        lifespan=lifespan,
        docs_url=None if settings.environment == "production" else "/docs",
        openapi_url=None if settings.environment == "production" else "/openapi.json",
        redoc_url=None,
    )
    if container is not None:
        app.state.container = container  # tests (ASGI transport does not run lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "X-Firebase-AppCheck"],
        max_age=600,
    )

    @app.middleware("http")
    async def request_context(request: Request, call_next):  # type: ignore[no-untyped-def]
        rid = (
            request.headers.get("x-request-id")
            or request.headers.get("x-cloud-trace-context", "").split("/")[0]
        )
        rid = rid or uuid.uuid4().hex
        if _too_large(request.headers.get("content-length"), settings.max_request_bytes):
            # Refused before the body is read: a flood of huge bodies cannot fill the server's memory.
            return JSONResponse(
                {"error": {"code": "too_large", "message": "That is too large to send.", "request_id": rid}},
                status_code=413,
            )
        token = request_id_var.set(rid)
        # Phone tests: remember the address the client reached this API at, so the payment sandbox page opens
        # at an address that phone can reach (lan.reachable_base_url).
        lan_token = (
            lan.remember_request(str(request.base_url)) if settings.sandbox_follows_lan_address else None
        )
        start = time.perf_counter()
        try:
            response = await call_next(request)
        finally:
            request_id_var.reset(token)
            if lan_token is not None:
                lan.forget_request(lan_token)
        elapsed = round((time.perf_counter() - start) * 1000, 1)
        response.headers["X-Request-ID"] = rid
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = response.headers.get("Cache-Control", "no-store")
        if settings.environment in ("staging", "production"):
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        if request.url.path not in ("/v1/health",):
            log_event(
                logger,
                "request",
                method=request.method,
                path=request.url.path,
                status=response.status_code,
                ms=elapsed,
                request_id=rid,
            )
        return response

    @app.exception_handler(DomainError)
    async def domain_error(request: Request, exc: DomainError) -> JSONResponse:
        body = {"error": {**exc.to_dict(), "request_id": request_id_var.get()}}
        return JSONResponse(body, status_code=exc.status_code)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError) -> JSONResponse:
        errors = [
            {"loc": list(e.get("loc", [])), "msg": e.get("msg"), "type": e.get("type")} for e in exc.errors()
        ]
        return JSONResponse(
            {
                "error": {
                    "code": "validation_failed",
                    "message": "Request validation failed",
                    "details": {"errors": errors},
                }
            },
            status_code=422,
        )

    @app.exception_handler(Exception)
    async def unhandled(request: Request, exc: Exception) -> JSONResponse:
        logger.exception("unhandled error", extra={"extra_fields": {"path": request.url.path}})
        return JSONResponse(
            {
                "error": {
                    "code": "internal_error",
                    "message": "Something went wrong. Please try again.",
                    "request_id": request_id_var.get(),
                }
            },
            status_code=500,
        )

    for router in (
        public.router,
        places.router,
        discover.router,
        customer.router,
        wallet.router,
        waybills.public,
        waybills.router,
        waybills.admin,
        growth.router,
        growth.admin,
        channels.router,
        partner.router,
        rider.router,
        admin.router,
        system.webhooks,
        system.internal,
    ):
        app.include_router(router)
    if settings.environment in ("local", "test"):
        app.include_router(system.dev)
    return app


def app_factory() -> FastAPI:
    """Entry point for `uvicorn --factory gudmeal_api.main:app_factory`."""
    return create_app()
