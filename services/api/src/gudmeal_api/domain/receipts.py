"""Receipts (ADR-0019): what a customer paid for an order, as one document every client prints the same way.

A receipt only repeats figures the order already carries (lines and the price breakdown computed by
`pricing.py` when the order was quoted). Nothing is priced here.
"""

from __future__ import annotations

from datetime import datetime

from pydantic import Field

from .models import Model, Order, Vertical

SERVICE_NAMES = {
    Vertical.FOOD: "Order Food",
    Vertical.PHARMACY: "Pharmacy",
    Vertical.BEAUTY: "Beauty & Skin Care",
    Vertical.GROCERY: "Shop & Groceries",
    Vertical.MARKET: "Buy Foodstuff",
    Vertical.PARCEL: "Package Delivery",
    Vertical.WAYBILL: "Interstate waybill",
}
#: Payment states in which money has been taken for the order (a refund later does not unmake the receipt).
PAID_STATES = frozenset({"paid", "partially_refunded", "refunded"})
PAID_WITH = {"wallet": "Yummy Chops wallet", "cash": "Cash on delivery"}
PAID_ONLINE = "Card, bank transfer or USSD"
#: The receipt's rows for fees and taxes, in the order they are printed: (breakdown field, label, sign).
CHARGE_ROWS: tuple[tuple[str, str, int], ...] = (
    ("subtotal_kobo", "Subtotal", 1),
    ("delivery_fee_kobo", "Delivery fee", 1),
    ("linehaul_fee_kobo", "Transport between cities", 1),
    ("pickup_fee_kobo", "Pickup from your address", 1),
    ("cod_fee_kobo", "Cash-on-delivery fee", 1),
    ("service_fee_kobo", "Service fee", 1),
    ("small_order_fee_kobo", "Small order fee", 1),
    ("vat_kobo", "VAT", 1),
    ("discount_kobo", "Discount", -1),
)


class ReceiptLine(Model):
    name: str
    quantity: int
    amount_kobo: int
    details: list[str] = Field(default_factory=list)  # choices and notes: "Weight: 1 kg"


class ReceiptCharge(Model):
    label: str
    amount_kobo: int  # negative for a discount


class Receipt(Model):
    """`customer_profiles/{uid}/receipts/{order_id}`: one receipt per order, kept once the customer prints it."""

    id: str  # the order's id
    number: str  # what the customer quotes to support: "GM-" + the order's short code
    order_id: str
    order_code: str
    customer_id: str
    customer_name: str | None = None
    service: str
    service_name: str
    seller: str
    seller_address: str = ""
    summary: list[str] = Field(default_factory=list)  # packages: the route, size and tracking code
    lines: list[ReceiptLine] = Field(default_factory=list)
    charges: list[ReceiptCharge] = Field(default_factory=list)
    total_kobo: int
    savings_kobo: int = 0  # Yummy Chops Plus savings on this order (information only)
    refunded_kobo: int = 0
    paid_with: str
    payment_reference: str | None = None
    paid_at: datetime | None = None
    ordered_at: datetime
    issued_at: datetime
    printed_at: datetime | None = None
    print_count: int = 0
    saved: bool = False  # True once it is kept under "My receipts"


def is_paid(order: Order) -> bool:
    return order.payment.status in PAID_STATES


def _word(value: object) -> str:
    """An enum member or a plain string as words: `extra_large` reads "extra large"."""
    return str(getattr(value, "value", value)).replace("_", " ")


def _summary(order: Order) -> list[str]:
    if order.parcel is not None:
        p = order.parcel
        out = [
            f"From {p.pickup.area or p.pickup.line1} to {p.dropoff.area or p.dropoff.line1}",
            f"{_word(p.size).capitalize()} package: {_word(p.category)}",
            f"To {p.dropoff.name}",
        ]
        if p.cod_amount_kobo:
            out.append("The rider also collects the item price for the sender")
        return out
    if order.waybill is not None:
        w = order.waybill
        out = [
            f"{w.origin_city_name or w.origin_city} to {w.destination_city_name or w.destination_city}",
            f"Carrier: {w.carrier_name}",
        ]
        if w.tracking_code:
            out.append(f"Tracking number {w.tracking_code}")
        return out
    return []


def _charges(order: Order) -> list[ReceiptCharge]:
    b = order.breakdown
    rows = [
        ReceiptCharge(label=label, amount_kobo=sign * getattr(b, field))
        for field, label, sign in CHARGE_ROWS
        if getattr(b, field)
    ]
    # Never print rows that do not add up to what was charged: fall back to the total alone.
    return rows if sum(r.amount_kobo for r in rows) == b.total_kobo else []


def build_receipt(order: Order, now: datetime) -> Receipt:
    """The receipt for a paid order, from the order alone."""
    shop_order = order.parcel is None and order.waybill is None
    return Receipt(
        id=order.id,
        number=f"YC-{order.short_code}",
        order_id=order.id,
        order_code=order.short_code,
        customer_id=order.customer_id,
        customer_name=order.customer_name,
        service=order.vertical.value,
        service_name=SERVICE_NAMES.get(order.vertical, order.vertical.value.capitalize()),
        seller=order.restaurant_name if shop_order else "Yummy Chops",
        seller_address=order.restaurant_address if shop_order else SERVICE_NAMES[order.vertical],
        summary=_summary(order),
        lines=[
            ReceiptLine(
                name=line.name,
                quantity=line.quantity,
                amount_kobo=line.line_total_kobo,
                details=[*line.selection_labels, *([f"Note: {line.notes}"] if line.notes else [])],
            )
            for line in order.lines
        ],
        charges=_charges(order),
        total_kobo=order.breakdown.total_kobo,
        savings_kobo=order.breakdown.plus_savings_kobo,
        refunded_kobo=order.refund_total_kobo,
        paid_with=PAID_WITH.get(order.payment.provider or "", PAID_ONLINE),
        payment_reference=order.payment.reference,
        paid_at=order.payment.paid_at,
        ordered_at=order.created_at,
        issued_at=now,
    )
