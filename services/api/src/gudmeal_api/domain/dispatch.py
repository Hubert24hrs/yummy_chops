"""Rider eligibility and scoring for dispatch. Pure functions — the service layer handles offers/timeouts."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from .geo import GeoPoint, haversine_km
from .models import RiderProfile, RiderStatus, VehicleType


@dataclass(frozen=True)
class DispatchConfig:
    max_pickup_radius_km: float = 6.0
    max_active_deliveries: int = 2
    max_location_age_seconds: int = 180
    vehicle_max_delivery_km: dict[VehicleType, float] = field(
        default_factory=lambda: {
            VehicleType.BICYCLE: 3.0,
            # Every shop delivers anywhere in its city (2026-11-26): motorcycles and cars cover the whole city.
            VehicleType.MOTORCYCLE: 60.0,
            VehicleType.CAR: 60.0,
        }
    )
    # Score weights (lower total score = better candidate).
    w_distance: float = 1.0  # per km to the restaurant
    w_load: float = 1.5  # per active delivery
    w_acceptance: float = 2.0  # (1 - acceptance rate)
    w_rating: float = 0.8  # (5 - rating)
    avg_pickup_speed_kmh: float = 20.0


@dataclass(frozen=True)
class RankedRider:
    rider_id: str
    score: float
    distance_to_restaurant_km: float
    eta_to_restaurant_minutes: int


def ineligibility_reason(
    rider: RiderProfile,
    *,
    restaurant_location: GeoPoint,
    delivery_distance_km: float,
    now: datetime,
    cfg: DispatchConfig,
) -> str | None:
    if rider.status != RiderStatus.ACTIVE:
        return "not_active"
    if not rider.is_online:
        return "offline"
    if rider.last_location is None or rider.last_location_at is None:
        return "no_location"
    if (now - rider.last_location_at).total_seconds() > cfg.max_location_age_seconds:
        return "stale_location"
    if len(rider.active_order_ids) >= cfg.max_active_deliveries:
        return "at_capacity"
    if delivery_distance_km > cfg.vehicle_max_delivery_km.get(rider.vehicle, 0):
        return "vehicle_unsuitable"
    if haversine_km(rider.last_location, restaurant_location) > cfg.max_pickup_radius_km:
        return "too_far"
    return None


def score_rider(rider: RiderProfile, restaurant_location: GeoPoint, cfg: DispatchConfig) -> float:
    assert rider.last_location is not None
    distance = haversine_km(rider.last_location, restaurant_location)
    return round(
        cfg.w_distance * distance
        + cfg.w_load * len(rider.active_order_ids)
        + cfg.w_acceptance * (1 - rider.acceptance_rate)
        + cfg.w_rating * (5 - rider.rating),
        4,
    )


def rank_riders(
    riders: list[RiderProfile],
    *,
    restaurant_location: GeoPoint,
    delivery_distance_km: float,
    now: datetime,
    cfg: DispatchConfig | None = None,
    exclude: set[str] | None = None,
) -> list[RankedRider]:
    cfg = cfg or DispatchConfig()
    exclude = exclude or set()
    ranked: list[RankedRider] = []
    for rider in riders:
        if rider.uid in exclude:
            continue
        if ineligibility_reason(
            rider,
            restaurant_location=restaurant_location,
            delivery_distance_km=delivery_distance_km,
            now=now,
            cfg=cfg,
        ):
            continue
        assert rider.last_location is not None
        distance = haversine_km(rider.last_location, restaurant_location)
        ranked.append(
            RankedRider(
                rider_id=rider.uid,
                score=score_rider(rider, restaurant_location, cfg),
                distance_to_restaurant_km=round(distance, 2),
                eta_to_restaurant_minutes=max(1, round(distance / cfg.avg_pickup_speed_kmh * 60)),
            )
        )
    ranked.sort(key=lambda r: (r.score, r.rider_id))
    return ranked
