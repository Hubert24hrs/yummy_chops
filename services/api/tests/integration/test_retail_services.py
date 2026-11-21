"""Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, names from ADR-0025): the three services, their shop pages (aisles, sizes and
market measures, stock, choices, combos), the over-the-counter rule, and orders end to end."""

from __future__ import annotations

from datetime import timedelta

import pytest

from conftest import ADDRESS, PRINCIPALS, auth, idem
from gudmeal_api.seed.autopilot import run_demo_shops
from gudmeal_api.services import dispatch as dispatch_mod
from gudmeal_api.services.membership import services_text

ENUGU_ADDRESS = {
    "label": "Home",
    "line1": "21 Nike Lake Road",
    "area": "Independence Layout",
    "location": {"lat": 6.4473, "lng": 7.5214},
    "contact_phone": "+2348066666666",
}


async def quote(client, shop: str, lines: list[dict], *, who: str = "customer", address: dict = ADDRESS):
    return await client.post(
        "/v1/quotes",
        json={"restaurant_id": shop, "lines": lines, "fulfillment": "delivery", "delivery_address": address},
        headers=auth(who),
    )


async def paid_order(client, shop: str, lines: list[dict], **kw) -> tuple[dict, str]:
    who = kw.get("who", "customer")
    r = await quote(client, shop, lines, **kw)
    assert r.status_code == 201, r.text
    q = r.json()
    r = await client.post(
        "/v1/orders", json={"quote_id": q["id"], "channel": "app"}, headers={**auth(who), **idem()}
    )
    assert r.status_code == 201, r.text
    order_id = r.json()["id"]
    r = await client.post(f"/v1/orders/{order_id}/checkout", json={}, headers={**auth(who), **idem()})
    assert r.status_code == 200 and r.json()["amount_kobo"] == q["breakdown"]["total_kobo"], r.text
    r = await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    assert r.status_code == 303
    return q, order_id


async def label(client, order_id: str, who: str = "customer") -> str:
    r = await client.get(f"/v1/orders/{order_id}", headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()["progress"]["label"]


async def detail(client, shop: str) -> dict:
    r = await client.get(f"/v1/restaurants/{shop}")
    assert r.status_code == 200, r.text
    return r.json()


def products(shop_detail: dict) -> dict[str, dict]:
    return {i["id"]: i for s in shop_detail["sections"] for i in s["items"]}


# ------------------------------------------------------------------------------------------------- catalogue
async def test_the_six_services_in_the_order_the_apps_show_them(client):
    services = (await client.get("/v1/services", params={"city": "lagos"})).json()
    assert [s["id"] for s in services] == ["food", "pharmacy", "beauty", "grocery", "market", "parcel"]
    by_id = {s["id"]: s for s in services}
    assert by_id["grocery"]["name"] == "Shop & Groceries" and by_id["grocery"]["merchants"] == 3
    assert by_id["pharmacy"]["name"] == "Pharmacy" and by_id["pharmacy"]["merchants"] == 2
    assert by_id["market"]["name"] == "Buy Foodstuff" and by_id["market"]["merchants"] == 2
    assert "over-the-counter" in by_id["pharmacy"]["tagline"].lower()
    enugu = {s["id"]: s for s in (await client.get("/v1/services", params={"city": "enugu"})).json()}
    assert [enugu[v]["merchants"] for v in ("grocery", "pharmacy", "market")] == [1, 1, 1]


async def test_each_new_service_lists_its_shops_and_browse_categories(client):
    for vertical, shops, categories in (
        ("grocery", {"g-freshbasket", "g-mainland-mart", "g-quickstop"}, {"supermarkets", "convenience"}),
        ("pharmacy", {"p-carefirst", "p-wellspring"}, {"pain", "vitamins", "firstaid"}),
        ("market", {"m-lekki-market", "m-mainland-market"}, {"foodstuff", "vegetables", "combos"}),
    ):
        r = await client.get("/v1/restaurants", params={"vertical": vertical, "city": "lagos"})
        assert r.status_code == 200, r.text
        assert {s["id"] for s in r.json()} == shops and {s["vertical"] for s in r.json()} == {vertical}
        cats = (await client.get(f"/v1/services/{vertical}/categories", params={"city": "lagos"})).json()
        assert categories <= {c["id"] for c in cats} and all(c["emoji"] and c["merchants"] for c in cats)
    # A category narrows the list: only the mini mart is a convenience store.
    r = await client.get("/v1/restaurants", params={"vertical": "grocery", "category": "convenience"})
    assert [s["id"] for s in r.json()] == ["g-quickstop"]
    promos = await client.get("/v1/restaurants", params={"vertical": "grocery", "category": "promotions"})
    assert [s["id"] for s in promos.json()] == ["g-freshbasket"]
    assert promos.json()[0]["promotions"][0]["code"] == "FRESH10"
    # Food pages are unchanged by the new shops.
    food = (await client.get("/v1/restaurants", params={"city": "lagos"})).json()
    assert {s["vertical"] for s in food} == {"food"}


async def test_a_market_is_a_shopper_with_aisles_measures_choices_and_combos(client):
    market = await detail(client, "m-lekki-market")
    assert market["restaurant"]["badge"] == "Shopper" and market["restaurant"]["vertical"] == "market"
    assert market["restaurant"]["supports_pickup"] is False  # the shopper is in the market: delivery only
    aisles = [s["category"]["name"] for s in market["sections"]]
    assert aisles[0] == "Soup & stew combos" and "Pepper & vegetables" in aisles and "Meat (raw)" in aisles
    items = products(market)
    combo = items["lm-combo-egusi"]
    assert combo["kind"] == "combo" and "ugwu" in combo["description"].lower()
    assert items["lm-garri-derica"]["unit_label"] == "derica"
    assert (
        items["lm-tomatoes-half-paint"]["unit_label"] == "half paint"
        and items["lm-tomatoes-half-paint"]["emoji"]
    )
    assert items["lm-croaker-1kg"]["is_available"] is False  # out of stock today, still listed
    # Beef is sold by weight: a required choice, so the listed price is a "from" price.
    beef = items["lm-beef"]
    weight = market["option_groups"]["m-lekki-market-beef-weight"]
    assert beef["option_group_ids"][0] == weight["id"] and weight["min_select"] == 1
    assert [c["name"] for c in weight["choices"]] == ["500 g", "1 kg", "2 kg"]
    r = await quote(
        client,
        "m-lekki-market",
        [
            {
                "item_id": "lm-beef",
                "quantity": 1,
                "selections": [{"group_id": weight["id"], "choice_ids": ["1kg"]}],
            },
            {"item_id": "lm-combo-pepper-stew", "quantity": 2},
        ],
    )
    assert r.status_code == 201, r.text
    assert r.json()["breakdown"]["subtotal_kobo"] == (420_000 + 380_000) + 2 * 250_000
    r = await quote(client, "m-lekki-market", [{"item_id": "lm-beef", "quantity": 1}])
    assert r.status_code == 422, r.text  # the weight must be chosen
    # Enugu's market sells what Enugu cooks.
    enugu = products(await detail(client, "m-enugu-main-market"))
    assert "em-abacha-wrap" in enugu and "em-combo-onugbu" in enugu


async def test_a_supermarket_shows_sizes_and_stock(client):
    shop = await detail(client, "g-freshbasket")
    assert shop["restaurant"]["badge"] is None
    assert [s["category"]["name"] for s in shop["sections"]][:2] == ["Soft drinks & water", "Food cupboard"]
    items = products(shop)
    assert len(items) == 48
    water = items["fb-water-75x12"]
    assert (
        water["name"] == "Table water" and water["unit_label"] == "75 cl × 12" and water["kind"] == "product"
    )
    assert water["price_kobo"] == 270_000 and water["popularity"] > 0
    assert items["fb-butter-250"]["is_available"] is False
    r = await quote(client, "g-freshbasket", [{"item_id": "fb-butter-250", "quantity": 1}])
    assert r.status_code == 409 and r.json()["error"]["code"] == "item_unavailable"
    # The mini mart stocks only its own aisles, at its own prices.
    mini = products(await detail(client, "g-quickstop"))
    assert "qs-rice-5kg" not in mini and mini["qs-cola-50"]["price_kobo"] > items["fb-cola-50"]["price_kobo"]
    found = (await client.get("/v1/search", params={"q": "table water", "vertical": "grocery"})).json()
    assert found["items"] and {h["vertical"] for h in found["items"]} == {"grocery"}


# ---------------------------------------------------------------------------------- over-the-counter only
async def test_pharmacies_sell_over_the_counter_products_only(client, container):
    shop = await detail(client, "p-carefirst")
    items = products(shop)
    assert "cf-paracetamol-12" in items and items["cf-paracetamol-12"]["unit_label"] == "12 tablets"
    # A prescription-only medicine is never shown, never found and can never be ordered...
    assert "cf-amoxicillin-500" not in items
    found = (await client.get("/v1/search", params={"q": "amoxicillin"})).json()
    assert found["items"] == []
    r = await quote(client, "p-carefirst", [{"item_id": "cf-amoxicillin-500", "quantity": 1}])
    assert r.status_code == 409 and "needs a prescription" in r.json()["error"]["message"]
    assert r.json()["error"]["details"]["reason"] == "prescription_required"
    # ...but the pharmacy's own list still has it, marked.
    menu = (await client.get("/v1/partner/restaurants/p-carefirst/menu", headers=auth("ops"))).json()
    hidden = next(i for i in menu["items"] if i["id"] == "cf-amoxicillin-500")
    assert hidden["requires_prescription"] is True
    # A pharmacy that adds a prescription-only product gets the same treatment.
    r = await client.post(
        "/v1/partner/restaurants/p-carefirst/items",
        json={
            "category_id": "pain",
            "name": "Tramadol 50 mg capsules",
            "price_kobo": 150_000,
            "kind": "product",
            "unit_label": "10 capsules",
            "requires_prescription": True,
        },
        headers=auth("ops"),
    )
    assert r.status_code == 201, r.text
    assert r.json()["id"] not in products(await detail(client, "p-carefirst"))
    r = await quote(client, "p-carefirst", [{"item_id": r.json()["id"], "quantity": 1}])
    assert r.status_code == 409


async def test_a_shop_sets_the_size_brand_and_picture_of_a_product(client):
    r = await client.post(
        "/v1/partner/restaurants/g-freshbasket/items",
        json={
            "category_id": "drinks",
            "name": "Zobo drink",
            "price_kobo": 80_000,
            "kind": "product",
            "unit_label": "50 cl bottle",
            "brand": "House brand",
            "emoji": "🥤",
        },
        headers=auth("ops"),
    )
    assert r.status_code == 201, r.text
    item = products(await detail(client, "g-freshbasket"))[r.json()["id"]]
    assert (item["unit_label"], item["brand"], item["emoji"]) == ("50 cl bottle", "House brand", "🥤")
    r = await client.patch(
        f"/v1/partner/restaurants/g-freshbasket/items/{item['id']}/availability",
        json={"available": False},
        headers=auth("ops"),
    )
    assert r.status_code == 200, r.text
    assert products(await detail(client, "g-freshbasket"))[item["id"]]["is_available"] is False


# ------------------------------------------------------------------------------------------- orders end to end
@pytest.mark.parametrize(
    ("shop", "lines", "accepted", "city"),
    [
        (
            "g-freshbasket",
            [{"item_id": "fb-water-75x12", "quantity": 1}, {"item_id": "fb-bread-sliced", "quantity": 2}],
            "Store accepted",
            "lagos",
        ),
        (
            "p-carefirst",
            [{"item_id": "cf-paracetamol-12", "quantity": 2}, {"item_id": "cf-vitamin-c-20", "quantity": 1}],
            "Pharmacy accepted",
            "lagos",
        ),
        (
            "m-lekki-market",
            [{"item_id": "lm-combo-egusi", "quantity": 1}, {"item_id": "lm-garri-half-paint", "quantity": 1}],
            "Shopper accepted",
            "lagos",
        ),
        (
            "m-enugu-main-market",
            [{"item_id": "em-combo-onugbu", "quantity": 1}, {"item_id": "em-yam-tuber", "quantity": 1}],
            "Shopper accepted",
            "enugu",
        ),
    ],
)
async def test_an_order_runs_from_checkout_to_delivery(client, container, shop, lines, accepted, city):
    address = ENUGU_ADDRESS if city == "enugu" else ADDRESS
    q, order_id = await paid_order(client, shop, lines, address=address)
    b = q["breakdown"]
    assert (
        b["total_kobo"]
        == (b["subtotal_kobo"] + b["delivery_fee_kobo"] + b["service_fee_kobo"] + b["small_order_fee_kobo"])
        + b["vat_kobo"]
        - b["discount_kobo"]
    )
    vertical = shop_vertical = {"g": "grocery", "p": "pharmacy", "m": "market"}[shop[0]]
    assert (await label(client, order_id)).startswith("Sent to")

    base = f"/v1/partner/restaurants/{shop}/orders/{order_id}"
    r = await client.post(f"{base}/accept", json={"prep_minutes": 15}, headers=auth("ops"))
    assert r.status_code == 200, r.text
    assert await label(client, order_id) == accepted

    offers = await container.repos.assignments.find(where=[("order_id", "==", order_id)])
    offer = next(o for o in offers if o.status == "offered")
    rider = next(name for name, p in PRINCIPALS.items() if p.uid == offer.rider_id)
    r = await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    assert r.status_code == 200, r.text
    rider_view = r.json()
    # The rider sees what to collect (names and quantities), never prices.
    assert [i["quantity"] for i in rider_view["items"]] == [ln["quantity"] for ln in lines]
    assert "breakdown" not in rider_view and rider_view["vertical"] == shop_vertical
    r = await client.post(f"{base}/ready", headers=auth("ops"))
    assert r.status_code == 200, r.text
    assert "the " in (await label(client, order_id))  # "Rider on the way to the store / pharmacy / market"
    assert (
        await client.post(f"/v1/rider/deliveries/{order_id}/pickup", headers=auth(rider))
    ).status_code == 200
    code = (await client.get(f"/v1/orders/{order_id}/codes", headers=auth("customer"))).json()[
        "delivery_code"
    ]
    r = await client.post(
        f"/v1/rider/deliveries/{order_id}/deliver", json={"code": code}, headers=auth(rider)
    )
    assert r.status_code == 200, r.text

    done = (await client.get(f"/v1/orders/{order_id}", headers=auth("customer"))).json()
    assert done["status"] == "completed" and done["vertical"] == vertical
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert ledger["trial_balance"]["debits_kobo"] == ledger["trial_balance"]["credits_kobo"]
    summary = (await client.get("/v1/me/order-summary", headers=auth("customer"))).json()
    assert summary["by_vertical"][vertical]["orders"] == 1
    assert summary["by_vertical"][vertical]["spent_kobo"] == b["total_kobo"]


async def test_plus_members_get_their_benefits_at_the_new_shops(client, container):
    lines = [{"item_id": "fb-rice-5kg", "quantity": 1}]
    before = (await quote(client, "g-freshbasket", lines)).json()["breakdown"]
    assert before["delivery_fee_kobo"] > 0 and before["plus_savings_kobo"] == 0
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": 500_000}, headers={**auth("customer"), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    r = await client.post(
        "/v1/plus/subscribe", json={"provider": "wallet"}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 201, r.text
    for shop, member_lines in (
        ("g-freshbasket", lines),
        ("p-carefirst", [{"item_id": "cf-multivitamin-30", "quantity": 1}]),
        ("m-lekki-market", [{"item_id": "lm-yam-tuber", "quantity": 1}]),
    ):
        after = (await quote(client, shop, member_lines)).json()["breakdown"]
        assert after["delivery_fee_kobo"] == 0 and after["plus_savings_kobo"] > 0, shop


async def test_plus_benefits_name_every_kind_of_shop(client):
    r = await client.get("/v1/plus", headers=auth("customer"))
    assert r.status_code == 200, r.text
    benefits = r.json()["plan"]["benefits"]
    assert benefits[0] == "Free delivery on restaurant and shop orders of ₦3,000 or more"
    assert benefits[1] == "50% off the service fee on restaurant and shop orders"
    # A plan limited to some services names them.
    assert services_text(["food", "beauty"]) == "Food and Beauty"
    assert services_text(["food", "grocery", "pharmacy"]) == "Food, Groceries and Pharmacy"
    assert services_text(["market"]) == "Foodstuff"
    assert services_text([]) == "eligible"


async def test_the_demo_autopilot_accepts_and_packs_orders_at_the_new_shops(client, container):
    """Phone tests have nobody at the shop: a market order would otherwise wait for its shopper for ever."""
    _, order_id = await paid_order(client, "m-lekki-market", [{"item_id": "lm-yam-tuber", "quantity": 1}])
    assert await label(client, order_id) == "Sent to your shopper"
    later = dispatch_mod.utcnow() + timedelta(seconds=20)
    assert await run_demo_shops(container, now=later) == 1
    assert await label(client, order_id) == "Shopper accepted"
    assert await run_demo_shops(container, now=later + timedelta(seconds=45)) == 1
    assert (await container.repos.orders.get(order_id)).ready_at is not None


# ------------------------------------------------------------------------------------------------- sign-up
async def test_a_business_says_what_kind_of_shop_it_is_and_pharmacies_give_their_licence(client, container):
    """Any kind of shop can apply (ADR-0025): the choice decides its service and its first shelf."""
    application = {
        "business_name": "Allen Avenue Pharmacy",
        "vertical": "pharmacy",
        "cac_number": "RC654321",
        "contact_name": "Tobi",
        "contact_phone": "+2348033333333",
        "address": "12 Allen Avenue",
        "area": "Ikeja",
        "location": {"lat": 6.6, "lng": 3.35},
        "cuisines": ["Pain relief", "Vitamins"],
        "bank_name": "Test Bank",
        "bank_account_name": "Allen Avenue Pharmacy Ltd",
        "bank_account_last4": "4321",
    }
    no_licence = await client.post("/v1/applications/restaurant", json=application, headers=auth("customer2"))
    assert no_licence.status_code == 422 and "PCN premises licence" in no_licence.text
    r = await client.post(
        "/v1/applications/restaurant",
        json={**application, "pcn_licence_number": "PCN/PR/12345"},
        headers=auth("customer2"),
    )
    assert r.status_code == 201, r.text
    assert r.json()["data"]["vertical"] == "pharmacy"
    decided = await client.post(
        f"/v1/admin/applications/{r.json()['id']}/decision", json={"approve": True}, headers=auth("ops")
    )
    assert decided.status_code == 200, decided.text
    shop = await container.repos.restaurants.get(decided.json()["created_entity_id"])
    assert shop.vertical == "pharmacy" and shop.status == "pending"
    assert [c.name for c in await container.repos.get_menu_categories(shop.id)] == ["Products"]

    # A business that does not say is a restaurant, as before.
    plain = {k: v for k, v in application.items() if k != "vertical"}
    r = await client.post("/v1/applications/restaurant", json=plain, headers=auth("customer"))
    assert r.status_code == 201 and r.json()["data"]["vertical"] == "food"
