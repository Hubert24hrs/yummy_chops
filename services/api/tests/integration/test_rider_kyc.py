"""Rider sign-up and KYC, checked by hand by the team (docs/adr/0027-rider-kyc.md)."""

from __future__ import annotations

import base64

import httpx

from conftest import _p, auth
from gudmeal_api.container import Container
from gudmeal_api.domain.models import KYC_DOCUMENTS

JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 64
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64
PDF = b"%PDF-1.4\n" + b"\x00" * 64

SIGN_UP = {
    "full_name": "Bayo Rider",
    "phone": "+2348033333333",
    "email": "bayo@gmail.com",
    "residential_address": "12 Admiralty Way, Lekki",
}
DETAILS = {
    "permanent_address": "4 Ogui Road, Enugu",
    "nin": "123 4567 8901",
    "guarantors": [
        {
            "name": "Ada Obi",
            "phone": "+2348011111111",
            "email": "ada@gmail.com",
            "address": "5 Bisola Durosinmi-Etti Drive, Lekki",
            "occupation": "Teacher",
        },
        {
            "name": "Musa Bello",
            "phone": "+2348022222222",
            "email": "",
            "address": "7 Ajose Adeogun Street, Victoria Island",
            "occupation": "Trader",
        },
    ],
}


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


async def sign_up(client: httpx.AsyncClient, container: Container) -> dict:
    r = await client.post("/v1/applications/rider", json=SIGN_UP, headers=auth("customer2"))
    assert r.status_code == 201, r.text
    # The app refreshes the sign-in token, which now carries the rider role.
    verifier = getattr(container.verifier, "_fallback", container.verifier)
    verifier.principals["new_rider"] = _p("cust-2", "rider", name="Bayo Rider")
    return r.json()


async def complete(client: httpx.AsyncClient) -> dict:
    r = await client.put("/v1/rider/kyc", json=DETAILS, headers=auth("new_rider"))
    assert r.status_code == 200, r.text
    for kind in KYC_DOCUMENTS:
        r = await client.post(
            f"/v1/rider/kyc/documents/{kind}",
            json={"data": b64(PDF if kind.endswith("_form") else JPEG)},
            headers=auth("new_rider"),
        )
        assert r.status_code == 200, r.text
    return r.json()


async def test_a_new_rider_signs_up_completes_kyc_and_is_verified(client, container):
    app = await sign_up(client, container)

    # Signing up gives the rider app at once, with a pending profile: no going online before the team checks.
    assert "rider" in (await container.identity.get_claims("cust-2"))["roles"]
    profile = (await client.get("/v1/rider/profile", headers=auth("new_rider"))).json()
    assert profile["status"] == "pending" and profile["verified_at"] is None
    r = await client.put("/v1/rider/availability", json={"online": True}, headers=auth("new_rider"))
    assert r.status_code == 403 and "verified your KYC" in r.json()["error"]["message"]

    kyc = (await client.get("/v1/rider/kyc", headers=auth("new_rider"))).json()
    assert kyc["status"] == "draft" and kyc["full_name"] == "Bayo Rider"
    assert (
        kyc["whatsapp_phone"] == SIGN_UP["phone"]
        and kyc["residential_address"] == SIGN_UP["residential_address"]
    )
    assert list(kyc["documents"]) == list(KYC_DOCUMENTS) and "NIN" in kyc["missing"]

    # Nothing can be submitted half done.
    r = await client.post("/v1/rider/kyc/submit", headers=auth("new_rider"))
    assert r.status_code == 422 and "permanent address" in r.json()["error"]["message"]
    # The team cannot verify an unfinished KYC either.
    r = await client.post(
        f"/v1/admin/applications/{app['id']}/decision", json={"approve": True}, headers=auth("admin")
    )
    assert r.status_code == 409, r.text

    kyc = await complete(client)
    assert kyc["missing"] == [] and kyc["nin"] == "•••••••8901"  # the rider sees only the last four digits
    assert all(doc["uploaded"] for doc in kyc["documents"].values())
    r = await client.post("/v1/rider/kyc/submit", headers=auth("new_rider"))
    assert r.status_code == 200 and r.json()["status"] == "submitted" and r.json()["editable"] is False
    # Submitted means with the team: no more changes until they answer.
    r = await client.put(
        "/v1/rider/kyc", json={"permanent_address": "Somewhere else"}, headers=auth("new_rider")
    )
    assert r.status_code == 409

    # The team sees it, the full NIN and every photo.
    queue = (await client.get("/v1/admin/rider-kyc?status=submitted", headers=auth("admin"))).json()
    assert [k["uid"] for k in queue] == ["cust-2"] and queue[0]["nin"] == "•••••••8901"
    detail = (await client.get("/v1/admin/rider-kyc/cust-2", headers=auth("admin"))).json()
    assert detail["nin"] == "12345678901" and detail["guarantors"][1]["name"] == "Musa Bello"
    photo = await client.get("/v1/admin/rider-kyc/cust-2/documents/face", headers=auth("admin"))
    assert (
        photo.status_code == 200 and photo.content == JPEG and photo.headers["content-type"] == "image/jpeg"
    )
    assert photo.headers["cache-control"] == "private, no-store"

    r = await client.post(
        "/v1/admin/rider-kyc/cust-2/decision",
        json={"approve": True, "note": "All checked"},
        headers=auth("admin"),
    )
    assert r.status_code == 200 and r.json()["status"] == "verified"
    profile = (await client.get("/v1/rider/profile", headers=auth("new_rider"))).json()
    assert profile["status"] == "active" and profile["verified_at"]  # the Verified badge
    application = (await client.get("/v1/applications/mine", headers=auth("customer2"))).json()
    assert application[0]["status"] == "approved"
    r = await client.put("/v1/rider/availability", json={"online": True}, headers=auth("new_rider"))
    assert r.status_code == 200 and r.json()["is_online"] is True


async def test_the_team_can_ask_for_changes_and_the_rider_fixes_them(client, container):
    await sign_up(client, container)
    await complete(client)
    assert (await client.post("/v1/rider/kyc/submit", headers=auth("new_rider"))).status_code == 200

    r = await client.post(
        "/v1/admin/rider-kyc/cust-2/decision",
        json={
            "approve": False,
            "note": "The plate number photo is blurred",
            "changes_needed": ["plate_number"],
        },
        headers=auth("admin"),
    )
    assert r.status_code == 200 and r.json()["status"] == "needs_changes"
    kyc = (await client.get("/v1/rider/kyc", headers=auth("new_rider"))).json()
    assert kyc["editable"] and kyc["review_note"] == "The plate number photo is blurred"
    assert kyc["documents"]["plate_number"]["needs_change"] is True

    r = await client.post(
        "/v1/rider/kyc/documents/plate_number", json={"data": b64(PNG)}, headers=auth("new_rider")
    )
    assert r.status_code == 200
    r = await client.post("/v1/rider/kyc/submit", headers=auth("new_rider"))
    assert r.status_code == 200 and r.json()["status"] == "submitted" and r.json()["changes_needed"] == []

    # Unknown items and empty answers are refused.
    r = await client.post(
        "/v1/admin/rider-kyc/cust-2/decision",
        json={"approve": False, "changes_needed": ["horoscope"]},
        headers=auth("admin"),
    )
    assert r.status_code == 422


async def test_uploads_are_checked_and_private(client, container):
    await sign_up(client, container)

    async def upload(kind: str, data: bytes | str, who: str = "new_rider") -> httpx.Response:
        payload = data if isinstance(data, str) else b64(data)
        return await client.post(f"/v1/rider/kyc/documents/{kind}", json={"data": payload}, headers=auth(who))

    assert (await upload("face", b"GIF89a" + b"\x00" * 30)).status_code == 422  # not a JPEG, PNG or WebP
    assert (await upload("face", PDF)).status_code == 422  # photos must be pictures
    assert (await upload("guarantor_1_form", PDF)).status_code == 200  # a signed form may be a scanned PDF
    assert (await upload("face", "not base64!")).status_code == 422
    assert (
        await upload("face", b"\xff\xd8\xff" + b"\x00" * (5 * 1024 * 1024))
    ).status_code == 422  # over 5 MB
    assert (await upload("passport", JPEG)).status_code == 404
    assert (
        await upload("face", "data:image/png;base64," + b64(PNG))
    ).status_code == 200  # a browser's data URL

    own = await client.get("/v1/rider/kyc/documents/face", headers=auth("new_rider"))
    assert own.status_code == 200 and own.content == PNG
    # Another rider cannot see them, and neither can a customer.
    assert (
        await client.get("/v1/admin/rider-kyc/cust-2/documents/face", headers=auth("rider1"))
    ).status_code == 403
    assert (await client.get("/v1/admin/rider-kyc/cust-2", headers=auth("customer"))).status_code == 403
    assert (await client.get("/v1/rider/kyc", headers=auth("customer"))).status_code == 403

    r = await client.put("/v1/rider/kyc", json={"nin": "1234"}, headers=auth("new_rider"))
    assert r.status_code == 422 and "11 digits" in r.json()["error"]["message"]
    bad_email = {
        **DETAILS,
        "guarantors": [{**DETAILS["guarantors"][0], "email": "not-an-email"}, DETAILS["guarantors"][1]],
    }
    assert (await client.put("/v1/rider/kyc", json=bad_email, headers=auth("new_rider"))).status_code == 422


async def test_turning_down_a_sign_up_keeps_the_rider_offline(client, container):
    app = await sign_up(client, container)
    r = await client.post(
        f"/v1/admin/applications/{app['id']}/decision",
        json={"approve": False, "reason": "Under 18"},
        headers=auth("admin"),
    )
    assert r.status_code == 200 and r.json()["status"] == "rejected"
    profile = (await client.get("/v1/rider/profile", headers=auth("new_rider"))).json()
    assert profile["status"] == "suspended"
    assert (await client.get("/v1/rider/kyc", headers=auth("new_rider"))).json()["status"] == "rejected"
    r = await client.put("/v1/rider/availability", json={"online": True}, headers=auth("new_rider"))
    assert r.status_code == 403
