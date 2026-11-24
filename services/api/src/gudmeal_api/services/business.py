"""Businesses with branches, one menu and split card payments (docs/adr/0028-business-branches-and-split-payments.md).

A business has a unique ID (YCB-XXXXXX), an owner, one or more branches and one bank account:

* every branch is a merchant of its own (`Restaurant`: address, hours, orders, a manager's phone number) that sells
  the main branch's menu; customers see the branch nearest to them;
* a branch belongs to the city of the delivery zone it is in; once it exists, its address and pin change only through
  the kitchen location checks every shop has (services/locations.py: in the city's zones, pin near the address,
  bigger moves checked by Yummy Chops);
* items are tagged with the business ID;
* card payments are split by Paystack: the business's share goes straight to its bank account (a Paystack
  subaccount); the bank account number itself is never stored, only its last four digits.
"""

from __future__ import annotations

import re
import secrets
import uuid
from datetime import UTC, datetime
from typing import Any

from pydantic import BaseModel, Field

from ..domain.geo import GeoPoint, geohash_encode
from ..domain.models import Business, Restaurant, RestaurantStatus
from ..errors import Conflict, NotFound, PaymentProviderError, PermissionDenied, ValidationFailed
from ..ledger.audit import AuditLog
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, Role
from .catalog import slugify
from .infra import IdentityAdmin

ID_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"  # no 0/O or 1/I: read out over the phone without mistakes
MAX_BRANCHES = 30
# Used when the API has no Paystack key (the local sandbox): bank accounts are not really checked.
SANDBOX_BANKS = [
    {"code": "044", "name": "Access Bank"},
    {"code": "058", "name": "Guaranty Trust Bank"},
    {"code": "011", "name": "First Bank of Nigeria"},
    {"code": "033", "name": "United Bank For Africa"},
    {"code": "057", "name": "Zenith Bank"},
    {"code": "999992", "name": "OPay"},
]


def utcnow() -> datetime:
    return datetime.now(UTC)


class BranchInput(BaseModel):
    branch_name: str | None = Field(default=None, max_length=60)
    address: str = Field(min_length=5, max_length=200)
    area: str = Field(default="", max_length=60)
    location: GeoPoint
    manager_phone: str | None = Field(default=None, max_length=20)


class BranchUpdate(BaseModel):
    """The branch's name and manager's number. Its address moves with the kitchen location checks
    (`PUT /v1/partner/restaurants/{id}/location`), like any shop's."""

    branch_name: str | None = Field(default=None, max_length=60)
    manager_phone: str | None = Field(default=None, max_length=20)


class BankInput(BaseModel):
    bank_code: str = Field(min_length=3, max_length=10, pattern=r"^\d+$")
    account_number: str = Field(pattern=r"^\d{10}$", description="NUBAN: 10 digits")


class BusinessService:
    def __init__(
        self,
        repos: Repositories,
        identity: IdentityAdmin,
        audit: AuditLog,
        paystack: Any | None = None,  # PaystackProvider, when the API has a Paystack key
    ) -> None:
        self.repos = repos
        self.identity = identity
        self.audit = audit
        self.paystack = paystack
        self._banks: list[dict[str, str]] | None = None

    # ------------------------------------------------------------------------------------------------ creating
    async def new_id(self) -> str:
        for _ in range(20):
            candidate = "YCB-" + "".join(secrets.choice(ID_ALPHABET) for _ in range(6))
            if await self.repos.businesses.get(candidate) is None:
                return candidate
        raise Conflict("Could not make a business ID: try again")

    async def create(
        self,
        *,
        owner_uid: str,
        main: Restaurant,
        email: str | None = None,
        branches: list[BranchInput] | None = None,
    ) -> Business:
        """A business for `main` (already saved): its ID goes on the main branch and every item, and each extra
        branch becomes a merchant selling the main branch's menu. The owner manages them all."""
        business = Business(
            id=await self.new_id(),
            name=main.name,
            owner_uid=owner_uid,
            vertical=main.vertical,
            phone=main.phone,
            email=email,
            main_restaurant_id=main.id,
            created_at=utcnow(),
        )
        await self.repos.businesses.create(business)
        await self.repos.restaurants.update(
            main.id,
            {"business_id": business.id, "branch_name": main.branch_name or main.area or "Main branch"},
        )
        for item in await self.repos.list_items(main.id):
            await self.repos.items.update(item.id, {"business_id": business.id})
        # Branches from the sign-up form were checked by the team with the application.
        created = [await self._new_branch(business, main, b, strict=False) for b in branches or []]
        await self._grant(owner_uid, [main.id, *(r.id for r in created)])
        return business

    async def _new_branch(
        self, business: Business, main: Restaurant, data: BranchInput, *, strict: bool = True
    ) -> Restaurant:
        zone = (await self.repos.get_pricing_config()).zone_for(data.location)
        if zone is None and strict:
            raise ValidationFailed(
                "That address is outside the areas we deliver. Pick it from the address search."
            )
        rid = uuid.uuid4().hex[:20]
        branch = main.model_copy(
            update={
                "id": rid,
                "city": zone.city if zone else main.city,
                "slug": f"{slugify(main.name)}-{rid[:4]}",
                "address": data.address.strip(),
                "area": data.area.strip(),
                "location": data.location,
                "geohash": geohash_encode(data.location.lat, data.location.lng, 9),
                "business_id": business.id,
                "menu_restaurant_id": main.menu_id,
                "branch_name": (data.branch_name or data.area or "Branch").strip(),
                "manager_phone": data.manager_phone,
                # Hidden until the owner opens it for orders (the menu is shared, the hours and staff are not).
                "status": RestaurantStatus.PENDING,
                "is_accepting_orders": False,
                "is_featured": False,
                "rating": 0.0,
                "rating_count": 0,
                "created_at": utcnow(),
            }
        )
        await self.repos.restaurants.create(branch)
        return branch

    async def _grant(self, uid: str, restaurant_ids: list[str]) -> None:
        claims = await self.identity.get_claims(uid)
        roles = set(claims.get("roles", [])) | {Role.RESTAURANT_OWNER.value}
        restaurant_roles = {**claims.get("restaurant_roles", {}), **dict.fromkeys(restaurant_ids, "owner")}
        await self.identity.set_claims(uid, sorted(roles), restaurant_roles)

    # ------------------------------------------------------------------------------------------------ the owner
    async def mine(self, principal: Principal) -> dict[str, Any]:
        """The owner's businesses, and their restaurants that are not in a business yet (to get an ID)."""
        businesses = await self.repos.businesses.find(where=[("owner_uid", "==", principal.uid)], limit=20)
        owned = [rid for rid, role in principal.restaurant_roles.items() if role == "owner"]
        loose = [
            {"restaurant_id": r.id, "name": r.name, "address": r.address, "area": r.area}
            for r in (await self.repos.restaurants.get_many(owned)).values()
            if not r.business_id
        ]
        return {"businesses": [await self.view(b) for b in businesses], "without_business": loose}

    async def claim(self, principal: Principal, restaurant_id: str) -> dict[str, Any]:
        """An owner's existing restaurant gets a business ID (and can then add branches and a bank account)."""
        restaurant = await self._owned_restaurant(principal, restaurant_id)
        if restaurant.business_id:
            raise Conflict("This restaurant already belongs to a business")
        business = await self.create(owner_uid=principal.uid, main=restaurant)
        await self._audit(principal, "business.created", business.id, {"restaurant_id": restaurant_id})
        return await self.view(business)

    async def add_branch(self, principal: Principal, business_id: str, data: BranchInput) -> dict[str, Any]:
        business = await self._owned(principal, business_id)
        branches = await self.repos.restaurants.find(where=[("business_id", "==", business.id)], limit=100)
        if len(branches) >= MAX_BRANCHES:
            raise ValidationFailed(f"A business can have at most {MAX_BRANCHES} branches")
        main = await self.repos.restaurants.get(business.main_restaurant_id)
        if main is None:
            raise NotFound("The main branch is missing")
        branch = await self._new_branch(business, main, data)
        await self._grant(business.owner_uid, [branch.id])
        await self._audit(principal, "business.branch_added", business.id, {"restaurant_id": branch.id})
        return await self.view(business)

    async def update_branch(
        self, principal: Principal, business_id: str, restaurant_id: str, data: BranchUpdate
    ) -> dict[str, Any]:
        business = await self._owned(principal, business_id)
        branch = await self.repos.restaurants.get(restaurant_id)
        if branch is None or branch.business_id != business.id:
            raise NotFound("Branch not found")
        patch: dict[str, Any] = {
            k: v.strip() if isinstance(v, str) else v for k, v in data.model_dump(exclude_unset=True).items()
        }
        if patch:
            await self.repos.restaurants.update(restaurant_id, patch)
        await self._audit(principal, "business.branch_updated", business.id, {"restaurant_id": restaurant_id})
        return await self.view(business)

    # ------------------------------------------------------------------------------------------------ the bank
    async def banks(self) -> list[dict[str, str]]:
        if self.paystack is None:
            return SANDBOX_BANKS
        if self._banks is None:
            self._banks = sorted(await self.paystack.list_banks(), key=lambda b: b["name"].lower())
        return self._banks

    async def connect_bank(self, principal: Principal, business_id: str, data: BankInput) -> dict[str, Any]:
        """The business's bank account for split payments: checked with the bank, then given to Paystack as a
        subaccount. Only the last four digits are kept here."""
        business = await self._owned(principal, business_id)
        bank = next((b for b in await self.banks() if b["code"] == data.bank_code), None)
        if bank is None:
            raise ValidationFailed("Choose your bank from the list")
        if self.paystack is None:  # local sandbox: nothing real to check or connect
            account_name, code = (
                f"{business.name} (test account)",
                business.paystack_subaccount_code or (f"ACCT_SANDBOX_{business.id}"),
            )
        else:
            try:
                account_name = await self.paystack.resolve_account(
                    account_number=data.account_number, bank_code=data.bank_code
                )
                code = await self.paystack.save_subaccount(
                    code=business.paystack_subaccount_code,
                    business_name=business.name,
                    bank_code=data.bank_code,
                    account_number=data.account_number,
                    email=business.email,
                    phone=business.phone,
                )
            except PaymentProviderError as exc:
                raise ValidationFailed(f"The bank account could not be connected: {exc.message}") from exc
        await self.repos.businesses.update(
            business.id,
            {
                "paystack_subaccount_code": code,
                "settlement_bank_code": data.bank_code,
                "settlement_bank_name": bank["name"],
                "settlement_account_name": account_name,
                "settlement_account_last4": data.account_number[-4:],
            },
        )
        await self._audit(principal, "business.bank_connected", business.id, {"bank": bank["name"]})
        return await self.view(await self._owned(principal, business_id))

    # ------------------------------------------------------------------------------------------------ the team
    async def list_all(self, principal: Principal) -> list[dict[str, Any]]:
        if not principal.can(Permission.RESTAURANTS_MANAGE):
            raise PermissionDenied("Staff only")
        return [await self.view(b) for b in await self.repos.businesses.find(limit=500)]

    # ------------------------------------------------------------------------------------------------ helpers
    async def view(self, business: Business) -> dict[str, Any]:
        branches = await self.repos.restaurants.find(where=[("business_id", "==", business.id)], limit=100)
        branches.sort(key=lambda r: (r.id != business.main_restaurant_id, r.branch_name or r.area))
        data = business.model_dump(mode="json")
        data.pop("paystack_subaccount_code", None)
        data["bank_connected"] = bool(business.paystack_subaccount_code)
        data["branches"] = [
            {
                "restaurant_id": r.id,
                "branch_name": r.branch_name,
                "address": r.address,
                "area": r.area,
                "location": r.location.model_dump(),
                "manager_phone": r.manager_phone,
                "main": r.id == business.main_restaurant_id,
                "status": r.status.value,
                "is_accepting_orders": r.is_accepting_orders,
            }
            for r in branches
        ]
        return data

    async def _owned(self, principal: Principal, business_id: str) -> Business:
        business = await self.repos.businesses.get(business_id)
        if business is None:
            raise NotFound("Business not found")
        if business.owner_uid != principal.uid and not principal.can(Permission.RESTAURANTS_MANAGE):
            raise PermissionDenied("Only the business's owner can change it")
        return business

    async def _owned_restaurant(self, principal: Principal, restaurant_id: str) -> Restaurant:
        restaurant = await self.repos.restaurants.get(restaurant_id)
        if restaurant is None:
            raise NotFound("Restaurant not found")
        if principal.restaurant_roles.get(restaurant_id) != "owner" and restaurant.owner_uid != principal.uid:
            raise PermissionDenied("Only the restaurant's owner can do this")
        return restaurant

    async def _audit(
        self, principal: Principal, action: str, business_id: str, details: dict[str, Any]
    ) -> None:
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action=action,
            resource_type="business",
            resource_id=business_id,
            details=details,
        )


def valid_business_id(value: str) -> bool:
    return bool(re.fullmatch(r"YCB-[" + ID_ALPHABET + r"]{6}", value))


__all__ = ["BankInput", "BranchInput", "BranchUpdate", "BusinessService", "valid_business_id"]
