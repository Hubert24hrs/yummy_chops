"""Order lifecycle orchestration. All status changes go through `transition()` (Firestore transaction)."""

from __future__ import annotations

import hmac
import logging
import secrets
import uuid
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

from ..domain.models import (
    DeliveryAddress,
    Fulfillment,
    Order,
    OrderEvent,
    PaymentSummary,
    Vertical,
    Voucher,
    WaybillStage,
)
from ..domain.money import format_naira
from ..domain.order_state import ACTIVE_FULFILMENT, ActorType, OrderStatus, assert_transition
from ..errors import (
    InvalidTransition,
    NotFound,
    PermissionDenied,
    PriceChanged,
    QuoteExpired,
    ValidationFailed,
    VoucherInvalid,
)
from ..maps import RouteEstimate
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, require, require_restaurant
from .infra import Emitter, Notifier, TaskQueue
from .quotes import QuoteService, quoted_route

logger = logging.getLogger(__name__)
S = OrderStatus
A = ActorType
_SHORT_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"

TASK_RESTAURANT_TIMEOUT = "/internal/tasks/restaurant-accept-timeout"
TASK_UNPAID_EXPIRY = "/internal/tasks/unpaid-order-expiry"
TASK_PARCEL_RELEASE = "/internal/tasks/parcel-release"
PARCEL_DISPATCH_LEAD = timedelta(minutes=30)  # start finding a rider this long before a scheduled pickup
PARCEL_MERCHANT_ID = "gm-send"  # pseudo-merchant id for courier jobs (no partner owns it)
MAX_ORDERS_PER_CHECKOUT = 10  # a mixed cart: one order per shop, paid at once (ADR-0030)
REPAIR_WINDOW = timedelta(days=3)  # how far back the sweep looks for money paid on cancelled orders

# Per-service wording; falls back to CUSTOMER_NOTIFY.
NOTIFY_BY_VERTICAL: dict[Vertical, dict[OrderStatus, tuple[str, str]]] = {
    Vertical.BEAUTY: {
        S.RESTAURANT_ACCEPTED: ("Order accepted", "{restaurant} is packing your order"),
        S.DELIVERED: ("Delivered", "Your order from {restaurant} has arrived"),
    },
    Vertical.GROCERY: {
        S.RESTAURANT_ACCEPTED: ("Order accepted", "{restaurant} is packing your order"),
        S.DELIVERED: ("Delivered", "Your order from {restaurant} has arrived"),
    },
    Vertical.PHARMACY: {
        S.RESTAURANT_ACCEPTED: ("Order accepted", "{restaurant} is packing your order"),
        S.DELIVERED: ("Delivered", "Your order from {restaurant} has arrived"),
    },
    Vertical.MARKET: {
        S.RESTAURANT_ACCEPTED: ("Shopper on it", "{restaurant} is buying your items"),
        S.DELIVERED: ("Delivered", "Your foodstuff has arrived"),
    },
    Vertical.WAYBILL: {
        S.DELIVERED: ("Delivered", "Your interstate package has been delivered"),
        S.REFUND_PENDING: ("Refund started", "We're refunding your waybill booking"),
        S.CANCELLED: ("Booking cancelled", "Your waybill booking was cancelled"),
    },
    Vertical.PARCEL: {
        S.READY_FOR_PICKUP: ("Finding a rider", "We're assigning a rider to collect your package"),
        S.RIDER_ASSIGNED: ("Rider assigned", "{rider} is heading to collect your package"),
        S.PICKED_UP: ("Package picked up", "{rider} has your package and is on the way"),
        S.DELIVERED: ("Delivered", "Your package has been delivered"),
        S.REFUND_PENDING: ("Refund started", "We're refunding your package booking"),
        S.CANCELLED: ("Booking cancelled", "Your package booking was cancelled"),
    },
}

CUSTOMER_NOTIFY: dict[OrderStatus, tuple[str, str]] = {
    S.RESTAURANT_ACCEPTED: ("Order accepted", "{restaurant} is preparing your order"),
    S.READY_FOR_PICKUP: ("Ready", "Your order from {restaurant} is ready"),
    S.RIDER_ASSIGNED: ("Rider assigned", "{rider} is heading to {restaurant}"),
    S.PICKED_UP: ("On the way", "{rider} has picked up your order"),
    S.DELIVERED: ("Delivered", "Enjoy your meal from {restaurant}!"),
    S.REFUND_PENDING: ("Refund started", "We're refunding your order from {restaurant}"),
    S.REFUNDED: ("Refunded", "Your refund has been processed"),
    S.CANCELLED: ("Order cancelled", "Your order from {restaurant} was cancelled"),
}


def utcnow() -> datetime:
    return datetime.now(UTC)


def short_code() -> str:
    return "".join(secrets.choice(_SHORT_ALPHABET) for _ in range(6))


def new_code() -> str:
    return f"{secrets.randbelow(10_000):04d}"


Patch = dict[str, Any] | Callable[[Order], dict[str, Any]]


class OrderService:
    def __init__(
        self,
        repos: Repositories,
        quotes: QuoteService,
        *,
        emitter: Emitter,
        notifier: Notifier,
        tasks: TaskQueue,
        payments: Any,
        cash: Any = None,
        restaurant_accept_timeout_seconds: int = 480,
        unpaid_order_ttl_seconds: int = 1800,
        code_max_attempts: int = 5,
    ) -> None:
        self.repos = repos
        self.quotes = quotes
        self.emitter = emitter
        self.notifier = notifier
        self.tasks = tasks
        self.payments = payments
        self.cash = cash  # CashService: pay-on-delivery eligibility
        self.accept_timeout = restaurant_accept_timeout_seconds
        self.unpaid_ttl = unpaid_order_ttl_seconds
        self.code_max_attempts = code_max_attempts

    # ============================================================================ core transition
    @staticmethod
    def build_transition(
        order: Order,
        to: OrderStatus,
        *,
        actor_type: ActorType,
        actor_id: str,
        reason: str | None = None,
        patch: Patch | None = None,
        metadata: dict[str, Any] | None = None,
        now: datetime,
    ) -> tuple[dict[str, Any], OrderEvent]:
        assert_transition(order.status, to, actor_type, reason)
        updates: dict[str, Any] = {"status": to, "updated_at": now, "version": order.version + 1}
        if patch:
            updates.update(patch(order) if callable(patch) else patch)
        _money_guard(order, to, updates)
        _flow_guard(order, to, actor_type)
        event = OrderEvent(
            id=uuid.uuid4().hex,
            order_id=order.id,
            from_status=order.status,
            to_status=to,
            actor_type=actor_type,
            actor_id=actor_id,
            reason=reason,
            at=now,
            metadata=metadata or {},
        )
        return updates, event

    @staticmethod
    def write_transition(tx: Transaction, order_id: str, updates: dict[str, Any], event: OrderEvent) -> None:
        tx.update(f"orders/{order_id}", to_doc(updates))
        tx.create(f"order_events/{event.id}", to_doc(event))

    async def transition(
        self,
        order_id: str,
        to: OrderStatus,
        *,
        actor_type: ActorType,
        actor_id: str,
        reason: str | None = None,
        patch: Patch | None = None,
        metadata: dict[str, Any] | None = None,
        check: Callable[[Order], None] | None = None,
    ) -> Order:
        now = utcnow()
        captured: dict[str, Any] = {}

        async def fn(tx: Transaction) -> Order:
            data = await tx.get(f"orders/{order_id}")
            if data is None:
                raise NotFound("Order not found")
            order = Order.model_validate(data)
            if check:
                check(order)
            updates, event = self.build_transition(
                order,
                to,
                actor_type=actor_type,
                actor_id=actor_id,
                reason=reason,
                patch=patch,
                metadata=metadata,
                now=now,
            )
            if _frees_voucher(order, to):
                await self._release_voucher(tx, order)  # reads first: a transaction reads before it writes
            self.write_transition(tx, order_id, updates, event)
            captured["from"] = order.status
            captured["event"] = event
            return Order.model_validate({**order.model_dump(), **updates})

        updated = await self.repos.store.run_transaction(fn)
        await self.after_transition(updated, captured["from"], captured["event"])
        return updated

    async def after_transition(self, order: Order, previous: OrderStatus, event: OrderEvent) -> None:
        await self.emitter.emit(f"order.{order.status.value}", _event_payload(order, previous, event))
        if order.is_leg:
            return  # internal rider job of a waybill: the waybill sends the customer its own updates
        template = NOTIFY_BY_VERTICAL.get(order.vertical, {}).get(order.status) or CUSTOMER_NOTIFY.get(
            order.status
        )
        if template:
            title, body = template
            await self.notifier.notify_user(
                order.customer_id,
                title,
                body.format(restaurant=order.restaurant_name, rider=order.rider_name or "Your rider"),
                {"order_id": order.id, "status": order.status.value},
            )

    # ============================================================================ reads
    async def get(self, order_id: str) -> Order:
        order = await self.repos.orders.get(order_id)
        if order is None:
            raise NotFound("Order not found")
        return order

    def assert_can_view(self, principal: Principal, order: Order) -> None:
        if order.customer_id == principal.uid:
            return
        if principal.can_on_restaurant(order.restaurant_id, "orders"):
            return
        if order.rider_id and order.rider_id == principal.uid:
            return
        if principal.can(Permission.ORDERS_READ_ALL):
            return
        raise NotFound("Order not found")  # do not reveal existence

    async def get_for(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        self.assert_can_view(principal, order)
        return order

    async def list_for_customer(self, uid: str, limit: int = 20) -> list[Order]:
        orders = await self.repos.orders.find(
            where=[("customer_id", "==", uid)], order_by=[("created_at", "desc")], limit=min(limit, 100)
        )
        return [o for o in orders if not o.is_leg]  # waybill rider jobs are internal

    async def list_for_restaurant(
        self,
        principal: Principal,
        restaurant_id: str,
        statuses: list[OrderStatus] | None = None,
        limit: int = 50,
    ) -> list[Order]:
        require_restaurant(principal, restaurant_id, "orders")
        where: list[Any] = [("restaurant_id", "==", restaurant_id)]
        if statuses:
            where.append(("status", "in", [s.value for s in statuses][:10]))
        return await self.repos.orders.find(
            where=where, order_by=[("created_at", "desc")], limit=min(limit, 200)
        )

    async def list_for_rider(
        self, uid: str, statuses: list[OrderStatus] | None = None, limit: int = 30
    ) -> list[Order]:
        where: list[Any] = [("rider_id", "==", uid)]
        if statuses:
            where.append(("status", "in", [s.value for s in statuses][:10]))
        return await self.repos.orders.find(
            where=where, order_by=[("created_at", "desc")], limit=min(limit, 100)
        )

    async def list_all(
        self, principal: Principal, status: OrderStatus | None = None, limit: int = 100
    ) -> list[Order]:
        require(principal, Permission.ORDERS_READ_ALL)
        where = [("status", "==", status.value)] if status else []
        return await self.repos.orders.find(
            where=where, order_by=[("created_at", "desc")], limit=min(limit, 500)
        )

    async def events(self, principal: Principal, order_id: str) -> list[OrderEvent]:
        await self.get_for(principal, order_id)
        return await self.repos.order_events.find(
            where=[("order_id", "==", order_id)], order_by=[("at", "asc")]
        )

    async def customer_codes(self, principal: Principal, order_id: str) -> dict[str, Any]:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        codes = await self.repos.store.get(self.repos.codes_path(order_id)) or {}
        return {"delivery_code": codes.get("delivery_code"), "pickup_code": codes.get("pickup_code")}

    # ============================================================================ customer flows
    async def create_from_quote(
        self,
        principal: Principal,
        quote_id: str,
        *,
        channel: Literal["app", "web", "ai_agent", "whatsapp", "admin"] = "app",
        contact_phone: str | None = None,
        group_order_id: str | None = None,
    ) -> Order:
        quote = await self.quotes.get_quote(principal, quote_id)
        if quote.order_id:
            return await self.get(quote.order_id)  # creating twice from one quote is idempotent
        now = utcnow()
        if quote.expires_at < now:
            raise QuoteExpired("Your price quote expired; please review your cart again")

        # Re-validate against live data: availability, opening hours and unchanged prices.
        from ..domain.models import CartLine, QuoteRequest

        req = QuoteRequest(
            restaurant_id=quote.restaurant_id,
            lines=[
                CartLine(item_id=ln.item_id, quantity=ln.quantity, selections=ln.selections, notes=ln.notes)
                for ln in quote.lines
            ],
            fulfillment=quote.fulfillment,
            delivery_address=quote.delivery_address,
            scheduled_for=quote.scheduled_for,
            voucher_code=quote.breakdown.voucher_code,
        )
        # Reuse the quote's road distance: re-measuring could shift a fee with traffic, not with any change
        # the customer made.
        restaurant, result, *_ = await self.quotes.price_request(
            req, customer_id=principal.uid, now=now, route=quoted_route(quote)
        )
        if result.breakdown.total_kobo != quote.breakdown.total_kobo:
            raise PriceChanged(
                "Prices changed since your quote; please review your cart",
                details={
                    "quoted_total_kobo": quote.breakdown.total_kobo,
                    "new_total_kobo": result.breakdown.total_kobo,
                },
            )

        order_id = uuid.uuid4().hex
        address = quote.delivery_address
        if address and contact_phone:
            address = address.model_copy(update={"contact_phone": contact_phone})
        order = Order(
            id=order_id,
            short_code=short_code(),
            customer_id=principal.uid,
            customer_name=principal.name,
            customer_phone=contact_phone or principal.phone,
            vertical=restaurant.vertical,
            restaurant_id=restaurant.id,
            restaurant_name=restaurant.name,
            restaurant_location=restaurant.location,
            restaurant_address=restaurant.address,
            status=S.DRAFT,
            fulfillment=quote.fulfillment,
            lines=quote.lines,
            breakdown=quote.breakdown,
            settlement=quote.settlement,
            delivery_address=address,
            distance_km=quote.distance_km,
            scheduled_for=quote.scheduled_for,
            quote_id=quote.id,
            estimated_delivery_at=quote.estimated_delivery_at,
            channel=channel,
            group_order_id=group_order_id,
            created_at=now,
            updated_at=now,
        )
        event = OrderEvent(
            id=uuid.uuid4().hex,
            order_id=order_id,
            from_status=None,
            to_status=S.DRAFT,
            actor_type=A.CUSTOMER,
            actor_id=principal.uid,
            at=now,
            metadata={"channel": channel},
        )

        async def fn(tx: Transaction) -> str:
            qdata = await tx.get(f"quotes/{quote.id}")
            if qdata and qdata.get("order_id"):
                return str(qdata["order_id"])
            await self._reserve_voucher(tx, order)  # may refuse; reads first, then its writes with the rest
            tx.update(f"quotes/{quote.id}", {"order_id": order_id})
            tx.create(f"orders/{order_id}", to_doc(order))
            tx.create(f"order_events/{event.id}", to_doc(event))
            return order_id

        created_id = await self.repos.store.run_transaction(fn)
        if created_id != order_id:
            return await self.get(created_id)
        await self.tasks.enqueue(TASK_UNPAID_EXPIRY, {"order_id": order_id}, delay_seconds=self.unpaid_ttl)
        return order

    async def checkout(
        self, principal: Principal, order_id: str, *, provider: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        """Pay for an order: gateway (card/transfer/USSD), Yummy Chops wallet, or cash on delivery."""
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        if order.is_leg:
            raise InvalidTransition("This is part of a waybill and is paid with the waybill")
        if order.group_order_id:
            group = await self.repos.group_orders.get(order.group_order_id)
            if group is not None and group.split_mode == "each":
                raise InvalidTransition("Everyone pays their own share from the group order")
        if order.status not in (S.DRAFT, S.PENDING_PAYMENT):
            raise InvalidTransition(f"Order is already {order.status.value}")
        if provider == "cash":
            await self.cash.assert_pay_on_delivery(principal, order)  # refused orders stay payable online
        if order.status == S.DRAFT:
            order = await self.transition(
                order_id, S.PENDING_PAYMENT, actor_type=A.CUSTOMER, actor_id=principal.uid
            )
        if provider == "wallet":
            payment = await self.payments.pay_with_wallet(order, principal, idempotency_key)
            order = await self.get(order_id)  # payment.succeeded has already moved it on
            return {"order_id": order_id, "status": order.status.value, **payment}
        if provider == "cash":
            return await self._submit_pay_on_delivery(order, idempotency_key)
        payment = await self.payments.initiate(order, principal, provider, idempotency_key)
        summary = PaymentSummary(
            provider=payment["provider"], reference=payment["reference"], status="pending"
        )

        async def fn(tx: Transaction) -> None:
            # Only while the order still waits for payment: the payer may have paid in the meantime (a checkout
            # link opened earlier), and "pending" must never be written over "paid".
            doc = await tx.get(f"orders/{order_id}")
            if doc is not None and doc.get("status") in (S.DRAFT.value, S.PENDING_PAYMENT.value):
                tx.update(f"orders/{order_id}", {"payment": to_doc(summary), "updated_at": utcnow()})

        await self.repos.store.run_transaction(fn)
        return {"order_id": order_id, "status": S.PENDING_PAYMENT.value, **payment}

    async def checkout_many(
        self, principal: Principal, order_ids: list[str], *, provider: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        """Pay for a mixed cart: several orders of this customer, one per shop, with ONE payment (ADR-0030).

        Card: one gateway checkout for the sum; when it is verified every order gets its share and goes to its
        shop. Wallet: one debit of the sum. Cash: each order is placed as pay on delivery (checked one by one).
        Each order is then prepared, dispatched, delivered, refunded and settled on its own."""
        ids = list(dict.fromkeys(order_ids))
        if not ids or len(ids) > MAX_ORDERS_PER_CHECKOUT:
            raise ValidationFailed(f"Pay for 1 to {MAX_ORDERS_PER_CHECKOUT} orders at once")
        if len(ids) == 1 or provider == "cash":
            placed = [
                await self.checkout(
                    principal, oid, provider=provider, idempotency_key=f"{idempotency_key}:{oid}"
                )
                for oid in ids
            ]
            first = placed[0]
            return {
                **first,
                "order_ids": ids,
                "reference": first.get("reference") if len(ids) == 1 else None,
                "amount_kobo": sum(int(p.get("amount_kobo") or 0) for p in placed),
                "orders": [
                    {"order_id": p["order_id"], "status": p["status"], "amount_kobo": p.get("amount_kobo")}
                    for p in placed
                ],
            }
        orders = [await self.get(oid) for oid in ids]
        for order in orders:
            if order.customer_id != principal.uid:
                raise NotFound("Order not found")
            if order.is_leg or order.is_waybill or order.is_parcel or order.group_order_id:
                raise InvalidTransition(f"Order {order.short_code} is paid on its own")
            if order.status not in (S.DRAFT, S.PENDING_PAYMENT):
                raise InvalidTransition(f"Order {order.short_code} is already {order.status.value}")
        orders = [
            await self.transition(o.id, S.PENDING_PAYMENT, actor_type=A.CUSTOMER, actor_id=principal.uid)
            if o.status == S.DRAFT
            else o
            for o in orders
        ]
        if provider == "wallet":
            payment = await self.payments.pay_basket_with_wallet(orders, principal, idempotency_key)
        else:
            payment = await self.payments.initiate_basket(orders, principal, provider, idempotency_key)
            summary = to_doc(
                PaymentSummary(provider=payment["provider"], reference=payment["reference"], status="pending")
            )
            for oid in ids:

                async def fn(tx: Transaction, oid: str = oid) -> None:
                    # As for one order: "pending" is never written over "paid".
                    doc = await tx.get(f"orders/{oid}")
                    if doc is not None and doc.get("status") in (S.DRAFT.value, S.PENDING_PAYMENT.value):
                        tx.update(f"orders/{oid}", {"payment": summary, "updated_at": utcnow()})

                await self.repos.store.run_transaction(fn)
        now = [await self.get(oid) for oid in ids]
        return {
            **payment,
            "order_id": ids[0],
            "order_ids": ids,
            "status": now[0].status.value,
            "orders": [
                {"order_id": o.id, "status": o.status.value, "amount_kobo": o.breakdown.total_kobo}
                for o in now
            ],
        }

    async def _submit_pay_on_delivery(self, order: Order, idempotency_key: str) -> dict[str, Any]:
        """Eligible cash order: record the cash due and send it to the merchant without online payment."""
        payment = await self.payments.start_cash_payment(order, idempotency_key)
        summary = PaymentSummary(provider="cash", reference=payment["reference"], status="pending")
        order = await self.transition(
            order.id,
            S.SUBMITTED_TO_RESTAURANT,
            actor_type=A.SYSTEM,
            actor_id="payments",
            patch={"payment": to_doc(summary)},
            metadata={"payment_method": "cash", "reference": payment["reference"]},
            check=lambda o: _expect(o, {S.PENDING_PAYMENT}),
        )
        await self._issue_codes(order)
        await self._notify_merchant(order)
        return {"order_id": order.id, "status": order.status.value, **payment}

    async def _issue_codes(self, order: Order) -> None:
        await self.repos.store.set(
            self.repos.codes_path(order.id),
            {
                "order_id": order.id,
                "customer_id": order.customer_id,
                "delivery_code": new_code(),
                "pickup_code": new_code(),
                "attempts": 0,
                "locked": False,
            },
        )

    async def _notify_merchant(self, order: Order) -> None:
        """New order for the merchant ("Payment received" when it is paid already), and the timer that refunds or
        cancels it if nobody confirms it."""
        if order.is_pay_on_delivery:
            title = "New order"
            body = f"Order {order.short_code} · {format_naira(order.breakdown.subtotal_kobo)} · customer pays cash on delivery"
        else:
            title = "Payment received"
            body = f"Order {order.short_code} · {format_naira(order.breakdown.subtotal_kobo)} paid. Confirm the order to start."
            if order.payment.split_to_business_kobo:
                share = format_naira(order.payment.split_to_business_kobo)
                body += f" Your {share} is on its way to your bank account (Paystack)."
        await self.notifier.notify_restaurant(order.restaurant_id, title, body, {"order_id": order.id})
        await self.tasks.enqueue(
            TASK_RESTAURANT_TIMEOUT, {"order_id": order.id}, delay_seconds=self.accept_timeout
        )

    async def cancel_by_customer(self, principal: Principal, order_id: str, reason: str | None) -> Order:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        if order.is_leg:
            raise InvalidTransition("This is part of a waybill; cancel the waybill instead")
        reason = (reason or "Cancelled by customer").strip()[:300]
        if order.is_waybill and order.status == S.PAID:
            return await self._cancel_waybill(principal, order, reason)
        if order.awaiting_cash_payment and order.status == S.SUBMITTED_TO_RESTAURANT:
            # Pay on delivery before the merchant accepted: nothing was paid, so nothing to refund.
            return await self.transition(
                order_id,
                S.CANCELLED,
                actor_type=A.CUSTOMER,
                actor_id=principal.uid,
                reason=reason,
                patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
                check=lambda o: _expect(o, {S.SUBMITTED_TO_RESTAURANT}),
            )
        if order.status in (S.DRAFT, S.PENDING_PAYMENT):
            return await self.transition(
                order_id,
                S.CANCELLED,
                actor_type=A.CUSTOMER,
                actor_id=principal.uid,
                reason=reason,
                patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
            )
        # Full automatic refund while nobody has started work: the merchant hasn't accepted yet, or (parcels)
        # no rider has been assigned.
        refundable = {S.PAID, S.READY_FOR_PICKUP} if order.is_parcel else {S.PAID, S.SUBMITTED_TO_RESTAURANT}
        if order.status in refundable:
            return await self.transition(
                order_id,
                S.REFUND_PENDING,
                actor_type=A.CUSTOMER,
                actor_id=principal.uid,
                reason=reason,
                patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
                metadata=refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
                check=lambda o: _expect(o, refundable),
            )
        raise InvalidTransition("This order can no longer be cancelled in the app; please contact support")

    async def _cancel_waybill(self, principal: Principal, order: Order, reason: str) -> Order:
        """Full refund until the package is with a rider or at the hub; after that, support decides."""
        w = order.waybill
        assert w is not None
        leg = await self.repos.orders.get(w.first_mile_order_id) if w.first_mile_order_id else None
        early = w.stage in (None, WaybillStage.AWAITING_DROPOFF, WaybillStage.PICKUP_SCHEDULED)
        if not early or (leg is not None and leg.status not in (S.DRAFT, S.READY_FOR_PICKUP, S.CANCELLED)):
            raise InvalidTransition(
                "Your package is already with a rider or at the hub; please contact support to cancel"
            )
        return await self.transition(
            order.id,
            S.REFUND_PENDING,
            actor_type=A.CUSTOMER,
            actor_id=principal.uid,
            reason=reason,
            patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
            metadata=refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
            check=lambda o: _expect(o, {S.PAID}),
        )

    async def dispute(self, principal: Principal, order_id: str, reason: str) -> Order:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        if order.is_leg:
            raise InvalidTransition("This is part of a waybill; raise the issue on the waybill")
        if order.completed_at and utcnow() - order.completed_at > timedelta(days=2):
            raise InvalidTransition("Disputes must be raised within 48 hours of delivery")
        return await self.transition(
            order_id, S.DISPUTED, actor_type=A.CUSTOMER, actor_id=principal.uid, reason=reason
        )

    # ============================================================================ payment hooks
    async def on_payment_succeeded(self, payload: dict[str, Any]) -> None:
        order_id = str(payload["order_id"])
        order = await self.get(order_id)
        paid_at = payload.get("paid_at") or utcnow().isoformat()
        payment_patch = {
            "payment": to_doc(
                PaymentSummary(
                    provider=payload.get("provider"),
                    reference=payload.get("reference"),
                    status="paid",
                    paid_at=datetime.fromisoformat(str(paid_at)),
                    split_to_business_kobo=int(payload.get("split_amount_kobo") or 0),
                )
            )
        }
        reference = payload.get("reference")
        if order.status == S.CANCELLED or (
            order.status not in (S.DRAFT, S.PENDING_PAYMENT) and order.payment.reference != reference
        ):
            # Paid after the order was cancelled/expired, or a second payment for an order that is already paid
            # (another gateway, the wallet, or switched to pay on delivery) → refund this payment automatically.
            await self.emitter.emit(
                "payment.orphaned",
                {
                    "order_id": order_id,
                    "payment_id": payload.get("payment_id"),
                    **refund_meta(int(payload["amount_kobo"]), "platform", "before_completion", auto=True),
                },
            )
            return
        if order.status == S.DRAFT:
            order = await self.transition(
                order_id, S.PENDING_PAYMENT, actor_type=A.SYSTEM, actor_id="payments"
            )
        if order.status == S.PENDING_PAYMENT:
            if int(payload["amount_kobo"]) != order.breakdown.total_kobo:
                logger.error(
                    "paid amount differs from order total", extra={"extra_fields": {"order_id": order_id}}
                )
                return
            order = await self.transition(
                order_id,
                S.PAID,
                actor_type=A.SYSTEM,
                actor_id="payments",
                patch=payment_patch,
                metadata={"reference": payload.get("reference")},
            )
            await self._issue_codes(order)
        if order.status == S.PAID and order.is_parcel:
            await self._schedule_parcel_release(order)
            return
        if order.status == S.PAID and order.is_waybill:
            # Rider pickup or hub drop-off is arranged by WaybillService (after the codes above exist).
            await self.emitter.emit("waybill.paid", {"order_id": order_id})
            return
        if order.status == S.PAID:
            order = await self.transition(
                order_id, S.SUBMITTED_TO_RESTAURANT, actor_type=A.SYSTEM, actor_id="payments"
            )
            await self._notify_merchant(order)

    async def _reserve_voucher(self, tx: Transaction, order: Order) -> None:
        """Count the order's voucher as used, in the transaction that creates the order. Counting it only once
        the order was paid let one voucher go on any number of orders opened before the first was paid. The
        voucher's limits are enforced here; `_release_voucher` gives it back if the order comes to nothing."""
        code = order.breakdown.voucher_code
        if not code:
            return
        used_path = f"vouchers/{code}/redemptions/{order.customer_id}"
        vdoc = await tx.get(f"vouchers/{code}")
        used = await tx.get(used_path) or {}
        if vdoc is None:
            raise VoucherInvalid("Voucher code not recognised")
        voucher = Voucher.model_validate(vdoc)
        holding = list(used.get("order_ids", []))
        if order.id in holding:
            return
        if int(used.get("count", 0)) >= voucher.per_customer_limit:
            raise VoucherInvalid("You have already used this voucher")
        if voucher.usage_limit is not None and voucher.used_count >= voucher.usage_limit:
            raise VoucherInvalid("This voucher has been fully redeemed")
        tx.update(f"vouchers/{code}", {"used_count": voucher.used_count + 1})
        tx.set(
            used_path,
            {
                "count": int(used.get("count", 0)) + 1,
                "last_order_id": order.id,
                "order_ids": [*holding, order.id],
            },
        )

    async def _release_voucher(self, tx: Transaction, order: Order) -> None:
        """Give an order's voucher back (see `_frees_voucher`). Only an order that holds it gives it back, and
        an order ends cancelled or refunded once, so a voucher is never handed back twice."""
        code = order.breakdown.voucher_code
        if not code:
            return
        used_path = f"vouchers/{code}/redemptions/{order.customer_id}"
        vdoc = await tx.get(f"vouchers/{code}")
        used = await tx.get(used_path) or {}
        holding = list(used.get("order_ids", []))
        if order.id not in holding:
            return
        tx.set(
            used_path,
            {
                **used,
                "count": max(0, int(used.get("count", 0)) - 1),
                "order_ids": [oid for oid in holding if oid != order.id],
            },
        )
        if vdoc is not None:
            tx.update(f"vouchers/{code}", {"used_count": max(0, int(vdoc.get("used_count", 0)) - 1)})

    async def on_refund_succeeded(self, payload: dict[str, Any]) -> None:
        order = await self.get(str(payload["order_id"]))
        if order.status != S.REFUND_PENDING or payload.get("pending_refunds"):
            return  # a split group-order refund moves the order on with its last part
        full = bool(payload.get("fully_refunded"))
        total_refunded = int(payload.get("total_refunded_kobo", order.refund_total_kobo))
        await self.transition(
            order.id,
            S.REFUNDED if full else S.PARTIALLY_REFUNDED,
            actor_type=A.SYSTEM,
            actor_id="payments",
            patch={
                "refund_total_kobo": total_refunded,
                "payment.status": "refunded" if full else "partially_refunded",
            },
            metadata={"refund_id": payload.get("refund_id")},
        )

    async def on_refund_rejected(self, payload: dict[str, Any]) -> None:
        order = await self.get(str(payload["order_id"]))
        if order.status == S.REFUND_PENDING and order.completed_at:
            await self.transition(
                order.id,
                S.COMPLETED,
                actor_type=A.STAFF,
                actor_id=str(payload.get("decided_by")),
                reason=str(payload.get("note") or "Refund rejected"),
            )

    async def expire_unpaid(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.status not in (S.DRAFT, S.PENDING_PAYMENT):
            return
        if order.payment.reference:
            await self.payments.verify_reference(order.payment.reference, source="reconcile")
            order = await self.get(order.id)
            if order.status not in (S.DRAFT, S.PENDING_PAYMENT):
                return
        await self.transition(
            order.id,
            S.CANCELLED,
            actor_type=A.SYSTEM,
            actor_id="scheduler",
            reason="Payment not completed in time",
            patch={"cancelled_at": utcnow(), "cancellation_reason": "payment_timeout"},
        )

    # ============================================================================ restaurant flows
    # ============================================================================ package delivery
    async def create_parcel_order(
        self,
        principal: Principal,
        quote_id: str,
        *,
        parcels: Any,
        channel: Literal["app", "web", "ai_agent", "whatsapp", "admin"] = "app",
    ) -> Order:
        """Create a courier order from a parcel quote (idempotent per quote, re-priced like food orders)."""
        quote = await parcels.get_quote(principal, quote_id)
        if quote.order_id:
            return await self.get(quote.order_id)
        now = utcnow()
        if quote.expires_at < now:
            raise QuoteExpired("Your price quote expired; please get a new price")
        from ..domain.models import ParcelQuoteRequest

        d = quote.details
        result, *_ = await parcels.price(
            ParcelQuoteRequest(
                pickup=d.pickup,
                dropoff=d.dropoff,
                size=d.size,
                category=d.category,
                description=d.description,
                declared_value_kobo=d.declared_value_kobo,
                scheduled_for=quote.scheduled_for,
                cod_amount_kobo=d.cod_amount_kobo,
            ),
            now=now,
            route=RouteEstimate(
                distance_km=quote.road_distance_km or 0.0,
                duration_minutes=0,
                source=quote.route_source or "estimate",
            ),
        )
        if result.breakdown.total_kobo != quote.breakdown.total_kobo:
            raise PriceChanged(
                "Delivery prices changed since your quote; please review the new price",
                details={
                    "quoted_total_kobo": quote.breakdown.total_kobo,
                    "new_total_kobo": result.breakdown.total_kobo,
                },
            )
        order_id = uuid.uuid4().hex
        pickup, dropoff = d.pickup, d.dropoff
        order = Order(
            id=order_id,
            short_code=short_code(),
            vertical=Vertical.PARCEL,
            customer_id=principal.uid,
            customer_name=principal.name,
            customer_phone=principal.phone or pickup.phone,
            restaurant_id=PARCEL_MERCHANT_ID,
            restaurant_name=f"Package from {pickup.name}",
            restaurant_location=pickup.location,
            restaurant_address=", ".join(x for x in (pickup.line1, pickup.area, pickup.city) if x),
            status=S.DRAFT,
            fulfillment=Fulfillment.DELIVERY,
            lines=[],
            breakdown=quote.breakdown,
            settlement=quote.settlement,
            delivery_address=DeliveryAddress(
                label=f"Recipient: {dropoff.name}"[:40],
                line1=dropoff.line1,
                area=dropoff.area,
                city=dropoff.city,
                state=dropoff.city,
                location=dropoff.location,
                instructions=dropoff.instructions,
                contact_phone=dropoff.phone,
            ),
            distance_km=quote.distance_km,
            scheduled_for=quote.scheduled_for,
            quote_id=quote.id,
            estimated_delivery_at=quote.estimated_delivery_at,
            channel=channel,
            parcel=d,
            created_at=now,
            updated_at=now,
        )
        event = OrderEvent(
            id=uuid.uuid4().hex,
            order_id=order_id,
            from_status=None,
            to_status=S.DRAFT,
            actor_type=A.CUSTOMER,
            actor_id=principal.uid,
            at=now,
            metadata={"channel": channel, "vertical": "parcel"},
        )

        async def fn(tx: Transaction) -> str:
            qdata = await tx.get(f"parcel_quotes/{quote.id}")
            if qdata and qdata.get("order_id"):
                return str(qdata["order_id"])
            tx.update(f"parcel_quotes/{quote.id}", {"order_id": order_id})
            tx.create(f"orders/{order_id}", to_doc(order))
            tx.create(f"order_events/{event.id}", to_doc(event))
            return order_id

        created_id = await self.repos.store.run_transaction(fn)
        if created_id != order_id:
            return await self.get(created_id)
        await self.tasks.enqueue(TASK_UNPAID_EXPIRY, {"order_id": order_id}, delay_seconds=self.unpaid_ttl)
        return order

    async def _schedule_parcel_release(self, order: Order) -> None:
        """Paid parcel: look for a rider now, or shortly before the scheduled pickup time."""
        if order.scheduled_for is not None:
            start_at = order.scheduled_for - PARCEL_DISPATCH_LEAD
            delay = int((start_at - utcnow()).total_seconds())
            if delay > 60:
                await self.tasks.enqueue(TASK_PARCEL_RELEASE, {"order_id": order.id}, delay_seconds=delay)
                return
        await self.release_parcel({"order_id": order.id})

    async def release_parcel(self, payload: dict[str, Any]) -> None:
        """Task handler: a paid parcel becomes ready for pickup, which starts rider dispatch."""
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or not order.is_parcel or order.status != S.PAID:
            return  # cancelled/refunded meanwhile, or already released (task retries are harmless)

        def only_paid_parcels(o: Order) -> None:
            if not o.is_parcel:
                raise InvalidTransition("Only package deliveries skip the merchant")
            _expect(o, {S.PAID})

        await self.transition(
            order.id,
            S.READY_FOR_PICKUP,
            actor_type=A.SYSTEM,
            actor_id="parcels",
            patch={"ready_at": utcnow()},
            check=only_paid_parcels,
        )

    # ============================================================================ customer summary
    async def summary_for_customer(self, uid: str) -> dict[str, Any]:
        """Totals across everything a customer has paid for (amounts net of refunds, integer kobo)."""
        orders = await self.repos.orders.find(where=[("customer_id", "==", uid)], limit=5000)
        paid = [o for o in orders if o.payment.status in ("paid", "refunded", "partially_refunded")]
        by_vertical: dict[str, dict[str, int]] = {v.value: {"orders": 0, "spent_kobo": 0} for v in Vertical}
        favourite: dict[str, tuple[str, int]] = {}
        now = utcnow()
        month_spent = 0
        for o in paid:
            net = max(0, o.breakdown.total_kobo - o.refund_total_kobo)
            bucket = by_vertical[o.vertical.value]
            bucket["orders"] += 1
            bucket["spent_kobo"] += net
            if o.created_at.year == now.year and o.created_at.month == now.month:
                month_spent += net
            if not o.is_parcel:
                name, count = favourite.get(o.restaurant_id, (o.restaurant_name, 0))
                favourite[o.restaurant_id] = (name, count + 1)
        fav = max(favourite.items(), key=lambda kv: kv[1][1], default=None)
        in_progress = sum(1 for o in orders if o.status in ACTIVE_FULFILMENT)
        return {
            "orders_count": len(paid),
            "completed_count": sum(1 for o in paid if o.status == S.COMPLETED),
            "in_progress_count": in_progress,
            "total_spent_kobo": sum(b["spent_kobo"] for b in by_vertical.values()),
            "this_month_spent_kobo": month_spent,
            "refunded_kobo": sum(o.refund_total_kobo for o in paid),
            "by_vertical": by_vertical,
            "favourite_merchant": None
            if fav is None
            else {"id": fav[0], "name": fav[1][0], "orders": fav[1][1]},
            "first_order_at": min((o.created_at for o in paid), default=None),
            "last_order_at": max((o.created_at for o in paid), default=None),
        }

    def _restaurant_actor(self, principal: Principal, order: Order) -> tuple[ActorType, str]:
        if principal.can_on_restaurant(order.restaurant_id, "orders"):
            return A.RESTAURANT, principal.uid
        if principal.can(Permission.ORDERS_INTERVENE):
            return A.STAFF, principal.uid
        raise PermissionDenied("You do not have access to this restaurant's orders")

    async def accept(self, principal: Principal, order_id: str, prep_minutes: int) -> Order:
        if not 1 <= prep_minutes <= 180:
            raise ValidationFailed("Preparation time must be between 1 and 180 minutes")
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        now = utcnow()
        return await self.transition(
            order_id,
            S.RESTAURANT_ACCEPTED,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Accepted on behalf of restaurant",
            patch={"accepted_at": now, "prep_minutes": prep_minutes},
            metadata={"prep_minutes": prep_minutes},
        )

    async def reject(self, principal: Principal, order_id: str, reason: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        unpaid = order.awaiting_cash_payment  # pay on delivery: cancel, nothing to refund
        return await self.transition(
            order_id,
            S.CANCELLED if unpaid else S.REFUND_PENDING,
            actor_type=actor,
            actor_id=actor_id,
            reason=reason,
            patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
            metadata=None
            if unpaid
            else refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
            check=lambda o: _expect(o, {S.SUBMITTED_TO_RESTAURANT, S.RESTAURANT_ACCEPTED, S.PREPARING}),
        )

    async def mark_preparing(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        return await self.transition(
            order_id,
            S.PREPARING,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Updated by staff",
        )

    async def mark_ready(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        now = utcnow()
        if order.status == S.RIDER_ASSIGNED:
            # Rider already assigned: record readiness without changing the lifecycle status.
            await self.repos.orders.update(order_id, {"ready_at": now, "updated_at": now})
            if order.rider_id:
                await self.notifier.notify_user(
                    order.rider_id,
                    "Order ready",
                    f"Order {order.short_code} is ready",
                    {"order_id": order_id},
                )
            return order.model_copy(update={"ready_at": now})
        return await self.transition(
            order_id,
            S.READY_FOR_PICKUP,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Updated by staff",
            patch={"ready_at": now},
        )

    async def complete_pickup(self, principal: Principal, order_id: str, code: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        if order.fulfillment != Fulfillment.PICKUP:
            raise InvalidTransition("Only pickup orders are handed over at the counter")
        await self.verify_code(order_id, "pickup_code", code)
        now = utcnow()
        return await self.transition(
            order_id,
            S.COMPLETED,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Handover by staff",
            patch={"completed_at": now, "picked_up_at": now},
        )

    async def restaurant_timeout(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.status != S.SUBMITTED_TO_RESTAURANT:
            return
        unpaid = order.awaiting_cash_payment
        await self.transition(
            order.id,
            S.CANCELLED if unpaid else S.REFUND_PENDING,
            actor_type=A.SYSTEM,
            actor_id="scheduler",
            reason="Restaurant did not respond in time",
            patch={"cancelled_at": utcnow(), "cancellation_reason": "restaurant_timeout"},
            metadata=None
            if unpaid
            else refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
        )

    # ============================================================================ rider flows
    async def _rider_order(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        if order.rider_id != principal.uid:
            raise NotFound("Order not found")
        return order

    async def rider_pickup(self, principal: Principal, order_id: str) -> Order:
        await self._rider_order(principal, order_id)
        return await self.transition(
            order_id,
            S.PICKED_UP,
            actor_type=A.RIDER,
            actor_id=principal.uid,
            patch={"picked_up_at": utcnow()},
            check=lambda o: _rider_check(o, principal.uid),
        )

    async def rider_in_transit(self, principal: Principal, order_id: str) -> Order:
        await self._rider_order(principal, order_id)
        return await self.transition(
            order_id,
            S.IN_TRANSIT,
            actor_type=A.RIDER,
            actor_id=principal.uid,
            check=lambda o: _rider_check(o, principal.uid),
        )

    async def rider_deliver(
        self, principal: Principal, order_id: str, code: str, *, cash_collected: bool = False
    ) -> Order:
        order = await self._rider_order(principal, order_id)
        if order.leg_kind == "first_mile":
            raise InvalidTransition("Hand the package to the hub staff; they confirm it in the hub console")
        due = order.cash_to_collect_kobo
        if due and not cash_collected:
            raise ValidationFailed(
                f"Collect {format_naira(due)} in cash, then confirm delivery",
                details={"cash_to_collect_kobo": due},
            )
        _expect(order, {S.PICKED_UP, S.IN_TRANSIT})
        await self.verify_code(order_id, "delivery_code", code)
        now = utcnow()
        patch: dict[str, Any] = {"delivered_at": now}
        if due:
            cash_patch, cash_held = await self._cash_at_the_door(order, principal.uid, now)
            patch |= cash_patch
        order = await self.transition(
            order_id,
            S.DELIVERED,
            actor_type=A.RIDER,
            actor_id=principal.uid,
            patch=patch,
            check=lambda o: _rider_check(o, principal.uid),
        )
        if due:
            await self.repos.riders.update(principal.uid, {"cash_held_kobo": cash_held})
        return order

    async def _cash_at_the_door(
        self, order: Order, rider_id: str, now: datetime, *, recorded_by: str | None = None
    ) -> tuple[dict[str, Any], int]:
        """Put the cash the rider took at the door on the books, and return what the order then shows and the
        cash the rider now holds. Ledger first (idempotent): an order is never delivered without its cash being
        on the books, whoever marks it delivered."""
        cash_held = await self.payments.record_cash_collection(order, rider_id, recorded_by=recorded_by)
        patch: dict[str, Any] = {"cash_collected_at": now}
        if order.awaiting_cash_payment:
            patch["payment"] = to_doc(
                PaymentSummary(provider="cash", reference=order.payment.reference, status="paid", paid_at=now)
            )
        return patch, cash_held

    async def verify_code(
        self, order_id: str, field: Literal["delivery_code", "pickup_code"], code: str
    ) -> None:
        path = self.repos.codes_path(order_id)
        max_attempts = self.code_max_attempts

        async def fn(tx: Transaction) -> str:
            doc = await tx.get(path)
            if doc is None:
                return "missing"
            if doc.get("locked"):
                return "locked"
            if hmac.compare_digest(str(doc.get(field, "")), (code or "").strip()):
                tx.update(path, {"attempts": 0})
                return "ok"
            attempts = int(doc.get("attempts", 0)) + 1
            tx.update(path, {"attempts": attempts, "locked": attempts >= max_attempts})
            return "wrong"

        outcome = await self.repos.store.run_transaction(fn)
        if outcome == "ok":
            return
        if outcome == "locked":
            raise PermissionDenied("Too many incorrect codes. Please contact support.")
        if outcome == "missing":
            raise InvalidTransition("This order has no confirmation code")
        raise ValidationFailed("Incorrect code")

    async def complete_after_delivery(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.status != S.DELIVERED:
            return
        await self.transition(
            order.id, S.COMPLETED, actor_type=A.SYSTEM, actor_id="system", patch={"completed_at": utcnow()}
        )

    # ============================================================================ staff flows
    async def intervene(
        self,
        principal: Principal,
        order_id: str,
        to: OrderStatus,
        reason: str,
        refund_amount_kobo: int | None = None,
        liability: Literal["restaurant", "platform"] = "platform",
    ) -> Order:
        require(principal, Permission.ORDERS_INTERVENE)
        order = await self.get(order_id)
        metadata: dict[str, Any] = {"intervention": True}
        patch: dict[str, Any] = {}
        cash_held: int | None = None
        if to == S.REFUND_PENDING:
            amount = refund_amount_kobo or order.breakdown.total_kobo - order.refund_total_kobo
            if amount <= 0 or amount > order.breakdown.total_kobo - order.refund_total_kobo:
                raise ValidationFailed("Refund amount exceeds the refundable balance")
            stage = "after_completion" if order.completed_at else "before_completion"
            if stage == "before_completion":
                if refund_amount_kobo is not None and refund_amount_kobo != order.breakdown.total_kobo:
                    raise ValidationFailed(
                        "An order that is not completed yet is refunded in full: leave the amount empty",
                        details={"total_kobo": order.breakdown.total_kobo},
                    )
                amount = order.breakdown.total_kobo  # pre-completion refunds are always full
            metadata.update(refund_meta(amount, liability, stage, auto=False))
        if to == S.CANCELLED:
            patch = {"cancelled_at": utcnow(), "cancellation_reason": reason}
        if to == S.COMPLETED and order.status == S.DISPUTED:
            patch = {"completed_at": order.completed_at or utcnow()}
        if to == S.DELIVERED and order.cash_to_collect_kobo:
            # Delivered means the rider took the cash: it goes on the books as the rider's to hand in, the same
            # way as when the rider confirms the delivery, so no rider holds cash nobody is tracking.
            if not order.rider_id:
                raise InvalidTransition(
                    "This order has cash to collect and no rider. Assign a rider first, "
                    "or cancel the order if the customer did not pay."
                )
            _expect(order, {S.PICKED_UP, S.IN_TRANSIT})
            now = utcnow()
            cash_patch, cash_held = await self._cash_at_the_door(
                order, order.rider_id, now, recorded_by=principal.uid
            )
            patch = {"delivered_at": now, **cash_patch}
            metadata["cash_recorded_kobo"] = order.cash_to_collect_kobo
        updated = await self.transition(
            order_id,
            to,
            actor_type=A.STAFF,
            actor_id=principal.uid,
            reason=reason,
            patch=patch,
            metadata=metadata,
        )
        if cash_held is not None and order.rider_id:
            await self.repos.riders.update(order.rider_id, {"cash_held_kobo": cash_held})
        return updated

    async def unsettled_completed(self, older_than: timedelta = timedelta(minutes=5)) -> list[Order]:
        """Completed orders the ledger has not settled yet (their `order.completed` event was lost or failed)."""
        cutoff = utcnow() - older_than
        orders = await self.repos.orders.find(
            where=[
                ("status", "in", [S.COMPLETED.value, S.PARTIALLY_REFUNDED.value]),
                ("settled_at", "==", None),
            ],
            limit=500,
        )
        return [o for o in orders if o.completed_at and o.completed_at < cutoff]

    async def repair_lost_events(self, older_than: timedelta = timedelta(minutes=5)) -> dict[str, int]:
        """Order events are published after the order is saved; one that is lost would leave money stuck. The
        sweep job calls this (safe to repeat: the refund paths are idempotent):

        - an order waiting for a refund that nobody started gets its refund event again;
        - money paid for an order that is cancelled, with no refund on record, is refunded like any payment
          that arrives after a cancellation."""
        now = utcnow()
        cutoff = now - older_than
        waiting = await self.repos.orders.find(where=[("status", "==", S.REFUND_PENDING.value)], limit=500)
        waiting = [o for o in waiting if o.updated_at < cutoff]
        started = await self.payments.orders_with_refunds([o.id for o in waiting])
        restarted = 0
        for order in waiting:
            if order.id in started:
                continue
            events = await self.repos.order_events.find(
                where=[("order_id", "==", order.id)], order_by=[("at", "asc")]
            )
            event = next((e for e in reversed(events) if e.to_status == S.REFUND_PENDING), None)
            if event is None:
                continue
            await self.emitter.emit("order.refund_pending", _event_payload(order, event.from_status, event))
            restarted += 1
        cancelled = await self.repos.orders.find(
            where=[("status", "==", S.CANCELLED.value), ("created_at", ">=", now - REPAIR_WINDOW)],
            order_by=[("created_at", "desc")],
            limit=500,
        )
        held = await self.payments.unrefunded_payments([o.id for o in cancelled if o.updated_at < cutoff])
        for payment in held:
            await self.emitter.emit(
                "payment.orphaned",
                {
                    "order_id": payment["order_id"],
                    "payment_id": payment["id"],
                    **refund_meta(
                        payment["amount_kobo"] - payment["refunded_kobo"],
                        "platform",
                        "before_completion",
                        auto=True,
                    ),
                },
            )
        return {"refunds_restarted": restarted, "late_payments_refunded": len(held)}


def refund_meta(amount_kobo: int, liability: str, stage: str, *, auto: bool) -> dict[str, Any]:
    return {
        "refund_amount_kobo": amount_kobo,
        "refund_liability": liability,
        "refund_stage": stage,
        "refund_auto_approve": auto,
    }


def _expect(order: Order, allowed: set[OrderStatus]) -> None:
    if order.status not in allowed:
        raise InvalidTransition(f"Order is {order.status.value}")


def _event_payload(order: Order, previous: OrderStatus | None, event: OrderEvent) -> dict[str, Any]:
    return {
        "order_id": order.id,
        "from": previous.value if previous else None,
        "to": order.status.value,
        "event_id": event.id,
        "metadata": {**event.metadata, "reason": event.reason},
        "fulfillment": order.fulfillment.value,
        "actor_type": event.actor_type.value,
    }


def _frees_voucher(order: Order, to: OrderStatus) -> bool:
    """An order that comes to nothing gives its voucher back: cancelled (nothing was paid for it), or refunded
    in full before it was ever completed."""
    return to == S.CANCELLED or (to == S.REFUNDED and order.completed_at is None)


def _money_guard(order: Order, to: OrderStatus, updates: dict[str, Any]) -> None:
    """Keep order status consistent with money: an order holding customer money is refunded, never just
    cancelled; an unpaid pay-on-delivery order is cancelled (there is nothing to refund); and only cash orders
    reach the merchant without an online payment."""
    pay = updates.get("payment")
    provider = pay.get("provider") if isinstance(pay, dict) else order.payment.provider
    status = updates.get("payment.status") or (pay.get("status") if isinstance(pay, dict) else None)
    status = status or order.payment.status
    # Cash orders before the rider takes the money, and waybill rider jobs (paid through their waybill), hold none.
    unpaid_cash = provider in ("cash", "internal") and status != "paid"
    if to == S.CANCELLED and order.status not in (S.DRAFT, S.PENDING_PAYMENT) and not unpaid_cash:
        raise InvalidTransition("This order has been paid, so it must be refunded rather than cancelled")
    if to == S.REFUND_PENDING and unpaid_cash:
        raise InvalidTransition("Nothing has been paid for this order yet; cancel it instead")
    if to == S.SUBMITTED_TO_RESTAURANT and order.status == S.PENDING_PAYMENT and provider != "cash":
        raise InvalidTransition("Only pay-on-delivery orders go to the merchant before payment")
    if order.status == S.REFUND_PENDING and to == S.COMPLETED and order.completed_at is None:
        # Completing settles the order (the shop and the rider are credited) while its refund still pays out.
        raise InvalidTransition(
            "This order was never completed, so it cannot be marked completed while it is being refunded"
        )


def _flow_guard(order: Order, to: OrderStatus, actor: ActorType) -> None:
    """Transitions that exist only for interstate waybills and their internal rider jobs."""
    if order.status == S.PAID and to == S.IN_TRANSIT and not order.is_waybill:
        raise InvalidTransition("Only waybills go in transit straight from payment")
    if order.status == S.DRAFT and to == S.READY_FOR_PICKUP and not order.is_leg:
        raise InvalidTransition("Only waybill rider jobs skip payment")
    if to == S.DELIVERED and actor == A.SYSTEM and not order.is_waybill:
        raise InvalidTransition("Only waybills are marked delivered by the system")
    if to == S.SUBMITTED_TO_RESTAURANT and order.vertical in (Vertical.PARCEL, Vertical.WAYBILL):
        raise InvalidTransition("Packages are not sent to a merchant")


def _rider_check(order: Order, uid: str) -> None:
    if order.rider_id != uid:
        raise PermissionDenied("This delivery is assigned to another rider")


__all__ = ["ACTIVE_FULFILMENT", "OrderService", "refund_meta"]
