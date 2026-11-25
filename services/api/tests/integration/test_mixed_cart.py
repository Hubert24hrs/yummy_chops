"""Mixed cart (ADR-0030): items from several shops, one order per shop, ONE payment for all of them."""

from __future__ import annotations

from sqlalchemy import select

from conftest import auth, idem
from gudmeal_api.ledger.tables import PaymentRecord

PHARMACY = "p-carefirst"
PHARMACY_LINES = [{"item_id": "cf-vitamin-c-20", "quantity": 2}]


async def balances(client) -> dict[str, int]:
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert ledger["trial_balance"]["debits_kobo"] == ledger["trial_balance"]["credits_kobo"]
    return {a["account"]: a["balance_kobo"] for a in ledger["accounts"]}


async def two_orders(flow, who: str = "customer") -> tuple[dict, dict]:
    meal = await flow.order(who)
    pills = await flow.order(who, restaurant_id=PHARMACY, lines=PHARMACY_LINES)
    return meal, pills


async def pay_all(client, ids: list[str], provider: str | None = None, who: str = "customer", key=None):
    body: dict = {"order_ids": ids}
    if provider:
        body["provider"] = provider
    return await client.post("/v1/checkouts", json=body, headers={**auth(who), **(key or idem())})


async def test_one_card_payment_pays_an_order_per_shop(flow, client, container):
    meal, pills = await two_orders(flow)
    total = meal["breakdown"]["total_kobo"] + pills["breakdown"]["total_kobo"]
    before = await balances(client)
    key = idem()
    r = await pay_all(client, [meal["id"], pills["id"]], key=key)
    assert r.status_code == 200, r.text
    co = r.json()
    assert (
        co["amount_kobo"] == total
        and co["authorization_url"]
        and co["order_ids"] == [meal["id"], pills["id"]]
    )
    assert [o["amount_kobo"] for o in co["orders"]] == [
        meal["breakdown"]["total_kobo"],
        pills["breakdown"]["total_kobo"],
    ]
    for o in (meal, pills):
        waiting = await flow.get(o["id"])
        assert waiting["status"] == "pending_payment" and waiting["payment"]["reference"] == co["reference"]
    again = await pay_all(client, [meal["id"], pills["id"]], key=key)  # the same request twice: one checkout
    assert again.json()["reference"] == co["reference"]

    r = await client.post(f"/v1/dev/sandbox-checkout/{co['reference']}/complete?outcome=success")
    assert r.status_code == 303, r.text
    for o in (meal, pills):
        paid = await flow.get(o["id"])
        assert paid["status"] == "submitted_to_restaurant" and paid["payment"]["status"] == "paid"
        payments = (await client.get(f"/v1/orders/{o['id']}/payments", headers=auth("customer"))).json()
        rows = payments["items"] if isinstance(payments, dict) else payments
        assert [(p["amount_kobo"], p["status"]) for p in rows] == [
            (o["breakdown"]["total_kobo"], "succeeded")
        ]
    after = await balances(client)
    assert after["cash:local_sandbox"] - before.get("cash:local_sandbox", 0) == total
    async with container.db.session() as s:
        shares = list(
            (await s.execute(select(PaymentRecord).where(PaymentRecord.parent_id.is_not(None)))).scalars()
        )
    assert sorted(p.order_id for p in shares) == sorted([meal["id"], pills["id"]])

    # Each order then goes on by itself: the kitchen's order is delivered and settled.
    done = await flow.deliver(meal["id"])
    assert done["status"] == "completed"
    assert (await flow.get(pills["id"]))["status"] == "submitted_to_restaurant"
    await balances(client)


async def test_one_order_of_the_cart_is_refunded_on_its_own(flow, client, container):
    meal, pills = await two_orders(flow)
    co = (await pay_all(client, [meal["id"], pills["id"]])).json()
    await client.post(f"/v1/dev/sandbox-checkout/{co['reference']}/complete?outcome=success")

    r = await client.post(f"/v1/orders/{pills['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 200, r.text
    refunded = await flow.get(pills["id"])
    assert refunded["status"] == "refunded"
    assert refunded["refund_total_kobo"] == pills["breakdown"]["total_kobo"]
    assert (await flow.get(meal["id"]))["status"] == "submitted_to_restaurant"
    # The gateway is asked to refund part of the ONE charge it knows.
    sandbox = container.payments.providers["local_sandbox"]
    assert sandbox.refunds[-1] == {
        "reference": co["reference"],
        "amount_kobo": pills["breakdown"]["total_kobo"],
    }
    b = await balances(client)
    assert b["liability:customer_funds"] == meal["breakdown"]["total_kobo"]


async def test_the_wallet_pays_the_whole_cart_at_once(flow, client):
    meal, pills = await two_orders(flow)
    total = meal["breakdown"]["total_kobo"] + pills["breakdown"]["total_kobo"]
    r = await pay_all(client, [meal["id"], pills["id"]], "wallet")
    assert r.status_code == 422 and "too low" in r.text  # nothing in the wallet yet: nothing is paid
    assert (await flow.get(meal["id"]))["status"] == "pending_payment"

    top = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": total + 100_000}, headers={**auth("customer"), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{top.json()['reference']}/complete?outcome=success")
    r = await pay_all(client, [meal["id"], pills["id"]], "wallet")
    assert r.status_code == 200, r.text
    assert r.json()["payment_status"] == "succeeded" and r.json()["authorization_url"] is None
    assert [o["status"] for o in r.json()["orders"]] == ["submitted_to_restaurant"] * 2
    wallet = (await client.get("/v1/wallet", headers=auth("customer"))).json()
    assert wallet["balance_kobo"] == 100_000
    await balances(client)


async def test_only_the_customers_own_unpaid_orders(flow, client):
    meal, pills = await two_orders(flow)
    other = await flow.order("customer2")
    r = await pay_all(client, [meal["id"], other["id"]])
    assert r.status_code == 404
    paid = await flow.paid_order()
    r = await pay_all(client, [meal["id"], paid["id"]])
    assert r.status_code in (409, 422), r.text
    assert (await pay_all(client, [])).status_code == 422
    # One order is an ordinary checkout.
    r = await pay_all(client, [pills["id"]])
    assert (
        r.status_code == 200
        and r.json()["order_id"] == pills["id"]
        and r.json()["order_ids"] == [pills["id"]]
    )
