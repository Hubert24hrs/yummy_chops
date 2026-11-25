"""HTTP API for the agents service."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import AsyncExitStack, asynccontextmanager
from typing import Annotated, Any, Literal

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .config import Settings, get_settings
from .graph import build_graph
from .identity import (
    CHANNEL_PREFIX,
    AppCheckVerifier,
    AuthError,
    Caller,
    ChannelTokenVerifier,
    FirebaseAppCheckVerifier,
    FirebaseVerifier,
    Verifier,
)
from .llm import BudgetedModels, GeminiFactory, ModelFactory
from .offline import OfflineModels
from .service import AgentService, NoPendingApprovalError, RateLimitedError
from .store import AgentStore, ThreadAccessError
from .tools import customer, operations, services
from .tools.registry import ToolRegistry

logger = logging.getLogger("gudmeal_agents")


def build_registry() -> ToolRegistry:
    registry = ToolRegistry()
    customer.register(registry)
    operations.register(registry)
    services.register(registry)
    return registry


async def make_checkpointer(settings: Settings, stack: AsyncExitStack) -> Any:
    if settings.checkpointer == "postgres":
        from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
        from psycopg.rows import dict_row
        from psycopg_pool import AsyncConnectionPool

        if settings.checkpoint_postgres_url is None:
            raise RuntimeError("CHECKPOINT_POSTGRES_URL is required for CHECKPOINTER=postgres")
        # A pool, not one connection: a connection the database dropped is checked and replaced, where a single
        # connection would fail every chat until the instance restarts. The connection settings are the ones
        # LangGraph documents for its Postgres saver.
        pool = AsyncConnectionPool(
            settings.checkpoint_postgres_url.get_secret_value(),
            min_size=1,
            max_size=settings.checkpoint_pool_max_size,
            kwargs={"autocommit": True, "prepare_threshold": 0, "row_factory": dict_row},
            check=AsyncConnectionPool.check_connection,
            open=False,
        )
        await stack.enter_async_context(pool)  # opened here, closed on shutdown
        saver = AsyncPostgresSaver(pool)
        await saver.setup()
        return saver
    if settings.checkpointer == "sqlite":
        from langgraph.checkpoint.sqlite.aio import AsyncSqliteSaver

        return await stack.enter_async_context(
            AsyncSqliteSaver.from_conn_string(settings.checkpoint_sqlite_path)
        )
    from langgraph.checkpoint.memory import InMemorySaver

    return InMemorySaver()


class ChatLocation(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


class ChatAddress(BaseModel):
    """Same shape and limits as gudmeal-api's DeliveryAddress (it is kept with the conversation)."""

    label: str | None = Field(default=None, max_length=40)
    line1: str = Field(min_length=3, max_length=200)
    area: str | None = Field(default=None, max_length=80)
    city: str = Field(default="Lagos", max_length=60)
    state: str = Field(default="Lagos", max_length=60)
    location: ChatLocation
    instructions: str | None = Field(default=None, max_length=300)
    contact_phone: str | None = Field(default=None, max_length=20)


class ChatInput(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    thread_id: str | None = Field(default=None, max_length=64)
    channel: Literal["app", "web", "partner", "admin", "whatsapp"] = "app"
    delivery_address: ChatAddress | None = None


class ApprovalInput(BaseModel):
    approved: bool
    # Required: an approval always names the action the customer was shown, never "whatever is waiting".
    tool_call_id: str = Field(min_length=1, max_length=128)


async def caller_dep(
    request: Request,
    authorization: Annotated[str | None, Header()] = None,
    x_firebase_appcheck: Annotated[str | None, Header()] = None,
) -> Caller:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Sign in required")
    token = authorization[7:].strip()
    app_check: AppCheckVerifier | None = request.app.state.app_check
    try:
        # App Check proves a genuine Yummy Chops app or website, as on the API. The API's own WhatsApp calls
        # carry a channel token instead; it is signed with the shared secret and verified below like any token.
        if app_check is not None and not token.startswith(f"{CHANNEL_PREFIX}."):
            if not x_firebase_appcheck:
                raise AuthError("App Check token required")
            await app_check.verify(x_firebase_appcheck)
        return await request.app.state.verifier.verify(token)
    except AuthError as exc:
        raise HTTPException(401, str(exc)) from exc


CallerDep = Annotated[Caller, Depends(caller_dep)]


def create_app(
    settings: Settings | None = None,
    *,
    verifier: Verifier | None = None,
    models: ModelFactory | None = None,
    http: httpx.AsyncClient | None = None,
    checkpointer: Any = None,
    store: AgentStore | None = None,
    app_check: AppCheckVerifier | None = None,
) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        async with AsyncExitStack() as stack:
            if not hasattr(app.state, "service"):
                await _wire(app, stack)
            yield
            await app.state.store.close()

    async def _wire(app: FastAPI, stack: AsyncExitStack | None) -> None:
        settings.validate_for_environment()
        agent_store = store or AgentStore(settings.database_url)
        await agent_store.create_all()
        model_factory = models
        if model_factory is None and settings.llm_configured:
            model_factory = GeminiFactory(settings)
        if model_factory is None:
            # No Gemini key: Yummy still works in rule-based offline mode (same tools, approvals and audit).
            model_factory = OfflineModels()
        offline_only = isinstance(model_factory, OfflineModels)
        saver = checkpointer
        if saver is None:
            assert stack is not None
            saver = await make_checkpointer(settings, stack)
        client = http or httpx.AsyncClient(timeout=settings.api_timeout_seconds)
        graph = build_graph(
            # A turn whose daily spend budget is used up is answered by the rule-based models (AgentService).
            models=model_factory if offline_only else BudgetedModels(model_factory, OfflineModels()),
            registry=build_registry(),
            audit=agent_store,
            settings=settings,
            checkpointer=saver,
        )
        app.state.store = agent_store
        app.state.verifier = ChannelTokenVerifier(
            settings.channel_token_secret.get_secret_value(),
            verifier or FirebaseVerifier(settings.firebase_project_id, settings.check_token_revocation),
        )
        # As in the API: App Check is on when APP_CHECK_ENFORCED is set (or a verifier is handed in).
        app.state.app_check = app_check or (
            FirebaseAppCheckVerifier(settings.firebase_project_id) if settings.app_check_enforced else None
        )
        app.state.service = AgentService(
            settings=settings,
            graph=graph,
            store=agent_store,
            http=client,
            model_name=model_factory.model_name if model_factory else "unconfigured",
        )
        app.state.llm_ready = not offline_only
        app.state.ai_mode = "offline" if offline_only else "llm"

    app = FastAPI(
        title="Yummy Chops Agents",
        version="0.1.0",
        lifespan=lifespan,
        docs_url=None if settings.environment == "production" else "/docs",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-Firebase-AppCheck"],
        allow_credentials=False,
    )
    app.state.wire = _wire

    def service(request: Request) -> AgentService:
        return request.app.state.service  # type: ignore[no-any-return]

    def result_json(result: Any) -> dict[str, Any]:
        return {
            "thread_id": result.thread_id,
            "status": result.status,
            "reply": result.reply,
            "agent": result.agent,
            "cards": result.cards,
            "approval": result.approval,
            "warnings": result.warnings,
        }

    @app.get("/health")
    async def health(request: Request) -> dict[str, Any]:
        return {
            "status": "ok",
            "llm_configured": bool(getattr(request.app.state, "llm_ready", False)),
            "ai_mode": getattr(request.app.state, "ai_mode", "unknown"),
            "assistant": "Yummy",
        }

    @app.post("/v1/chat")
    async def chat(data: ChatInput, caller: CallerDep, request: Request) -> dict[str, Any]:
        try:
            result = await service(request).chat(
                caller,
                data.message,
                thread_id=data.thread_id,
                channel=data.channel,
                delivery_address=data.delivery_address.model_dump() if data.delivery_address else None,
            )
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc
        except RateLimitedError as exc:
            raise HTTPException(429, str(exc)) from exc
        except NoPendingApprovalError as exc:
            raise HTTPException(409, str(exc)) from exc
        return result_json(result)

    @app.post("/v1/chat/{thread_id}/approval")
    async def approval(
        thread_id: str, data: ApprovalInput, caller: CallerDep, request: Request
    ) -> dict[str, Any]:
        try:
            result = await service(request).resume(
                caller, thread_id, approved=data.approved, tool_call_id=data.tool_call_id
            )
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc
        except NoPendingApprovalError as exc:
            raise HTTPException(409, str(exc)) from exc
        return result_json(result)

    @app.get("/v1/threads")
    async def threads(caller: CallerDep, request: Request) -> list[dict[str, Any]]:
        return await request.app.state.store.list_threads(caller.uid)

    @app.get("/v1/threads/{thread_id}/messages")
    async def messages(thread_id: str, caller: CallerDep, request: Request) -> list[dict[str, Any]]:
        try:
            return await service(request).history(caller, thread_id)
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc

    @app.delete("/v1/threads/{thread_id}", status_code=204)
    async def delete_thread(thread_id: str, caller: CallerDep, request: Request) -> None:
        try:
            await service(request).delete_thread(caller, thread_id)
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc

    def _require_ai_monitor(caller: Caller) -> None:
        if not caller.roles & {"operations_manager", "super_admin"}:
            raise HTTPException(403, "AI monitoring requires operations or super admin")

    @app.get("/v1/admin/metrics")
    async def metrics(
        caller: CallerDep, request: Request, days: Annotated[int, Query(ge=1, le=90)] = 7
    ) -> dict[str, Any]:
        _require_ai_monitor(caller)
        data = await request.app.state.store.metrics(days)
        return {**data, "model": request.app.state.service.model_name}

    @app.get("/v1/admin/tool-invocations")
    async def invocations(
        caller: CallerDep, request: Request, limit: Annotated[int, Query(ge=1, le=500)] = 100
    ) -> list[dict[str, Any]]:
        _require_ai_monitor(caller)
        return await request.app.state.store.recent_invocations(limit)

    return app


def app_factory() -> FastAPI:
    return create_app()
