"""Fixes from the money audit: split exposure, Paystack refund events, vouchers, refund repair, staff guards,
reconciliation and limits."""

from __future__ import annotations

import hashlib
import hmac
import json
from datetime import UTC, datetime, timedelta

import httpx
from sqlalchemy import select, text

from conftest import PRINCIPALS, auth, idem
from gudmeal_api.errors import PaymentProviderError
from gudmeal_api.ledger.tables import PaymentRecord, RefundRecord
from gudmeal_api.payments.paystack import PaystackProvider
from gudmeal_api.services import orders as orders_mod

SK = "sk_test_unit_only"
SHOP = "r-jollof-junction"


async def refunds(container, order_id: str) -> list[RefundRecord]:
    async with container.db.session() as s:
        return list(
            (await s.execute(select(RefundRecord).where(RefundRecord.order_id == order_id))).scalars()
        )


async def staff_move(client, order_id: str, to: str, who: str = "ops", **extra):
    return await client.post(
        f"/v1/admin/orders/{order_id}/transition",
        json={"to": to, "reason": "Staff decision", **extra},
        headers=auth(who),
    )


# ------------------------------------------------------------------------------------------- split exposure
async def test_a_shop_past_its_limit_for_money_paid_ahead_is_not_split(flow, client, container):
    business = (
        await client.post("/v1/partner/business", json={"restaurant_id": SHOP}, headers=auth("owner"))
    ).json()
    await client.put(
        f"/v1/partner/business/{business['id']}/bank",
        json={"bank_code": "058", "account_number": "0123456789"},
        headers=auth("owner"),
    )
    first = await flow.paid_order()
    share = (await container.repos.orders.get(first["id"])).settlement.restaurant_earning_kobo
    container.payments.split_exposure_limit = share  # one unfinished split order is all this shop may have
    second = await flow.paid_order()
    async with container.db.session() as s:
        rows = {
            p.order_id: p.split_amount_kobo
            for p in (await s.execute(select(PaymentRecord))).scalars()
            if p.status == "succeeded"
        }
    assert rows[first["id"]] == share and rows[second["id"]] == 0


# ------------------------------------------------------------------------------------------- Paystack refunds
class FakePaystack:
    """Paystack's HTTP contract, as far as a card payment and its refund need it."""

    def __init__(self) -> None:
        self.amounts: dict[str, int] = {}
        self.refund_times_out = False

    def __call__(self, request: httpx.Request) -> httpx.Response:
        path = request.url.path
        if path == "/transaction/initialize":
            body = json.loads(request.content)
            self.amounts[body["reference"]] = int(body["amount"])
            data = {"authorization_url": "https://checkout.paystack.com/x", "reference": body["reference"]}
            return httpx.Response(200, json={"status": True, "data": data})
        if path.startswith("/transaction/verify/"):
            ref = path.rsplit("/", 1)[1]
            data = {"id": 4099, "status": "success", "reference": ref, "amount": self.amounts[ref]}
            return httpx.Response(200, json={"status": True, "data": {**data, "currency": "NGN"}})
        if path == "/refund":
            if self.refund_times_out:
                raise httpx.ReadTimeout("no answer", request=request)
            return httpx.Response(200, json={"status": True, "data": {"id": 77, "status": "pending"}})
        return httpx.Response(404, json={"status": False, "message": "not found"})


async def paystack_event(client, event: str, data: dict):
    body = json.dumps({"event": event, "data": data}).encode()
    signature = hmac.new(SK.encode(), body, hashlib.sha512).hexdigest()
    return await client.post(
        "/v1/webhooks/paystack", content=body, headers={"x-paystack-signature": signature}
    )


async def paid_by_paystack(flow, client, container, fake: FakePaystack) -> tuple[dict, str]:
    http = httpx.AsyncClient(transport=httpx.MockTransport(fake))
    container.payments.providers["paystack"] = PaystackProvider(SK, http=http)
    order = await flow.order()
    r = await client.post(
        f"/v1/orders/{order['id']}/checkout",
        json={"provider": "paystack"},
        headers={**auth("customer"), **idem()},
    )
    assert r.status_code == 200, r.text
    ref = r.json()["reference"]
    r = await paystack_event(client, "charge.success", {"id": 4099, "reference": ref})
    assert r.status_code == 200 and (await flow.get(order["id"]))["status"] == "submitted_to_restaurant"
    return order, ref


def refund_event(ref: str, amount: int, status: str) -> dict:
    """The shape Paystack sends: the payment's reference and the amount, no id of the refund."""
    return {
        "status": status,
        "transaction_reference": ref,
        "refund_reference": "132013318360" if status == "processed" else None,
        "amount": str(amount),
        "currency": "NGN",
        "processor": "mpgs_zen",
        "customer": {"first_name": "Ada", "last_name": "Obi", "email": "ada@example.com"},
        "integration": 463433,
        "domain": "test",
    }


async def test_paystack_refund_events_finish_the_refund(flow, client, container):
    order, ref = await paid_by_paystack(flow, client, container, FakePaystack())
    total = order["breakdown"]["total_kobo"]
    await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    assert [r.status for r in await refunds(container, order["id"])] == ["processing"]
    assert (
        await paystack_event(client, "refund.pending", refund_event(ref, total, "pending"))
    ).status_code == 200
    assert (await flow.get(order["id"]))["status"] == "refund_pending"
    wrong = await paystack_event(client, "refund.processed", refund_event(ref, total - 1, "processed"))
    assert wrong.status_code == 200 and (await flow.get(order["id"]))["status"] == "refund_pending"
    r = await paystack_event(
        client,
        "refund.processed",
        refund_event(ref, total, "processed") | {"refund_reference": "132013318361"},
    )
    assert r.status_code == 200
    final = await flow.get(order["id"])
    assert final["status"] == "refunded" and final["refund_total_kobo"] == total


async def test_a_refund_the_provider_did_not_answer_stays_processing(flow, client, container):
    fake = FakePaystack()
    order, ref = await paid_by_paystack(flow, client, container, fake)
    fake.refund_times_out = True
    await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    (refund,) = await refunds(container, order["id"])
    assert refund.status == "processing" and "no answer" in refund.decision_note
    failed = await paystack_event(
        client, "refund.failed", refund_event(ref, order["breakdown"]["total_kobo"], "failed")
    )
    assert failed.status_code == 200
    assert [r.status for r in await refunds(container, order["id"])] == ["failed"]


async def test_finance_can_try_a_failed_refund_again(flow, client, container, monkeypatch):
    order = await flow.paid_order()
    real = container.sandbox.refund

    async def refuse(**_):
        raise PaymentProviderError("Insufficient balance")

    monkeypatch.setattr(container.sandbox, "refund", refuse)
    await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    (refund,) = await refunds(container, order["id"])
    assert refund.status == "failed" and (await flow.get(order["id"]))["status"] == "refund_pending"
    monkeypatch.setattr(container.sandbox, "refund", real)
    again = await container.payments.retry_refund(PRINCIPALS["finance"], refund.id)
    assert again["status"] == "succeeded" and (await flow.get(order["id"]))["status"] == "refunded"
    try:
        await container.payments.retry_refund(PRINCIPALS["finance"], refund.id)
    except Exception as exc:
        assert "Only a failed refund" in str(exc)
    else:
        raise AssertionError("a refund that succeeded must not be sent again")


# ------------------------------------------------------------------------------------------- vouchers
async def test_a_voucher_is_counted_when_the_order_is_made_and_given_back_if_it_comes_to_nothing(
    flow, client, container
):
    r = await client.put(
        "/v1/admin/vouchers/ONCE10",
        json={"code": "ONCE10", "kind": "fixed", "value": 50_000, "usage_limit": 1, "per_customer_limit": 1},
        headers=auth("admin"),
    )
    assert r.status_code == 200, r.text
    held = await flow.order(voucher="ONCE10")
    assert held["breakdown"]["discount_kobo"] == 50_000

    async def quote_again(who: str = "customer"):
        body = {
            "restaurant_id": SHOP,
            "lines": [{"item_id": f"{SHOP}-drink-0", "quantity": 20}],
            "fulfillment": "pickup",
            "voucher_code": "ONCE10",
        }
        return await client.post("/v1/quotes", json=body, headers=auth(who))

    blocked = await quote_again()
    assert blocked.status_code == 422 and "not paid for yet" in blocked.json()["error"]["message"]
    assert (await quote_again("customer2")).status_code == 422  # used up for everyone while it is held

    await client.post(f"/v1/orders/{held['id']}/cancel", json={}, headers=auth("customer"))
    assert (await quote_again()).status_code == 201  # given back with the unpaid order

    paid = await flow.paid_order(voucher="ONCE10")
    assert (await quote_again()).status_code == 422
    await client.post(f"/v1/orders/{paid['id']}/cancel", json={}, headers=auth("customer"))
    assert (await flow.get(paid["id"]))["status"] == "refunded"
    assert (await quote_again()).status_code == 201  # refunded in full before it was completed

    used = await flow.paid_order(voucher="ONCE10")
    await container.tasks.run_all(orders_mod.TASK_UNPAID_EXPIRY)  # paid orders are left alone
    assert (await flow.deliver(used["id"]))["status"] == "completed"
    assert (await quote_again()).status_code == 422
    assert (await container.repos.vouchers.get("ONCE10")).used_count == 1


# ------------------------------------------------------------------------------------------- the sweep
async def test_the_sweep_restarts_refunds_and_refunds_late_payments_whose_event_was_lost(
    flow, client, container, monkeypatch
):
    order = await flow.paid_order()
    late = await flow.order()
    r = await client.post(
        f"/v1/orders/{late['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    late_ref = r.json()["reference"]
    await client.post(f"/v1/orders/{late['id']}/cancel", json={}, headers=auth("customer"))
    real = container.orders.emitter.emit

    async def lost(topic: str, payload: dict) -> None:
        if topic not in ("order.refund_pending", "payment.orphaned"):
            await real(topic, payload)

    monkeypatch.setattr(container.orders.emitter, "emit", lost)
    await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    await client.post(f"/v1/dev/sandbox-checkout/{late_ref}/complete?outcome=success")
    assert (await flow.get(order["id"]))["status"] == "refund_pending"
    assert await refunds(container, order["id"]) == [] and await refunds(container, late["id"]) == []

    monkeypatch.setattr(container.orders.emitter, "emit", real)
    assert await container.orders.repair_lost_events(timedelta(seconds=-60)) == {
        "refunds_restarted": 1,
        "late_payments_refunded": 1,
    }
    assert (await flow.get(order["id"]))["status"] == "refunded"
    assert [x.status for x in await refunds(container, late["id"])] == ["succeeded"]
    assert await container.orders.repair_lost_events(timedelta(seconds=-60)) == {
        "refunds_restarted": 0,
        "late_payments_refunded": 0,
    }


async def test_the_sweep_finds_completed_orders_that_were_not_settled(flow, client, container):
    order = await flow.paid_order()
    await flow.deliver(order["id"])
    assert await container.orders.unsettled_completed(timedelta(seconds=-60)) == []
    await container.repos.orders.update(order["id"], {"settled_at": None})
    found = await container.orders.unsettled_completed(timedelta(seconds=-60))
    assert [o.id for o in found] == [order["id"]]


# ------------------------------------------------------------------------------------------- staff guards
async def test_an_order_being_refunded_cannot_be_completed_or_settled(flow, client, container):
    order = await flow.paid_order()
    r = await staff_move(client, order["id"], "refund_pending", refund_amount_kobo=1_000)
    assert r.status_code == 422 and "refunded in full" in r.json()["error"]["message"]
    assert (await staff_move(client, order["id"], "refund_pending")).status_code == 200
    (refund,) = await refunds(container, order["id"])
    assert refund.status == "requested" and refund.amount_kobo == order["breakdown"]["total_kobo"]
    r = await staff_move(client, order["id"], "completed", who="admin")
    assert r.status_code == 409 and "never completed" in r.json()["error"]["message"]
    stored = await container.orders.get(order["id"])
    assert await container.payments.settle_completed_order(stored) is False


async def test_staff_marking_a_cash_order_delivered_puts_the_cash_on_the_riders_books(
    flow, client, container
):
    from test_wallet_and_cash import accept_and_assign, checkout, complete_prepaid_order, ledger

    await complete_prepaid_order(flow, client, container)
    order = await flow.order()
    assert (await checkout(client, order["id"], "cash")).status_code == 200
    rider = await accept_and_assign(client, container, order["id"])
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    r = await staff_move(client, order["id"], "delivered")
    assert r.status_code == 200, r.text
    done = await flow.get(order["id"])
    assert done["status"] == "completed" and done["payment"]["status"] == "paid" and done["cash_collected_at"]
    uid = PRINCIPALS[rider].uid
    assert (await ledger(client))[f"receivable:rider_cash:{uid}"] == order["breakdown"]["total_kobo"]
    assert (await container.repos.riders.get(uid)).cash_held_kobo == order["breakdown"]["total_kobo"]


# ------------------------------------------------------------------------------------------- limits
async def test_checkouts_nobody_finished_are_given_up_after_a_day(flow, client, container):
    order = await flow.order()
    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    ref = r.json()["reference"]
    assert (await container.payments.reconcile_stale(timedelta(seconds=-60)))["abandoned"] == 0
    async with container.db.transaction() as s:
        await s.execute(
            text("UPDATE payment_records SET created_at = :old WHERE reference = :ref"),
            # PostgreSQL wants a real date; SQLite stores dates as this text.
            {
                "old": datetime(2020, 1, 1, tzinfo=UTC)
                if container.db.dialect == "postgresql"
                else "2020-01-01 00:00:00.000000",
                "ref": ref,
            },
        )
    assert await container.payments.reconcile_stale() == {"checked": 1, "errors": 0, "abandoned": 1}
    assert await container.payments.reconcile_stale() == {"checked": 0, "errors": 0, "abandoned": 0}


async def test_top_ups_on_their_way_count_towards_the_wallet_limit(client):
    async def start(amount: int):
        return await client.post(
            "/v1/wallet/topups", json={"amount_kobo": amount}, headers={**auth("customer"), **idem()}
        )

    for _ in range(3):
        assert (await start(10_000_000)).status_code == 201
    r = await start(50_000)
    assert r.status_code == 422 and "top-up on the way" in r.json()["error"]["message"]
    assert r.json()["error"]["details"]["max_topup_now_kobo"] == 0


async def test_publishing_prices_from_a_stale_page_is_refused(client):
    cfg = (await client.get("/v1/admin/config/pricing", headers=auth("admin"))).json()
    first = await client.put("/v1/admin/config/pricing", json=cfg, headers=auth("admin"))
    assert first.status_code == 200 and first.json()["version"] == cfg["version"] + 1
    stale = await client.put("/v1/admin/config/pricing", json=cfg, headers=auth("admin"))
    assert stale.status_code == 409 and "Reload" in stale.json()["error"]["message"]


async def test_a_signature_that_is_not_plain_text_is_refused_not_an_error(client):
    r = await client.post(
        "/v1/webhooks/local_sandbox", content=b"{}", headers={"x-sandbox-signature": "café".encode("latin-1")}
    )
    assert r.status_code == 401
