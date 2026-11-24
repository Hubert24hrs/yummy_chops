"""Businesses with branches, one menu and split card payments (docs/adr/0028-business-branches-and-split-payments.md)."""

from __future__ import annotations

import re
from datetime import timedelta

from sqlalchemy import select

from conftest import _p, auth
from gudmeal_api.ledger.tables import PaymentRecord

IKEJA = {"lat": 6.6018, "lng": 3.3515}
NEAR_IKEJA = {
    "label": "Office",
    "line1": "2 Allen Avenue",
    "area": "Ikeja",
    "location": {"lat": 6.6031, "lng": 3.3528},
    "contact_phone": "+2348011111111",
}
SIGN_UP = {
    "business_name": "Ofada Hub",
    "vertical": "food",
    "cac_number": "RC123456",
    "contact_name": "Kemi",
    "contact_phone": "+2348022222222",
    "email": "hello@ofadahub.ng",
    "address": "1 Allen Avenue",
    "area": "Ikeja",
    "location": IKEJA,
    "cuisines": ["Nigerian"],
    "branches": [
        {"address": "5 Admiralty Way", "area": "Lekki Phase 1", "location": {"lat": 6.4478, "lng": 3.4723}},
        {
            "address": "12 Ogui Road",
            "area": "Enugu",
            "location": {"lat": 6.4402, "lng": 7.4943},
            "manager_phone": "+2348033333333",
        },
    ],
}


def as_owner(container, name: str, uid: str, restaurants: list[str]) -> None:
    """The partner dashboard refreshes the owner's sign-in token, which then lists every branch."""
    verifier = getattr(container.verifier, "_fallback", container.verifier)
    verifier.principals[name] = _p(uid, "restaurant_owner", restaurants=dict.fromkeys(restaurants, "owner"))


async def restaurant_balance(container, rid: str) -> int:
    async with container.db.session() as s:
        return await container.ledger.balance(s, f"liability:restaurant:{rid}")


async def books_balance(client) -> bool:
    tb = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()["trial_balance"]
    return tb["debits_kobo"] == tb["credits_kobo"]


async def test_signing_up_with_branches_gives_a_business_id_and_every_branch(client, container):
    r = await client.post("/v1/applications/restaurant", json=SIGN_UP, headers=auth("customer2"))
    assert r.status_code == 201, r.text  # no bank details at sign-up any more: they come in the dashboard
    r = await client.post(
        f"/v1/admin/applications/{r.json()['id']}/decision", json={"approve": True}, headers=auth("ops")
    )
    assert r.status_code == 200, r.text
    claims = await container.identity.get_claims("cust-2")
    assert len(claims["restaurant_roles"]) == 3 and set(claims["restaurant_roles"].values()) == {"owner"}

    as_owner(container, "ofada", "cust-2", list(claims["restaurant_roles"]))
    mine = (await client.get("/v1/partner/business", headers=auth("ofada"))).json()
    assert mine["without_business"] == []
    [business] = mine["businesses"]
    assert re.fullmatch(r"YCB-[2-9A-HJ-NP-Z]{6}", business["id"])
    assert business["email"] == "hello@ofadahub.ng" and business["bank_connected"] is False
    assert "paystack_subaccount_code" not in business
    branches = business["branches"]
    assert [b["main"] for b in branches] == [True, False, False]
    assert {b["area"] for b in branches} == {"Ikeja", "Lekki Phase 1", "Enugu"}
    assert next(b for b in branches if b["area"] == "Enugu")["manager_phone"] == "+2348033333333"
    assert all(b["status"] == "pending" for b in branches)  # hidden until each opens for orders
    # Each branch belongs to the city of the delivery zone it is in.
    cities = {
        r.area: r.city
        for r in await container.repos.restaurants.find(where=[("business_id", "==", business["id"])])
    }
    assert cities == {"Ikeja": "lagos", "Lekki Phase 1": "lagos", "Enugu": "enugu"}

    # The team sees every business, its branches and whether its bank account is connected.
    listed = (await client.get("/v1/admin/businesses", headers=auth("ops"))).json()
    assert business["id"] in {b["id"] for b in listed}
    assert (await client.get("/v1/admin/businesses", headers=auth("ofada"))).status_code == 403


async def test_customers_see_the_nearest_branch_which_sells_the_main_menu(client, container):
    main = "r-jollof-junction"
    mine = (await client.get("/v1/partner/business", headers=auth("owner"))).json()
    assert main in {r["restaurant_id"] for r in mine["without_business"]}  # can get a business ID
    r = await client.post("/v1/partner/business", json={"restaurant_id": main}, headers=auth("owner"))
    assert r.status_code == 201, r.text
    business = r.json()
    assert (
        await client.post("/v1/partner/business", json={"restaurant_id": main}, headers=auth("owner"))
    ).status_code == 409
    r = await client.post(
        f"/v1/partner/business/{business['id']}/branches",
        json={"branch_name": "Ikeja", "address": "1 Allen Avenue", "area": "Ikeja", "location": IKEJA},
        headers=auth("owner"),
    )
    assert r.status_code == 201, r.text
    branch = next(b for b in r.json()["branches"] if not b["main"])["restaurant_id"]
    outside = await client.post(
        f"/v1/partner/business/{business['id']}/branches",
        json={"address": "1 Somewhere Far", "area": "Kano", "location": {"lat": 12.0022, "lng": 8.5920}},
        headers=auth("owner"),
    )
    assert outside.status_code == 422 and "outside the areas we deliver" in outside.text
    assert (await container.identity.get_claims("demo-owner-1"))["restaurant_roles"][branch] == "owner"
    as_owner(container, "owner_all", "demo-owner-1", [main, branch])

    # The branch shares the main menu, so it can open at once.
    r = await client.put(
        f"/v1/partner/restaurants/{branch}/accepting", json={"accepting": True}, headers=auth("owner_all")
    )
    assert r.status_code == 200 and r.json()["status"] == "active", r.text
    await container.repos.restaurants.update(
        branch, {"opening_hours": (await container.repos.restaurants.get(main)).opening_hours.model_dump()}
    )

    near_ikeja = (
        await client.get("/v1/restaurants", params={**IKEJA, "vertical": "food", "limit": 100})
    ).json()
    ids = [c["id"] for c in near_ikeja]
    assert branch in ids and main not in ids  # one card per business: the branch nearest the customer
    near_lekki = (
        await client.get(
            "/v1/restaurants", params={"lat": 6.4478, "lng": 3.4723, "vertical": "food", "limit": 100}
        )
    ).json()
    assert main in [c["id"] for c in near_lekki] and branch not in [c["id"] for c in near_lekki]

    page = (await client.get(f"/v1/restaurants/{branch}")).json()
    assert "jj-party-jollof" in {i["id"] for s in page["sections"] for i in s["items"]}
    quote = await client.post(
        "/v1/quotes",
        json={
            "restaurant_id": branch,
            "lines": [
                {
                    "item_id": "jj-party-jollof",
                    "quantity": 1,
                    "selections": [{"group_id": "r-jollof-junction-protein", "choice_ids": ["chicken"]}],
                }
            ],
            "fulfillment": "delivery",
            "delivery_address": NEAR_IKEJA,
        },
        headers=auth("customer"),
    )
    assert quote.status_code == 201, quote.text
    assert quote.json()["restaurant_id"] == branch  # the order goes to the Ikeja branch

    # A dish added from the branch goes on the one menu, tagged with the business ID.
    menu = (await client.get(f"/v1/partner/restaurants/{branch}/menu", headers=auth("owner_all"))).json()
    r = await client.post(
        f"/v1/partner/restaurants/{branch}/items",
        json={"category_id": menu["categories"][0]["id"], "name": "Ofada rice", "price_kobo": 350_000},
        headers=auth("owner_all"),
    )
    assert r.status_code == 201, r.text
    item = await container.repos.items.get(r.json()["id"])
    assert item.restaurant_id == main and item.business_id == business["id"]
    assert all(i.business_id == business["id"] for i in await container.repos.list_items(main))

    # The branch's name and manager's number can be changed; strangers cannot. Its address cannot be moved here
    # (that goes through the kitchen location checks).
    r = await client.put(
        f"/v1/partner/business/{business['id']}/branches/{branch}",
        json={
            "manager_phone": " +2348044444444 ",
            "branch_name": "Ikeja GRA",
            "location": {"lat": 6.5, "lng": 3.3},
        },
        headers=auth("owner"),
    )
    assert r.status_code == 200
    changed = next(b for b in r.json()["branches"] if b["restaurant_id"] == branch)
    assert changed["manager_phone"] == "+2348044444444" and changed["branch_name"] == "Ikeja GRA"
    assert changed["location"] == IKEJA
    r = await client.put(
        f"/v1/partner/business/{business['id']}/branches/{branch}",
        json={"manager_phone": "1"},
        headers=auth("customer"),
    )
    assert r.status_code == 403


async def test_split_card_payments_pay_the_business_straight_away_and_keep_the_books_balanced(
    flow, client, container
):
    business = (
        await client.post(
            "/v1/partner/business", json={"restaurant_id": "r-jollof-junction"}, headers=auth("owner")
        )
    ).json()
    banks = (await client.get("/v1/partner/banks", headers=auth("owner"))).json()
    assert {"code": "058", "name": "Guaranty Trust Bank"} in banks
    r = await client.put(
        f"/v1/partner/business/{business['id']}/bank",
        json={"bank_code": "058", "account_number": "0123456789"},
        headers=auth("owner"),
    )
    assert r.status_code == 200, r.text
    connected = r.json()
    assert connected["bank_connected"] and connected["settlement_account_last4"] == "6789"
    assert "0123456789" not in str(connected) and "paystack_subaccount_code" not in connected
    bad = await client.put(
        f"/v1/partner/business/{business['id']}/bank",
        json={"bank_code": "058", "account_number": "12345"},
        headers=auth("owner"),
    )
    assert bad.status_code == 422

    order = await flow.paid_order()
    stored = await container.repos.orders.get(order["id"])
    share = stored.settlement.restaurant_earning_kobo
    async with container.db.session() as s:
        payment = await s.scalar(select(PaymentRecord).where(PaymentRecord.order_id == order["id"]))
    assert payment.split_subaccount and payment.split_amount_kobo == share
    assert stored.payment.split_to_business_kobo == share
    # Paid at once by the split: until the order completes, the restaurant has been paid ahead of its earning.
    assert await restaurant_balance(container, "r-jollof-junction") == -share
    assert await books_balance(client)

    # The shop hears "Payment received", with its share on the way to its bank.
    notes = await container.repos.notifications.find(where=[("recipient_uid", "==", "demo-owner-1")])
    note = next(n for n in notes if order["short_code"] in n.body)
    assert note.title == "Payment received" and "on its way to your bank account" in note.body

    done = await flow.deliver(order["id"])
    assert done["status"] == "completed"
    assert await restaurant_balance(container, "r-jollof-junction") == 0  # earned exactly what the split paid
    assert await books_balance(client)


async def test_a_refund_before_the_order_completes_leaves_the_business_owing_its_share(
    flow, client, container
):
    business = (
        await client.post(
            "/v1/partner/business", json={"restaurant_id": "r-jollof-junction"}, headers=auth("owner")
        )
    ).json()
    await client.put(
        f"/v1/partner/business/{business['id']}/bank",
        json={"bank_code": "044", "account_number": "0001112223"},
        headers=auth("owner"),
    )
    order = await flow.paid_order()
    share = (await container.repos.orders.get(order["id"])).settlement.restaurant_earning_kobo
    r = await client.post(
        f"/v1/orders/{order['id']}/cancel", json={"reason": "Changed my mind"}, headers=auth("customer")
    )
    assert r.status_code == 200, r.text
    # The customer's refund comes from Yummy Chops; the business's share is recovered from its next payout.
    assert await restaurant_balance(container, "r-jollof-junction") == -share
    assert await books_balance(client)


async def test_the_board_shows_the_rider_on_the_way_with_their_number_and_minutes(flow, client, container):
    order = await flow.paid_order()
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/accept",
        json={"prep_minutes": 10},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200
    offer = next(
        o
        for o in await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
        if o.status == "offered"
    )
    rider = next(name for name, p in __import__("conftest").PRINCIPALS.items() if p.uid == offer.rider_id)
    assert (await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))).status_code == 200

    board = (
        await client.get("/v1/partner/restaurants/r-jollof-junction/orders", headers=auth("kitchen"))
    ).json()
    on_board = next(o for o in board if o["id"] == order["id"])
    assert on_board["rider"]["name"] and isinstance(on_board["rider"]["eta_minutes"], int)
    assert on_board["rider"]["eta_minutes"] >= 1
    assert "phone" in on_board["rider"]

    # An old location gives no estimate rather than a wrong one.
    profile = await container.repos.riders.get(offer.rider_id)
    await container.repos.riders.save(
        profile.model_copy(update={"last_location_at": profile.last_location_at - timedelta(minutes=30)})
    )
    board = (
        await client.get("/v1/partner/restaurants/r-jollof-junction/orders", headers=auth("kitchen"))
    ).json()
    assert next(o for o in board if o["id"] == order["id"])["rider"]["eta_minutes"] is None
