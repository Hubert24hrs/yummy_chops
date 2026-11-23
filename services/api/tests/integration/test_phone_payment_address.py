"""Phone tests: "Pay by card, transfer or USSD" opens the payment page at an address the phone can reach.

The owner's phone opened the sandbox page at 10.2.0.2, the laptop's VPN tunnel address, and waited forever: the
laptop guessed its own address, and with a VPN connected that guess is the VPN's. The page now opens at the
address the phone reached the API at (docs/adr/0020-test-apps-find-the-test-server.md).
"""

from __future__ import annotations

from collections.abc import AsyncIterator, Iterator

import httpx
import pytest

from conftest import Flow, auth, idem, make_container
from gudmeal_api import lan
from gudmeal_api.container import Container
from gudmeal_api.main import create_app

PHONE_SEES = "http://192.168.100.8:8000"  # the laptop's Wi-Fi address, as the phone reaches it
VPN_GUESS = "10.2.0.2"  # what the laptop guesses for itself while Proton VPN is connected


@pytest.fixture(autouse=True)
def _fresh(monkeypatch: pytest.MonkeyPatch) -> Iterator[None]:
    lan.forget_devices()
    monkeypatch.setattr(lan, "current_lan_address", lambda: VPN_GUESS)
    yield
    lan.forget_devices()


@pytest.fixture
async def phone_test() -> AsyncIterator[Container]:
    """The API as `node scripts/dev.mjs api --lan` runs it: the sandbox follows the phone."""
    c = await make_container(public_base_url=PHONE_SEES, sandbox_follows_lan_address=True)
    yield c
    await c.close()


def _client(c: Container, base_url: str) -> httpx.AsyncClient:
    return httpx.AsyncClient(
        transport=httpx.ASGITransport(app=create_app(c.settings, container=c)), base_url=base_url
    )


async def _checkout(client: httpx.AsyncClient, c: Container) -> dict:
    order = await Flow(client, c).order()
    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 200, r.text
    return r.json() | {"order_id": order["id"]}


async def test_the_phone_pays_at_the_address_it_reached_the_api_at(phone_test: Container) -> None:
    async with _client(phone_test, PHONE_SEES) as phone:
        started = await _checkout(phone, phone_test)
        assert started["authorization_url"] == f"{PHONE_SEES}/v1/dev/sandbox-checkout/{started['reference']}"
        assert VPN_GUESS not in started["authorization_url"]

        # The phone opens that page and approves; back in the app, the order is verified as paid.
        page = await phone.get(started["authorization_url"])
        assert page.status_code == 200 and "Approve payment" in page.text
        done = await phone.post(f"/v1/dev/sandbox-checkout/{started['reference']}/complete?outcome=success")
        assert done.status_code in (200, 303)
        verified = await phone.post(
            "/v1/payments/verify", json={"reference": started["reference"]}, headers=auth("customer")
        )
        assert verified.status_code == 200, verified.text
        order = (await phone.get(f"/v1/orders/{started['order_id']}", headers=auth("customer"))).json()
        assert order["payment"]["status"] == "paid"


async def test_a_page_asked_for_through_localhost_opens_where_the_phone_reached_the_api(
    phone_test: Container,
) -> None:
    # Yummy (the assistant) and the websites call the API at localhost; the payer is still the phone on the Wi-Fi.
    async with (
        _client(phone_test, PHONE_SEES) as phone,
        _client(phone_test, "http://localhost:8000") as local,
    ):
        assert (await phone.get("/v1/health")).status_code == 200  # the phone has been talking to the API
        started = await _checkout(local, phone_test)
        assert started["authorization_url"].startswith(f"{PHONE_SEES}/v1/dev/sandbox-checkout/")


async def test_before_any_phone_the_laptops_own_guess_is_used(phone_test: Container) -> None:
    async with _client(phone_test, "http://localhost:8000") as local:
        started = await _checkout(local, phone_test)
    assert started["authorization_url"].startswith(
        f"http://{VPN_GUESS}:8000/"
    )  # the guess (tested in unit tests)


# ---------------------------------------------------------------------------------------- back to the app
# Paystack test mode on a phone (docs/PAYSTACK_TEST_MODE.md): after paying, the payment page sends the payer to
# PAYMENT_CALLBACK_URL, the website on the laptop's localhost, which the phone cannot open. In phone tests the
# payer comes back to the API's own "return to the app" page instead, at the address the phone reached it at.


@pytest.fixture
async def website_on_localhost() -> AsyncIterator[Container]:
    """The API as `node scripts/dev.mjs api --lan` runs it, with the website's callback page on localhost."""
    c = await make_container(
        public_base_url=PHONE_SEES,
        sandbox_follows_lan_address=True,
        payment_callback_url="http://localhost:3000/checkout/callback",
    )
    yield c
    await c.close()


async def test_after_paying_the_phone_comes_back_to_a_page_it_can_open(
    website_on_localhost: Container,
) -> None:
    c = website_on_localhost
    async with _client(c, PHONE_SEES) as phone:
        started = await _checkout(phone, c)
        done = await phone.post(f"/v1/dev/sandbox-checkout/{started['reference']}/complete?outcome=success")
        assert done.status_code == 303, done.text
        back = done.headers["location"]
        assert back.startswith(f"{PHONE_SEES}/v1/dev/payment-return?order_id={started['order_id']}&")
        page = await phone.get(back)
        assert page.status_code == 200
        assert "Payment approved" in page.text and "Return to the Yummy Chops app" in page.text


async def test_the_return_page_asks_the_provider_and_never_trusts_the_redirect(
    website_on_localhost: Container,
) -> None:
    c = website_on_localhost
    async with _client(c, PHONE_SEES) as phone:
        started = await _checkout(phone, c)
        # Paystack adds `trxref` and `reference`; arriving here without having paid changes nothing.
        page = await phone.get(
            f"/v1/dev/payment-return?order_id={started['order_id']}&trxref={started['reference']}"
        )
        assert page.status_code == 200 and "Payment approved" not in page.text
        order = (await phone.get(f"/v1/orders/{started['order_id']}", headers=auth("customer"))).json()
        assert order["payment"]["status"] != "paid"
        unknown = await phone.get("/v1/dev/payment-return?reference=YC-NOT-A-PAYMENT")
        assert unknown.status_code == 200 and "Return to the Yummy Chops app" in unknown.text


async def test_the_website_keeps_its_own_callback_page_outside_phone_tests() -> None:
    from gudmeal_api.config import Settings
    from gudmeal_api.container import _payment_callback_url

    website = "http://localhost:3000/checkout/callback"
    assert _payment_callback_url(Settings(environment="test", payment_callback_url=website)) == website
    online = Settings(
        environment="development", payment_callback_url=website, sandbox_follows_lan_address=True
    )
    assert _payment_callback_url(online) == website  # the return page exists only on local and test servers
    phone = Settings(environment="test", payment_callback_url=website, sandbox_follows_lan_address=True)
    follows = _payment_callback_url(phone)
    assert callable(follows) and follows().endswith("/v1/dev/payment-return")
