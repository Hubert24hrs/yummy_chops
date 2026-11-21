"""Demo shop autopilot: local testing only (DEMO_SHOP_AUTOPILOT, honoured only when ENVIRONMENT=local).

An order from a restaurant or shop (food, groceries, pharmacy, market, beauty) is only offered to a rider after the
shop accepts it. Someone testing alone with the
customer and rider apps on a phone has nobody at the shop's dashboard, so the order would sit at "Sent to
restaurant" until it is cancelled. With the autopilot on, a demo shop accepts an order nobody has answered for a
few seconds and marks it ready a little later, through the same service calls the partner dashboard makes.
Anyone who does act in the partner dashboard first simply wins: the autopilot only touches orders left waiting.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from ..domain.models import MERCHANT_VERTICALS, Fulfillment, Order
from ..domain.order_state import OrderStatus
from ..errors import DomainError
from ..security.rbac import Principal

S = OrderStatus
SHOP_VERTICALS = set(MERCHANT_VERTICALS)
ACCEPT_AFTER_SECONDS = 12.0
READY_AFTER_SECONDS = 30.0
PREP_MINUTES = 10


def _staff(order: Order) -> Principal:
    """Acts as the shop's own staff for this one order's shop (so events read "restaurant", not "admin")."""
    return Principal(
        uid="demo-shop-autopilot",
        roles=frozenset({"restaurant_staff"}),
        restaurant_roles={order.restaurant_id: "staff"},
        name="Demo shop (autopilot)",
    )


async def run_demo_shops(
    container: Any,
    *,
    accept_after: float = ACCEPT_AFTER_SECONDS,
    ready_after: float = READY_AFTER_SECONDS,
    now: datetime | None = None,
) -> int:
    """One pass: accept orders left unanswered, then mark accepted orders ready. Returns how many it moved."""
    now = now or datetime.now(UTC)
    orders, repos = container.orders, container.repos
    moved = 0
    waiting = await repos.orders.find(where=[("status", "==", S.SUBMITTED_TO_RESTAURANT.value)], limit=50)
    for order in waiting:
        if order.vertical in SHOP_VERTICALS and (now - order.updated_at).total_seconds() >= accept_after:
            try:
                await orders.accept(_staff(order), order.id, PREP_MINUTES)
                moved += 1
            except DomainError:
                continue  # someone at the shop got there first, or the order was cancelled
    for status in (S.RESTAURANT_ACCEPTED, S.PREPARING, S.RIDER_ASSIGNED):
        for order in await repos.orders.find(where=[("status", "==", status.value)], limit=50):
            if (
                order.vertical in SHOP_VERTICALS
                and order.ready_at is None
                and order.accepted_at is not None
                and (now - order.accepted_at).total_seconds() >= ready_after
                # Pickup orders end at the counter with the customer's code: leave those to a person.
                and order.fulfillment == Fulfillment.DELIVERY
            ):
                try:
                    await orders.mark_ready(_staff(order), order.id)
                    moved += 1
                except DomainError:
                    continue
    return moved
