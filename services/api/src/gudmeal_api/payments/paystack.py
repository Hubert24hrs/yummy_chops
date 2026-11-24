"""Paystack adapter (https://paystack.com/docs/api/).

- Amounts are sent and received in the currency subunit (kobo for NGN).
- Webhooks are signed: `x-paystack-signature` = hex(HMAC-SHA512(secret_key, raw_body)).
- A successful charge is never trusted from the webhook alone: we always call Verify Transaction.
"""

from __future__ import annotations

import hashlib
import hmac
import json
from collections.abc import Mapping
from datetime import datetime
from typing import Any

import httpx

from ..errors import PaymentProviderError
from .base import InitializeResult, RefundResult, SplitInstruction, VerifyResult, VerifyStatus, WebhookEvent

_STATUS_MAP: dict[str, VerifyStatus] = {
    "success": "success",
    "failed": "failed",
    "abandoned": "abandoned",
    "reversed": "reversed",
    "ongoing": "pending",
    "pending": "pending",
    "processing": "pending",
    "queued": "pending",
}

_EVENT_MAP = {
    "charge.success": "charge.success",
    "charge.failed": "charge.failed",
    "refund.processed": "refund.processed",
    "refund.failed": "refund.failed",
}


class PaystackProvider:
    name = "paystack"
    supports_split = True

    def __init__(
        self,
        secret_key: str,
        *,
        http: httpx.AsyncClient,
        base_url: str = "https://api.paystack.co",
        ip_allowlist: list[str] | None = None,
    ) -> None:
        if not secret_key:
            raise ValueError("Paystack secret key is required")
        self._secret = secret_key
        self._http = http
        self._base = base_url.rstrip("/")
        self._ip_allowlist = set(ip_allowlist or [])

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self._secret}", "Content-Type": "application/json"}

    async def _request(self, method: str, path: str, **kwargs: Any) -> dict[str, Any]:
        try:
            resp = await self._http.request(method, f"{self._base}{path}", headers=self._headers(), **kwargs)
        except httpx.HTTPError as exc:
            raise PaymentProviderError(
                "Paystack is unreachable", details={"error": type(exc).__name__}
            ) from exc
        try:
            body = resp.json()
        except ValueError as exc:
            raise PaymentProviderError(
                "Invalid response from Paystack", details={"status": resp.status_code}
            ) from exc
        if resp.status_code >= 400 or not body.get("status"):
            raise PaymentProviderError(
                body.get("message") or "Paystack request failed",
                details={"status": resp.status_code, "path": path},
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
            "email": email,
            "amount": str(amount_kobo),
            "currency": currency,
            "reference": reference,
            "callback_url": callback_url,
            "metadata": json.dumps({**metadata, "cancel_action": callback_url}),
        }
        if split is not None:
            # The business's share goes to its subaccount; Yummy Chops keeps a flat amount and bears Paystack's fee.
            payload |= {
                "subaccount": split.subaccount,
                "transaction_charge": split.platform_kobo,
                "bearer": "account",
            }
        body = await self._request("POST", "/transaction/initialize", json=payload)
        data = body.get("data") or {}
        if not data.get("authorization_url"):
            raise PaymentProviderError("Paystack did not return an authorization URL")
        return InitializeResult(
            reference=data.get("reference", reference),
            authorization_url=data["authorization_url"],
            access_code=data.get("access_code"),
        )

    # ---- businesses' bank accounts (split payments) ----------------------------------------------------------------
    async def list_banks(self) -> list[dict[str, str]]:
        """Nigerian banks and their Paystack codes, for a business to pick its settlement bank."""
        body = await self._request(
            "GET", "/bank", params={"country": "nigeria", "currency": "NGN", "perPage": 100}
        )
        return [
            {"code": str(b["code"]), "name": str(b["name"])}
            for b in body.get("data") or []
            if b.get("code") and b.get("name") and b.get("active", True) and not b.get("is_deleted")
        ]

    async def resolve_account(self, *, account_number: str, bank_code: str) -> str:
        """The name on a bank account, as the bank has it (so the owner can see it is theirs)."""
        body = await self._request(
            "GET", "/bank/resolve", params={"account_number": account_number, "bank_code": bank_code}
        )
        return str((body.get("data") or {}).get("account_name") or "")

    async def save_subaccount(
        self,
        *,
        code: str | None,
        business_name: str,
        bank_code: str,
        account_number: str,
        email: str | None = None,
        phone: str | None = None,
    ) -> str:
        """Creates (or, with `code`, updates) the business's subaccount; returns its code (ACCT_...)."""
        payload = {
            "business_name": business_name,
            "settlement_bank": bank_code,
            "account_number": account_number,
            # Each payment says what Yummy Chops keeps (transaction_charge), so the default share is never used.
            "percentage_charge": 0,
            "description": "Yummy Chops business",
            "primary_contact_email": email,
            "primary_contact_phone": phone,
        }
        payload = {k: v for k, v in payload.items() if v not in (None, "")}
        if code:
            body = await self._request("PUT", f"/subaccount/{code}", json=payload)
        else:
            body = await self._request("POST", "/subaccount", json=payload)
        saved = str((body.get("data") or {}).get("subaccount_code") or code or "")
        if not saved:
            raise PaymentProviderError("Paystack did not return a subaccount code")
        return saved

    async def verify(self, reference: str) -> VerifyResult:
        body = await self._request("GET", f"/transaction/verify/{reference}")
        data = body.get("data") or {}
        paid_at = data.get("paid_at") or data.get("paidAt")
        return VerifyResult(
            reference=str(data.get("reference", "")),
            status=_STATUS_MAP.get(str(data.get("status", "")).lower(), "unknown"),
            amount_kobo=int(data.get("amount") or 0),
            currency=str(data.get("currency", "")).upper(),
            provider_transaction_id=str(data["id"]) if data.get("id") is not None else None,
            channel=data.get("channel"),
            paid_at=datetime.fromisoformat(paid_at.replace("Z", "+00:00")) if paid_at else None,
            gateway_message=data.get("gateway_response"),
            raw={
                k: data.get(k)
                for k in ("id", "status", "reference", "amount", "currency", "channel", "paid_at")
            },
        )

    async def refund(
        self, *, reference: str, provider_transaction_id: str | None, amount_kobo: int
    ) -> RefundResult:
        body = await self._request(
            "POST",
            "/refund",
            json={"transaction": provider_transaction_id or reference, "amount": str(amount_kobo)},
        )
        data = body.get("data") or {}
        status = str(data.get("status", "pending")).lower()
        return RefundResult(
            provider_refund_id=str(data["id"]) if data.get("id") is not None else None,
            status="processed" if status == "processed" else "failed" if status == "failed" else "pending",
            raw={k: data.get(k) for k in ("id", "status", "amount", "currency")},
        )

    def verify_webhook(self, raw_body: bytes, headers: Mapping[str, str], client_ip: str | None) -> bool:
        if self._ip_allowlist and client_ip not in self._ip_allowlist:
            return False
        signature = headers.get("x-paystack-signature") or ""
        expected = hmac.new(self._secret.encode(), raw_body, hashlib.sha512).hexdigest()
        return bool(signature) and hmac.compare_digest(expected, signature)

    def parse_webhook(self, raw_body: bytes) -> WebhookEvent:
        event = json.loads(raw_body)
        name = str(event.get("event", ""))
        data = event.get("data") or {}
        reference = data.get("reference") or (data.get("transaction") or {}).get("reference")
        ident = data.get("id") or reference or hashlib.sha256(raw_body).hexdigest()[:32]
        return WebhookEvent(
            provider=self.name,
            event_type=_EVENT_MAP.get(name, "other"),
            raw_event=name,
            dedupe_key=f"{name}:{ident}",
            reference=str(reference) if reference else None,
            data={k: data.get(k) for k in ("id", "status", "reference", "amount", "currency")},
        )
