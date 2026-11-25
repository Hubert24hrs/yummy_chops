"""Per-key token-bucket rate limiter (per instance).

Cloud Run may run several instances, so effective limits are `limit × instances`; the limits below are
sized with that in mind. A shared Redis/Memorystore limiter can replace this behind the same interface.
"""

from __future__ import annotations

import time
from collections import OrderedDict
from dataclasses import dataclass

from ..errors import RateLimited


@dataclass
class _Bucket:
    tokens: float
    updated: float


class RateLimiter:
    #: Most buckets kept at once: past it the least recently used go first (a new key per request, as a flood
    #: with made-up addresses brings, cannot grow memory or slow every request down).
    MAX_BUCKETS = 50_000

    def __init__(self, max_buckets: int = MAX_BUCKETS) -> None:
        self._buckets: OrderedDict[str, _Bucket] = OrderedDict()
        self._max = max_buckets

    def check(self, key: str, *, capacity: int, refill_per_second: float) -> None:
        now = time.monotonic()
        bucket = self._buckets.get(key)
        if bucket is None:
            bucket = _Bucket(tokens=capacity, updated=now)
            self._buckets[key] = bucket
            while len(self._buckets) > self._max:
                self._buckets.popitem(last=False)
        else:
            self._buckets.move_to_end(key)
        bucket.tokens = min(capacity, bucket.tokens + (now - bucket.updated) * refill_per_second)
        bucket.updated = now
        if bucket.tokens < 1:
            retry = (1 - bucket.tokens) / refill_per_second if refill_per_second else 60
            raise RateLimited(
                "Too many requests; please slow down", details={"retry_after_seconds": round(retry, 1)}
            )
        bucket.tokens -= 1


# Named limits used by routes: (capacity, refill per second)
LIMITS: dict[str, tuple[int, float]] = {
    "quote": (30, 0.5),
    "order_create": (10, 0.1),
    "checkout": (10, 0.1),
    "wallet_topup": (10, 0.1),
    "plus": (10, 0.1),
    "rewards": (20, 0.2),  # applying referral codes, redeeming points
    "group_join": (10, 0.05),  # joining a group order by code (slows down code guessing)
    "payout": (10, 0.05),
    "track": (30, 0.5),  # public waybill tracking, per client address
    "payment_verify": (20, 0.3),
    "code_attempt": (5, 0.02),
    "rider_location": (30, 1.0),
    "places": (40, 0.5),  # address search: each call can cost a Google request
    "meal_plan": (10, 0.2),
    "support": (10, 0.05),
    "application": (5, 0.01),
    "kyc_upload": (20, 0.2),  # a rider uploads 7 photos, sometimes twice
}
