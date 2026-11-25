"""Shop statements (settlements): a statement never asks Finance to pay more than the shop is owed."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from conftest import auth
from gudmeal_api.ledger import ledger as postings

SHOP = "r-jollof-junction"


def iso(moment: datetime) -> str:
    return moment.isoformat()


async def generate(client, start: datetime, end: datetime) -> list[dict]:
    r = await client.post(
        "/v1/admin/settlements/generate",
        json={"period_start": iso(start), "period_end": iso(end)},
        headers=auth("finance"),
    )
    assert r.status_code == 201, r.text
    return [row for row in r.json() if row["restaurant_id"] == SHOP]


async def statements(client) -> list[dict]:
    rows = (await client.get("/v1/admin/settlements", headers=auth("finance"))).json()
    return [row for row in rows if row["restaurant_id"] == SHOP]


async def owed(container) -> int:
    async with container.db.session() as s:
        return await container.ledger.balance(s, f"liability:restaurant:{SHOP}")


async def connect_bank(client) -> None:
    business = (
        await client.post("/v1/partner/business", json={"restaurant_id": SHOP}, headers=auth("owner"))
    ).json()
    r = await client.put(
        f"/v1/partner/business/{business['id']}/bank",
        json={"bank_code": "058", "account_number": "0123456789"},
        headers=auth("owner"),
    )
    assert r.status_code == 200, r.text


async def test_a_share_paid_by_split_is_not_paid_again(flow, client, container):
    await connect_bank(client)
    start = datetime.now(UTC) - timedelta(hours=1)
    order = await flow.paid_order()
    share = (await container.repos.orders.get(order["id"])).settlement.restaurant_earning_kobo
    cut = datetime.now(UTC)  # the split is in the first period, the completion in the second
    assert (await flow.deliver(order["id"]))["status"] == "completed"
    assert await owed(container) == 0

    first = await generate(client, start, cut)
    second = await generate(client, cut, datetime.now(UTC) + timedelta(hours=1))
    assert first[0]["net_kobo"] == -share and second[0]["net_kobo"] == 0
    for row in await statements(client):
        assert row["gross_kobo"] - row["commission_kobo"] + row["adjustments_kobo"] == row["net_kobo"]
        paid = await client.post(
            f"/v1/admin/settlements/{row['id']}/paid",
            json={"bank_reference": "BANK-1"},
            headers=auth("finance"),
        )
        assert paid.status_code == 200
    assert await owed(container) == 0  # nothing was paid out a second time


async def test_statements_are_capped_do_not_overlap_and_payout_checks_the_balance(flow, client, container):
    start = datetime.now(UTC) - timedelta(hours=1)
    order = await flow.paid_order()
    assert (await flow.deliver(order["id"]))["status"] == "completed"
    earned = await owed(container)
    cut = datetime.now(UTC)
    first = await generate(client, start, cut)
    assert first[0]["net_kobo"] == earned > 0
    assert (
        await generate(client, start - timedelta(days=1), cut) == []
    )  # the same days, not on two statements

    # A refund the shop bears arrives after the statement was made: it is owed less than the statement says.
    async with container.db.transaction() as s:
        await container.ledger.post(
            s,
            kind="refund",
            idempotency_key="test:refund",
            postings=postings.refund_issued(
                provider="local_sandbox",
                amount_kobo=10_000,
                stage="after_completion",
                liability="restaurant",
                restaurant_id=SHOP,
            ),
            created_by="test",
        )
    r = await client.post(
        f"/v1/admin/settlements/{first[0]['id']}/paid",
        json={"bank_reference": "BANK-1"},
        headers=auth("finance"),
    )
    assert r.status_code == 422 and "owed less" in r.json()["error"]["message"]

    # The next statement takes off what the unpaid one promises, and so carries the refund.
    again = await flow.paid_order()
    assert (await flow.deliver(again["id"]))["status"] == "completed"
    second = await generate(client, cut, datetime.now(UTC) + timedelta(hours=1))
    assert second[0]["net_kobo"] == await owed(container) - earned
    r = await client.post(
        f"/v1/admin/settlements/{first[0]['id']}/paid",
        json={"bank_reference": "BANK-1"},
        headers=auth("finance"),
    )
    assert r.status_code == 200  # the shop has now earned the difference
