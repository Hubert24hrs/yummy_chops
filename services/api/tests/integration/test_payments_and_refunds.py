"""Payment security: signatures, duplicates, amount mismatches, orphaned payments, refunds and approvals."""

from __future__ import annotations

import json

from sqlalchemy import select, text

from conftest import auth, idem, make_container
from gudmeal_api.ledger.tables import LedgerEntry, PaymentRecord
from gudmeal_api.services import orders as orders_mod


async def balances(client) -> dict[str, int]:
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert ledger["trial_balance"]["debits_kobo"] == ledger["trial_balance"]["credits_kobo"]
    return {a["account"]: a["balance_kobo"] for a in ledger["accounts"]}


async def checkout(client, order_id: str) -> str:
    r = await client.post(f"/v1/orders/{order_id}/checkout", json={}, headers={**auth("customer"), **idem()})
    assert r.status_code == 200, r.text
    return r.json()["reference"]


async def test_webhook_with_bad_signature_is_rejected(flow, client, container):
    order = await flow.order()
    ref = await checkout(client, order["id"])
    body = json.dumps({"event": "charge.success", "data": {"id": "x", "reference": ref}}).encode()
    r = await client.post(
        "/v1/webhooks/local_sandbox", content=body, headers={"x-sandbox-signature": "forged"}
    )
    assert r.status_code == 401
    assert (await flow.get(order["id"]))["status"] == "pending_payment"


async def test_client_cannot_fake_success_without_provider(flow, client):
    order = await flow.order()
    ref = await checkout(client, order["id"])
    r = await client.post("/v1/payments/verify", json={"reference": ref}, headers=auth("customer"))
    assert r.status_code == 200 and r.json()["status"] == "pending"
    assert (await flow.get(order["id"]))["status"] == "pending_payment"
    assert (
        await client.post("/v1/payments/verify", json={"reference": ref}, headers=auth("customer2"))
    ).status_code == 404


async def test_duplicate_webhooks_post_once(flow, client, container):
    order = await flow.order()
    ref = await checkout(client, order["id"])
    body, signature, _ = container.sandbox.complete(ref, success=True)
    for expected in ("processed", "duplicate", "duplicate"):
        r = await client.post(
            "/v1/webhooks/local_sandbox", content=body, headers={"x-sandbox-signature": signature}
        )
        assert r.status_code == 200 and r.json()["status"] == expected
    r = await client.post("/v1/payments/verify", json={"reference": ref}, headers=auth("customer"))
    assert r.json()["status"] == "succeeded"
    async with container.db.session() as s:
        captured = (
            await s.execute(
                text("SELECT count(*) FROM financial_transactions WHERE kind = 'payment_captured'")
            )
        ).scalar()
    assert captured == 1
    assert (await flow.get(order["id"]))["status"] == "submitted_to_restaurant"


async def test_amount_mismatch_flags_payment_and_does_not_fulfil(flow, client, container):
    order = await flow.order()
    ref = await checkout(client, order["id"])
    container.sandbox.charges[ref].amount_kobo -= 100  # provider reports a different amount
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")
    async with container.db.session() as s:
        rec = await s.scalar(select(PaymentRecord).where(PaymentRecord.reference == ref))
    assert rec.status == "flagged" and "amount_mismatch" in rec.failure_reason
    assert (await flow.get(order["id"]))["status"] == "pending_payment"
    overview = (await client.get("/v1/admin/overview", headers=auth("ops"))).json()
    assert overview["flagged_payments"] == 1
    audit = (await client.get("/v1/admin/audit?resource_type=payment", headers=auth("admin"))).json()
    assert audit[0]["action"] == "payment.flagged"


async def test_failed_payment_allows_retry(flow, client):
    order = await flow.order()
    ref = await checkout(client, order["id"])
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=failure")
    assert (await flow.get(order["id"]))["status"] == "pending_payment"
    ref2 = await checkout(client, order["id"])
    assert ref2 != ref
    await client.post(f"/v1/dev/sandbox-checkout/{ref2}/complete?outcome=success")
    assert (await flow.get(order["id"]))["status"] == "submitted_to_restaurant"


async def test_restaurant_rejection_refunds_in_full(flow, client):
    order = await flow.paid_order()
    total = order["breakdown"]["total_kobo"]
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/reject",
        json={},
        headers=auth("owner"),
    )
    assert r.status_code == 422  # reason required
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/reject",
        json={"reason": "Out of jollof"},
        headers=auth("owner"),
    )
    assert r.status_code == 200
    final = await flow.get(order["id"])
    assert final["status"] == "refunded" and final["refund_total_kobo"] == total
    b = await balances(client)
    assert b["liability:customer_funds"] == 0 and b["cash:local_sandbox"] == 0


async def test_customer_cancel_after_payment_before_acceptance_refunds(flow, client):
    order = await flow.paid_order()
    r = await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 200
    assert (await flow.get(order["id"]))["status"] == "refunded"
    accepted = await flow.paid_order()
    await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{accepted['id']}/accept",
        json={"prep_minutes": 10},
        headers=auth("owner"),
    )
    r = await client.post(f"/v1/orders/{accepted['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 409


async def test_restaurant_timeout_refunds(flow, client, container):
    order = await flow.paid_order()
    ran = await container.tasks.run_all(orders_mod.TASK_RESTAURANT_TIMEOUT)
    assert ran == 1
    final = await flow.get(order["id"])
    assert final["status"] == "refunded" and final["cancellation_reason"] == "restaurant_timeout"


async def test_orphaned_payment_after_expiry_is_refunded(flow, client, container):
    order = await flow.order()
    ref = await checkout(client, order["id"])
    await container.tasks.run_all(orders_mod.TASK_UNPAID_EXPIRY)  # payment still pending → order cancelled
    assert (await flow.get(order["id"]))["status"] == "cancelled"
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")  # customer pays late
    assert container.sandbox.refunds and container.sandbox.refunds[0]["reference"] == ref
    b = await balances(client)
    assert b["cash:local_sandbox"] == 0 and b["liability:customer_funds"] == 0


async def _complete_order(flow, client, container) -> dict:
    order = await flow.paid_order()
    base = f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}"
    await client.post(f"{base}/accept", json={"prep_minutes": 10}, headers=auth("owner"))
    offer = (await container.repos.assignments.find(where=[("order_id", "==", order["id"])]))[0]
    who = {
        "demo-rider-1": "rider1",
        "demo-rider-2": "rider2",
        "demo-rider-3": "rider3",
        "demo-rider-4": "rider4",
    }
    rider = who[offer.rider_id]
    await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    code = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()[
        "delivery_code"
    ]
    r = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver", json={"code": code}, headers=auth(rider)
    )
    assert r.status_code == 200, r.text
    return await flow.get(order["id"]) | {"rider": rider, "rider_uid": offer.rider_id}


async def test_missing_item_partial_refund_needs_finance_approval(flow, client, container):
    order = await _complete_order(flow, client, container)
    item = order["lines"][1]
    r = await client.post(
        "/v1/support/tickets",
        headers=auth("customer"),
        json={
            "order_id": order["id"],
            "category": "missing_item",
            "description": "The drinks were missing",
            "missing_item_ids": [item["item_id"]],
        },
    )
    assert r.status_code == 201
    ticket = r.json()
    r = await client.patch(
        f"/v1/admin/support/tickets/{ticket['id']}",
        headers=auth("support"),
        json={
            "status": "resolved",
            "resolution": "Refunding missing drinks",
            "refund_amount_kobo": item["line_total_kobo"],
            "refund_liability": "restaurant",
        },
    )
    assert r.status_code == 200, r.text
    assert (await flow.get(order["id"]))["status"] == "refund_pending"
    refunds = (await client.get("/v1/admin/refunds?status=requested", headers=auth("support"))).json()
    assert len(refunds) == 1 and refunds[0]["amount_kobo"] == item["line_total_kobo"]

    before = await balances(client)
    r = await client.post(
        f"/v1/admin/refunds/{refunds[0]['id']}/decision", json={"approve": True}, headers=auth("support")
    )
    assert r.status_code == 403  # support may request but not approve
    r = await client.post(
        f"/v1/admin/refunds/{refunds[0]['id']}/decision",
        json={"approve": True, "note": "ok"},
        headers=auth("finance"),
    )
    assert r.status_code == 200 and r.json()["status"] == "succeeded"
    final = await flow.get(order["id"])
    assert final["status"] == "partially_refunded" and final["refund_total_kobo"] == item["line_total_kobo"]
    after = await balances(client)
    key = "liability:restaurant:r-jollof-junction"
    assert before[key] - after[key] == item["line_total_kobo"]  # restaurant bears the missing item

    audit = (
        await client.get(f"/v1/admin/audit?resource_id={refunds[0]['id']}", headers=auth("admin"))
    ).json()
    assert audit[0]["action"] == "refund.approved" and audit[0]["actor_id"] == "fin-1"


async def test_ledger_rows_are_append_only(flow, client, container):
    await flow.paid_order()
    await container.audit.record(
        actor_id="t", actor_roles=[], action="test", resource_type="t", resource_id="1"
    )
    async with container.db.session() as s:
        entry = await s.scalar(select(LedgerEntry).limit(1))
        assert entry is not None
    for stmt in (
        "UPDATE ledger_entries SET amount_kobo = 1",
        "DELETE FROM ledger_entries",
        "UPDATE financial_transactions SET kind = 'x'",
        "DELETE FROM audit_events",
    ):
        try:
            async with container.db.transaction() as s:
                await s.execute(text(stmt))
        except Exception as exc:
            assert "append-only" in str(exc)
        else:
            raise AssertionError(f"{stmt} should have been rejected")


async def test_rider_payout_rules(flow, client, container):
    order = await _complete_order(flow, client, container)
    earnings = (await client.get("/v1/rider/earnings", headers=auth(order["rider"]))).json()
    assert earnings["balance_kobo"] > 0 and earnings["deliveries_completed"] == 1
    r = await client.post(
        "/v1/rider/payouts", json={"amount_kobo": 50_000}, headers={**auth(order["rider"]), **idem()}
    )
    assert r.status_code == 422  # below ₦1,000 minimum
    r = await client.post(
        "/v1/rider/payouts",
        json={"amount_kobo": earnings["balance_kobo"] + 100_000},
        headers={**auth(order["rider"]), **idem()},
    )
    assert r.status_code == 422
    assert (await client.get("/v1/rider/earnings", headers=auth("customer"))).status_code == 403


async def test_sandbox_sends_a_phone_on_the_wifi_back_to_the_app(flow, container):
    """A phone testing the app against a laptop cannot open the laptop's localhost callback: after approving it is
    told to return to the app (which verifies the payment). The laptop's own browser still gets the redirect."""
    import httpx

    from gudmeal_api.main import create_app

    app = create_app(container.settings, container=container)
    for client_ip, expect in (("192.168.1.23", 200), ("192.168.1.8", 303)):
        order = await flow.order()
        r = await flow.client.post(
            f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
        )
        ref = r.json()["reference"]
        container.sandbox.charges[ref].callback_url = "http://localhost:3000/checkout/callback"
        transport = httpx.ASGITransport(app=app, client=(client_ip, 50123))
        async with httpx.AsyncClient(transport=transport, base_url="http://192.168.1.8:8000") as http:
            r = await http.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")
        assert r.status_code == expect, (client_ip, r.status_code)
        if expect == 200:
            assert "Payment approved" in r.text and "Return to the Yummy Chops app" in r.text
        else:
            assert r.headers["location"].startswith("http://localhost:3000/checkout/callback?reference=")
        assert (await flow.get(order["id"]))["payment"]["status"] == "paid"


async def test_payment_gateways_get_an_email_that_can_receive_mail() -> None:
    # Paystack refuses special-use domains ("email must be a valid email"): the demo accounts are @yummychops.test.
    from gudmeal_api.security.rbac import Principal

    c = await make_container()
    try:
        fallback = c.settings.customer_email_fallback_domain
        assert c.payments.payer_email(Principal(uid="u1", email="ada@gmail.com")) == "ada@gmail.com"
        assert c.payments.payer_email(Principal(uid="u2")) == f"u2@{fallback}"
        for demo in (
            "customer@yummychops.test",
            "x@example",
            "y@shop.invalid",
            "z@host.local",
            "q@localhost",
        ):
            assert c.payments.payer_email(Principal(uid="demo-1", email=demo)) == f"demo-1@{fallback}", demo
    finally:
        await c.close()
