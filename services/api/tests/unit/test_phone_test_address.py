"""Phone tests: the payment sandbox page opens at the address this computer has on its Wi-Fi right now."""

from __future__ import annotations

import socket
from collections.abc import Iterator

import httpx
import pytest

from gudmeal_api import container as container_mod
from gudmeal_api import lan
from gudmeal_api.config import Settings
from gudmeal_api.payments.sandbox import LocalSandboxProvider


class _FakeSocket:
    """Stands in for the UDP socket: `connect` sends nothing, `getsockname` tells which address would be used."""

    def __init__(self, address: str | None) -> None:
        self._address = address
        self.closed = False

    def connect(self, _target: tuple[str, int]) -> None:
        if self._address is None:
            raise OSError("Network is unreachable")

    def getsockname(self) -> tuple[str, int]:
        return (self._address or "", 50000)

    def close(self) -> None:
        self.closed = True


def _network(
    monkeypatch: pytest.MonkeyPatch, address: str | None, others: tuple[str, ...] = ()
) -> _FakeSocket:
    """`address`: what the system would use for the internet; `others`: this computer's other addresses."""
    fake = _FakeSocket(address)
    monkeypatch.delenv("LAN_IP", raising=False)
    monkeypatch.setattr(socket, "socket", lambda *_a, **_k: fake)
    infos = [
        (socket.AF_INET, socket.SOCK_DGRAM, 0, "", (a, 0)) for a in ((address,) if address else ()) + others
    ]
    monkeypatch.setattr(socket, "getaddrinfo", lambda *_a, **_k: infos)
    return fake


@pytest.fixture(autouse=True)
def _no_device_seen_yet() -> Iterator[None]:
    lan.forget_devices()
    yield
    lan.forget_devices()


async def _checkout_url(provider: LocalSandboxProvider, reference: str = "ref-1") -> str:
    result = await provider.initialize(
        reference=reference,
        amount_kobo=150_000,
        email="customer@yummychops.test",
        currency="NGN",
        callback_url="http://web.test/checkout/callback",
        metadata={},
    )
    return result.authorization_url


class TestCurrentLanAddress:
    def test_the_address_of_the_network_this_computer_is_on(self, monkeypatch: pytest.MonkeyPatch) -> None:
        fake = _network(monkeypatch, "192.168.100.8")
        assert lan.current_lan_address() == "192.168.100.8"
        assert fake.closed

    def test_no_network_gives_nothing(self, monkeypatch: pytest.MonkeyPatch) -> None:
        fake = _network(monkeypatch, None)
        assert lan.current_lan_address() is None
        assert fake.closed

    @pytest.mark.parametrize("address", ["127.0.0.1", "0.0.0.0"])  # noqa: S104 (an address to refuse, not to bind)
    def test_an_address_no_phone_can_reach_gives_nothing(
        self, monkeypatch: pytest.MonkeyPatch, address: str
    ) -> None:
        _network(monkeypatch, address)
        assert lan.current_lan_address() is None

    def test_lan_ip_overrides_the_guess(self, monkeypatch: pytest.MonkeyPatch) -> None:
        _network(monkeypatch, "192.168.100.8")
        monkeypatch.setenv("LAN_IP", " 10.0.0.7 ")
        assert lan.current_lan_address() == "10.0.0.7"

    def test_a_vpn_does_not_hide_the_wifi(self, monkeypatch: pytest.MonkeyPatch) -> None:
        # The owner's laptop on 2026-11-19: Proton VPN routes everything through 10.2.0.2; Hyper-V has 172.27.192.1.
        _network(monkeypatch, "10.2.0.2", others=("172.27.192.1", "192.168.100.8"))
        assert lan.current_lan_address() == "192.168.100.8"

    def test_a_wifi_outside_192_168_is_still_found(self, monkeypatch: pytest.MonkeyPatch) -> None:
        _network(monkeypatch, "10.221.34.228", others=("172.27.192.1",))
        assert lan.current_lan_address() == "10.221.34.228"

    def test_link_local_addresses_are_not_offered(self, monkeypatch: pytest.MonkeyPatch) -> None:
        _network(monkeypatch, None, others=("169.254.10.20",))
        assert lan.current_lan_address() is None


class TestReachableBaseUrl:
    def test_the_address_the_phone_used_wins(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(lan, "current_lan_address", lambda: "10.2.0.2")
        token = lan.remember_request("http://192.168.100.8:8000/")
        try:
            assert lan.reachable_base_url(8000, "http://start:8000") == "http://192.168.100.8:8000"
        finally:
            lan.forget_request(token)

    def test_a_localhost_caller_gets_the_address_the_phone_last_used(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.setattr(lan, "current_lan_address", lambda: "10.2.0.2")
        lan.forget_request(lan.remember_request("http://192.168.100.8:8000/"))  # the phone asked earlier
        token = lan.remember_request("http://localhost:8000/")  # now Yummy (the assistant) asks for the phone
        try:
            assert lan.reachable_base_url(8000, "http://start:8000") == "http://192.168.100.8:8000"
        finally:
            lan.forget_request(token)

    def test_before_any_device_the_guess_then_the_start_address(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.setattr(lan, "current_lan_address", lambda: "192.168.100.8")
        assert lan.reachable_base_url(8000, "http://start:8000") == "http://192.168.100.8:8000"
        monkeypatch.setattr(lan, "current_lan_address", lambda: None)
        assert lan.reachable_base_url(8000, "http://start:8000") == "http://start:8000"

    def test_each_user_pays_at_their_own_devices_address(self) -> None:
        # The owner's phone is on the Wi-Fi; a tester elsewhere comes in through the public test link.
        owner_wifi, test_link = "http://192.168.100.8:8000", "https://yummy-test.ngrok-free.app"
        lan.forget_request(lan.remember_request(owner_wifi + "/", "demo-customer-1"))
        lan.forget_request(lan.remember_request(test_link + "/", "demo-tester-1"))
        # Yummy, the assistant, asks through localhost on behalf of each of them.
        for user, expected in (("demo-customer-1", owner_wifi), ("demo-tester-1", test_link)):
            token = lan.remember_request("http://localhost:8000/", user)
            try:
                assert lan.reachable_base_url(8000, "http://start:8000") == expected
            finally:
                lan.forget_request(token)
        # Someone the API has not seen on a device yet gets the address any device used last.
        token = lan.remember_request("http://localhost:8000/", "someone-new")
        try:
            assert lan.reachable_base_url(8000, "http://start:8000") == test_link
        finally:
            lan.forget_request(token)

    def test_only_a_verified_user_is_remembered(self) -> None:
        # The middleware knows only the address; the user is added once the API has verified the sign-in.
        token = lan.remember_request("http://192.168.100.8:8000/")
        try:
            lan.remember_user("demo-customer-1")
        finally:
            lan.forget_request(token)
        token = lan.remember_request("http://localhost:8000/")  # Yummy asks for that user, through localhost
        try:
            lan.remember_user("demo-customer-1")
            assert lan.reachable_base_url(8000, "http://start:8000") == "http://192.168.100.8:8000"
        finally:
            lan.forget_request(token)
        lan.remember_user("nobody")  # outside a request: nothing to remember, and no error


class TestSandboxPageAddress:
    async def test_a_fixed_address_stays_fixed(self) -> None:
        provider = LocalSandboxProvider(public_base_url="http://localhost:8000/", signing_secret="s")
        assert await _checkout_url(provider) == "http://localhost:8000/v1/dev/sandbox-checkout/ref-1"

    async def test_the_link_follows_the_computer_to_another_wifi(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        where = {"address": "192.168.100.8"}
        monkeypatch.setattr(lan, "current_lan_address", lambda: where["address"])
        settings = Settings(
            environment="test", public_base_url="http://192.168.100.8:8000", sandbox_follows_lan_address=True
        )
        async with httpx.AsyncClient() as http:
            _providers, sandbox = container_mod._payment_providers(settings, http)
        assert sandbox is not None
        assert await _checkout_url(sandbox, "a") == "http://192.168.100.8:8000/v1/dev/sandbox-checkout/a"

        where["address"] = "10.221.34.228"  # the computer joined another Wi-Fi; the server was not restarted
        assert await _checkout_url(sandbox, "b") == "http://10.221.34.228:8000/v1/dev/sandbox-checkout/b"

        where["address"] = None  # type: ignore[assignment]  # offline: fall back to the address it was started with
        assert await _checkout_url(sandbox, "c") == "http://192.168.100.8:8000/v1/dev/sandbox-checkout/c"

    async def test_without_the_switch_the_configured_address_is_used(
        self, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        monkeypatch.setattr(lan, "current_lan_address", lambda: "10.221.34.228")
        settings = Settings(environment="test", public_base_url="http://localhost:8000")
        async with httpx.AsyncClient() as http:
            _providers, sandbox = container_mod._payment_providers(settings, http)
        assert sandbox is not None
        assert await _checkout_url(sandbox) == "http://localhost:8000/v1/dev/sandbox-checkout/ref-1"
