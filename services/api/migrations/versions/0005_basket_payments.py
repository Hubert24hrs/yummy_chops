"""Mixed cart: one payment for several orders

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-25 12:00:00

- payment_records.purpose also accepts 'basket': one gateway charge (or wallet debit) for several orders, one per
  shop (docs/adr/0030-mixed-cart-one-payment.md);
- payment_records.covers: the basket's orders and the amount of each (JSON, NULL for every other payment);
- payment_records.parent_id: on an order's own payment, the basket payment it is a share of (NULL otherwise).

Downgrade drops the two columns and the extra purpose; it refuses while basket payments exist (they would no longer
fit the constraint). The ledger keeps every posting they caused.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

JSONType = sa.JSON().with_variant(postgresql.JSONB(), "postgresql")


def upgrade() -> None:
    op.add_column("payment_records", sa.Column("covers", JSONType, nullable=True))
    op.add_column("payment_records", sa.Column("parent_id", sa.String(length=36), nullable=True))
    op.create_index("ix_payment_records_parent_id", "payment_records", ["parent_id"])
    op.drop_constraint("ck_payment_purpose", "payment_records", type_="check")
    op.create_check_constraint(
        "ck_payment_purpose",
        "payment_records",
        "purpose IN ('order','wallet_topup','plus','group_share','basket')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_payment_purpose", "payment_records", type_="check")
    op.create_check_constraint(
        "ck_payment_purpose", "payment_records", "purpose IN ('order','wallet_topup','plus','group_share')"
    )
    op.drop_index("ix_payment_records_parent_id", table_name="payment_records")
    op.drop_column("payment_records", "parent_id")
    op.drop_column("payment_records", "covers")
