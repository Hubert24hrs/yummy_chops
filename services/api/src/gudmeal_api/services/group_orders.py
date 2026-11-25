"""Group orders with split bill (ADR-0016).

A group order is a shared cart at one restaurant or Beauty & Skin Care shop. Friends join with a 6-character code
and add their
own items; the host checks out ONE normal quote and order (host's address, voucher and Plus benefits). Then:

- split_mode "host": the host pays the order as usual; shares only show who owes the host what.
- split_mode "each": every member pays their own share (card or wallet; the host can pay the rest). The order
  moves to `paid` only when the shares add up to its total; if the unpaid-order expiry cancels it first, every
  paid share is refunded automatically. Shares come from `pricing.split_bill` and always add up to the total.

No money ever moves between users: each share is an ordinary payment to Yummy Chops for the order.
"""

from __future__ import annotations

import logging
import re
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

from pydantic import BaseModel, Field

from ..domain.growth import (
    GROUP_CODE_PATTERN,
    GroupLine,
    GroupMember,
    GroupOrder,
    GroupShare,
    SplitMode,
    new_code,
    normalise_code,
)
from ..domain.models import (
    CartLine,
    DeliveryAddress,
    Fulfillment,
    Order,
    OrderStatus,
    QuoteRequest,
    RestaurantStatus,
    Vertical,
)
from ..domain.money import format_naira
from ..domain.order_state import ActorType
from ..domain.pricing import price_line, split_bill
from ..errors import (
    Conflict,
    InvalidTransition,
    ItemUnavailable,
    NotFound,
    PermissionDenied,
    ValidationFailed,
)
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Principal
from .infra import Notifier
from .orders import OrderService
from .payments import PaymentService
from .quotes import QuoteService

logger = logging.getLogger(__name__)
S = OrderStatus
A = ActorType
MAX_LINES_PER_MEMBER = 20
MAX_ACTIVE_GROUPS_PER_HOST = 3
EDITABLE = ("open",)
BEFORE_ORDER = ("open", "locked")


def utcnow() -> datetime:
    return datetime.now(UTC)


class GroupCreateInput(BaseModel):
    restaurant_id: str = Field(max_length=80)
    fulfillment: Fulfillment = Fulfillment.DELIVERY
    delivery_address: DeliveryAddress | None = None
    split_mode: SplitMode = "each"


class GroupJoinInput(BaseModel):
    code: str = Field(min_length=6, max_length=12)


class GroupLinesInput(BaseModel):
    lines: list[CartLine] = Field(default_factory=list, max_length=MAX_LINES_PER_MEMBER)


class GroupReadyInput(BaseModel):
    ready: bool


class GroupSettingsInput(BaseModel):
    split_mode: SplitMode


class GroupCheckoutInput(BaseModel):
    voucher_code: str | None = Field(default=None, max_length=40)
    contact_phone: str | None = Field(default=None, max_length=20)
    channel: Literal["app", "web"] = "app"


class GroupPayInput(BaseModel):
    provider: Literal["wallet", "paystack", "flutterwave", "local_sandbox"] | None = None
    cover_rest: bool = False  # host only: pay every share that is still unpaid


class GroupOrderService:
    def __init__(
        self,
        repos: Repositories,
        quotes: QuoteService,
        orders: OrderService,
        payments: PaymentService,
        *,
        notifier: Notifier,
        unpaid_order_ttl_seconds: int,
    ) -> None:
        self.repos = repos
        self.quotes = quotes
        self.orders = orders
        self.payments = payments
        self.notifier = notifier
        self.pay_window = timedelta(seconds=unpaid_order_ttl_seconds)

    # ------------------------------------------------------------------------------------------- helpers
    def _path(self, group_id: str) -> str:
        return self.repos.group_orders.path(group_id)

    async def _get(self, group_id: str) -> GroupOrder:
        g = await self.repos.group_orders.get(group_id)
        if g is None:
            raise NotFound("Group order not found")
        return g

    async def _for_member(self, principal: Principal, group_id: str) -> GroupOrder:
        g = await self._get(group_id)
        if g.member(principal.uid) is None:
            raise NotFound("Group order not found")  # same answer as a wrong id: no probing
        return g

    @staticmethod
    def _host_only(g: GroupOrder, principal: Principal) -> None:
        if principal.uid != g.host_uid:
            raise PermissionDenied("Only the host can do that")

    @staticmethod
    def _status(g: GroupOrder, now: datetime) -> str:
        return "expired" if g.status in BEFORE_ORDER and g.expires_at <= now else g.status

    def _expect(self, g: GroupOrder, allowed: tuple[str, ...]) -> None:
        status = self._status(g, utcnow())
        if status in allowed:
            return
        messages = {
            "locked": "The host has locked the cart",
            "ordered": "The order has already been placed",
            "cancelled": "This group order was cancelled",
            "expired": "This group order has expired",
            "open": "The host hasn't placed the order yet",
        }
        raise InvalidTransition(messages.get(status, f"This group order is {status}"))

    async def _update(self, g: GroupOrder, fn: Any) -> GroupOrder:
        """Read-modify-write the group in a transaction; `fn(group)` returns the changed group or raises."""

        async def tx_fn(tx: Transaction) -> GroupOrder:
            doc = await tx.get(self._path(g.id))
            if doc is None:
                raise NotFound("Group order not found")
            current = GroupOrder.model_validate(doc)
            changed = fn(current)
            changed = changed.model_copy(update={"updated_at": utcnow()})
            tx.set(self._path(g.id), to_doc(changed))
            return changed

        return await self.repos.store.run_transaction(tx_fn)

    async def _menu_of(self, g: GroupOrder) -> str:
        """Whose menu the group's shop sells: a branch sells its main branch's (ADR-0028)."""
        shop = await self.repos.restaurants.get(g.restaurant_id)
        return shop.menu_id if shop else g.restaurant_id

    async def _price_lines(self, g: GroupOrder) -> tuple[list[dict[str, Any]], dict[str, int]]:
        """Live menu prices of everyone's lines (estimates: the checkout quote is the price)."""
        menu = await self._menu_of(g)
        items = await self.repos.items.get_many([ln.item_id for ln in g.lines])
        groups = await self.repos.option_groups.get_many(
            sorted({gid for i in items.values() for gid in i.option_group_ids})
        )
        names = {m.uid: m.name for m in g.members}
        per_member: dict[str, int] = {}
        out: list[dict[str, Any]] = []
        for ln in g.lines:
            item = items.get(ln.item_id)
            problem = None
            total = 0
            labels: list[str] = []
            try:
                if item is None or item.restaurant_id != menu:
                    raise ItemUnavailable("No longer on the menu")
                priced = price_line(ln, item, groups)
                total, labels = priced.line_total_kobo, priced.selection_labels
            except (ItemUnavailable, ValidationFailed) as exc:
                problem = exc.message
            per_member[ln.member_uid] = per_member.get(ln.member_uid, 0) + total
            out.append(
                {
                    "id": ln.id,
                    "member_uid": ln.member_uid,
                    "member": names.get(ln.member_uid, "Guest"),
                    "item_id": ln.item_id,
                    "name": item.name if item else "Unavailable item",
                    "quantity": ln.quantity,
                    "selections": [s.model_dump() for s in ln.selections],
                    "options": labels,
                    "notes": ln.notes,
                    "line_total_kobo": total,
                    "problem": problem,
                }
            )
        return out, per_member

    async def view(self, g: GroupOrder, viewer: str) -> dict[str, Any]:
        cfg = await self.repos.get_growth_config()
        now = utcnow()
        lines, per_member = await self._price_lines(g)
        order = await self.repos.orders.get(g.order_id) if g.order_id else None
        awaiting = order is not None and order.status in (S.DRAFT, S.PENDING_PAYMENT)
        paid = sum(s.amount_kobo for s in g.shares if s.status == "paid")
        mine = g.share(viewer)
        return {
            "id": g.id,
            "code": g.code,
            "status": self._status(g, now),
            "split_mode": g.split_mode,
            "is_host": viewer == g.host_uid,
            "host_name": g.host_name,
            "restaurant": {"id": g.restaurant_id, "name": g.restaurant_name},
            "vertical": g.vertical,
            "fulfillment": g.fulfillment.value,
            "delivery_area": (g.delivery_address.area or g.delivery_address.label or g.delivery_address.line1)
            if g.delivery_address
            else None,
            "members": [
                {
                    "uid": m.uid,
                    "name": m.name,
                    "is_host": m.uid == g.host_uid,
                    "me": m.uid == viewer,
                    "ready": m.ready,
                    "items": sum(ln.quantity for ln in g.lines if ln.member_uid == m.uid),
                    "items_kobo": per_member.get(m.uid, 0),
                }
                for m in g.members
            ],
            "max_members": cfg.group_max_members,
            "lines": lines,
            "estimated_items_kobo": sum(per_member.values()),
            "expires_at": g.expires_at,
            "order": None
            if order is None
            else {
                "id": order.id,
                "short_code": order.short_code,
                "status": order.status.value,
                "total_kobo": order.breakdown.total_kobo,
                "breakdown": order.breakdown.model_dump(),
            },
            "total_kobo": g.total_kobo,
            "shares": [
                {
                    "uid": s.uid,
                    "name": s.name,
                    "me": s.uid == viewer,
                    "items_kobo": s.items_kobo,
                    "amount_kobo": s.amount_kobo,
                    "status": s.status,
                    "paid_by_host": s.status == "paid" and s.paid_by == g.host_uid and s.uid != g.host_uid,
                }
                for s in g.shares
            ],
            "my_share": None
            if mine is None
            else {"amount_kobo": mine.amount_kobo, "items_kobo": mine.items_kobo, "status": mine.status},
            "paid_kobo": paid,
            "remaining_kobo": max(0, g.total_kobo - paid) if g.split_mode == "each" else 0,
            "pay_by": order.created_at + self.pay_window if order is not None and awaiting else None,
            "can_pay": g.split_mode == "each" and awaiting and mine is not None and mine.status == "unpaid",
            "can_cover_rest": g.split_mode == "each"
            and awaiting
            and viewer == g.host_uid
            and paid < g.total_kobo,
            "cancel_reason": g.cancel_reason,
        }

    # ------------------------------------------------------------------------------------------- reads
    async def get(self, principal: Principal, group_id: str) -> dict[str, Any]:
        return await self.view(await self._for_member(principal, group_id), principal.uid)

    async def mine(self, principal: Principal) -> list[dict[str, Any]]:
        """Group orders I'm in that are still open, waiting for payment, or placed in the last day."""
        found = await self.repos.group_orders.find(
            where=[("member_uids", "array_contains", principal.uid)], limit=50
        )
        now = utcnow()
        recent = [
            g
            for g in found
            if self._status(g, now) in BEFORE_ORDER
            or (g.status == "ordered" and now - g.updated_at < timedelta(days=1))
        ]
        recent.sort(key=lambda g: g.updated_at, reverse=True)
        return [await self.view(g, principal.uid) for g in recent[:10]]

    # ------------------------------------------------------------------------------------------- the cart
    async def create(self, principal: Principal, data: GroupCreateInput) -> dict[str, Any]:
        cfg = await self.repos.get_growth_config()
        if not cfg.group_orders_enabled:
            raise ValidationFailed("Group orders are not available right now")
        restaurant = await self.repos.restaurants.get(data.restaurant_id)
        if restaurant is None or restaurant.status != RestaurantStatus.ACTIVE:
            raise NotFound("Store not found")
        if restaurant.vertical not in (Vertical.FOOD, Vertical.BEAUTY):
            raise ValidationFailed("Group orders are for restaurants and Beauty & Skin Care shops")
        if data.fulfillment == Fulfillment.DELIVERY and data.delivery_address is None:
            raise ValidationFailed("Add the delivery address for the group order")
        mine = await self.repos.group_orders.find(where=[("host_uid", "==", principal.uid)], limit=50)
        now = utcnow()
        if sum(1 for g in mine if self._status(g, now) in BEFORE_ORDER) >= MAX_ACTIVE_GROUPS_PER_HOST:
            raise ValidationFailed("You already have open group orders; finish or cancel one first")
        name = (principal.name or "Host").split(" ")[0][:40]
        for _ in range(6):
            g = GroupOrder(
                id=uuid.uuid4().hex,
                code=new_code(6),
                host_uid=principal.uid,
                host_name=name,
                restaurant_id=restaurant.id,
                restaurant_name=restaurant.name,
                vertical=restaurant.vertical.value,
                fulfillment=data.fulfillment,
                delivery_address=data.delivery_address if data.fulfillment == Fulfillment.DELIVERY else None,
                split_mode=data.split_mode,
                members=[GroupMember(uid=principal.uid, name=name, joined_at=now)],
                member_uids=[principal.uid],
                created_at=now,
                updated_at=now,
                expires_at=now + timedelta(hours=cfg.group_open_hours),
            )

            async def fn(tx: Transaction, g: GroupOrder = g) -> bool:
                if await tx.get(f"group_codes/{g.code}") is not None:
                    return False
                tx.create(f"group_codes/{g.code}", {"code": g.code, "group_id": g.id, "created_at": now})
                tx.create(self._path(g.id), to_doc(g))
                return True

            if await self.repos.store.run_transaction(fn):
                return await self.view(g, principal.uid)
        raise Conflict("Could not create a group code, please try again")

    async def join(self, principal: Principal, raw_code: str) -> dict[str, Any]:
        code = normalise_code(raw_code)
        if not re.match(GROUP_CODE_PATTERN, code):
            raise ValidationFailed("Group codes are 6 letters and numbers")
        ref = await self.repos.store.get(f"group_codes/{code}")
        if ref is None:
            raise NotFound("We couldn't find a group order with that code")
        g = await self._get(str(ref["group_id"]))
        if g.member(principal.uid) is not None:
            return await self.view(g, principal.uid)
        self._expect(g, EDITABLE)
        cfg = await self.repos.get_growth_config()
        name = (principal.name or "Guest").split(" ")[0][:40]

        def add(current: GroupOrder) -> GroupOrder:
            if current.member(principal.uid) is not None:
                return current
            self._expect(current, EDITABLE)
            if len(current.members) >= cfg.group_max_members:
                raise ValidationFailed(f"This group order is full ({cfg.group_max_members} people)")
            member = GroupMember(uid=principal.uid, name=name, joined_at=utcnow())
            return current.model_copy(
                update={
                    "members": [*current.members, member],
                    "member_uids": [*current.member_uids, principal.uid],
                }
            )

        g = await self._update(g, add)
        await self.notifier.notify_user(
            g.host_uid,
            "Someone joined your group order",
            f"{name} joined your {g.restaurant_name} order.",
            {"screen": "group", "group_order_id": g.id},
        )
        return await self.view(g, principal.uid)

    async def set_lines(self, principal: Principal, group_id: str, lines: list[CartLine]) -> dict[str, Any]:
        g = await self._for_member(principal, group_id)
        self._expect(g, EDITABLE)
        items = await self.repos.items.get_many([ln.item_id for ln in lines])
        option_groups = await self.repos.option_groups.get_many(
            sorted({gid for i in items.values() for gid in i.option_group_ids})
        )
        menu = await self._menu_of(g)
        for line in lines:  # reject what the quote would reject, while the customer is still choosing
            item = items.get(line.item_id)
            if item is None or item.restaurant_id != menu:
                raise ItemUnavailable(
                    "That item is not on this store's menu", details={"item_id": line.item_id}
                )
            price_line(line, item, option_groups)
        new_lines = [
            GroupLine(id=uuid.uuid4().hex[:10], member_uid=principal.uid, **line.model_dump())
            for line in lines
        ]

        def replace(current: GroupOrder) -> GroupOrder:
            self._expect(current, EDITABLE)
            others = [ln for ln in current.lines if ln.member_uid != principal.uid]
            if len(others) + len(new_lines) > 50:
                raise ValidationFailed("A group order can have at most 50 items")
            return current.model_copy(update={"lines": [*others, *new_lines]})

        return await self.view(await self._update(g, replace), principal.uid)

    async def set_ready(self, principal: Principal, group_id: str, ready: bool) -> dict[str, Any]:
        g = await self._for_member(principal, group_id)

        def mark(current: GroupOrder) -> GroupOrder:
            members = [
                m.model_copy(update={"ready": ready}) if m.uid == principal.uid else m
                for m in current.members
            ]
            return current.model_copy(update={"members": members})

        return await self.view(await self._update(g, mark), principal.uid)

    async def settings(self, principal: Principal, group_id: str, data: GroupSettingsInput) -> dict[str, Any]:
        g = await self._for_member(principal, group_id)
        self._host_only(g, principal)
        self._expect(g, BEFORE_ORDER)
        g = await self._update(g, lambda cur: cur.model_copy(update={"split_mode": data.split_mode}))
        return await self.view(g, principal.uid)

    async def set_locked(self, principal: Principal, group_id: str, locked: bool) -> dict[str, Any]:
        g = await self._for_member(principal, group_id)
        self._host_only(g, principal)
        self._expect(g, BEFORE_ORDER)
        g = await self._update(
            g, lambda cur: cur.model_copy(update={"status": "locked" if locked else "open"})
        )
        return await self.view(g, principal.uid)

    async def remove_member(self, principal: Principal, group_id: str, uid: str) -> dict[str, Any]:
        """The host removes someone, or a member leaves (with their items). The host can't leave: they cancel."""
        g = await self._for_member(principal, group_id)
        if uid != principal.uid:
            self._host_only(g, principal)
        if uid == g.host_uid:
            raise ValidationFailed("The host can't leave; cancel the group order instead")
        self._expect(g, BEFORE_ORDER)

        def drop(current: GroupOrder) -> GroupOrder:
            return current.model_copy(
                update={
                    "members": [m for m in current.members if m.uid != uid],
                    "member_uids": [u for u in current.member_uids if u != uid],
                    "lines": [ln for ln in current.lines if ln.member_uid != uid],
                }
            )

        g = await self._update(g, drop)
        if uid == principal.uid:
            return {"left": True}
        return await self.view(g, principal.uid)

    # ------------------------------------------------------------------------------------------- checkout
    async def checkout(self, principal: Principal, group_id: str, data: GroupCheckoutInput) -> dict[str, Any]:
        """Host only: one quote and one order for everyone's items, then the shares of the bill."""
        g = await self._for_member(principal, group_id)
        self._host_only(g, principal)
        if g.status == "ordered":
            return await self.view(g, principal.uid)
        self._expect(g, BEFORE_ORDER)
        if not g.lines:
            raise ValidationFailed("Add some items before placing the group order")
        req = QuoteRequest(
            restaurant_id=g.restaurant_id,
            lines=[
                CartLine(item_id=ln.item_id, quantity=ln.quantity, selections=ln.selections, notes=ln.notes)
                for ln in g.lines
            ],
            fulfillment=g.fulfillment,
            delivery_address=g.delivery_address,
            voucher_code=data.voucher_code,
        )
        quote = await self.quotes.create_quote(principal, req)
        order = await self.orders.create_from_quote(
            principal, quote.id, channel=data.channel, contact_phone=data.contact_phone, group_order_id=g.id
        )
        items: dict[str, int] = {}
        for ln, priced in zip(g.lines, quote.lines, strict=True):
            items[ln.member_uid] = items.get(ln.member_uid, 0) + priced.line_total_kobo
        amounts = split_bill(items, order.breakdown.total_kobo)
        names = {m.uid: m.name for m in g.members}
        shares = [
            GroupShare(uid=uid, name=names.get(uid, "Guest"), items_kobo=items[uid], amount_kobo=amounts[uid])
            for uid in items
        ]
        if g.split_mode == "each":
            order = await self.orders.transition(
                order.id, S.PENDING_PAYMENT, actor_type=A.CUSTOMER, actor_id=principal.uid
            )

        def place(current: GroupOrder) -> GroupOrder:
            if current.order_id and current.order_id != order.id:
                raise Conflict("This group order was placed already")
            return current.model_copy(
                update={
                    "status": "ordered",
                    "order_id": order.id,
                    "total_kobo": order.breakdown.total_kobo,
                    "shares": shares,
                    "split_mode": g.split_mode,
                }
            )

        g = await self._update(g, place)
        pay_by = (order.created_at + self.pay_window + timedelta(hours=1)).strftime("%H:%M")
        for share in shares:
            if share.uid == g.host_uid:
                continue
            if g.split_mode == "each":
                title = "Pay your share"
                body = (
                    f"{g.host_name} placed the {g.restaurant_name} order. Your share is "
                    f"{format_naira(share.amount_kobo)}; please pay by {pay_by}."
                )
            else:
                title = "Group order placed"
                body = f"{g.host_name} is paying for the {g.restaurant_name} order (your part: {format_naira(share.amount_kobo)})."
            await self.notifier.notify_user(
                share.uid, title, body, {"screen": "group", "group_order_id": g.id}
            )
        return await self.view(g, principal.uid)

    async def pay(
        self, principal: Principal, group_id: str, data: GroupPayInput, idempotency_key: str
    ) -> dict[str, Any]:
        """Pay my share (or, for the host, everything still unpaid) by card or from the wallet."""
        g = await self._for_member(principal, group_id)
        if g.split_mode != "each":
            raise InvalidTransition(f"{g.host_name} is paying for this group order")
        if g.status != "ordered" or not g.order_id:
            raise InvalidTransition("The host hasn't placed the order yet")
        order = await self.orders.get(g.order_id)
        if order.status != S.PENDING_PAYMENT:
            raise InvalidTransition("This group order is no longer waiting for payment")
        if data.cover_rest:
            self._host_only(g, principal)
            amount = sum(s.amount_kobo for s in g.shares if s.status == "unpaid")
            key = f"rest:{idempotency_key}"
        else:
            share = g.share(principal.uid)
            if share is None:
                raise ValidationFailed("You don't have any items in this order")
            if share.status == "paid":
                raise ValidationFailed("Your share is already paid")
            amount, key = share.amount_kobo, f"own:{idempotency_key}"
        if amount <= 0:
            raise ValidationFailed("Everything is already paid")
        if data.provider == "wallet":
            payment = await self.payments.pay_share_with_wallet(principal.uid, order, amount, key)
        else:
            payment = await self.payments.start_share_checkout(principal, order, amount, data.provider, key)
        return {"payment": payment, "group": await self.view(await self._get(g.id), principal.uid)}

    async def cancel(self, principal: Principal, group_id: str) -> dict[str, Any]:
        """Host only: cancel before ordering, or while the order still waits for everyone's payment."""
        g = await self._for_member(principal, group_id)
        self._host_only(g, principal)
        if g.status in BEFORE_ORDER:
            g = await self._update(
                g,
                lambda cur: cur.model_copy(
                    update={"status": "cancelled", "cancel_reason": "Cancelled by the host"}
                ),
            )
            for m in g.members:
                if m.uid != g.host_uid:
                    await self.notifier.notify_user(
                        m.uid,
                        "Group order cancelled",
                        f"{g.host_name} cancelled the {g.restaurant_name} order.",
                        {"screen": "group", "group_order_id": g.id},
                    )
            return await self.view(g, principal.uid)
        if g.status == "ordered" and g.order_id:
            order = await self.orders.get(g.order_id)
            if order.status in (S.DRAFT, S.PENDING_PAYMENT):
                await self.orders.transition(
                    order.id,
                    S.CANCELLED,
                    actor_type=A.CUSTOMER,
                    actor_id=principal.uid,
                    reason="Group order cancelled by the host",
                    patch={"cancelled_at": utcnow(), "cancellation_reason": "group_cancelled"},
                )  # → order.cancelled → every paid share is refunded
                return await self.view(await self._get(g.id), principal.uid)
            raise InvalidTransition("The order is already with the store; cancel it from the order page")
        raise InvalidTransition(f"This group order is {g.status}")

    # ------------------------------------------------------------------------------------------- money events
    async def on_share_paid(self, payload: dict[str, Any]) -> None:
        """A share payment was captured: mark what it covers; refund anything it doesn't need to cover."""
        order_id = str(payload["order_id"])
        order = await self.repos.orders.get(order_id)
        if order is None or not order.group_order_id:
            return
        payer = str(payload["customer_id"])
        amount = int(payload["amount_kobo"])
        payment_id = str(payload["payment_id"])
        now = utcnow()

        async def fn(tx: Transaction) -> tuple[int, bool, GroupOrder | None]:
            doc = await tx.get(self._path(order.group_order_id or ""))
            order_doc = await tx.get(f"orders/{order_id}")
            if doc is None:
                return amount, False, None
            g = GroupOrder.model_validate(doc)
            live = order_doc is not None and order_doc.get("status") == S.PENDING_PAYMENT.value
            if g.order_id != order_id or g.status != "ordered" or not live:
                return amount, False, g  # cancelled, expired or replaced: give the money back
            shares = [s.model_copy() for s in g.shares]
            covered = [s.amount_kobo for s in shares if s.payment_reference == payload.get("reference")]
            if covered:
                # Replayed event: nothing new to apply. What the payment did not cover is still handed back (the
                # refund is made once, whatever happened to the first delivery of the event after it was applied).
                return amount - sum(covered), all(s.status == "paid" for s in shares), g
            left = amount

            def settle(share: GroupShare) -> None:
                nonlocal left
                share.status = "paid"
                share.paid_by = payer
                share.payment_reference = str(payload.get("reference") or payment_id)
                share.paid_at = now
                left -= share.amount_kobo

            own = next((s for s in shares if s.uid == payer), None)
            if own is not None and own.status == "unpaid" and own.amount_kobo <= left:
                settle(own)
            if payer == g.host_uid:  # the host paying the rest covers whatever is still unpaid
                for share in shares:
                    if share.status == "unpaid" and share.amount_kobo <= left:
                        settle(share)
            all_paid = all(s.status == "paid" for s in shares)
            updated = g.model_copy(update={"shares": shares, "updated_at": now})
            tx.set(self._path(g.id), to_doc(updated))
            return left, all_paid, updated

        leftover, all_paid, g = await self.repos.store.run_transaction(fn)
        if leftover > 0:
            await self._refund_payment(
                order_id,
                payment_id,
                leftover,
                key=f"group:{order.group_order_id}:excess:{payment_id}",
                reason="Group order share was already paid or the order was called off",
            )
        if all_paid and g is not None:
            await self.orders.on_payment_succeeded(
                {
                    "order_id": order_id,
                    "provider": "group",
                    "reference": f"GROUP-{g.code}",
                    "amount_kobo": order.breakdown.total_kobo,
                    "paid_at": now.isoformat(),
                }
            )
            for m in g.members:
                if g.share(m.uid) is not None:
                    await self.notifier.notify_user(
                        m.uid,
                        "Everyone has paid",
                        f"Your group order is on its way to {g.restaurant_name}.",
                        {"screen": "group", "group_order_id": g.id},
                    )

    async def on_order_called_off(self, payload: dict[str, Any]) -> None:
        """The group's order was cancelled before everyone paid: give every paid share back in full."""
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or not order.group_order_id:
            return
        g = await self.repos.group_orders.get(order.group_order_id)
        if g is None or g.order_id != order.id:
            return
        reason = (payload.get("metadata") or {}).get("reason") or "The order was cancelled"
        if g.status != "cancelled":
            g = await self._update(
                g, lambda cur: cur.model_copy(update={"status": "cancelled", "cancel_reason": str(reason)})
            )
        for p in await self.payments.group_share_payments(order.id):
            left = p["amount_kobo"] - p["refunded_kobo"]
            if left > 0:
                await self._refund_payment(
                    order.id,
                    p["id"],
                    left,
                    key=f"group:{g.id}:cancelled:{p['id']}",
                    reason="Group order cancelled before everyone paid",
                )
        for share in g.shares:
            note = (
                f"Your {format_naira(share.amount_kobo)} is being refunded."
                if share.status == "paid"
                else "Nothing was charged to you."
            )
            await self.notifier.notify_user(
                share.paid_by or share.uid,
                "Group order cancelled",
                f"The {g.restaurant_name} group order was cancelled. {note}",
                {"screen": "group", "group_order_id": g.id},
            )

    async def _refund_payment(
        self, order_id: str, payment_id: str, amount: int, *, key: str, reason: str
    ) -> None:
        try:
            await self.payments.create_refund(
                order_id=order_id,
                amount_kobo=amount,
                reason=reason,
                liability="platform",
                stage="before_completion",
                requested_by="system",
                idempotency_key=key,
                auto_approve=True,
                payment_id=payment_id,
            )
        except ValidationFailed as exc:  # already refunded by another path (cancellation vs late payment)
            logger.warning("group share refund skipped: %s", exc.message)


def is_group_order(order: Order) -> bool:
    return order.group_order_id is not None


__all__ = [
    "GroupCheckoutInput",
    "GroupCreateInput",
    "GroupJoinInput",
    "GroupLinesInput",
    "GroupOrderService",
    "GroupPayInput",
    "GroupReadyInput",
    "GroupSettingsInput",
]
