"""A rider's trip: the shops to collect from, in the quickest order, then the customer (ADR-0031).

Pure functions: the caller passes how long a leg takes (road estimate or a measured time)."""

from __future__ import annotations

from collections.abc import Callable, Sequence
from itertools import pairwise, permutations
from urllib.parse import urlencode

from .geo import GeoPoint

#: Up to this many shops every order is tried (8! = 40 320 small sums); more use the nearest next shop each time.
EXACT_UP_TO = 8


def quickest_order[T](
    start: GeoPoint | None,
    stops: Sequence[T],
    end: GeoPoint,
    where: Callable[[T], GeoPoint],
    cost: Callable[[GeoPoint, GeoPoint], float],
) -> list[T]:
    """The order of `stops` that makes start → stops → end quickest. Without a start (the rider's position is not
    known) the trip starts at whichever stop is best."""
    items = list(stops)
    if len(items) <= 1:
        return items

    def total(seq: Sequence[T]) -> float:
        points = [where(s) for s in seq]
        legs = ([cost(start, points[0])] if start is not None else []) + [
            cost(a, b) for a, b in pairwise(points)
        ]
        return sum(legs) + cost(points[-1], end)

    if len(items) <= EXACT_UP_TO:
        return list(min(permutations(items), key=total))
    left, ordered = items[:], []
    here = start
    while left:
        nxt = min(left, key=lambda s: cost(here, where(s)) if here is not None else cost(where(s), end))
        ordered.append(nxt)
        left.remove(nxt)
        here = where(nxt)
    return ordered


def navigation_url(stops: Sequence[GeoPoint], *, vehicle: str = "motorcycle") -> str:
    """Google Maps directions from where the phone is, through every stop, to the last one (the customer)."""
    if not stops:
        return ""
    fmt = lambda p: f"{p.lat:.6f},{p.lng:.6f}"  # noqa: E731
    params = {
        "api": "1",
        "destination": fmt(stops[-1]),
        "travelmode": "bicycling" if vehicle == "bicycle" else "driving",
    }
    if len(stops) > 1:
        params["waypoints"] = "|".join(fmt(p) for p in stops[:-1])
    return "https://www.google.com/maps/dir/?" + urlencode(params, safe=",|")
