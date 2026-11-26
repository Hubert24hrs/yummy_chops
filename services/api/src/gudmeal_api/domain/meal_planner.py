"""Budget-aware meal planner.

Answers requests such as "I have ₦10,000 — find the best meal for two, delivered before 8pm".
Everything here is deterministic: the AI agent turns language into a `PlannerRequest`, and this module
chooses items and computes exact totals with the same pricing engine used for real quotes.
"""

from __future__ import annotations

import itertools
import math
from dataclasses import dataclass, field
from datetime import datetime, timedelta

from pydantic import BaseModel

from ..errors import DomainError
from .geo import GeoPoint, haversine_km
from .hours import is_open
from .models import (
    CartLine,
    Fulfillment,
    ItemKind,
    MenuItem,
    OptionGroup,
    OptionSelection,
    PriceBreakdown,
    Restaurant,
    RestaurantStatus,
)
from .pricing import PricingConfig, compute_price, estimate_minutes, price_line

MAX_PARTY_SIZE = 10
TOP_MAINS = 6

CITY_WIDE_KM = 60.0  # every shop delivers anywhere in its city (2026-11-26)


@dataclass
class PlannerRequest:
    budget_kobo: int
    party_size: int
    location: GeoPoint
    now: datetime
    deliver_by: datetime | None = None
    dietary: set[str] = field(default_factory=set)
    exclude_allergens: set[str] = field(default_factory=set)
    cuisines: set[str] = field(default_factory=set)
    include_drinks: bool = True
    max_options: int = 3


class PlanLine(BaseModel):
    item_id: str
    name: str
    kind: ItemKind
    quantity: int
    unit_total_kobo: int
    selection_labels: list[str] = []


class MealPlan(BaseModel):
    restaurant_id: str
    restaurant_name: str
    restaurant_rating: float
    items: list[PlanLine]
    cart_lines: list[CartLine]
    breakdown: PriceBreakdown
    distance_km: float
    eta_minutes: int
    estimated_delivery_at: datetime
    meets_deadline: bool
    budget_remaining_kobo: int
    score: float
    rationale: list[str]


class PlannerResult(BaseModel):
    plans: list[MealPlan]
    restaurants_considered: int
    restaurants_eligible: int
    cheapest_total_kobo: int | None = None
    notes: list[str] = []


@dataclass
class _Candidate:
    item: MenuItem
    line: CartLine
    unit_total: int
    quality: float
    labels: list[str]


def _default_selections(item: MenuItem, groups: dict[str, OptionGroup]) -> list[OptionSelection] | None:
    """Satisfy required option groups with the cheapest available choices; None if impossible."""
    selections: list[OptionSelection] = []
    for gid in item.option_group_ids:
        group = groups.get(gid)
        if group is None:
            return None
        if group.min_select == 0:
            continue
        available = sorted((c for c in group.choices if c.is_available), key=lambda c: c.price_delta_kobo)
        if len(available) < group.min_select:
            return None
        selections.append(
            OptionSelection(group_id=gid, choice_ids=[c.id for c in available[: group.min_select]])
        )
    return selections


def _eligible_item(item: MenuItem, req: PlannerRequest) -> bool:
    if not (item.is_active and item.is_available):
        return False
    if req.dietary and not req.dietary.issubset({d.lower() for d in item.dietary}):
        return False
    return not (req.exclude_allergens and req.exclude_allergens & {a.lower() for a in item.allergens})


def _candidates(
    restaurant: Restaurant, items: list[MenuItem], groups: dict[str, OptionGroup], req: PlannerRequest
) -> list[_Candidate]:
    max_pop = max((i.popularity for i in items), default=0) or 1
    out: list[_Candidate] = []
    for item in items:
        if not _eligible_item(item, req):
            continue
        selections = _default_selections(item, groups)
        if selections is None:
            continue
        line = CartLine(item_id=item.id, quantity=1, selections=selections)
        priced = price_line(line, item, groups)
        quality = 0.5 * (restaurant.rating / 5) + 0.5 * (math.log1p(item.popularity) / math.log1p(max_pop))
        out.append(_Candidate(item, line, priced.line_total_kobo, round(quality, 4), priced.selection_labels))
    return out


def _lines_from(counts: dict[str, int], by_id: dict[str, _Candidate]) -> list[CartLine]:
    return [
        by_id[item_id].line.model_copy(update={"quantity": qty})
        for item_id, qty in sorted(counts.items())
        if qty
    ]


def _mains_combinations(mains: list[_Candidate], party_size: int) -> list[tuple[_Candidate, ...]]:
    combos: list[tuple[_Candidate, ...]] = []
    for size in range(1, party_size + 1):
        for combo in itertools.combinations_with_replacement(mains, size):
            serves = sum(c.item.serves for c in combo)
            if serves < party_size:
                continue
            # Minimal: removing the smallest portion would leave someone without a meal.
            if serves - min(c.item.serves for c in combo) >= party_size:
                continue
            combos.append(combo)
    return combos


def plan_meals(
    req: PlannerRequest,
    catalog: list[tuple[Restaurant, list[MenuItem], dict[str, OptionGroup]]],
    cfg: PricingConfig,
) -> PlannerResult:
    if req.budget_kobo <= 0:
        return PlannerResult(
            plans=[], restaurants_considered=0, restaurants_eligible=0, notes=["Budget must be positive"]
        )
    party = max(1, min(req.party_size, MAX_PARTY_SIZE))
    zone = cfg.zone_for(req.location)
    surge = zone.surge_bps if zone else 10_000
    notes: list[str] = []
    if req.party_size > MAX_PARTY_SIZE:
        notes.append(f"Planning for {MAX_PARTY_SIZE} people (maximum for automatic planning)")

    best_per_restaurant: list[MealPlan] = []
    cheapest: int | None = None
    eligible_count = 0

    for restaurant, items, groups in catalog:
        if restaurant.status != RestaurantStatus.ACTIVE or not restaurant.is_accepting_orders:
            continue
        if not restaurant.supports_delivery or not is_open(restaurant.opening_hours, req.now):
            continue
        if req.cuisines and not req.cuisines & {c.lower() for c in restaurant.cuisines}:
            continue
        distance = haversine_km(restaurant.location, req.location)
        if distance > max(restaurant.delivery_radius_km, CITY_WIDE_KM):  # shops deliver city-wide
            continue
        prep = max([restaurant.avg_prep_minutes] + [i.prep_minutes or 0 for i in items])
        eta = estimate_minutes(min(prep, restaurant.avg_prep_minutes + 15), distance, cfg)
        arrival = req.now + timedelta(minutes=eta)
        if req.deliver_by and arrival > req.deliver_by:
            continue

        cands = _candidates(restaurant, items, groups, req)
        mains = sorted(
            (c for c in cands if c.item.kind in (ItemKind.MAIN, ItemKind.COMBO)),
            key=lambda c: (-c.quality, c.unit_total),
        )[:TOP_MAINS]
        if not mains:
            continue
        eligible_count += 1
        drinks = sorted(
            (c for c in cands if c.item.kind == ItemKind.DRINK), key=lambda c: (-c.quality, c.unit_total)
        )
        sides = sorted(
            (c for c in cands if c.item.kind in (ItemKind.SIDE, ItemKind.SNACK)),
            key=lambda c: (-c.quality, c.unit_total),
        )
        by_id = {c.item.id: c for c in cands}

        best: MealPlan | None = None
        for combo in _mains_combinations(mains, party):
            counts: dict[str, int] = {}
            for c in combo:
                counts[c.item.id] = counts.get(c.item.id, 0) + 1
            extras_options: list[tuple[dict[str, int], list[str]]] = [({}, [])]
            if req.include_drinks and drinks:
                extras_options.append(({drinks[0].item.id: party}, ["drinks for everyone"]))
                if sides:
                    extras_options.append(
                        (
                            {drinks[0].item.id: party, sides[0].item.id: 1},
                            ["drinks for everyone", "a side to share"],
                        )
                    )
            elif sides:
                extras_options.append(({sides[0].item.id: 1}, ["a side to share"]))

            for extras, extra_notes in extras_options:
                merged = dict(counts)
                for k, v in extras.items():
                    merged[k] = merged.get(k, 0) + v
                lines = _lines_from(merged, by_id)
                priced = [price_line(ln, by_id[ln.item_id].item, groups) for ln in lines]
                try:
                    result = compute_price(
                        lines=priced,
                        restaurant=restaurant,
                        fulfillment=Fulfillment.DELIVERY,
                        distance_km=distance,
                        cfg=cfg,
                        surge_bps=surge,
                        now=req.now,
                    )
                except DomainError:
                    continue  # e.g. below the restaurant's minimum order
                total = result.breakdown.total_kobo
                cheapest = total if cheapest is None else min(cheapest, total)
                if total > req.budget_kobo:
                    continue
                distinct = len(counts)
                quality = sum(c.quality * c.item.serves for c in combo) / party
                score = (
                    quality
                    + 0.12 * min(distinct, party)
                    + (0.25 if extra_notes else 0)
                    + 0.35 * (total / req.budget_kobo)
                    - 0.004 * eta
                )
                rationale = [
                    f"{restaurant.name} is rated {restaurant.rating:.1f}★ and delivers in about {eta} minutes",
                    f"{distinct} different main dish{'es' if distinct > 1 else ''} for {party} "
                    f"{'people' if party > 1 else 'person'}",
                ]
                if extra_notes:
                    rationale.append("Includes " + " and ".join(extra_notes))
                plan = MealPlan(
                    restaurant_id=restaurant.id,
                    restaurant_name=restaurant.name,
                    restaurant_rating=restaurant.rating,
                    items=[
                        PlanLine(
                            item_id=p.item_id,
                            name=p.name,
                            kind=p.kind,
                            quantity=p.quantity,
                            unit_total_kobo=p.unit_price_kobo + p.options_unit_price_kobo,
                            selection_labels=p.selection_labels,
                        )
                        for p in priced
                    ],
                    cart_lines=lines,
                    breakdown=result.breakdown,
                    distance_km=round(distance, 2),
                    eta_minutes=eta,
                    estimated_delivery_at=arrival,
                    meets_deadline=req.deliver_by is None or arrival <= req.deliver_by,
                    budget_remaining_kobo=req.budget_kobo - total,
                    score=round(score, 4),
                    rationale=rationale,
                )
                if best is None or plan.score > best.score:
                    best = plan
        if best:
            best_per_restaurant.append(best)

    best_per_restaurant.sort(key=lambda p: (-p.score, p.eta_minutes))
    if not best_per_restaurant:
        if eligible_count == 0:
            notes.append("No open restaurant can deliver to this address in time")
        elif cheapest is not None:
            notes.append("No combination fits the budget")
    return PlannerResult(
        plans=best_per_restaurant[: req.max_options],
        restaurants_considered=len(catalog),
        restaurants_eligible=eligible_count,
        cheapest_total_kobo=cheapest,
        notes=notes,
    )
