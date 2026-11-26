"""Who sees what, and what the API refuses outright (fixes from the November 2026 audit)."""

from __future__ import annotations

from types import SimpleNamespace

import httpx
import pytest

from conftest import Flow, auth
from gudmeal_api.api.deps import client_ip
from gudmeal_api.config import Settings
from gudmeal_api.errors import RateLimited
from gudmeal_api.security.compare import same_secret
from gudmeal_api.security.rate_limit import RateLimiter


async def test_the_shop_sees_progress_but_not_the_map(flow: Flow, client: httpx.AsyncClient) -> None:
    order = await flow.paid_order()
    for who, sees_map in (("customer", True), ("ops", True), ("kitchen", False), ("owner", False)):
        r = await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth(who))
        assert r.status_code == 200, (who, r.text)
        body = r.json()
        assert body["status"] == order["status"]
        assert (body["dropoff_location"] is not None) is sees_map, who
        assert body["route_polyline"] is None or sees_map, who
        assert body["rider_location"] is None or sees_map, who
    r = await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth("customer2"))
    assert r.status_code == 404  # someone else's order


async def test_only_riders_raise_rider_emergencies(client: httpx.AsyncClient) -> None:
    body = {"description": "My bike was hit at the junction"}
    assert (await client.post("/v1/rider/emergency", json=body, headers=auth("customer"))).status_code == 403
    assert (await client.post("/v1/rider/emergency", json=body, headers=auth("rider1"))).status_code == 201


async def test_campaign_vouchers_only_and_their_counters_stay(client: httpx.AsyncClient, container) -> None:
    voucher = {
        "kind": "fixed",
        "value": 50_000,
        "per_customer_limit": 1,
        "used_count": 999,
        "customer_id": "x",
    }
    r = await client.put("/v1/admin/vouchers/SPRING500", json=voucher, headers=auth("admin"))
    assert r.status_code == 200, r.text
    saved = await container.repos.vouchers.get("SPRING500")
    assert saved.used_count == 0 and saved.customer_id is None and saved.source == "campaign"
    # A customer's own reward voucher cannot be overwritten from the Command Centre.
    personal = saved.model_copy(update={"code": "PTS-ADA-1", "customer_id": "cust-1", "source": "points"})
    await container.repos.vouchers.save(personal)
    r = await client.put("/v1/admin/vouchers/PTS-ADA-1", json=voucher, headers=auth("admin"))
    assert r.status_code == 409
    shop_paid = {"kind": "fixed", "value": 50_000, "funded_by": "restaurant"}
    r = await client.put("/v1/admin/vouchers/SHOPPAYS", json=shop_paid, headers=auth("admin"))
    assert r.status_code == 422


async def test_huge_bodies_are_refused_before_they_are_read(client: httpx.AsyncClient) -> None:
    r = await client.post(
        "/v1/webhooks/whatsapp", content=b"{}", headers={"content-length": str(64 * 1024 * 1024)}
    )
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "too_large"


def test_the_callers_address_is_the_one_our_proxy_saw() -> None:
    def request(xff: str | None, hops: int) -> SimpleNamespace:
        headers = {"x-forwarded-for": xff} if xff is not None else {}
        settings = Settings(_env_file=None, trusted_proxy_hops=hops)
        return SimpleNamespace(
            headers=headers,
            client=SimpleNamespace(host="10.0.0.9"),
            app=SimpleNamespace(state=SimpleNamespace(container=SimpleNamespace(settings=settings))),
        )

    # Cloud Run appends the real address last; anything before it is whatever the caller typed.
    assert client_ip(request("6.6.6.6, 41.58.1.2", 1)) == "41.58.1.2"
    assert client_ip(request("41.58.1.2", 1)) == "41.58.1.2"
    assert client_ip(request("6.6.6.6, 41.58.1.2, 35.191.0.1", 2)) == "41.58.1.2"
    assert client_ip(request("6.6.6.6", 0)) == "10.0.0.9"  # no proxy in front: the header means nothing
    assert client_ip(request(None, 1)) == "10.0.0.9"


def test_the_rate_limiter_keeps_a_bounded_number_of_keys() -> None:
    limiter = RateLimiter(max_buckets=3)
    for key in ("a", "b", "c"):
        limiter.check(key, capacity=1, refill_per_second=0)
    limiter.check("d", capacity=1, refill_per_second=0)  # "a", the least recently used, is dropped
    assert list(limiter._buckets) == ["b", "c", "d"]


def test_secrets_compare_safely_whatever_the_caller_sends() -> None:
    assert same_secret("s3cret", "s3cret")
    assert not same_secret("s3cret", "S3cret")
    assert not same_secret("s3cret", None)
    assert not same_secret("s3cret", "sécret")  # text outside ASCII is simply wrong, not a server error


async def test_support_refunds_stay_within_what_was_paid(flow: Flow, client: httpx.AsyncClient) -> None:
    order = await flow.paid_order()
    r = await client.post(
        "/v1/support/tickets",
        json={"order_id": order["id"], "category": "late_delivery", "description": "Where is my food?"},
        headers=auth("customer"),
    )
    assert r.status_code == 201, r.text
    ticket = r.json()["id"]
    total = order["breakdown"]["total_kobo"]

    async def resolve(who: str, amount: int) -> httpx.Response:
        body = {"status": "resolved", "resolution": "Sorry", "refund_amount_kobo": amount}
        return await client.patch(f"/v1/admin/support/tickets/{ticket}", json=body, headers=auth(who))

    # The order is still under way: refunding it stops it, which is for operations, and only in full.
    assert (await resolve("support", total)).status_code == 403
    assert (await resolve("ops", total // 2)).status_code == 422
    assert (await resolve("ops", total + 1)).status_code == 422
    assert (await resolve("ops", total)).status_code == 200


async def test_profile_and_address_edits(client: httpx.AsyncClient) -> None:
    r = await client.patch(
        "/v1/me/profile", json={"allergens": None, "marketing_consent": None}, headers=auth("customer")
    )
    assert r.status_code == 200, r.text
    address = {
        "label": "Home",
        "line1": "5 Bisola Durosinmi-Etti Drive",
        "area": "Lekki Phase 1",
        "location": {"lat": 6.441, "lng": 3.46},
    }
    for _ in range(20):
        assert (
            await client.post("/v1/me/addresses", json=address, headers=auth("customer2"))
        ).status_code == 201
    r = await client.put("/v1/me/addresses/brand-new-id", json=address, headers=auth("customer2"))
    assert r.status_code == 422  # the limit holds for a new id sent with PUT too
    first = (await client.get("/v1/me/addresses", headers=auth("customer2"))).json()[0]["id"]
    assert (
        await client.put(f"/v1/me/addresses/{first}", json=address, headers=auth("customer2"))
    ).status_code == 200


def test_checking_a_payment_every_two_seconds_is_never_refused(monkeypatch) -> None:
    """The app and the website poll /v1/payments/verify every 2 s while the payment page is open (~10 min)."""
    from gudmeal_api.security import rate_limit

    now = [1000.0]
    monkeypatch.setattr(rate_limit.time, "monotonic", lambda: now[0])
    capacity, refill = rate_limit.LIMITS["payment_verify"]
    limiter = RateLimiter()
    for _ in range(300):  # 10 minutes
        limiter.check("payment_verify:cust-1", capacity=capacity, refill_per_second=refill)
        now[0] += 2.0
    for _ in range(capacity):  # a burst still runs out
        limiter.check("payment_verify:cust-1", capacity=capacity, refill_per_second=refill)
    with pytest.raises(RateLimited):
        limiter.check("payment_verify:cust-1", capacity=capacity, refill_per_second=refill)
