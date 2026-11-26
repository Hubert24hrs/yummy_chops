"""End-to-end order lifecycle through the HTTP API (customer → payment → restaurant → rider → settlement)."""

from __future__ import annotations

from conftest import ADDRESS, PRINCIPALS, auth, idem
from gudmeal_api.services import dispatch as dispatch_mod


async def test_full_delivery_flow(flow, client, container):
    # --- quote & order -------------------------------------------------------------------------
    quote = await flow.quote()
    b = quote["breakdown"]
    assert "settlement" not in quote
    assert b["total_kobo"] == (
        b["subtotal_kobo"]
        + b["delivery_fee_kobo"]
        + b["service_fee_kobo"]
        + b["small_order_fee_kobo"]
        + b["vat_kobo"]
        - b["discount_kobo"]
    )

    key = idem()
    r = await client.post("/v1/orders", json={"quote_id": quote["id"]}, headers={**auth("customer"), **key})
    assert r.status_code == 201
    order = r.json()
    assert order["status"] == "draft" and "settlement" not in order
    replay = await client.post(
        "/v1/orders", json={"quote_id": quote["id"]}, headers={**auth("customer"), **key}
    )
    assert replay.headers.get("Idempotent-Replayed") == "true" and replay.json()["id"] == order["id"]

    # --- checkout & payment (server-side verification) --------------------------------------------
    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 200, r.text
    checkout = r.json()
    assert checkout["amount_kobo"] == b["total_kobo"] and checkout["provider"] == "local_sandbox"
    assert checkout["authorization_url"].endswith(f"/v1/dev/sandbox-checkout/{checkout['reference']}")
    r = await client.post(f"/v1/dev/sandbox-checkout/{checkout['reference']}/complete?outcome=success")
    assert r.status_code == 303 and "reference=" in r.headers["location"]

    order = await flow.get(order["id"])
    assert order["status"] == "submitted_to_restaurant"
    assert order["payment"]["status"] == "paid"

    # --- restaurant ---------------------------------------------------------------------------------
    r = await client.get("/v1/partner/restaurants/r-jollof-junction/orders", headers=auth("owner"))
    assert [o["id"] for o in r.json()] == [order["id"]]
    partner_view = r.json()[0]
    assert "customer_phone" not in partner_view and set(partner_view["delivery_address"]) == {"area", "city"}
    assert partner_view["restaurant_earning_kobo"] > 0

    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/accept",
        json={"prep_minutes": 15},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "restaurant_accepted"

    # Dispatch offered the job to the best rider and scheduled the offer timeout.
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    assert len(offers) == 1 and offers[0].status == "offered"
    assert any(path == dispatch_mod.TASK_OFFER_TIMEOUT for path, _, _ in container.tasks.tasks)
    rider_name = {
        "demo-rider-1": "rider1",
        "demo-rider-2": "rider2",
        "demo-rider-3": "rider3",
        "demo-rider-4": "rider4",
    }[offers[0].rider_id]

    r = await client.get("/v1/rider/offers", headers=auth(rider_name))
    assert [o["id"] for o in r.json()] == [offers[0].id]
    r = await client.post(f"/v1/rider/offers/{offers[0].id}/accept", headers=auth(rider_name))
    assert r.status_code == 200, r.text
    rider_view = r.json()
    assert rider_view["status"] == "rider_assigned" and rider_view["audience"] == "rider"
    assert "breakdown" not in rider_view and rider_view["rider_pay_kobo"] > 0

    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/ready", headers=auth("owner")
    )
    assert r.status_code == 200 and r.json()["ready_at"]
    assert (await flow.get(order["id"]))["status"] == "rider_assigned"

    # --- rider delivery with OTP ---------------------------------------------------------------------
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider_name))
    ).status_code == 200
    r = await client.post("/v1/rider/location", json={"lat": 6.443, "lng": 3.465}, headers=auth(rider_name))
    assert r.status_code == 204
    tracking = (await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth("customer"))).json()
    assert tracking["rider_location"]["lat"] == 6.443 and tracking["eta_minutes"] >= 1
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/in-transit", headers=auth(rider_name))
    ).status_code == 200

    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    assert (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth(rider_name))).status_code == 404
    wrong = "0000" if codes["delivery_code"] != "0000" else "1111"
    r = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver", json={"code": wrong}, headers=auth(rider_name)
    )
    assert r.status_code == 422 and r.json()["error"]["message"] == "Incorrect code"
    r = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver",
        json={"code": codes["delivery_code"]},
        headers=auth(rider_name),
    )
    assert r.status_code == 200, r.text

    final = await flow.get(order["id"])
    assert final["status"] == "completed" and final["settled_at"]
    rider = await container.repos.riders.get(offers[0].rider_id)
    assert rider.active_order_ids == [] and rider.completed_deliveries == 1

    # --- money: ledger balanced, payables correct ---------------------------------------------------
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    tb = ledger["trial_balance"]
    assert tb["debits_kobo"] == tb["credits_kobo"]
    balances = {a["account"]: a["balance_kobo"] for a in ledger["accounts"]}
    full = (await client.get(f"/v1/admin/orders/{order['id']}", headers=auth("admin"))).json()
    settlement = full["order"]["settlement"]
    assert balances["cash:local_sandbox"] == b["total_kobo"]
    assert balances["liability:customer_funds"] == 0
    assert balances["liability:restaurant:r-jollof-junction"] == settlement["restaurant_earning_kobo"]
    assert balances[f"liability:rider:{offers[0].rider_id}"] == settlement["rider_pay_kobo"]
    assert balances["revenue:commission"] == settlement["commission_kobo"]
    assert [e["kind"] for e in full["ledger"]].count("order_settlement") >= 2

    # --- review ---------------------------------------------------------------------------------
    r = await client.post(
        f"/v1/orders/{order['id']}/review",
        json={"food_rating": 5, "delivery_rating": 4, "comment": "Smoky!"},
        headers=auth("customer"),
    )
    assert r.status_code == 201
    r = await client.post(
        f"/v1/orders/{order['id']}/review", json={"food_rating": 1}, headers=auth("customer")
    )
    assert r.status_code == 409
    restaurant = await container.repos.restaurants.get("r-jollof-junction")
    assert restaurant.rating_count == 1241

    events = (await client.get(f"/v1/orders/{order['id']}/events", headers=auth("customer"))).json()
    assert [e["to_status"] for e in events] == [
        "draft",
        "pending_payment",
        "paid",
        "submitted_to_restaurant",
        "restaurant_accepted",
        "rider_assigned",
        "picked_up",
        "in_transit",
        "delivered",
        "completed",
    ]


async def test_order_visibility_is_isolated(flow, client):
    order = await flow.order()
    for who in ("customer2", "other_owner", "rider1"):
        r = await client.get(f"/v1/orders/{order['id']}", headers=auth(who))
        assert r.status_code == 404, who
    assert (await client.get(f"/v1/orders/{order['id']}", headers=auth("support"))).status_code == 200
    r = await client.post(
        f"/v1/partner/restaurants/r-suya-lane/orders/{order['id']}/accept",
        json={"prep_minutes": 5},
        headers=auth("other_owner"),
    )
    assert r.status_code == 404


async def test_pickup_order_handover(flow, client, container):
    order = await flow.paid_order(fulfillment="pickup")
    assert order["breakdown"]["delivery_fee_kobo"] == 0
    base = f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}"
    await client.post(f"{base}/accept", json={"prep_minutes": 10}, headers=auth("owner"))
    assert (
        await container.repos.assignments.find(where=[("order_id", "==", order["id"])]) == []
    )  # no rider for pickup
    assert (await client.post(f"{base}/ready", headers=auth("owner"))).json()["status"] == "ready_for_pickup"
    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    r = await client.post(f"{base}/handover", json={"code": codes["pickup_code"]}, headers=auth("owner"))
    assert r.status_code == 200 and r.json()["status"] == "completed"
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert ledger["trial_balance"]["debits_kobo"] == ledger["trial_balance"]["credits_kobo"]


async def test_customer_cancels_unpaid_order(flow, client):
    order = await flow.order()
    r = await client.post(
        f"/v1/orders/{order['id']}/cancel", json={"reason": "Changed my mind"}, headers=auth("customer")
    )
    assert r.status_code == 200 and r.json()["status"] == "cancelled"
    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 409


async def test_quote_cannot_be_used_after_price_change(flow, client, container):
    quote = await flow.quote()
    await container.repos.items.update("jj-party-jollof", {"price_kobo": 700_000})
    r = await client.post(
        "/v1/orders", json={"quote_id": quote["id"]}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 409 and r.json()["error"]["code"] == "price_changed"


async def test_quote_owned_by_customer(flow, client):
    quote = await flow.quote()
    r = await client.post(
        "/v1/orders", json={"quote_id": quote["id"]}, headers={**auth("customer2"), **idem()}
    )
    assert r.status_code == 404


async def test_shops_deliver_anywhere_in_their_city_but_not_to_another(client):
    async def quote(location: dict) -> object:
        return await client.post(
            "/v1/quotes",
            headers=auth("customer"),
            json={
                "restaurant_id": "r-jollof-junction",
                "fulfillment": "delivery",
                "delivery_address": {**ADDRESS, "location": location},
                "lines": [{"item_id": "jj-dodo", "quantity": 1}],
            },
        )

    ikeja = await quote({"lat": 6.6018, "lng": 3.3515})  # ~19 km from the Lekki kitchen, still Lagos
    assert ikeja.status_code == 201, ikeja.text
    enugu = await quote({"lat": 6.4402, "lng": 7.4994})  # another city
    assert enugu.status_code == 409 and enugu.json()["error"]["code"] == "out_of_delivery_area"


async def test_voucher_applies_once_per_customer(flow, client):
    order = await flow.paid_order(voucher="WELCOME500")
    assert order["breakdown"]["discount_kobo"] == 50_000
    r = await client.post(
        "/v1/quotes",
        headers=auth("customer"),
        json={
            "restaurant_id": "r-jollof-junction",
            "fulfillment": "delivery",
            "delivery_address": ADDRESS,
            "voucher_code": "WELCOME500",
            "lines": [{"item_id": "jj-ofada", "quantity": 1}],
        },
    )
    assert r.status_code == 422 and r.json()["error"]["code"] == "voucher_invalid"


async def test_the_rider_can_reach_the_customer_only_while_delivering(flow, client, container):
    # After accepting, the rider sees how to reach the customer: the checkout number, else the account's number.
    order = await flow.paid_order()
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/accept",
        json={"prep_minutes": 10},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200, r.text
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    offer = next(o for o in offers if o.status == "offered")
    rider = next(name for name, p in PRINCIPALS.items() if p.uid == offer.rider_id)
    assert (await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))).status_code == 200

    async def rider_view(active: bool = True) -> dict:
        r = await client.get(f"/v1/rider/deliveries?active={str(active).lower()}", headers=auth(rider))
        assert r.status_code == 200, r.text
        return next(o for o in r.json() if o["id"] == order["id"])

    job = await rider_view()
    assert job["customer_name"] == "Ada Obi"
    assert job["delivery_address"]["line1"] == ADDRESS["line1"]
    assert job["delivery_address"]["contact_phone"] == ADDRESS["contact_phone"]

    # No number on the address: the account's own number is used.
    await container.repos.orders.update(
        order["id"],
        {"delivery_address": {**ADDRESS, "contact_phone": None}, "customer_phone": "+2348099990000"},
    )
    assert (await rider_view())["delivery_address"]["contact_phone"] == "+2348099990000"

    # Once delivered, the job in the rider's history no longer shows the customer's number.
    await container.repos.orders.update(order["id"], {"delivery_address": ADDRESS})
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    ).status_code == 200
    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    done = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver",
        json={"code": codes["delivery_code"]},
        headers=auth(rider),
    )
    assert done.status_code == 200, done.text
    assert (await rider_view(active=False))["delivery_address"]["contact_phone"] is None


async def test_a_delivery_order_needs_a_phone_for_the_rider(client):
    """A guest has no phone on their account: the order must carry one (owner, 2026-11-26)."""
    no_phone = {k: v for k, v in ADDRESS.items() if k != "contact_phone"}
    body = {
        "restaurant_id": "r-jollof-junction",
        "fulfillment": "delivery",
        "delivery_address": no_phone,
        "lines": [{"item_id": "jj-dodo", "quantity": 1}],
    }
    q = (await client.post("/v1/quotes", headers=auth("customer2"), json=body)).json()
    r = await client.post(
        "/v1/orders", json={"quote_id": q["id"], "channel": "app"}, headers={**auth("customer2"), **idem()}
    )
    assert r.status_code == 422 and "phone number" in r.json()["error"]["message"]
    r = await client.post(
        "/v1/orders",
        json={"quote_id": q["id"], "channel": "app", "contact_phone": "0803 000 0000"},
        headers={**auth("customer2"), **idem()},
    )
    assert r.status_code == 201, r.text
    assert r.json()["delivery_address"]["contact_phone"] == "0803 000 0000"
