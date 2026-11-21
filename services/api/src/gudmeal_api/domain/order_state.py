"""The order state machine — the single source of truth for legal order status changes.

Only `OrderService.transition` may apply these rules (inside a Firestore transaction). Clients and the
AI can request actions through API endpoints, which map onto transitions performed by a specific actor.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from ..errors import InvalidTransition, PermissionDenied


class OrderStatus(StrEnum):
    DRAFT = "draft"
    PENDING_PAYMENT = "pending_payment"
    PAID = "paid"
    SUBMITTED_TO_RESTAURANT = "submitted_to_restaurant"
    RESTAURANT_ACCEPTED = "restaurant_accepted"
    PREPARING = "preparing"
    READY_FOR_PICKUP = "ready_for_pickup"
    RIDER_ASSIGNED = "rider_assigned"
    PICKED_UP = "picked_up"
    IN_TRANSIT = "in_transit"
    DELIVERED = "delivered"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    REFUND_PENDING = "refund_pending"
    PARTIALLY_REFUNDED = "partially_refunded"
    REFUNDED = "refunded"
    DISPUTED = "disputed"


class ActorType(StrEnum):
    CUSTOMER = "customer"
    RESTAURANT = "restaurant"
    RIDER = "rider"
    SYSTEM = "system"
    STAFF = "staff"  # support / operations / super admin — always audited, reason required


S = OrderStatus
A = ActorType


@dataclass(frozen=True, slots=True)
class TransitionRule:
    actors: frozenset[ActorType]
    reason_required_for: frozenset[ActorType] = frozenset({A.STAFF})


def _rule(*actors: ActorType, reason_for: tuple[ActorType, ...] = (A.STAFF,)) -> TransitionRule:
    return TransitionRule(frozenset(actors), frozenset(reason_for))


# (from, to) -> who may perform it. Anything absent is illegal.
TRANSITIONS: dict[tuple[OrderStatus, OrderStatus], TransitionRule] = {
    # checkout & payment
    (S.DRAFT, S.PENDING_PAYMENT): _rule(A.CUSTOMER, A.SYSTEM),
    (S.DRAFT, S.CANCELLED): _rule(A.CUSTOMER, A.SYSTEM, A.STAFF),
    (S.PENDING_PAYMENT, S.PAID): _rule(A.SYSTEM),  # only the payment verifier
    (S.PENDING_PAYMENT, S.CANCELLED): _rule(A.CUSTOMER, A.SYSTEM, A.STAFF),
    # Pay on delivery: nothing is paid online, so an eligible order goes straight to the merchant and the rider
    # collects cash at the door. OrderService applies this only to cash orders.
    (S.PENDING_PAYMENT, S.SUBMITTED_TO_RESTAURANT): _rule(A.SYSTEM),
    # hand-off to the kitchen / shop
    (S.PAID, S.SUBMITTED_TO_RESTAURANT): _rule(A.SYSTEM),
    # Package Delivery has no merchant: once paid (and at the scheduled time) the parcel is ready for a rider.
    # OrderService only applies this to parcel orders.
    (S.PAID, S.READY_FOR_PICKUP): _rule(A.SYSTEM),
    (S.PAID, S.REFUND_PENDING): _rule(A.CUSTOMER, A.SYSTEM, A.STAFF),
    # Interstate waybill: a paid shipment goes in transit when the origin hub receives the package.
    # OrderService applies this only to waybills.
    (S.PAID, S.IN_TRANSIT): _rule(A.SYSTEM, A.STAFF),
    # Internal rider leg of a waybill (no payment of its own): released from draft straight to dispatch.
    # OrderService applies this only to legs.
    (S.DRAFT, S.READY_FOR_PICKUP): _rule(A.SYSTEM),
    (S.SUBMITTED_TO_RESTAURANT, S.RESTAURANT_ACCEPTED): _rule(A.RESTAURANT, A.STAFF),
    (S.SUBMITTED_TO_RESTAURANT, S.REFUND_PENDING): _rule(
        A.RESTAURANT, A.CUSTOMER, A.SYSTEM, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)
    ),
    # kitchen
    (S.RESTAURANT_ACCEPTED, S.PREPARING): _rule(A.RESTAURANT, A.STAFF),
    (S.RESTAURANT_ACCEPTED, S.READY_FOR_PICKUP): _rule(A.RESTAURANT, A.STAFF),
    (S.RESTAURANT_ACCEPTED, S.RIDER_ASSIGNED): _rule(A.SYSTEM, A.STAFF),
    (S.RESTAURANT_ACCEPTED, S.REFUND_PENDING): _rule(
        A.RESTAURANT, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)
    ),
    (S.PREPARING, S.READY_FOR_PICKUP): _rule(A.RESTAURANT, A.STAFF),
    (S.PREPARING, S.RIDER_ASSIGNED): _rule(A.SYSTEM, A.STAFF),
    (S.PREPARING, S.REFUND_PENDING): _rule(A.RESTAURANT, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)),
    (S.READY_FOR_PICKUP, S.RIDER_ASSIGNED): _rule(A.SYSTEM, A.STAFF),
    (S.READY_FOR_PICKUP, S.COMPLETED): _rule(A.RESTAURANT, A.STAFF),  # pickup orders, code checked
    # Customers may cancel a parcel before a rider is assigned (OrderService rejects this for food/shop orders).
    (S.READY_FOR_PICKUP, S.REFUND_PENDING): _rule(A.CUSTOMER, A.STAFF),
    # delivery
    (S.RIDER_ASSIGNED, S.PICKED_UP): _rule(A.RIDER, A.STAFF),
    (S.RIDER_ASSIGNED, S.PREPARING): _rule(A.SYSTEM, A.STAFF),  # rider unassigned, food not ready
    (S.RIDER_ASSIGNED, S.READY_FOR_PICKUP): _rule(A.SYSTEM, A.STAFF),  # rider unassigned, food ready
    (S.RIDER_ASSIGNED, S.REFUND_PENDING): _rule(A.STAFF),
    (S.PICKED_UP, S.IN_TRANSIT): _rule(A.RIDER, A.STAFF),
    (S.PICKED_UP, S.DELIVERED): _rule(A.RIDER, A.STAFF),
    (S.PICKED_UP, S.DISPUTED): _rule(A.STAFF),
    # SYSTEM: a waybill is delivered when its last-mile rider leg is (OrderService allows it only for waybills).
    (S.IN_TRANSIT, S.DELIVERED): _rule(A.RIDER, A.STAFF, A.SYSTEM),
    (S.IN_TRANSIT, S.DISPUTED): _rule(A.STAFF),
    (S.DELIVERED, S.COMPLETED): _rule(A.SYSTEM, A.STAFF),
    (S.DELIVERED, S.DISPUTED): _rule(A.CUSTOMER, A.STAFF, reason_for=(A.CUSTOMER, A.STAFF)),
    # after-sales
    (S.COMPLETED, S.DISPUTED): _rule(A.CUSTOMER, A.STAFF, reason_for=(A.CUSTOMER, A.STAFF)),
    (S.COMPLETED, S.REFUND_PENDING): _rule(A.STAFF, A.SYSTEM),
    (S.DISPUTED, S.COMPLETED): _rule(A.STAFF),
    (S.DISPUTED, S.REFUND_PENDING): _rule(A.STAFF, A.SYSTEM),
    (S.REFUND_PENDING, S.REFUNDED): _rule(A.SYSTEM),
    (S.REFUND_PENDING, S.PARTIALLY_REFUNDED): _rule(A.SYSTEM),
    (S.REFUND_PENDING, S.COMPLETED): _rule(A.STAFF),  # refund rejected after completion
    (S.PARTIALLY_REFUNDED, S.DISPUTED): _rule(A.CUSTOMER, A.STAFF, reason_for=(A.CUSTOMER, A.STAFF)),
    (S.PARTIALLY_REFUNDED, S.REFUND_PENDING): _rule(A.STAFF, A.SYSTEM),
    # Unpaid pay-on-delivery orders are cancelled, not refunded (no money moved). OrderService refuses these
    # for any order that holds customer money, which must go through REFUND_PENDING instead.
    (S.SUBMITTED_TO_RESTAURANT, S.CANCELLED): _rule(
        A.RESTAURANT, A.CUSTOMER, A.SYSTEM, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)
    ),
    (S.RESTAURANT_ACCEPTED, S.CANCELLED): _rule(A.RESTAURANT, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)),
    (S.PREPARING, S.CANCELLED): _rule(A.RESTAURANT, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)),
    # SYSTEM: a waybill's rider leg is called off with its shipment (legs hold no money).
    (S.READY_FOR_PICKUP, S.CANCELLED): _rule(A.STAFF, A.SYSTEM),
    (S.RIDER_ASSIGNED, S.CANCELLED): _rule(A.STAFF, A.SYSTEM),
    (S.PICKED_UP, S.CANCELLED): _rule(A.STAFF),  # e.g. the customer refused to pay at the door
    (S.IN_TRANSIT, S.CANCELLED): _rule(A.STAFF),
}

TERMINAL: frozenset[OrderStatus] = frozenset({S.CANCELLED, S.REFUNDED})

# Orders in these states hold customer money that has not been earned yet.
ACTIVE_FULFILMENT: frozenset[OrderStatus] = frozenset(
    {
        S.PAID,
        S.SUBMITTED_TO_RESTAURANT,
        S.RESTAURANT_ACCEPTED,
        S.PREPARING,
        S.READY_FOR_PICKUP,
        S.RIDER_ASSIGNED,
        S.PICKED_UP,
        S.IN_TRANSIT,
    }
)

# Coarse progress used by customer UIs.
CUSTOMER_PROGRESS: dict[OrderStatus, tuple[int, str]] = {
    S.DRAFT: (0, "Draft"),
    S.PENDING_PAYMENT: (0, "Awaiting payment"),
    S.PAID: (1, "Payment confirmed"),
    S.SUBMITTED_TO_RESTAURANT: (1, "Sent to restaurant"),
    S.RESTAURANT_ACCEPTED: (2, "Restaurant accepted"),
    S.PREPARING: (2, "Preparing your food"),
    S.READY_FOR_PICKUP: (3, "Ready for pickup"),
    S.RIDER_ASSIGNED: (3, "Rider on the way to restaurant"),
    S.PICKED_UP: (4, "Picked up"),
    S.IN_TRANSIT: (4, "On the way to you"),
    S.DELIVERED: (5, "Delivered"),
    S.COMPLETED: (5, "Completed"),
    S.CANCELLED: (-1, "Cancelled"),
    S.REFUND_PENDING: (-1, "Refund in progress"),
    S.PARTIALLY_REFUNDED: (5, "Partially refunded"),
    S.REFUNDED: (-1, "Refunded"),
    S.DISPUTED: (-1, "Under review"),
}


# Wording per service where the food labels above would be wrong.
PROGRESS_LABELS: dict[str, dict[OrderStatus, str]] = {
    "beauty": {
        S.SUBMITTED_TO_RESTAURANT: "Sent to the shop",
        S.RESTAURANT_ACCEPTED: "Shop accepted",
        S.PREPARING: "Packing your order",
        S.READY_FOR_PICKUP: "Packed and ready",
        S.RIDER_ASSIGNED: "Rider on the way to the shop",
    },
    "grocery": {
        S.SUBMITTED_TO_RESTAURANT: "Sent to the store",
        S.RESTAURANT_ACCEPTED: "Store accepted",
        S.PREPARING: "Packing your order",
        S.READY_FOR_PICKUP: "Packed and ready",
        S.RIDER_ASSIGNED: "Rider on the way to the store",
    },
    "pharmacy": {
        S.SUBMITTED_TO_RESTAURANT: "Sent to the pharmacy",
        S.RESTAURANT_ACCEPTED: "Pharmacy accepted",
        S.PREPARING: "Packing your order",
        S.READY_FOR_PICKUP: "Packed and ready",
        S.RIDER_ASSIGNED: "Rider on the way to the pharmacy",
    },
    "market": {
        S.SUBMITTED_TO_RESTAURANT: "Sent to your shopper",
        S.RESTAURANT_ACCEPTED: "Shopper accepted",
        S.PREPARING: "Buying your items",
        S.READY_FOR_PICKUP: "Bought and packed",
        S.RIDER_ASSIGNED: "Rider on the way to the market",
    },
    "waybill": {
        S.PAID: "Booked",
        S.IN_TRANSIT: "On the way",
        S.DELIVERED: "Delivered",
    },
    "parcel": {
        S.PAID: "Booking confirmed",
        S.READY_FOR_PICKUP: "Finding a rider",
        S.RIDER_ASSIGNED: "Rider heading to pickup",
        S.PICKED_UP: "Package picked up",
        S.IN_TRANSIT: "On the way to the recipient",
        S.DELIVERED: "Delivered",
    },
}


# Step numbers per service where the food timeline doesn't fit. Parcels: 0 booked · 1 rider found · 2 heading to
# pickup · 3 on the way · 4 delivered (the current step is the one in progress).
PROGRESS_STEPS: dict[str, dict[OrderStatus, int]] = {
    "parcel": {S.PAID: 1, S.READY_FOR_PICKUP: 1, S.RIDER_ASSIGNED: 2, S.PICKED_UP: 3, S.IN_TRANSIT: 3},
}


def progress_label(status: OrderStatus, vertical: str = "food") -> tuple[int, str]:
    step, label = CUSTOMER_PROGRESS[status]
    step = PROGRESS_STEPS.get(vertical, {}).get(status, step)
    return step, PROGRESS_LABELS.get(vertical, {}).get(status, label)


def can_transition(src: OrderStatus, dst: OrderStatus, actor: ActorType) -> bool:
    rule = TRANSITIONS.get((src, dst))
    return rule is not None and actor in rule.actors


def allowed_targets(src: OrderStatus, actor: ActorType) -> set[OrderStatus]:
    return {dst for (s, dst), rule in TRANSITIONS.items() if s == src and actor in rule.actors}


def assert_transition(src: OrderStatus, dst: OrderStatus, actor: ActorType, reason: str | None) -> None:
    """Raise if `actor` may not move an order from `src` to `dst`."""
    if src in TERMINAL:
        raise InvalidTransition(f"Order is {src.value}; no further changes are allowed")
    rule = TRANSITIONS.get((src, dst))
    if rule is None:
        raise InvalidTransition(
            f"Cannot move order from {src.value} to {dst.value}",
            details={"from": src.value, "to": dst.value},
        )
    if actor not in rule.actors:
        raise PermissionDenied(
            f"{actor.value} may not move an order from {src.value} to {dst.value}",
            details={"from": src.value, "to": dst.value, "actor": actor.value},
        )
    if actor in rule.reason_required_for and not (reason and reason.strip()):
        raise InvalidTransition("A reason is required for this action", details={"to": dst.value})
