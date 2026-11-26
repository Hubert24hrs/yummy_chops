"""Tools for shops to get their menu onto Yummy Chops (ADR-0034): item photos, and a whole menu or product list from a
spreadsheet.

Photos go through the API like every other file (firebase/storage.rules lets no app touch the bucket): the API checks
what the file is and its size, keeps it under `public/restaurants/{menu}/items/`, and serves it to everyone at
`/v1/media/...`. Each photo gets its own name (from its content), so a changed photo is never hidden by a cache.

The spreadsheet is a CSV file (Excel and Google Sheets save one with "Save as / Download → CSV"). The API reads it
twice: first as a preview of what would change (new, updated, unchanged, and every row it cannot use, with the
reason), then, only when no row has a problem, for real. Items are matched by name and size, so a shop can send the
same sheet again with new prices to update them.
"""

from __future__ import annotations

import base64
import binascii
import csv
import hashlib
import io
from decimal import Decimal, InvalidOperation
from typing import Any, Literal

from pydantic import BaseModel, Field

from ..domain.models import ItemKind, MenuItem
from ..domain.money import naira
from ..errors import NotFound, ValidationFailed
from ..repositories.repos import Repositories
from ..security.rbac import Principal, require_restaurant
from .catalog import CatalogService, ItemInput
from .files import EXTENSIONS, FileStore, check_upload

PHOTOS = {"image/jpeg", "image/png", "image/webp"}
PUBLIC_PREFIX = "public/restaurants/"
MAX_CSV_BYTES = 1_000_000
MAX_ROWS = 2_000
MAX_CATEGORIES = 40

#: Column headings a shop may use (lower case, spaces and dashes as underscores) and the field each one fills.
COLUMNS: dict[str, str] = {
    "category": "category",
    "section": "category",
    "department": "category",
    "name": "name",
    "item": "name",
    "product": "name",
    "item_name": "name",
    "product_name": "name",
    "price": "price",
    "price_naira": "price",
    "price_ngn": "price",
    "amount": "price",
    "description": "description",
    "details": "description",
    "size": "unit",
    "unit": "unit",
    "measure": "unit",
    "size_or_measure": "unit",
    "unit_label": "unit",
    "brand": "brand",
    "available": "available",
    "in_stock": "available",
    "stock": "available",
    "tags": "tags",
    "keywords": "tags",
    "prescription": "prescription",
    "needs_prescription": "prescription",
    "prescription_only": "prescription",
}
REQUIRED = ("category", "name", "price")
YES = {"yes", "y", "true", "1", "in stock", "available", "instock"}
NO = {"no", "n", "false", "0", "out of stock", "sold out", "unavailable", "outofstock"}

#: The template a shop downloads: the headings and two example rows.
TEMPLATE = (
    "category,name,price,size,brand,description,available,tags\n"
    "Drinks,Table water,2300,75 cl x 12,Eva,A pack of 12 bottles,yes,water\n"
    "Rice and pasta,Long grain rice,18500,5 kg,Mama Gold,,yes,rice\n"
)


class PhotoInput(BaseModel):
    """A photo, base64-encoded or as a browser data URL (at most 5 MB once decoded)."""

    data: str = Field(min_length=4, max_length=7_200_000)


class MenuImportInput(BaseModel):
    csv: str = Field(min_length=1, max_length=MAX_CSV_BYTES)
    #: False: only show what would change. True: make the changes (refused while any row has a problem).
    apply: bool = False


class ImportRow(BaseModel):
    row: int  # the line in the file (the headings are line 1)
    name: str = ""
    category: str = ""
    price_kobo: int | None = None
    action: Literal["create", "update", "unchanged", "error"]
    error: str | None = None
    changes: list[str] = Field(default_factory=list)


class ImportResult(BaseModel):
    applied: bool
    created: int
    updated: int
    unchanged: int
    errors: int
    new_categories: list[str]
    rows: list[ImportRow]


def _key(name: str, unit: str | None) -> tuple[str, str]:
    return (" ".join(name.lower().split()), " ".join((unit or "").lower().split()))


def _price(raw: str) -> int:
    text = raw.strip().replace("₦", "").replace(",", "").replace(" ", "")
    if text[:1] in ("N", "n"):
        text = text[1:]
    if text.upper().endswith("NGN"):
        text = text[:-3]
    try:
        value = Decimal(text)
    except InvalidOperation as exc:
        raise ValueError(f'"{raw}" is not a price') from exc
    if value <= 0:
        raise ValueError("The price must be more than ₦0")
    try:
        kobo = naira(value)
    except ValueError as exc:
        raise ValueError(f'"{raw}" has more than 2 decimal places') from exc
    if kobo > 100_000_000:
        raise ValueError("That price looks too high (at most ₦1,000,000)")
    return kobo


def _yes_no(raw: str, column: str) -> bool | None:
    text = raw.strip().lower()
    if not text:
        return None
    if text in YES:
        return True
    if text in NO:
        return False
    raise ValueError(f'"{raw}" in {column}: write yes or no')


def _read_csv(text: str) -> tuple[list[str], list[tuple[int, dict[str, str]]]]:
    """The fields the headings map to, and each non-empty row with its line number."""
    text = text.lstrip("﻿")  # Excel's "CSV UTF-8" starts with a byte order mark
    first = text.split("\n", 1)[0]
    delimiter = ";" if first.count(";") > first.count(",") else ","  # Excel in some locales uses semicolons
    reader = csv.reader(io.StringIO(text), delimiter=delimiter)
    try:
        headings = next(reader)
    except StopIteration:
        raise ValidationFailed("The file is empty") from None
    fields: list[str] = []
    for heading in headings:
        key = "_".join(heading.strip().lower().replace("-", " ").split())
        fields.append(COLUMNS.get(key, ""))
    missing = [f for f in REQUIRED if f not in fields]
    if missing:
        raise ValidationFailed(
            "The first line needs the column headings category, name and price "
            f"(missing: {', '.join(missing)}). Download the template to see the layout."
        )
    rows: list[tuple[int, dict[str, str]]] = []
    for line, cells in enumerate(reader, start=2):
        if not any(c.strip() for c in cells):
            continue
        row = {}
        for field, cell in zip(fields, cells, strict=False):
            if field and field not in row:
                row[field] = cell.strip()
        rows.append((line, row))
        if len(rows) > MAX_ROWS:
            raise ValidationFailed(f"Send at most {MAX_ROWS} items in one file")
    if not rows:
        raise ValidationFailed("The file has headings but no items")
    return fields, rows


class MenuToolsService:
    def __init__(
        self, repos: Repositories, catalog: CatalogService, files: FileStore, public_base_url: str
    ) -> None:
        self.repos = repos
        self.catalog = catalog
        self.files = files
        self.public_base_url = public_base_url.rstrip("/")

    # --- photos -------------------------------------------------------------------------------------------------
    async def set_photo(self, principal: Principal, restaurant_id: str, item_id: str, data: str) -> MenuItem:
        require_restaurant(principal, restaurant_id, "menu")
        item = await self.catalog._owned_item(restaurant_id, item_id)
        if data.startswith("data:") and "," in data:
            data = data.split(",", 1)[1]  # a data URL from a browser
        try:
            raw = base64.b64decode(data, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise ValidationFailed("The photo could not be read") from exc
        content_type = check_upload(raw, PHOTOS)
        digest = hashlib.sha256(raw).hexdigest()[:16]
        path = f"{PUBLIC_PREFIX}{item.restaurant_id}/items/{item.id}-{digest}.{EXTENSIONS[content_type]}"
        await self.files.put(path, raw, content_type)
        url = f"{self.public_base_url}/v1/media/{path}"
        await self.repos.items.update(item.id, {"image_url": url})
        return item.model_copy(update={"image_url": url})

    async def remove_photo(self, principal: Principal, restaurant_id: str, item_id: str) -> MenuItem:
        require_restaurant(principal, restaurant_id, "menu")
        item = await self.catalog._owned_item(restaurant_id, item_id)
        await self.repos.items.update(item.id, {"image_url": None})
        return item.model_copy(update={"image_url": None})

    async def media(self, path: str) -> tuple[bytes, str]:
        """A shop's public picture. Nothing outside public/restaurants/ is ever served from here."""
        if not path.startswith(PUBLIC_PREFIX) or ".." in path.split("/") or "\\" in path:
            raise NotFound("File not found")
        data, content_type = await self.files.get(path)
        if content_type not in PHOTOS:
            raise NotFound("File not found")
        return data, content_type

    # --- spreadsheet import -------------------------------------------------------------------------------------
    async def import_menu(
        self, principal: Principal, restaurant_id: str, data: MenuImportInput
    ) -> ImportResult:
        require_restaurant(principal, restaurant_id, "menu")
        restaurant = await self.catalog.get_restaurant(restaurant_id, include_inactive=True)
        shop = restaurant.vertical != "food"
        fields, rows = _read_csv(data.csv)
        categories = await self.repos.get_menu_categories(restaurant.menu_id)
        by_category = {c.name.strip().lower(): c for c in categories}
        existing: dict[tuple[str, str], MenuItem] = {}
        for item in await self.repos.list_items(restaurant.menu_id):
            if item.is_active:
                existing.setdefault(_key(item.name, item.unit_label), item)

        new_categories: list[str] = []
        seen: dict[tuple[str, str], int] = {}
        plans: list[tuple[ImportRow, dict[str, Any], MenuItem | None]] = []
        for line, row in rows:
            name = " ".join(row.get("name", "").split())
            category = " ".join(row.get("category", "").split())
            result = ImportRow(row=line, name=name, category=category, action="unchanged")
            try:
                if not name:
                    raise ValueError("The name is empty")
                if len(name) > 80:
                    raise ValueError("Keep the name under 80 characters")
                if not category:
                    raise ValueError("The category is empty")
                if len(category) > 60:
                    raise ValueError("Keep the category under 60 characters")
                if not row.get("price"):
                    raise ValueError("The price is empty")
                price = _price(row["price"])
                result.price_kobo = price
                unit = row.get("unit") or None
                brand = row.get("brand") or None
                description = row.get("description") or ""
                if unit and len(unit) > 30:
                    raise ValueError("Keep the size under 30 characters")
                if brand and len(brand) > 40:
                    raise ValueError("Keep the brand under 40 characters")
                if len(description) > 400:
                    raise ValueError("Keep the description under 400 characters")
                tags = [t.strip().lower() for t in row.get("tags", "").split(",") if t.strip()][:15]
                available = _yes_no(row.get("available", ""), "available")
                prescription = _yes_no(row.get("prescription", ""), "prescription")
                if prescription and restaurant.vertical != "pharmacy":
                    raise ValueError("Only pharmacies can list prescription products")
                key = _key(name, unit)
                if key in seen:
                    raise ValueError(f"The same item (name and size) is already on line {seen[key]}")
                seen[key] = line
                if category.lower() not in by_category and category not in new_categories:
                    if not any(c.lower() == category.lower() for c in new_categories):
                        new_categories.append(category)
                fields_given: dict[str, Any] = {"name": name, "price_kobo": price, "category": category}
                if unit is not None or "unit" in fields:
                    fields_given["unit_label"] = unit
                if brand is not None or "brand" in fields:
                    fields_given["brand"] = brand
                if description:
                    fields_given["description"] = description
                if tags:
                    fields_given["tags"] = tags
                if available is not None:
                    fields_given["is_available"] = available
                if prescription is not None:
                    fields_given["requires_prescription"] = prescription
                current = existing.get(key)
                if current is None:
                    result.action = "create"
                else:
                    cat_now = next((c.name for c in categories if c.id == current.category_id), "")
                    changes = [
                        label
                        for label, before, after in (
                            ("price", current.price_kobo, price),
                            ("category", cat_now.lower(), category.lower()),
                            ("brand", current.brand, fields_given.get("brand", current.brand)),
                            (
                                "description",
                                current.description,
                                fields_given.get("description", current.description),
                            ),
                            ("tags", current.tags, fields_given.get("tags", current.tags)),
                            (
                                "in stock",
                                current.is_available,
                                fields_given.get("is_available", current.is_available),
                            ),
                            (
                                "prescription",
                                current.requires_prescription,
                                fields_given.get("requires_prescription", current.requires_prescription),
                            ),
                        )
                        if before != after
                    ]
                    result.action = "update" if changes else "unchanged"
                    result.changes = changes
                plans.append((result, fields_given, current))
            except ValueError as exc:
                result.action = "error"
                result.error = str(exc)
                plans.append((result, {}, None))

        if len(categories) + len(new_categories) > MAX_CATEGORIES:
            raise ValidationFailed(
                f"A menu can have at most {MAX_CATEGORIES} categories; this file would make "
                f"{len(categories) + len(new_categories)}."
            )
        errors = sum(1 for r, _, _ in plans if r.action == "error")
        apply = data.apply and errors == 0
        if apply:
            if new_categories:
                names = [c.name for c in categories] + new_categories
                await self.catalog.set_categories(principal, restaurant_id, names)
            ids = {
                c.name.strip().lower(): c.id for c in await self.repos.get_menu_categories(restaurant.menu_id)
            }
            position = max((i.position for i in existing.values()), default=0)
            for result, given, current in plans:
                if result.action not in ("create", "update"):
                    continue
                body: dict[str, Any] = {k: v for k, v in given.items() if k != "category"}
                body["category_id"] = ids[given["category"].lower()]
                if current is None:
                    position += 1
                    body.setdefault("kind", ItemKind.PRODUCT if shop else ItemKind.MAIN)
                    body["position"] = position
                    await self.catalog.create_item(principal, restaurant_id, ItemInput(**body))
                else:
                    body["name"] = current.name  # keep the shop's own spelling and capitals
                    await self.catalog.update_item(principal, restaurant_id, current.id, ItemInput(**body))
        return ImportResult(
            applied=apply,
            created=sum(1 for r, _, _ in plans if r.action == "create"),
            updated=sum(1 for r, _, _ in plans if r.action == "update"),
            unchanged=sum(1 for r, _, _ in plans if r.action == "unchanged"),
            errors=errors,
            new_categories=new_categories,
            rows=[r for r, _, _ in plans],
        )
