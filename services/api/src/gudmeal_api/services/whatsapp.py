"""Yummy on WhatsApp (ADR-0017): webhook intake, account linking and conversations through the agents service.

Flow: Meta → signed webhook (verified, de-duplicated) → Cloud Task → ``WhatsAppService.handle`` → for a linked
number, a short-lived customer-only channel token → Yummy (``POST /v1/chat`` on the agents service, same tools,
permissions and approvals as the app) → reply rendered for WhatsApp → Cloud API (or the local sandbox).
"""

from __future__ import annotations

import json
import logging
import secrets
from collections import defaultdict
from datetime import UTC, datetime, timedelta
from typing import Any, Protocol

import httpx

from ..config import Settings
from ..domain.whatsapp import (
    HELP_COMMAND,
    LINK_COMMAND,
    MAX_INBOUND_CHARS,
    NO,
    STOP_COMMAND,
    YES,
    approval_message,
    digits,
    mask,
    parse_webhook,
    render_result,
    shared_location_address,
    signature_ok,
    support_line,
    text_message,
)
from ..errors import Conflict, NotFound, PermissionDenied, RateLimited, Unauthenticated, ValidationFailed
from ..ledger.audit import AuditLog
from ..repositories import Repositories, Transaction
from ..security.channel_tokens import mint
from ..security.compare import same_secret
from ..security.rate_limit import RateLimiter
from ..security.rbac import Principal
from .infra import TaskQueue

logger = logging.getLogger(__name__)
TASK_WHATSAPP_MESSAGE = "/internal/tasks/whatsapp-message"
# Not a credential: a fixed value the local simulator and tests sign fake webhooks with. Outside local/test the
# real Meta app secret is required (see Settings.validate_for_environment).
SANDBOX_APP_SECRET = "local-whatsapp-sandbox"  # noqa: S105
CODE_TTL = timedelta(minutes=10)
THREAD_IDLE = timedelta(hours=24)
DEDUPE_TTL = timedelta(days=7)


def utcnow() -> datetime:
    return datetime.now(UTC)


def _first(name: str | None) -> str:
    return (name or "").strip().split(" ")[0][:40]


# ------------------------------------------------------------------------------------------- senders
class WhatsAppSender(Protocol):
    async def send(self, to: str, message: dict[str, Any]) -> None: ...


#: How long a yes-or-no question waits for its answer before a new message replaces it.
PENDING_TTL = timedelta(minutes=15)


class WhatsAppSendError(Exception):
    pass


class CloudApiSender:
    """WhatsApp Business Cloud API: POST /{phone-number-id}/messages with the system-user access token."""

    def __init__(self, http: httpx.AsyncClient, *, token: str, phone_number_id: str, version: str) -> None:
        self.http = http
        self.url = f"https://graph.facebook.com/{version}/{phone_number_id}/messages"
        self.headers = {"Authorization": f"Bearer {token}"}

    async def send(self, to: str, message: dict[str, Any]) -> None:
        body = {"messaging_product": "whatsapp", "recipient_type": "individual", "to": to, **message}
        r = await self.http.post(self.url, json=body, headers=self.headers, timeout=15)
        if r.status_code >= 300:
            code = (
                (r.json().get("error") or {}).get("code")
                if r.headers.get("content-type", "").startswith("application/json")
                else None
            )
            raise WhatsAppSendError(f"WhatsApp send failed ({r.status_code}, code {code}) to {mask(to)}")


class SandboxSender:
    """Records outgoing messages instead of sending them (local development, the simulator and tests)."""

    def __init__(self) -> None:
        self.outbox: dict[str, list[dict[str, Any]]] = defaultdict(list)

    async def send(self, to: str, message: dict[str, Any]) -> None:
        self.outbox[to].append({"at": utcnow().isoformat(), **message})


# ------------------------------------------------------------------------------------------- Yummy
class AgentsError(Exception):
    def __init__(self, status: int, message: str) -> None:
        super().__init__(message)
        self.status = status
        self.message = message


class AgentsClient:
    """Calls Yummy (the agents service) as the customer, with a delegated channel token."""

    def __init__(self, http: httpx.AsyncClient, base_url: str) -> None:
        self.http = http
        self.base = base_url.rstrip("/")

    async def _post(self, path: str, token: str, body: dict[str, Any]) -> dict[str, Any]:
        try:
            r = await self.http.post(
                f"{self.base}{path}", json=body, headers={"Authorization": f"Bearer {token}"}, timeout=90
            )
        except httpx.HTTPError as exc:
            raise AgentsError(503, "Yummy is not reachable") from exc
        if r.status_code >= 300:
            try:
                detail = r.json().get("detail") or r.text
            except ValueError:
                detail = r.text
            raise AgentsError(r.status_code, str(detail)[:200])
        return dict(r.json())

    async def chat(
        self, token: str, message: str, thread_id: str | None, delivery_address: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        body: dict[str, Any] = {"message": message, "channel": "whatsapp"}
        if thread_id:
            body["thread_id"] = thread_id
        if delivery_address:
            body["delivery_address"] = delivery_address
        return await self._post("/v1/chat", token, body)

    async def approve(
        self, token: str, thread_id: str, approved: bool, tool_call_id: str | None
    ) -> dict[str, Any]:
        return await self._post(
            f"/v1/chat/{thread_id}/approval", token, {"approved": approved, "tool_call_id": tool_call_id}
        )


class Agents(Protocol):
    async def chat(
        self, token: str, message: str, thread_id: str | None, delivery_address: dict[str, Any] | None = None
    ) -> dict[str, Any]: ...

    async def approve(
        self, token: str, thread_id: str, approved: bool, tool_call_id: str | None
    ) -> dict[str, Any]: ...


# ------------------------------------------------------------------------------------------- the channel
class WhatsAppService:
    def __init__(
        self,
        repos: Repositories,
        *,
        settings: Settings,
        sender: WhatsAppSender,
        agents: Agents,
        tasks: TaskQueue,
        rate_limiter: RateLimiter,
        audit: AuditLog,
    ) -> None:
        self.repos = repos
        self.settings = settings
        self.sender = sender
        self.agents = agents
        self.tasks = tasks
        self.rate_limiter = rate_limiter
        self.audit = audit
        secret = settings.whatsapp_app_secret.get_secret_value() if settings.whatsapp_app_secret else None
        self.app_secret = secret or (SANDBOX_APP_SECRET if settings.environment in ("local", "test") else "")
        self.web_url = settings.public_web_url.rstrip("/")

    @property
    def enabled(self) -> bool:
        return self.settings.whatsapp_enabled and bool(self.app_secret)

    @property
    def business_number(self) -> str:
        return self.settings.whatsapp_business_number

    # ------------------------------------------------------------------------------------------- webhook
    def verify_subscription(self, mode: str | None, token: str | None, challenge: str | None) -> str:
        expected = (
            self.settings.whatsapp_verify_token.get_secret_value()
            if self.settings.whatsapp_verify_token
            else ""
        )
        if not self.enabled:
            raise NotFound("WhatsApp is not enabled")
        if mode != "subscribe" or not expected or not same_secret(expected, token):
            raise PermissionDenied("Webhook verification failed")
        return challenge or ""

    async def receive(self, raw: bytes, signature_header: str | None) -> int:
        """Verify, de-duplicate and queue each incoming message; Meta gets its 200 straight away."""
        if not self.enabled:
            raise NotFound("WhatsApp is not enabled")
        if not signature_ok(self.app_secret, raw, signature_header):
            raise Unauthenticated("Invalid webhook signature")
        try:
            body = json.loads(raw)
        except ValueError as exc:
            raise ValidationFailed("Malformed webhook body") from exc
        queued = 0
        now = utcnow()
        for message in parse_webhook(body):
            try:
                await self.repos.store.create(
                    f"whatsapp_messages/{message.message_id}",
                    {"received_at": now, "expire_at": now + DEDUPE_TTL},
                )
            except Conflict:
                continue  # Meta re-delivered a message we already have
            await self.tasks.enqueue(TASK_WHATSAPP_MESSAGE, message.task_payload())
            queued += 1
        return queued

    # ------------------------------------------------------------------------------------------- a message
    async def _say(self, wa_id: str, text: str) -> None:
        await self.sender.send(wa_id, text_message(text))

    def _support_line(self) -> str:
        return support_line(self.settings.support_contacts())

    async def handle(self, payload: dict[str, Any]) -> None:
        wa_id = str(payload["wa_id"])
        text = str(payload.get("text") or "").strip()
        try:
            self.rate_limiter.check(f"whatsapp:{wa_id}", capacity=20, refill_per_second=0.2)
        except RateLimited:
            return await self._say(
                wa_id, "You're sending messages quickly. Give me a moment, then try again."
            )
        if payload.get("kind") == "unsupported":
            return await self._say(
                wa_id,
                "I can read text messages and shared locations for now. Type what you need, for example: jollof "
                "rice for 2 under ₦10,000.",
            )
        if len(text) > MAX_INBOUND_CHARS:
            return await self._say(wa_id, "That message is a bit long for me. Please send a shorter one.")
        code = LINK_COMMAND.match(text)
        if code:
            return await self._connect(wa_id, code.group(1))
        link = await self.repos.store.get(f"whatsapp_links/{wa_id}")
        if link is None:
            name = _first(payload.get("name"))
            return await self._say(
                wa_id,
                f"Hi{' ' + name if name else ''}! I'm Yummy from Yummy Chops. To order food, groceries, foodstuff, "
                f"pharmacy or beauty products, or send packages here, connect your Yummy Chops account: in the app "
                f"open Profile → Connect WhatsApp (or {self.web_url}/account), then send me the code it shows.\n"
                f"New to Yummy Chops? Sign up at "
                f"{self.web_url}.\n{self._support_line()}",
            )
        if payload.get("kind") == "location":
            return await self._remember_location(wa_id, payload)
        if STOP_COMMAND.match(text):
            return await self._disconnect(wa_id, link)
        if HELP_COMMAND.match(text):
            return await self._say(wa_id, self._help(link.get("name")))
        await self._converse(wa_id, link, payload, text)

    def _help(self, name: str | None) -> str:
        return (
            f"I'm Yummy{', ' + _first(name) if name else ''}. Ask me in English, Pidgin, Igbo, Yoruba or Hausa:\n"
            "• food, groceries, foodstuff, pharmacy or beauty products, e.g. 'jollof rice for 2 under ₦10,000'\n"
            "• 'send a package to Yaba' or 'send to Abuja'\n"
            "• 'where is my order', 'my points', 'Yummy Chops Plus'\n"
            "Share your location (📎 → Location) and I'll find stores that deliver to you; otherwise I use the "
            "first address saved in your app.\n"
            "You approve every order with a Yes button and pay on the secure payment page.\n"
            "Send STOP to disconnect WhatsApp."
        )

    async def _remember_location(self, wa_id: str, payload: dict[str, Any]) -> None:
        """Deliveries in this chat go to the location the customer shared (until they share another)."""
        place = str(payload.get("text") or "").strip()
        location = {
            "lat": float(payload["latitude"]),
            "lng": float(payload["longitude"]),
            "name": place or None,
            "at": utcnow(),
        }
        await self.repos.store.update(f"whatsapp_links/{wa_id}", {"location": location})
        await self._say(
            wa_id,
            f"Got it, I'll deliver to {place or 'the location you shared'} in this chat. What would you like? For "
            "example: jollof rice for 2 under ₦10,000.",
        )

    async def _converse(self, wa_id: str, link: dict[str, Any], payload: dict[str, Any], text: str) -> None:
        now = utcnow()
        token = mint(
            self.settings.channel_token_secret.get_secret_value(),
            uid=str(link["uid"]),
            name=link.get("name"),
            channel="whatsapp",
        )
        button = str(payload.get("button_id") or "")
        pending = link.get("pending")
        thread = link.get("thread_id")
        last = link.get("last_at")
        asked_at = (pending or {}).get("at")
        if pending and thread and asked_at and now - asked_at > PENDING_TTL and not button:
            try:
                await self.agents.approve(token, thread, False, pending.get("tool_call_id"))
            except AgentsError:
                thread = None  # the old conversation cannot be cleared: start a new one
            pending = None
        try:
            if button.startswith(("approve:", "decline:")) and thread:
                result = await self.agents.approve(
                    token, thread, button.startswith("approve:"), button.split(":", 1)[1] or None
                )
            elif pending and thread and (YES.match(text) or NO.match(text)):
                result = await self.agents.approve(
                    token, thread, bool(YES.match(text)), pending.get("tool_call_id")
                )
            else:
                fresh = not thread or last is None or now - last > THREAD_IDLE
                address = shared_location_address(link["location"]) if link.get("location") else None
                try:
                    result = await self.agents.chat(token, text, None if fresh else thread, address)
                except AgentsError as exc:
                    if exc.status == 404 and not fresh:  # the old conversation is gone: start a new one
                        result = await self.agents.chat(token, text, None, address)
                    elif exc.status == 409 and pending:  # an order is waiting for Yes or No
                        await self.sender.send(
                            wa_id,
                            approval_message(
                                {
                                    "tool_call_id": pending.get("tool_call_id"),
                                    "preview": {
                                        "title": f"Please answer this first: {pending.get('title') or 'shall I go ahead?'}"
                                    },
                                }
                            ),
                        )
                        return
                    else:
                        raise
        except AgentsError as exc:
            if exc.status == 409:
                await self.repos.store.update(f"whatsapp_links/{wa_id}", {"pending": None, "thread_id": None})
                return await self._say(wa_id, "That request is out of date. Tell me again what you'd like.")
            if exc.status == 429:
                return await self._say(
                    wa_id, "You're sending messages quickly. Give me a moment, then try again."
                )
            logger.error(
                "gudy unavailable for a WhatsApp message", extra={"extra_fields": {"status": exc.status}}
            )
            return await self._say(
                wa_id,
                f"Sorry, I can't answer right now. Please try again in a few minutes. {self._support_line()}",
            )
        approval = result.get("approval")
        await self.repos.store.update(
            f"whatsapp_links/{wa_id}",
            {
                "thread_id": result.get("thread_id") or thread,
                "last_at": now,
                "pending": {
                    "tool_call_id": approval.get("tool_call_id"),
                    "title": (approval.get("preview") or {}).get("title"),
                    "at": now,
                }
                if approval
                else None,
            },
        )
        for message in render_result(result, self.web_url):
            await self.sender.send(wa_id, message)

    # ------------------------------------------------------------------------------------------- linking
    async def _connect(self, wa_id: str, code: str) -> None:
        try:
            self.rate_limiter.check(f"whatsapp_link:{wa_id}", capacity=5, refill_per_second=5 / 3600)
        except RateLimited:
            return await self._say(
                wa_id, "Too many tries. Get a fresh code in the Yummy Chops app and try again later."
            )
        now = utcnow()

        async def fn(tx: Transaction) -> tuple[str, str | None] | None:
            c = await tx.get(f"whatsapp_link_codes/{code}")
            if c is None or c.get("used_at") or c["expires_at"] <= now:
                return None
            uid = str(c["uid"])
            previous_number = await tx.get(f"whatsapp_accounts/{uid}")
            previous_account = await tx.get(f"whatsapp_links/{wa_id}")
            tx.update(f"whatsapp_link_codes/{code}", {"used_at": now})
            if previous_number and previous_number.get("wa_id") != wa_id:
                tx.delete(f"whatsapp_links/{previous_number['wa_id']}")  # one number per account
            if previous_account and previous_account.get("uid") != uid:
                tx.delete(f"whatsapp_accounts/{previous_account['uid']}")  # one account per number
            tx.set(
                f"whatsapp_links/{wa_id}",
                {
                    "wa_id": wa_id,
                    "uid": uid,
                    "name": c.get("name"),
                    "linked_at": now,
                    "thread_id": None,
                    "last_at": None,
                    "pending": None,
                },
            )
            tx.set(f"whatsapp_accounts/{uid}", {"uid": uid, "wa_id": wa_id, "linked_at": now})
            return uid, c.get("name")

        linked = await self.repos.store.run_transaction(fn)
        if linked is None:
            return await self._say(
                wa_id,
                "That code isn't valid or has expired. Get a new one in the Yummy Chops app: Profile → Connect WhatsApp.",
            )
        uid, name = linked
        await self.audit.record(
            actor_id=uid,
            actor_roles=["customer"],
            action="whatsapp.linked",
            resource_type="customer",
            resource_id=uid,
            details={"number": mask(wa_id)},
        )
        await self._say(
            wa_id,
            f"You're connected{', ' + _first(name) if name else ''}! I'm Yummy. Ask me for food, groceries, "
            "foodstuff, pharmacy or beauty products, a package delivery, your order status, your points or Yummy "
            "Chops Plus, for example: 'jollof rice for 2 "
            "under ₦10,000'. Share your location (📎 → Location) so I can find stores that deliver to you. You approve every order with a Yes button. Send HELP for tips or STOP to disconnect.",
        )

    async def _disconnect(self, wa_id: str, link: dict[str, Any]) -> None:
        await self._remove(wa_id, str(link["uid"]))
        await self._say(
            wa_id,
            "WhatsApp is disconnected from your Yummy Chops account. You can connect again from the app any time.",
        )

    async def _remove(self, wa_id: str, uid: str) -> None:
        async def fn(tx: Transaction) -> None:
            account = await tx.get(f"whatsapp_accounts/{uid}")
            tx.delete(f"whatsapp_links/{wa_id}")
            if account and account.get("wa_id") == wa_id:
                tx.delete(f"whatsapp_accounts/{uid}")

        await self.repos.store.run_transaction(fn)
        await self.audit.record(
            actor_id=uid,
            actor_roles=["customer"],
            action="whatsapp.unlinked",
            resource_type="customer",
            resource_id=uid,
            details={"number": mask(wa_id)},
        )

    # ------------------------------------------------------------------------------------------- customers
    def _wa_link(self, text: str | None = None) -> str:
        url = f"https://wa.me/{digits(self.business_number)}"
        return f"{url}?text={text.replace(' ', '%20')}" if text else url

    async def status(self, principal: Principal) -> dict[str, Any]:
        account = await self.repos.store.get(f"whatsapp_accounts/{principal.uid}")
        return {
            "enabled": self.enabled,
            "linked": account is not None,
            "number": mask(str(account["wa_id"])) if account else None,
            "linked_at": account.get("linked_at") if account else None,
            "business_number": self.business_number,
            "chat_link": self._wa_link() if account else None,
        }

    async def create_link_code(self, principal: Principal) -> dict[str, Any]:
        if not self.enabled:
            raise ValidationFailed("WhatsApp ordering isn't available yet")
        self.rate_limiter.check(f"whatsapp_code:{principal.uid}", capacity=5, refill_per_second=5 / 3600)
        now = utcnow()
        for _ in range(5):
            code = f"{secrets.randbelow(10**8):08d}"
            try:
                await self.repos.store.create(
                    f"whatsapp_link_codes/{code}",
                    {
                        "uid": principal.uid,
                        "name": principal.name,
                        "created_at": now,
                        "expires_at": now + CODE_TTL,
                        "expire_at": now + timedelta(days=1),
                        "used_at": None,
                    },
                )
            except Conflict:
                continue
            return {
                "code": code,
                "expires_at": now + CODE_TTL,
                "business_number": self.business_number,
                "wa_link": self._wa_link(f"LINK {code}"),
            }
        raise Conflict("Could not create a code, please try again")

    async def unlink(self, principal: Principal) -> dict[str, Any]:
        account = await self.repos.store.get(f"whatsapp_accounts/{principal.uid}")
        if account is not None:
            await self._remove(str(account["wa_id"]), principal.uid)
        return await self.status(principal)


__all__ = [
    "SANDBOX_APP_SECRET",
    "TASK_WHATSAPP_MESSAGE",
    "AgentsClient",
    "AgentsError",
    "CloudApiSender",
    "SandboxSender",
    "WhatsAppService",
]
