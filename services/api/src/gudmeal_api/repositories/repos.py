"""Typed repositories over the DocumentStore port. Collection names follow docs/architecture/data-model.md."""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from datetime import UTC, datetime
from typing import Any, Generic, TypeVar

from pydantic import BaseModel

from ..domain.geo import GeoPoint
from ..domain.growth import GroupOrder, GrowthConfig, Membership, RewardsAccount
from ..domain.logistics import WaybillNetwork, default_network
from ..domain.models import (
    Application,
    Business,
    CustomerProfile,
    DeliveryAssignment,
    MenuCategory,
    MenuItem,
    Notification,
    OptionGroup,
    Order,
    OrderEvent,
    ParcelQuote,
    Quote,
    Restaurant,
    Review,
    RiderKyc,
    RiderProfile,
    SavedAddress,
    SupportTicket,
    Voucher,
    WaybillQuote,
)
from ..domain.pricing import PricingConfig
from ..errors import NotFound, ValidationFailed
from .store import DocumentStore, Filter, OrderBy, to_doc

M = TypeVar("M", bound=BaseModel)
MAX_ID_BYTES = 1500  # Firestore's limit for a document id


def valid_doc_id(doc_id: Any) -> bool:
    """Whether `doc_id` can name a document. Ids also arrive in request bodies and query strings: one with a "/"
    would point at another document's path, and Firestore refuses "", ".", ".." and "__x__". No document has
    such an id, so callers treat it as not found instead of sending it to the store."""
    if not isinstance(doc_id, str) or not doc_id or "/" in doc_id or doc_id in (".", ".."):
        return False
    if doc_id.startswith("__") and doc_id.endswith("__"):
        return False
    try:
        return len(doc_id.encode()) <= MAX_ID_BYTES
    except UnicodeEncodeError:  # half of a surrogate pair, from a JSON escape
        return False


class TypedCollection(Generic[M]):
    def __init__(self, store: DocumentStore, collection: str, model: type[M], key: str = "id") -> None:
        self.store = store
        self.collection = collection
        self.model = model
        self.key = key

    def path(self, doc_id: str) -> str:
        if not valid_doc_id(doc_id):
            raise NotFound("Document not found")
        return f"{self.collection}/{doc_id}"

    def parse(self, data: dict[str, Any]) -> M:
        return self.model.model_validate(data)

    def doc_id(self, obj: M) -> str:
        return str(getattr(obj, self.key))

    async def get(self, doc_id: str) -> M | None:
        if not valid_doc_id(doc_id):
            return None
        data = await self.store.get(self.path(doc_id))
        return self.parse(data) if data is not None else None

    async def get_many(self, ids: Sequence[str]) -> dict[str, M]:
        unique = [i for i in dict.fromkeys(ids) if valid_doc_id(i)]
        docs = await self.store.get_many([self.path(i) for i in unique])
        return {i: self.parse(d) for i, d in zip(unique, docs, strict=True) if d is not None}

    async def save(self, obj: M) -> None:
        await self.store.set(self.path(self.doc_id(obj)), to_doc(obj))

    async def create(self, obj: M) -> None:
        await self.store.create(self.path(self.doc_id(obj)), to_doc(obj))

    async def update(self, doc_id: str, fields: dict[str, Any]) -> None:
        await self.store.update(self.path(doc_id), to_doc(fields))

    async def delete(self, doc_id: str) -> None:
        if valid_doc_id(doc_id):  # nothing to delete otherwise
            await self.store.delete(self.path(doc_id))

    async def find(
        self,
        where: Iterable[Filter] = (),
        order_by: Iterable[OrderBy] = (),
        limit: int | None = None,
    ) -> list[M]:
        docs = await self.store.query(self.collection, where=where, order_by=order_by, limit=limit)
        return [self.parse(d) for d in docs]


class Repositories:
    """Aggregate of typed collections plus a few non-uniform documents."""

    def __init__(self, store: DocumentStore) -> None:
        self.store = store
        self.restaurants = TypedCollection(store, "restaurant_profiles", Restaurant)
        self.items = TypedCollection(store, "food_items", MenuItem)
        self.option_groups = TypedCollection(store, "food_customisations", OptionGroup)
        self.quotes = TypedCollection(store, "quotes", Quote)
        self.parcel_quotes = TypedCollection(store, "parcel_quotes", ParcelQuote)
        self.waybill_quotes = TypedCollection(store, "waybill_quotes", WaybillQuote)
        self.orders = TypedCollection(store, "orders", Order)
        self.order_events = TypedCollection(store, "order_events", OrderEvent)
        self.riders = TypedCollection(store, "rider_profiles", RiderProfile, key="uid")
        self.assignments = TypedCollection(store, "delivery_assignments", DeliveryAssignment)
        self.customers = TypedCollection(store, "customer_profiles", CustomerProfile, key="uid")
        self.vouchers = TypedCollection(store, "vouchers", Voucher, key="code")
        self.reviews = TypedCollection(store, "reviews", Review)
        self.tickets = TypedCollection(store, "support_tickets", SupportTicket)
        self.applications = TypedCollection(store, "applications", Application)
        self.rider_kyc = TypedCollection(store, "rider_kyc", RiderKyc, key="uid")
        self.businesses = TypedCollection(store, "businesses", Business)
        self.notifications = TypedCollection(store, "notifications", Notification)
        # Growth (ADR-0016): Plus memberships, Yummy points and referrals, group orders.
        self.memberships = TypedCollection(store, "memberships", Membership, key="uid")
        self.rewards = TypedCollection(store, "loyalty_accounts", RewardsAccount, key="uid")
        self.group_orders = TypedCollection(store, "group_orders", GroupOrder)

    # --- menus ------------------------------------------------------------------------------
    async def get_menu_categories(self, restaurant_id: str) -> list[MenuCategory]:
        doc = await self.store.get(f"restaurant_menus/{restaurant_id}")
        cats = [MenuCategory.model_validate(c) for c in (doc or {}).get("categories", [])]
        return sorted(cats, key=lambda c: (c.position, c.name))

    async def set_menu_categories(self, restaurant_id: str, categories: list[MenuCategory]) -> None:
        await self.store.set(
            f"restaurant_menus/{restaurant_id}",
            {"restaurant_id": restaurant_id, "categories": to_doc(categories)},
        )

    async def list_items(self, restaurant_id: str) -> list[MenuItem]:
        items = await self.items.find(where=[("restaurant_id", "==", restaurant_id)])
        return sorted(items, key=lambda i: (i.position, i.name))

    async def list_option_groups(self, restaurant_id: str) -> dict[str, OptionGroup]:
        groups = await self.option_groups.find(where=[("restaurant_id", "==", restaurant_id)])
        return {g.id: g for g in groups}

    # --- customer addresses -------------------------------------------------------------------
    def _addresses(self, uid: str) -> TypedCollection[SavedAddress]:
        return TypedCollection(self.store, f"customer_profiles/{uid}/addresses", SavedAddress)

    async def list_addresses(self, uid: str) -> list[SavedAddress]:
        return await self._addresses(uid).find(limit=20)

    async def save_address(self, uid: str, address: SavedAddress) -> None:
        await self._addresses(uid).save(address)

    async def delete_address(self, uid: str, address_id: str) -> None:
        await self._addresses(uid).delete(address_id)

    # --- order private codes -----------------------------------------------------------------
    def codes_path(self, order_id: str) -> str:
        return f"orders/{order_id}/customer_private/codes"

    # --- users & devices -----------------------------------------------------------------------
    async def get_user(self, uid: str) -> dict[str, Any] | None:
        return await self.store.get(f"users/{uid}")

    async def upsert_user(self, uid: str, data: dict[str, Any]) -> None:
        await self.store.set(f"users/{uid}", {"uid": uid, **data}, merge=True)

    # --- tracking ------------------------------------------------------------------------------
    async def set_tracking(self, order_id: str, data: dict[str, Any]) -> None:
        await self.store.set(f"delivery_tracking/{order_id}", {"order_id": order_id, **data})

    async def get_tracking(self, order_id: str) -> dict[str, Any] | None:
        return await self.store.get(f"delivery_tracking/{order_id}")

    # --- kitchen pins checked by Yummy Chops (services/locations.py) ---------------------------
    async def get_verified_pin(self, restaurant_id: str) -> GeoPoint | None:
        """The pin staff last set for this shop (or the pin it had before its first own move): partners' own
        moves are measured from it, so small moves cannot add up to a big one."""
        doc = await self.store.get(f"restaurant_verified_pins/{restaurant_id}")
        return GeoPoint.model_validate(doc["location"]) if doc else None

    async def set_verified_pin(self, restaurant_id: str, location: GeoPoint, verified_by: str | None) -> None:
        await self.store.set(
            f"restaurant_verified_pins/{restaurant_id}",
            {
                "restaurant_id": restaurant_id,
                "location": to_doc(location),
                "verified_by": verified_by,  # the staff member; None for the pin a shop started from
                "at": datetime.now(UTC),
            },
        )

    # --- platform configuration ----------------------------------------------------------------
    async def get_pricing_config(self) -> PricingConfig:
        doc = await self.store.get("platform_configuration/pricing")
        return PricingConfig.model_validate(doc) if doc else PricingConfig()

    async def save_pricing_config(self, cfg: PricingConfig) -> None:
        await self.store.set("platform_configuration/pricing", to_doc(cfg))

    async def get_growth_config(self) -> GrowthConfig:
        doc = await self.store.get("platform_configuration/growth")
        return GrowthConfig.model_validate(doc) if doc else GrowthConfig()

    async def save_growth_config(self, cfg: GrowthConfig) -> None:
        await self.store.set("platform_configuration/growth", to_doc(cfg))

    async def get_waybill_network(self) -> WaybillNetwork:
        doc = await self.store.get("platform_configuration/logistics")
        return WaybillNetwork.model_validate(doc) if doc else default_network()

    async def save_waybill_network(self, network: WaybillNetwork) -> None:
        await self.store.set("platform_configuration/logistics", to_doc(network))

    def waybill_code_path(self, tracking_code: str) -> str:
        """Public tracking number → order id (looked up without exposing the order id)."""
        return f"waybill_tracking/{tracking_code}"

    async def list_feature_flags(self) -> dict[str, Any]:
        docs = await self.store.query("feature_flags")
        return {d["key"]: d for d in docs}

    async def set_feature_flag(self, key: str, enabled: bool, description: str, updated_by: str) -> None:
        if not valid_doc_id(key):
            raise ValidationFailed('A flag name cannot be empty, "." or "..", or contain "/"')
        await self.store.set(
            f"feature_flags/{key}",
            {"key": key, "enabled": enabled, "description": description, "updated_by": updated_by},
        )
