"""Central, typed tool registry and the execution pipeline every agent tool call goes through.

Pipeline: known tool → allowed for this agent → caller role permitted → arguments validated (Pydantic)
→ per-user rate limit → approval (handled by the graph via interrupt) → timeout → API call → audit.
Tools never accept identity arguments; identity comes from the verified token bound to the request.
"""

from __future__ import annotations

import asyncio
import logging
import time
from collections import defaultdict, deque
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from datetime import datetime
from typing import Annotated, Any, Protocol

from pydantic import BaseModel, ConfigDict, StringConstraints, ValidationError

from ..api_client import ApiError, GudMealApi
from ..identity import Caller

logger = logging.getLogger(__name__)

# Every id a tool takes (order, shop, item, quote, rider...) ends up in the path of an API call, so it may only
# hold letters, digits, "_" and "-": an id such as "abc/cancel#" can never turn one API call into another.
ToolId = Annotated[str, StringConstraints(pattern=r"^[A-Za-z0-9_-]{2,64}$")]


class ToolArgs(BaseModel):
    """Base for tool arguments: unknown fields are rejected so the model gets precise feedback."""

    model_config = ConfigDict(extra="forbid")


FORBIDDEN_ARG_NAMES = {
    "user_id",
    "uid",
    "customer_id",
    "role",
    "roles",
    "token",
    "amount",
    "amount_kobo",
    "price",
    "total",
    "total_kobo",
}


@dataclass
class ToolContext:
    api: GudMealApi
    caller: Caller
    thread_id: str
    tool_call_id: str
    artifacts: dict[str, Any]
    now: datetime

    def idempotency_key(self, purpose: str) -> str:
        # Stable across graph resumes/retries of the same tool call → the API dedupes side effects.
        return f"agent-{self.thread_id[:24]}-{self.tool_call_id[-32:]}-{purpose}"[:200]


@dataclass
class ToolOutput:
    data: Any
    card: dict[str, Any] | None = None
    artifacts: dict[str, Any] | None = None


Handler = Callable[[Any, ToolContext], Awaitable[ToolOutput]]
Preview = Callable[[Any, ToolContext], Awaitable[dict[str, Any]]]


@dataclass(frozen=True)
class ToolSpec:
    name: str
    description: str
    args_model: type[BaseModel]
    handler: Handler
    roles: frozenset[str]
    requires_approval: bool = False
    preview: Preview | None = None
    timeout_s: float = 20.0
    rate_per_minute: int = 30
    mutating: bool = False

    def schema(self) -> dict[str, Any]:
        params = self.args_model.model_json_schema()
        params.pop("title", None)
        return {
            "type": "function",
            "function": {"name": self.name, "description": self.description, "parameters": params},
        }

    def permitted(self, caller: Caller) -> bool:
        return bool(self.roles & caller.roles)


class ToolError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code
        self.message = message

    def payload(self) -> dict[str, Any]:
        return {"error": {"code": self.code, "message": self.message}}


class AuditSink(Protocol):
    async def record_tool(self, entry: dict[str, Any]) -> None: ...


class RateLimiter:
    def __init__(self) -> None:
        self._events: dict[str, deque[float]] = defaultdict(deque)

    def check(self, key: str, per_minute: int) -> None:
        now = time.monotonic()
        q = self._events[key]
        while q and now - q[0] > 60:
            q.popleft()
        if len(q) >= per_minute:
            raise ToolError("rate_limited", "Too many requests for this action; please wait a moment")
        q.append(now)


@dataclass
class ToolRegistry:
    tools: dict[str, ToolSpec] = field(default_factory=dict)
    limiter: RateLimiter = field(default_factory=RateLimiter)

    def register(self, spec: ToolSpec) -> ToolSpec:
        if spec.name in self.tools:
            raise ValueError(f"Duplicate tool {spec.name}")
        bad = FORBIDDEN_ARG_NAMES & set(spec.args_model.model_fields)
        if bad:
            raise ValueError(f"Tool {spec.name} must not accept identity/amount arguments: {sorted(bad)}")
        self.tools[spec.name] = spec
        return spec

    def get(self, name: str) -> ToolSpec | None:
        return self.tools.get(name)

    def available(self, names: list[str], caller: Caller) -> list[ToolSpec]:
        return [self.tools[n] for n in names if n in self.tools and self.tools[n].permitted(caller)]

    def authorize(
        self, name: str, allowed_names: list[str], caller: Caller, raw_args: dict[str, Any]
    ) -> tuple[ToolSpec, BaseModel]:
        spec = self.tools.get(name)
        if spec is None or name not in allowed_names:
            raise ToolError("unknown_tool", f"Tool '{name}' is not available to this assistant")
        if not spec.permitted(caller):
            raise ToolError("permission_denied", "You do not have permission to use this action")
        try:
            args = spec.args_model.model_validate(raw_args or {})
        except ValidationError as exc:
            errors = [f"{'.'.join(str(p) for p in e['loc'])}: {e['msg']}" for e in exc.errors()][:5]
            raise ToolError("invalid_arguments", "; ".join(errors)) from exc
        self.limiter.check(f"{caller.uid}:{name}", spec.rate_per_minute)
        return spec, args

    async def run(
        self, spec: ToolSpec, args: BaseModel, ctx: ToolContext, audit: AuditSink | None
    ) -> ToolOutput:
        started = time.perf_counter()
        status, error = "ok", None
        try:
            return await asyncio.wait_for(spec.handler(args, ctx), timeout=spec.timeout_s)
        except TimeoutError as exc:
            status, error = "timeout", "timeout"
            raise ToolError("timeout", "The action took too long; please try again") from exc
        except ApiError as exc:
            status, error = "api_error", exc.code
            raise ToolError(exc.code, exc.message) from exc
        except ToolError as exc:
            status, error = "error", exc.code
            raise
        except Exception as exc:
            # Anything else (an API answer in an unexpected shape, a bug in a handler) still ends as a tool
            # result, so the conversation is never left with a tool call that has no answer.
            status, error = "error", "internal_error"
            logger.exception("tool %s failed unexpectedly", spec.name)
            raise ToolError("internal_error", "Something went wrong on our side; please try again") from exc
        finally:
            if audit is not None:
                try:
                    await audit.record_tool(
                        {
                            "thread_id": ctx.thread_id,
                            "tool_call_id": ctx.tool_call_id,
                            "uid": ctx.caller.uid,
                            "tool": spec.name,
                            "status": status,
                            "error": error[:64] if error else None,
                            "mutating": spec.mutating,
                            "latency_ms": round((time.perf_counter() - started) * 1000, 1),
                            "args": _redact(args.model_dump(mode="json")),
                        }
                    )
                except (
                    Exception
                ):  # the action itself is finished: a failed audit write must not undo its answer
                    logger.exception("could not record the audit entry for tool %s", spec.name)


_PRIVATE_KEYS = ("phone", "code", "note", "address", "name")


def _redact(value: Any) -> Any:
    """Tool arguments for the audit, without personal details at any depth (e.g. ``items[].notes``)."""
    if isinstance(value, dict):
        return {
            k: "[redacted]" if any(s in k.lower() for s in _PRIVATE_KEYS) else _redact(v)
            for k, v in value.items()
        }
    if isinstance(value, list):
        return [_redact(v) for v in value]
    return value
