"""PostgreSQL schema for money, idempotency, outbox and audit (SQLAlchemy 2.x).

The same metadata is used by Alembic migrations (production) and `create_all` (local/test, SQLite).
Append-only guarantees are enforced by database triggers for both dialects.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import (
    JSON,
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    event,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

JSONType = JSON().with_variant(JSONB(), "postgresql")


def new_id() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(UTC)


class Base(DeclarativeBase):
    pass


class FinancialAccount(Base):
    __tablename__ = "financial_accounts"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    code: Mapped[str] = mapped_column(String(160), unique=True, nullable=False)
    type: Mapped[str] = mapped_column(String(16), nullable=False)
    owner_type: Mapped[str | None] = mapped_column(String(32))
    owner_id: Mapped[str | None] = mapped_column(String(128))
    currency: Mapped[str] = mapped_column(String(3), default="NGN", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    __table_args__ = (
        CheckConstraint("type IN ('asset','liability','revenue','expense','equity')", name="ck_account_type"),
    )


class FinancialTransaction(Base):
    __tablename__ = "financial_transactions"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    kind: Mapped[str] = mapped_column(String(48), nullable=False)
    idempotency_key: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    reference: Mapped[str | None] = mapped_column(String(160), index=True)
    order_id: Mapped[str | None] = mapped_column(String(64), index=True)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    created_by: Mapped[str] = mapped_column(String(128), nullable=False)
    meta: Mapped[dict[str, Any]] = mapped_column("metadata", JSONType, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    transaction_id: Mapped[str] = mapped_column(ForeignKey("financial_transactions.id"), nullable=False)
    account_id: Mapped[str] = mapped_column(ForeignKey("financial_accounts.id"), nullable=False)
    direction: Mapped[str] = mapped_column(String(6), nullable=False)
    amount_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="NGN", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    __table_args__ = (
        CheckConstraint("amount_kobo > 0", name="ck_entry_positive"),
        CheckConstraint("direction IN ('debit','credit')", name="ck_entry_direction"),
        Index("ix_ledger_entries_account", "account_id", "created_at"),
        Index("ix_ledger_entries_txn", "transaction_id"),
    )


# Providers that are not payment gateways: the customer's Yummy Chops wallet and cash paid to the rider.
INTERNAL_PROVIDERS = ("wallet", "cash")


class PaymentRecord(Base):
    """Money a customer pays: for an order (gateway, wallet or cash on delivery), a share of a group order,
    a Yummy Chops Plus membership, or to top up their wallet."""

    __tablename__ = "payment_records"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    order_id: Mapped[str | None] = mapped_column(String(64), index=True)  # None: top-ups and Plus
    customer_id: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    purpose: Mapped[str] = mapped_column(String(16), nullable=False, default="order", server_default="order")
    provider: Mapped[str] = mapped_column(String(24), nullable=False)
    reference: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    amount_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    currency: Mapped[str] = mapped_column(String(3), default="NGN", nullable=False)
    status: Mapped[str] = mapped_column(String(24), nullable=False, default="initialized")
    authorization_url: Mapped[str | None] = mapped_column(Text)
    access_code: Mapped[str | None] = mapped_column(String(120))
    provider_transaction_id: Mapped[str | None] = mapped_column(String(120))
    channel: Mapped[str | None] = mapped_column(String(40))
    failure_reason: Mapped[str | None] = mapped_column(Text)
    refunded_kobo: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    # Split card payments (migration 0004): the share sent straight to a business's Paystack subaccount.
    split_subaccount: Mapped[str | None] = mapped_column(String(40))
    split_amount_kobo: Mapped[int] = mapped_column(BigInteger, default=0, server_default="0", nullable=False)
    idempotency_key: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    __table_args__ = (
        CheckConstraint("amount_kobo > 0", name="ck_payment_positive"),
        CheckConstraint(
            "status IN ('initialized','pending','succeeded','failed','abandoned','flagged')",
            name="ck_payment_status",
        ),
        CheckConstraint(
            "purpose IN ('order','wallet_topup','plus','group_share')", name="ck_payment_purpose"
        ),
        CheckConstraint(
            "purpose NOT IN ('order','group_share') OR order_id IS NOT NULL", name="ck_payment_order_ref"
        ),
        CheckConstraint(
            "split_amount_kobo >= 0 AND split_amount_kobo < amount_kobo", name="ck_payment_split"
        ),
        Index("ix_payment_records_status_created", "status", "created_at"),
    )


class PaymentEvent(Base):
    __tablename__ = "payment_events"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    payment_id: Mapped[str | None] = mapped_column(ForeignKey("payment_records.id"))
    provider: Mapped[str] = mapped_column(String(24), nullable=False)
    dedupe_key: Mapped[str] = mapped_column(String(200), nullable=False)
    event_type: Mapped[str] = mapped_column(String(64), nullable=False)
    source: Mapped[str] = mapped_column(String(24), nullable=False)  # webhook | verify | reconcile
    payload: Mapped[dict[str, Any]] = mapped_column(JSONType, default=dict, nullable=False)
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    __table_args__ = (UniqueConstraint("provider", "dedupe_key", name="uq_payment_event_dedupe"),)


class RefundRecord(Base):
    __tablename__ = "refund_records"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    payment_id: Mapped[str] = mapped_column(ForeignKey("payment_records.id"), nullable=False)
    order_id: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    amount_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    liability: Mapped[str] = mapped_column(String(16), nullable=False)  # restaurant | platform
    stage: Mapped[str] = mapped_column(String(24), nullable=False)  # before_completion | after_completion
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="requested")
    requested_by: Mapped[str] = mapped_column(String(128), nullable=False)
    decided_by: Mapped[str | None] = mapped_column(String(128))
    decision_note: Mapped[str | None] = mapped_column(Text)
    provider_refund_id: Mapped[str | None] = mapped_column(String(120))
    # original = back to the card/bank/provider; wallet = instantly into the customer's Yummy Chops wallet
    destination: Mapped[str] = mapped_column(
        String(16), nullable=False, default="original", server_default="original"
    )
    idempotency_key: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    __table_args__ = (
        CheckConstraint("amount_kobo > 0", name="ck_refund_positive"),
        CheckConstraint("destination IN ('original','wallet')", name="ck_refund_destination"),
        CheckConstraint(
            "status IN ('requested','approved','processing','succeeded','failed','rejected')",
            name="ck_refund_status",
        ),
        CheckConstraint("liability IN ('restaurant','platform')", name="ck_refund_liability"),
    )


class CommissionRecord(Base):
    __tablename__ = "commission_records"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    order_id: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    restaurant_id: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    base_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    commission_bps: Mapped[int] = mapped_column(Integer, nullable=False)
    commission_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)


class RestaurantSettlement(Base):
    __tablename__ = "restaurant_settlements"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    restaurant_id: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    orders_count: Mapped[int] = mapped_column(Integer, nullable=False)
    gross_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    commission_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    adjustments_kobo: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    net_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="pending")
    payout_reference: Mapped[str | None] = mapped_column(String(120))
    approved_by: Mapped[str | None] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    __table_args__ = (
        UniqueConstraint("restaurant_id", "period_start", "period_end", name="uq_settlement_period"),
        CheckConstraint("status IN ('pending','approved','paid','failed')", name="ck_settlement_status"),
    )


class RiderPayout(Base):
    __tablename__ = "rider_payouts"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    rider_id: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    amount_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="requested")
    idempotency_key: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    decided_by: Mapped[str | None] = mapped_column(String(128))
    reference: Mapped[str | None] = mapped_column(String(120))
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    __table_args__ = (
        CheckConstraint("amount_kobo > 0", name="ck_payout_positive"),
        CheckConstraint(
            "status IN ('requested','approved','paid','rejected','failed')", name="ck_payout_status"
        ),
    )


class VendorPayout(Base):
    """A seller's request to withdraw cash-on-delivery money collected for them (reviewed by finance)."""

    __tablename__ = "vendor_payouts"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    vendor_id: Mapped[str] = mapped_column(String(128), index=True, nullable=False)
    amount_kobo: Mapped[int] = mapped_column(BigInteger, nullable=False)
    bank_name: Mapped[str] = mapped_column(String(80), nullable=False)
    account_number: Mapped[str] = mapped_column(String(10), nullable=False)
    account_name: Mapped[str] = mapped_column(String(120), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="requested")
    idempotency_key: Mapped[str] = mapped_column(String(200), unique=True, nullable=False)
    decided_by: Mapped[str | None] = mapped_column(String(128))
    decision_note: Mapped[str | None] = mapped_column(Text)
    reference: Mapped[str | None] = mapped_column(String(120))
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    __table_args__ = (
        CheckConstraint("amount_kobo > 0", name="ck_vendor_payout_positive"),
        CheckConstraint("status IN ('requested','paid','rejected')", name="ck_vendor_payout_status"),
    )


class IdempotencyRecord(Base):
    __tablename__ = "idempotency_records"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    scope: Mapped[str] = mapped_column(String(120), nullable=False)
    key: Mapped[str] = mapped_column(String(200), nullable=False)
    request_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="in_progress")
    response_status: Mapped[int | None] = mapped_column(Integer)
    response_body: Mapped[Any | None] = mapped_column(JSONType)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    __table_args__ = (
        UniqueConstraint("scope", "key", name="uq_idempotency_scope_key"),
        Index("ix_idempotency_expires", "expires_at"),
    )


class OutboxEvent(Base):
    __tablename__ = "outbox_events"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    topic: Mapped[str] = mapped_column(String(80), nullable=False)
    payload: Mapped[dict[str, Any]] = mapped_column(JSONType, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    claimed_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_error: Mapped[str | None] = mapped_column(Text)
    __table_args__ = (Index("ix_outbox_unpublished", "published_at", "created_at"),)


class AuditEvent(Base):
    __tablename__ = "audit_events"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, nullable=False)
    actor_id: Mapped[str] = mapped_column(String(128), nullable=False)
    actor_roles: Mapped[list[str]] = mapped_column(JSONType, default=list, nullable=False)
    action: Mapped[str] = mapped_column(String(80), nullable=False)
    resource_type: Mapped[str] = mapped_column(String(48), nullable=False)
    resource_id: Mapped[str] = mapped_column(String(128), nullable=False)
    details: Mapped[dict[str, Any]] = mapped_column(JSONType, default=dict, nullable=False)
    request_id: Mapped[str | None] = mapped_column(String(64))
    __table_args__ = (
        Index("ix_audit_resource", "resource_type", "resource_id"),
        Index("ix_audit_actor_time", "actor_id", "occurred_at"),
        Index("ix_audit_time", "occurred_at"),
    )


# ------------------------------------------------------------------------------------------------
# Append-only & balance enforcement (database level)
# ------------------------------------------------------------------------------------------------

APPEND_ONLY_TABLES = ("financial_transactions", "ledger_entries", "audit_events", "commission_records")

PG_FUNCTIONS = [
    """
    CREATE OR REPLACE FUNCTION gm_forbid_mutation() RETURNS trigger AS $$
    BEGIN
      RAISE EXCEPTION 'table % is append-only', TG_TABLE_NAME USING ERRCODE = 'check_violation';
    END;
    $$ LANGUAGE plpgsql;
    """,
    """
    CREATE OR REPLACE FUNCTION gm_check_transaction_balanced() RETURNS trigger AS $$
    DECLARE
      net bigint;
    BEGIN
      SELECT COALESCE(SUM(CASE WHEN direction = 'debit' THEN amount_kobo ELSE -amount_kobo END), 0)
        INTO net FROM ledger_entries WHERE transaction_id = NEW.transaction_id;
      IF net <> 0 THEN
        RAISE EXCEPTION 'financial transaction % is unbalanced by %', NEW.transaction_id, net
          USING ERRCODE = 'check_violation';
      END IF;
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """,
]


def pg_trigger_statements() -> list[str]:
    stmts = list(PG_FUNCTIONS)
    for table in APPEND_ONLY_TABLES:
        stmts.append(
            f"CREATE TRIGGER {table}_append_only BEFORE UPDATE OR DELETE ON {table} "
            f"FOR EACH ROW EXECUTE FUNCTION gm_forbid_mutation();"
        )
    stmts.append(
        "CREATE CONSTRAINT TRIGGER ledger_entries_balanced AFTER INSERT ON ledger_entries "
        "DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION gm_check_transaction_balanced();"
    )
    return stmts


def sqlite_trigger_statements() -> list[str]:
    stmts = []
    for table in APPEND_ONLY_TABLES:
        for op in ("UPDATE", "DELETE"):
            stmts.append(
                f"CREATE TRIGGER IF NOT EXISTS {table}_no_{op.lower()} BEFORE {op} ON {table} "
                f"BEGIN SELECT RAISE(ABORT, 'table {table} is append-only'); END;"
            )
    return stmts


@event.listens_for(Base.metadata, "after_create")
def _install_triggers(target: Any, connection: Any, **_: Any) -> None:
    dialect = connection.dialect.name
    statements = (
        pg_trigger_statements()
        if dialect == "postgresql"
        else sqlite_trigger_statements()
        if dialect == "sqlite"
        else []
    )
    for stmt in statements:
        connection.exec_driver_sql(stmt)  # raw: plpgsql bodies contain literal %
