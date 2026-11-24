"""Discovery, RBAC, onboarding, admin, dispatch edge cases, internal endpoints, meal planning."""

from __future__ import annotations

from conftest import LEKKI, _p, auth, idem
from gudmeal_api.services import dispatch as dispatch_mod


async def test_discovery_and_search(client):
    r = await client.get("/v1/restaurants", params=LEKKI)
    assert r.status_code == 200
    cards = r.json()
    # 10 Lagos restaurants; beauty shops (vertical=beauty) and Enugu merchants are not in the food list near Lekki
    assert len(cards) == 10 and all(c["distance_km"] is not None for c in cards)
    assert {c["vertical"] for c in cards} == {"food"} and {c["city"] for c in cards} == {"lagos"}
    assert cards[0]["is_featured"]
    detail = (await client.get("/v1/restaurants/r-jollof-junction", params=LEKKI)).json()
    assert detail["sections"][0]["items"] and "r-jollof-junction-protein" in detail["option_groups"]
    found = (await client.get("/v1/search", params={"q": "jollof"})).json()
    assert {i["item"]["id"] for i in found["items"]} >= {"jj-party-jollof", "gb-jollof-quinoa"}
    prefix = (await client.get("/v1/search", params={"q": "shaw"})).json()
    assert any(i["item"]["id"] == "sr-chicken" for i in prefix["items"])
    assert (await client.get("/v1/restaurants/does-not-exist")).status_code == 404
    cfg = (await client.get("/v1/config/public")).json()
    assert "local_sandbox" in cfg["payment_providers"] and cfg["features"]["ai_concierge"] is True


async def test_authentication_required(client):
    assert (await client.get("/v1/me")).status_code == 401
    assert (await client.get("/v1/me", headers={"Authorization": "Bearer nope"})).status_code == 401
    me = (await client.get("/v1/me", headers=auth("owner"))).json()
    assert me["restaurant_roles"] == {"r-jollof-junction": "owner"}


async def test_rbac_on_admin_endpoints(client):
    for path in ("/v1/admin/overview", "/v1/admin/ledger", "/v1/admin/payments", "/v1/admin/config/pricing"):
        assert (await client.get(path, headers=auth("customer"))).status_code == 403, path
    assert (await client.get("/v1/admin/ledger", headers=auth("support"))).status_code == 403
    assert (await client.get("/v1/admin/ledger", headers=auth("finance"))).status_code == 200
    assert (await client.get("/v1/admin/overview", headers=auth("ops"))).status_code == 200
    r = await client.put("/v1/admin/users/cust-2/roles", json={"roles": ["super_admin"]}, headers=auth("ops"))
    assert r.status_code == 403  # privilege escalation blocked


async def test_kitchen_staff_cannot_edit_menu_but_can_toggle_availability(client):
    base = "/v1/partner/restaurants/r-jollof-junction"
    r = await client.patch(
        f"{base}/items/jj-dodo/availability", json={"available": False}, headers=auth("kitchen")
    )
    assert r.status_code == 200 and r.json()["is_available"] is False
    r = await client.post(
        f"{base}/items",
        headers=auth("kitchen"),
        json={"category_id": "rice", "name": "Coconut rice", "price_kobo": 500_000},
    )
    assert r.status_code == 403
    r = await client.post(
        f"{base}/items",
        headers=auth("owner"),
        json={"category_id": "rice", "name": "Coconut Rice", "price_kobo": 500_000, "tags": ["rice"]},
    )
    assert r.status_code == 201
    found = (await client.get("/v1/search", params={"q": "coconut"})).json()
    assert any(i["item"]["name"] == "Coconut Rice" for i in found["items"])
    r = await client.post(
        "/v1/partner/restaurants/r-suya-lane/items",
        headers=auth("owner"),
        json={"category_id": "grills", "name": "Hack", "price_kobo": 100},
    )
    assert r.status_code == 403


async def test_unavailable_item_blocks_quote(client):
    await client.patch(
        "/v1/partner/restaurants/r-jollof-junction/items/jj-dodo/availability",
        json={"available": False},
        headers=auth("owner"),
    )
    r = await client.post(
        "/v1/quotes",
        headers=auth("customer"),
        json={
            "restaurant_id": "r-jollof-junction",
            "fulfillment": "pickup",
            "lines": [{"item_id": "jj-dodo", "quantity": 1}],
        },
    )
    assert r.status_code == 409 and r.json()["error"]["code"] == "item_unavailable"


async def test_restaurant_onboarding_approval_grants_roles(client, container):
    application = {
        "business_name": "Ofada Hub",
        "cac_number": "RC123456",
        "contact_name": "Kemi",
        "contact_phone": "+2348022222222",
        "address": "1 Allen Avenue",
        "area": "Ikeja",
        "location": {"lat": 6.6, "lng": 3.35},
        "cuisines": ["Nigerian"],
        "bank_name": "Test Bank",
        "bank_account_name": "Ofada Hub Ltd",
        "bank_account_last4": "1234",
        "document_paths": ["applications/cust-2/cac.pdf"],
    }
    r = await client.post("/v1/applications/restaurant", json=application, headers=auth("customer2"))
    assert r.status_code == 201
    app_id = r.json()["id"]
    assert (
        await client.post("/v1/applications/restaurant", json=application, headers=auth("customer2"))
    ).status_code == 409
    bad = {**application, "document_paths": ["applications/someone-else/cac.pdf"]}
    assert (
        await client.post("/v1/applications/restaurant", json=bad, headers=auth("customer"))
    ).status_code == 422

    assert (
        await client.post(
            f"/v1/admin/applications/{app_id}/decision", json={"approve": True}, headers=auth("finance")
        )
    ).status_code == 403
    r = await client.post(
        f"/v1/admin/applications/{app_id}/decision",
        json={"approve": True, "reason": "Docs ok"},
        headers=auth("ops"),
    )
    assert r.status_code == 200
    rid = r.json()["created_entity_id"]
    claims = await container.identity.get_claims("cust-2")
    assert claims["restaurant_roles"] == {rid: "owner"} and "restaurant_owner" in claims["roles"]
    restaurant = await container.repos.restaurants.get(rid)
    assert restaurant.owner_uid == "cust-2" and restaurant.is_accepting_orders is False
    assert restaurant.status == "pending"

    # Customers cannot find (or order from) the new shop until it has a menu and opens for orders.
    listed = (await client.get("/v1/restaurants", params={"q": "Ofada Hub"})).json()
    assert all(r["id"] != rid for r in listed)
    assert (await client.get(f"/v1/restaurants/{rid}")).status_code == 404
    verifier = getattr(container.verifier, "_fallback", container.verifier)  # under the channel-token layer
    verifier.principals["new_owner"] = _p("cust-2", "restaurant_owner", restaurants={rid: "owner"})
    base = f"/v1/partner/restaurants/{rid}"
    r = await client.put(f"{base}/accepting", json={"accepting": True}, headers=auth("new_owner"))
    assert r.status_code == 422 and "at least one available item" in r.json()["error"]["message"]
    r = await client.post(
        f"{base}/items",
        json={"category_id": "mains", "name": "Ofada rice & ayamase", "price_kobo": 350_000},
        headers=auth("new_owner"),
    )
    assert r.status_code == 201, r.text
    r = await client.put(f"{base}/accepting", json={"accepting": True}, headers=auth("new_owner"))
    assert r.status_code == 200 and r.json()["status"] == "active" and r.json()["is_accepting_orders"] is True
    assert (await client.get(f"/v1/restaurants/{rid}")).status_code == 200


async def test_rider_application_and_availability(client, container):
    r = await client.post(
        "/v1/applications/rider",
        headers=auth("customer2"),
        json={
            "full_name": "Bayo Rider",
            "phone": "+2348033333333",
            "vehicle": "motorcycle",
            "plate_number": "LAG-123-AB",
        },
    )
    app_id = r.json()["id"]
    # Signing up gives the rider app at once; the team verifies the rider on their KYC (test_rider_kyc.py).
    assert "rider" in (await container.identity.get_claims("cust-2"))["roles"]
    r = await client.post(
        f"/v1/admin/applications/{app_id}/decision", json={"approve": True}, headers=auth("admin")
    )
    assert r.status_code == 409, r.text  # no KYC submitted yet
    r = await client.put("/v1/rider/availability", json={"online": True}, headers=auth("rider1"))
    assert r.status_code == 200 and r.json()["is_online"] is True
    await client.put(
        "/v1/admin/riders/demo-rider-1/status",
        json={"status": "suspended", "reason": "Docs expired"},
        headers=auth("ops"),
    )
    r = await client.put("/v1/rider/availability", json={"online": True}, headers=auth("rider1"))
    assert r.status_code == 403


async def test_offer_timeout_moves_to_next_rider_and_manual_dispatch(flow, client, container):
    order = await flow.paid_order()
    await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/accept",
        json={"prep_minutes": 20},
        headers=auth("owner"),
    )
    first = (await container.repos.assignments.find(where=[("order_id", "==", order["id"])]))[0]
    await container.repos.assignments.update(first.id, {"expires_at": first.offered_at})  # let it lapse
    await container.tasks.run_all(dispatch_mod.TASK_OFFER_TIMEOUT)
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    statuses = sorted((o.rider_id, o.status) for o in offers)
    assert ("expired" in [s for _, s in statuses]) and len(offers) == 2
    second = next(o for o in offers if o.status == "offered")
    assert second.rider_id != first.rider_id

    # Ops overrides with a manual assignment to a third rider.
    names = {
        "demo-rider-1": "rider1",
        "demo-rider-2": "rider2",
        "demo-rider-3": "rider3",
        "demo-rider-4": "rider4",
    }
    manual = next(uid for uid in names if uid not in (first.rider_id, second.rider_id))
    r = await client.post(
        f"/v1/admin/orders/{order['id']}/assign-rider",
        headers=auth("ops"),
        json={"rider_uid": manual, "reason": "Rider requested by restaurant"},
    )
    assert r.status_code == 200 and r.json()["rider_id"] == manual
    r = await client.post(f"/v1/rider/offers/{second.id}/accept", headers=auth(names[second.rider_id]))
    assert r.status_code == 409  # order already has a rider


async def test_internal_endpoints_require_credentials(client):
    assert (await client.post("/internal/jobs/sweep")).status_code == 403
    r = await client.post("/internal/jobs/sweep", headers={"X-Internal-Token": "test-internal-secret"})
    assert r.status_code == 200 and "settled" in r.json()


async def test_meal_plan_endpoint(client):
    r = await client.post(
        "/v1/meal-plans",
        headers=auth("customer"),
        json={"budget_kobo": 1_000_000, "party_size": 2, "location": LEKKI},
    )
    assert r.status_code == 200
    plans = r.json()["plans"]
    assert plans and all(p["breakdown"]["total_kobo"] <= 1_000_000 for p in plans)
    # A plan's cart lines can be quoted directly and the totals match.
    plan = plans[0]
    r = await client.post(
        "/v1/quotes",
        headers=auth("customer"),
        json={
            "restaurant_id": plan["restaurant_id"],
            "lines": plan["cart_lines"],
            "fulfillment": "delivery",
            "delivery_address": {"line1": "5 Admiralty Road", "location": LEKKI},
        },
    )
    assert r.status_code == 201 and r.json()["breakdown"]["total_kobo"] == plan["breakdown"]["total_kobo"]


async def test_admin_overview_and_analytics(flow, client):
    await flow.paid_order()
    overview = (await client.get("/v1/admin/overview", headers=auth("ops"))).json()
    assert overview["orders_today"] >= 1 and overview["riders_online"] == 6  # 4 Lagos + 2 Enugu demo riders
    analytics = (await client.get("/v1/admin/analytics?days=7", headers=auth("admin"))).json()
    assert len(analytics["series"]) == 7
    partner = (
        await client.get("/v1/partner/restaurants/r-jollof-junction/analytics", headers=auth("owner"))
    ).json()
    assert partner["orders_total"] >= 1
    assert (
        await client.get("/v1/partner/restaurants/r-jollof-junction/analytics", headers=auth("kitchen"))
    ).status_code == 403


async def test_pricing_config_versioned_and_audited(client):
    cfg = (await client.get("/v1/admin/config/pricing", headers=auth("admin"))).json()
    cfg["service_fee_bps"] = 600
    r = await client.put("/v1/admin/config/pricing", json=cfg, headers=auth("admin"))
    assert r.status_code == 200 and r.json()["version"] == cfg["version"] + 1
    assert (await client.put("/v1/admin/config/pricing", json=cfg, headers=auth("ops"))).status_code == 403
    audit = (await client.get("/v1/admin/audit?resource_type=config", headers=auth("admin"))).json()
    assert audit[0]["action"] == "config.pricing_updated"


async def test_idempotency_key_rules(flow, client):
    quote = await flow.quote()
    r = await client.post("/v1/orders", json={"quote_id": quote["id"]}, headers=auth("customer"))
    assert r.status_code == 422  # header required
    key = idem()
    await client.post("/v1/orders", json={"quote_id": quote["id"]}, headers={**auth("customer"), **key})
    other = await flow.quote()
    r = await client.post("/v1/orders", json={"quote_id": other["id"]}, headers={**auth("customer"), **key})
    assert r.status_code == 409 and r.json()["error"]["code"] == "idempotency_conflict"


async def test_profile_addresses_and_export(client):
    r = await client.patch(
        "/v1/me/profile", json={"allergens": ["Peanuts"], "dietary": ["halal"]}, headers=auth("customer")
    )
    assert r.json()["allergens"] == ["peanuts"]
    r = await client.post(
        "/v1/me/addresses",
        headers=auth("customer"),
        json={"line1": "5 Admiralty Road", "location": LEKKI, "label": "Work"},
    )
    assert r.status_code == 201
    assert len((await client.get("/v1/me/addresses", headers=auth("customer"))).json()) == 1
    assert len((await client.get("/v1/me/addresses", headers=auth("customer2"))).json()) == 0
    export = (await client.get("/v1/me/export", headers=auth("customer"))).json()
    assert export["profile"]["uid"] == "cust-1"
