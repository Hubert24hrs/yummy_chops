"""Growth features (phase 4, ADR-0016): Yummy Chops Plus, Yummy points and referrals, group orders.

Pure models and helpers, no I/O. Money stays in integer kobo; prices, savings and bill shares come only from
`pricing.py`. Points are not money: they turn into platform-funded personal vouchers when redeemed.
"""

from __future__ import annotations

import secrets
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from .models import CartLine, DeliveryAddress, Fulfillment, Model

CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"  # no 0/O or 1/I/L: easy to read out and type
REFERRAL_PATTERN = r"^[A-Z0-9]{5,12}$"
GROUP_CODE_PATTERN = r"^[2-9A-HJ-NP-Z]{6}$"


# ------------------------------------------------------------------------------------------- settings
class PlusConfig(BaseModel):
    """Yummy Chops Plus membership. Product defaults, to be confirmed by the owner (ADR-0016)."""

    enabled: bool = True
    price_kobo: int = Field(default=150_000, gt=0, le=10_000_000)  # ₦1,500 per period, VAT included
    period_days: int = Field(default=30, ge=1, le=366)
    free_delivery_min_subtotal_kobo: int = Field(default=300_000, ge=0)  # ₦3,000
    service_fee_discount_bps: int = Field(default=5_000, ge=0, le=10_000)  # 50% off the service fee
    verticals: list[str] = Field(
        default_factory=lambda: ["food", "beauty", "grocery", "pharmacy", "market"], max_length=10
    )
    points_multiplier: int = Field(default=2, ge=1, le=10)  # Yummy points earned by members
    renew_window_hours: int = Field(default=24, ge=1, le=168)  # wallet auto-renewal starts this early


class GrowthConfig(BaseModel):
    """Yummy points, referrals and group orders (`platform_configuration/growth`)."""

    version: int = 1
    # Yummy points: earned on completed orders, redeemed for personal vouchers.
    points_enabled: bool = True
    points_per_100_naira: int = Field(default=1, ge=0, le=100)
    point_value_kobo: int = Field(default=100, ge=1, le=10_000)  # 1 point = ₦1 when redeemed
    redeem_step_points: int = Field(default=500, ge=1, le=1_000_000)
    redeem_min_subtotal_kobo: int = Field(default=200_000, ge=0)  # ₦2,000
    redeem_valid_days: int = Field(default=90, ge=1, le=730)
    # Referrals: a voucher for the new customer at once, one for the friend after the first completed order.
    referrals_enabled: bool = True
    referee_reward_kobo: int = Field(default=100_000, ge=0, le=10_000_000)  # ₦1,000
    referee_min_subtotal_kobo: int = Field(default=300_000, ge=0)  # ₦3,000
    referrer_reward_kobo: int = Field(default=100_000, ge=0, le=10_000_000)  # ₦1,000
    referrer_monthly_cap: int = Field(default=10, ge=0, le=1_000)
    referral_valid_days: int = Field(default=30, ge=1, le=365)
    # Group orders
    group_orders_enabled: bool = True
    group_max_members: int = Field(default=10, ge=2, le=30)  # including the host
    group_open_hours: int = Field(default=3, ge=1, le=48)


# ------------------------------------------------------------------------------------------- Plus
class Membership(Model):
    """`memberships/{uid}`. Benefits apply while `paid_through` is in the future."""

    uid: str
    member_since: datetime
    paid_through: datetime
    periods: int = 0
    auto_renew: bool = True
    last_payment_reference: str | None = None
    last_price_kobo: int = 0
    reminder_for: datetime | None = None  # the paid_through date a low-balance reminder was sent for
    cancelled_at: datetime | None = None
    updated_at: datetime


def membership_active(m: Membership | None, now: datetime) -> bool:
    return m is not None and m.paid_through > now


# ------------------------------------------------------------------------------------------- rewards
class RewardsAccount(Model):
    """`loyalty_accounts/{uid}`: Yummy points balance and referral state (points are not money)."""

    uid: str
    points: int = 0  # may go below zero when a refund reverses points that were already redeemed
    lifetime_points: int = 0
    referral_code: str | None = None
    referred_by: str | None = None
    referred_at: datetime | None = None
    referral_rewarded: bool = False  # the friend who referred this customer has been rewarded
    referrals_rewarded: int = 0  # friends of this customer who completed a first order
    month_key: str | None = None  # "2026-11": month of `month_rewards`, for the monthly cap
    month_rewards: int = 0
    updated_at: datetime | None = None


PointsKind = Literal["earned", "redeemed", "reversed"]


class PointsEntry(Model):
    """`loyalty_accounts/{uid}/entries/{id}` — append-only; deterministic ids make each event count once."""

    id: str
    kind: PointsKind
    points: int  # signed
    order_id: str | None = None
    voucher_code: str | None = None
    note: str = ""
    at: datetime


def points_for(amount_kobo: int, cfg: GrowthConfig, multiplier: int = 1) -> int:
    """Points for a completed order: `points_per_100_naira` for every full ₦100, times the Plus multiplier."""
    if amount_kobo <= 0 or not cfg.points_enabled:
        return 0
    return (amount_kobo // 10_000) * cfg.points_per_100_naira * multiplier


def new_code(length: int) -> str:
    return "".join(secrets.choice(CODE_ALPHABET) for _ in range(length))


def referral_code_for(name: str | None) -> str:
    """Friendly referral code: up to four letters of the customer's name, then four random characters."""
    letters = "".join(ch for ch in (name or "").upper() if "A" <= ch <= "Z")[:4]
    return (letters if len(letters) >= 2 else "GUD") + new_code(4)


def normalise_code(code: str) -> str:
    return "".join(ch for ch in code.upper() if ch.isalnum())


# ------------------------------------------------------------------------------------------- group orders
GroupStatus = Literal["open", "locked", "ordered", "cancelled", "expired"]
SplitMode = Literal["host", "each"]  # the host pays everything, or everyone pays their own share


class GroupMember(Model):
    uid: str
    name: str = Field(max_length=80)
    joined_at: datetime
    ready: bool = False


class GroupLine(CartLine):
    id: str
    member_uid: str


class GroupShare(Model):
    uid: str
    name: str
    items_kobo: int
    amount_kobo: int
    status: Literal["unpaid", "paid"] = "unpaid"
    paid_by: str | None = None  # the member, or the host when they paid the rest
    payment_reference: str | None = None
    paid_at: datetime | None = None


class GroupOrder(Model):
    """`group_orders/{id}`: a shared cart at one Food or Beauty store, checked out as one order."""

    id: str
    code: str
    host_uid: str
    host_name: str
    restaurant_id: str
    restaurant_name: str
    vertical: str
    fulfillment: Fulfillment = Fulfillment.DELIVERY
    delivery_address: DeliveryAddress | None = None
    split_mode: SplitMode = "each"
    status: GroupStatus = "open"
    members: list[GroupMember] = Field(default_factory=list, max_length=30)
    member_uids: list[str] = Field(default_factory=list, max_length=30)  # for "my group orders" queries
    lines: list[GroupLine] = Field(default_factory=list, max_length=50)
    order_id: str | None = None
    total_kobo: int = 0
    shares: list[GroupShare] = Field(default_factory=list, max_length=30)
    cancel_reason: str | None = None
    created_at: datetime
    updated_at: datetime
    expires_at: datetime

    def member(self, uid: str) -> GroupMember | None:
        return next((m for m in self.members if m.uid == uid), None)

    def share(self, uid: str) -> GroupShare | None:
        return next((s for s in self.shares if s.uid == uid), None)


__all__ = [
    "CODE_ALPHABET",
    "GROUP_CODE_PATTERN",
    "REFERRAL_PATTERN",
    "GroupLine",
    "GroupMember",
    "GroupOrder",
    "GroupShare",
    "GrowthConfig",
    "Membership",
    "PlusConfig",
    "PointsEntry",
    "RewardsAccount",
    "membership_active",
    "new_code",
    "normalise_code",
    "points_for",
    "referral_code_for",
]
