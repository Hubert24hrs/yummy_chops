"""Rider dispatch: offers with timeouts, acceptance, decline, manual assignment, rider availability & location."""

from __future__ import annotations

import logging
import math
import uuid
from dataclasses import replace
from datetime import UTC, datetime, timedelta
from typing import Any

from ..domain.dispatch import DispatchConfig, rank_riders
from ..domain.geo import GeoPoint, geohash_decode, geohash_encode, haversine_km
from ..domain.models import (
    AssignmentStatus,
    DeliveryAssignment,
    Fulfillment,
    Order,
    RiderProfile,
    RiderStatus,
)
from ..domain.order_state import ActorType, OrderStatus
from ..domain.trips import navigation_url, quickest_order
from ..errors import InvalidTransition, NotFound, PermissionDenied, ValidationFailed
from ..logging_setup import log_event
from ..maps import MapsService
from ..repositories import Repositories, Transaction, to_doc, valid_doc_id
from ..security.rbac import Permission, Principal, require, require_rider
from .infra import Emitter, Notifier, TaskQueue
from .orders import OrderService

logger = logging.getLogger(__name__)
S = OrderStatus
TASK_OFFER_TIMEOUT = "/internal/tasks/dispatch-offer-timeout"
TASK_DISPATCH_RETRY = "/internal/tasks/dispatch-retry"
DISPATCHABLE = {S.RESTAURANT_ACCEPTED, S.PREPARING, S.READY_FOR_PICKUP}
ACTIVE_DELIVERY = {S.RIDER_ASSIGNED, S.PICKED_UP, S.IN_TRANSIT}
#: Orders of a trip that a rider taking the trip's offer will collect (some shops may still have to accept theirs).
TRIP_JOINABLE = {S.PAID, S.SUBMITTED_TO_RESTAURANT, *DISPATCHABLE}
#: For ordering a trip's stops: road distance is about this much longer than straight, at this average speed.
ROAD_FACTOR = 1.35
AVG_KMH = 22.0
#: After this many rounds with nobody to ask, ops are alerted; dispatch keeps trying, just less often.
MAX_ATTEMPTS = 8
RETRY_SECONDS = 60
SLOW_RETRY_SECONDS = 120
#: A rider whose offer ran out (not declined) can be asked again after this long, so a small fleet never runs out.
REOFFER_AFTER = timedelta(minutes=5)
#: Each round with nobody close enough looks this much further from the pickup, up to MAX_PICKUP_RADIUS_KM.
RADIUS_STEP_KM = 3.0
MAX_PICKUP_RADIUS_KM = 30.0
#: Idle online riders are kept at this geohash precision (6 ≈ 1.2 km x 0.6 km cell), never more precisely.
COARSE_GEOHASH = 6
#: What is kept of where an offline rider with no delivery is: nothing (no tracking outside active deliveries).
NO_LOCATION: dict[str, Any] = {"last_location": None, "last_location_at": None, "geohash": None}
#: How often a live delivery's road ETA is re-measured (Routes calls cost money; pings arrive every few seconds).


def utcnow() -> datetime:
    return datetime.now(UTC)


def coarse_cell(point: GeoPoint) -> GeoPoint:
    """The centre of the coarse cell a point is in: all that is kept of an online rider who is not on a delivery."""
    lat, lng, _, _ = geohash_decode(geohash_encode(point.lat, point.lng, COARSE_GEOHASH))
    return GeoPoint(lat=round(lat, 5), lng=round(lng, 5))


class DispatchService:
    def __init__(
        self,
        repos: Repositories,
        orders: OrderService,
        *,
        tasks: TaskQueue,
        notifier: Notifier,
        emitter: Emitter,
        offer_timeout_seconds: int = 45,
        reoffer_after_seconds: int | None = None,
        config: DispatchConfig | None = None,
        rider_cash_limit_kobo: int = 5_000_000,
        maps: MapsService | None = None,
    ) -> None:
        self.repos = repos
        self.orders = orders
        self.tasks = tasks
        self.notifier = notifier
        self.emitter = emitter
        self.offer_timeout = offer_timeout_seconds
        self.reoffer_after = (
            REOFFER_AFTER if reoffer_after_seconds is None else timedelta(seconds=reoffer_after_seconds)
        )
        self.cfg = config or DispatchConfig()
        self.cash_limit = rider_cash_limit_kobo
        self.maps = maps or MapsService(None)
        self._route_refresh = timedelta(seconds=self.maps.live_refresh_seconds)

    # ============================================================================ rider self-service
    async def rider_profile(self, principal: Principal) -> RiderProfile:
        require_rider(principal)
        profile = await self.repos.riders.get(principal.uid)
        if profile is None:
            raise NotFound("Rider profile not found")
        return profile

    async def _active_deliveries(self, profile: RiderProfile) -> list[Order]:
        """The rider's deliveries in progress, read from the orders themselves (as `/v1/rider/deliveries` does):
        the profile's `active_order_ids` is a counter for the job limit and could miss an order (a large trip, or
        an order joining the trip while another one is being delivered)."""
        found = await self.orders.list_for_rider(profile.uid, list(ACTIVE_DELIVERY), limit=100)
        return sorted(found, key=lambda o: (o.created_at, o.id))

    async def set_availability(self, principal: Principal, online: bool) -> RiderProfile:
        profile = await self.rider_profile(principal)
        if online and profile.status != RiderStatus.ACTIVE:
            raise PermissionDenied("You can go online once the team has verified your KYC")
        changes: dict[str, Any] = {"is_online": online}
        if not online and not await self._active_deliveries(profile):
            changes.update(NO_LOCATION)  # with a delivery in progress it goes when that delivery ends
        await self.repos.riders.update(principal.uid, changes)
        if online and not profile.is_online:
            await self.sweep()  # jobs waiting for a rider are offered now, not at the next retry
        return profile.model_copy(update=changes)

    async def update_location(
        self, principal: Principal, point: GeoPoint, accuracy_m: float | None = None
    ) -> None:
        """Rider location pings, with privacy rules (no tracking outside active deliveries):

        * offline riders with no delivery are not tracked at all (pings are rejected);
        * online without a delivery, only a coarse cell (~600 m) is kept, enough to offer nearby jobs;
        * the precise position is stored and shown to the customer only during an active delivery, and for all
          of it: a rider who switches to offline on the way is still followed until that delivery ends.
        """
        profile = await self.rider_profile(principal)
        active = await self._active_deliveries(profile)
        if not profile.is_online and not active:
            raise InvalidTransition("Go online to share your location")
        now = utcnow()
        if active:
            stored, precision = point, 7
        else:
            stored, precision = coarse_cell(point), COARSE_GEOHASH
        was_stale = (
            profile.last_location_at is None
            or (now - profile.last_location_at).total_seconds() > self.cfg.max_location_age_seconds
        )
        await self.repos.riders.update(
            principal.uid,
            {
                "last_location": to_doc(stored),
                "last_location_at": now,
                "geohash": geohash_encode(stored.lat, stored.lng, precision),
            },
        )
        for order in active:
            await self._track(order, point, accuracy_m, now)
        if was_stale and not active:
            await self.sweep()  # the rider just became visible to dispatch again

    async def _track(self, order: Order, point: GeoPoint, accuracy_m: float | None, now: datetime) -> None:
        """Live tracking for the customer. Road ETAs are re-measured at most every few minutes (cost)."""
        prev = await self.repos.get_tracking(order.id) or {}
        target = (
            order.restaurant_location
            if order.status == S.RIDER_ASSIGNED
            else (order.delivery_address.location if order.delivery_address else None)
        )
        eta: int | None = None
        source: str | None = None
        polyline: str | None = None
        route_at = prev.get("route_at")
        if isinstance(route_at, str):
            route_at = datetime.fromisoformat(route_at)
        fresh = (
            route_at is not None
            and prev.get("leg") == order.status.value
            and now - route_at < self._route_refresh
            and prev.get("eta_minutes") is not None
        )
        if target is not None and fresh:
            elapsed = int((now - route_at).total_seconds() // 60)
            eta, source, polyline = (
                max(1, int(prev["eta_minutes"]) - elapsed),
                prev.get("eta_source"),
                prev.get("route_polyline"),
            )
        elif target is not None:
            cfg = await self.repos.get_pricing_config()
            leg = await self.maps.route(point, target, cfg)
            eta, source, polyline, route_at = leg.duration_minutes, leg.source, leg.polyline, now
            if order.status == S.RIDER_ASSIGNED and order.delivery_address and order.restaurant_location:
                onward = await self.maps.route(
                    order.restaurant_location, order.delivery_address.location, cfg
                )
                eta += onward.duration_minutes  # to the kitchen, then on to the door
        await self.repos.set_tracking(
            order.id,
            {
                "rider_location": to_doc(point),
                "updated_at": now,
                "status": order.status.value,
                "leg": order.status.value,
                "eta_minutes": eta,
                "eta_source": source,
                "route_polyline": polyline,
                "route_at": route_at,
                "accuracy_m": accuracy_m,
                "customer_id": order.customer_id,
                "active": True,
            },
        )

    async def pending_offers(self, principal: Principal) -> list[DeliveryAssignment]:
        require_rider(principal)
        offers = await self.repos.assignments.find(
            where=[("rider_id", "==", principal.uid), ("status", "==", AssignmentStatus.OFFERED.value)],
            limit=5,
        )
        now = utcnow()
        return [o for o in offers if o.expires_at > now]

    # ============================================================================ dispatch engine
    async def start(
        self, order_id: str, *, exclude: set[str] | None = None, count_round: bool = True
    ) -> DeliveryAssignment | None:
        """Offer the job to the best available rider. With nobody to ask, a counted round schedules the next try;
        an opportunistic look (`count_round=False`, from `sweep`) changes nothing: the scheduled try is still due."""
        order = await self.repos.orders.get(order_id)
        if order is None or order.fulfillment != Fulfillment.DELIVERY or order.status not in DISPATCHABLE:
            return None
        if order.rider_id:
            return None
        trip = await self.orders.trip_orders(order)
        previous = await self.repos.assignments.find(where=[("order_id", "==", order_id)])
        if len(trip) > 1:
            # One rider collects a mixed cart's orders (ADR-0031): the rider already on this trip takes this one too,
            # unless that rider had this order and handed it back (or can no longer take it): then it is offered as
            # usual.
            gave_back = (exclude or set()) | {
                a.rider_id
                for a in previous
                if a.status not in (AssignmentStatus.OFFERED, AssignmentStatus.EXPIRED)
            }
            on_trip = next(
                (
                    o
                    for o in trip
                    if o.rider_id and o.status in ACTIVE_DELIVERY and o.rider_id not in gave_back
                ),
                None,
            )
            if on_trip is not None and await self.join_trip(order, str(on_trip.rider_id)):
                return None
        open_offers = []
        for o in trip:  # an open offer for any order of the trip stands for the whole trip
            open_offers += await self.repos.assignments.find(
                where=[("order_id", "==", o.id), ("status", "==", AssignmentStatus.OFFERED.value)]
            )
        now = utcnow()
        if any(o.expires_at > now for o in open_offers):
            return None  # an offer is already outstanding
        if len(trip) > 1:
            # A trip offer is recorded on one of its orders: a rider who declined it (or let it run out) declined
            # this order too.
            known = {a.id for a in previous}
            previous += [
                a
                for a in await self.repos.assignments.find(
                    where=[("trip_order_ids", "array_contains", order_id)]
                )
                if a.id not in known and a.status in (AssignmentStatus.DECLINED, AssignmentStatus.EXPIRED)
            ]
        # Riders who declined or handed the job back are not asked again; a rider whose offer just ran out is
        # skipped for a while (they may be away from the phone), then asked again.
        excluded = (exclude or set()) | {
            a.rider_id
            for a in previous
            if a.status != AssignmentStatus.EXPIRED or now - a.expires_at < self.reoffer_after
        }
        riders = await self.repos.riders.find(
            where=[("is_online", "==", True), ("status", "==", RiderStatus.ACTIVE.value)], limit=500
        )
        # The whole trip: this order and the others of the cart still waiting for a rider (some shops may not have
        # accepted theirs yet; those join the rider's trip when they do).
        jobs = [order] + [
            o for o in trip if o.id != order.id and o.rider_id is None and o.status in TRIP_JOINABLE
        ]
        cash_due = sum(o.cash_to_collect_kobo for o in jobs)
        if cash_due:  # don't send riders out with more cash than they may carry (the whole trip's)
            riders = [r for r in riders if r.cash_held_kobo + cash_due <= self.cash_limit]
        # Nobody close enough last round (a small fleet, or a pickup far from every rider): look further each time.
        # Found on a phone test: a package picked up in Ajah never reached the only rider, 11.5 km away in Ikate.
        base = self.cfg.max_pickup_radius_km
        radius = min(base + RADIUS_STEP_KM * order.dispatch_attempts, max(base, MAX_PICKUP_RADIUS_KM))
        ranked = rank_riders(
            riders,
            restaurant_location=order.restaurant_location,
            delivery_distance_km=order.distance_km or 0.0,
            now=now,
            cfg=replace(self.cfg, max_pickup_radius_km=radius),
            exclude=excluded,
        )
        attempt = len(previous) + 1
        if not ranked:
            if not count_round:
                return None
            attempts = order.dispatch_attempts + 1
            await self.repos.orders.update(order_id, {"dispatch_attempts": attempts})
            if attempts == MAX_ATTEMPTS:  # alert ops once, but keep looking for a rider
                await self.emitter.emit(
                    "dispatch.unassigned", {"order_id": order_id, "attempts": attempts_label(order)}
                )
                log_event(logger, "dispatch exhausted", logging.WARNING, order_id=order_id)
            delay = RETRY_SECONDS if attempts < MAX_ATTEMPTS else SLOW_RETRY_SECONDS
            # A rider who missed the offer can be asked again soon: come back as soon as that wait is over.
            waits = [
                (self.reoffer_after - (now - a.expires_at)).total_seconds()
                for a in previous
                if a.status == AssignmentStatus.EXPIRED and now - a.expires_at < self.reoffer_after
            ]
            if waits:
                delay = max(1, min(delay, math.ceil(min(waits))))
            await self.tasks.enqueue(TASK_DISPATCH_RETRY, {"order_id": order_id}, delay_seconds=delay)
            return None
        best = ranked[0]
        rider = next(r for r in riders if r.uid == best.rider_id)
        dropoff = order.delivery_address.location if order.delivery_address else order.restaurant_location
        planned = quickest_order(
            rider.last_location, jobs, dropoff, lambda o: o.restaurant_location, self._leg_cost
        )
        assignment = DeliveryAssignment(
            id=uuid.uuid4().hex,
            order_id=order_id,
            rider_id=best.rider_id,
            status=AssignmentStatus.OFFERED,
            attempt=attempt,
            score=best.score,
            distance_to_restaurant_km=best.distance_to_restaurant_km,
            restaurant_name=order.restaurant_name,
            pickup=order.restaurant_location,
            dropoff=order.delivery_address.location if order.delivery_address else None,
            dropoff_area=order.delivery_address.area if order.delivery_address else None,
            payout_kobo=sum(o.settlement.rider_pay_kobo for o in jobs),
            offered_at=now,
            expires_at=now + timedelta(seconds=self.offer_timeout),
            trip_order_ids=[o.id for o in jobs] if len(jobs) > 1 else [],
            pickups=[
                {
                    "order_id": o.id,
                    "name": o.restaurant_name,
                    "address": o.restaurant_address,
                    "location": to_doc(o.restaurant_location),
                }
                for o in planned
            ]
            if len(jobs) > 1
            else [],
        )
        await self.repos.assignments.create(assignment)
        await self.repos.riders.update(rider.uid, {"offers_received": rider.offers_received + 1})
        await self.tasks.enqueue(
            TASK_OFFER_TIMEOUT, {"assignment_id": assignment.id}, delay_seconds=self.offer_timeout
        )
        await self.notifier.notify_user(
            best.rider_id,
            "New delivery offer",
            f"Pickup at {order.restaurant_name} · {best.distance_to_restaurant_km} km away"
            if len(jobs) == 1
            else f"{len(jobs)} pickups ({', '.join(o.restaurant_name for o in planned)}) · one customer",
            {"assignment_id": assignment.id, "order_id": order_id},
        )
        return assignment

    async def accept_offer(self, principal: Principal, assignment_id: str) -> Order:
        require_rider(principal)
        if not valid_doc_id(assignment_id):
            raise NotFound("Offer not found")
        now = utcnow()
        captured: dict[str, Any] = {}

        async def fn(tx: Transaction) -> Order:
            adoc = await tx.get(f"delivery_assignments/{assignment_id}")
            if adoc is None:
                raise NotFound("Offer not found")
            assignment = DeliveryAssignment.model_validate(adoc)
            if assignment.rider_id != principal.uid:
                raise NotFound("Offer not found")
            odoc = await tx.get(f"orders/{assignment.order_id}")
            rdoc = await tx.get(f"rider_profiles/{principal.uid}")
            if odoc is None or rdoc is None:
                raise NotFound("Order not found")
            order = Order.model_validate(odoc)
            rider = RiderProfile.model_validate(rdoc)
            if rider.status != RiderStatus.ACTIVE:
                # Suspended (or KYC turned down) after the offer went out: the same test going online uses.
                raise PermissionDenied(
                    "Your rider account is not active, so you cannot take deliveries. Please contact support."
                )
            if assignment.status != AssignmentStatus.OFFERED or assignment.expires_at <= now:
                raise InvalidTransition("This offer is no longer available")
            if order.rider_id:
                raise InvalidTransition("This order already has a rider")
            others = [o for o in rider.active_order_ids if o not in assignment.trip_order_ids]
            if len(others) >= self.cfg.max_active_deliveries:
                raise InvalidTransition("You have reached the maximum number of active deliveries")
            updates, event = OrderService.build_transition(
                order,
                S.RIDER_ASSIGNED,
                actor_type=ActorType.SYSTEM,
                actor_id="dispatch",
                patch={"rider_id": rider.uid, "rider_name": rider.name, "assignment_id": assignment.id},
                metadata={"rider_id": rider.uid, "assignment_id": assignment.id},
                now=now,
            )
            OrderService.write_transition(tx, order.id, updates, event)
            tx.update(
                f"delivery_assignments/{assignment.id}",
                {"status": AssignmentStatus.ACCEPTED.value, "responded_at": now},
            )
            accepted = rider.offers_accepted + 1
            tx.update(
                f"rider_profiles/{rider.uid}",
                {
                    "active_order_ids": [*rider.active_order_ids, order.id],
                    "offers_accepted": accepted,
                    "acceptance_rate": round(accepted / max(1, rider.offers_received), 3),
                },
            )
            captured.update(
                previous=order.status,
                event=event,
                trip=[i for i in assignment.trip_order_ids if i != order.id],
            )
            return Order.model_validate({**order.model_dump(), **updates})

        order = await self.repos.store.run_transaction(fn)
        await self.orders.after_transition(order, captured["previous"], captured["event"])
        await self.notifier.notify_restaurant(
            order.restaurant_id,
            "Rider assigned",
            f"{order.rider_name} is coming for order {order.short_code}",
            {"order_id": order.id},
        )
        # The offer was for the whole trip: the trip's other orders that are ready for a rider are theirs now
        # (the rest join when their shops accept them).
        for other_id in captured["trip"]:
            other = await self.repos.orders.get(other_id)
            if other is not None and other.rider_id is None and other.status in DISPATCHABLE:
                await self.join_trip(other, principal.uid, notify=False)
        return order

    async def decline_offer(self, principal: Principal, assignment_id: str, reason: str | None) -> None:
        require_rider(principal)
        assignment = await self.repos.assignments.get(assignment_id)
        if assignment is None or assignment.rider_id != principal.uid:
            raise NotFound("Offer not found")
        if not await self._close_offer(assignment_id, AssignmentStatus.DECLINED, reason):
            return
        rider = await self.repos.riders.get(principal.uid)
        if rider:
            await self.repos.riders.update(
                rider.uid,
                {"acceptance_rate": round(rider.offers_accepted / max(1, rider.offers_received), 3)},
            )
        await self._restart(assignment)

    async def _close_offer(
        self, assignment_id: str, status: AssignmentStatus, reason: str | None = None
    ) -> bool:
        now = utcnow()

        async def fn(tx: Transaction) -> bool:
            doc = await tx.get(f"delivery_assignments/{assignment_id}")
            if doc is None or doc.get("status") != AssignmentStatus.OFFERED.value:
                return False
            tx.update(
                f"delivery_assignments/{assignment_id}",
                {"status": status.value, "responded_at": now, "decline_reason": reason},
            )
            return True

        return await self.repos.store.run_transaction(fn)

    async def handle_offer_timeout(self, payload: dict[str, Any]) -> None:
        assignment = await self.repos.assignments.get(str(payload["assignment_id"]))
        if assignment is None or assignment.status != AssignmentStatus.OFFERED:
            return
        if await self._close_offer(assignment.id, AssignmentStatus.EXPIRED):
            await self._restart(assignment)

    async def _restart(self, assignment: DeliveryAssignment) -> None:
        """An offer was closed without a rider: look again for its order and, for a trip offer, for every order of
        the trip. The others waited for this offer with no retry of their own, and its own order may be gone
        (cancelled while the offer was out); `start` makes one offer for the trip and skips the rest."""
        for order_id in dict.fromkeys([assignment.order_id, *assignment.trip_order_ids]):
            await self.start(order_id)

    async def _withdraw_offers(self, order_id: str) -> None:
        """The order was called off before any rider took it: its open offer goes, and the rest of its trip (which
        waited for that offer) is offered again."""
        offers = await self.repos.assignments.find(
            where=[("order_id", "==", order_id), ("status", "==", AssignmentStatus.OFFERED.value)]
        )
        for offer in offers:
            if await self._close_offer(offer.id, AssignmentStatus.CANCELLED, "order called off"):
                for other_id in offer.trip_order_ids:
                    if other_id != order_id:
                        await self.start(other_id)

    async def retry(self, payload: dict[str, Any]) -> None:
        await self.start(str(payload["order_id"]))

    async def sweep(self) -> int:
        """Offer jobs still waiting for a rider right away (a rider came online, became visible again or finished a
        delivery) instead of at the next retry. Returns how many offers were made."""
        waiting: list[Order] = []
        for status in DISPATCHABLE:
            waiting += await self.repos.orders.find(where=[("status", "==", status.value)], limit=100)
        offers = 0
        for order in sorted(waiting, key=lambda o: o.created_at):
            if (
                order.rider_id is None
                and order.fulfillment == Fulfillment.DELIVERY
                # An extra look between scheduled tries: it must not add tries or count as a round.
                and await self.start(order.id, count_round=False)
            ):
                offers += 1
        return offers

    async def shop_phone(self, restaurant_id: str) -> str | None:
        """The number a rider calls at a shop: the branch manager's, else the shop's, else its business's."""
        shop = await self.repos.restaurants.get(restaurant_id)
        if shop is None:
            return None
        if shop.manager_phone or shop.phone:
            return shop.manager_phone or shop.phone
        business = await self.repos.businesses.get(shop.business_id) if shop.business_id else None
        return business.phone if business else None

    async def rider_trips(self, principal: Principal) -> list[dict[str, Any]]:
        """The rider's work as planned trips (ADR-0031): the shops still to visit in the quickest order (measured
        road times when the server has them), then the customer, with each place's phone and what to collect."""
        profile = await self.rider_profile(principal)
        active = await self._active_deliveries(profile)
        if not active:
            return []
        cfg = await self.repos.get_pricing_config()
        groups: dict[str, list[Order]] = {}
        for o in sorted(active, key=lambda o: o.created_at):
            groups.setdefault(o.trip_id or o.id, []).append(o)
        here = profile.last_location
        trips = []
        for trip_id, orders in groups.items():
            first = orders[0]
            dropoff = first.delivery_address.location if first.delivery_address else first.restaurant_location
            done = [o for o in orders if o.status != S.RIDER_ASSIGNED]
            todo = quickest_order(
                here,
                [o for o in orders if o.status == S.RIDER_ASSIGNED],
                dropoff,
                lambda o: o.restaurant_location,
                self._leg_cost,
            )
            stops: list[dict[str, Any]] = []
            for o in [*done, *todo]:
                stops.append(
                    {
                        "kind": "pickup",
                        "order_id": o.id,
                        "short_code": o.short_code,
                        "name": o.restaurant_name,
                        "vertical": o.vertical.value,
                        "address": o.restaurant_address,
                        "location": to_doc(o.restaurant_location),
                        "phone": await self.shop_phone(o.restaurant_id),
                        "items": [
                            {"name": ln.name, "quantity": ln.quantity, "options": ln.selection_labels}
                            for ln in o.lines
                        ],
                        "status": o.status.value,
                        "ready": o.ready_at is not None,
                        "done": o.status != S.RIDER_ASSIGNED,
                    }
                )
            address = first.delivery_address
            stops.append(
                {
                    "kind": "dropoff",
                    "order_ids": [o.id for o in orders],
                    "name": first.customer_name,
                    "address": (", ".join(p for p in (address.line1, address.area) if p) or None)
                    if address
                    else None,
                    "location": to_doc(dropoff),
                    "phone": (address.contact_phone if address else None) or first.customer_phone,
                    "instructions": address.instructions if address else None,
                    "cash_to_collect_kobo": sum(o.cash_to_collect_kobo for o in orders),
                    "done": False,
                }
            )
            # How long each remaining leg takes, from where the rider is now (measured by Google when available).
            remaining = [s for s in stops if not s["done"]]
            total_km = total_min = 0.0
            source = "estimate"
            prev = here
            for stop in remaining:
                point = GeoPoint.model_validate(stop["location"])
                if prev is not None:
                    leg = await self.maps.route(prev, point, cfg)
                    stop["leg_km"] = round(leg.distance_km, 1)
                    stop["leg_minutes"] = leg.duration_minutes
                    total_km += leg.distance_km
                    total_min += leg.duration_minutes
                    if leg.source != "estimate":
                        source = str(leg.source)
                prev = point
            trips.append(
                {
                    "trip_id": trip_id,
                    "order_ids": [o.id for o in orders],
                    "stops": stops,
                    "next_stop": next((i for i, s in enumerate(stops) if not s["done"]), len(stops) - 1),
                    "total_km": round(total_km, 1),
                    "total_minutes": round(total_min),
                    "route_source": source,
                    "navigation_url": navigation_url(
                        [GeoPoint.model_validate(s["location"]) for s in remaining],
                        vehicle=profile.vehicle.value,
                    ),
                    "payout_kobo": sum(o.settlement.rider_pay_kobo for o in orders),
                }
            )
        return trips

    def _leg_cost(self, a: GeoPoint, b: GeoPoint) -> float:
        """Minutes for a leg by road estimate (to put a trip's stops in order)."""
        return haversine_km(a, b) * ROAD_FACTOR / AVG_KMH * 60

    async def join_trip(self, order: Order, rider_uid: str, *, notify: bool = True) -> Order | None:
        """Give an order of a mixed cart to the rider already doing its trip (ADR-0031): they agreed to every shop
        of the trip when they took the offer. Nothing happens if the rider can no longer take it."""
        rider = await self.repos.riders.get(rider_uid)
        if (
            rider is None
            or rider.status != RiderStatus.ACTIVE
            or order.rider_id
            or order.status not in DISPATCHABLE
        ):
            return None
        now = utcnow()
        assignment = DeliveryAssignment(
            id=uuid.uuid4().hex,
            order_id=order.id,
            rider_id=rider_uid,
            status=AssignmentStatus.ACCEPTED,
            attempt=0,
            score=0.0,
            distance_to_restaurant_km=round(haversine_km(rider.last_location, order.restaurant_location), 2)
            if rider.last_location
            else 0.0,
            restaurant_name=order.restaurant_name,
            pickup=order.restaurant_location,
            dropoff=order.delivery_address.location if order.delivery_address else None,
            dropoff_area=order.delivery_address.area if order.delivery_address else None,
            payout_kobo=order.settlement.rider_pay_kobo,
            offered_at=now,
            expires_at=now,
            responded_at=now,
        )
        await self.repos.assignments.create(assignment)

        def still_free(current: Order) -> None:
            if current.rider_id:
                raise InvalidTransition("This order already has a rider")

        try:
            updated = await self.orders.transition(
                order.id,
                S.RIDER_ASSIGNED,
                actor_type=ActorType.SYSTEM,
                actor_id="dispatch",
                patch={"rider_id": rider_uid, "rider_name": rider.name, "assignment_id": assignment.id},
                metadata={"rider_id": rider_uid, "trip_id": order.trip_id},
                check=still_free,
            )
        except InvalidTransition:
            await self.repos.assignments.update(assignment.id, {"status": AssignmentStatus.CANCELLED.value})
            return None

        async def add_job(tx: Transaction) -> None:
            # In a transaction: a delivery finishing at the same moment must not write the list back without it.
            doc = await tx.get(f"rider_profiles/{rider_uid}")
            active = list((doc or {}).get("active_order_ids") or [])
            if doc is not None and order.id not in active:
                tx.update(f"rider_profiles/{rider_uid}", {"active_order_ids": [*active, order.id]})

        await self.repos.store.run_transaction(add_job)
        await self.notifier.notify_restaurant(
            order.restaurant_id,
            "Rider assigned",
            f"{rider.name} is coming for order {order.short_code}",
            {"order_id": order.id},
        )
        if notify:
            await self.notifier.notify_user(
                rider_uid,
                "Another pickup on your trip",
                f"Collect order {order.short_code} at {order.restaurant_name} too",
                {"order_id": order.id},
            )
        return updated

    async def manual_assign(self, principal: Principal, order_id: str, rider_uid: str, reason: str) -> Order:
        require(principal, Permission.DISPATCH_MANUAL)
        rider = await self.repos.riders.get(rider_uid)
        if rider is None or rider.status != RiderStatus.ACTIVE:
            raise ValidationFailed("Rider is not active")
        order = await self.orders.get(order_id)
        if order.rider_id:
            raise InvalidTransition("Order already has a rider; unassign first")
        now = utcnow()
        assignment = DeliveryAssignment(
            id=uuid.uuid4().hex,
            order_id=order_id,
            rider_id=rider_uid,
            status=AssignmentStatus.ACCEPTED,
            attempt=0,
            score=0.0,
            distance_to_restaurant_km=round(haversine_km(rider.last_location, order.restaurant_location), 2)
            if rider.last_location
            else 0.0,
            restaurant_name=order.restaurant_name,
            pickup=order.restaurant_location,
            dropoff=order.delivery_address.location if order.delivery_address else None,
            payout_kobo=order.settlement.rider_pay_kobo,
            offered_at=now,
            expires_at=now,
            responded_at=now,
        )
        await self.repos.assignments.create(assignment)
        updated = await self.orders.transition(
            order_id,
            S.RIDER_ASSIGNED,
            actor_type=ActorType.STAFF,
            actor_id=principal.uid,
            reason=reason,
            patch={"rider_id": rider_uid, "rider_name": rider.name, "assignment_id": assignment.id},
            metadata={"manual": True, "rider_id": rider_uid},
        )
        await self.repos.riders.update(rider_uid, {"active_order_ids": [*rider.active_order_ids, order_id]})
        await self.notifier.notify_user(
            rider_uid, "Delivery assigned", f"Pickup at {order.restaurant_name}", {"order_id": order_id}
        )
        return updated

    async def unassign(self, principal: Principal, order_id: str, reason: str) -> Order:
        """Rider can't complete (or ops reassigns): restore kitchen state and re-dispatch."""
        order = await self.orders.get(order_id)
        if order.rider_id is None or order.status != S.RIDER_ASSIGNED:
            raise InvalidTransition("Order has no rider to unassign before pickup")
        is_assigned_rider = principal.uid == order.rider_id
        if not is_assigned_rider:
            require(principal, Permission.DISPATCH_MANUAL)
        rider_id = order.rider_id
        target = S.READY_FOR_PICKUP if order.ready_at else S.PREPARING
        actor = ActorType.SYSTEM if is_assigned_rider else ActorType.STAFF
        updated = await self.orders.transition(
            order_id,
            target,
            actor_type=actor,
            actor_id=principal.uid,
            reason=reason,
            patch={"rider_id": None, "rider_name": None, "assignment_id": None},
            metadata={"unassigned_rider": rider_id},
        )
        if order.assignment_id:
            await self.repos.assignments.update(
                order.assignment_id, {"status": AssignmentStatus.CANCELLED.value, "decline_reason": reason}
            )
        await self.release_rider(rider_id, order_id, completed=False)
        await self.start(order_id, exclude={rider_id})
        return updated

    async def release_rider(self, rider_id: str, order_id: str, *, completed: bool) -> None:
        async def fn(tx: Transaction) -> None:
            doc = await tx.get(f"rider_profiles/{rider_id}")
            if doc is None:
                return
            rider = RiderProfile.model_validate(doc)
            remaining = [o for o in rider.active_order_ids if o != order_id]
            changes: dict[str, Any] = {"active_order_ids": remaining}
            if completed:
                changes["completed_deliveries"] = rider.completed_deliveries + 1
            if not remaining and rider.last_location is not None:
                # No delivery left: the exact position goes. An online rider keeps the coarse cell dispatch needs;
                # one who switched to offline on the way keeps nothing.
                if rider.is_online:
                    cell = coarse_cell(rider.last_location)
                    changes["last_location"] = to_doc(cell)
                    changes["geohash"] = geohash_encode(cell.lat, cell.lng, COARSE_GEOHASH)
                else:
                    changes.update(NO_LOCATION)
            tx.update(f"rider_profiles/{rider_id}", changes)

        await self.repos.store.run_transaction(fn)
        # The delivery session is over: stop showing where the rider is.
        prev = await self.repos.get_tracking(order_id)
        if prev:
            await self.repos.set_tracking(
                order_id,
                {
                    **{
                        k: v
                        for k, v in prev.items()
                        if k not in ("order_id", "rider_location", "route_polyline")
                    },
                    "rider_location": None,
                    "route_polyline": None,
                    "eta_minutes": None,
                    "active": False,
                    "updated_at": utcnow(),
                },
            )

    async def on_order_called_off(self, payload: dict[str, Any]) -> None:
        """Cancelled or refunded before delivery, or put under review by staff on the way (a dispute): free the
        rider, who could otherwise take no more jobs, and tell them."""
        if payload.get("from") not in (S.RIDER_ASSIGNED.value, S.PICKED_UP.value, S.IN_TRANSIT.value):
            await self._withdraw_offers(str(payload["order_id"]))
            return
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or not order.rider_id:
            return
        disputed = payload.get("to") == S.DISPUTED.value
        await self.release_rider(order.rider_id, order.id, completed=False)
        if order.assignment_id:
            await self.repos.assignments.update(
                order.assignment_id,
                {
                    "status": AssignmentStatus.CANCELLED.value,
                    "decline_reason": "order under review" if disputed else "order called off",
                },
            )
        if disputed:
            title = "Delivery stopped"
            body = f"Order {order.short_code} is being reviewed by support. Please contact support about what you are carrying."
        else:
            title = "Delivery cancelled"
            body = f"Order {order.short_code} was cancelled. Please contact support if you collected it."
        await self.notifier.notify_user(order.rider_id, title, body, {"order_id": order.id})

    async def on_order_delivered(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order and order.rider_id:
            await self.release_rider(order.rider_id, order.id, completed=True)
            if order.assignment_id:
                await self.repos.assignments.update(
                    order.assignment_id, {"status": AssignmentStatus.COMPLETED.value}
                )
            await self.sweep()  # the rider is free again: offer anything that is still waiting


def attempts_label(order: Order) -> int:
    return order.dispatch_attempts + 1
