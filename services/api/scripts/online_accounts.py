"""Staff accounts for the ONLINE test server (ADR-0026): a real Firebase project, never the emulator.

Customers sign up in the app by themselves. This script makes the few staff logins the owner needs to play the
other side of an order: a rider (the rider app), a shop owner (the partner dashboard) and an admin (the Command
Centre). Their uids are the demo data's, so the rider is the seeded rider profile and the owner owns Jollof Junction.

Each account gets its OWN random password (never the emulator's demo password, which is public in this repository).
The passwords are written to the git-ignored file `.env.online-accounts` at the repository root and are never
printed. Running the script again keeps the passwords already in that file.

Needs: `gcloud` signed in as an owner of the project, and Email/Password sign-in switched on in Firebase.

Usage (from the repository root):
    services/api/.venv/Scripts/python services/api/scripts/online_accounts.py yummy-chops-dev
"""

from __future__ import annotations

import json
import secrets
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SECRETS_FILE = ROOT / ".env.online-accounts"

ACCOUNTS = [
    ("demo-rider-1", "rider@yummychops.test", "Chidi Okafor", ["rider"], {}),
    (
        "demo-owner-1",
        "owner@yummychops.test",
        "Jollof Junction Owner",
        ["restaurant_owner"],
        {"r-jollof-junction": "owner"},
    ),
    ("demo-admin-1", "admin@yummychops.test", "Super Admin", ["super_admin"], {}),
]


def access_token() -> str:
    gcloud = shutil.which("gcloud") or shutil.which("gcloud.cmd")
    if not gcloud:
        sys.exit("gcloud is not installed or not on PATH")
    out = subprocess.run([gcloud, "auth", "print-access-token"], capture_output=True, text=True, check=True)  # noqa: S603  (fixed command)
    return out.stdout.strip()


def call(project: str, token: str, path: str, body: dict) -> dict:
    req = urllib.request.Request(
        f"https://identitytoolkit.googleapis.com/v1/projects/{project}/{path}",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "x-goog-user-project": project,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as res:  # noqa: S310  (fixed https URL)
            return json.loads(res.read() or b"{}")
    except urllib.error.HTTPError as e:
        message = json.loads(e.read() or b"{}").get("error", {}).get("message", str(e))
        raise SystemExit(f"Firebase refused {path}: {message}") from None


def saved_passwords() -> dict[str, str]:
    if not SECRETS_FILE.exists():
        return {}
    pairs = {}
    for line in SECRETS_FILE.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            email, _, password = line.partition("=")
            pairs[email.strip()] = password.strip()
    return pairs


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    project = sys.argv[1]
    if project.startswith("demo-") or project.endswith("-prod"):
        sys.exit(f"Refusing {project}: this script is for the online TEST server only")
    token = access_token()
    passwords = saved_passwords()
    for uid, email, name, roles, restaurant_roles in ACCOUNTS:
        password = passwords.get(email) or secrets.token_urlsafe(12)
        passwords[email] = password
        found = call(project, token, "accounts:lookup", {"localId": [uid]}).get("users")
        profile = {"email": email, "password": password, "displayName": name, "emailVerified": True}
        if found:
            call(project, token, "accounts:update", {"localId": uid, **profile})
        else:
            call(project, token, "accounts", {"localId": uid, **profile})
        claims = {"roles": roles, "restaurant_roles": restaurant_roles}
        call(project, token, "accounts:update", {"localId": uid, "customAttributes": json.dumps(claims)})
        print(f"  {email:<26} roles={roles}")
    SECRETS_FILE.write_text(
        "# Staff logins for the ONLINE test server (made by services/api/scripts/online_accounts.py).\n"
        "# Git-ignored: keep these to yourself. Format: email=password\n"
        + "".join(f"{email}={pw}\n" for email, pw in passwords.items()),
        encoding="utf-8",
        newline="\n",
    )
    print(f"Passwords saved in {SECRETS_FILE.name} (git-ignored; not printed here).")


if __name__ == "__main__":
    main()
