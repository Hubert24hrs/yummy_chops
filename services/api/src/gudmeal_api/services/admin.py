"""Command Centre operations: overview, analytics, configuration, roles, finance (settlements & payouts)."""

from __future__ import annotations

import uuid
from collections import Counter, defaultdict
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

from pydantic import BaseModel, Field
from sqlalchemy import and_, func, select

from ..domain.models import Order, RestaurantStatus, RiderStatus
from ..domain.order_state import OrderStatus
from ..domain.pricing import PricingConfig
from ..errors import Conflict, NotFound, ValidationFailed
from ..ledger import ledger as postings
from ..ledger.audit import AuditLog
from ..ledger.db import Database
from ..ledger.ledger import LedgerService
from ..ledger.tables import (
    CommissionRecord,
    FinancialAccount,
    FinancialTransaction,
    LedgerEntry,
    PaymentRecord,
    RefundRecord,
    RestaurantSettlement,
    RiderPayout,
)
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, Role, require, require_restaurant, require_rider
from .business import suspend_branches_selling
from .infra import IdentityAdmin

S = OrderStatus
LAGOS_OFFSET = timedelta(hours=1)
PRICING_PATH = "platform_configuration/pricing"  # the document Repositories.get_pricing_config reads
# What a shop's statement adds up: its earnings, refunds it bears, and shares it has had already by split payment.
SETTLEMENT_KINDS = ("order_settlement", "refund", "split_settled")
UNPAID_SETTLEMENTS = ("pending", "approved")


def utcnow() -> datetime:
    return datetime.now(UTC)


def as_utc(moment: datetime) -> datetime:
    return moment.astimezone(UTC) if moment.tzinfo else moment.replace(tzinfo=UTC)


def lagos_day_start(now: datetime) -> datetime:
    local = now + LAGOS_OFFSET
    return local.replace(hour=0, minute=0, second=0, microsecond=0) - LAGOS_OFFSET


class RolesInput(BaseModel):
    roles: list[Role] = Field(default_factory=list, max_length=10)
    restaurant_roles: dict[str, Literal["owner", "manager", "staff"]] = Field(default_factory=dict)


class FlagInput(BaseModel):
    enabled: bool
    description: str = Field(default="", max_length=300)


class PayoutRequestInput(BaseModel):
    amount_kobo: int = Field(gt=0)


MIN_PAYOUT_KOBO = 100_000  # ₦1,000


class AnalyticsService:
    def __init__(self, repos: Repositories) -> None:
        self.repos = repos

    @staticmethod
    def summarise(orders: list[Order], days: int, now: datetime) -> dict[str, Any]:
        completed = [o for o in orders if o.status in (S.COMPLETED, S.PARTIALLY_REFUNDED)]
        by_day: dict[str, dict[str, int]] = defaultdict(lambda: {"orders": 0, "gross_kobo": 0})
        items: Counter[str] = Counter()
        prep: list[int] = []
        for o in completed:
            day = (o.created_at + LAGOS_OFFSET).date().isoformat()
            by_day[day]["orders"] += 1
            by_day[day]["gross_kobo"] += o.breakdown.subtotal_kobo
            for ln in o.lines:
                items[ln.name] += ln.quantity
            if o.accepted_at and o.ready_at:
                prep.append(int((o.ready_at - o.accepted_at).total_seconds() // 60))
        decided = [
            o
            for o in orders
            if o.status not in (S.DRAFT, S.PENDING_PAYMENT, S.PAID, S.SUBMITTED_TO_RESTAURANT, S.CANCELLED)
        ]
        rejected = [o for o in orders if o.cancellation_reason and o.status in (S.REFUND_PENDING, S.REFUNDED)]
        series = []
        for i in range(days - 1, -1, -1):
            day = ((now + LAGOS_OFFSET) - timedelta(days=i)).date().isoformat()
            series.append({"date": day, **by_day.get(day, {"orders": 0, "gross_kobo": 0})})
        gross = sum(o.breakdown.subtotal_kobo for o in completed)
        return {
            "period_days": days,
            "orders_total": len(orders),
            "orders_completed": len(completed),
            "gross_sales_kobo": gross,
            "commission_kobo": sum(o.settlement.commission_kobo for o in completed),
            "net_earnings_kobo": sum(o.settlement.restaurant_earning_kobo for o in completed),
            "average_order_kobo": gross // len(completed) if completed else 0,
            "acceptance_rate": round(1 - len(rejected) / len(decided), 3) if decided else None,
            "avg_prep_minutes": round(sum(prep) / len(prep), 1) if prep else None,
            "top_items": [{"name": n, "quantity": q} for n, q in items.most_common(5)],
            "series": series,
        }

    async def restaurant(self, principal: Principal, restaurant_id: str, days: int = 14) -> dict[str, Any]:
        require_restaurant(principal, restaurant_id, "analytics")
        days = max(1, min(days, 90))
        now = utcnow()
        orders = await self.repos.orders.find(
            where=[("restaurant_id", "==", restaurant_id), ("created_at", ">=", now - timedelta(days=days))],
            limit=5000,
        )
        summary = self.summarise(orders, days, now)
        summary["forecast_next_7_days_orders"] = self.forecast([p["orders"] for p in summary["series"]])
        return summary

    @staticmethod
    def forecast(daily: list[int]) -> int:
        """Simple, explainable forecast: weighted moving average of the last 7 days × 7."""
        window = daily[-7:]
        if not window:
            return 0
        weights = list(range(1, len(window) + 1))
        avg = sum(v * w for v, w in zip(window, weights, strict=True)) / sum(weights)
        return round(avg * 7)


class AdminService:
    def __init__(
        self,
        *,
        repos: Repositories,
        db: Database,
        ledger: LedgerService,
        audit: AuditLog,
        identity: IdentityAdmin,
        analytics: AnalyticsService,
    ) -> None:
        self.repos = repos
        self.db = db
        self.ledger = ledger
        self.audit = audit
        self.identity = identity
        self.analytics = analytics

    # ---------------------------------------------------------------- overview ------------------
    async def overview(self, principal: Principal) -> dict[str, Any]:
        require(principal, Permission.ORDERS_READ_ALL)
        now = utcnow()
        since = lagos_day_start(now)
        today = await self.repos.orders.find(where=[("created_at", ">=", since)], limit=10_000)
        today = [o for o in today if not o.is_leg]  # waybill rider jobs are part of their waybill
        status_counts = Counter(o.status.value for o in today)
        completed = [o for o in today if o.status in (S.COMPLETED, S.PARTIALLY_REFUNDED)]
        riders_online = await self.repos.riders.find(where=[("is_online", "==", True)], limit=5000)
        pending_apps = await self.repos.applications.find(where=[("status", "==", "submitted")], limit=500)
        open_tickets = await self.repos.tickets.find(
            where=[("status", "in", ["open", "escalated"])], limit=1000
        )
        active = [
            o
            for o in today
            if o.status
            in (
                S.SUBMITTED_TO_RESTAURANT,
                S.RESTAURANT_ACCEPTED,
                S.PREPARING,
                S.READY_FOR_PICKUP,
                S.RIDER_ASSIGNED,
                S.PICKED_UP,
                S.IN_TRANSIT,
            )
        ]
        stuck = [o for o in active if now - o.updated_at > timedelta(minutes=30)]
        async with self.db.session() as s:
            pending_refunds = await s.scalar(
                select(func.count()).select_from(RefundRecord).where(RefundRecord.status == "requested")
            )
            flagged = await s.scalar(
                select(func.count()).select_from(PaymentRecord).where(PaymentRecord.status == "flagged")
            )
        return {
            "as_of": now,
            "orders_today": len(today),
            "orders_by_status": dict(status_counts),
            "gmv_today_kobo": sum(o.breakdown.total_kobo for o in completed),
            "platform_revenue_today_kobo": sum(
                o.settlement.commission_kobo + o.breakdown.service_fee_kobo + o.breakdown.small_order_fee_kobo
                for o in completed
            ),
            "active_orders": len(active),
            "stuck_orders": [
                {
                    "id": o.id,
                    "short_code": o.short_code,
                    "status": o.status.value,
                    "minutes_since_update": int((now - o.updated_at).total_seconds() // 60),
                }
                for o in stuck[:20]
            ],
            "riders_online": len(riders_online),
            "riders_busy": sum(1 for r in riders_online if r.active_order_ids),
            "pending_applications": len(pending_apps),
            "open_tickets": len(open_tickets),
            "pending_refunds": int(pending_refunds or 0),
            "flagged_payments": int(flagged or 0),
        }

    async def platform_analytics(self, principal: Principal, days: int = 14) -> dict[str, Any]:
        require(principal, Permission.ANALYTICS_READ)
        days = max(1, min(days, 90))
        now = utcnow()
        orders = await self.repos.orders.find(
            where=[("created_at", ">=", now - timedelta(days=days))], limit=20_000
        )
        orders = [o for o in orders if not o.is_leg]
        summary = AnalyticsService.summarise(orders, days, now)
        by_restaurant: Counter[str] = Counter()
        for o in orders:
            if o.status in (S.COMPLETED, S.PARTIALLY_REFUNDED):
                by_restaurant[o.restaurant_name] += o.breakdown.subtotal_kobo
        summary["top_restaurants"] = [{"name": n, "gross_kobo": v} for n, v in by_restaurant.most_common(5)]
        summary["forecast_next_7_days_orders"] = AnalyticsService.forecast(
            [p["orders"] for p in summary["series"]]
        )
        return summary

    # ---------------------------------------------------------------- entities ------------------
    async def list_restaurants(self, principal: Principal) -> list[Any]:
        require(principal, Permission.RESTAURANTS_MANAGE)
        return await self.repos.restaurants.find(limit=1000)

    async def set_restaurant_status(
        self, principal: Principal, restaurant_id: str, status: RestaurantStatus, reason: str
    ) -> None:
        require(principal, Permission.RESTAURANTS_MANAGE)
        if await self.repos.restaurants.get(restaurant_id) is None:
            raise NotFound("Restaurant not found")
        await self.repos.restaurants.update(restaurant_id, {"status": status.value})
        stopped = (
            await suspend_branches_selling(self.repos, restaurant_id)
            if status == RestaurantStatus.SUSPENDED
            else []
        )
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="restaurant.status_changed",
            resource_type="restaurant",
            resource_id=restaurant_id,
            details={"status": status.value, "reason": reason, "branches_suspended": stopped},
        )

    async def list_riders(self, principal: Principal) -> list[Any]:
        require(principal, Permission.RIDERS_MANAGE)
        return await self.repos.riders.find(limit=2000)

    async def set_rider_status(
        self, principal: Principal, uid: str, status: RiderStatus, reason: str
    ) -> None:
        require(principal, Permission.RIDERS_MANAGE)
        if await self.repos.riders.get(uid) is None:
            raise NotFound("Rider not found")
        changes: dict[str, Any] = {"status": status.value}
        if status != RiderStatus.ACTIVE:
            changes["is_online"] = False
        await self.repos.riders.update(uid, changes)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="rider.status_changed",
            resource_type="rider",
            resource_id=uid,
            details={"status": status.value, "reason": reason},
        )

    async def set_roles(self, principal: Principal, uid: str, data: RolesInput) -> dict[str, Any]:
        require(principal, Permission.USERS_MANAGE_ROLES)
        if (
            uid == principal.uid
            and Role.SUPER_ADMIN.value in principal.roles
            and Role.SUPER_ADMIN not in data.roles
        ):
            raise ValidationFailed("You cannot remove your own super_admin role")
        roles = sorted({r.value for r in data.roles})
        await self.identity.set_claims(uid, roles, dict(data.restaurant_roles))
        await self.repos.upsert_user(uid, {"roles": roles, "restaurant_roles": dict(data.restaurant_roles)})
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="user.roles_set",
            resource_type="user",
            resource_id=uid,
            details={"roles": roles, "restaurant_roles": data.restaurant_roles},
        )
        return {"uid": uid, "roles": roles, "restaurant_roles": data.restaurant_roles}

    # ---------------------------------------------------------------- configuration ---------------
    async def get_pricing(self, principal: Principal) -> PricingConfig:
        require(principal, Permission.CONFIG_READ)
        return await self.repos.get_pricing_config()

    async def update_pricing(self, principal: Principal, cfg: PricingConfig) -> PricingConfig:
        """Publish new prices. The page sends back the version it loaded: if someone else has published since,
        saving would silently undo their change, so it is refused and the page must be reloaded."""
        require(principal, Permission.CONFIG_WRITE)

        async def fn(tx: Transaction) -> PricingConfig:
            doc = await tx.get(PRICING_PATH)
            current = PricingConfig.model_validate(doc) if doc else PricingConfig()
            if cfg.version != current.version:
                raise Conflict(
                    "The pricing was changed after you opened this page. Reload it and make your changes again.",
                    details={"your_version": cfg.version, "current_version": current.version},
                )
            new_cfg = cfg.model_copy(update={"version": current.version + 1})
            tx.set(PRICING_PATH, to_doc(new_cfg))
            return new_cfg

        new_cfg = await self.repos.store.run_transaction(fn)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="config.pricing_updated",
            resource_type="config",
            resource_id="pricing",
            details={
                "from_version": new_cfg.version - 1,
                "to_version": new_cfg.version,
                "config": new_cfg.model_dump(mode="json"),
            },
        )
        return new_cfg

    async def set_flag(self, principal: Principal, key: str, data: FlagInput) -> dict[str, Any]:
        require(principal, Permission.FLAGS_WRITE)
        await self.repos.set_feature_flag(key, data.enabled, data.description, principal.uid)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="flag.set",
            resource_type="feature_flag",
            resource_id=key,
            details=data.model_dump(),
        )
        return {"key": key, **data.model_dump()}

    # ---------------------------------------------------------------- finance ----------------------
    async def ledger_overview(self, principal: Principal) -> dict[str, Any]:
        require(principal, Permission.LEDGER_READ)
        async with self.db.session() as s:
            return {
                "trial_balance": await self.ledger.trial_balance(s),
                "accounts": await self.ledger.balances(s),
            }

    async def order_ledger(self, principal: Principal, order_id: str) -> list[dict[str, Any]]:
        require(principal, Permission.LEDGER_READ)
        async with self.db.session() as s:
            return await self.ledger.entries_for_order(s, order_id)

    async def generate_settlements(
        self, principal: Principal, period_start: datetime, period_end: datetime
    ) -> list[dict[str, Any]]:
        """Statements of what each shop is owed for a period (period_end is not included, so the next period
        starts where this one ends). A statement never asks Finance to pay more than the shop is owed now:

        - a share the shop has had already by split payment counts against its earnings;
        - what its other unpaid statements promise is taken off first, and money it owes back (a refunded split
          order, a refund it bears) is taken out of what it earns next;
        - days that are on one of the shop's statements already are not put on another."""
        require(principal, Permission.SETTLEMENTS_MANAGE)
        period_start, period_end = as_utc(period_start), as_utc(period_end)
        if period_end <= period_start:
            raise ValidationFailed("period_end must be after period_start")
        created: list[dict[str, Any]] = []
        async with self.db.transaction() as s:
            rows = (
                await s.execute(
                    select(
                        FinancialAccount.owner_id,
                        LedgerEntry.direction,
                        func.sum(LedgerEntry.amount_kobo),
                        func.count(func.distinct(FinancialTransaction.order_id)),
                    )
                    .join(LedgerEntry, LedgerEntry.account_id == FinancialAccount.id)
                    .join(FinancialTransaction, FinancialTransaction.id == LedgerEntry.transaction_id)
                    .where(
                        and_(
                            FinancialAccount.owner_type == "restaurant",
                            FinancialTransaction.kind.in_(SETTLEMENT_KINDS),
                            FinancialTransaction.created_at >= period_start,
                            FinancialTransaction.created_at < period_end,
                        )
                    )
                    .group_by(FinancialAccount.owner_id, LedgerEntry.direction)
                )
            ).all()
            totals: dict[str, dict[str, int]] = defaultdict(lambda: {"credit": 0, "debit": 0, "orders": 0})
            for owner_id, direction, amount, orders in rows:
                totals[owner_id][direction] += int(amount or 0)
                if direction == "credit":
                    totals[owner_id]["orders"] = int(orders or 0)
            for restaurant_id, t in totals.items():
                overlaps = await s.scalar(
                    select(RestaurantSettlement.id)
                    .where(
                        RestaurantSettlement.restaurant_id == restaurant_id,
                        RestaurantSettlement.period_start < period_end,
                        RestaurantSettlement.period_end > period_start,
                    )
                    .limit(1)
                )
                if overlaps:
                    continue
                commission = await s.scalar(
                    select(func.coalesce(func.sum(CommissionRecord.commission_kobo), 0)).where(
                        CommissionRecord.restaurant_id == restaurant_id,
                        CommissionRecord.created_at >= period_start,
                        CommissionRecord.created_at < period_end,
                    )
                )
                owed = await self.ledger.balance(s, f"liability:restaurant:{restaurant_id}")
                promised = await s.scalar(
                    select(func.coalesce(func.sum(RestaurantSettlement.net_kobo), 0)).where(
                        RestaurantSettlement.restaurant_id == restaurant_id,
                        RestaurantSettlement.status.in_(UNPAID_SETTLEMENTS),
                        RestaurantSettlement.net_kobo > 0,
                    )
                )
                net = min(t["credit"] - t["debit"], owed - int(promised or 0))
                row = RestaurantSettlement(
                    id=str(uuid.uuid4()),
                    restaurant_id=restaurant_id,
                    period_start=period_start,
                    period_end=period_end,
                    orders_count=t["orders"],
                    gross_kobo=t["credit"] + int(commission or 0),
                    commission_kobo=int(commission or 0),
                    adjustments_kobo=net - t["credit"],  # gross - commission + adjustments = net
                    net_kobo=net,
                    status="pending",
                )
                s.add(row)
                created.append(
                    {"id": row.id, "restaurant_id": restaurant_id, "net_kobo": net, "orders": t["orders"]}
                )
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action="settlements.generated",
                resource_type="settlement",
                resource_id=f"{period_start.isoformat()}..{period_end.isoformat()}",
                details={"count": len(created)},
            )
        return created

    async def list_settlements(
        self, principal: Principal, restaurant_id: str | None = None
    ) -> list[dict[str, Any]]:
        if restaurant_id and principal.can_on_restaurant(restaurant_id, "finance"):
            pass
        else:
            require(principal, Permission.SETTLEMENTS_MANAGE)
        stmt = select(RestaurantSettlement).order_by(RestaurantSettlement.period_end.desc()).limit(200)
        if restaurant_id:
            stmt = stmt.where(RestaurantSettlement.restaurant_id == restaurant_id)
        async with self.db.session() as s:
            return [
                {
                    "id": r.id,
                    "restaurant_id": r.restaurant_id,
                    "period_start": r.period_start,
                    "period_end": r.period_end,
                    "orders_count": r.orders_count,
                    "gross_kobo": r.gross_kobo,
                    "commission_kobo": r.commission_kobo,
                    "adjustments_kobo": r.adjustments_kobo,
                    "net_kobo": r.net_kobo,
                    "status": r.status,
                    "payout_reference": r.payout_reference,
                    "paid_at": r.paid_at,
                }
                for r in (await s.execute(stmt)).scalars()
            ]

    async def mark_settlement_paid(
        self, principal: Principal, settlement_id: str, bank_reference: str
    ) -> dict[str, Any]:
        require(principal, Permission.PAYOUTS_APPROVE)
        async with self.db.transaction() as s:
            row = await s.get(RestaurantSettlement, settlement_id, with_for_update=True)
            if row is None:
                raise NotFound("Settlement not found")
            if row.status == "paid":
                return {"id": row.id, "status": row.status}
            if row.net_kobo > 0:
                # The statement was right when it was made; a refund the shop bears, or a share it has had by
                # split payment since, may have lowered what it is owed. Never pay out more than that.
                account = f"liability:restaurant:{row.restaurant_id}"
                await self.ledger.lock_account(s, account)
                owed = await self.ledger.balance(s, account)
                if row.net_kobo > owed:
                    raise ValidationFailed(
                        "The shop is owed less than this statement says, so nothing was paid. "
                        "It can be paid once the shop has earned the difference.",
                        details={"net_kobo": row.net_kobo, "owed_kobo": owed},
                    )
                await self.ledger.post(
                    s,
                    kind="restaurant_payout",
                    idempotency_key=f"settlement:{row.id}:paid",
                    postings=postings.payout_made("restaurant", row.restaurant_id, row.net_kobo),
                    created_by=principal.uid,
                    reference=bank_reference,
                    description=f"Settlement {row.id}",
                )
            row.status = "paid"
            row.payout_reference = bank_reference
            row.paid_at = utcnow()
            row.approved_by = principal.uid
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action="settlement.paid",
                resource_type="settlement",
                resource_id=row.id,
                details={"net_kobo": row.net_kobo, "reference": bank_reference},
            )
            return {"id": row.id, "status": row.status}

    # ---------------------------------------------------------------- rider earnings & payouts -----
    async def rider_earnings(self, principal: Principal) -> dict[str, Any]:
        require_rider(principal)
        account = f"liability:rider:{principal.uid}"
        async with self.db.session() as s:
            balance = await self.ledger.balance(s, account)
            cash_held = await self.ledger.balance(s, postings.rider_cash_account(principal.uid))
            pending = await s.scalar(
                select(func.coalesce(func.sum(RiderPayout.amount_kobo), 0)).where(
                    RiderPayout.rider_id == principal.uid, RiderPayout.status.in_(("requested", "approved"))
                )
            )
            payouts = (
                (
                    await s.execute(
                        select(RiderPayout)
                        .where(RiderPayout.rider_id == principal.uid)
                        .order_by(RiderPayout.requested_at.desc())
                        .limit(20)
                    )
                )
                .scalars()
                .all()
            )
        deliveries = await self.repos.orders.find(
            where=[("rider_id", "==", principal.uid), ("status", "==", S.COMPLETED.value)], limit=500
        )
        week_ago = utcnow() - timedelta(days=7)
        return {
            "balance_kobo": balance,
            "pending_payouts_kobo": int(pending or 0),
            # Cash collected at the door is ours: it is netted off before a rider can withdraw earnings.
            "cash_held_kobo": cash_held,
            "available_kobo": max(0, balance - int(pending or 0) - cash_held),
            "deliveries_completed": len(deliveries),
            "earned_last_7_days_kobo": sum(
                o.settlement.rider_pay_kobo
                for o in deliveries
                if o.completed_at and o.completed_at >= week_ago
            ),
            "payouts": [
                {
                    "id": p.id,
                    "amount_kobo": p.amount_kobo,
                    "status": p.status,
                    "requested_at": p.requested_at,
                    "paid_at": p.paid_at,
                }
                for p in payouts
            ],
        }

    async def request_rider_payout(
        self, principal: Principal, amount_kobo: int, idempotency_key: str
    ) -> dict[str, Any]:
        require_rider(principal)
        if amount_kobo < MIN_PAYOUT_KOBO:
            raise ValidationFailed("Minimum withdrawal is ₦1,000")
        account = postings.rider_account(principal.uid)
        async with self.db.transaction() as s:
            existing = await s.scalar(
                select(RiderPayout).where(RiderPayout.idempotency_key == f"{principal.uid}:{idempotency_key}")
            )
            if existing:
                return {"id": existing.id, "status": existing.status, "amount_kobo": existing.amount_kobo}
            # Checked under the account lock: two requests sent at once cannot both count the same balance.
            await self.ledger.lock_account(s, account)
            balance = await self.ledger.balance(s, account)
            cash_held = await self.ledger.balance(s, postings.rider_cash_account(principal.uid))
            pending = await s.scalar(
                select(func.coalesce(func.sum(RiderPayout.amount_kobo), 0)).where(
                    RiderPayout.rider_id == principal.uid, RiderPayout.status.in_(("requested", "approved"))
                )
            )
            available = max(0, balance - int(pending or 0) - cash_held)
            if amount_kobo > available:
                raise ValidationFailed(
                    "Amount exceeds your available balance", details={"available_kobo": available}
                )
            row = RiderPayout(
                rider_id=principal.uid,
                amount_kobo=amount_kobo,
                idempotency_key=f"{principal.uid}:{idempotency_key}",
            )
            s.add(row)
            await s.flush()
            return {"id": row.id, "status": row.status, "amount_kobo": row.amount_kobo}

    async def list_rider_payouts(
        self, principal: Principal, status: str | None = None
    ) -> list[dict[str, Any]]:
        require(principal, Permission.PAYOUTS_APPROVE)
        stmt = select(RiderPayout).order_by(RiderPayout.requested_at.desc()).limit(300)
        if status:
            stmt = stmt.where(RiderPayout.status == status)
        async with self.db.session() as s:
            return [
                {
                    "id": p.id,
                    "rider_id": p.rider_id,
                    "amount_kobo": p.amount_kobo,
                    "status": p.status,
                    "requested_at": p.requested_at,
                    "decided_by": p.decided_by,
                    "reference": p.reference,
                }
                for p in (await s.execute(stmt)).scalars()
            ]

    async def decide_rider_payout(
        self, principal: Principal, payout_id: str, *, approve: bool, bank_reference: str | None
    ) -> dict[str, Any]:
        require(principal, Permission.PAYOUTS_APPROVE)
        async with self.db.transaction() as s:
            row = await s.get(RiderPayout, payout_id, with_for_update=True)
            if row is None:
                raise NotFound("Payout not found")
            if row.status != "requested":
                raise ValidationFailed(f"Payout already {row.status}")
            row.decided_by = principal.uid
            row.decided_at = utcnow()
            if approve:
                if not bank_reference:
                    raise ValidationFailed("A bank transfer reference is required to mark the payout as paid")
                await self.ledger.lock_account(s, postings.rider_account(row.rider_id))
                balance = await self.ledger.balance(s, f"liability:rider:{row.rider_id}")
                cash_held = await self.ledger.balance(s, postings.rider_cash_account(row.rider_id))
                if row.amount_kobo > balance - cash_held:
                    raise ValidationFailed(
                        "Rider balance is insufficient once the cash they hold is deducted",
                        details={"balance_kobo": balance, "cash_held_kobo": cash_held},
                    )
                await self.ledger.post(
                    s,
                    kind="rider_payout",
                    idempotency_key=f"payout:{row.id}",
                    postings=postings.payout_made("rider", row.rider_id, row.amount_kobo),
                    created_by=principal.uid,
                    reference=bank_reference,
                    description=f"Rider payout {row.id}",
                )
                row.status = "paid"
                row.reference = bank_reference
                row.paid_at = utcnow()
            else:
                row.status = "rejected"
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action=f"payout.{row.status}",
                resource_type="rider_payout",
                resource_id=row.id,
                details={"amount_kobo": row.amount_kobo, "reference": bank_reference},
            )
            return {"id": row.id, "status": row.status}
