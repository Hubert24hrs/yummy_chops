"""Rider sign-up and KYC, checked by hand by the team (docs/adr/0027-rider-kyc.md).

1. Sign-up (website `/ride` or the rider app): full name, WhatsApp number, email, residential address. The person gets
   the rider app at once (the `rider` role), with a pending rider profile and a KYC draft. They cannot go online yet.
2. KYC, in the rider app: permanent address, NIN, photos of the plate number, Hackney permit, rider's card or licence
   and the bike, two guarantors (details plus their signed guarantor form) and a selfie for the face check. Then
   Submit.
3. The team reviews it in the Command Centre and either verifies the rider (the Verified badge; they may now go
   online) or says what must change; the rider fixes it and submits again.

The NIN is shown in full only to the reviewing team; the rider sees its last four digits. Files stay private (see
services/files.py).
"""

from __future__ import annotations

import base64
import binascii
import re
from datetime import UTC, datetime
from typing import Any

from pydantic import BaseModel, Field

from ..domain.models import (
    KYC_DOCUMENTS,
    Guarantor,
    KycDocument,
    RiderKyc,
    RiderProfile,
    RiderStatus,
    VehicleType,
)
from ..errors import Conflict, InvalidTransition, NotFound, ValidationFailed
from ..ledger.audit import AuditLog
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, Role, require, require_rider
from .files import EXTENSIONS, FileStore, check_upload
from .infra import IdentityAdmin, Notifier

IMAGES = {"image/jpeg", "image/png", "image/webp"}
FORMS = IMAGES | {"application/pdf"}  # a guarantor's signed form may be a scan
NIN = re.compile(r"^\d{11}$")
EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
EDITABLE = ("draft", "needs_changes")
REVIEW_ITEMS = {*KYC_DOCUMENTS, "details", "guarantors"}


def utcnow() -> datetime:
    return datetime.now(UTC)


def mask_nin(nin: str) -> str:
    return f"{'•' * 7}{nin[-4:]}" if nin else ""


class GuarantorInput(BaseModel):
    name: str = Field(default="", max_length=80)
    phone: str = Field(default="", max_length=20)
    email: str = Field(default="", max_length=120)
    address: str = Field(default="", max_length=200)
    occupation: str = Field(default="", max_length=80)


class KycDetailsInput(BaseModel):
    """What the rider types on the KYC dashboard. Saved as they go; checked in full on Submit."""

    permanent_address: str | None = Field(default=None, max_length=200)
    nin: str | None = Field(default=None, max_length=20)
    guarantors: list[GuarantorInput] | None = Field(default=None, min_length=2, max_length=2)


class KycUploadInput(BaseModel):
    """A photo or scan, base64-encoded (at most 5 MB once decoded)."""

    data: str = Field(min_length=4, max_length=7_200_000)


class KycDecisionInput(BaseModel):
    approve: bool
    note: str | None = Field(default=None, max_length=500)
    changes_needed: list[str] = Field(default_factory=list, max_length=12)


class RiderKycService:
    def __init__(
        self,
        repos: Repositories,
        files: FileStore,
        identity: IdentityAdmin,
        audit: AuditLog,
        notifier: Notifier,
    ) -> None:
        self.repos = repos
        self.files = files
        self.identity = identity
        self.audit = audit
        self.notifier = notifier

    # ------------------------------------------------------------------------------------------------ sign-up
    async def start(
        self,
        uid: str,
        *,
        full_name: str,
        whatsapp_phone: str,
        email: str,
        residential_address: str,
        vehicle: VehicleType = VehicleType.MOTORCYCLE,
        plate_number: str | None = None,
    ) -> RiderKyc:
        """A new rider signed up: they get the rider app (role), a pending profile and a KYC draft."""
        if await self.repos.riders.get(uid) is None:
            await self.repos.riders.create(
                RiderProfile(
                    uid=uid,
                    name=full_name,
                    phone=whatsapp_phone,
                    vehicle=vehicle,
                    plate_number=plate_number,
                    status=RiderStatus.PENDING,
                    created_at=utcnow(),
                )
            )
        kyc = await self.repos.rider_kyc.get(uid)
        if kyc is None:
            kyc = RiderKyc(
                uid=uid,
                full_name=full_name,
                whatsapp_phone=whatsapp_phone,
                email=email,
                residential_address=residential_address,
                updated_at=utcnow(),
            )
            await self.repos.rider_kyc.create(kyc)
        claims = await self.identity.get_claims(uid)
        roles = set(claims.get("roles", [])) | {Role.RIDER.value}
        await self.identity.set_claims(uid, sorted(roles), claims.get("restaurant_roles", {}))
        return kyc

    # ------------------------------------------------------------------------------------------------ the rider
    async def mine(self, principal: Principal) -> dict[str, Any]:
        require_rider(principal)
        return self.view(await self._get(principal.uid, create=True), reviewer=False)

    async def update(self, principal: Principal, data: KycDetailsInput) -> dict[str, Any]:
        require_rider(principal)
        kyc = self._editable(await self._get(principal.uid, create=True))
        patch: dict[str, Any] = {"updated_at": utcnow()}
        if data.permanent_address is not None:
            patch["permanent_address"] = data.permanent_address.strip()
        if data.nin is not None:
            nin = re.sub(r"\s", "", data.nin)
            if nin and not NIN.match(nin):
                raise ValidationFailed("The NIN has 11 digits")
            patch["nin"] = nin
        if data.guarantors is not None:
            guarantors = []
            for n, g in enumerate(data.guarantors, start=1):
                email = g.email.strip()
                if email and not EMAIL.match(email):
                    raise ValidationFailed(f"Guarantor {n}'s email does not look right")
                guarantors.append(
                    Guarantor(
                        name=g.name.strip(),
                        phone=g.phone.strip(),
                        email=email,
                        address=g.address.strip(),
                        occupation=g.occupation.strip(),
                    ).model_dump()
                )
            patch["guarantors"] = guarantors
        await self.repos.rider_kyc.update(kyc.uid, patch)
        return self.view(await self._get(kyc.uid), reviewer=False)

    async def upload(self, principal: Principal, kind: str, data: str) -> dict[str, Any]:
        require_rider(principal)
        if kind not in KYC_DOCUMENTS:
            raise NotFound("Unknown document")
        kyc = self._editable(await self._get(principal.uid, create=True))
        if data.startswith("data:") and "," in data:
            data = data.split(",", 1)[1]  # a data URL from a browser
        try:
            raw = base64.b64decode(data, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise ValidationFailed("The file could not be read") from exc
        content_type = check_upload(raw, FORMS if kind.endswith("_form") else IMAGES)
        # One file per document (a new photo replaces the old one), so storage cannot grow with every upload.
        path = f"applications/{kyc.uid}/kyc/{kind}.{EXTENSIONS[content_type]}"
        await self.files.put(path, raw, content_type)
        documents = {key: doc.model_dump(mode="json") for key, doc in kyc.documents.items()}
        documents[kind] = KycDocument(
            path=path, content_type=content_type, size=len(raw), uploaded_at=utcnow()
        ).model_dump(mode="json")
        await self.repos.rider_kyc.update(kyc.uid, {"documents": documents, "updated_at": utcnow()})
        return self.view(await self._get(kyc.uid), reviewer=False)

    async def document(self, principal: Principal, uid: str, kind: str) -> tuple[bytes, str]:
        """A file, for the rider who uploaded it or the reviewing team."""
        if principal.uid == uid:
            require_rider(principal)
        else:
            require(principal, Permission.APPLICATIONS_REVIEW)
        kyc = await self._get(uid)
        found = kyc.documents.get(kind)
        if found is None:
            raise NotFound("Not uploaded yet")
        return await self.files.get(found.path)

    async def submit(self, principal: Principal) -> dict[str, Any]:
        require_rider(principal)
        kyc = self._editable(await self._get(principal.uid, create=True))
        if missing := self.missing(kyc):
            raise ValidationFailed("Still to do: " + "; ".join(missing))
        now = utcnow()
        await self.repos.rider_kyc.update(
            kyc.uid, {"status": "submitted", "submitted_at": now, "changes_needed": [], "updated_at": now}
        )
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="rider_kyc.submitted",
            resource_type="rider_kyc",
            resource_id=kyc.uid,
            details={},
        )
        return self.view(await self._get(kyc.uid), reviewer=False)

    # ------------------------------------------------------------------------------------------------ the team
    async def list(self, principal: Principal, status: str | None = None) -> list[dict[str, Any]]:
        require(principal, Permission.APPLICATIONS_REVIEW)
        where: list[Any] = [("status", "==", status)] if status else []
        found = await self.repos.rider_kyc.find(where=where, limit=200)
        found.sort(
            key=lambda k: k.submitted_at or k.updated_at or datetime.min.replace(tzinfo=UTC), reverse=True
        )
        return [
            {
                "uid": k.uid,
                "full_name": k.full_name,
                "whatsapp_phone": k.whatsapp_phone,
                "status": k.status,
                "submitted_at": k.submitted_at.isoformat() if k.submitted_at else None,
                "nin": mask_nin(k.nin),
                "documents": len(k.documents),
                "missing": len(self.missing(k)),
            }
            for k in found
        ]

    async def detail(self, principal: Principal, uid: str) -> dict[str, Any]:
        require(principal, Permission.APPLICATIONS_REVIEW)
        return self.view(await self._get(uid), reviewer=True)

    async def decide(self, principal: Principal, uid: str, data: KycDecisionInput) -> dict[str, Any]:
        require(principal, Permission.APPLICATIONS_REVIEW)
        kyc = await self._get(uid)
        if kyc.status != "submitted":
            raise InvalidTransition("Only a submitted KYC can be reviewed")
        if data.approve:
            await self.verify(uid, reviewer_uid=principal.uid, note=data.note)
        else:
            if unknown := set(data.changes_needed) - REVIEW_ITEMS:
                raise ValidationFailed(f"Unknown items: {', '.join(sorted(unknown))}")
            if not data.note and not data.changes_needed:
                raise ValidationFailed("Say what the rider must change")
            now = utcnow()
            await self.repos.rider_kyc.update(
                uid,
                {
                    "status": "needs_changes",
                    "reviewed_at": now,
                    "reviewed_by": principal.uid,
                    "review_note": data.note,
                    "changes_needed": data.changes_needed,
                    "updated_at": now,
                },
            )
            await self.notifier.notify_user(
                uid,
                "Your rider KYC needs changes",
                data.note or "Open the rider app to see what to change",
                {"kind": "rider_kyc"},
            )
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action=f"rider_kyc.{'verified' if data.approve else 'changes_requested'}",
            resource_type="rider_kyc",
            resource_id=uid,
            details={"note": data.note, "changes_needed": data.changes_needed},
        )
        return self.view(await self._get(uid), reviewer=True)

    async def verify(self, uid: str, *, reviewer_uid: str, note: str | None) -> str:
        """The team checked the KYC: the rider is verified (the badge) and may go online. Also closes their sign-up
        application, so it no longer waits on the Applications page."""
        kyc = await self.repos.rider_kyc.get(uid)
        if kyc is None or kyc.status != "submitted":
            raise Conflict("The rider has not submitted their KYC yet")
        now = utcnow()
        await self.repos.rider_kyc.update(
            uid,
            {
                "status": "verified",
                "reviewed_at": now,
                "reviewed_by": reviewer_uid,
                "review_note": note,
                "changes_needed": [],
                "updated_at": now,
            },
        )
        if await self.repos.riders.get(uid) is None:
            await self.repos.riders.create(
                RiderProfile(uid=uid, name=kyc.full_name, phone=kyc.whatsapp_phone, created_at=now)
            )
        await self.repos.riders.update(uid, {"status": RiderStatus.ACTIVE.value, "verified_at": now})
        for app in await self.repos.applications.find(
            where=[("applicant_uid", "==", uid), ("type", "==", "rider")], limit=10
        ):
            if app.status in ("submitted", "in_review"):
                await self.repos.applications.update(
                    app.id,
                    {
                        "status": "approved",
                        "decided_at": now,
                        "decided_by": reviewer_uid,
                        "decision_reason": note,
                        "created_entity_id": uid,
                    },
                )
        await self.notifier.notify_user(
            uid,
            "You're verified",
            "Your KYC passed: you can now go online and take deliveries",
            {"kind": "rider_kyc"},
        )
        return uid

    async def reject(self, uid: str, *, reviewer_uid: str, note: str | None) -> None:
        """The sign-up was turned down: the rider cannot go online."""
        now = utcnow()
        if await self.repos.rider_kyc.get(uid) is not None:
            await self.repos.rider_kyc.update(
                uid,
                {"status": "rejected", "reviewed_at": now, "reviewed_by": reviewer_uid, "review_note": note},
            )
        if await self.repos.riders.get(uid) is not None:
            await self.repos.riders.update(uid, {"status": RiderStatus.SUSPENDED.value, "is_online": False})

    # ------------------------------------------------------------------------------------------------ helpers
    async def _get(self, uid: str, *, create: bool = False) -> RiderKyc:
        kyc = await self.repos.rider_kyc.get(uid)
        if kyc is not None:
            return kyc
        if not create:
            raise NotFound("No KYC for this rider")
        profile = await self.repos.riders.get(uid)
        kyc = RiderKyc(
            uid=uid,
            full_name=profile.name if profile else "",
            whatsapp_phone=(profile.phone or "") if profile else "",
            updated_at=utcnow(),
        )
        await self.repos.rider_kyc.create(kyc)
        return kyc

    @staticmethod
    def _editable(kyc: RiderKyc) -> RiderKyc:
        if kyc.status not in EDITABLE:
            raise InvalidTransition(
                "Your KYC is with the team for review"
                if kyc.status == "submitted"
                else f"Your KYC is {kyc.status.replace('_', ' ')}"
            )
        return kyc

    @staticmethod
    def missing(kyc: RiderKyc) -> list[str]:
        """What is still needed before the KYC can be submitted, in the order the app shows it."""
        out = []
        if not kyc.permanent_address.strip():
            out.append("permanent address")
        if not NIN.match(kyc.nin or ""):
            out.append("NIN")
        out += [label for kind, label in KYC_DOCUMENTS.items() if kind not in kyc.documents]
        guarantors = [*kyc.guarantors, Guarantor(), Guarantor()][:2]
        for n, g in enumerate(guarantors, start=1):
            if not all(part.strip() for part in (g.name, g.phone, g.address, g.occupation)):
                out.append(f"guarantor {n}'s details")
        return out

    def view(self, kyc: RiderKyc, *, reviewer: bool) -> dict[str, Any]:
        data = kyc.model_dump(mode="json")
        data["documents"] = {
            kind: {
                "label": label,
                "uploaded": kind in kyc.documents,
                "content_type": kyc.documents[kind].content_type if kind in kyc.documents else None,
                "uploaded_at": data["documents"].get(kind, {}).get("uploaded_at"),
                "needs_change": kind in kyc.changes_needed,
            }
            for kind, label in KYC_DOCUMENTS.items()
        }
        if not reviewer:
            data["nin"] = mask_nin(kyc.nin)
        data["missing"] = self.missing(kyc)
        data["editable"] = kyc.status in EDITABLE
        return data


__all__ = ["KycDecisionInput", "KycDetailsInput", "KycUploadInput", "RiderKycService", "mask_nin"]
