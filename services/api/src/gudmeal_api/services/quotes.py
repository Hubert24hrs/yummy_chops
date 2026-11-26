"""Server-side price quotes. Orders can only be created from a valid, unexpired quote."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from ..domain.geo import haversine_km
from ..domain.growth import PlusConfig, membership_active
from ..domain.hours import is_open
from ..domain.models import (
    Fulfillment,
    OptionGroup,
    Quote,
    QuoteRequest,
    Restaurant,
    RestaurantStatus,
    Voucher,
)
from ..domain.pricing import (
    PricingConfig,
    PricingResult,
    compute_price,
    estimate_minutes,
    menu_fingerprint,
    price_line,
)
from ..errors import (
    ItemUnavailable,
    NotFound,
    OutOfDeliveryArea,
    RestaurantUnavailable,
    ValidationFailed,
    VoucherInvalid,
)
from ..maps import MapsService, RouteEstimate
from ..maps.models import shop_delivers_to
from ..repositories import Repositories
from ..security.rbac import Principal

MAX_SCHEDULE_AHEAD = timedelta(days=7)
MIN_SCHEDULE_LEAD = timedelta(minutes=30)


def quoted_route(quote: Quote) -> RouteEstimate | None:
    """The road route a quote was priced on, so re-validation prices the same kilometres."""
    if quote.distance_km is None:
        return None
    return RouteEstimate(
        distance_km=quote.road_distance_km if quote.road_distance_km is not None else 0.0,
        duration_minutes=0,
        source=quote.route_source or "estimate",  # quotes from before Maps were estimates
    )


class QuoteService:
    def __init__(
        self, repos: Repositories, *, ttl_seconds: int = 600, maps: MapsService | None = None
    ) -> None:
        self.repos = repos
        self.ttl = timedelta(seconds=ttl_seconds)
        self.maps = maps or MapsService(None)

    async def _voucher(self, code: str | None, customer_id: str) -> Voucher | None:
        if not code:
            return None
        voucher = await self.repos.vouchers.get(code.strip().upper())
        if voucher is None or (voucher.customer_id is not None and voucher.customer_id != customer_id):
            raise VoucherInvalid("Voucher code not recognised")  # personal vouchers belong to one account
        used = await self.repos.store.get(f"vouchers/{voucher.code}/redemptions/{customer_id}")
        if used and int(used.get("count", 0)) >= voucher.per_customer_limit:
            # A voucher is counted when its order is created and given back if that order is never paid.
            held = await self.repos.orders.get_many(list(used.get("order_ids", [])))
            if any(o.status.value in ("draft", "pending_payment") for o in held.values()):
                raise VoucherInvalid(
                    "This voucher is on an order you have not paid for yet. "
                    "Pay for that order or cancel it, then use the voucher again."
                )
            raise VoucherInvalid("You have already used this voucher")
        return voucher

    async def plus_for(
        self, customer_id: str, vertical: str, cfg: PricingConfig, now: datetime
    ) -> PlusConfig | None:
        """The Plus plan when this customer is a member and the service qualifies for member benefits."""
        plan = cfg.plus
        if not plan.enabled or vertical not in plan.verticals:
            return None
        membership = await self.repos.memberships.get(customer_id)
        return plan if membership_active(membership, now) else None

    def _check_availability(self, restaurant: Restaurant, req: QuoteRequest, now: datetime) -> datetime:
        if restaurant.status != RestaurantStatus.ACTIVE:
            raise RestaurantUnavailable("This restaurant is not available")
        if not restaurant.is_accepting_orders:
            raise RestaurantUnavailable(f"{restaurant.name} is not accepting orders right now")
        if req.fulfillment == Fulfillment.DELIVERY and not restaurant.supports_delivery:
            raise RestaurantUnavailable(f"{restaurant.name} does not offer delivery")
        if req.fulfillment == Fulfillment.PICKUP and not restaurant.supports_pickup:
            raise RestaurantUnavailable(f"{restaurant.name} does not offer pickup")
        target = now
        if req.scheduled_for is not None:
            sched = req.scheduled_for if req.scheduled_for.tzinfo else req.scheduled_for.replace(tzinfo=UTC)
            if sched < now + MIN_SCHEDULE_LEAD or sched > now + MAX_SCHEDULE_AHEAD:
                raise ValidationFailed("Scheduled orders must be between 30 minutes and 7 days ahead")
            target = sched
        if not is_open(restaurant.opening_hours, target):
            raise RestaurantUnavailable(
                f"{restaurant.name} is closed at the requested time", details={"restaurant_id": restaurant.id}
            )
        return target

    async def price_request(
        self,
        req: QuoteRequest,
        *,
        customer_id: str,
        now: datetime | None = None,
        route: RouteEstimate | None = None,
    ) -> tuple[Restaurant, PricingResult, list, float | None, int, datetime, RouteEstimate | None]:
        """Validate and price a request against live catalog data (used for quotes and re-validation).

        Delivery is priced on the road route: measured by Google Routes when Maps is configured, otherwise
        the straight line x road factor estimate. Pass `route` to re-price a quote on the same kilometres.
        """
        now = now or datetime.now(UTC)
        restaurant = await self.repos.restaurants.get(req.restaurant_id)
        if restaurant is None:
            raise NotFound("Restaurant not found")
        target = self._check_availability(restaurant, req, now)

        item_ids = [ln.item_id for ln in req.lines]
        items = await self.repos.items.get_many(item_ids)
        for line in req.lines:
            item = items.get(line.item_id)
            if (
                item is None or item.restaurant_id != restaurant.menu_id
            ):  # branches sell the main branch's menu
                raise ItemUnavailable(
                    "An item in your cart is no longer on the menu", details={"item_id": line.item_id}
                )
            if item.requires_prescription:
                # Yummy Chops delivers over-the-counter products only (ADR-0018).
                raise ItemUnavailable(
                    f"{item.name} needs a prescription and cannot be ordered online",
                    details={"item_id": line.item_id, "reason": "prescription_required"},
                )
        group_ids = sorted({g for i in items.values() for g in i.option_group_ids})
        groups: dict[str, OptionGroup] = await self.repos.option_groups.get_many(group_ids)
        priced = [price_line(line, items[line.item_id], groups) for line in req.lines]

        distance: float | None = None
        surge = 10_000
        cfg = await self.repos.get_pricing_config()
        if req.fulfillment == Fulfillment.DELIVERY:
            assert req.delivery_address is not None
            distance = haversine_km(restaurant.location, req.delivery_address.location)
            if not shop_delivers_to(
                restaurant.location, restaurant.delivery_radius_km, req.delivery_address.location
            ):
                raise OutOfDeliveryArea(
                    f"{restaurant.name} does not deliver to this address",
                    details={"distance_km": round(distance, 2), "radius_km": restaurant.delivery_radius_km},
                )
            zone = cfg.zone_for(req.delivery_address.location)
            if cfg.zones and zone is None:
                raise OutOfDeliveryArea("We don't deliver to this area yet")
            surge = zone.surge_bps if zone else 10_000
            if route is None:
                route = await self.maps.route(restaurant.location, req.delivery_address.location, cfg)
        else:
            route = None
        measured = route is not None and route.source == "google"

        voucher = await self._voucher(req.voucher_code, customer_id)
        plus = await self.plus_for(customer_id, restaurant.vertical.value, cfg, now)
        result = compute_price(
            lines=priced,
            restaurant=restaurant,
            fulfillment=req.fulfillment,
            distance_km=distance,
            cfg=cfg,
            surge_bps=surge,
            voucher=voucher,
            now=now,
            measured_road_km=route.distance_km if measured and route else None,
            plus=plus,
        )
        prep = max([restaurant.avg_prep_minutes] + [items[i].prep_minutes or 0 for i in item_ids])
        travel = route.duration_minutes if measured and route and route.duration_minutes else None
        eta = (
            estimate_minutes(prep, distance, cfg, travel_minutes=travel)
            if req.fulfillment == Fulfillment.DELIVERY
            else prep
        )
        return restaurant, result, priced, distance, eta, target, route

    async def create_quote(self, principal: Principal, req: QuoteRequest) -> Quote:
        now = datetime.now(UTC)
        restaurant, result, priced, distance, eta, target, route = await self.price_request(
            req, customer_id=principal.uid, now=now
        )
        cfg = await self.repos.get_pricing_config()
        quote = Quote(
            id=uuid.uuid4().hex,
            customer_id=principal.uid,
            vertical=restaurant.vertical,
            restaurant_id=restaurant.id,
            restaurant_name=restaurant.name,
            lines=priced,
            breakdown=result.breakdown,
            settlement=result.settlement,
            fulfillment=req.fulfillment,
            delivery_address=req.delivery_address,
            distance_km=round(distance, 3) if distance is not None else None,
            road_distance_km=route.distance_km if route else None,
            route_source=route.source if route else None,
            eta_minutes=eta,
            estimated_delivery_at=target + timedelta(minutes=eta),
            scheduled_for=req.scheduled_for,
            pricing_version=cfg.version,
            menu_fingerprint=menu_fingerprint(priced),
            created_at=now,
            expires_at=now + self.ttl,
        )
        await self.repos.quotes.create(quote)
        return quote

    async def get_quote(self, principal: Principal, quote_id: str) -> Quote:
        quote = await self.repos.quotes.get(quote_id)
        if quote is None or quote.customer_id != principal.uid:
            raise NotFound("Quote not found")
        return quote
