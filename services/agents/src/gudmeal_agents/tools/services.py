"""Yummy's multi-service tools: what Yummy Chops offers, order totals, Package Delivery, navigation, support contacts.

As everywhere else, tools never take identity or amount arguments: prices and totals come from the API.
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Any, Literal

from pydantic import Field

from ..api_client import ApiError
from .customer import EVERYONE, LAGOS, chat_channel, delivery_address, lagos_time, naira
from .registry import ToolArgs, ToolContext, ToolError, ToolId, ToolOutput, ToolRegistry, ToolSpec

SERVICE_NAMES = {
    "food": "Order Food",
    "pharmacy": "Pharmacy",
    "beauty": "Beauty & Skin Care",
    "grocery": "Shop & Groceries",
    "market": "Buy Foodstuff",
    "parcel": "Package Delivery",
    "waybill": "Interstate waybill",
}
CITY_ALIASES = {
    "lagos": "lagos",
    "enugu": "enugu",
    "abuja": "abuja",
    "port harcourt": "port-harcourt",
    "portharcourt": "port-harcourt",
    "port-harcourt": "port-harcourt",
    "ph": "port-harcourt",
}
TRACKING_CODE = re.compile(r"^GMW[2-9A-HJ-NP-Z]{8}$")

Screen = Literal[
    "home",
    "food",
    "grocery",
    "pharmacy",
    "market",
    "beauty",
    "parcel",
    "discover",
    "orders",
    "support",
    "profile",
    "merchant",
    "order",
    "wallet",
    "waybill",
    "plus",
    "rewards",
    "group",
]
SCREEN_LABELS: dict[str, str] = {
    "home": "Go to Home",
    "food": "Order Food",
    "pharmacy": "Open Pharmacy",
    "beauty": "Open Beauty & Skin Care",
    "grocery": "Open Shop & Groceries",
    "market": "Buy Foodstuff",
    "parcel": "Send a package",
    "discover": "Open Discover",
    "orders": "Open my orders",
    "support": "Open Support",
    "profile": "Open my profile",
    "merchant": "Open the store",
    "order": "Track this order",
    "wallet": "Open my wallet",
    "waybill": "Send to another city",
    "plus": "Open Yummy Chops Plus",
    "rewards": "Open Rewards",
    "group": "Open group orders",
}


class NoArgs(ToolArgs):
    pass


class OpenScreenArgs(ToolArgs):
    screen: Screen = Field(description="Which part of the app to open for the customer")
    merchant_id: ToolId | None = Field(default=None, description="For screen='merchant'")
    order_id: ToolId | None = Field(default=None, description="For screen='order'")
    # The apps put the category into a link, so it is held to the same characters as an id.
    category: ToolId | None = Field(
        default=None,
        description="Optional browse category id for a shop service, e.g. 'local', 'drinks', 'pain'",
    )


PHONE = r"^\+?[0-9 ]{7,20}$"


class ParcelQuoteArgs(ToolArgs):
    dropoff_address: str = Field(
        min_length=3, max_length=200, description="Street address of the recipient, with the neighbourhood"
    )
    recipient_name: str = Field(min_length=2, max_length=80)
    recipient_phone: str = Field(pattern=PHONE)
    pickup_address: str | None = Field(
        default=None,
        max_length=200,
        description="Where the rider collects the package. Omit to use the customer's saved address.",
    )
    sender_name: str | None = Field(default=None, max_length=80, description="Defaults to the customer")
    sender_phone: str | None = Field(default=None, pattern=PHONE, description="Defaults to the customer")
    size: Literal["small", "medium", "large"] = Field(
        default="small",
        description="small: documents, phones, shoes (up to 5 kg); medium: up to 10 kg; large: up to 20 kg",
    )
    category: Literal["documents", "clothing", "electronics", "food", "cosmetics", "household", "other"] = (
        "other"
    )
    description: str = Field(default="", max_length=200, description="What is inside, briefly")
    pickup_time: str | None = Field(
        default=None,
        description="Omit for now. Otherwise HH:MM (24h, Lagos time, today or tomorrow) or ISO-8601.",
    )


class QuoteIdArgs(ToolArgs):
    quote_id: ToolId


# ------------------------------------------------------------------------------------------------
async def list_services(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    addr = ctx.artifacts.get("delivery_address") or {}
    city = (addr.get("city") or "").strip().lower() or None
    services = await ctx.api.get("/v1/services", city=city if city in ("lagos", "enugu") else None)
    data = [
        {
            "service": s["id"],
            "name": s["name"],
            "what_it_is": s["tagline"],
            "available": s["available"],
            **({"partners": s["merchants"]} if "merchants" in s else {}),
            **({"options": s["options"], "coming_soon": s["coming_soon"]} if s["id"] == "parcel" else {}),
        }
        for s in services
    ]
    return ToolOutput(
        {"services": data, "cities": ["Lagos", "Enugu"]},
        card={"type": "services", "services": [{"id": s["service"], "name": s["name"]} for s in data]},
    )


async def get_order_totals(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    s = await ctx.api.get("/v1/me/order-summary")
    by_service = {
        SERVICE_NAMES[k]: {"orders": v["orders"], "spent": naira(v["spent_kobo"])}
        for k, v in s["by_vertical"].items()
        if v["orders"]
    }
    data = {
        "paid_orders": s["orders_count"],
        "completed": s["completed_count"],
        "in_progress": s["in_progress_count"],
        "total_spent": naira(s["total_spent_kobo"]),
        "spent_this_month": naira(s["this_month_spent_kobo"]),
        "refunded": naira(s["refunded_kobo"]) if s["refunded_kobo"] else None,
        "by_service": by_service,
        "favourite": s["favourite_merchant"]["name"] if s.get("favourite_merchant") else None,
        "note": "Totals are net of refunds and computed by Yummy Chops; quote them exactly.",
    }
    return ToolOutput(data, card={"type": "order_totals", **{k: v for k, v in data.items() if k != "note"}})


async def open_screen(args: OpenScreenArgs, ctx: ToolContext) -> ToolOutput:
    if args.screen == "merchant" and not args.merchant_id:
        raise ToolError("invalid_arguments", "merchant_id is required to open a store")
    if args.screen == "order" and not (args.order_id or ctx.artifacts.get("last_order_id")):
        raise ToolError("invalid_arguments", "order_id is required to open an order")
    params = {
        k: v
        for k, v in {
            "merchant_id": args.merchant_id,
            "order_id": args.order_id
            or (ctx.artifacts.get("last_order_id") if args.screen == "order" else None),
            "category": args.category,
        }.items()
        if v
    }
    card = {"type": "navigate", "screen": args.screen, "params": params, "label": SCREEN_LABELS[args.screen]}
    return ToolOutput({"shown_button": card["label"]}, card=card)


class WaybillOptionsArgs(ToolArgs):
    destination: str | None = Field(default=None, max_length=40, description="Destination city, e.g. 'Abuja'")
    origin: str | None = Field(
        default=None,
        max_length=40,
        description="Sending city; defaults to the city of the customer's address",
    )


class TrackWaybillArgs(ToolArgs):
    tracking_code: str | None = Field(
        default=None,
        max_length=20,
        description="Waybill tracking number (GMW + 8 characters); latest if empty",
    )


def _city_id(text: str | None) -> str | None:
    if not text:
        return None
    key = re.sub(r"\s+", " ", text.strip().lower()).removesuffix(" city")
    return CITY_ALIASES.get(key, key.replace(" ", "-"))


async def get_waybill_options(args: WaybillOptionsArgs, ctx: ToolContext) -> ToolOutput:
    """Routes, from-prices and transit days from the customer's city (read-only; booking happens in the app)."""
    addr = ctx.artifacts.get("delivery_address") or {}
    origin = _city_id(args.origin) or _city_id(addr.get("city")) or "lagos"
    wanted = _city_id(args.destination)
    if wanted and wanted == origin:
        return ToolOutput(
            {
                "same_city": True,
                "message": "Both places are in the same city: use Package Delivery (bike courier).",
            },
            card={"type": "navigate", "screen": "parcel", "params": {}, "label": SCREEN_LABELS["parcel"]},
        )
    try:
        data = await ctx.api.get("/v1/waybill/destinations", origin=origin)
    except ApiError as exc:
        raise ToolError(exc.code, exc.message) from exc
    routes = data["destinations"]
    if wanted:
        routes = [d for d in routes if d["city"] == wanted]
        if not routes:
            names = ", ".join(d["name"] for d in data["destinations"])
            return ToolOutput(
                {
                    "available": False,
                    "from": data["origin"]["name"],
                    "message": f"No waybill route to {args.destination} yet. Routes from {data['origin']['name']}: {names}.",
                }
            )
    rows = [
        {
            "to": d["name"],
            "price_from": naira(d["from_kobo"]),
            "transit": f"{d['transit_days'][0]} day(s)"
            if d["transit_days"][0] == d["transit_days"][1]
            else f"{d['transit_days'][0]}-{d['transit_days'][1]} days",
            "door_delivery": d["door_delivery"],
            "collection_points": [h["name"] for h in d["collection_hubs"]],
        }
        for d in routes
    ]
    out = {
        "from": data["origin"]["name"],
        "home_pickup": data["origin"]["home_pickup"],
        "destinations": rows,
        "note": "Prices are 'from' prices (small package dropped at the hub and collected). The app shows the exact "
        "total before payment; book in Send a package, Interstate.",
    }
    return ToolOutput(
        out, card={"type": "waybill_options", "from": out["from"], "destinations": rows, "screen": "waybill"}
    )


async def track_waybill(args: TrackWaybillArgs, ctx: ToolContext) -> ToolOutput:
    code = (args.tracking_code or "").strip().upper().replace("-", "").replace(" ", "")
    if code and not TRACKING_CODE.match(code):
        raise ToolError(
            "invalid_arguments", "Tracking numbers look like GMW followed by 8 letters and digits"
        )
    if not code:
        orders = await ctx.api.get("/v1/orders", limit=20)
        latest = next(
            (
                o
                for o in orders
                if o.get("vertical") == "waybill" and (o.get("waybill") or {}).get("tracking_code")
            ),
            None,
        )
        if latest is None:
            return ToolOutput({"message": "No waybills yet"})
        code = latest["waybill"]["tracking_code"]
    try:
        t = await ctx.api.get(f"/v1/track/{code}")
    except ApiError as exc:
        raise ToolError(exc.code, exc.message) from exc
    out: dict[str, Any] = {
        "tracking_code": code,
        "route": f"{t['origin']} to {t['destination']}",
        "status": t["label"],
        "expected": t["eta_text"],
        "delivered": t["delivered"],
        "history": [m["label"] for m in t["milestones"]],
    }
    if t.get("collection_point") and not t["delivered"]:
        cp = t["collection_point"]
        out["collection_point"] = f"{cp['name']}, {cp['address']} ({cp['hours']})"
    return ToolOutput(out, card={"type": "waybill_tracking", **out})


class OptionalOrderArgs(ToolArgs):
    order_id: ToolId | None = Field(
        default=None, description="Order to pay for; defaults to the latest order in this chat"
    )


async def get_wallet(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    """Read-only: Yummy can tell the balance but never tops up, moves or withdraws money."""
    w = await ctx.api.get("/v1/wallet")
    recent = [
        {
            "what": t["description"],
            "amount": ("+" if t["direction"] == "in" else "-") + naira(t["amount_kobo"]),
            "when": lagos_time(t["created_at"]),
        }
        for t in w["transactions"][:5]
    ]
    data: dict[str, Any] = {
        "balance": naira(w["balance_kobo"]),
        "wallet_available": w["enabled"],
        "refunds_go_to_wallet": w["refund_to_wallet"],
        "recent": recent,
        "top_up_limits": f"{naira(w['limits']['min_topup_kobo'])} to {naira(w['limits']['max_topup_kobo'])} per top-up",
        "note": "Yummy cannot top up or move money. To top up, the customer opens the Wallet screen (open_screen).",
    }
    if w.get("seller"):
        data["cash_on_delivery_balance"] = naira(w["seller"]["available_kobo"])
    card = {"type": "wallet", "balance": data["balance"], "recent": recent}
    if "cash_on_delivery_balance" in data:
        card["cash_on_delivery_balance"] = data["cash_on_delivery_balance"]
    return ToolOutput(data, card=card)


async def get_payment_options(args: OptionalOrderArgs, ctx: ToolContext) -> ToolOutput:
    order_id = args.order_id or ctx.artifacts.get("last_order_id")
    if not order_id:
        raise ToolError("invalid_arguments", "Which order? Create or open an order first.")
    try:
        opts = await ctx.api.get(f"/v1/orders/{order_id}/payment-options")
    except ApiError as exc:
        raise ToolError(exc.code, exc.message) from exc
    methods = [
        {
            "method": m["label"],
            "available": m["available"],
            **({"why_not": m["reason"]} if m.get("reason") else {}),
            **({"wallet_balance": naira(m["balance_kobo"])} if m["id"] == "wallet" else {}),
        }
        for m in opts["methods"]
    ]
    data = {"order_total": naira(opts["total_kobo"]), "methods": methods}
    return ToolOutput(data, card={"type": "payment_options", **data})


async def get_support_contacts(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    support = (await ctx.api.get("/v1/config/public"))["support"]
    # Only the contacts that exist: the API sends an empty value for one that is not set up yet.
    data: dict[str, Any] = {k: support[k] for k in ("whatsapp", "phone", "email") if support.get(k)}
    data |= {"hours": support["hours"], "in_app": "Support tab → Chat with us (a person replies in the app)"}
    missing = [
        name
        for k, name in (("whatsapp", "WhatsApp"), ("phone", "phone"), ("email", "email"))
        if not data.get(k)
    ]
    if missing:
        data["note"] = (
            f"Not set up yet: {', '.join(missing)}. Never make up a contact; offer the ones listed here, the in-app "
            "Support tab or a support ticket."
        )
    return ToolOutput(data, card={"type": "support_contacts", **data})


# ------------------------------------------------------------------------------------------------ parcels
async def _place(ctx: ToolContext, text: str) -> dict[str, Any]:
    try:
        return await ctx.api.get("/v1/places/resolve", q=text)
    except ApiError as exc:
        if exc.status == 404:
            raise ToolError(
                "unknown_area",
                f"I couldn't place '{text}'. Ask for the neighbourhood, e.g. 'Yaba' or 'Independence Layout'.",
            ) from exc
        raise


def _pickup_time(text: str | None, now: datetime) -> str | None:
    if not text:
        return None
    text = text.strip()
    m = re.fullmatch(r"([01]?\d|2[0-3]):([0-5]\d)", text)
    if m:
        local_now = now.astimezone(LAGOS)
        target = local_now.replace(hour=int(m.group(1)), minute=int(m.group(2)), second=0, microsecond=0)
        if target <= local_now:
            target += timedelta(days=1)  # "16:00" after 4pm means tomorrow
        return target.isoformat()
    try:
        dt = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ToolError(
            "invalid_arguments", "pickup_time must be HH:MM (24h, Lagos time) or ISO-8601"
        ) from exc
    return (dt if dt.tzinfo else dt.replace(tzinfo=LAGOS)).isoformat()


def _quote_summary(q: dict[str, Any]) -> dict[str, Any]:
    d, b = q["details"], q["breakdown"]
    return {
        "quote_id": q["id"],
        "from": f"{d['pickup']['line1']} ({d['pickup']['name']})",
        "to": f"{d['dropoff']['line1']} ({d['dropoff']['name']}, {d['dropoff']['phone']})",
        "size": d["size"],
        "distance_km": round(q["distance_km"], 1),
        "delivery_fee": naira(b["delivery_fee_kobo"]),
        "service_fee": naira(b["service_fee_kobo"]),
        "vat": naira(b["vat_kobo"]),
        "total": naira(b["total_kobo"]),
        "pickup": f"Scheduled for {lagos_time(q['scheduled_for'])}"
        if q.get("scheduled_for")
        else "As soon as possible",
        "estimated_delivery": lagos_time(q["estimated_delivery_at"]),
        "valid_until": lagos_time(q["expires_at"]),
    }


async def get_parcel_quote(args: ParcelQuoteArgs, ctx: ToolContext) -> ToolOutput:
    if args.pickup_address:
        place = await _place(ctx, args.pickup_address)
        pickup_loc = {"lat": place["lat"], "lng": place["lng"]}
        pickup_line, pickup_city = args.pickup_address, place["city"].title()
    else:
        saved = await delivery_address(ctx)
        pickup_loc, pickup_line = saved["location"], saved["line1"]
        pickup_city = saved.get("city") or "Lagos"
    sender_name, sender_phone = args.sender_name, args.sender_phone
    if not sender_name or not sender_phone:
        me = await ctx.api.get("/v1/me")  # the verified account's own name and phone
        sender_name = sender_name or me.get("name") or ctx.caller.name
        sender_phone = sender_phone or me.get("phone")
    if not sender_name or not sender_phone:
        raise ToolError("missing_sender", "Ask for the sender's name and phone number for the rider.")
    drop = await _place(ctx, args.dropoff_address)
    body = {
        "pickup": {
            "name": sender_name,
            "phone": sender_phone,
            "line1": pickup_line,
            "city": pickup_city,
            "location": pickup_loc,
        },
        "dropoff": {
            "name": args.recipient_name,
            "phone": args.recipient_phone,
            "line1": args.dropoff_address,
            "city": drop["city"].title(),
            "location": {"lat": drop["lat"], "lng": drop["lng"]},
        },
        "size": args.size,
        "category": args.category,
        "description": args.description,
        "scheduled_for": _pickup_time(args.pickup_time, ctx.now),
    }
    quote = await ctx.api.post("/v1/parcels/quotes", body)
    summary = _quote_summary(quote)
    summary["next_step"] = (
        "Show the price and ask the customer to confirm, then call book_parcel with quote_id."
    )
    return ToolOutput(
        summary,
        card={"type": "parcel_quote", "quote": summary},
        artifacts={"last_parcel_quote_id": quote["id"]},
    )


async def preview_book_parcel(args: QuoteIdArgs, ctx: ToolContext) -> dict[str, Any]:
    q = _quote_summary(await ctx.api.get(f"/v1/parcels/quotes/{args.quote_id}"))
    return {
        "title": f"Book a {q['size']} package delivery for {q['total']}?",
        "parcel": q,
        "message": f"From {q['from']} to {q['to']}. You'll pay {q['total']} securely on the payment page. A rider "
        "is assigned after payment.",
    }


async def book_parcel(args: QuoteIdArgs, ctx: ToolContext) -> ToolOutput:
    order = await ctx.api.post(
        "/v1/parcels",
        {"quote_id": args.quote_id, "channel": chat_channel(ctx)},
        idempotency_key=ctx.idempotency_key("parcel"),
    )
    res = await ctx.api.post(
        f"/v1/orders/{order['id']}/checkout", {}, idempotency_key=ctx.idempotency_key("checkout")
    )
    data = {
        "order_id": order["id"],
        "short_code": order["short_code"],
        "amount": naira(res["amount_kobo"]),
        "payment_url": res["authorization_url"],
        "instruction": "Share the payment link. Yummy Chops finds a rider as soon as the payment is verified. "
        "The recipient must give the rider the delivery code shown in the order.",
    }
    return ToolOutput(
        data,
        card={
            "type": "payment_link",
            "url": res["authorization_url"],
            "amount": data["amount"],
            "order_id": order["id"],
        },
        artifacts={"last_order_id": order["id"]},
    )


# ------------------------------------------------------------------------------------------- growth (read-only)
GROUP_STATUS = {
    "open": "collecting everyone's orders",
    "locked": "cart locked by the host",
    "cancelled": "cancelled",
    "expired": "expired",
}


async def get_plus_membership(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    """Read-only: Yummy explains Plus but never joins, renews or cancels it."""
    p = await ctx.api.get("/v1/plus")
    plan, m = p["plan"], p.get("membership")
    data: dict[str, Any] = {
        "member": p["member"],
        "available": plan["enabled"],
        "price": f"{naira(plan['price_kobo'])} every {plan['period_days']} days (VAT included)",
        "benefits": plan["benefits"],
        "note": "Yummy cannot join, renew or cancel Plus: open_screen('plus') shows the Plus screen.",
    }
    if m:
        data.update(
            {
                "status": m["status"],
                "member_until": m["paid_through_text"],
                "auto_renew_from_wallet": m["auto_renew"],
                "saved_so_far": naira(m["savings_kobo"]),
            }
        )
    card = {"type": "plus", "member": p["member"], "price": data["price"], "benefits": plan["benefits"]}
    if m and p["member"]:
        card.update({"member_until": m["paid_through_text"], "saved": naira(m["savings_kobo"])})
    return ToolOutput(data, card=card)


async def get_rewards(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    """Read-only: points, personal vouchers and the referral code (no redeeming or applying codes)."""
    r = await ctx.api.get("/v1/rewards")
    redeem, ref, earn = r["redeem"], r["referral"], r["earn"]
    vouchers = [
        {
            "code": v["code"],
            "worth": naira(v["value_kobo"]),
            "min_order": naira(v["min_subtotal_kobo"]),
            "expires": lagos_time(v["ends_at"]) if v.get("ends_at") else None,
        }
        for v in r["vouchers"]
    ]
    rate = f"{earn['points_per_100_naira']} point for every ₦100 spent on completed orders"
    if earn["plus_multiplier"] > 1:
        rate += f" ({earn['plus_multiplier']}x for Yummy Chops Plus members)"
    data: dict[str, Any] = {
        "points": r["points"],
        "points_worth": naira(r["points_value_kobo"]),
        "earn_rate": rate,
        "redeem_rule": f"{redeem['step_points']} points = {naira(redeem['step_value_kobo'])} off orders from "
        f"{naira(redeem['min_subtotal_kobo'])}",
        "redeemable_points": redeem["redeemable_points"],
        "points_to_next_reward": redeem["points_to_next"],
        "next_reward_worth": naira(redeem["step_value_kobo"]),
        "referral_code": ref["code"],
        "friend_gets": naira(ref["friend_gets_kobo"]),
        "you_get": naira(ref["you_get_kobo"]),
        "friends_rewarded": ref["friends_rewarded"],
        "share_text": ref["share_text"],
        "vouchers": vouchers,
        "note": "Yummy cannot redeem points or apply referral codes: open_screen('rewards').",
    }
    card = {
        "type": "rewards",
        "points": r["points"],
        "referral_code": ref["code"],
        "share_text": ref["share_text"],
        "vouchers": vouchers,
    }
    return ToolOutput(data, card=card)


async def get_group_orders(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    """Read-only: the customer's group orders, who is in them and what they owe (shares come from the API)."""
    groups = await ctx.api.get("/v1/group-orders")
    rows = []
    for g in groups:
        order = g.get("order") or {}
        if g["status"] == "ordered":
            status = (
                "waiting for everyone to pay"
                if order.get("status") == "pending_payment"
                else (f"order {str(order.get('status', '')).replace('_', ' ')}")
            )
        else:
            status = GROUP_STATUS.get(g["status"], g["status"])
        row: dict[str, Any] = {
            "store": g["restaurant"]["name"],
            "status": status,
            "people": len(g["members"]),
            "you_are_host": g["is_host"],
            "host": g["host_name"],
        }
        if g["status"] == "open":
            row["join_code"] = g["code"]
        mine = g.get("my_share")
        if mine:
            row["your_share"] = naira(mine["amount_kobo"]) + (" (paid)" if mine["status"] == "paid" else "")
        if g.get("remaining_kobo"):
            row["still_to_pay"] = naira(g["remaining_kobo"])
        row["group_order_id"] = g["id"]
        rows.append(row)
    data: dict[str, Any] = {"group_orders": rows}
    if not rows:
        data["how_to_start"] = (
            "Open a Food or Beauty store and tap 'Order with friends', then share the 6-character code."
        )
    data["note"] = "Yummy cannot join, change or pay a group order: open_screen('group')."
    return ToolOutput(data, card={"type": "group_orders", "groups": rows})


def register(reg: ToolRegistry) -> None:
    add = reg.register
    add(
        ToolSpec(
            "list_services",
            "What Yummy Chops offers (Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, "
            "Package Delivery), where, "
            "and what is coming soon.",
            NoArgs,
            list_services,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_order_totals",
            "The customer's totals: number of paid orders, total spent (net of "
            "refunds), spend per service and this month, favourite store.",
            NoArgs,
            get_order_totals,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "open_screen",
            "Show the customer a button that opens a part of the app (Order Food, Pharmacy, Beauty & Skin Care, "
            "Shop & Groceries, Buy Foodstuff, Package Delivery, Orders, Support, Profile, a store or an order).",
            OpenScreenArgs,
            open_screen,
            EVERYONE,
            rate_per_minute=30,
        )
    )
    add(
        ToolSpec(
            "get_waybill_options",
            "Interstate waybill routes from the customer's city: destinations, from-prices, transit days, door "
            "delivery or collection points. Read-only; customers book in the app.",
            WaybillOptionsArgs,
            get_waybill_options,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "track_waybill",
            "Where an interstate waybill is (by tracking number, or the customer's latest waybill).",
            TrackWaybillArgs,
            track_waybill,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_wallet",
            "The customer's Yummy Chops wallet: balance, recent activity, refund setting and any cash-on-delivery "
            "money collected for them as a seller. Read-only.",
            NoArgs,
            get_wallet,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_payment_options",
            "How the customer can pay an order (card/transfer/USSD, Yummy Chops wallet, pay on delivery in cash) and "
            "why an option is unavailable. Yummy Chops decides eligibility; quote the reasons exactly.",
            OptionalOrderArgs,
            get_payment_options,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_plus_membership",
            "Yummy Chops Plus: price, member benefits, and the customer's membership (until when, auto-renew, "
            "savings). Read-only; customers join or cancel on the Plus screen.",
            NoArgs,
            get_plus_membership,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_rewards",
            "The customer's Yummy points, how to earn and redeem them, their personal vouchers and their referral "
            "code. Read-only; redeeming and applying codes happen on the Rewards screen.",
            NoArgs,
            get_rewards,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_group_orders",
            "The customer's group orders (order with friends, split bill): store, status, join code, their share "
            "and what is still unpaid. Read-only.",
            NoArgs,
            get_group_orders,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_support_contacts",
            "Yummy Chops support contacts (WhatsApp, phone, email) and hours.",
            NoArgs,
            get_support_contacts,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_parcel_quote",
            "Price a Package Delivery within Lagos or within Enugu (bike courier), now "
            "or at a pickup time. Needs the drop-off address with its neighbourhood and the recipient's name "
            "and phone. Does not charge the customer.",
            ParcelQuoteArgs,
            get_parcel_quote,
            EVERYONE,
            mutating=True,
            rate_per_minute=10,
        )
    )
    add(
        ToolSpec(
            "book_parcel",
            "Book a priced Package Delivery and create a secure payment link. Requires the "
            "customer's explicit approval.",
            QuoteIdArgs,
            book_parcel,
            EVERYONE,
            requires_approval=True,
            preview=preview_book_parcel,
            mutating=True,
            rate_per_minute=6,
        )
    )


__all__ = ["register"]
