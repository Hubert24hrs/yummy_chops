"""Shops put their menu on Yummy Chops: item photos and a whole list from a spreadsheet (ADR-0034)."""

from __future__ import annotations

import base64

from conftest import auth

SHOP = "r-jollof-junction"
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64
JPEG = b"\xff\xd8\xff\xe0" + b"\x01" * 64


async def first_item(client) -> dict:
    menu = (await client.get(f"/v1/partner/restaurants/{SHOP}/menu", headers=auth("owner"))).json()
    return menu["items"][0]


async def test_a_shop_adds_a_photo_that_everyone_can_see(client):
    item = await first_item(client)
    r = await client.post(
        f"/v1/partner/restaurants/{SHOP}/items/{item['id']}/photo",
        json={"data": "data:image/png;base64," + base64.b64encode(PNG).decode()},
        headers=auth("owner"),
    )
    assert r.status_code == 200, r.text
    url = r.json()["image_url"]
    assert "/v1/media/public/restaurants/" in url
    # Customers (signed in or not) load it, and it can be cached for a long time.
    pic = await client.get(url.split("://", 1)[1].split("/", 1)[1].join(["/", ""]))
    assert pic.status_code == 200
    assert pic.content == PNG
    assert pic.headers["content-type"] == "image/png"
    assert "immutable" in pic.headers["cache-control"]
    # The menu shows it; a new photo gets a new address, so no cache shows the old one.
    menu = (await client.get(f"/v1/partner/restaurants/{SHOP}/menu", headers=auth("owner"))).json()
    assert any(i.get("image_url") == url for i in menu["items"])
    r2 = await client.post(
        f"/v1/partner/restaurants/{SHOP}/items/{item['id']}/photo",
        json={"data": base64.b64encode(JPEG).decode()},
        headers=auth("owner"),
    )
    assert r2.json()["image_url"] != url
    assert r2.json()["image_url"].endswith(".jpg")
    # Taking it off.
    r3 = await client.delete(f"/v1/partner/restaurants/{SHOP}/items/{item['id']}/photo", headers=auth("owner"))
    assert r3.json()["image_url"] is None


async def test_only_pictures_from_the_shops_own_staff_are_accepted(client):
    item = await first_item(client)
    path = f"/v1/partner/restaurants/{SHOP}/items/{item['id']}/photo"
    pdf = {"data": base64.b64encode(b"%PDF-1.4 hello").decode()}
    assert (await client.post(path, json=pdf, headers=auth("owner"))).status_code == 422
    png = {"data": base64.b64encode(PNG).decode()}
    assert (await client.post(path, json=png, headers=auth("other_owner"))).status_code == 403
    assert (await client.post(path, json=png, headers=auth("customer"))).status_code == 403


async def test_media_serves_only_public_shop_pictures(client, container):
    await container.menu_tools.files.put("applications/u1/kyc/selfie.jpg", JPEG, "image/jpeg")
    assert (await client.get("/v1/media/applications/u1/kyc/selfie.jpg")).status_code == 404
    assert (await client.get("/v1/media/public/restaurants/../../applications/u1/kyc/selfie.jpg")).status_code == 404
    assert (await client.get("/v1/media/public/restaurants/nothing.png")).status_code == 404


SHEET = """category,name,price,size,brand,description,available,tags
Drinks,Table water,"2,300",75 cl x 12,Eva,A pack of 12,yes,water
Drinks,Malt drink,₦450.50,33 cl,,,,
Groceries,Long grain rice,18500,5 kg,Mama Gold,,no,"rice, grains"
"""


async def test_a_spreadsheet_is_previewed_then_imported_then_updates_prices(client):
    url = f"/v1/partner/restaurants/{SHOP}/menu/import"
    preview = (await client.post(url, json={"csv": SHEET}, headers=auth("owner"))).json()
    assert preview["applied"] is False
    assert (preview["created"], preview["updated"], preview["errors"]) == (3, 0, 0)
    assert preview["new_categories"] == ["Groceries"]  # the shop already has Drinks
    assert [r["price_kobo"] for r in preview["rows"]] == [230_000, 45_050, 1_850_000]
    before = (await client.get(f"/v1/partner/restaurants/{SHOP}/menu", headers=auth("owner"))).json()
    assert not any(i["name"] == "Table water" for i in before["items"])  # a preview changes nothing

    done = (await client.post(url, json={"csv": SHEET, "apply": True}, headers=auth("owner"))).json()
    assert done["applied"] is True
    menu = (await client.get(f"/v1/partner/restaurants/{SHOP}/menu", headers=auth("owner"))).json()
    items = {i["name"]: i for i in menu["items"]}
    cats = {c["id"]: c["name"] for c in menu["categories"]}
    assert items["Table water"]["price_kobo"] == 230_000
    assert items["Table water"]["unit_label"] == "75 cl x 12"
    assert items["Table water"]["brand"] == "Eva"
    assert cats[items["Long grain rice"]["category_id"]] == "Groceries"
    assert items["Long grain rice"]["is_available"] is False
    assert items["Long grain rice"]["tags"] == ["rice", "grains"]

    # The same sheet again with a new price: one update, nothing doubled.
    again = SHEET.replace("18500", "19000")
    result = (await client.post(url, json={"csv": again, "apply": True}, headers=auth("owner"))).json()
    assert (result["created"], result["updated"], result["unchanged"]) == (0, 1, 2)
    assert result["rows"][2]["changes"] == ["price"]
    menu = (await client.get(f"/v1/partner/restaurants/{SHOP}/menu", headers=auth("owner"))).json()
    rice = [i for i in menu["items"] if i["name"] == "Long grain rice"]
    assert len(rice) == 1 and rice[0]["price_kobo"] == 1_900_000


async def test_a_sheet_with_a_bad_row_changes_nothing_and_says_which_row(client):
    url = f"/v1/partner/restaurants/{SHOP}/menu/import"
    bad = "Category;Product name;Price\nDrinks;Zobo;abc\nDrinks;Chapman;1200\nDrinks;Chapman;1300\n;Kunu;500\n"
    result = (await client.post(url, json={"csv": bad, "apply": True}, headers=auth("owner"))).json()
    assert result["applied"] is False
    errors = {r["row"]: r["error"] for r in result["rows"] if r["action"] == "error"}
    assert set(errors) == {2, 4, 5}
    assert "not a price" in errors[2]
    assert "line 3" in errors[4]
    assert "category is empty" in errors[5]
    menu = (await client.get(f"/v1/partner/restaurants/{SHOP}/menu", headers=auth("owner"))).json()
    assert not any(i["name"] == "Tiger nut milk" for i in menu["items"])


async def test_a_sheet_without_the_headings_is_explained(client):
    url = f"/v1/partner/restaurants/{SHOP}/menu/import"
    r = await client.post(url, json={"csv": "Zobo,500\n"}, headers=auth("owner"))
    assert r.status_code == 422
    assert "template" in r.text
    assert (await client.post(url, json={"csv": SHEET}, headers=auth("other_owner"))).status_code == 403
    template = await client.get("/v1/partner/menu-template.csv", headers=auth("owner"))
    assert template.text.startswith("category,name,price")


async def test_kitchen_staff_cannot_change_the_menu(client):
    url = f"/v1/partner/restaurants/{SHOP}/menu/import"
    assert (await client.post(url, json={"csv": SHEET}, headers=auth("kitchen"))).status_code == 403
