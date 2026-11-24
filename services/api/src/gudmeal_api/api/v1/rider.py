"""Yummy Chops Rider endpoints."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Header
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field

from ...domain.geo import GeoPoint
from ...domain.order_state import OrderStatus
from ...security.rbac import require_rider
from ...services.rider_kyc import KycDetailsInput, KycUploadInput
from ..deps import Ctr, CurrentPrincipal, limit, run_idempotent
from ..serializers import order_view

router = APIRouter(prefix="/v1/rider", tags=["rider"])
ACTIVE = [OrderStatus.RIDER_ASSIGNED, OrderStatus.PICKED_UP, OrderStatus.IN_TRANSIT]


class AvailabilityInput(BaseModel):
    online: bool


class LocationInput(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    accuracy_m: float | None = Field(default=None, ge=0, le=5000)


class ReasonInput(BaseModel):
    reason: str | None = Field(default=None, max_length=300)


class DeliverInput(BaseModel):
    code: str = Field(pattern=r"^\d{4}$")
    # Required (true) when the order has cash to collect: pay on delivery and/or a package's COD amount.
    # The amount itself always comes from the server.
    cash_collected: bool = False


class PayoutInput(BaseModel):
    amount_kobo: int = Field(gt=0)


class EmergencyInput(BaseModel):
    description: str = Field(min_length=3, max_length=1000)
    lat: float | None = Field(default=None, ge=-90, le=90)
    lng: float | None = Field(default=None, ge=-180, le=180)


@router.get("/profile")
async def profile(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.dispatch.rider_profile(principal)


@router.put("/availability")
async def availability(data: AvailabilityInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.dispatch.set_availability(principal, data.online)


@router.post("/location", status_code=204, dependencies=[Depends(limit("rider_location"))])
async def location(data: LocationInput, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.dispatch.update_location(principal, GeoPoint(lat=data.lat, lng=data.lng), data.accuracy_m)


@router.get("/offers")
async def offers(c: Ctr, principal: CurrentPrincipal) -> Any:
    """Offers waiting for this rider. `expires_in_seconds` is how long each has left by the server's clock: apps
    count down from it, so a phone (or server) whose clock is wrong still shows the right time to answer."""
    pending = await c.dispatch.pending_offers(principal)
    now = datetime.now(UTC)
    return [
        {
            **offer.model_dump(mode="json"),
            "expires_in_seconds": max(0, int((offer.expires_at - now).total_seconds())),
        }
        for offer in pending
    ]


@router.post("/offers/{assignment_id}/accept")
async def accept_offer(assignment_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return order_view(await c.dispatch.accept_offer(principal, assignment_id), principal)


@router.post("/offers/{assignment_id}/decline", status_code=204)
async def decline_offer(assignment_id: str, data: ReasonInput, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.dispatch.decline_offer(principal, assignment_id, data.reason)


@router.get("/deliveries")
async def deliveries(c: Ctr, principal: CurrentPrincipal, active: bool = True) -> list[dict[str, Any]]:
    require_rider(principal)
    orders = await c.orders.list_for_rider(principal.uid, ACTIVE if active else None)
    return [order_view(o, principal) for o in orders]


@router.post("/deliveries/{order_id}/pickup")
async def pickup(order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    require_rider(principal)
    return order_view(await c.orders.rider_pickup(principal, order_id), principal)


@router.post("/deliveries/{order_id}/in-transit")
async def in_transit(order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    require_rider(principal)
    return order_view(await c.orders.rider_in_transit(principal, order_id), principal)


@router.post("/deliveries/{order_id}/deliver")
async def deliver(order_id: str, data: DeliverInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    require_rider(principal)
    c.rate_limiter.check(f"code:{principal.uid}", capacity=5, refill_per_second=0.02)
    order = await c.orders.rider_deliver(principal, order_id, data.code, cash_collected=data.cash_collected)
    return order_view(order, principal)


@router.post("/deliveries/{order_id}/unassign")
async def unassign(order_id: str, data: ReasonInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    require_rider(principal)
    order = await c.dispatch.unassign(principal, order_id, data.reason or "Rider unable to complete")
    return {"order_id": order.id, "status": order.status.value}


# ---- KYC (docs/adr/0027-rider-kyc.md): what a new rider completes before the team verifies them ----------------
@router.get("/kyc")
async def kyc(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.kyc.mine(principal)


@router.put("/kyc")
async def update_kyc(data: KycDetailsInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.kyc.update(principal, data)


@router.post("/kyc/documents/{kind}", dependencies=[Depends(limit("kyc_upload"))])
async def upload_kyc_document(kind: str, data: KycUploadInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.kyc.upload(principal, kind, data.data)


@router.get("/kyc/documents/{kind}")
async def kyc_document(kind: str, c: Ctr, principal: CurrentPrincipal) -> Response:
    data, content_type = await c.kyc.document(principal, principal.uid, kind)
    return Response(content=data, media_type=content_type, headers={"Cache-Control": "private, no-store"})


@router.post("/kyc/submit")
async def submit_kyc(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.kyc.submit(principal)


@router.get("/earnings")
async def earnings(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.rider_earnings(principal)


@router.post("/payouts", status_code=201)
async def request_payout(
    data: PayoutInput,
    c: Ctr,
    principal: CurrentPrincipal,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> JSONResponse:
    async def run() -> Any:
        return await c.admin.request_rider_payout(principal, data.amount_kobo, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"rider.payout:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.post("/emergency", status_code=201)
async def emergency(data: EmergencyInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    location = GeoPoint(lat=data.lat, lng=data.lng) if data.lat is not None and data.lng is not None else None
    return await c.support.emergency(principal, data.description, location)
