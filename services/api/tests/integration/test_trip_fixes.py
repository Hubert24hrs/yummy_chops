"""Mixed-cart trips (ADR-0030, ADR-0031) when something goes differently: an order called off while the trip offer is
out, one order handed back, wrong codes at the door, a cart paid in cash, and orders going to different doors."""

from __future__ import annotations

import pytest

from conftest import ADDRESS, PRINCIPALS, auth, idem
from gudmeal_api.errors import IncorrectCode, PermissionDenied

PHARMACY = "p-carefirst"
PHARMACY_LINES = [{"item_id": "cf-vitamin-c-20", "quantity": 2}]


def rider_name(uid: str) -> str:
    return next(n for n, p in PRINCIPALS.items() if p.uid == uid)


async def pay(client, ids: list[str], provider: str | None = None):
    body: dict = {"order_ids": ids}
    if provider:
        body["provider"] = provider
    return await client.post("/v1/checkouts", json=body, headers={**auth("customer"), **idem()})


async def paid_trip(flow, client) -> tuple[dict, dict]:
    meal = await flow.order()
    pills = await flow.order(restaurant_id=PHARMACY, lines=PHARMACY_LINES)
    r = await pay(client, [meal["id"], pills["id"]])
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


async def open_offers(container) -> list:
    return [o for o in await container.repos.assignments.find() if o.status == "offered"]


async def test_an_order_called_off_while_the_trip_offer_is_out_frees_the_rest_of_the_trip(
    flow, client, container
):
    meal, pills = await paid_trip(flow, client)
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")
    [offer] = await open_offers(container)
    assert offer.order_id == meal["id"] and pills["id"] in offer.trip_order_ids

    # The kitchen cannot make the meal after all: its offer goes (a rider can no longer take a cancelled job)...
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{meal['id']}/reject",
        json={"reason": "Out of rice"},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200, r.text
    assert (await container.repos.assignments.get(offer.id)).status == "cancelled"
    # ...and the pharmacy's order, which waited for that offer, finds a rider as soon as it is accepted.
    await accept(client, PHARMACY, pills["id"], "ops")
    [again] = await open_offers(container)
    assert again.order_id == pills["id"]


async def test_a_rider_declining_a_trip_is_not_offered_its_other_orders(flow, client, container):
    meal, pills = await paid_trip(flow, client)
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")
    await accept(client, PHARMACY, pills["id"], "ops")
    [offer] = await open_offers(container)
    r = await client.post(
        f"/v1/rider/offers/{offer.id}/decline",
        json={"reason": "Too far"},
        headers=auth(rider_name(offer.rider_id)),
    )
    assert r.status_code == 204, r.text
    for o in await open_offers(container):
        assert o.rider_id != offer.rider_id


async def test_an_order_handed_back_is_not_given_straight_back_to_the_same_rider(flow, client, container):
    meal, pills = await paid_trip(flow, client)
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")
    await accept(client, PHARMACY, pills["id"], "ops")
    [offer] = await open_offers(container)
    rider = rider_name(offer.rider_id)
    assert (await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))).status_code == 200
    assert (await flow.get(pills["id"]))["status"] == "rider_assigned"

    r = await client.post(
        f"/v1/rider/deliveries/{pills['id']}/unassign",
        json={"reason": "Pharmacy closed"},
        headers=auth(rider),
    )
    assert r.status_code == 200, r.text
    handed_back = await container.repos.orders.get(pills["id"])
    assert handed_back.rider_id != offer.rider_id
    assert all(o.rider_id != offer.rider_id for o in await open_offers(container))
    assert (await flow.get(meal["id"]))["status"] == "rider_assigned"  # the rest of the trip stays theirs


async def test_wrong_codes_count_across_the_whole_trip(flow, client, container):
    meal, pills = await paid_trip(flow, client)
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")
    await accept(client, PHARMACY, pills["id"], "ops")
    [offer] = await open_offers(container)
    rider = rider_name(offer.rider_id)
    assert (await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))).status_code == 200
    for o in (meal, pills):
        r = await client.post(f"/v1/rider/deliveries/{o['id']}/pickup", headers=auth(rider))
        assert r.status_code == 200, r.text
    code = (await client.get(f"/v1/orders/{meal['id']}/codes", headers=auth("customer"))).json()[
        "delivery_code"
    ]
    wrong = f"{(int(code) + 1) % 10_000:04d}"
    tries = container.orders.code_max_attempts
    # The two orders share one code: spreading guesses over them gives no extra tries. (Straight to the service:
    # the per-rider request limit would otherwise stop the guesses first.)
    for n in range(tries):
        target = (meal, pills)[n % 2]
        with pytest.raises(IncorrectCode):
            await container.orders.rider_deliver(PRINCIPALS[rider], target["id"], wrong)
    for o in (meal, pills):
        with pytest.raises(PermissionDenied):
            await container.orders.rider_deliver(PRINCIPALS[rider], o["id"], code)


async def test_a_right_code_does_not_use_up_the_riders_tries(flow, client, container):
    """Only wrong codes count against the per-rider limit: a trip of many orders is delivered with one code."""
    meal, pills = await paid_trip(flow, client)
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")
    await accept(client, PHARMACY, pills["id"], "ops")
    [offer] = await open_offers(container)
    rider = rider_name(offer.rider_id)
    assert (await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))).status_code == 200
    for o in (meal, pills):
        assert (
            await client.post(f"/v1/rider/deliveries/{o['id']}/pickup", headers=auth(rider))
        ).status_code == 200
    code = (await client.get(f"/v1/orders/{meal['id']}/codes", headers=auth("customer"))).json()[
        "delivery_code"
    ]
    wrong = f"{(int(code) + 1) % 10_000:04d}"
    for _ in range(4):  # four wrong tries of the five
        r = await client.post(
            f"/v1/rider/deliveries/{meal['id']}/deliver", json={"code": wrong}, headers=auth(rider)
        )
        assert r.status_code == 422, r.text
    for o in (meal, pills):  # the last try is right, and so is every call after it
        r = await client.post(
            f"/v1/rider/deliveries/{o['id']}/deliver", json={"code": code}, headers=auth(rider)
        )
        assert r.status_code == 200, r.text
    r = await client.post(
        f"/v1/rider/deliveries/{meal['id']}/deliver", json={"code": wrong}, headers=auth(rider)
    )
    assert r.status_code != 429, r.text  # the right codes gave their tries back
    assert (await client.get("/v1/rider/trip", headers=auth(rider))).json() == {"trips": []}


async def test_a_mixed_cart_paid_on_delivery(flow, client, container):
    await flow.deliver((await flow.paid_order())["id"])  # pay on delivery unlocks after a first order
    meal = await flow.order()
    pills = await flow.order(restaurant_id=PHARMACY, lines=PHARMACY_LINES)

    # One order the shop cannot take in cash: nothing of the cart is placed.
    container.cash.max_order_kobo = pills["breakdown"]["total_kobo"] - 1
    r = await pay(client, [meal["id"], pills["id"]], "cash")
    assert r.status_code == 422, r.text
    for o in (meal, pills):
        assert (await flow.get(o["id"]))["status"] in ("draft", "pending_payment")
    container.cash.max_order_kobo = 2_500_000_000

    # The cart's own orders are one trip to one door, not "another pay-on-delivery order on the way".
    r = await pay(client, [meal["id"], pills["id"]], "cash")
    assert r.status_code == 200, r.text
    for o in (meal, pills):
        view = await flow.get(o["id"])
        assert view["status"] == "submitted_to_restaurant" and view["payment"]["provider"] == "cash"

    # A rider is never sent out to collect more cash than they may carry, for the whole trip.
    container.dispatch.cash_limit = max(meal["breakdown"]["total_kobo"], pills["breakdown"]["total_kobo"])
    await accept(client, PHARMACY, pills["id"], "ops")
    await accept(client, "r-jollof-junction", meal["id"], "kitchen")
    assert not await open_offers(container)
    container.dispatch.cash_limit = 5_000_000
    assert await container.dispatch.start(meal["id"]) is not None


async def test_orders_for_different_doors_are_not_one_trip(flow, client, container):
    meal = await flow.order()
    quote = await client.post(
        "/v1/quotes",
        json={
            "restaurant_id": PHARMACY,
            "lines": PHARMACY_LINES,
            "fulfillment": "delivery",
            "delivery_address": {
                **ADDRESS,
                "line1": "12 Allen Avenue",
                "location": {"lat": 6.6018, "lng": 3.3515},
            },
        },
        headers=auth("customer"),
    )
    assert quote.status_code == 201, quote.text
    r = await client.post(
        "/v1/orders",
        json={"quote_id": quote.json()["id"], "channel": "web"},
        headers={**auth("customer"), **idem()},
    )
    assert r.status_code == 201, r.text
    pills = r.json()
    r = await pay(client, [meal["id"], pills["id"]])
    assert r.status_code == 200, r.text
    for o in (meal, pills):
        assert (await container.repos.orders.get(o["id"])).trip_id is None
