"""Yummy Chops Command Centre endpoints (staff only; every mutation is audited by the service layer)."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Any, Literal

from fastapi import APIRouter, Header, Query
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field

from ...domain.models import RestaurantStatus, RiderStatus, Voucher
from ...domain.order_state import OrderStatus
from ...domain.pricing import PricingConfig
from ...security.rbac import Permission, require
from ...services.admin import FlagInput, RolesInput
from ...services.cash import PayOnDeliveryBlockInput, RemittanceInput
from ...services.engagement import TicketResolution
from ...services.rider_kyc import KycDecisionInput
from ..deps import Ctr, CurrentPrincipal, run_idempotent
from ..serializers import order_view

router = APIRouter(prefix="/v1/admin", tags=["admin"])


class TransitionInput(BaseModel):
    to: OrderStatus
    reason: str = Field(min_length=3, max_length=500)
    refund_amount_kobo: int | None = Field(default=None, gt=0)
    liability: Literal["restaurant", "platform"] = "platform"


class AssignInput(BaseModel):
    rider_uid: str
    reason: str = Field(min_length=3, max_length=300)


class DecisionInput(BaseModel):
    approve: bool
    reason: str | None = Field(default=None, max_length=500)


class RefundDecisionInput(BaseModel):
    approve: bool
    note: str | None = Field(default=None, max_length=500)


class StatusInput(BaseModel):
    reason: str = Field(min_length=3, max_length=300)


class RestaurantStatusInput(StatusInput):
    status: RestaurantStatus


class RiderStatusInput(StatusInput):
    status: RiderStatus


class SettlementPeriod(BaseModel):
    period_start: datetime
    period_end: datetime


class PaidInput(BaseModel):
    bank_reference: str = Field(min_length=4, max_length=120)


class PayoutDecisionInput(BaseModel):
    approve: bool
    bank_reference: str | None = Field(default=None, max_length=120)


class SellerPayoutDecisionInput(PayoutDecisionInput):
    note: str | None = Field(default=None, max_length=500)


@router.get("/overview")
async def overview(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.overview(principal)


@router.get("/analytics")
async def analytics(
    c: Ctr, principal: CurrentPrincipal, days: Annotated[int, Query(ge=1, le=90)] = 14
) -> Any:
    return await c.admin.platform_analytics(principal, days)


@router.get("/orders")
async def orders(
    c: Ctr,
    principal: CurrentPrincipal,
    status: OrderStatus | None = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 100,
) -> list[dict[str, Any]]:
    return [order_view(o, principal) for o in await c.orders.list_all(principal, status, limit)]


@router.get("/orders/{order_id}")
async def order_detail(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    require(principal, Permission.ORDERS_READ_ALL)
    order = await c.orders.get(order_id)
    detail: dict[str, Any] = {
        "order": order_view(order, principal),
        "events": await c.orders.events(principal, order_id),
    }
    if principal.can(Permission.PAYMENTS_READ):
        detail["payments"] = await c.payments.payments_for_order(order_id)
    if principal.can(Permission.LEDGER_READ):
        detail["ledger"] = await c.admin.order_ledger(principal, order_id)
    return detail


@router.post("/orders/{order_id}/transition")
async def transition(order_id: str, data: TransitionInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    order = await c.orders.intervene(
        principal, order_id, data.to, data.reason, data.refund_amount_kobo, data.liability
    )
    return order_view(order, principal)


@router.post("/orders/{order_id}/assign-rider")
async def assign_rider(order_id: str, data: AssignInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return order_view(
        await c.dispatch.manual_assign(principal, order_id, data.rider_uid, data.reason), principal
    )


@router.get("/applications")
async def applications(
    c: Ctr,
    principal: CurrentPrincipal,
    status: str | None = None,
    type: Literal["restaurant", "rider"] | None = None,
) -> Any:
    return await c.applications.list(principal, status, type)


@router.post("/applications/{application_id}/decision")
async def decide_application(
    application_id: str, data: DecisionInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.applications.decide(principal, application_id, approve=data.approve, reason=data.reason)


@router.get("/restaurants")
async def restaurants(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.list_restaurants(principal)


@router.put("/restaurants/{restaurant_id}/status", status_code=204)
async def restaurant_status(
    restaurant_id: str, data: RestaurantStatusInput, c: Ctr, principal: CurrentPrincipal
) -> None:
    await c.admin.set_restaurant_status(principal, restaurant_id, data.status, data.reason)


@router.get("/riders")
async def riders(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.list_riders(principal)


@router.put("/riders/{uid}/status", status_code=204)
async def rider_status(uid: str, data: RiderStatusInput, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.admin.set_rider_status(principal, uid, data.status, data.reason)


@router.put("/users/{uid}/roles")
async def set_roles(uid: str, data: RolesInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.set_roles(principal, uid, data)


# ---- businesses and their branches (docs/adr/0028-business-branches-and-split-payments.md) -------------------
@router.get("/businesses")
async def businesses(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.businesses.list_all(principal)


# ---- rider KYC review (docs/adr/0027-rider-kyc.md) -----------------------------------------------------------
@router.get("/rider-kyc")
async def rider_kyc_list(c: Ctr, principal: CurrentPrincipal, status: str | None = None) -> Any:
    return await c.kyc.list(principal, status)


@router.get("/rider-kyc/{uid}")
async def rider_kyc_detail(uid: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.kyc.detail(principal, uid)


@router.get("/rider-kyc/{uid}/documents/{kind}")
async def rider_kyc_document(uid: str, kind: str, c: Ctr, principal: CurrentPrincipal) -> Response:
    data, content_type = await c.kyc.document(principal, uid, kind)
    return Response(content=data, media_type=content_type, headers={"Cache-Control": "private, no-store"})


@router.post("/rider-kyc/{uid}/decision")
async def rider_kyc_decision(uid: str, data: KycDecisionInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.kyc.decide(principal, uid, data)


@router.get("/refunds")
async def refunds(c: Ctr, principal: CurrentPrincipal, status: str | None = None) -> Any:
    return await c.payments.list_refunds(principal, status)


@router.post("/refunds/{refund_id}/decision")
async def refund_decision(
    refund_id: str, data: RefundDecisionInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.payments.decide_refund(principal, refund_id, approve=data.approve, note=data.note)


@router.get("/payments")
async def payments(c: Ctr, principal: CurrentPrincipal, status: str | None = None) -> Any:
    return await c.payments.list_payments(principal, status)


@router.get("/ledger")
async def ledger(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.ledger_overview(principal)


@router.post("/settlements/generate", status_code=201)
async def generate_settlements(data: SettlementPeriod, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.generate_settlements(principal, data.period_start, data.period_end)


@router.get("/settlements")
async def settlements(c: Ctr, principal: CurrentPrincipal, restaurant_id: str | None = None) -> Any:
    return await c.admin.list_settlements(principal, restaurant_id)


@router.post("/settlements/{settlement_id}/paid")
async def settlement_paid(settlement_id: str, data: PaidInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.mark_settlement_paid(principal, settlement_id, data.bank_reference)


@router.get("/payouts")
async def payouts(c: Ctr, principal: CurrentPrincipal, status: str | None = None) -> Any:
    return await c.admin.list_rider_payouts(principal, status)


@router.post("/payouts/{payout_id}/decision")
async def payout_decision(
    payout_id: str, data: PayoutDecisionInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.admin.decide_rider_payout(
        principal, payout_id, approve=data.approve, bank_reference=data.bank_reference
    )


# ---------------------------------------------------------------- cash, wallets & seller payouts
@router.get("/cash")
async def cash_overview(c: Ctr, principal: CurrentPrincipal) -> Any:
    """Cash held by riders (pay on delivery + COD), wallet balances and money owed to sellers."""
    return await c.cash.overview(principal)


@router.post("/riders/{uid}/cash-remittances", status_code=201)
async def record_remittance(
    uid: str,
    data: RemittanceInput,
    c: Ctr,
    principal: CurrentPrincipal,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
) -> JSONResponse:
    async def run() -> Any:
        return await c.cash.record_remittance(principal, uid, data, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"admin.remittance:{uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.put("/customers/{uid}/pay-on-delivery")
async def customer_pay_on_delivery(
    uid: str, data: PayOnDeliveryBlockInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.cash.set_customer_block(principal, uid, data)


@router.get("/seller-payouts")
async def seller_payouts(c: Ctr, principal: CurrentPrincipal, status: str | None = None) -> Any:
    return await c.wallet.list_seller_payouts(principal, status)


@router.post("/seller-payouts/{payout_id}/decision")
async def seller_payout_decision(
    payout_id: str, data: SellerPayoutDecisionInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.wallet.decide_seller_payout(
        principal, payout_id, approve=data.approve, bank_reference=data.bank_reference, note=data.note
    )


@router.get("/config/pricing")
async def get_pricing(c: Ctr, principal: CurrentPrincipal) -> PricingConfig:
    return await c.admin.get_pricing(principal)


@router.put("/config/pricing")
async def put_pricing(data: PricingConfig, c: Ctr, principal: CurrentPrincipal) -> PricingConfig:
    return await c.admin.update_pricing(principal, data)


@router.get("/flags")
async def flags(c: Ctr, principal: CurrentPrincipal) -> Any:
    require(principal, Permission.CONFIG_READ)
    return await c.repos.list_feature_flags()


@router.put("/flags/{key}")
async def set_flag(key: str, data: FlagInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.set_flag(principal, key, data)


@router.get("/audit")
async def audit(
    c: Ctr,
    principal: CurrentPrincipal,
    resource_type: str | None = None,
    resource_id: str | None = None,
    actor_id: str | None = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 100,
) -> Any:
    require(principal, Permission.AUDIT_READ)
    return await c.audit.list(
        resource_type=resource_type, resource_id=resource_id, actor_id=actor_id, limit=limit
    )


@router.get("/support/tickets")
async def tickets(c: Ctr, principal: CurrentPrincipal, status: str | None = None) -> Any:
    return await c.support.list(principal, status)


@router.patch("/support/tickets/{ticket_id}")
async def resolve_ticket(ticket_id: str, data: TicketResolution, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.support.resolve(principal, ticket_id, data)


@router.get("/vouchers")
async def vouchers(c: Ctr, principal: CurrentPrincipal) -> Any:
    require(principal, Permission.PROMOTIONS_MANAGE)
    return await c.repos.vouchers.find(limit=500)


@router.put("/vouchers/{code}")
async def upsert_voucher(code: str, data: Voucher, c: Ctr, principal: CurrentPrincipal) -> Voucher:
    require(principal, Permission.PROMOTIONS_MANAGE)
    voucher = data.model_copy(update={"code": code.upper()})
    await c.repos.vouchers.save(Voucher.model_validate(voucher.model_dump()))
    await c.audit.record(
        actor_id=principal.uid,
        actor_roles=principal.audit_roles(),
        action="voucher.saved",
        resource_type="voucher",
        resource_id=voucher.code,
        details=voucher.model_dump(mode="json"),
    )
    return voucher
