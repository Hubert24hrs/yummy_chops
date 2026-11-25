"""AgentService: per-request identity binding, thread ownership, graph invocation, approvals, accounting."""

from __future__ import annotations

import asyncio
import logging
import time
import weakref
from collections import defaultdict, deque
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager, contextmanager
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any, Literal
from zoneinfo import ZoneInfo

import httpx
from langchain_core.messages import AIMessage, HumanMessage
from langgraph.types import Command

from .api_client import GudMealApi, ServiceAuth, current_api
from .config import Settings
from .graph import current_caller
from .guardrails import BLOCKED_REPLIES, CARD_WARNING, GuardResult, check_input
from .identity import Caller
from .llm import offline_turn, text_of
from .offline import OfflineModels
from .store import AgentStore, ThreadAccessError

logger = logging.getLogger(__name__)
LAGOS = ZoneInfo("Africa/Lagos")


class RateLimitedError(Exception):
    pass


class NoPendingApprovalError(Exception):
    pass


@dataclass
class ChatResult:
    thread_id: str
    status: Literal["completed", "approval_required", "blocked"]
    reply: str | None = None
    agent: str | None = None
    cards: list[dict[str, Any]] = field(default_factory=list)
    approval: dict[str, Any] | None = None
    warnings: list[str] = field(default_factory=list)


def _with_card_warning(reply: str, warnings: list[str] | None) -> str:
    if "card_number_removed" in (warnings or []) or "secret_removed" in (warnings or []):
        return f"{CARD_WARNING}\n\n{reply}".strip()
    return reply


class AgentService:
    def __init__(
        self, *, settings: Settings, graph: Any, store: AgentStore, http: httpx.AsyncClient, model_name: str
    ) -> None:
        self.settings = settings
        self.graph = graph
        self.store = store
        self.http = http
        self.model_name = model_name
        self._rate: dict[str, deque[float]] = defaultdict(deque)
        # One conversation runs one turn at a time in this process, so a double tap on Approve runs the action
        # once. A lock disappears when nobody holds it or waits for it.
        self._locks: weakref.WeakValueDictionary[str, asyncio.Lock] = weakref.WeakValueDictionary()
        secret = (
            settings.internal_shared_secret.get_secret_value() if settings.internal_shared_secret else None
        )
        self.service_auth = ServiceAuth(
            settings.internal_auth_mode,
            secret=secret,
            audience=settings.api_oidc_audience or settings.api_base_url,
        )

    # ------------------------------------------------------------------------------------------
    @contextmanager
    def _bind(self, caller: Caller, *, offline: bool = False) -> Iterator[None]:
        api = GudMealApi(self.http, self.settings.api_base_url, caller.token, service_auth=self.service_auth)
        t1, t2, t3 = current_caller.set(caller), current_api.set(api), offline_turn.set(offline)
        try:
            yield
        finally:
            current_caller.reset(t1)
            current_api.reset(t2)
            offline_turn.reset(t3)

    @asynccontextmanager
    async def _thread_lock(self, thread_id: str) -> AsyncIterator[None]:
        lock = self._locks.get(thread_id)
        if lock is None:
            lock = self._locks[thread_id] = asyncio.Lock()
        async with lock:
            yield

    def _check_rate(self, uid: str) -> None:
        now = time.monotonic()
        q = self._rate[uid]
        while q and now - q[0] > 60:
            q.popleft()
        if len(q) >= self.settings.chat_rate_per_minute:
            raise RateLimitedError("You're sending messages too quickly. Please wait a moment.")
        q.append(now)

    async def _budget_used_up(self, uid: str) -> bool:
        """Whether a daily spend budget is spent: this account's tokens or everyone's cost, counted from the
        usage table since midnight in Lagos (so the answer is the same on every instance)."""
        s = self.settings
        if self.model_name == OfflineModels.model_name:
            return False  # nothing to spend: the rule-based models already answer
        midnight = datetime.now(UTC).astimezone(LAGOS).replace(hour=0, minute=0, second=0, microsecond=0)
        since = midnight.astimezone(UTC)
        if s.user_daily_token_budget > 0:
            tokens, _ = await self.store.usage_since(since, uid)
            if tokens >= s.user_daily_token_budget:
                logger.warning("daily token budget used up for account %s: answering in rule-based mode", uid)
                return True
        if s.global_daily_cost_budget_usd > 0:
            _, cost = await self.store.usage_since(since)
            if cost >= s.global_daily_cost_budget_usd:
                logger.warning("global daily cost budget used up: answering in rule-based mode")
                return True
        return False

    def _config(self, thread_id: str) -> dict[str, Any]:
        return {
            "configurable": {"thread_id": thread_id},
            "recursion_limit": 4 * self.settings.max_graph_steps + 10,
        }

    async def _pending(self, thread_id: str) -> dict[str, Any] | None:
        snapshot = await self.graph.aget_state(self._config(thread_id))
        interrupts = list(getattr(snapshot, "interrupts", ()) or ())
        if not interrupts:
            for task in getattr(snapshot, "tasks", ()) or ():
                interrupts.extend(getattr(task, "interrupts", ()) or ())
        return interrupts[0].value if interrupts else None

    async def _usage(self, thread_id: str) -> dict[str, Any]:
        snapshot = await self.graph.aget_state(self._config(thread_id))
        return dict((snapshot.values or {}).get("usage") or {})

    # ------------------------------------------------------------------------------------------
    async def chat(
        self,
        caller: Caller,
        message: str,
        *,
        thread_id: str | None = None,
        channel: str = "app",
        delivery_address: dict[str, Any] | None = None,
    ) -> ChatResult:
        self._check_rate(caller.uid)
        guard = check_input(message, max_chars=self.settings.max_message_chars)
        existing = bool(thread_id)  # only an earlier turn can have left an approval waiting
        if thread_id:
            await self.store.assert_owner(thread_id, caller.uid)
        else:
            thread_id = await self.store.create_thread(caller.uid, channel, guard.text[:80])
        async with self._thread_lock(thread_id):
            if existing and await self._pending(thread_id):
                raise NoPendingApprovalError("Please approve or decline the pending action first")
            if guard.blocked:
                return await self._blocked(caller, thread_id, guard)
            payload: dict[str, Any] = {
                "messages": [HumanMessage(content=guard.text)],  # redacted text only is ever persisted
                "caller": caller.public_dict(),
                "turn_cards": [],
                "steps": 0,
                "blocked": False,
            }
            artifacts: dict[str, Any] = {"channel": channel}
            if delivery_address:
                artifacts["delivery_address"] = delivery_address
            payload["artifacts"] = artifacts
            return await self._run(caller, thread_id, payload, warnings=guard.warnings)

    async def _blocked(self, caller: Caller, thread_id: str, guard: GuardResult) -> ChatResult:
        """A blocked message (empty, too long, an attempt to override the rules) is answered here: it never
        reaches the graph, the model or the saved conversation."""
        reply = BLOCKED_REPLIES.get(guard.reason or "", BLOCKED_REPLIES["prompt_injection"])
        await self._record(caller, thread_id, None, {}, {}, time.perf_counter(), "blocked", None)
        return ChatResult(
            thread_id=thread_id,
            status="blocked",
            reply=_with_card_warning(reply, guard.warnings),
            warnings=guard.warnings,
        )

    async def resume(
        self, caller: Caller, thread_id: str, *, approved: bool, tool_call_id: str
    ) -> ChatResult:
        await self.store.assert_owner(thread_id, caller.uid)
        async with self._thread_lock(thread_id):
            pending = await self._pending(thread_id)
            if pending is None:
                raise NoPendingApprovalError("There is no action waiting for approval")
            if pending.get("tool_call_id") != tool_call_id:
                raise NoPendingApprovalError("This approval is out of date; please review the latest request")
            return await self._run(
                caller, thread_id, Command(resume={"approved": approved, "tool_call_id": tool_call_id})
            )

    async def _run(
        self, caller: Caller, thread_id: str, payload: Any, *, warnings: list[str] | None = None
    ) -> ChatResult:
        config = self._config(thread_id)
        before = await self._usage(thread_id)
        offline = await self._budget_used_up(caller.uid)
        model = OfflineModels.model_name if offline else self.model_name
        started = time.perf_counter()
        status, error = "completed", None
        try:
            with self._bind(caller, offline=offline):
                result = await self.graph.ainvoke(payload, config)
        except Exception as exc:
            status, error = "error", type(exc).__name__
            try:
                after = await self._usage(thread_id)  # what the turn used before it failed
            except Exception:
                after = before
            await self._record(caller, thread_id, None, before, after, started, status, error, model)
            raise
        pending = await self._pending(thread_id)
        after = dict(result.get("usage") or {})
        agent = result.get("active_agent")
        if pending is not None:
            status = "approval_required"
            out = ChatResult(
                thread_id=thread_id,
                status="approval_required",
                agent=agent,
                cards=result.get("turn_cards") or [],
                approval=pending,
            )
        else:
            last_ai = next(
                (m for m in reversed(result.get("messages", [])) if isinstance(m, AIMessage)), None
            )
            reply = _with_card_warning(text_of(last_ai) if last_ai else "", warnings)
            status = "blocked" if result.get("blocked") else "completed"
            out = ChatResult(
                thread_id=thread_id,
                status=status,
                reply=reply,
                agent=agent,  # type: ignore[arg-type]
                cards=result.get("turn_cards") or [],
                warnings=warnings or [],
            )
        await self._record(caller, thread_id, agent, before, after, started, status, error, model)
        await self.store.touch(thread_id)
        return out

    async def _record(
        self,
        caller: Caller,
        thread_id: str,
        agent: str | None,
        before: dict[str, Any],
        after: dict[str, Any],
        started: float,
        status: str,
        error: str | None,
        model: str | None = None,
    ) -> None:
        def delta(key: str) -> float:  # never negative: a turn cannot give tokens back
            return max(0.0, float(after.get(key, 0) or 0) - float(before.get(key, 0) or 0))

        await self.store.record_run(
            thread_id=thread_id,
            uid=caller.uid,
            agent=agent,
            model=model or self.model_name,
            status=status,
            input_tokens=int(delta("input_tokens")),
            output_tokens=int(delta("output_tokens")),
            llm_calls=int(delta("llm_calls")),
            cost_usd=round(delta("cost_usd"), 8),
            latency_ms=round((time.perf_counter() - started) * 1000, 1),
            error=error,
        )

    async def history(self, caller: Caller, thread_id: str) -> list[dict[str, Any]]:
        await self.store.assert_owner(thread_id, caller.uid)
        snapshot = await self.graph.aget_state(self._config(thread_id))
        out = []
        for m in (snapshot.values or {}).get("messages", []):
            if isinstance(m, HumanMessage):
                out.append(
                    {"role": "user", "text": m.content if isinstance(m.content, str) else str(m.content)}
                )
            elif isinstance(m, AIMessage) and not m.tool_calls and text_of(m):
                out.append({"role": "assistant", "text": text_of(m)})
        return out

    async def delete_thread(self, caller: Caller, thread_id: str) -> None:
        """The conversation's content goes first (checkpoints, then the audit rows) and the owner row last: if
        a step fails, the owner still sees the conversation and can delete it again."""
        await self.store.assert_owner(thread_id, caller.uid)
        async with self._thread_lock(thread_id):
            await self.graph.checkpointer.adelete_thread(thread_id)
            await self.store.delete_thread(thread_id, caller.uid)


__all__ = ["AgentService", "ChatResult", "NoPendingApprovalError", "RateLimitedError", "ThreadAccessError"]
