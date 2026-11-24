"""Split card payments: a business's share goes straight to its bank account

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-24 12:00:00

- payment_records.split_subaccount: the business's Paystack subaccount a card payment was split with (or NULL);
- payment_records.split_amount_kobo: how much of the payment went straight to that business (0 when not split).
  When the payment succeeds the ledger records that share as already paid to the business
  (docs/adr/0028-business-branches-and-split-payments.md).

Downgrade drops the two columns: the ledger keeps every posting they caused.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("payment_records", sa.Column("split_subaccount", sa.String(length=40), nullable=True))
    op.add_column(
        "payment_records",
        sa.Column("split_amount_kobo", sa.BigInteger(), nullable=False, server_default="0"),
    )
    op.create_check_constraint(
        "ck_payment_split",
        "payment_records",
        "split_amount_kobo >= 0 AND split_amount_kobo < amount_kobo",
    )


def downgrade() -> None:
    op.drop_constraint("ck_payment_split", "payment_records", type_="check")
    op.drop_column("payment_records", "split_amount_kobo")
    op.drop_column("payment_records", "split_subaccount")
