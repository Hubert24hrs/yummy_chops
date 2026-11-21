"""Multi-service launch: services catalogue, browse categories, beauty orders, Package Delivery, order totals."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from conftest import ADDRESS, LEKKI, auth, idem
from gudmeal_api.services import orders as orders_mod

LAGOS = ZoneInfo("Africa/Lagos")
RIDERS = {f"demo-rider-{n}": f"rider{n}" for n in range(1, 5)}


def stop(name: str, lat: float, lng: float, line1: str, phone: str = "+2348022222222", **kw: str) -> dict:
    return {"name": name, "phone": phone, "line1": line1, "location": {"lat": lat, "lng": lng}, **kw}


PICKUP = stop("Ada Obi", 6.4410, 3.4600, "5 Bisola Durosinmi-Etti Drive", area="Lekki Phase 1")
DROPOFF_VI = stop(
    "Tunde Bello",
    6.4281,
    3.4219,
    "7 Ajose Adeogun Street",
    phone="+2348033333333",
    area="Victoria Island",
    instructions="Call on arrival",
)
DROPOFF_ENUGU = stop(
    "Chika Eze", 6.4473, 7.5214, "21 Nike Lake Road", area="Independence Layout", city="Enugu"
)


def tomorrow_noon_lagos() -> datetime:
    local = datetime.now(LAGOS) + timedelta(days=1)
    return local.replace(hour=12, minute=0, second=0, microsecond=0).astimezone(UTC)


async def parcel_quote(client, who: str = "customer", **body) -> dict:
    payload = {"pickup": PICKUP, "dropoff": DROPOFF_VI, "size": "small", "category": "documents", **body}
    r = await client.post("/v1/parcels/quotes", json=payload, headers=auth(who))
    assert r.status_code == 201, r.text
    return r.json()


async def paid_parcel(client, who: str = "customer", **body) -> dict:
    quote = await parcel_quote(client, who, **body)
    r = await client.post("/v1/parcels", json={"quote_id": quote["id"]}, headers={**auth(who), **idem()})
    assert r.status_code == 201, r.text
    order = r.json()
    r = await client.post(f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth(who), **idem()})
    assert r.status_code == 200, r.text
    r = await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    assert r.status_code == 303
    r = await client.get(f"/v1/orders/{order['id']}", headers=auth(who))
    return r.json() | {"quote": quote}


# ---------------------------------------------------------------------------------- catalogue
async def test_services_categories_and_cities(client):
    services = {s["id"]: s for s in (await client.get("/v1/services")).json()}
    # The owner's order (ADR-0025): Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff,
    # Package Delivery.
    assert list(services) == ["food", "pharmacy", "beauty", "grocery", "market", "parcel"]
    assert services["food"]["merchants"] == 14 and services["beauty"]["merchants"] == 5
    assert services["parcel"]["cities"] == ["enugu", "lagos"] and services["parcel"]["available"]
    assert "interstate" in services["parcel"]["options"] and services["parcel"]["coming_soon"] == []
    enugu = {s["id"]: s for s in (await client.get("/v1/services", params={"city": "enugu"})).json()}
    assert enugu["food"]["merchants"] == 4 and enugu["beauty"]["merchants"] == 2

    food_cats = {c["id"]: c for c in (await client.get("/v1/services/food/categories")).json()}
    assert {"promotions", "local", "international", "snacks", "grills", "healthy", "drinks"} <= set(food_cats)
    assert food_cats["promotions"]["merchants"] == 3  # JOLLOF20, COALCITY10, PIZZANIGHT
    beauty_cats = {c["id"] for c in (await client.get("/v1/services/beauty/categories")).json()}
    assert beauty_cats == {"promotions", "skincare", "bodycare", "haircare", "makeup", "fragrance", "men"}

    shops = (await client.get("/v1/restaurants", params={"vertical": "beauty"})).json()
    assert len(shops) == 5 and {s["vertical"] for s in shops} == {"beauty"}
    enugu_shops = (await client.get("/v1/restaurants", params={"vertical": "beauty", "city": "enugu"})).json()
    assert {s["id"] for s in enugu_shops} == {"b-udala-glow-studio", "b-ekulu-naturals"}
    skincare = (
        await client.get("/v1/restaurants", params={"vertical": "beauty", "category": "skincare"})
    ).json()
    assert {s["id"] for s in skincare} == {"b-shea-harbour", "b-udala-glow-studio"}
    promos = (await client.get("/v1/restaurants", params={"category": "promotions", "city": "lagos"})).json()
    assert {s["id"] for s in promos} == {"r-jollof-junction", "r-kiln-and-crust"}
    jj = next(s for s in promos if s["id"] == "r-jollof-junction")
    assert jj["promotions"] == [{"code": "JOLLOF20", "label": "20% off at Jollof Junction (up to ₦2,000)"}]
    local = (
        await client.get("/v1/restaurants", params={"category": "local", "pickup": True, **LEKKI})
    ).json()
    assert local and all(c["supports_pickup"] for c in local)
    everything = (await client.get("/v1/restaurants", params={"vertical": "all"})).json()
    assert len(everything) == 29  # 14 restaurants, 5 beauty shops, 4 supermarkets, 3 pharmacies, 3 markets

    assert (await client.get("/v1/restaurants", params={"category": "nope"})).status_code == 422
    assert (await client.get("/v1/restaurants", params={"city": "abuja"})).status_code == 422

    found = (await client.get("/v1/search", params={"q": "serum", "vertical": "beauty"})).json()
    assert {i["item"]["id"] for i in found["items"]} >= {"sh-vitc", "sh-niacinamide"}
    assert {i["vertical"] for i in found["items"]} == {"beauty"}
    assert [c["id"] for c in (await client.get("/v1/cities")).json()] == ["lagos", "enugu"]
    cfg = (await client.get("/v1/config/public")).json()
    assert {c["id"] for c in cfg["cities"]} == {"lagos", "enugu"}


async def test_support_contacts_show_only_real_ones(client, container):
    """Only the customer-care email exists so far: WhatsApp and phone come back empty, so the apps show them as
    "coming soon" instead of a made-up number. `placeholders` stays true until all three exist, for app builds
    that only read that flag."""
    support = (await client.get("/v1/config/public")).json()["support"]
    assert {k: v for k, v in support.items() if k != "hours"} == {
        "whatsapp": "",
        "phone": "",
        "email": "customercare@yummy247.com",
        "placeholders": True,
    }
    container.settings.support_whatsapp = "+234 812 345 6789"
    container.settings.support_phone = "+234 1 234 5678"
    support = (await client.get("/v1/config/public")).json()["support"]
    assert support["whatsapp"] == "+234 812 345 6789" and support["placeholders"] is False


async def test_beauty_order_uses_shop_wording(flow, client):
    detail = (await client.get("/v1/restaurants/b-shea-harbour")).json()
    vitc = next(i for s in detail["sections"] for i in s["items"] if i["id"] == "sh-vitc")
    assert vitc["kind"] == "product" and vitc["unit_label"] == "30 ml"
    order = await flow.paid_order(
        restaurant_id="b-shea-harbour",
        lines=[{"item_id": "sh-vitc", "quantity": 1}, {"item_id": "sh-spf50", "quantity": 1}],
        voucher="GLOW15",
    )
    assert order["vertical"] == "beauty" and order["status"] == "submitted_to_restaurant"
    assert order["progress"]["label"] == "Sent to the shop"
    assert order["breakdown"]["discount_kobo"] == 300_000  # 15% of ₦23,500 capped at ₦3,000


# ---------------------------------------------------------------------------------- parcels: pricing
async def test_parcel_quote_validation_and_pricing(client):
    q = await parcel_quote(client, size="medium")
    b = q["breakdown"]
    assert "settlement" not in q and q["details"]["city"] == "lagos"
    assert b["subtotal_kobo"] == 0 and b["delivery_fee_kobo"] % 5_000 == 0
    assert b["total_kobo"] == b["delivery_fee_kobo"] + b["service_fee_kobo"] + b["vat_kobo"]
    assert b["service_fee_kobo"] == 10_000 and q["eta_minutes"] > 25
    small = await parcel_quote(client, size="small")
    assert small["breakdown"]["delivery_fee_kobo"] < b["delivery_fee_kobo"]  # medium costs more

    async def rejected(body: dict, status: int) -> str:
        payload = {"pickup": PICKUP, "dropoff": DROPOFF_VI, **body}
        r = await client.post("/v1/parcels/quotes", json=payload, headers=auth("customer"))
        assert r.status_code == status, r.text
        return r.json()["error"]["message"]

    assert "Interstate" in await rejected({"dropoff": DROPOFF_ENUGU}, 409)
    assert "Lagos and Enugu" in await rejected({"dropoff": stop("Abuja", 9.0765, 7.3986, "Wuse 2")}, 409)
    assert await rejected({"dropoff": PICKUP}, 422)
    soon = (datetime.now(UTC) + timedelta(minutes=10)).isoformat()
    assert "30 minutes" in await rejected({"scheduled_for": soon}, 422)
    night = (tomorrow_noon_lagos() + timedelta(hours=14)).isoformat()  # 2am Lagos
    assert "7am to 9pm" in await rejected({"scheduled_for": night}, 422)
    assert (
        await client.post("/v1/parcels/quotes", json={"pickup": PICKUP}, headers=auth("customer"))
    ).status_code == 422
    assert (await client.post("/v1/parcels/quotes", json={})).status_code == 401


# ---------------------------------------------------------------------------------- parcels: lifecycle
async def test_parcel_end_to_end_with_rider_and_ledger(client, container):
    quote = await parcel_quote(client, description="Signed contract", declared_value_kobo=0)
    key = idem()
    r = await client.post("/v1/parcels", json={"quote_id": quote["id"]}, headers={**auth("customer"), **key})
    assert r.status_code == 201, r.text
    order = r.json()
    assert order["vertical"] == "parcel" and order["restaurant_id"] == "gm-send" and order["lines"] == []
    assert order["parcel"]["dropoff"]["name"] == "Tunde Bello" and "settlement" not in order
    assert order["delivery_address"]["contact_phone"] == "+2348033333333"
    replay = await client.post(
        "/v1/parcels", json={"quote_id": quote["id"]}, headers={**auth("customer"), **key}
    )
    assert replay.json()["id"] == order["id"] and replay.headers.get("Idempotent-Replayed") == "true"

    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.json()["amount_kobo"] == quote["breakdown"]["total_kobo"]
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    paid = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert paid["status"] == "ready_for_pickup" and paid["progress"]["label"] == "Finding a rider"

    # No merchant is involved: nothing reaches a partner dashboard; dispatch offers the job straight away.
    owner_view = (
        await client.get("/v1/partner/restaurants/r-jollof-junction/orders", headers=auth("owner"))
    ).json()
    assert order["id"] not in [o["id"] for o in owner_view]
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    assert len(offers) == 1 and offers[0].status == "offered"
    rider = RIDERS[offers[0].rider_id]
    r = await client.post(f"/v1/rider/offers/{offers[0].id}/accept", headers=auth(rider))
    assert r.status_code == 200, r.text
    rider_view = r.json()
    assert rider_view["vertical"] == "parcel" and rider_view["parcel"]["pickup"]["phone"] == "+2348022222222"
    assert rider_view["parcel"]["size"] == "small" and "declared_value_kobo" not in rider_view["parcel"]

    assert (
        await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    ).status_code == 200
    mid = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert mid["progress"]["label"] == "Package picked up"
    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    r = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver",
        json={"code": codes["delivery_code"]},
        headers=auth(rider),
    )
    assert r.status_code == 200, r.text
    final = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert final["status"] == "completed" and final["settled_at"]

    full = (await client.get(f"/v1/admin/orders/{order['id']}", headers=auth("admin"))).json()
    settlement = full["order"]["settlement"]
    assert settlement["commission_kobo"] == 0 and settlement["restaurant_earning_kobo"] == 0
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    tb = ledger["trial_balance"]
    assert tb["debits_kobo"] == tb["credits_kobo"]
    balances = {a["account"]: a["balance_kobo"] for a in ledger["accounts"]}
    b = quote["breakdown"]
    assert balances["liability:customer_funds"] == 0
    assert balances[f"liability:rider:{offers[0].rider_id}"] == settlement["rider_pay_kobo"]
    assert balances["revenue:delivery"] == b["delivery_fee_kobo"] - settlement["rider_pay_kobo"]
    assert (
        balances["liability:vat"] == b["vat_kobo"]
        and balances["revenue:service_fee"] == b["service_fee_kobo"]
    )
    assert not any(a.startswith("liability:restaurant:") for a in balances)


async def test_scheduled_parcel_released_before_pickup_and_cancellation(client, container):
    when = tomorrow_noon_lagos()
    order = await paid_parcel(client, scheduled_for=when.isoformat(), size="large", category="household")
    assert order["status"] == "paid" and order["progress"]["label"] == "Booking confirmed"
    release = [t for t in container.tasks.tasks if t[0] == orders_mod.TASK_PARCEL_RELEASE]
    assert release and release[-1][1] == {"order_id": order["id"]}
    expected = (when - orders_mod.PARCEL_DISPATCH_LEAD - datetime.now(UTC)).total_seconds()
    assert abs(release[-1][2] - expected) < 120
    assert not await container.repos.assignments.find(where=[("order_id", "==", order["id"])])

    r = await client.post(
        "/internal/tasks/parcel-release",
        json={"order_id": order["id"]},
        headers={"X-Internal-Token": "test-internal-secret"},
    )
    assert r.status_code in (200, 204), r.text
    released = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert released["status"] == "ready_for_pickup"
    await container.orders.release_parcel({"order_id": order["id"]})  # duplicate task delivery is harmless

    # Before a rider accepts, the sender can cancel and is refunded in full automatically.
    r = await client.post(
        f"/v1/orders/{order['id']}/cancel", json={"reason": "Changed plans"}, headers=auth("customer")
    )
    assert r.status_code == 200, r.text
    done = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert done["status"] == "refunded" and done["refund_total_kobo"] == order["breakdown"]["total_kobo"]

    # A scheduled parcel can also be cancelled while it is still waiting (status paid).
    waiting = await paid_parcel(client, scheduled_for=when.isoformat())
    r = await client.post(f"/v1/orders/{waiting['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 200 and r.json()["status"] in ("refund_pending", "refunded")
    await container.orders.release_parcel({"order_id": waiting["id"]})  # late task: no effect
    assert (await container.repos.orders.get(waiting["id"])).status.value == "refunded"


async def test_food_orders_cannot_be_cancelled_once_ready(flow, client):
    order = await flow.paid_order()
    base = f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}"
    assert (
        await client.post(f"{base}/accept", json={"prep_minutes": 10}, headers=auth("owner"))
    ).status_code == 200
    assert (await client.post(f"{base}/ready", headers=auth("owner"))).status_code == 200
    r = await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 409


# ---------------------------------------------------------------------------------- order totals
async def test_order_summary_totals(flow, client):
    empty = (await client.get("/v1/me/order-summary", headers=auth("customer2"))).json()
    assert (
        empty["orders_count"] == 0 and empty["total_spent_kobo"] == 0 and empty["favourite_merchant"] is None
    )

    food = await flow.paid_order("customer2")
    refunded = await flow.paid_order("customer2")
    r = await client.post(f"/v1/orders/{refunded['id']}/cancel", json={}, headers=auth("customer2"))
    assert r.status_code == 200
    parcel = await paid_parcel(client, "customer2")
    unpaid = await flow.order("customer2")  # never paid: not counted

    s = (await client.get("/v1/me/order-summary", headers=auth("customer2"))).json()
    assert s["orders_count"] == 3 and s["in_progress_count"] == 2
    assert s["total_spent_kobo"] == food["breakdown"]["total_kobo"] + parcel["breakdown"]["total_kobo"]
    assert s["refunded_kobo"] == refunded["breakdown"]["total_kobo"]
    assert s["by_vertical"]["food"] == {"orders": 2, "spent_kobo": food["breakdown"]["total_kobo"]}
    assert s["by_vertical"]["parcel"]["orders"] == 1 and s["by_vertical"]["beauty"]["orders"] == 0
    assert s["favourite_merchant"]["id"] == "r-jollof-junction" and s["favourite_merchant"]["orders"] == 2
    assert s["this_month_spent_kobo"] == s["total_spent_kobo"]
    assert unpaid["id"] not in str(s)
    other = (await client.get("/v1/me/order-summary", headers=auth("customer"))).json()
    assert other["orders_count"] == 0  # strictly per customer
    assert ADDRESS["area"] == "Lekki Phase 1"


async def test_places_for_address_entry_without_a_map(client):
    lagos = (await client.get("/v1/places/areas", params={"city": "lagos"})).json()
    enugu = (await client.get("/v1/places/areas", params={"city": "enugu"})).json()
    assert len(lagos) >= 30 and len(enugu) >= 10 and {a["city"] for a in enugu} == {"enugu"}
    hit = (await client.get("/v1/places/resolve", params={"q": "3 Isaac John Street, Ikeja GRA"})).json()
    assert hit["name"] == "Ikeja GRA" and hit["city"] == "lagos"
    vi = (await client.get("/v1/places/resolve", params={"q": "VI"})).json()
    assert vi["name"] == "Victoria Island"
    assert (await client.get("/v1/places/resolve", params={"q": "Wuse 2 Abuja"})).status_code == 404
    # Every area resolves inside a delivery zone of its own city, so parcels can be priced.
    cfg = await client.get("/v1/config/public")
    zones = cfg.json()["zones"]
    assert zones and all(a["city"] in {"lagos", "enugu"} for a in lagos + enugu)
