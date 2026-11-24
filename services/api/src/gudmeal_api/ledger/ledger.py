"""Double-entry ledger service and posting builders.

Every business money movement is a `FinancialTransaction` with ≥2 `LedgerEntry` rows whose debits equal
credits. Postings are idempotent by key, so retries (webhooks, events, jobs) never double-post.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, Literal

from sqlalchemy import case, func, select
from sqlalchemy.dialects import postgresql, sqlite
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..domain.models import Order
from .tables import FinancialAccount, FinancialTransaction, LedgerEntry, new_id

Direction = Literal["debit", "credit"]

ACCOUNT_TYPE_BY_PREFIX = {
    "cash": "asset",
    "receivable": "asset",
    "liability": "liability",
    "revenue": "revenue",
    "expense": "expense",
    "equity": "equity",
}
DEBIT_NORMAL = {"asset", "expense"}


class LedgerError(ValueError):
    pass


@dataclass(frozen=True, slots=True)
class Posting:
    account: str
    direction: Direction
    amount_kobo: int


def account_type(code: str) -> str:
    prefix = code.split(":", 1)[0]
    try:
        return ACCOUNT_TYPE_BY_PREFIX[prefix]
    except KeyError as exc:
        raise LedgerError(f"Unknown account prefix in {code!r}") from exc


# Accounts that belong to one person or business: (prefix, kind) -> owner_type = kind, owner_id = 3rd part.
OWNED_ACCOUNTS = {
    ("liability", "restaurant"),  # owed to a merchant
    ("liability", "rider"),  # owed to a rider (delivery pay)
    ("liability", "wallet"),  # a customer's Yummy Chops wallet (closed-loop stored value)
    ("liability", "vendor"),  # cash-on-delivery money collected for a seller
    ("receivable", "rider_cash"),  # cash a rider collected at the door and still has to hand in
    ("liability", "carrier"),  # owed to a line-haul carrier for interstate waybills
}


def wallet_account(uid: str) -> str:
    return f"liability:wallet:{uid}"


def vendor_account(uid: str) -> str:
    return f"liability:vendor:{uid}"


def rider_account(uid: str) -> str:
    return f"liability:rider:{uid}"


def rider_cash_account(uid: str) -> str:
    return f"receivable:rider_cash:{uid}"


def carrier_account(carrier_id: str) -> str:
    return f"liability:carrier:{carrier_id}"


def _owner(code: str) -> tuple[str | None, str | None]:
    parts = code.split(":")
    if len(parts) == 3 and (parts[0], parts[1]) in OWNED_ACCOUNTS and parts[2]:
        return parts[1], parts[2]
    return None, None


def validate_postings(postings: Sequence[Posting]) -> None:
    if len(postings) < 2:
        raise LedgerError("A transaction needs at least two entries")
    debit = credit = 0
    for p in postings:
        if not isinstance(p.amount_kobo, int) or isinstance(p.amount_kobo, bool) or p.amount_kobo <= 0:
            raise LedgerError(f"Entry amounts must be positive integers (got {p.amount_kobo!r})")
        account_type(p.account)
        if p.direction == "debit":
            debit += p.amount_kobo
        elif p.direction == "credit":
            credit += p.amount_kobo
        else:
            raise LedgerError(f"Invalid direction {p.direction!r}")
    if debit != credit:
        raise LedgerError(f"Unbalanced transaction: debits {debit} != credits {credit}")


def net(postings: Sequence[Posting]) -> list[Posting]:
    """Merge postings per account/direction and drop zero amounts (helper for builders)."""
    merged: dict[tuple[str, str], int] = {}
    for p in postings:
        if p.amount_kobo == 0:
            continue
        merged[(p.account, p.direction)] = merged.get((p.account, p.direction), 0) + p.amount_kobo
    return [Posting(a, d, amt) for (a, d), amt in merged.items()]  # type: ignore[arg-type]


# ------------------------------------------------------------------------------------------------
# Posting builders (pure)
# ------------------------------------------------------------------------------------------------


def payment_captured(provider: str, amount_kobo: int) -> list[Posting]:
    return [
        Posting(f"cash:{provider}", "debit", amount_kobo),
        Posting("liability:customer_funds", "credit", amount_kobo),
    ]


def split_settled(provider: str, restaurant_id: str, amount_kobo: int) -> list[Posting]:
    """A split card payment: the provider sent the business's share straight to its bank account, so the business has
    been paid that much already (like a payout made through the provider). When the order completes its earning is
    credited and the two cancel out; if the order is refunded first, the business owes its share back
    (docs/adr/0028-business-branches-and-split-payments.md)."""
    return [
        Posting(f"liability:restaurant:{restaurant_id}", "debit", amount_kobo),
        Posting(f"cash:{provider}", "credit", amount_kobo),
    ]


def order_completed(order: Order) -> list[Posting]:
    """Recognise revenue and payables when an order completes (see docs/architecture/payments-and-ledger.md)."""
    b, s = order.breakdown, order.settlement
    total = b.total_kobo
    delivery_margin = b.delivery_fee_kobo - s.rider_pay_kobo
    postings = [
        Posting("liability:customer_funds", "debit", total),
        Posting("expense:promotions", "debit", s.platform_funded_discount_kobo),
        Posting(f"liability:restaurant:{order.restaurant_id}", "credit", s.restaurant_earning_kobo),
        Posting("liability:vat", "credit", b.vat_kobo),
        Posting("revenue:commission", "credit", s.commission_kobo),
        Posting("revenue:service_fee", "credit", b.service_fee_kobo + b.small_order_fee_kobo),
        Posting("revenue:cod_fee", "credit", b.cod_fee_kobo),
    ]
    if order.rider_id and s.rider_pay_kobo:
        postings.append(Posting(f"liability:rider:{order.rider_id}", "credit", s.rider_pay_kobo))
    else:
        delivery_margin = b.delivery_fee_kobo  # no rider (pickup) → nothing owed for delivery
    if delivery_margin >= 0:
        postings.append(Posting("revenue:delivery", "credit", delivery_margin))
    else:
        postings.append(Posting("expense:delivery_subsidy", "debit", -delivery_margin))
    result = net(postings)
    validate_postings(result)
    return result


def refund_issued(
    *,
    provider: str,
    amount_kobo: int,
    stage: Literal["before_completion", "after_completion"],
    liability: Literal["restaurant", "platform"],
    restaurant_id: str,
    to_wallet_of: str | None = None,
) -> list[Posting]:
    """Refund to the original payment method (cash leaves the provider) or into the customer's wallet."""
    if stage == "before_completion":
        debit_account = "liability:customer_funds"
    elif liability == "restaurant":
        debit_account = f"liability:restaurant:{restaurant_id}"
    else:
        debit_account = "expense:refunds"
    credit_account = wallet_account(to_wallet_of) if to_wallet_of else f"cash:{provider}"
    return [Posting(debit_account, "debit", amount_kobo), Posting(credit_account, "credit", amount_kobo)]


def payout_made(
    owner_type: Literal["restaurant", "rider", "vendor", "carrier"], owner_id: str, amount_kobo: int
) -> list[Posting]:
    return [
        Posting(f"liability:{owner_type}:{owner_id}", "debit", amount_kobo),
        Posting("cash:bank", "credit", amount_kobo),
    ]


def waybill_completed(order: Order) -> list[Posting]:
    """Recognise an interstate shipment when it is delivered: all fees (net of VAT and the COD fee) are waybill
    revenue, and the carrier's share of the line haul becomes an expense owed to the carrier. Riders who did the
    first and last mile were paid from their own legs (`leg_rider_pay`) when those finished."""
    if order.waybill is None:
        raise LedgerError("Not a waybill order")
    b, s = order.breakdown, order.settlement
    postings = net(
        [
            Posting("liability:customer_funds", "debit", b.total_kobo),
            Posting("liability:vat", "credit", b.vat_kobo),
            Posting("revenue:cod_fee", "credit", b.cod_fee_kobo),
            Posting("revenue:waybill", "credit", b.total_kobo - b.vat_kobo - b.cod_fee_kobo),
            Posting("expense:linehaul", "debit", s.carrier_cost_kobo),
            Posting(carrier_account(order.waybill.carrier_id), "credit", s.carrier_cost_kobo),
        ]
    )
    validate_postings(postings)
    return postings


def leg_rider_pay(rider_id: str, amount_kobo: int) -> list[Posting]:
    """A rider finished a waybill's first- or last-mile leg: their pay is a cost of the shipment."""
    return [
        Posting("expense:waybill_riders", "debit", amount_kobo),
        Posting(rider_account(rider_id), "credit", amount_kobo),
    ]


def wallet_topup(provider: str, uid: str, amount_kobo: int) -> list[Posting]:
    """A customer adds money to their wallet through a payment provider."""
    return [
        Posting(f"cash:{provider}", "debit", amount_kobo),
        Posting(wallet_account(uid), "credit", amount_kobo),
    ]


def wallet_payment(uid: str, amount_kobo: int) -> list[Posting]:
    """A customer pays for an order from their wallet: stored value becomes funds held for the order."""
    return [
        Posting(wallet_account(uid), "debit", amount_kobo),
        Posting("liability:customer_funds", "credit", amount_kobo),
    ]


def plus_paid(source_account: str, amount_kobo: int, vat_kobo: int) -> list[Posting]:
    """Yummy Chops Plus paid (price includes VAT) from a gateway (`cash:<provider>`) or a wallet."""
    postings = net(
        [
            Posting(source_account, "debit", amount_kobo),
            Posting("revenue:plus", "credit", amount_kobo - vat_kobo),
            Posting("liability:vat", "credit", vat_kobo),
        ]
    )
    validate_postings(postings)
    return postings


def cash_collected(rider_id: str, amount_kobo: int) -> list[Posting]:
    """Pay on delivery: the rider took the order total in cash, which they now owe the platform."""
    return [
        Posting(rider_cash_account(rider_id), "debit", amount_kobo),
        Posting("liability:customer_funds", "credit", amount_kobo),
    ]


def cod_collected(rider_id: str, vendor_id: str, amount_kobo: int) -> list[Posting]:
    """Vendor cash-on-delivery: the rider took the item price from the recipient; it is owed to the seller."""
    return [
        Posting(rider_cash_account(rider_id), "debit", amount_kobo),
        Posting(vendor_account(vendor_id), "credit", amount_kobo),
    ]


def rider_cash_remitted(
    rider_id: str, amount_kobo: int, method: Literal["bank_transfer", "cash_deposit", "earnings_offset"]
) -> list[Posting]:
    """A rider hands in collected cash (paid into the bank) or it is deducted from what we owe them."""
    debit = rider_account(rider_id) if method == "earnings_offset" else "cash:bank"
    return [
        Posting(debit, "debit", amount_kobo),
        Posting(rider_cash_account(rider_id), "credit", amount_kobo),
    ]


def vendor_to_wallet(uid: str, amount_kobo: int) -> list[Posting]:
    """A seller moves cash-on-delivery money into their own Yummy Chops wallet (instant, no bank transfer)."""
    return [
        Posting(vendor_account(uid), "debit", amount_kobo),
        Posting(wallet_account(uid), "credit", amount_kobo),
    ]


# ------------------------------------------------------------------------------------------------
# Service
# ------------------------------------------------------------------------------------------------


class LedgerService:
    async def _ensure_accounts(self, session: AsyncSession, codes: set[str]) -> dict[str, str]:
        existing = {
            row.code: row.id
            for row in (
                await session.execute(select(FinancialAccount).where(FinancialAccount.code.in_(codes)))
            ).scalars()
        }
        missing = codes - existing.keys()
        if missing:
            dialect = session.bind.dialect.name if session.bind else "postgresql"
            insert_fn = postgresql.insert if dialect == "postgresql" else sqlite.insert
            rows = []
            for code in sorted(missing):
                owner_type, owner_id = _owner(code)
                rows.append(
                    {
                        "id": new_id(),
                        "code": code,
                        "type": account_type(code),
                        "owner_type": owner_type,
                        "owner_id": owner_id,
                        "currency": "NGN",
                        "is_active": True,
                    }
                )
            stmt = insert_fn(FinancialAccount).values(rows).on_conflict_do_nothing(index_elements=["code"])
            await session.execute(stmt)
            existing.update(
                {
                    row.code: row.id
                    for row in (
                        await session.execute(
                            select(FinancialAccount).where(FinancialAccount.code.in_(missing))
                        )
                    ).scalars()
                }
            )
        return existing

    async def post(
        self,
        session: AsyncSession,
        *,
        kind: str,
        idempotency_key: str,
        postings: Sequence[Posting],
        created_by: str,
        reference: str | None = None,
        order_id: str | None = None,
        description: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> tuple[str, bool]:
        """Post a balanced transaction. Returns (transaction_id, created). Idempotent by key."""
        validate_postings(postings)
        existing = await session.scalar(
            select(FinancialTransaction.id).where(FinancialTransaction.idempotency_key == idempotency_key)
        )
        if existing:
            return existing, False
        accounts = await self._ensure_accounts(session, {p.account for p in postings})
        txn_id = new_id()
        try:
            async with session.begin_nested():
                session.add(
                    FinancialTransaction(
                        id=txn_id,
                        kind=kind,
                        idempotency_key=idempotency_key,
                        reference=reference,
                        order_id=order_id,
                        description=description,
                        created_by=created_by,
                        meta=metadata or {},
                    )
                )
                await session.flush()
                session.add_all(
                    LedgerEntry(
                        transaction_id=txn_id,
                        account_id=accounts[p.account],
                        direction=p.direction,
                        amount_kobo=p.amount_kobo,
                    )
                    for p in postings
                )
                await session.flush()
        except IntegrityError:
            existing = await session.scalar(
                select(FinancialTransaction.id).where(FinancialTransaction.idempotency_key == idempotency_key)
            )
            if existing:
                return existing, False
            raise
        return txn_id, True

    async def lock_account(self, session: AsyncSession, code: str) -> None:
        """Serialise money movements on one account (row lock on PostgreSQL; SQLite locks the database)."""
        await self._ensure_accounts(session, {code})
        await session.execute(
            select(FinancialAccount.id).where(FinancialAccount.code == code).with_for_update()
        )

    async def statement(self, session: AsyncSession, code: str, limit: int = 50) -> list[dict[str, Any]]:
        """Latest entries on one account, newest first, as money in or out for the account's owner."""
        acct = await session.scalar(select(FinancialAccount).where(FinancialAccount.code == code))
        if acct is None:
            return []
        stmt = (
            select(
                FinancialTransaction.id,
                FinancialTransaction.kind,
                FinancialTransaction.reference,
                FinancialTransaction.order_id,
                FinancialTransaction.description,
                FinancialTransaction.created_at,
                LedgerEntry.direction,
                LedgerEntry.amount_kobo,
            )
            .join(LedgerEntry, LedgerEntry.transaction_id == FinancialTransaction.id)
            .where(LedgerEntry.account_id == acct.id)
            .order_by(FinancialTransaction.created_at.desc(), FinancialTransaction.id)
            .limit(min(limit, 200))
        )
        increases = "debit" if acct.type in DEBIT_NORMAL else "credit"
        rows = (await session.execute(stmt)).all()
        return [
            {
                "id": txn_id,
                "kind": kind,
                "reference": reference,
                "order_id": order_id,
                "description": description,
                "created_at": created_at,
                "direction": "in" if direction == increases else "out",
                "amount_kobo": int(amount),
            }
            for txn_id, kind, reference, order_id, description, created_at, direction, amount in rows
        ]

    async def balance(self, session: AsyncSession, code: str) -> int:
        acct = await session.scalar(select(FinancialAccount).where(FinancialAccount.code == code))
        if acct is None:
            return 0
        signed = case(
            (LedgerEntry.direction == "debit", LedgerEntry.amount_kobo), else_=-LedgerEntry.amount_kobo
        )
        total = await session.scalar(
            select(func.coalesce(func.sum(signed), 0)).where(LedgerEntry.account_id == acct.id)
        )
        total = int(total or 0)
        return total if acct.type in DEBIT_NORMAL else -total

    async def balances(self, session: AsyncSession, prefix: str | None = None) -> list[dict[str, Any]]:
        signed = case(
            (LedgerEntry.direction == "debit", LedgerEntry.amount_kobo), else_=-LedgerEntry.amount_kobo
        )
        stmt = (
            select(FinancialAccount.code, FinancialAccount.type, func.coalesce(func.sum(signed), 0))
            .join(LedgerEntry, LedgerEntry.account_id == FinancialAccount.id, isouter=True)
            .group_by(FinancialAccount.code, FinancialAccount.type)
            .order_by(FinancialAccount.code)
        )
        if prefix:
            stmt = stmt.where(FinancialAccount.code.like(f"{prefix}%"))
        out = []
        for code, typ, raw in (await session.execute(stmt)).all():
            raw = int(raw or 0)
            out.append({"account": code, "type": typ, "balance_kobo": raw if typ in DEBIT_NORMAL else -raw})
        return out

    async def trial_balance(self, session: AsyncSession) -> dict[str, int]:
        debit = await session.scalar(
            select(func.coalesce(func.sum(LedgerEntry.amount_kobo), 0)).where(
                LedgerEntry.direction == "debit"
            )
        )
        credit = await session.scalar(
            select(func.coalesce(func.sum(LedgerEntry.amount_kobo), 0)).where(
                LedgerEntry.direction == "credit"
            )
        )
        return {"debits_kobo": int(debit or 0), "credits_kobo": int(credit or 0)}

    async def entries_for_order(self, session: AsyncSession, order_id: str) -> list[dict[str, Any]]:
        stmt = (
            select(
                FinancialTransaction.kind,
                FinancialAccount.code,
                LedgerEntry.direction,
                LedgerEntry.amount_kobo,
            )
            .join(LedgerEntry, LedgerEntry.transaction_id == FinancialTransaction.id)
            .join(FinancialAccount, FinancialAccount.id == LedgerEntry.account_id)
            .where(FinancialTransaction.order_id == order_id)
            .order_by(FinancialTransaction.created_at)
        )
        return [
            {"kind": k, "account": a, "direction": d, "amount_kobo": int(amt)}
            for k, a, d, amt in (await session.execute(stmt)).all()
        ]
