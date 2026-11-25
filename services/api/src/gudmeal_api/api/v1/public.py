"""Unauthenticated discovery endpoints (SEO pages and browsing before sign-in)."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query
from sqlalchemy import text

from ...domain import places
from ...domain.cities import CITIES
from ...domain.geo import GeoPoint
from ...domain.pricing import cod_limit
from ...errors import NotFound, ServiceUnavailable, ValidationFailed
from ...services.catalog import RestaurantCard, RestaurantDetail
from ..deps import Ctr

router = APIRouter(prefix="/v1", tags=["public"])

#: Services sold by merchants (Package Delivery is a courier job, not a shop).
MerchantVertical = Literal["food", "beauty", "grocery", "pharmacy", "market"]


def _location(lat: float | None, lng: float | None) -> GeoPoint | None:
    if (lat is None) != (lng is None):
        raise ValidationFailed("Provide both lat and lng")
    return GeoPoint(lat=lat, lng=lng) if lat is not None and lng is not None else None


@router.get("/health")
async def health() -> dict[str, str]:
    # `service` lets a test app tell this API from anything else that answers on the same Wi-Fi
    # (mobile/core/lib/src/test_server.dart looks for exactly this name).
    return {"status": "ok", "service": "gudmeal-api"}


@router.get("/ready")
async def ready(c: Ctr) -> dict[str, str]:
    try:
        async with c.db.session() as s:
            await s.execute(text("SELECT 1"))
    except Exception as exc:
        raise ServiceUnavailable("Database unavailable") from exc
    return {"status": "ready"}


@router.get("/restaurants", response_model=list[RestaurantCard])
async def list_restaurants(
    c: Ctr,
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
    cuisine: Annotated[str | None, Query(max_length=40)] = None,
    q: Annotated[str | None, Query(max_length=60)] = None,
    open_now: bool = False,
    sort: Literal["recommended", "distance", "rating", "delivery_fee"] = "recommended",
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    vertical: Literal["food", "beauty", "grocery", "pharmacy", "market", "all"] = "food",
    city: Annotated[str | None, Query(max_length=30)] = None,
    category: Annotated[str | None, Query(max_length=30)] = None,
    pickup: bool = False,
) -> list[RestaurantCard]:
    """Merchants for a service: restaurants (`vertical=food`, default), beauty shops, supermarkets
    (`grocery`), pharmacies or market shoppers (`market`)."""
    return await c.catalog.list_restaurants(
        location=_location(lat, lng),
        cuisine=cuisine,
        query=q,
        open_now=open_now,
        sort=sort,
        limit=limit,
        vertical=None if vertical == "all" else vertical,
        city=city,
        category=category,
        pickup_only=pickup,
    )


@router.get("/restaurants/{restaurant_id}", response_model=RestaurantDetail)
async def restaurant_detail(
    restaurant_id: str,
    c: Ctr,
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
) -> RestaurantDetail:
    return await c.catalog.get_restaurant_detail(restaurant_id, location=_location(lat, lng))


@router.get("/restaurants/{restaurant_id}/reviews")
async def restaurant_reviews(
    restaurant_id: str, c: Ctr, limit: Annotated[int, Query(ge=1, le=50)] = 20
) -> list[Any]:
    return await c.reviews.for_restaurant(restaurant_id, limit)


@router.get("/search")
async def search(
    c: Ctr,
    q: Annotated[str, Query(min_length=2, max_length=60)],
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
    vertical: MerchantVertical | None = None,
    city: Annotated[str | None, Query(max_length=30)] = None,
) -> dict[str, Any]:
    return await c.catalog.search(q, location=_location(lat, lng), vertical=vertical, city=city)


@router.get("/cuisines")
async def cuisines(c: Ctr, vertical: MerchantVertical | None = None) -> list[dict[str, Any]]:
    return await c.catalog.cuisines(vertical)


@router.get("/services")
async def services(c: Ctr, city: Annotated[str | None, Query(max_length=30)] = None) -> list[dict[str, Any]]:
    """Yummy Chops' services (Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, Package
    Delivery) and their availability."""
    return await c.catalog.services(city=city)


@router.get("/services/{vertical}/categories")
async def service_categories(
    vertical: MerchantVertical, c: Ctr, city: Annotated[str | None, Query(max_length=30)] = None
) -> list[dict[str, Any]]:
    return await c.catalog.browse_categories(vertical, city=city)


@router.get("/places/areas")
async def place_areas(city: Annotated[str | None, Query(max_length=30)] = None) -> list[dict[str, Any]]:
    """Neighbourhoods we serve (approximate centres) for address entry without a map pin."""
    return [{"name": a.name, "city": a.city, "lat": a.lat, "lng": a.lng} for a in places.areas(city)]


@router.get("/places/resolve")
async def place_resolve(
    q: Annotated[str, Query(min_length=2, max_length=200)],
    city: Annotated[str | None, Query(max_length=30)] = None,
) -> dict[str, Any]:
    """Best-matching neighbourhood for free text, e.g. '12 Admiralty Way, Lekki Phase 1'."""
    area = places.find_area(q, city)
    if area is None:
        raise NotFound("We couldn't place that address. Add the neighbourhood, e.g. 'Yaba' or 'GRA Enugu'.")
    return {"name": area.name, "city": area.city, "lat": area.lat, "lng": area.lng}


@router.get("/cities")
async def cities() -> list[dict[str, Any]]:
    return [
        {"id": x.id, "name": x.name, "state": x.state, "center": x.center.model_dump()}
        for x in CITIES.values()
    ]


@router.get("/config/public")
async def public_config(c: Ctr) -> dict[str, Any]:
    cfg = await c.repos.get_pricing_config()
    flags = await c.repos.list_feature_flags()
    support = c.settings.support_contacts()
    return {
        "currency": "NGN",
        "service_fee_bps": cfg.service_fee_bps,
        "service_fee_min_kobo": cfg.service_fee_min_kobo,
        "service_fee_max_kobo": cfg.service_fee_max_kobo,
        "small_order_threshold_kobo": cfg.small_order_threshold_kobo,
        "small_order_fee_kobo": cfg.small_order_fee_kobo,
        "vat_bps": cfg.vat_bps,
        "zones": [
            {"id": z.id, "name": z.name, "center": z.center, "radius_km": z.radius_km}
            for z in cfg.zones
            if z.is_active
        ],
        "features": {k: bool(v.get("enabled")) for k, v in flags.items()},
        "payment_providers": sorted(c.providers),
        "wallet": {"enabled": c.settings.wallet_enabled, **c.wallet.limits()},
        "pay_on_delivery": {
            "enabled": c.settings.pay_on_delivery_enabled
            and flags.get("pay_on_delivery", {}).get("enabled", True),
            "max_order_kobo": c.settings.pay_on_delivery_max_kobo,
        },
        "cash_on_delivery": {
            "max_kobo": cod_limit(cfg, c.settings.rider_cash_limit_kobo),
            "fee_bps": cfg.parcel.cod_fee_bps,
        },
        "plus": {
            "enabled": cfg.plus.enabled,
            "price_kobo": cfg.plus.price_kobo,
            "period_days": cfg.plus.period_days,
            "free_delivery_min_subtotal_kobo": cfg.plus.free_delivery_min_subtotal_kobo,
            "service_fee_discount_bps": cfg.plus.service_fee_discount_bps,
            "points_multiplier": cfg.plus.points_multiplier,
        },
        "cities": [{"id": x.id, "name": x.name} for x in CITIES.values()],
        # An empty contact is not set up yet: the apps show it as "coming soon". `placeholders` is true while any
        # contact is missing; app builds from before 2026-11-21 read only that flag and grey out all three.
        "support": {
            "whatsapp": support.get("whatsapp", ""),
            "phone": support.get("phone", ""),
            "email": support.get("email", ""),
            "hours": c.settings.support_hours,
            "placeholders": len(support) < 3,
        },
    }
