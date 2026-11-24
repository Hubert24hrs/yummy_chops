"""Pilot simulation (owner, 2026-11-22: "simulate it"): a small Lekki pilot against a SEPARATE copy of the API.

Five nearby shops (two restaurants, a supermarket, a pharmacy and a market shopper), five riders and twelve
customers. Orders arrive at random for a few minutes and are paid by card, wallet or cash on delivery; about one in
ten is a parcel (Package Delivery). Three riders are seeded demo riders; two sign up from scratch, apply to ride and
are approved by an admin, as the pilot's real riders will be.

Business rules are the production defaults: an offer runs out after 45 s, a rider who missed one is asked again
only after 5 minutes, the first search radius is 6 km, riders stop getting cash jobs at N50,000 held, and pay on
delivery needs one completed prepaid order first. Two things stand in for people: the demo shops accept an order
after about 12 s and pack it 30 s later (the local autopilot), and the simulated riders ride 30 times faster than
real life and leave one offer in ten to run out. So the times measure the platform's own steps, not shops or traffic.

At the end it writes docs/PILOT_SIMULATION.md (orders, step times, riders, shops, money, problems).

It never touches the phone test: it starts its own API on port 8010 with its own memory store and ledger file, and
stops it when done. It shares only the Auth emulator (127.0.0.1:9099, which must be running), where it adds
sim-*@yummychops.test accounts with the same emulator-only password as the other demo accounts.

    services/api/.venv/Scripts/python services/api/scripts/pilot_sim.py [--orders 30] [--minutes 8] [--seed 7]
"""

from __future__ import annotations

import argparse
import contextlib
import math
import os
import random
import re
import statistics
import subprocess
import sys
import tempfile
import threading
import time
import uuid
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

import httpx

PORT = 8010
ROOT = Path(__file__).resolve().parents[3]
API_DIR = ROOT / "services" / "api"
REPORT = ROOT / "docs" / "PILOT_SIMULATION.md"
LEKKI = {"lat": 6.4478, "lng": 3.4723}  # Lekki Phase 1, where the pilot runs
VI = {"lat": 6.4281, "lng": 3.4219}  # Victoria Island, where some parcels go
SPEEDUP = 30  # riders ride this many times faster than real life
RIDER_KMH = 25  # a motorbike in Lekki traffic
IGNORE_SHARE = 0.1  # share of offers a rider leaves to run out
PARCEL_SHARE = 0.1  # share of orders that are parcels (Package Delivery)
SHOPS_WANTED = {"food": 2, "grocery": 1, "pharmacy": 1, "market": 1}
SHOP_MIX = {"food": 0.6, "grocery": 0.15, "pharmacy": 0.15, "market": 0.1}  # shares of shop orders by kind
PAYMENT_MIX = {"card": 0.5, "wallet": 0.2, "cash": 0.3}  # how customers want to pay
DONE = {"delivered", "completed"}
ENDED = DONE | {"cancelled", "refund_pending", "refunded", "rejected", "failed", "expired"}
SEEDED_RIDERS = {"rider2": "demo-rider-2", "rider3": "demo-rider-3", "rider4": "demo-rider-4"}
KIND_NAMES = {
    "food": "Order Food",
    "grocery": "Shop & Groceries",
    "pharmacy": "Pharmacy",
    "market": "Buy Foodstuff",
    "parcel": "Package Delivery",
}

os.environ["E2E_API_URL"] = f"http://127.0.0.1:{PORT}"
sys.path.insert(0, str(Path(__file__).parent))
import e2e_local as e  # noqa: E402  (reads E2E_API_URL when imported)


class PerThreadClient:
    """e2e_local's helpers share one HTTP client; each rider thread gets its own instead."""

    def __init__(self) -> None:
        self._local = threading.local()

    def _client(self) -> httpx.Client:
        if not hasattr(self._local, "client"):
            self._local.client = httpx.Client(timeout=60)
        return self._local.client

    def request(self, *args: Any, **kwargs: Any) -> httpx.Response:
        return self._client().request(*args, **kwargs)

    def get(self, *args: Any, **kwargs: Any) -> httpx.Response:
        return self._client().get(*args, **kwargs)


e.client = PerThreadClient()
RIDERS: dict[str, str] = {}  # sim rider name -> uid
LOCK = threading.Lock()
STOP = threading.Event()
PROBLEMS: list[str] = []
OFFERS = {"seen": 0, "left_to_run_out": 0, "taken_by_someone_else": 0}


def problem(text: str) -> None:
    with LOCK:
        PROBLEMS.append(text[:300])
    print(f"  ! {text[:240]}", flush=True)


def naira(kobo: int) -> str:
    return f"₦{kobo / 100:,.0f}"


# ------------------------------------------------------------------------------------------------ the API copy
def start_api(log: Path) -> subprocess.Popen[bytes]:
    """Our own API: memory store with the demo shops, its own ledger file and the production business rules, plus
    the two local stand-ins (shops open around the clock, the shop autopilot)."""
    with contextlib.suppress(httpx.HTTPError):
        e.client.get(f"{e.API}/v1/health", timeout=2)
        raise SystemExit(f"Something is already running on port {PORT}; stop it first.")
    py = API_DIR / (".venv/Scripts/python.exe" if os.name == "nt" else ".venv/bin/python")
    ledger = Path(tempfile.gettempdir()) / "yummy_pilot_sim.db"
    ledger.unlink(missing_ok=True)
    env = os.environ | {
        "ENVIRONMENT": "local",
        "DATA_BACKEND": "memory",
        "SEED_DEMO_DATA": "true",
        "DATABASE_URL": f"sqlite+aiosqlite:///{ledger.as_posix()}",
        "PUBLIC_BASE_URL": f"http://127.0.0.1:{PORT}",
        "PAYMENT_CALLBACK_URL": "http://localhost:3000/checkout/callback",
        "INTERNAL_SHARED_SECRET": "local-dev-only",
        "CHECK_TOKEN_REVOCATION": "false",
        "FIREBASE_AUTH_EMULATOR_HOST": e.EMULATOR,
        "FIREBASE_PROJECT_ID": e.PROJECT,
        "DEMO_SHOPS_ALWAYS_OPEN": "true",
        "DEMO_SHOP_AUTOPILOT": "true",
        "WHATSAPP_ENABLED": "false",
        "PYTHONUNBUFFERED": "1",
    }
    for name in ("DISPATCH_PICKUP_RADIUS_KM", "DISPATCH_REOFFER_SECONDS", "RIDER_CASH_LIMIT_KOBO"):
        env.pop(name, None)  # production defaults, not the phone test's shortcuts
    out = log.open("w", encoding="utf-8")
    proc = subprocess.Popen(  # noqa: S603  (our own API with fixed arguments)
        [str(py), "-m", "uvicorn", "--factory", "gudmeal_api.main:app_factory", "--port", str(PORT)],
        cwd=API_DIR,
        env=env,
        stdout=out,
        stderr=subprocess.STDOUT,
    )
    for _ in range(120):
        with contextlib.suppress(httpx.HTTPError):
            if e.client.get(f"{e.API}/v1/health", timeout=3).status_code == 200:
                return proc
        if proc.poll() is not None:
            raise SystemExit(f"The API copy stopped while starting; see {log}")
        time.sleep(1)
    proc.terminate()
    raise SystemExit(f"The API copy did not start within 2 minutes; see {log}")


# ------------------------------------------------------------------------------------------------ accounts
def customer_accounts(count: int) -> list[str]:
    """Sim customers in the Auth emulator (no roles, like anyone who signs up); each opens the app once."""
    from firebase_admin import auth

    names = []
    for n in range(1, count + 1):
        name, uid = f"sim{n:02d}", f"sim-customer-{n:02d}"
        email = f"{uid}@yummychops.test"
        profile = {
            "email": email,
            "password": e.PASSWORD,
            "display_name": f"Sim Customer {n}",
            "email_verified": True,
        }
        try:
            auth.update_user(uid, **profile)
        except auth.UserNotFoundError:
            auth.create_user(uid=uid, **profile)
        e.EMAILS[name] = email
        e.call("GET", "/v1/me", name)
        names.append(name)
    return names


def onboard_rider(n: int) -> tuple[str, str]:
    """A new person signs up, applies to ride and an admin approves them, as the pilot's real riders will."""
    from firebase_admin import auth

    name, email = f"rider{n}", f"sim-rider-{n}@yummychops.test"
    with contextlib.suppress(auth.UserNotFoundError):
        auth.delete_user(auth.get_user_by_email(email).uid)  # each run starts from a clean sign-up
    r = httpx.post(
        f"http://{e.EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key",
        json={"email": email, "password": e.PASSWORD, "returnSecureToken": True},
        timeout=20,
    )
    if r.status_code != 200:
        raise e.Fail(f"{email} could not sign up: {r.text[:200]}")
    e.EMAILS[name], e.TOKENS[name] = email, r.json()["idToken"]
    e.call("GET", "/v1/me", name)
    application = e.call(
        "POST",
        "/v1/applications/rider",
        name,
        {
            "full_name": f"Sim Rider {n}",
            "phone": f"+234803{n:07d}",
            "email": email,
            "residential_address": "Lekki Phase 1",
            "vehicle": "motorcycle",
            "city": "lagos",
        },
    )
    e.complete_rider_kyc(name, f"Sim Rider {n}")  # the KYC the team checks before verifying a rider
    aid = application.get("id") or (application.get("application") or {}).get("id")
    e.call(
        "POST",
        f"/v1/admin/applications/{aid}/decision",
        "admin",
        {"approve": True, "reason": "Pilot simulation"},
    )
    e.TOKENS.pop(name)  # a fresh token carries the rider role
    return name, r.json()["localId"]


# ------------------------------------------------------------------------------------------------ places
def km(a: dict, b: dict) -> float:
    rad = math.radians
    h = (
        math.sin(rad(b["lat"] - a["lat"]) / 2) ** 2
        + math.cos(rad(a["lat"])) * math.cos(rad(b["lat"])) * math.sin(rad(b["lng"] - a["lng"]) / 2) ** 2
    )
    return 2 * 6371 * math.asin(math.sqrt(h))


def near(point: dict, spread_km: float, rng: random.Random) -> dict:
    d = spread_km * math.sqrt(rng.random())
    angle = rng.random() * 2 * math.pi
    return {
        "lat": round(point["lat"] + d / 111 * math.sin(angle), 6),
        "lng": round(point["lng"] + d / 111 * math.cos(angle), 6),
    }


def phone(rng: random.Random) -> str:
    return f"+234803{rng.randint(1_000_000, 9_999_999)}"


def pick_shops() -> list[dict]:
    """The nearest demo shops of each kind within 6 km of Lekki Phase 1."""
    cards = e.items_of(
        e.call(
            "GET",
            "/v1/restaurants",
            params={"city": "lagos", "vertical": "all", "sort": "distance", "limit": 100, **LEKKI},
        )
    )
    shops = []
    for vertical, count in SHOPS_WANTED.items():
        close = [
            c
            for c in cards
            if c["vertical"] == vertical
            and c.get("is_accepting_orders", True)
            and (c.get("distance_km") or 99) <= 6
        ]
        shops += sorted(close, key=lambda c: c["distance_km"])[:count]
    if not shops:
        raise SystemExit("No demo shops within 6 km of Lekki Phase 1")
    return shops


# ------------------------------------------------------------------------------------------------ orders
@dataclass
class Sim:
    order_id: str
    short: str
    customer: str
    kind: str
    shop: str
    wanted: str
    paid_with: str
    total_kobo: int
    subtotal_kobo: int
    placed: float
    note: str | None = None
    rider: str | None = None
    rider_took: float | None = None
    waited_at_counter: float | None = None
    status: str = "placed"


ORDERS: dict[str, Sim] = {}


def basket(detail: dict, minimum: int, rng: random.Random) -> list[dict]:
    """A few products, enough for the shop's minimum order, with the first choice wherever one is required."""
    groups = detail.get("option_groups") or {}
    if isinstance(groups, list):
        groups = {g["id"]: g for g in groups}
    items = [
        i
        for sec in detail.get("sections", [])
        for i in sec.get("items", [])
        if i.get("is_available", True) and not i.get("requires_prescription")
    ]
    want = rng.choice([1, 2, 2, 3])
    lines: list[dict] = []
    total = 0
    for item in rng.sample(items, k=len(items)):
        if len(lines) >= want and total >= minimum * 1.05:
            break
        quantity = rng.choice([1, 1, 2])
        selections = []
        for gid in item.get("option_group_ids", []):
            need = groups.get(gid, {}).get("min_select") or 0
            if need:
                picks = [c["id"] for c in groups[gid].get("choices", []) if c.get("is_available", True)][
                    :need
                ]
                selections.append({"group_id": gid, "choice_ids": picks})
        lines.append(
            {"item_id": item["id"], "quantity": quantity} | ({"selections": selections} if selections else {})
        )
        total += item.get("price_kobo", 0) * quantity
    return lines


def pay(order_id: str, who: str, wanted: str) -> tuple[str, str | None]:
    """Pays the way the customer wants to; returns how it was paid and, when that differs, why."""
    methods = {m["id"]: m for m in e.call("GET", f"/v1/orders/{order_id}/payment-options", who)["methods"]}
    note = None
    if wanted == "cash":
        if methods["cash"]["available"]:
            e.call("POST", f"/v1/orders/{order_id}/checkout", who, {"provider": "cash"}, idem=True)
            return "cash", None
        note = methods["cash"].get("reason") or "pay on delivery was not offered"
        wanted = "card"
    if wanted == "wallet":
        short = methods["wallet"].get("short_by_kobo") or 0
        if short:
            amount = -(-max(short, 2_000_000) // 100_000) * 100_000  # at least N20,000, in whole N1,000s
            e.complete_sandbox(e.call("POST", "/v1/wallet/topups", who, {"amount_kobo": amount}, idem=True))
        e.call("POST", f"/v1/orders/{order_id}/checkout", who, {"provider": "wallet"}, idem=True)
        return "wallet", note
    e.pay_by_card(order_id, who)
    return "card", note


def record(order: dict, quote: dict, who: str, kind: str, shop: str, wanted: str) -> None:
    paid_with, note = pay(order["id"], who, wanted)
    b = quote["breakdown"]
    sim = Sim(
        order_id=order["id"],
        short=order.get("short_code") or order["id"][:8],
        customer=who,
        kind=kind,
        shop=shop,
        wanted=wanted,
        paid_with=paid_with,
        total_kobo=b["total_kobo"],
        subtotal_kobo=b.get("subtotal_kobo", 0),
        placed=time.time(),
        note=note,
    )
    with LOCK:
        ORDERS[sim.order_id] = sim
    print(
        f"  + {sim.short:<8} {KIND_NAMES[kind]:<17} {shop[:28]:<28} {paid_with:<6} {naira(sim.total_kobo)}",
        flush=True,
    )


def place_shop_order(who: str, shop: dict, detail: dict, wanted: str, rng: random.Random) -> None:
    address = {
        "label": "Home",
        "line1": f"{rng.randint(1, 60)} Admiralty Way",
        "area": "Lekki Phase 1",
        "location": near(LEKKI, 2.5, rng),
        "contact_phone": phone(rng),
    }
    lines = basket(detail, shop.get("min_order_kobo") or 0, rng)
    body = {
        "restaurant_id": shop["id"],
        "lines": lines,
        "fulfillment": "delivery",
        "delivery_address": address,
    }
    quote = e.call("POST", "/v1/quotes", who, body, expect=201)
    order = e.call(
        "POST", "/v1/orders", who, {"quote_id": quote["id"], "channel": "app"}, expect=201, idem=True
    )
    record(order, quote, who, shop["vertical"], shop["name"], wanted)


def place_parcel(who: str, wanted: str, rng: random.Random) -> None:
    to_vi = rng.random() < 0.5
    body = {
        "pickup": {
            "name": "Sim Sender",
            "phone": phone(rng),
            "line1": f"{rng.randint(1, 40)} Fola Osibo Road",
            "area": "Lekki Phase 1",
            "location": near(LEKKI, 2.0, rng),
        },
        "dropoff": {
            "name": "Sim Recipient",
            "phone": phone(rng),
            "line1": f"{rng.randint(1, 40)} {'Ajose Adeogun Street' if to_vi else 'Admiralty Way'}",
            "area": "Victoria Island" if to_vi else "Lekki Phase 1",
            "location": near(VI if to_vi else LEKKI, 1.5, rng),
        },
        "size": "small",
        "category": rng.choice(["documents", "clothing", "cosmetics", "other"]),
        "description": "Pilot simulation parcel",
    }
    quote = e.call("POST", "/v1/parcels/quotes", who, body, expect=201)
    order = e.call("POST", "/v1/parcels", who, {"quote_id": quote["id"]}, expect=201, idem=True)
    record(order, quote, who, "parcel", "Package Delivery", wanted)


def run_orders(
    customers: list[str], shops: list[dict], details: dict, args: argparse.Namespace, rng: random.Random
):
    gap = args.minutes * 60 / max(1, args.orders)
    by_kind: dict[str, list[dict]] = {}
    for shop in shops:
        by_kind.setdefault(shop["vertical"], []).append(shop)
    kinds = [k for k in SHOP_MIX if k in by_kind]
    for n in range(args.orders):
        time.sleep(rng.expovariate(1 / gap))
        who = rng.choice(customers)
        wanted = rng.choices(list(PAYMENT_MIX), weights=list(PAYMENT_MIX.values()))[0]
        try:
            if rng.random() < PARCEL_SHARE:
                place_parcel(who, wanted, rng)
            else:
                kind = rng.choices(kinds, weights=[SHOP_MIX[k] for k in kinds])[0]
                shop = rng.choice(by_kind[kind])
                place_shop_order(who, shop, details[shop["id"]], wanted, rng)
        except e.Fail as exc:
            problem(f"order {n + 1} could not be placed: {exc}")


def wait_until_done(minutes: float) -> None:
    deadline = time.time() + minutes * 60
    while time.time() < deadline:
        still = []
        for sim in [s for s in ORDERS.values() if s.status not in ENDED]:
            sim.status = e.get_order(sim.order_id, sim.customer)["status"]
            if sim.status not in ENDED:
                still.append(sim)
        if not still:
            return
        print(f"  … {len(still)} still open: " + ", ".join(sorted({s.status for s in still})), flush=True)
        time.sleep(10)
    problem(
        f"{sum(s.status not in ENDED for s in ORDERS.values())} orders were still open after {minutes:.0f} min"
    )


# ------------------------------------------------------------------------------------------------ riders
def sim_for(order_id: str, seconds: float = 20) -> Sim | None:
    deadline = time.time() + seconds
    while time.time() < deadline:
        if order_id in ORDERS:
            return ORDERS[order_id]
        time.sleep(0.5)
    return None


class Rider(threading.Thread):
    def __init__(self, name: str, start: dict, rng: random.Random) -> None:
        super().__init__(daemon=True, name=name)
        self.who, self.at, self.rng = name, start, rng
        self.seen: set[str] = set()
        self.ignored: set[str] = set()
        self.last_ping = 0.0

    def ping(self, *, now: bool = False) -> None:
        if now or time.time() - self.last_ping >= 4:
            e.call("POST", "/v1/rider/location", self.who, self.at)
            self.last_ping = time.time()

    def ride(self, to: dict) -> None:
        """A straight line, 30 times faster than real life, sending the position every ~3 s like the app."""
        seconds = km(self.at, to) / RIDER_KMH * 3600 / SPEEDUP
        steps = max(1, math.ceil(seconds / 3))
        start = dict(self.at)
        for s in range(1, steps + 1):
            time.sleep(seconds / steps)
            self.at = {
                "lat": start["lat"] + (to["lat"] - start["lat"]) * s / steps,
                "lng": start["lng"] + (to["lng"] - start["lng"]) * s / steps,
            }
            self.ping(now=True)

    def run(self) -> None:
        try:
            e.call("PUT", "/v1/rider/availability", self.who, {"online": True})
            self.ping(now=True)
        except e.Fail as exc:
            problem(f"{self.who} could not go online: {exc}")
            return
        while not STOP.is_set():
            try:
                offer = self.next_offer()
                if offer:
                    self.work(offer)
                else:
                    time.sleep(2)
                    self.ping()
            except e.Fail as exc:
                problem(f"{self.who}: {exc}")
                time.sleep(3)

    def next_offer(self) -> dict | None:
        for offer in e.call("GET", "/v1/rider/offers", self.who):
            if offer["id"] not in self.seen:
                self.seen.add(offer["id"])
                looking_away = self.rng.random() < IGNORE_SHARE
                if looking_away:
                    self.ignored.add(offer["id"])
                with LOCK:
                    OFFERS["seen"] += 1
                    OFFERS["left_to_run_out"] += looking_away
            if offer["id"] not in self.ignored:
                return offer
        return None

    def view(self, order_id: str) -> dict:
        return next((o for o in e.call("GET", "/v1/rider/deliveries", self.who) if o["id"] == order_id), {})

    def work(self, offer: dict) -> None:
        order_id = offer["order_id"]
        took = e.call(
            "POST", f"/v1/rider/offers/{offer['id']}/accept", self.who, expect=(200, 400, 404, 409, 410, 422)
        )
        if isinstance(took, dict) and "error" in took:
            with LOCK:
                OFFERS["taken_by_someone_else"] += 1
            return
        sim = sim_for(order_id)
        if sim:
            sim.rider, sim.rider_took = self.who, time.time()
        self.ride(offer["pickup"])
        arrived = time.time()
        view = self.view(order_id)
        if not view:
            problem(f"{self.who}: order {order_id[:8]} is no longer in their deliveries")
            return
        if view.get("vertical") != "parcel":  # wait at the counter until the shop hands it over
            while not view.get("ready_at") and time.time() < arrived + 300 and not STOP.is_set():
                time.sleep(2)
                view = self.view(order_id) or view
            if not view.get("ready_at"):
                problem(f"order {order_id[:8]} was still not ready after 5 minutes at the counter")
        e.call("POST", f"/v1/rider/deliveries/{order_id}/pickup", self.who)
        if sim:
            sim.waited_at_counter = time.time() - arrived
        e.call("POST", f"/v1/rider/deliveries/{order_id}/in-transit", self.who)
        self.ride(offer.get("dropoff") or (view.get("delivery_address") or {}).get("location") or LEKKI)
        sim = sim or sim_for(order_id)
        if not sim:
            problem(f"{self.who}: no customer known for order {order_id[:8]}, so no delivery code")
            return
        code = e.call("GET", f"/v1/orders/{order_id}/codes", sim.customer).get("delivery_code")
        body: dict[str, Any] = {"code": code}
        if view.get("collect_cash_kobo"):
            body["cash_collected"] = True
        e.call("POST", f"/v1/rider/deliveries/{order_id}/deliver", self.who, body)
        print(f"  ✓ {self.who} delivered {sim.short}", flush=True)


# ------------------------------------------------------------------------------------------------ report
def ts(value: str | None) -> float | None:
    return datetime.fromisoformat(value).timestamp() if value else None


def gap(start: float | None, end: float | None) -> float | None:
    return end - start if start is not None and end is not None else None


def fmt(seconds: float) -> str:
    return f"{seconds:.0f} s" if seconds < 120 else f"{seconds / 60:.1f} min"


def spread(values: list[float | None]) -> str:
    clean = sorted(v for v in values if v is not None)
    if not clean:
        return "–"
    p90 = clean[min(len(clean) - 1, round(0.9 * (len(clean) - 1)))]
    return f"{fmt(statistics.median(clean))} · {fmt(p90)} · {fmt(clean[-1])}"


def final_view(sim: Sim) -> dict:
    """The full order as staff see it (with the money split), or the customer's view if staff cannot read it."""
    try:
        return e.call("GET", f"/v1/orders/{sim.order_id}", "admin")
    except e.Fail:
        return e.get_order(sim.order_id, sim.customer)


def end_of_day_cash() -> tuple[dict[str, int], list[str]]:
    """Each rider hands in the cash they collected; finance records it on the Cash page."""
    held, notes = {}, []
    for name, uid in RIDERS.items():
        held[name] = e.rider_cash(uid)
        if held[name]:
            e.call(
                "POST",
                f"/v1/admin/riders/{uid}/cash-remittances",
                "finance",
                {
                    "amount_kobo": held[name],
                    "method": "bank_transfer",
                    "reference": f"PILOT-{uuid.uuid4().hex[:8]}",
                },
                idem=True,
            )
            left = e.rider_cash(uid)
            if left:
                notes.append(f"{name} still holds {naira(left)} after handing in {naira(held[name])}")
    return held, notes


def trial_balance() -> tuple[int, int]:
    tb = e.call("GET", "/v1/admin/ledger", "finance")["trial_balance"]
    return tb["debits_kobo"], tb["credits_kobo"]


def longest_pause(log: Path) -> float:
    """The longest gap between two lines of the API log: it runs all the time, so a long gap means the computer slept."""
    longest, before = 0.0, None
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.search(r'"time": "([^"]+)"', line)
        if m:
            at = datetime.fromisoformat(m.group(1)).timestamp()
            longest = max(longest, at - before) if before is not None else longest
            before = at
    return longest


def report(
    shops: list[dict], customers: list[str], args: argparse.Namespace, started: float, log: Path
) -> str:
    time.sleep(3)  # delivered orders become completed a moment later
    views = {oid: final_view(sim) for oid, sim in ORDERS.items()}
    sims = list(ORDERS.values())
    done = [s for s in sims if views[s.order_id]["status"] in DONE]
    other: dict[str, int] = {}
    for s in sims:
        if views[s.order_id]["status"] not in DONE:
            other[views[s.order_id]["status"]] = other.get(views[s.order_id]["status"], 0) + 1

    def t(s: Sim, key: str) -> float | None:
        return ts(views[s.order_id].get(key))

    shop_orders = [s for s in done if s.kind != "parcel"]
    steps = [
        (
            "Shop accepts the order",
            [gap(s.placed, t(s, "accepted_at")) for s in shop_orders],
            "stand-in: the autopilot accepts after about 12 s",
        ),
        (
            "A rider takes the job",
            [gap(t(s, "accepted_at") or s.placed, s.rider_took) for s in done],
            "real: offers, offers that run out, the next rider (counted from the shop accepting; parcels from payment)",
        ),
        (
            "Shop packs it",
            [gap(t(s, "accepted_at"), t(s, "ready_at")) for s in shop_orders],
            "stand-in: the autopilot marks it ready 30 s after accepting",
        ),
        (
            "Rider waits at the counter",
            [s.waited_at_counter for s in shop_orders],
            "follows from the packing time and how fast the rider got there",
        ),
        (
            "Ride to the customer",
            [gap(t(s, "picked_up_at"), t(s, "delivered_at")) for s in done],
            "30 times faster than real life",
        ),
        (
            "Whole order, paid to delivered",
            [gap(s.placed, t(s, "delivered_at")) for s in done],
            "all of the above together",
        ),
    ]
    debits, credits = trial_balance()
    earnings = {name: e.call("GET", "/v1/rider/earnings", name) for name in RIDERS}
    cash_held, cash_notes = end_of_day_cash()
    debits_after, credits_after = trial_balance()
    wanted_cash = [s for s in sims if s.wanted == "cash"]
    switched = [s for s in wanted_cash if s.paid_with != "cash"]
    reasons = sorted({s.note for s in switched if s.note})
    settle = {oid: (v.get("settlement") or {}) for oid, v in views.items()}
    api_errors = sum(
        1
        for line in log.read_text(encoding="utf-8", errors="replace").splitlines()
        if '" 500' in line or "Traceback" in line
    )
    lines = [
        "# Pilot simulation",
        "",
        f"Run on {datetime.now().strftime('%Y-%m-%d at %H:%M')} with `services/api/scripts/pilot_sim.py --orders "
        f"{args.orders} --minutes {args.minutes:g} --seed {args.seed}`, on a separate copy of the local API (port "
        f"{PORT}), so the phone test was not touched. Re-running the script rewrites this page.",
        "",
        "## The pilot that was simulated",
        "",
        "- **Area:** Lekki Phase 1. Customers live within 2.5 km of its centre; half the parcels go to Victoria Island.",
        "- **Shops:** the nearest demo shop of each kind: "
        + "; ".join(f"{s['name']} ({KIND_NAMES[s['vertical']]}, {s['distance_km']:.1f} km)" for s in shops)
        + ".",
        f"- **Riders:** {len(RIDERS)}. Demo riders 2 to 4, plus 2 new people who signed up, applied to ride and were "
        "approved by an admin at the start of the run.",
        f"- **Customers:** {len(customers)}, ordering at random: {len(sims)} orders in about {args.minutes:g} minutes "
        f"(about one every {args.minutes * 60 / max(1, args.orders):.0f} s), about 1 in 10 a parcel. Customers "
        "wanted to pay by card (50%), wallet (20%) or cash on delivery (30%).",
        "- **Business rules:** the production defaults. Offers run out after 45 s; a rider who missed an offer is "
        "asked again only after 5 minutes; dispatch first looks 6 km around the pickup; riders stop getting cash "
        "jobs at ₦50,000 held; pay on delivery needs one completed prepaid order first and is capped at ₦25,000.",
        "- **Stand-ins for people:** the shops are the local autopilot (accepts after about 12 s, packed 30 s later), "
        "and the riders are simulated: they ride 30 times faster than real life and leave 1 offer in 10 to run out.",
        "",
        "## Results",
        "",
        f"- **Delivered: {len(done)} of {len(sims)}.** Not delivered: "
        + (", ".join(f"{k} {v}" for k, v in sorted(other.items())) or "none")
        + ".",
        f"- **Paid by:** card {sum(s.paid_with == 'card' for s in sims)}, wallet "
        f"{sum(s.paid_with == 'wallet' for s in sims)}, cash on delivery {sum(s.paid_with == 'cash' for s in sims)}.",
        f"- **Wanted cash but paid by card:** {len(switched)} of {len(wanted_cash)}"
        + (f" ({'; '.join(reasons)})" if reasons else "")
        + ".",
        f"- **Orders that could not be placed:** {sum('could not be placed' in p for p in PROBLEMS)}.",
        f"- **Server errors in the API log:** {api_errors}.",
        *(
            [
                f"- **The computer slept for about {fmt(pause)} during the run**, so the step times below are too long: "
                "run it again with the computer kept awake."
            ]
            if (pause := longest_pause(log)) > 180
            else []
        ),
        "",
        "## Time for each step",
        "",
        "Median · 90% of orders within · slowest.",
        "",
        "| Step | Time | What it measures |",
        "|---|---|---|",
        *[f"| {name} | {spread(values)} | {what} |" for name, values, what in steps],
        "",
        "## Offers to riders",
        "",
        f"- Offers sent: {OFFERS['seen']} for {len(sims)} orders.",
        f"- Left to run out on purpose (a rider looking away): {OFFERS['left_to_run_out']}.",
        f"- Already gone when the rider pressed accept: {OFFERS['taken_by_someone_else']}.",
        "",
        "## Riders",
        "",
        "| Rider | Deliveries | Earned | Cash collected, handed in at the end |",
        "|---|---|---|---|",
    ]
    for name, uid in RIDERS.items():
        earn = earnings[name]
        lines.append(
            f"| {name} ({uid}) | {earn.get('deliveries_completed', 0)} | {naira(earn.get('balance_kobo', 0))} | "
            f"{naira(cash_held.get(name, 0))} |"
        )
    lines += [
        "",
        "## Shops",
        "",
        "| Shop | Service | Orders | Delivered | Products sold | Shop earns | Commission |",
        "|---|---|---|---|---|---|---|",
    ]
    for shop in [*shops, {"name": "Package Delivery", "vertical": "parcel"}]:
        mine = [s for s in sims if s.shop == shop["name"]]
        if not mine:
            continue
        delivered = [s for s in mine if s in done]
        lines.append(
            f"| {shop['name']} | {KIND_NAMES[shop['vertical']]} | {len(mine)} | {len(delivered)} | "
            f"{naira(sum(s.subtotal_kobo for s in delivered))} | "
            f"{naira(sum(settle[s.order_id].get('restaurant_earning_kobo', 0) for s in delivered))} | "
            f"{naira(sum(settle[s.order_id].get('commission_kobo', 0) for s in delivered))} |"
        )
    collected = sum(cash_held.values())
    lines += [
        "",
        "## Money",
        "",
        f"- Customers paid {naira(sum(s.total_kobo for s in sims))} in all; delivered orders "
        f"{naira(sum(s.total_kobo for s in done))}.",
        f"- Riders earned {naira(sum(int(v.get('balance_kobo', 0)) for v in earnings.values()))}.",
        f"- Riders collected {naira(collected)} in cash; finance recorded each rider handing it in"
        + (": " + "; ".join(cash_notes) if cash_notes else ", and every rider now holds ₦0")
        + ".",
        f"- Ledger: debits {naira(debits)}, credits {naira(credits)} before the cash was handed in, debits "
        f"{naira(debits_after)}, credits {naira(credits_after)} after: "
        + ("**balanced**." if debits == credits and debits_after == credits_after else "**NOT balanced**."),
        "",
        "## Problems met",
        "",
        *([f"- {p}" for p in PROBLEMS] or ["- None."]),
        "",
        "## Every order",
        "",
        "| Order | Service | Shop | Paid by | Rider | Paid to delivered | Status |",
        "|---|---|---|---|---|---|---|",
    ]
    for s in sorted(sims, key=lambda s: s.placed):
        took = gap(s.placed, t(s, "delivered_at"))
        lines.append(
            f"| {s.short} | {KIND_NAMES[s.kind]} | {s.shop} | {s.paid_with} | {s.rider or '–'} | "
            f"{fmt(took) if took is not None else '–'} | {views[s.order_id]['status']} |"
        )
    lines += ["", f"The run took {fmt(time.time() - started)} on the clock.", ""]
    return "\n".join(lines)


# ------------------------------------------------------------------------------------------------ main
def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=(__doc__ or "").splitlines()[0])
    ap.add_argument("--orders", type=int, default=30)
    ap.add_argument("--minutes", type=float, default=8)
    ap.add_argument("--customers", type=int, default=12)
    ap.add_argument("--seed", type=int, default=7)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    started = time.time()
    log = Path(tempfile.gettempdir()) / "yummy_pilot_sim_api.log"
    print(f"Starting a separate API on port {PORT} (log: {log})", flush=True)
    proc = start_api(log)
    try:
        e.ensure_accounts()  # the base demo users (if the emulator restarted) and riders 2-4
        customers = customer_accounts(args.customers)
        RIDERS.update(SEEDED_RIDERS)
        for n in (5, 6):
            name, uid = onboard_rider(n)
            RIDERS[name] = uid
        print(
            f"Riders: {', '.join(RIDERS)} (rider5 and rider6 signed up and were approved just now)",
            flush=True,
        )
        e.call(
            "PUT", "/v1/rider/availability", "rider1", {"online": False}
        )  # nobody holds rider@ in this copy
        shops = pick_shops()
        details = {s["id"]: e.call("GET", f"/v1/restaurants/{s['id']}", params=LEKKI) for s in shops}
        print(
            "Shops: " + "; ".join(f"{s['name']} ({s['vertical']}, {s['distance_km']:.1f} km)" for s in shops)
        )
        riders = [
            Rider(name, near(LEKKI, 2.0, rng), random.Random(args.seed * 100 + i))
            for i, name in enumerate(RIDERS)
        ]
        for rider in riders:
            rider.start()
        time.sleep(3)
        run_orders(customers, shops, details, args, rng)
        print("All orders placed; waiting for the last deliveries", flush=True)
        wait_until_done(15)
        STOP.set()
        for rider in riders:
            rider.join(timeout=60)
        text = report(shops, customers, args, started, log)
        REPORT.write_text(text, encoding="utf-8", newline="\n")
        print("\n" + text)
        print(f"Report written to {REPORT.relative_to(ROOT)}")
        return 0
    finally:
        STOP.set()
        proc.terminate()
        try:
            proc.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    raise SystemExit(main())
