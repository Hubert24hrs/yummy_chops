"""Yummy location intelligence: nearby recommendations and delivery-time comparisons.

The test stack has no Google Maps key, so every time and distance is the API's labelled estimate; the tools must
pass those numbers through unchanged and say they are estimates.
"""

from __future__ import annotations

from typing import Any

from langchain_core.messages import AIMessage

from conftest import LEKKI_ADDRESS, bearer, last_tool_data, tool_call
from gudmeal_agents.agents import keyword_route
from gudmeal_agents.identity import Caller
from gudmeal_agents.offline import nearby_args

CUSTOMER = Caller(uid="c", roles=frozenset({"customer"}))
LEKKI = LEKKI_ADDRESS["location"]


async def chat(client, message: str) -> dict[str, Any]:
    r = await client.post("/v1/chat", json={"message": message}, headers=bearer("customer"))
    assert r.status_code == 200, r.text
    return r.json()


async def add_address(api) -> None:
    r = await api.post("/v1/me/addresses", json=LEKKI_ADDRESS, headers=bearer("customer"))
    assert r.status_code == 201, r.text


async def api_estimates(api, ids: list[str]) -> dict[str, dict[str, Any]]:
    r = await api.get(
        "/v1/delivery/estimates",
        params={"restaurant_ids": ",".join(ids), **LEKKI},
        headers=bearer("customer"),
    )
    assert r.status_code == 200, r.text
    return {e["restaurant_id"]: e for e in r.json()["estimates"]}


def test_offline_parser_understands_location_questions():
    assert nearby_args("Which restaurants near me deliver fastest?") == {
        "service": "food",
        "sort_by": "fastest",
    }
    best = nearby_args("best rated suya spot close to me, 4 stars and up")
    assert best == {"service": "food", "sort_by": "best_rated", "min_rating": 4.0, "query": "suya"}
    quick = nearby_args("cheap food near me I can get in 30 minutes")
    assert quick == {"service": "food", "sort_by": "closest", "max_minutes": 30, "max_price_level": 2}
    assert nearby_args("any sunscreen shop near me?")["service"] == "beauty"
    assert nearby_args("any pharmacy near me?")["service"] == "pharmacy"
    assert nearby_args("which supermarket is close to me?")["service"] == "grocery"
    assert nearby_args("is there a market near me?")["service"] == "market"
    # Not location questions (or better served by another flow).
    assert nearby_args("where is my rider? is he near?") is None
    assert nearby_args("what's the fastest way to send a package?") is None
    assert nearby_args("jollof for ₦8k near me") is None  # an amount → meal plan within budget
    assert nearby_args("How far!") is None
    assert nearby_args("I want jollof") is None


def test_location_questions_route_to_the_customer_agent():
    assert keyword_route("Which kitchen near me can arrive fastest?", CUSTOMER).agent == "customer"
    assert keyword_route("fastest restaurant to Lekki", CUSTOMER).agent == "customer"
    assert keyword_route("where is my rider", CUSTOMER).agent == "delivery"  # unchanged


async def test_offline_gudy_recommends_nearby_kitchens_with_estimates(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    await add_address(api)

    reply = await chat(client, "Which restaurants near me deliver fastest?")
    assert reply["status"] == "completed"
    assert reply["reply"].startswith("Places that deliver to Lekki Phase 1 (quickest first):")
    assert "estimates; checkout shows the exact price" in reply["reply"]
    items = next(c for c in reply["cards"] if c["type"] == "restaurants")["items"]
    assert 1 <= len(items) <= 5
    etas = [i["eta_minutes"] for i in items]
    assert etas == sorted(etas)
    assert all(i["times_are"] == "estimate from distance" for i in items)  # no Google key in tests

    # Numbers come straight from the API (never invented by Yummy).
    api_rows = await api_estimates(api, [i["restaurant_id"] for i in items])
    for item in items:
        row = api_rows[item["restaurant_id"]]
        assert row["delivers"] and row["source"] == "estimate"
        assert item["eta_minutes"] == row["eta_minutes"]
        assert item["road_distance_km"] == row["road_distance_km"]
        assert f"about {item['eta_minutes']} min" in reply["reply"]

    invocations = await offline_stack["store"].recent_invocations()
    assert any(i["tool"] == "find_nearby_restaurants" for i in invocations)
    assert offline_stack["container"].maps.provider == "local"


async def test_offline_gudy_says_when_nothing_can_arrive_in_time(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    await add_address(api)
    reply = await chat(client, "anything near me that can come in 10 minutes?")
    assert reply["reply"].startswith("I couldn't find a place that delivers to Lekki Phase 1")


async def test_nearby_needs_an_address(offline_stack):
    reply = await chat(offline_stack["client"], "restaurants near me")
    assert reply["reply"].startswith("Sorry, no delivery address found")


async def test_nearby_filters_and_sorts_by_rating_and_delivery_fee(stack):
    client, api, models = stack["client"], stack["api"], stack["models"]
    await add_address(api)
    seen: dict[str, Any] = {}

    def capture(key: str):
        def step(msgs):
            seen[key] = last_tool_data(msgs)["data"]
            return AIMessage(content="Here you go.")

        return step

    models.steps = [
        tool_call("find_nearby_restaurants", {"sort_by": "best_rated", "min_rating": 4.5, "limit": 8}, "c1"),
        capture("rated"),
        tool_call("find_nearby_restaurants", {"sort_by": "cheapest_delivery", "limit": 8}, "c2"),
        capture("cheap"),
    ]
    await chat(client, "best rated places around me")
    await chat(client, "which nearby place has the cheapest delivery?")

    rated = seen["rated"]["restaurants"]
    assert rated and all(r["rating"] >= 4.5 for r in rated)
    assert [r["rating"] for r in rated] == sorted((r["rating"] for r in rated), reverse=True)
    cheap = seen["cheap"]["restaurants"]
    fees = [int(r["delivery_fee"].replace("₦", "").replace(",", "").split(".")[0]) for r in cheap]
    assert fees == sorted(fees)
    assert seen["cheap"]["note"].startswith("Times and delivery fees are for comparison")


async def test_compare_delivery_times_sorts_by_eta_and_flags_unknown_places(stack):
    client, api, models = stack["client"], stack["api"], stack["models"]
    await add_address(api)
    nearby = (
        await api.get(
            "/v1/restaurants", params={**LEKKI, "sort": "distance", "limit": 6}, headers=bearer("customer")
        )
    ).json()
    delivering = [r for r in nearby if r["delivers_to_location"]]
    assert len(delivering) >= 2
    far_name, near_id = delivering[-1]["name"], delivering[0]["id"]  # by name and by id

    seen: dict[str, Any] = {}

    def capture(msgs):
        seen.update(last_tool_data(msgs)["data"])
        return AIMessage(content="Compared.")

    models.steps = [
        tool_call("compare_delivery_times", {"restaurants": [far_name, near_id, "Nowhere Kitchen"]}, "cmp"),
        capture,
    ]
    reply = await chat(client, f"Who gets to me faster, {far_name} or the other one?")
    assert reply["status"] == "completed"

    rows = seen["comparison"]
    assert {r["restaurant_id"] for r in rows} == {delivering[-1]["id"], near_id}
    assert [r["eta_minutes"] for r in rows] == sorted(r["eta_minutes"] for r in rows)
    assert seen["fastest"] == rows[0]["name"]
    assert seen["not_found_nearby"] == ["Nowhere Kitchen"]
    api_rows = await api_estimates(api, [r["restaurant_id"] for r in rows])
    for r in rows:
        assert r["eta_minutes"] == api_rows[r["restaurant_id"]]["eta_minutes"]
        assert r["times_are"] == "estimate from distance"
