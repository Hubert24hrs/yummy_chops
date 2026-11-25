"""Payment provider port. Adapters translate provider APIs into these provider-neutral types."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Literal, Protocol

from ..errors import PaymentProviderError

VerifyStatus = Literal["success", "failed", "abandoned", "pending", "reversed", "unknown"]


class ProviderOutcomeUnknown(PaymentProviderError):
    """The provider may have received the request but gave no usable answer (a timeout, a dropped connection, a
    server error): what was asked may or may not have happened, so the caller must not treat it as refused."""


@dataclass(frozen=True)
class InitializeResult:
    reference: str
    authorization_url: str
    access_code: str | None = None


@dataclass(frozen=True)
class SplitInstruction:
    """Send a business's share of a card payment straight to its own bank account through the provider (Paystack: a
    subaccount; docs/adr/0028-business-branches-and-split-payments.md). Yummy Chops keeps `platform_kobo` and bears
    the provider's fee; the business gets the rest of the amount."""

    subaccount: str
    platform_kobo: int


@dataclass(frozen=True)
class VerifyResult:
    reference: str
    status: VerifyStatus
    amount_kobo: int
    currency: str
    provider_transaction_id: str | None = None
    channel: str | None = None
    paid_at: datetime | None = None
    gateway_message: str | None = None
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class RefundResult:
    provider_refund_id: str | None
    status: Literal["pending", "processing", "processed", "failed"]
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class WebhookEvent:
    provider: str
    event_type: str  # normalised: charge.success | charge.failed | refund.processed | refund.failed | other
    dedupe_key: str
    reference: str | None
    raw_event: str
    data: dict[str, Any] = field(default_factory=dict)


class PaymentProvider(Protocol):
    name: str
    supports_split: bool  # can send a business's share straight to its account (SplitInstruction)

    async def initialize(
        self,
        *,
        reference: str,
        amount_kobo: int,
        email: str,
        currency: str,
        callback_url: str,
        metadata: Mapping[str, Any],
        customer_name: str | None = None,
        customer_phone: str | None = None,
        split: SplitInstruction | None = None,
    ) -> InitializeResult: ...

    async def verify(self, reference: str) -> VerifyResult: ...

    async def refund(
        self, *, reference: str, provider_transaction_id: str | None, amount_kobo: int
    ) -> RefundResult: ...

    def verify_webhook(self, raw_body: bytes, headers: Mapping[str, str], client_ip: str | None) -> bool: ...

    def parse_webhook(self, raw_body: bytes) -> WebhookEvent: ...
