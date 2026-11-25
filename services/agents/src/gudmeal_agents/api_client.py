"""HTTP client for gudmeal-api, bound to the end user's ID token (on-behalf-of).

The API re-applies authentication, RBAC, ownership checks, pricing and the order state machine for
every call, so the agent can never do more than the signed-in user could do in the app.
"""

from __future__ import annotations

import asyncio
import contextvars
import re
import time
from typing import Any

import httpx

# A path is fixed text plus ids. Anything that could change the route ("..", a query or fragment mark, an escape,
# a backslash, a space) is refused; query parameters always travel in `params`.
_UNSAFE_PATH = re.compile(r"\.\.|[?#%\\\s]")


class ApiError(Exception):
    def __init__(self, status: int, code: str, message: str, details: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message
        self.details = details or {}

    def as_tool_error(self) -> dict[str, Any]:
        return {"error": {"code": self.code, "message": self.message, "details": self.details}}


class ServiceAuth:
    """Proves to gudmeal-api that a call comes from this service. App Check is for client apps; Yummy's tool
    calls carry the user's token *and* this service credential (ADR-0017)."""

    def __init__(self, mode: str, *, secret: str | None = None, audience: str | None = None) -> None:
        self.mode = mode
        self.secret = secret
        self.audience = audience
        self._token: str | None = None
        self._expires = 0.0
        self._lock = asyncio.Lock()

    async def headers(self) -> dict[str, str]:
        if self.mode == "shared_secret" and self.secret:
            return {"X-Internal-Token": self.secret}
        if self.mode != "oidc" or not self.audience:
            return {}
        async with self._lock:
            if self._token is None or time.time() > self._expires - 300:
                from google.auth.transport.requests import Request
                from google.oauth2 import id_token

                # Cloud Run's metadata server signs an ID token for this service account (valid one hour).
                self._token = await asyncio.to_thread(id_token.fetch_id_token, Request(), self.audience)
                self._expires = time.time() + 3300
        return {"X-Service-Authorization": f"Bearer {self._token}"}


class GudMealApi:
    def __init__(
        self,
        http: httpx.AsyncClient,
        base_url: str,
        token: str,
        *,
        request_id: str | None = None,
        service_auth: ServiceAuth | None = None,
    ) -> None:
        self._http = http
        self._base = base_url.rstrip("/")
        self._service_auth = service_auth
        self._headers = {"Authorization": f"Bearer {token}", "X-Agent-Request": "gudmeal-agents"}
        if request_id:
            self._headers["X-Request-ID"] = request_id

    async def request(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        params: dict[str, Any] | None = None,
        idempotency_key: str | None = None,
    ) -> Any:
        if _UNSAFE_PATH.search(path):
            raise ApiError(400, "invalid_reference", "That reference is not valid")
        headers = dict(self._headers)
        if self._service_auth is not None:
            headers.update(await self._service_auth.headers())
        if idempotency_key:
            headers["Idempotency-Key"] = idempotency_key
        try:
            resp = await self._http.request(
                method, f"{self._base}{path}", json=json, params=params, headers=headers
            )
        except httpx.HTTPError as exc:
            raise ApiError(503, "api_unreachable", "Yummy Chops service is temporarily unreachable") from exc
        if resp.status_code == 204:
            return None
        try:
            body = resp.json()
        except ValueError:
            body = {}
        if resp.status_code >= 400:
            err = body.get("error", {}) if isinstance(body, dict) else {}
            raise ApiError(
                resp.status_code,
                err.get("code", "error"),
                err.get("message", "Request failed"),
                err.get("details"),
            )
        return body

    async def get(self, path: str, **params: Any) -> Any:
        return await self.request("GET", path, params={k: v for k, v in params.items() if v is not None})

    async def post(self, path: str, body: Any = None, *, idempotency_key: str | None = None) -> Any:
        return await self.request(
            "POST", path, json=body if body is not None else {}, idempotency_key=idempotency_key
        )

    async def patch(self, path: str, body: Any) -> Any:
        return await self.request("PATCH", path, json=body)


# Bound per request by AgentService; never stored in graph state or checkpoints.
current_api: contextvars.ContextVar[GudMealApi | None] = contextvars.ContextVar("current_api", default=None)
