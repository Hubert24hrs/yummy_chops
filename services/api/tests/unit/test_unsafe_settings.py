"""Settings that would make a server unsafe stop it at start-up (config.Settings.validate_for_environment)."""

from __future__ import annotations

import pytest

from gudmeal_api.config import EMULATOR_SWITCHES, Settings
from gudmeal_api.security.auth import principal_from_claims

# The online test server (ENVIRONMENT=development) with every setting it needs.
ONLINE = dict(
    _env_file=None,
    environment="development",
    channel_token_secret="c" * 40,
    file_store="gcs",
    storage_bucket="demo.firebasestorage.app",
)


@pytest.fixture(autouse=True)
def _no_emulators_or_cloud_run(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in (*EMULATOR_SWITCHES, "K_SERVICE"):
        monkeypatch.delenv(name, raising=False)


def refused(settings: Settings) -> str:
    with pytest.raises(RuntimeError) as exc:
        settings.validate_for_environment()
    return str(exc.value)


def test_the_online_test_server_starts_with_its_settings() -> None:
    Settings(**ONLINE).validate_for_environment()


@pytest.mark.parametrize("switch", EMULATOR_SWITCHES)
def test_no_server_in_the_cloud_trusts_an_emulator(monkeypatch: pytest.MonkeyPatch, switch: str) -> None:
    monkeypatch.setenv(switch, "127.0.0.1:9099")
    assert switch in refused(Settings(**ONLINE))


def test_the_online_test_server_needs_its_own_secrets_and_storage() -> None:
    problems = refused(Settings(_env_file=None, environment="development"))
    assert "CHANNEL_TOKEN_SECRET" in problems  # the default is in this public repository
    assert "FILE_STORE=gcs" in problems  # riders' ID documents must not sit on a server's temporary disk
    assert "CHANNEL_TOKEN_SECRET" in refused(Settings(**{**ONLINE, "channel_token_secret": "short"}))
    assert "SANDBOX_FOLLOWS_LAN_ADDRESS" in refused(Settings(**ONLINE, sandbox_follows_lan_address=True))


def test_live_payment_keys_only_in_production_and_test_keys_never_there() -> None:
    assert "live Paystack key" in refused(Settings(**ONLINE, paystack_secret_key="sk_live_abc"))
    assert "live Paystack key" in refused(
        Settings(_env_file=None, environment="local", paystack_secret_key="sk_live_abc")
    )
    Settings(
        _env_file=None, environment="local", paystack_secret_key="sk_test_abc"
    ).validate_for_environment()
    production = Settings(_env_file=None, environment="production", paystack_secret_key="sk_test_abc")
    assert "must be the live key in production" in refused(production)


def test_cloud_run_never_runs_the_local_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    # ENVIRONMENT defaults to local, which opens the developer tools and the pretend payment page.
    monkeypatch.setenv("K_SERVICE", "gudmeal-api")
    assert "ENVIRONMENT must be" in refused(Settings(_env_file=None))
    Settings(**ONLINE).validate_for_environment()


def test_roles_count_only_when_they_are_a_list() -> None:
    def roles(value: object) -> set[str]:
        return set(principal_from_claims({"sub": "u1", "roles": value}).roles)

    assert roles(["operations_manager", "made_up"]) == {"customer", "operations_manager"}
    # A token written by hand (the sign-in emulator does not check signatures) must not make roles out of a
    # dictionary's keys or a string's letters.
    assert roles({"super_admin": True}) == {"customer"}
    assert roles("super_admin") == {"customer"}
    assert roles(None) == {"customer"}
