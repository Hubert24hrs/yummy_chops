"""Receipts (ADR-0019): after paying, the customer prints the receipt of the order; it is then kept under
"My receipts". A receipt only repeats what the order was charged."""

from __future__ import annotations

from datetime import UTC, datetime

from conftest import auth, idem
from gudmeal_api.domain.receipts import build_receipt

PICKUP = {
    "name": "Ada Obi",
    "phone": "+2348022222222",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": {"lat": 6.4410, "lng": 3.4600},
}
DROPOFF = {
    "name": "Tunde Bello",
    "phone": "+2348033333333",
    "line1": "7 Ajose Adeogun Street",
    "area": "Victoria Island",
    "location": {"lat": 6.4281, "lng": 3.4219},
}


async def receipt(client, order_id: str, who: str = "customer", *, method: str = "get"):
    return await getattr(client, method)(f"/v1/orders/{order_id}/receipt", headers=auth(who))


async def kept(client, who: str = "customer") -> list[dict]:
    r = await client.get("/v1/receipts", headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def test_a_receipt_repeats_what_was_paid_and_is_kept_once_printed(flow, client):
    order = await flow.paid_order()
    r = await receipt(client, order["id"])
    assert r.status_code == 200, r.text
    shown = r.json()

    # Ready to print, not kept yet.
    assert shown["saved"] is False and shown["print_count"] == 0
    assert await kept(client) == []
    assert shown["number"] == f"YC-{order['short_code']}" and shown["order_id"] == order["id"]
    assert shown["seller"] == "Jollof Junction" and shown["service_name"] == "Order Food"
    assert shown["seller_address"] == order["restaurant_address"]

    # The lines and the charges are the order's own figures, and they add up.
    assert [(ln["quantity"], ln["name"], ln["amount_kobo"]) for ln in shown["lines"]] == [
        (ln["quantity"], ln["name"], ln["line_total_kobo"]) for ln in order["lines"]
    ]
    assert shown["lines"][0]["details"] == order["lines"][0]["selection_labels"] != []
    b = order["breakdown"]
    charges = {c["label"]: c["amount_kobo"] for c in shown["charges"]}
    assert charges["Subtotal"] == b["subtotal_kobo"] == sum(ln["amount_kobo"] for ln in shown["lines"])
    assert charges["Delivery fee"] == b["delivery_fee_kobo"] > 0
    assert charges["Service fee"] == b["service_fee_kobo"] > 0
    assert charges["VAT"] == b["vat_kobo"] > 0
    assert sum(charges.values()) == shown["total_kobo"] == b["total_kobo"]
    assert shown["paid_with"] == "Card, bank transfer or USSD"
    assert shown["payment_reference"] == order["payment_reference"] and shown["paid_at"]

    # PRINT keeps it under "My receipts"; printing again counts the copy and keeps one receipt.
    r = await receipt(client, order["id"], method="post")
    assert r.status_code == 200, r.text
    printed = r.json()
    assert printed["saved"] is True and printed["print_count"] == 1 and printed["printed_at"]
    again = (await receipt(client, order["id"], method="post")).json()
    assert again["print_count"] == 2 and again["issued_at"] == printed["issued_at"]
    mine = await kept(client)
    assert [m["number"] for m in mine] == [shown["number"]] and mine[0]["total_kobo"] == b["total_kobo"]
    assert (await receipt(client, order["id"])).json()["saved"] is True

    # Somebody else's receipts are their own.
    assert await kept(client, "customer2") == []


async def test_no_receipt_before_payment_and_only_for_the_customer(flow, client):
    order = await flow.order()
    for method in ("get", "post"):
        r = await receipt(client, order["id"], method=method)
        assert r.status_code == 409 and r.json()["error"]["code"] == "order_not_paid", r.text
    assert await kept(client) == []

    paid = await flow.paid_order()
    for who in ("customer2", "kitchen", "rider1"):
        for method in ("get", "post"):
            assert (await receipt(client, paid["id"], who, method=method)).status_code == 404, who
    assert (await receipt(client, "no-such-order")).status_code == 404
    assert (await client.get(f"/v1/orders/{paid['id']}/receipt")).status_code == 401
    assert (await client.get("/v1/receipts")).status_code == 401


async def test_newest_receipt_first_and_a_later_refund_shows(flow, client, container):
    first = await flow.paid_order()
    second = await flow.paid_order()
    await receipt(client, first["id"], method="post")
    await receipt(client, second["id"], method="post")
    assert [m["order_id"] for m in await kept(client)] == [second["id"], first["id"]]

    await container.repos.orders.update(first["id"], {"refund_total_kobo": 150_000})
    assert (await receipt(client, first["id"])).json()["refunded_kobo"] == 150_000


async def test_a_package_delivery_has_a_receipt_too(client):
    payload = {"pickup": PICKUP, "dropoff": DROPOFF, "size": "small", "category": "documents"}
    r = await client.post("/v1/parcels/quotes", json=payload, headers=auth("customer"))
    assert r.status_code == 201, r.text
    r = await client.post(
        "/v1/parcels", json={"quote_id": r.json()["id"]}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 201, r.text
    order = r.json()
    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")

    r = await receipt(client, order["id"], method="post")
    assert r.status_code == 200, r.text
    shown = r.json()
    assert shown["seller"] == "Yummy Chops" and shown["service_name"] == "Package Delivery"
    assert shown["lines"] == []
    assert (
        shown["summary"][0] == "From Lekki Phase 1 to Victoria Island"
        and shown["summary"][2] == "To Tunde Bello"
    )
    assert (
        sum(c["amount_kobo"] for c in shown["charges"])
        == shown["total_kobo"]
        == order["breakdown"]["total_kobo"]
    )
    assert any(c["label"] == "Delivery fee" for c in shown["charges"])


async def test_receipt_wording_for_wallet_and_cash_and_rows_that_must_add_up(flow, container):
    paid = await flow.paid_order()
    order = await container.repos.orders.get(paid["id"])
    now = datetime.now(UTC)

    def paid_with(provider: str) -> str:
        payment = order.payment.model_copy(update={"provider": provider})
        return build_receipt(order.model_copy(update={"payment": payment}), now).paid_with

    assert paid_with("wallet") == "Yummy Chops wallet"
    assert paid_with("cash") == "Cash on delivery"
    assert paid_with("paystack") == "Card, bank transfer or USSD"

    # A discount is printed as a negative row.
    b = order.breakdown
    discounted = order.model_copy(
        update={
            "breakdown": b.model_copy(update={"discount_kobo": 50_000, "total_kobo": b.total_kobo - 50_000})
        }
    )
    rows = {c.label: c.amount_kobo for c in build_receipt(discounted, now).charges}
    assert rows["Discount"] == -50_000 and sum(rows.values()) == b.total_kobo - 50_000

    # Rows that would not add up to the amount charged are never printed: the total stands alone.
    odd = order.model_copy(update={"breakdown": b.model_copy(update={"total_kobo": b.total_kobo + 1})})
    assert build_receipt(odd, now).charges == [] and build_receipt(odd, now).total_kobo == b.total_kobo + 1
