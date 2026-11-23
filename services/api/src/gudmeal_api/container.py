"""Composition root: builds every adapter and service from Settings and wires events and tasks."""

from __future__ import annotations

import logging
import secrets
from collections.abc import Callable
from dataclasses import dataclass, field
from typing import Any
from urllib.parse import urlsplit

import httpx

from .config import Settings
from .domain.dispatch import DispatchConfig
from .domain.money import format_naira
from .lan import reachable_base_url
from .ledger.audit import AuditLog
from .ledger.db import Database
from .ledger.idempotency import IdempotencyService
from .ledger.ledger import LedgerService
from .ledger.outbox import OutboxRelay
from .maps import MapsService
from .payments.base import PaymentProvider
from .payments.flutterwave import FlutterwaveProvider
from .payments.paystack import PaystackProvider
from .payments.sandbox import LocalSandboxProvider
from .repositories import DocumentStore, MemoryDocumentStore, Repositories
from .security.auth import AppCheckVerifier, TokenVerifier
from .security.channel_tokens import ChannelTokenVerifier
from .security.rate_limit import RateLimiter
from .services import dispatch as dispatch_mod
from .services import orders as orders_mod
from .services.admin import AdminService, AnalyticsService
from .services.cash import CashService
from .services.catalog import CatalogService
from .services.dispatch import DispatchService
from .services.engagement import (
    ApplicationService,
    MealPlanService,
    ProfileService,
    ReviewService,
    SupportService,
)
from .services.group_orders import GroupOrderService
from .services.infra import (
    CloudTasksQueue,
    Emitter,
    EventBus,
    EventHandlers,
    IdentityAdmin,
    InProcessEventBus,
    InProcessTaskQueue,
    Notifier,
    PubSubEventBus,
    TaskQueue,
    TaskRouter,
)
from .services.membership import MembershipService
from .services.orders import OrderService
from .services.parcels import ParcelService
from .services.payments import PaymentService
from .services.quotes import QuoteService
from .services.receipts import ReceiptService
from .services.rewards import RewardsService
from .services.wallet import WalletService
from .services.waybills import WaybillService
from .services.whatsapp import (
    TASK_WHATSAPP_MESSAGE,
    AgentsClient,
    CloudApiSender,
    SandboxSender,
    WhatsAppService,
)

logger = logging.getLogger(__name__)


@dataclass
class Container:
    settings: Settings
    repos: Repositories
    db: Database
    ledger: LedgerService
    audit: AuditLog
    idempotency: IdempotencyService
    handlers: EventHandlers
    bus: EventBus
    relay: OutboxRelay
    emitter: Emitter
    task_router: TaskRouter
    tasks: TaskQueue
    notifier: Notifier
    identity: IdentityAdmin
    verifier: TokenVerifier
    app_check: AppCheckVerifier | None
    rate_limiter: RateLimiter
    providers: dict[str, PaymentProvider]
    http: httpx.AsyncClient
    catalog: CatalogService
    quotes: QuoteService
    parcels: ParcelService
    payments: PaymentService
    wallet: WalletService
    cash: CashService
    waybills: WaybillService
    membership: MembershipService
    rewards: RewardsService
    receipts: ReceiptService
    groups: GroupOrderService
    whatsapp: WhatsAppService
    orders: OrderService
    dispatch: DispatchService
    profiles: ProfileService
    applications: ApplicationService
    reviews: ReviewService
    support: SupportService
    meal_plans: MealPlanService
    analytics: AnalyticsService
    admin: AdminService
    maps: MapsService
    sandbox: LocalSandboxProvider | None = None
    extras: dict[str, Any] = field(default_factory=dict)

    async def close(self) -> None:
        await self.http.aclose()
        await self.db.dispose()


def _payment_providers(
    settings: Settings, http: httpx.AsyncClient
) -> tuple[dict[str, PaymentProvider], LocalSandboxProvider | None]:
    providers: dict[str, PaymentProvider] = {}
    if settings.paystack_secret_key:
        providers["paystack"] = PaystackProvider(
            settings.paystack_secret_key.get_secret_value(),
            http=http,
            base_url=settings.paystack_base_url,
            ip_allowlist=settings.paystack_webhook_ip_allowlist,
        )
    if settings.flutterwave_secret_key and settings.flutterwave_secret_hash:
        providers["flutterwave"] = FlutterwaveProvider(
            settings.flutterwave_secret_key.get_secret_value(),
            settings.flutterwave_secret_hash.get_secret_value(),
            http=http,
            base_url=settings.flutterwave_base_url,
        )
    sandbox = None
    if settings.environment in ("local", "test"):
        sandbox = LocalSandboxProvider(
            public_base_url=_sandbox_base_url(settings), signing_secret=secrets.token_hex(32)
        )
        providers[sandbox.name] = sandbox
    return providers, sandbox


def _sandbox_base_url(settings: Settings) -> str | Callable[[], str]:
    """Where the payment sandbox page is served: PUBLIC_BASE_URL, or, with SANDBOX_FOLLOWS_LAN_ADDRESS on (phone
    tests), an address the paying phone can reach: the one it reached this API at (see lan.reachable_base_url)."""
    if not settings.sandbox_follows_lan_address:
        return settings.public_base_url
    port = urlsplit(settings.public_base_url).port or 8000
    return lambda: reachable_base_url(port, settings.public_base_url)


def _payment_callback_url(settings: Settings) -> str | Callable[[], str]:
    """Where a card payment page (Paystack, or the sandbox) sends the payer back: PAYMENT_CALLBACK_URL, the
    website's callback page. In phone tests (SANDBOX_FOLLOWS_LAN_ADDRESS) that is this computer's own localhost,
    which the paying phone cannot open, so the payer comes back to this API's "return to the app" page instead
    (/v1/dev/payment-return), at an address the phone can reach."""
    url = settings.payment_callback_url
    if (
        settings.environment not in ("local", "test")
        or not settings.sandbox_follows_lan_address
        or urlsplit(url).hostname not in ("localhost", "127.0.0.1")
    ):
        return url
    port = urlsplit(settings.public_base_url).port or 8000
    return lambda: f"{reachable_base_url(port, settings.public_base_url)}/v1/dev/payment-return"


async def build_container(
    settings: Settings,
    *,
    store: DocumentStore | None = None,
    db: Database | None = None,
    verifier: TokenVerifier | None = None,
    app_check: AppCheckVerifier | None = None,
    identity: IdentityAdmin | None = None,
    http: httpx.AsyncClient | None = None,
    task_queue: Any = None,
    extra_providers: dict[str, PaymentProvider] | None = None,
) -> Container:
    settings.validate_for_environment()

    # --- data ----------------------------------------------------------------------------------
    if store is None:
        if settings.data_backend == "firestore":
            from .repositories.firestore_store import FirestoreDocumentStore

            store = FirestoreDocumentStore.from_project(settings.gcp_project_id)
        else:
            store = MemoryDocumentStore()
    repos = Repositories(store)
    if db is None:
        db = Database(settings.database_url, echo=settings.database_echo)
        if settings.environment in ("local", "test") and db.dialect == "sqlite":
            await db.create_all()

    # --- identity --------------------------------------------------------------------------------
    firebase_app = None
    if verifier is None or identity is None or (settings.app_check_enforced and app_check is None):
        from .security.auth import get_firebase_app

        firebase_app = get_firebase_app(settings.firebase_project_id)
    if verifier is None:
        from .security.auth import FirebaseTokenVerifier

        verifier = FirebaseTokenVerifier(firebase_app, check_revoked=settings.check_token_revocation)
    if identity is None:
        from .services.infra import FirebaseIdentityAdmin

        identity = FirebaseIdentityAdmin(firebase_app)
    if settings.app_check_enforced and app_check is None:
        from .security.auth import FirebaseAppCheckVerifier

        app_check = FirebaseAppCheckVerifier(firebase_app)

    # --- async infrastructure ---------------------------------------------------------------------
    handlers = EventHandlers()
    bus: EventBus = (
        PubSubEventBus(settings.gcp_project_id, settings.pubsub_topic)
        if settings.event_bus == "pubsub"
        else InProcessEventBus(handlers)
    )
    task_router = TaskRouter()
    if task_queue is not None:
        tasks = task_queue(task_router) if callable(task_queue) else task_queue
    elif settings.task_queue == "cloudtasks":
        if not settings.cloud_tasks_service_account or not settings.internal_oidc_audience:
            raise RuntimeError("Cloud Tasks requires CLOUD_TASKS_SERVICE_ACCOUNT and INTERNAL_OIDC_AUDIENCE")
        tasks = CloudTasksQueue(
            project_id=settings.gcp_project_id,
            location=settings.cloud_tasks_location,
            queue=settings.cloud_tasks_queue,
            base_url=settings.public_base_url,
            service_account=settings.cloud_tasks_service_account,
            audience=settings.internal_oidc_audience,
        )
    else:
        tasks = InProcessTaskQueue(task_router)

    http = http or httpx.AsyncClient(timeout=settings.payment_http_timeout_seconds)
    maps = MapsService.from_settings(settings, http)
    providers, sandbox = _payment_providers(settings, http)
    providers.update(extra_providers or {})
    default_provider = settings.payment_default_provider
    if default_provider not in providers and sandbox is not None:
        default_provider = sandbox.name

    ledger = LedgerService()
    audit = AuditLog(db)
    relay = OutboxRelay(db, bus)
    emitter = Emitter(bus)
    notifier = Notifier(repos, use_fcm=settings.notifier == "fcm")

    # --- services ----------------------------------------------------------------------------------
    catalog = CatalogService(repos)
    quotes = QuoteService(repos, ttl_seconds=settings.quote_ttl_seconds, maps=maps)
    payments = PaymentService(
        db=db,
        ledger=ledger,
        audit=audit,
        relay=relay,
        repos=repos,
        providers=providers,
        default_provider=default_provider,
        callback_url=_payment_callback_url(settings),
        email_fallback_domain=settings.customer_email_fallback_domain,
        refund_auto_approve_limit_kobo=settings.refund_auto_approve_limit_kobo,
        failover_provider=settings.payment_failover_provider,
        wallet_enabled=settings.wallet_enabled,
    )
    cash = CashService(
        repos=repos,
        db=db,
        ledger=ledger,
        audit=audit,
        enabled=settings.pay_on_delivery_enabled,
        max_order_kobo=settings.pay_on_delivery_max_kobo,
        min_completed_orders=settings.pay_on_delivery_min_completed_orders,
        rider_cash_limit_kobo=settings.rider_cash_limit_kobo,
    )
    wallet = WalletService(
        repos=repos,
        db=db,
        ledger=ledger,
        payments=payments,
        cash=cash,
        enabled=settings.wallet_enabled,
        min_topup_kobo=settings.wallet_min_topup_kobo,
        max_topup_kobo=settings.wallet_max_topup_kobo,
        max_balance_kobo=settings.wallet_max_balance_kobo,
    )
    orders = OrderService(
        repos,
        quotes,
        emitter=emitter,
        notifier=notifier,
        tasks=tasks,
        payments=payments,
        cash=cash,
        restaurant_accept_timeout_seconds=settings.restaurant_accept_timeout_seconds,
        unpaid_order_ttl_seconds=settings.unpaid_order_ttl_seconds,
        code_max_attempts=settings.delivery_code_max_attempts,
    )
    dispatch = DispatchService(
        repos,
        orders,
        tasks=tasks,
        notifier=notifier,
        emitter=emitter,
        offer_timeout_seconds=settings.dispatch_offer_timeout_seconds,
        reoffer_after_seconds=settings.dispatch_reoffer_seconds,
        config=DispatchConfig(max_pickup_radius_km=settings.dispatch_pickup_radius_km),
        rider_cash_limit_kobo=settings.rider_cash_limit_kobo,
        maps=maps,
    )
    analytics = AnalyticsService(repos)
    rate_limiter = RateLimiter()
    wa_sender: CloudApiSender | SandboxSender = SandboxSender()
    if (
        settings.whatsapp_provider == "cloud"
        and settings.whatsapp_access_token
        and settings.whatsapp_phone_number_id
    ):
        wa_sender = CloudApiSender(
            http,
            token=settings.whatsapp_access_token.get_secret_value(),
            phone_number_id=settings.whatsapp_phone_number_id,
            version=settings.whatsapp_graph_version,
        )
    container = Container(
        settings=settings,
        repos=repos,
        db=db,
        ledger=ledger,
        audit=audit,
        idempotency=IdempotencyService(db),
        handlers=handlers,
        bus=bus,
        relay=relay,
        emitter=emitter,
        task_router=task_router,
        tasks=tasks,
        notifier=notifier,
        identity=identity,
        verifier=ChannelTokenVerifier(settings.channel_token_secret.get_secret_value(), verifier),
        app_check=app_check,
        rate_limiter=rate_limiter,
        providers=providers,
        http=http,
        catalog=catalog,
        quotes=quotes,
        parcels=ParcelService(repos, maps=maps),
        payments=payments,
        wallet=wallet,
        cash=cash,
        waybills=WaybillService(
            repos,
            orders,
            tasks=tasks,
            notifier=notifier,
            audit=audit,
            unpaid_order_ttl_seconds=settings.unpaid_order_ttl_seconds,
        ),
        membership=MembershipService(repos, payments, db=db, ledger=ledger, notifier=notifier),
        rewards=RewardsService(repos, notifier=notifier, audit=audit),
        receipts=ReceiptService(repos),
        whatsapp=WhatsAppService(
            repos,
            settings=settings,
            sender=wa_sender,
            agents=AgentsClient(http, settings.agents_base_url),
            tasks=tasks,
            rate_limiter=rate_limiter,
            audit=audit,
        ),
        groups=GroupOrderService(
            repos,
            quotes,
            orders,
            payments,
            notifier=notifier,
            unpaid_order_ttl_seconds=settings.unpaid_order_ttl_seconds,
        ),
        orders=orders,
        dispatch=dispatch,
        profiles=ProfileService(repos),
        applications=ApplicationService(repos, identity, audit, notifier),
        reviews=ReviewService(repos, orders),
        support=SupportService(repos, orders, audit),
        meal_plans=MealPlanService(repos),
        analytics=analytics,
        admin=AdminService(
            repos=repos, db=db, ledger=ledger, audit=audit, identity=identity, analytics=analytics
        ),
        maps=maps,
        sandbox=sandbox,
    )
    register_handlers(container)
    return container


def register_handlers(c: Container) -> None:
    async def refund_from_event(payload: dict[str, Any]) -> None:
        meta = payload.get("metadata") or payload
        amount = meta.get("refund_amount_kobo")
        if not amount:
            return
        key = payload.get("event_id") or payload.get("payment_id")
        await c.payments.create_refund(
            order_id=str(payload["order_id"]),
            amount_kobo=int(amount),
            reason=str(meta.get("reason") or payload.get("reason") or "Order refund"),
            liability=meta.get("refund_liability", "platform"),
            stage=meta.get("refund_stage", "before_completion"),
            requested_by="system",
            idempotency_key=f"order:{payload['order_id']}:refund:{key}",
            auto_approve=bool(meta.get("refund_auto_approve")),
            payment_id=payload.get("payment_id") if not payload.get("event_id") else None,
        )

    async def wallet_topped_up(payload: dict[str, Any]) -> None:
        await c.notifier.notify_user(
            str(payload["customer_id"]),
            "Wallet topped up",
            f"{format_naira(int(payload['amount_kobo']))} was added to your Yummy Chops wallet",
            {"screen": "wallet"},
        )

    async def refund_in_wallet(payload: dict[str, Any]) -> None:
        if payload.get("destination") == "wallet" and payload.get("customer_id"):
            await c.notifier.notify_user(
                str(payload["customer_id"]),
                "Refund in your wallet",
                f"{format_naira(int(payload['amount_kobo']))} is back in your Yummy Chops wallet",
                {"order_id": str(payload["order_id"]), "screen": "wallet"},
            )

    async def dispatch_start(payload: dict[str, Any]) -> None:
        if payload.get("fulfillment") == "delivery":
            await c.dispatch.start(str(payload["order_id"]))

    async def settle(payload: dict[str, Any]) -> None:
        order = await c.repos.orders.get(str(payload["order_id"]))
        if order is not None and order.settled_at is None:
            await c.payments.settle_completed_order(order)

    h = c.handlers
    h.on("payment.succeeded", c.orders.on_payment_succeeded)
    h.on("payment.orphaned", refund_from_event)
    h.on("order.refund_pending", refund_from_event)
    h.on("refund.succeeded", c.orders.on_refund_succeeded)
    h.on("refund.succeeded", refund_in_wallet)
    h.on("wallet.topped_up", wallet_topped_up)
    h.on("plus.paid", c.membership.on_paid)
    h.on("order.completed", c.rewards.on_order_completed)
    h.on("order.refunded", c.rewards.on_order_refunded)
    h.on("order.partially_refunded", c.rewards.on_order_refunded)
    # Group orders: share payments, and refunds of paid shares when the order is called off unpaid.
    h.on("group_share.paid", c.groups.on_share_paid)
    h.on("order.cancelled", c.groups.on_order_called_off)
    h.on("order.cancelled", c.payments.on_order_cancelled)
    h.on("order.cancelled", c.dispatch.on_order_called_off)
    h.on("order.refund_pending", c.dispatch.on_order_called_off)
    # Interstate waybills: booking follow-up after payment, rider legs moving the shipment, call-offs.
    h.on("waybill.paid", c.waybills.on_paid)
    h.on("order.picked_up", c.waybills.on_leg_event)
    h.on("order.delivered", c.waybills.on_leg_event)
    h.on("order.refund_pending", c.waybills.on_called_off)
    h.on("order.cancelled", c.waybills.on_called_off)
    h.on("refund.rejected", c.orders.on_refund_rejected)
    h.on("order.restaurant_accepted", dispatch_start)
    h.on("order.preparing", dispatch_start)
    h.on("order.ready_for_pickup", dispatch_start)
    h.on("order.delivered", c.dispatch.on_order_delivered)
    h.on("order.delivered", c.orders.complete_after_delivery)
    h.on("order.completed", settle)

    r = c.task_router
    r.route(orders_mod.TASK_RESTAURANT_TIMEOUT, c.orders.restaurant_timeout)
    r.route(orders_mod.TASK_UNPAID_EXPIRY, c.orders.expire_unpaid)
    r.route(orders_mod.TASK_PARCEL_RELEASE, c.orders.release_parcel)
    r.route(dispatch_mod.TASK_OFFER_TIMEOUT, c.dispatch.handle_offer_timeout)
    r.route(dispatch_mod.TASK_DISPATCH_RETRY, c.dispatch.retry)
    r.route(TASK_WHATSAPP_MESSAGE, c.whatsapp.handle)
