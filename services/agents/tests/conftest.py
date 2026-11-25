"""Agents ↔ real gudmeal-api wired in-process. A scripted model stands in for Gemini (deterministic tests)."""

from __future__ import annotations

import json
from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager
from typing import Any

import httpx
import pytest
from gudmeal_api.config import Settings as ApiSettings
from gudmeal_api.container import build_container
from gudmeal_api.domain.hours import OpeningHours
from gudmeal_api.main import create_app as create_api_app
from gudmeal_api.repositories import MemoryDocumentStore
from gudmeal_api.security.auth import StaticTokenVerifier
from gudmeal_api.security.rbac import Principal
from gudmeal_api.seed import seed
from gudmeal_api.services.infra import MemoryIdentityAdmin, RecordingTaskQueue
from langchain_core.messages import AIMessage, ToolMessage
from langgraph.checkpoint.memory import InMemorySaver

from gudmeal_agents.agents import RouteDecision
from gudmeal_agents.config import Settings
from gudmeal_agents.identity import Caller, StaticVerifier
from gudmeal_agents.main import create_app
from gudmeal_agents.store import AgentStore

# Distinctive tokens so tests can prove they never reach persisted state.
TOKENS = {
    "customer": ("tok_cust_7f3a9c", Principal(uid="cust-1", roles=frozenset({"customer"}), name="Ada")),
    "customer2": ("tok_cust2_51be20", Principal(uid="cust-2", roles=frozenset({"customer"}), name="Bayo")),
    "owner": (
        "tok_owner_c0ffee",
        Principal(
            uid="demo-owner-1",
            roles=frozenset({"customer", "restaurant_owner"}),
            restaurant_roles={"r-jollof-junction": "owner"},
        ),
    ),
    "ops": ("tok_ops_99aa11", Principal(uid="ops-1", roles=frozenset({"customer", "operations_manager"}))),
}
LEKKI_ADDRESS = {
    "label": "Home",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": {"lat": 6.4410, "lng": 3.4600},
}


def bearer(who: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {TOKENS[who][0]}"}


class ScriptedModels:
    """Implements the ModelFactory protocol with a deterministic script."""

    model_name = "scripted-test-model"

    def __init__(self) -> None:
        self.steps: list[Callable[[list[Any]], AIMessage] | AIMessage | Exception] = []
        self.routes: list[RouteDecision | Exception] = []
        self.bound_tools: list[list[str]] = []
        self.calls = 0

    def for_tools(self, tools: list[dict[str, Any]]) -> ScriptedModels:
        self.bound_tools.append([t["function"]["name"] for t in tools])
        return self

    def for_structured(self, schema: type) -> _Router:
        return _Router(self)

    async def ainvoke(self, messages: list[Any], config: Any = None, **_: Any) -> AIMessage:
        self.calls += 1
        if not self.steps:
            raise AssertionError("Scripted model ran out of steps")
        step = self.steps.pop(0)
        if isinstance(step, Exception):
            raise step
        return step(messages) if callable(step) else step


class _Router:
    def __init__(self, parent: ScriptedModels) -> None:
        self.parent = parent

    async def ainvoke(self, messages: list[Any], config: Any = None, **_: Any) -> RouteDecision:
        if not self.parent.routes:
            return RouteDecision(agent="customer", intent="default", confidence=0.5)
        r = self.parent.routes.pop(0)
        if isinstance(r, Exception):
            raise r
        return r


def tool_call(name: str, args: dict[str, Any], call_id: str) -> AIMessage:
    return AIMessage(
        content="",
        tool_calls=[{"name": name, "args": args, "id": call_id}],
        usage_metadata={"input_tokens": 1200, "output_tokens": 60, "total_tokens": 1260},
    )


def last_tool_data(messages: list[Any]) -> dict[str, Any]:
    tm = next(m for m in reversed(messages) if isinstance(m, ToolMessage))
    return json.loads(tm.content)


@pytest.fixture
async def stack() -> AsyncIterator[dict[str, Any]]:
    async with make_stack(ScriptedModels()) as s:
        yield s


@pytest.fixture
async def offline_stack() -> AsyncIterator[dict[str, Any]]:
    """Yummy without a Gemini key: the rule-based offline model drives the same graph and tools."""
    from gudmeal_agents.offline import OfflineModels

    async with make_stack(OfflineModels()) as s:
        yield s


@asynccontextmanager
async def make_stack(
    models: Any, *, app_check: Any = None, **agent_settings: Any
) -> AsyncIterator[dict[str, Any]]:
    """`agent_settings` override the agents service's settings (budgets, limits) for one test."""
    api_settings = ApiSettings(
        environment="test",
        database_url="sqlite+aiosqlite:///:memory:",
        seed_demo_data=False,
        public_base_url="http://api.test",
    )
    container = await build_container(
        api_settings,
        store=MemoryDocumentStore(),
        verifier=StaticTokenVerifier({tok: p for tok, p in TOKENS.values()}),
        identity=MemoryIdentityAdmin(),
        task_queue=RecordingTaskQueue,
    )
    await seed(container.repos)
    for r in await container.repos.restaurants.find():
        await container.repos.restaurants.update(
            r.id, {"opening_hours": OpeningHours.every_day("00:00", "24:00").model_dump()}
        )
    api_app = create_api_app(api_settings, container=container)
    api_http = httpx.AsyncClient(transport=httpx.ASGITransport(app=api_app), base_url="http://api.test")

    settings = Settings(
        **{
            "environment": "test",
            "api_base_url": "http://api.test",
            "checkpointer": "memory",
            "database_url": "sqlite+aiosqlite:///:memory:",
            "chat_rate_per_minute": 100,
            **agent_settings,
        }
    )
    callers = {
        tok: Caller(uid=p.uid, roles=p.roles, restaurant_roles=dict(p.restaurant_roles), name=p.name)
        for tok, p in TOKENS.values()
    }
    saver = InMemorySaver()
    store = AgentStore(settings.database_url)
    app = create_app(
        settings,
        verifier=StaticVerifier(callers),
        models=models,
        http=api_http,
        checkpointer=saver,
        store=store,
        app_check=app_check,
    )
    await app.state.wire(app, None)
    client = httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://agents.test")
    try:
        yield {
            "client": client,
            "api": api_http,
            "models": models,
            "container": container,
            "saver": saver,
            "store": store,
            "app": app,
        }
    finally:
        await client.aclose()
        await api_http.aclose()
        await store.close()
        await container.close()
