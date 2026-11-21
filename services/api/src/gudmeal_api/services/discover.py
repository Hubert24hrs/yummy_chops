"""Discover feed: dish-first sections for the Discover tab of the apps.

Three sections, each a short list of hero dishes for the dish carousel:

* ``most_loved``   - the most ordered dishes in the city (one per kitchen, ranked by popularity);
* ``new_kitchens`` - signature dishes from kitchens that joined recently;
* ``top_rated``    - the signature dish of each of the best-rated kitchens.

Prices are shown exactly as the menu lists them; delivery fee / ETA come from the catalog card, so the
numbers match the rest of the app. Each dish also carries an ``art`` key (``rice``, ``soup_swallow``,
``skewers``...) that the apps use to draw an illustrated plate until the kitchen uploads a photo.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import Literal

from pydantic import BaseModel, Field

from ..domain.cities import CITIES
from ..domain.geo import GeoPoint
from ..domain.models import ItemKind, MenuItem, Restaurant, RestaurantStatus, Vertical
from ..errors import ValidationFailed
from ..repositories import Repositories
from .catalog import CatalogService, RestaurantCard

SectionId = Literal["most_loved", "new_kitchens", "top_rated"]

#: Kitchens that joined within this many days count as "new".
NEW_KITCHEN_DAYS = 120
#: Kitchens need at least this many ratings before they can be called "top rated".
TOP_RATED_MIN_RATINGS = 50
#: Dish kinds that can headline the carousel (no drinks, add-ons or retail products).
HERO_KINDS = {ItemKind.MAIN, ItemKind.COMBO, ItemKind.SNACK, ItemKind.DESSERT, ItemKind.SIDE}

# Ordered: the first family whose keyword appears in the dish name (or tags) wins.
_ART_RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("pizza", ("pizza",)),
    ("wrap", ("shawarma", "wrap", "burrito")),
    ("broth", ("pepper soup", "peppersoup", "point and kill")),
    ("skewers", ("suya", "kilishi", "skewer", "kebab", "asun")),
    ("bowl", ("salad", "bowl", "parfait", "yoghurt", "yogurt", "granola", "abacha")),
    (
        "soup_swallow",
        (
            "egusi",
            "efo",
            "gbegiri",
            "ewedu",
            "amala",
            "eba",
            "semo",
            "fufu",
            "pounded yam",
            "edikang",
            "afang",
            "okra",
            "ogbono",
            "onugbu",
            "oha",
            "banga",
            "owerri",
            "swallow",
            "soup",
        ),
    ),
    ("rice", ("jollof", "fried rice", "ofada", "rice", "quinoa", "coconut rice")),
    (
        "bites",
        ("puff", "chops", "meat pie", "samosa", "spring roll", "fries", "chips", "moi moi", "akara", "pie"),
    ),
    (
        "grill",
        (
            "grill",
            "chicken",
            "croaker",
            "fish",
            "turkey",
            "goat",
            "gizzard",
            "bbq",
            "barbecue",
            "bole",
            "wings",
        ),
    ),
)


def plate_art(item: MenuItem) -> str:
    """The illustrated-plate family for a dish: a presentation hint, never used for pricing."""
    text = " ".join([item.name, *item.tags]).lower()
    for family, keywords in _ART_RULES:
        if any(k in text for k in keywords):
            return family
    return "plate"


class DiscoverDish(BaseModel):
    item_id: str
    restaurant_id: str
    restaurant_name: str
    area: str
    city: str
    name: str
    description: str
    price_kobo: int
    image_url: str | None
    art: str
    kind: str
    tags: list[str]
    dietary: list[str]
    allergens: list[str]
    spice_level: int
    serves: int
    prep_minutes: int | None
    likes: int = Field(description="How many times the dish was ordered (popularity)")
    rating: float = Field(description="The kitchen's rating out of 5")
    rating_count: int
    eyebrow: str
    has_options: bool
    is_available: bool
    is_open: bool
    is_accepting_orders: bool
    is_new_kitchen: bool
    distance_km: float | None = None
    eta_minutes: int | None = None
    delivery_fee_kobo: int | None = None
    delivers_to_location: bool | None = None


class DiscoverSection(BaseModel):
    id: SectionId
    title: str
    subtitle: str
    dishes: list[DiscoverDish]


class DiscoverFeed(BaseModel):
    city: str | None
    generated_at: datetime
    sections: list[DiscoverSection]


def _signature_dishes(items: list[MenuItem], count: int) -> list[MenuItem]:
    """A kitchen's best dishes to headline with: active hero kinds, most ordered first."""
    heroes = [i for i in items if i.is_active and i.kind in HERO_KINDS]
    # Dishes you can order now first; sides only headline when a kitchen has no mains, combos or snacks.
    heroes.sort(
        key=lambda i: (not i.is_available, i.kind == ItemKind.SIDE, -i.popularity, i.position, i.name)
    )
    return heroes[:count]


class DiscoverService:
    def __init__(self, repos: Repositories, catalog: CatalogService) -> None:
        self.repos = repos
        self.catalog = catalog

    async def dishes(
        self,
        *,
        city: str | None = None,
        location: GeoPoint | None = None,
        limit: int = 6,
        now: datetime | None = None,
    ) -> DiscoverFeed:
        if city is not None and city not in CITIES:
            raise ValidationFailed("We don't operate in that city yet", details={"city": city})
        now = now or datetime.now(UTC)
        limit = max(1, min(limit, 12))

        # Cards carry open-now, delivery fee and ETA for the customer's location (same maths as the lists).
        cards = {
            c.id: c
            for c in await self.catalog.list_restaurants(
                location=location, city=city, vertical=Vertical.FOOD.value, limit=100
            )
        }
        kitchens: dict[str, Restaurant] = {
            r.id: r
            for r in await self.repos.restaurants.find(
                where=[("status", "==", RestaurantStatus.ACTIVE.value)]
            )
            if r.id in cards
        }
        menus = {rid: await self.repos.list_items(rid) for rid in kitchens}
        new_since = now - timedelta(days=NEW_KITCHEN_DAYS)

        def is_new(r: Restaurant) -> bool:
            return r.created_at is not None and r.created_at >= new_since

        def dish(item: MenuItem, eyebrow: str) -> DiscoverDish:
            r, card = kitchens[item.restaurant_id], cards[item.restaurant_id]
            return _to_dish(item, r, card, eyebrow=eyebrow, is_new_kitchen=is_new(r))

        sections: list[DiscoverSection] = []

        # Most loved: the single most ordered dish of each kitchen, ranked across the city.
        signature = [d for rid in kitchens for d in _signature_dishes(menus[rid], 1)]
        signature.sort(key=lambda i: (-i.popularity, i.name))
        loved = [
            dish(item, f"#{rank} Most loved dish") for rank, item in enumerate(signature[:limit], start=1)
        ]
        if loved:
            sections.append(
                DiscoverSection(
                    id="most_loved",
                    title="Most loved dishes",
                    subtitle="What everyone near you is ordering",
                    dishes=loved,
                )
            )

        # New kitchens: newest first, up to two dishes each so a single newcomer still fills the carousel.
        newcomers = sorted(
            (r for r in kitchens.values() if is_new(r)),
            key=lambda r: (r.created_at or now, r.rating),
            reverse=True,
        )
        fresh: list[DiscoverDish] = []
        per_kitchen = 1 if len(newcomers) >= 3 else 2
        for r in newcomers:
            for item in _signature_dishes(menus[r.id], per_kitchen):
                fresh.append(dish(item, f"New kitchen · {r.area}" if r.area else "New kitchen"))
        if fresh:
            sections.append(
                DiscoverSection(
                    id="new_kitchens",
                    title="New kitchen discoveries",
                    subtitle=f"Fresh from kitchens that joined in the last {NEW_KITCHEN_DAYS // 30} months",
                    dishes=fresh[:limit],
                )
            )

        # Top rated: each well-reviewed kitchen's signature dish, best kitchens first.
        rated = sorted(
            (r for r in kitchens.values() if r.rating_count >= TOP_RATED_MIN_RATINGS),
            key=lambda r: (-r.rating, -r.rating_count, r.name),
        )
        top: list[DiscoverDish] = []
        for r in rated:
            best = _signature_dishes(menus[r.id], 1)
            if best:
                top.append(dish(best[0], f"Top-rated kitchen · {r.rating:.1f}★"))
        if top:
            sections.append(
                DiscoverSection(
                    id="top_rated",
                    title="From top-rated kitchens",
                    subtitle="Signature dishes from the best-reviewed kitchens",
                    dishes=top[:limit],
                )
            )
        return DiscoverFeed(city=city, generated_at=now, sections=sections)


def _to_dish(
    item: MenuItem, r: Restaurant, card: RestaurantCard, *, eyebrow: str, is_new_kitchen: bool
) -> DiscoverDish:
    return DiscoverDish(
        item_id=item.id,
        restaurant_id=r.id,
        restaurant_name=r.name,
        area=r.area,
        city=r.city,
        name=item.name,
        description=item.description,
        price_kobo=item.price_kobo,
        image_url=item.image_url,
        art=plate_art(item),
        kind=item.kind.value,
        tags=item.tags,
        dietary=item.dietary,
        allergens=item.allergens,
        spice_level=item.spice_level,
        serves=item.serves,
        prep_minutes=item.prep_minutes or r.avg_prep_minutes,
        likes=item.popularity,
        rating=r.rating,
        rating_count=r.rating_count,
        eyebrow=eyebrow,
        has_options=bool(item.option_group_ids),
        is_available=item.is_available,
        is_open=card.is_open,
        is_accepting_orders=card.is_accepting_orders,
        is_new_kitchen=is_new_kitchen,
        distance_km=card.distance_km,
        eta_minutes=card.eta_minutes,
        delivery_fee_kobo=card.delivery_fee_kobo,
        delivers_to_location=card.delivers_to_location,
    )
