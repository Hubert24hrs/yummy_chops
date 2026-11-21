# ADR-0025: Six services: Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, Package Delivery

- **Status:** Accepted (built and tested with invented demo shops; the decisions listed under "Open" are the owner's)
- **Date:** 2026-11-21
- **Context owner:** owner's request of 2026-11-21: "add these features to the interface: Order Food, Pharmacy,
  Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, Package Delivery; also add all activities related to it, if
  any exist already then don't duplicate, change the 'food' to 'Order Food', 'Supplement & Skin Care' to 'Beauty &
  Skin Care', add others"
- **Supersedes:** the "three services" part of [ADR-0021](0021-supplements-and-skin-care-minimal-home.md) (the
  minimal home stays) and the withdrawal of [ADR-0018](0018-groceries-pharmacy-market.md), which applies again
  under the new names

## Context

On 2026-11-17 the owner asked for Groceries, Pharmacy and Market Shopping (ADR-0018). On 2026-11-18 they removed
them and renamed Beauty & Skin care to Supplements & Skin Care (ADR-0021). On 2026-11-21 they asked for six
services by name, in this order. Nothing was to be built twice: the three shop services existed in commit
1f45da5 and were removed in 9cbede1, and Food, Supplements & Skin Care and Package Delivery were live.

## Decision

1. **Six services, in the owner's order and names.** The service ids do not change, so orders, wallets, Plus,
   receipts and the apps already in people's hands keep working:

   | Shown as | Service id | Website | App route |
   |---|---|---|---|
   | Order Food | `food` | /food | /food |
   | Pharmacy | `pharmacy` | /pharmacy | /pharmacy |
   | Beauty & Skin Care | `beauty` | /beauty | /beauty |
   | Shop & Groceries | `grocery` | /groceries | /groceries |
   | Buy Foodstuff | `market` | /foodstuff | /market |
   | Package Delivery | `parcel` | /send | /send |

   `GET /v1/services`, the home bubbles, the website header and footer, the service pages, receipts, spending
   summaries, Yummy (in the app and on WhatsApp) and the partner dashboard all use these names and this order.
   Inside a sentence the plain words stay ("food, pharmacy items, beauty products, groceries and foodstuff").

2. **The shop services come back from commit 1f45da5, not rewritten.** Everything 9cbede1 removed was merged back
   onto today's code: the `grocery`, `pharmacy` and `market` verticals and their browse categories, the demo shops
   (`seed/retail.py`: 7 in Lagos, 3 in Enugu, all invented), products by the aisle with brand, size or market
   measure, stock and "From" prices (website `restaurants/[id]/shop.tsx`, app `shop_view.dart`), the "Shopper" badge,
   the over-the-counter rule (a prescription-only product is hidden from customers and refused in quotes), the
   order progress words ("Buying your items" for a market shopper), the partner product form (brand, size or
   measure, picture, prescription flag), Yummy's word lists and the end-to-end journeys. ADR-0018 describes them.

3. **Beauty & Skin Care sells beauty again.** The demo beauty shops go back to skincare, body care, hair care,
   make-up, fragrance and men's grooming, and the bubble shows a lipstick again. Vitamins and supplements are sold
   by the pharmacies ("Vitamins & supplements" aisle), so nothing is sold twice.

4. **The minimal home shows six bubbles.** Two rows of three, smaller than the three big ones; a long name wraps
   into two even lines ("Beauty &" / "Skin Care") and "&" never starts a line. The picks below add one shop of
   each new kind, so people find them from the home page. Nothing else returns to the home (ADR-0021 stands).

5. **Every kind of shop can sign up.** "Add your business" (website and app) asks for the kind of business:
   Restaurant (Order Food), Pharmacy, Beauty & Skin Care shop, Supermarket or store (Shop & Groceries) or Market
   shopper (Buy Foodstuff). The approved shop appears under that service with a first shelf to fill ("Mains",
   "Products" or "Foodstuff"). A pharmacy must give its Pharmacists Council of Nigeria (PCN) premises licence
   number, which the team checks before the pharmacy goes live. The Command Centre shows the kind on each
   application.

## Consequences

- Phones need the new customer app build to see six bubbles and the new names; the rider app does not change.
- The API accepts `vertical=grocery|pharmacy|market` again (no more 422).
- `docs/NEXT_STEPS.md` lists the owner's open decisions again.

## Open (the owner's decisions)

- Plus minimum basket for supermarkets and market shoppers (now ₦3,000, as for food), and the commission for the
  new kinds of shop (now the platform default).
- A legal review of selling over-the-counter medicines online before real pharmacies join, including how the PCN
  licence is checked.

## Tests

API `tests/integration/test_retail_services.py` (six services in the owner's order, shop pages, the
over-the-counter rule, orders end to end, sign-up by kind of business with the pharmacy licence), agents
`tests/test_gudy.py`, website `home.test.tsx`, `redesign.test.tsx`, `restaurants/[id]/shop.test.tsx`, customer app
`retail_test.dart`, `parity_test.dart`, `redesign_test.dart`, and the journeys in `services/api/scripts/e2e_local.py`.
