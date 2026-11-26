# ADR-0034: Menu photos and menus from a spreadsheet

- **Status:** Accepted
- **Date:** 2026-11-26
- **Context owner:** the owner, preparing to onboard real shops so the demo shops can be removed.

## Context

Delivery platforms (Chowdeck, Glovo, Uber Eats, DoorDash) let each shop own its menu: the shop enters items, prices
and photos and keeps them up to date, and the platform's team helps with the first menu (and, for the big ones, pays
for a photo shoot). Yummy Chops already had the partner dashboard for items and prices, but no way to add a photo of
an item (only an emoji), and every item had to be typed one by one: impossible for a supermarket or pharmacy with
hundreds of products.

## Decision

1. **Item photos.** In the partner dashboard (Menu → edit an item) the shop adds, changes or removes a photo; it
   saves at once. The browser shrinks it first (at most 1200 px, JPEG), so uploads are fast on mobile data. The API
   checks what the file is (JPEG, PNG or WebP by its first bytes, at most 5 MB), keeps it with the other files
   (`services/files.py`: the bucket stays closed to apps, firebase/storage.rules) under
   `public/restaurants/{menu}/items/{item}-{hash}`, and serves it to everyone at `GET /v1/media/...` with a
   one-year cache: a new photo gets a new name. Nothing outside `public/restaurants/` is ever served there.
   The website's restaurant menus, shop pages and the customer app (dish rows, product cards) show the photo, and
   the emoji while there is none or it cannot load.
2. **A menu from a spreadsheet.** "Import from spreadsheet" takes a CSV file (Excel / Google Sheets → Save as CSV;
   comma or semicolon). Headings: `category`, `name`, `price` (naira; "₦1,500", "1500.50") are needed; `size`,
   `brand`, `description`, `available` (yes/no), `tags`, and for pharmacies `prescription` are optional. The API
   reads it first as a preview (new, update, unchanged, and every line it cannot use with the reason) and imports
   only when the shop confirms and no line has a problem: a file is never half imported. Items are matched by name
   and size, so sending the same sheet again with new prices updates them instead of adding copies; new categories
   are added after the existing ones. At most 2,000 lines per file and 40 categories per menu. Only the shop's
   owner or managers with the menu permission can import (`require_restaurant(..., "menu")`), as for editing items.

## Consequences

- Onboarding a shop: the team (or the shop) fills in the template from the shop's price list, imports it, then adds
  photos of the best sellers. The shop keeps prices up to date the same way.
- Old photos stay in storage when replaced (small JPEGs); a clean-up job can come later if it matters.
- Photos are served by the API (Cloud Run); a CDN in front of `/v1/media/` can come later if traffic needs it.
