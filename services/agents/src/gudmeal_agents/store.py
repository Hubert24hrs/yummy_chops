"""Agent bookkeeping database: thread ownership, tool-invocation audit and per-run usage/cost.

Separate from the API's money database. LangGraph checkpoints live in their own tables (checkpointer).
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import JSON, Boolean, DateTime, Float, Index, Integer, String, Text, delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.pool import StaticPool


def utcnow() -> datetime:
    return datetime.now(UTC)


class Base(DeclarativeBase):
    pass


class AgentThread(Base):
    __tablename__ = "agent_threads"
    thread_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    uid: Mapped[str] = mapped_column(String(128), index=True)
    title: Mapped[str | None] = mapped_column(String(120))
    channel: Mapped[str] = mapped_column(String(16), default="app")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class ToolInvocation(Base):
    __tablename__ = "agent_tool_invocations"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    thread_id: Mapped[str] = mapped_column(String(64), index=True)
    tool_call_id: Mapped[str] = mapped_column(String(128))
    uid: Mapped[str] = mapped_column(String(128), index=True)
    tool: Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(16))
    error: Mapped[str | None] = mapped_column(String(64))
    mutating: Mapped[bool] = mapped_column(Boolean, default=False)
    latency_ms: Mapped[float] = mapped_column(Float, default=0)
    args: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    __table_args__ = (Index("ix_tool_inv_time", "created_at"),)


class AgentRun(Base):
    __tablename__ = "agent_runs"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    thread_id: Mapped[str] = mapped_column(String(64), index=True)
    uid: Mapped[str] = mapped_column(String(128), index=True)
    agent: Mapped[str | None] = mapped_column(String(32))
    model: Mapped[str] = mapped_column(String(80))
    status: Mapped[str] = mapped_column(String(24))
    input_tokens: Mapped[int] = mapped_column(Integer, default=0)
    output_tokens: Mapped[int] = mapped_column(Integer, default=0)
    llm_calls: Mapped[int] = mapped_column(Integer, default=0)
    cost_usd: Mapped[float] = mapped_column(Float, default=0.0)
    latency_ms: Mapped[float] = mapped_column(Float, default=0.0)
    error: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    __table_args__ = (Index("ix_agent_runs_time", "created_at"),)


class ThreadAccessError(Exception):
    pass


class AgentStore:
    def __init__(self, url: str) -> None:
        kwargs: dict[str, Any] = {}
        if url.startswith("sqlite") and ":memory:" in url:
            kwargs = {"poolclass": StaticPool, "connect_args": {"check_same_thread": False}}
        self.engine = create_async_engine(url, **kwargs)
        self.sessions = async_sessionmaker(self.engine, expire_on_commit=False)

    async def create_all(self) -> None:
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    async def close(self) -> None:
        await self.engine.dispose()

    async def create_thread(self, uid: str, channel: str, title: str | None) -> str:
        thread_id = f"t_{uuid.uuid4().hex}"
        async with self.sessions() as s, s.begin():
            s.add(
                AgentThread(thread_id=thread_id, uid=uid, channel=channel, title=(title or "")[:120] or None)
            )
        return thread_id

    async def assert_owner(self, thread_id: str, uid: str) -> None:
        async with self.sessions() as s:
            owner = await s.scalar(select(AgentThread.uid).where(AgentThread.thread_id == thread_id))
        if owner is None or owner != uid:
            raise ThreadAccessError("Conversation not found")

    async def touch(self, thread_id: str) -> None:
        async with self.sessions() as s, s.begin():
            row = await s.get(AgentThread, thread_id)
            if row:
                row.updated_at = utcnow()

    async def list_threads(self, uid: str, limit: int = 30) -> list[dict[str, Any]]:
        async with self.sessions() as s:
            rows = (
                await s.execute(
                    select(AgentThread)
                    .where(AgentThread.uid == uid)
                    .order_by(AgentThread.updated_at.desc())
                    .limit(limit)
                )
            ).scalars()
            return [
                {
                    "thread_id": r.thread_id,
                    "title": r.title,
                    "channel": r.channel,
                    "created_at": r.created_at,
                    "updated_at": r.updated_at,
                }
                for r in rows
            ]

    async def delete_thread(self, thread_id: str, uid: str) -> None:
        """Remove the conversation's audit rows (they hold tool arguments), then the owner row: if anything fails
        on the way, the owner can still see the conversation and delete it again. Usage rows (agent_runs) hold
        no content and stay, so deleting a conversation never resets a spend budget."""
        await self.assert_owner(thread_id, uid)
        async with self.sessions() as s, s.begin():
            await s.execute(delete(ToolInvocation).where(ToolInvocation.thread_id == thread_id))
            await s.execute(delete(AgentThread).where(AgentThread.thread_id == thread_id))

    async def record_tool(self, entry: dict[str, Any]) -> None:
        async with self.sessions() as s, s.begin():
            s.add(ToolInvocation(**entry))

    async def record_run(self, **fields: Any) -> None:
        async with self.sessions() as s, s.begin():
            s.add(AgentRun(**fields))

    async def usage_since(self, since: datetime, uid: str | None = None) -> tuple[int, float]:
        """Tokens (input + output) and cost in USD recorded since `since`, for one account or for everyone."""
        query = select(
            func.coalesce(func.sum(AgentRun.input_tokens + AgentRun.output_tokens), 0),
            func.coalesce(func.sum(AgentRun.cost_usd), 0.0),
        ).where(AgentRun.created_at >= since)
        if uid is not None:
            query = query.where(AgentRun.uid == uid)
        async with self.sessions() as s:
            tokens, cost = (await s.execute(query)).one()
        return int(tokens), float(cost)

    async def metrics(self, days: int = 7) -> dict[str, Any]:
        since = utcnow() - timedelta(days=days)
        async with self.sessions() as s:
            runs = await _agg(s, since)
            tools = (
                await s.execute(
                    select(
                        ToolInvocation.tool,
                        ToolInvocation.status,
                        func.count(),
                        func.avg(ToolInvocation.latency_ms),
                    )
                    .where(ToolInvocation.created_at >= since)
                    .group_by(ToolInvocation.tool, ToolInvocation.status)
                )
            ).all()
        by_tool: dict[str, dict[str, Any]] = {}
        for tool, status, count, latency in tools:
            entry = by_tool.setdefault(tool, {"calls": 0, "errors": 0, "avg_latency_ms": 0.0})
            entry["calls"] += int(count)
            if status != "ok":
                entry["errors"] += int(count)
            entry["avg_latency_ms"] = round(float(latency or 0), 1)
        return {"period_days": days, **runs, "tools": by_tool}

    async def recent_invocations(self, limit: int = 100) -> list[dict[str, Any]]:
        async with self.sessions() as s:
            rows = (
                await s.execute(
                    select(ToolInvocation).order_by(ToolInvocation.created_at.desc()).limit(min(limit, 500))
                )
            ).scalars()
            return [
                {
                    "tool": r.tool,
                    "status": r.status,
                    "error": r.error,
                    "uid": r.uid,
                    "thread_id": r.thread_id,
                    "latency_ms": r.latency_ms,
                    "mutating": r.mutating,
                    "created_at": r.created_at,
                }
                for r in rows
            ]


async def _agg(s: AsyncSession, since: datetime) -> dict[str, Any]:
    row = (
        await s.execute(
            select(
                func.count(),
                func.coalesce(func.sum(AgentRun.input_tokens), 0),
                func.coalesce(func.sum(AgentRun.output_tokens), 0),
                func.coalesce(func.sum(AgentRun.cost_usd), 0.0),
                func.coalesce(func.avg(AgentRun.latency_ms), 0.0),
            ).where(AgentRun.created_at >= since)
        )
    ).one()
    statuses = dict(
        (
            await s.execute(
                select(AgentRun.status, func.count())
                .where(AgentRun.created_at >= since)
                .group_by(AgentRun.status)
            )
        ).all()
    )
    agents = dict(
        (
            await s.execute(
                select(AgentRun.agent, func.count())
                .where(AgentRun.created_at >= since)
                .group_by(AgentRun.agent)
            )
        ).all()
    )
    runs = int(row[0])
    return {
        "runs": runs,
        "input_tokens": int(row[1]),
        "output_tokens": int(row[2]),
        "cost_usd": round(float(row[3]), 6),
        "avg_latency_ms": round(float(row[4]), 1),
        "cost_per_run_usd": round(float(row[3]) / runs, 6) if runs else 0.0,
        "by_status": {k: int(v) for k, v in statuses.items()},
        "by_agent": {str(k): int(v) for k, v in agents.items()},
    }
