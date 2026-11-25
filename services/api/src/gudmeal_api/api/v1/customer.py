"""Authenticated customer endpoints: profile, quotes, orders, payments, reviews, support, meal plans."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Header, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from ...domain.models import CartLine, DeliveryAddress, ParcelQuote, ParcelQuoteRequest, QuoteRequest
from ...errors import NotFound
from ...security.rbac import Permission
from ...services.engagement import (
    MealPlanInput,
    ProfileUpdate,
    RestaurantApplicationInput,
    ReviewInput,
    RiderApplicationInput,
    TicketInput,
)
from ..deps import Ctr, CurrentPrincipal, limit, run_idempotent
from ..serializers import order_view, quote_view

router = APIRouter(prefix="/v1", tags=["customer"])
IdemKey = Annotated[str | None, Header(alias="Idempotency-Key")]


class CreateOrderInput(BaseModel):
    quote_id: str
    contact_phone: str | None = Field(default=None, max_length=20)
    channel: Literal["app", "web", "ai_agent", "whatsapp"] = "app"


class CreateParcelInput(BaseModel):
    quote_id: str
    channel: Literal["app", "web", "ai_agent", "whatsapp"] = "app"


def parcel_quote_view(quote: ParcelQuote) -> dict[str, Any]:
    data = quote.model_dump(mode="json")
    data.pop("settlement", None)  # rider pay and margins are internal
    return data


class CheckoutInput(BaseModel):
    # None = card/transfer/USSD through the default gateway (with failover); "wallet" pays from the Yummy Chops
    # wallet; "cash" = pay on delivery (eligibility is checked by the server).
    provider: Literal["paystack", "flutterwave", "local_sandbox", "wallet", "cash"] | None = None


class MultiCheckoutInput(CheckoutInput):
    # A mixed cart: the customer's orders, one per shop, paid with one payment (ADR-0030).
    order_ids: list[str] = Field(min_length=1, max_length=10)


class ReasonInput(BaseModel):
    reason: str | None = Field(default=None, max_length=500)


class VerifyInput(BaseModel):
    reference: str = Field(min_length=6, max_length=100)


class FavouriteInput(BaseModel):
    favourite: bool


class DeviceInput(BaseModel):
    token: str = Field(min_length=10, max_length=4096)
    platform: Literal["android", "ios", "web"]


class ReorderInput(BaseModel):
    delivery_address: DeliveryAddress | None = None


# ---------------------------------------------------------------- identity & profile ------------
@router.get("/me")
async def me(principal: CurrentPrincipal) -> dict[str, Any]:
    return {
        "uid": principal.uid,
        "email": principal.email,
        "phone": principal.phone,
        "name": principal.name,
        "roles": sorted(principal.roles),
        "restaurant_roles": dict(principal.restaurant_roles),
        "permissions": sorted(p.value for p in principal.permissions()),
    }


@router.get("/me/profile")
async def get_profile(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.get(principal)


@router.patch("/me/profile")
async def update_profile(data: ProfileUpdate, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.update(principal, data)


@router.get("/me/addresses")
async def list_addresses(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.addresses(principal)


@router.post("/me/addresses", status_code=201)
async def add_address(data: DeliveryAddress, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.save_address(principal, data)


@router.put("/me/addresses/{address_id}")
async def update_address(address_id: str, data: DeliveryAddress, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.save_address(principal, data, address_id)


@router.delete("/me/addresses/{address_id}", status_code=204)
async def delete_address(address_id: str, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.profiles.delete_address(principal, address_id)


@router.put("/me/favourites/{restaurant_id}")
async def set_favourite(restaurant_id: str, data: FavouriteInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.toggle_favourite(principal, restaurant_id, data.favourite)


@router.post("/me/devices", status_code=204)
async def register_device(data: DeviceInput, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.profiles.register_device(principal, data.token, data.platform)


@router.get("/me/export")
async def export_data(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.export(principal, c.orders)


@router.get("/me/notifications")
async def notifications(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.repos.notifications.find(
        where=[("recipient_uid", "==", principal.uid)], order_by=[("created_at", "desc")], limit=50
    )


# ---------------------------------------------------------------- quotes & orders ---------------
@router.post("/quotes", status_code=201, dependencies=[Depends(limit("quote"))])
async def create_quote(req: QuoteRequest, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return quote_view(await c.quotes.create_quote(principal, req))


@router.get("/quotes/{quote_id}")
async def get_quote(quote_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return quote_view(await c.quotes.get_quote(principal, quote_id))


@router.post("/orders", status_code=201, dependencies=[Depends(limit("order_create"))])
async def create_order(
    data: CreateOrderInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        order = await c.orders.create_from_quote(
            principal, data.quote_id, channel=data.channel, contact_phone=data.contact_phone
        )
        return order_view(order, principal)

    return await run_idempotent(
        c,
        scope=f"orders.create:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.post("/parcels/quotes", status_code=201, dependencies=[Depends(limit("quote"))])
async def create_parcel_quote(req: ParcelQuoteRequest, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return parcel_quote_view(await c.parcels.create_quote(principal, req))


@router.get("/parcels/quotes/{quote_id}")
async def get_parcel_quote(quote_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return parcel_quote_view(await c.parcels.get_quote(principal, quote_id))


@router.post("/parcels", status_code=201, dependencies=[Depends(limit("order_create"))])
async def create_parcel(
    data: CreateParcelInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        order = await c.orders.create_parcel_order(
            principal, data.quote_id, parcels=c.parcels, channel=data.channel
        )
        return order_view(order, principal)

    return await run_idempotent(
        c,
        scope=f"parcels.create:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.get("/me/order-summary")
async def my_order_summary(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """Totals across all of the customer's paid orders (used by the Orders tab and Yummy)."""
    return await c.orders.summary_for_customer(principal.uid)


@router.get("/orders")
async def my_orders(
    c: Ctr, principal: CurrentPrincipal, limit_: Annotated[int, Query(alias="limit", ge=1, le=100)] = 20
) -> list[dict[str, Any]]:
    return [order_view(o, principal) for o in await c.orders.list_for_customer(principal.uid, limit_)]


@router.get("/orders/{order_id}")
async def get_order(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return order_view(await c.orders.get_for(principal, order_id), principal)


@router.get("/orders/{order_id}/events")
async def order_events(order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    events = await c.orders.events(principal, order_id)
    if principal.is_staff:
        return events
    # Customers, shops and riders see what happened and when; who on the team did it, their notes and the
    # internal details stay with staff.
    return [
        {
            "id": e.id,
            "order_id": e.order_id,
            "from_status": e.from_status,
            "to_status": e.to_status,
            "actor_type": e.actor_type,
            "reason": None if e.actor_type == "staff" else e.reason,
            "at": e.at,
        }
        for e in events
    ]


@router.get("/orders/{order_id}/codes")
async def order_codes(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.orders.customer_codes(principal, order_id)


LIVE_STATUSES = ("rider_assigned", "picked_up", "in_transit")


@router.get("/orders/{order_id}/tracking")
async def order_tracking(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """Live delivery map data. The rider's position is only shared while they are on this delivery."""
    order = await c.orders.get_for(principal, order_id)
    tracking = await c.repos.get_tracking(order_id) or {}
    # A shop sees how the delivery is going, but not where the rider is or the customer's exact pin (ADR-0028).
    sees_map = principal.uid in (order.customer_id, order.rider_id) or principal.can(
        Permission.ORDERS_READ_ALL
    )
    live = sees_map and order.status.value in LIVE_STATUSES and tracking.get("active", True)
    return {
        "order_id": order.id,
        "status": order.status.value,
        "rider_name": order.rider_name,
        "rider_location": tracking.get("rider_location") if live else None,
        "eta_minutes": tracking.get("eta_minutes") if order.status.value in LIVE_STATUSES else None,
        "eta_source": tracking.get("eta_source")  # "google" (measured) or "estimate"
        if order.status.value in LIVE_STATUSES
        else None,
        "route_polyline": tracking.get("route_polyline") if live else None,  # current leg, Google format
        "updated_at": tracking.get("updated_at"),
        "estimated_delivery_at": order.estimated_delivery_at,
        "pickup_location": order.restaurant_location,
        "dropoff_location": order.delivery_address.location if sees_map and order.delivery_address else None,
    }


@router.post("/orders/{order_id}/checkout", dependencies=[Depends(limit("checkout"))])
async def checkout(
    order_id: str, data: CheckoutInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.orders.checkout(
            principal, order_id, provider=data.provider, idempotency_key=str(idempotency_key)
        )

    return await run_idempotent(
        c, scope=f"orders.checkout:{order_id}", key=idempotency_key, payload=data.model_dump(), fn=run
    )


@router.post("/checkouts", dependencies=[Depends(limit("checkout"))])
async def checkout_many(
    data: MultiCheckoutInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    """Pay for several orders (a mixed cart, one order per shop) with one payment."""

    async def run() -> dict[str, Any]:
        return await c.orders.checkout_many(
            principal, data.order_ids, provider=data.provider, idempotency_key=str(idempotency_key)
        )

    return await run_idempotent(
        c,
        scope=f"orders.checkout_many:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
    )


@router.post("/orders/{order_id}/cancel")
async def cancel_order(
    order_id: str, data: ReasonInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return order_view(await c.orders.cancel_by_customer(principal, order_id, data.reason), principal)


@router.post("/orders/{order_id}/dispute")
async def dispute_order(
    order_id: str, data: ReasonInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return order_view(
        await c.orders.dispute(principal, order_id, data.reason or "Customer dispute"), principal
    )


@router.post("/orders/{order_id}/review", status_code=201)
async def review_order(order_id: str, data: ReviewInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.reviews.create(principal, order_id, data)


@router.post("/orders/{order_id}/reorder", status_code=201, dependencies=[Depends(limit("quote"))])
async def reorder(order_id: str, data: ReorderInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    order = await c.orders.get(order_id)
    if order.customer_id != principal.uid:
        raise NotFound("Order not found")
    req = QuoteRequest(
        restaurant_id=order.restaurant_id,
        lines=[
            CartLine(item_id=ln.item_id, quantity=ln.quantity, selections=ln.selections, notes=ln.notes)
            for ln in order.lines
        ],
        fulfillment=order.fulfillment,
        delivery_address=data.delivery_address or order.delivery_address,
    )
    return quote_view(await c.quotes.create_quote(principal, req))


# ---------------------------------------------------------------- payments --------------------
@router.post("/payments/verify", dependencies=[Depends(limit("payment_verify"))])
async def verify_payment(data: VerifyInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    view = await c.payments.verify_for_customer(principal, data.reference)
    view.pop("authorization_url", None)
    return view


@router.get("/orders/{order_id}/receipt")
async def order_receipt(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """The receipt of an order the customer paid for. `saved` says whether it is kept under "My receipts"
    (it is once the customer has printed it)."""
    return (await c.receipts.get(principal, order_id)).model_dump(mode="json")


@router.post("/orders/{order_id}/receipt")
async def print_receipt(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """The customer pressed PRINT: keep the receipt under "My receipts" and count the print."""
    return (await c.receipts.print(principal, order_id)).model_dump(mode="json")


@router.get("/receipts")
async def my_receipts(
    c: Ctr, principal: CurrentPrincipal, limit_: Annotated[int, Query(alias="limit", ge=1, le=100)] = 50
) -> list[dict[str, Any]]:
    """The receipts the customer has printed, newest first."""
    return [r.model_dump(mode="json") for r in await c.receipts.list(principal, limit_)]


@router.get("/orders/{order_id}/payments")
async def order_payments(order_id: str, c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    order = await c.orders.get(order_id)
    if order.customer_id != principal.uid:
        raise NotFound("Order not found")
    return await c.payments.payments_for_order(order_id)


# ---------------------------------------------------------------- AI-facing helpers -----------
@router.post("/meal-plans", dependencies=[Depends(limit("meal_plan"))])
async def meal_plans(data: MealPlanInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.meal_plans.plan(principal, data)


# ---------------------------------------------------------------- support & onboarding --------
@router.post("/support/tickets", status_code=201, dependencies=[Depends(limit("support"))])
async def open_ticket(data: TicketInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.support.open(principal, data)


@router.get("/support/tickets")
async def my_tickets(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.support.mine(principal)


@router.post("/applications/restaurant", status_code=201, dependencies=[Depends(limit("application"))])
async def apply_restaurant(data: RestaurantApplicationInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.applications.submit(principal, "restaurant", data)


@router.post("/applications/rider", status_code=201, dependencies=[Depends(limit("application"))])
async def apply_rider(data: RiderApplicationInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.applications.submit(principal, "rider", data)


@router.get("/applications/mine")
async def my_applications(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.applications.mine(principal)
