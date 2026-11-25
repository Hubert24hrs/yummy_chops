"""Input guardrails: size limits, prompt-injection heuristics and payment-data redaction."""

from __future__ import annotations

import re
from dataclasses import dataclass, field

INJECTION_PATTERNS = [
    r"ignore\s+(all\s+|any\s+)?(the\s+)?(previous|prior|above|earlier)\s+(instructions|rules|messages)",
    r"disregard\s+(all\s+|the\s+|your\s+)?(rules|instructions|guidelines)",
    r"(reveal|show|print|repeat|leak)\s+(me\s+)?(your|the)\s+(system\s+)?(prompt|instructions)",
    r"\byou\s+are\s+now\s+(an?\s+)?(admin|administrator|developer|dan|unrestricted)",
    r"\b(developer|god|jailbreak)\s+mode\b",
    r"act\s+as\s+(an?\s+)?(admin|administrator|super\s*admin|another\s+user)",
    r"(bypass|skip|disable)\s+(the\s+)?(approval|confirmation|verification|rules|guardrails)",
    r"(mark|set)\s+(my\s+|the\s+)?(order|payment)\s+(as\s+)?paid",
    r"<\s*/?\s*(system|assistant)\s*>",
]
_INJECTION = re.compile("|".join(f"(?:{p})" for p in INJECTION_PATTERNS), re.I)
_CARD_CANDIDATE = re.compile(r"(?<!\d)(?:\d[ -]?){13,19}(?!\d)")
_CVV_PIN = re.compile(r"\b(cvv|cvc|pin|otp)\b\s*[:=]?\s*\d{3,6}\b", re.I)


def _luhn_ok(digits: str) -> bool:
    total, parity = 0, len(digits) % 2
    for i, ch in enumerate(digits):
        d = int(ch)
        if i % 2 == parity:
            d *= 2
            if d > 9:
                d -= 9
        total += d
    return total % 10 == 0


@dataclass
class GuardResult:
    text: str
    blocked: bool = False
    reason: str | None = None
    warnings: list[str] = field(default_factory=list)


def check_input(text: str, *, max_chars: int) -> GuardResult:
    text = (text or "").strip()
    if not text:
        return GuardResult(text="", blocked=True, reason="empty")

    warnings: list[str] = []

    def _redact_card(match: re.Match[str]) -> str:
        digits = re.sub(r"\D", "", match.group(0))
        if 13 <= len(digits) <= 19 and _luhn_ok(digits):
            warnings.append("card_number_removed")
            return "[card number removed]"
        return match.group(0)

    sanitized = _CARD_CANDIDATE.sub(_redact_card, text)
    if _CVV_PIN.search(sanitized):
        sanitized = _CVV_PIN.sub("[secret removed]", sanitized)
        warnings.append("secret_removed")
    # Card and PIN details are removed first, so even the kept start of an over-long message never holds them.
    if len(text) > max_chars:
        return GuardResult(text=sanitized[:max_chars], blocked=True, reason="too_long", warnings=warnings)
    if _INJECTION.search(sanitized):
        return GuardResult(text=sanitized, blocked=True, reason="prompt_injection", warnings=warnings)
    return GuardResult(text=sanitized, warnings=warnings)


BLOCKED_REPLIES = {
    "prompt_injection": "I can't help with that request. I can help you find food, place and track orders, or sort "
    "out an issue with an order.",
    "too_long": "That message is a bit long for me. Could you shorten it to the key details?",
    "empty": "How can I help with your meal today?",
}
CARD_WARNING = (
    "For your safety I removed what looked like card or PIN details. Never share card numbers, PINs or "
    "OTPs in chat — payment happens only on the secure payment page."
)
