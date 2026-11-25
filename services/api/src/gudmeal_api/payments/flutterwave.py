"""Flutterwave adapter (v3 Standard checkout).

- Amounts are major units (naira) — converted exactly to/from kobo with Decimal.
- Webhooks carry a `verif-hash` header that must equal the secret hash configured in the dashboard
  (constant-time comparison). Charges are always re-verified with Verify-by-reference.
"""

from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from datetime import datetime
from typing import Any

import httpx

from ..domain.money import kobo_to_naira_decimal, naira_decimal_to_kobo
from ..errors import PaymentProviderError
from ..security.compare import same_secret
from .base import (
    InitializeResult,
    ProviderOutcomeUnknown,
    RefundResult,
    SplitInstruction,
    VerifyResult,
    VerifyStatus,
    WebhookEvent,
)

# The request never left this server, so nothing happened at the provider.
NOT_SENT = (httpx.ConnectError, httpx.ConnectTimeout, httpx.PoolTimeout)

_STATUS_MAP: dict[str, VerifyStatus] = {
    "successful": "success",
    "failed": "failed",
    "cancelled": "abandoned",
    "pending": "pending",
}


class FlutterwaveProvider:
    name = "flutterwave"
    supports_split = False  # the backup gateway: Yummy Chops receives it all and pays the business out later

    def __init__(
        self,
        secret_key: str,
        secret_hash: str,
        *,
        http: httpx.AsyncClient,
        base_url: str = "https://api.flutterwave.com/v3",
    ) -> None:
        if not secret_key or not secret_hash:
            raise ValueError("Flutterwave secret key and webhook secret hash are required")
        self._secret = secret_key
        self._hash = secret_hash
        self._http = http
        self._base = base_url.rstrip("/")

    async def _request(self, method: str, path: str, **kwargs: Any) -> dict[str, Any]:
        try:
            resp = await self._http.request(
                method, f"{self._base}{path}", headers={"Authorization": f"Bearer {self._secret}"}, **kwargs
            )
        except NOT_SENT as exc:
            raise PaymentProviderError(
                "Flutterwave is unreachable", details={"error": type(exc).__name__}
            ) from exc
        except httpx.HTTPError as exc:  # sent, then no answer: Flutterwave may have done what was asked
            raise ProviderOutcomeUnknown(
                "Flutterwave did not answer", details={"error": type(exc).__name__}
            ) from exc
        try:
            body = resp.json()
        except ValueError as exc:
            raise ProviderOutcomeUnknown("Invalid response from Flutterwave") from exc
        if not isinstance(body, dict) or resp.status_code >= 500:
            raise ProviderOutcomeUnknown(
                "Flutterwave had an error", details={"status": resp.status_code, "path": path}
            )
        if resp.status_code >= 400 or body.get("status") != "success":
            raise PaymentProviderError(
                body.get("message") or "Flutterwave request failed", details={"path": path}
            )
        return body

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
        payload = {
            "tx_ref": reference,
            "amount": str(kobo_to_naira_decimal(amount_kobo)),
            "currency": currency,
            "redirect_url": callback_url,
            "customer": {
                "email": email,
                **({"name": customer_name} if customer_name else {}),
                **({"phonenumber": customer_phone} if customer_phone else {}),
            },
            "meta": dict(metadata),
            "customizations": {"title": "Yummy Chops", "description": "Food order payment"},
        }
        body = await self._request("POST", "/payments", json=payload)
        link = (body.get("data") or {}).get("link")
        if not link:
            raise PaymentProviderError("Flutterwave did not return a checkout link")
        return InitializeResult(reference=reference, authorization_url=link)

    async def verify(self, reference: str) -> VerifyResult:
        body = await self._request("GET", "/transactions/verify_by_reference", params={"tx_ref": reference})
        data = body.get("data") or {}
        created = data.get("created_at")
        return VerifyResult(
            reference=str(data.get("tx_ref", "")),
            status=_STATUS_MAP.get(str(data.get("status", "")).lower(), "unknown"),
            amount_kobo=naira_decimal_to_kobo(data.get("amount") or 0),
            currency=str(data.get("currency", "")).upper(),
            provider_transaction_id=str(data["id"]) if data.get("id") is not None else None,
            channel=data.get("payment_type"),
            paid_at=datetime.fromisoformat(created.replace("Z", "+00:00")) if created else None,
            gateway_message=data.get("processor_response"),
            raw={k: data.get(k) for k in ("id", "status", "tx_ref", "amount", "currency", "payment_type")},
        )

    async def refund(
        self, *, reference: str, provider_transaction_id: str | None, amount_kobo: int
    ) -> RefundResult:
        if not provider_transaction_id:
            raise PaymentProviderError("Flutterwave refunds require the transaction id")
        body = await self._request(
            "POST",
            f"/transactions/{provider_transaction_id}/refund",
            json={"amount": str(kobo_to_naira_decimal(amount_kobo))},
        )
        data = body.get("data") or {}
        status = str(data.get("status", "pending")).lower()
        return RefundResult(
            provider_refund_id=str(data["id"]) if data.get("id") is not None else None,
            status="processed" if status in ("completed", "successful") else "pending",
            raw={k: data.get(k) for k in ("id", "status", "amount_refunded")},
        )

    def verify_webhook(self, raw_body: bytes, headers: Mapping[str, str], client_ip: str | None) -> bool:
        provided = headers.get("verif-hash") or ""
        return bool(provided) and same_secret(self._hash, provided)

    def parse_webhook(self, raw_body: bytes) -> WebhookEvent:
        event = json.loads(raw_body)
        name = str(event.get("event", ""))
        data = event.get("data") or {}
        status = str(data.get("status", "")).lower()
        if name == "charge.completed":
            normalised = "charge.success" if status == "successful" else "charge.failed"
        else:
            normalised = "other"
        ident = data.get("id") or data.get("tx_ref") or hashlib.sha256(raw_body).hexdigest()[:32]
        return WebhookEvent(
            provider=self.name,
            event_type=normalised,
            raw_event=name,
            dedupe_key=f"{name}:{ident}:{status}",
            reference=data.get("tx_ref"),
            data={k: data.get(k) for k in ("id", "status", "tx_ref", "amount", "currency")},
        )
