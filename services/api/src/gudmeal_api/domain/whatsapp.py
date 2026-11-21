"""WhatsApp Business Cloud API (ADR-0017): webhook signatures, inbound parsing and outbound message building.

Pure functions, no I/O. Replies are built only from Yummy's result (text, payment links, screen buttons and the
server-side approval preview), so amounts shown on WhatsApp come from the API, never from the model.
"""

from __future__ import annotations

import hashlib
import hmac
import re
from dataclasses import dataclass
from typing import Any, Literal

MAX_TEXT = 4096  # WhatsApp text limit
MAX_BODY = 1024  # interactive message body limit
MAX_BUTTON_TITLE = 20
MAX_INBOUND_CHARS = 1000

YES = re.compile(
    r"^\s*(yes|y|yeah|yep|ok|okay|sure|go ahead|confirm|place it|book it|oya|ee|beeni|eh)\b", re.I
)
NO = re.compile(r"^\s*(no|n|nope|cancel|not now|stop it|mba|rara|a'a)\b", re.I)
LINK_COMMAND = re.compile(r"^\s*link\s*[:#-]?\s*(\d{6})\s*$", re.I)
STOP_COMMAND = re.compile(r"^\s*(stop|unlink|disconnect)\s*$", re.I)
HELP_COMMAND = re.compile(r"^\s*(help|menu|\?)\s*$", re.I)

WEB_ROUTES = {
    "home": "/",
    "food": "/food",
    "beauty": "/beauty",
    "grocery": "/groceries",
    "pharmacy": "/pharmacy",
    "market": "/foodstuff",
    "parcel": "/send",
    "discover": "/discover",
    "orders": "/orders",
    "support": "/support",
    "profile": "/account",
    "wallet": "/wallet",
    "waybill": "/send?mode=interstate",
    "plus": "/plus",
    "rewards": "/rewards",
    "group": "/group",
}


# ------------------------------------------------------------------------------------------- webhooks
def signature(app_secret: str, raw: bytes) -> str:
    """The X-Hub-Signature-256 value Meta sends (used by the local simulator and tests)."""
    return "sha256=" + hmac.new(app_secret.encode(), raw, hashlib.sha256).hexdigest()


def signature_ok(app_secret: str, raw: bytes, header: str | None) -> bool:
    if not header or not header.startswith("sha256="):
        return False
    return hmac.compare_digest(signature(app_secret, raw), header)


@dataclass(frozen=True)
class Inbound:
    message_id: str
    wa_id: str  # the sender's number in international format without "+", verified by WhatsApp
    name: str | None
    kind: Literal["text", "button", "location", "unsupported"]
    text: str = ""
    button_id: str | None = None
    timestamp: int = 0
    latitude: float | None = None  # a shared location (the place's name or address is in `text`)
    longitude: float | None = None

    def task_payload(self) -> dict[str, Any]:
        return {
            "message_id": self.message_id,
            "wa_id": self.wa_id,
            "name": self.name,
            "kind": self.kind,
            "text": self.text,
            "button_id": self.button_id,
            "timestamp": self.timestamp,
            "latitude": self.latitude,
            "longitude": self.longitude,
        }


def parse_webhook(body: dict[str, Any]) -> list[Inbound]:
    """Messages in a Cloud API webhook (delivery statuses and other fields are ignored)."""
    found: list[Inbound] = []
    for entry in body.get("entry") or []:
        for change in entry.get("changes") or []:
            if change.get("field") != "messages":
                continue
            value = change.get("value") or {}
            names = {
                str(c.get("wa_id")): (c.get("profile") or {}).get("name") for c in value.get("contacts") or []
            }
            for m in value.get("messages") or []:
                wa_id, message_id = str(m.get("from") or ""), str(m.get("id") or "")
                if not wa_id.isdigit() or not message_id:
                    continue
                kind: Literal["text", "button", "location", "unsupported"] = "unsupported"
                text, button_id = "", None
                lat = lng = None
                if m.get("type") == "location":
                    loc = m.get("location") or {}
                    try:
                        lat, lng = float(loc["latitude"]), float(loc["longitude"])
                    except (KeyError, TypeError, ValueError):
                        lat = lng = None
                    if lat is not None and lng is not None and -90 <= lat <= 90 and -180 <= lng <= 180:
                        kind = "location"
                        text = str(loc.get("name") or loc.get("address") or "")[:200]
                    else:
                        lat = lng = None
                elif m.get("type") == "text":
                    kind, text = "text", str((m.get("text") or {}).get("body") or "")
                elif m.get("type") == "interactive":
                    i = m.get("interactive") or {}
                    reply = i.get("button_reply") or i.get("list_reply") or {}
                    kind, text, button_id = (
                        "button",
                        str(reply.get("title") or ""),
                        str(reply.get("id") or "") or None,
                    )
                elif m.get("type") == "button":  # quick-reply buttons on template messages
                    b = m.get("button") or {}
                    kind, text, button_id = (
                        "button",
                        str(b.get("text") or ""),
                        str(b.get("payload") or "") or None,
                    )
                try:
                    ts = int(m.get("timestamp") or 0)
                except (TypeError, ValueError):
                    ts = 0
                found.append(
                    Inbound(message_id, wa_id, names.get(wa_id), kind, text, button_id, ts, lat, lng)
                )
    return found


CITY_CENTRES = {"Lagos": (6.5244, 3.3792), "Enugu": (6.4584, 7.5464)}


def shared_location_address(location: dict[str, Any]) -> dict[str, Any]:
    """A location the customer shared on WhatsApp, as the delivery address Yummy plans and quotes with.
    The API still checks that the point is inside a delivery zone."""
    lat, lng = float(location["lat"]), float(location["lng"])
    city = min(CITY_CENTRES, key=lambda c: (CITY_CENTRES[c][0] - lat) ** 2 + (CITY_CENTRES[c][1] - lng) ** 2)
    label = str(location.get("name") or "").strip()
    line1 = label if len(label) >= 3 else "Location shared on WhatsApp"
    return {
        "label": "WhatsApp location",
        "line1": line1[:200],
        "area": label[:80] or None,
        "city": city,
        "state": city,
        "location": {"lat": lat, "lng": lng},
    }


def mask(wa_id: str) -> str:
    """+234 801 ••• 1111 — enough for the customer to recognise their number, not to read it off a screen."""
    if len(wa_id) < 10:
        return "•••"
    return f"+{wa_id[:3]} {wa_id[3:6]} ••• {wa_id[-4:]}"


def digits(number: str) -> str:
    return "".join(ch for ch in number if ch.isdigit())


# ------------------------------------------------------------------------------------------- outbound
def text_message(body: str) -> dict[str, Any]:
    if len(body) > MAX_TEXT:
        body = body[: MAX_TEXT - 1] + "…"
    return {"type": "text", "text": {"body": body, "preview_url": True}}


def buttons_message(body: str, buttons: list[tuple[str, str]]) -> dict[str, Any]:
    if len(body) > MAX_BODY:
        body = body[: MAX_BODY - 1] + "…"
    return {
        "type": "interactive",
        "interactive": {
            "type": "button",
            "body": {"text": body},
            "action": {
                "buttons": [
                    {"type": "reply", "reply": {"id": bid[:256], "title": title[:MAX_BUTTON_TITLE]}}
                    for bid, title in buttons[:3]
                ]
            },
        },
    }


def link_message(body: str, label: str, url: str) -> dict[str, Any]:
    return {
        "type": "interactive",
        "interactive": {
            "type": "cta_url",
            "body": {"text": body[:MAX_BODY]},
            "action": {
                "name": "cta_url",
                "parameters": {"display_text": label[:MAX_BUTTON_TITLE], "url": url},
            },
        },
    }


def web_route(screen: str, params: dict[str, Any]) -> str | None:
    if screen == "merchant":
        return f"/restaurants/{params['merchant_id']}" if params.get("merchant_id") else None
    if screen == "order":
        return f"/orders/{params['order_id']}" if params.get("order_id") else "/orders"
    return WEB_ROUTES.get(screen)


def approval_message(approval: dict[str, Any]) -> dict[str, Any]:
    """Yummy's approval screen as Yes/No buttons. The summary (and its exact total) is the server's preview."""
    preview = approval.get("preview") or {}
    lines = [str(preview.get("title") or "Shall I go ahead?")]
    if preview.get("message"):
        lines.append(str(preview["message"]))
    call_id = str(approval.get("tool_call_id") or "")
    return buttons_message(
        "\n".join(lines), [(f"approve:{call_id}", "Yes, go ahead"), (f"decline:{call_id}", "No")]
    )


def render_result(result: dict[str, Any], web_url: str) -> list[dict[str, Any]]:
    """Yummy's reply for WhatsApp: the text (plus links for screen buttons), a payment link, an approval."""
    messages: list[dict[str, Any]] = []
    links: list[str] = []
    payment: dict[str, Any] | None = None
    for card in result.get("cards") or []:
        if card.get("type") == "payment_link" and card.get("url"):
            payment = card
        elif card.get("type") == "navigate":
            route = web_route(str(card.get("screen")), dict(card.get("params") or {}))
            if route:
                links.append(f"{card.get('label') or 'Open Yummy Chops'}: {web_url.rstrip('/')}{route}")
    text = (result.get("reply") or "").strip()
    if links:
        text = (text + "\n\n" if text else "") + "\n".join(dict.fromkeys(links))
    if text:
        messages.append(text_message(text))
    if payment:
        messages.append(
            link_message(
                f"Pay {payment.get('amount', '')} on the secure payment page. Your order goes to the store as soon "
                "as the payment is confirmed.",
                "Pay now",
                str(payment["url"]),
            )
        )
    if result.get("approval"):
        messages.append(approval_message(result["approval"]))
    return messages


def support_line(contacts: dict[str, str]) -> str:
    """'Need a person?' with only the support contacts that exist (Settings.support_contacts()), never a
    placeholder number."""
    ways = [
        f"{label} {contacts[kind]}"
        for kind, label in (("whatsapp", "WhatsApp"), ("phone", "call"), ("email", "email"))
        if contacts.get(kind)
    ]
    if not ways:
        return "Need a person? Open Support in the Yummy Chops app."
    joined = ways[0] if len(ways) == 1 else ", ".join(ways[:-1]) + " or " + ways[-1]
    return f"Need a person? {joined[0].upper()}{joined[1:]}."


__all__ = [
    "HELP_COMMAND",
    "LINK_COMMAND",
    "MAX_INBOUND_CHARS",
    "NO",
    "STOP_COMMAND",
    "YES",
    "Inbound",
    "approval_message",
    "buttons_message",
    "digits",
    "link_message",
    "mask",
    "parse_webhook",
    "render_result",
    "shared_location_address",
    "signature",
    "signature_ok",
    "support_line",
    "text_message",
    "web_route",
]
