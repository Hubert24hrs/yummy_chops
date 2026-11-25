"""Yummy on WhatsApp (ADR-0017): channel tokens, webhook signatures, inbound parsing and reply rendering."""

import json
import time

import pytest

from gudmeal_api.config import Settings
from gudmeal_api.domain.whatsapp import (
    HELP_COMMAND,
    LINK_COMMAND,
    NO,
    STOP_COMMAND,
    YES,
    buttons_message,
    digits,
    mask,
    parse_webhook,
    render_result,
    shared_location_address,
    signature,
    signature_ok,
    support_line,
    text_message,
)
from gudmeal_api.errors import Unauthenticated
from gudmeal_api.security import channel_tokens as ct
from gudmeal_api.security.auth import StaticTokenVerifier
from gudmeal_api.security.rbac import Principal

SECRET = "test-channel-secret"


class TestChannelTokens:
    def test_round_trip_carries_only_the_customer_role(self):
        token = ct.mint(SECRET, uid="cust-1", name="Ada Obi", channel="whatsapp")
        assert token.startswith("gmc1.") and ct.is_channel_token(token)
        claims = ct.verify(SECRET, token)
        assert claims["uid"] == "cust-1" and claims["roles"] == ["customer"] and claims["ch"] == "whatsapp"
        assert claims["exp"] - claims["iat"] == 600

    def test_tampering_wrong_secret_expiry_and_garbage_are_refused(self):
        token = ct.mint(SECRET, uid="cust-1", channel="whatsapp")
        prefix, payload, sig = token.split(".")
        forged = json.loads(ct._unb64(payload)) | {"uid": "admin-1", "roles": ["super_admin"]}
        tampered = f"{prefix}.{ct._b64(json.dumps(forged).encode())}.{sig}"
        for bad in (tampered, token + "x", "gmc1.abc", "not-a-token", token.replace("gmc1", "gmc2", 1)):
            with pytest.raises(ValueError):
                ct.verify(SECRET, bad)
        with pytest.raises(ValueError, match="signature"):
            ct.verify("another-secret", token)
        old = ct.mint(SECRET, uid="cust-1", channel="whatsapp", now=time.time() - 601)
        with pytest.raises(ValueError, match="Expired"):
            ct.verify(SECRET, old)
        future = ct.mint(SECRET, uid="cust-1", channel="whatsapp", now=time.time() + 3600)
        with pytest.raises(ValueError, match="Expired"):
            ct.verify(SECRET, future)
        with pytest.raises(ValueError):
            ct.mint(SECRET, uid="cust-1", channel="sms")

    async def test_verifier_turns_tokens_into_customers_and_leaves_other_tokens_alone(self):
        staff = Principal(uid="admin-1", roles=frozenset({"customer", "super_admin"}))
        verifier = ct.ChannelTokenVerifier(SECRET, StaticTokenVerifier({"admin": staff}))
        principal = await verifier.verify(ct.mint(SECRET, uid="admin-1", name="Super", channel="whatsapp"))
        assert principal.uid == "admin-1" and principal.roles == frozenset(
            {"customer"}
        )  # never staff on WhatsApp
        assert (await verifier.verify("admin")).roles == staff.roles
        with pytest.raises(Unauthenticated):
            await verifier.verify(ct.mint("wrong", uid="cust-1", channel="whatsapp"))


class TestWebhooks:
    def test_signatures(self):
        raw = b'{"object":"whatsapp_business_account"}'
        good = signature("app-secret", raw)
        assert good.startswith("sha256=") and signature_ok("app-secret", raw, good)
        assert not signature_ok("app-secret", raw + b" ", good)
        assert not signature_ok("other", raw, good)
        assert not signature_ok("app-secret", raw, None)
        assert not signature_ok("app-secret", raw, good.removeprefix("sha256="))

    def test_parse_messages_buttons_and_unsupported_types(self):
        body = {
            "object": "whatsapp_business_account",
            "entry": [
                {
                    "changes": [
                        {"field": "account_update", "value": {}},
                        {
                            "field": "messages",
                            "value": {
                                "contacts": [{"wa_id": "2348011111111", "profile": {"name": "Ada Obi"}}],
                                "messages": [
                                    {
                                        "from": "2348011111111",
                                        "id": "wamid.1",
                                        "timestamp": "1700000000",
                                        "type": "text",
                                        "text": {"body": "jollof for 2"},
                                    },
                                    {
                                        "from": "2348011111111",
                                        "id": "wamid.2",
                                        "type": "interactive",
                                        "interactive": {
                                            "type": "button_reply",
                                            "button_reply": {
                                                "id": "approve:call-1",
                                                "title": "Yes, go ahead",
                                            },
                                        },
                                    },
                                    {
                                        "from": "2348011111111",
                                        "id": "wamid.3",
                                        "type": "image",
                                        "image": {"id": "m1"},
                                    },
                                    {
                                        "from": "not-a-number",
                                        "id": "wamid.4",
                                        "type": "text",
                                        "text": {"body": "x"},
                                    },
                                ],
                                "statuses": [{"id": "wamid.0", "status": "read"}],
                            },
                        },
                    ]
                }
            ],
        }
        msgs = parse_webhook(body)
        assert [(m.message_id, m.kind) for m in msgs] == [
            ("wamid.1", "text"),
            ("wamid.2", "button"),
            ("wamid.3", "unsupported"),
        ]
        assert (
            msgs[0].text == "jollof for 2" and msgs[0].name == "Ada Obi" and msgs[0].timestamp == 1700000000
        )
        assert msgs[1].button_id == "approve:call-1"
        assert msgs[0].task_payload()["wa_id"] == "2348011111111"
        assert parse_webhook({}) == []

    def test_commands_and_answers(self):
        assert LINK_COMMAND.match("LINK 12345678").group(1) == "12345678"
        assert LINK_COMMAND.match(" link: 12345678 ") and not LINK_COMMAND.match("link 123456")
        assert STOP_COMMAND.match("Stop") and not STOP_COMMAND.match("stop the order please")
        assert HELP_COMMAND.match("menu")
        for word in ("yes", "Yes please", "ok", "oya", "ee"):
            assert YES.match(word), word
        for word in ("no", "No thanks", "mba", "rara", "a'a"):
            assert NO.match(word), word
        assert not YES.match("nope") and not NO.match("yes")
        # Only a whole-message answer counts: these are questions or other requests.
        for text in (
            "Ok how long will it take?",
            "Eh? not that one",
            "yes but change the address",
            "no, wait",
        ):
            assert not YES.match(text) and not NO.match(text), text
        assert YES.match("Okay, thanks!") and NO.match("No thank you.")


class TestRendering:
    def test_masking_and_limits(self):
        assert mask("2348011111111") == "+234 801 ••• 1111"
        assert mask("123") == "•••"
        assert digits("+234 800 GUD 0001") == "2348000001"
        assert len(text_message("x" * 5000)["text"]["body"]) == 4096
        msg = buttons_message(
            "b" * 2000, [("a", "A title that is far too long"), ("b", "B"), ("c", "C"), ("d", "D")]
        )
        action = msg["interactive"]["action"]["buttons"]
        assert len(msg["interactive"]["body"]["text"]) == 1024 and len(action) == 3
        assert action[0]["reply"]["title"] == "A title that is far "

    def test_reply_links_payment_and_approval(self):
        result = {
            "reply": "Here are two plans.",
            "cards": [
                {"type": "navigate", "screen": "plus", "params": {}, "label": "Open Yummy Chops Plus"},
                {"type": "navigate", "screen": "plus", "params": {}, "label": "Open Yummy Chops Plus"},
                {
                    "type": "navigate",
                    "screen": "order",
                    "params": {"order_id": "o1"},
                    "label": "Track this order",
                },
                {"type": "restaurants", "items": []},
                {"type": "payment_link", "url": "https://checkout.example/abc", "amount": "₦9,450"},
            ],
            "approval": {
                "type": "approval_required",
                "tool": "confirm_order",
                "tool_call_id": "call-9",
                "preview": {
                    "title": "Place order GM12AB from Jollof Junction?",
                    "message": "You'll pay ₦9,450 securely.",
                },
            },
        }
        text, pay, approve = render_result(result, "https://gudmeal.example/")
        assert text["text"]["body"] == (
            "Here are two plans.\n\nOpen Yummy Chops Plus: https://gudmeal.example/plus\n"
            "Track this order: https://gudmeal.example/orders/o1"
        )
        assert pay["interactive"]["type"] == "cta_url"
        assert pay["interactive"]["action"]["parameters"] == {
            "display_text": "Pay now",
            "url": "https://checkout.example/abc",
        }
        assert "₦9,450" in pay["interactive"]["body"]["text"]
        body = approve["interactive"]["body"]["text"]
        assert body == "Place order GM12AB from Jollof Junction?\nYou'll pay ₦9,450 securely."
        ids = [b["reply"]["id"] for b in approve["interactive"]["action"]["buttons"]]
        assert ids == ["approve:call-9", "decline:call-9"]
        assert render_result({"reply": "", "cards": []}, "https://x") == []


def test_shared_locations():
    body = {
        "entry": [
            {
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messages": [
                                {
                                    "from": "2348011111111",
                                    "id": "wamid.l",
                                    "type": "location",
                                    "location": {
                                        "latitude": 6.4478,
                                        "longitude": 3.4723,
                                        "name": "Lekki Phase 1",
                                        "address": "Admiralty Way",
                                    },
                                },
                                {
                                    "from": "2348011111111",
                                    "id": "wamid.bad",
                                    "type": "location",
                                    "location": {"latitude": "x"},
                                },
                            ]
                        },
                    }
                ]
            }
        ]
    }
    good, bad = parse_webhook(body)
    assert (good.kind, good.latitude, good.longitude, good.text) == (
        "location",
        6.4478,
        3.4723,
        "Lekki Phase 1",
    )
    assert good.task_payload()["latitude"] == 6.4478
    assert bad.kind == "unsupported" and bad.latitude is None
    lagos = shared_location_address({"lat": 6.4478, "lng": 3.4723, "name": "Lekki Phase 1"})
    assert lagos["city"] == "Lagos" and lagos["line1"] == "Lekki Phase 1"
    enugu = shared_location_address({"lat": 6.4473, "lng": 7.5214, "name": None})
    assert (
        enugu["city"] == "Enugu" and enugu["line1"] == "Location shared on WhatsApp" and enugu["area"] is None
    )


def test_support_contacts_offer_only_what_exists():
    """No made-up support number reaches a customer: empty contacts are left out (ADR-0023 update, 2026-11-21)."""
    defaults = Settings(_env_file=None).support_contacts()
    assert defaults == {"email": "customercare@yummy247.com"}
    assert support_line(defaults) == "Need a person? Email customercare@yummy247.com."

    every = Settings(
        _env_file=None,
        support_whatsapp="+234 812 345 6789",
        support_phone=" +234 1 234 5678 ",
        support_email="",
    ).support_contacts()
    assert every == {"whatsapp": "+234 812 345 6789", "phone": "+234 1 234 5678"}
    assert support_line(every) == "Need a person? WhatsApp +234 812 345 6789 or call +234 1 234 5678."
    assert (
        support_line(every | {"email": "customercare@yummy247.com"})
        == "Need a person? WhatsApp +234 812 345 6789, call +234 1 234 5678 or email customercare@yummy247.com."
    )
    assert support_line({}) == "Need a person? Open Support in the Yummy Chops app."
