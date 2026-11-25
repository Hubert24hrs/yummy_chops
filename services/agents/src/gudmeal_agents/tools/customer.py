"""Customer-facing tools: discovery (restaurants and every kind of shop), budget meal planning, order drafting, checkout (with
approval), tracking."""

from __future__ import annotations

import re
from datetime import datetime
from typing import Any, Literal
from zoneinfo import ZoneInfo

from pydantic import Field

from ..api_client import ApiError
from .registry import ToolArgs, ToolContext, ToolError, ToolId, ToolOutput, ToolRegistry, ToolSpec

LAGOS = ZoneInfo("Africa/Lagos")
EVERYONE = frozenset({"customer"})


def naira(kobo: int | None) -> str:
    if kobo is None:
        return "—"
    whole, frac = divmod(int(kobo), 100)
    return f"₦{whole:,}" + (f".{frac:02d}" if frac else "")


def lagos_time(iso: str | None) -> str | None:
    """'2026-11-16T18:35:00Z' → '7:35 PM' (Lagos time); portable across platforms."""
    if not iso:
        return None
    local = datetime.fromisoformat(iso.replace("Z", "+00:00")).astimezone(LAGOS)
    return local.strftime("%I:%M %p").lstrip("0")


def chat_channel(ctx: ToolContext) -> str:
    """Orders and tickets record where the customer was talking to Yummy: WhatsApp, or the app/website."""
    return "whatsapp" if ctx.artifacts.get("channel") == "whatsapp" else "ai_agent"


async def delivery_address(ctx: ToolContext) -> dict[str, Any]:
    """The address used for planning/quotes: request context first, then the first saved address."""
    if ctx.artifacts.get("delivery_address"):
        return ctx.artifacts["delivery_address"]
    addresses = await ctx.api.get("/v1/me/addresses")
    if not addresses:
        raise ToolError(
            "no_address",
            "No delivery address found. Ask the customer to add one in the app "
            "(or share their location) before planning or ordering.",
        )
    addr = {
        k: addresses[0].get(k)
        for k in ("label", "line1", "area", "city", "state", "location", "instructions", "contact_phone")
    }
    return addr


def parse_deadline(text: str | None, now: datetime) -> datetime | None:
    """Accepts 'HH:MM' (24h, Lagos time) or ISO-8601. Returns an aware UTC datetime."""
    if not text:
        return None
    text = text.strip()
    m = re.fullmatch(r"([01]?\d|2[0-3]):([0-5]\d)", text)
    if m:
        local_now = now.astimezone(LAGOS)
        target = local_now.replace(hour=int(m.group(1)), minute=int(m.group(2)), second=0, microsecond=0)
        if target <= local_now:
            raise ToolError("deadline_passed", f"{text} has already passed in Lagos today")
        return target
    try:
        dt = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ToolError(
            "invalid_arguments", "deliver_before must be HH:MM (24h, Lagos time) or ISO-8601"
        ) from exc
    return dt if dt.tzinfo else dt.replace(tzinfo=LAGOS)


def order_summary(order: dict[str, Any]) -> dict[str, Any]:
    # The API shows each audience its own view: a rider's has the items but no prices (`breakdown`) and no
    # `lines`. The summary says what is there and leaves the amounts empty.
    b = order.get("breakdown") or None
    lines = order.get("lines") or order.get("items") or []

    def money(key: str) -> str | None:
        return naira(b[key]) if b else None

    return {
        "order_id": order["id"],
        "short_code": order["short_code"],
        "status": order["status"],
        "status_label": order.get("progress", {}).get("label"),
        "restaurant": order.get("restaurant_name"),
        "items": [
            f"{ln['quantity']} × {ln['name']}"
            + (f" ({', '.join(ln['selection_labels'])})" if ln.get("selection_labels") else "")
            for ln in lines
        ],
        "subtotal": money("subtotal_kobo"),
        "delivery_fee": money("delivery_fee_kobo"),
        "service_fee": naira(b["service_fee_kobo"] + b["small_order_fee_kobo"]) if b else None,
        "vat": money("vat_kobo"),
        "discount": naira(b["discount_kobo"]) if b and b["discount_kobo"] else None,
        "total": money("total_kobo"),
        "total_kobo": b["total_kobo"] if b else None,
        "fulfillment": order.get("fulfillment"),
        "estimated_arrival": lagos_time(order.get("estimated_delivery_at")),
        "rider": order.get("rider_name"),
    }


# ------------------------------------------------------------------------------------------------
# Argument models (no identity or amount fields — the API derives those)
# ------------------------------------------------------------------------------------------------


# The merchant services (ADR-0018): restaurants, supermarkets, pharmacies, market shoppers, beauty shops.
Service = Literal["food", "grocery", "pharmacy", "market", "beauty"]
SERVICES_HELP = (
    "'food' restaurants, 'grocery' supermarkets and convenience stores, 'pharmacy' over-the-counter "
    "pharmacy products, 'market' fresh foodstuff bought by a shopper at the market, 'beauty' beauty & "
    "skin care shops"
)


class SearchRestaurantsArgs(ToolArgs):
    service: Service = Field(default="food", description=SERVICES_HELP)
    query: str | None = Field(
        default=None, max_length=60, description="Dish, cuisine, product type or shop name"
    )
    category: str | None = Field(
        default=None,
        max_length=30,
        description="Browse category id: food: promotions, local, international, snacks, grills, healthy, "
        "drinks; grocery: promotions, supermarkets, convenience, drinks, fresh, baby, household; pharmacy: "
        "promotions, pain, cold, vitamins, firstaid, baby, personal; market: promotions, foodstuff, "
        "vegetables, protein, tubers, fruits, combos; beauty: promotions, skincare, bodycare, haircare, "
        "makeup, fragrance, men",
    )
    cuisine: str | None = Field(default=None, max_length=40)
    open_now: bool = True
    limit: int = Field(default=5, ge=1, le=10)


class SearchFoodArgs(ToolArgs):
    query: str = Field(
        min_length=2,
        max_length=60,
        description="What the customer wants, e.g. 'jollof', 'suya', 'sunscreen', 'bottled water', "
        "'paracetamol', 'garri'",
    )
    service: Service | None = Field(
        default=None, description=f"Limit to one service ({SERVICES_HELP}); omit to search all"
    )
    limit: int = Field(default=8, ge=1, le=15)


class MenuArgs(ToolArgs):
    restaurant_id: ToolId


class MealPlanArgs(ToolArgs):
    budget_naira: int = Field(gt=0, le=1_000_000, description="Total budget in naira including all fees")
    party_size: int = Field(default=1, ge=1, le=10)
    deliver_before: str | None = Field(
        default=None, description="Deadline as HH:MM 24h Lagos time, e.g. '20:00'"
    )
    dietary: list[str] = Field(
        default_factory=list, max_length=5, description="e.g. vegetarian, vegan, halal"
    )
    exclude_allergens: list[str] = Field(default_factory=list, max_length=10)
    cuisines: list[str] = Field(default_factory=list, max_length=5)
    include_drinks: bool = True


class ChoiceArg(ToolArgs):
    group_id: ToolId
    choice_ids: list[ToolId] = Field(default_factory=list, max_length=10)


class ItemArg(ToolArgs):
    item_id: ToolId
    quantity: int = Field(default=1, ge=1, le=20)
    choices: list[ChoiceArg] = Field(default_factory=list, max_length=10)
    notes: str | None = Field(default=None, max_length=200)


class DraftArgs(ToolArgs):
    plan_ref: str | None = Field(
        default=None, description="A plan reference such as 'plan-1' from plan_meal_within_budget"
    )
    restaurant_id: ToolId | None = None
    items: list[ItemArg] = Field(default_factory=list, max_length=30)
    fulfillment: Literal["delivery", "pickup"] = "delivery"
    voucher_code: str | None = Field(default=None, max_length=40)


class OrderIdArgs(ToolArgs):
    order_id: ToolId


class OptionalOrderArgs(ToolArgs):
    order_id: ToolId | None = Field(default=None, description="Omit to use the most recent order")


class CancelArgs(ToolArgs):
    order_id: ToolId
    reason: str = Field(default="Cancelled via Yummy Chops assistant", max_length=300)


class ListOrdersArgs(ToolArgs):
    limit: int = Field(default=5, ge=1, le=20)


class NoArgs(ToolArgs):
    pass


class PreferencesArgs(ToolArgs):
    dietary: list[str] | None = Field(default=None, max_length=10)
    allergens: list[str] | None = Field(default=None, max_length=15)
    favourite_cuisines: list[str] | None = Field(default=None, max_length=15)


class NearbyArgs(ToolArgs):
    service: Service = Field(default="food", description=SERVICES_HELP)
    cuisine: str | None = Field(default=None, max_length=40, description="e.g. 'Nigerian', 'Pizza', 'Grills'")
    query: str | None = Field(
        default=None,
        max_length=60,
        description="Keyword matched against names, cuisines and tags, e.g. 'suya'",
    )
    max_minutes: int | None = Field(
        default=None, ge=10, le=180, description="Only places that can arrive this fast"
    )
    min_rating: float | None = Field(default=None, ge=0, le=5, description="Minimum rating out of 5")
    max_price_level: int | None = Field(default=None, ge=1, le=4, description="1 budget ... 4 premium")
    sort_by: Literal["fastest", "closest", "best_rated", "cheapest_delivery"] = "fastest"
    open_now: bool = True
    limit: int = Field(default=5, ge=1, le=8)


class CompareDeliveryArgs(ToolArgs):
    restaurants: list[str] = Field(
        min_length=2,
        max_length=6,
        description="Restaurant or shop names (or ids) the customer wants compared",
    )


# ------------------------------------------------------------------------------------------------
# Handlers
# ------------------------------------------------------------------------------------------------


_CATALOG_SORT = {
    "fastest": "distance",
    "closest": "distance",
    "best_rated": "rating",
    "cheapest_delivery": "delivery_fee",
}
_SLUG = re.compile(r"[a-z0-9][a-z0-9-]{2,59}")


def _estimate_label(source: str | None) -> str:
    return "measured road route (Google Maps)" if source == "google" else "estimate from distance"


async def find_nearby_restaurants(args: NearbyArgs, ctx: ToolContext) -> ToolOutput:
    """Location-aware recommendations: delivers to the customer, then time/rating/price filters and a sort."""
    addr = await delivery_address(ctx)
    loc = addr.get("location") or {}
    if loc.get("lat") is None:
        raise ToolError(
            "no_location", "Ask the customer for their delivery address or to share their location."
        )
    cards = await ctx.api.get(
        "/v1/restaurants",
        vertical=args.service,
        cuisine=args.cuisine,
        q=args.query,
        open_now=args.open_now,
        lat=loc["lat"],
        lng=loc["lng"],
        sort=_CATALOG_SORT[args.sort_by],
        limit=30,
    )
    candidates = [
        c
        for c in cards
        if c.get("delivers_to_location")
        and (args.min_rating is None or c["rating"] >= args.min_rating)
        and (args.max_price_level is None or c.get("price_level", 2) <= args.max_price_level)
    ][:10]
    estimates: dict[str, dict[str, Any]] = {}
    if candidates:
        data = await ctx.api.get(
            "/v1/delivery/estimates",
            restaurant_ids=",".join(c["id"] for c in candidates),
            lat=loc["lat"],
            lng=loc["lng"],
        )
        estimates = {e["restaurant_id"]: e for e in data["estimates"]}
    rows: list[dict[str, Any]] = []
    for c in candidates:
        e = estimates.get(c["id"], {})
        eta = e.get("eta_minutes", c.get("eta_minutes"))
        if args.max_minutes is not None and (eta is None or eta > args.max_minutes):
            continue
        fee = e.get("delivery_fee_kobo", c.get("delivery_fee_kobo"))
        rows.append(
            {
                "restaurant_id": c["id"],
                "name": c["name"],
                "area": c["area"],
                "cuisines": c["cuisines"],
                "rating": c["rating"],
                "price_level": c.get("price_level"),
                "is_open": c["is_open"],
                "road_distance_km": e.get("road_distance_km"),
                "eta_minutes": eta,
                "delivery_fee": naira(fee) if fee is not None else None,
                "_fee_kobo": fee if fee is not None else 10**9,
                "times_are": _estimate_label(e.get("source")),
            }
        )
    order = {
        "fastest": lambda r: (r["eta_minutes"] or 999, -r["rating"]),
        "closest": lambda r: (r["road_distance_km"] or 999, r["eta_minutes"] or 999),
        "best_rated": lambda r: (-r["rating"], r["eta_minutes"] or 999),
        "cheapest_delivery": lambda r: (r["_fee_kobo"], r["eta_minutes"] or 999),
    }[args.sort_by]
    rows.sort(key=order)
    picked = [{k: v for k, v in r.items() if k != "_fee_kobo"} for r in rows[: args.limit]]
    return ToolOutput(
        {
            "restaurants": picked,
            "near": addr.get("area") or addr.get("line1"),
            "sorted_by": args.sort_by,
            "note": "Times and delivery fees are for comparison; checkout confirms the exact price.",
        },
        card={"type": "restaurants", "items": picked},
    )


async def compare_delivery_times(args: CompareDeliveryArgs, ctx: ToolContext) -> ToolOutput:
    """Which of these kitchens gets food to the customer fastest (and at what delivery fee)."""
    addr = await delivery_address(ctx)
    loc = addr.get("location") or {}
    if loc.get("lat") is None:
        raise ToolError(
            "no_location", "Ask the customer for their delivery address or to share their location."
        )
    ids: list[str] = []
    unknown: list[str] = []
    for name in args.restaurants:
        text = name.strip()[:60]
        found = await ctx.api.get(
            "/v1/restaurants", vertical="all", q=text, lat=loc["lat"], lng=loc["lng"], limit=1
        )
        if found:
            ids.append(found[0]["id"])
            continue
        if _SLUG.fullmatch(text):  # the model may pass an id from an earlier result
            try:
                ids.append((await ctx.api.get(f"/v1/restaurants/{text}"))["restaurant"]["id"])
                continue
            except ApiError as exc:
                if exc.status != 404:
                    raise
        unknown.append(name)
    if not ids:
        raise ToolError(
            "not_found", "None of those places are on Yummy Chops near this address. Ask for the names again."
        )
    data = await ctx.api.get(
        "/v1/delivery/estimates", restaurant_ids=",".join(dict.fromkeys(ids)), lat=loc["lat"], lng=loc["lng"]
    )
    rows = sorted(
        (
            {
                "restaurant_id": e["restaurant_id"],
                "name": e["name"],
                "area": e["area"],
                "eta_minutes": e["eta_minutes"],
                "road_distance_km": e["road_distance_km"],
                "delivery_fee": naira(e["delivery_fee_kobo"]) if e["delivery_fee_kobo"] is not None else None,
                "delivers_here": e["delivers"],
                "open_now": e["is_open"],
                "times_are": _estimate_label(e["source"]),
            }
            for e in data["estimates"]
        ),
        key=lambda r: (not r["delivers_here"], r["eta_minutes"]),
    )
    fastest = next((r["name"] for r in rows if r["delivers_here"]), None)
    return ToolOutput(
        {
            "comparison": rows,
            "fastest": fastest,
            "not_found_nearby": unknown,
            "near": addr.get("area") or addr.get("line1"),
            "note": "Times and delivery fees are for comparison; checkout confirms the exact price.",
        },
        card={"type": "restaurants", "items": rows},
    )


async def search_restaurants(args: SearchRestaurantsArgs, ctx: ToolContext) -> ToolOutput:
    addr = ctx.artifacts.get("delivery_address")
    loc = (addr or {}).get("location") or {}
    cards = await ctx.api.get(
        "/v1/restaurants",
        vertical=args.service,
        category=args.category,
        q=args.query,
        cuisine=args.cuisine,
        open_now=args.open_now,
        lat=loc.get("lat"),
        lng=loc.get("lng"),
        limit=args.limit,
    )
    results = [
        {
            "restaurant_id": c["id"],
            "service": c.get("vertical", "food"),
            "name": c["name"],
            "cuisines": c["cuisines"],
            "promotions": [f"{p['label']} (code {p['code']})" for p in c.get("promotions", [])],
            "rating": c["rating"],
            "is_open": c["is_open"],
            "area": c["area"],
            "eta_minutes": c.get("eta_minutes"),
            "delivery_fee": naira(c.get("delivery_fee_kobo"))
            if c.get("delivery_fee_kobo") is not None
            else None,
            "delivers_here": c.get("delivers_to_location"),
        }
        for c in cards
    ]
    return ToolOutput({"restaurants": results}, card={"type": "restaurants", "items": results})


async def search_food_items(args: SearchFoodArgs, ctx: ToolContext) -> ToolOutput:
    found = await ctx.api.get("/v1/search", q=args.query, vertical=args.service)
    items = [
        {
            "item_id": r["item"]["id"],
            "name": r["item"]["name"]
            + (f" ({r['item']['unit_label']})" if r["item"].get("unit_label") else ""),
            "price": naira(r["item"]["price_kobo"]),
            "service": r.get("vertical", "food"),
            "restaurant_id": r["restaurant_id"],
            "restaurant": r["restaurant_name"],
            "available": r["item"]["is_available"],
            "needs_choices": bool(r["item"]["option_group_ids"]),
        }
        for r in found["items"][: args.limit]
    ]
    return ToolOutput({"items": items})


async def get_restaurant_menu(args: MenuArgs, ctx: ToolContext) -> ToolOutput:
    d = await ctx.api.get(f"/v1/restaurants/{args.restaurant_id}")
    groups = d["option_groups"]
    sections = []
    for s in d["sections"]:
        items = []
        for it in s["items"]:
            entry: dict[str, Any] = {
                "item_id": it["id"],
                "name": it["name"],
                "price": naira(it["price_kobo"]),
                "available": it["is_available"],
                "serves": it["serves"],
            }
            if it["option_group_ids"]:
                entry["choices"] = [
                    {
                        "group_id": gid,
                        "name": groups[gid]["name"],
                        "min": groups[gid]["min_select"],
                        "max": groups[gid]["max_select"],
                        "options": [
                            {
                                "choice_id": ch["id"],
                                "name": ch["name"],
                                "extra": naira(ch["price_delta_kobo"]),
                            }
                            for ch in groups[gid]["choices"]
                            if ch["is_available"]
                        ],
                    }
                    for gid in it["option_group_ids"]
                    if gid in groups
                ]
            items.append(entry)
        sections.append({"category": s["category"]["name"], "items": items})
    r = d["restaurant"]
    return ToolOutput(
        {"restaurant_id": r["id"], "name": r["name"], "is_open": r["is_open"], "menu": sections}
    )


async def plan_meal_within_budget(args: MealPlanArgs, ctx: ToolContext) -> ToolOutput:
    addr = await delivery_address(ctx)
    deadline = parse_deadline(args.deliver_before, ctx.now)
    body = {
        "budget_kobo": args.budget_naira * 100,
        "party_size": args.party_size,
        "location": addr["location"],
        "deliver_by": deadline.isoformat() if deadline else None,
        "dietary": args.dietary,
        "exclude_allergens": args.exclude_allergens,
        "cuisines": args.cuisines,
        "include_drinks": args.include_drinks,
        "max_options": 3,
    }
    result = await ctx.api.post("/v1/meal-plans", body)
    plans, stored = [], {}
    for i, p in enumerate(result["plans"], start=1):
        ref = f"plan-{i}"
        stored[ref] = {
            "restaurant_id": p["restaurant_id"],
            "cart_lines": p["cart_lines"],
            "total_kobo": p["breakdown"]["total_kobo"],
        }
        plans.append(
            {
                "plan_ref": ref,
                "restaurant": p["restaurant_name"],
                "rating": p["restaurant_rating"],
                "items": [f"{ln['quantity']} × {ln['name']}" for ln in p["items"]],
                "total": naira(p["breakdown"]["total_kobo"]),
                "delivery_fee": naira(p["breakdown"]["delivery_fee_kobo"]),
                "left_from_budget": naira(p["budget_remaining_kobo"]),
                "arrives_around": lagos_time(p["estimated_delivery_at"]),
                "why": p["rationale"],
            }
        )
    data: dict[str, Any] = {"plans": plans, "delivery_to": addr.get("label") or addr.get("line1")}
    if not plans:
        data["notes"] = result.get("notes", [])
        if result.get("cheapest_total_kobo"):
            data["cheapest_possible_total"] = naira(result["cheapest_total_kobo"])
    return ToolOutput(
        data,
        card={"type": "meal_plans", "plans": plans},
        artifacts={"plans": stored, "delivery_address": addr},
    )


async def create_order_draft(args: DraftArgs, ctx: ToolContext) -> ToolOutput:
    if args.plan_ref:
        plan = (ctx.artifacts.get("plans") or {}).get(args.plan_ref)
        if plan is None:
            raise ToolError(
                "unknown_plan", f"{args.plan_ref} is not one of the plans shown in this conversation"
            )
        restaurant_id, lines = plan["restaurant_id"], plan["cart_lines"]
    else:
        if not args.restaurant_id or not args.items:
            raise ToolError("invalid_arguments", "Provide plan_ref, or restaurant_id with items")
        restaurant_id = args.restaurant_id
        lines = [
            {
                "item_id": it.item_id,
                "quantity": it.quantity,
                "notes": it.notes,
                "selections": [{"group_id": c.group_id, "choice_ids": c.choice_ids} for c in it.choices],
            }
            for it in args.items
        ]
    body: dict[str, Any] = {
        "restaurant_id": restaurant_id,
        "lines": lines,
        "fulfillment": args.fulfillment,
        "voucher_code": args.voucher_code,
    }
    addr = None
    if args.fulfillment == "delivery":
        addr = await delivery_address(ctx)
        body["delivery_address"] = addr
    quote = await ctx.api.post("/v1/quotes", body)
    order = await ctx.api.post(
        "/v1/orders",
        {"quote_id": quote["id"], "channel": chat_channel(ctx)},
        idempotency_key=ctx.idempotency_key("order"),
    )
    summary = order_summary(order)
    summary["next_step"] = "Show this summary and ask the customer to confirm before calling confirm_order."
    return ToolOutput(
        summary,
        card={"type": "order_draft", "order": summary},
        artifacts={"last_order_id": order["id"], **({"delivery_address": addr} if addr else {})},
    )


def deliver_to(order: dict[str, Any]) -> str | None:
    """Where a delivery goes, in words. It is shown on the approval (WhatsApp has no order screen) but is kept
    out of the order summaries the model reads."""
    a = order.get("delivery_address")
    if order.get("fulfillment") != "delivery" or not a:
        return None
    parts = (str(a.get(k) or "").strip() for k in ("line1", "area", "city"))
    return ", ".join(dict.fromkeys(p for p in parts if p)) or None


async def preview_confirm(args: OrderIdArgs, ctx: ToolContext) -> dict[str, Any]:
    order = await ctx.api.get(f"/v1/orders/{args.order_id}")
    s = order_summary(order)
    where = deliver_to(order)
    return {
        "title": f"Place order {s['short_code']} from {s['restaurant']}?",
        "order": s,
        "deliver_to": where,
        "message": (f"Delivering to {where}. " if where else "")
        + f"You'll pay {s['total']} securely on the payment page. Card details are never shared with the "
        "assistant.",
    }


async def confirm_order(args: OrderIdArgs, ctx: ToolContext) -> ToolOutput:
    res = await ctx.api.post(
        f"/v1/orders/{args.order_id}/checkout", {}, idempotency_key=ctx.idempotency_key("checkout")
    )
    data = {
        "order_id": args.order_id,
        "status": res["status"],
        "amount": naira(res["amount_kobo"]),
        "payment_url": res["authorization_url"],
        "provider": res["provider"],
        "instruction": "Share the payment link. The order is sent to the restaurant automatically once the "
        "payment is verified by Yummy Chops.",
    }
    return ToolOutput(
        data,
        card={
            "type": "payment_link",
            "url": res["authorization_url"],
            "amount": naira(res["amount_kobo"]),
            "order_id": args.order_id,
        },
    )


async def get_order_status(args: OptionalOrderArgs, ctx: ToolContext) -> ToolOutput:
    order_id = args.order_id or ctx.artifacts.get("last_order_id")
    if not order_id:
        orders = await ctx.api.get("/v1/orders", limit=1)
        if not orders:
            return ToolOutput({"message": "No orders yet"})
        order = orders[0]
    else:
        order = await ctx.api.get(f"/v1/orders/{order_id}")
    s = order_summary(order)
    return ToolOutput(s, card={"type": "order_status", "order": s})


async def list_my_orders(args: ListOrdersArgs, ctx: ToolContext) -> ToolOutput:
    orders = await ctx.api.get("/v1/orders", limit=args.limit)
    return ToolOutput(
        {
            "orders": [
                {
                    "order_id": o["id"],
                    "short_code": o["short_code"],
                    "restaurant": o["restaurant_name"],
                    "status": o["status"],
                    "total": naira(o["breakdown"]["total_kobo"]),
                    "placed": o["created_at"][:16].replace("T", " "),
                }
                for o in orders
            ]
        }
    )


async def reorder(args: OrderIdArgs, ctx: ToolContext) -> ToolOutput:
    addr = await delivery_address(ctx)
    quote = await ctx.api.post(f"/v1/orders/{args.order_id}/reorder", {"delivery_address": addr})
    order = await ctx.api.post(
        "/v1/orders",
        {"quote_id": quote["id"], "channel": chat_channel(ctx)},
        idempotency_key=ctx.idempotency_key("reorder"),
    )
    s = order_summary(order)
    return ToolOutput(s, card={"type": "order_draft", "order": s}, artifacts={"last_order_id": order["id"]})


async def preview_cancel(args: CancelArgs, ctx: ToolContext) -> dict[str, Any]:
    order = await ctx.api.get(f"/v1/orders/{args.order_id}")
    return {
        "title": f"Cancel order {order['short_code']} from {order['restaurant_name']}?",
        "message": "If you have already paid and the restaurant has not accepted yet, you'll get a full refund.",
        "order": order_summary(order),
    }


async def cancel_order(args: CancelArgs, ctx: ToolContext) -> ToolOutput:
    order = await ctx.api.post(f"/v1/orders/{args.order_id}/cancel", {"reason": args.reason})
    return ToolOutput({"order_id": order["id"], "status": order["status"]})


async def get_my_preferences(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    p = await ctx.api.get("/v1/me/profile")
    return ToolOutput(
        {
            "dietary": p["dietary"],
            "allergens": p["allergens"],
            "favourite_cuisines": p["favourite_cuisines"],
            "personalisation_enabled": p["personalisation_consent"],
        }
    )


_PREFERENCE_LABELS = {
    "dietary": "Dietary needs",
    "allergens": "Allergies",
    "favourite_cuisines": "Favourite cuisines",
}


async def preview_preferences(args: PreferencesArgs, ctx: ToolContext) -> dict[str, Any]:
    """What will be saved, list by list; an emptied list reads 'none', so clearing allergies is never silent."""
    body = args.model_dump(exclude_none=True)
    if not body:
        raise ToolError("invalid_arguments", "Nothing to update")
    changes = [f"{_PREFERENCE_LABELS[k]}: {', '.join(v) if v else 'none'}" for k, v in body.items()]
    return {
        "title": "Save these preferences to your profile?",
        "message": ". ".join(changes) + ". Yummy uses them when it suggests meals.",
        "preferences": body,
    }


async def update_my_preferences(args: PreferencesArgs, ctx: ToolContext) -> ToolOutput:
    body = args.model_dump(exclude_none=True)
    if not body:
        raise ToolError("invalid_arguments", "Nothing to update")
    p = await ctx.api.patch("/v1/me/profile", body)
    return ToolOutput(
        {
            "saved": True,
            "dietary": p["dietary"],
            "allergens": p["allergens"],
            "favourite_cuisines": p["favourite_cuisines"],
        }
    )


async def list_saved_addresses(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    addresses = await ctx.api.get("/v1/me/addresses")
    return ToolOutput(
        {
            "addresses": [
                {"label": a.get("label"), "line1": a["line1"], "area": a.get("area")} for a in addresses
            ]
        }
    )


async def get_delivery_tracking(args: OptionalOrderArgs, ctx: ToolContext) -> ToolOutput:
    order_id = args.order_id or ctx.artifacts.get("last_order_id")
    if not order_id:
        latest = await ctx.api.get("/v1/orders", limit=1)
        if not latest:
            return ToolOutput({"message": "No orders yet"})
        order_id = latest[0]["id"]
    order = await ctx.api.get(f"/v1/orders/{order_id}")
    t = await ctx.api.get(f"/v1/orders/{order_id}/tracking")
    return ToolOutput(
        {
            "order_id": order_id,
            "short_code": order["short_code"],
            "restaurant": order["restaurant_name"],
            "status_label": order.get("progress", {}).get("label"),
            "status": t["status"],
            "rider": t.get("rider_name"),
            "eta_minutes": t.get("eta_minutes"),
            "estimated_arrival": lagos_time(t.get("estimated_delivery_at")),
            "has_live_location": bool(t.get("rider_location")),
        }
    )


def register(reg: ToolRegistry) -> None:
    add = reg.register
    add(
        ToolSpec(
            "search_restaurants",
            "Find restaurants (service='food'), supermarkets ('grocery'), pharmacies ('pharmacy'), market "
            "shoppers ('market') or beauty & skin care shops ('beauty'), open now by default, near the "
            "customer's delivery address. Optional browse category such as 'local', 'drinks' or 'skincare'.",
            SearchRestaurantsArgs,
            search_restaurants,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "search_food_items",
            "Search dishes, groceries, over-the-counter pharmacy products, market foodstuff and beauty "
            "products by name or keyword across all partner restaurants and shops.",
            SearchFoodArgs,
            search_food_items,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_restaurant_menu",
            "Get a restaurant's menu or a shop's product list (supermarket, pharmacy, market, beauty), with "
            "item ids, prices, sizes and required choices (e.g. protein, shade, weight or pack size).",
            MenuArgs,
            get_restaurant_menu,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "plan_meal_within_budget",
            "Build complete meal plans that fit a total budget (including all fees) for a party size and an "
            "optional delivery deadline. Totals are computed by Yummy Chops' pricing engine.",
            MealPlanArgs,
            plan_meal_within_budget,
            EVERYONE,
            rate_per_minute=10,
            timeout_s=25,
        )
    )
    add(
        ToolSpec(
            "create_order_draft",
            "Create an order draft from a plan_ref or explicit items. Returns the exact price breakdown. "
            "Does not charge the customer.",
            DraftArgs,
            create_order_draft,
            EVERYONE,
            mutating=True,
            rate_per_minute=10,
        )
    )
    add(
        ToolSpec(
            "confirm_order",
            "Confirm a drafted order and create a secure payment link. Requires the "
            "customer's explicit approval.",
            OrderIdArgs,
            confirm_order,
            EVERYONE,
            requires_approval=True,
            preview=preview_confirm,
            mutating=True,
            rate_per_minute=6,
        )
    )
    add(
        ToolSpec(
            "get_order_status",
            "Get the live status and ETA of an order (latest order if omitted).",
            OptionalOrderArgs,
            get_order_status,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "list_my_orders", "List the customer's recent orders.", ListOrdersArgs, list_my_orders, EVERYONE
        )
    )
    add(
        ToolSpec(
            "reorder",
            "Create a new order draft with the same items as a previous order.",
            OrderIdArgs,
            reorder,
            EVERYONE,
            mutating=True,
            rate_per_minute=6,
        )
    )
    add(
        ToolSpec(
            "cancel_order",
            "Cancel an order (only before the restaurant accepts). Requires approval.",
            CancelArgs,
            cancel_order,
            EVERYONE,
            requires_approval=True,
            preview=preview_cancel,
            mutating=True,
            rate_per_minute=5,
        )
    )
    add(
        ToolSpec(
            "get_my_preferences",
            "Read the customer's dietary preferences and allergies.",
            NoArgs,
            get_my_preferences,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "update_my_preferences",
            "Save dietary preferences, allergies or favourite cuisines the customer "
            "explicitly asked to save. Requires the customer's approval.",
            PreferencesArgs,
            update_my_preferences,
            EVERYONE,
            requires_approval=True,
            preview=preview_preferences,
            mutating=True,
            rate_per_minute=5,
        )
    )
    add(
        ToolSpec(
            "list_saved_addresses",
            "List the customer's saved delivery addresses.",
            NoArgs,
            list_saved_addresses,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_delivery_tracking",
            "Live delivery tracking (rider, ETA) for an order.",
            OptionalOrderArgs,
            get_delivery_tracking,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "find_nearby_restaurants",
            "Recommend restaurants or shops that deliver to the customer's address, using road travel times: filter "
            "by cuisine, how fast it must arrive (max_minutes), rating and price level; sort by fastest, closest, "
            "best_rated or cheapest_delivery. Use for 'near me', 'fastest', 'closest' and similar questions.",
            NearbyArgs,
            find_nearby_restaurants,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "compare_delivery_times",
            "Compare how fast (and at what delivery fee) named restaurants or shops can deliver to the customer.",
            CompareDeliveryArgs,
            compare_delivery_times,
            EVERYONE,
        )
    )


__all__ = ["delivery_address", "lagos_time", "naira", "order_summary", "parse_deadline", "register"]
