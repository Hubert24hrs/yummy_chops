"""Customer profiles & addresses, onboarding applications, reviews, support tickets and the meal planner."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any, Literal

from pydantic import BaseModel, Field, model_validator

from ..domain.geo import GeoPoint, geohash_encode
from ..domain.hours import OpeningHours
from ..domain.meal_planner import PlannerRequest, PlannerResult, plan_meals
from ..domain.models import (
    Application,
    CustomerProfile,
    DeliveryAddress,
    MenuCategory,
    Restaurant,
    RestaurantStatus,
    Review,
    RiderProfile,
    RiderStatus,
    SavedAddress,
    SupportTicket,
    TicketCategory,
    VehicleType,
    Vertical,
)
from ..domain.order_state import ActorType, OrderStatus
from ..errors import Conflict, InvalidTransition, NotFound, ValidationFailed
from ..ledger.audit import AuditLog
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, Role, require
from .catalog import slugify
from .infra import IdentityAdmin, Notifier
from .orders import OrderService, refund_meta
from .rider_kyc import RiderKycService


def utcnow() -> datetime:
    return datetime.now(UTC)


# ================================================================================================
# Profiles
# ================================================================================================


class ProfileUpdate(BaseModel):
    display_name: str | None = Field(default=None, max_length=80)
    dietary: list[str] | None = Field(default=None, max_length=10)
    allergens: list[str] | None = Field(default=None, max_length=15)
    favourite_cuisines: list[str] | None = Field(default=None, max_length=15)
    personalisation_consent: bool | None = None
    marketing_consent: bool | None = None


class ProfileService:
    def __init__(self, repos: Repositories) -> None:
        self.repos = repos

    async def get(self, principal: Principal) -> CustomerProfile:
        profile = await self.repos.customers.get(principal.uid)
        if profile is None:
            profile = CustomerProfile(
                uid=principal.uid,
                display_name=principal.name,
                phone=principal.phone,
                email=principal.email,
                created_at=utcnow(),
                updated_at=utcnow(),
            )
            await self.repos.customers.save(profile)
        return profile

    async def update(self, principal: Principal, data: ProfileUpdate) -> CustomerProfile:
        profile = await self.get(principal)
        changes = {
            k: ([s.strip().lower() for s in v] if isinstance(v, list) else v)
            for k, v in data.model_dump(exclude_unset=True).items()
        }
        updated = profile.model_copy(update={**changes, "updated_at": utcnow()})
        await self.repos.customers.save(CustomerProfile.model_validate(updated.model_dump()))
        return updated

    async def toggle_favourite(
        self, principal: Principal, restaurant_id: str, favourite: bool
    ) -> CustomerProfile:
        profile = await self.get(principal)
        favs = [r for r in profile.favourite_restaurant_ids if r != restaurant_id]
        if favourite:
            favs.insert(0, restaurant_id)
        await self.repos.customers.update(principal.uid, {"favourite_restaurant_ids": favs[:100]})
        return profile.model_copy(update={"favourite_restaurant_ids": favs[:100]})

    async def addresses(self, principal: Principal) -> list[SavedAddress]:
        return await self.repos.list_addresses(principal.uid)

    async def save_address(
        self, principal: Principal, address: DeliveryAddress, address_id: str | None = None
    ) -> SavedAddress:
        existing = await self.repos.list_addresses(principal.uid)
        if address_id is None and len(existing) >= 20:
            raise ValidationFailed("You can save up to 20 addresses")
        saved = SavedAddress(id=address_id or uuid.uuid4().hex[:16], **address.model_dump())
        await self.repos.save_address(principal.uid, saved)
        return saved

    async def delete_address(self, principal: Principal, address_id: str) -> None:
        await self.repos.delete_address(principal.uid, address_id)

    async def register_device(self, principal: Principal, token: str, platform: str) -> None:
        user = await self.repos.get_user(principal.uid) or {}
        tokens = [t for t in user.get("device_tokens", []) if t != token]
        await self.repos.upsert_user(
            principal.uid, {"device_tokens": [token, *tokens][:10], "last_platform": platform}
        )

    async def export(self, principal: Principal, orders: OrderService) -> dict[str, Any]:
        """NDPA data-subject access: everything we hold about the customer in the app database."""
        return {
            "profile": await self.get(principal),
            "addresses": await self.addresses(principal),
            "orders": await orders.list_for_customer(principal.uid, limit=100),
            "tickets": await self.repos.tickets.find(where=[("opened_by", "==", principal.uid)], limit=100),
            "exported_at": utcnow(),
        }


# ================================================================================================
# Applications (restaurant / rider onboarding)
# ================================================================================================


#: The first shelf a new shop gets, by kind of business; the owner renames or adds more in the partner dashboard.
FIRST_CATEGORY: dict[str, tuple[str, str]] = {
    "food": ("mains", "Mains"),
    "pharmacy": ("products", "Products"),
    "beauty": ("products", "Products"),
    "grocery": ("products", "Products"),
    "market": ("foodstuff", "Foodstuff"),
}


class RestaurantApplicationInput(BaseModel):
    """A business asks to sell on Yummy Chops: a restaurant or a shop of any kind (ADR-0025)."""

    business_name: str = Field(min_length=2, max_length=80)
    #: The kind of business, which decides the service the shop appears under: a restaurant (Order Food), a pharmacy,
    #: a beauty & skin care shop, a supermarket or store (Shop & Groceries) or a market shopper (Buy Foodstuff).
    vertical: Literal["food", "pharmacy", "beauty", "grocery", "market"] = "food"
    #: Pharmacies only: the Pharmacists Council of Nigeria premises licence, checked before the shop goes live.
    pcn_licence_number: str | None = Field(default=None, min_length=4, max_length=30)
    cac_number: str = Field(min_length=4, max_length=20, description="Corporate Affairs Commission number")
    contact_name: str = Field(min_length=2, max_length=80)
    contact_phone: str = Field(min_length=7, max_length=20)
    address: str = Field(min_length=5, max_length=200)
    area: str = Field(min_length=2, max_length=60)
    location: GeoPoint
    cuisines: list[str] = Field(min_length=1, max_length=8)
    bank_name: str = Field(min_length=2, max_length=60)
    bank_account_name: str = Field(min_length=2, max_length=80)
    bank_account_last4: str = Field(
        pattern=r"^\d{4}$", description="Full account details are collected by the payment provider"
    )
    document_paths: list[str] = Field(default_factory=list, max_length=10)

    @model_validator(mode="after")
    def _pharmacies_give_their_licence(self) -> RestaurantApplicationInput:
        if self.vertical == "pharmacy" and not self.pcn_licence_number:
            raise ValueError("A pharmacy needs its PCN premises licence number")
        return self


class RiderApplicationInput(BaseModel):
    """Rider sign-up (docs/adr/0027-rider-kyc.md): the KYC follows in the rider app."""

    full_name: str = Field(min_length=2, max_length=80)
    phone: str = Field(min_length=7, max_length=20)  # the rider's WhatsApp number
    email: str | None = Field(default=None, max_length=120)
    residential_address: str | None = Field(default=None, max_length=200)
    vehicle: VehicleType = VehicleType.MOTORCYCLE
    plate_number: str | None = Field(default=None, max_length=20)
    licence_number: str | None = Field(default=None, max_length=30)
    city: str = "Lagos"
    document_paths: list[str] = Field(default_factory=list, max_length=10)


class ApplicationService:
    def __init__(
        self,
        repos: Repositories,
        identity: IdentityAdmin,
        audit: AuditLog,
        notifier: Notifier,
        kyc: RiderKycService | None = None,
    ) -> None:
        self.repos = repos
        self.identity = identity
        self.audit = audit
        self.notifier = notifier
        self.kyc = kyc

    async def submit(
        self, principal: Principal, kind: Literal["restaurant", "rider"], data: BaseModel
    ) -> Application:
        open_apps = await self.repos.applications.find(
            where=[("applicant_uid", "==", principal.uid), ("type", "==", kind)], limit=10
        )
        if any(a.status in ("submitted", "in_review") for a in open_apps):
            raise Conflict("You already have an application under review")
        for path in getattr(data, "document_paths", []):
            if not path.startswith(f"applications/{principal.uid}/"):
                raise ValidationFailed("Documents must be uploaded to your own application folder")
        app = Application(
            id=uuid.uuid4().hex,
            type=kind,
            applicant_uid=principal.uid,
            data=to_doc(data),
            document_paths=getattr(data, "document_paths", []),
            submitted_at=utcnow(),
        )
        await self.repos.applications.create(app)
        if kind == "rider" and self.kyc is not None and isinstance(data, RiderApplicationInput):
            # The new rider gets the rider app straight away, to do their KYC there (they cannot go online yet).
            await self.kyc.start(
                principal.uid,
                full_name=data.full_name,
                whatsapp_phone=data.phone,
                email=(data.email or principal.email or "").strip(),
                residential_address=(data.residential_address or "").strip(),
                vehicle=data.vehicle,
                plate_number=data.plate_number,
            )
        return app

    async def mine(self, principal: Principal) -> list[Application]:
        return await self.repos.applications.find(where=[("applicant_uid", "==", principal.uid)], limit=20)

    async def list(self, principal: Principal, status: str | None, kind: str | None) -> list[Application]:
        require(principal, Permission.APPLICATIONS_REVIEW)
        where: list[Any] = []
        if status:
            where.append(("status", "==", status))
        if kind:
            where.append(("type", "==", kind))
        apps = await self.repos.applications.find(where=where, limit=200)
        return sorted(apps, key=lambda a: a.submitted_at, reverse=True)

    async def decide(
        self, principal: Principal, application_id: str, *, approve: bool, reason: str | None
    ) -> Application:
        require(principal, Permission.APPLICATIONS_REVIEW)
        app = await self.repos.applications.get(application_id)
        if app is None:
            raise NotFound("Application not found")
        if app.status not in ("submitted", "in_review"):
            raise InvalidTransition(f"Application already {app.status}")
        entity_id: str | None = None
        if app.type == "rider" and self.kyc is not None:
            # Riders are verified on their KYC: approving needs it submitted; turning down stops them going online.
            if approve:
                entity_id = await self.kyc.verify(app.applicant_uid, reviewer_uid=principal.uid, note=reason)
            else:
                await self.kyc.reject(app.applicant_uid, reviewer_uid=principal.uid, note=reason)
        elif approve:
            entity_id = await (
                self._approve_restaurant(app) if app.type == "restaurant" else self._approve_rider(app)
            )
        decided = app.model_copy(
            update={
                "status": "approved" if approve else "rejected",
                "decided_at": utcnow(),
                "decided_by": principal.uid,
                "decision_reason": reason,
                "created_entity_id": entity_id,
            }
        )
        await self.repos.applications.save(decided)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action=f"application.{'approved' if approve else 'rejected'}",
            resource_type="application",
            resource_id=app.id,
            details={"type": app.type, "entity_id": entity_id, "reason": reason},
        )
        await self.notifier.notify_user(
            app.applicant_uid,
            "Application update",
            f"Your {app.type} application was {'approved' if approve else 'not approved'}",
            {"application_id": app.id},
        )
        return decided

    async def _approve_restaurant(self, app: Application) -> str:
        d = app.data
        rid = uuid.uuid4().hex[:20]
        location = GeoPoint.model_validate(d["location"])
        vertical = Vertical(d.get("vertical", "food"))
        restaurant = Restaurant(
            id=rid,
            vertical=vertical,
            name=d["business_name"],
            slug=f"{slugify(d['business_name'])}-{rid[:4]}",
            cuisines=d.get("cuisines", []),
            location=location,
            geohash=geohash_encode(location.lat, location.lng, 9),
            address=d["address"],
            area=d.get("area", ""),
            status=RestaurantStatus.PENDING,  # hidden until it has a menu and opens for orders
            is_accepting_orders=False,
            opening_hours=OpeningHours.every_day("09:00", "21:00"),
            owner_uid=app.applicant_uid,
            phone=d.get("contact_phone"),
            created_at=utcnow(),
        )
        await self.repos.restaurants.create(restaurant)
        shelf_id, shelf_name = FIRST_CATEGORY.get(vertical.value, FIRST_CATEGORY["food"])
        await self.repos.set_menu_categories(rid, [MenuCategory(id=shelf_id, name=shelf_name, position=0)])
        claims = await self.identity.get_claims(app.applicant_uid)
        roles = set(claims.get("roles", [])) | {Role.RESTAURANT_OWNER.value}
        restaurant_roles = {**claims.get("restaurant_roles", {}), rid: "owner"}
        await self.identity.set_claims(app.applicant_uid, sorted(roles), restaurant_roles)
        return rid

    async def _approve_rider(self, app: Application) -> str:
        d = app.data
        profile = RiderProfile(
            uid=app.applicant_uid,
            name=d["full_name"],
            phone=d.get("phone"),
            vehicle=VehicleType(d["vehicle"]),
            plate_number=d.get("plate_number"),
            status=RiderStatus.ACTIVE,
            created_at=utcnow(),
        )
        await self.repos.riders.save(profile)
        claims = await self.identity.get_claims(app.applicant_uid)
        roles = set(claims.get("roles", [])) | {Role.RIDER.value}
        await self.identity.set_claims(app.applicant_uid, sorted(roles), claims.get("restaurant_roles", {}))
        return app.applicant_uid


# ================================================================================================
# Reviews
# ================================================================================================


class ReviewInput(BaseModel):
    food_rating: int = Field(ge=1, le=5)
    delivery_rating: int | None = Field(default=None, ge=1, le=5)
    comment: str | None = Field(default=None, max_length=1000)


class ReviewService:
    def __init__(self, repos: Repositories, orders: OrderService) -> None:
        self.repos = repos
        self.orders = orders

    async def create(self, principal: Principal, order_id: str, data: ReviewInput) -> Review:
        order = await self.orders.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        if order.status not in (OrderStatus.COMPLETED, OrderStatus.PARTIALLY_REFUNDED):
            raise InvalidTransition("You can review an order once it is completed")
        review = Review(
            id=order_id,
            order_id=order_id,
            restaurant_id=order.restaurant_id,
            customer_id=principal.uid,
            rider_id=order.rider_id,
            created_at=utcnow(),
            **data.model_dump(),
        )

        async def fn(tx: Transaction) -> None:
            if await tx.get(f"reviews/{order_id}") is not None:
                raise Conflict("You have already reviewed this order")
            rdoc = await tx.get(f"restaurant_profiles/{order.restaurant_id}")
            rider_doc = await tx.get(f"rider_profiles/{order.rider_id}") if order.rider_id else None
            tx.create(f"reviews/{order_id}", to_doc(review))
            tx.update(f"orders/{order_id}", {"reviewed": True})
            if rdoc is not None:
                count = int(rdoc.get("rating_count", 0))
                avg = float(rdoc.get("rating", 0.0))
                tx.update(
                    f"restaurant_profiles/{order.restaurant_id}",
                    {
                        "rating": round((avg * count + data.food_rating) / (count + 1), 2),
                        "rating_count": count + 1,
                    },
                )
            if rider_doc is not None and data.delivery_rating:
                count = int(rider_doc.get("rating_count", 0))
                avg = float(rider_doc.get("rating", 5.0))
                tx.update(
                    f"rider_profiles/{order.rider_id}",
                    {
                        "rating": round((avg * count + data.delivery_rating) / (count + 1), 2),
                        "rating_count": count + 1,
                    },
                )

        await self.repos.store.run_transaction(fn)
        return review

    async def for_restaurant(self, restaurant_id: str, limit: int = 20) -> list[Review]:
        reviews = await self.repos.reviews.find(
            where=[("restaurant_id", "==", restaurant_id)],
            order_by=[("created_at", "desc")],
            limit=min(limit, 50),
        )
        return [r.model_copy(update={"customer_id": "hidden"}) for r in reviews]


# ================================================================================================
# Support
# ================================================================================================


class TicketInput(BaseModel):
    order_id: str | None = None
    category: TicketCategory
    description: str = Field(min_length=5, max_length=2000)
    missing_item_ids: list[str] = Field(default_factory=list, max_length=20)
    channel: Literal["app", "web", "ai_agent", "whatsapp"] = "app"


class TicketResolution(BaseModel):
    status: Literal["in_progress", "escalated", "resolved", "closed"]
    resolution: str | None = Field(default=None, max_length=2000)
    refund_amount_kobo: int | None = Field(default=None, gt=0)
    refund_liability: Literal["restaurant", "platform"] = "platform"


URGENT = {"rider", "payment"}


class SupportService:
    def __init__(self, repos: Repositories, orders: OrderService, audit: AuditLog) -> None:
        self.repos = repos
        self.orders = orders
        self.audit = audit

    async def open(self, principal: Principal, data: TicketInput) -> SupportTicket:
        if data.order_id:
            order = await self.orders.get_for(principal, data.order_id)
            item_ids = {ln.item_id for ln in order.lines}
            if any(i not in item_ids for i in data.missing_item_ids):
                raise ValidationFailed("Missing items must be part of the order")
        elif data.missing_item_ids:
            raise ValidationFailed("Missing items require an order")
        now = utcnow()
        ticket = SupportTicket(
            id=uuid.uuid4().hex,
            opened_by=principal.uid,
            order_id=data.order_id,
            category=data.category,
            description=data.description,
            missing_item_ids=data.missing_item_ids,
            channel=data.channel,
            priority="high" if data.category in URGENT else "normal",
            created_at=now,
            updated_at=now,
        )
        await self.repos.tickets.create(ticket)
        return ticket

    async def emergency(
        self, principal: Principal, description: str, location: GeoPoint | None
    ) -> SupportTicket:
        now = utcnow()
        ticket = SupportTicket(
            id=uuid.uuid4().hex,
            opened_by=principal.uid,
            category="rider",
            description=f"[EMERGENCY] {description}"
            + (f" @ {location.lat:.5f},{location.lng:.5f}" if location else ""),
            priority="urgent",
            channel="app",
            status="escalated",
            created_at=now,
            updated_at=now,
        )
        await self.repos.tickets.create(ticket)
        return ticket

    async def mine(self, principal: Principal) -> list[SupportTicket]:
        tickets = await self.repos.tickets.find(where=[("opened_by", "==", principal.uid)], limit=50)
        return sorted(tickets, key=lambda t: t.created_at, reverse=True)

    async def list(self, principal: Principal, status: str | None = None) -> list[SupportTicket]:
        require(principal, Permission.SUPPORT_MANAGE)
        where = [("status", "==", status)] if status else []
        tickets = await self.repos.tickets.find(where=where, limit=300)
        order = {"urgent": 0, "high": 1, "normal": 2, "low": 3}
        return sorted(tickets, key=lambda t: (order[t.priority], t.created_at))

    async def resolve(self, principal: Principal, ticket_id: str, data: TicketResolution) -> SupportTicket:
        require(principal, Permission.SUPPORT_MANAGE)
        ticket = await self.repos.tickets.get(ticket_id)
        if ticket is None:
            raise NotFound("Ticket not found")
        changes: dict[str, Any] = {
            "status": data.status,
            "resolution": data.resolution,
            "updated_at": utcnow(),
            "assigned_to": principal.uid,
        }
        if data.refund_amount_kobo:
            if not ticket.order_id:
                raise ValidationFailed("Refunds need an order")
            require(principal, Permission.REFUNDS_REQUEST)
            order = await self.orders.get(ticket.order_id)
            target = OrderStatus.REFUND_PENDING
            await self.orders.transition(
                order.id,
                target,
                actor_type=ActorType.STAFF,
                actor_id=principal.uid,
                reason=f"Support ticket {ticket.id}: {data.resolution or ticket.category}",
                metadata={
                    **refund_meta(
                        data.refund_amount_kobo,
                        data.refund_liability,
                        "after_completion" if order.completed_at else "before_completion",
                        auto=False,
                    ),
                    "ticket_id": ticket.id,
                },
            )
        updated = ticket.model_copy(update=changes)
        await self.repos.tickets.save(updated)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="ticket.updated",
            resource_type="support_ticket",
            resource_id=ticket.id,
            details={"status": data.status, "refund_amount_kobo": data.refund_amount_kobo},
        )
        return updated


# ================================================================================================
# Meal planner (AI "₦10,000 for two before 8pm")
# ================================================================================================


class MealPlanInput(BaseModel):
    budget_kobo: int = Field(gt=0, le=100_000_000)
    party_size: int = Field(default=1, ge=1, le=20)
    location: GeoPoint
    deliver_by: datetime | None = None
    dietary: list[str] = Field(default_factory=list, max_length=5)
    exclude_allergens: list[str] = Field(default_factory=list, max_length=10)
    cuisines: list[str] = Field(default_factory=list, max_length=5)
    include_drinks: bool = True
    max_options: int = Field(default=3, ge=1, le=5)


class MealPlanService:
    def __init__(self, repos: Repositories) -> None:
        self.repos = repos

    async def plan(self, principal: Principal, data: MealPlanInput) -> PlannerResult:
        profile = await self.repos.customers.get(principal.uid)
        allergens = set(a.lower() for a in data.exclude_allergens)
        if profile and profile.personalisation_consent:
            allergens |= {a.lower() for a in profile.allergens}  # never recommend known allergens
        restaurants = await self.repos.restaurants.find(
            where=[("status", "==", RestaurantStatus.ACTIVE.value)]
        )
        catalog = []
        for r in restaurants:
            items = await self.repos.list_items(r.id)
            groups = await self.repos.list_option_groups(r.id)
            catalog.append((r, items, groups))
        deliver_by = data.deliver_by
        if deliver_by is not None and deliver_by.tzinfo is None:
            deliver_by = deliver_by.replace(tzinfo=UTC)
        req = PlannerRequest(
            budget_kobo=data.budget_kobo,
            party_size=data.party_size,
            location=data.location,
            now=utcnow(),
            deliver_by=deliver_by,
            dietary={d.lower() for d in data.dietary},
            exclude_allergens=allergens,
            cuisines={c.lower() for c in data.cuisines},
            include_drinks=data.include_drinks,
            max_options=data.max_options,
        )
        return plan_meals(req, catalog, await self.repos.get_pricing_config())
