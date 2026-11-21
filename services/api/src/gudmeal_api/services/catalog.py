"""Merchant discovery (restaurants, shops, pharmacies, markets), menus, search and partner menu management."""

from __future__ import annotations

import re
import uuid
from datetime import UTC, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field

from ..domain.catalog_groups import CATEGORIES_BY_VERTICAL, PROMOTIONS, category_matches, find_category
from ..domain.cities import CITIES
from ..domain.geo import GeoPoint, geohash_encode, haversine_km
from ..domain.hours import OpeningHours, is_open, next_opening
from ..domain.models import (
    MERCHANT_VERTICALS,
    ItemKind,
    MenuCategory,
    MenuItem,
    OptionChoice,
    OptionGroup,
    Restaurant,
    RestaurantStatus,
    Vertical,
    Voucher,
)
from ..domain.pricing import delivery_fee, estimate_minutes
from ..errors import NotFound, ValidationFailed
from ..repositories import Repositories
from ..security.rbac import Principal, require_restaurant

_TOKEN = re.compile(r"[a-z0-9]+")
STOPWORDS = {"and", "with", "the", "of", "in", "a", "an", "&", "for"}


def slugify(text: str) -> str:
    slug = "-".join(_TOKEN.findall(text.lower()))
    return slug[:60] or "restaurant"


def search_keywords(*texts: str) -> list[str]:
    tokens: set[str] = set()
    for text in texts:
        for tok in _TOKEN.findall((text or "").lower()):
            if tok in STOPWORDS or len(tok) < 2:
                continue
            tokens.add(tok)
            for n in range(3, min(len(tok), 8)):
                tokens.add(tok[:n])  # prefixes for type-ahead
    return sorted(tokens)[:60]


#: The merchant services in the order the apps show them: id, name, one-line description.
MERCHANT_SERVICES: tuple[tuple[Vertical, str, str], ...] = (
    (Vertical.FOOD, "Order Food", "Restaurants, local dishes, snacks and drinks"),
    (Vertical.PHARMACY, "Pharmacy", "Over-the-counter medicines, vitamins, first aid and personal care"),
    (Vertical.BEAUTY, "Beauty & Skin Care", "Skincare, hair care, make-up and fragrance from partner shops"),
    (
        Vertical.GROCERY,
        "Shop & Groceries",
        "Supermarkets and convenience stores: drinks, food cupboard, household",
    ),
    (
        Vertical.MARKET,
        "Buy Foodstuff",
        "Rice, beans, garri, yam, pepper and more, bought fresh for you at the market",
    ),
)
MERCHANT_BADGES: dict[Vertical, str] = {Vertical.MARKET: "Shopper"}


class PromoBadge(BaseModel):
    code: str
    label: str


class RestaurantCard(BaseModel):
    id: str
    vertical: str = "food"
    city: str = "lagos"
    name: str
    slug: str
    description: str
    cuisines: list[str]
    tags: list[str]
    image_url: str | None
    cover_url: str | None
    area: str
    rating: float
    rating_count: int
    price_level: int
    is_open: bool
    is_accepting_orders: bool
    is_featured: bool
    next_opening_at: datetime | None = None
    distance_km: float | None = None
    eta_minutes: int | None = None
    delivery_fee_kobo: int | None = None
    min_order_kobo: int
    supports_delivery: bool
    supports_pickup: bool
    delivers_to_location: bool | None = None
    promotions: list[PromoBadge] = Field(default_factory=list)
    location: GeoPoint | None = None  # the shop's public pin (for maps)
    badge: str | None = None  # e.g. "Shopper" on a market: someone buys the items for the customer


class MenuSection(BaseModel):
    category: MenuCategory
    items: list[MenuItem]


class RestaurantDetail(BaseModel):
    restaurant: RestaurantCard
    address: str
    location: GeoPoint
    opening_hours: OpeningHours
    avg_prep_minutes: int
    sections: list[MenuSection]
    option_groups: dict[str, OptionGroup]


class ItemInput(BaseModel):
    category_id: str
    name: str = Field(min_length=1, max_length=80)
    description: str = Field(default="", max_length=400)
    price_kobo: int = Field(gt=0, le=100_000_000)
    image_url: str | None = Field(default=None, max_length=500)
    kind: ItemKind = ItemKind.MAIN
    tags: list[str] = Field(default_factory=list, max_length=15)
    dietary: list[str] = Field(default_factory=list, max_length=10)
    allergens: list[str] = Field(default_factory=list, max_length=15)
    serves: int = Field(default=1, ge=1, le=20)
    spice_level: int = Field(default=0, ge=0, le=3)
    option_group_ids: list[str] = Field(default_factory=list, max_length=10)
    prep_minutes: int | None = Field(default=None, ge=1, le=180)
    is_available: bool = True
    position: int = 0
    # Products (shops, pharmacies, markets): the size or measure, the brand, and a picture placeholder.
    unit_label: str | None = Field(default=None, max_length=30)
    brand: str | None = Field(default=None, max_length=40)
    emoji: str | None = Field(default=None, max_length=8)
    requires_prescription: bool = False  # hidden from customers and never sold (over-the-counter only)


class OptionGroupInput(BaseModel):
    name: str = Field(min_length=1, max_length=60)
    min_select: int = Field(default=0, ge=0, le=20)
    max_select: int = Field(default=1, ge=1, le=20)
    choices: list[OptionChoice] = Field(min_length=1, max_length=30)


class RestaurantSettingsInput(BaseModel):
    description: str | None = Field(default=None, max_length=500)
    is_accepting_orders: bool | None = None
    avg_prep_minutes: int | None = Field(default=None, ge=1, le=180)
    opening_hours: OpeningHours | None = None
    min_order_kobo: int | None = Field(default=None, ge=0)
    supports_pickup: bool | None = None
    supports_delivery: bool | None = None
    image_url: str | None = Field(default=None, max_length=500)
    cover_url: str | None = Field(default=None, max_length=500)
    phone: str | None = Field(default=None, max_length=20)


class CatalogService:
    def __init__(self, repos: Repositories) -> None:
        self.repos = repos

    # ---------------------------------------------------------------- discovery ----------------
    async def _active_promotions(self, now: datetime) -> dict[str, list[PromoBadge]]:
        """Merchant-specific vouchers that a customer can use right now, keyed by merchant id."""
        promos: dict[str, list[PromoBadge]] = {}
        for v in await self.repos.vouchers.find():
            if not _voucher_live(v, now) or not v.restaurant_id:
                continue
            promos.setdefault(v.restaurant_id, []).append(
                PromoBadge(code=v.code, label=v.description or v.code)
            )
        return promos

    async def _card(
        self,
        r: Restaurant,
        location: GeoPoint | None,
        now: datetime,
        promotions: dict[str, list[PromoBadge]] | None = None,
    ) -> RestaurantCard:
        open_now = is_open(r.opening_hours, now)
        if promotions is None:
            promotions = await self._active_promotions(now)
        card = RestaurantCard(
            id=r.id,
            vertical=r.vertical.value,
            city=r.city,
            name=r.name,
            slug=r.slug,
            description=r.description,
            cuisines=r.cuisines,
            tags=r.tags,
            image_url=r.image_url,
            cover_url=r.cover_url,
            area=r.area,
            location=r.location,
            rating=r.rating,
            rating_count=r.rating_count,
            price_level=r.price_level,
            is_open=open_now,
            is_accepting_orders=r.is_accepting_orders,
            is_featured=r.is_featured,
            next_opening_at=None if open_now else next_opening(r.opening_hours, now),
            min_order_kobo=r.min_order_kobo,
            supports_delivery=r.supports_delivery,
            supports_pickup=r.supports_pickup,
            promotions=promotions.get(r.id, []),
            badge=MERCHANT_BADGES.get(r.vertical),
        )
        if location is not None:
            cfg = await self.repos.get_pricing_config()
            distance = haversine_km(r.location, location)
            zone = cfg.zone_for(location)
            card.distance_km = round(distance, 2)
            card.delivers_to_location = r.supports_delivery and distance <= r.delivery_radius_km
            card.eta_minutes = estimate_minutes(r.avg_prep_minutes, distance, cfg)
            if card.delivers_to_location:
                card.delivery_fee_kobo = delivery_fee(distance, cfg, zone.surge_bps if zone else 10_000)
        return card

    async def list_restaurants(
        self,
        *,
        location: GeoPoint | None = None,
        cuisine: str | None = None,
        query: str | None = None,
        open_now: bool = False,
        sort: Literal["recommended", "distance", "rating", "delivery_fee"] = "recommended",
        limit: int = 50,
        vertical: str | None = Vertical.FOOD.value,
        city: str | None = None,
        category: str | None = None,
        pickup_only: bool = False,
    ) -> list[RestaurantCard]:
        """List merchants. `vertical=None` lists every service; `category` is a browse-category id."""
        now = datetime.now(UTC)
        if vertical is not None and vertical not in {v.value for v in Vertical}:
            raise ValidationFailed("Unknown service", details={"vertical": vertical})
        if city is not None and city not in CITIES:
            raise ValidationFailed("We don't operate in that city yet", details={"city": city})
        browse = None
        if category:
            browse = find_category(vertical or Vertical.FOOD.value, category)
            if browse is None:
                raise ValidationFailed("Unknown category", details={"category": category})
        restaurants = await self.repos.restaurants.find(
            where=[("status", "==", RestaurantStatus.ACTIVE.value)]
        )
        promotions = await self._active_promotions(now)
        cards: list[RestaurantCard] = []
        q = (query or "").lower().strip()
        for r in restaurants:
            if vertical is not None and r.vertical.value != vertical:
                continue
            if city is not None and r.city != city:
                continue
            if browse is not None:
                if browse.id == PROMOTIONS:
                    if r.id not in promotions:
                        continue
                elif not category_matches(browse, r.cuisines):
                    continue
            if pickup_only and not r.supports_pickup:
                continue
            if cuisine and cuisine.lower() not in {c.lower() for c in r.cuisines}:
                continue
            if q and q not in r.name.lower() and not any(q in c.lower() for c in r.cuisines + r.tags):
                continue
            card = await self._card(r, location, now, promotions)
            if open_now and not card.is_open:
                continue
            if location is not None and card.distance_km is not None and card.distance_km > 25:
                continue
            cards.append(card)

        def rec_key(c: RestaurantCard) -> tuple[Any, ...]:
            return (
                not (c.is_open and c.is_accepting_orders),
                not c.is_featured,
                -(c.rating * min(1.0, c.rating_count / 50)),
                c.distance_km or 0,
            )

        keys = {
            "recommended": rec_key,
            "distance": lambda c: (c.distance_km is None, c.distance_km or 0),
            "rating": lambda c: (-c.rating, -c.rating_count),
            "delivery_fee": lambda c: (c.delivery_fee_kobo is None, c.delivery_fee_kobo or 0),
        }
        cards.sort(key=keys[sort])
        return cards[: max(1, min(limit, 100))]

    async def get_restaurant(self, restaurant_id: str, *, include_inactive: bool = False) -> Restaurant:
        r = await self.repos.restaurants.get(restaurant_id)
        if r is None or (r.status != RestaurantStatus.ACTIVE and not include_inactive):
            raise NotFound("Restaurant not found")
        return r

    async def get_restaurant_detail(
        self, restaurant_id: str, *, location: GeoPoint | None = None, include_unavailable: bool = True
    ) -> RestaurantDetail:
        r = await self.get_restaurant(restaurant_id)
        categories = await self.repos.get_menu_categories(r.id)
        items = [
            i
            for i in await self.repos.list_items(r.id)
            # Prescription-only medicines are never shown to customers (the partner's own menu lists them).
            if i.is_active and not i.requires_prescription and (include_unavailable or i.is_available)
        ]
        groups = await self.repos.list_option_groups(r.id)
        by_cat: dict[str, list[MenuItem]] = {}
        for item in items:
            by_cat.setdefault(item.category_id, []).append(item)
        sections = [
            MenuSection(category=c, items=by_cat.get(c.id, [])) for c in categories if by_cat.get(c.id)
        ]
        used = {gid for i in items for gid in i.option_group_ids}
        return RestaurantDetail(
            restaurant=await self._card(r, location, datetime.now(UTC)),
            address=r.address,
            location=r.location,
            opening_hours=r.opening_hours,
            avg_prep_minutes=r.avg_prep_minutes,
            sections=sections,
            option_groups={gid: g for gid, g in groups.items() if gid in used},
        )

    async def search(
        self,
        query: str,
        *,
        location: GeoPoint | None = None,
        limit: int = 20,
        vertical: str | None = None,
        city: str | None = None,
    ) -> dict[str, Any]:
        tokens = [t for t in search_keywords(query) if len(t) >= 3][:10] or search_keywords(query)[:10]
        if not tokens:
            raise ValidationFailed("Search query is too short")
        active = {
            r.id: r
            for r in await self.repos.restaurants.find(where=[("status", "==", "active")])
            if (vertical is None or r.vertical.value == vertical) and (city is None or r.city == city)
        }
        items = await self.repos.items.find(
            where=[("search_keywords", "array_contains_any", tokens)], limit=200
        )
        q_tokens = set(_TOKEN.findall(query.lower()))
        scored: list[tuple[float, MenuItem]] = []
        for item in items:
            if item.restaurant_id not in active or not item.is_active or item.requires_prescription:
                continue
            hits = len(q_tokens & set(item.search_keywords))
            name_bonus = 2 if query.lower() in item.name.lower() else 0
            scored.append((hits + name_bonus + min(item.popularity, 500) / 500, item))
        scored.sort(key=lambda s: -s[0])
        restaurants = await self.list_restaurants(
            location=location, query=query, limit=10, vertical=vertical, city=city
        )
        return {
            "items": [
                {
                    "item": item,
                    "restaurant_id": item.restaurant_id,
                    "restaurant_name": active[item.restaurant_id].name,
                    "vertical": active[item.restaurant_id].vertical.value,
                }
                for _, item in scored[:limit]
            ],
            "restaurants": restaurants,
        }

    async def browse_categories(self, vertical: str, *, city: str | None = None) -> list[dict[str, Any]]:
        """Categories for a service page, with how many merchants each one has (empty ones are hidden)."""
        if vertical not in CATEGORIES_BY_VERTICAL:
            raise ValidationFailed("This service has no categories", details={"vertical": vertical})
        merchants = [
            r
            for r in await self.repos.restaurants.find(where=[("status", "==", "active")])
            if r.vertical.value == vertical and (city is None or r.city == city)
        ]
        promotions = await self._active_promotions(datetime.now(UTC))
        out: list[dict[str, Any]] = []
        for cat in CATEGORIES_BY_VERTICAL[vertical]:
            if cat.id == PROMOTIONS:
                count = sum(1 for r in merchants if r.id in promotions)
            else:
                count = sum(1 for r in merchants if category_matches(cat, r.cuisines))
            if count:
                out.append({"id": cat.id, "name": cat.name, "emoji": cat.emoji, "merchants": count})
        return out

    async def services(self, *, city: str | None = None) -> list[dict[str, Any]]:
        """What Yummy Chops offers: the home-screen bubbles and the assistant's knowledge of services."""
        merchants = [
            r
            for r in await self.repos.restaurants.find(where=[("status", "==", "active")])
            if city is None or r.city == city
        ]
        counts = {v: sum(1 for r in merchants if r.vertical == v) for v in MERCHANT_VERTICALS}
        cfg = await self.repos.get_pricing_config()
        parcel_cities = sorted({z.city for z in cfg.zones if z.is_active})
        return [
            *(
                {
                    "id": vertical.value,
                    "name": name,
                    "tagline": tagline,
                    "available": counts[vertical] > 0,
                    "merchants": counts[vertical],
                }
                for vertical, name, tagline in MERCHANT_SERVICES
            ),
            {
                "id": "parcel",
                "name": "Package Delivery",
                "tagline": "Send packages across the city by bike, now or later, and interstate by waybill",
                "available": city is None or city in parcel_cities,
                "options": ["instant", "scheduled", "cash_on_delivery", "interstate"],
                "coming_soon": [],
                "cities": parcel_cities,
            },
        ]

    async def cuisines(self, vertical: str | None = None) -> list[dict[str, Any]]:
        counts: dict[str, int] = {}
        for r in await self.repos.restaurants.find(where=[("status", "==", "active")]):
            if vertical is not None and r.vertical.value != vertical:
                continue
            for c in r.cuisines:
                counts[c] = counts.get(c, 0) + 1
        return [
            {"name": k, "restaurants": v} for k, v in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
        ]

    # ---------------------------------------------------------------- partner management -------
    async def update_settings(
        self, principal: Principal, restaurant_id: str, data: RestaurantSettingsInput
    ) -> Restaurant:
        require_restaurant(principal, restaurant_id, "settings")
        r = await self.get_restaurant(restaurant_id, include_inactive=True)
        updated = r.model_copy(update={k: v for k, v in data.model_dump(exclude_unset=True).items()})
        updated = Restaurant.model_validate(updated.model_dump())
        await self.repos.restaurants.save(updated)
        return updated

    async def set_accepting_orders(
        self, principal: Principal, restaurant_id: str, accepting: bool
    ) -> Restaurant:
        require_restaurant(principal, restaurant_id, "orders")
        restaurant = await self.get_restaurant(restaurant_id, include_inactive=True)
        changes: dict[str, Any] = {"is_accepting_orders": accepting}
        if accepting and restaurant.status == RestaurantStatus.PENDING:
            # A newly approved shop stays hidden from customers until it first opens for orders, and it can only do
            # that with something to sell (ops can also activate it from the Command Centre).
            if not any(item.is_available for item in await self.repos.list_items(restaurant_id)):
                raise ValidationFailed(
                    "Add at least one available item to your menu before opening for orders"
                )
            changes["status"] = RestaurantStatus.ACTIVE.value
        await self.repos.restaurants.update(restaurant_id, changes)
        return await self.get_restaurant(restaurant_id, include_inactive=True)

    async def set_categories(
        self, principal: Principal, restaurant_id: str, names: list[str]
    ) -> list[MenuCategory]:
        require_restaurant(principal, restaurant_id, "menu")
        if not 1 <= len(names) <= 40:
            raise ValidationFailed("Provide between 1 and 40 categories")
        existing = {c.name.lower(): c for c in await self.repos.get_menu_categories(restaurant_id)}
        cats = [
            MenuCategory(
                id=existing[n.lower()].id if n.lower() in existing else uuid.uuid4().hex[:12],
                name=n,
                position=i,
            )
            for i, n in enumerate(names)
        ]
        await self.repos.set_menu_categories(restaurant_id, cats)
        return cats

    async def _validate_item_refs(self, restaurant_id: str, data: ItemInput) -> None:
        cats = {c.id for c in await self.repos.get_menu_categories(restaurant_id)}
        if data.category_id not in cats:
            raise ValidationFailed("Unknown menu category", details={"category_id": data.category_id})
        if data.option_group_ids:
            groups = await self.repos.option_groups.get_many(data.option_group_ids)
            if any(
                groups.get(g) is None or groups[g].restaurant_id != restaurant_id
                for g in data.option_group_ids
            ):
                raise ValidationFailed("Unknown option group")

    async def create_item(self, principal: Principal, restaurant_id: str, data: ItemInput) -> MenuItem:
        require_restaurant(principal, restaurant_id, "menu")
        r = await self.get_restaurant(restaurant_id, include_inactive=True)
        await self._validate_item_refs(restaurant_id, data)
        item = MenuItem(
            id=uuid.uuid4().hex,
            restaurant_id=restaurant_id,
            **data.model_dump(),
            search_keywords=search_keywords(
                data.name, data.description, " ".join(data.tags), " ".join(r.cuisines)
            ),
        )
        await self.repos.items.create(item)
        return item

    async def _owned_item(self, restaurant_id: str, item_id: str) -> MenuItem:
        item = await self.repos.items.get(item_id)
        if item is None or item.restaurant_id != restaurant_id or not item.is_active:
            raise NotFound("Menu item not found")
        return item

    async def update_item(
        self, principal: Principal, restaurant_id: str, item_id: str, data: ItemInput
    ) -> MenuItem:
        require_restaurant(principal, restaurant_id, "menu")
        r = await self.get_restaurant(restaurant_id, include_inactive=True)
        current = await self._owned_item(restaurant_id, item_id)
        await self._validate_item_refs(restaurant_id, data)
        item = current.model_copy(
            update={
                **data.model_dump(),
                "search_keywords": search_keywords(
                    data.name, data.description, " ".join(data.tags), " ".join(r.cuisines)
                ),
            }
        )
        await self.repos.items.save(MenuItem.model_validate(item.model_dump()))
        return item

    async def set_item_availability(
        self, principal: Principal, restaurant_id: str, item_id: str, available: bool
    ) -> MenuItem:
        if not (
            principal.can_on_restaurant(restaurant_id, "menu")
            or principal.can_on_restaurant(restaurant_id, "menu_availability")
        ):
            require_restaurant(principal, restaurant_id, "menu")
        item = await self._owned_item(restaurant_id, item_id)
        await self.repos.items.update(item_id, {"is_available": available})
        return item.model_copy(update={"is_available": available})

    async def delete_item(self, principal: Principal, restaurant_id: str, item_id: str) -> None:
        require_restaurant(principal, restaurant_id, "menu")
        await self._owned_item(restaurant_id, item_id)
        await self.repos.items.update(item_id, {"is_active": False, "is_available": False})

    async def upsert_option_group(
        self, principal: Principal, restaurant_id: str, data: OptionGroupInput, group_id: str | None = None
    ) -> OptionGroup:
        require_restaurant(principal, restaurant_id, "menu")
        if group_id:
            existing = await self.repos.option_groups.get(group_id)
            if existing is None or existing.restaurant_id != restaurant_id:
                raise NotFound("Option group not found")
        group = OptionGroup(id=group_id or uuid.uuid4().hex, restaurant_id=restaurant_id, **data.model_dump())
        await self.repos.option_groups.save(group)
        return group

    async def menu_for_partner(self, principal: Principal, restaurant_id: str) -> dict[str, Any]:
        require_restaurant(principal, restaurant_id, "orders")
        r = await self.get_restaurant(restaurant_id, include_inactive=True)
        return {
            "restaurant": r,
            "categories": await self.repos.get_menu_categories(restaurant_id),
            "items": [i for i in await self.repos.list_items(restaurant_id) if i.is_active],
            "option_groups": list((await self.repos.list_option_groups(restaurant_id)).values()),
        }


def restaurant_geohash(r: Restaurant) -> Restaurant:
    return r.model_copy(update={"geohash": geohash_encode(r.location.lat, r.location.lng, 9)})


def _voucher_live(v: Voucher, now: datetime) -> bool:
    if not v.is_active:
        return False
    if v.starts_at and now < v.starts_at:
        return False
    if v.ends_at and now >= v.ends_at:
        return False
    return v.usage_limit is None or v.used_count < v.usage_limit
