"""Location results shared by the Google Maps client, the keyless fallback and the API.

Every result carries ``source`` so a straight-line estimate is never presented as a measured route
and a neighbourhood centre is never presented as a rooftop address.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

from ..domain.cities import CITIES
from ..domain.geo import GeoPoint, haversine_km

PlaceSource = Literal["google", "local"]
RouteSource = Literal["google", "estimate"]
#: rooftop = a building/entrance; street = a street segment; area = neighbourhood centre; approximate = coarse.
Precision = Literal["rooftop", "street", "area", "approximate"]

#: How far from a city centre an address can be and still belong to that city.
CITY_RADIUS_KM = 60.0


class MapsError(Exception):
    """The maps provider failed (network, quota, key). Callers fall back to estimates."""


class PlaceSuggestion(BaseModel):
    place_id: str
    title: str
    subtitle: str = ""
    distance_m: int | None = None
    source: PlaceSource


class PlaceResult(BaseModel):
    place_id: str | None = None
    formatted_address: str
    location: GeoPoint
    area: str | None = None
    city: str | None = Field(
        default=None, description="Yummy Chops city id when the place is in a city we serve"
    )
    precision: Precision
    source: PlaceSource


class RouteEstimate(BaseModel):
    distance_km: float
    duration_minutes: int
    polyline: str | None = Field(default=None, description="Encoded polyline (Google format) when measured")
    traffic_aware: bool = False
    source: RouteSource


def shop_delivers_to(shop_location: GeoPoint, radius_km: float, point: GeoPoint) -> bool:
    """Every shop delivers anywhere in its own city (owner's decision, 2026-11-26); a shop's own radius only
    matters outside the cities Yummy Chops serves."""
    city = served_city(shop_location)
    if city is not None and city == served_city(point):
        return True
    return haversine_km(shop_location, point) <= radius_km


def served_city(point: GeoPoint) -> str | None:
    """The Yummy Chops city a point belongs to (nearest centre within ``CITY_RADIUS_KM``), if any."""
    best: tuple[float, str] | None = None
    for city in CITIES.values():
        d = haversine_km(point, city.center)
        if d <= CITY_RADIUS_KM and (best is None or d < best[0]):
            best = (d, city.id)
    return best[1] if best else None
