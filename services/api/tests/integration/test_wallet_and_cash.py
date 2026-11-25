"""Phase 2 money features end to end: Yummy Chops wallet, pay on delivery, vendor cash-on-delivery, failover."""

from __future__ import annotations

from datetime import timedelta

from sqlalchemy import select

from conftest import auth, idem
from gudmeal_api.errors import PaymentProviderError
from gudmeal_api.ledger.tables import PaymentRecord
from gudmeal_api.services import orders as orders_mod

RIDERS = {f"demo-rider-{n}": f"rider{n}" for n in range(1, 7)}
SELLER_STOP = {
    "name": "Ada Obi",
    "phone": "+2348022222222",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": {"lat": 6.4410, "lng": 3.4600},
}
BUYER_STOP = {
    "name": "Tunde Bello",
    "phone": "+2348033333333",
    "line1": "7 Ajose Adeogun Street",
    "area": "Victoria Island",
    "location": {"lat": 6.4281, "lng": 3.4219},
}


async def ledger(client) -> dict[str, int]:
    data = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert data["trial_balance"]["debits_kobo"] == data["trial_balance"]["credits_kobo"]
    return {a["account"]: a["balance_kobo"] for a in data["accounts"]}


async def wallet(client, who: str = "customer") -> dict:
    r = await client.get("/v1/wallet", headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def top_up(client, amount_kobo: int, who: str = "customer") -> dict:
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": amount_kobo}, headers={**auth(who), **idem()}
    )
    assert r.status_code == 201, r.text
    r2 = await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    assert r2.status_code == 303
    return r.json()


async def checkout(client, order_id: str, provider: str | None = None, who: str = "customer"):
    body = {"provider": provider} if provider else {}
    return await client.post(f"/v1/orders/{order_id}/checkout", json=body, headers={**auth(who), **idem()})


async def accept_and_assign(client, container, order_id: str, *, merchant: bool = True) -> str:
    """Merchant accepts (food), the offered rider accepts. Returns the rider's principal name."""
    if merchant:
        r = await client.post(
            f"/v1/partner/restaurants/r-jollof-junction/orders/{order_id}/accept",
            json={"prep_minutes": 10},
            headers=auth("kitchen"),
        )
        assert r.status_code == 200, r.text
    offers = await container.repos.assignments.find(where=[("order_id", "==", order_id)])
    offer = next(o for o in offers if o.status == "offered")
    rider = RIDERS[offer.rider_id]
    r = await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    assert r.status_code == 200, r.text
    return rider


async def deliver(client, order_id: str, rider: str, *, cash: bool = False):
    codes = (await client.get(f"/v1/orders/{order_id}/codes", headers=auth("customer"))).json()
    return await client.post(
        f"/v1/rider/deliveries/{order_id}/deliver",
        json={"code": codes["delivery_code"], "cash_collected": cash},
        headers=auth(rider),
    )


async def complete_prepaid_order(flow, client, container) -> dict:
    """Pay online and deliver one order (unlocks pay on delivery for the customer)."""
    order = await flow.paid_order()
    rider = await accept_and_assign(client, container, order["id"])
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    ).status_code == 200
    r = await deliver(client, order["id"], rider)
    assert r.status_code == 200, r.text
    return await flow.get(order["id"])


async def payment_rows(container, order_id: str) -> list[PaymentRecord]:
    async with container.db.session() as s:
        return list(
            (await s.execute(select(PaymentRecord).where(PaymentRecord.order_id == order_id))).scalars()
        )


# ---------------------------------------------------------------------------------------- wallet
async def test_wallet_topup_one_tap_pay_and_instant_refund(flow, client, container):
    empty = await wallet(client)
    assert empty["balance_kobo"] == 0 and empty["enabled"] and empty["transactions"] == []
    assert empty["limits"] == {
        "min_topup_kobo": 50_000,
        "max_topup_kobo": 10_000_000,
        "max_balance_kobo": 30_000_000,
    }
    assert empty["seller"] is None and empty["refund_to_wallet"] is False

    for bad in (49_999, 10_000_001):
        r = await client.post(
            "/v1/wallet/topups", json={"amount_kobo": bad}, headers={**auth("customer"), **idem()}
        )
        assert r.status_code == 422, r.text

    order = await flow.order()
    total = order["breakdown"]["total_kobo"]
    started = await top_up(client, total + 150_000)
    assert started["provider"] == "local_sandbox" and started["reference"].startswith("YC-TOPUP-")
    w = await wallet(client)
    assert w["balance_kobo"] == total + 150_000
    assert w["transactions"][0] | {"created_at": None, "id": None} == {
        "id": None,
        "kind": "wallet_topup",
        "reference": started["reference"],
        "order_id": None,
        "description": "Wallet top-up",
        "created_at": None,
        "direction": "in",
        "amount_kobo": total + 150_000,
    }
    # The top-up never touches order money and is verified with the gateway like any payment.
    r = await client.post(
        "/v1/payments/verify", json={"reference": started["reference"]}, headers=auth("customer")
    )
    assert r.json()["status"] == "succeeded" and r.json()["purpose"] == "wallet_topup"
    books = await ledger(client)
    assert (
        books["liability:wallet:cust-1"] == total + 150_000 and books["cash:local_sandbox"] == total + 150_000
    )

    options = (await client.get(f"/v1/orders/{order['id']}/payment-options", headers=auth("customer"))).json()
    methods = {m["id"]: m for m in options["methods"]}
    assert methods["wallet"]["available"] and methods["wallet"]["short_by_kobo"] == 0
    assert methods["card"]["available"] and methods["card"]["provider"] == "local_sandbox"
    assert not methods["cash"]["available"] and "first order" in methods["cash"]["reason"]
    assert (
        await client.get(f"/v1/orders/{order['id']}/payment-options", headers=auth("customer2"))
    ).status_code == 404

    r = await checkout(client, order["id"], "wallet")
    assert r.status_code == 200, r.text
    paid = r.json()
    assert paid["provider"] == "wallet" and paid["status"] == "submitted_to_restaurant"
    assert paid["payment_status"] == "succeeded" and paid["amount_kobo"] == total
    view = await flow.get(order["id"])
    assert view["payment"]["provider"] == "wallet" and view["payment"]["status"] == "paid"
    w = await wallet(client)
    assert w["balance_kobo"] == 150_000
    assert w["transactions"][0]["direction"] == "out" and w["transactions"][0]["kind"] == "wallet_payment"

    # Cancel before the kitchen accepts: the refund lands in the wallet at once (no gateway involved).
    r = await client.post(
        f"/v1/orders/{order['id']}/cancel", json={"reason": "Changed my mind"}, headers=auth("customer")
    )
    assert r.status_code == 200, r.text
    assert (await flow.get(order["id"]))["status"] == "refunded"
    assert (await wallet(client))["balance_kobo"] == total + 150_000
    assert container.sandbox.refunds == []
    refunds = (await client.get("/v1/admin/refunds", headers=auth("finance"))).json()
    assert [(x["destination"], x["status"]) for x in refunds] == [("wallet", "succeeded")]
    books = await ledger(client)
    assert books["liability:customer_funds"] == 0 and books["liability:wallet:cust-1"] == total + 150_000


async def test_wallet_balance_checks_and_limits(flow, client, container):
    order = await flow.order()
    total = order["breakdown"]["total_kobo"]
    r = await checkout(client, order["id"], "wallet")
    assert r.status_code == 422
    assert r.json()["error"]["details"] == {"balance_kobo": 0, "needed_kobo": total, "short_by_kobo": total}
    # The refusal leaves the order payable by card.
    assert (await flow.get(order["id"]))["status"] == "pending_payment"
    assert (await checkout(client, order["id"])).status_code == 200

    container.wallet.max_balance = 1_500_000
    await top_up(client, 1_000_000)
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": 1_000_000}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 422 and r.json()["error"]["details"]["max_topup_now_kobo"] == 500_000


async def test_card_refunds_can_go_to_the_wallet_instead(flow, client, container):
    r = await client.put("/v1/wallet/settings", json={"refund_to_wallet": True}, headers=auth("customer"))
    assert r.status_code == 200 and (await wallet(client))["refund_to_wallet"] is True
    order = await flow.paid_order()
    total = order["breakdown"]["total_kobo"]
    r = await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 200
    assert (await flow.get(order["id"]))["status"] == "refunded"
    assert (await wallet(client))["balance_kobo"] == total
    assert container.sandbox.refunds == []  # the card was not refunded: the money is wallet credit now
    books = await ledger(client)
    assert books["cash:local_sandbox"] == total and books["liability:wallet:cust-1"] == total


async def test_a_second_payment_for_the_same_order_is_refunded(flow, client, container):
    order = await flow.order()
    total = order["breakdown"]["total_kobo"]
    await top_up(client, total)
    card = (await checkout(client, order["id"])).json()  # customer opens card checkout, then pays by wallet
    assert (await checkout(client, order["id"], "wallet")).status_code == 200
    r = await client.post(f"/v1/dev/sandbox-checkout/{card['reference']}/complete?outcome=success")
    assert r.status_code == 303
    view = await flow.get(order["id"])
    assert view["status"] == "submitted_to_restaurant" and view["payment"]["provider"] == "wallet"
    assert container.sandbox.refunds == [{"reference": card["reference"], "amount_kobo": total}]
    books = await ledger(client)
    assert books["cash:local_sandbox"] == total  # topped up once; the duplicate card charge went back
    assert books["liability:customer_funds"] == total  # exactly one payment is held for the order


# ---------------------------------------------------------------------------------- pay on delivery
async def test_pay_on_delivery_end_to_end_with_rider_cash_and_hand_in(flow, client, container):
    first = await flow.order()
    r = await checkout(client, first["id"], "cash")
    assert r.status_code == 422 and "first order" in r.json()["error"]["message"]
    assert (await flow.get(first["id"]))["status"] == "draft"  # refused before anything changed

    await complete_prepaid_order(flow, client, container)
    order = await flow.order()
    total = order["breakdown"]["total_kobo"]
    options = (await client.get(f"/v1/orders/{order['id']}/payment-options", headers=auth("customer"))).json()
    assert {m["id"]: m["available"] for m in options["methods"]}["cash"] is True

    r = await checkout(client, order["id"], "cash")
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "submitted_to_restaurant" and r.json()["provider"] == "cash"
    view = await flow.get(order["id"])
    assert view["payment"]["provider"] == "cash" and view["payment"]["status"] == "pending"
    assert (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()[
        "delivery_code"
    ]
    assert [(p.provider, p.status) for p in await payment_rows(container, order["id"])] == [
        ("cash", "pending")
    ]
    assert (
        "liability:customer_funds" not in await ledger(client)
        or (await ledger(client))["liability:customer_funds"] == 0
    )  # nothing is on the books until the rider takes the cash

    rider = await accept_and_assign(client, container, order["id"])
    rider_view = await flow.get(order["id"], rider)
    assert rider_view["payment_method"] == "cash" and rider_view["collect_cash_kobo"] == total
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    ).status_code == 200
    r = await deliver(client, order["id"], rider, cash=False)
    assert r.status_code == 422 and r.json()["error"]["details"] == {"cash_to_collect_kobo": total}
    r = await deliver(client, order["id"], rider, cash=True)
    assert r.status_code == 200, r.text

    done = await flow.get(order["id"])
    assert done["status"] == "completed" and done["settled_at"] and done["payment"]["status"] == "paid"
    assert done["cash_collected_at"]
    rider_uid = next(uid for uid, name in RIDERS.items() if name == rider)
    books = await ledger(client)
    assert books[f"receivable:rider_cash:{rider_uid}"] == total
    assert books["liability:customer_funds"] == 0
    assert (await container.repos.riders.get(rider_uid)).cash_held_kobo == total

    earnings = (await client.get("/v1/rider/earnings", headers=auth(rider))).json()
    assert earnings["cash_held_kobo"] == total
    assert earnings["available_kobo"] == max(0, earnings["balance_kobo"] - total)

    cash = (await client.get("/v1/admin/cash", headers=auth("finance"))).json()
    assert [(x["rider_id"], x["cash_held_kobo"]) for x in cash["riders"]] == [(rider_uid, total)]
    assert cash["totals"]["cash_with_riders_kobo"] == total
    assert (await client.get("/v1/admin/cash", headers=auth("customer"))).status_code == 403

    url = f"/v1/admin/riders/{rider_uid}/cash-remittances"
    too_much = {"amount_kobo": total + 1, "method": "bank_transfer", "reference": "TRF-1"}
    assert (await client.post(url, json=too_much, headers={**auth("finance"), **idem()})).status_code == 422
    no_ref = {"amount_kobo": total, "method": "cash_deposit"}
    assert (await client.post(url, json=no_ref, headers={**auth("finance"), **idem()})).status_code == 422
    r = await client.post(
        url,
        json={"amount_kobo": total, "method": "bank_transfer", "reference": "TRF-1"},
        headers={**auth("finance"), **idem()},
    )
    assert r.status_code == 201 and r.json()["cash_held_kobo"] == 0
    books = await ledger(client)
    assert books[f"receivable:rider_cash:{rider_uid}"] == 0 and books["cash:bank"] == total
    assert (await container.repos.riders.get(rider_uid)).cash_held_kobo == 0
    audit = (await client.get("/v1/admin/audit?resource_type=rider", headers=auth("admin"))).json()
    assert any(a["action"] == "rider_cash.remitted" for a in audit)


async def test_cash_can_be_deducted_from_rider_earnings(flow, client, container):
    await complete_prepaid_order(flow, client, container)
    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 200
    rider = await accept_and_assign(client, container, order["id"])
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    assert (await deliver(client, order["id"], rider, cash=True)).status_code == 200
    rider_uid = next(uid for uid, name in RIDERS.items() if name == rider)
    earned = (await ledger(client)).get(f"liability:rider:{rider_uid}", 0)
    assert earned > 0
    url = f"/v1/admin/riders/{rider_uid}/cash-remittances"
    r = await client.post(
        url,
        json={"amount_kobo": earned + 1, "method": "earnings_offset"},
        headers={**auth("finance"), **idem()},
    )
    assert r.status_code == 422  # can't deduct more than we owe the rider
    r = await client.post(
        url, json={"amount_kobo": earned, "method": "earnings_offset"}, headers={**auth("finance"), **idem()}
    )
    assert r.status_code == 201, r.text
    books = await ledger(client)
    assert books[f"liability:rider:{rider_uid}"] == 0
    assert books[f"receivable:rider_cash:{rider_uid}"] == order["breakdown"]["total_kobo"] - earned


async def test_unpaid_cash_orders_are_cancelled_not_refunded(flow, client, container):
    await complete_prepaid_order(flow, client, container)

    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 200
    r = await client.post(
        f"/v1/orders/{order['id']}/cancel", json={"reason": "Ordered twice"}, headers=auth("customer")
    )
    assert r.status_code == 200 and r.json()["status"] == "cancelled"
    assert [(p.provider, p.status) for p in await payment_rows(container, order["id"])] == [
        ("cash", "abandoned")
    ]

    second = await flow.order()
    assert (await checkout(client, second["id"], "cash")).status_code == 200
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{second['id']}/reject",
        json={"reason": "Out of rice"},
        headers=auth("owner"),
    )
    assert r.status_code == 200 and r.json()["status"] == "cancelled"

    third = await flow.order()
    assert (await checkout(client, third["id"], "cash")).status_code == 200
    await container.orders.restaurant_timeout({"order_id": third["id"]})
    assert (await flow.get(third["id"]))["status"] == "cancelled"

    assert (await client.get("/v1/admin/refunds", headers=auth("finance"))).json() == []
    assert (await ledger(client))["liability:customer_funds"] == 0


async def test_pay_on_delivery_eligibility_rules(flow, client, container):
    await complete_prepaid_order(flow, client, container)
    active = await flow.order()
    assert (await checkout(client, active["id"], "cash")).status_code == 200
    another = await flow.order()
    r = await checkout(client, another["id"], "cash")
    assert r.status_code == 422 and "already have" in r.json()["error"]["message"]
    await client.post(f"/v1/orders/{active['id']}/cancel", json={}, headers=auth("customer"))

    container.cash.max_order_kobo = another["breakdown"]["total_kobo"] - 1
    r = await checkout(client, another["id"], "cash")
    assert r.status_code == 422 and "up to" in r.json()["error"]["message"]
    container.cash.max_order_kobo = 2_500_000_000

    r = await client.put("/v1/admin/flags/pay_on_delivery", json={"enabled": False}, headers=auth("admin"))
    assert r.status_code == 200
    r = await checkout(client, another["id"], "cash")
    assert r.status_code == 422 and "not available" in r.json()["error"]["message"]
    assert (await client.get("/v1/config/public")).json()["pay_on_delivery"]["enabled"] is False
    await client.put("/v1/admin/flags/pay_on_delivery", json={"enabled": True}, headers=auth("admin"))

    url = "/v1/admin/customers/cust-1/pay-on-delivery"
    block = {"blocked": True, "reason": "Refused a cash delivery"}
    assert (await client.put(url, json=block, headers=auth("customer"))).status_code == 403
    assert (await client.put(url, json=block, headers=auth("support"))).status_code == 200
    r = await checkout(client, another["id"], "cash")
    assert r.status_code == 422 and "turned off" in r.json()["error"]["message"]
    r = await client.put(
        url, json={"blocked": False, "reason": "Spoke to the customer"}, headers=auth("support")
    )
    assert r.status_code == 200
    audit = (await client.get("/v1/admin/audit?resource_type=customer", headers=auth("admin"))).json()
    assert [a["action"] for a in audit][:2] == [
        "customer.pay_on_delivery_allowed",
        "customer.pay_on_delivery_blocked",
    ]
    assert (await checkout(client, another["id"], "cash")).status_code == 200


async def test_staff_cannot_cancel_paid_orders_or_refund_unpaid_ones(flow, client, container):
    paid = await flow.paid_order()
    r = await client.post(
        f"/v1/admin/orders/{paid['id']}/transition",
        json={"to": "cancelled", "reason": "Customer asked"},
        headers=auth("ops"),
    )
    assert r.status_code == 409 and "refunded rather than cancelled" in r.json()["error"]["message"]

    await container.repos.orders.update(
        paid["id"], {"status": "completed", "completed_at": paid["created_at"]}
    )
    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 200
    r = await client.post(
        f"/v1/admin/orders/{order['id']}/transition",
        json={"to": "refund_pending", "reason": "Goodwill"},
        headers=auth("ops"),
    )
    assert r.status_code == 409 and "cancel it instead" in r.json()["error"]["message"]
    r = await client.post(
        f"/v1/admin/orders/{order['id']}/transition",
        json={"to": "cancelled", "reason": "Customer unreachable"},
        headers=auth("ops"),
    )
    assert r.status_code == 200 and r.json()["status"] == "cancelled"


async def test_dispatch_skips_riders_carrying_too_much_cash(flow, client, container):
    await complete_prepaid_order(flow, client, container)
    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 200
    riders = await container.repos.riders.find()
    for r in riders:
        await container.repos.riders.update(r.uid, {"cash_held_kobo": container.dispatch.cash_limit})
    await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/accept",
        json={"prep_minutes": 10},
        headers=auth("kitchen"),
    )
    assert await container.repos.assignments.find(where=[("order_id", "==", order["id"])]) == []
    for r in riders:
        await container.repos.riders.update(r.uid, {"cash_held_kobo": 0})
    await container.dispatch.retry({"order_id": order["id"]})
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    assert len(offers) == 1 and offers[0].status == "offered"


async def test_reconcile_and_settlement_leave_cash_alone(flow, client, container):
    await complete_prepaid_order(flow, client, container)
    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 200
    assert await container.payments.reconcile_stale(older_than=timedelta(seconds=-60)) == {
        "checked": 0,
        "errors": 0,
        "abandoned": 0,
    }

    # A completed order whose cash was never recorded is not settled (no revenue without money received).
    unpaid = await container.orders.get(order["id"])
    assert await container.payments.settle_completed_order(unpaid) is False


# ---------------------------------------------------------------------------- vendor cash-on-delivery
async def test_seller_cash_on_delivery_collection_payout_and_wallet(client, container):
    payload = {"pickup": SELLER_STOP, "dropoff": BUYER_STOP, "size": "small", "category": "clothing"}
    r = await client.post(
        "/v1/parcels/quotes", json={**payload, "cod_amount_kobo": 10_000_001}, headers=auth("customer")
    )
    assert r.status_code == 422 and "limit" in r.json()["error"]["message"]
    r = await client.post(
        "/v1/parcels/quotes", json={**payload, "cod_amount_kobo": 2_500_000}, headers=auth("customer")
    )
    assert r.status_code == 201, r.text
    quote = r.json()
    b = quote["breakdown"]
    assert b["cod_fee_kobo"] == 38_000 and quote["details"]["cod_amount_kobo"] == 2_500_000
    assert (
        b["total_kobo"] == b["delivery_fee_kobo"] + b["service_fee_kobo"] + b["cod_fee_kobo"] + b["vat_kobo"]
    )

    r = await client.post(
        "/v1/parcels", json={"quote_id": quote["id"]}, headers={**auth("customer"), **idem()}
    )
    order = r.json()
    assert order["parcel"]["cod_amount_kobo"] == 2_500_000
    ref = (await checkout(client, order["id"])).json()["reference"]
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")

    rider = await accept_and_assign(client, container, order["id"], merchant=False)
    rider_view = (await client.get(f"/v1/orders/{order['id']}", headers=auth(rider))).json()
    assert rider_view["payment_method"] == "prepaid" and rider_view["collect_cash_kobo"] == 2_500_000
    assert rider_view["parcel"]["cod_amount_kobo"] == 2_500_000
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    assert (await deliver(client, order["id"], rider)).status_code == 422
    assert (await deliver(client, order["id"], rider, cash=True)).status_code == 200

    rider_uid = next(uid for uid, name in RIDERS.items() if name == rider)
    books = await ledger(client)
    assert books["liability:vendor:cust-1"] == 2_500_000
    assert books[f"receivable:rider_cash:{rider_uid}"] == 2_500_000
    assert books["revenue:cod_fee"] == 38_000 and books["liability:customer_funds"] == 0

    seller = (await wallet(client))["seller"]
    assert seller == {
        "cod_balance_kobo": 2_500_000,
        "pending_payouts_kobo": 0,
        "available_kobo": 2_500_000,
        "min_payout_kobo": 100_000,
    }
    balance = (await client.get("/v1/seller/balance", headers=auth("customer"))).json()
    assert (
        balance["transactions"][0]["direction"] == "in"
        and balance["transactions"][0]["amount_kobo"] == 2_500_000
    )

    bank = {"bank_name": "GTBank", "account_number": "0123456789", "account_name": "Ada Obi"}
    for bad, status in (
        ({"amount_kobo": 99_999}, 422),
        ({"amount_kobo": 2_500_001}, 422),
        ({"amount_kobo": 1, "account_number": "123"}, 422),
    ):
        r = await client.post(
            "/v1/seller/payouts", json={**bank, **bad}, headers={**auth("customer"), **idem()}
        )
        assert r.status_code == status, r.text
    r = await client.post(
        "/v1/seller/payouts", json={**bank, "amount_kobo": 2_000_000}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 201, r.text
    payout = r.json()
    assert payout["status"] == "requested" and payout["account_number"] == "******6789"

    r = await client.post(
        "/v1/seller/move-to-wallet", json={"amount_kobo": 500_001}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 422 and r.json()["error"]["details"]["available_kobo"] == 500_000
    r = await client.post(
        "/v1/seller/move-to-wallet", json={"amount_kobo": 500_000}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 200 and r.json()["wallet_balance_kobo"] == 500_000

    assert (await client.get("/v1/admin/seller-payouts", headers=auth("customer"))).status_code == 403
    queue = (await client.get("/v1/admin/seller-payouts?status=requested", headers=auth("finance"))).json()
    assert [(p["id"], p["account_number"]) for p in queue] == [(payout["id"], "0123456789")]
    url = f"/v1/admin/seller-payouts/{payout['id']}/decision"
    assert (await client.post(url, json={"approve": True}, headers=auth("finance"))).status_code == 422
    r = await client.post(
        url, json={"approve": True, "bank_reference": "NIP-778899"}, headers=auth("finance")
    )
    assert r.status_code == 200 and r.json()["status"] == "paid"
    books = await ledger(client)
    assert books["liability:vendor:cust-1"] == 0 and books["liability:wallet:cust-1"] == 500_000
    assert (
        books["cash:bank"] == -2_000_000
    )  # paid out; the rider still has to hand in the ₦25,000 they collected


# -------------------------------------------------------------------------------------- failover
class DownGateway:
    name = "paystack"

    def __init__(self) -> None:
        self.calls = 0

    async def initialize(self, **_: object) -> None:
        self.calls += 1
        raise PaymentProviderError("Paystack is unreachable")


async def test_checkout_fails_over_to_the_backup_gateway(flow, client, container):
    down = DownGateway()
    container.payments.providers["paystack"] = down  # type: ignore[assignment]
    container.payments.default_provider = "paystack"
    container.payments.failover_provider = "local_sandbox"

    order = await flow.order()
    r = await checkout(client, order["id"])
    assert r.status_code == 200, r.text
    assert r.json()["provider"] == "local_sandbox" and r.json()["failover_from"] == "paystack"
    rows = await payment_rows(container, order["id"])
    assert sorted((p.provider, p.status) for p in rows) == [
        ("local_sandbox", "pending"),
        ("paystack", "failed"),
    ]
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    assert (await flow.get(order["id"]))["status"] == "submitted_to_restaurant"

    # A customer who picked a gateway explicitly gets its error instead of a silent switch.
    explicit = await flow.order()
    r = await checkout(client, explicit["id"], "paystack")
    assert r.status_code == 502

    # After three failures in a row the broken gateway is skipped until it recovers.
    topup = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": 100_000}, headers={**auth("customer"), **idem()}
    )
    assert topup.status_code == 201 and topup.json()["failover_from"] == "paystack"
    assert down.calls == 3 and container.payments.health.degraded("paystack")
    later = await flow.order()
    r = await checkout(client, later["id"])
    assert (
        r.status_code == 200 and r.json()["provider"] == "local_sandbox" and "failover_from" not in r.json()
    )
    assert down.calls == 3


async def test_unpaid_order_expiry_still_cancels_after_a_failed_cash_attempt(flow, client, container):
    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 422
    await checkout(client, order["id"])
    await container.orders.expire_unpaid({"order_id": order["id"]})
    assert (await flow.get(order["id"]))["status"] == "cancelled"
    assert orders_mod.TASK_UNPAID_EXPIRY in [path for path, _, _ in container.tasks.tasks]
