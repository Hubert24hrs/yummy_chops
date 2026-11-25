"""Customers connect their WhatsApp number to Yummy Chops (ADR-0017)."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter

from ..deps import Ctr, CurrentPrincipal

router = APIRouter(prefix="/v1/me/whatsapp", tags=["whatsapp"])


@router.get("")
async def whatsapp_status(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.whatsapp.status(principal)


@router.post("/link-code", status_code=201)
async def whatsapp_link_code(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """An 8-digit code (10 minutes, single use) and a wa.me link that pre-fills 'LINK <code>'."""
    return await c.whatsapp.create_link_code(principal)


@router.delete("")
async def whatsapp_disconnect(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.whatsapp.unlink(principal)
