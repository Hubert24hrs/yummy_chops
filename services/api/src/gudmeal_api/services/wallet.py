"""Yummy Chops wallet (closed-loop stored value) and sellers' cash-on-delivery balances.

- Wallet: top up through a payment gateway, pay for orders in one tap, receive instant refunds. Money in the
  wallet can only be spent on Yummy Chops; there is no cash withdrawal (see ADR-0013 for the legal notes).
- Sellers: cash a rider collects for a package sender (vendor COD) is owed to the seller. They can move it into
  their wallet instantly or ask for a bank payout, which finance reviews and pays.

All balances come from the ledger. Amounts a person types (top-up, payout) are checked against limits and
balances here; prices never come from requests.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from pydantic import BaseModel, Field
from sqlalchemy import func, select

from ..domain.models import CustomerProfile, Order
from ..domain.money import format_naira
from ..errors import NotFound, ValidationFailed
from ..ledger import ledger as postings
from ..ledger.audit import AuditLog
from ..ledger.db import Database
from ..ledger.ledger import LedgerService
from ..ledger.tables import VendorPayout
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, require
from .cash import CashService
from .payments import PaymentService

MIN_SELLER_PAYOUT_KOBO = 100_000  # ₦1,000


def utcnow() -> datetime:
    return datetime.now(UTC)


class SellerPayoutInput(BaseModel):
    amount_kobo: int = Field(gt=0, le=100_000_000)
    bank_name: str = Field(min_length=2, max_length=80)
    account_number: str = Field(pattern=r"^\d{10}$")  # NUBAN
    account_name: str = Field(min_length=2, max_length=120)


def _mask(account_number: str) -> str:
    return f"******{account_number[-4:]}"


def payout_view(p: VendorPayout, *, full_account: bool = False) -> dict[str, Any]:
    return {
        "id": p.id,
        "vendor_id": p.vendor_id,
        "amount_kobo": p.amount_kobo,
        "bank_name": p.bank_name,
        "account_number": p.account_number if full_account else _mask(p.account_number),
        "account_name": p.account_name,
        "status": p.status,
        "reference": p.reference,
        "decision_note": p.decision_note,
        "requested_at": p.requested_at,
        "decided_at": p.decided_at,
        "paid_at": p.paid_at,
    }


class WalletService:
    def __init__(
        self,
        *,
        repos: Repositories,
        db: Database,
        ledger: LedgerService,
        payments: PaymentService,
        cash: CashService,
        enabled: bool = True,
        min_topup_kobo: int = 50_000,
        max_topup_kobo: int = 10_000_000,
        max_balance_kobo: int = 30_000_000,
    ) -> None:
        self.repos = repos
        self.db = db
        self.ledger = ledger
        self.payments = payments
        self.cash = cash
        self.enabled = enabled
        self.min_topup = min_topup_kobo
        self.max_topup = max_topup_kobo
        self.max_balance = max_balance_kobo

    def limits(self) -> dict[str, int]:
        return {
            "min_topup_kobo": self.min_topup,
            "max_topup_kobo": self.max_topup,
            "max_balance_kobo": self.max_balance,
        }

    async def balance(self, uid: str) -> int:
        async with self.db.session() as s:
            return await self.ledger.balance(s, postings.wallet_account(uid))

    # ------------------------------------------------------------------ customer wallet
    async def overview(self, principal: Principal, limit: int = 30) -> dict[str, Any]:
        uid = principal.uid
        async with self.db.session() as s:
            balance = await self.ledger.balance(s, postings.wallet_account(uid))
            statement = await self.ledger.statement(s, postings.wallet_account(uid), limit=limit)
        profile = await self.repos.customers.get(uid)
        return {
            "balance_kobo": balance,
            "currency": "NGN",
            "enabled": self.enabled,
            "limits": self.limits(),
            "refund_to_wallet": bool(profile and profile.refund_to_wallet),
            "transactions": statement,
            "seller": await self._seller_summary(uid),
        }

    async def transactions(self, principal: Principal, limit: int = 50) -> list[dict[str, Any]]:
        async with self.db.session() as s:
            return await self.ledger.statement(s, postings.wallet_account(principal.uid), limit=limit)

    async def start_topup(
        self, principal: Principal, amount_kobo: int, provider: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        if not self.enabled:
            raise ValidationFailed("The Yummy Chops wallet is not available right now")
        if amount_kobo < self.min_topup or amount_kobo > self.max_topup:
            raise ValidationFailed(
                f"Top up between {format_naira(self.min_topup)} and {format_naira(self.max_topup)}",
                details=self.limits(),
            )
        balance = await self.balance(principal.uid)
        room = self.max_balance - balance
        if amount_kobo > room:
            raise ValidationFailed(
                f"Your wallet can hold up to {format_naira(self.max_balance)}",
                details={"balance_kobo": balance, "max_topup_now_kobo": max(0, room)},
            )
        # The limit is checked again as the top-up is recorded, under the wallet's lock and counting top-ups
        # that are on their way, so several started at once cannot pass it together.
        return await self.payments.start_wallet_topup(
            principal, amount_kobo, provider, idempotency_key, max_balance_kobo=self.max_balance
        )

    async def set_refund_preference(self, principal: Principal, refund_to_wallet: bool) -> dict[str, Any]:
        profile = await self.repos.customers.get(principal.uid)
        if profile is None:
            profile = CustomerProfile(
                uid=principal.uid,
                display_name=principal.name,
                phone=principal.phone,
                email=principal.email,
                created_at=utcnow(),
                updated_at=utcnow(),
            )
        await self.repos.customers.save(
            profile.model_copy(update={"refund_to_wallet": refund_to_wallet, "updated_at": utcnow()})
        )
        return {"refund_to_wallet": refund_to_wallet}

    async def payment_options(self, principal: Principal, order: Order) -> dict[str, Any]:
        """What the customer can pay this order with, and why an option is unavailable."""
        total = order.breakdown.total_kobo
        balance = await self.balance(principal.uid) if self.enabled else 0
        short = max(0, total - balance)
        cash_ok, cash_reason = await self.cash.pay_on_delivery_status(principal, order)
        return {
            "order_id": order.id,
            "total_kobo": total,
            "methods": [
                {
                    "id": "card",
                    "label": "Card, bank transfer or USSD",
                    "provider": self.payments.default_provider,
                    "available": True,
                    "reason": None,
                },
                {
                    "id": "wallet",
                    "label": "Yummy Chops wallet",
                    "available": self.enabled and short == 0,
                    "balance_kobo": balance,
                    "short_by_kobo": short,
                    "reason": None
                    if self.enabled and short == 0
                    else (
                        "The wallet is not available right now"
                        if not self.enabled
                        else f"Top up {format_naira(short)} to pay with your wallet"
                    ),
                },
                {
                    "id": "cash",
                    "label": "Pay on delivery (cash)",
                    "available": cash_ok,
                    "reason": cash_reason,
                },
            ],
        }

    # ------------------------------------------------------------------ sellers (vendor COD)
    async def _seller_summary(self, uid: str) -> dict[str, Any] | None:
        async with self.db.session() as s:
            balance = await self.ledger.balance(s, postings.vendor_account(uid))
            pending = await s.scalar(
                select(func.coalesce(func.sum(VendorPayout.amount_kobo), 0)).where(
                    VendorPayout.vendor_id == uid, VendorPayout.status == "requested"
                )
            )
            any_payouts = await s.scalar(
                select(func.count()).select_from(VendorPayout).where(VendorPayout.vendor_id == uid)
            )
            collected = await self.ledger.statement(s, postings.vendor_account(uid), limit=1)
        if not balance and not any_payouts and not collected:
            return None
        pending = int(pending or 0)
        return {
            "cod_balance_kobo": balance,
            "pending_payouts_kobo": pending,
            "available_kobo": max(0, balance - pending),
            "min_payout_kobo": MIN_SELLER_PAYOUT_KOBO,
        }

    async def seller_overview(self, principal: Principal) -> dict[str, Any]:
        uid = principal.uid
        summary = await self._seller_summary(uid) or {
            "cod_balance_kobo": 0,
            "pending_payouts_kobo": 0,
            "available_kobo": 0,
            "min_payout_kobo": MIN_SELLER_PAYOUT_KOBO,
        }
        async with self.db.session() as s:
            statement = await self.ledger.statement(s, postings.vendor_account(uid), limit=30)
            payouts = (
                (
                    await s.execute(
                        select(VendorPayout)
                        .where(VendorPayout.vendor_id == uid)
                        .order_by(VendorPayout.requested_at.desc())
                        .limit(20)
                    )
                )
                .scalars()
                .all()
            )
        return {**summary, "transactions": statement, "payouts": [payout_view(p) for p in payouts]}

    async def request_seller_payout(
        self, principal: Principal, data: SellerPayoutInput, idempotency_key: str
    ) -> dict[str, Any]:
        if data.amount_kobo < MIN_SELLER_PAYOUT_KOBO:
            raise ValidationFailed(f"Minimum withdrawal is {format_naira(MIN_SELLER_PAYOUT_KOBO)}")
        key = f"{principal.uid}:{idempotency_key}"
        account = postings.vendor_account(principal.uid)
        async with self.db.transaction() as s:
            existing = await s.scalar(select(VendorPayout).where(VendorPayout.idempotency_key == key))
            if existing is not None:
                return payout_view(existing)
            await self.ledger.lock_account(s, account)
            balance = await self.ledger.balance(s, account)
            pending = await s.scalar(
                select(func.coalesce(func.sum(VendorPayout.amount_kobo), 0)).where(
                    VendorPayout.vendor_id == principal.uid, VendorPayout.status == "requested"
                )
            )
            available = balance - int(pending or 0)
            if data.amount_kobo > available:
                raise ValidationFailed(
                    "Amount is more than your available cash-on-delivery balance",
                    details={"available_kobo": max(0, available)},
                )
            row = VendorPayout(
                vendor_id=principal.uid,
                amount_kobo=data.amount_kobo,
                bank_name=data.bank_name.strip(),
                account_number=data.account_number,
                account_name=data.account_name.strip(),
                idempotency_key=key,
            )
            s.add(row)
            await s.flush()
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action="seller_payout.requested",
                resource_type="vendor_payout",
                resource_id=row.id,
                details={"amount_kobo": data.amount_kobo, "account": _mask(data.account_number)},
            )
            return payout_view(row)

    async def move_cod_to_wallet(
        self, principal: Principal, amount_kobo: int, idempotency_key: str
    ) -> dict[str, Any]:
        """Instant: COD money a seller is owed becomes spendable Yummy Chops wallet credit."""
        if not self.enabled:
            raise ValidationFailed("The Yummy Chops wallet is not available right now")
        uid = principal.uid
        vendor, wallet = postings.vendor_account(uid), postings.wallet_account(uid)
        async with self.db.transaction() as s:
            await self.ledger.lock_account(s, vendor)
            balance = await self.ledger.balance(s, vendor)
            pending = await s.scalar(
                select(func.coalesce(func.sum(VendorPayout.amount_kobo), 0)).where(
                    VendorPayout.vendor_id == uid, VendorPayout.status == "requested"
                )
            )
            available = balance - int(pending or 0)
            if amount_kobo <= 0 or amount_kobo > available:
                raise ValidationFailed(
                    "Amount is more than your available cash-on-delivery balance",
                    details={"available_kobo": max(0, available)},
                )
            await self.ledger.lock_account(s, wallet)
            wallet_balance = await self.ledger.balance(s, wallet)
            if wallet_balance + amount_kobo > self.max_balance:
                raise ValidationFailed(
                    f"Your wallet can hold up to {format_naira(self.max_balance)}",
                    details={"max_move_now_kobo": max(0, self.max_balance - wallet_balance)},
                )
            txn_id, created = await self.ledger.post(
                s,
                kind="vendor_to_wallet",
                idempotency_key=f"cod-to-wallet:{uid}:{idempotency_key}",
                postings=postings.vendor_to_wallet(uid, amount_kobo),
                created_by=uid,
                description="Moved from your cash-on-delivery balance",
            )
            new_balance = await self.ledger.balance(s, wallet)
        return {"transaction_id": txn_id, "moved": created, "wallet_balance_kobo": new_balance}

    # ------------------------------------------------------------------ finance
    async def list_seller_payouts(
        self, principal: Principal, status: str | None = None
    ) -> list[dict[str, Any]]:
        require(principal, Permission.PAYOUTS_APPROVE)
        stmt = select(VendorPayout).order_by(VendorPayout.requested_at.desc()).limit(300)
        if status:
            stmt = stmt.where(VendorPayout.status == status)
        async with self.db.session() as s:
            return [payout_view(p, full_account=True) for p in (await s.execute(stmt)).scalars()]

    async def decide_seller_payout(
        self,
        principal: Principal,
        payout_id: str,
        *,
        approve: bool,
        bank_reference: str | None,
        note: str | None,
    ) -> dict[str, Any]:
        require(principal, Permission.PAYOUTS_APPROVE)
        async with self.db.transaction() as s:
            row = await s.get(VendorPayout, payout_id, with_for_update=True)
            if row is None:
                raise NotFound("Payout not found")
            if row.status != "requested":
                raise ValidationFailed(f"Payout already {row.status}")
            row.decided_by = principal.uid
            row.decided_at = utcnow()
            row.decision_note = (note or "")[:1000] or None
            if approve:
                if not bank_reference or not bank_reference.strip():
                    raise ValidationFailed("A bank transfer reference is required to mark the payout as paid")
                account = postings.vendor_account(row.vendor_id)
                await self.ledger.lock_account(s, account)
                if row.amount_kobo > await self.ledger.balance(s, account):
                    raise ValidationFailed("Seller balance is insufficient")
                await self.ledger.post(
                    s,
                    kind="vendor_payout",
                    idempotency_key=f"vendor-payout:{row.id}",
                    postings=postings.payout_made("vendor", row.vendor_id, row.amount_kobo),
                    created_by=principal.uid,
                    reference=bank_reference.strip(),
                    description="Paid to your bank account",
                )
                row.status = "paid"
                row.reference = bank_reference.strip()
                row.paid_at = utcnow()
            else:
                row.status = "rejected"
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action=f"seller_payout.{row.status}",
                resource_type="vendor_payout",
                resource_id=row.id,
                details={"amount_kobo": row.amount_kobo, "reference": row.reference},
            )
            return payout_view(row, full_account=True)
