"""Domain models shared by services, repositories and the HTTP layer.

Conventions: money fields are integer kobo and end in `_kobo`; datetimes are timezone-aware UTC.
"""

from __future__ import annotations

from datetime import date, datetime
from enum import StrEnum
from typing import Annotated, Any, Literal

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, model_validator

from .geo import GeoPoint
from .hours import OpeningHours
from .order_state import ActorType, OrderStatus


class Model(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)


def no_markup(value: str | None) -> str | None:
    """Refuse the characters < and >, so a name or an address can never carry markup onto a page or a map."""
    if value is not None and ("<" in value or ">" in value):
        raise ValueError("Please remove the characters < and >")
    return value


#: What people type for a shop's or branch's name and address. Use these on request models only: stored documents
#: are read with the plain models below, so a document saved before this rule still loads.
PlainText = Annotated[str, AfterValidator(no_markup)]
OptionalPlainText = Annotated[str | None, AfterValidator(no_markup)]


# ----------------------------------------------------------------------------------------------
# Catalog
# ----------------------------------------------------------------------------------------------


class RestaurantStatus(StrEnum):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"


class Vertical(StrEnum):
    """Yummy Chops services. Food, pharmacy items, beauty & skin care products, groceries and market foodstuff
    are sold by merchants; parcels are courier jobs."""

    FOOD = "food"
    BEAUTY = "beauty"
    GROCERY = "grocery"  # supermarkets and convenience stores
    PHARMACY = "pharmacy"  # over-the-counter medicines, health and personal care (no prescription medicines)
    MARKET = "market"  # foodstuff from an open market, bought by a shopper
    PARCEL = "parcel"
    WAYBILL = "waybill"  # interstate: rider/hub first mile, partner line haul, rider/hub last mile


MERCHANT_VERTICALS = (
    Vertical.FOOD,
    Vertical.BEAUTY,
    Vertical.GROCERY,
    Vertical.PHARMACY,
    Vertical.MARKET,
)
#: Shops that sell products by the aisle (ADR-0018): their pages show aisles, sizes and stock, not a menu.
RETAIL_VERTICALS = (Vertical.GROCERY, Vertical.PHARMACY, Vertical.MARKET)


class Restaurant(Model):
    """A merchant: a restaurant (food), a beauty shop, a supermarket (grocery), a pharmacy, or a market
    shopper (market). The name is historical: every merchant is stored as a `Restaurant`."""

    id: str
    vertical: Vertical = Vertical.FOOD
    city: str = Field(default="lagos", pattern=r"^[a-z][a-z-]{1,30}$")
    name: str = Field(min_length=2, max_length=80)
    slug: str = Field(pattern=r"^[a-z0-9-]{2,80}$")
    description: str = Field(default="", max_length=500)
    cuisines: list[str] = Field(default_factory=list, max_length=10)
    tags: list[str] = Field(default_factory=list, max_length=20)
    image_url: str | None = None
    cover_url: str | None = None
    location: GeoPoint
    geohash: str = ""
    address: str = Field(max_length=200)
    area: str = ""
    zone_id: str = "lagos"
    rating: float = Field(default=0.0, ge=0, le=5)
    rating_count: int = Field(default=0, ge=0)
    price_level: int = Field(default=2, ge=1, le=4)
    avg_prep_minutes: int = Field(default=20, ge=1, le=180)
    opening_hours: OpeningHours = Field(default_factory=OpeningHours)
    is_accepting_orders: bool = True
    status: RestaurantStatus = RestaurantStatus.ACTIVE
    commission_bps: int | None = Field(default=None, ge=0, le=5000)
    delivery_radius_km: float = Field(default=8.0, gt=0, le=40)
    min_order_kobo: int = Field(default=0, ge=0)
    supports_delivery: bool = True
    supports_pickup: bool = True
    is_featured: bool = False
    phone: str | None = None
    owner_uid: str | None = None
    created_at: datetime | None = None
    # Businesses with branches (docs/adr/0028-business-branches-and-split-payments.md): every branch is a merchant of
    # its own (address, hours, orders) under one business; branches share the main branch's menu.
    business_id: str | None = None
    menu_restaurant_id: str | None = None  # where this branch's menu lives (None: its own)
    branch_name: str | None = Field(default=None, max_length=60)
    manager_phone: str | None = Field(default=None, max_length=20)

    @property
    def menu_id(self) -> str:
        """The merchant whose menu (items, shelves, options) this one sells."""
        return self.menu_restaurant_id or self.id


class Business(Model):
    """A business on Yummy Chops: one owner, one or more branches (each a `Restaurant`), one menu, one bank account.

    `id` is the business's unique ID (e.g. YCB-7K3Q9P): shown to the owner, tagged on every item it lists and used
    for its split card payments."""

    id: str
    name: str = Field(min_length=2, max_length=80)
    owner_uid: str
    vertical: Vertical = Vertical.FOOD
    phone: str | None = Field(default=None, max_length=20)
    email: str | None = Field(default=None, max_length=120)
    main_restaurant_id: str
    # Split card payments (Paystack subaccount): the business's share goes straight to its bank account.
    paystack_subaccount_code: str | None = None
    settlement_bank_code: str | None = None
    settlement_bank_name: str | None = None
    settlement_account_name: str | None = None
    settlement_account_last4: str | None = None  # never the full account number
    created_at: datetime


class MenuCategory(Model):
    id: str
    name: str = Field(min_length=1, max_length=60)
    position: int = 0


class ItemKind(StrEnum):
    MAIN = "main"
    COMBO = "combo"
    SIDE = "side"
    SNACK = "snack"
    DRINK = "drink"
    DESSERT = "dessert"
    EXTRA = "extra"
    PRODUCT = "product"  # non-food merchandise (beauty & skin care)


class OptionChoice(Model):
    id: str
    name: str = Field(min_length=1, max_length=60)
    price_delta_kobo: int = Field(default=0, ge=0)
    is_available: bool = True


class OptionGroup(Model):
    id: str
    restaurant_id: str
    name: str = Field(min_length=1, max_length=60)
    min_select: int = Field(default=0, ge=0, le=20)
    max_select: int = Field(default=1, ge=1, le=20)
    choices: list[OptionChoice] = Field(min_length=1, max_length=30)

    @model_validator(mode="after")
    def _bounds(self) -> OptionGroup:
        if self.min_select > self.max_select:
            raise ValueError("min_select cannot exceed max_select")
        return self


class MenuItem(Model):
    id: str
    restaurant_id: str
    business_id: str | None = None  # the business's unique ID, tagged on everything it lists
    category_id: str
    name: str = Field(min_length=1, max_length=80)
    description: str = Field(default="", max_length=400)
    price_kobo: int = Field(gt=0, le=100_000_000)
    image_url: str | None = None
    kind: ItemKind = ItemKind.MAIN
    tags: list[str] = Field(default_factory=list, max_length=15)
    dietary: list[str] = Field(default_factory=list, max_length=10)
    allergens: list[str] = Field(default_factory=list, max_length=15)
    serves: int = Field(default=1, ge=1, le=20)
    spice_level: int = Field(default=0, ge=0, le=3)
    is_available: bool = True
    is_active: bool = True
    popularity: int = Field(default=0, ge=0)
    option_group_ids: list[str] = Field(default_factory=list, max_length=10)
    prep_minutes: int | None = Field(default=None, ge=1, le=180)
    unit_label: str | None = Field(default=None, max_length=30)  # e.g. "250 ml", "50cl", "half paint"
    brand: str | None = Field(default=None, max_length=40)
    emoji: str | None = Field(default=None, max_length=8)  # picture placeholder until the shop adds a photo
    # Pharmacies sell over-the-counter products only: a prescription-only item is hidden from customers and
    # can never be ordered (ADR-0018).
    requires_prescription: bool = False
    search_keywords: list[str] = Field(default_factory=list)
    position: int = 0


# ----------------------------------------------------------------------------------------------
# Cart, quotes and orders
# ----------------------------------------------------------------------------------------------


class Fulfillment(StrEnum):
    DELIVERY = "delivery"
    PICKUP = "pickup"


class OptionSelection(Model):
    group_id: str
    choice_ids: list[str] = Field(default_factory=list, max_length=20)


class CartLine(Model):
    item_id: str
    quantity: int = Field(ge=1, le=50)
    selections: list[OptionSelection] = Field(default_factory=list, max_length=10)
    notes: str | None = Field(default=None, max_length=200)


class DeliveryAddress(Model):
    label: str | None = Field(default=None, max_length=40)
    line1: str = Field(min_length=3, max_length=200)
    area: str | None = Field(default=None, max_length=80)
    city: str = Field(default="Lagos", max_length=60)
    state: str = Field(default="Lagos", max_length=60)
    location: GeoPoint
    instructions: str | None = Field(default=None, max_length=300)
    contact_phone: str | None = Field(default=None, max_length=20)
    # Google place ID when the address came from search (IDs may be stored indefinitely; the pin is the user's).
    place_id: str | None = Field(default=None, max_length=300)


class QuoteRequest(Model):
    restaurant_id: str
    lines: list[CartLine] = Field(min_length=1, max_length=50)
    fulfillment: Fulfillment = Fulfillment.DELIVERY
    delivery_address: DeliveryAddress | None = None
    scheduled_for: datetime | None = None
    voucher_code: str | None = Field(default=None, max_length=40)

    @model_validator(mode="after")
    def _address_required(self) -> QuoteRequest:
        if self.fulfillment == Fulfillment.DELIVERY and self.delivery_address is None:
            raise ValueError("delivery_address is required for delivery orders")
        return self


class ParcelSize(StrEnum):
    SMALL = "small"  # fits in a bike box: documents, phones, a pair of shoes (up to 5 kg)
    MEDIUM = "medium"  # a shoebox to a small carton (up to 10 kg)
    LARGE = "large"  # bulky but bike-portable (up to 20 kg)


ParcelCategory = Literal["documents", "clothing", "electronics", "food", "cosmetics", "household", "other"]


class ParcelStop(Model):
    """Where a package is collected or dropped, and who to meet there."""

    name: str = Field(min_length=2, max_length=80)
    phone: str = Field(pattern=r"^\+?[0-9 ]{7,20}$")
    line1: str = Field(min_length=3, max_length=200)
    area: str | None = Field(default=None, max_length=80)
    city: str = Field(default="Lagos", max_length=60)
    location: GeoPoint
    instructions: str | None = Field(default=None, max_length=300)


class ParcelQuoteRequest(Model):
    pickup: ParcelStop
    dropoff: ParcelStop
    size: ParcelSize = ParcelSize.SMALL
    category: ParcelCategory = "other"
    description: str = Field(default="", max_length=200)
    declared_value_kobo: int | None = Field(default=None, ge=0, le=50_000_000)  # max ₦500,000
    scheduled_for: datetime | None = None  # pickup time; None = as soon as possible
    # Vendor cash-on-delivery: the rider collects this item price from the recipient for the sender.
    # The real ceiling comes from the pricing config (ParcelFeeConfig.cod_max_kobo).
    cod_amount_kobo: int | None = Field(default=None, ge=0, le=50_000_000)


class ParcelDetails(Model):
    pickup: ParcelStop
    dropoff: ParcelStop
    size: ParcelSize
    category: ParcelCategory
    description: str = ""
    declared_value_kobo: int | None = None
    city: str = "lagos"
    cod_amount_kobo: int | None = None  # cash the rider collects from the recipient for the sender


# ----------------------------------------------------------------------------------------------
# Interstate waybill
# ----------------------------------------------------------------------------------------------

WaybillFirstMile = Literal[
    "pickup", "dropoff"
]  # rider collects from the sender, or the sender drops at a hub
WaybillLastMile = Literal["door", "collect"]  # rider delivers to the door, or the recipient collects at a hub
WaybillLegKind = Literal["first_mile", "last_mile"]


class WaybillStage(StrEnum):
    AWAITING_DROPOFF = "awaiting_dropoff"
    PICKUP_SCHEDULED = "pickup_scheduled"
    PICKED_UP = "picked_up"
    AT_ORIGIN_HUB = "at_origin_hub"
    DEPARTED = "departed"
    AT_DESTINATION_HUB = "at_destination_hub"
    OUT_FOR_DELIVERY = "out_for_delivery"
    READY_FOR_COLLECTION = "ready_for_collection"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class WaybillParty(Model):
    """Sender or recipient. The address is required only where a rider goes (home pickup, door delivery)."""

    name: str = Field(min_length=2, max_length=80)
    phone: str = Field(pattern=r"^\+?[0-9 ]{7,20}$")
    line1: str | None = Field(default=None, min_length=3, max_length=200)
    area: str | None = Field(default=None, max_length=80)
    location: GeoPoint | None = None
    instructions: str | None = Field(default=None, max_length=300)


class WaybillQuoteRequest(Model):
    origin_city: str = Field(pattern=r"^[a-z][a-z-]{1,30}$")
    destination_city: str = Field(pattern=r"^[a-z][a-z-]{1,30}$")
    first_mile: WaybillFirstMile = "pickup"
    last_mile: WaybillLastMile = "door"
    origin_hub_id: str | None = Field(default=None, max_length=40)  # drop-off hub (nearest hub when omitted)
    destination_hub_id: str | None = Field(
        default=None, max_length=40
    )  # collection hub (nearest when omitted)
    sender: WaybillParty
    recipient: WaybillParty
    size: ParcelSize = ParcelSize.SMALL
    weight_kg: float = Field(gt=0, le=50)
    category: ParcelCategory = "other"
    description: str = Field(default="", max_length=200)
    declared_value_kobo: int | None = Field(default=None, ge=0, le=50_000_000)
    cod_amount_kobo: int | None = Field(
        default=None, ge=0, le=50_000_000
    )  # door delivery in Yummy Chops cities only


class WaybillMilestone(Model):
    stage: WaybillStage
    at: datetime
    hub_id: str | None = None
    note: str | None = None


class WaybillDetails(Model):
    tracking_code: str | None = None  # set when the order is created; also the public tracking number
    lane_id: str
    carrier_id: str
    carrier_name: str
    origin_city: str
    destination_city: str
    origin_city_name: str = ""
    destination_city_name: str = ""
    origin_hub_id: str
    destination_hub_id: str
    origin_hub_name: str = ""
    destination_hub_name: str = ""
    destination_hub_address: str = ""  # where the recipient collects (last_mile = collect)
    destination_hub_hours: str = ""
    first_mile: WaybillFirstMile
    last_mile: WaybillLastMile
    sender: WaybillParty
    recipient: WaybillParty
    size: ParcelSize
    weight_kg: float
    category: ParcelCategory = "other"
    description: str = ""
    declared_value_kobo: int | None = None
    cod_amount_kobo: int | None = None
    eta_from: date
    eta_to: date
    stage: WaybillStage | None = None  # set once paid
    milestones: list[WaybillMilestone] = Field(default_factory=list)
    first_mile_order_id: str | None = None
    last_mile_order_id: str | None = None
    trip_reference: str | None = None  # carrier trip / manifest reference recorded at departure


class PricedLine(Model):
    item_id: str
    name: str
    kind: ItemKind = ItemKind.MAIN
    quantity: int
    unit_price_kobo: int
    options_unit_price_kobo: int = 0
    line_total_kobo: int
    selections: list[OptionSelection] = Field(default_factory=list)
    selection_labels: list[str] = Field(default_factory=list)
    notes: str | None = None


class PriceBreakdown(Model):
    subtotal_kobo: int
    delivery_fee_kobo: int = 0
    service_fee_kobo: int = 0
    small_order_fee_kobo: int = 0
    vat_kobo: int = 0
    discount_kobo: int = 0
    cod_fee_kobo: int = 0  # cash-on-delivery collection fee (parcels)
    linehaul_fee_kobo: int = 0  # waybill: carrying the package between cities
    pickup_fee_kobo: int = 0  # waybill: rider collects from the sender's address
    plus_savings_kobo: int = 0  # Yummy Chops Plus: fees and VAT the member did not pay (informational)
    total_kobo: int
    discount_funded_by: Literal["platform", "restaurant"] | None = None
    voucher_code: str | None = None


class SettlementTerms(Model):
    """Internal money split, frozen at quote time. Never shown to customers."""

    commission_bps: int
    commission_kobo: int
    rider_pay_kobo: int = 0
    restaurant_funded_discount_kobo: int = 0
    platform_funded_discount_kobo: int = 0
    restaurant_earning_kobo: int
    carrier_cost_kobo: int = 0  # waybill: owed to the line-haul carrier when the shipment completes


class Quote(Model):
    id: str
    customer_id: str
    vertical: Vertical = Vertical.FOOD
    restaurant_id: str
    restaurant_name: str
    lines: list[PricedLine]
    breakdown: PriceBreakdown
    settlement: SettlementTerms
    fulfillment: Fulfillment
    delivery_address: DeliveryAddress | None = None
    distance_km: float | None = None  # straight line, kitchen to door (delivery radius checks)
    road_distance_km: float | None = None  # what the delivery fee was priced on
    route_source: Literal["google", "estimate"] | None = None  # measured by Google Routes, or estimated
    eta_minutes: int
    estimated_delivery_at: datetime
    scheduled_for: datetime | None = None
    pricing_version: int
    menu_fingerprint: str
    created_at: datetime
    expires_at: datetime
    order_id: str | None = None  # set once an order has been created from the quote


class ParcelQuote(Model):
    id: str
    customer_id: str
    details: ParcelDetails
    breakdown: PriceBreakdown
    settlement: SettlementTerms
    distance_km: float
    road_distance_km: float | None = None
    route_source: Literal["google", "estimate"] | None = None
    eta_minutes: int
    estimated_delivery_at: datetime
    scheduled_for: datetime | None = None
    pricing_version: int
    created_at: datetime
    expires_at: datetime
    order_id: str | None = None


class WaybillQuote(Model):
    id: str
    customer_id: str
    details: WaybillDetails
    breakdown: PriceBreakdown
    settlement: SettlementTerms
    pickup_km: float | None = None  # sender → origin hub (home pickup)
    delivery_km: float | None = None  # destination hub → recipient (door delivery)
    network_version: int
    created_at: datetime
    expires_at: datetime
    order_id: str | None = None


class PaymentSummary(Model):
    provider: str | None = None
    reference: str | None = None
    status: Literal["unpaid", "pending", "paid", "failed", "refunded", "partially_refunded"] = "unpaid"
    paid_at: datetime | None = None
    # A split card payment: the business's share, sent straight to its bank account by the provider.
    split_to_business_kobo: int = 0


class Order(Model):
    id: str
    short_code: str
    vertical: Vertical = Vertical.FOOD
    customer_id: str
    customer_name: str | None = None
    customer_phone: str | None = None
    restaurant_id: str
    restaurant_name: str
    restaurant_location: GeoPoint
    restaurant_address: str = ""
    status: OrderStatus
    fulfillment: Fulfillment
    lines: list[PricedLine]
    breakdown: PriceBreakdown
    settlement: SettlementTerms
    delivery_address: DeliveryAddress | None = None
    distance_km: float | None = None
    scheduled_for: datetime | None = None
    quote_id: str
    payment: PaymentSummary = Field(default_factory=PaymentSummary)
    rider_id: str | None = None
    rider_name: str | None = None
    assignment_id: str | None = None
    dispatch_attempts: int = 0
    prep_minutes: int | None = None
    estimated_delivery_at: datetime | None = None
    accepted_at: datetime | None = None
    ready_at: datetime | None = None
    picked_up_at: datetime | None = None
    delivered_at: datetime | None = None
    completed_at: datetime | None = None
    cancelled_at: datetime | None = None
    cancellation_reason: str | None = None
    refund_total_kobo: int = 0
    cash_collected_at: datetime | None = None  # rider took cash at the door (pay on delivery and/or COD)
    settled_at: datetime | None = None
    reviewed: bool = False
    channel: Literal["app", "web", "ai_agent", "whatsapp", "admin"] = "app"
    parcel: ParcelDetails | None = None  # set for vertical == parcel
    waybill: WaybillDetails | None = None  # set for vertical == waybill
    # Internal rider job that moves a waybill between an address and a hub (no payment of its own).
    leg_of: str | None = None
    group_order_id: str | None = None  # placed by the host of a group order (split bill)
    leg_kind: WaybillLegKind | None = None
    created_at: datetime
    updated_at: datetime
    version: int = 0

    @property
    def is_parcel(self) -> bool:
        return self.vertical == Vertical.PARCEL

    @property
    def is_waybill(self) -> bool:
        return self.vertical == Vertical.WAYBILL

    @property
    def is_leg(self) -> bool:
        return self.leg_of is not None

    @property
    def is_pay_on_delivery(self) -> bool:
        return self.payment.provider == "cash"

    @property
    def awaiting_cash_payment(self) -> bool:
        """Pay-on-delivery order whose cash has not been collected: nothing to refund if it is called off."""
        return self.is_pay_on_delivery and self.payment.status != "paid"

    @property
    def cash_to_collect_kobo(self) -> int:
        """Cash the rider must take at the door: the order total (pay on delivery) plus any vendor COD."""
        if self.cash_collected_at is not None:
            return 0
        due = self.breakdown.total_kobo if self.awaiting_cash_payment else 0
        if self.parcel is not None and self.parcel.cod_amount_kobo:
            due += self.parcel.cod_amount_kobo
        return due


class OrderEvent(Model):
    id: str
    order_id: str
    from_status: OrderStatus | None
    to_status: OrderStatus
    actor_type: ActorType
    actor_id: str
    reason: str | None = None
    at: datetime
    metadata: dict[str, Any] = Field(default_factory=dict)


# ----------------------------------------------------------------------------------------------
# Riders & dispatch
# ----------------------------------------------------------------------------------------------


class VehicleType(StrEnum):
    BICYCLE = "bicycle"
    MOTORCYCLE = "motorcycle"
    CAR = "car"


class RiderStatus(StrEnum):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"


class RiderProfile(Model):
    uid: str
    name: str
    phone: str | None = None
    vehicle: VehicleType = VehicleType.MOTORCYCLE
    plate_number: str | None = None
    status: RiderStatus = RiderStatus.PENDING
    is_online: bool = False
    rating: float = Field(default=5.0, ge=0, le=5)
    rating_count: int = 0
    acceptance_rate: float = Field(default=1.0, ge=0, le=1)
    offers_received: int = 0
    offers_accepted: int = 0
    active_order_ids: list[str] = Field(default_factory=list)
    completed_deliveries: int = 0
    cash_held_kobo: int = 0  # copy of the ledger's receivable:rider_cash balance, used by dispatch
    zone_id: str = "lagos"
    last_location: GeoPoint | None = None
    last_location_at: datetime | None = None
    geohash: str | None = None
    created_at: datetime | None = None
    # Set when the team has checked the rider's KYC (documents, NIN, guarantors, face): the Verified badge.
    verified_at: datetime | None = None


# ---- rider KYC (docs/adr/0027-rider-kyc.md) ---------------------------------------------------------------------
# What a rider uploads, in the order the rider app asks for it. Photos are images; the guarantors' signed forms may
# also be PDFs.
KYC_DOCUMENTS: dict[str, str] = {
    "plate_number": "Plate number",
    "hackney_permit": "Hackney permit",
    "riders_card": "Rider's card or licence",
    "bike": "Photo of your bike",
    "guarantor_1_form": "Guarantor 1: signed form",
    "guarantor_2_form": "Guarantor 2: signed form",
    "face": "Face verification (selfie)",
}


class KycDocument(Model):
    path: str  # in the file store, under applications/{uid}/kyc/
    content_type: str
    size: int
    uploaded_at: datetime


class Guarantor(Model):
    name: str = Field(default="", max_length=80)
    phone: str = Field(default="", max_length=20)
    email: str = Field(default="", max_length=120)
    address: str = Field(default="", max_length=200)
    occupation: str = Field(default="", max_length=80)


class RiderKyc(Model):
    uid: str
    # draft → submitted → verified, or → needs_changes → (rider fixes) → submitted → ...
    status: Literal["draft", "submitted", "needs_changes", "verified", "rejected"] = "draft"
    # From the sign-up form.
    full_name: str = ""
    whatsapp_phone: str = ""
    email: str = ""
    residential_address: str = ""
    # From the KYC dashboard.
    permanent_address: str = ""
    nin: str = ""  # National Identification Number: shown in full only to the reviewing team
    documents: dict[str, KycDocument] = Field(default_factory=dict)
    guarantors: list[Guarantor] = Field(default_factory=lambda: [Guarantor(), Guarantor()])
    submitted_at: datetime | None = None
    reviewed_at: datetime | None = None
    reviewed_by: str | None = None
    review_note: str | None = None
    changes_needed: list[str] = Field(
        default_factory=list
    )  # KYC_DOCUMENTS keys and/or "details", "guarantors"
    updated_at: datetime | None = None


class AssignmentStatus(StrEnum):
    OFFERED = "offered"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


class DeliveryAssignment(Model):
    id: str
    order_id: str
    rider_id: str
    status: AssignmentStatus
    attempt: int
    score: float
    distance_to_restaurant_km: float
    restaurant_name: str
    pickup: GeoPoint
    dropoff: GeoPoint | None
    dropoff_area: str | None = None
    payout_kobo: int
    offered_at: datetime
    expires_at: datetime
    responded_at: datetime | None = None
    decline_reason: str | None = None


# ----------------------------------------------------------------------------------------------
# Customers, engagement, support
# ----------------------------------------------------------------------------------------------


class CustomerProfile(Model):
    uid: str
    display_name: str | None = Field(default=None, max_length=80)
    phone: str | None = None
    email: str | None = None
    dietary: list[str] = Field(default_factory=list, max_length=10)
    allergens: list[str] = Field(default_factory=list, max_length=15)
    favourite_cuisines: list[str] = Field(default_factory=list, max_length=15)
    favourite_restaurant_ids: list[str] = Field(default_factory=list, max_length=100)
    personalisation_consent: bool = True
    marketing_consent: bool = False
    loyalty_points: int = 0
    refund_to_wallet: bool = False  # card refunds go instantly into the Yummy Chops wallet instead
    pay_on_delivery_blocked: bool = False  # set by support after a refused or failed cash delivery
    created_at: datetime | None = None
    updated_at: datetime | None = None


class SavedAddress(DeliveryAddress):
    id: str


class Voucher(Model):
    code: str = Field(pattern=r"^[A-Z0-9_-]{3,40}$")
    description: str = ""
    kind: Literal["percent", "fixed"]
    value: int = Field(gt=0)  # bps for percent, kobo for fixed
    max_discount_kobo: int | None = Field(default=None, gt=0)
    target: Literal["subtotal", "delivery_fee"] = "subtotal"
    min_subtotal_kobo: int = Field(default=0, ge=0)
    funded_by: Literal["platform", "restaurant"] = "platform"
    restaurant_id: str | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    usage_limit: int | None = Field(default=None, gt=0)
    per_customer_limit: int = Field(default=1, gt=0)
    used_count: int = 0
    is_active: bool = True
    customer_id: str | None = None  # personal voucher (rewards): only this account can use it
    source: Literal["campaign", "points", "referral", "referrer"] = "campaign"


class Review(Model):
    id: str
    order_id: str
    restaurant_id: str
    customer_id: str
    rider_id: str | None = None
    food_rating: int = Field(ge=1, le=5)
    delivery_rating: int | None = Field(default=None, ge=1, le=5)
    comment: str | None = Field(default=None, max_length=1000)
    created_at: datetime


TicketCategory = Literal[
    "missing_item", "wrong_order", "late_delivery", "payment", "quality", "rider", "account", "other"
]


class SupportTicket(Model):
    id: str
    opened_by: str
    order_id: str | None = None
    category: TicketCategory
    description: str = Field(max_length=2000)
    missing_item_ids: list[str] = Field(default_factory=list)
    status: Literal["open", "in_progress", "escalated", "resolved", "closed"] = "open"
    priority: Literal["low", "normal", "high", "urgent"] = "normal"
    channel: Literal["app", "web", "ai_agent", "whatsapp", "phone"] = "app"
    assigned_to: str | None = None
    resolution: str | None = None
    refund_id: str | None = None
    created_at: datetime
    updated_at: datetime


class Application(Model):
    id: str
    type: Literal["restaurant", "rider"]
    applicant_uid: str
    status: Literal["submitted", "in_review", "approved", "rejected"] = "submitted"
    data: dict[str, Any] = Field(default_factory=dict)
    document_paths: list[str] = Field(default_factory=list, max_length=20)
    submitted_at: datetime
    decided_at: datetime | None = None
    decided_by: str | None = None
    decision_reason: str | None = None
    created_entity_id: str | None = None


class Notification(Model):
    id: str
    recipient_uid: str
    title: str
    body: str
    data: dict[str, str] = Field(default_factory=dict)
    created_at: datetime
    read_at: datetime | None = None
