"""Yummy Chops Partner (restaurant dashboard) endpoints."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query, Response
from pydantic import BaseModel, Field

from ...domain.order_state import OrderStatus
from ...services.business import BankInput, BranchInput, BranchUpdate
from ...services.catalog import ItemInput, OptionGroupInput, RestaurantSettingsInput
from ...services.menu_tools import TEMPLATE, MenuImportInput, PhotoInput
from ..deps import Ctr, CurrentPrincipal, limit
from ..serializers import order_view

router = APIRouter(prefix="/v1/partner", tags=["partner"])


# ---- the business: its unique ID, branches and bank account (docs/adr/0028-business-branches-and-split-payments.md)
class ClaimInput(BaseModel):
    restaurant_id: str = Field(min_length=1, max_length=64)


@router.get("/business")
async def my_business(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.businesses.mine(principal)


@router.post("/business", status_code=201)
async def claim_business(data: ClaimInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.businesses.claim(principal, data.restaurant_id)


@router.post("/business/{business_id}/branches", status_code=201)
async def add_branch(business_id: str, data: BranchInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.businesses.add_branch(principal, business_id, data)


@router.put("/business/{business_id}/branches/{restaurant_id}")
async def update_branch(
    business_id: str, restaurant_id: str, data: BranchUpdate, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.businesses.update_branch(principal, business_id, restaurant_id, data)


@router.get("/banks")
async def banks(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.businesses.banks()


@router.put("/business/{business_id}/bank")
async def connect_bank(business_id: str, data: BankInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.businesses.connect_bank(principal, business_id, data)


class AcceptInput(BaseModel):
    prep_minutes: int = Field(ge=1, le=180)


class RejectInput(BaseModel):
    reason: str = Field(min_length=3, max_length=300)


class CodeInput(BaseModel):
    code: str = Field(pattern=r"^\d{4}$")


class AvailabilityInput(BaseModel):
    available: bool


class AcceptingInput(BaseModel):
    accepting: bool


class CategoriesInput(BaseModel):
    names: list[str] = Field(min_length=1, max_length=40)


@router.get("/restaurants")
async def my_restaurants(c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    ids = list(principal.restaurant_roles)
    found = await c.repos.restaurants.get_many(ids)
    return [{"restaurant": found[i], "role": principal.restaurant_roles[i]} for i in ids if i in found]


@router.get("/restaurants/{restaurant_id}/menu")
async def menu(restaurant_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.catalog.menu_for_partner(principal, restaurant_id)


@router.put("/restaurants/{restaurant_id}/categories")
async def set_categories(
    restaurant_id: str, data: CategoriesInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.set_categories(principal, restaurant_id, data.names)


@router.post("/restaurants/{restaurant_id}/items", status_code=201)
async def create_item(restaurant_id: str, data: ItemInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.catalog.create_item(principal, restaurant_id, data)


@router.put("/restaurants/{restaurant_id}/items/{item_id}")
async def update_item(
    restaurant_id: str, item_id: str, data: ItemInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.update_item(principal, restaurant_id, item_id, data)


@router.patch("/restaurants/{restaurant_id}/items/{item_id}/availability")
async def item_availability(
    restaurant_id: str, item_id: str, data: AvailabilityInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.set_item_availability(principal, restaurant_id, item_id, data.available)


@router.delete("/restaurants/{restaurant_id}/items/{item_id}", status_code=204)
async def delete_item(restaurant_id: str, item_id: str, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.catalog.delete_item(principal, restaurant_id, item_id)


@router.post(
    "/restaurants/{restaurant_id}/items/{item_id}/photo", dependencies=[Depends(limit("menu_photo"))]
)
async def item_photo(
    restaurant_id: str, item_id: str, data: PhotoInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.menu_tools.set_photo(principal, restaurant_id, item_id, data.data)


@router.delete("/restaurants/{restaurant_id}/items/{item_id}/photo")
async def remove_item_photo(restaurant_id: str, item_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.menu_tools.remove_photo(principal, restaurant_id, item_id)


@router.post("/restaurants/{restaurant_id}/menu/import", dependencies=[Depends(limit("menu_import"))])
async def import_menu(restaurant_id: str, data: MenuImportInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.menu_tools.import_menu(principal, restaurant_id, data)


@router.get("/menu-template.csv")
async def menu_template() -> Response:
    return Response(
        content=TEMPLATE,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="yummy-chops-menu-template.csv"'},
    )


@router.post("/restaurants/{restaurant_id}/option-groups", status_code=201)
async def create_group(
    restaurant_id: str, data: OptionGroupInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.upsert_option_group(principal, restaurant_id, data)


@router.put("/restaurants/{restaurant_id}/option-groups/{group_id}")
async def update_group(
    restaurant_id: str, group_id: str, data: OptionGroupInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.upsert_option_group(principal, restaurant_id, data, group_id)


@router.patch("/restaurants/{restaurant_id}/settings")
async def update_settings(
    restaurant_id: str, data: RestaurantSettingsInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.update_settings(principal, restaurant_id, data)


@router.put("/restaurants/{restaurant_id}/accepting")
async def set_accepting(restaurant_id: str, data: AcceptingInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.catalog.set_accepting_orders(principal, restaurant_id, data.accepting)


@router.get("/restaurants/{restaurant_id}/orders")
async def restaurant_orders(
    restaurant_id: str,
    c: Ctr,
    principal: CurrentPrincipal,
    status: Annotated[list[OrderStatus] | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
) -> list[dict[str, Any]]:
    orders = await c.orders.list_for_restaurant(principal, restaurant_id, status, limit)
    views = [order_view(o, principal) for o in orders]
    # The rider coming for the order or carrying it: who, their number and, while they are coming, about how many
    # minutes away (docs/adr/0028-business-branches-and-split-payments.md).
    riding = {o.rider_id for o in orders if o.rider_id and o.status in RIDER_ON_THE_WAY}
    if not riding:
        return views
    riders = await c.repos.riders.get_many(sorted(riding))
    cfg = await c.repos.get_pricing_config()
    now = datetime.now(UTC)
    for view, order in zip(views, orders, strict=True):
        rider = riders.get(order.rider_id or "") if order.status in RIDER_ON_THE_WAY else None
        if rider is None:
            continue
        minutes = None
        at = rider.last_location
        # Only from a recent location (the age dispatch trusts): an old one gives no estimate, not a wrong one.
        recent = rider.last_location_at is not None and (
            (now - rider.last_location_at).total_seconds() <= c.dispatch.cfg.max_location_age_seconds
        )
        if order.status == OrderStatus.RIDER_ASSIGNED and at is not None and recent:
            minutes = c.maps.estimate(at, order.restaurant_location, cfg).duration_minutes
        view["rider"] = {
            "name": rider.name,
            "phone": rider.phone,
            "eta_minutes": minutes,
            "verified": rider.verified_at is not None,
        }
    return views


RIDER_ON_THE_WAY = (OrderStatus.RIDER_ASSIGNED, OrderStatus.PICKED_UP, OrderStatus.IN_TRANSIT)


async def _restaurant_order(c: Any, principal: Any, restaurant_id: str, order_id: str) -> None:
    order = await c.orders.get_for(principal, order_id)
    if order.restaurant_id != restaurant_id:
        from ...errors import NotFound

        raise NotFound("Order not found")


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/accept")
async def accept(
    restaurant_id: str, order_id: str, data: AcceptInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.accept(principal, order_id, data.prep_minutes), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/reject")
async def reject(
    restaurant_id: str, order_id: str, data: RejectInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.reject(principal, order_id, data.reason), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/preparing")
async def preparing(restaurant_id: str, order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.mark_preparing(principal, order_id), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/ready")
async def ready(restaurant_id: str, order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.mark_ready(principal, order_id), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/handover")
async def handover(
    restaurant_id: str, order_id: str, data: CodeInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    c.rate_limiter.check(f"code:{principal.uid}", capacity=5, refill_per_second=0.02)
    return order_view(await c.orders.complete_pickup(principal, order_id, data.code), principal)


@router.get("/restaurants/{restaurant_id}/analytics")
async def analytics(
    restaurant_id: str, c: Ctr, principal: CurrentPrincipal, days: Annotated[int, Query(ge=1, le=90)] = 14
) -> Any:
    return await c.analytics.restaurant(principal, restaurant_id, days)


@router.get("/restaurants/{restaurant_id}/settlements")
async def settlements(restaurant_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.list_settlements(principal, restaurant_id)
