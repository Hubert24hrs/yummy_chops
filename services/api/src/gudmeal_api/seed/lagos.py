"""Demo catalog for local development: fictional Lagos restaurants, menus, riders and vouchers.

The multi-service additions (Enugu, beauty & skin care shops, more Lagos food) live in `expansion.py`.

All businesses and people here are invented. Prices are realistic for Lagos in 2026 (kobo).
Used only with DATA_BACKEND=memory or explicitly via `python -m gudmeal_api.seed` against an emulator.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from ..domain.geo import GeoPoint, geohash_encode
from ..domain.hours import OpeningHours, TimeRange
from ..domain.models import (
    ItemKind,
    MenuCategory,
    MenuItem,
    OptionChoice,
    OptionGroup,
    Restaurant,
    RiderProfile,
    RiderStatus,
    VehicleType,
    Voucher,
)
from ..domain.money import naira
from ..domain.pricing import PricingConfig, ZoneConfig
from ..repositories import Repositories
from ..services.catalog import search_keywords
from .expansion import ENUGU_ZONE, enugu_riders, seed_expansion
from .retail import seed_retail

DEMO_OWNER_UID = "demo-owner-1"
DEMO_CUSTOMER_UID = "demo-customer-1"
DEMO_ADMIN_UID = "demo-admin-1"
DEMO_RIDER_UIDS = ["demo-rider-1", "demo-rider-2", "demo-rider-3", "demo-rider-4"]

PRICING = PricingConfig(
    zones=[
        ZoneConfig(
            id="lagos-island",
            name="Lagos Island & Lekki",
            center=GeoPoint(lat=6.4450, lng=3.4600),
            radius_km=14,
        ),
        ZoneConfig(
            id="lagos-mainland", name="Lagos Mainland", center=GeoPoint(lat=6.5450, lng=3.3550), radius_km=16
        ),
        ZoneConfig(
            id="lagos-lekki-ajah", name="Lekki to Ajah", center=GeoPoint(lat=6.4700, lng=3.5800), radius_km=12
        ),
        ZoneConfig(id="lagos-ikorodu", name="Ikorodu", center=GeoPoint(lat=6.6194, lng=3.5105), radius_km=9),
        ENUGU_ZONE,
    ]
)


def _hours(open_: str, close: str, *, sunday: tuple[str, str] | None = None) -> OpeningHours:
    weekly = {d: [TimeRange(open=open_, close=close)] for d in range(6)}
    weekly[6] = (
        [TimeRange(open=sunday[0], close=sunday[1])] if sunday else [TimeRange(open=open_, close=close)]
    )
    return OpeningHours(weekly=weekly)


def _r(rid: str, name: str, area: str, lat: float, lng: float, **kw: object) -> Restaurant:
    loc = GeoPoint(lat=lat, lng=lng)
    return Restaurant(
        id=rid,
        name=name,
        slug=rid.removeprefix("r-"),
        area=area,
        location=loc,
        geohash=geohash_encode(lat, lng, 9),
        address=f"{kw.pop('street')}, {area}, Lagos",
        created_at=datetime(2026, 1, 15, tzinfo=UTC),
        **kw,  # type: ignore[arg-type]
    )


RESTAURANTS: list[Restaurant] = [
    _r(
        "r-jollof-junction",
        "Jollof Junction",
        "Lekki Phase 1",
        6.4478,
        3.4723,
        street="12 Admiralty Way",
        description="Smoky party jollof, fried rice and grilled proteins, cooked over firewood every morning.",
        cuisines=["Nigerian", "Rice dishes"],
        tags=["party jollof", "family packs"],
        rating=4.7,
        rating_count=1240,
        price_level=2,
        avg_prep_minutes=18,
        opening_hours=_hours("10:00", "23:00"),
        is_featured=True,
        delivery_radius_km=12,
        owner_uid=DEMO_OWNER_UID,
        phone="+2348000000101",
    ),
    _r(
        "r-mama-ayo",
        "Mama Ayo's Kitchen",
        "Yaba",
        6.5095,
        3.3711,
        street="4 Herbert Macaulay Way",
        description="Home-style Yoruba classics: amala with gbegiri and ewedu, efo riro and ofada with ayamase.",
        cuisines=["Nigerian", "Yoruba"],
        tags=["swallow", "soups"],
        rating=4.6,
        rating_count=812,
        price_level=1,
        avg_prep_minutes=15,
        opening_hours=_hours("08:00", "22:00"),
        delivery_radius_km=10,
        phone="+2348000000102",
    ),
    _r(
        "r-suya-lane",
        "Suya Lane",
        "Victoria Island",
        6.4281,
        3.4219,
        street="7 Ajose Adeogun Street",
        description="Late-night suya, kilishi and asun grilled to order with yaji spice.",
        cuisines=["Grills", "Northern Nigerian"],
        tags=["suya", "late night", "spicy"],
        rating=4.8,
        rating_count=2031,
        price_level=2,
        avg_prep_minutes=20,
        opening_hours=_hours("16:00", "02:00"),
        is_featured=True,
        delivery_radius_km=12,
        phone="+2348000000103",
    ),
    _r(
        "r-island-small-chops",
        "Island Small Chops",
        "Ikoyi",
        6.4520,
        3.4350,
        street="22 Awolowo Road",
        description="Puff-puff, samosa, spring rolls, peppered gizzard and party platters.",
        cuisines=["Snacks", "Party food"],
        tags=["small chops", "platters"],
        rating=4.4,
        rating_count=390,
        price_level=2,
        avg_prep_minutes=22,
        opening_hours=_hours("09:00", "20:00", sunday=("12:00", "19:00")),
        delivery_radius_km=10,
        phone="+2348000000104",
    ),
    _r(
        "r-calabar-pot",
        "Calabar Pot",
        "Surulere",
        6.4969,
        3.3602,
        street="15 Adeniran Ogunsanya Street",
        description="Edikang ikong, afang and catfish pepper soup, the Calabar way.",
        cuisines=["Nigerian", "Efik"],
        tags=["soups", "pepper soup", "seafood"],
        rating=4.5,
        rating_count=522,
        price_level=2,
        avg_prep_minutes=25,
        opening_hours=_hours("10:00", "22:00"),
        delivery_radius_km=12,
        phone="+2348000000105",
    ),
    _r(
        "r-shawarma-republic",
        "Shawarma Republic",
        "Ikeja GRA",
        6.5833,
        3.3500,
        street="3 Isaac John Street",
        description="Loaded chicken and beef shawarma, wraps and loaded fries.",
        cuisines=["Fast food", "Shawarma"],
        tags=["wraps", "quick bites"],
        rating=4.3,
        rating_count=1688,
        price_level=1,
        avg_prep_minutes=12,
        opening_hours=_hours("11:00", "23:30"),
        delivery_radius_km=10,
        phone="+2348000000106",
    ),
    _r(
        "r-oniru-grill-house",
        "Oniru Grill House",
        "Oniru",
        6.4366,
        3.4497,
        street="Plot 9 Yesufu Abiodun Way",
        description="Whole grilled croaker, bole and fish, and barbecue platters for sharing.",
        cuisines=["Grills", "Seafood"],
        tags=["grilled fish", "sharing"],
        rating=4.6,
        rating_count=704,
        price_level=3,
        avg_prep_minutes=30,
        opening_hours=_hours("12:00", "23:00"),
        delivery_radius_km=12,
        phone="+2348000000107",
    ),
    _r(
        "r-green-bowl",
        "Green Bowl Lagos",
        "Victoria Island",
        6.4302,
        3.4185,
        street="10 Saka Tinubu Street",
        description="Plant-forward bowls, salads and fresh juices made with local produce.",
        cuisines=["Healthy", "Vegetarian"],
        tags=["vegan options", "salads", "juices"],
        rating=4.5,
        rating_count=455,
        price_level=2,
        avg_prep_minutes=12,
        opening_hours=_hours("07:30", "21:00"),
        delivery_radius_km=10,
        phone="+2348000000108",
    ),
]


def _protein_group(rid: str) -> OptionGroup:
    return OptionGroup(
        id=f"{rid}-protein",
        restaurant_id=rid,
        name="Choose your protein",
        min_select=1,
        max_select=1,
        choices=[
            OptionChoice(id="chicken", name="Fried chicken"),
            OptionChoice(id="beef", name="Peppered beef"),
            OptionChoice(id="turkey", name="Grilled turkey", price_delta_kobo=naira(1500)),
            OptionChoice(id="goat", name="Goat meat", price_delta_kobo=naira(1000)),
            OptionChoice(id="fish", name="Fried fish", price_delta_kobo=naira(1000)),
        ],
    )


def _extras_group(rid: str) -> OptionGroup:
    return OptionGroup(
        id=f"{rid}-extras",
        restaurant_id=rid,
        name="Extras",
        min_select=0,
        max_select=3,
        choices=[
            OptionChoice(id="dodo", name="Extra dodo (plantain)", price_delta_kobo=naira(1000)),
            OptionChoice(id="moimoi", name="Moi moi", price_delta_kobo=naira(1500)),
            OptionChoice(id="egg", name="Boiled egg", price_delta_kobo=naira(500)),
            OptionChoice(id="coleslaw", name="Coleslaw", price_delta_kobo=naira(700)),
        ],
    )


def _drinks(rid: str, cat: str) -> list[MenuItem]:
    rows = [
        ("Chapman", 2500, 60),
        ("Zobo (50cl)", 1200, 45),
        ("Chilled water (75cl)", 500, 30),
        ("Malt drink", 1000, 25),
    ]
    return [
        _item(
            rid,
            f"{rid}-drink-{i}",
            cat,
            name,
            price,
            kind=ItemKind.DRINK,
            popularity=pop,
            dietary=["vegetarian", "vegan"],
            description="Chilled",
        )
        for i, (name, price, pop) in enumerate(rows)
    ]


def _item(rid: str, iid: str, cat: str, name: str, price: int, **kw: object) -> MenuItem:
    desc = str(kw.pop("description", ""))
    tags = list(kw.pop("tags", []))  # type: ignore[call-overload]
    return MenuItem(
        id=iid,
        restaurant_id=rid,
        category_id=cat,
        name=name,
        description=desc,
        price_kobo=naira(price),
        tags=tags,
        search_keywords=search_keywords(name, desc, " ".join(tags)),
        **kw,  # type: ignore[arg-type]
    )


def _menus() -> dict[str, tuple[list[MenuCategory], list[MenuItem], list[OptionGroup]]]:
    menus: dict[str, tuple[list[MenuCategory], list[MenuItem], list[OptionGroup]]] = {}

    rid = "r-jollof-junction"
    cats = [
        MenuCategory(id="rice", name="Rice dishes", position=0),
        MenuCategory(id="packs", name="Family packs", position=1),
        MenuCategory(id="sides", name="Sides", position=2),
        MenuCategory(id="drinks", name="Drinks", position=3),
    ]
    groups = [_protein_group(rid), _extras_group(rid)]
    items = [
        _item(
            rid,
            "jj-party-jollof",
            "rice",
            "Party Jollof Rice",
            5500,
            popularity=980,
            description="Smoky firewood jollof with your choice of protein and dodo.",
            tags=["jollof", "rice"],
            option_group_ids=[f"{rid}-protein", f"{rid}-extras"],
            spice_level=1,
            allergens=[],
        ),
        _item(
            rid,
            "jj-fried-rice",
            "rice",
            "Nigerian Fried Rice",
            6000,
            popularity=640,
            description="Fried rice with liver, prawns and mixed vegetables.",
            tags=["fried rice", "rice"],
            option_group_ids=[f"{rid}-protein", f"{rid}-extras"],
            allergens=["shellfish"],
        ),
        _item(
            rid,
            "jj-ofada",
            "rice",
            "Ofada Rice & Ayamase",
            6500,
            popularity=410,
            description="Local ofada rice with green pepper ayamase stew and assorted meat.",
            tags=["ofada", "spicy"],
            spice_level=3,
            option_group_ids=[f"{rid}-extras"],
        ),
        _item(
            rid,
            "jj-family-jollof",
            "packs",
            "Jollof Family Pack (serves 3)",
            16500,
            kind=ItemKind.COMBO,
            serves=3,
            popularity=300,
            description="Party jollof, 3 pieces of chicken, dodo and coleslaw for three.",
            tags=["family", "jollof", "sharing"],
        ),
        _item(
            rid,
            "jj-dodo",
            "sides",
            "Dodo (fried plantain)",
            1500,
            kind=ItemKind.SIDE,
            popularity=520,
            dietary=["vegetarian", "vegan"],
            tags=["plantain"],
        ),
        _item(
            rid,
            "jj-moimoi",
            "sides",
            "Moi Moi",
            1500,
            kind=ItemKind.SIDE,
            popularity=280,
            dietary=["vegetarian"],
            allergens=["egg"],
            tags=["beans"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, groups)

    rid = "r-mama-ayo"
    cats = [
        MenuCategory(id="swallow", name="Swallow & soups", position=0),
        MenuCategory(id="rice", name="Rice", position=1),
        MenuCategory(id="drinks", name="Drinks", position=2),
    ]
    groups = [_protein_group(rid)]
    items = [
        _item(
            rid,
            "ma-amala",
            "swallow",
            "Amala, Gbegiri & Ewedu",
            5000,
            popularity=900,
            description="Soft amala with gbegiri (bean soup), ewedu and stew.",
            tags=["amala", "abula", "swallow"],
            option_group_ids=[f"{rid}-protein"],
        ),
        _item(
            rid,
            "ma-efo",
            "swallow",
            "Efo Riro & Semo",
            5500,
            popularity=610,
            description="Rich spinach stew with locust beans and assorted meat.",
            tags=["efo riro", "swallow"],
            option_group_ids=[f"{rid}-protein"],
        ),
        _item(
            rid,
            "ma-poundo-egusi",
            "swallow",
            "Pounded Yam & Egusi",
            6500,
            popularity=720,
            description="Hand-pounded yam with melon seed egusi soup.",
            tags=["pounded yam", "egusi", "swallow"],
            option_group_ids=[f"{rid}-protein"],
        ),
        _item(
            rid,
            "ma-ofada",
            "rice",
            "Ofada Rice & Ayamase",
            6000,
            popularity=380,
            spice_level=3,
            description="Ofada rice with designer stew.",
            tags=["ofada", "spicy"],
        ),
        _item(
            rid,
            "ma-beans-dodo",
            "rice",
            "Ewa Agoyin & Dodo",
            3500,
            popularity=430,
            description="Mashed beans with agoyin pepper sauce and plantain.",
            tags=["beans", "agoyin"],
            dietary=["vegetarian"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, groups)

    rid = "r-suya-lane"
    cats = [
        MenuCategory(id="grills", name="Suya & grills", position=0),
        MenuCategory(id="drinks", name="Drinks", position=1),
    ]
    groups = [
        OptionGroup(
            id=f"{rid}-heat",
            restaurant_id=rid,
            name="Yaji level",
            min_select=1,
            max_select=1,
            choices=[
                OptionChoice(id="mild", name="Mild"),
                OptionChoice(id="medium", name="Medium"),
                OptionChoice(id="fire", name="Fire"),
            ],
        )
    ]
    items = [
        _item(
            rid,
            "sl-beef-suya",
            "grills",
            "Beef Suya (250g)",
            4500,
            popularity=1500,
            spice_level=2,
            description="Thinly sliced beef, yaji spice, onions and tomatoes.",
            tags=["suya", "beef"],
            option_group_ids=[f"{rid}-heat"],
            allergens=["peanuts"],
        ),
        _item(
            rid,
            "sl-chicken-suya",
            "grills",
            "Chicken Suya (250g)",
            5000,
            popularity=900,
            spice_level=2,
            description="Boneless chicken thigh with yaji.",
            tags=["suya", "chicken"],
            option_group_ids=[f"{rid}-heat"],
            allergens=["peanuts"],
        ),
        _item(
            rid,
            "sl-asun",
            "grills",
            "Asun (spicy goat)",
            6000,
            popularity=640,
            spice_level=3,
            description="Smoked goat meat tossed in scotch bonnet.",
            tags=["asun", "goat", "spicy"],
        ),
        _item(
            rid,
            "sl-platter",
            "grills",
            "Suya Platter (serves 2)",
            11000,
            kind=ItemKind.COMBO,
            serves=2,
            popularity=420,
            description="Beef and chicken suya, kilishi, yam chips.",
            tags=["sharing", "suya"],
            allergens=["peanuts"],
        ),
        _item(
            rid,
            "sl-yam-chips",
            "grills",
            "Yam Chips",
            2000,
            kind=ItemKind.SIDE,
            popularity=300,
            dietary=["vegetarian", "vegan"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, groups)

    rid = "r-island-small-chops"
    cats = [
        MenuCategory(id="chops", name="Small chops", position=0),
        MenuCategory(id="drinks", name="Drinks", position=1),
    ]
    items = [
        _item(
            rid,
            "isc-platter",
            "chops",
            "Small Chops Platter (serves 2)",
            8000,
            kind=ItemKind.COMBO,
            serves=2,
            popularity=700,
            description="Puff-puff, samosa, spring rolls, peppered gizzard and chicken.",
            tags=["small chops", "party"],
            allergens=["gluten", "egg"],
        ),
        _item(
            rid,
            "isc-puff",
            "chops",
            "Puff-Puff (10 pcs)",
            1500,
            kind=ItemKind.SNACK,
            popularity=520,
            dietary=["vegetarian"],
            allergens=["gluten"],
        ),
        _item(
            rid,
            "isc-gizzard",
            "chops",
            "Peppered Gizzard",
            4000,
            kind=ItemKind.MAIN,
            popularity=380,
            spice_level=2,
            tags=["gizzard", "peppered"],
        ),
        _item(
            rid,
            "isc-samosa",
            "chops",
            "Samosa (6 pcs)",
            2500,
            kind=ItemKind.SNACK,
            popularity=260,
            allergens=["gluten"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, [])

    rid = "r-calabar-pot"
    cats = [
        MenuCategory(id="soups", name="Soups", position=0),
        MenuCategory(id="drinks", name="Drinks", position=1),
    ]
    swallow = OptionGroup(
        id=f"{rid}-swallow",
        restaurant_id=rid,
        name="Swallow",
        min_select=1,
        max_select=1,
        choices=[
            OptionChoice(id="garri", name="Eba (garri)"),
            OptionChoice(id="semo", name="Semo"),
            OptionChoice(id="poundo", name="Pounded yam", price_delta_kobo=naira(800)),
        ],
    )
    items = [
        _item(
            rid,
            "cp-edikang",
            "soups",
            "Edikang Ikong & Swallow",
            7000,
            popularity=600,
            description="Vegetable soup with periwinkle, beef and stockfish.",
            tags=["edikang ikong", "soup"],
            option_group_ids=[f"{rid}-swallow"],
            allergens=["shellfish", "fish"],
        ),
        _item(
            rid,
            "cp-afang",
            "soups",
            "Afang Soup & Swallow",
            6500,
            popularity=470,
            tags=["afang", "soup"],
            option_group_ids=[f"{rid}-swallow"],
            allergens=["fish"],
        ),
        _item(
            rid,
            "cp-catfish",
            "soups",
            "Catfish Pepper Soup",
            7500,
            popularity=520,
            spice_level=3,
            tags=["pepper soup", "catfish"],
            allergens=["fish"],
        ),
        _item(
            rid,
            "cp-goat-pepper",
            "soups",
            "Goat Meat Pepper Soup",
            5500,
            popularity=430,
            spice_level=3,
            tags=["pepper soup", "goat"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, [swallow])

    rid = "r-shawarma-republic"
    cats = [
        MenuCategory(id="wraps", name="Shawarma & wraps", position=0),
        MenuCategory(id="sides", name="Sides", position=1),
        MenuCategory(id="drinks", name="Drinks", position=2),
    ]
    size = OptionGroup(
        id=f"{rid}-size",
        restaurant_id=rid,
        name="Size",
        min_select=1,
        max_select=1,
        choices=[
            OptionChoice(id="regular", name="Regular"),
            OptionChoice(id="jumbo", name="Jumbo", price_delta_kobo=naira(1500)),
        ],
    )
    addons = OptionGroup(
        id=f"{rid}-addons",
        restaurant_id=rid,
        name="Add-ons",
        min_select=0,
        max_select=2,
        choices=[
            OptionChoice(id="sausage", name="Extra sausage", price_delta_kobo=naira(800)),
            OptionChoice(id="cheese", name="Cheese", price_delta_kobo=naira(1000)),
        ],
    )
    items = [
        _item(
            rid,
            "sr-chicken",
            "wraps",
            "Chicken Shawarma",
            4500,
            popularity=1400,
            tags=["shawarma", "chicken"],
            option_group_ids=[f"{rid}-size", f"{rid}-addons"],
            allergens=["gluten", "dairy"],
        ),
        _item(
            rid,
            "sr-beef",
            "wraps",
            "Beef Shawarma",
            5000,
            popularity=800,
            tags=["shawarma", "beef"],
            option_group_ids=[f"{rid}-size", f"{rid}-addons"],
            allergens=["gluten", "dairy"],
        ),
        _item(
            rid,
            "sr-veggie",
            "wraps",
            "Veggie Wrap",
            3800,
            popularity=210,
            dietary=["vegetarian"],
            tags=["wrap"],
            option_group_ids=[f"{rid}-size"],
            allergens=["gluten"],
        ),
        _item(
            rid,
            "sr-fries",
            "sides",
            "Loaded Fries",
            2500,
            kind=ItemKind.SIDE,
            popularity=600,
            allergens=["dairy"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, [size, addons])

    rid = "r-oniru-grill-house"
    cats = [
        MenuCategory(id="fish", name="Grilled fish", position=0),
        MenuCategory(id="bbq", name="Barbecue", position=1),
        MenuCategory(id="drinks", name="Drinks", position=2),
    ]
    items = [
        _item(
            rid,
            "og-croaker",
            "fish",
            "Whole Grilled Croaker (serves 2)",
            14000,
            kind=ItemKind.COMBO,
            serves=2,
            popularity=650,
            description="Charcoal-grilled croaker with plantain and pepper sauce.",
            tags=["grilled fish", "croaker", "sharing"],
            allergens=["fish"],
        ),
        _item(
            rid,
            "og-bole",
            "fish",
            "Bole & Fish",
            7000,
            popularity=540,
            tags=["bole", "port harcourt"],
            description="Roasted plantain and yam with grilled fish and palm-oil sauce.",
            allergens=["fish"],
        ),
        _item(rid, "og-chicken", "bbq", "BBQ Chicken Quarter", 6000, popularity=420, tags=["bbq", "chicken"]),
        _item(
            rid,
            "og-platter",
            "bbq",
            "Mixed Grill Platter (serves 3)",
            21000,
            kind=ItemKind.COMBO,
            serves=3,
            popularity=260,
            tags=["sharing", "bbq"],
        ),
        *_drinks(rid, "drinks"),
    ]
    menus[rid] = (cats, items, [])

    rid = "r-green-bowl"
    cats = [
        MenuCategory(id="bowls", name="Bowls", position=0),
        MenuCategory(id="juices", name="Fresh juices", position=1),
    ]
    items = [
        _item(
            rid,
            "gb-plantain-bowl",
            "bowls",
            "Plantain & Bean Power Bowl",
            5500,
            popularity=500,
            dietary=["vegetarian", "vegan"],
            description="Roasted plantain, honey beans, avocado, greens.",
            tags=["bowl", "healthy"],
        ),
        _item(
            rid,
            "gb-chicken-salad",
            "bowls",
            "Grilled Chicken Salad",
            6500,
            popularity=430,
            description="Grilled chicken, mixed leaves, cucumber, groundnut dressing.",
            tags=["salad"],
            allergens=["peanuts"],
        ),
        _item(
            rid,
            "gb-jollof-quinoa",
            "bowls",
            "Jollof Quinoa Bowl",
            6000,
            popularity=380,
            dietary=["vegetarian", "vegan", "gluten_free"],
            tags=["jollof", "quinoa"],
        ),
        _item(
            rid,
            "gb-pineapple",
            "juices",
            "Pineapple & Ginger Juice",
            2500,
            kind=ItemKind.DRINK,
            popularity=300,
            dietary=["vegetarian", "vegan"],
        ),
        _item(
            rid,
            "gb-watermelon",
            "juices",
            "Watermelon Mint Juice",
            2500,
            kind=ItemKind.DRINK,
            popularity=260,
            dietary=["vegetarian", "vegan"],
        ),
    ]
    menus[rid] = (cats, items, [])
    return menus


VOUCHERS = [
    Voucher(
        code="WELCOME500",
        description="₦500 off your first order over ₦3,000",
        kind="fixed",
        value=naira(500),
        min_subtotal_kobo=naira(3000),
        funded_by="platform",
        per_customer_limit=1,
    ),
    Voucher(
        code="GUDLUNCH",
        description="10% off (up to ₦1,500)",
        kind="percent",
        value=1000,
        max_discount_kobo=naira(1500),
        funded_by="platform",
        per_customer_limit=3,
    ),
    Voucher(
        code="FREEDELIVERY",
        description="Free delivery (up to ₦1,500)",
        kind="percent",
        value=10_000,
        max_discount_kobo=naira(1500),
        target="delivery_fee",
        funded_by="platform",
        per_customer_limit=2,
    ),
    Voucher(
        code="JOLLOF20",
        description="20% off at Jollof Junction (up to ₦2,000)",
        kind="percent",
        value=2000,
        max_discount_kobo=naira(2000),
        funded_by="restaurant",
        restaurant_id="r-jollof-junction",
        per_customer_limit=2,
    ),
]


def demo_riders(now: datetime) -> list[RiderProfile]:
    spots = [
        (6.4500, 3.4700, VehicleType.MOTORCYCLE, "Chidi Okafor"),
        (6.4300, 3.4250, VehicleType.MOTORCYCLE, "Bola Adeyemi"),
        (6.5050, 3.3700, VehicleType.MOTORCYCLE, "Musa Ibrahim"),
        (6.4400, 3.4500, VehicleType.BICYCLE, "Tunde Bakare"),
    ]
    return [
        RiderProfile(
            uid=uid,
            name=name,
            phone=f"+23480000002{i:02d}",
            vehicle=vehicle,
            status=RiderStatus.ACTIVE,
            is_online=True,
            rating=4.7 + 0.05 * (i % 3),
            rating_count=100 + 40 * i,
            acceptance_rate=0.9,
            offers_received=50,
            offers_accepted=45,
            last_location=GeoPoint(lat=lat, lng=lng),
            last_location_at=now,
            geohash=geohash_encode(lat, lng, 7),
            created_at=now - timedelta(days=60),
        )
        for i, (uid, (lat, lng, vehicle, name)) in enumerate(zip(DEMO_RIDER_UIDS, spots, strict=True))
    ]


async def seed(repos: Repositories) -> dict[str, int]:
    now = datetime.now(UTC)
    await repos.save_pricing_config(PRICING)
    menus = _menus()
    counts = {"restaurants": 0, "items": 0, "groups": 0, "riders": 0, "vouchers": 0}
    for r in RESTAURANTS:
        await repos.restaurants.save(r)
        cats, items, groups = menus[r.id]
        await repos.set_menu_categories(r.id, cats)
        for g in groups:
            await repos.option_groups.save(g)
        for pos, it in enumerate(items):
            await repos.items.save(it.model_copy(update={"position": pos}))
        counts["restaurants"] += 1
        counts["items"] += len(items)
        counts["groups"] += len(groups)
    for rider in demo_riders(now):
        await repos.riders.save(rider)
        counts["riders"] += 1
    for v in VOUCHERS:
        await repos.vouchers.save(v)
        counts["vouchers"] += 1
    for key, enabled, desc in [
        ("ai_concierge", True, "AI food concierge in customer apps"),
        ("group_ordering", False, "Group ordering (beta)"),
        ("scheduled_orders", True, "Schedule orders up to 7 days ahead"),
    ]:
        await repos.set_feature_flag(key, enabled, desc, "seed")
    extra = await seed_expansion(repos, now)
    counts["restaurants"] += extra["merchants"]
    counts["items"] += extra["items"]
    counts["riders"] += extra["riders"]
    counts["vouchers"] += extra["vouchers"]
    retail = await seed_retail(repos)  # supermarkets, pharmacies and market shoppers (ADR-0018)
    counts["restaurants"] += retail["merchants"]
    counts["items"] += retail["items"]
    counts["groups"] += retail["groups"]
    counts["vouchers"] += retail["vouchers"]
    return counts


async def refresh_demo_riders(repos: Repositories) -> None:
    """Keep seeded demo riders' locations fresh in local dev (simulates rider app pings)."""
    now = datetime.now(UTC)
    for rider in [*demo_riders(now), *enugu_riders(now)]:
        existing = await repos.riders.get(rider.uid)
        if existing and existing.is_online and existing.last_location:
            await repos.riders.update(rider.uid, {"last_location_at": now})


async def park_extra_demo_riders(repos: Repositories) -> None:
    """Local dev: only demo-rider-1 (rider@yummychops.test, the account people sign in to the rider app with) starts
    online. Otherwise job offers go to demo riders nobody is holding and run out before the app ever sees them."""
    now = datetime.now(UTC)
    for rider in [*demo_riders(now), *enugu_riders(now)]:
        if rider.uid != DEMO_RIDER_UIDS[0]:
            await repos.riders.update(rider.uid, {"is_online": False})


async def open_demo_shops_all_day(repos: Repositories) -> int:
    """Local testing only (DEMO_SHOPS_ALWAYS_OPEN): every shop takes orders around the clock, so testers can order
    at night. Real shops keep their own hours."""
    always = OpeningHours.every_day("00:00", "23:59").model_dump(mode="json")
    shops = await repos.restaurants.find()
    for shop in shops:
        await repos.restaurants.update(shop.id, {"opening_hours": always})
    return len(shops)
