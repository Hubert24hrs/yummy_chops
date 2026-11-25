"""Interstate waybill: destinations, quotes, booking, rider legs, hub operations and public tracking.

A waybill is an order with `vertical = waybill`, so payment, refunds and settlement follow the normal order pipeline
and every status change goes through `OrderService.transition`. Finer progress (picked up, at the hub, departed…)
lives in `order.waybill.stage` / `milestones`.

The first and last mile are separate internal rider jobs: parcel orders with `leg_of` = the waybill, no payment of
their own, dispatched like any same-city package. Hubs confirm custody in the Command Centre: they receive packages
(which also completes a first-mile rider job), record departures with the carrier's trip reference, record arrivals
(which starts door delivery or opens collection) and hand packages over against the recipient's collection code.
"""

from __future__ import annotations

import logging
import re
import secrets
import uuid
from collections.abc import Callable
from datetime import UTC, date, datetime, timedelta
from typing import Any

from pydantic import BaseModel, Field

from ..domain.geo import haversine_km
from ..domain.logistics import (
    WAYBILL_STEPS,
    Hub,
    WaybillNetwork,
    delivery_window,
    stage_label,
    stage_step,
)
from ..domain.models import (
    DeliveryAddress,
    Fulfillment,
    Order,
    OrderEvent,
    ParcelDetails,
    ParcelStop,
    PaymentSummary,
    PriceBreakdown,
    SettlementTerms,
    Vertical,
    WaybillDetails,
    WaybillLegKind,
    WaybillMilestone,
    WaybillParty,
    WaybillQuote,
    WaybillQuoteRequest,
    WaybillStage,
)
from ..domain.order_state import ActorType, OrderStatus
from ..domain.pricing import PricingConfig, PricingResult, compute_waybill_price, parcel_rider_pay
from ..errors import (
    InvalidTransition,
    NotFound,
    OutOfDeliveryArea,
    PriceChanged,
    QuoteExpired,
    ValidationFailed,
)
from ..ledger.audit import AuditLog
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, require
from .infra import Notifier, TaskQueue
from .orders import PARCEL_MERCHANT_ID, TASK_UNPAID_EXPIRY, OrderService, new_code, short_code

logger = logging.getLogger(__name__)
S = OrderStatus
A = ActorType
W = WaybillStage
WAYBILL_MERCHANT_ID = "gm-waybill"  # pseudo-merchant for waybill orders (no partner owns it)
QUOTE_TTL = timedelta(minutes=15)
_CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
TRACKING_PATTERN = r"^GMW[2-9A-HJ-NP-Z]{8}$"
EARLY_STAGES = {W.AWAITING_DROPOFF, W.PICKUP_SCHEDULED, W.PICKED_UP}


def utcnow() -> datetime:
    return datetime.now(UTC)


def new_tracking_code() -> str:
    return "GMW" + "".join(secrets.choice(_CODE_ALPHABET) for _ in range(8))


def eta_text(details: WaybillDetails) -> str:
    def fmt(d: date) -> str:
        return f"{d:%a} {d.day} {d:%b}"

    if details.eta_from == details.eta_to:
        return fmt(details.eta_from)
    return f"{fmt(details.eta_from)} – {fmt(details.eta_to)}"


class HubScanInput(BaseModel):
    hub_id: str = Field(max_length=40)
    tracking_code: str = Field(pattern=TRACKING_PATTERN)


class DepartInput(BaseModel):
    hub_id: str = Field(max_length=40)
    tracking_codes: list[str] = Field(min_length=1, max_length=200)
    trip_reference: str = Field(
        min_length=2, max_length=120
    )  # the carrier's trip, vehicle or manifest number


class CollectInput(HubScanInput):
    code: str = Field(pattern=r"^\d{4}$")  # the recipient's collection code


def _hub_stop(hub: Hub, city_name: str, instructions: str) -> ParcelStop:
    return ParcelStop(
        name=hub.name[:80],
        phone=hub.phone,
        line1=hub.address[:200],
        area=None,
        city=city_name,
        location=hub.location,
        instructions=instructions,
    )


def _party_stop(party: WaybillParty, city_name: str) -> ParcelStop:
    if party.location is None or not party.line1:
        raise ValidationFailed("An address is needed for a rider pickup or delivery")
    return ParcelStop(
        name=party.name,
        phone=party.phone,
        line1=party.line1,
        area=party.area,
        city=city_name,
        location=party.location,
        instructions=party.instructions,
    )


def _hub_view(hub: Hub) -> dict[str, Any]:
    return {
        "id": hub.id,
        "name": hub.name,
        "city": hub.city,
        "kind": hub.kind,
        "address": hub.address,
        "location": hub.location.model_dump(),
        "phone": hub.phone,
        "hours": hub.hours,
        "accepts_dropoff": hub.accepts_dropoff,
        "offers_collection": hub.offers_collection,
        "is_sample": hub.is_sample,
    }


def waybill_quote_view(quote: WaybillQuote) -> dict[str, Any]:
    data = quote.model_dump(mode="json")
    data.pop("settlement", None)  # carrier and rider costs are internal
    data["eta_text"] = eta_text(quote.details)
    return data


class WaybillService:
    def __init__(
        self,
        repos: Repositories,
        orders: OrderService,
        *,
        tasks: TaskQueue,
        notifier: Notifier,
        audit: AuditLog,
        unpaid_order_ttl_seconds: int = 1800,
        sample_network_bookable: bool = True,
        rider_cash_limit_kobo: int | None = None,
    ) -> None:
        self.rider_cash_limit_kobo = rider_cash_limit_kobo
        self.repos = repos
        self.orders = orders
        self.tasks = tasks
        self.notifier = notifier
        self.audit = audit
        self.unpaid_ttl = unpaid_order_ttl_seconds
        #: Sample hubs and carriers (the network before a real one is saved) can be booked in local and test only.
        self.sample_network_bookable = sample_network_bookable

    async def network(self) -> WaybillNetwork:
        return await self.repos.get_waybill_network()

    # ============================================================================ catalogue
    async def origins(self) -> list[dict[str, Any]]:
        net = await self.network()
        out = []
        for city_id in net.origins():
            city = net.city(city_id)
            if city is None:
                continue
            out.append(
                {
                    "id": city.id,
                    "name": city.name,
                    "state": city.state,
                    "home_pickup": city.door_service,
                    "dropoff_hubs": [_hub_view(h) for h in net.hubs_in(city.id, dropoff=True)],
                }
            )
        return out

    async def destinations(self, origin_city: str) -> dict[str, Any]:
        net = await self.network()
        cfg = await self.repos.get_pricing_config()
        origin = net.city(origin_city)
        lanes = net.destinations(origin_city)
        if origin is None or not lanes:
            raise NotFound("We don't send waybills from that city yet")
        destinations = []
        for lane in lanes:
            dest = net.city(lane.destination_city)
            carrier = net.carrier(lane.carrier_id)
            if dest is None or carrier is None:
                continue
            cheapest = compute_waybill_price(
                lane=lane,
                size=min(lane.base_by_size_kobo, key=lambda size: lane.base_by_size_kobo[size]),
                weight_kg=0.5,
                max_weight_kg=max(net.max_kg_by_size.values()),
                service_fee_kobo=net.service_fee_kobo,
                pickup_km=None,
                delivery_km=None,
                cod_amount_kobo=None,
                cfg=cfg,
            )
            destinations.append(
                {
                    "city": dest.id,
                    "name": dest.name,
                    "state": dest.state,
                    "door_delivery": dest.door_service,
                    "transit_days": [lane.transit_days_min, lane.transit_days_max],
                    "from_kobo": cheapest.breakdown.total_kobo,  # small package, drop-off and collection
                    "carrier": carrier.name,
                    "collection_hubs": [_hub_view(h) for h in net.hubs_in(dest.id, collection=True)],
                }
            )
        return {
            "origin": {"id": origin.id, "name": origin.name, "home_pickup": origin.door_service},
            "dropoff_hubs": [_hub_view(h) for h in net.hubs_in(origin.id, dropoff=True)],
            "destinations": destinations,
            "max_kg_by_size": {k.value: v for k, v in net.max_kg_by_size.items()},
        }

    # ============================================================================ quotes
    async def price(
        self, req: WaybillQuoteRequest, *, now: datetime | None = None
    ) -> tuple[PricingResult, WaybillDetails, float | None, float | None, WaybillNetwork]:
        """Validate a shipment against the live network and price it. All amounts come from `pricing.py`."""
        now = now or utcnow()
        net = await self.network()
        cfg = await self.repos.get_pricing_config()
        if req.origin_city == req.destination_city:
            raise ValidationFailed(
                "Both addresses are in the same city: book a same-city package delivery instead"
            )
        origin, dest = net.city(req.origin_city), net.city(req.destination_city)
        lane = net.lane(req.origin_city, req.destination_city)
        if origin is None or dest is None or lane is None:
            raise OutOfDeliveryArea(
                "We don't run waybills on that route yet",
                details={"origins": net.origins()},
            )
        carrier = net.carrier(lane.carrier_id)
        if carrier is None:
            raise OutOfDeliveryArea("This route is not available right now")

        pickup_km = delivery_km = None
        if req.first_mile == "pickup":
            if not origin.door_service:
                raise ValidationFailed(
                    f"Home pickup isn't available in {origin.name}; drop the package at a hub"
                )
            self._check_address(req.sender, cfg, origin.id, origin.name, "pickup")
        origin_hub = (
            net.hub(req.origin_hub_id)
            if req.origin_hub_id
            else net.nearest_hub(origin.id, req.sender.location, dropoff=True)
        )
        if origin_hub is None or origin_hub.city != origin.id or not origin_hub.accepts_dropoff:
            raise ValidationFailed("Choose a hub in the sending city")
        if req.first_mile == "pickup":
            assert req.sender.location is not None
            pickup_km = haversine_km(req.sender.location, origin_hub.location)

        if req.last_mile == "door":
            if not dest.door_service:
                raise ValidationFailed(
                    f"Door delivery isn't available in {dest.name} yet; the recipient can collect at the hub"
                )
            self._check_address(req.recipient, cfg, dest.id, dest.name, "delivery")
        elif req.cod_amount_kobo:
            raise ValidationFailed("Cash on delivery needs door delivery (the rider collects the cash)")
        dest_hub = (
            net.hub(req.destination_hub_id)
            if req.destination_hub_id
            else net.nearest_hub(
                dest.id,
                req.recipient.location if req.last_mile == "door" else None,
                collection=req.last_mile == "collect",
            )
        )
        if (
            dest_hub is None
            or dest_hub.city != dest.id
            or (req.last_mile == "collect" and not dest_hub.offers_collection)
        ):
            raise ValidationFailed("Choose a collection point in the destination city")
        if req.last_mile == "door":
            assert req.recipient.location is not None
            delivery_km = haversine_km(dest_hub.location, req.recipient.location)
        sample = carrier.is_sample or origin_hub.is_sample or dest_hub.is_sample
        if sample and not self.sample_network_bookable:
            # Never take money for a route through a placeholder hub or carrier.
            raise OutOfDeliveryArea("Interstate waybills on this route are not open for booking yet")

        result = compute_waybill_price(
            lane=lane,
            size=req.size,
            weight_kg=req.weight_kg,
            max_weight_kg=net.max_kg_by_size[req.size],
            service_fee_kobo=net.service_fee_kobo,
            pickup_km=pickup_km,
            delivery_km=delivery_km,
            cod_amount_kobo=req.cod_amount_kobo or None,
            cfg=cfg,
            rider_cash_limit_kobo=self.rider_cash_limit_kobo,
        )
        eta_from, eta_to = delivery_window(lane, now, first_mile=req.first_mile, last_mile=req.last_mile)
        details = WaybillDetails(
            lane_id=lane.id,
            carrier_id=carrier.id,
            carrier_name=carrier.name,
            origin_city=origin.id,
            destination_city=dest.id,
            origin_city_name=origin.name,
            destination_city_name=dest.name,
            origin_hub_id=origin_hub.id,
            destination_hub_id=dest_hub.id,
            origin_hub_name=origin_hub.name,
            destination_hub_name=dest_hub.name,
            destination_hub_address=dest_hub.address,
            destination_hub_hours=dest_hub.hours,
            first_mile=req.first_mile,
            last_mile=req.last_mile,
            sender=req.sender,
            recipient=req.recipient,
            size=req.size,
            weight_kg=req.weight_kg,
            category=req.category,
            description=req.description.strip(),
            declared_value_kobo=req.declared_value_kobo,
            cod_amount_kobo=req.cod_amount_kobo or None,
            eta_from=eta_from,
            eta_to=eta_to,
        )
        return result, details, pickup_km, delivery_km, net

    @staticmethod
    def _check_address(
        party: WaybillParty, cfg: PricingConfig, city_id: str, city_name: str, what: str
    ) -> None:
        if party.location is None or not party.line1:
            raise ValidationFailed(f"Enter the {what} address")
        zone = cfg.zone_for(party.location)
        if zone is None or zone.city != city_id:
            raise OutOfDeliveryArea(f"The {what} address is outside our {city_name} delivery area")

    async def create_quote(self, principal: Principal, req: WaybillQuoteRequest) -> WaybillQuote:
        now = utcnow()
        result, details, pickup_km, delivery_km, net = await self.price(req, now=now)
        quote = WaybillQuote(
            id=uuid.uuid4().hex,
            customer_id=principal.uid,
            details=details,
            breakdown=result.breakdown,
            settlement=result.settlement,
            pickup_km=round(pickup_km, 3) if pickup_km is not None else None,
            delivery_km=round(delivery_km, 3) if delivery_km is not None else None,
            network_version=net.version,
            created_at=now,
            expires_at=now + QUOTE_TTL,
        )
        await self.repos.waybill_quotes.create(quote)
        return quote

    async def get_quote(self, principal: Principal, quote_id: str) -> WaybillQuote:
        quote = await self.repos.waybill_quotes.get(quote_id)
        if quote is None or quote.customer_id != principal.uid:
            raise NotFound("Quote not found")
        return quote

    # ============================================================================ booking
    async def create_order(self, principal: Principal, quote_id: str, *, channel: str = "app") -> Order:
        """Create the waybill order from a quote (idempotent per quote), re-priced against live configuration."""
        quote = await self.get_quote(principal, quote_id)
        if quote.order_id:
            return await self.orders.get(quote.order_id)
        now = utcnow()
        if quote.expires_at < now:
            raise QuoteExpired("Your price quote expired; please get a new price")
        d = quote.details
        result, fresh, *_ = await self.price(
            WaybillQuoteRequest(
                origin_city=d.origin_city,
                destination_city=d.destination_city,
                first_mile=d.first_mile,
                last_mile=d.last_mile,
                origin_hub_id=d.origin_hub_id,
                destination_hub_id=d.destination_hub_id,
                sender=d.sender,
                recipient=d.recipient,
                size=d.size,
                weight_kg=d.weight_kg,
                category=d.category,
                description=d.description,
                declared_value_kobo=d.declared_value_kobo,
                cod_amount_kobo=d.cod_amount_kobo,
            ),
            now=now,
        )
        if result.breakdown.total_kobo != quote.breakdown.total_kobo:
            raise PriceChanged(
                "Waybill prices changed since your quote; please review the new price",
                details={
                    "quoted_total_kobo": quote.breakdown.total_kobo,
                    "new_total_kobo": result.breakdown.total_kobo,
                },
            )
        net = await self.network()
        origin_hub = net.hub(fresh.origin_hub_id)
        assert origin_hub is not None
        door = fresh.last_mile == "door"
        for _ in range(3):
            code = new_tracking_code()
            order_id = uuid.uuid4().hex
            details = fresh.model_copy(update={"tracking_code": code})
            recipient = details.recipient
            order = Order(
                id=order_id,
                short_code=short_code(),
                vertical=Vertical.WAYBILL,
                customer_id=principal.uid,
                customer_name=principal.name,
                customer_phone=principal.phone or details.sender.phone,
                restaurant_id=WAYBILL_MERCHANT_ID,
                restaurant_name=f"Waybill to {details.destination_city_name}",
                restaurant_location=origin_hub.location,
                restaurant_address=origin_hub.address,
                status=S.DRAFT,
                fulfillment=Fulfillment.DELIVERY if door else Fulfillment.PICKUP,
                lines=[],
                breakdown=quote.breakdown,
                settlement=quote.settlement,
                delivery_address=DeliveryAddress(
                    label=f"Recipient: {recipient.name}"[:40],
                    line1=recipient.line1 or "",
                    area=recipient.area,
                    city=details.destination_city_name,
                    state=details.destination_city_name,
                    location=recipient.location,
                    instructions=recipient.instructions,
                    contact_phone=recipient.phone,
                )
                if door and recipient.location is not None and recipient.line1
                else None,
                quote_id=quote.id,
                channel=channel,  # type: ignore[arg-type]
                waybill=details,
                created_at=now,
                updated_at=now,
            )
            event = OrderEvent(
                id=uuid.uuid4().hex,
                order_id=order_id,
                from_status=None,
                to_status=S.DRAFT,
                actor_type=A.CUSTOMER,
                actor_id=principal.uid,
                at=now,
                metadata={"channel": channel, "vertical": "waybill", "tracking_code": code},
            )

            async def fn(
                tx: Transaction, order: Order = order, event: OrderEvent = event, code: str = code
            ) -> str | None:
                qdata = await tx.get(f"waybill_quotes/{quote.id}")
                if qdata and qdata.get("order_id"):
                    return str(qdata["order_id"])
                if await tx.get(self.repos.waybill_code_path(code)) is not None:
                    return None  # tracking number already used: try another
                tx.update(f"waybill_quotes/{quote.id}", {"order_id": order.id})
                tx.create(f"orders/{order.id}", to_doc(order))
                tx.create(f"order_events/{event.id}", to_doc(event))
                tx.create(self.repos.waybill_code_path(code), {"order_id": order.id, "created_at": now})
                return order.id

            created_id = await self.repos.store.run_transaction(fn)
            if created_id is None:
                continue
            if created_id != order_id:
                return await self.orders.get(created_id)
            await self.tasks.enqueue(
                TASK_UNPAID_EXPIRY, {"order_id": order_id}, delay_seconds=self.unpaid_ttl
            )
            return order
        raise InvalidTransition("Could not allocate a tracking number; please try again")

    # ============================================================================ lifecycle (events)
    async def on_paid(self, payload: dict[str, Any]) -> None:
        """`waybill.paid`: book the rider pickup, or ask the sender to drop the package at the hub."""
        order = await self.repos.orders.get(str(payload["order_id"]))
        if (
            order is None
            or order.waybill is None
            or order.status != S.PAID
            or order.waybill.stage is not None
        ):
            return
        w = order.waybill
        if w.first_mile == "pickup":
            updated = await self._milestone(
                order.id, W.PICKUP_SCHEDULED, hub_id=w.origin_hub_id, allowed={None}
            )
            if updated is None:
                return
            await self._start_leg(updated, "first_mile")
            await self._notify(
                order,
                "Pickup booked",
                f"A rider will collect your package and take it to {w.origin_hub_name}. "
                f"Tracking number {w.tracking_code}.",
            )
        else:
            if await self._milestone(order.id, W.AWAITING_DROPOFF, hub_id=w.origin_hub_id, allowed={None}):
                hub = (await self.network()).hub(w.origin_hub_id)
                where = f"{hub.name}, {hub.address} ({hub.hours})" if hub else w.origin_hub_name
                await self._notify(
                    order,
                    "Drop off your package",
                    f"Take it to {where} and give tracking number {w.tracking_code}. "
                    "Write the number on the package.",
                )

    async def on_leg_event(self, payload: dict[str, Any]) -> None:
        """`order.picked_up` / `order.delivered` of a rider leg move the waybill on."""
        leg = await self.repos.orders.get(str(payload["order_id"]))
        if leg is None or not leg.is_leg or leg.leg_of is None:
            return
        parent = await self.repos.orders.get(leg.leg_of)
        if parent is None or parent.waybill is None:
            return
        w, to = parent.waybill, payload.get("to")
        rider = leg.rider_name or "Your rider"
        if leg.leg_kind == "first_mile" and to == S.PICKED_UP.value:
            if await self._milestone(parent.id, W.PICKED_UP, hub_id=None, allowed={W.PICKUP_SCHEDULED}):
                await self._notify(
                    parent, "Package collected", f"{rider} is taking your package to {w.origin_hub_name}."
                )
        elif leg.leg_kind == "last_mile" and to == S.PICKED_UP.value:
            if await self._milestone(
                parent.id, W.OUT_FOR_DELIVERY, hub_id=w.destination_hub_id, allowed={W.AT_DESTINATION_HUB}
            ):
                await self._notify(
                    parent, "Out for delivery", f"{rider} is delivering your package to {w.recipient.name}."
                )
        elif leg.leg_kind == "last_mile" and to == S.DELIVERED.value:
            await self._deliver(
                parent,
                actor=A.SYSTEM,
                actor_id="waybills",
                reason=None,
                note=f"Delivered by {rider}",
                allowed={W.AT_DESTINATION_HUB, W.OUT_FOR_DELIVERY},
            )

    async def on_called_off(self, payload: dict[str, Any]) -> None:
        """A waybill was refunded or cancelled: call off rider legs that haven't collected the package."""
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.waybill is None:
            return
        w = order.waybill
        for leg_id in (w.first_mile_order_id, w.last_mile_order_id):
            leg = await self.repos.orders.get(leg_id) if leg_id else None
            if leg is None or leg.status not in (S.DRAFT, S.READY_FOR_PICKUP, S.RIDER_ASSIGNED):
                continue
            try:
                await self.orders.transition(
                    leg.id,
                    S.CANCELLED,
                    actor_type=A.SYSTEM,
                    actor_id="waybills",
                    reason="Waybill called off",
                    patch={"cancelled_at": utcnow(), "cancellation_reason": "waybill_called_off"},
                )
            except InvalidTransition:
                logger.warning("could not cancel waybill leg", extra={"extra_fields": {"leg_id": leg.id}})
        if w.stage not in (W.DELIVERED, W.CANCELLED):
            open_stages: set[WaybillStage | None] = {None, *(set(W) - {W.DELIVERED, W.CANCELLED})}
            await self._milestone(order.id, W.CANCELLED, hub_id=None, allowed=open_stages)

    # ============================================================================ hub operations
    async def hub_board(self, principal: Principal, hub_id: str) -> dict[str, Any]:
        require(principal, Permission.HUB_OPERATE)
        net = await self.network()
        hub = net.hub(hub_id)
        if hub is None:
            raise NotFound("Hub not found")
        orders = await self.repos.orders.find(
            where=[
                ("vertical", "==", Vertical.WAYBILL.value),
                ("status", "in", [S.PAID.value, S.IN_TRANSIT.value]),
            ],
            limit=2000,
        )

        def pick(origin: bool, stages: set[WaybillStage]) -> list[dict[str, Any]]:
            rows = [
                o
                for o in orders
                if o.waybill is not None
                and o.waybill.stage in stages
                and (o.waybill.origin_hub_id if origin else o.waybill.destination_hub_id) == hub.id
            ]
            return [self._hub_item(o) for o in sorted(rows, key=lambda o: o.updated_at)]

        return {
            "hub": _hub_view(hub),
            "expected": pick(True, EARLY_STAGES),
            "at_hub": pick(True, {W.AT_ORIGIN_HUB}),
            "incoming": pick(False, {W.DEPARTED}),
            "out_for_delivery": pick(False, {W.AT_DESTINATION_HUB, W.OUT_FOR_DELIVERY}),
            "for_collection": pick(False, {W.READY_FOR_COLLECTION}),
        }

    async def hubs(self, principal: Principal) -> list[dict[str, Any]]:
        require(principal, Permission.HUB_OPERATE)
        net = await self.network()
        return [{**_hub_view(h), "city_name": net.city_name(h.city)} for h in net.hubs]

    async def receive(self, principal: Principal, data: HubScanInput) -> dict[str, Any]:
        """The origin hub takes the package in: completes a first-mile rider job; the waybill goes in transit."""
        require(principal, Permission.HUB_OPERATE)
        hub, parent = await self._hub_and_waybill(data.hub_id, data.tracking_code)
        w = parent.waybill
        assert w is not None
        if w.origin_hub_id != hub.id:
            raise ValidationFailed(f"This package is booked into {w.origin_hub_name}")
        if parent.status != S.PAID or w.stage not in EARLY_STAGES:
            raise InvalidTransition(f"Waybill {w.tracking_code}: {stage_label(w)}")
        now = utcnow()
        leg = await self.repos.orders.get(w.first_mile_order_id) if w.first_mile_order_id else None
        if leg is not None and leg.status in (S.PICKED_UP, S.IN_TRANSIT):
            await self.orders.transition(
                leg.id,
                S.DELIVERED,
                actor_type=A.STAFF,
                actor_id=principal.uid,
                reason=f"Received at {hub.name}",
                patch={"delivered_at": now},
            )
        elif leg is not None and leg.status in (S.DRAFT, S.READY_FOR_PICKUP, S.RIDER_ASSIGNED):
            await self.orders.transition(
                leg.id,
                S.CANCELLED,
                actor_type=A.STAFF,
                actor_id=principal.uid,
                reason="Sender brought the package to the hub",
                patch={"cancelled_at": now, "cancellation_reason": "dropped_at_hub"},
            )
        updated = await self.orders.transition(
            parent.id,
            S.IN_TRANSIT,
            actor_type=A.STAFF,
            actor_id=principal.uid,
            reason=f"Received at {hub.name}",
            patch=self._milestone_patch(W.AT_ORIGIN_HUB, hub.id),
            check=self._expect(S.PAID, EARLY_STAGES),
        )
        await self._notify(
            updated,
            "At the hub",
            f"Your package is at {hub.name} and leaves on the next departure to {w.destination_city_name}.",
        )
        return self._hub_item(updated)

    async def depart(self, principal: Principal, data: DepartInput) -> dict[str, Any]:
        """Packages leave the origin hub with a carrier (one trip reference for the whole load)."""
        require(principal, Permission.HUB_OPERATE)
        net = await self.network()
        hub = net.hub(data.hub_id)
        if hub is None:
            raise NotFound("Hub not found")
        departed: list[str] = []
        skipped: list[dict[str, str]] = []
        for code in dict.fromkeys(c.strip().upper() for c in data.tracking_codes):
            try:
                parent = await self._by_code(code)
            except NotFound:
                skipped.append({"tracking_code": code, "reason": "Not found"})
                continue
            w = parent.waybill
            assert w is not None
            if w.origin_hub_id != hub.id or w.stage != W.AT_ORIGIN_HUB or parent.status != S.IN_TRANSIT:
                skipped.append({"tracking_code": code, "reason": stage_label(w)})
                continue
            updated = await self._milestone(
                parent.id,
                W.DEPARTED,
                hub_id=hub.id,
                note=f"Trip {data.trip_reference}",
                allowed={W.AT_ORIGIN_HUB},
                extra={"trip_reference": data.trip_reference},
            )
            if updated is None:
                skipped.append({"tracking_code": code, "reason": "Already departed"})
                continue
            departed.append(code)
            await self._notify(
                updated,
                "On the way",
                f"Your package left {hub.name} for {w.destination_city_name}. Expected {eta_text(w)}.",
            )
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="waybills.departed",
            resource_type="hub",
            resource_id=hub.id,
            details={"trip_reference": data.trip_reference, "departed": departed, "skipped": skipped},
        )
        return {"departed": departed, "skipped": skipped}

    async def arrive(self, principal: Principal, data: HubScanInput) -> dict[str, Any]:
        """The destination hub takes the package in: door delivery is dispatched, or collection opens."""
        require(principal, Permission.HUB_OPERATE)
        hub, parent = await self._hub_and_waybill(data.hub_id, data.tracking_code)
        w = parent.waybill
        assert w is not None
        if w.destination_hub_id != hub.id:
            raise ValidationFailed(f"This package is going to {w.destination_hub_name}")
        updated = await self._milestone(parent.id, W.AT_DESTINATION_HUB, hub_id=hub.id, allowed={W.DEPARTED})
        if updated is None:
            raise InvalidTransition(f"Waybill {w.tracking_code}: {stage_label(w)}")
        if w.last_mile == "door":
            await self._start_leg(updated, "last_mile")
            await self._notify(
                updated,
                f"Arrived in {w.destination_city_name}",
                f"A rider will deliver your package to {w.recipient.name}. They need the delivery code from your app.",
            )
        else:
            ready = await self._milestone(
                parent.id, W.READY_FOR_COLLECTION, hub_id=hub.id, allowed={W.AT_DESTINATION_HUB}
            )
            updated = ready or updated
            await self._notify(
                updated,
                "Ready for collection",
                f"{w.recipient.name} can collect the package at {hub.name} ({hub.hours}) with the collection code "
                "from your app.",
            )
        return self._hub_item(await self.orders.get(parent.id))

    async def collect(self, principal: Principal, data: CollectInput) -> dict[str, Any]:
        """The recipient collects at the destination hub with the collection code."""
        require(principal, Permission.HUB_OPERATE)
        hub, parent = await self._hub_and_waybill(data.hub_id, data.tracking_code)
        w = parent.waybill
        assert w is not None
        if w.destination_hub_id != hub.id:
            raise ValidationFailed(f"This package is collected at {w.destination_hub_name}")
        if parent.status != S.IN_TRANSIT or w.stage != W.READY_FOR_COLLECTION:
            raise InvalidTransition(f"Waybill {w.tracking_code}: {stage_label(w)}")
        await self.orders.verify_code(parent.id, "pickup_code", data.code)
        updated = await self._deliver(
            parent,
            actor=A.STAFF,
            actor_id=principal.uid,
            reason=f"Collected at {hub.name}",
            note=f"Collected at {hub.name}",
            allowed={W.READY_FOR_COLLECTION},
        )
        return self._hub_item(updated)

    # ============================================================================ public tracking
    async def track(self, tracking_code: str) -> dict[str, Any]:
        """Public tracking by number: progress only (no names, phones or addresses)."""
        order = await self._by_code(tracking_code.strip().upper())
        w = order.waybill
        assert w is not None
        net = await self.network()

        def place(hub_id: str | None) -> str | None:
            hub = net.hub(hub_id) if hub_id else None
            return hub.name if hub else None

        collection = None
        if w.last_mile == "collect":
            collection = {
                "name": w.destination_hub_name,
                "address": w.destination_hub_address,
                "hours": w.destination_hub_hours,
            }
        return {
            "tracking_code": w.tracking_code,
            "origin": w.origin_city_name,
            "destination": w.destination_city_name,
            "stage": w.stage.value if w.stage else None,
            "label": stage_label(w)
            if order.status not in (S.REFUND_PENDING, S.REFUNDED, S.CANCELLED)
            else "Cancelled",
            "step": stage_step(w),
            "steps": list(WAYBILL_STEPS),
            "eta_from": w.eta_from.isoformat(),
            "eta_to": w.eta_to.isoformat(),
            "eta_text": eta_text(w),
            "last_mile": w.last_mile,
            "collection_point": collection,
            "milestones": [
                {
                    "stage": m.stage.value,
                    "label": stage_label(w, m.stage),
                    "at": m.at,
                    "place": place(m.hub_id),
                }
                for m in w.milestones
            ],
            "delivered": order.status in (S.DELIVERED, S.COMPLETED),
        }

    # ============================================================================ configuration
    async def get_config(self, principal: Principal) -> WaybillNetwork:
        require(principal, Permission.CONFIG_READ)
        return await self.network()

    async def save_config(self, principal: Principal, network: WaybillNetwork) -> WaybillNetwork:
        require(principal, Permission.CONFIG_WRITE)
        current = await self.network()
        for lane in network.lanes:
            if network.city(lane.origin_city) is None or network.city(lane.destination_city) is None:
                raise ValidationFailed(f"Lane {lane.id} uses an unknown city")
            if network.carrier(lane.carrier_id) is None:
                raise ValidationFailed(f"Lane {lane.id} uses an unknown carrier")
            if set(lane.base_by_size_kobo) != set(network.max_kg_by_size):
                raise ValidationFailed(f"Lane {lane.id} needs a price for every package size")
        for hub in network.hubs:
            if network.city(hub.city) is None:
                raise ValidationFailed(f"Hub {hub.id} is in an unknown city")
        updated = network.model_copy(update={"version": current.version + 1})
        await self.repos.save_waybill_network(updated)
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="config.waybill_network_updated",
            resource_type="config",
            resource_id="logistics",
            details={"from_version": current.version, "to_version": updated.version},
        )
        return updated

    # ============================================================================ helpers
    async def _by_code(self, tracking_code: str) -> Order:
        if not re.fullmatch(TRACKING_PATTERN, tracking_code):  # also keeps "/" out of the document path
            raise NotFound("Tracking number not found")
        doc = await self.repos.store.get(self.repos.waybill_code_path(tracking_code))
        order = await self.repos.orders.get(str(doc["order_id"])) if doc else None
        if order is None or order.waybill is None:
            raise NotFound("Tracking number not found")
        return order

    async def _hub_and_waybill(self, hub_id: str, tracking_code: str) -> tuple[Hub, Order]:
        net = await self.network()
        hub = net.hub(hub_id)
        if hub is None:
            raise NotFound("Hub not found")
        return hub, await self._by_code(tracking_code)

    def _hub_item(self, order: Order) -> dict[str, Any]:
        """What hub staff need to handle a package (names and phones to check people; no prices)."""
        w = order.waybill
        assert w is not None
        return {
            "order_id": order.id,
            "tracking_code": w.tracking_code,
            "status": order.status.value,
            "stage": w.stage.value if w.stage else None,
            "label": stage_label(w),
            "origin": w.origin_city_name,
            "destination": w.destination_city_name,
            "first_mile": w.first_mile,
            "last_mile": w.last_mile,
            "size": w.size.value,
            "weight_kg": w.weight_kg,
            "category": w.category,
            "description": w.description,
            "sender": {"name": w.sender.name, "phone": w.sender.phone},
            "recipient": {"name": w.recipient.name, "phone": w.recipient.phone},
            "cod_amount_kobo": w.cod_amount_kobo,
            "carrier": w.carrier_name,
            "trip_reference": w.trip_reference,
            "eta_text": eta_text(w),
            "updated_at": order.updated_at,
        }

    @staticmethod
    def _expect(status: OrderStatus, stages: set[WaybillStage]) -> Callable[[Order], None]:
        def check(o: Order) -> None:
            if o.status != status or o.waybill is None or o.waybill.stage not in stages:
                label = stage_label(o.waybill) if o.waybill else o.status.value
                raise InvalidTransition(f"Waybill is {label.lower()}")

        return check

    @staticmethod
    def _milestone_patch(
        stage: WaybillStage, hub_id: str | None, note: str | None = None
    ) -> Callable[[Order], dict[str, Any]]:
        def patch(o: Order) -> dict[str, Any]:
            assert o.waybill is not None
            w = o.waybill
            milestone = WaybillMilestone(stage=stage, at=utcnow(), hub_id=hub_id, note=note)
            return {
                "waybill": to_doc(
                    w.model_copy(update={"stage": stage, "milestones": [*w.milestones, milestone]})
                )
            }

        return patch

    async def _milestone(
        self,
        order_id: str,
        stage: WaybillStage,
        *,
        hub_id: str | None,
        allowed: set[WaybillStage | None],
        note: str | None = None,
        extra: dict[str, Any] | None = None,
    ) -> Order | None:
        """Record progress that doesn't change the order status. Returns None if the waybill isn't in `allowed`
        (so repeated events are harmless)."""
        now = utcnow()

        async def fn(tx: Transaction) -> Order | None:
            doc = await tx.get(f"orders/{order_id}")
            if doc is None:
                return None
            order = Order.model_validate(doc)
            w = order.waybill
            if w is None or w.stage not in allowed:
                return None
            milestone = WaybillMilestone(stage=stage, at=now, hub_id=hub_id, note=note)
            new_w = w.model_copy(
                update={"stage": stage, "milestones": [*w.milestones, milestone], **(extra or {})}
            )
            tx.update(f"orders/{order_id}", {"waybill": to_doc(new_w), "updated_at": now})
            return order.model_copy(update={"waybill": new_w, "updated_at": now})

        return await self.repos.store.run_transaction(fn)

    async def _deliver(
        self,
        parent: Order,
        *,
        actor: ActorType,
        actor_id: str,
        reason: str | None,
        note: str,
        allowed: set[WaybillStage],
    ) -> Order:
        milestone = self._milestone_patch(
            W.DELIVERED, parent.waybill.destination_hub_id if parent.waybill else None, note
        )
        now = utcnow()
        return await self.orders.transition(
            parent.id,
            S.DELIVERED,
            actor_type=actor,
            actor_id=actor_id,
            reason=reason,
            patch=lambda o: {**milestone(o), "delivered_at": now},
            check=self._expect(S.IN_TRANSIT, allowed),
        )

    async def _start_leg(self, parent: Order, kind: WaybillLegKind) -> Order:
        """Create a rider job for the first or last mile (idempotent: one per waybill and kind) and dispatch it."""
        w = parent.waybill
        assert w is not None
        net = await self.network()
        cfg = await self.repos.get_pricing_config()
        first = kind == "first_mile"
        hub = net.hub(w.origin_hub_id if first else w.destination_hub_id)
        if hub is None:
            raise NotFound("Hub not found")
        if first:
            pickup = _party_stop(w.sender, w.origin_city_name)
            dropoff = _hub_stop(
                hub, w.origin_city_name, f"Waybill {w.tracking_code}: hand it to the hub staff"
            )
        else:
            pickup = _hub_stop(
                hub, w.destination_city_name, f"Waybill {w.tracking_code}: collect it from the hub staff"
            )
            dropoff = _party_stop(w.recipient, w.destination_city_name)
        leg_id = f"{parent.id}-{'fm' if first else 'lm'}"
        distance = haversine_km(pickup.location, dropoff.location)
        now = utcnow()
        leg = Order(
            id=leg_id,
            short_code=short_code(),
            vertical=Vertical.PARCEL,
            customer_id=parent.customer_id,
            customer_name=parent.customer_name,
            customer_phone=parent.customer_phone,
            restaurant_id=PARCEL_MERCHANT_ID,
            restaurant_name=f"Waybill {w.tracking_code} ({'to' if first else 'from'} the hub)",
            restaurant_location=pickup.location,
            restaurant_address=", ".join(x for x in (pickup.line1, pickup.area, pickup.city) if x),
            status=S.DRAFT,
            fulfillment=Fulfillment.DELIVERY,
            lines=[],
            breakdown=PriceBreakdown(subtotal_kobo=0, total_kobo=0),
            settlement=SettlementTerms(
                commission_bps=0,
                commission_kobo=0,
                rider_pay_kobo=parcel_rider_pay(distance, w.size, cfg),
                restaurant_earning_kobo=0,
            ),
            delivery_address=DeliveryAddress(
                label=("Hub" if first else f"Recipient: {dropoff.name}")[:40],
                line1=dropoff.line1,
                area=dropoff.area,
                city=dropoff.city,
                state=dropoff.city,
                location=dropoff.location,
                instructions=dropoff.instructions,
                contact_phone=dropoff.phone,
            ),
            distance_km=round(distance, 3),
            quote_id=parent.quote_id,
            payment=PaymentSummary(provider="internal", status="unpaid"),
            channel=parent.channel,
            parcel=ParcelDetails(
                pickup=pickup,
                dropoff=dropoff,
                size=w.size,
                category=w.category,
                description=w.description or f"Waybill {w.tracking_code}",
                city=w.origin_city if first else w.destination_city,
                cod_amount_kobo=None if first else w.cod_amount_kobo,
            ),
            leg_of=parent.id,
            leg_kind=kind,
            created_at=now,
            updated_at=now,
        )
        event = OrderEvent(
            id=uuid.uuid4().hex,
            order_id=leg_id,
            from_status=None,
            to_status=S.DRAFT,
            actor_type=A.SYSTEM,
            actor_id="waybills",
            at=now,
            metadata={"leg_of": parent.id, "leg": kind},
        )
        field = "first_mile_order_id" if first else "last_mile_order_id"

        async def fn(tx: Transaction) -> bool:
            if await tx.get(f"orders/{leg_id}") is not None:
                return False
            tx.create(f"orders/{leg_id}", to_doc(leg))
            tx.create(f"order_events/{event.id}", to_doc(event))
            tx.update(f"orders/{parent.id}", {f"waybill.{field}": leg_id})
            return True

        if not await self.repos.store.run_transaction(fn):
            existing = await self.repos.orders.get(leg_id)
            assert existing is not None
            return existing
        parent_codes = await self.repos.store.get(self.repos.codes_path(parent.id)) or {}
        await self.repos.store.set(
            self.repos.codes_path(leg_id),
            {
                "order_id": leg_id,
                "customer_id": parent.customer_id,
                # The recipient gives the rider the waybill's delivery code (shared by the sender).
                "delivery_code": parent_codes.get("delivery_code") or new_code(),
                "pickup_code": new_code(),
                "attempts": 0,
                "locked": False,
            },
        )
        return await self.orders.transition(
            leg_id,
            S.READY_FOR_PICKUP,
            actor_type=A.SYSTEM,
            actor_id="waybills",
            patch={"ready_at": now},
            metadata={"leg_of": parent.id, "leg": kind},
        )

    async def _notify(self, order: Order, title: str, body: str) -> None:
        await self.notifier.notify_user(
            order.customer_id, title, body, {"order_id": order.id, "screen": "order"}
        )
