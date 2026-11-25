"""A mixed cart's orders make one rider trip (ADR-0031): one offer for every shop, the shops in the quickest
order then the customer, each shop's phone, and one delivery code."""

from __future__ import annotations

from conftest import PRINCIPALS, auth, idem
from gudmeal_api.domain.geo import GeoPoint, haversine_km
from gudmeal_api.domain.trips import navigation_url, quickest_order

PHARMACY = "p-carefirst"


async def paid_trip(flow, client) -> tuple[dict, dict]:
    meal = await flow.order()
    pills = await flow.order(restaurant_id=PHARMACY, lines=[{"item_id": "cf-vitamin-c-20", "quantity": 2}])
    r = await client.post(
        "/v1/checkouts", json={"order_ids": [meal["id"], pills["id"]]}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 200, r.text
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    return meal, pills


async def accept(client, shop: str, order_id: str, who: str) -> None:
    r = await client.post(
        f"/v1/partner/restaurants/{shop}/orders/{order_id}/accept",
        json={"prep_minutes": 10},
        headers=auth(who),
    )
    assert r.status_code == 200, r.text


async def test_one_rider_collects_every_shop_of_the_cart(flow, client, container):
    meal, pills = await paid_trip(flow, client)
    assert (await flow.get(meal["id"]))["status"] == "submitted_to_restaurant"
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")

    # One offer covers both shops (the pharmacy has not accepted yet) and pays for both deliveries.
    offers = [o for o in await container.repos.assignments.find() if o.status == "offered"]
    assert len(offers) == 1
    offer = offers[0]
    assert sorted(offer.trip_order_ids) == sorted([meal["id"], pills["id"]])
    assert {p["name"] for p in offer.pickups} == {"Jollof Junction", "CareFirst Pharmacy"}
    both = [await container.repos.orders.get(o["id"]) for o in (meal, pills)]
    assert offer.payout_kobo == sum(o.settlement.rider_pay_kobo for o in both if o) > 0
    rider = next(n for n, p in PRINCIPALS.items() if p.uid == offer.rider_id)
    shown = (await client.get("/v1/rider/offers", headers=auth(rider))).json()
    assert len(shown[0]["pickups"]) == 2

    r = await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    assert r.status_code == 200, r.text
    # The pharmacy accepts later: its order joins the same rider's trip, with no new offer.
    await accept(client, PHARMACY, pills["id"], "ops")
    assert (await flow.get(pills["id"]))["rider_name"] == (await flow.get(meal["id"]))["rider_name"]
    assert not [o for o in await container.repos.assignments.find() if o.status == "offered"]

    plan = (await client.get("/v1/rider/trip", headers=auth(rider))).json()["trips"]
    assert len(plan) == 1
    trip = plan[0]
    kinds = [s["kind"] for s in trip["stops"]]
    assert kinds == ["pickup", "pickup", "dropoff"]
    pickups = trip["stops"][:2]
    assert all(s["phone"] for s in pickups) and all(s["items"] for s in pickups)
    assert trip["stops"][2]["order_ids"] == [meal["id"], pills["id"]]
    assert trip["navigation_url"].startswith("https://www.google.com/maps/dir/?api=1")
    assert "waypoints=" in trip["navigation_url"] and trip["total_minutes"] > 0
    deliveries = (await client.get("/v1/rider/deliveries", headers=auth(rider))).json()
    assert all(d["restaurant_phone"] and d["trip_id"] for d in deliveries)

    # One code at the door for both orders.
    codes = [
        (await client.get(f"/v1/orders/{o['id']}/codes", headers=auth("customer"))).json()
        for o in (meal, pills)
    ]
    assert codes[0]["delivery_code"] == codes[1]["delivery_code"]
    for stop in pickups:
        r = await client.post(f"/v1/rider/deliveries/{stop['order_id']}/pickup", headers=auth(rider))
        assert r.status_code == 200, r.text
    after = (await client.get("/v1/rider/trip", headers=auth(rider))).json()["trips"][0]
    assert [s["done"] for s in after["stops"]] == [True, True, False] and after["next_stop"] == 2
    for o in (meal, pills):
        r = await client.post(
            f"/v1/rider/deliveries/{o['id']}/deliver",
            json={"code": codes[0]["delivery_code"]},
            headers=auth(rider),
        )
        assert r.status_code == 200, r.text
        assert (await flow.get(o["id"]))["status"] in ("delivered", "completed")
    assert (await client.get("/v1/rider/trip", headers=auth(rider))).json() == {"trips": []}


async def test_an_ordinary_order_is_a_trip_of_one(flow, client):
    order = await flow.paid_order()
    done = await flow.deliver(order["id"])
    assert done["status"] == "completed"


def test_the_quickest_order_of_shops():
    rider = GeoPoint(lat=6.430, lng=3.420)
    near = GeoPoint(lat=6.432, lng=3.425)
    middle = GeoPoint(lat=6.436, lng=3.440)
    customer = GeoPoint(lat=6.440, lng=3.460)
    far_side = GeoPoint(lat=6.445, lng=3.470)
    stops = [far_side, middle, near]
    order = quickest_order(rider, stops, customer, lambda p: p, haversine_km)
    assert order[:2] == [near, middle]
    assert quickest_order(None, [middle], customer, lambda p: p, haversine_km) == [middle]
    url = navigation_url([near, middle, customer], vehicle="bicycle")
    assert "travelmode=bicycling" in url and url.count("|") == 1
