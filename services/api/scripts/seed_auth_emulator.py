"""Create demo users with roles in the **Firebase Auth emulator** (never a real project).

Usage (from services/api):
    set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
    uv run python scripts/seed_auth_emulator.py

Each demo user gets the password from DEMO_USER_PASSWORD (default only valid for the emulator). With
REMOTE_TESTER_PASSWORD set (from .env.remote-link), the public test link's account tester@yummychops.test is
created too, with that password: the link lets only this account sign in (docs/adr/0024-public-test-link.md).
"""

from __future__ import annotations

import os
import sys

import firebase_admin
from firebase_admin import auth

if not os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
    sys.exit(
        "Refusing to run: FIREBASE_AUTH_EMULATOR_HOST is not set (this script only targets the emulator)."
    )

PROJECT = os.environ.get("FIREBASE_PROJECT_ID", "demo-gudmeal")
PASSWORD = os.environ.get("DEMO_USER_PASSWORD", "gudmeal-demo-123")
TESTER_PASSWORD = os.environ.get("REMOTE_TESTER_PASSWORD", "").strip()
TESTER = ("demo-tester-1", "tester@yummychops.test", "Test Customer", [], {})

USERS = [
    ("demo-customer-1", "customer@yummychops.test", "Ada Customer", [], {}),
    ("demo-customer-2", "friend@yummychops.test", "Bayo Friend", [], {}),  # group orders need two people
    (
        "demo-owner-1",
        "owner@yummychops.test",
        "Jollof Junction Owner",
        ["restaurant_owner"],
        {"r-jollof-junction": "owner"},
    ),
    (
        "demo-kitchen-1",
        "kitchen@yummychops.test",
        "Jollof Junction Kitchen",
        ["restaurant_staff"],
        {"r-jollof-junction": "staff"},
    ),
    ("demo-rider-1", "rider@yummychops.test", "Chidi Okafor", ["rider"], {}),
    ("demo-support-1", "support@yummychops.test", "Support Agent", ["support_agent"], {}),
    ("demo-finance-1", "finance@yummychops.test", "Finance Manager", ["finance_manager"], {}),
    ("demo-hub-1", "hub@yummychops.test", "Hub Agent", ["hub_agent"], {}),
    ("demo-admin-1", "admin@yummychops.test", "Super Admin", ["super_admin"], {}),
]


def _upsert(user: tuple, password: str) -> None:
    uid, email, name, roles, restaurant_roles = user
    try:
        auth.get_user(uid)
        auth.update_user(uid, email=email, password=password, display_name=name, email_verified=True)
    except auth.UserNotFoundError:
        auth.create_user(uid=uid, email=email, password=password, display_name=name, email_verified=True)
    auth.set_custom_user_claims(uid, {"roles": roles, "restaurant_roles": restaurant_roles})
    print(f"  {email:<26} roles={roles or ['customer']}")


def main() -> None:
    firebase_admin.initialize_app(options={"projectId": PROJECT})
    for user in USERS:
        _upsert(user, PASSWORD)
    print(f"Seeded {len(USERS)} emulator users (password from DEMO_USER_PASSWORD).")
    if TESTER_PASSWORD:
        _upsert(TESTER, TESTER_PASSWORD)
        print("Seeded the test link's tester account (password from REMOTE_TESTER_PASSWORD).")


if __name__ == "__main__":
    main()
