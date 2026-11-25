"""Support, payment, restaurant, delivery, growth, admin and analytics tools."""

from __future__ import annotations

import re
from typing import Any, Literal

from pydantic import Field

from .customer import EVERYONE, chat_channel, naira, order_summary
from .registry import ToolArgs, ToolContext, ToolError, ToolId, ToolOutput, ToolRegistry, ToolSpec

RESTAURANT_ROLES = frozenset({"restaurant_owner", "restaurant_manager", "restaurant_staff"})
RESTAURANT_MANAGERS = frozenset({"restaurant_owner", "restaurant_manager"})
SUPPORT = frozenset({"support_agent", "operations_manager", "super_admin"})
OPS = frozenset({"operations_manager", "super_admin"})
FINANCE = frozenset({"finance_manager", "super_admin", "support_agent"})
MARKETING = frozenset({"marketing_manager", "super_admin"})
STAFF = frozenset(
    {"support_agent", "operations_manager", "finance_manager", "marketing_manager", "super_admin"}
)
ANALYTICS = frozenset({"operations_manager", "finance_manager", "marketing_manager", "super_admin"})

HELP_ARTICLES: list[dict[str, str]] = [
    {
        "id": "fees",
        "title": "How delivery and service fees work",
        "body": "Delivery fees depend on distance (shown before you pay). A service fee of 5% (min ₦100, max ₦1,500) "
        "applies, plus a small-order fee on orders under ₦3,000. VAT (7.5%) applies to platform fees. "
        "The total you approve is exactly what you pay.",
    },
    {
        "id": "refunds",
        "title": "Refunds and missing items",
        "body": "If a restaurant rejects or doesn't respond to a paid order, you're refunded in full automatically. "
        "For missing or wrong items, report the issue within 48 hours; our team reviews it and refunds approved "
        "amounts to your original payment method, usually within 1–5 business days.",
    },
    {
        "id": "payment",
        "title": "Paying for an order",
        "body": "Payments are processed securely by our payment partners (card, bank transfer or USSD where available). "
        "Yummy Chops never asks for your card PIN or OTP in chat. Your order is confirmed once the payment is "
        "verified.",
    },
    {
        "id": "delivery-code",
        "title": "Delivery confirmation code",
        "body": "Each order has a 4-digit delivery code in your app. Only share it with the rider when you have "
        "received your food. Never share it before delivery.",
    },
    {
        "id": "cancel",
        "title": "Cancelling an order",
        "body": "You can cancel before the restaurant accepts. After acceptance the kitchen has started cooking, so "
        "contact support for help.",
    },
    {
        "id": "schedule",
        "title": "Scheduled and pickup orders",
        "body": "You can schedule orders from 30 minutes to 7 days ahead, or choose pickup and collect with your pickup "
        "code at the counter (no delivery fee).",
    },
]


def _rid(ctx: ToolContext, restaurant_id: str | None) -> str:
    if restaurant_id:
        return restaurant_id
    ids = list(ctx.caller.restaurant_roles)
    if len(ids) == 1:
        return ids[0]
    raise ToolError("invalid_arguments", "Which restaurant? Provide restaurant_id")


class TicketArgs(ToolArgs):
    category: Literal[
        "missing_item", "wrong_order", "late_delivery", "payment", "quality", "rider", "account", "other"
    ]
    description: str = Field(min_length=5, max_length=1500)
    order_id: ToolId | None = None
    missing_item_ids: list[ToolId] = Field(default_factory=list, max_length=20)


class RefundReviewArgs(ToolArgs):
    order_id: ToolId
    reason: str = Field(min_length=5, max_length=1000)
    missing_item_ids: list[ToolId] = Field(default_factory=list, max_length=20)


class HelpArgs(ToolArgs):
    query: str = Field(min_length=2, max_length=200)


class OrderArg(ToolArgs):
    order_id: ToolId


class RestaurantOrdersArgs(ToolArgs):
    restaurant_id: ToolId | None = None
    status: (
        Literal[
            "submitted_to_restaurant",
            "restaurant_accepted",
            "preparing",
            "ready_for_pickup",
            "rider_assigned",
        ]
        | None
    ) = None


class AcceptArgs(ToolArgs):
    order_id: ToolId
    prep_minutes: int = Field(ge=1, le=180)
    restaurant_id: ToolId | None = None


class RejectArgs(ToolArgs):
    order_id: ToolId
    reason: str = Field(min_length=3, max_length=300)
    restaurant_id: ToolId | None = None


class AvailabilityArgs(ToolArgs):
    item_id: ToolId
    available: bool
    restaurant_id: ToolId | None = None


class AnalyticsArgs(ToolArgs):
    days: int = Field(default=14, ge=1, le=90)
    restaurant_id: ToolId | None = None


class AssignArgs(ToolArgs):
    order_id: ToolId
    rider_uid: ToolId
    reason: str = Field(min_length=3, max_length=300)


class NoArgs(ToolArgs):
    pass


# ---------------------------------------------------------------- support & payment -------------
async def create_support_ticket(args: TicketArgs, ctx: ToolContext) -> ToolOutput:
    t = await ctx.api.post("/v1/support/tickets", {**args.model_dump(), "channel": chat_channel(ctx)})
    return ToolOutput(
        {
            "ticket_id": t["id"],
            "status": t["status"],
            "priority": t["priority"],
            "message": "A Yummy Chops support specialist will review this.",
        },
        card={"type": "support_ticket", "ticket_id": t["id"]},
    )


async def preview_refund(args: RefundReviewArgs, ctx: ToolContext) -> dict[str, Any]:
    order = await ctx.api.get(f"/v1/orders/{args.order_id}")
    return {
        "title": f"Send a refund request for order {order['short_code']}?",
        "message": "Our team will review it. Approved refunds go back to your original payment method.",
        "order": order_summary(order),
        "reason": args.reason,
    }


async def request_refund_review(args: RefundReviewArgs, ctx: ToolContext) -> ToolOutput:
    category = "missing_item" if args.missing_item_ids else "payment"
    t = await ctx.api.post(
        "/v1/support/tickets",
        {
            "order_id": args.order_id,
            "category": category,
            "description": f"Refund request: {args.reason}",
            "missing_item_ids": args.missing_item_ids,
            "channel": chat_channel(ctx),
        },
    )
    return ToolOutput(
        {
            "ticket_id": t["id"],
            "status": "submitted_for_review",
            "message": "Refunds are decided by the Yummy Chops team, not the assistant.",
        }
    )


async def search_help_articles(args: HelpArgs, ctx: ToolContext) -> ToolOutput:
    words = set(re.findall(r"[a-z]{3,}", args.query.lower()))
    scored = sorted(
        HELP_ARTICLES,
        key=lambda a: -len(words & set(re.findall(r"[a-z]{3,}", (a["title"] + " " + a["body"]).lower()))),
    )
    return ToolOutput({"articles": scored[:2]})


async def get_payment_status(args: OrderArg, ctx: ToolContext) -> ToolOutput:
    payments = await ctx.api.get(f"/v1/orders/{args.order_id}/payments")
    if not payments:
        return ToolOutput({"status": "no_payment", "message": "No payment has been started for this order"})
    latest = payments[-1]
    if latest["status"] in ("initialized", "pending"):
        latest = await ctx.api.post(
            "/v1/payments/verify", {"reference": latest["reference"]}
        )  # server-side check
    return ToolOutput(
        {
            "status": latest["status"],
            "amount": naira(latest["amount_kobo"]),
            "refunded": naira(latest.get("refunded_kobo", 0)),
            "reference": latest["reference"],
        }
    )


async def list_pending_refunds(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    refunds = await ctx.api.get("/v1/admin/refunds", status="requested")
    return ToolOutput(
        {
            "pending": [
                {
                    "refund_id": r["id"],
                    "order_id": r["order_id"],
                    "amount": naira(r["amount_kobo"]),
                    "reason": r["reason"][:200],
                }
                for r in refunds[:20]
            ],
            "count": len(refunds),
        }
    )


async def list_open_tickets(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    tickets = await ctx.api.get("/v1/admin/support/tickets", status="open")
    return ToolOutput(
        {
            "open": [
                {
                    "ticket_id": t["id"],
                    "category": t["category"],
                    "priority": t["priority"],
                    "order_id": t.get("order_id"),
                }
                for t in tickets[:20]
            ],
            "count": len(tickets),
        }
    )


# ---------------------------------------------------------------- restaurant ------------------
async def list_restaurant_orders(args: RestaurantOrdersArgs, ctx: ToolContext) -> ToolOutput:
    rid = _rid(ctx, args.restaurant_id)
    params: dict[str, Any] = {"limit": 20}
    if args.status:
        params["status"] = args.status
    orders = await ctx.api.get(f"/v1/partner/restaurants/{rid}/orders", **params)
    return ToolOutput(
        {
            "restaurant_id": rid,
            "orders": [
                {
                    "order_id": o["id"],
                    "short_code": o["short_code"],
                    "status": o["status"],
                    "items": [f"{ln['quantity']} × {ln['name']}" for ln in o["lines"]],
                    "placed": o["created_at"][11:16],
                    "your_earning": naira(o.get("restaurant_earning_kobo")),
                }
                for o in orders
            ],
        }
    )


async def _restaurant_preview(ctx: ToolContext, rid: str, order_id: str, verb: str) -> dict[str, Any]:
    orders = await ctx.api.get(f"/v1/partner/restaurants/{rid}/orders", limit=50)
    order = next((o for o in orders if o["id"] == order_id), None)
    if order is None:
        raise ToolError("not_found", "Order not found for this restaurant")
    return {
        "title": f"{verb} order {order['short_code']}?",
        "items": [f"{ln['quantity']} × {ln['name']}" for ln in order["lines"]],
    }


async def preview_accept(args: AcceptArgs, ctx: ToolContext) -> dict[str, Any]:
    p = await _restaurant_preview(ctx, _rid(ctx, args.restaurant_id), args.order_id, "Accept")
    return {**p, "message": f"Preparation time: {args.prep_minutes} minutes"}


async def accept_order(args: AcceptArgs, ctx: ToolContext) -> ToolOutput:
    rid = _rid(ctx, args.restaurant_id)
    o = await ctx.api.post(
        f"/v1/partner/restaurants/{rid}/orders/{args.order_id}/accept", {"prep_minutes": args.prep_minutes}
    )
    return ToolOutput({"order_id": o["id"], "status": o["status"]})


async def preview_reject(args: RejectArgs, ctx: ToolContext) -> dict[str, Any]:
    p = await _restaurant_preview(ctx, _rid(ctx, args.restaurant_id), args.order_id, "Reject")
    return {**p, "message": f"The customer will be refunded in full. Reason: {args.reason}"}


async def reject_order(args: RejectArgs, ctx: ToolContext) -> ToolOutput:
    rid = _rid(ctx, args.restaurant_id)
    o = await ctx.api.post(
        f"/v1/partner/restaurants/{rid}/orders/{args.order_id}/reject", {"reason": args.reason}
    )
    return ToolOutput({"order_id": o["id"], "status": o["status"]})


async def preview_availability(args: AvailabilityArgs, ctx: ToolContext) -> dict[str, Any]:
    return {"title": f"Mark item {'available' if args.available else 'sold out'}?", "item_id": args.item_id}


async def set_item_availability(args: AvailabilityArgs, ctx: ToolContext) -> ToolOutput:
    rid = _rid(ctx, args.restaurant_id)
    item = await ctx.api.patch(
        f"/v1/partner/restaurants/{rid}/items/{args.item_id}/availability", {"available": args.available}
    )
    return ToolOutput({"item": item["name"], "available": item["is_available"]})


async def get_restaurant_analytics(args: AnalyticsArgs, ctx: ToolContext) -> ToolOutput:
    rid = _rid(ctx, args.restaurant_id)
    a = await ctx.api.get(f"/v1/partner/restaurants/{rid}/analytics", days=args.days)
    return ToolOutput(
        {
            "period_days": a["period_days"],
            "orders_completed": a["orders_completed"],
            "gross_sales": naira(a["gross_sales_kobo"]),
            "net_earnings": naira(a["net_earnings_kobo"]),
            "average_order": naira(a["average_order_kobo"]),
            "acceptance_rate": a["acceptance_rate"],
            "avg_prep_minutes": a["avg_prep_minutes"],
            "top_items": a["top_items"],
            "forecast_next_7_days_orders": a["forecast_next_7_days_orders"],
        },
        card={"type": "analytics", "series": a["series"]},
    )


# ---------------------------------------------------------------- delivery & admin -------------
async def get_available_riders(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    riders = await ctx.api.get("/v1/admin/riders")
    online = [r for r in riders if r["is_online"] and r["status"] == "active"]
    return ToolOutput(
        {
            "online": len(online),
            "riders": [
                {
                    "rider_uid": r["uid"],
                    "name": r["name"],
                    "vehicle": r["vehicle"],
                    "active_deliveries": len(r["active_order_ids"]),
                    "rating": r["rating"],
                }
                for r in online[:20]
            ],
        }
    )


async def preview_assign(args: AssignArgs, ctx: ToolContext) -> dict[str, Any]:
    return {"title": f"Assign rider {args.rider_uid} to order {args.order_id}?", "reason": args.reason}


async def request_rider_assignment(args: AssignArgs, ctx: ToolContext) -> ToolOutput:
    o = await ctx.api.post(
        f"/v1/admin/orders/{args.order_id}/assign-rider", {"rider_uid": args.rider_uid, "reason": args.reason}
    )
    return ToolOutput({"order_id": o["id"], "status": o["status"], "rider": o.get("rider_name")})


async def get_admin_overview(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    o = await ctx.api.get("/v1/admin/overview")
    return ToolOutput(
        {
            "orders_today": o["orders_today"],
            "active_orders": o["active_orders"],
            "gmv_today": naira(o["gmv_today_kobo"]),
            "platform_revenue_today": naira(o["platform_revenue_today_kobo"]),
            "riders_online": o["riders_online"],
            "riders_busy": o["riders_busy"],
            "stuck_orders": o["stuck_orders"],
            "pending_applications": o["pending_applications"],
            "open_tickets": o["open_tickets"],
            "pending_refunds": o["pending_refunds"],
            "flagged_payments": o["flagged_payments"],
            "orders_by_status": o["orders_by_status"],
        }
    )


async def get_admin_analytics(args: AnalyticsArgs, ctx: ToolContext) -> ToolOutput:
    a = await ctx.api.get("/v1/admin/analytics", days=args.days)
    return ToolOutput(
        {
            "period_days": a["period_days"],
            "orders_completed": a["orders_completed"],
            "gross_sales": naira(a["gross_sales_kobo"]),
            "commission": naira(a["commission_kobo"]),
            "average_order": naira(a["average_order_kobo"]),
            "top_restaurants": a["top_restaurants"],
            "top_items": a["top_items"],
            "forecast_next_7_days_orders": a["forecast_next_7_days_orders"],
        },
        card={"type": "analytics", "series": a["series"]},
    )


async def list_vouchers(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    vouchers = await ctx.api.get("/v1/admin/vouchers")
    return ToolOutput(
        {
            "vouchers": [
                {
                    "code": v["code"],
                    "description": v["description"],
                    "active": v["is_active"],
                    "used": v["used_count"],
                    "funded_by": v["funded_by"],
                }
                for v in vouchers
            ]
        }
    )


def register(reg: ToolRegistry) -> None:
    add = reg.register
    add(
        ToolSpec(
            "create_support_ticket",
            "Open a support ticket for an order problem (missing/wrong items, late "
            "delivery, quality, rider, account).",
            TicketArgs,
            create_support_ticket,
            EVERYONE,
            mutating=True,
            rate_per_minute=5,
        )
    )
    add(
        ToolSpec(
            "request_refund_review",
            "Ask the Yummy Chops team to review a refund. The assistant cannot issue "
            "refunds. Requires the customer's approval.",
            RefundReviewArgs,
            request_refund_review,
            EVERYONE,
            requires_approval=True,
            preview=preview_refund,
            mutating=True,
            rate_per_minute=3,
        )
    )
    add(
        ToolSpec(
            "search_help_articles",
            "Search Yummy Chops help articles (fees, refunds, payments, cancellation, "
            "delivery codes, scheduling).",
            HelpArgs,
            search_help_articles,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_payment_status",
            "Check an order's payment status (verified server-side with the provider).",
            OrderArg,
            get_payment_status,
            EVERYONE,
            rate_per_minute=10,
        )
    )
    add(
        ToolSpec(
            "list_pending_refunds",
            "List refund requests awaiting a finance decision.",
            NoArgs,
            list_pending_refunds,
            FINANCE,
        )
    )
    add(ToolSpec("list_open_tickets", "List open support tickets.", NoArgs, list_open_tickets, SUPPORT))
    add(
        ToolSpec(
            "list_restaurant_orders",
            "List the restaurant's current orders.",
            RestaurantOrdersArgs,
            list_restaurant_orders,
            RESTAURANT_ROLES,
        )
    )
    add(
        ToolSpec(
            "accept_order",
            "Accept an incoming order with a preparation time. Requires approval.",
            AcceptArgs,
            accept_order,
            RESTAURANT_ROLES,
            requires_approval=True,
            preview=preview_accept,
            mutating=True,
        )
    )
    add(
        ToolSpec(
            "reject_order",
            "Reject an incoming order (customer is refunded). Requires approval.",
            RejectArgs,
            reject_order,
            RESTAURANT_ROLES,
            requires_approval=True,
            preview=preview_reject,
            mutating=True,
        )
    )
    add(
        ToolSpec(
            "set_item_availability",
            "Mark a menu item available or sold out. Requires approval.",
            AvailabilityArgs,
            set_item_availability,
            RESTAURANT_ROLES,
            requires_approval=True,
            preview=preview_availability,
            mutating=True,
        )
    )
    add(
        ToolSpec(
            "get_restaurant_analytics",
            "Sales, prep time, top items and a 7-day order forecast for a restaurant.",
            AnalyticsArgs,
            get_restaurant_analytics,
            RESTAURANT_MANAGERS,
        )
    )
    add(
        ToolSpec(
            "get_available_riders",
            "List online riders and their workload.",
            NoArgs,
            get_available_riders,
            OPS,
        )
    )
    add(
        ToolSpec(
            "request_rider_assignment",
            "Manually assign a rider to an order. Requires approval.",
            AssignArgs,
            request_rider_assignment,
            OPS,
            requires_approval=True,
            preview=preview_assign,
            mutating=True,
        )
    )
    add(
        ToolSpec(
            "get_admin_overview",
            "Real-time platform overview: orders, GMV, riders, exceptions.",
            NoArgs,
            get_admin_overview,
            STAFF,
        )
    )
    add(
        ToolSpec(
            "get_admin_analytics",
            "Platform analytics and demand forecast.",
            AnalyticsArgs,
            get_admin_analytics,
            ANALYTICS,
        )
    )
    add(ToolSpec("list_vouchers", "List vouchers and their usage.", NoArgs, list_vouchers, MARKETING))
