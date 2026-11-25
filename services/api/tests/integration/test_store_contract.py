"""DocumentStore contract: the in-memory adapter and the Firestore adapter must behave the same.

The Firestore variant runs only when FIRESTORE_EMULATOR_HOST is set (CI starts the emulator).
"""

from __future__ import annotations

import os
import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import pytest

from gudmeal_api.errors import Conflict, NotFound
from gudmeal_api.repositories import MemoryDocumentStore

BACKENDS = ["memory"]
if os.environ.get("FIRESTORE_EMULATOR_HOST"):
    BACKENDS.append("firestore")


@pytest.fixture(params=BACKENDS)
async def store(request) -> AsyncIterator[object]:
    if request.param == "memory":
        yield MemoryDocumentStore()
        return
    from gudmeal_api.repositories.firestore_store import FirestoreDocumentStore

    # The emulator runs in single-project mode; collections are unique per test instead.
    yield FirestoreDocumentStore.from_project(os.environ.get("GCLOUD_PROJECT", "demo-gudmeal-rules"))


def col() -> str:
    return f"contract_{uuid.uuid4().hex[:8]}"


async def test_create_get_update_delete(store):
    c = col()
    await store.create(f"{c}/a", {"id": "a", "n": 1, "nested": {"x": 1}})
    with pytest.raises(Conflict):
        await store.create(f"{c}/a", {"id": "a"})
    await store.update(f"{c}/a", {"n": 2, "nested.y": 3})
    doc = await store.get(f"{c}/a")
    assert doc["n"] == 2 and doc["nested"] == {"x": 1, "y": 3}
    with pytest.raises(NotFound):
        await store.update(f"{c}/missing", {"n": 1})
    await store.delete(f"{c}/a")
    assert await store.get(f"{c}/a") is None


async def test_queries(store):
    c = col()
    now = datetime.now(UTC).replace(microsecond=0)
    for i in range(5):
        await store.set(
            f"{c}/d{i}",
            {
                "id": f"d{i}",
                "group": "even" if i % 2 == 0 else "odd",
                "rank": i,
                "tags": [f"t{i}", "all"],
                "at": now + timedelta(minutes=i),
            },
        )
    evens = await store.query(c, where=[("group", "==", "even")], order_by=[("rank", "desc")])
    assert [d["id"] for d in evens] == ["d4", "d2", "d0"]
    assert len(await store.query(c, where=[("tags", "array_contains", "t3")])) == 1
    assert len(await store.query(c, where=[("tags", "array_contains_any", ["t1", "t2"])])) == 2
    assert [
        d["id"] for d in await store.query(c, where=[("rank", "in", [1, 3])], order_by=[("rank", "asc")])
    ] == ["d1", "d3"]
    recent = await store.query(c, where=[("at", ">=", now + timedelta(minutes=3))], order_by=[("at", "asc")])
    assert [d["id"] for d in recent] == ["d3", "d4"]
    assert len(await store.query(c, order_by=[("rank", "asc")], limit=2)) == 2


async def test_null_filters(store):
    """`!= None` finds documents whose field has a value (the catalogue reads only vouchers tied to a merchant)."""
    c = col()
    await store.set(f"{c}/shop", {"id": "shop", "restaurant_id": "r1"})
    await store.set(f"{c}/personal", {"id": "personal", "restaurant_id": None})
    assert [d["id"] for d in await store.query(c, where=[("restaurant_id", "!=", None)])] == ["shop"]
    assert [d["id"] for d in await store.query(c, where=[("restaurant_id", "==", None)])] == ["personal"]


async def test_transactions_are_atomic(store):
    c = col()
    await store.set(f"{c}/counter", {"id": "counter", "n": 0})

    async def bump(tx):
        doc = await tx.get(f"{c}/counter")
        tx.update(f"{c}/counter", {"n": doc["n"] + 1})
        tx.create(f"{c}/log1", {"id": "log1"})
        return doc["n"] + 1

    assert await store.run_transaction(bump) == 1

    async def conflicting(tx):
        await tx.get(f"{c}/counter")
        tx.update(f"{c}/counter", {"n": 100})
        tx.create(f"{c}/log1", {"id": "dup"})  # already exists → whole transaction fails

    with pytest.raises(Conflict):
        await store.run_transaction(conflicting)
    assert (await store.get(f"{c}/counter"))["n"] == 1


async def test_get_many_preserves_order(store):
    c = col()
    await store.set(f"{c}/x", {"id": "x"})
    await store.set(f"{c}/z", {"id": "z"})
    docs = await store.get_many([f"{c}/z", f"{c}/missing", f"{c}/x"])
    assert [d["id"] if d else None for d in docs] == ["z", None, "x"]
