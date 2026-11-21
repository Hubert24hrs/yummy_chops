"""Yummy Chops Plus (ADR-0016): join by card or wallet, wallet auto-renewal, cancellation, member savings.

Benefits are applied by the pricing engine when a member's quote is priced (`QuoteService`); this service only
manages who is a member and until when. A membership period is created per verified payment (idempotent), so a
replayed webhook or event never extends a membership twice.
"""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from ..domain.growth import Membership, PlusConfig, membership_active
from ..domain.models import MERCHANT_VERTICALS, OrderStatus
from ..domain.money import format_naira
from ..domain.pricing import vat_inclusive_split
from ..errors import NotFound, ValidationFailed
from ..ledger.db import Database
from ..ledger.ledger import LedgerService
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, require
from .infra import Notifier
from .payments import PaymentService

logger = logging.getLogger(__name__)
LAPSE_GRACE = timedelta(days=1)  # after this, a lapsed membership is not charged again automatically
RENEW_EARLY = timedelta(days=7)  # members can pay for the next period in the last week of the current one


def utcnow() -> datetime:
    return datetime.now(UTC)


def lagos_day(dt: datetime) -> str:
    return (dt + timedelta(hours=1)).strftime("%a %d %b %Y")


SERVICE_WORDS = {
    "food": "Food",
    "beauty": "Beauty",
    "grocery": "Groceries",
    "pharmacy": "Pharmacy",
    "market": "Foodstuff",
}


def services_text(verticals: list[str]) -> str:
    """How a benefit names the services it covers: "Food and Beauty"; every shop service reads
    "restaurant and shop"."""
    if {v.value for v in MERCHANT_VERTICALS} <= set(verticals):
        return "restaurant and shop"
    names = [SERVICE_WORDS.get(v, v.capitalize()) for v in verticals]
    if not names:
        return "eligible"
    return names[0] if len(names) == 1 else f"{', '.join(names[:-1])} and {names[-1]}"


def benefits_text(plan: PlusConfig) -> list[str]:
    services = services_text(plan.verticals)
    out = []
    if plan.free_delivery_min_subtotal_kobo:
        out.append(
            f"Free delivery on {services} orders of {format_naira(plan.free_delivery_min_subtotal_kobo)} or more"
        )
    else:
        out.append(f"Free delivery on {services} orders")
    if plan.service_fee_discount_bps:
        pct = plan.service_fee_discount_bps / 100
        out.append(f"{pct:g}% off the service fee on {services} orders")
    if plan.points_multiplier > 1:
        out.append(f"{plan.points_multiplier}× Yummy points on every completed order")
    return out


class MembershipService:
    def __init__(
        self,
        repos: Repositories,
        payments: PaymentService,
        *,
        db: Database,
        ledger: LedgerService,
        notifier: Notifier,
    ) -> None:
        self.repos = repos
        self.payments = payments
        self.db = db
        self.ledger = ledger
        self.notifier = notifier

    # ------------------------------------------------------------------------------------------- reads
    async def get(self, uid: str) -> Membership | None:
        return await self.repos.memberships.get(uid)

    async def is_member(self, uid: str, now: datetime | None = None) -> bool:
        return membership_active(await self.get(uid), now or utcnow())

    async def plan_view(self) -> dict[str, Any]:
        cfg = await self.repos.get_pricing_config()
        plan = cfg.plus
        _, vat = vat_inclusive_split(plan.price_kobo, cfg.vat_bps)
        return {
            "enabled": plan.enabled,
            "price_kobo": plan.price_kobo,
            "vat_kobo": vat,
            "period_days": plan.period_days,
            "free_delivery_min_subtotal_kobo": plan.free_delivery_min_subtotal_kobo,
            "service_fee_discount_bps": plan.service_fee_discount_bps,
            "points_multiplier": plan.points_multiplier,
            "verticals": plan.verticals,
            "benefits": benefits_text(plan),
        }

    async def overview(self, principal: Principal) -> dict[str, Any]:
        now = utcnow()
        m = await self.get(principal.uid)
        active = membership_active(m, now)
        membership = None
        if m is not None and m.periods > 0:
            membership = {
                "status": "active" if active else "expired",
                "member_since": m.member_since,
                "paid_through": m.paid_through,
                "paid_through_text": lagos_day(m.paid_through),
                "days_left": max(0, (m.paid_through - now).days) if active else 0,
                "auto_renew": m.auto_renew,
                "can_renew": not active or m.paid_through <= now + RENEW_EARLY,
                "periods": m.periods,
                "savings_kobo": await self._savings(principal.uid, m.member_since),
            }
        return {"plan": await self.plan_view(), "member": active, "membership": membership}

    async def _savings(self, uid: str, since: datetime) -> int:
        orders = await self.repos.orders.find(where=[("customer_id", "==", uid)], limit=500)
        done = {OrderStatus.COMPLETED, OrderStatus.PARTIALLY_REFUNDED}
        return sum(
            o.breakdown.plus_savings_kobo for o in orders if o.status in done and o.created_at >= since
        )

    # ------------------------------------------------------------------------------------------- joining
    async def subscribe(
        self, principal: Principal, provider: str | None, idempotency_key: str, *, auto_renew: bool = True
    ) -> dict[str, Any]:
        """Pay for a membership period. Wallet payments start it at once; card payments when verified."""
        cfg = await self.repos.get_pricing_config()
        plan = cfg.plus
        if not plan.enabled:
            raise ValidationFailed("Yummy Chops Plus is not available right now")
        now = utcnow()
        m = await self.get(principal.uid)
        if m is not None and m.paid_through > now + RENEW_EARLY:
            raise ValidationFailed(
                f"You're already a Yummy Chops Plus member until {lagos_day(m.paid_through)}"
            )
        await self._remember_choice(principal.uid, auto_renew, now)
        if provider == "wallet":
            _, vat = vat_inclusive_split(plan.price_kobo, cfg.vat_bps)
            payment = await self.payments.pay_plus_with_wallet(
                principal.uid, plan.price_kobo, vat, idempotency_key
            )
        else:
            payment = await self.payments.start_plus_checkout(
                principal, plan.price_kobo, provider, idempotency_key
            )
        return {"payment": payment, **(await self.overview(principal))}

    async def _remember_choice(self, uid: str, auto_renew: bool, now: datetime) -> None:
        """Record the customer's auto-renew choice before payment (the membership starts when paid)."""

        async def fn(tx: Transaction) -> None:
            path = self.repos.memberships.path(uid)
            doc = await tx.get(path)
            if doc is None:
                fresh = Membership(
                    uid=uid, member_since=now, paid_through=now, auto_renew=auto_renew, updated_at=now
                )
                tx.create(path, to_doc(fresh))
            else:
                tx.update(path, {"auto_renew": auto_renew, "cancelled_at": None, "updated_at": now})

        await self.repos.store.run_transaction(fn)

    async def on_paid(self, payload: dict[str, Any]) -> None:
        await self.activate(
            uid=str(payload["customer_id"]),
            payment_id=str(payload["payment_id"]),
            reference=str(payload.get("reference") or ""),
            amount_kobo=int(payload["amount_kobo"]),
            renewal=bool(payload.get("renewal")),
        )

    async def activate(
        self, *, uid: str, payment_id: str, reference: str, amount_kobo: int, renewal: bool = False
    ) -> Membership | None:
        """Add one period per verified payment, from now or from the end of the current period."""
        cfg = await self.repos.get_pricing_config()
        days = cfg.plus.period_days
        now = utcnow()

        async def fn(tx: Transaction) -> Membership | None:
            period_path = f"{self.repos.memberships.path(uid)}/periods/{payment_id}"
            if await tx.get(period_path) is not None:
                return None  # this payment already added its period
            doc = await tx.get(self.repos.memberships.path(uid))
            m = Membership.model_validate(doc) if doc else None
            start = m.paid_through if m is not None and m.paid_through > now else now
            end = start + timedelta(days=days)
            n = (m.periods if m else 0) + 1
            tx.create(
                period_path,
                {
                    "n": n,
                    "starts_at": start,
                    "ends_at": end,
                    "payment_id": payment_id,
                    "reference": reference,
                    "amount_kobo": amount_kobo,
                    "renewal": renewal,
                    "at": now,
                },
            )
            updated = Membership(
                uid=uid,
                member_since=m.member_since if m is not None and m.periods > 0 else now,
                paid_through=end,
                periods=n,
                auto_renew=m.auto_renew if m is not None else True,
                last_payment_reference=reference,
                last_price_kobo=amount_kobo,
                reminder_for=None,
                cancelled_at=m.cancelled_at if m is not None else None,
                updated_at=now,
            )
            tx.set(self.repos.memberships.path(uid), to_doc(updated))
            return updated

        updated = await self.repos.store.run_transaction(fn)
        if updated is not None:
            if updated.periods == 1:
                await self.notifier.notify_user(
                    uid,
                    "Welcome to Yummy Chops Plus",
                    f"Your benefits are on until {lagos_day(updated.paid_through)}.",
                    {"screen": "plus"},
                )
            else:
                await self.notifier.notify_user(
                    uid,
                    "Yummy Chops Plus renewed",
                    f"Your membership now runs until {lagos_day(updated.paid_through)}.",
                    {"screen": "plus"},
                )
        return updated

    async def set_auto_renew(self, principal: Principal, auto_renew: bool) -> dict[str, Any]:
        """Turning auto-renew off is how a member cancels: benefits last until the paid period ends."""
        m = await self.get(principal.uid)
        if m is None or m.periods == 0:
            raise NotFound("You're not a Yummy Chops Plus member")
        now = utcnow()
        await self.repos.memberships.update(
            principal.uid,
            {"auto_renew": auto_renew, "cancelled_at": None if auto_renew else now, "updated_at": now},
        )
        return await self.overview(principal)

    # ------------------------------------------------------------------------------------------- renewals
    async def renew_due(self, now: datetime | None = None) -> dict[str, int]:
        """Daily job: renew memberships ending soon from the wallet; remind members who can't be charged."""
        cfg = await self.repos.get_pricing_config()
        plan = cfg.plus
        if not plan.enabled:
            return {"renewed": 0, "reminded": 0}
        now = now or utcnow()
        horizon = now + timedelta(hours=plan.renew_window_hours)
        due = await self.repos.memberships.find(
            where=[("auto_renew", "==", True), ("paid_through", "<=", horizon)], limit=500
        )
        _, vat = vat_inclusive_split(plan.price_kobo, cfg.vat_bps)
        renewed = reminded = 0
        for m in due:
            if m.periods == 0 or m.paid_through < now - LAPSE_GRACE:
                continue  # never paid, or lapsed: the member re-joins themselves
            try:
                await self.payments.pay_plus_with_wallet(
                    m.uid, plan.price_kobo, vat, f"renew:{m.periods + 1}", renewal=True
                )
                renewed += 1
            except ValidationFailed as exc:
                if m.reminder_for == m.paid_through:
                    continue
                await self.repos.memberships.update(
                    m.uid, {"reminder_for": m.paid_through, "updated_at": now}
                )
                short = int((exc.details or {}).get("short_by_kobo", plan.price_kobo))
                await self.notifier.notify_user(
                    m.uid,
                    "Keep Yummy Chops Plus",
                    f"Top up {format_naira(short)} in your wallet to renew automatically. Your benefits end on "
                    f"{lagos_day(m.paid_through)}.",
                    {"screen": "plus"},
                )
                reminded += 1
        return {"renewed": renewed, "reminded": reminded}

    # ------------------------------------------------------------------------------------------- staff
    async def admin_stats(self, principal: Principal) -> dict[str, Any]:
        require(principal, Permission.ANALYTICS_READ)
        now = utcnow()
        active = await self.repos.memberships.find(where=[("paid_through", ">", now)], limit=5_000)
        active = [m for m in active if m.periods > 0]
        async with self.db.session() as s:
            revenue = await self.ledger.balance(s, "revenue:plus")
        return {
            "active_members": len(active),
            "auto_renew_on": sum(1 for m in active if m.auto_renew),
            "ending_in_7_days": sum(1 for m in active if m.paid_through <= now + timedelta(days=7)),
            "revenue_kobo": revenue,
            "plan": await self.plan_view(),
        }


__all__ = ["MembershipService", "benefits_text"]
