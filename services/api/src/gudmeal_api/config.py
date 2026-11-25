"""Runtime configuration (12-factor). Every value can be set through environment variables.

Secrets are `SecretStr` so they never appear in logs or reprs. Unsafe settings stop the service at start-up
(see `Settings.validate_for_environment`): a few everywhere, more on any server in the cloud, all of them in
staging and production.
"""

from __future__ import annotations

import os
from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

Environment = Literal["local", "test", "development", "staging", "production"]

# Local-only placeholders: every server in the cloud refuses to start with them (validate_for_environment).
DEFAULT_CODE_PEPPER = "local-dev-pepper-change-me"
DEFAULT_CHANNEL_TOKEN_SECRET = "local-dev-channel-secret-change-me"  # noqa: S105
#: Environment variables that point the Google SDKs at a local emulator. The sign-in emulator accepts unsigned
#: tokens with any roles, so none of them may be set on a server in the cloud.
EMULATOR_SWITCHES = (
    "FIREBASE_AUTH_EMULATOR_HOST",
    "FIRESTORE_EMULATOR_HOST",
    "FIREBASE_STORAGE_EMULATOR_HOST",
    "STORAGE_EMULATOR_HOST",
)
MIN_SECRET_LENGTH = 32


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    # --- service ---------------------------------------------------------------------------
    environment: Environment = "local"
    service_name: str = "gudmeal-api"
    log_level: str = "INFO"
    public_base_url: str = "http://localhost:8000"
    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:3000",  # customer web
            "http://localhost:3001",  # partner dashboard
            "http://localhost:3002",  # command centre
            "http://localhost:5050",  # Flutter customer app (web debug)
        ]
    )

    # How many of our own proxies stand in front of this service and append the caller's address to
    # X-Forwarded-For: 1 on Cloud Run, 2 behind a load balancer as well, 0 when callers connect directly
    # (api/deps.py client_ip). Entries before those are whatever the caller sent.
    trusted_proxy_hops: int = 1
    # The largest request body accepted (a rider's KYC photo, 5 MB, arrives base64-encoded in JSON: about 7 MB).
    max_request_bytes: int = 8 * 1024 * 1024

    # --- data ------------------------------------------------------------------------------
    data_backend: Literal["memory", "firestore"] = "memory"
    seed_demo_data: bool = (
        True  # at start-up with the memory backend; online test server: /internal/jobs/seed-demo
    )
    gcp_project_id: str = "demo-gudmeal"
    database_url: str = "sqlite+aiosqlite:///./gudmeal_local.db"
    database_echo: bool = False

    # --- auth ------------------------------------------------------------------------------
    firebase_project_id: str = "demo-gudmeal"
    app_check_enforced: bool = False
    check_token_revocation: bool = True

    # --- payments --------------------------------------------------------------------------
    payment_default_provider: Literal["paystack", "flutterwave"] = "paystack"
    payment_callback_url: str = "http://localhost:3000/checkout/callback"
    paystack_secret_key: SecretStr | None = None
    paystack_base_url: str = "https://api.paystack.co"
    paystack_webhook_ip_allowlist: list[str] = Field(default_factory=list)
    flutterwave_secret_key: SecretStr | None = None
    flutterwave_secret_hash: SecretStr | None = None
    flutterwave_base_url: str = "https://api.flutterwave.com/v3"
    customer_email_fallback_domain: str = "customers.yummy247.com"
    refund_auto_approve_limit_kobo: int = 0  # 0 = every refund needs finance approval
    payment_http_timeout_seconds: float = 15.0
    # Backup gateway tried when the default one fails to start a checkout (only if it is configured).
    payment_failover_provider: str | None = "flutterwave"
    # Split card payments (ADR-0028): a business's share reaches its bank before the order is finished, and a refund
    # comes out of Yummy Chops' balance. So a shop's unfinished split money is capped: past this, or while the shop
    # owes money back, its card payments are not split and it is paid in the weekly settlement instead.
    split_exposure_limit_kobo: int = 20_000_000  # ₦200,000

    # --- Yummy Chops wallet (closed-loop stored value: spend on Yummy Chops only, no cash withdrawal) ---------
    # Limits are product defaults pending legal/CBN review (see docs/adr/0013-wallet-and-cash.md).
    wallet_enabled: bool = True
    wallet_min_topup_kobo: int = 50_000  # ₦500
    wallet_max_topup_kobo: int = 10_000_000  # ₦100,000 per top-up
    wallet_max_balance_kobo: int = 30_000_000  # ₦300,000

    # --- private files (rider KYC documents; services/files.py) ------------------------------------
    # memory: tests; local: the git-ignored UPLOADS_DIR on this computer; gcs: STORAGE_BUCKET (staging, production).
    file_store: Literal["memory", "local", "gcs"] = "local"
    uploads_dir: str = ".uploads"
    storage_bucket: str | None = None

    # --- pay on delivery (cash to the rider) --------------------------------------------------------
    pay_on_delivery_enabled: bool = True  # the `pay_on_delivery` feature flag can switch it off live
    pay_on_delivery_max_kobo: int = 2_500_000  # ₦25,000 per order
    pay_on_delivery_min_completed_orders: int = 1  # build trust with one prepaid order first
    rider_cash_limit_kobo: int = 5_000_000  # riders carry at most ₦50,000 of collected cash

    # --- internal endpoints (Pub/Sub push, Cloud Tasks, Scheduler) -----------------------------
    internal_auth_mode: Literal["shared_secret", "oidc"] = "shared_secret"
    internal_shared_secret: SecretStr | None = None
    internal_oidc_audience: str | None = None
    internal_oidc_service_accounts: list[str] = Field(default_factory=list)
    # Yummy Chops' own services (the agents service) that may call user endpoints without App Check. They still
    # need the user's token, and this list does not open /internal/* (that is INTERNAL_OIDC_SERVICE_ACCOUNTS).
    trusted_service_accounts: list[str] = Field(default_factory=list)

    # --- async infrastructure ----------------------------------------------------------------
    event_bus: Literal["inprocess", "pubsub"] = "inprocess"
    pubsub_topic: str = "gudmeal-domain-events"
    task_queue: Literal["inprocess", "cloudtasks"] = "inprocess"
    cloud_tasks_location: str = "europe-west1"
    cloud_tasks_queue: str = "gudmeal-default"
    cloud_tasks_service_account: str | None = None

    # --- notifications -------------------------------------------------------------------------
    notifier: Literal["log", "fcm"] = "log"

    # --- customer support contacts (the apps' Support tab, Yummy and WhatsApp messages) ------------
    # An empty contact does not exist yet: the apps show it as "coming soon" and Yummy and WhatsApp leave it out,
    # so no made-up number is ever shown. The email is the real customer-care mailbox (Zoho Mail on yummy247.com,
    # docs/DEPLOYMENT.md §5b); set SUPPORT_WHATSAPP and SUPPORT_PHONE once the owner has real numbers.
    support_whatsapp: str = ""
    support_phone: str = ""
    support_email: str = "customercare@yummy247.com"
    support_hours: str = "Every day, 8am to 10pm"

    # --- business rules -----------------------------------------------------------------------
    quote_ttl_seconds: int = 600
    unpaid_order_ttl_seconds: int = 1800
    restaurant_accept_timeout_seconds: int = 480
    dispatch_offer_timeout_seconds: int = 45
    # First search radius around the pickup; it widens by 3 km each round with nobody to ask (up to 30 km).
    dispatch_pickup_radius_km: float = 6.0
    # A rider who missed an offer (it ran out) is asked again for the same job after this long.
    dispatch_reoffer_seconds: int = 300
    # Testing only, refused in staging and production: the local stack (ENVIRONMENT=local with the seeded demo data)
    # and the online test server (ENVIRONMENT=development, through /internal/jobs/seed-demo and /demo-shops; ADR-0026):
    demo_shops_always_open: bool = False  # demo shops take orders around the clock
    demo_shop_autopilot: bool = (
        False  # demo shops accept and pack orders by themselves (nobody at the dashboard)
    )
    # Phone tests: the payment sandbox page opens at the address this computer has on its Wi-Fi right now,
    # not at PUBLIC_BASE_URL (the address changes when the computer joins another Wi-Fi). The sandbox exists
    # only when ENVIRONMENT is local or test, so the switch does nothing anywhere else.
    sandbox_follows_lan_address: bool = False
    delivery_code_max_attempts: int = 5
    code_pepper: SecretStr = SecretStr(DEFAULT_CODE_PEPPER)

    # --- maps ---------------------------------------------------------------------------------
    # Server key for Places (New), Geocoding and Routes. Never shipped to apps or browsers; without it the
    # API uses its neighbourhood table and straight-line estimates (clearly labelled as estimates).
    google_maps_api_key: SecretStr | None = None
    maps_travel_mode: Literal["DRIVE", "TWO_WHEELER"] = "DRIVE"
    # Traffic-aware routes give better Lagos ETAs but bill at Google's higher Routes tier; false = cheaper tier.
    maps_traffic_aware: bool = True
    # How often a live delivery's road ETA may be re-measured (between measurements it counts down locally).
    maps_live_eta_refresh_seconds: int = 180
    maps_routes_enabled: bool = True
    maps_timeout_seconds: float = 4.0
    maps_daily_request_cap: int = 20_000  # per instance; GCP quotas + budget alerts are the hard limit

    # --- Yummy on WhatsApp (ADR-0017): off until the Meta account, number and keys exist -----------
    whatsapp_enabled: bool = False
    whatsapp_provider: Literal["sandbox", "cloud"] = "sandbox"
    whatsapp_access_token: SecretStr | None = None  # permanent system-user token (Secret Manager)
    whatsapp_app_secret: SecretStr | None = None  # signs Meta's webhooks (X-Hub-Signature-256)
    whatsapp_verify_token: SecretStr | None = None  # chosen by us, entered in the Meta webhook settings
    whatsapp_phone_number_id: str | None = None
    whatsapp_business_number: str = "+234 000 000 0000"
    whatsapp_graph_version: str = "v21.0"
    # Delegated customer-only tokens for chat channels; shared with the agents service.
    channel_token_secret: SecretStr = SecretStr(DEFAULT_CHANNEL_TOKEN_SECRET)
    agents_base_url: str = "http://localhost:8100"
    public_web_url: str = "http://localhost:3000"

    @property
    def is_cloud(self) -> bool:
        return self.environment in ("development", "staging", "production")

    def support_contacts(self) -> dict[str, str]:
        """The support contacts that exist, in the order people see them: whatsapp, phone, email."""
        contacts = {
            "whatsapp": self.support_whatsapp.strip(),
            "phone": self.support_phone.strip(),
            "email": self.support_email.strip(),
        }
        return {kind: value for kind, value in contacts.items() if value}

    def validate_for_environment(self) -> None:
        """Fail fast on unsafe configuration: two rules everywhere, more for every server in the cloud (the online
        test server included) and the full list for staging and production."""
        problems: list[str] = []
        paystack = self.paystack_secret_key.get_secret_value() if self.paystack_secret_key else ""
        if paystack.startswith("sk_live_") and self.environment != "production":
            problems.append("a live Paystack key (sk_live_...) is allowed only in production")
        if os.environ.get("K_SERVICE") and not self.is_cloud:
            # Cloud Run sets K_SERVICE. ENVIRONMENT defaults to local, which opens /v1/dev and the pretend payments.
            problems.append("ENVIRONMENT must be development, staging or production on Cloud Run")
        if self.is_cloud:
            problems += self._cloud_problems()
        if self.environment in ("staging", "production"):
            problems += self._release_problems(paystack)
        if problems:
            raise RuntimeError("Unsafe configuration: " + "; ".join(problems))

    def _cloud_problems(self) -> list[str]:
        """What no server reachable from the internet may run with, whatever it is for."""
        problems = [
            f"{name} must not be set: the emulators accept unsigned sign-ins"
            for name in EMULATOR_SWITCHES
            if os.environ.get(name)
        ]
        if self.sandbox_follows_lan_address:
            problems.append("SANDBOX_FOLLOWS_LAN_ADDRESS is for phone tests on this computer only")
        channel = self.channel_token_secret.get_secret_value()
        if channel == DEFAULT_CHANNEL_TOKEN_SECRET or len(channel) < MIN_SECRET_LENGTH:
            problems.append(
                f"CHANNEL_TOKEN_SECRET must be set from Secret Manager ({MIN_SECRET_LENGTH} characters or more)"
            )
        internal = self.internal_shared_secret.get_secret_value() if self.internal_shared_secret else ""
        if self.internal_auth_mode == "shared_secret" and internal and len(internal) < MIN_SECRET_LENGTH:
            problems.append(f"INTERNAL_SHARED_SECRET must be {MIN_SECRET_LENGTH} characters or more")
        if self.file_store != "gcs" or not self.storage_bucket:
            problems.append("FILE_STORE=gcs and STORAGE_BUCKET are required (riders' KYC documents)")
        return problems

    def _release_problems(self, paystack: str) -> list[str]:
        problems: list[str] = []
        if self.data_backend != "firestore":
            problems.append("DATA_BACKEND must be 'firestore'")
        if self.database_url.startswith("sqlite"):
            problems.append("DATABASE_URL must point to PostgreSQL")
        if self.internal_auth_mode != "oidc":
            problems.append("INTERNAL_AUTH_MODE must be 'oidc'")
        if not self.internal_oidc_audience or not self.internal_oidc_service_accounts:
            problems.append("INTERNAL_OIDC_AUDIENCE and INTERNAL_OIDC_SERVICE_ACCOUNTS are required")
        pepper = self.code_pepper.get_secret_value()
        if pepper == DEFAULT_CODE_PEPPER or len(pepper) < MIN_SECRET_LENGTH:
            problems.append(
                f"CODE_PEPPER must be set from Secret Manager ({MIN_SECRET_LENGTH} characters or more)"
            )
        if self.payment_default_provider == "paystack" and not paystack:
            problems.append("PAYSTACK_SECRET_KEY is required")
        if self.environment == "production" and paystack.startswith("sk_test_"):
            problems.append("PAYSTACK_SECRET_KEY must be the live key in production (it is a test key)")
        if self.event_bus != "pubsub" or self.task_queue != "cloudtasks":
            problems.append("EVENT_BUS=pubsub and TASK_QUEUE=cloudtasks are required")
        if self.seed_demo_data:
            problems.append("SEED_DEMO_DATA must be false")
        if self.demo_shops_always_open or self.demo_shop_autopilot:
            problems.append("DEMO_SHOPS_ALWAYS_OPEN and DEMO_SHOP_AUTOPILOT are for local testing only")
        if self.environment == "production" and not self.app_check_enforced:
            problems.append("APP_CHECK_ENFORCED must be true in production")
        if self.app_check_enforced and not self.trusted_service_accounts:
            problems.append(
                "TRUSTED_SERVICE_ACCOUNTS must list the agents service account (Yummy's tool calls)"
            )
        if self.whatsapp_enabled and not (
            self.whatsapp_provider == "cloud"
            and self.whatsapp_access_token
            and self.whatsapp_app_secret
            and self.whatsapp_verify_token
            and self.whatsapp_phone_number_id
        ):
            problems.append(
                "WHATSAPP_ENABLED needs WHATSAPP_PROVIDER=cloud and the WhatsApp access token, app secret, "
                "verify token and phone number id"
            )
        return problems


@lru_cache
def get_settings() -> Settings:
    return Settings()
