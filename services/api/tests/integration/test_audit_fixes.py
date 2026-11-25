"""Fixes from the pre-release audit of the catalogue, branches, dispatch, kitchen pins, waybills and document ids."""

from __future__ import annotations

import pytest

from conftest import PRINCIPALS, _p, auth, idem
from gudmeal_api.domain.models import RestaurantStatus, RiderStatus, Voucher
from gudmeal_api.errors import NotFound, OutOfDeliveryArea, ValidationFailed
from gudmeal_api.services.business import MAX_CLAIMS_CHARS, suspend_branches_selling
from gudmeal_api.services.waybills import WaybillService

MAIN = "r-jollof-junction"
IKEJA = {"lat": 6.6018, "lng": 3.3515}
BRANCH = {"branch_name": "Ikeja", "address": "1 Allen Avenue", "area": "Ikeja", "location": IKEJA}


def as_owner(container, name: str, restaurants: list[str]) -> None:
    """The partner dashboard refreshes the owner's sign-in token, which then lists every branch."""
    verifier = getattr(container.verifier, "_fallback", container.verifier)
    verifier.principals[name] = _p(
        "demo-owner-1", "restaurant_owner", restaurants=dict.fromkeys(restaurants, "owner")
    )


async def business_with_branch(client, container, *, open_branch: bool = True) -> tuple[str, str]:
    """Jollof Junction becomes a business with an Ikeja branch. Returns (business id, branch id)."""
    r = await client.post("/v1/partner/business", json={"restaurant_id": MAIN}, headers=auth("owner"))
    assert r.status_code == 201, r.text
    business = r.json()["id"]
    r = await client.post(f"/v1/partner/business/{business}/branches", json=BRANCH, headers=auth("owner"))
    assert r.status_code == 201, r.text
    branch = next(b for b in r.json()["branches"] if not b["main"])["restaurant_id"]
    as_owner(container, "owner_all", [MAIN, branch])
    if open_branch:
        r = await client.put(
            f"/v1/partner/restaurants/{branch}/accepting", json={"accepting": True}, headers=auth("owner_all")
        )
        assert r.status_code == 200 and r.json()["status"] == "active", r.text
        hours = (await container.repos.restaurants.get(MAIN)).opening_hours.model_dump()
        await container.repos.restaurants.update(branch, {"opening_hours": hours})
    return business, branch


async def on_a_delivery(flow, client, container) -> tuple[dict, str, str]:
    """A paid order accepted by the kitchen and by the rider it was offered to: (order, rider name, rider uid)."""
    order = await flow.paid_order()
    r = await client.post(
        f"/v1/partner/restaurants/{MAIN}/orders/{order['id']}/accept",
        json={"prep_minutes": 10},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200, r.text
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    offer = next(o for o in offers if o.status == "offered")
    rider = next(name for name, p in PRINCIPALS.items() if p.uid == offer.rider_id)
    r = await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    assert r.status_code == 200, r.text
    return order, rider, offer.rider_id


# ------------------------------------------------------------------------------------------ 1. time zones
async def test_a_bad_time_zone_is_refused_and_one_already_stored_only_closes_that_shop(client, container):
    hours = {"timezone": "Nope/Zone", "weekly": {"0": [{"open": "09:00", "close": "21:00"}]}}
    r = await client.patch(
        f"/v1/partner/restaurants/{MAIN}/settings", json={"opening_hours": hours}, headers=auth("owner")
    )
    assert r.status_code == 422 and "time zone" in r.text
    ok = await client.patch(
        f"/v1/partner/restaurants/{MAIN}/settings",
        json={"opening_hours": {**hours, "timezone": "Africa/Lagos"}},
        headers=auth("owner"),
    )
    assert ok.status_code == 200, ok.text

    await container.repos.restaurants.update(
        MAIN, {"opening_hours.timezone": "Nope/Zone"}
    )  # saved before the check
    listed = await client.get("/v1/restaurants", params={"vertical": "food", "limit": 100})
    assert listed.status_code == 200, listed.text
    card = next(c for c in listed.json() if c["id"] == MAIN)
    assert card["is_open"] is False and card["next_opening_at"] is None
    assert len(listed.json()) > 1
    assert (await client.get("/v1/discover/dishes")).status_code == 200
    assert (await client.get("/v1/search", params={"q": "jollof"})).status_code == 200


# ------------------------------------------------------------------------------------------ 2. branches in feeds
async def test_discover_and_search_show_the_branch_nearest_the_customer(client, container):
    _, branch = await business_with_branch(client, container)
    r = await client.get("/v1/discover/dishes", params={"city": "lagos", "limit": 12, **IKEJA})
    assert r.status_code == 200, r.text
    shown = {d["restaurant_id"] for s in r.json()["sections"] for d in s["dishes"]}
    assert branch in shown and MAIN not in shown  # the Ikeja branch's dishes, from the main branch's menu
    near_lekki = await client.get(
        "/v1/discover/dishes", params={"city": "lagos", "limit": 12, "lat": 6.4478, "lng": 3.4723}
    )
    shown = {d["restaurant_id"] for s in near_lekki.json()["sections"] for d in s["dishes"]}
    assert MAIN in shown and branch not in shown

    found = (await client.get("/v1/search", params={"q": "party jollof", **IKEJA})).json()["items"]
    hit = next(i for i in found if i["item"]["id"] == "jj-party-jollof")
    assert hit["restaurant_id"] == branch
    found = (await client.get("/v1/search", params={"q": "party jollof"})).json()["items"]
    assert next(i for i in found if i["item"]["id"] == "jj-party-jollof")["restaurant_id"] == MAIN

    # The dish is still found when only the branch is open to customers.
    await container.repos.restaurants.update(MAIN, {"status": RestaurantStatus.PENDING.value})
    found = (await client.get("/v1/search", params={"q": "party jollof"})).json()["items"]
    assert next(i for i in found if i["item"]["id"] == "jj-party-jollof")["restaurant_id"] == branch


# ------------------------------------------------------------------------------------------ 3. suspension
async def test_a_suspended_business_cannot_add_or_open_branches(client, container):
    business, branch = await business_with_branch(client, container, open_branch=False)
    await container.repos.restaurants.update(MAIN, {"status": RestaurantStatus.SUSPENDED.value})
    r = await client.post(
        f"/v1/partner/business/{business}/branches",
        json={**BRANCH, "branch_name": "Ikeja 2"},
        headers=auth("owner"),
    )
    assert r.status_code == 403 and "suspended" in r.json()["error"]["message"]
    r = await client.put(
        f"/v1/partner/restaurants/{branch}/accepting", json={"accepting": True}, headers=auth("owner_all")
    )
    assert r.status_code == 403 and "suspended" in r.json()["error"]["message"]
    assert (await container.repos.restaurants.get(branch)).status == RestaurantStatus.PENDING

    await container.repos.restaurants.update(MAIN, {"status": RestaurantStatus.ACTIVE.value})
    r = await client.put(
        f"/v1/partner/restaurants/{branch}/accepting", json={"accepting": True}, headers=auth("owner_all")
    )
    assert r.status_code == 200 and r.json()["status"] == "active"


async def test_suspending_the_main_branch_stops_the_open_branches_that_sell_its_menu(client, container):
    business, branch = await business_with_branch(client, container)
    r = await client.post(
        f"/v1/partner/business/{business}/branches",
        json={**BRANCH, "branch_name": "Not open yet"},
        headers=auth("owner"),
    )
    pending = next(b for b in r.json()["branches"] if b["branch_name"] == "Not open yet")["restaurant_id"]

    assert await suspend_branches_selling(container.repos, MAIN) == [branch]
    assert (await container.repos.restaurants.get(branch)).status == RestaurantStatus.SUSPENDED
    assert (await container.repos.restaurants.get(pending)).status == RestaurantStatus.PENDING
    assert (await client.get(f"/v1/restaurants/{branch}")).status_code == 404
    assert await suspend_branches_selling(container.repos, MAIN) == []  # nothing left to stop


# ------------------------------------------------------------------------------------------ 4. cheaper public pages
async def test_lists_read_the_pricing_config_once_and_only_merchants_vouchers(client, container):
    await container.repos.vouchers.save(
        Voucher(code="YCP-TEST01", kind="fixed", value=100_000, customer_id="cust-1", source="points")
    )
    store = container.repos.store
    config_reads: list[str] = []
    vouchers_read: list[dict] = []
    get, query = store.get, store.query

    async def counting_get(path):
        if path == "platform_configuration/pricing":
            config_reads.append(path)
        return await get(path)

    async def recording_query(collection, **kw):
        docs = await query(collection, **kw)
        if collection == "vouchers":
            vouchers_read.extend(docs)
        return docs

    store.get, store.query = counting_get, recording_query
    r = await client.get("/v1/restaurants", params={"lat": 6.4410, "lng": 3.4600, "vertical": "all"})
    assert r.status_code == 200 and len(r.json()) > 5
    assert len(config_reads) == 1
    assert vouchers_read and all(v["restaurant_id"] and not v.get("customer_id") for v in vouchers_read)
    assert any(c["promotions"] for c in r.json())  # merchants' own promotions still show

    config_reads.clear()
    vouchers_read.clear()
    page = await client.get(f"/v1/restaurants/{MAIN}", params={"lat": 6.4410, "lng": 3.4600})
    assert page.status_code == 200 and len(config_reads) == 1
    assert vouchers_read and {v["restaurant_id"] for v in vouchers_read} == {MAIN}
    assert page.json()["restaurant"]["promotions"]


# ------------------------------------------------------------------------------------------ 5. rider location
async def test_a_rider_who_goes_offline_on_a_delivery_is_followed_until_it_ends(flow, client, container):
    order, rider, uid = await on_a_delivery(flow, client, container)
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    ).status_code == 200
    r = await client.put("/v1/rider/availability", json={"online": False}, headers=auth(rider))
    assert r.status_code == 200 and r.json()["last_location"] is not None  # kept while the delivery lasts

    ping = await client.post("/v1/rider/location", json={"lat": 6.443, "lng": 3.465}, headers=auth(rider))
    assert ping.status_code == 204, ping.text
    seen = (await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth("customer"))).json()
    assert seen["rider_location"] == {"lat": 6.443, "lng": 3.465}

    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    r = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver",
        json={"code": codes["delivery_code"]},
        headers=auth(rider),
    )
    assert r.status_code == 200, r.text
    after = await container.repos.riders.get(uid)
    assert after.last_location is None and after.last_location_at is None and after.geohash is None
    again = await client.post("/v1/rider/location", json={"lat": 6.443, "lng": 3.465}, headers=auth(rider))
    assert again.status_code == 409  # offline with no delivery: not tracked


async def test_going_offline_without_a_delivery_forgets_where_the_rider_was(flow, client, container):
    await client.put("/v1/rider/availability", json={"online": True}, headers=auth("rider2"))
    await client.post("/v1/rider/location", json={"lat": 6.43011, "lng": 3.42022}, headers=auth("rider2"))
    assert (await container.repos.riders.get("demo-rider-2")).last_location is not None
    r = await client.put("/v1/rider/availability", json={"online": False}, headers=auth("rider2"))
    assert r.status_code == 200
    stored = await container.repos.riders.get("demo-rider-2")
    assert stored.last_location is None and stored.last_location_at is None and stored.geohash is None

    # An online rider keeps only the coarse cell once their delivery ends.
    order, rider, uid = await on_a_delivery(flow, client, container)
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    await client.post("/v1/rider/location", json={"lat": 6.44313, "lng": 3.46527}, headers=auth(rider))
    assert (await container.repos.riders.get(uid)).last_location.lat == 6.44313
    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver",
        json={"code": codes["delivery_code"]},
        headers=auth(rider),
    )
    idle = await container.repos.riders.get(uid)
    assert idle.last_location is not None and idle.last_location.lat != 6.44313 and len(idle.geohash) == 6


# ------------------------------------------------------------------------------------------ 6. kitchen pin
async def test_small_pin_moves_cannot_add_up_to_a_big_one(client, container):
    path = f"/v1/partner/restaurants/{MAIN}/location"
    start = (await container.repos.restaurants.get(MAIN)).location

    def moved(steps: int) -> dict:  # each step is about 1.5 km east
        return {
            "address": "14 Admiralty Way, Lekki Phase 1",
            "location": {"lat": start.lat, "lng": round(start.lng + 0.0135 * steps, 6)},
            "confirm_pin": True,
        }

    assert (await client.put(path, json=moved(1), headers=auth("owner"))).status_code == 200
    r = await client.put(path, json=moved(2), headers=auth("owner"))  # 1.5 km again, 3 km from the start
    assert r.status_code == 403 and "2 km" in r.json()["error"]["message"]
    assert (await client.put(path, json=moved(0), headers=auth("owner"))).status_code == 200  # back is fine

    assert (
        await client.put(path, json=moved(2), headers=auth("admin"))
    ).status_code == 200  # staff verify it
    assert (
        await client.put(path, json=moved(3), headers=auth("owner"))
    ).status_code == 200  # 1.5 km from there
    assert (await client.put(path, json=moved(0), headers=auth("owner"))).status_code == 403


# ------------------------------------------------------------------------------------------ 7. bank account
async def test_only_the_owner_sets_the_bank_account_and_it_is_audited_and_announced(client, container):
    business = (
        await client.post("/v1/partner/business", json={"restaurant_id": MAIN}, headers=auth("owner"))
    ).json()["id"]
    bank = {"bank_code": "058", "account_number": "0123456789"}
    for staff in ("ops", "admin"):
        r = await client.put(f"/v1/partner/business/{business}/bank", json=bank, headers=auth(staff))
        assert r.status_code == 403 and "owner" in r.json()["error"]["message"]
    assert (await container.repos.businesses.get(business)).paystack_subaccount_code is None

    r = await client.put(f"/v1/partner/business/{business}/bank", json=bank, headers=auth("owner"))
    assert r.status_code == 200, r.text
    [entry] = [
        e
        for e in await container.audit.list(resource_type="business", resource_id=business)
        if e["action"] == "business.bank_connected"
    ]
    assert entry["actor_id"] == "demo-owner-1" and entry["details"]["bank"] == "Guaranty Trust Bank"
    assert entry["details"]["account_last4"] == "6789" and entry["details"]["account_name"]
    assert "0123456789" not in str(entry)
    notes = await container.repos.notifications.find(where=[("recipient_uid", "==", "demo-owner-1")])
    note = next(n for n in notes if n.title == "Bank account connected")
    assert "Guaranty Trust Bank" in note.body and "6789" in note.body and "0123456789" not in note.body

    await client.put(
        f"/v1/partner/business/{business}/bank",
        json={"bank_code": "044", "account_number": "0001112223"},
        headers=auth("owner"),
    )
    notes = await container.repos.notifications.find(where=[("recipient_uid", "==", "demo-owner-1")])
    assert any(n.title == "Bank account changed" and "2223" in n.body for n in notes)


# ------------------------------------------------------------------------------------------ 8. smaller items
async def test_a_staff_dispute_on_the_way_frees_the_rider(flow, client, container):
    order, rider, uid = await on_a_delivery(flow, client, container)
    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    ).status_code == 200
    assert (await container.repos.riders.get(uid)).active_order_ids == [order["id"]]
    r = await client.post(
        f"/v1/admin/orders/{order['id']}/transition",
        json={"to": "disputed", "reason": "Customer says the rider has gone the wrong way"},
        headers=auth("ops"),
    )
    assert r.status_code == 200, r.text
    assert (await container.repos.riders.get(uid)).active_order_ids == []
    notes = await container.repos.notifications.find(where=[("recipient_uid", "==", uid)])
    assert any(n.title == "Delivery stopped" for n in notes)


async def test_a_rider_suspended_after_the_offer_cannot_accept_it(flow, client, container):
    order = await flow.paid_order()
    await client.post(
        f"/v1/partner/restaurants/{MAIN}/orders/{order['id']}/accept",
        json={"prep_minutes": 10},
        headers=auth("kitchen"),
    )
    [offer] = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    rider = next(name for name, p in PRINCIPALS.items() if p.uid == offer.rider_id)
    await container.repos.riders.update(offer.rider_id, {"status": RiderStatus.SUSPENDED.value})
    r = await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    assert r.status_code == 403 and "not active" in r.json()["error"]["message"]
    assert (await container.repos.orders.get(order["id"])).rider_id is None


async def test_a_branch_that_would_not_fit_in_the_owners_sign_in_roles_is_refused_first(client, container):
    business, _ = await business_with_branch(client, container, open_branch=False)
    claims = await container.identity.get_claims("demo-owner-1")
    other_shops = {f"{n:020d}": "owner" for n in range(26)}  # shops this sign-in already manages elsewhere
    await container.identity.set_claims(
        "demo-owner-1", claims["roles"], {**claims["restaurant_roles"], **other_shops}
    )
    before = len(await container.repos.restaurants.find(where=[("business_id", "==", business)]))
    r = await client.post(
        f"/v1/partner/business/{business}/branches",
        json={**BRANCH, "branch_name": "One too many"},
        headers=auth("owner"),
    )
    assert r.status_code == 422 and "this many shops" in r.json()["error"]["message"]
    assert len(await container.repos.restaurants.find(where=[("business_id", "==", business)])) == before
    assert MAX_CLAIMS_CHARS == 1000


async def test_sample_hubs_and_carriers_cannot_be_booked_outside_local_and_test(container):
    from test_waybills import ENUGU_RECIPIENT, SENDER

    from gudmeal_api.domain.models import WaybillQuoteRequest

    assert container.waybills.sample_network_bookable is True  # ENVIRONMENT=test
    online = WaybillService(
        container.repos,
        container.orders,
        tasks=container.tasks,
        notifier=container.notifier,
        audit=container.audit,
        sample_network_bookable=False,
    )
    req = WaybillQuoteRequest(
        origin_city="lagos", destination_city="enugu", sender=SENDER, recipient=ENUGU_RECIPIENT, weight_kg=2
    )
    with pytest.raises(OutOfDeliveryArea, match="not open for booking"):
        await online.create_quote(PRINCIPALS["customer"], req)

    # Once the team saves real hubs and a real carrier for the route, it can be booked.
    net = await container.repos.get_waybill_network()
    real = net.model_copy(
        update={
            "hubs": [h.model_copy(update={"is_sample": False}) for h in net.hubs],
            "carriers": [c.model_copy(update={"is_sample": False}) for c in net.carriers],
        }
    )
    await container.repos.save_waybill_network(real)
    assert (await online.create_quote(PRINCIPALS["customer"], req)).breakdown.total_kobo > 0


# ------------------------------------------------------------------------------------------ 9. menu edits
async def test_editing_an_item_keeps_what_the_request_left_out(client, container):
    menu = (await client.get(f"/v1/partner/restaurants/{MAIN}/menu", headers=auth("owner"))).json()
    category = menu["categories"][0]["id"]
    r = await client.post(
        f"/v1/partner/restaurants/{MAIN}/items",
        json={
            "category_id": category,
            "name": "Ofada rice",
            "price_kobo": 350_000,
            "image_url": "https://example.com/ofada.jpg",
            "prep_minutes": 25,
            "position": 7,
            "description": "With ayamase",
            "tags": ["spicy"],
        },
        headers=auth("owner"),
    )
    assert r.status_code == 201, r.text
    item_id = r.json()["id"]
    path = f"/v1/partner/restaurants/{MAIN}/items/{item_id}"
    edit = {"category_id": category, "name": "Ofada rice (large)", "price_kobo": 400_000}
    assert (await client.put(path, json=edit, headers=auth("owner"))).status_code == 200
    stored = await container.repos.items.get(item_id)
    assert stored.name == "Ofada rice (large)" and stored.price_kobo == 400_000
    assert stored.image_url == "https://example.com/ofada.jpg" and stored.prep_minutes == 25
    assert stored.position == 7 and stored.description == "With ayamase" and stored.tags == ["spicy"]
    assert "ayamase" in stored.search_keywords and "large" in stored.search_keywords

    # Sending a field, even as null, still changes it.
    assert (
        await client.put(path, json={**edit, "image_url": None}, headers=auth("owner"))
    ).status_code == 200
    assert (await container.repos.items.get(item_id)).image_url is None


# ------------------------------------------------------------------------------------------ 10. no markup
async def test_shop_addresses_and_branch_names_cannot_carry_markup(client, container):
    business, branch = await business_with_branch(client, container, open_branch=False)
    for field, value in (
        ("address", "1 Allen <script>alert(1)</script>"),
        ("branch_name", "Ikeja <b>"),
        ("area", ">x"),
    ):
        r = await client.post(
            f"/v1/partner/business/{business}/branches", json={**BRANCH, field: value}, headers=auth("owner")
        )
        assert r.status_code == 422 and "< and >" in r.text, (field, r.text)
    r = await client.put(
        f"/v1/partner/business/{business}/branches/{branch}",
        json={"branch_name": "<img>"},
        headers=auth("owner"),
    )
    assert r.status_code == 422 and "< and >" in r.text
    start = (await container.repos.restaurants.get(MAIN)).location.model_dump()
    for body in ({"address": "14 Admiralty Way <i>"}, {"address": "14 Admiralty Way", "area": "<Lekki>"}):
        r = await client.put(
            f"/v1/partner/restaurants/{MAIN}/location",
            json={"location": start, **body},
            headers=auth("owner"),
        )
        assert r.status_code == 422 and "< and >" in r.text
    sign_up = {
        "business_name": "Ofada Hub",
        "cac_number": "RC123456",
        "contact_name": "Kemi",
        "contact_phone": "+2348022222222",
        "address": "1 Allen Avenue",
        "area": "Ikeja",
        "location": IKEJA,
        "cuisines": ["Nigerian"],
        "branches": [{**BRANCH, "address": "5 Admiralty <script>"}],
    }
    r = await client.post("/v1/applications/restaurant", json=sign_up, headers=auth("customer2"))
    assert r.status_code == 422 and "< and >" in r.text


# ------------------------------------------------------------------------------------------ 11. document ids
@pytest.mark.parametrize("bad", ["a/b", "x/customer_private/codes", ".", "..", "", "__all__", "é" * 800])
async def test_ids_that_cannot_name_a_document_are_not_found(container, bad):
    repos = container.repos
    assert await repos.orders.get(bad) is None
    assert await repos.items.get_many([bad, "jj-party-jollof"]) == {
        "jj-party-jollof": await repos.items.get("jj-party-jollof")
    }
    with pytest.raises(NotFound):
        await repos.orders.update(bad, {"reviewed": True})
    await repos.orders.delete(bad)  # nothing to delete
    with pytest.raises(ValidationFailed):
        await repos.set_feature_flag(bad, True, "", "admin-1")


async def test_ids_with_a_slash_in_requests_give_clean_answers(flow, client, container):
    quote = {
        "restaurant_id": "r-jollof-junction/x",
        "lines": [{"item_id": "jj-party-jollof", "quantity": 1}],
        "fulfillment": "pickup",
    }
    assert (await client.post("/v1/quotes", json=quote, headers=auth("customer"))).status_code == 404
    lines = [{"item_id": "food_items/jj-party-jollof", "quantity": 1}]
    r = await client.post(
        "/v1/quotes", json={**quote, "restaurant_id": MAIN, "lines": lines}, headers=auth("customer")
    )
    assert r.status_code == 409 and r.json()["error"]["code"] == "item_unavailable"
    r = await client.post("/v1/orders", json={"quote_id": "a/b/c/d"}, headers={**auth("customer"), **idem()})
    assert r.status_code == 404
    order = await flow.paid_order()
    ticket = {
        "order_id": f"{order['id']}/customer_private/codes",
        "category": "other",
        "description": "Hello there",
    }
    assert (
        await client.post("/v1/support/tickets", json=ticket, headers=auth("customer"))
    ).status_code == 404
    r = await client.get(
        "/v1/delivery/estimates",
        params={"restaurant_ids": f"{MAIN},a/b", "lat": 6.4410, "lng": 3.4600},
        headers=auth("customer"),
    )
    assert r.status_code == 200 and [e["restaurant_id"] for e in r.json()["estimates"]] == [MAIN]
    assert (await client.get("/v1/track/GMW2.345678")).status_code == 404
    r = await client.post(
        "/v1/admin/waybills/depart",
        json={"hub_id": "lagos-lekki", "tracking_codes": ["GMW/2345678"], "trip_reference": "LAG-1"},
        headers=auth("hub"),
    )
    assert r.status_code == 200 and r.json()["skipped"] == [
        {"tracking_code": "GMW/2345678", "reason": "Not found"}
    ]
    assert (await client.post("/v1/rider/offers/__offer__/accept", headers=auth("rider1"))).status_code == 404
