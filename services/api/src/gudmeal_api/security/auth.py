"""Firebase ID token and App Check verification."""

from __future__ import annotations

import asyncio
import logging
from typing import Any, Protocol

import firebase_admin
from firebase_admin import app_check, auth

from ..errors import PermissionDenied, Unauthenticated
from .rbac import RESTAURANT_ROLE_NAMES, Principal, Role

logger = logging.getLogger(__name__)


class TokenVerifier(Protocol):
    async def verify(self, token: str) -> Principal: ...


class AppCheckVerifier(Protocol):
    async def verify(self, token: str) -> None: ...


def principal_from_claims(claims: dict[str, Any], token: str | None = None) -> Principal:
    raw_roles = claims.get("roles")
    if not isinstance(raw_roles, list | tuple):
        raw_roles = []  # roles are set as a list (scripts, the Command Centre); anything else counts as none
    roles = {r for r in raw_roles if isinstance(r, str) and r in {x.value for x in Role}}
    roles.add(Role.CUSTOMER.value)  # every signed-in user can order food
    raw_restaurants = claims.get("restaurant_roles") or {}
    restaurant_roles = (
        {
            str(rid): str(role)
            for rid, role in raw_restaurants.items()
            if isinstance(rid, str) and role in RESTAURANT_ROLE_NAMES
        }
        if isinstance(raw_restaurants, dict)
        else {}
    )
    return Principal(
        uid=str(claims.get("uid") or claims.get("sub") or claims.get("user_id")),
        roles=frozenset(roles),
        restaurant_roles=restaurant_roles,
        email=claims.get("email"),
        phone=claims.get("phone_number"),
        name=claims.get("name"),
        email_verified=bool(claims.get("email_verified")),
        token=token,
    )


def get_firebase_app(project_id: str) -> firebase_admin.App:
    try:
        return firebase_admin.get_app()
    except ValueError:
        # Uses Application Default Credentials on Cloud Run; FIREBASE_AUTH_EMULATOR_HOST locally.
        return firebase_admin.initialize_app(options={"projectId": project_id})


class FirebaseTokenVerifier:
    def __init__(self, app: firebase_admin.App, *, check_revoked: bool = True) -> None:
        self._app = app
        self._check_revoked = check_revoked

    async def verify(self, token: str) -> Principal:
        try:
            claims = await asyncio.to_thread(
                auth.verify_id_token, token, app=self._app, check_revoked=self._check_revoked
            )
        except auth.RevokedIdTokenError as exc:
            raise Unauthenticated("Session revoked; please sign in again") from exc
        except auth.UserDisabledError as exc:
            raise PermissionDenied("This account is disabled") from exc
        except (auth.InvalidIdTokenError, auth.ExpiredIdTokenError, ValueError) as exc:
            raise Unauthenticated("Invalid or expired ID token") from exc
        except auth.CertificateFetchError as exc:
            logger.exception("Could not fetch Firebase certificates")
            raise Unauthenticated("Unable to verify credentials right now") from exc
        return principal_from_claims(claims, token)


class FirebaseAppCheckVerifier:
    def __init__(self, app: firebase_admin.App) -> None:
        self._app = app

    async def verify(self, token: str) -> None:
        try:
            await asyncio.to_thread(app_check.verify_token, token, app=self._app)
        except Exception as exc:  # the SDK raises ValueError/jwt errors for invalid tokens
            raise Unauthenticated("Invalid App Check token") from exc


class StaticTokenVerifier:
    """Test double: maps opaque tokens to principals."""

    def __init__(self, principals: dict[str, Principal] | None = None) -> None:
        self.principals = dict(principals or {})

    async def verify(self, token: str) -> Principal:
        principal = self.principals.get(token)
        if principal is None:
            raise Unauthenticated("Invalid or expired ID token")
        return Principal(
            uid=principal.uid,
            roles=principal.roles,
            restaurant_roles=principal.restaurant_roles,
            email=principal.email,
            phone=principal.phone,
            name=principal.name,
            email_verified=principal.email_verified,
            token=token,
        )
