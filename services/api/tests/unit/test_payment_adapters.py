"""Provider adapters against their documented HTTP contracts (mock transport; no network, no real keys)."""

from __future__ import annotations

import hashlib
import hmac
import json

import httpx
import pytest

from gudmeal_api.errors import PaymentProviderError
from gudmeal_api.payments.flutterwave import FlutterwaveProvider
from gudmeal_api.payments.paystack import PaystackProvider

SK = "sk_test_unit_only"


def transport(
    routes: dict[tuple[str, str], tuple[int, dict]], seen: list[httpx.Request]
) -> httpx.MockTransport:
    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        status, body = routes[(request.method, request.url.path)]
        return httpx.Response(status, json=body)

    return httpx.MockTransport(handler)


class TestPaystack:
    async def test_initialize_sends_kobo_and_reference(self):
        seen: list[httpx.Request] = []
        routes = {
            ("POST", "/transaction/initialize"): (
                200,
                {
                    "status": True,
                    "data": {
                        "authorization_url": "https://checkout.paystack.com/abc",
                        "access_code": "abc",
                        "reference": "YC-1",
                    },
                },
            )
        }
        async with httpx.AsyncClient(transport=transport(routes, seen)) as http:
            p = PaystackProvider(SK, http=http)
            res = await p.initialize(
                reference="YC-1",
                amount_kobo=945_000,
                email="a@b.co",
                currency="NGN",
                callback_url="https://yummy247.com/cb",
                metadata={"order_id": "o1"},
            )
        assert res.authorization_url == "https://checkout.paystack.com/abc"
        body = json.loads(seen[0].content)
        assert body["amount"] == "945000" and body["reference"] == "YC-1" and body["currency"] == "NGN"
        assert seen[0].headers["Authorization"] == f"Bearer {SK}"
        assert json.loads(body["metadata"])["order_id"] == "o1"

    async def test_verify_maps_status_and_amount(self):
        seen: list[httpx.Request] = []
        routes = {
            ("GET", "/transaction/verify/YC-1"): (
                200,
                {
                    "status": True,
                    "data": {
                        "id": 4099,
                        "status": "success",
                        "reference": "YC-1",
                        "amount": 945000,
                        "currency": "NGN",
                        "channel": "card",
                        "paid_at": "2026-11-14T18:00:00.000Z",
                        "gateway_response": "Approved",
                    },
                },
            )
        }
        async with httpx.AsyncClient(transport=transport(routes, seen)) as http:
            res = await PaystackProvider(SK, http=http).verify("YC-1")
        assert (res.status, res.amount_kobo, res.currency, res.provider_transaction_id) == (
            "success",
            945000,
            "NGN",
            "4099",
        )
        assert res.paid_at is not None and res.paid_at.tzinfo is not None

    async def test_errors_raise_provider_error(self):
        seen: list[httpx.Request] = []
        routes = {
            ("GET", "/transaction/verify/bad"): (400, {"status": False, "message": "Transaction not found"})
        }
        async with httpx.AsyncClient(transport=transport(routes, seen)) as http:
            with pytest.raises(PaymentProviderError, match="Transaction not found"):
                await PaystackProvider(SK, http=http).verify("bad")

    async def test_refund(self):
        seen: list[httpx.Request] = []
        routes = {("POST", "/refund"): (200, {"status": True, "data": {"id": 77, "status": "pending"}})}
        async with httpx.AsyncClient(transport=transport(routes, seen)) as http:
            res = await PaystackProvider(SK, http=http).refund(
                reference="YC-1", provider_transaction_id="4099", amount_kobo=50_000
            )
        assert res.provider_refund_id == "77" and res.status == "pending"
        assert json.loads(seen[0].content) == {"transaction": "4099", "amount": "50000"}

    def test_webhook_signature_hmac_sha512(self):
        p = PaystackProvider(SK, http=httpx.AsyncClient())
        body = json.dumps({"event": "charge.success", "data": {"id": 1, "reference": "YC-1"}}).encode()
        good = hmac.new(SK.encode(), body, hashlib.sha512).hexdigest()
        assert p.verify_webhook(body, {"x-paystack-signature": good}, "1.2.3.4")
        assert not p.verify_webhook(body, {"x-paystack-signature": good[:-1] + "0"}, None)
        assert not p.verify_webhook(body + b" ", {"x-paystack-signature": good}, None)
        assert not p.verify_webhook(body, {}, None)
        event = p.parse_webhook(body)
        assert (event.event_type, event.reference, event.dedupe_key) == (
            "charge.success",
            "YC-1",
            "charge.success:1",
        )

    def test_ip_allowlist(self):
        p = PaystackProvider(SK, http=httpx.AsyncClient(), ip_allowlist=["52.31.139.75"])
        body = b"{}"
        sig = hmac.new(SK.encode(), body, hashlib.sha512).hexdigest()
        assert p.verify_webhook(body, {"x-paystack-signature": sig}, "52.31.139.75")
        assert not p.verify_webhook(body, {"x-paystack-signature": sig}, "8.8.8.8")


class TestFlutterwave:
    async def test_initialize_converts_to_naira(self):
        seen: list[httpx.Request] = []
        routes = {
            ("POST", "/v3/payments"): (200, {"status": "success", "data": {"link": "https://checkout.flw/x"}})
        }
        async with httpx.AsyncClient(transport=transport(routes, seen)) as http:
            p = FlutterwaveProvider("FLWSECK_TEST-x", "hash", http=http)
            res = await p.initialize(
                reference="YC-2",
                amount_kobo=945_025,
                email="a@b.co",
                currency="NGN",
                callback_url="https://yummy247.com/cb",
                metadata={},
                customer_phone="+234800",
            )
        body = json.loads(seen[0].content)
        assert res.authorization_url == "https://checkout.flw/x"
        assert body["amount"] == "9450.25" and body["tx_ref"] == "YC-2"
        assert body["customer"] == {"email": "a@b.co", "phonenumber": "+234800"}

    async def test_verify_converts_back_to_kobo(self):
        seen: list[httpx.Request] = []
        routes = {
            ("GET", "/v3/transactions/verify_by_reference"): (
                200,
                {
                    "status": "success",
                    "data": {
                        "id": 555,
                        "tx_ref": "YC-2",
                        "status": "successful",
                        "amount": 9450.25,
                        "currency": "NGN",
                    },
                },
            )
        }
        async with httpx.AsyncClient(transport=transport(routes, seen)) as http:
            res = await FlutterwaveProvider("k", "h", http=http).verify("YC-2")
        assert (res.status, res.amount_kobo, res.provider_transaction_id) == ("success", 945_025, "555")
        assert seen[0].url.params["tx_ref"] == "YC-2"

    def test_webhook_verif_hash(self):
        p = FlutterwaveProvider("k", "s3cret-hash", http=httpx.AsyncClient())
        body = json.dumps(
            {"event": "charge.completed", "data": {"id": 9, "tx_ref": "YC-2", "status": "successful"}}
        ).encode()
        assert p.verify_webhook(body, {"verif-hash": "s3cret-hash"}, None)
        assert not p.verify_webhook(body, {"verif-hash": "wrong"}, None)
        assert not p.verify_webhook(body, {}, None)
        ev = p.parse_webhook(body)
        assert ev.event_type == "charge.success" and ev.reference == "YC-2"
        failed = p.parse_webhook(
            json.dumps({"event": "charge.completed", "data": {"id": 9, "status": "failed"}}).encode()
        )
        assert failed.event_type == "charge.failed" and failed.dedupe_key != ev.dedupe_key


def test_paystack_refund_events_name_the_payment_not_the_refund():
    p = PaystackProvider(SK, http=httpx.AsyncClient())
    data = {
        "status": "processed",
        "transaction_reference": "YC-1",
        "refund_reference": "1320",
        "amount": "5000",
    }
    event = p.parse_webhook(json.dumps({"event": "refund.processed", "data": data}).encode())
    assert (event.event_type, event.reference, event.dedupe_key) == (
        "refund.processed",
        "YC-1",
        "refund.processed:1320",
    )
    assert event.data["transaction_reference"] == "YC-1" and event.data["amount"] == "5000"
    pending = p.parse_webhook(json.dumps({"event": "refund.pending", "data": data}).encode())
    assert pending.event_type == "refund.pending"


def test_signatures_outside_ascii_are_wrong_not_an_error():
    body = b"{}"
    assert not PaystackProvider(SK, http=httpx.AsyncClient()).verify_webhook(
        body, {"x-paystack-signature": "caf\u00e9"}, None
    )
    assert not FlutterwaveProvider("k", "hash", http=httpx.AsyncClient()).verify_webhook(
        body, {"verif-hash": "caf\u00e9"}, None
    )


async def test_a_timeout_is_an_unknown_outcome_but_a_failed_connection_is_a_refusal():
    from gudmeal_api.payments.base import ProviderOutcomeUnknown

    def timeout(request: httpx.Request) -> httpx.Response:
        raise httpx.ReadTimeout("slow", request=request)

    def unreachable(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("down", request=request)

    async with httpx.AsyncClient(transport=httpx.MockTransport(timeout)) as http:
        with pytest.raises(ProviderOutcomeUnknown):
            await PaystackProvider(SK, http=http).refund(
                reference="r", provider_transaction_id="1", amount_kobo=1
            )
    async with httpx.AsyncClient(transport=httpx.MockTransport(unreachable)) as http:
        with pytest.raises(PaymentProviderError) as caught:
            await PaystackProvider(SK, http=http).refund(
                reference="r", provider_transaction_id="1", amount_kobo=1
            )
        assert not isinstance(caught.value, ProviderOutcomeUnknown)
