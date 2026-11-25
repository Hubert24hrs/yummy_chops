"""Role-aware views of domain objects — each audience sees only what it needs."""

from __future__ import annotations

from typing import Any

from ..domain.logistics import WAYBILL_STEPS, stage_label, stage_step
from ..domain.models import Order, Quote
from ..domain.order_state import OrderStatus, progress_label
from ..security.rbac import Permission, Principal


def _progress(order: Order) -> dict[str, Any]:
    if order.waybill is not None and order.waybill.stage is not None:
        called_off = order.status in (OrderStatus.REFUND_PENDING, OrderStatus.REFUNDED, OrderStatus.CANCELLED)
        return {
            "step": -1 if called_off else stage_step(order.waybill),
            "total_steps": len(WAYBILL_STEPS),
            "label": progress_label(order.status, "waybill")[1] if called_off else stage_label(order.waybill),
            "steps": list(WAYBILL_STEPS),
        }
    step, label = progress_label(order.status, order.vertical.value)
    return {"step": step, "total_steps": 5, "label": label}


def order_view(order: Order, principal: Principal) -> dict[str, Any]:
    data = order.model_dump(mode="json")
    data["progress"] = _progress(order)
    if principal.can(Permission.ORDERS_READ_ALL):
        data["audience"] = "staff"
        return data
    if order.customer_id == principal.uid:
        data.pop("settlement", None)
        data["audience"] = "customer"
        return data
    if principal.can_on_restaurant(order.restaurant_id, "orders"):
        settlement = data.pop("settlement")
        data.pop("customer_phone", None)
        addr = data.get("delivery_address")
        if addr:
            data["delivery_address"] = {"area": addr.get("area"), "city": addr.get("city")}
        data["restaurant_earning_kobo"] = settlement["restaurant_earning_kobo"]
        data["commission_kobo"] = settlement["commission_kobo"]
        data["audience"] = "restaurant"
        return data
    if order.rider_id == principal.uid:
        parcel = order.parcel
        address = data["delivery_address"]
        if address is not None:
            # The rider reaches the customer on the way: the number given at checkout, else the account's own,
            # and only while the job is in progress (finished jobs in the rider's history show no number).
            on_the_job = order.status in (
                OrderStatus.RIDER_ASSIGNED,
                OrderStatus.PICKED_UP,
                OrderStatus.IN_TRANSIT,
            )
            phone = (address.get("contact_phone") or order.customer_phone) if on_the_job else None
            address = {**address, "contact_phone": phone}
        return {
            "id": order.id,
            "short_code": order.short_code,
            "vertical": order.vertical.value,
            "status": order.status.value,
            "progress": data["progress"],
            "fulfillment": order.fulfillment.value,
            "restaurant_name": order.restaurant_name,
            "restaurant_address": order.restaurant_address,
            "restaurant_location": data["restaurant_location"],
            "trip_id": order.trip_id,  # orders of one mixed cart collected in one trip (ADR-0031)
            "customer_name": order.customer_name,
            "delivery_address": address,
            "items": [{"name": ln.name, "quantity": ln.quantity} for ln in order.lines],
            "rider_pay_kobo": order.settlement.rider_pay_kobo,
            # Cash to take at the door (pay on delivery and/or the sender's COD amount); 0 when prepaid.
            "payment_method": "cash" if order.is_pay_on_delivery else "prepaid",
            # Waybill rider jobs: first mile ends at a hub (staff confirm the hand-over), last mile at the door.
            "leg_kind": order.leg_kind,
            "hub_handover": order.leg_kind == "first_mile",
            "collect_cash_kobo": order.cash_to_collect_kobo,
            "cash_collected_at": data["cash_collected_at"],
            "ready_at": data["ready_at"],
            "picked_up_at": data["picked_up_at"],
            "estimated_delivery_at": data["estimated_delivery_at"],
            # Parcels: the rider needs both contacts and what they are carrying (no prices or declared value).
            "parcel": None
            if parcel is None
            else {
                "size": parcel.size.value,
                "category": parcel.category,
                "description": parcel.description,
                "cod_amount_kobo": parcel.cod_amount_kobo,
                "pickup": parcel.pickup.model_dump(mode="json"),
                "dropoff": parcel.dropoff.model_dump(mode="json"),
            },
            "audience": "rider",
        }
    raise PermissionError("no view")  # callers must check access first


def quote_view(quote: Quote) -> dict[str, Any]:
    data = quote.model_dump(mode="json")
    data.pop("settlement", None)
    return data
