from __future__ import annotations

import os
import uuid
from collections.abc import AsyncIterator
from typing import Any

import httpx
import pytest

from gudmeal_api.config import Settings
from gudmeal_api.container import Container, build_container
from gudmeal_api.domain.hours import OpeningHours
from gudmeal_api.ledger.db import Database
from gudmeal_api.main import create_app
from gudmeal_api.repositories import MemoryDocumentStore
from gudmeal_api.security.auth import StaticTokenVerifier
from gudmeal_api.security.rbac import Principal
from gudmeal_api.seed import seed
from gudmeal_api.services.infra import MemoryIdentityAdmin, RecordingTaskQueue


def _p(uid: str, *roles: str, restaurants: dict[str, str] | None = None, **kw: Any) -> Principal:
    return Principal(uid=uid, roles=frozenset({"customer", *roles}), restaurant_roles=restaurants or {}, **kw)


PRINCIPALS: dict[str, Principal] = {
    "customer": _p("cust-1", email="ada@example.com", name="Ada Obi", phone="+2348011111111"),
    "customer2": _p("cust-2", name="Bayo"),
    "customer3": _p("cust-3", name="Chika", phone="+2348044444444"),
    "owner": _p("demo-owner-1", "restaurant_owner", restaurants={"r-jollof-junction": "owner"}),
    "kitchen": _p("staff-1", "restaurant_staff", restaurants={"r-jollof-junction": "staff"}),
    "other_owner": _p("owner-2", "restaurant_owner", restaurants={"r-suya-lane": "owner"}),
    "rider1": _p("demo-rider-1", "rider", name="Chidi Okafor"),
    "rider2": _p("demo-rider-2", "rider", name="Bola Adeyemi"),
    "rider3": _p("demo-rider-3", "rider"),
    "rider4": _p("demo-rider-4", "rider"),
    "rider5": _p("demo-rider-5", "rider", name="Ifeanyi Eze"),  # Enugu
    "rider6": _p("demo-rider-6", "rider", name="Ngozi Nwosu"),  # Enugu
    "hub": _p("hub-1", "hub_agent"),
    "support": _p("support-1", "support_agent"),
    "ops": _p("ops-1", "operations_manager"),
    "finance": _p("fin-1", "finance_manager"),
    "admin": _p("admin-1", "super_admin"),
}

LEKKI = {"lat": 6.4410, "lng": 3.4600}
ADDRESS = {
    "label": "Home",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": LEKKI,
    "contact_phone": "+2348011111111",
}


def auth(name: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {name}"}


def idem() -> dict[str, str]:
    return {"Idempotency-Key": f"test-{uuid.uuid4().hex}"}


async def make_container(
    database_url: str = "sqlite+aiosqlite:///:memory:", db: Database | None = None, **overrides: Any
) -> Container:
    options: dict[str, Any] = {
        "environment": "test",
        "database_url": database_url,
        "seed_demo_data": False,
        "internal_shared_secret": "test-internal-secret",
        "public_base_url": "http://test",
        "payment_callback_url": "http://web.test/checkout/callback",
        "file_store": "memory",
    }
    settings = Settings(**(options | overrides))
    if db is not None:
        await db.create_all()
    c = await build_container(
        settings,
        store=MemoryDocumentStore(),
        db=db,
        verifier=StaticTokenVerifier(PRINCIPALS),
        identity=MemoryIdentityAdmin(),
        task_queue=RecordingTaskQueue,
    )
    await seed(c.repos)
    for r in await c.repos.restaurants.find():  # deterministic tests: open around the clock
        await c.repos.restaurants.update(
            r.id, {"opening_hours": OpeningHours.every_day("00:00", "24:00").model_dump()}
        )
    return c


@pytest.fixture
async def container() -> AsyncIterator[Container]:
    db = None
    url = os.environ.get("TEST_DATABASE_URL")
    if url:  # CI runs the same suite against PostgreSQL
        db = Database(url)
        from gudmeal_api.ledger.tables import Base

        async with db.engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
    c = await make_container(url or "sqlite+aiosqlite:///:memory:", db=db)
    yield c
    await c.close()


@pytest.fixture
async def client(container: Container) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(container.settings, container=container)
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as http:
        yield http


class Flow:
    """Helpers that drive the API like the real clients do."""

    def __init__(self, client: httpx.AsyncClient, container: Container) -> None:
        self.client = client
        self.c = container

    async def quote(
        self,
        who: str = "customer",
        *,
        restaurant_id: str = "r-jollof-junction",
        lines: list | None = None,
        fulfillment: str = "delivery",
        voucher: str | None = None,
    ) -> dict[str, Any]:
        lines = lines or [
            {
                "item_id": "jj-party-jollof",
                "quantity": 2,
                "selections": [{"group_id": "r-jollof-junction-protein", "choice_ids": ["chicken"]}],
            },
            {"item_id": "r-jollof-junction-drink-0", "quantity": 2},
        ]
        body: dict[str, Any] = {"restaurant_id": restaurant_id, "lines": lines, "fulfillment": fulfillment}
        if fulfillment == "delivery":
            body["delivery_address"] = ADDRESS
        if voucher:
            body["voucher_code"] = voucher
        r = await self.client.post("/v1/quotes", json=body, headers=auth(who))
        assert r.status_code == 201, r.text
        return r.json()

    async def order(self, who: str = "customer", **kw: Any) -> dict[str, Any]:
        quote = await self.quote(who, **kw)
        r = await self.client.post(
            "/v1/orders", json={"quote_id": quote["id"], "channel": "web"}, headers={**auth(who), **idem()}
        )
        assert r.status_code == 201, r.text
        return r.json()

    async def paid_order(self, who: str = "customer", **kw: Any) -> dict[str, Any]:
        order = await self.order(who, **kw)
        r = await self.client.post(
            f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth(who), **idem()}
        )
        assert r.status_code == 200, r.text
        ref = r.json()["reference"]
        r = await self.client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")
        assert r.status_code == 303, r.text
        return await self.get(order["id"], who) | {"payment_reference": ref}

    async def get(self, order_id: str, who: str = "customer") -> dict[str, Any]:
        r = await self.client.get(f"/v1/orders/{order_id}", headers=auth(who))
        assert r.status_code == 200, r.text
        return r.json()

    async def deliver(self, order_id: str, who: str = "customer") -> dict[str, Any]:
        """The kitchen accepts a paid Jollof Junction order, the offered rider picks it up and delivers it with
        the customer's code; the order is then completed and settled."""
        r = await self.client.post(
            f"/v1/partner/restaurants/r-jollof-junction/orders/{order_id}/accept",
            json={"prep_minutes": 10},
            headers=auth("kitchen"),
        )
        assert r.status_code == 200, r.text
        offers = await self.c.repos.assignments.find(where=[("order_id", "==", order_id)])
        offer = next(o for o in offers if o.status == "offered")
        rider = next(name for name, p in PRINCIPALS.items() if p.uid == offer.rider_id)
        r = await self.client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
        assert r.status_code == 200, r.text
        r = await self.client.post(f"/v1/rider/deliveries/{order_id}/pickup", headers=auth(rider))
        assert r.status_code == 200, r.text
        codes = (await self.client.get(f"/v1/orders/{order_id}/codes", headers=auth(who))).json()
        r = await self.client.post(
            f"/v1/rider/deliveries/{order_id}/deliver",
            json={"code": codes["delivery_code"]},
            headers=auth(rider),
        )
        assert r.status_code == 200, r.text
        return await self.get(order_id, who)


@pytest.fixture
def flow(client: httpx.AsyncClient, container: Container) -> Flow:
    return Flow(client, container)
