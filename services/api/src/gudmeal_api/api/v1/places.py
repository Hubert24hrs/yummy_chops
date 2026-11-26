"""Address search and map pins through the API: Google Places / Geocoding stay server side (the key never
reaches an app or browser). Signed-in only and rate limited, because every call can cost money; browsing
before sign-in uses the free neighbourhood list (`/v1/places/areas`)."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query

from ...domain.geo import GeoPoint, haversine_km
from ...domain.hours import is_open
from ...domain.models import RestaurantStatus
from ...domain.pricing import delivery_fee, estimate_minutes
from ...errors import NotFound, ValidationFailed
from ...maps import PlaceResult
from ...maps.models import shop_delivers_to
from ...security.rbac import Permission, require
from ...services.locations import LocationInput, RestaurantLocationService
from ..deps import Ctr, CurrentPrincipal, limit

router = APIRouter(prefix="/v1", tags=["places"])

SessionToken = Annotated[str | None, Query(max_length=64, pattern=r"^[A-Za-z0-9_-]+$")]


async def _with_coverage(c: Ctr, place: PlaceResult) -> dict[str, Any]:
    """The place plus whether we deliver there (inside an active delivery zone)."""
    cfg = await c.repos.get_pricing_config()
    zone = cfg.zone_for(place.location)
    return {
        "place": place.model_dump(),
        "serviceable": zone is not None,
        "zone": zone.name if zone else None,
        "city": zone.city if zone else place.city,
    }


@router.get("/places/autocomplete", dependencies=[Depends(limit("places"))])
async def autocomplete(
    c: Ctr,
    principal: CurrentPrincipal,
    q: Annotated[str, Query(min_length=2, max_length=120)],
    session: SessionToken = None,
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
    city: Annotated[str | None, Query(max_length=30)] = None,
) -> dict[str, Any]:
    """Address suggestions as the customer types. Pass one `session` token per address search (cheaper)."""
    if (lat is None) != (lng is None):
        raise ValidationFailed("Provide both lat and lng")
    near = GeoPoint(lat=lat, lng=lng) if lat is not None and lng is not None else None
    found = await c.maps.autocomplete(q, session_token=session, near=near, city=city)
    return {"suggestions": [s.model_dump() for s in found], "provider": c.maps.provider}


@router.get("/places/details", dependencies=[Depends(limit("places"))])
async def details(
    c: Ctr,
    principal: CurrentPrincipal,
    place_id: Annotated[str, Query(min_length=3, max_length=300)],
    session: SessionToken = None,
) -> dict[str, Any]:
    """The chosen suggestion's address and map pin (ends the autocomplete session)."""
    place = await c.maps.place(place_id, session_token=session)
    if place is None:
        raise NotFound("We couldn't find that place. Try typing the street and the area.")
    return await _with_coverage(c, place)


@router.get("/places/reverse", dependencies=[Depends(limit("places"))])
async def reverse(
    c: Ctr,
    principal: CurrentPrincipal,
    lat: Annotated[float, Query(ge=-90, le=90)],
    lng: Annotated[float, Query(ge=-180, le=180)],
) -> dict[str, Any]:
    """Name the customer's current location ("use my location") or a dropped pin. The pin itself is kept."""
    place = await c.maps.reverse(GeoPoint(lat=lat, lng=lng))
    if place is None:
        raise NotFound("That location is outside the areas we serve")
    return await _with_coverage(c, place)


@router.get("/delivery/estimates", dependencies=[Depends(limit("places"))])
async def delivery_estimates(
    c: Ctr,
    principal: CurrentPrincipal,
    restaurant_ids: Annotated[
        str, Query(min_length=2, max_length=600, description="Comma-separated, up to 10")
    ],
    lat: Annotated[float, Query(ge=-90, le=90)],
    lng: Annotated[float, Query(ge=-180, le=180)],
) -> dict[str, Any]:
    """Compare kitchens for one address: road distance, travel time, ETA and delivery fee (one Routes matrix
    call). Fees here guide the choice; checkout prices the order again on its own quote."""
    ids = list(dict.fromkeys(x.strip() for x in restaurant_ids.split(",") if x.strip()))[:10]
    point = GeoPoint(lat=lat, lng=lng)
    cfg = await c.repos.get_pricing_config()
    zone = cfg.zone_for(point)
    kitchens = [
        r
        for r in [await c.repos.restaurants.get(i) for i in ids]
        if r is not None and r.status == RestaurantStatus.ACTIVE
    ]
    routes = await c.maps.routes_to([r.location for r in kitchens], point, cfg)
    now = datetime.now(UTC)
    out = []
    for r, route in zip(kitchens, routes, strict=True):
        straight = haversine_km(r.location, point)
        measured = route.source == "google"
        delivers = (
            r.supports_delivery
            and zone is not None
            and shop_delivers_to(r.location, r.delivery_radius_km, point)
        )
        out.append(
            {
                "restaurant_id": r.id,
                "name": r.name,
                "area": r.area,
                "road_distance_km": route.distance_km,
                "travel_minutes": route.duration_minutes,
                "eta_minutes": estimate_minutes(
                    r.avg_prep_minutes,
                    straight,
                    cfg,
                    travel_minutes=route.duration_minutes if measured else None,
                ),
                "delivery_fee_kobo": delivery_fee(
                    straight,
                    cfg,
                    zone.surge_bps if zone else 10_000,
                    measured_km=route.distance_km if measured else None,
                )
                if delivers
                else None,
                "delivers": delivers,
                "is_open": is_open(r.opening_hours, now) and r.is_accepting_orders,
                "source": route.source,
            }
        )
    return {"estimates": out, "provider": c.maps.provider}


# ------------------------------------------------------------------------------------- partners
@router.get("/partner/restaurants/{restaurant_id}/location")
async def restaurant_location(restaurant_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """The kitchen's pin, address, delivery radius and zone."""
    return await RestaurantLocationService(c.repos, c.maps, c.audit).get(principal, restaurant_id)


@router.put("/partner/restaurants/{restaurant_id}/location")
async def update_restaurant_location(
    restaurant_id: str, data: LocationInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    """Move the kitchen's pin / update its address (validated against the address; audited)."""
    return await RestaurantLocationService(c.repos, c.maps, c.audit).update(principal, restaurant_id, data)


@router.get("/admin/riders/live")
async def live_riders(c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    """Online riders for the operations map. Idle riders only ever have a coarse (~600 m) position."""
    require(principal, Permission.DISPATCH_MANUAL)
    riders = await c.repos.riders.find(where=[("is_online", "==", True)], limit=500)
    return [
        {
            "rider_id": r.uid,
            "name": r.name,
            "vehicle": r.vehicle.value,
            "location": r.last_location.model_dump() if r.last_location else None,
            "located_at": r.last_location_at,
            "precision": "precise" if r.active_order_ids else "coarse",
            "on_delivery": bool(r.active_order_ids),
            "active_order_ids": r.active_order_ids,
            "zone_id": r.zone_id,
        }
        for r in riders
    ]


@router.get("/admin/maps/status")
async def maps_status(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """Which maps provider is live and today's Google request count against the cap (staff)."""
    require(principal, Permission.CONFIG_READ)
    return c.maps.status()
