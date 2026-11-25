"""Package Delivery pricing, state rules, wording and ledger postings (pure domain, no I/O)."""

from datetime import UTC, datetime

import pytest

from gudmeal_api.domain.catalog_groups import (
    BEAUTY_CATEGORIES,
    FOOD_CATEGORIES,
    category_matches,
    find_category,
)
from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.models import (
    Fulfillment,
    Order,
    ParcelDetails,
    ParcelSize,
    ParcelStop,
    Vertical,
)
from gudmeal_api.domain.money import apply_bps
from gudmeal_api.domain.order_state import ActorType, OrderStatus, can_transition, progress_label
from gudmeal_api.domain.pricing import (
    PricingConfig,
    compute_parcel_price,
    parcel_fee,
    parcel_minutes,
    parcel_rider_pay,
    rider_pay,
)
from gudmeal_api.errors import ValidationFailed
from gudmeal_api.ledger.ledger import order_completed, validate_postings

CFG = PricingConfig()
S, A = OrderStatus, ActorType


@pytest.mark.parametrize("size", list(ParcelSize))
@pytest.mark.parametrize("km", [0.0, 0.4, 3.0, 7.25, 18.0, 39.0])
def test_parcel_fee_is_rounded_bounded_and_grows_with_size_and_distance(size, km):
    fee = parcel_fee(km, size, CFG)
    assert fee % CFG.parcel.round_to_kobo == 0
    assert CFG.parcel.min_kobo <= fee <= CFG.parcel.max_kobo
    assert fee >= parcel_fee(max(0.0, km - 2), size, CFG)
    if size != ParcelSize.LARGE:
        bigger = list(ParcelSize)[list(ParcelSize).index(size) + 1]
        assert parcel_fee(km, bigger, CFG) >= fee


def test_parcel_fee_examples_and_surge():
    assert parcel_fee(0, ParcelSize.SMALL, CFG) == 100_000  # ₦1,000 minimum
    # 5 km straight line → 6.75 road km: ₦1,000 + 6.75 × ₦150 = ₦2,012.50 → ₦2,000
    assert parcel_fee(5, ParcelSize.SMALL, CFG) == 200_000
    assert parcel_fee(5, ParcelSize.LARGE, CFG) == 350_000  # ₦3,512.50 → ₦3,500
    assert parcel_fee(5, ParcelSize.SMALL, CFG, surge_bps=15_000) == 300_000  # 1.5× → ₦3,018.75 → ₦3,000
    assert parcel_fee(500, ParcelSize.LARGE, CFG) == CFG.parcel.max_kobo


def test_parcel_price_breakdown_and_settlement():
    result = compute_parcel_price(distance_km=5, size=ParcelSize.MEDIUM, cfg=CFG)
    b, s = result.breakdown, result.settlement
    assert b.subtotal_kobo == 0 and b.discount_kobo == 0 and b.small_order_fee_kobo == 0
    assert b.vat_kobo == apply_bps(b.delivery_fee_kobo + b.service_fee_kobo, CFG.vat_bps)
    assert b.total_kobo == b.delivery_fee_kobo + b.service_fee_kobo + b.vat_kobo
    assert s.commission_kobo == 0 and s.restaurant_earning_kobo == 0
    assert s.rider_pay_kobo == rider_pay(5, CFG) + 20_000 == parcel_rider_pay(5, ParcelSize.MEDIUM, CFG)
    assert s.rider_pay_kobo < b.delivery_fee_kobo  # the platform keeps a margin
    with pytest.raises(ValidationFailed):
        compute_parcel_price(distance_km=45, size=ParcelSize.SMALL, cfg=CFG)
    assert parcel_minutes(5, CFG) > CFG.parcel.pickup_eta_minutes


def test_parcel_state_rules():
    assert can_transition(S.PAID, S.READY_FOR_PICKUP, A.SYSTEM)
    for actor in (A.CUSTOMER, A.RESTAURANT, A.RIDER, A.STAFF):
        assert not can_transition(S.PAID, S.READY_FOR_PICKUP, actor)
    assert can_transition(S.PAID, S.REFUND_PENDING, A.CUSTOMER)
    assert can_transition(S.READY_FOR_PICKUP, S.REFUND_PENDING, A.CUSTOMER)
    assert not can_transition(
        S.RIDER_ASSIGNED, S.REFUND_PENDING, A.CUSTOMER
    )  # rider is on the way: support only
    assert not can_transition(S.PICKED_UP, S.REFUND_PENDING, A.CUSTOMER)


def test_progress_wording_per_service():
    assert progress_label(S.READY_FOR_PICKUP, "parcel") == (1, "Finding a rider")
    assert progress_label(S.RIDER_ASSIGNED, "parcel") == (2, "Rider heading to pickup")
    assert progress_label(S.IN_TRANSIT, "parcel") == (3, "On the way to the recipient")
    assert progress_label(S.PREPARING, "beauty") == (2, "Packing your order")
    assert progress_label(S.PREPARING, "food") == (2, "Preparing your food")
    assert progress_label(S.COMPLETED, "parcel") == (5, "Completed")  # falls back to the shared label


def _parcel_order(rider: str | None = "demo-rider-1") -> Order:
    result = compute_parcel_price(distance_km=8, size=ParcelSize.LARGE, cfg=CFG)
    stop = ParcelStop(
        name="Ada", phone="+2348011111111", line1="5 Bisola Street", location=GeoPoint(lat=6.44, lng=3.46)
    )
    now = datetime(2026, 11, 16, 12, tzinfo=UTC)
    return Order(
        id="o1",
        short_code="ABC123",
        vertical=Vertical.PARCEL,
        customer_id="c1",
        restaurant_id="gm-send",
        restaurant_name="Package from Ada",
        restaurant_location=stop.location,
        status=S.COMPLETED,
        fulfillment=Fulfillment.DELIVERY,
        lines=[],
        breakdown=result.breakdown,
        settlement=result.settlement,
        quote_id="q1",
        rider_id=rider,
        parcel=ParcelDetails(pickup=stop, dropoff=stop, size=ParcelSize.LARGE, category="household"),
        created_at=now,
        updated_at=now,
    )


def test_parcel_settlement_postings_balance_without_merchant_or_commission():
    order = _parcel_order()
    postings = order_completed(order)
    validate_postings(postings)
    accounts = {p.account: (p.direction, p.amount_kobo) for p in postings}
    assert accounts["liability:customer_funds"] == ("debit", order.breakdown.total_kobo)
    assert accounts["liability:rider:demo-rider-1"] == ("credit", order.settlement.rider_pay_kobo)
    assert accounts["revenue:delivery"] == (
        "credit",
        order.breakdown.delivery_fee_kobo - order.settlement.rider_pay_kobo,
    )
    assert not any(a.startswith(("liability:restaurant:", "revenue:commission")) for a in accounts)
    assert order.is_parcel


def test_browse_categories_match_case_insensitively():
    local = find_category("food", "local")
    assert local is not None and category_matches(local, ["Igbo", "Soups"])
    assert not category_matches(local, ["Pizza"])
    assert find_category("beauty", "skincare") in BEAUTY_CATEGORIES
    assert find_category("food", "skincare") is None
    assert FOOD_CATEGORIES[0].id == "promotions" == BEAUTY_CATEGORIES[0].id


def test_every_listed_neighbourhood_is_inside_a_zone_of_its_city():
    from gudmeal_api.domain.places import AREAS
    from gudmeal_api.seed.lagos import PRICING

    for area in AREAS:
        zone = PRICING.zone_for(area.location)
        assert zone is not None and zone.city == area.city, area.name


def test_cash_on_delivery_is_capped_by_what_a_rider_may_carry():
    import pytest

    from gudmeal_api.domain.pricing import PricingConfig, cod_fee, cod_limit
    from gudmeal_api.errors import ValidationFailed

    cfg = PricingConfig()
    assert cod_limit(cfg) == cfg.parcel.cod_max_kobo and cod_limit(cfg, 5_000_000) == 5_000_000
    assert cod_fee(6_000_000, cfg) > 0
    with pytest.raises(ValidationFailed):
        cod_fee(6_000_000, cfg, rider_cash_limit_kobo=5_000_000)
