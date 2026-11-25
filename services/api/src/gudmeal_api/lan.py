"""Where a device on this computer's Wi-Fi can reach this API: the address the phone test uses.

Only the local phone test uses it. A phone on the same Wi-Fi opens the payment sandbox page on this computer,
and the computer's address changes with the Wi-Fi it joins, so the address is looked up when it is needed
instead of once at startup (docs/adr/0020-test-apps-find-the-test-server.md).

The best answer is the address the phone itself used to reach this API: whatever the phone reached once, it can
reach again. Guessing this computer's address is the last resort, and a VPN makes the guess go wrong: while one is
connected, asking the system which address it would use for the internet gives the VPN's tunnel address
(10.2.0.2 with Proton VPN), which no phone can reach.
"""

from __future__ import annotations

import ipaddress
import os
import socket
from contextvars import ContextVar, Token
from urllib.parse import urlsplit

#: The current request: the address (scheme://host:port) it reached this API at (set by the API's middleware), and
#: who sent it once the API has verified their sign-in (`remember_user`).
_request: ContextVar[tuple[str, str | None] | None] = ContextVar("lan_request", default=None)
#: The last address a device on the network (the test phone) reached this API at...
_last_network_base: str | None = None
#: ...and each user's own last address: the owner's phone on the Wi-Fi, a tester through the public test link.
_by_user: dict[str, str] = {}


def _on_the_network(host: str) -> bool:
    """True for an address another device can use: not loopback, not "any", not link-local."""
    if not host or host.lower() == "localhost":
        return False
    try:
        ip = ipaddress.ip_address(host.strip("[]"))
    except ValueError:
        return True  # a name (like mypc.local) that the device resolved by itself
    return not (ip.is_loopback or ip.is_unspecified or ip.is_link_local)


def remember_request(base_url: str, user: str | None = None) -> Token[tuple[str, str | None] | None]:
    """Called by the API for every request: the address the client used to reach it (`request.base_url`), and
    (tests) who sent it."""
    global _last_network_base
    base = base_url.rstrip("/")
    if _on_the_network(urlsplit(base).hostname or ""):
        _last_network_base = base
        if user:
            _by_user[user] = base
    return _request.set((base, user))


def remember_user(user: str) -> None:
    """Called once the API has verified who sent the current request: where their own device reached it. Only a
    verified sign-in counts, so nobody can point another person's payment page at an address of their choosing."""
    current = _request.get()
    if current is None:
        return
    base = current[0]
    _request.set((base, user))
    if _on_the_network(urlsplit(base).hostname or ""):
        _by_user[user] = base


def forget_request(token: Token[tuple[str, str | None] | None]) -> None:
    _request.reset(token)


def forget_devices() -> None:
    """Forget every device's address (tests; a new phone test starts fresh anyway)."""
    global _last_network_base
    _last_network_base = None
    _by_user.clear()


def reachable_base_url(port: int, fallback: str) -> str:
    """Where a device on the Wi-Fi can open a page served by this API, best answer first:

    1. the address the current request came in on, when it is a network address (the phone is asking);
    2. for a request through `localhost` (Yummy, the assistant, asking for a user), the address that user's
       device last reached this API at: the Wi-Fi for the owner's phone, the public test link for a tester;
    3. the address any device last reached this API at (a website on this computer asks);
    4. this computer's guess of its own Wi-Fi address;
    5. `fallback` (PUBLIC_BASE_URL, the address the server was started with).
    """
    current = _request.get()
    if current:
        base, user = current
        if _on_the_network(urlsplit(base).hostname or ""):
            return base
        if user and user in _by_user:
            return _by_user[user]
    if _last_network_base:
        return _last_network_base
    address = current_lan_address()
    return f"http://{address}:{port}" if address else fallback


def current_lan_address() -> str | None:
    """This computer's IPv4 address on its Wi-Fi (or cable), or None when it has none.

    `LAN_IP` overrides the guess, as in scripts/lan.mjs. A 192.168.x.x address wins over the address the system
    would use for the internet, because that one is a VPN's tunnel while a VPN is connected; home and office
    Wi-Fi is almost always 192.168.x.x (scripts/lan.mjs prefers it too).
    """
    override = os.environ.get("LAN_IP", "").strip()
    if override:
        return override
    candidates = [a for a in (_routed_address(), *_host_addresses()) if a and _on_the_network(a)]
    for address in candidates:
        if address.startswith("192.168."):
            return address
    return candidates[0] if candidates else None


def _routed_address() -> str | None:
    """The address the system would use to reach another network (None without a network)."""
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Connecting a UDP socket sends nothing. It only asks the system which of its own addresses it would use
        # to reach another network. 192.0.2.1 is a documentation address that no real host has.
        probe.connect(("192.0.2.1", 9))
        return str(probe.getsockname()[0])
    except OSError:
        return None  # no network at all
    finally:
        probe.close()


def _host_addresses() -> list[str]:
    """Every IPv4 address of this computer (Wi-Fi, cable, VPN, virtual switches), in no particular order."""
    try:
        infos = socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)
    except OSError:
        return []
    return list(dict.fromkeys(str(info[4][0]) for info in infos))
