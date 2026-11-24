"""Local payment sandbox — a test double for offline development and automated tests.

It mimics a hosted checkout: `initialize` returns a URL served by this API (`/v1/dev/sandbox-checkout/...`),
the page lets a developer approve or decline, and approval delivers an HMAC-signed webhook through the
same verification → ledger → order pipeline as Paystack. It can only be constructed when
ENVIRONMENT is `local` or `test` (enforced in the container), so it can never handle real money.
"""

from __future__ import annotations

import hashlib
import hmac
import json
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from ..errors import NotFound
from .base import InitializeResult, RefundResult, SplitInstruction, VerifyResult, WebhookEvent


@dataclass
class _SandboxCharge:
    reference: str
    amount_kobo: int
    currency: str
    callback_url: str
    status: str = "pending"
    paid_at: datetime | None = None


class LocalSandboxProvider:
    name = "local_sandbox"
    supports_split = True  # stands in for Paystack, splits included (nothing really moves)

    def __init__(self, *, public_base_url: str | Callable[[], str], signing_secret: str) -> None:
        # A function is asked again for every checkout: in a phone test this computer's address changes with
        # the Wi-Fi it joins, and the page must open at the address the computer has now.
        self._base_url: Callable[[], str] = (
            public_base_url if callable(public_base_url) else lambda: public_base_url
        )
        self._secret = signing_secret
        self.charges: dict[str, _SandboxCharge] = {}
        self.refunds: list[dict[str, Any]] = []

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
    ) -> InitializeResult:
        self.charges[reference] = _SandboxCharge(reference, amount_kobo, currency, callback_url)
        return InitializeResult(
            reference=reference,
            authorization_url=f"{self._base_url().rstrip('/')}/v1/dev/sandbox-checkout/{reference}",
        )

    def complete(self, reference: str, *, success: bool) -> tuple[bytes, str, str]:
        """Simulate the customer finishing checkout. Returns (webhook_body, signature, callback_url)."""
        charge = self.charges.get(reference)
        if charge is None:
            raise NotFound("Unknown sandbox payment")
        charge.status = "success" if success else "failed"
        charge.paid_at = datetime.now(UTC) if success else None
        body = json.dumps(
            {
                "event": "charge.success" if success else "charge.failed",
                "data": {
                    "id": f"sbx_{reference}",
                    "reference": reference,
                    "status": charge.status,
                    "amount": charge.amount_kobo,
                    "currency": charge.currency,
                },
            }
        ).encode()
        return body, self.sign(body), charge.callback_url

    def sign(self, body: bytes) -> str:
        return hmac.new(self._secret.encode(), body, hashlib.sha512).hexdigest()

    async def verify(self, reference: str) -> VerifyResult:
        charge = self.charges.get(reference)
        if charge is None:
            return VerifyResult(reference=reference, status="unknown", amount_kobo=0, currency="NGN")
        return VerifyResult(
            reference=reference,
            status="success"
            if charge.status == "success"
            else "failed"
            if charge.status == "failed"
            else "pending",
            amount_kobo=charge.amount_kobo,
            currency=charge.currency,
            provider_transaction_id=f"sbx_{reference}",
            channel="sandbox",
            paid_at=charge.paid_at,
        )

    async def refund(
        self, *, reference: str, provider_transaction_id: str | None, amount_kobo: int
    ) -> RefundResult:
        self.refunds.append({"reference": reference, "amount_kobo": amount_kobo})
        return RefundResult(provider_refund_id=f"sbx_rf_{len(self.refunds)}", status="processed")

    def verify_webhook(self, raw_body: bytes, headers: Mapping[str, str], client_ip: str | None) -> bool:
        signature = headers.get("x-sandbox-signature") or ""
        return bool(signature) and hmac.compare_digest(self.sign(raw_body), signature)

    def parse_webhook(self, raw_body: bytes) -> WebhookEvent:
        event = json.loads(raw_body)
        data = event.get("data") or {}
        name = str(event.get("event"))
        return WebhookEvent(
            provider=self.name,
            event_type=name if name in ("charge.success", "charge.failed") else "other",
            raw_event=name,
            dedupe_key=f"{name}:{data.get('id')}",
            reference=data.get("reference"),
            data=data,
        )
