"""Yummy on WhatsApp end to end (ADR-0017), with a recording fake in place of the agents service:
signed webhooks, de-duplication, linking by code, customer-only channel tokens, approvals, disconnecting,
rate limits and service calls without App Check."""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from pydantic import SecretStr

from conftest import auth
from gudmeal_api.domain.whatsapp import signature
from gudmeal_api.errors import Unauthenticated
from gudmeal_api.services.whatsapp import SANDBOX_APP_SECRET, TASK_WHATSAPP_MESSAGE, AgentsError

ADA_PHONE = "2348011111111"
TASKS = TASK_WHATSAPP_MESSAGE


class FakeAgents:
    """Stands in for Yummy: records every call (with its channel token) and returns scripted results."""

    def __init__(self) -> None:
        self.calls: list[tuple[str, str, dict[str, Any]]] = []
        self.results: list[dict[str, Any] | AgentsError] = []

    def _next(self, thread: str | None) -> dict[str, Any]:
        result = self.results.pop(0) if self.results else {"reply": "Hello from Yummy"}
        if isinstance(result, AgentsError):
            raise result
        return {"thread_id": thread or f"t-{len(self.calls)}", "cards": [], "approval": None, **result}

    async def chat(
        self, token: str, message: str, thread_id: str | None, delivery_address: dict | None = None
    ) -> dict[str, Any]:
        call = {"message": message, "thread_id": thread_id}
        if delivery_address:
            call["delivery_address"] = delivery_address
        self.calls.append(("chat", token, call))
        return self._next(thread_id)

    async def approve(
        self, token: str, thread_id: str, approved: bool, tool_call_id: str | None
    ) -> dict[str, Any]:
        self.calls.append(
            ("approve", token, {"thread_id": thread_id, "approved": approved, "tool_call_id": tool_call_id})
        )
        return self._next(thread_id)


def enable(container, agents: FakeAgents | None = None) -> FakeAgents:
    container.settings.whatsapp_enabled = True
    container.settings.whatsapp_verify_token = SecretStr("verify-me")
    fake = agents or FakeAgents()
    container.whatsapp.agents = fake
    return fake


def webhook(
    wa_id: str, *, text: str | None = None, button: tuple[str, str] | None = None, kind: str | None = None
) -> dict:
    message: dict[str, Any] = {"from": wa_id, "id": f"wamid.{uuid.uuid4().hex}", "timestamp": "1700000000"}
    if button:
        message |= {
            "type": "interactive",
            "interactive": {"type": "button_reply", "button_reply": {"id": button[0], "title": button[1]}},
        }
    elif kind:
        message |= {"type": kind, kind: {"id": "media-1"}}
    else:
        message |= {"type": "text", "text": {"body": text or ""}}
    return {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "contacts": [{"wa_id": wa_id, "profile": {"name": "Ada Obi"}}],
                            "messages": [message],
                        },
                    }
                ]
            }
        ],
    }


async def post(client, body: dict, secret: str = SANDBOX_APP_SECRET, sig: str | None = None):
    raw = json.dumps(body).encode()
    headers = {"Content-Type": "application/json", "X-Hub-Signature-256": sig or signature(secret, raw)}
    return await client.post("/v1/webhooks/whatsapp", content=raw, headers=headers)


async def say(client, container, wa_id: str, **kw) -> list[dict]:
    """Send one message as `wa_id`, run the queued task, return the replies sent back."""
    before = len(container.whatsapp.sender.outbox[wa_id])
    r = await post(client, webhook(wa_id, **kw))
    assert r.status_code == 200, r.text
    await container.tasks.run_all(TASKS)
    return container.whatsapp.sender.outbox[wa_id][before:]


def texts(messages: list[dict]) -> list[str]:
    out = []
    for m in messages:
        out.append(m["text"]["body"] if m["type"] == "text" else m["interactive"]["body"]["text"])
    return out


async def link(client, container, who: str = "customer", wa_id: str = ADA_PHONE) -> str:
    code = (await client.post("/v1/me/whatsapp/link-code", headers=auth(who))).json()["code"]
    replies = await say(client, container, wa_id, text=f"LINK {code}")
    assert "You're connected" in texts(replies)[0], replies
    return code


async def test_webhook_verification_signatures_and_deduplication(client, container):
    r = await client.get(
        "/v1/webhooks/whatsapp",
        params={"hub.mode": "subscribe", "hub.verify_token": "verify-me", "hub.challenge": "42"},
    )
    assert r.status_code == 404  # off until configured
    enable(container)
    r = await client.get(
        "/v1/webhooks/whatsapp",
        params={"hub.mode": "subscribe", "hub.verify_token": "verify-me", "hub.challenge": "42"},
    )
    assert r.status_code == 200 and r.text == "42"
    bad = await client.get(
        "/v1/webhooks/whatsapp",
        params={"hub.mode": "subscribe", "hub.verify_token": "nope", "hub.challenge": "42"},
    )
    assert bad.status_code == 403

    body = webhook(ADA_PHONE, text="hello")
    assert (await post(client, body, secret="wrong-secret")).status_code == 401
    assert (await post(client, body, sig="sha256=00")).status_code == 401
    assert (await post(client, body)).json() == {"queued": 1}
    assert (await post(client, body)).json() == {"queued": 0}  # Meta re-delivered the same message
    await container.tasks.run_all(TASKS)
    replies = container.whatsapp.sender.outbox[ADA_PHONE]
    assert len(replies) == 1 and "connect your Yummy Chops account" in texts(replies)[0]
    assert "Profile → Connect WhatsApp" in texts(replies)[0]

    media = await say(client, container, ADA_PHONE, kind="image")
    assert "I can read text messages and shared locations for now" in texts(media)[0]


async def test_linking_by_code_and_disconnecting(client, container):
    agents = enable(container)
    status = (await client.get("/v1/me/whatsapp", headers=auth("customer"))).json()
    assert status["enabled"] is True and status["linked"] is False
    r = await client.post("/v1/me/whatsapp/link-code", headers=auth("customer"))
    assert r.status_code == 201
    code = r.json()["code"]
    assert len(code) == 8 and r.json()["wa_link"].endswith(f"?text=LINK%20{code}")

    wrong = await say(
        client, container, ADA_PHONE, text="LINK 00000000" if code != "00000000" else "LINK 11111111"
    )
    assert "isn't valid or has expired" in texts(wrong)[0]
    linked = await say(client, container, ADA_PHONE, text=f"link {code}")
    assert texts(linked)[0].startswith("You're connected, Ada!")
    status = (await client.get("/v1/me/whatsapp", headers=auth("customer"))).json()
    assert status["linked"] is True and status["number"] == "+234 801 ••• 1111"
    reused = await say(client, container, "2348022222222", text=f"LINK {code}")
    assert "isn't valid" in texts(reused)[0]  # single use
    assert agents.calls == []  # linking never involves Yummy

    help_ = await say(client, container, ADA_PHONE, text="help")
    assert "Send STOP to disconnect" in texts(help_)[0]
    stop = await say(client, container, ADA_PHONE, text="STOP")
    assert "disconnected" in texts(stop)[0]
    assert (await client.get("/v1/me/whatsapp", headers=auth("customer"))).json()["linked"] is False
    after = await say(client, container, ADA_PHONE, text="jollof please")
    assert "connect your Yummy Chops account" in texts(after)[0]
    audit = (await client.get("/v1/admin/audit?resource_type=customer", headers=auth("admin"))).json()
    assert [a["action"] for a in audit][:2] == ["whatsapp.unlinked", "whatsapp.linked"]
    assert all("2348011111111" not in json.dumps(a) for a in audit)  # numbers are masked in the audit log

    # Linking a new number moves the account to it; the app can disconnect too.
    await link(client, container)
    await link(client, container, wa_id="2348033333333")
    assert (await client.get("/v1/me/whatsapp", headers=auth("customer"))).json()[
        "number"
    ] == "+234 803 ••• 3333"
    old = await say(client, container, ADA_PHONE, text="hi")
    assert "connect your Yummy Chops account" in texts(old)[0]
    r = await client.delete("/v1/me/whatsapp", headers=auth("customer"))
    assert r.status_code == 200 and r.json()["linked"] is False


async def test_conversations_use_customer_only_tokens_and_approvals(client, container):
    agents = enable(container)
    await link(client, container)
    agents.results.append(
        {
            "reply": "Here are 2 plans under ₦10,000.",
            "cards": [{"type": "navigate", "screen": "plus", "params": {}, "label": "Open Yummy Chops Plus"}],
        }
    )
    replies = await say(client, container, ADA_PHONE, text="jollof for 2 under 10k")
    assert texts(replies) == [
        "Here are 2 plans under ₦10,000.\n\nOpen Yummy Chops Plus: http://localhost:3000/plus"
    ]
    kind, token, call = agents.calls[-1]
    assert kind == "chat" and call == {"message": "jollof for 2 under 10k", "thread_id": None}

    # The API accepts Yummy's delegated token as the customer, and only as a customer.
    me = await client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200 and me.json()["uid"] == "cust-1"
    assert (
        await client.get("/v1/admin/ledger", headers={"Authorization": f"Bearer {token}"})
    ).status_code == 403

    # An order needs the customer's Yes: buttons, a tap, or a typed answer.
    agents.results.append(
        {
            "reply": "Plan 1 is ready.",
            "approval": {
                "type": "approval_required",
                "tool": "confirm_order",
                "tool_call_id": "call-1",
                "preview": {
                    "title": "Place order GM12AB from Jollof Junction?",
                    "message": "You'll pay ₦9,450.",
                },
            },
        }
    )
    ask = await say(client, container, ADA_PHONE, text="order plan 1")
    assert agents.calls[-1][2]["thread_id"] == "t-1"  # same conversation as before
    buttons = ask[1]["interactive"]["action"]["buttons"]
    assert [b["reply"]["id"] for b in buttons] == ["approve:call-1", "decline:call-1"]
    agents.results.append(AgentsError(409, "Please approve or decline the pending action first"))
    nudge = await say(client, container, ADA_PHONE, text="what drinks do you have")
    assert texts(nudge)[0].startswith("Please answer this first: Place order GM12AB")
    agents.results.append(
        {
            "reply": "Pay below.",
            "cards": [{"type": "payment_link", "url": "https://pay.example/x", "amount": "₦9,450"}],
        }
    )
    paid = await say(client, container, ADA_PHONE, button=("approve:call-1", "Yes, go ahead"))
    assert agents.calls[-1][:1] == ("approve",) and agents.calls[-1][2] == {
        "thread_id": "t-1",
        "approved": True,
        "tool_call_id": "call-1",
    }
    assert paid[1]["interactive"]["action"]["parameters"]["url"] == "https://pay.example/x"

    agents.results.append(
        {
            "reply": "Shall I book it?",
            "approval": {"tool_call_id": "call-2", "preview": {"title": "Book a package?"}},
        }
    )
    await say(client, container, ADA_PHONE, text="send a package to Yaba")
    agents.results.append({"reply": "Okay, I won't book it."})
    await say(client, container, ADA_PHONE, text="No thanks")
    assert agents.calls[-1][2] == {"thread_id": "t-1", "approved": False, "tool_call_id": "call-2"}

    # A conversation idle for a day starts afresh; a vanished thread is replaced; Yummy being down is explained.
    await container.repos.store.update(
        f"whatsapp_links/{ADA_PHONE}", {"last_at": datetime.now(UTC) - timedelta(days=2)}
    )
    await say(client, container, ADA_PHONE, text="hi again")
    assert agents.calls[-1][2]["thread_id"] is None
    agents.results.extend([AgentsError(404, "Thread not found"), {"reply": "New chat"}])
    gone = await say(client, container, ADA_PHONE, text="hello?")
    assert agents.calls[-2][2]["thread_id"] is not None and agents.calls[-1][2]["thread_id"] is None
    assert texts(gone) == ["New chat"]
    agents.results.append(AgentsError(503, "down"))
    down = await say(client, container, ADA_PHONE, text="hello?")
    assert texts(down)[0].startswith("Sorry, I can't answer right now")


async def test_staff_accounts_are_only_customers_on_whatsapp(client, container):
    agents = enable(container)
    await link(client, container, who="admin", wa_id="2348099999999")
    await say(client, container, "2348099999999", text="show me the ledger")
    token = agents.calls[-1][1]
    assert (
        await client.get("/v1/admin/ledger", headers={"Authorization": f"Bearer {token}"})
    ).status_code == 403
    assert (await client.get("/v1/admin/ledger", headers=auth("admin"))).status_code == 200


async def test_limits_and_disabled_channel(client, container):
    assert (
        await client.post("/v1/me/whatsapp/link-code", headers=auth("customer"))
    ).status_code == 422  # off
    enable(container)
    for _ in range(5):
        assert (await client.post("/v1/me/whatsapp/link-code", headers=auth("customer2"))).status_code == 201
    assert (await client.post("/v1/me/whatsapp/link-code", headers=auth("customer2"))).status_code == 429
    for _ in range(5):
        await say(client, container, "2348044444444", text="LINK 12345670")
    tired = await say(client, container, "2348044444444", text="LINK 12345670")
    assert "Too many tries" in texts(tired)[0]
    await link(client, container)
    replies: list[str] = []
    for _ in range(30):  # a burst of 20 messages per number is fine (1 was the link), then one every 5 s
        replies.append(texts(await say(client, container, ADA_PHONE, text="hi"))[0])
        if "sending messages quickly" in replies[-1]:
            break
    assert replies[:18] == ["Hello from Yummy"] * 18 and "sending messages quickly" in replies[-1]
    assert 20 <= len(replies) <= 25
    long = await say(client, container, "2348055555555", text="x" * 1001)
    assert "a bit long" in texts(long)[0]


class StrictAppCheck:
    async def verify(self, token: str) -> None:
        if token != "good-app":
            raise Unauthenticated("Invalid App Check token")


async def test_app_check_admits_our_own_services(client, container):
    container.app_check = StrictAppCheck()
    assert (await client.get("/v1/me", headers=auth("customer"))).status_code == 401
    ok = await client.get("/v1/me", headers={**auth("customer"), "X-Firebase-AppCheck": "good-app"})
    assert ok.status_code == 200
    service = await client.get(
        "/v1/me", headers={**auth("customer"), "X-Internal-Token": "test-internal-secret"}
    )
    assert service.status_code == 200 and service.json()["uid"] == "cust-1"
    forged = await client.get("/v1/me", headers={**auth("customer"), "X-Internal-Token": "guess"})
    assert forged.status_code == 401
    assert (
        await client.get("/v1/me", headers={"X-Internal-Token": "test-internal-secret"})
    ).status_code == 401  # a user is still needed


async def test_cloud_api_sender_and_the_local_simulator(client, container):
    import httpx

    from gudmeal_api.domain.whatsapp import text_message
    from gudmeal_api.services.whatsapp import CloudApiSender, WhatsAppSendError

    seen: list[httpx.Request] = []

    def meta(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if json.loads(request.content)["to"] == "2340000000000":
            return httpx.Response(400, json={"error": {"code": 131030, "message": "Recipient not allowed"}})
        return httpx.Response(200, json={"messages": [{"id": "wamid.out"}]})

    async with httpx.AsyncClient(transport=httpx.MockTransport(meta)) as http:
        sender = CloudApiSender(http, token="test-token", phone_number_id="1055", version="v21.0")
        await sender.send(ADA_PHONE, text_message("Hi"))
        try:
            await sender.send("2340000000000", text_message("Hi"))
            raise AssertionError("expected a send error")
        except WhatsAppSendError as exc:
            assert "131030" in str(exc) and "2340000000000" not in str(exc)  # the number is masked
    assert str(seen[0].url) == "https://graph.facebook.com/v21.0/1055/messages"
    assert seen[0].headers["authorization"] == "Bearer test-token"
    assert json.loads(seen[0].content) == {
        "messaging_product": "whatsapp",
        "recipient_type": "individual",
        "to": ADA_PHONE,
        "type": "text",
        "text": {"body": "Hi", "preview_url": True},
    }

    enable(container)
    page = await client.get("/v1/dev/whatsapp")
    assert page.status_code == 200 and "Yummy on WhatsApp" in page.text
    r = await client.post(f"/v1/dev/whatsapp/{ADA_PHONE}/send", json={"text": "hello", "name": "Ada"})
    assert r.json() == {"queued": 1}
    await container.tasks.run_all(TASKS)
    convo = (await client.get(f"/v1/dev/whatsapp/{ADA_PHONE}/messages")).json()
    assert convo[0] == {"direction": "in", "type": "text", "text": {"body": "hello"}}
    assert "connect your Yummy Chops account" in convo[1]["text"]["body"]


async def test_shared_locations_become_the_delivery_address(client, container):
    agents = enable(container)
    await link(client, container)
    r = await post(
        client,
        {
            "object": "whatsapp_business_account",
            "entry": [
                {
                    "changes": [
                        {
                            "field": "messages",
                            "value": {
                                "messages": [
                                    {
                                        "from": ADA_PHONE,
                                        "id": "wamid.loc1",
                                        "type": "location",
                                        "location": {
                                            "latitude": 6.4473,
                                            "longitude": 7.5214,
                                            "name": "Independence Layout",
                                        },
                                    }
                                ]
                            },
                        }
                    ]
                }
            ],
        },
    )
    assert r.json() == {"queued": 1}
    await container.tasks.run_all(TASKS)
    assert (
        "Got it, I'll deliver to Independence Layout"
        in texts(container.whatsapp.sender.outbox[ADA_PHONE][-1:])[0]
    )
    assert agents.calls == []  # remembering a place needs no Yummy call
    await say(client, container, ADA_PHONE, text="rice for 2 under 8000")
    address = agents.calls[-1][2]["delivery_address"]
    assert address["city"] == "Enugu" and address["location"] == {"lat": 6.4473, "lng": 7.5214}
    assert address["line1"] == "Independence Layout"
    r = await client.post(
        f"/v1/dev/whatsapp/{ADA_PHONE}/send",
        json={"latitude": 6.4478, "longitude": 3.4723, "place": "Lekki Phase 1"},
    )
    assert r.json() == {"queued": 1}
    await container.tasks.run_all(TASKS)
    await say(client, container, ADA_PHONE, text="and some drinks")
    assert agents.calls[-1][2]["delivery_address"]["city"] == "Lagos"
