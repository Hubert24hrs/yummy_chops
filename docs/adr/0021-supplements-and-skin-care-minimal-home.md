# ADR-0021: Three services, Supplements & Skin Care, and a minimal home page

- **Status:** Accepted; the three services and the name Supplements & Skin Care were superseded on 2026-11-21 by
  [ADR-0025](0025-six-services.md) (six services, Beauty & Skin Care). The minimal home stays, with six bubbles.
- **Date:** 2026-11-18
- **Context owner:** owner's request of 2026-11-18, from the phone: remove Groceries, Pharmacy and Market Shopping
  "and any features associated with them", rename "Beauty & Skin care" to "Supplements & Skin Care", and make the
  home page as minimal as possible, like Glovo's

## Decision

1. **Three services: Food, Supplements & Skin Care, Package Delivery.** Groceries, Pharmacy and Market Shopping
   ([ADR-0018](0018-groceries-pharmacy-market.md), now withdrawn) are gone from every part of the platform: the app,
   the website, the partner dashboard, Yummy, the API and the demo data. The API refuses `vertical=grocery`,
   `pharmacy` and `market` (422). Their own parts went with them: the aisle-style shop page, the "Shopper" badge,
   product brand and picture fields, and the prescription rule.
2. **Supplements & Skin Care keeps the id `beauty`.** Only the name changes, everywhere a person reads it (bubbles,
   pages, receipts, notifications, Yummy, WhatsApp). Renaming the id would touch stored orders, ledger metadata,
   routes (`/beauty`) and every client for no visible gain.
3. **The demo shops sell what the name says.** Make-up, fragrance and hair-care demo products became vitamins and
   supplements (Ivie & Oak Wellness, Coco Calabash Grooming, and supplements at Udala Glow Studio and Ekulu
   Naturals). Browse categories: Promotions, Supplements, Skincare, Body care, Men's grooming. Everything stays
   invented; no real brands.
4. **Yummy never gives health advice about supplements.** No diagnosis, no picking a supplement or a dose for a
   symptom, no claims that a product treats, cures or prevents anything; health worries, medicines, pregnancy and
   children go to a pharmacist or a doctor. This replaces the pharmacy rule.
5. **The home page is minimal, in the app and on the website:** the address, three big floating bubbles on the
   red header (two on top, one below), and the places picked for the customer. The promo card, "Send a package" card, Ask Yummy card,
   the three "why Yummy Chops" cards and the "Sell on Yummy Chops. Ride with Yummy Chops." banner are gone from it. Nothing
   was lost: deals show as a "Promo" tag on the shop tiles, Yummy floats over every tab and page, and the
   business and rider sign-ups are in the app's Profile and the website's footer.
6. **The website followed the same day.** At first its home kept the explanation sections (for visitors without
   the app); the owner chose to make it as minimal as the app. Its desktop headline and Yummy box went too: the
   bubbles sit centred, the page title stays for search engines and screen readers.

## Consequences

- To bring a removed service back, start from commit 1f45da5, where the three were added.
- The bubble label of a long name wraps into two even lines ("Supplements &" / "Skin Care") on both the app and
  the website.
- Before real supplement shops join: check the rules for selling supplements online in Nigeria (NAFDAC
  registration of each product, no health claims). See [NEXT_STEPS.md](../NEXT_STEPS.md).

## Tests

- API: `tests/integration/test_services_and_parcels.py` (three services, the new name, the categories, 19 shops).
- Yummy: `tests/test_gudy.py` (supplements by name, the service opens by its name, removed services not offered).
- Website: `src/app/home.test.tsx` (the minimal home), `src/components/redesign.test.tsx`. App:
  `test/parity_test.dart` (the minimal home),
  `test/redesign_test.dart`.
