"""Model access (Gemini via langchain-google-genai) with fallback, plus usage/cost accounting."""

from __future__ import annotations

import contextvars
from typing import Any, Protocol

from langchain_core.messages import AIMessage

from .config import Settings

# Bound per request by AgentService: True when a daily spend budget is used up, so this turn is answered by the
# rule-based models instead of Gemini.
offline_turn: contextvars.ContextVar[bool] = contextvars.ContextVar("offline_turn", default=False)


class Invocable(Protocol):
    async def ainvoke(self, input: Any, config: Any | None = None, **kwargs: Any) -> Any: ...


class ModelFactory(Protocol):
    model_name: str

    def for_tools(self, tools: list[dict[str, Any]]) -> Invocable: ...

    def for_structured(self, schema: type) -> Invocable: ...


def gemini_access(settings: Settings) -> dict[str, Any]:
    """How the Gemini client reaches Google: Vertex AI with the service's own identity, or an AI Studio key."""
    if settings.llm_backend == "vertex":
        if not settings.vertex_project:
            raise RuntimeError("VERTEX_PROJECT is not set")
        return {"vertexai": True, "project": settings.vertex_project, "location": settings.vertex_location}
    if settings.google_api_key is None:
        raise RuntimeError("GOOGLE_API_KEY is not set")
    return {"google_api_key": settings.google_api_key.get_secret_value()}


class GeminiFactory:
    def __init__(self, settings: Settings) -> None:
        from langchain_google_genai import ChatGoogleGenerativeAI

        common: dict[str, Any] = {
            "temperature": settings.llm_temperature,
            "max_retries": settings.llm_max_retries,
            "timeout": settings.llm_timeout_seconds,
            "max_output_tokens": settings.llm_max_output_tokens,
            **gemini_access(settings),
        }
        self.model_name = settings.gemini_model
        self._primary = ChatGoogleGenerativeAI(model=settings.gemini_model, **common)
        self._fallback = (
            ChatGoogleGenerativeAI(model=settings.gemini_fallback_model, **common)
            if settings.gemini_fallback_model
            else None
        )

    def for_tools(self, tools: list[dict[str, Any]]) -> Invocable:
        primary: Any = self._primary.bind_tools(tools) if tools else self._primary
        if self._fallback is not None:
            fb = self._fallback.bind_tools(tools) if tools else self._fallback
            return primary.with_fallbacks([fb])  # type: ignore[no-any-return]
        return primary  # type: ignore[no-any-return]

    def for_structured(self, schema: type) -> Invocable:
        # include_raw: the answer comes as {"raw": message, "parsed": object}, and the message carries the token
        # counts, so the router's usage is counted like every other call.
        primary: Any = self._primary.with_structured_output(schema, include_raw=True)
        if self._fallback is not None:
            fallback = self._fallback.with_structured_output(schema, include_raw=True)
            return primary.with_fallbacks([fallback])  # type: ignore[no-any-return]
        return primary  # type: ignore[no-any-return]


class BudgetedModels:
    """The configured models, or the rule-based ones for a turn whose daily spend budget is used up."""

    def __init__(self, primary: ModelFactory, offline: ModelFactory) -> None:
        self._primary = primary
        self._offline = offline

    @property
    def model_name(self) -> str:
        return self._primary.model_name

    @property
    def deterministic_routing(self) -> bool:
        return bool(getattr(self._current(), "deterministic_routing", False))

    def _current(self) -> ModelFactory:
        return self._offline if offline_turn.get() else self._primary

    def for_tools(self, tools: list[dict[str, Any]]) -> Invocable:
        return self._current().for_tools(tools)

    def for_structured(self, schema: type) -> Invocable:
        return self._current().for_structured(schema)


def usage_of(message: AIMessage) -> tuple[int, int]:
    meta = getattr(message, "usage_metadata", None) or {}
    return int(meta.get("input_tokens", 0) or 0), int(meta.get("output_tokens", 0) or 0)


def cost_usd(input_tokens: int, output_tokens: int, settings: Settings) -> float:
    return round(
        input_tokens / 1e6 * settings.price_input_per_million_usd
        + output_tokens / 1e6 * settings.price_output_per_million_usd,
        8,
    )


def text_of(message: AIMessage) -> str:
    content = message.content
    if isinstance(content, str):
        return content
    parts = []
    for part in content:
        if isinstance(part, str):
            parts.append(part)
        elif isinstance(part, dict) and part.get("type") == "text":
            parts.append(str(part.get("text", "")))
    return "".join(parts)
