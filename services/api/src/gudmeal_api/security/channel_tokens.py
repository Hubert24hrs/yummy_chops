"""Delegated channel tokens (ADR-0017).

A WhatsApp message carries a phone number, not a Firebase ID token. For a number linked to an account, the API
mints a short-lived token that lets Yummy act for that customer — and only as a customer: staff, merchant and
rider powers never travel over a chat channel. Format: ``gmc1.<base64url(json)>.<base64url(hmac_sha256)>``.

The same verification lives in the agents service (``gudmeal_agents.identity``); both use CHANNEL_TOKEN_SECRET.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import secrets
import time
from typing import Any

from ..errors import Unauthenticated
from .auth import TokenVerifier
from .compare import same_secret
from .rbac import Principal

PREFIX = "gmc1"
CHANNELS = ("whatsapp",)
DEFAULT_TTL_SECONDS = 600
CLOCK_SKEW_SECONDS = 60


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def _sign(secret: str, signed_part: str) -> str:
    return _b64(hmac.new(secret.encode(), signed_part.encode(), hashlib.sha256).digest())


def mint(
    secret: str,
    *,
    uid: str,
    channel: str,
    name: str | None = None,
    ttl_seconds: int = DEFAULT_TTL_SECONDS,
    now: float | None = None,
) -> str:
    if channel not in CHANNELS:
        raise ValueError(f"Unknown channel {channel!r}")
    issued = int(now if now is not None else time.time())
    claims = {
        "uid": uid,
        "name": name,
        "roles": ["customer"],
        "ch": channel,
        "iat": issued,
        "exp": issued + ttl_seconds,
        "jti": secrets.token_hex(8),
    }
    payload = _b64(json.dumps(claims, separators=(",", ":"), sort_keys=True).encode())
    signed = f"{PREFIX}.{payload}"
    return f"{signed}.{_sign(secret, signed)}"


def is_channel_token(token: str) -> bool:
    return token.startswith(f"{PREFIX}.")


def verify(secret: str, token: str, now: float | None = None) -> dict[str, Any]:
    """Return the claims of a valid token, or raise ValueError (bad format, signature, channel or expiry)."""
    parts = token.split(".")
    if len(parts) != 3 or parts[0] != PREFIX:
        raise ValueError("Not a channel token")
    signed = f"{parts[0]}.{parts[1]}"
    if not same_secret(_sign(secret, signed), parts[2]):
        raise ValueError("Bad signature")
    try:
        claims = json.loads(_unb64(parts[1]))
    except (ValueError, json.JSONDecodeError) as exc:
        raise ValueError("Bad payload") from exc
    t = now if now is not None else time.time()
    if not isinstance(claims, dict) or not claims.get("uid") or claims.get("ch") not in CHANNELS:
        raise ValueError("Bad claims")
    if int(claims.get("exp", 0)) <= t or int(claims.get("iat", 0)) > t + CLOCK_SKEW_SECONDS:
        raise ValueError("Expired")
    return claims


class ChannelTokenVerifier:
    """Accepts channel tokens; hands every other token to the normal (Firebase) verifier."""

    def __init__(self, secret: str, fallback: TokenVerifier) -> None:
        self._secret = secret
        self._fallback = fallback

    async def verify(self, token: str) -> Principal:
        if not is_channel_token(token):
            return await self._fallback.verify(token)
        try:
            claims = verify(self._secret, token)
        except ValueError as exc:
            raise Unauthenticated("Invalid or expired channel token") from exc
        return Principal(
            uid=str(claims["uid"]),
            roles=frozenset({"customer"}),  # never more than a customer over a chat channel
            name=claims.get("name"),
            token=token,
        )


__all__ = ["ChannelTokenVerifier", "is_channel_token", "mint", "verify"]
