"""End-to-end check of a running local stack: every customer journey, the shop, riders, hubs and admin.

Start the stack first (`node scripts/dev.mjs auth`, `node scripts/dev.mjs api`, `node scripts/dev.mjs agents`),
then run it with the API's virtualenv:

    services/api/.venv/Scripts/python services/api/scripts/e2e_local.py        # Windows
    services/api/.venv/bin/python services/api/scripts/e2e_local.py            # macOS / Linux
    ... e2e_local.py food_delivery_card parcel_bike_delivery                   # only some journeys

It talks to the API over HTTP with real Firebase **Auth emulator** tokens (the emulator-only demo accounts from
seed_auth_emulator.py; it adds demo riders 2-4 and a beauty-shop owner to the emulator), pays through the local
payment sandbox and prints PASS/FAIL for every step. It refuses to run against anything but a local or private
address, and never touches a real Firebase project or payment provider.
"""

from __future__ import annotations

import base64
import ipaddress
import os
import re
import sys
import time
import uuid
from collections.abc import Callable
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import httpx

API = os.environ.get("E2E_API_URL", "http://127.0.0.1:8000").rstrip("/")
AGENTS = os.environ.get("E2E_AGENTS_URL", "http://127.0.0.1:8100").rstrip("/")
EMULATOR = os.environ.get("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
PROJECT = os.environ.get("FIREBASE_PROJECT_ID", "demo-gudmeal")
PASSWORD = os.environ.get("DEMO_USER_PASSWORD", "gudmeal-demo-123")


def _local_only(url: str) -> None:
    host = urlparse(url).hostname or ""
    if host == "localhost":
        return
    try:
        if ipaddress.ip_address(host).is_private or ipaddress.ip_address(host).is_loopback:
            return
    except ValueError:
        pass
    sys.exit(f"Refusing to run against {url}: this check only targets a local stack.")


for _url in (API, AGENTS, f"http://{EMULATOR}"):
    _local_only(_url)

EMAILS = {
    "customer": "customer@yummychops.test",
    "friend": "friend@yummychops.test",
    "owner": "owner@yummychops.test",
    "kitchen": "kitchen@yummychops.test",
    "rider1": "rider@yummychops.test",
    "rider2": "rider2@yummychops.test",
    "rider3": "rider3@yummychops.test",
    "rider4": "rider4@yummychops.test",
    "support": "support@yummychops.test",
    "finance": "finance@yummychops.test",
    "hub": "hub@yummychops.test",
    "admin": "admin@yummychops.test",
    "beauty": "beauty@yummychops.test",
}
RIDERS = {
    "rider1": "demo-rider-1",
    "rider2": "demo-rider-2",
    "rider3": "demo-rider-3",
    "rider4": "demo-rider-4",
}
JJ = "r-jollof-junction"
LEKKI = {"lat": 6.4410, "lng": 3.4600}
ADDRESS = {
    "label": "Home",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": LEKKI,
    "contact_phone": "+2348011111111",
}
JJ_LINES = [
    {
        "item_id": "jj-party-jollof",
        "quantity": 2,
        "selections": [{"group_id": "r-jollof-junction-protein", "choice_ids": ["chicken"]}],
    },
    {"item_id": "r-jollof-junction-drink-0", "quantity": 2},
]
PICKUP = {
    "name": "Ada Obi",
    "phone": "+2348022222222",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": LEKKI,
}
DROPOFF_VI = {
    "name": "Tunde Bello",
    "phone": "+2348033333333",
    "line1": "7 Ajose Adeogun Street",
    "area": "Victoria Island",
    "instructions": "Call on arrival",
    "location": {"lat": 6.4281, "lng": 3.4219},
}
WAYBILL_SENDER = {
    "name": "Ada Obi",
    "phone": "+2348022222222",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": LEKKI,
}
WAYBILL_RECIPIENT = {
    "name": "Chika Eze",
    "phone": "+2348066666666",
    "line1": "21 Nike Lake Road",
    "area": "Independence Layout",
    "location": {"lat": 6.4473, "lng": 7.5214},
}

client = httpx.Client(timeout=60, follow_redirects=False)
TOKENS: dict[str, str] = {}
STATE: dict[str, Any] = {}
RESULTS: list[tuple[str, str, bool, str]] = []
CURRENT = [""]
FLOWS: list[Callable[[], None]] = []


class Fail(Exception):
    pass


# --------------------------------------------------------------------------------------------- plumbing
def token(who: str) -> str:
    if who not in TOKENS:
        r = httpx.post(
            f"http://{EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key",
            json={"email": EMAILS[who], "password": PASSWORD, "returnSecureToken": True},
            timeout=20,
        )
        if r.status_code != 200:
            raise Fail(f"cannot sign in {EMAILS[who]} on the Auth emulator: {r.text[:200]}")
        TOKENS[who] = r.json()["idToken"]
    return TOKENS[who]


def call(
    method: str,
    path: str,
    who: str | None = None,
    body: Any = None,
    *,
    expect: int | tuple[int, ...] = (200, 201, 204),
    idem: bool = False,
    params: dict[str, Any] | None = None,
) -> Any:
    headers = {}
    if who:
        headers["Authorization"] = f"Bearer {token(who)}"
    if idem:
        headers["Idempotency-Key"] = uuid.uuid4().hex
    url = path if path.startswith("http") else API + path
    r = client.request(method, url, headers=headers, json=body, params=params)
    if r.status_code == 429 and 429 not in (expect if isinstance(expect, tuple) else (expect,)):
        wait = float(r.json().get("error", {}).get("details", {}).get("retry_after_seconds", 30))
        print(f"    (rate limited; waiting {wait:.0f}s as the API asks)", flush=True)
        time.sleep(min(wait, 90) + 1)
        r = client.request(method, url, headers=headers, json=body, params=params)
    allowed = expect if isinstance(expect, tuple) else (expect,)
    if r.status_code not in allowed:
        raise Fail(f"{method} {path} as {who or 'anonymous'} -> {r.status_code}: {r.text[:500]}")
    if r.content and "json" in r.headers.get("content-type", ""):
        return r.json()
    return r if r.content else {}


ALL_DAY = {"open": "00:00", "close": "23:59"}


def open_all_day(shop: str, owner: str) -> None:
    """Shops keep real opening hours (Lagos time). For a night-time run, open the test shops all day and put the
    real hours back at the end (restore_hours)."""
    hours = call("GET", f"/v1/restaurants/{shop}").get("opening_hours")
    if not hours or shop in STATE.setdefault("hours", {}):
        return
    STATE["hours"][shop] = (owner, hours)
    always = {**hours, "weekly": {day: [ALL_DAY] for day in map(str, range(7))}, "closed_dates": []}
    call("PATCH", f"/v1/partner/restaurants/{shop}/settings", owner, {"opening_hours": always})


def restore_hours() -> None:
    for shop, (owner, hours) in STATE.get("hours", {}).items():
        call("PATCH", f"/v1/partner/restaurants/{shop}/settings", owner, {"opening_hours": hours})
        print(f"  restored the real opening hours of {shop}")


def park_extra_riders() -> None:
    """Riders 2-4 only exist for this check: take them offline again so job offers reach the rider app
    (rider@yummychops.test) when someone tests on a phone."""
    for rider in ("rider2", "rider3", "rider4"):
        try:
            call("PUT", "/v1/rider/availability", rider, {"online": False})
        except Fail as exc:
            print(f"  could not take {rider} offline: {exc}")


def check(name: str, condition: Any, detail: Any = "") -> None:
    passed = bool(condition)
    RESULTS.append((CURRENT[0], name, passed, "" if passed else str(detail)[:600]))
    print(
        f"  {'PASS' if passed else 'FAIL'} {name}" + ("" if passed else f"  ::  {str(detail)[:600]}"),
        flush=True,
    )
    if not passed:
        raise Fail(name)


def flow(fn: Callable[[], None]) -> Callable[[], None]:
    FLOWS.append(fn)
    return fn


def wrong(code: str) -> str:
    return "".join("1" if ch != "1" else "2" for ch in str(code)) or "0000"


def items_of(resp: Any) -> list[dict]:
    if isinstance(resp, list):
        return resp
    for key in ("items", "results", "data", "orders", "restaurants"):
        if isinstance(resp, dict) and isinstance(resp.get(key), list):
            return resp[key]
    raise Fail(f"expected a list, got keys {list(resp) if isinstance(resp, dict) else type(resp)}")


def complete_sandbox(resp: dict) -> None:
    """Approve a local-sandbox checkout (card/bank payment) if the response is one."""
    nested = resp.get("checkout") or resp.get("payment") or {}
    ref = resp.get("reference") or nested.get("reference")
    url = resp.get("authorization_url") or nested.get("authorization_url") or ""
    if ref and "sandbox-checkout" in url:
        call("POST", f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success", expect=303)


def balance(who: str) -> int:
    w = call("GET", "/v1/wallet", who)
    for key in ("balance_kobo", "available_kobo", "available_balance_kobo"):
        if key in w:
            return int(w[key])
    raise Fail(f"no balance in wallet response: {list(w)}")


def payment_options(order_id: str, who: str = "customer") -> list[str]:
    r = call("GET", f"/v1/orders/{order_id}/payment-options", who)
    options = r if isinstance(r, list) else next((v for v in r.values() if isinstance(v, list)), [])
    return [o.get("provider") or o.get("id") for o in options if o.get("available", True)]


def quote(who: str = "customer", *, restaurant_id: str = JJ, lines: list | None = None, **extra: Any) -> dict:
    body: dict[str, Any] = {
        "restaurant_id": restaurant_id,
        "lines": lines or JJ_LINES,
        "fulfillment": "delivery",
    }
    body |= extra
    if body["fulfillment"] == "delivery":
        body.setdefault("delivery_address", ADDRESS)
    return call("POST", "/v1/quotes", who, body, expect=201)


def place(who: str = "customer", **kw: Any) -> tuple[dict, dict]:
    q = quote(who, **kw)
    order = call("POST", "/v1/orders", who, {"quote_id": q["id"], "channel": "web"}, expect=201, idem=True)
    return order, q


def pay_by_card(order_id: str, who: str = "customer") -> dict:
    co = call("POST", f"/v1/orders/{order_id}/checkout", who, {}, idem=True)
    complete_sandbox(co)
    return co


def get_order(order_id: str, who: str = "customer") -> dict:
    return call("GET", f"/v1/orders/{order_id}", who)


def paid_order(who: str = "customer", **kw: Any) -> dict:
    order, _ = place(who, **kw)
    pay_by_card(order["id"], who)
    return get_order(order["id"], who)


def find_offer(order_id: str, seconds: int = 20) -> tuple[str, dict]:
    deadline = time.time() + seconds
    while time.time() < deadline:
        for rider in RIDERS:
            for offer in items_of(call("GET", "/v1/rider/offers", rider)):
                oid = offer.get("order_id") or (offer.get("order") or {}).get("id")
                if oid == order_id:
                    return rider, offer
        time.sleep(1)
    raise Fail(f"no rider was offered order {order_id} within {seconds}s")


def ledger_balanced() -> None:
    data = call("GET", "/v1/admin/ledger", "finance")
    tb = data["trial_balance"]
    check("ledger balances (debits = credits)", tb["debits_kobo"] == tb["credits_kobo"], tb)


ACCEPTED = ("restaurant_accepted", "preparing", "rider_assigned", "ready_for_pickup")


def shop_step(base: str, step: str, staff: str, body: dict | None = None) -> dict:
    """A shop action on an order. In phone-test mode (`dev.mjs api --lan`) the demo shop autopilot may have done
    it already (409): then the order as the shop sees it now is returned instead."""
    r = call("POST", f"{base}/{step}", staff, body, expect=(200, 409))
    if "error" not in r:
        return r
    parts = base.split("/")
    orders = items_of(call("GET", f"/v1/partner/restaurants/{parts[4]}/orders", staff))
    current = next((o for o in orders if o["id"] == parts[-1]), None)
    if current is None:
        raise Fail(f"{step} was refused and the shop no longer lists the order: {r}")
    print(f"    (the demo shop autopilot had already done '{step}')", flush=True)
    return current


def deliver(
    order_id: str,
    *,
    who: str = "customer",
    shop: str = JJ,
    staff: str = "kitchen",
    owner: str = "owner",
    has_shop: bool = True,
    cash: bool = False,
    probe_wrong_code: bool = False,
) -> tuple[dict, str]:
    """Shop accepts, the offered rider accepts, shop marks ready, rider picks up, travels and delivers with the
    customer's code (optionally trying a wrong code first; riders get 5 quick attempts, then 1 per 50 s)."""
    base = f"/v1/partner/restaurants/{shop}/orders/{order_id}"
    if has_shop:
        # Step 2 of the flow: the shop receives the order, accepts it and prepares it.
        inbox = items_of(call("GET", f"/v1/partner/restaurants/{shop}/orders", staff))
        check("shop receives the order", any(o["id"] == order_id for o in inbox), len(inbox))
        r = shop_step(base, "accept", staff, {"prep_minutes": 10})
        check("shop accepts the order", r["status"] in ACCEPTED, r["status"])
    # Step 3: a rider accepts the delivery, collects it and delivers it.
    rider, offer = find_offer(order_id)
    earned_before = call("GET", "/v1/rider/earnings", rider)
    r = call("POST", f"/v1/rider/offers/{offer['id']}/accept", rider)
    check(f"{RIDERS[rider]} accepts the delivery offer", r["status"] == "rider_assigned", r["status"])
    if has_shop:
        r = shop_step(base, "ready", owner)
        check("shop marks the order ready", r.get("ready_at"), r)
    r = call("POST", f"/v1/rider/deliveries/{order_id}/pickup", rider)
    check("rider picks it up", r.get("status") == "picked_up", r.get("status"))
    call("POST", "/v1/rider/location", rider, {"lat": 6.443, "lng": 3.465})
    tracking = call("GET", f"/v1/orders/{order_id}/tracking", who)
    check("customer can track the rider", tracking, tracking)
    r = call("POST", f"/v1/rider/deliveries/{order_id}/in-transit", rider)
    check("rider is on the way", r.get("status") not in (None, "picked_up"), r.get("status"))
    call("GET", f"/v1/orders/{order_id}/codes", rider, expect=(403, 404))
    check("rider cannot read the customer's codes", True)
    codes = call("GET", f"/v1/orders/{order_id}/codes", who)
    code = codes.get("delivery_code")
    check("customer has a delivery code", code, codes)
    if probe_wrong_code:
        call(
            "POST",
            f"/v1/rider/deliveries/{order_id}/deliver",
            rider,
            {"code": wrong(code)},
            expect=(400, 403, 409, 422),
        )
        check("a wrong delivery code is refused", True)
    body: dict[str, Any] = {"code": code}
    if cash:
        body["cash_collected"] = True
    call("POST", f"/v1/rider/deliveries/{order_id}/deliver", rider, body)
    final = get_order(order_id, who)
    check(
        "delivered with the right code",
        final["status"] in ("delivered", "completed"),
        final["status"],
    )
    # Step 4: the customer has the order: it is completed and the rider's delivery earnings are recorded.
    for _ in range(20):
        if final["status"] == "completed":
            break
        time.sleep(0.5)
        final = get_order(order_id, who)
    check("order completed", final["status"] == "completed", final["status"])
    earned_after = call("GET", "/v1/rider/earnings", rider)
    earned = earned_after["balance_kobo"] - earned_before["balance_kobo"]
    check(
        f"rider's delivery earnings recorded ({naira(earned)})",
        earned > 0
        and earned == offer.get("payout_kobo", earned)
        and earned_after["deliveries_completed"] == earned_before["deliveries_completed"] + 1,
        {"earned": earned, "offer": offer.get("payout_kobo"), "after": earned_after["deliveries_completed"]},
    )
    return final, rider


OWNED_SHOPS: dict[str, str] = {}


def ensure_accounts(beauty_shop: str | None = None) -> None:
    """Seed the base demo users if the emulator was restarted, and add riders 2-4 (and a beauty-shop owner)."""
    os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = EMULATOR
    import firebase_admin
    from firebase_admin import auth

    try:
        token("customer")
    except Fail:  # the emulator was restarted: seed the base demo users first
        sys.path.insert(0, str(Path(__file__).parent))
        import seed_auth_emulator

        seed_auth_emulator.main()
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": PROJECT})
    wanted = [
        (uid, EMAILS[name], f"Demo Rider {uid[-1]}", ["rider"], {})
        for name, uid in RIDERS.items()
        if name != "rider1"
    ]
    if beauty_shop:
        OWNED_SHOPS[beauty_shop] = "owner"  # the demo shop owner keeps every shop a journey gave it
        wanted.append(
            (
                "demo-beauty-owner-1",
                EMAILS["beauty"],
                "Beauty Shop Owner",
                ["restaurant_owner"],
                dict(OWNED_SHOPS),
            )
        )
        TOKENS.pop("beauty", None)
    for uid, email, name, roles, shops in wanted:
        try:
            auth.update_user(uid, email=email, password=PASSWORD, display_name=name, email_verified=True)
        except auth.UserNotFoundError:
            auth.create_user(uid=uid, email=email, password=PASSWORD, display_name=name, email_verified=True)
        auth.set_custom_user_claims(uid, {"roles": roles, "restaurant_roles": shops})


# Tiny placeholder files for the KYC uploads (a JPEG and a PDF header): the API checks the kind, not the picture.
KYC_PHOTO = base64.b64encode(bytes([0xFF, 0xD8, 0xFF, 0xE0]) + bytes(64)).decode()
KYC_FORM = base64.b64encode(b"%PDF-1.4" + bytes(64)).decode()


def complete_rider_kyc(who: str, name: str) -> None:
    """What a new rider does in the rider app after signing up (docs/adr/0027-rider-kyc.md): details, NIN, two
    guarantors, every photo, then Submit. Placeholder files stand in for the photos."""
    TOKENS.pop(who, None)  # a fresh sign-in token carries the rider role given at sign-up
    guarantor = {"email": "", "address": "1 Admiralty Way, Lekki", "occupation": "Trader"}
    call(
        "PUT",
        "/v1/rider/kyc",
        who,
        {
            "permanent_address": "1 Admiralty Way, Lekki",
            "nin": "12345678901",
            "guarantors": [
                {**guarantor, "name": f"{name} guarantor 1", "phone": "+2348030000001"},
                {**guarantor, "name": f"{name} guarantor 2", "phone": "+2348030000002"},
            ],
        },
    )
    for kind in call("GET", "/v1/rider/kyc", who)["documents"]:
        data = KYC_FORM if kind.endswith("_form") else KYC_PHOTO
        call("POST", f"/v1/rider/kyc/documents/{kind}", who, {"data": data})
    call("POST", "/v1/rider/kyc/submit", who)


def riders_online() -> None:
    for i, rider in enumerate(RIDERS):
        call("PUT", "/v1/rider/availability", rider, {"online": True})
        call(
            "POST",
            "/v1/rider/location",
            rider,
            {"lat": LEKKI["lat"] + 0.002 * i, "lng": LEKKI["lng"] + 0.002 * i},
        )


# ---------------------------------------------------------------------------------------------- journeys
@flow
def public_browsing() -> None:
    """Browsing without signing in: cities, services, shops, menus, search, Discover"""
    check("API healthy", call("GET", "/v1/health"))
    call("GET", "/v1/ready")
    check("API ready (database and stores reachable)", True)
    cities = str(call("GET", "/v1/cities")).lower()
    check("Lagos and Enugu are live cities", "lagos" in cities and "enugu" in cities, cities[:200])
    services = {s["id"]: s for s in call("GET", "/v1/services")}
    check(
        "Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff and Package Delivery are available",
        all(services.get(v, {}).get("available") for v in (*SHOP_SERVICES, "parcel")),
        services.keys(),
    )
    for city, vertical in ((c, v) for c in ("lagos", "enugu") for v in SHOP_SERVICES):
        shops = items_of(call("GET", "/v1/restaurants", params={"city": city, "vertical": vertical}))
        check(f"{vertical} shops listed in {city.title()}", len(shops) > 0, len(shops))
    detail = call("GET", f"/v1/restaurants/{JJ}")
    check("menu loads for Jollof Junction", "jj-party-jollof" in str(detail), list(detail))
    found = items_of(call("GET", "/v1/search", params={"q": "jollof", "city": "lagos"}))
    check("search finds jollof", len(found) > 0, found)
    feed = call("GET", "/v1/discover/dishes", params={"city": "lagos"})
    check("Discover feed has dish sections", len(feed.get("sections", [])) >= 1, list(feed))
    check("public config loads", call("GET", "/v1/config/public"))


@flow
def customer_account() -> None:
    """Customer account: profile, saved addresses, favourites, notifications"""
    me = call("GET", "/v1/me", "customer")
    check("signed-in customer profile", me.get("uid") or me.get("id"), me)
    addr = call("POST", "/v1/me/addresses", "customer", ADDRESS | {"label": "E2E Office"}, expect=(200, 201))
    aid = addr.get("id") or (addr.get("address") or {}).get("id")
    check("address saved", aid, addr)
    listed = items_of(call("GET", "/v1/me/addresses", "customer"))
    check("address listed", any(a.get("id") == aid for a in listed), listed)
    call("DELETE", f"/v1/me/addresses/{aid}", "customer", expect=(200, 204))
    check("address deleted", True)
    call("PUT", f"/v1/me/favourites/{JJ}", "customer", {"favourite": True}, expect=(200, 204, 422))
    call("GET", "/v1/me/notifications", "customer")
    check("notifications load", True)


@flow
def food_delivery_card() -> None:
    """Food: order Jollof Junction, pay by card (sandbox), kitchen, rider, delivery code, review"""
    riders_online()
    q = quote()
    b = q["breakdown"]
    parts = (
        b["subtotal_kobo"]
        + b["delivery_fee_kobo"]
        + b["service_fee_kobo"]
        + b["small_order_fee_kobo"]
        + b["vat_kobo"]
    )
    check("quote totals add up", b["total_kobo"] == parts - b["discount_kobo"], b)
    order = call(
        "POST", "/v1/orders", "customer", {"quote_id": q["id"], "channel": "web"}, expect=201, idem=True
    )
    check("order created as a draft", order["status"] == "draft", order["status"])
    co = pay_by_card(order["id"])
    check("checkout charges the quoted total", co["amount_kobo"] == b["total_kobo"], co)
    o = get_order(order["id"])
    check(
        "payment verified, order sent to the kitchen",
        o["status"] == "submitted_to_restaurant" and o["payment"]["status"] == "paid",
        (o["status"], o.get("payment")),
    )
    listed = items_of(call("GET", f"/v1/partner/restaurants/{JJ}/orders", "owner"))
    check("kitchen sees the order", any(x["id"] == order["id"] for x in listed))
    deliver(order["id"], probe_wrong_code=True)
    call(
        "POST",
        f"/v1/orders/{order['id']}/review",
        "customer",
        {"food_rating": 5, "delivery_rating": 5, "comment": "E2E check: hot and on time"},
    )
    check("customer reviews the order", True)
    events = items_of(call("GET", f"/v1/orders/{order['id']}/events", "customer"))
    check("order timeline records each step", len(events) >= 6, len(events))
    earnings = call("GET", "/v1/rider/earnings", "rider1")
    check("rider earnings load", earnings is not None)
    ledger_balanced()
    STATE["completed_order"] = order["id"]


def naira(kobo: int) -> str:
    return f"NGN {kobo / 100:,.2f}"


@flow
def food_one_payment_covers_everything() -> None:
    """Food in one checkout: the customer pays food + delivery fee + service fee (+VAT) once; a rider is then found"""
    riders_online()
    who = "friend"  # not a Yummy Chops Plus member, so the full delivery and service fees are charged
    check("this customer pays full fees (no Plus membership)", not call("GET", "/v1/plus", who).get("member"))
    q = quote(who)
    b = q["breakdown"]
    print(
        f"    quote: food {naira(b['subtotal_kobo'])} + delivery {naira(b['delivery_fee_kobo'])}"
        f" + service {naira(b['service_fee_kobo'])} + VAT {naira(b['vat_kobo'])}"
        f" - discount {naira(b['discount_kobo'])} = {naira(b['total_kobo'])}",
        flush=True,
    )
    check(
        "the quote charges food, a delivery fee and a service fee",
        b["subtotal_kobo"] > 0 and b["delivery_fee_kobo"] > 0 and b["service_fee_kobo"] > 0,
        b,
    )
    fees = b["delivery_fee_kobo"] + b["service_fee_kobo"] + b["small_order_fee_kobo"] + b["vat_kobo"]
    check(
        "total = food + delivery fee + service fee + VAT",
        b["total_kobo"] == b["subtotal_kobo"] + fees - b["discount_kobo"],
        b,
    )

    order = call("POST", "/v1/orders", who, {"quote_id": q["id"], "channel": "app"}, expect=201, idem=True)
    co = call("POST", f"/v1/orders/{order['id']}/checkout", who, {}, idem=True)
    check(
        f"one checkout asks for the whole {naira(b['total_kobo'])}", co["amount_kobo"] == b["total_kobo"], co
    )
    complete_sandbox(co)
    # The receipt of what was just paid for (ADR-0019): shown once paid, kept once printed.
    shown = call("GET", f"/v1/orders/{order['id']}/receipt", who)
    check(
        "the receipt repeats the payment: same total, charges add up",
        shown["total_kobo"] == b["total_kobo"]
        and sum(c["amount_kobo"] for c in shown["charges"]) == b["total_kobo"]
        and not shown["saved"],
        shown,
    )
    printed = call("POST", f"/v1/orders/{order['id']}/receipt", who)
    mine = items_of(call("GET", "/v1/receipts", who))
    check(
        "PRINT keeps the receipt under My receipts",
        printed["saved"] and printed["print_count"] == 1 and any(m["order_id"] == order["id"] for m in mine),
        [m["number"] for m in mine],
    )
    payments = items_of(call("GET", f"/v1/orders/{order['id']}/payments", who))
    check(
        "exactly one payment, for the full total",
        len(payments) == 1
        and payments[0]["amount_kobo"] == b["total_kobo"]
        and payments[0]["status"] == "succeeded",
        payments,
    )
    o = get_order(order["id"], who)
    check("paid once, the order goes to the kitchen", o["status"] == "submitted_to_restaurant", o["status"])

    # The kitchen accepts, then dispatch looks for a rider: the delivery fee in that same payment pays the rider.
    _, rider = deliver(order["id"], who=who)
    check(f"a rider was found and delivered it ({RIDERS[rider]})", True)
    full = call("GET", f"/v1/admin/orders/{order['id']}", "admin")
    s = full["order"]["settlement"]
    kitchen = b["subtotal_kobo"] - s["commission_kobo"] - s["restaurant_funded_discount_kobo"]
    platform = b["total_kobo"] - s["restaurant_earning_kobo"] - s["rider_pay_kobo"]
    print(
        f"    split of the one payment: kitchen {naira(s['restaurant_earning_kobo'])}"
        f" (food minus {s['commission_bps'] / 100:g}% commission), rider {naira(s['rider_pay_kobo'])},"
        f" Yummy Chops {naira(platform)} (commission + fees, including {naira(b['vat_kobo'])} VAT held for the tax office)",
        flush=True,
    )
    check("the kitchen gets the food minus commission", s["restaurant_earning_kobo"] == kitchen, s)
    check("the rider is paid from the delivery fee", 0 < s["rider_pay_kobo"] <= b["delivery_fee_kobo"], s)
    check(
        "kitchen + rider + Yummy Chops = exactly what the customer paid",
        platform == s["commission_kobo"] + fees - s["platform_funded_discount_kobo"] - s["rider_pay_kobo"],
        (platform, s, b),
    )
    ledger_balanced()


@flow
def food_pickup() -> None:
    """Food pickup: the customer collects at the counter with a pickup code"""
    o = paid_order(fulfillment="pickup")
    base = f"/v1/partner/restaurants/{JJ}/orders/{o['id']}"
    shop_step(base, "accept", "kitchen", {"prep_minutes": 10})
    r = shop_step(base, "ready", "owner")
    check("order ready for pickup", r["status"] == "ready_for_pickup", r["status"])
    codes = call("GET", f"/v1/orders/{o['id']}/codes", "customer")
    call(
        "POST",
        f"{base}/handover",
        "owner",
        {"code": wrong(codes["pickup_code"])},
        expect=(400, 403, 409, 422),
    )
    check("a wrong pickup code is refused", True)
    call("POST", f"{base}/handover", "owner", {"code": codes["pickup_code"]})
    final = get_order(o["id"])
    check("handed over and completed", final["status"] in ("completed", "delivered"), final["status"])
    ledger_balanced()


@flow
def wallet_topup_pay_and_refund() -> None:
    """Wallet: top up by card, pay an order from the wallet, cancel it and get the money back"""
    before = balance("customer")
    t = call("POST", "/v1/wallet/topups", "customer", {"amount_kobo": 2_000_000}, idem=True)
    complete_sandbox(t)
    topped = balance("customer")
    check("a NGN 20,000 top-up lands in the wallet", topped == before + 2_000_000, (before, topped, t))
    order, q = place()
    opts = payment_options(order["id"])
    check("wallet offered at checkout", "wallet" in opts, opts)
    call("POST", f"/v1/orders/{order['id']}/checkout", "customer", {"provider": "wallet"}, idem=True)
    o = get_order(order["id"])
    check(
        "paid from the wallet, sent to the kitchen",
        o["payment"]["status"] == "paid" and o["status"] == "submitted_to_restaurant",
        (o["status"], o.get("payment")),
    )
    paid = balance("customer")
    check("wallet charged the order total", paid == topped - q["breakdown"]["total_kobo"], (topped, paid))
    call("POST", f"/v1/orders/{order['id']}/cancel", "customer", {"reason": "E2E check: changed my mind"})
    o = get_order(order["id"])
    check(
        "customer cancels before the kitchen accepts", o["status"] in ("cancelled", "refunded"), o["status"]
    )
    refunded = balance("customer")
    check("the refund goes back to the wallet", refunded == topped, (topped, refunded))
    ledger_balanced()


@flow
def pay_on_delivery_cash() -> None:
    """Pay on delivery: the rider collects cash, finance records the rider's remittance"""
    call(
        "PUT",
        "/v1/admin/customers/demo-customer-1/pay-on-delivery",
        "admin",
        {"blocked": False, "reason": "E2E check"},
    )
    riders_online()
    order, q = place()
    opts = payment_options(order["id"])
    pod = next((p for p in opts if p and ("delivery" in p or "cash" in p)), None)
    check("pay on delivery offered", pod, opts)
    call("POST", f"/v1/orders/{order['id']}/checkout", "customer", {"provider": pod}, idem=True)
    o = get_order(order["id"])
    check(
        "cash order goes to the kitchen",
        o["status"] == "submitted_to_restaurant",
        (o["status"], o.get("payment")),
    )
    _, rider = deliver(order["id"], cash=True)
    uid = RIDERS[rider]
    owed = rider_cash(uid)
    check(
        "rider now holds the cash", owed >= q["breakdown"]["total_kobo"], (owed, q["breakdown"]["total_kobo"])
    )
    call(
        "POST",
        f"/v1/admin/riders/{uid}/cash-remittances",
        "finance",
        {"amount_kobo": owed, "method": "bank_transfer", "reference": f"E2E-{uuid.uuid4().hex[:8]}"},
        idem=True,
    )
    check("remittance clears the rider's cash", rider_cash(uid) == 0, rider_cash(uid))
    ledger_balanced()


def rider_cash(uid: str) -> int:
    data = call("GET", "/v1/admin/cash", "finance")
    rows = next((v for v in data.values() if isinstance(v, list)), []) if isinstance(data, dict) else data
    for row in rows:
        if uid in (row.get("uid"), row.get("rider_uid"), row.get("rider_id")):
            for key in (
                "cash_on_hand_kobo",
                "cash_held_kobo",
                "owed_kobo",
                "outstanding_kobo",
                "balance_kobo",
            ):
                if key in row:
                    return int(row[key])
            raise Fail(f"no cash field in {row}")
    return 0


@flow
def beauty_order() -> None:
    """Beauty & Skin Care: order from a Lagos shop, the shop owner accepts, a rider delivers"""
    riders_online()
    shops = items_of(call("GET", "/v1/restaurants", params={"city": "lagos", "vertical": "beauty"}))
    shop = next((s for s in shops if s.get("is_open", True) and s.get("is_accepting_orders", True)), shops[0])
    detail = call("GET", f"/v1/restaurants/{shop['id']}")
    line = first_orderable_line(detail)
    ensure_accounts(beauty_shop=shop["id"])
    open_all_day(shop["id"], "beauty")
    o = paid_order(restaurant_id=shop["id"], lines=[line])
    check(
        f"beauty order at {shop.get('name')} paid and sent to the shop",
        o["status"] == "submitted_to_restaurant",
        o["status"],
    )
    deliver(o["id"], shop=shop["id"], staff="beauty", owner="beauty")
    ledger_balanced()


def first_orderable_line(detail: dict) -> dict:
    items: list[dict] = []
    menu = detail.get("menu") if isinstance(detail.get("menu"), dict) else detail
    for cat in (menu.get("sections") or []) + (menu.get("categories") or []):
        items += cat.get("items", [])
    items += menu.get("items", []) or []
    groups = {g["id"]: g for g in (menu.get("option_groups") or detail.get("option_groups") or [])}
    for item in items:
        if item.get("is_available") is False:
            continue
        selections = []
        for gid in item.get("option_group_ids", []):
            group = groups.get(gid, {})
            need = group.get("min_select") or group.get("min") or (1 if group.get("required") else 0)
            if need:
                choices = [c["id"] for c in group.get("choices", []) if c.get("is_available", True)][:need]
                selections.append({"group_id": gid, "choice_ids": choices})
        return {"item_id": item["id"], "quantity": 1} | ({"selections": selections} if selections else {})
    raise Fail(f"no orderable item in {detail.get('id')} (keys {list(detail)})")


SHOP_SERVICES = ("food", "grocery", "pharmacy", "market", "beauty")


def line_for(detail: dict, item_id: str, quantity: int = 1) -> dict:
    """A cart line for one product, picking the first choice wherever one is required (weight, pack size)."""
    item = next(i for sec in detail["sections"] for i in sec["items"] if i["id"] == item_id)
    selections = []
    for gid in item.get("option_group_ids", []):
        group = detail["option_groups"][gid]
        if group["min_select"]:
            picks = [c["id"] for c in group["choices"] if c.get("is_available", True)][: group["min_select"]]
            selections.append({"group_id": gid, "choice_ids": picks})
    return {"item_id": item_id, "quantity": quantity} | ({"selections": selections} if selections else {})


def shop_order(shop_id: str, basket: list[tuple[str, int]], sent: str, what: str) -> dict:
    """Order from a shop that sells by the aisle: browse it, pay in one payment, the shop packs, a rider
    delivers. Returns the shop page."""
    riders_online()
    detail = call("GET", f"/v1/restaurants/{shop_id}")
    name = detail["restaurant"]["name"]
    products = [i for sec in detail["sections"] for i in sec["items"]]
    check(f"{name}: products are listed by the aisle", len(detail["sections"]) >= 3, len(detail["sections"]))
    check(
        f"{name}: every product shows its size or measure",
        all(i.get("unit_label") or i.get("kind") == "combo" for i in products),
        [i["name"] for i in products if not i.get("unit_label") and i.get("kind") != "combo"][:5],
    )
    ensure_accounts(beauty_shop=shop_id)  # the demo shop-owner account now owns this shop
    open_all_day(shop_id, "beauty")
    lines = [line_for(detail, item_id, qty) for item_id, qty in basket]
    q = quote(restaurant_id=shop_id, lines=lines)
    b = q["breakdown"]
    order = call(
        "POST", "/v1/orders", "customer", {"quote_id": q["id"], "channel": "app"}, expect=201, idem=True
    )
    co = call("POST", f"/v1/orders/{order['id']}/checkout", "customer", {}, idem=True)
    check(
        f"{what}: one payment of {naira(b['total_kobo'])} covers the products, delivery and service fee",
        co["amount_kobo"] == b["total_kobo"]
        and b["total_kobo"]
        == b["subtotal_kobo"]
        + b["delivery_fee_kobo"]
        + b["service_fee_kobo"]
        + b["small_order_fee_kobo"]
        + b["vat_kobo"]
        - b["discount_kobo"],
        b,
    )
    complete_sandbox(co)
    o = get_order(order["id"])
    check(f"{what} order paid and sent to the shop", o["status"] == "submitted_to_restaurant", o["status"])
    check(f'the customer reads "{sent}"', o["progress"]["label"] == sent, o["progress"])
    deliver(o["id"], shop=shop_id, staff="beauty", owner="beauty")
    ledger_balanced()
    return detail


@flow
def grocery_order() -> None:
    """Groceries: a supermarket basket (water, rice, eggs by the crate) paid once, packed and delivered"""
    shops = items_of(call("GET", "/v1/restaurants", params={"city": "lagos", "vertical": "grocery"}))
    check("supermarkets and convenience stores are listed", len(shops) >= 2, [s["name"] for s in shops])
    detail = shop_order(
        "g-freshbasket",
        [("fb-water-75x12", 2), ("fb-rice-5kg", 1), ("fb-eggs", 1)],
        "Sent to the store",
        "groceries",
    )
    stock = [i["is_available"] for sec in detail["sections"] for i in sec["items"]]
    check(
        "the store shows what is out of stock as well as what is in",
        True in stock and False in stock,
        stock[:8],
    )


@flow
def pharmacy_order() -> None:
    """Pharmacy: over-the-counter products delivered; prescription-only medicines cannot be ordered"""
    detail = shop_order(
        "p-carefirst",
        [("cf-paracetamol-12", 2), ("cf-multivitamin-30", 1)],
        "Sent to the pharmacy",
        "pharmacy",
    )
    listed = {i["id"] for sec in detail["sections"] for i in sec["items"]}
    check(
        "the pharmacy page hides prescription-only medicines",
        "cf-amoxicillin-500" not in listed,
        sorted(listed)[:6],
    )
    found = call("GET", "/v1/search", params={"q": "amoxicillin", "city": "lagos"})
    check("search does not offer them either", "amoxicillin" not in str(found).lower(), str(found)[:200])
    refused = call(
        "POST",
        "/v1/quotes",
        "customer",
        {
            "restaurant_id": "p-carefirst",
            "lines": [{"item_id": "cf-amoxicillin-500", "quantity": 1}],
            "fulfillment": "delivery",
            "delivery_address": ADDRESS,
        },
        expect=409,
    )
    check(
        "ordering one by its id is refused: it needs a prescription",
        refused["error"]["details"].get("reason") == "prescription_required",
        refused,
    )


@flow
def mixed_cart_one_payment() -> None:
    """Mixed cart (ADR-0030): a meal, a pharmacy item and a beauty item in one cart; the beauty item is removed;
    one payment pays an order per shop, and ONE rider collects them all by the planned route (ADR-0031)"""
    riders_online()
    beauty = items_of(call("GET", "/v1/restaurants", params={"city": "lagos", "vertical": "beauty"}))[0]["id"]
    pharmacy = "p-carefirst"
    ensure_accounts(beauty_shop=pharmacy)
    ensure_accounts(beauty_shop=beauty)  # the demo shop-owner account works both shops
    for shop in (pharmacy, beauty):
        open_all_day(shop, "beauty")
    cart = {
        JJ: JJ_LINES,
        pharmacy: [line_for(call("GET", f"/v1/restaurants/{pharmacy}"), "cf-vitamin-c-20", 2)],
        beauty: [first_orderable_line(call("GET", f"/v1/restaurants/{beauty}"))],
    }
    quotes = {shop: quote(restaurant_id=shop, lines=lines) for shop, lines in cart.items()}
    check(
        "one quote per shop in the cart, each with its own delivery fee",
        all(q["breakdown"]["delivery_fee_kobo"] > 0 for q in quotes.values()),
        {s: q["breakdown"]["delivery_fee_kobo"] for s, q in quotes.items()},
    )
    del quotes[beauty]  # the customer removes the beauty item in the cart and reviews the total again
    orders = {
        shop: call(
            "POST", "/v1/orders", "customer", {"quote_id": q["id"], "channel": "app"}, expect=201, idem=True
        )
        for shop, q in quotes.items()
    }
    total = sum(q["breakdown"]["total_kobo"] for q in quotes.values())
    co = call(
        "POST", "/v1/checkouts", "customer", {"order_ids": [o["id"] for o in orders.values()]}, idem=True
    )
    check(
        f"ONE checkout of {naira(total)} for the {len(orders)} shops' orders",
        co["amount_kobo"] == total and co["authorization_url"] and len(co["orders"]) == len(orders),
        co,
    )
    complete_sandbox(co)
    call("POST", "/v1/payments/verify", "customer", {"reference": co["reference"]})
    for shop, order in orders.items():
        o = get_order(order["id"])
        check(
            f"{shop}: paid by the one payment and sent to the shop",
            o["status"] == "submitted_to_restaurant",
            o,
        )
        payments = items_of(call("GET", f"/v1/orders/{order['id']}/payments", "customer"))
        check(
            f"{shop}: its own share of the payment ({naira(quotes[shop]['breakdown']['total_kobo'])})",
            [(p["amount_kobo"], p["status"]) for p in payments]
            == [(quotes[shop]["breakdown"]["total_kobo"], "succeeded")],
            payments,
        )
    mine = {o["id"] for o in items_of(call("GET", "/v1/orders", "customer"))}
    check("the customer sees each order in Orders", all(o["id"] in mine for o in orders.values()))
    deliver_trip(orders, {JJ: ("kitchen", "owner"), pharmacy: ("beauty", "beauty")})
    ledger_balanced()


def deliver_trip(orders: dict[str, dict], staff: dict[str, tuple[str, str]], who: str = "customer") -> None:
    """ADR-0031: one rider collects every shop's order of a mixed cart, by the planned route, then delivers them
    all with the customer's one code."""
    for shop, order in orders.items():
        base = f"/v1/partner/restaurants/{shop}/orders/{order['id']}"
        r = shop_step(base, "accept", staff[shop][0], {"prep_minutes": 10})
        check(f"{shop} accepts its order", r["status"] in ACCEPTED, r["status"])
    ids = [o["id"] for o in orders.values()]
    deadline, found = time.time() + 20, None
    while found is None and time.time() < deadline:
        for rider in RIDERS:
            for offer in items_of(call("GET", "/v1/rider/offers", rider)):
                if offer.get("order_id") in ids:
                    found = (rider, offer)
        if found is None:
            time.sleep(1)
    if found is None:
        raise Fail("no rider was offered the trip")
    rider, offer = found
    check(
        f"ONE offer for the whole trip: {len(offer.get('pickups', []))} pickups for {RIDERS[rider]}",
        sorted(offer.get("trip_order_ids", [])) == sorted(ids) and len(offer.get("pickups", [])) == len(ids),
        offer,
    )
    call("POST", f"/v1/rider/offers/{offer['id']}/accept", rider)
    for oid in ids:
        check(f"order {oid[:6]} is on {RIDERS[rider]}'s trip", get_order(oid, who).get("rider_name"), oid)
    trip = call("GET", "/v1/rider/trip", rider)["trips"][0]
    stops = trip["stops"]
    print(
        "    planned route: "
        + " -> ".join(s["name"] or "customer" for s in stops)
        + f" ({trip['total_km']} km, ~{trip['total_minutes']} min, {trip['route_source']})",
        flush=True,
    )
    check(
        "the trip lists every shop to collect from (with its phone), then the customer",
        [s["kind"] for s in stops] == ["pickup"] * len(ids) + ["dropoff"]
        and all(s["phone"] for s in stops[:-1]),
        stops,
    )
    check(
        "the rider gets a Google Maps link for the whole route",
        "google.com/maps/dir" in trip["navigation_url"],
    )
    for stop in stops[:-1]:
        shop = next(k for k, o in orders.items() if o["id"] == stop["order_id"])
        shop_step(f"/v1/partner/restaurants/{shop}/orders/{stop['order_id']}", "ready", staff[shop][1])
        r = call("POST", f"/v1/rider/deliveries/{stop['order_id']}/pickup", rider)
        check(f"collected at {stop['name']}", r.get("status") == "picked_up", r.get("status"))
    codes = {call("GET", f"/v1/orders/{oid}/codes", who)["delivery_code"] for oid in ids}
    check("one delivery code for the whole trip", len(codes) == 1, len(codes))
    for oid in ids:
        call("POST", f"/v1/rider/deliveries/{oid}/in-transit", rider)
        call("POST", f"/v1/rider/deliveries/{oid}/deliver", rider, {"code": next(iter(codes))})
    for oid in ids:
        final = get_order(oid, who)
        for _ in range(20):
            if final["status"] == "completed":
                break
            time.sleep(0.5)
            final = get_order(oid, who)
        check(f"order {oid[:6]} delivered and completed", final["status"] == "completed", final["status"])
    check("the trip is finished", call("GET", "/v1/rider/trip", rider)["trips"] == [])


@flow
def market_order() -> None:
    """Buy Foodstuff: a shopper buys foodstuff by market measures (beef by weight, a soup combo, yam)"""
    shops = items_of(call("GET", "/v1/restaurants", params={"city": "lagos", "vertical": "market"}))
    check("market shoppers are listed and say so", all(s.get("badge") == "Shopper" for s in shops), shops[:2])
    detail = shop_order(
        "m-lekki-market",
        [("lm-beef", 1), ("lm-combo-egusi", 1), ("lm-yam-tuber", 2)],
        "Sent to your shopper",
        "foodstuff",
    )
    measures = {i.get("unit_label") for sec in detail["sections"] for i in sec["items"]}
    check(
        "foodstuff is sold by market measures",
        {"derica", "half paint"} <= measures,
        sorted(m for m in measures if m)[:10],
    )


@flow
def parcel_bike_delivery() -> None:
    """Package Delivery (book a bike rider): Lekki to Victoria Island with pickup and drop-off codes"""
    riders_online()
    q = call(
        "POST",
        "/v1/parcels/quotes",
        "customer",
        {
            "pickup": PICKUP,
            "dropoff": DROPOFF_VI,
            "size": "small",
            "category": "documents",
            "description": "E2E contract",
        },
        expect=201,
    )
    check("parcel quote has a price", q.get("breakdown", {}).get("total_kobo", 0) > 0, q.get("breakdown"))
    order = call("POST", "/v1/parcels", "customer", {"quote_id": q["id"]}, expect=201, idem=True)
    check("parcel booked", order.get("vertical") == "parcel", order.get("vertical"))
    pay_by_card(order["id"])
    o = get_order(order["id"])
    check("parcel paid", o["payment"]["status"] == "paid", (o["status"], o.get("payment")))
    deliver(order["id"], has_shop=False)
    ledger_balanced()


@flow
def interstate_waybill() -> None:
    """Interstate waybill: Lagos to Enugu, hub drop-off, line-haul trip, collection with a code"""
    check("waybill origins listed", call("GET", "/v1/waybill/origins"))
    q = call(
        "POST",
        "/v1/waybills/quotes",
        "customer",
        {
            "origin_city": "lagos",
            "destination_city": "enugu",
            "first_mile": "dropoff",
            "last_mile": "collect",
            "sender": WAYBILL_SENDER,
            "recipient": WAYBILL_RECIPIENT,
            "size": "small",
            "weight_kg": 3.2,
            "category": "clothing",
            "description": "E2E: two ankara dresses",
        },
        expect=201,
    )
    order = call(
        "POST", "/v1/waybills", "customer", {"quote_id": q["id"], "channel": "web"}, expect=201, idem=True
    )
    pay_by_card(order["id"])
    o = get_order(order["id"])
    wb = o.get("waybill") or {}
    code = wb.get("tracking_code") or o.get("tracking_code")
    origin = wb.get("origin_hub_id") or (wb.get("origin_hub") or {}).get("id")
    dest = wb.get("destination_hub_id") or (wb.get("destination_hub") or {}).get("id")
    check(
        "waybill paid, tracking code issued",
        o["payment"]["status"] == "paid" and code and origin and dest,
        (o["status"], wb),
    )
    hub_post("/v1/admin/waybills/receive", {"hub_id": origin, "tracking_code": code})
    check("origin hub receives the parcel", True)
    hub_post(
        "/v1/admin/waybills/depart",
        {"hub_id": origin, "tracking_codes": [code], "trip_reference": "E2E-TRIP-1"},
    )
    check("line-haul trip departs", True)
    hub_post("/v1/admin/waybills/arrive", {"hub_id": dest, "tracking_code": code})
    check("destination hub receives it", True)
    tracked = call("GET", f"/v1/track/{code}")
    check(
        "public tracking says ready for collection",
        "collection" in str(tracked.get("label", "")).lower(),
        tracked,
    )
    codes = call("GET", f"/v1/orders/{order['id']}/codes", "customer")
    collect = codes.get("pickup_code")  # the recipient shows the pickup code at the hub
    check("customer has a pickup code for the hub", collect, list(codes))
    hub_post(
        "/v1/admin/waybills/collect",
        {"hub_id": dest, "tracking_code": code, "code": wrong(collect)},
        expect=422,
    )
    check("a wrong pickup code is refused at the hub", True)
    hub_post("/v1/admin/waybills/collect", {"hub_id": dest, "tracking_code": code, "code": collect})
    tracked = call("GET", f"/v1/track/{code}")
    check(
        "public tracking shows it collected",
        "collect" in str(tracked).lower() or "delivered" in str(tracked).lower(),
        tracked,
    )
    ledger_balanced()


def hub_post(path: str, body: dict, expect: int | tuple[int, ...] = (200, 201, 204)) -> Any:
    try:
        return call("POST", path, "hub", body, expect=expect)
    except Fail as exc:
        if " 403:" not in str(exc):
            raise
        return call("POST", path, "admin", body, expect=expect)  # the demo hub agent may be scoped to one hub


@flow
def group_order_split_bill() -> None:
    """Group order: a friend joins with a code, each adds food, the bill is split and each pays a share"""
    riders_online()
    g = call(
        "POST",
        "/v1/group-orders",
        "customer",
        {"restaurant_id": JJ, "fulfillment": "delivery", "delivery_address": ADDRESS, "split_mode": "each"},
        expect=201,
    )
    gid = g["id"]
    code = g.get("code") or g.get("join_code") or g.get("invite_code")
    check("group created with a join code", code, list(g))
    call("POST", "/v1/group-orders/join", "friend", {"code": code})
    check("friend joins", True)
    call("PUT", f"/v1/group-orders/{gid}/lines", "customer", {"lines": [JJ_LINES[0] | {"quantity": 1}]})
    call("PUT", f"/v1/group-orders/{gid}/lines", "friend", {"lines": [JJ_LINES[1]]})
    for who in ("customer", "friend"):
        call("PUT", f"/v1/group-orders/{gid}/ready", who, {"ready": True})
    call("POST", f"/v1/group-orders/{gid}/lock", "customer", {})
    call("POST", f"/v1/group-orders/{gid}/checkout", "customer", {"channel": "web"}, idem=True)
    check("host locks the basket and checks out", True)
    for who in ("customer", "friend"):
        complete_sandbox(call("POST", f"/v1/group-orders/{gid}/pay", who, {}, idem=True))
    g2 = call("GET", f"/v1/group-orders/{gid}", "customer")
    order_id = g2.get("order_id") or (g2.get("order") or {}).get("id")
    check(
        "everyone paid their share; one order created",
        order_id,
        {k: g2.get(k) for k in ("status", "order_id")},
    )
    o = get_order(order_id)
    check(
        "group order sent to the kitchen",
        o["status"] == "submitted_to_restaurant",
        (o["status"], o.get("payment")),
    )
    deliver(order_id)
    ledger_balanced()


@flow
def plus_and_rewards() -> None:
    """Yummy Chops Plus and rewards: subscribe, member benefit on a quote, referral code, points"""
    plus = call("GET", "/v1/plus", "customer")
    if not plus.get("member"):
        complete_sandbox(call("POST", "/v1/plus/subscribe", "customer", {}, idem=True))
        plus = call("GET", "/v1/plus", "customer")
    check("customer is a Plus member", plus.get("member") and plus.get("membership"), plus.get("membership"))
    b = quote()["breakdown"]
    check("member benefit shows on the quote", b["discount_kobo"] > 0 or b["delivery_fee_kobo"] == 0, b)
    rewards = call("GET", "/v1/rewards", "customer")
    check("points balance and referral code", "points" in rewards, list(rewards))
    ref = rewards.get("referral_code") or (rewards.get("referral") or {}).get("code")
    if ref:
        r = client.post(
            f"{API}/v1/rewards/referral",
            json={"code": ref},
            headers={"Authorization": f"Bearer {token('friend')}"},
        )
        check(
            "friend can apply the referral code (or already has)",
            r.status_code in (200, 201, 409, 422),
            r.text[:300],
        )
    if rewards.get("points", 0) >= 500:
        call("POST", "/v1/rewards/redeem", "customer", {"points": 500}, idem=True)
        check("500 points redeemed for a voucher", True)


@flow
def support_and_disputes() -> None:
    """Support: a ticket on a delivered order reaches the support desk; a dispute can be raised"""
    oid = STATE.get("completed_order")
    check("a delivered order is available", oid)
    t = call(
        "POST",
        "/v1/support/tickets",
        "customer",
        {
            "order_id": oid,
            "category": "quality",
            "description": "E2E check: the food was cold",
            "channel": "web",
        },
    )
    tid = t.get("id") or (t.get("ticket") or {}).get("id")
    desk = items_of(call("GET", "/v1/admin/support/tickets", "support"))
    check("support agent sees the ticket", any(x.get("id") == tid for x in desk), tid)
    r = client.post(
        f"{API}/v1/orders/{oid}/dispute",
        json={"reason": "E2E check: a drink was missing"},
        headers={"Authorization": f"Bearer {token('customer')}"},
    )
    check("dispute accepted or explained", r.status_code in (200, 201, 409, 422), r.text[:300])


@flow
def partner_tools() -> None:
    """Partner dashboard tools: menu item add/hide/delete, pause orders, analytics, settlements, balance"""
    menu = call("GET", f"/v1/partner/restaurants/{JJ}/menu", "owner")
    cat = (menu.get("categories") or [{}])[0].get("id")
    item = call(
        "POST",
        f"/v1/partner/restaurants/{JJ}/items",
        "owner",
        {
            "category_id": cat,
            "name": "E2E Test Plate",
            "price_kobo": 150_000,
            "description": "From the E2E check",
        },
    )
    iid = item.get("id") or (item.get("item") or {}).get("id")
    check("owner adds a menu item", iid, item)
    call("PATCH", f"/v1/partner/restaurants/{JJ}/items/{iid}/availability", "kitchen", {"available": False})
    check("kitchen hides it (sold out)", True)
    call("DELETE", f"/v1/partner/restaurants/{JJ}/items/{iid}", "owner", expect=(200, 204))
    check("owner deletes it", True)
    call("PUT", f"/v1/partner/restaurants/{JJ}/accepting", "owner", {"accepting": False})
    shut = call("GET", f"/v1/restaurants/{JJ}")["restaurant"]
    call("PUT", f"/v1/partner/restaurants/{JJ}/accepting", "owner", {"accepting": True})
    check(
        "pausing orders shows on the public page",
        shut.get("is_accepting_orders") is False,
        shut.get("is_accepting_orders"),
    )
    reopened = call("GET", f"/v1/restaurants/{JJ}")["restaurant"]
    check(
        "resuming orders shows too",
        reopened.get("is_accepting_orders") is True,
        reopened.get("is_accepting_orders"),
    )
    for path in ("analytics", "settlements"):
        call("GET", f"/v1/partner/restaurants/{JJ}/{path}", "owner")
    call("GET", "/v1/seller/balance", "owner")
    check("analytics, settlements and balance load", True)


@flow
def business_and_split_payments() -> None:
    """Businesses (ADR-0028): a business ID, a branch on the same menu, a bank account, a split card payment"""
    mine = call("GET", "/v1/partner/business", "owner")
    if any(r["restaurant_id"] == JJ for r in mine["without_business"]):
        call("POST", "/v1/partner/business", "owner", {"restaurant_id": JJ}, expect=201)
        mine = call("GET", "/v1/partner/business", "owner")
    business = next(b for b in mine["businesses"] if any(br["restaurant_id"] == JJ for br in b["branches"]))
    bid = business["id"]
    check("the shop has a business ID", re.fullmatch(r"YCB-[2-9A-HJ-NP-Z]{6}", bid), bid)
    if len(business["branches"]) == 1:
        business = call(
            "POST",
            f"/v1/partner/business/{bid}/branches",
            "owner",
            {
                "branch_name": "E2E Ikeja",
                "address": "1 Allen Avenue",
                "area": "Ikeja",
                "location": {"lat": 6.6018, "lng": 3.3515},
                "manager_phone": "+2348044444444",
            },
            expect=201,
        )
    branch = next(b for b in business["branches"] if not b["main"])
    TOKENS.pop("owner", None)  # a fresh sign-in lists the new branch
    menu = call("GET", f"/v1/partner/restaurants/{branch['restaurant_id']}/menu", "owner")
    main_menu = call("GET", f"/v1/partner/restaurants/{JJ}/menu", "owner")
    check(
        "the branch sells the main branch's menu",
        {i["id"] for i in menu["items"]} == {i["id"] for i in main_menu["items"]},
    )
    banks = call("GET", "/v1/partner/banks", "owner")
    connected = call(
        "PUT",
        f"/v1/partner/business/{bid}/bank",
        "owner",
        {"bank_code": banks[0]["code"], "account_number": "0123456789"},
    )
    check(
        "the bank account is connected; only its last 4 digits are kept",
        connected["bank_connected"]
        and connected["settlement_account_last4"] == "6789"
        and "0123456789" not in str(connected),
        connected,
    )
    riders_online()
    order = paid_order()
    board = items_of(call("GET", f"/v1/partner/restaurants/{JJ}/orders", "owner"))
    seen = next(o for o in board if o["id"] == order["id"])
    share = seen.get("restaurant_earning_kobo") or 0
    check(
        "the card payment is split: the shop's share goes to its bank account",
        share > 0 and seen["payment"].get("split_to_business_kobo") == share,
        seen["payment"],
    )
    deliver(order["id"])
    ledger_balanced()


@flow
def onboarding_applications() -> None:
    """Sign-ups: a brand-new person signs up, applies to ride and to list a shop; admin approves both"""
    email = f"applicant-{uuid.uuid4().hex[:8]}@yummychops.test"
    r = httpx.post(
        f"http://{EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key",
        json={"email": email, "password": PASSWORD, "returnSecureToken": True},
        timeout=20,
    )
    check("a new customer signs up", r.status_code == 200, r.text[:200])
    EMAILS["applicant"], TOKENS["applicant"] = email, r.json()["idToken"]
    call("GET", "/v1/me", "applicant")
    rider_app = call(
        "POST",
        "/v1/applications/rider",
        "applicant",
        {
            "full_name": "E2E Applicant",
            "phone": "+2348099999999",
            "email": email,
            "residential_address": "1 Admiralty Way, Lekki",
            "vehicle": "motorcycle",
            "city": "lagos",
        },
    )
    complete_rider_kyc("applicant", "E2E Applicant")
    check(
        "the new rider completes their KYC",
        call("GET", "/v1/rider/kyc", "applicant")["status"] == "submitted",
    )
    shop_app = call(
        "POST",
        "/v1/applications/restaurant",
        "applicant",
        {
            "business_name": "E2E Test Kitchen",
            "cac_number": "RC1234567",
            "contact_name": "E2E Applicant",
            "contact_phone": "+2348099999999",
            "email": email,
            "address": "1 Admiralty Way",
            "area": "Lekki Phase 1",
            "location": LEKKI,
            # A second branch (ADR-0028); the bank account comes later, in the partner dashboard.
            "branches": [
                {
                    "address": "7 Ajose Adeogun Street",
                    "area": "Victoria Island",
                    "location": ADDRESS["location"],
                },
            ],
            "cuisines": ["nigerian"],
        },
    )
    check("rider and shop applications submitted", rider_app and shop_app)
    for app in (rider_app, shop_app):
        aid = app.get("id") or (app.get("application") or {}).get("id")
        call(
            "POST",
            f"/v1/admin/applications/{aid}/decision",
            "admin",
            {"approve": True, "reason": "E2E check"},
        )
    mine = items_of(call("GET", "/v1/applications/mine", "applicant"))
    check(
        "admin approves both",
        mine and all(a.get("status") == "approved" for a in mine),
        [a.get("status") for a in mine],
    )
    TOKENS.pop("applicant")  # a fresh token carries the new roles
    me = call("GET", "/v1/me", "applicant")
    check("the new rider and shop roles are on the account", "rider" in str(me), me)
    [business] = call("GET", "/v1/partner/business", "applicant")["businesses"]
    check(
        "the new business gets its ID and both branches",
        re.fullmatch(r"YCB-[2-9A-HJ-NP-Z]{6}", business["id"]) and len(business["branches"]) == 2,
        business,
    )
    listed = items_of(call("GET", "/v1/restaurants", params={"city": "lagos", "q": "E2E Test Kitchen"}))
    check("the new shop stays hidden until it is set up", not listed, [s.get("name") for s in listed])


@flow
def payouts_and_settlements() -> None:
    """Money out: rider cash-out, shop payout request, settlements generated"""
    earnings = call("GET", "/v1/rider/earnings", "rider1")
    available = next((v for k, v in earnings.items() if "available" in k and isinstance(v, int)), None)
    check("rider sees an available balance", available is not None, earnings)
    if available and available >= 100_000:
        p = call("POST", "/v1/rider/payouts", "rider1", {"amount_kobo": 100_000}, idem=True)
        pid = p.get("id") or (p.get("payout") or {}).get("id")
        call(
            "POST",
            f"/v1/admin/payouts/{pid}/decision",
            "finance",
            {"approve": True, "bank_reference": "E2E-BANK-1"},
        )
        check("finance pays the rider's cash-out", True)
    bal = call("GET", "/v1/seller/balance", "owner")
    shop_available = next((v for k, v in bal.items() if "available" in k and isinstance(v, int)), None)
    check("shop sees its balance", shop_available is not None, bal)
    if shop_available and shop_available >= 100_000:
        sp = call(
            "POST",
            "/v1/seller/payouts",
            "owner",
            {
                "amount_kobo": 100_000,
                "bank_name": "Test Bank",
                "account_number": "0000000000",
                "account_name": "Jollof Junction",
            },
            idem=True,
        )
        spid = sp.get("id") or (sp.get("payout") or {}).get("id")
        call(
            "POST",
            f"/v1/admin/seller-payouts/{spid}/decision",
            "finance",
            {"approve": True, "bank_reference": "E2E-BANK-2"},
        )
        check("finance pays the shop's payout", True)
    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + 60))  # period_end is exclusive
    week_ago = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() - 7 * 86400))
    call("POST", "/v1/admin/settlements/generate", "finance", {"period_start": week_ago, "period_end": now})
    rows = items_of(call("GET", "/v1/admin/settlements", "finance"))
    check("weekly settlements generated", len(rows) > 0, rows[:1])
    ledger_balanced()


@flow
def admin_console() -> None:
    """Command Centre: every admin view loads for the right role"""
    views = {
        "admin": [
            "overview",
            "analytics",
            "orders",
            "riders",
            "riders/live",
            "restaurants",
            "applications",
            "refunds",
            "payments",
            "audit",
            "flags",
            "growth",
            "hubs",
            "vouchers",
            "config/pricing",
            "config/logistics",
            "maps/status",
        ],
        "finance": ["ledger", "cash", "settlements", "payouts", "seller-payouts"],
        "support": ["support/tickets"],
    }
    failures = []
    for who, paths in views.items():
        for path in paths:
            try:
                call("GET", f"/v1/admin/{path}", who)
            except Fail as exc:
                failures.append(str(exc)[:200])
    check(f"{sum(map(len, views.values()))} admin views load", not failures, failures)
    oid = STATE.get("completed_order")
    if oid:
        full = call("GET", f"/v1/admin/orders/{oid}", "admin")
        check("admin sees the full order with its settlement", full, list(full)[:8])


@flow
def access_control() -> None:
    """Access control: anonymous users, other customers, kitchens and riders only see what they should"""
    oid = STATE.get("completed_order") or "missing"
    call("POST", "/v1/quotes", None, {}, expect=401)
    call("GET", f"/v1/orders/{oid}", "friend", expect=(403, 404))
    call("GET", f"/v1/partner/restaurants/{JJ}/orders", "customer", expect=403)
    call("GET", "/v1/admin/ledger", "customer", expect=403)
    call("GET", "/v1/admin/ledger", "kitchen", expect=403)
    call("GET", "/v1/admin/orders", "rider1", expect=403)
    call(
        "POST",
        f"/v1/partner/restaurants/{JJ}/items",
        "kitchen",
        {"category_id": "x", "name": "x", "price_kobo": 1},
        expect=(403, 422),
    )
    check("every forbidden request is refused", True)


@flow
def gudy_assistant() -> None:
    """Yummy, the AI assistant: answers a food request for the signed-in customer"""
    check("Yummy service healthy", call("GET", f"{AGENTS}/health"))
    chat = call(
        "POST",
        f"{AGENTS}/v1/chat",
        "customer",
        {"message": "I want jollof rice delivered to Lekki", "channel": "app"},
    )
    text = str(chat)
    check(
        "Yummy replies with suggestions",
        len(text) > 40 and ("jollof" in text.lower() or "restaurant" in text.lower()),
        text[:400],
    )
    STATE["gudy_thread"] = chat.get("thread_id")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    wanted = set(sys.argv[1:])
    ensure_accounts()
    open_all_day(JJ, "owner")
    try:
        run(wanted)
    finally:
        restore_hours()
        park_extra_riders()
    failed = [r for r in RESULTS if not r[2]]
    print(f"\n{len(RESULTS) - len(failed)} passed, {len(failed)} failed")
    for journey, name, _, detail in failed:
        print(f"  - {journey}: {name} :: {detail[:300]}")
    return 1 if failed else 0


def run(wanted: set[str]) -> None:
    for fn in FLOWS:
        if wanted and fn.__name__ not in wanted:
            continue
        CURRENT[0] = fn.__name__
        print(f"\n== {fn.__doc__}", flush=True)
        try:
            fn()
        except Fail as exc:
            if not RESULTS or RESULTS[-1][0] != fn.__name__ or RESULTS[-1][2]:
                RESULTS.append((fn.__name__, "request failed", False, str(exc)))
                print(f"  FAIL {exc}", flush=True)
        except Exception as exc:  # report and keep going with the next journey
            RESULTS.append((fn.__name__, "crashed", False, repr(exc)))
            print(f"  CRASH {exc!r}", flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
