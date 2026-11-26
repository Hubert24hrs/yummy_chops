from datetime import UTC, datetime, timedelta

import pytest

from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.models import (
    CartLine,
    Fulfillment,
    MenuItem,
    OptionChoice,
    OptionGroup,
    OptionSelection,
    Restaurant,
    Voucher,
)
from gudmeal_api.domain.money import apply_bps, naira
from gudmeal_api.domain.pricing import (
    PricingConfig,
    compute_price,
    delivery_fee,
    price_line,
    rider_pay,
    service_fee,
)
from gudmeal_api.errors import ItemUnavailable, ValidationFailed, VoucherInvalid

NOW = datetime(2026, 11, 16, 12, 0, tzinfo=UTC)
CFG = PricingConfig()
REST = Restaurant(
    id="r1",
    name="Test Kitchen",
    slug="test-kitchen",
    location=GeoPoint(lat=6.45, lng=3.47),
    address="1 Test St",
)
PROTEIN = OptionGroup(
    id="g1",
    restaurant_id="r1",
    name="Protein",
    min_select=1,
    max_select=1,
    choices=[
        OptionChoice(id="chicken", name="Chicken"),
        OptionChoice(id="turkey", name="Turkey", price_delta_kobo=naira(1500)),
        OptionChoice(id="goat", name="Goat", price_delta_kobo=naira(1000), is_available=False),
    ],
)
JOLLOF = MenuItem(
    id="i1",
    restaurant_id="r1",
    category_id="c",
    name="Jollof",
    price_kobo=naira(5500),
    option_group_ids=["g1"],
)


def line(choice="chicken", qty=1):
    return CartLine(
        item_id="i1", quantity=qty, selections=[OptionSelection(group_id="g1", choice_ids=[choice])]
    )


class TestLinePricing:
    def test_options_add_to_unit_price(self):
        pl = price_line(line("turkey", 2), JOLLOF, {"g1": PROTEIN})
        assert pl.unit_price_kobo == naira(5500)
        assert pl.options_unit_price_kobo == naira(1500)
        assert pl.line_total_kobo == naira(14000)
        assert pl.selection_labels == ["Protein: Turkey"]

    def test_required_group_enforced(self):
        with pytest.raises(ValidationFailed):
            price_line(CartLine(item_id="i1", quantity=1), JOLLOF, {"g1": PROTEIN})

    def test_unavailable_choice_rejected(self):
        with pytest.raises(ItemUnavailable):
            price_line(line("goat"), JOLLOF, {"g1": PROTEIN})

    def test_foreign_group_rejected(self):
        bad = CartLine(
            item_id="i1", quantity=1, selections=[OptionSelection(group_id="other", choice_ids=["x"])]
        )
        with pytest.raises(ValidationFailed):
            price_line(bad, JOLLOF, {"g1": PROTEIN})

    def test_unavailable_item_rejected(self):
        with pytest.raises(ItemUnavailable):
            price_line(line(), JOLLOF.model_copy(update={"is_available": False}), {"g1": PROTEIN})


class TestFees:
    def test_delivery_fee_bounds_and_surge(self):
        assert delivery_fee(0.1, CFG) == CFG.delivery.min_kobo
        assert delivery_fee(20, CFG) == CFG.delivery.max_kobo  # the usual cap
        # City-wide delivery (ADR-0033): a long trip never charges less than the rider is paid for it.
        for km in (25, 30, 40, 60):
            assert delivery_fee(km, CFG) >= rider_pay(km, CFG)
        base = delivery_fee(5, CFG)
        assert base % 5_000 == 0  # rounded to ₦50
        assert delivery_fee(5, CFG, surge_bps=15_000) >= base

    def test_service_fee_clamped(self):
        assert service_fee(naira(500), CFG) == CFG.service_fee_min_kobo
        assert service_fee(naira(1_000_000), CFG) == CFG.service_fee_max_kobo
        assert service_fee(naira(10_000), CFG) == naira(500)

    def test_rider_pay_minimum(self):
        assert rider_pay(0, CFG) == CFG.rider_pay.min_kobo


class TestComputePrice:
    def priced(self, qty=1):
        return [price_line(line(qty=qty), JOLLOF, {"g1": PROTEIN})]

    def test_total_is_sum_of_components(self):
        r = compute_price(
            lines=self.priced(2),
            restaurant=REST,
            fulfillment=Fulfillment.DELIVERY,
            distance_km=4.0,
            cfg=CFG,
            now=NOW,
        )
        b = r.breakdown
        assert b.subtotal_kobo == naira(11000)
        assert b.small_order_fee_kobo == 0
        assert b.total_kobo == (
            b.subtotal_kobo
            + b.delivery_fee_kobo
            + b.service_fee_kobo
            + b.small_order_fee_kobo
            + b.vat_kobo
            - b.discount_kobo
        )
        assert b.vat_kobo == apply_bps(b.delivery_fee_kobo + b.service_fee_kobo, 750)
        s = r.settlement
        assert s.commission_kobo == naira(1650)  # 15 %
        assert s.restaurant_earning_kobo == b.subtotal_kobo - s.commission_kobo

    def test_small_order_fee_for_small_delivery_orders(self):
        cheap = MenuItem(id="i2", restaurant_id="r1", category_id="c", name="Puff", price_kobo=naira(1500))
        lines = [price_line(CartLine(item_id="i2", quantity=1), cheap, {})]
        r = compute_price(
            lines=lines, restaurant=REST, fulfillment=Fulfillment.DELIVERY, distance_km=2, cfg=CFG, now=NOW
        )
        assert r.breakdown.small_order_fee_kobo == CFG.small_order_fee_kobo
        pickup = compute_price(
            lines=lines, restaurant=REST, fulfillment=Fulfillment.PICKUP, distance_km=None, cfg=CFG, now=NOW
        )
        assert pickup.breakdown.small_order_fee_kobo == 0 and pickup.breakdown.delivery_fee_kobo == 0
        assert pickup.settlement.rider_pay_kobo == 0

    def test_platform_voucher(self):
        v = Voucher(code="WELCOME500", kind="fixed", value=naira(500), min_subtotal_kobo=naira(3000))
        r = compute_price(
            lines=self.priced(),
            restaurant=REST,
            fulfillment=Fulfillment.DELIVERY,
            distance_km=3,
            cfg=CFG,
            voucher=v,
            now=NOW,
        )
        assert r.breakdown.discount_kobo == naira(500)
        assert r.settlement.platform_funded_discount_kobo == naira(500)
        assert (
            r.settlement.restaurant_earning_kobo == r.breakdown.subtotal_kobo - r.settlement.commission_kobo
        )

    def test_restaurant_voucher_reduces_restaurant_earning(self):
        v = Voucher(
            code="R20",
            kind="percent",
            value=2000,
            max_discount_kobo=naira(2000),
            funded_by="restaurant",
            restaurant_id="r1",
        )
        r = compute_price(
            lines=self.priced(2),
            restaurant=REST,
            fulfillment=Fulfillment.DELIVERY,
            distance_km=3,
            cfg=CFG,
            voucher=v,
            now=NOW,
        )
        assert r.breakdown.discount_kobo == naira(2000)  # capped (20 % of 11,000 = 2,200)
        assert r.settlement.restaurant_earning_kobo == naira(11000) - naira(1650) - naira(2000)

    def test_delivery_voucher_cannot_exceed_fee_and_reduces_vat_base(self):
        v = Voucher(code="FREEDEL", kind="percent", value=10_000, target="delivery_fee")
        r = compute_price(
            lines=self.priced(),
            restaurant=REST,
            fulfillment=Fulfillment.DELIVERY,
            distance_km=3,
            cfg=CFG,
            voucher=v,
            now=NOW,
        )
        b = r.breakdown
        assert b.discount_kobo == b.delivery_fee_kobo
        assert b.vat_kobo == apply_bps(b.service_fee_kobo, 750)

    @pytest.mark.parametrize(
        ("voucher", "msg"),
        [
            (Voucher(code="OLD", kind="fixed", value=100, ends_at=NOW - timedelta(days=1)), "expired"),
            (
                Voucher(code="SOON", kind="fixed", value=100, starts_at=NOW + timedelta(days=1)),
                "not active yet",
            ),
            (Voucher(code="OFF", kind="fixed", value=100, is_active=False), "no longer active"),
            (Voucher(code="FULL", kind="fixed", value=100, usage_limit=5, used_count=5), "fully redeemed"),
            (
                Voucher(code="OTHER", kind="fixed", value=100, restaurant_id="r2"),
                "not valid for this restaurant",
            ),
            (Voucher(code="MIN", kind="fixed", value=100, min_subtotal_kobo=naira(50_000)), "minimum"),
        ],
    )
    def test_voucher_rules(self, voucher, msg):
        with pytest.raises(VoucherInvalid, match=msg):
            compute_price(
                lines=self.priced(),
                restaurant=REST,
                fulfillment=Fulfillment.DELIVERY,
                distance_km=3,
                cfg=CFG,
                voucher=voucher,
                now=NOW,
            )

    def test_minimum_order(self):
        rest = REST.model_copy(update={"min_order_kobo": naira(20_000)})
        with pytest.raises(ValidationFailed, match="minimum"):
            compute_price(
                lines=self.priced(),
                restaurant=rest,
                fulfillment=Fulfillment.DELIVERY,
                distance_km=3,
                cfg=CFG,
                now=NOW,
            )
