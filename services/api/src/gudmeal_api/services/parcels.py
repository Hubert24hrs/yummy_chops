"""Package Delivery (courier) quotes.

A parcel is an order with `vertical=parcel` and no merchant: the pickup point takes the merchant's place
(`restaurant_location`/`restaurant_address`) so dispatch, the rider app, tracking and the ledger work unchanged.
Prices come only from `domain.pricing.compute_parcel_price`.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from ..domain.geo import haversine_km
from ..domain.models import ParcelDetails, ParcelQuote, ParcelQuoteRequest
from ..domain.pricing import PricingConfig, PricingResult, compute_parcel_price, parcel_minutes
from ..errors import NotFound, OutOfDeliveryArea, ValidationFailed
from ..maps import MapsService, RouteEstimate
from ..repositories import Repositories
from ..security.rbac import Principal

LAGOS_TZ = ZoneInfo("Africa/Lagos")
MIN_SCHEDULE_LEAD = timedelta(minutes=30)
MAX_SCHEDULE_AHEAD = timedelta(days=7)
PICKUP_HOURS = (7, 21)  # scheduled pickups between 07:00 and 21:00 Lagos time


class ParcelService:
    def __init__(
        self,
        repos: Repositories,
        *,
        ttl_seconds: int = 900,
        maps: MapsService | None = None,
        rider_cash_limit_kobo: int | None = None,
    ) -> None:
        self.repos = repos
        self.rider_cash_limit_kobo = (
            rider_cash_limit_kobo  # cash a rider collects stays within what they may carry
        )
        self.ttl = timedelta(seconds=ttl_seconds)
        self.maps = maps or MapsService(None)

    @staticmethod
    def _city(cfg: PricingConfig, req: ParcelQuoteRequest) -> tuple[str, int]:
        """Both stops must be inside one city we serve. Returns (city id, surge bps of the pickup zone)."""
        pickup_zone = cfg.zone_for(req.pickup.location)
        dropoff_zone = cfg.zone_for(req.dropoff.location)
        if pickup_zone is None or dropoff_zone is None:
            raise OutOfDeliveryArea("We deliver packages within Lagos and Enugu for now")
        if pickup_zone.city != dropoff_zone.city:
            raise OutOfDeliveryArea(
                "Pickup and drop-off are in different cities: book an Interstate waybill instead.",
                details={"pickup_city": pickup_zone.city, "dropoff_city": dropoff_zone.city},
            )
        return pickup_zone.city, pickup_zone.surge_bps

    @staticmethod
    def _check_schedule(scheduled_for: datetime | None, now: datetime) -> datetime | None:
        if scheduled_for is None:
            return None
        sched = scheduled_for if scheduled_for.tzinfo else scheduled_for.replace(tzinfo=UTC)
        if sched < now + MIN_SCHEDULE_LEAD or sched > now + MAX_SCHEDULE_AHEAD:
            raise ValidationFailed("Scheduled pickups must be between 30 minutes and 7 days ahead")
        local = sched.astimezone(LAGOS_TZ)
        if not (PICKUP_HOURS[0] <= local.hour < PICKUP_HOURS[1]):
            raise ValidationFailed("Scheduled pickups run from 7am to 9pm")
        return sched

    async def price(
        self, req: ParcelQuoteRequest, *, now: datetime | None = None, route: RouteEstimate | None = None
    ) -> tuple[PricingResult, ParcelDetails, float, datetime | None, PricingConfig, RouteEstimate]:
        """Validate and price a parcel request against the live pricing config.

        Priced on the road route (Google Routes when configured, else the estimate); pass `route` to re-price
        a quote on the same kilometres.
        """
        now = now or datetime.now(UTC)
        cfg = await self.repos.get_pricing_config()
        city, surge = self._city(cfg, req)
        sched = self._check_schedule(req.scheduled_for, now)
        distance = haversine_km(req.pickup.location, req.dropoff.location)
        if distance < 0.2:
            raise ValidationFailed("Pickup and drop-off are the same place")
        if route is None:
            route = await self.maps.route(req.pickup.location, req.dropoff.location, cfg)
        result = compute_parcel_price(
            distance_km=distance,
            size=req.size,
            cfg=cfg,
            surge_bps=surge,
            cod_amount_kobo=req.cod_amount_kobo or None,
            measured_road_km=route.distance_km if route.source == "google" else None,
            rider_cash_limit_kobo=self.rider_cash_limit_kobo,
        )
        details = ParcelDetails(
            pickup=req.pickup,
            dropoff=req.dropoff,
            size=req.size,
            category=req.category,
            description=req.description.strip(),
            declared_value_kobo=req.declared_value_kobo,
            city=city,
            cod_amount_kobo=req.cod_amount_kobo or None,
        )
        return result, details, distance, sched, cfg, route

    async def create_quote(self, principal: Principal, req: ParcelQuoteRequest) -> ParcelQuote:
        now = datetime.now(UTC)
        result, details, distance, sched, cfg, route = await self.price(req, now=now)
        measured = route.source == "google"
        eta = parcel_minutes(distance, cfg, travel_minutes=route.duration_minutes if measured else None)
        quote = ParcelQuote(
            id=uuid.uuid4().hex,
            customer_id=principal.uid,
            details=details,
            breakdown=result.breakdown,
            settlement=result.settlement,
            distance_km=round(distance, 3),
            road_distance_km=route.distance_km,
            route_source=route.source,
            eta_minutes=eta,
            estimated_delivery_at=(sched or now) + timedelta(minutes=eta),
            scheduled_for=sched,
            pricing_version=cfg.version,
            created_at=now,
            expires_at=now + self.ttl,
        )
        await self.repos.parcel_quotes.create(quote)
        return quote

    async def get_quote(self, principal: Principal, quote_id: str) -> ParcelQuote:
        quote = await self.repos.parcel_quotes.get(quote_id)
        if quote is None or quote.customer_id != principal.uid:
            raise NotFound("Quote not found")
        return quote
