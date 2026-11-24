"""Payment orchestration: gateway checkout (with failover), Yummy Chops wallet, pay on delivery, server-side
verification, webhooks, refunds (to the card or into the wallet) and settlement postings."""

from __future__ import annotations

import logging
import secrets
from collections.abc import Callable, Mapping
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from ..domain.models import Order
from ..domain.money import allocate
from ..domain.pricing import vat_inclusive_split
from ..errors import NotFound, PaymentProviderError, Unauthenticated, ValidationFailed
from ..ledger import ledger as postings
from ..ledger.audit import AuditLog
from ..ledger.db import Database
from ..ledger.ledger import LedgerService
from ..ledger.outbox import OutboxRelay, add_outbox_event
from ..ledger.tables import (
    INTERNAL_PROVIDERS,
    CommissionRecord,
    PaymentEvent,
    PaymentRecord,
    RefundRecord,
    new_id,
)
from ..logging_setup import log_event
from ..payments.base import PaymentProvider, SplitInstruction
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, require

logger = logging.getLogger(__name__)
REUSE_WINDOW = timedelta(minutes=25)
# Top-level domains reserved for testing and examples (RFC 2606, RFC 6761): no mailbox exists there.
_UNDELIVERABLE_TLDS = frozenset({"test", "example", "invalid", "localhost", "local"})


def utcnow() -> datetime:
    return datetime.now(UTC)


def payment_view(rec: PaymentRecord) -> dict[str, Any]:
    return {
        "id": rec.id,
        "order_id": rec.order_id,
        "purpose": rec.purpose,
        "provider": rec.provider,
        "reference": rec.reference,
        "amount_kobo": rec.amount_kobo,
        "currency": rec.currency,
        "status": rec.status,
        "authorization_url": rec.authorization_url,
        "channel": rec.channel,
        "paid_at": rec.paid_at,
        "refunded_kobo": rec.refunded_kobo,
        "created_at": rec.created_at,
        "failure_reason": rec.failure_reason,
    }


def refund_view(rec: RefundRecord) -> dict[str, Any]:
    return {
        "id": rec.id,
        "order_id": rec.order_id,
        "payment_id": rec.payment_id,
        "amount_kobo": rec.amount_kobo,
        "reason": rec.reason,
        "liability": rec.liability,
        "stage": rec.stage,
        "destination": rec.destination,
        "status": rec.status,
        "requested_by": rec.requested_by,
        "decided_by": rec.decided_by,
        "decision_note": rec.decision_note,
        "created_at": rec.created_at,
        "decided_at": rec.decided_at,
        "completed_at": rec.completed_at,
    }


class ProviderHealth:
    """Tiny circuit breaker: after `threshold` consecutive failures a gateway is tried last for `cooldown`."""

    def __init__(self, threshold: int = 3, cooldown: timedelta = timedelta(minutes=2)) -> None:
        self.threshold = threshold
        self.cooldown = cooldown
        self._failures: dict[str, tuple[int, datetime]] = {}

    def record(self, name: str, *, ok: bool) -> None:
        if ok:
            self._failures.pop(name, None)
            return
        count, _ = self._failures.get(name, (0, utcnow()))
        self._failures[name] = (count + 1, utcnow())

    def degraded(self, name: str) -> bool:
        count, last = self._failures.get(name, (0, None))
        return count >= self.threshold and last is not None and utcnow() - last < self.cooldown


class PaymentService:
    def __init__(
        self,
        *,
        db: Database,
        ledger: LedgerService,
        audit: AuditLog,
        relay: OutboxRelay,
        repos: Repositories,
        providers: Mapping[str, PaymentProvider],
        default_provider: str,
        callback_url: str | Callable[[], str],
        email_fallback_domain: str,
        refund_auto_approve_limit_kobo: int = 0,
        failover_provider: str | None = None,
        wallet_enabled: bool = True,
    ) -> None:
        self.db = db
        self.ledger = ledger
        self.audit = audit
        self.relay = relay
        self.repos = repos
        self.providers = dict(providers)
        self.default_provider = default_provider
        self.failover_provider = failover_provider
        self.callback_url = callback_url
        self.email_fallback_domain = email_fallback_domain
        self.refund_auto_approve_limit = refund_auto_approve_limit_kobo
        self.wallet_enabled = wallet_enabled
        self.health = ProviderHealth()

    def payer_email(self, principal: Principal) -> str:
        """The email a payment gateway gets for this payer. Gateways require one: customers who signed in without an
        email, and accounts on special-use domains that can never receive mail (the demo accounts' @yummychops.test;
        RFC 2606 and 6761), which Paystack refuses ("email must be a valid email"), get an address on our own domain."""
        email = (principal.email or "").strip()
        domain = email.rpartition("@")[2].lower()
        if "@" not in email or not domain or domain.rsplit(".", 1)[-1] in _UNDELIVERABLE_TLDS:
            return f"{principal.uid}@{self.email_fallback_domain}"
        return email

    def _return_to(self, query: str) -> str:
        """Where the payment page sends the payer back. The address can change while the API runs (phone tests
        follow the laptop's Wi-Fi address), so it is worked out for each payment."""
        base = self.callback_url() if callable(self.callback_url) else self.callback_url
        return f"{base}?{query}"

    def provider(self, name: str | None) -> PaymentProvider:
        key = name or self.default_provider
        provider = self.providers.get(key)
        if provider is None:
            raise ValidationFailed(
                f"Payment provider '{key}' is not configured",
                details={"available": sorted(self.providers)},
            )
        return provider

    def gateways(self, explicit: str | None = None) -> list[str]:
        """Gateways to try, in order: the one asked for, else the default then the backup (healthy first)."""
        if explicit:
            self.provider(explicit)
            return [explicit]
        names = [self.default_provider]
        backup = self.failover_provider
        if backup and backup != self.default_provider and backup in self.providers:
            names.append(backup)
        healthy = [n for n in names if not self.health.degraded(n)]
        return healthy + [n for n in names if n not in healthy]

    # ============================================================================ gateway checkout
    async def initiate(
        self, order: Order, principal: Principal, provider_name: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        names = self.gateways(provider_name)
        now = utcnow()
        async with self.db.session() as s:
            paid = await s.scalar(
                select(func.count())
                .select_from(PaymentRecord)
                .where(PaymentRecord.order_id == order.id, PaymentRecord.status == "succeeded")
            )
            if paid:
                raise ValidationFailed("This order is already paid")
            existing = await s.scalar(
                select(PaymentRecord)
                .where(PaymentRecord.order_id == order.id, PaymentRecord.status == "pending")
                .order_by(PaymentRecord.created_at.desc())
                .limit(1)
            )
        if (
            existing is not None
            and existing.provider == names[0]
            and existing.authorization_url
            and existing.amount_kobo == order.breakdown.total_kobo
            and now - _aware(existing.created_at) < REUSE_WINDOW
        ):
            return self._init_view(existing)
        return await self._hosted_checkout(
            names,
            split=await self.split_for(order),
            purpose="order",
            order_id=order.id,
            customer_id=order.customer_id,
            amount_kobo=order.breakdown.total_kobo,
            reference_stem=f"YC-{order.short_code}",
            idempotency_key=f"{order.id}:{idempotency_key}",
            principal=principal,
            callback_url=self._return_to(f"order_id={order.id}"),
            metadata={"order_id": order.id, "short_code": order.short_code, "customer_id": order.customer_id},
        )

    async def split_for(self, order: Order) -> SplitInstruction | None:
        """How an order's card payment is split when its business has a bank account at the provider: the business's
        earning goes straight to it, Yummy Chops keeps the rest (fees, commission, delivery). None when there is no
        such account (docs/adr/0028-business-branches-and-split-payments.md)."""
        restaurant = await self.repos.restaurants.get(order.restaurant_id) if order.restaurant_id else None
        if restaurant is None or not restaurant.business_id:
            return None
        business = await self.repos.businesses.get(restaurant.business_id)
        if business is None or not business.paystack_subaccount_code:
            return None
        share, total = order.settlement.restaurant_earning_kobo, order.breakdown.total_kobo
        if share <= 0 or share >= total:
            return None
        return SplitInstruction(subaccount=business.paystack_subaccount_code, platform_kobo=total - share)

    async def start_wallet_topup(
        self, principal: Principal, amount_kobo: int, provider_name: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        """Hosted checkout that credits the customer's wallet once the gateway confirms the payment."""
        if not self.wallet_enabled:
            raise ValidationFailed("The Yummy Chops wallet is not available right now")
        return await self._hosted_checkout(
            self.gateways(provider_name),
            purpose="wallet_topup",
            order_id=None,
            customer_id=principal.uid,
            amount_kobo=amount_kobo,
            reference_stem="YC-TOPUP",
            idempotency_key=f"topup:{principal.uid}:{idempotency_key}",
            principal=principal,
            callback_url=self._return_to("purpose=wallet_topup"),
            metadata={"purpose": "wallet_topup", "customer_id": principal.uid},
        )

    async def start_plus_checkout(
        self, principal: Principal, amount_kobo: int, provider_name: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        """Hosted checkout for Yummy Chops Plus; the membership starts once the gateway payment is verified."""
        return await self._hosted_checkout(
            self.gateways(provider_name),
            purpose="plus",
            order_id=None,
            customer_id=principal.uid,
            amount_kobo=amount_kobo,
            reference_stem="YC-PLUS",
            idempotency_key=f"plus:{principal.uid}:{idempotency_key}",
            principal=principal,
            callback_url=self._return_to("purpose=plus"),
            metadata={"purpose": "plus", "customer_id": principal.uid},
        )

    async def pay_plus_with_wallet(
        self, uid: str, amount_kobo: int, vat_kobo: int, idempotency_key: str, *, renewal: bool = False
    ) -> dict[str, Any]:
        """Pay for Yummy Chops Plus from the wallet (joining, or an automatic renewal)."""
        reference = f"YC-PLUS-W{secrets.token_hex(4).upper()}"
        return await self._wallet_debit(
            uid=uid,
            amount_kobo=amount_kobo,
            purpose="plus",
            order_id=None,
            reference=reference,
            idempotency_key=f"plus:{uid}:{idempotency_key}",
            ledger_kind="plus_payment",
            entries=postings.plus_paid(postings.wallet_account(uid), amount_kobo, vat_kobo),
            description="Yummy Chops Plus renewal" if renewal else "Yummy Chops Plus",
            event_type="plus.paid",
            event_payload={"customer_id": uid, "renewal": renewal},
            what="Yummy Chops Plus",
        )

    async def start_share_checkout(
        self,
        principal: Principal,
        order: Order,
        amount_kobo: int,
        provider_name: str | None,
        idempotency_key: str,
    ) -> dict[str, Any]:
        """Hosted checkout for one member's share of a group order (or the rest of the bill, for the host)."""
        return await self._hosted_checkout(
            self.gateways(provider_name),
            purpose="group_share",
            order_id=order.id,
            customer_id=principal.uid,
            amount_kobo=amount_kobo,
            reference_stem=f"YC-{order.short_code}-G",
            idempotency_key=f"share:{order.id}:{principal.uid}:{idempotency_key}",
            principal=principal,
            callback_url=self._return_to(f"group_order_id={order.group_order_id}"),
            metadata={
                "purpose": "group_share",
                "order_id": order.id,
                "group_order_id": order.group_order_id,
                "customer_id": principal.uid,
            },
        )

    async def pay_share_with_wallet(
        self, uid: str, order: Order, amount_kobo: int, idempotency_key: str
    ) -> dict[str, Any]:
        """Pay a group-order share from the member's own wallet (instant)."""
        return await self._wallet_debit(
            uid=uid,
            amount_kobo=amount_kobo,
            purpose="group_share",
            order_id=order.id,
            reference=f"YC-{order.short_code}-GW{secrets.token_hex(3).upper()}",
            idempotency_key=f"share:{order.id}:{uid}:{idempotency_key}",
            ledger_kind="wallet_payment",
            entries=postings.wallet_payment(uid, amount_kobo),
            description=f"Share of group order {order.short_code}",
            event_type="group_share.paid",
            event_payload={"order_id": order.id, "customer_id": uid},
            what="your share",
        )

    async def group_share_payments(self, order_id: str) -> list[dict[str, Any]]:
        async with self.db.session() as s:
            rows = list(
                (
                    await s.execute(
                        select(PaymentRecord)
                        .where(
                            PaymentRecord.order_id == order_id,
                            PaymentRecord.purpose == "group_share",
                            PaymentRecord.status == "succeeded",
                        )
                        .order_by(PaymentRecord.created_at)
                    )
                ).scalars()
            )
        return [
            {
                "id": r.id,
                "customer_id": r.customer_id,
                "amount_kobo": r.amount_kobo,
                "refunded_kobo": r.refunded_kobo,
                "provider": r.provider,
                "reference": r.reference,
            }
            for r in rows
        ]

    async def _wallet_debit(
        self,
        *,
        uid: str,
        amount_kobo: int,
        purpose: Literal["plus", "group_share"],
        order_id: str | None,
        reference: str,
        idempotency_key: str,
        ledger_kind: str,
        entries: list[postings.Posting],
        description: str,
        event_type: str,
        event_payload: dict[str, Any],
        what: str,
    ) -> dict[str, Any]:
        """Charge a customer's wallet under its account lock: balance check, succeeded payment record, ledger
        posting and outbox event in one database transaction (the same request twice charges once)."""
        if not self.wallet_enabled:
            raise ValidationFailed("The Yummy Chops wallet is not available right now")
        now = utcnow()
        account = postings.wallet_account(uid)
        async with self.db.transaction() as s:
            prior = await s.scalar(
                select(PaymentRecord).where(PaymentRecord.idempotency_key == idempotency_key)
            )
            if prior is not None:
                return self._init_view(prior)
            await self.ledger.lock_account(s, account)
            balance = await self.ledger.balance(s, account)
            if balance < amount_kobo:
                raise ValidationFailed(
                    f"Your Yummy Chops wallet balance is too low for {what}",
                    details={
                        "balance_kobo": balance,
                        "needed_kobo": amount_kobo,
                        "short_by_kobo": amount_kobo - balance,
                    },
                )
            rec = PaymentRecord(
                id=new_id(),
                order_id=order_id,
                customer_id=uid,
                purpose=purpose,
                provider="wallet",
                reference=reference,
                amount_kobo=amount_kobo,
                currency="NGN",
                status="succeeded",
                channel="wallet",
                paid_at=now,
                idempotency_key=idempotency_key,
                created_at=now,
                updated_at=now,
            )
            s.add(rec)
            await s.flush()
            await self.ledger.post(
                s,
                kind=ledger_kind,
                idempotency_key=f"payment:{rec.id}:captured",
                postings=entries,
                created_by="payments:wallet",
                reference=reference,
                order_id=order_id,
                description=description,
            )
            add_outbox_event(
                s,
                event_type,
                {
                    **event_payload,
                    "payment_id": rec.id,
                    "provider": "wallet",
                    "reference": reference,
                    "amount_kobo": amount_kobo,
                    "paid_at": now.isoformat(),
                },
            )
            view = self._init_view(rec)
        await self.relay.relay_pending()
        return view

    async def _hosted_checkout(
        self,
        names: list[str],
        *,
        purpose: Literal["order", "wallet_topup", "plus", "group_share"],
        order_id: str | None,
        customer_id: str,
        amount_kobo: int,
        reference_stem: str,
        idempotency_key: str,
        principal: Principal,
        callback_url: str,
        metadata: dict[str, Any],
        split: SplitInstruction | None = None,
    ) -> dict[str, Any]:
        """Start a gateway checkout, failing over to the next gateway when one cannot start it. A `split` is used only
        by gateways that can split (the backup gateway takes the whole payment; the business is paid out later)."""
        email = self.payer_email(principal)
        last_error: PaymentProviderError | None = None
        for attempt, name in enumerate(names):
            provider = self.provider(name)
            now = utcnow()
            key = idempotency_key if attempt == 0 else f"{idempotency_key}:{provider.name}"
            use_split = split if split is not None and getattr(provider, "supports_split", False) else None
            async with self.db.transaction() as s:
                prior = await s.scalar(select(PaymentRecord).where(PaymentRecord.idempotency_key == key))
                if prior is not None and prior.status == "pending" and prior.authorization_url:
                    return self._init_view(prior)  # same request retried
                if prior is not None:  # an earlier attempt failed: this retry gets its own record
                    key = f"{key}:{secrets.token_hex(3)}"
                rec = PaymentRecord(
                    id=new_id(),
                    order_id=order_id,
                    customer_id=customer_id,
                    purpose=purpose,
                    provider=provider.name,
                    reference=f"{reference_stem}-{secrets.token_hex(4).upper()}",
                    amount_kobo=amount_kobo,
                    currency="NGN",
                    status="initialized",
                    idempotency_key=key,
                    split_subaccount=use_split.subaccount if use_split else None,
                    split_amount_kobo=amount_kobo - use_split.platform_kobo if use_split else 0,
                    created_at=now,
                    updated_at=now,
                )
                s.add(rec)
            try:
                init = await provider.initialize(
                    reference=rec.reference,
                    amount_kobo=amount_kobo,
                    email=email,
                    currency="NGN",
                    callback_url=callback_url,
                    metadata=metadata,
                    customer_name=principal.name,
                    customer_phone=principal.phone,
                    split=use_split,
                )
            except PaymentProviderError as exc:
                self.health.record(provider.name, ok=False)
                async with self.db.transaction() as s:
                    row = await s.get(PaymentRecord, rec.id)
                    if row is not None:
                        row.status = "failed"
                        row.failure_reason = exc.message[:500]
                        row.updated_at = utcnow()
                last_error = exc
                if attempt + 1 < len(names):
                    log_event(
                        logger,
                        "payment gateway failover",
                        logging.WARNING,
                        failed=provider.name,
                        next=names[attempt + 1],
                        reference=rec.reference,
                    )
                continue
            self.health.record(provider.name, ok=True)
            async with self.db.transaction() as s:
                row = await s.get(PaymentRecord, rec.id)
                assert row is not None
                row.status = "pending"
                row.authorization_url = init.authorization_url
                row.access_code = init.access_code
                row.updated_at = utcnow()
                view = self._init_view(row)
            if attempt:
                view["failover_from"] = names[0]
            return view
        assert last_error is not None
        raise last_error

    @staticmethod
    def _init_view(rec: PaymentRecord) -> dict[str, Any]:
        return {
            "provider": rec.provider,
            "reference": rec.reference,
            "authorization_url": rec.authorization_url,
            "access_code": rec.access_code,
            "amount_kobo": rec.amount_kobo,
            "currency": rec.currency,
            "payment_status": rec.status,
        }

    # ============================================================================ wallet & cash
    async def wallet_balance(self, uid: str) -> int:
        async with self.db.session() as s:
            return await self.ledger.balance(s, postings.wallet_account(uid))

    async def pay_with_wallet(
        self, order: Order, principal: Principal, idempotency_key: str
    ) -> dict[str, Any]:
        """Pay the whole order from the wallet: balance check and debit happen under one account lock."""
        if not self.wallet_enabled:
            raise ValidationFailed("The Yummy Chops wallet is not available right now")
        now = utcnow()
        key = f"{order.id}:{idempotency_key}"
        account = postings.wallet_account(order.customer_id)
        total = order.breakdown.total_kobo
        async with self.db.transaction() as s:
            prior = await s.scalar(select(PaymentRecord).where(PaymentRecord.idempotency_key == key))
            if prior is not None:
                return self._init_view(prior)
            await self.ledger.lock_account(s, account)
            paid = await s.scalar(
                select(func.count())
                .select_from(PaymentRecord)
                .where(PaymentRecord.order_id == order.id, PaymentRecord.status == "succeeded")
            )
            if paid:
                raise ValidationFailed("This order is already paid")
            balance = await self.ledger.balance(s, account)
            if balance < total:
                raise ValidationFailed(
                    "Your Yummy Chops wallet balance is too low for this order",
                    details={"balance_kobo": balance, "needed_kobo": total, "short_by_kobo": total - balance},
                )
            rec = PaymentRecord(
                id=new_id(),
                order_id=order.id,
                customer_id=order.customer_id,
                purpose="order",
                provider="wallet",
                reference=f"YC-{order.short_code}-W{secrets.token_hex(3).upper()}",
                amount_kobo=total,
                currency="NGN",
                status="succeeded",
                channel="wallet",
                provider_transaction_id=None,
                paid_at=now,
                idempotency_key=key,
                created_at=now,
                updated_at=now,
            )
            s.add(rec)
            await s.flush()
            await self.ledger.post(
                s,
                kind="wallet_payment",
                idempotency_key=f"payment:{rec.id}:captured",
                postings=postings.wallet_payment(order.customer_id, total),
                created_by="payments:wallet",
                reference=rec.reference,
                order_id=order.id,
                description=f"Paid for order {order.short_code}",
            )
            add_outbox_event(
                s,
                "payment.succeeded",
                {
                    "order_id": order.id,
                    "payment_id": rec.id,
                    "provider": "wallet",
                    "reference": rec.reference,
                    "amount_kobo": total,
                    "paid_at": now.isoformat(),
                },
            )
            view = self._init_view(rec)
        await self.relay.relay_pending()
        return view

    async def start_cash_payment(self, order: Order, idempotency_key: str) -> dict[str, Any]:
        """Pay on delivery: record the cash due (status pending) without touching the ledger yet."""
        now = utcnow()
        key = f"{order.id}:{idempotency_key}"
        async with self.db.transaction() as s:
            prior = await s.scalar(
                select(PaymentRecord).where(
                    (PaymentRecord.idempotency_key == key)
                    | (
                        (PaymentRecord.order_id == order.id)
                        & (PaymentRecord.provider == "cash")
                        & (PaymentRecord.status == "pending")
                    )
                )
            )
            if prior is not None:
                return self._init_view(prior)
            rec = PaymentRecord(
                id=new_id(),
                order_id=order.id,
                customer_id=order.customer_id,
                purpose="order",
                provider="cash",
                reference=f"YC-{order.short_code}-C{secrets.token_hex(3).upper()}",
                amount_kobo=order.breakdown.total_kobo,
                currency="NGN",
                status="pending",
                channel="cash",
                idempotency_key=key,
                created_at=now,
                updated_at=now,
            )
            s.add(rec)
            return self._init_view(rec)

    async def record_cash_collection(self, order: Order, rider_id: str) -> int:
        """The rider confirmed the cash at the door. Posts it once (idempotent); returns the rider's cash held.

        Amounts come from the server's records (the order's cash payment and the parcel's COD amount), never
        from the rider's request.
        """
        now = utcnow()
        async with self.db.transaction() as s:
            pod_kobo = 0
            if order.awaiting_cash_payment:
                rec = await s.scalar(
                    select(PaymentRecord)
                    .where(
                        PaymentRecord.order_id == order.id,
                        PaymentRecord.provider == "cash",
                        PaymentRecord.status.in_(("pending", "succeeded")),
                    )
                    .order_by(PaymentRecord.created_at.desc())
                    .limit(1)
                    .with_for_update()
                )
                if rec is None:
                    raise ValidationFailed("This order has no cash payment to collect")
                if rec.status != "succeeded":
                    rec.status = "succeeded"
                    rec.paid_at = now
                    rec.provider_transaction_id = f"rider:{rider_id}"
                    rec.updated_at = now
                pod_kobo = rec.amount_kobo
                await self.ledger.post(
                    s,
                    kind="cash_collected",
                    idempotency_key=f"order:{order.id}:cash_collected",
                    postings=postings.cash_collected(rider_id, rec.amount_kobo),
                    created_by=f"rider:{rider_id}",
                    reference=rec.reference,
                    order_id=order.id,
                    description=f"Cash collected for order {order.short_code}",
                )
            cod_kobo = (order.parcel.cod_amount_kobo or 0) if order.parcel else 0
            if cod_kobo:
                await self.ledger.post(
                    s,
                    kind="cod_collected",
                    idempotency_key=f"order:{order.id}:cod_collected",
                    postings=postings.cod_collected(rider_id, order.customer_id, cod_kobo),
                    created_by=f"rider:{rider_id}",
                    reference=order.short_code,
                    order_id=order.id,
                    description=f"Cash on delivery collected for package {order.short_code}",
                )
            AuditLog.add(
                s,
                actor_id=rider_id,
                actor_roles=["rider"],
                action="cash.collected",
                resource_type="order",
                resource_id=order.id,
                details={"pay_on_delivery_kobo": pod_kobo, "cod_kobo": cod_kobo},
            )
            return await self.ledger.balance(s, postings.rider_cash_account(rider_id))

    async def void_cash_payment(self, order_id: str, reason: str = "Order cancelled before delivery") -> None:
        """A pay-on-delivery order was called off before the rider collected anything."""
        async with self.db.transaction() as s:
            rows = (
                await s.execute(
                    select(PaymentRecord).where(
                        PaymentRecord.order_id == order_id,
                        PaymentRecord.provider == "cash",
                        PaymentRecord.status == "pending",
                    )
                )
            ).scalars()
            for row in rows:
                row.status = "abandoned"
                row.failure_reason = reason[:500]
                row.updated_at = utcnow()

    async def on_order_cancelled(self, payload: dict[str, Any]) -> None:
        await self.void_cash_payment(str(payload["order_id"]))

    # ============================================================================ verification
    async def get_payment(self, reference: str) -> PaymentRecord:
        async with self.db.session() as s:
            rec = await s.scalar(select(PaymentRecord).where(PaymentRecord.reference == reference))
        if rec is None:
            raise NotFound("Payment not found")
        return rec

    async def verify_for_customer(self, principal: Principal, reference: str) -> dict[str, Any]:
        rec = await self.get_payment(reference)
        if rec.customer_id != principal.uid and not principal.can(Permission.PAYMENTS_READ):
            raise NotFound("Payment not found")
        return await self.verify_reference(reference, source="client")

    async def verify_reference(
        self, reference: str, *, source: Literal["webhook", "client", "reconcile"]
    ) -> dict[str, Any]:
        rec = await self.get_payment(reference)
        if rec.status == "succeeded" or rec.provider in INTERNAL_PROVIDERS:
            return payment_view(
                rec
            )  # wallet and cash payments are settled inside Yummy Chops, not by a gateway
        provider = self.provider(rec.provider)
        result = await provider.verify(reference)
        now = utcnow()
        async with self.db.transaction() as s:
            row = await s.scalar(
                select(PaymentRecord).where(PaymentRecord.reference == reference).with_for_update()
            )
            assert row is not None
            if row.status == "succeeded":
                return payment_view(row)
            s.add(
                PaymentEvent(
                    payment_id=row.id,
                    provider=row.provider,
                    dedupe_key=f"verify:{new_id()}",
                    event_type=f"verify.{result.status}",
                    source=source,
                    payload=result.raw,
                )
            )
            if result.status == "success":
                problems = []
                if result.reference and result.reference != row.reference:
                    problems.append("reference_mismatch")
                if result.amount_kobo != row.amount_kobo:
                    problems.append("amount_mismatch")
                if result.currency != row.currency:
                    problems.append("currency_mismatch")
                if problems:
                    row.status = "flagged"
                    row.failure_reason = ",".join(problems)
                    row.updated_at = now
                    AuditLog.add(
                        s,
                        actor_id="system",
                        actor_roles=["system"],
                        action="payment.flagged",
                        resource_type="payment",
                        resource_id=row.id,
                        details={"problems": problems, "reported_amount_kobo": result.amount_kobo},
                    )
                    log_event(
                        logger, "payment flagged", logging.ERROR, reference=reference, problems=problems
                    )
                else:
                    row.status = "succeeded"
                    row.paid_at = result.paid_at or now
                    row.provider_transaction_id = result.provider_transaction_id
                    row.channel = result.channel
                    row.updated_at = now
                    if row.purpose == "wallet_topup":
                        await self.ledger.post(
                            s,
                            kind="wallet_topup",
                            idempotency_key=f"payment:{row.id}:captured",
                            postings=postings.wallet_topup(row.provider, row.customer_id, row.amount_kobo),
                            created_by=f"payments:{source}",
                            reference=row.reference,
                            description="Wallet top-up",
                        )
                        add_outbox_event(
                            s,
                            "wallet.topped_up",
                            {
                                "customer_id": row.customer_id,
                                "payment_id": row.id,
                                "reference": row.reference,
                                "amount_kobo": row.amount_kobo,
                            },
                        )
                    elif row.purpose == "group_share":
                        await self.ledger.post(
                            s,
                            kind="payment_captured",
                            idempotency_key=f"payment:{row.id}:captured",
                            postings=postings.payment_captured(row.provider, row.amount_kobo),
                            created_by=f"payments:{source}",
                            reference=row.reference,
                            order_id=row.order_id,
                            description=f"Group order share {row.reference} captured",
                        )
                        add_outbox_event(
                            s,
                            "group_share.paid",
                            {
                                "order_id": row.order_id,
                                "customer_id": row.customer_id,
                                "payment_id": row.id,
                                "provider": row.provider,
                                "reference": row.reference,
                                "amount_kobo": row.amount_kobo,
                                "paid_at": (row.paid_at or now).isoformat(),
                            },
                        )
                    elif row.purpose == "plus":
                        cfg = await self.repos.get_pricing_config()
                        _, vat = vat_inclusive_split(row.amount_kobo, cfg.vat_bps)
                        await self.ledger.post(
                            s,
                            kind="plus_payment",
                            idempotency_key=f"payment:{row.id}:captured",
                            postings=postings.plus_paid(f"cash:{row.provider}", row.amount_kobo, vat),
                            created_by=f"payments:{source}",
                            reference=row.reference,
                            description="Yummy Chops Plus",
                        )
                        add_outbox_event(
                            s,
                            "plus.paid",
                            {
                                "customer_id": row.customer_id,
                                "payment_id": row.id,
                                "provider": row.provider,
                                "reference": row.reference,
                                "amount_kobo": row.amount_kobo,
                                "paid_at": (row.paid_at or now).isoformat(),
                                "renewal": False,
                            },
                        )
                    else:
                        await self.ledger.post(
                            s,
                            kind="payment_captured",
                            idempotency_key=f"payment:{row.id}:captured",
                            postings=postings.payment_captured(row.provider, row.amount_kobo),
                            created_by=f"payments:{source}",
                            reference=row.reference,
                            order_id=row.order_id,
                            description=f"Payment {row.reference} captured",
                        )
                        if row.split_amount_kobo and row.order_id:
                            # The business's share went straight to its bank account: it is paid that much already.
                            paid_order = await self.repos.orders.get(row.order_id)
                            if paid_order is not None and paid_order.restaurant_id:
                                await self.ledger.post(
                                    s,
                                    kind="split_settled",
                                    idempotency_key=f"payment:{row.id}:split",
                                    postings=postings.split_settled(
                                        row.provider, paid_order.restaurant_id, row.split_amount_kobo
                                    ),
                                    created_by=f"payments:{source}",
                                    reference=row.reference,
                                    order_id=row.order_id,
                                    description=f"Payment {row.reference}: the business's share paid by split",
                                )
                        add_outbox_event(
                            s,
                            "payment.succeeded",
                            {
                                "order_id": row.order_id,
                                "payment_id": row.id,
                                "provider": row.provider,
                                "reference": row.reference,
                                "amount_kobo": row.amount_kobo,
                                "split_amount_kobo": row.split_amount_kobo,
                                "paid_at": (row.paid_at or now).isoformat(),
                            },
                        )
            elif result.status in ("failed", "abandoned", "reversed"):
                row.status = "abandoned" if result.status == "abandoned" else "failed"
                row.failure_reason = (result.gateway_message or result.status)[:500]
                row.updated_at = now
            view = payment_view(row)
        await self.relay.relay_pending()
        return view

    async def handle_webhook(
        self, provider_name: str, raw_body: bytes, headers: Mapping[str, str], client_ip: str | None
    ) -> dict[str, str]:
        provider = self.providers.get(provider_name)
        if provider is None or provider_name in INTERNAL_PROVIDERS:
            raise NotFound("Unknown payment provider")
        if not provider.verify_webhook(raw_body, headers, client_ip):
            log_event(
                logger, "webhook signature rejected", logging.WARNING, provider=provider_name, ip=client_ip
            )
            raise Unauthenticated("Invalid webhook signature")
        event = provider.parse_webhook(raw_body)
        async with self.db.session() as s:
            seen = await s.scalar(
                select(PaymentEvent.id).where(
                    PaymentEvent.provider == provider.name, PaymentEvent.dedupe_key == event.dedupe_key
                )
            )
        if seen:
            return {"status": "duplicate"}

        if event.event_type in ("charge.success", "charge.failed") and event.reference:
            try:
                await self.verify_reference(event.reference, source="webhook")
            except NotFound:
                log_event(logger, "webhook for unknown reference", logging.WARNING, reference=event.reference)
        elif event.event_type in ("refund.processed", "refund.failed"):
            await self._apply_refund_webhook(event.event_type, event.data)

        try:
            async with self.db.transaction() as s:
                s.add(
                    PaymentEvent(
                        provider=provider.name,
                        dedupe_key=event.dedupe_key,
                        event_type=event.raw_event,
                        source="webhook",
                        payload=event.data,
                    )
                )
        except IntegrityError:
            return {"status": "duplicate"}
        return {"status": "processed"}

    async def reconcile_stale(
        self, older_than: timedelta = timedelta(minutes=10), limit: int = 100
    ) -> dict[str, int]:
        cutoff = utcnow() - older_than
        async with self.db.session() as s:
            refs = list(
                (
                    await s.execute(
                        select(PaymentRecord.reference)
                        .where(
                            PaymentRecord.status.in_(("initialized", "pending")),
                            PaymentRecord.provider.not_in(INTERNAL_PROVIDERS),  # cash waits for the rider
                            PaymentRecord.created_at < cutoff,
                        )
                        .order_by(PaymentRecord.created_at)
                        .limit(limit)
                    )
                ).scalars()
            )
        checked = errors = 0
        for ref in refs:
            try:
                await self.verify_reference(ref, source="reconcile")
                checked += 1
            except Exception:
                errors += 1
                logger.exception("reconcile failed", extra={"extra_fields": {"reference": ref}})
        return {"checked": checked, "errors": errors}

    # ============================================================================ refunds
    async def create_refund(
        self,
        *,
        order_id: str,
        amount_kobo: int,
        reason: str,
        liability: Literal["restaurant", "platform"],
        stage: Literal["before_completion", "after_completion"],
        requested_by: str,
        idempotency_key: str,
        auto_approve: bool,
        payment_id: str | None = None,
    ) -> dict[str, Any]:
        """Refund an order. A split-bill group order (several share payments) is refunded to every payer in
        proportion to what they still have paid in; approval is decided on the whole amount."""
        approved = auto_approve or (0 < amount_kobo <= self.refund_auto_approve_limit)
        if payment_id is None:
            parts = await self._split_refund(order_id, amount_kobo)
            if parts:
                views = [
                    await self._create_refund(
                        order_id=order_id,
                        amount_kobo=part,
                        reason=reason,
                        liability=liability,
                        stage=stage,
                        requested_by=requested_by,
                        idempotency_key=f"{idempotency_key}:{pid}",
                        approved=approved,
                        payment_id=pid,
                        process=False,
                    )
                    for pid, part in parts.items()
                    if part > 0
                ]
                # Record every part before paying any out, so the order moves on only with the last one.
                if approved:
                    views = [await self.process_refund(v["id"]) for v in views]
                return views[0]
        return await self._create_refund(
            order_id=order_id,
            amount_kobo=amount_kobo,
            reason=reason,
            liability=liability,
            stage=stage,
            requested_by=requested_by,
            idempotency_key=idempotency_key,
            approved=approved,
            payment_id=payment_id,
        )

    async def _split_refund(self, order_id: str, amount_kobo: int) -> dict[str, int] | None:
        async with self.db.session() as s:
            shares = list(
                (
                    await s.execute(
                        select(PaymentRecord)
                        .where(
                            PaymentRecord.order_id == order_id,
                            PaymentRecord.status == "succeeded",
                            PaymentRecord.purpose == "group_share",
                        )
                        .order_by(PaymentRecord.created_at)
                    )
                ).scalars()
            )
            if not shares:
                return None
            open_rows = (
                await s.execute(
                    select(RefundRecord.payment_id, func.coalesce(func.sum(RefundRecord.amount_kobo), 0))
                    .where(
                        RefundRecord.order_id == order_id,
                        RefundRecord.status.in_(("requested", "approved", "processing")),
                    )
                    .group_by(RefundRecord.payment_id)
                )
            ).all()
        pending = {pid: int(total or 0) for pid, total in open_rows}
        left = {p.id: max(0, p.amount_kobo - p.refunded_kobo - pending.get(p.id, 0)) for p in shares}
        if amount_kobo <= 0 or amount_kobo > sum(left.values()):
            raise ValidationFailed(
                "Refund exceeds the refundable amount", details={"refundable_kobo": sum(left.values())}
            )
        return allocate({pid: v for pid, v in left.items() if v > 0}, amount_kobo)

    async def _create_refund(
        self,
        *,
        order_id: str,
        amount_kobo: int,
        reason: str,
        liability: Literal["restaurant", "platform"],
        stage: Literal["before_completion", "after_completion"],
        requested_by: str,
        idempotency_key: str,
        approved: bool,
        payment_id: str | None,
        process: bool = True,
    ) -> dict[str, Any]:
        async with self.db.transaction() as s:
            existing = await s.scalar(
                select(RefundRecord).where(RefundRecord.idempotency_key == idempotency_key)
            )
            if existing is not None:
                return refund_view(existing)
            stmt = select(PaymentRecord).where(
                PaymentRecord.order_id == order_id, PaymentRecord.status == "succeeded"
            )
            if payment_id:
                stmt = stmt.where(PaymentRecord.id == payment_id)
            captured = list(
                (await s.execute(stmt.order_by(PaymentRecord.created_at).with_for_update())).scalars()
            )
            if not captured:
                raise ValidationFailed("Order has no captured payment to refund")
            payment = captured[-1]
            if len(captured) > 1:  # several payments for one order: refund the one the order is paid with
                order = await self.repos.orders.get(order_id)
                ref = order.payment.reference if order else None
                payment = next((p for p in captured if p.reference == ref), payment)
            open_total = await s.scalar(
                select(func.coalesce(func.sum(RefundRecord.amount_kobo), 0)).where(
                    RefundRecord.payment_id == payment.id,
                    RefundRecord.status.in_(("requested", "approved", "processing")),
                )
            )
            refundable = payment.amount_kobo - payment.refunded_kobo - int(open_total or 0)
            if amount_kobo <= 0 or amount_kobo > refundable:
                raise ValidationFailed(
                    "Refund exceeds the refundable amount", details={"refundable_kobo": refundable}
                )
            destination = await self._refund_destination(payment)
            refund = RefundRecord(
                id=new_id(),
                payment_id=payment.id,
                order_id=order_id,
                amount_kobo=amount_kobo,
                reason=reason[:1000],
                liability=liability,
                stage=stage,
                destination=destination,
                status="approved" if approved else "requested",
                requested_by=requested_by,
                decided_by="system" if approved else None,
                decided_at=utcnow() if approved else None,
                idempotency_key=idempotency_key,
            )
            s.add(refund)
            AuditLog.add(
                s,
                actor_id=requested_by,
                actor_roles=[],
                action="refund.requested",
                resource_type="order",
                resource_id=order_id,
                details={"amount_kobo": amount_kobo, "auto_approved": approved, "destination": destination},
            )
        if approved and process:
            return await self.process_refund(refund.id)
        return refund_view(refund)

    async def _refund_destination(self, payment: PaymentRecord) -> Literal["original", "wallet"]:
        """Wallet and cash payments are refunded into the wallet; card payments go back to the card unless the
        customer chose instant refunds to their wallet."""
        if payment.provider in INTERNAL_PROVIDERS:
            return "wallet"
        if not self.wallet_enabled:
            return "original"
        profile = await self.repos.customers.get(payment.customer_id)
        return "wallet" if profile is not None and profile.refund_to_wallet else "original"

    async def decide_refund(
        self, principal: Principal, refund_id: str, *, approve: bool, note: str | None
    ) -> dict[str, Any]:
        require(principal, Permission.REFUNDS_APPROVE)
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id, with_for_update=True)
            if rec is None:
                raise NotFound("Refund not found")
            if rec.status != "requested":
                raise ValidationFailed(f"Refund is already {rec.status}")
            rec.status = "approved" if approve else "rejected"
            rec.decided_by = principal.uid
            rec.decided_at = utcnow()
            rec.decision_note = (note or "")[:1000] or None
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action="refund.approved" if approve else "refund.rejected",
                resource_type="refund",
                resource_id=rec.id,
                details={"order_id": rec.order_id, "amount_kobo": rec.amount_kobo},
            )
            if not approve:
                add_outbox_event(
                    s,
                    "refund.rejected",
                    {
                        "order_id": rec.order_id,
                        "refund_id": rec.id,
                        "decided_by": principal.uid,
                        "note": rec.decision_note,
                    },
                )
            view = refund_view(rec)
        if approve:
            return await self.process_refund(refund_id)
        await self.relay.relay_pending()
        return view

    async def process_refund(self, refund_id: str) -> dict[str, Any]:
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id, with_for_update=True)
            if rec is None:
                raise NotFound("Refund not found")
            if rec.status != "approved":
                return refund_view(rec)
            to_wallet = rec.destination == "wallet"
            payment = await s.get(PaymentRecord, rec.payment_id)
            assert payment is not None
            if not to_wallet:
                rec.status = "processing"
            ref, txid, provider_name, amount = (
                payment.reference,
                payment.provider_transaction_id,
                payment.provider,
                rec.amount_kobo,
            )
        if to_wallet:
            return await self.complete_refund(refund_id)  # instant: no gateway involved
        try:
            result = await self.provider(provider_name).refund(
                reference=ref, provider_transaction_id=txid, amount_kobo=amount
            )
        except PaymentProviderError as exc:
            async with self.db.transaction() as s:
                rec = await s.get(RefundRecord, refund_id)
                assert rec is not None
                rec.status = "failed"
                rec.decision_note = f"provider error: {exc.message}"[:1000]
                return refund_view(rec)
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id)
            assert rec is not None
            rec.provider_refund_id = result.provider_refund_id
        if result.status == "processed":
            return await self.complete_refund(refund_id)
        if result.status == "failed":
            async with self.db.transaction() as s:
                rec = await s.get(RefundRecord, refund_id)
                assert rec is not None
                rec.status = "failed"
                return refund_view(rec)
        async with self.db.session() as s:
            rec = await s.get(RefundRecord, refund_id)
            assert rec is not None
            return refund_view(rec)  # processing: completed by the refund.processed webhook

    async def complete_refund(self, refund_id: str) -> dict[str, Any]:
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id, with_for_update=True)
            if rec is None:
                raise NotFound("Refund not found")
            if rec.status == "succeeded":
                return refund_view(rec)
            payment = await s.get(PaymentRecord, rec.payment_id, with_for_update=True)
            assert payment is not None
            order = await self.repos.orders.get(rec.order_id)
            to_wallet = rec.destination == "wallet"
            rec.status = "succeeded"
            rec.completed_at = utcnow()
            payment.refunded_kobo += rec.amount_kobo
            payment.updated_at = utcnow()
            short = order.short_code if order else rec.order_id[:6]
            await self.ledger.post(
                s,
                kind="refund",
                idempotency_key=f"refund:{rec.id}",
                postings=postings.refund_issued(
                    provider=payment.provider,
                    amount_kobo=rec.amount_kobo,
                    stage=rec.stage,  # type: ignore[arg-type]
                    liability=rec.liability,  # type: ignore[arg-type]
                    restaurant_id=order.restaurant_id if order else "unknown",
                    to_wallet_of=payment.customer_id if to_wallet else None,
                ),
                created_by="payments",
                reference=payment.reference,
                order_id=rec.order_id,
                description=f"Refund for order {short}",
            )
            add_outbox_event(
                s,
                "refund.succeeded",
                {
                    "order_id": rec.order_id,
                    "refund_id": rec.id,
                    "customer_id": payment.customer_id,
                    "amount_kobo": rec.amount_kobo,
                    "destination": rec.destination,
                    **(await self._refund_totals(s, rec, payment, order)),
                },
            )
            view = refund_view(rec)
        await self.relay.relay_pending()
        return view

    async def _refund_totals(
        self, s: Any, rec: RefundRecord, payment: PaymentRecord, order: Order | None
    ) -> dict[str, Any]:
        """Refund progress for the order: per payment, or across all shares of a split group order (where the
        order changes status only once the last of its refunds has completed)."""
        if payment.purpose != "group_share" or order is None:
            return {
                "total_refunded_kobo": payment.refunded_kobo,
                "fully_refunded": payment.refunded_kobo >= payment.amount_kobo,
                "pending_refunds": 0,
            }
        shares = list(
            (
                await s.execute(
                    select(PaymentRecord).where(
                        PaymentRecord.order_id == rec.order_id,
                        PaymentRecord.status == "succeeded",
                        PaymentRecord.purpose == "group_share",
                    )
                )
            ).scalars()
        )
        remaining = sum(p.amount_kobo - p.refunded_kobo for p in shares)
        pending = await s.scalar(
            select(func.count())
            .select_from(RefundRecord)
            .where(
                RefundRecord.order_id == rec.order_id,
                RefundRecord.id != rec.id,
                RefundRecord.status.in_(("requested", "approved", "processing")),
            )
        )
        return {
            "total_refunded_kobo": max(0, order.breakdown.total_kobo - remaining),
            "fully_refunded": remaining <= 0,
            "pending_refunds": int(pending or 0),
        }

    async def _apply_refund_webhook(self, event_type: str, data: dict[str, Any]) -> None:
        provider_refund_id = str(data.get("id")) if data.get("id") is not None else None
        if not provider_refund_id:
            return
        async with self.db.session() as s:
            rec = await s.scalar(
                select(RefundRecord).where(RefundRecord.provider_refund_id == provider_refund_id)
            )
        if rec is None:
            return
        if event_type == "refund.processed":
            await self.complete_refund(rec.id)
        else:
            async with self.db.transaction() as s:
                row = await s.get(RefundRecord, rec.id)
                if row is not None and row.status == "processing":
                    row.status = "failed"

    async def list_refunds(
        self, principal: Principal, status: str | None = None, limit: int = 100
    ) -> list[dict[str, Any]]:
        require(principal, Permission.REFUNDS_REQUEST)
        stmt = select(RefundRecord).order_by(RefundRecord.created_at.desc()).limit(min(limit, 500))
        if status:
            stmt = stmt.where(RefundRecord.status == status)
        async with self.db.session() as s:
            return [refund_view(r) for r in (await s.execute(stmt)).scalars()]

    async def list_payments(
        self, principal: Principal, status: str | None = None, limit: int = 100
    ) -> list[dict[str, Any]]:
        require(principal, Permission.PAYMENTS_READ)
        stmt = select(PaymentRecord).order_by(PaymentRecord.created_at.desc()).limit(min(limit, 500))
        if status:
            stmt = stmt.where(PaymentRecord.status == status)
        async with self.db.session() as s:
            return [payment_view(r) for r in (await s.execute(stmt)).scalars()]

    async def payments_for_order(self, order_id: str) -> list[dict[str, Any]]:
        async with self.db.session() as s:
            rows = (
                await s.execute(
                    select(PaymentRecord)
                    .where(PaymentRecord.order_id == order_id)
                    .order_by(PaymentRecord.created_at)
                )
            ).scalars()
            return [payment_view(r) for r in rows]

    # ============================================================================ settlement
    async def settle_completed_order(self, order: Order) -> bool:
        if order.is_leg:
            return await self._settle_leg(order)
        async with self.db.transaction() as s:
            captured = await s.scalar(
                select(func.count())
                .select_from(PaymentRecord)
                .where(PaymentRecord.order_id == order.id, PaymentRecord.status == "succeeded")
            )
            if not captured:  # never recognise revenue for money that was not received
                log_event(logger, "settlement skipped: no captured payment", logging.ERROR, order_id=order.id)
                return False
            _, created = await self.ledger.post(
                s,
                kind="order_settlement",
                idempotency_key=f"order:{order.id}:settlement",
                postings=postings.waybill_completed(order)
                if order.is_waybill
                else postings.order_completed(order),
                created_by="system",
                reference=order.short_code,
                order_id=order.id,
                description=f"Order {order.short_code} completed",
                metadata={"restaurant_id": order.restaurant_id, "rider_id": order.rider_id},
            )
            if created and not order.is_parcel and not order.is_waybill:  # courier jobs earn no commission
                s.add(
                    CommissionRecord(
                        order_id=order.id,
                        restaurant_id=order.restaurant_id,
                        base_kobo=order.breakdown.subtotal_kobo,
                        commission_bps=order.settlement.commission_bps,
                        commission_kobo=order.settlement.commission_kobo,
                    )
                )
        await self.repos.orders.update(order.id, {"settled_at": utcnow()})
        return created

    async def _settle_leg(self, order: Order) -> bool:
        """A waybill's first- or last-mile rider job finished: the rider is paid now, as a cost of the shipment.
        The customer's money is recognised when the whole waybill completes."""
        created = False
        if order.rider_id and order.settlement.rider_pay_kobo > 0:
            async with self.db.transaction() as s:
                _, created = await self.ledger.post(
                    s,
                    kind="waybill_leg",
                    idempotency_key=f"order:{order.id}:settlement",
                    postings=postings.leg_rider_pay(order.rider_id, order.settlement.rider_pay_kobo),
                    created_by="system",
                    reference=order.short_code,
                    order_id=order.leg_of,
                    description=f"Rider leg {order.short_code} of waybill",
                    metadata={"leg_order_id": order.id, "leg": order.leg_kind, "rider_id": order.rider_id},
                )
        await self.repos.orders.update(order.id, {"settled_at": utcnow()})
        return created


def _aware(dt: datetime) -> datetime:
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)
