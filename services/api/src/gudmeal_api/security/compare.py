"""Comparing secrets safely."""

from __future__ import annotations

import hmac


def same_secret(expected: str, given: str | None) -> bool:
    """Constant-time comparison of a secret with what a caller sent. `hmac.compare_digest` raises on text outside
    ASCII, and a header can carry any byte: compared as bytes, such a value is simply wrong (401, not a 500)."""
    return hmac.compare_digest(expected.encode(), (given or "").encode())
