"""Gemini through Vertex AI or an AI Studio key (config.Settings, llm.gemini_access)."""

from __future__ import annotations

import pytest

from gudmeal_agents.config import Settings
from gudmeal_agents.llm import gemini_access


def test_vertex_uses_the_project_and_no_key() -> None:
    s = Settings(
        _env_file=None, llm_backend="vertex", vertex_project="yummy-chops-dev", google_api_key="ignored"
    )
    assert s.llm_configured
    access = gemini_access(s)
    assert access == {"vertexai": True, "project": "yummy-chops-dev", "location": "global"}
    assert "google_api_key" not in access


def test_vertex_needs_a_project_and_ai_studio_needs_a_key() -> None:
    assert not Settings(_env_file=None, llm_backend="vertex").llm_configured
    assert not Settings(_env_file=None).llm_configured
    with pytest.raises(RuntimeError, match="GOOGLE_API_KEY"):
        gemini_access(Settings(_env_file=None))
    assert gemini_access(Settings(_env_file=None, google_api_key="k")) == {"google_api_key": "k"}


def test_production_runs_on_vertex(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("FIREBASE_AUTH_EMULATOR_HOST", raising=False)
    with pytest.raises(RuntimeError, match="LLM_BACKEND must be vertex"):
        Settings(_env_file=None, environment="production", google_api_key="k").validate_for_environment()
