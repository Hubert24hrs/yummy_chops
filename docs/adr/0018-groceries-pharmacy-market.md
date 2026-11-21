# ADR-0018: Groceries, Pharmacy and Market Shopping

- **Status:** Accepted again on 2026-11-21 under the owner's names Shop & Groceries, Pharmacy and Buy Foodstuff
  ([ADR-0025](0025-six-services.md)). It was withdrawn on 2026-11-18
  ([ADR-0021](0021-supplements-and-skin-care-minimal-home.md)); the code removed then (commit 9cbede1) was merged
  back. The service names below are the 2026-11-17 ones.
- **Date:** 2026-11-17
- **Context owner:** owner's request of 2026-11-17: "add Groceries, Pharmacy and Market Shopping", with Chowdeck
  as the reference for how products and product types are organised

## Context

Yummy Chops sold Food and Beauty & Skin care through one order pipeline (ADR-0012) and carried packages. The owner
asked for three more services and named a reference app. What that reference does, as far as public pages and
its vendor help show:

- **Kinds of store.** Restaurants, supermarkets, pharmacies and local markets are separate entries on the home
  screen, each with its own list of stores.
- **How a store lists what it sells.** Categories hold items. An item has a name, a description, a picture, a
  price and an in-stock switch. Choices (size, pack, extras) hang off an item as option groups.
- **How a store page reads.** Search inside the store, a "popular" row, the categories to jump to, then a few
  products per category with a way to see the rest. Prices that depend on a choice start with "From". A product
  that has run out stays listed with an out-of-stock label.
- **Local markets.** A shopper buys for the customer. Foodstuff is sold by market measures (derica, paint,
  bunch, kilo) and as ready-made soup or stew combos.
- **Pharmacies.** Over-the-counter products only.

Rules that had to keep holding: money is integer kobo and priced only by `pricing.py`; order status changes
only through `OrderService.transition`; every seeded business is invented.

## Decision

### 1. Three new merchant services, same pipeline

- `Vertical` gains `grocery` ("Groceries"), `pharmacy` ("Pharmacy") and `market` ("Market Shopping").
  `MERCHANT_VERTICALS` is now food, beauty, grocery, pharmacy, market; `RETAIL_VERTICALS` names the three shops
  that sell by the aisle.
- A supermarket, a pharmacy or a market shopper is a `Restaurant` record with that vertical. Quotes, orders,
  payments, dispatch, tracking, refunds, settlements, promo codes, vouchers, the wallet and pay on delivery
  work unchanged, because none of them depend on what a shop sells.
- `GET /v1/services` lists the six services in the order the apps show them: Food, Groceries, Pharmacy, Market
  Shopping, Beauty & Skin care, Package Delivery.
- Each service has its own browse categories (`GET /v1/services/{vertical}/categories`), for example
  supermarkets, drinks, fresh, baby and household for Groceries.
- Order progress reads naturally for each service: "Sent to the store", "Packing your order"; "Sent to your
  shopper", "Buying your items".

### 2. Products

`MenuItem` already had `unit_label` and `popularity`. It gains:

| Field | Meaning |
|---|---|
| `brand` | The maker, when there is one |
| `emoji` | A picture until the shop uploads a photo |
| `requires_prescription` | Prescription-only: never shown to customers, never sold |

- **Sizes and measures** live in `unit_label`: "75 cl × 12", "12 tablets", "derica", "half paint", "bunch".
- **Choices** reuse option groups: eggs by the half or full crate, beef by weight and cut, vegetables whole or
  sliced. The price is still computed only by the server.
- **Stock** is the existing `is_available` switch. Out-of-stock products stay on the shop page.
- **Aisles** are the shop's menu categories.
- **Market shoppers** carry the badge "Shopper" on their card and page.

### 3. Pharmacy: over-the-counter only

- A product flagged `requires_prescription` is left out of the shop page and of search, and a quote that names
  it is refused (`item_unavailable`, reason `prescription_required`).
- The partner dashboard lets a pharmacy keep such a product on its list with the flag set, and says that
  customers cannot see it.
- The Pharmacy pages say "Over-the-counter products only".
- Yummy never diagnoses and never picks a medicine or a dose for a symptom: it shows what the customer names, or
  opens the matching Pharmacy category.

### 4. Apps and website

- **Home:** six service bubbles in two rows of three.
- **Service pages** (`/groceries`, `/pharmacy`, `/market`): the same page as Food and Beauty, with each
  service's own words (stores, pharmacies, markets) and a short note where customers need one.
- **Shop page for the three new services:** search in the shop, Popular, the aisles, a few products per aisle
  with "View more", brand and size on each product, "From" prices, out-of-stock labels. On the website a product
  with no choice to make is added with one tap.
- One place holds each service's wording: `mobile/core/lib/src/services.dart` and `apps/web/src/lib/services.ts`.
- **Partner dashboard:** shops manage "Products" with brand, size or measure, a picture and, for pharmacies, the
  prescription flag.
- **Yummy:** searches and opens the new services in the app, on the website and offline.

### 5. Benefits and limits

- Yummy Chops Plus covers all five merchant services with the same ₦3,000 minimum basket.
- Group orders stay with restaurants and beauty shops.
- The local demo shop autopilot accepts and packs orders at every kind of shop.

## Not built, and why

- **Substitutions** ("if it is out of stock, replace it or refund it"): needs a choice at checkout and a
  partial-refund flow at the shop. Today an out-of-stock product cannot be added, and a shop that cannot fill an
  order rejects it, which refunds it in full.
- **Priced by the weight actually bought** (market meat and fish): products are sold in fixed weights for now, so
  the customer pays exactly the quoted total.
- **Product photos:** partners cannot upload images yet; products show an emoji until they can.
- **Prescriptions:** no upload, no pharmacist review. Prescription medicines are not sold.

## To confirm with the owner

- The Plus minimum basket for supermarkets and markets (the reference app sets a higher one for them).
- Commission and the service fee for the new services (they use the platform defaults).
- A legal review of selling over-the-counter medicines online, including the pharmacy regulator's rules for
  the partners who will join.

## Consequences

- One pipeline now carries five kinds of shop; a new kind is a vertical, its categories and its words.
- Older app builds list the new shops only where they asked for every vertical, and show them with the Food
  layout; the new builds use the aisle layout.
- Seed data grew to 29 invented shops and 571 products across Lagos and Enugu.

## Tests

- API: `tests/integration/test_retail_services.py` (services and categories, shop pages, stock, measures, the
  over-the-counter rule, partner product fields, orders end to end in both cities, Plus, the autopilot).
- Live stack: `scripts/e2e_local.py grocery_order pharmacy_order market_order`.
- Apps: `mobile/customer/test/retail_test.dart`, `apps/web/src/app/restaurants/[id]/shop.test.tsx`.
- Yummy: `services/agents/tests/test_gudy.py` (finds shop products, opens the new services).
