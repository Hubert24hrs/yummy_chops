"""Google Maps Platform web services, server side only (the key never reaches a browser or app).

* Places API (New): Autocomplete and Place Details, with session tokens and an Essentials field mask.
* Geocoding API: forward and reverse geocoding, restricted to Nigeria.
* Routes API: Compute Routes and Compute Route Matrix with a minimal field mask.

Implemented against Google's documented request/response formats; exercised in tests with recorded-shape
responses. Real calls only happen when ``GOOGLE_MAPS_API_KEY`` is configured.
"""

from __future__ import annotations

import math
from typing import Any
from urllib.parse import quote

import httpx

from ..domain.geo import GeoPoint
from .models import MapsError, PlaceResult, PlaceSuggestion, Precision, RouteEstimate, served_city

PLACES_URL = "https://places.googleapis.com/v1"
GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"
ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"
MATRIX_URL = "https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix"

#: Place Details fields we pay for (Essentials tier): enough to place a delivery address.
PLACE_FIELDS = "id,formattedAddress,location,addressComponents,types"
ROUTE_FIELDS = "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline"
MATRIX_FIELDS = "originIndex,destinationIndex,distanceMeters,duration,condition,status"
#: Routes API limit is far higher; we keep matrix calls small and cheap.
MAX_MATRIX_ORIGINS = 25

_AREA_TYPES = (
    "neighborhood",
    "sublocality_level_1",
    "sublocality",
    "locality",
    "administrative_area_level_2",
)


def _duration_minutes(value: str | None) -> int:
    """Routes API durations are strings like "925s"."""
    if not value:
        return 0
    try:
        seconds = float(value.rstrip("s"))
    except ValueError:
        return 0
    return max(1, math.ceil(seconds / 60))


def _lat_lng(point: GeoPoint) -> dict[str, float]:
    return {"latitude": point.lat, "longitude": point.lng}


def _area_from(components: list[dict[str, Any]], long_key: str) -> str | None:
    for wanted in _AREA_TYPES:
        for comp in components:
            if wanted in comp.get("types", []):
                return comp.get(long_key)
    return None


def _place_precision(types: list[str]) -> Precision:
    t = set(types)
    if t & {"street_address", "premise", "subpremise", "establishment", "point_of_interest"}:
        return "rooftop"
    if t & {"route", "intersection"}:
        return "street"
    if t & {"neighborhood", "sublocality", "sublocality_level_1", "locality", "political"}:
        return "area"
    return "approximate"


def _geocode_precision(location_type: str | None, types: list[str]) -> Precision:
    if location_type == "ROOFTOP":
        return "rooftop"
    if location_type == "RANGE_INTERPOLATED":
        return "street"
    if location_type == "GEOMETRIC_CENTER":
        return "street" if {"route", "street_address"} & set(types) else "area"
    return "approximate"


class GoogleMapsClient:
    def __init__(
        self,
        api_key: str,
        http: httpx.AsyncClient,
        *,
        travel_mode: str = "DRIVE",
        traffic_aware: bool = True,
        region: str = "ng",
        language: str = "en",
        timeout: float = 4.0,
    ) -> None:
        if not api_key:
            raise ValueError("Google Maps API key is required")
        self._key = api_key
        self._http = http
        self.travel_mode = travel_mode
        self.traffic_aware = traffic_aware
        self.region = region
        self.language = language
        self.timeout = timeout

    # ------------------------------------------------------------------------------ transport
    async def _send(self, method: str, url: str, *, field_mask: str | None = None, **kw: Any) -> Any:
        headers = {"X-Goog-Api-Key": self._key}
        if field_mask:
            headers["X-Goog-FieldMask"] = field_mask
        try:
            res = await self._http.request(method, url, headers=headers, timeout=self.timeout, **kw)
        except httpx.HTTPError as exc:  # timeouts, DNS, connection resets
            raise MapsError(f"maps request failed: {type(exc).__name__}") from exc
        if res.status_code >= 400:
            message = ""
            try:
                message = (res.json().get("error") or {}).get("message", "")
            except ValueError:
                pass
            raise MapsError(f"maps error {res.status_code}: {message}"[:300])
        try:
            return res.json()
        except ValueError as exc:
            raise MapsError("maps returned invalid JSON") from exc

    # ------------------------------------------------------------------------------ places
    async def autocomplete(
        self,
        text: str,
        *,
        session_token: str | None = None,
        near: GeoPoint | None = None,
        radius_m: int = 30_000,
    ) -> list[PlaceSuggestion]:
        body: dict[str, Any] = {
            "input": text,
            "includedRegionCodes": [self.region],
            "languageCode": self.language,
        }
        if session_token:
            body["sessionToken"] = session_token
        if near is not None:
            body["locationBias"] = {"circle": {"center": _lat_lng(near), "radius": float(radius_m)}}
            body["origin"] = _lat_lng(near)
        data = await self._send("POST", f"{PLACES_URL}/places:autocomplete", json=body)
        out: list[PlaceSuggestion] = []
        for s in data.get("suggestions", []):
            p = s.get("placePrediction")
            if not p or not p.get("placeId"):
                continue  # query predictions are not places
            fmt = p.get("structuredFormat") or {}
            title = ((fmt.get("mainText") or {}).get("text")) or ((p.get("text") or {}).get("text")) or ""
            subtitle = (fmt.get("secondaryText") or {}).get("text", "")
            out.append(
                PlaceSuggestion(
                    place_id=p["placeId"],
                    title=title,
                    subtitle=subtitle,
                    distance_m=p.get("distanceMeters"),
                    source="google",
                )
            )
        return out

    async def place(self, place_id: str, *, session_token: str | None = None) -> PlaceResult:
        params = {"languageCode": self.language}
        if session_token:
            params["sessionToken"] = session_token
        data = await self._send(
            "GET", f"{PLACES_URL}/places/{quote(place_id, safe='')}", field_mask=PLACE_FIELDS, params=params
        )
        loc = data.get("location") or {}
        if "latitude" not in loc or "longitude" not in loc:
            raise MapsError("place has no location")
        point = GeoPoint(lat=loc["latitude"], lng=loc["longitude"])
        return PlaceResult(
            place_id=data.get("id") or place_id,
            formatted_address=data.get("formattedAddress") or "",
            location=point,
            area=_area_from(data.get("addressComponents") or [], "longText"),
            city=served_city(point),
            precision=_place_precision(data.get("types") or []),
            source="google",
        )

    # ------------------------------------------------------------------------------ geocoding
    async def _geocode(self, params: dict[str, str]) -> PlaceResult | None:
        data = await self._send(
            "GET", GEOCODE_URL, params={**params, "key": self._key, "language": self.language}
        )
        status = data.get("status")
        if status == "ZERO_RESULTS":
            return None
        if status != "OK":
            raise MapsError(f"geocoding status {status}")
        r = data["results"][0]
        loc = r["geometry"]["location"]
        point = GeoPoint(lat=loc["lat"], lng=loc["lng"])
        return PlaceResult(
            place_id=r.get("place_id"),
            formatted_address=r.get("formatted_address", ""),
            location=point,
            area=_area_from(r.get("address_components") or [], "long_name"),
            city=served_city(point),
            precision=_geocode_precision(r["geometry"].get("location_type"), r.get("types") or []),
            source="google",
        )

    async def geocode(self, address: str) -> PlaceResult | None:
        return await self._geocode(
            {"address": address, "region": self.region, "components": f"country:{self.region.upper()}"}
        )

    async def reverse_geocode(self, point: GeoPoint) -> PlaceResult | None:
        return await self._geocode({"latlng": f"{point.lat:.6f},{point.lng:.6f}"})

    # ------------------------------------------------------------------------------ routes
    def _route_body(self) -> dict[str, Any]:
        body: dict[str, Any] = {
            "travelMode": self.travel_mode,
            "languageCode": self.language,
            "units": "METRIC",
        }
        if self.traffic_aware and self.travel_mode in ("DRIVE", "TWO_WHEELER"):
            body["routingPreference"] = "TRAFFIC_AWARE"
        return body

    async def route(self, origin: GeoPoint, destination: GeoPoint) -> RouteEstimate:
        body = {
            **self._route_body(),
            "origin": {"location": {"latLng": _lat_lng(origin)}},
            "destination": {"location": {"latLng": _lat_lng(destination)}},
            "computeAlternativeRoutes": False,
        }
        data = await self._send("POST", ROUTES_URL, field_mask=ROUTE_FIELDS, json=body)
        routes = data.get("routes") or []
        if not routes or "distanceMeters" not in routes[0]:
            raise MapsError("no route found")
        r = routes[0]
        return RouteEstimate(
            distance_km=round(r["distanceMeters"] / 1000, 3),
            duration_minutes=_duration_minutes(r.get("duration")),
            polyline=(r.get("polyline") or {}).get("encodedPolyline"),
            traffic_aware="routingPreference" in body,
            source="google",
        )

    async def route_matrix(
        self, origins: list[GeoPoint], destination: GeoPoint
    ) -> list[RouteEstimate | None]:
        """Many origins (kitchens) to one destination (the customer). ``None`` where no route exists."""
        if not origins:
            return []
        if len(origins) > MAX_MATRIX_ORIGINS:
            raise ValueError(f"at most {MAX_MATRIX_ORIGINS} origins per matrix call")
        body = {
            **self._route_body(),
            "origins": [{"waypoint": {"location": {"latLng": _lat_lng(o)}}} for o in origins],
            "destinations": [{"waypoint": {"location": {"latLng": _lat_lng(destination)}}}],
        }
        data = await self._send("POST", MATRIX_URL, field_mask=MATRIX_FIELDS, json=body)
        out: list[RouteEstimate | None] = [None] * len(origins)
        for el in data if isinstance(data, list) else []:
            i = el.get("originIndex")
            if i is None or not 0 <= i < len(origins):
                continue
            if el.get("condition") != "ROUTE_EXISTS" or "distanceMeters" not in el:
                continue
            out[i] = RouteEstimate(
                distance_km=round(el["distanceMeters"] / 1000, 3),
                duration_minutes=_duration_minutes(el.get("duration")),
                traffic_aware="routingPreference" in body,
                source="google",
            )
        return out
