"""Yummy: multi-service tools and the offline (no Gemini key) assistant, end to end against the real API."""

from __future__ import annotations

from datetime import UTC, datetime
from zoneinfo import ZoneInfo

import pytest

from conftest import LEKKI_ADDRESS, bearer, last_tool_data, tool_call
from gudmeal_agents.offline import detect_language, parse_budget, parse_deadline, parse_party

LAGOS = ZoneInfo("Africa/Lagos")


# ------------------------------------------------------------------------------------------- parsing
@pytest.mark.parametrize(
    ("text", "lang"),
    [
        ("Find me jollof under 5k please", "en"),
        ("Abeg wetin una dey sell for Lekki?", "pcm"),
        ("Biko, achoro m nri", "ig"),
        ("Ẹ jọ̀wọ́, mo fẹ́ oúnjẹ", "yo"),
        ("Sannu, ina son abinci", "ha"),
    ],
)
def test_language_detection(text, lang):
    assert detect_language(text) == lang


def test_budget_party_and_deadline_parsing():
    assert parse_budget("I have ₦10,000 for food") == 10_000
    assert parse_budget("budget na 15k") == 15_000
    assert parse_budget("N5000 for lunch") == 5_000
    assert parse_budget("5,000 naira only") == 5_000
    assert parse_budget("no money talk here") is None
    assert parse_party("best meal for two people") == 2
    assert parse_party("food for 3") == 3
    assert parse_party("four people dey come") == 4
    assert parse_party("just me") == 1
    assert parse_deadline("deliver before 8pm") == "20:00"
    assert parse_deadline("by 7:30 pm") == "19:30"
    assert parse_deadline("before 8") == "20:00"
    assert parse_deadline("by 11am") == "11:00"
    assert parse_deadline("whenever") is None


# ------------------------------------------------------------------------------------------- offline Yummy
async def chat(client, message: str, who: str = "customer", thread: str | None = None) -> dict:
    body = {"message": message, **({"thread_id": thread} if thread else {})}
    r = await client.post("/v1/chat", json=body, headers=bearer(who))
    assert r.status_code == 200, r.text
    return r.json()


async def test_offline_gudy_greets_in_the_customers_language_and_lists_services(offline_stack):
    client = offline_stack["client"]
    health = (await client.get("/health")).json()
    assert health["ai_mode"] == "offline" and health["assistant"] == "Yummy" and not health["llm_configured"]

    hi = await chat(client, "How far, abeg wetin you fit do?")
    assert hi["status"] == "completed" and hi["reply"].startswith("How far Ada! Na me be Yummy")
    igbo = await chat(client, "Ndewo")
    assert igbo["reply"].startswith("Ndewo Ada! Abụ m Yummy.") and "English for now" in igbo["reply"]

    services = await chat(client, "What services do you offer?")
    assert "Beauty & Skin Care" in services["reply"] and "Package Delivery" in services["reply"]
    assert "interstate" in services["reply"].lower()
    card = next(c for c in services["cards"] if c["type"] == "services")
    # The owner's order (ADR-0025): Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, Package
    # Delivery.
    assert [s["id"] for s in card["services"]] == [
        "food",
        "pharmacy",
        "beauty",
        "grocery",
        "market",
        "parcel",
    ]
    assert "Shop & Groceries" in services["reply"] and "Buy Foodstuff" in services["reply"]


async def test_offline_gudy_totals_beauty_search_parcels_and_support(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    none = await chat(client, "How much have I spent on Yummy Chops?")
    assert "haven't placed any orders" in none["reply"]

    # Pay for one order, then the totals come straight from the API (net of refunds).
    await api.post("/v1/me/addresses", json=LEKKI_ADDRESS, headers=bearer("customer"))
    quote = (
        await api.post(
            "/v1/quotes",
            json={
                "restaurant_id": "b-shea-harbour",
                "lines": [{"item_id": "sh-spf50", "quantity": 1}],
                "delivery_address": LEKKI_ADDRESS,
            },
            headers=bearer("customer"),
        )
    ).json()
    order = (
        await api.post(
            "/v1/orders",
            json={"quote_id": quote["id"]},
            headers={**bearer("customer"), "Idempotency-Key": "test-order-key-1"},
        )
    ).json()
    pay = (
        await api.post(
            f"/v1/orders/{order['id']}/checkout",
            json={},
            headers={**bearer("customer"), "Idempotency-Key": "test-checkout-key-1"},
        )
    ).json()
    await api.post(f"/v1/dev/sandbox-checkout/{pay['reference']}/complete?outcome=success")
    total = quote["breakdown"]["total_kobo"]
    naira = f"₦{total // 100:,}" + (f".{total % 100:02d}" if total % 100 else "")

    totals = await chat(client, "abeg how much i don spend?")
    assert f"total na {naira}" in totals["reply"] and "Beauty & Skin Care: 1 order(s)" in totals["reply"]
    assert any(c["type"] == "order_totals" for c in totals["cards"])

    beauty = await chat(client, "I need a good sunscreen")
    assert "SPF 50" in beauty["reply"] and "₦11,000" in beauty["reply"]

    parcel = await chat(client, "I want to send a package to my sister in Yaba")
    nav = next(c for c in parcel["cards"] if c["type"] == "navigate")
    assert nav["screen"] == "parcel" and "pickup and drop-off" in parcel["reply"]

    support = await chat(client, "I want to talk to a human")
    assert "Support tab" in support["reply"]
    # Only the contact that exists is offered (the customer-care email), never a made-up WhatsApp or phone number.
    assert "by email at customercare@yummy247.com" in support["reply"] and "WhatsApp" not in support["reply"]
    contacts = next(c for c in support["cards"] if c["type"] == "support_contacts")
    assert contacts["email"] == "customercare@yummy247.com" and not {"whatsapp", "phone"} & contacts.keys()
    assert contacts["note"].startswith("Not set up yet: WhatsApp, phone.")

    track = await chat(client, "Where is my order?")
    assert order["short_code"] in track["reply"]

    invocations = await offline_stack["store"].recent_invocations()
    assert {i["tool"] for i in invocations} >= {
        "get_order_totals",
        "search_food_items",
        "open_screen",
        "get_support_contacts",
    }
    assert all(i["status"] == "ok" for i in invocations)


async def test_offline_gudy_vision_flow_ends_on_an_approval_screen(offline_stack):
    """The product vision works without an LLM: plan → draft → approval with the exact total → payment link."""
    client, api = offline_stack["client"], offline_stack["api"]
    await api.post("/v1/me/addresses", json=LEKKI_ADDRESS, headers=bearer("customer"))
    local = datetime.now(UTC).astimezone(LAGOS)
    when = " and have it delivered before 11:59pm" if local.hour < 22 else ""
    body = await chat(
        client, f"Yummy Chops, I have ₦10,000. Find me the best meal for two people, order it{when}."
    )
    assert body["status"] == "approval_required", body
    approval = body["approval"]
    assert approval["tool"] == "confirm_order"
    preview = approval["preview"]["order"]
    order = (await api.get(f"/v1/orders/{preview['order_id']}", headers=bearer("customer"))).json()
    assert (
        order["status"] == "draft" and preview["total_kobo"] == order["breakdown"]["total_kobo"] <= 1_000_000
    )
    assert {c["type"] for c in body["cards"]} >= {"meal_plans", "order_draft"}

    r = await client.post(
        f"/v1/chat/{body['thread_id']}/approval",
        json={"approved": True, "tool_call_id": approval["tool_call_id"]},
        headers=bearer("customer"),
    )
    done = r.json()
    assert done["status"] == "completed" and "secure payment link" in done["reply"]
    assert any(c["type"] == "payment_link" for c in done["cards"])


async def test_offline_gudy_plan_then_pick_and_decline(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    await api.post("/v1/me/addresses", json=LEKKI_ADDRESS, headers=bearer("customer"))
    plans = await chat(client, "I have 15k, plan lunch for 3")
    assert plans["status"] == "completed" and "Reply 'plan 1'" in plans["reply"]
    assert "1. " in plans["reply"] and "Total ₦" in plans["reply"]
    missing = await chat(client, "plan 9", thread=plans["thread_id"])
    assert missing["status"] == "completed" and "not one of the plans" in missing["reply"]
    pick = await chat(client, "plan 1", thread=plans["thread_id"])
    assert pick["status"] == "approval_required" and pick["approval"]["tool"] == "confirm_order"
    r = await client.post(
        f"/v1/chat/{plans['thread_id']}/approval", json={"approved": False}, headers=bearer("customer")
    )
    assert "haven't done it" in r.json()["reply"]


# ------------------------------------------------------------------------------------------- Gemini-style tools
async def test_parcel_quote_and_booking_via_tools(stack):
    """With the LLM: Yummy prices a parcel from free-text addresses, then books it only after approval."""
    client, api, models = stack["client"], stack["api"], stack["models"]
    await api.post("/v1/me/addresses", json=LEKKI_ADDRESS, headers=bearer("customer"))
    models.steps = [
        tool_call(
            "get_parcel_quote",
            {
                "dropoff_address": "4 Herbert Macaulay Way, Yaba",
                "recipient_name": "Ngozi",
                "recipient_phone": "+2348055555555",
                "sender_phone": "+2348011111111",
                "size": "medium",
                "category": "clothing",
            },
            "call_quote",
        ),
        lambda msgs: tool_call(
            "book_parcel", {"quote_id": last_tool_data(msgs)["data"]["quote_id"]}, "call_book"
        ),
        lambda msgs: tool_call("open_screen", {"screen": "order"}, "call_open"),
        lambda msgs: __import__("langchain_core.messages", fromlist=["AIMessage"]).AIMessage(
            content="Booked!"
        ),
    ]
    body = await chat(client, "Send this dress to Ngozi in Yaba")
    assert body["status"] == "approval_required" and body["approval"]["tool"] == "book_parcel"
    preview = body["approval"]["preview"]
    assert preview["title"].startswith("Book a medium package delivery for ₦")
    quote_card = next(c for c in body["cards"] if c["type"] == "parcel_quote")["quote"]
    assert (
        quote_card["to"].startswith("4 Herbert Macaulay Way, Yaba (Ngozi")
        and quote_card["total"] == preview["parcel"]["total"]
    )

    done = (
        await client.post(
            f"/v1/chat/{body['thread_id']}/approval",
            json={"approved": True, "tool_call_id": body["approval"]["tool_call_id"]},
            headers=bearer("customer"),
        )
    ).json()
    assert done["reply"] == "Booked!"
    link = next(c for c in done["cards"] if c["type"] == "payment_link")
    nav = next(c for c in done["cards"] if c["type"] == "navigate")
    assert nav["params"]["order_id"] == link["order_id"]
    order = (await api.get(f"/v1/orders/{link['order_id']}", headers=bearer("customer"))).json()
    assert (
        order["vertical"] == "parcel"
        and order["channel"] == "ai_agent"
        and order["status"] == "pending_payment"
    )
    assert order["parcel"]["dropoff"]["name"] == "Ngozi" and order["parcel"]["size"] == "medium"


async def test_offline_gudy_reads_the_wallet_and_explains_cash_payments(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    r = await api.post(
        "/v1/wallet/topups",
        json={"amount_kobo": 250_000},
        headers={**bearer("customer"), "Idempotency-Key": "test-topup-key-1"},
    )
    assert r.status_code == 201, r.text
    await api.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")

    wallet = await chat(client, "How much is in my wallet?")
    assert "₦2,500" in wallet["reply"] and "Wallet top-up: +₦2,500" in wallet["reply"]
    card = next(c for c in wallet["cards"] if c["type"] == "wallet")
    assert card["balance"] == "₦2,500"
    topup = await chat(client, "abeg I wan top up my wallet")
    assert "can't move money" not in topup["reply"] and "no fit move money" in topup["reply"]

    pod = await chat(client, "Can I pay on delivery?")
    assert "first order" in pod["reply"] and "Pay on delivery" in pod["reply"]

    seller = await chat(client, "I sell online. Can the rider collect cash from my buyer?")
    nav = next(c for c in seller["cards"] if c["type"] == "navigate")
    assert nav["screen"] == "parcel" and "Collect cash from my buyer" in seller["reply"]

    opened = await chat(client, "open my wallet")
    assert next(c for c in opened["cards"] if c["type"] == "navigate")["screen"] == "wallet"

    invocations = await offline_stack["store"].recent_invocations()
    assert "get_wallet" in {i["tool"] for i in invocations}
    # Yummy has no tool that can move money in or out of a wallet.
    from gudmeal_agents.tools.registry import FORBIDDEN_ARG_NAMES

    assert {"amount", "amount_kobo"} <= set(FORBIDDEN_ARG_NAMES)


async def test_offline_gudy_quotes_waybill_routes_and_tracks_a_waybill(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    routes = await chat(client, "Can you send a package to Abuja?")
    assert "Abuja: from ₦" in routes["reply"] and "collect at Partner terminal, Utako" in routes["reply"]
    card = next(c for c in routes["cards"] if c["type"] == "waybill_options")
    assert card["screen"] == "waybill" and [d["to"] for d in card["destinations"]] == ["Abuja"]
    all_routes = await chat(client, "I want to send something interstate")
    assert "Enugu" in all_routes["reply"] and "Port Harcourt" in all_routes["reply"]

    none = await chat(client, "where is my waybill?")
    assert "don't have any waybills" in none["reply"]

    sender = {**LEKKI_ADDRESS, "name": "Ada", "phone": "+2348011111111"}
    sender.pop("label")
    q = await api.post(
        "/v1/waybills/quotes",
        json={
            "origin_city": "lagos",
            "destination_city": "abuja",
            "first_mile": "pickup",
            "last_mile": "collect",
            "sender": sender,
            "recipient": {"name": "Musa Bello", "phone": "+2348077777777"},
            "size": "small",
            "weight_kg": 1,
        },
        headers=bearer("customer"),
    )
    assert q.status_code == 201, q.text
    order = await api.post(
        "/v1/waybills",
        json={"quote_id": q.json()["id"]},
        headers={**bearer("customer"), "Idempotency-Key": "test-waybill-1"},
    )
    pay = await api.post(
        f"/v1/orders/{order.json()['id']}/checkout",
        json={},
        headers={**bearer("customer"), "Idempotency-Key": "test-waybill-pay-1"},
    )
    await api.post(f"/v1/dev/sandbox-checkout/{pay.json()['reference']}/complete?outcome=success")
    code = order.json()["waybill"]["tracking_code"]

    tracked = await chat(client, f"track {code.lower()}")
    assert f"Waybill {code} (Lagos to Abuja): Rider pickup booked. Expected " in tracked["reply"]
    assert "Collect it at Partner terminal, Utako" in tracked["reply"]
    latest = await chat(client, "where is my waybill?")
    assert code in latest["reply"]
    totals = await chat(client, "How much have I spent on Yummy Chops?")
    assert "Interstate waybill: 1 order(s)" in totals["reply"]


def test_offline_waybill_reply_drops_the_eta_once_delivered():
    from gudmeal_agents.offline import render

    data = {
        "tracking_code": "GMW23456789",
        "route": "Lagos to Abuja",
        "status": "Delivered",
        "expected": "Tue 17 Nov",
        "delivered": True,
    }
    assert render("track_waybill", data, "en") == "Waybill GMW23456789 (Lagos to Abuja): Delivered."


async def test_offline_gudy_explains_plus_points_referrals_and_group_orders(offline_stack):
    client, api = offline_stack["client"], offline_stack["api"]
    pitch = await chat(client, "Is Yummy Chops Plus worth it? Am I a member?")
    assert "Yummy Chops Plus costs ₦1,500 every 30 days (VAT included):" in pitch["reply"]
    assert "Free delivery on restaurant and shop orders of ₦3,000 or more" in pitch["reply"]
    assert next(c for c in pitch["cards"] if c["type"] == "plus")["member"] is False

    r = await api.post(
        "/v1/wallet/topups",
        json={"amount_kobo": 150_000},
        headers={**bearer("customer"), "Idempotency-Key": "gudy-plus-1"},
    )
    await api.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    r = await api.post(
        "/v1/plus/subscribe",
        json={"provider": "wallet"},
        headers={**bearer("customer"), "Idempotency-Key": "gudy-plus-2"},
    )
    assert r.status_code == 201, r.text
    member = await chat(client, "my plus membership")
    assert "You're a Yummy Chops Plus member until" in member["reply"] and "is on" in member["reply"]

    points = await chat(client, "How many points do I have?")
    assert "You have 0 Yummy points (worth ₦0)" in points["reply"]
    assert "Your referral code is ADA" in points["reply"] and "500 more points" in points["reply"]
    pidgin = await chat(client, "abeg wetin be my referral code?")
    assert "Your referral code na ADA" in pidgin["reply"]

    none = await chat(client, "I want to do a group order with my friends")
    assert "not in any group orders" in none["reply"]
    from conftest import LEKKI_ADDRESS

    g = await api.post(
        "/v1/group-orders",
        json={"restaurant_id": "r-jollof-junction", "delivery_address": LEKKI_ADDRESS},
        headers=bearer("customer"),
    )
    assert g.status_code == 201, g.text
    groups = await chat(client, "show my group orders")
    assert f"Jollof Junction: collecting everyone's orders, code {g.json()['code']}" in groups["reply"]
    assert (
        next(c for c in groups["cards"] if c["type"] == "group_orders")["groups"][0]["you_are_host"] is True
    )


async def test_offline_gudy_finds_shop_products_and_opens_the_new_services(offline_stack):
    """Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, ADR-0025)."""
    client = offline_stack["client"]
    para = await chat(client, "I need paracetamol")
    assert "Paracetamol 500 mg tablets" in para["reply"] and "₦300" in para["reply"]
    garri = await chat(client, "abeg I wan buy garri")
    assert "Ijebu garri" in garri["reply"]
    milk = await chat(client, "do you have milk?")
    assert "milk" in milk["reply"].lower() and "₦" in milk["reply"]

    # Words that name a whole service open it instead of searching for the word.
    for message, screen in (
        ("I want to buy groceries", "grocery"),
        ("do you sell medicine?", "pharmacy"),
        ("open market", "market"),
        ("take me to the pharmacy", "pharmacy"),
    ):
        reply = await chat(client, message)
        nav = next(c for c in reply["cards"] if c["type"] == "navigate")
        assert nav["screen"] == screen, message
