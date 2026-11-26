"""Cash in the field: pay-on-delivery eligibility, cash held by riders, and hand-ins (remittances).

The ledger is the source of truth: cash a rider collects is a receivable (`receivable:rider_cash:{uid}`) until
finance records it as paid into the bank or deducted from the rider's earnings. `RiderProfile.cash_held_kobo` is
only a copy used by dispatch to stop offering cash jobs to riders who already carry too much.
"""

from __future__ import annotations

from collections.abc import Collection
from datetime import UTC, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field

from ..domain.models import CustomerProfile, Fulfillment, Order
from ..domain.money import format_naira
from ..domain.order_state import ACTIVE_FULFILMENT, OrderStatus
from ..errors import NotFound, ValidationFailed
from ..ledger import ledger as postings
from ..ledger.audit import AuditLog
from ..ledger.db import Database
from ..ledger.ledger import LedgerService
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, require

S = OrderStatus
POD_FLAG = "pay_on_delivery"


class RemittanceInput(BaseModel):
    amount_kobo: int = Field(gt=0, le=100_000_000)
    method: Literal["bank_transfer", "cash_deposit", "earnings_offset"]
    reference: str | None = Field(default=None, max_length=120)  # bank or receipt reference
    note: str | None = Field(default=None, max_length=300)


class CarrierPayoutInput(BaseModel):
    amount_kobo: int = Field(gt=0, le=1_000_000_000)
    bank_reference: str = Field(min_length=4, max_length=120)


class PayOnDeliveryBlockInput(BaseModel):
    blocked: bool
    reason: str = Field(min_length=3, max_length=300)


class CashService:
    def __init__(
        self,
        *,
        repos: Repositories,
        db: Database,
        ledger: LedgerService,
        audit: AuditLog,
        enabled: bool = True,
        max_order_kobo: int = 2_500_000,
        min_completed_orders: int = 1,
        rider_cash_limit_kobo: int = 5_000_000,
    ) -> None:
        self.repos = repos
        self.db = db
        self.ledger = ledger
        self.audit = audit
        self.enabled = enabled
        self.max_order_kobo = max_order_kobo
        self.min_completed_orders = min_completed_orders
        self.rider_cash_limit_kobo = rider_cash_limit_kobo

    # ------------------------------------------------------------------ pay on delivery eligibility
    async def _flag_allows(self) -> bool:
        flag = (await self.repos.list_feature_flags()).get(POD_FLAG)
        return True if flag is None else bool(flag.get("enabled"))

    async def pay_on_delivery_status(
        self, principal: Principal, order: Order, *, together: Collection[str] = ()
    ) -> tuple[bool, str | None]:
        """Whether this customer may pay this order in cash at the door, and why not if they can't. `together` are
        the other orders of the same cart (ADR-0030): one trip to one door, so they are not "another" order."""
        if not self.enabled or not await self._flag_allows():
            return False, "Pay on delivery is not available right now"
        if order.is_parcel or order.is_waybill:
            return False, "Package deliveries are paid when you book"
        if order.group_order_id:
            return False, "Group orders are paid online"
        if order.fulfillment != Fulfillment.DELIVERY:
            return False, "Pay on delivery is only for delivery orders"
        if order.breakdown.total_kobo > self.max_order_kobo:
            return False, f"Pay on delivery is available for orders up to {format_naira(self.max_order_kobo)}"
        phone = order.customer_phone or (
            order.delivery_address.contact_phone if order.delivery_address else None
        )
        if not phone:
            return False, "Add a phone number so the rider can reach you"
        profile = await self.repos.customers.get(principal.uid)
        if profile is not None and profile.pay_on_delivery_blocked:
            return False, "Pay on delivery is turned off for your account. Please pay online."
        orders = await self.repos.orders.find(where=[("customer_id", "==", principal.uid)], limit=500)
        completed = sum(1 for o in orders if o.status == S.COMPLETED)
        if completed < self.min_completed_orders:
            n = self.min_completed_orders
            return False, f"Pay on delivery unlocks after your first {'order' if n == 1 else f'{n} orders'}"
        if any(
            o.id != order.id
            and o.id not in together
            and o.is_pay_on_delivery
            and o.status in ACTIVE_FULFILMENT
            for o in orders
        ):
            return False, "You already have a pay-on-delivery order on the way"
        return True, None

    async def set_customer_block(
        self, principal: Principal, uid: str, data: PayOnDeliveryBlockInput
    ) -> dict[str, Any]:
        """Support switches pay on delivery off for a customer (e.g. after a refused delivery), or back on."""
        require(principal, Permission.SUPPORT_MANAGE)
        now = datetime.now(UTC)
        profile = await self.repos.customers.get(uid) or CustomerProfile(
            uid=uid, created_at=now, updated_at=now
        )
        await self.repos.customers.save(
            profile.model_copy(update={"pay_on_delivery_blocked": data.blocked, "updated_at": now})
        )
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="customer.pay_on_delivery_blocked" if data.blocked else "customer.pay_on_delivery_allowed",
            resource_type="customer",
            resource_id=uid,
            details={"reason": data.reason},
        )
        return {"uid": uid, "pay_on_delivery_blocked": data.blocked}

    async def assert_pay_on_delivery(
        self, principal: Principal, order: Order, *, together: Collection[str] = ()
    ) -> None:
        ok, reason = await self.pay_on_delivery_status(principal, order, together=together)
        if not ok:
            raise ValidationFailed(reason or "Pay on delivery is not available", details={"method": "cash"})

    # ------------------------------------------------------------------ riders' cash
    async def rider_cash_held(self, rider_id: str) -> int:
        async with self.db.session() as s:
            return await self.ledger.balance(s, postings.rider_cash_account(rider_id))

    async def overview(self, principal: Principal) -> dict[str, Any]:
        """Finance view: who holds cash, what we owe in wallets and to sellers."""
        require(principal, Permission.PAYOUTS_APPROVE)
        async with self.db.session() as s:
            cash = await self.ledger.balances(s, "receivable:rider_cash:")
            earnings = {
                a["account"].rsplit(":", 1)[1]: a["balance_kobo"]
                for a in await self.ledger.balances(s, "liability:rider:")
            }
            wallets = await self.ledger.balances(s, "liability:wallet:")
            sellers = await self.ledger.balances(s, "liability:vendor:")
            carriers = await self.ledger.balances(s, "liability:carrier:")
        network = await self.repos.get_waybill_network()
        held = {a["account"].rsplit(":", 1)[1]: a["balance_kobo"] for a in cash if a["balance_kobo"]}
        profiles = await self.repos.riders.get_many(list(held))
        riders = sorted(
            (
                {
                    "rider_id": uid,
                    "name": profiles[uid].name if uid in profiles else uid,
                    "phone": profiles[uid].phone if uid in profiles else None,
                    "cash_held_kobo": amount,
                    "earnings_kobo": earnings.get(uid, 0),
                    "over_limit": amount > self.rider_cash_limit_kobo,
                }
                for uid, amount in held.items()
            ),
            key=lambda r: -r["cash_held_kobo"],
        )
        return {
            "riders": riders,
            "rider_cash_limit_kobo": self.rider_cash_limit_kobo,
            "carriers": [
                {
                    "carrier_id": cid,
                    "name": (c.name if (c := network.carrier(cid)) else cid),
                    "owed_kobo": a["balance_kobo"],
                }
                for a in carriers
                if (cid := a["account"].rsplit(":", 1)[1]) and a["balance_kobo"]
            ],
            "totals": {
                "cash_with_riders_kobo": sum(held.values()),
                "wallet_balances_kobo": sum(a["balance_kobo"] for a in wallets),
                "seller_balances_kobo": sum(a["balance_kobo"] for a in sellers),
                "carrier_balances_kobo": sum(a["balance_kobo"] for a in carriers),
            },
        }

    async def record_carrier_payout(
        self, principal: Principal, carrier_id: str, data: CarrierPayoutInput, idempotency_key: str
    ) -> dict[str, Any]:
        """Finance paid a line-haul carrier by bank transfer (amount checked against what we owe them)."""
        require(principal, Permission.PAYOUTS_APPROVE)
        if (await self.repos.get_waybill_network()).carrier(carrier_id) is None:
            raise NotFound("Carrier not found")
        account = postings.carrier_account(carrier_id)
        async with self.db.transaction() as s:
            await self.ledger.lock_account(s, account)
            owed = await self.ledger.balance(s, account)
            if data.amount_kobo > owed:
                raise ValidationFailed("That is more than we owe this carrier", details={"owed_kobo": owed})
            txn_id, created = await self.ledger.post(
                s,
                kind="carrier_payout",
                idempotency_key=f"carrier-payout:{carrier_id}:{idempotency_key}",
                postings=postings.payout_made("carrier", carrier_id, data.amount_kobo),
                created_by=principal.uid,
                reference=data.bank_reference.strip(),
                description="Carrier payout",
            )
            if created:
                AuditLog.add(
                    s,
                    actor_id=principal.uid,
                    actor_roles=principal.audit_roles(),
                    action="carrier.paid",
                    resource_type="carrier",
                    resource_id=carrier_id,
                    details={"amount_kobo": data.amount_kobo, "reference": data.bank_reference},
                )
            balance = await self.ledger.balance(s, account)
        return {"transaction_id": txn_id, "recorded": created, "owed_kobo": balance}

    async def record_remittance(
        self, principal: Principal, rider_id: str, data: RemittanceInput, idempotency_key: str
    ) -> dict[str, Any]:
        """Finance records cash a rider handed in, or deducts it from what we owe the rider."""
        require(principal, Permission.PAYOUTS_APPROVE)
        if await self.repos.riders.get(rider_id) is None:
            raise NotFound("Rider not found")
        if data.method != "earnings_offset" and not (data.reference and data.reference.strip()):
            raise ValidationFailed("Enter the bank or receipt reference for this hand-in")
        cash_account = postings.rider_cash_account(rider_id)
        async with self.db.transaction() as s:
            await self.ledger.lock_account(s, cash_account)
            held = await self.ledger.balance(s, cash_account)
            if data.amount_kobo > held:
                raise ValidationFailed(
                    "That is more than the cash this rider holds", details={"cash_held_kobo": held}
                )
            if data.method == "earnings_offset":
                # The same earnings cannot be paid out and used to clear cash at the same moment.
                await self.ledger.lock_account(s, postings.rider_account(rider_id))
                earned = await self.ledger.balance(s, postings.rider_account(rider_id))
                if data.amount_kobo > earned:
                    raise ValidationFailed(
                        "The rider's earnings are lower than this amount", details={"earnings_kobo": earned}
                    )
            txn_id, created = await self.ledger.post(
                s,
                kind="rider_cash_remittance",
                idempotency_key=f"remit:{rider_id}:{idempotency_key}",
                postings=postings.rider_cash_remitted(rider_id, data.amount_kobo, data.method),
                created_by=principal.uid,
                reference=(data.reference or "").strip() or None,
                description="Cash handed in"
                if data.method != "earnings_offset"
                else "Cash deducted from earnings",
                metadata={"method": data.method, "note": data.note, "rider_id": rider_id},
            )
            if created:
                AuditLog.add(
                    s,
                    actor_id=principal.uid,
                    actor_roles=principal.audit_roles(),
                    action="rider_cash.remitted",
                    resource_type="rider",
                    resource_id=rider_id,
                    details={
                        "amount_kobo": data.amount_kobo,
                        "method": data.method,
                        "reference": data.reference,
                    },
                )
            balance = await self.ledger.balance(s, cash_account)
        await self.repos.riders.update(rider_id, {"cash_held_kobo": balance})
        return {"transaction_id": txn_id, "recorded": created, "cash_held_kobo": balance}
