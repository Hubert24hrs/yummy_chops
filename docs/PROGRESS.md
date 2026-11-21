# Yummy Chops — status report (2026-11-21)

**Bottom line:** the core marketplace, payments/ledger, dispatch, AI agents, three web apps and two Flutter
apps are implemented and tested locally. On 2026-11-15 the owner chose a multi-service direction (see
[ROADMAP.md](ROADMAP.md#multi-service-expansion-owner-decisions-of-2026-11-15)); **phase 1 of it is done**: a
Glovo-style redesign of the customer app and website (since 2026-11-18 in the Yummy Chops logo's red, chocolate brown and orange-gold, [ADR-0022](adr/0022-brand.md)), six services since 2026-11-21 ([ADR-0025](adr/0025-six-services.md)): **Order
Food**, **Pharmacy**, **Beauty & Skin Care**, **Shop & Groceries**, **Buy Foodstuff** and **Package
Delivery** (instant and scheduled), **Lagos and Enugu**, and **Yummy**, the AI assistant (five languages, offline
mode). **Phase 2 is done too**: the **Yummy Chops wallet** (top-up, one-tap pay, instant refunds), **pay on delivery**
with rider cash tracking and hand-ins, **cash on delivery for sellers** with payouts, and **Flutterwave failover**
([ADR-0013](adr/0013-wallet-and-cash.md); the wallet still needs a legal review). **Phase 3 is done**: the **interstate waybill** between Lagos, Enugu, Abuja and Port Harcourt. It covers home
pickup or hub drop-off, line haul by partner carriers, door delivery or hub collection, public tracking
numbers and a hub console ([ADR-0015](adr/0015-interstate-waybill.md)). Its hubs and carriers are **sample
data** until real partners sign. **Phase 4 is done**:

- **Yummy Chops Plus**: free delivery from ₦3,000, half-price service fees and double points, for ₦1,500 per
  30 days, with wallet auto-renewal
- **Yummy points and referrals**, paid out as vouchers only, never cash
- **group orders with split bill**

See [ADR-0016](adr/0016-plus-rewards-group-orders.md). Prices and rewards are product defaults for the
owner to confirm. **Phase 5 is built and tested against a local WhatsApp sandbox**: customers link their
WhatsApp number with a one-time code, then chat with Yummy to order, approve with Yes/No buttons, pay on the
secure payment page, share a location and track orders ([ADR-0017](adr/0017-assistant-on-whatsapp.md)).
Switching it on needs the owner's Meta WhatsApp Business account, number and keys, and approval of Meta's
messaging charges. **Google Maps Platform** is integrated ([ADR-0014](adr/0014-google-maps-platform.md), setup and costs in
[GOOGLE_MAPS.md](GOOGLE_MAPS.md)): address search with exact pins, road-distance delivery fees, private live
rider tracking, nearby maps, kitchen pins, an operations map and Yummy "near me" answers. It runs on clearly
labelled estimates until the owner adds a key. **Only the websites, the domain and the email are live** (since
2026-11-20: Vercel at yummy247.com, mail at Zoho; the API and Yummy are not deployed yet), and the product is
**not production-ready**: cloud resources, real payment
test-mode, a Gemini key and the items in [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) are still required.

## What has been built

| Area | Contents |
|---|---|
| Architecture | System/data/security/AI docs, 23 ADRs (ADR-0023: the name Yummy Chops and the yummy247.com domain; ADR-0022: the brand's logo, icons and colours; ADR-0025: six services in the owner's order and names; ADR-0021: three services, Supplements & Skin Care and a minimal app home page (services superseded by 0025); ADR-0020: phone test apps find the test server by themselves; ADR-0018: Groceries, Pharmacy and Market Shopping (back as Shop & Groceries, Pharmacy and Buy Foodstuff); ADR-0019: receipts and the receipt printer; ADR-0012: one order pipeline for food, beauty and parcels; ADR-0013: wallet, pay on delivery, vendor COD, failover; ADR-0014: Google Maps Platform behind the API; ADR-0015: interstate waybill; ADR-0016: Plus, rewards and group orders; ADR-0017: Yummy on WhatsApp), roadmap with the owner's product decisions |
| `services/api` | Catalog & search, deterministic pricing (fees, VAT, vouchers, ₦50 fee rounding), quotes, orders with a 17-state machine, Paystack/Flutterwave/sandbox payments, signed webhooks, refunds with finance approval, double-entry append-only ledger, settlements, rider payouts, dispatch scoring with offer timeouts and manual dispatch, OTP delivery & pickup codes, reviews, support tickets, onboarding approvals that set Firebase custom claims, admin analytics/forecast, audit log, outbox, Alembic migration; **multi-service**: merchant verticals (food, beauty) and cities (Lagos, Enugu), browse categories and promotions, Package Delivery (parcel quotes and orders, scheduled pickups released by a task, cancel-until-rider refunds, no-merchant settlement), customer order totals, Lagos/Enugu neighbourhood lookup, support contacts; **money (phase 2)**: closed-loop wallet (top-ups, one-tap pay under an account row lock, instant refunds), pay on delivery (eligibility, cash confirmed at the door, rider cash receivables, hand-ins, dispatch cash limit, support block), vendor COD on packages (fee in pricing, seller balance, payouts, move to wallet), gateway failover with a circuit breaker, automatic refund of duplicate payments, money guard on order status, migration 0002; **logistics (phase 3)**: interstate waybill (network of cities, hubs, carriers and lanes in configuration; deterministic line-haul pricing and expected dates; quotes and bookings; first- and last-mile rider jobs dispatched like packages; hub receive/depart/arrive/hand-over with compare-and-set milestones; public tracking numbers without personal data; carrier balances and payouts in the ledger; full refund until the package is with a rider or at a hub); **growth (phase 4)**: Yummy Chops Plus (member pricing in the engine, card or wallet payments, a daily wallet auto-renewal job, cancel by turning auto-renew off), Yummy points (earned on completion, reversed on refunds, redeemed for personal vouchers), referral codes with welcome and thank-you vouchers (monthly cap), group orders (shared cart, join codes, one order, split bill paid per member, the host can pay the rest, expiry refunds, refunds split between payers), migration 0003; **WhatsApp (phase 5)**: Meta webhook (verification challenge, `X-Hub-Signature-256` signatures), de-duplication by message id and one Cloud Task per message, linking a number by one-time code, customer-only channel tokens for Yummy, Yes/No approval buttons and payment links, shared locations used as the delivery address, `STOP` and disconnect in the app, masked numbers in audit, a sandbox sender and a WhatsApp simulator, an App Check exemption for Yummy Chops' agents service (which still cannot reach internal endpoints); 166 HTTP paths (with the 7 maps endpoints) |
| `services/agents` | **Yummy**: LangGraph graph (guard → router → specialist ⇄ tools), 8 agents, 45 typed tools (services, totals, navigation buttons, support contacts, parcel quote and booking, read-only wallet and payment options, waybill routes and tracking, Plus, rewards and group orders added), replies in English, Pidgin, Igbo, Yoruba or Hausa, rule-based **offline mode** without a Gemini key, `interrupt()` approvals, Postgres/SQLite/memory checkpointers, thread ownership, tool audit, token/cost accounting, Gemini via env-pinned model; **WhatsApp (phase 5)**: accepts the API's channel tokens (customer role only), short plain replies on WhatsApp, a service credential on its API calls, orders and tickets tagged `whatsapp`, approvals that say where the order goes |
| Web | Customer site, **redesigned Glovo-style in the Yummy Chops logo's colours** (animated draggable service bubbles, /food, /beauty, /send, /discover with the **dish carousel** (most loved, new kitchens, top-rated kitchens; the app's plates; Order food opens the dish on the menu), /support, Profile-style account, mobile bottom bar, floating Yummy, wallet page, card/wallet/pay-on-delivery choice at checkout, cash-on-delivery for packages, **interstate waybill** booking with expected dates, a public `/track` page and a printable label, **Yummy Chops Plus**, **Rewards** (points, vouchers, invite friends) and **group orders** (Order with friends, join by code, split bill), **Connect WhatsApp** on the account page) plus SEO pages, JSON-LD, sitemap, checkout, payment callback, tracking, Yummy chat with approvals + voice; Partner dashboard (live board with alerts, menu editor, insights, settlements, hours), Command Centre (overview, order intervention, verification, refunds, payments, finance, **cash & wallets** (rider cash hand-ins, seller withdrawals, pay-on-delivery block, carrier payouts), **hubs** (scan in, depart with a trip reference, arrive, hand over against the collection code), **growth** (Plus members and revenue, points, referrals, settings), support, AI monitoring, pricing config, flags, audit) |
| Mobile | `gud_meal_core` (Freezed models, Dio clients, auth port, theme from tokens), customer app **redesigned Glovo-style** (home with animated, finger-draggable bubbles drawn as original illustrations; Food and Beauty pages; Package Delivery with cash on delivery; Discover with the **dish carousel**; Orders with spending; Support; Profile; **wallet**; card/wallet/pay-on-delivery choice; **interstate waybill** booking, tracking history and collection code; **Yummy Chops Plus**, **Rewards** and **group orders** with split bill; **Order on WhatsApp** in Profile; draggable Yummy robot and chat), rider app (online/GPS, offers with countdown, pickup/transit/OTP delivery, **cash collection confirmation**, package jobs with sender/recipient call buttons, waybill pickup and door-delivery jobs with a hub hand-over card, navigation, earnings with cash held, SOS) |
| Maps | Google Places (New), Geocoding and Routes **only inside the API** (server key; keyless fallback to the neighbourhood table and labelled estimates): `/v1/places/*`, `/v1/delivery/estimates`; delivery fee, rider pay and ETA on the measured road distance (stored on the quote so the order prices the same); rider privacy (no pings while offline, ~1 km areas when idle, precise only on a delivery, cleared at the end); partner kitchen pins checked against the address and audited; operations live-rider map; cost controls (field masks, session tokens, caches, daily cap, traffic-aware switch, 3-minute live ETA refresh). Apps: address picker, nearby map, live delivery map (schematic without a key, Google tiles with restricted keys), rider turn-by-turn links; website checkout search and order map; partner Kitchen location; Command Centre Live riders; Yummy `find_nearby_restaurants` and `compare_delivery_times` |
| Firebase | Deny-by-default Firestore & Storage rules, composite indexes, quote TTL, emulator config, rules tests |
| Delivery | Dockerfiles, CI workflow, manual deploy workflow, Cloud Build config, GCP bootstrap & deploy scripts (service identities, channel-token and WhatsApp secrets, Firestore TTL for WhatsApp records). The three websites deploy as Cloud Run services too: one image per app (Next.js standalone output, non-root, smoke-tested in CI), browser settings from GitHub Environment variables, and Cloud Run's deterministic URLs, so CORS, the payment return page and the OIDC audience are right on the first deploy |

## What works (verified)

- Full order lifecycle through the HTTP API: quote → order → checkout → signed webhook → server verification →
  ledger → restaurant accept → dispatch → rider pickup → live tracking → OTP delivery → completion → settlement.
- The same lifecycle **in a browser** against the running stack (Firebase Auth emulator + API + Next.js):
  sign-in, menu customisation, voucher, server quote (₦13,499.38 with exact VAT), sandbox payment, callback
  verification, tracking with delivery code, completion, review; Command Centre showed matching GMV, a balanced
  trial balance and a generated settlement (₦9,775 net to the restaurant).
- The vision request (“₦10,000, best meal for two before 8pm, order it”) through the agents service against the
  real API: plans within budget, a draft order, an approval screen with the exact API total, then a payment link;
  declining never charges.
- **Yummy Chops Partner in a browser** (restaurant owner account, Auth emulator + API, sandbox-paid orders): live
  board with a “(n) New orders” title alert; reject with a reason → automatic full refund (₦18,031.88); accept with
  a custom prep time → start preparing → mark ready; pickup handover (a wrong code shows “Incorrect code”, the
  right code completes the order); sold-out toggle, item edit (₦1,650.50 + description) and a new item, all
  reflected in the public menu API; insights (gross ₦1,500, earnings ₦1,275 after ₦225 commission, 67%
  acceptance); payouts empty state; pause/resume reflected in the public listing; opening hours including
  past-midnight trading (Saturday 10:00–02:00). The ledger trial balance stayed equal (₦102,035.02 each side).
  Partner and Command Centre layouts checked at 375 px, 768 px and 1280 px: no horizontal page scroll.
- Flutter customer app (web build) rendering live restaurants and menus from the API.
- **Multi-service phase 1 in a browser** (phone-size viewport, Auth emulator + API + agents in offline mode):
  - *Mobile app (Flutter web build)*: home bubbles pop in, follow a drag and spring back, and a tap opens the
    service; Food and Beauty pages with categories, filters, popular brands and store cards; Discover; Support;
    Profile signed in and out. Yummy answered “What do you offer?” with service chips and a Pidgin question about
    spending in Pidgin. **Package Delivery booked end to end**: Lekki → Ikota, 8.4 km, small parcel quoted at
    ₦2,700 + ₦100 booking fee + ₦210 VAT = **₦3,010**, booked, paid in the sandbox, then shown as “Finding a rider”
    with the recipient code and a pickup → drop-off card.
  - *Website*: the same home bubbles and Yummy button, bottom tab bar, Food page, Support, and a parcel quote from
    the real API (Lekki → Yaba, 13.1 km: ₦3,650 + ₦100 + ₦281.25 VAT = ₦4,031.25).
  - Bugs found and fixed while testing: sign-in screen not closing after a successful sign-in, section titles
    squeezed by a spacer, Yummy greeting pushing its button off-screen, a bubble's rest position outside the
    physics bounds (never settled), validation messages hidden below the fold, food wording on parcel orders,
    filter pills wrapping, and the partner editor rejecting the new “product” item kind.
- **Phase 2 (money) on the running local stack** (Auth emulator + API + agents, demo accounts):
  - *Website*: a ₦10,000 wallet top-up started on the wallet page, approved on the sandbox checkout page and
    credited (statement shows “Wallet top-up”).
  - *API as the apps call it* (signed in with emulator tokens): payment options for a ₦6,655.63 order showed card ✓,
    wallet ✓ and pay on delivery ✗ “unlocks after your first order”; paying from the wallet sent the order to the
    restaurant and left ₦3,344.37; cancelling refunded ₦6,655.63 into the wallet at once; a package with ₦25,000
    cash on delivery priced at ₦1,900 + ₦100 + ₦380 collection fee + ₦178.50 VAT = ₦2,558.50; the Command Centre
    cash view showed ₦10,000 in customer wallets and refused the customer (403); Yummy read the wallet and its
    history and explained pay on delivery in Pidgin.
  - The visual pass of the new screens in the browser pane was limited because the pane was hidden during this
    session; the screens are covered by widget/component tests and the production builds.

- **Phase 3 (interstate waybill) on the running local stack.** The setup was the Auth emulator, the API and the
  agents with the demo accounts, signed in with emulator tokens as the apps are.
  - *Routes.* Lagos sends to Enugu (from ₦5,052.50, 1–2 days, door delivery). It also sends to Abuja and Port
    Harcourt (from ₦5,590, collection at a partner terminal).
  - *Door to door.* Lekki to Independence Layout (Enugu), 3.2 kg, with ₦25,000 cash on delivery:

    | Line haul | Pickup | Delivery | Booking | COD fee | VAT | Total |
    |---|---|---|---|---|---|---|
    | ₦5,100 | ₦1,300 | ₦1,100 | ₦200 | ₦380 | ₦606 | **₦8,686** |

    It was expected Tue 17 to Thu 19 Nov.
  - *Drop-off and collection.* Lagos (Lekki hub) to Abuja (Utako terminal), 1.5 kg of documents, **₦5,590**,
    booked and paid from the wallet.
    - The Lekki board listed the package, and the customer was refused access to the board (403).
    - A scan at the wrong hub was refused.
    - Receive, depart (trip LAG-ABJ-0907) and arrive followed.
    - A wrong collection code was refused; the right code completed and settled the order.
  - *Tracking and money.*
    - Public tracking showed six milestones and no names or phone numbers.
    - Yummy tracked the package by number.
    - Finance saw ₦3,000 owed to Sample Carrier North and recorded the payout. Paying more than was owed (422) and
      a hub agent recording a payout (403) were refused.
  - *Bugs found and fixed during this check:*
    - Pay on delivery was offered on door-to-door waybills.
    - An internal rider job could be sent to checkout.
    - Yummy's tracking reply kept the expected date after delivery and did not label the collection point.
  - *Not checked in a browser.* The browser pane was hidden, so the new screens were not checked visually: the
    website booking form, tracking page and label, the hub console, and the app screens. Component and widget
    tests and the production builds cover them.

- **Phase 4 (Plus, rewards, group orders) on the running local stack.** The setup was the Auth emulator, the
  API and the agents. Two demo customers took part: Ada and Bayo, the new `friend@yummychops.test`.
  - *Yummy Chops Plus.* ₦1,500 for 30 days (₦104.65 VAT included). Ada joined from her wallet. The same Jollof
    Junction order then cost less:

    | | Delivery | Service fee | Total |
    |---|---|---|---|
    | Before | ₦800 | ₦1,500 | ₦38,472.50 |
    | As a member | ₦0 | ₦750 | ₦36,806.25 |

    That is ₦1,666.25 saved, matching the quote's savings line. Paying again straight away was refused.
  - *Referrals.* Bayo applied Ada's code and got a ₦1,000 welcome voucher for orders from ₦3,000. Ada could not
    use her own code, and Bayo's personal voucher was "not recognised" in Ada's quote.
  - *Group order with split bill.*
    - Ada started a group at Jollof Junction, Bayo joined with the 6-character code, and each added items
      (₦33,000 and ₦3,000).
    - Ada locked the cart and placed one order for ₦36,806.25, with her Plus benefits applied to the group.
    - The shares came to ₦33,739.06 and ₦3,067.19 and add up exactly to the total.
    - Paying the whole order directly was refused (409).
    - Bayo paid by card in the sandbox and the order stayed `pending_payment`. Ada then paid from her wallet,
      and the order went to the restaurant with payment provider `group`.
  - *Yummy.* It confirmed Ada's membership date, gave her points and referral code, and listed Bayo's group order
    with "your share ₦3,067.19 (paid)".
  - *Staff view.* Finance saw 1 Plus member, ₦1,395.35 of Plus revenue (net of VAT), 1 referred customer and the
    voucher issued. The ledger trial balance was equal on both sides.
  - *Not checked in a browser.* The browser pane was hidden, so the new screens were not checked visually: Plus,
    Rewards, group orders and the Growth page. Component and widget tests and the production builds cover them.

- **Phase 5 (Yummy on WhatsApp) on the running local stack.** The setup was the Auth emulator, the API with the
  WhatsApp sandbox and the agents service in offline mode (no Gemini key). Messages went through the WhatsApp
  simulator, which signs them the way Meta does, so they took the real path: signature check, de-duplication,
  task, linking, Yummy, reply.
  - *Linking.* An unknown number got sign-up instructions only. Ada created a code in the app, sent
    `LINK 725514` and was connected. The app then showed her number masked (`+234 801 ••• 1111`).
  - *Ordering.*
    - "What do you offer?" listed the three services.
    - Ada shared a location (Lekki Phase 1) and asked "I have ₦10,000, find me food for 2 people". Yummy
      offered an Island Small Chops platter for ₦9,881.25.
    - "plan 1" brought Yes/No buttons under "Place order VQT3CV from Island Small Chops? Delivering to Lekki
      Phase 1, Lagos. You'll pay ₦9,881.25 securely on the payment page."
    - Typing "yes" returned a "Pay now" link to the payment page.
    - The order was saved with channel `whatsapp`.
  - *Paying and tracking.* After the sandbox payment, "where is my order?" answered "Sent to restaurant" with
    the expected time.
  - *Other.* A Pidgin question about the referral code got a Pidgin answer. `STOP` disconnected the number,
    and the audit log recorded the link and the unlink with masked numbers.
  - *Bugs found and fixed during this check:*
    - A WhatsApp customer had no way to give a delivery address, so shared locations are now used.
    - Food requests that followed a growth question stayed with the growth agent.
    - The approval did not say where the order would go.
    - WhatsApp orders could not be told apart from app chats with Yummy.
    - The deploy script did not pass the channel-token secret or the agents' service identity, so staging
      would not have started. Its `^@^` delimiter also split the service-account emails.
  - *Not checked.* Meta's real Cloud API was not called (there is no account yet). The browser pane was
    hidden, so the Connect WhatsApp screens on the website and in the app were not checked visually.
    Component and widget tests and the production builds cover them.

- **Google Maps integration on the running local stack** (no Google key: everything on labelled estimates;
  Auth emulator + API + customer web build + partner dashboard + Command Centre):
  - *Customer app*: nearby map for Lekki Phase 1 (10 restaurants, closest first, estimated times; the
    customer's pin drawn on top). Signed in by phone on the emulator, then Profile → Saved addresses → Find on
    map: "Lekki" found the neighbourhood, the pin preview said "Yummy Chops delivers here", and the address was
    saved with the street typed in.
  - *Partner dashboard*: Kitchen location card with zone and radius. A 13.1 km move was refused with "needs Yummy
    Chops to verify"; a nearby move saved with an edited street line.
  - *Command Centre*: Live riders with a Lagos/Enugu switch, 6 online riders shown as area-only.
  - Fixed while testing: the address list reopening after a pick, the street line being replaced by a
    neighbourhood name, the customer's pin hidden under a restaurant pin, the picker under the tab bar, and idle
    riders using the customer's marker.
  - Not checked in the browser: the website pages (an earlier dev server process still held port 3000; covered
    by component tests and type checks) and any real Google response (no key, no paid usage).

## What has been tested — results

| Suite | Result |
|---|---|
| **Six services (2026-11-21, [ADR-0025](adr/0025-six-services.md))**: the owner asked for Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff and Package Delivery, with everything that goes with them and nothing built twice | Pharmacy, groceries and market shopping came back from commit 1f45da5 (merged onto today's code, not rewritten) under the owner's names: 10 invented demo shops, products by the aisle, the over-the-counter rule, the partner product form, Yummy's words and the journeys. Food is shown as **Order Food**, Supplements & Skin Care as **Beauty & Skin Care** (beauty products again; supplements are in the pharmacies' Vitamins aisle). Home on the app and the website: six bubbles, two rows of three, in the owner's order; one shop of each new kind among the picks. The website's foodstuff page is /foodstuff. "Add your business" (website and app) asks the kind of business; a pharmacy must give its PCN premises licence; the Command Centre shows the kind on each application. Checked: API **686 passed**; agents 57; website **68** (16 files); shared client 11; Flutter shared code 52, customer app **69**, rider app 14; analyzers, lint and type checks clean (website, partner, Command Centre); the running stack passed **243 of 243** journey checks (pharmacy, supermarket and market-shopper orders included). New customer app build for phones (64-bit). Open: the owner's decisions in NEXT_STEPS.md (Plus basket, commission, pharmacy legal review). |
| **The brand (2026-11-18, [ADR-0022](adr/0022-brand.md)); renamed Yummy Chops (2026-11-19, [ADR-0023](adr/0023-yummy-chops.md))**: the owner's logo, its colours, the name | `scripts/make-brand-assets.py` makes every logo file from `assets/brand/yummychops-logo.webp`: the whole logo is both apps' icons (Android and iOS; the customer app's on white, the rider app's on a white disc on chocolate brown), the sign-in screens of the apps and the websites, and the Android launch screen; cut-outs of the emblem and the name make the website headers and favicons. The tokens, the header gradient, the assistant Yummy and every hard-coded colour use the logo's red, chocolate brown, orange-gold and leaf green; website headings use Nunito. The platform was first called Gud Meal, then Yummy Chops (2026-11-18); on 2026-11-19 the owner renamed it Yummy Chops: the logo's lettering, every name people read, Yummy points, YC- receipt and voucher numbers, the yummy247.com addresses and the demo accounts (@yummychops.test); the same day the assistant Gudy was renamed Yummy and the GitHub repository became `yummy_chops`. |
| **Three services and a minimal home (2026-11-18, [ADR-0021](adr/0021-supplements-and-skin-care-minimal-home.md))**: the owner removed Groceries, Pharmacy and Market Shopping, renamed Beauty & Skin care, and asked for a Glovo-like minimal home | Removed from the app, website, partner dashboard, Yummy, API and demo data (the API now refuses those services). The service id stays `beauty`; every name a person reads says Supplements & Skin Care, and the demo shops now sell vitamins and supplements instead of make-up, fragrance and hair care. Yummy's supplements rule: no diagnosis, doses or health claims. The home page, in the app and on the website, shows only the address, three big bubbles and the picks. Tests: API 659, agents 57, website 55, shared app code 52, customer app 61, rider app 14. |
| **Test apps find the test server by themselves (2026-11-17, [ADR-0020](adr/0020-test-apps-find-the-test-server.md))**: the computer's Wi-Fi address changed three times in one day, and each change needed both apps rebuilt and installed again | A phone test build now looks for the computer when it starts: the address that worked last time, the address it was built for, the addresses of earlier builds, then every address on the phone's own Wi-Fi. It says so when it cannot find the computer and takes a typed address; when the app comes back to the front and the server no longer answers, it offers to look again. The payment sandbox page follows the computer's current address, so the stack needs no restart. Store builds never search. Tests: `mobile/core/test/test_server_test.dart`, `test_server_connection_test.dart`, `services/api/tests/unit/test_phone_test_address.py`. **Not run on a phone yet.** |
| **The app has everything the website has (2026-11-17, owner: the app is the priority)** | Compared screen by screen and added to the customer app: the home page's closing sections (three "why Yummy Chops" cards, the "Sell on Yummy Chops. Ride with Yummy Chops." banner, See all); "Continue with Google" on the sign-in screen; "Use my current location" in the delivery-area picker and as one tap at checkout; in the profile: food preferences, download my data, track a package, add your business, ride with Yummy Chops, FAQ with privacy and terms; new screens `/help`, `/track`, `/partner-with-us`, `/ride` (`mobile/customer/lib/features/info/info_screens.dart`); Discover's in-demand list now covers every kind of shop. Tests: `mobile/customer/test/parity_test.dart` (12). Found on the way: profile rows could run off the screen with large text and showed no tap ripple; the Support answer about payment still said the wallet was coming soon (app and website). Google sign-in on a phone was checked only against the sign-in emulator (it accepts the stand-in credential the test build sends); the real Google account chooser needs the Firebase project |
| **Audit of the order flow (2026-11-17)**: customer chooses items, address and payment → shop receives, accepts, prepares → rider accepts, collects, delivers → order completed and rider earnings recorded | Every delivery in `services/api/scripts/e2e_local.py` now asserts all four steps, including that the order reaches `completed` and that the rider's ledger balance rises by exactly the offered pay. Full run against the live local stack: **243 passed, 0 failed** over 22 journeys (browsing, account, food by card, food in one payment, pickup, wallet, pay on delivery, beauty, groceries, pharmacy, market, package, interstate waybill, group order, Plus and rewards, support, partner tools, sign-ups, payouts, Command Centre, access control, Yummy). The owner's own situation was replayed too (one customer, only `rider@` online, nobody at the shop): food, beauty, package, groceries, pharmacy and market all paid, were accepted by the demo shop autopilot, reached that rider, were delivered and completed, with earnings and receipt recorded. Bug found and fixed on the way: signing in from the Orders tab of the customer app left the Sign in screen open instead of returning to Orders (`sign_in_screen.dart`, test `sign_in_return_test.dart`) |
| **Receipt printer (2026-11-17, [ADR-0019](adr/0019-receipt-printer.md))** | After a card or wallet payment the customer sees a thermal printer marked "Yummy Chops"; the red PRINT button prints the receipt of that order (items, fees, VAT, total, how it was paid) and keeps it under "My receipts". API: `GET`/`POST /v1/orders/{id}/receipt`, `GET /v1/receipts` (5 tests). Website: `components/ui/receipt-printer.tsx` (needs the `motion` package), `/orders/{id}/receipt`, `/receipts` (9 tests). App: `features/receipts` (6 tests; the phone vibrates instead of playing the printer sound). Checked in a browser on the website: payment return page → printer → PRINT → receipt printed, saved, listed, torn off |
| **Groceries, Pharmacy and Market Shopping (2026-11-17, [ADR-0018](adr/0018-groceries-pharmacy-market.md); removed 2026-11-18)** | Three more services through the same order pipeline: 10 invented demo shops (supermarkets, pharmacies, market shoppers) in Lagos and Enugu, products by the aisle with brand, size or market measure, stock, choices and "From" prices; pharmacies are over-the-counter only (prescription-only products are hidden and refused). Customer app and website: six home services, a page per service, aisle-style shop pages. Partner dashboard: product form. Yummy: finds products and opens the new services. API tests `test_retail_services.py` (13), live journeys `grocery_order`, `pharmacy_order`, `market_order` |
| **App icon (2026-11-17)** | Superseded on 2026-11-18 by the owner's logo ([ADR-0022](adr/0022-brand.md)), lettered Yummy Chops since 2026-11-19 ([ADR-0023](adr/0023-yummy-chops.md)). |
| **Second phone test by the owner (2026-11-17)**: a paid package (Ajah to VGC, cash on delivery) still never reached the rider app; all food shops were closed at night | Causes: dispatch only ever looked 6 km around the pickup and the only rider was 11.5 km away; shops keep Lagos opening hours. Fixed: the search widens by 3 km each round with nobody to ask (up to 30 km; first radius `DISPATCH_PICKUP_RADIUS_KM`); a missed offer comes back as soon as the rider may be asked again (`DISPATCH_REOFFER_SECONDS`, 5 minutes by default); extra looks triggered by riders coming online no longer pile up retries. Local testing mode (`scripts/dev.mjs`, see LOCAL_DEVELOPMENT.md section 6): demo shops open around the clock, a 40 km radius, re-offers after 20 seconds, a N1,000,000 rider cash limit, and with `--lan` a **demo shop autopilot** that accepts and packs food and beauty orders because nobody is at the shop's dashboard during a phone test (the two `DEMO_` switches are refused in staging and production). Replayed live with only `rider@yummychops.test` online and nobody playing the shop: the owner's exact package (N2,418.75, offered at 11.54 km, N2,500 cash collected and handed in), a food order and a beauty order (shop accepted by itself, offer after 16 s), and a missed offer (back 20 s after it ran out). Also found: the rider app counted an offer down with the phone's clock against the server's deadline, and this PC's clock was 16 s slow, so a 45 s offer showed 28 s on the phone (a phone whose clock runs a minute fast would show every offer as expired). `GET /v1/rider/offers` now sends `expires_in_seconds` and the app counts down from it. End-to-end check **157 / 157** with the autopilot on. Tests: API **645** (8 new: widening search, re-offer timing, no piled-up retries, seconds left on offers, always-open shops, autopilot, switches refused outside local), Flutter core **20** |
| **Phone test by the owner (2026-11-17)**: customer side worked; the rider app never received a job | Causes: the rider app only sent its position after moving 25 m, so a rider waiting in one place looked silent after 3 minutes and was never offered anything; a rider whose offer ran out was excluded from that job for good, and dispatch stopped after 8 rounds; locally, 5 demo riders nobody holds took the offers first. Fixed: the app sends its position on going online and every minute; dispatch asks a rider again 5 minutes after a missed offer (never one who declined), keeps trying every 2 minutes after alerting ops, and offers waiting jobs as soon as a rider comes online, shows up again or finishes a delivery; local mode keeps only `rider@yummychops.test` online. Also fixed: rider earnings never loaded (`earned_last_7_days_kobo`), the rider's item list was empty (the API sends `items`), the delivery screen did not refresh while waiting at the shop, and an unpaid order had no way to pay again (new **Finish paying** card). The rider home screen is now a dashboard (online status, location shared, earnings, deliveries, rating, offers with a buzz). Checked by driving the rider app (browser build) through a food, a beauty and a package delivery, and the customer app's order and Finish paying screens. New end-to-end journey (owner's request): food paid in **one checkout** covering food, delivery fee, service fee and VAT (₦16,000 + ₦800 + ₦800 + ₦120 = ₦17,720, exactly one payment), then a rider is found and delivers; the payment splits into kitchen ₦13,600 (food minus 15% commission), rider ₦609.90 and Yummy Chops ₦3,510.10, and the ledger balances. End-to-end check **157 / 157**. Tests: API **637** (5 new dispatch tests), Flutter core **19** / customer **42** / rider **14** |
| **End-to-end audit of the running stack (2026-11-17)**: `services/api/scripts/e2e_local.py`, every journey over HTTP with Auth-emulator accounts (browsing, account, food by card with kitchen, rider and delivery code, pickup with handover code, wallet top-up/pay/cancel-refund, pay on delivery with rider cash remittance, beauty, bike package, Lagos→Enugu waybill through both hubs, group order with split bill, Plus, rewards, support and disputes, partner tools, rider and shop sign-up approvals, payouts and settlements, 23 Command Centre views, access control, Yummy), then the same through the Wi-Fi address; plus a browser walk-through (website order → kitchen dashboard → rider → "Completed" live on the website, Command Centre, customer app) | **137 / 137 steps passed** (44 / 44 over Wi-Fi). Fixed on the way: newly approved shops were listed to customers with an empty menu (now *pending* until they open with at least one item); partner dashboard and Command Centre had no sign-out under 1024 px; the website payment return page forced a sign-in for app payments; the login page's `next` allowed `//other-site` redirects; `npm test` failed for the two dashboards without tests; Android test builds could not reach a laptop (sign-in host fixed at 10.0.2.2, cleartext blocked) and showed `gud_meal_customer` as the app name. Suites after the fixes: API **632 passed**, agents **56**, web **47**, api-client **11**, Flutter **17 / 41 / 10**, lint, analyzers and type checks clean. Android test APKs built locally with `scripts/build-test-apk.mjs` (customer 59 MB for all phones, rider 19 MB for 64-bit phones) and served on the Wi-Fi; not yet installed on a phone |
| API unit + HTTP integration (SQLite) | **610 passed**, 3 skipped (PostgreSQL-only); 21 new for phase 5: webhook signatures and parsing, masked numbers, shared locations, approval buttons and payment links, channel tokens (expiry, tampering, customer role only), linking by code (single use, expiry, rate limit, one number per account), unknown numbers, Yummy conversations with approvals, rate limits, `STOP`, the simulator, and the agents service skipping App Check without opening internal endpoints; 53 for phase 4: Plus pricing (free delivery threshold, service fee discount, savings equal the price difference, vouchers, totals always add up), VAT-inclusive split, fair allocation and bill shares (20 random cases), points and codes, Plus postings; joining by wallet and card, member prices, early renewal, wallet auto-renewal with one reminder, cancelling, lapses; points on completion, double for Plus, redeeming, refunds taking points back, referrals and the monthly cap; group orders end to end, expiry refunds, the host paying the rest and late payments refunded, refunds split between payers, host-pays mode and the rules; 31 for phase 3: line-haul pricing and weight limits, departures around the cut-off and Sundays, expected dates, stage labels, waybill postings always balance (15 random cases), state rules and flow guard, catalogue, quote validation, door to door with two rider jobs, hubs, COD and ledger, drop-off and hub collection paid from the wallet, cancellations, hub permissions and network configuration, no pay on delivery or rider-job checkout; 47 for phase 2: postings always balance, COD fee, state rules and money guard, wallet top-up/pay/instant refund, card refunds to the wallet, duplicate payment refund, pay on delivery end to end with rider cash and hand-ins (bank and earnings offset), cancellations without refunds, eligibility rules, dispatch cash limit, vendor COD with payouts and move to wallet, gateway failover and circuit breaker |
| API integration on PostgreSQL 16 incl. append-only and unbalanced-transaction triggers, and a race test proving two simultaneous wallet payments cannot overspend (it fails when the account lock is removed) | **116 passed** in CI with the WhatsApp tests (108 on embedded PostgreSQL locally at phase 4) |
| Alembic upgrade / `alembic check` / downgrade / upgrade (with migrations 0002 and 0003) on PostgreSQL 16 | passed |
| Agents (routing, permissions, approvals, isolation, injection, redaction, failure recovery, cost, Gemini schema, Yummy offline mode in 5 languages, parcel booking via tools, wallet and cash questions, waybill routes and tracking, Plus, points and group orders, WhatsApp channel tokens and service credentials, WhatsApp orders tagged and approvals that name the address, food requests routed back to the customer agent) | **49 passed**, 1 skipped (live Gemini needs a key) |
| TypeScript (api-client 7, web 23) + 3 Next.js production builds with type-check | **30 passed**, builds OK |
| Flutter core / customer / rider | **12 / 35 / 8 passed** (Connect WhatsApp, Plus join, rewards and redeeming, group bill and paying a share, starting a group, bubble drag-and-spring-back, Food page, Yummy button, Orders spending, parcel form, cash on delivery for packages, payment choice, wallet, Discover, interstate waybill booking, rider package job, rider cash confirmation, rider hub hand-over), analyzer clean |
| Google Maps ([ADR-0014](adr/0014-google-maps-platform.md)), on the code merged with phases 3–5 | API **631 passed**, 3 skipped (21 maps: request shapes, keyless fallback, caching, daily cap, measured pricing, outage fallback, rider privacy, live ETA throttle, kitchen pins, live map); agents **56 passed** (7 location); Flutter core / customer / rider **17 / 41 / 10** (5 / 6 / 2 maps); web **27** and api-client **10** (4 + 3 maps); ruff, analyzers and all type checks clean; Next.js production builds of the three sites passed locally before phase 5 was merged |
| Discover dish carousel on the website (the app's carousel and plates, ported to the web) | web **45 passed** (18 new: title split, timeline and band, plates for every dish family, arrows, pager, keys and swipes, auto-play pausing on hover, the pause button and reduced motion, switching lists, the feed's retry, Order food opening the dish on the menu); api-client **11 passed**; type check clean; Next.js production build of the website passed; checked in the browser at phone and desktop sizes, light and dark |
| Firestore & Storage rules tests (Firebase emulators) | **passed in CI** ([run](https://github.com/Hubert24hrs/yummy_chops/actions/runs/43931811599)); not runnable locally without Java |
| Firestore DocumentStore contract tests against the emulator | **8 passed in CI** (memory + Firestore backends) |
| Docker images build + API container smoke test | **passed in CI**; not runnable locally without Docker |
| Full CI (6 jobs) on GitHub Actions | **all green** on the phase 5 push ([run](https://github.com/Hubert24hrs/yummy_chops/actions/runs/43931811599)) |

## What has been deployed

Since 2026-11-20 ([DEPLOYMENT.md](DEPLOYMENT.md) sections 5a and 5b):

- **The three websites on Vercel**, on the owner's free Hobby plan, built from GitHub `main`:
  https://yummy247.com (www redirects to it), https://partner.yummy247.com and https://admin.yummy247.com, over
  HTTPS. They point at `api.yummy247.com` and `assistant.yummy247.com`, which do not exist yet, so they load
  but cannot list shops, sign anyone in or take orders.
- **The domain** `yummy247.com` (Namecheap, BasicDNS): records for Vercel and Zoho, and the parking records removed.
- **Email**: `customercare@yummy247.com` on Zoho Mail's Forever Free plan. Zoho verified the domain, MX, SPF
  and DKIM; DMARC is report-only (`p=none`).

No GCP or Firebase project was created or modified, and no paid service was enabled.

## What has not been deployed

The API, Yummy, Firebase rules and indexes; Cloud SQL, Pub/Sub, Tasks, Scheduler, Secret Manager, Artifact
Registry; mobile store builds.

## Firebase configuration status

Rules, indexes and emulator config are in `firebase/`. The `.firebaserc` aliases point to
`yummy-chops-dev|staging|prod`, which do not exist yet. Apps run against the Auth emulator with demo config.

## GCP configuration status

Not configured. `infra/scripts/bootstrap-gcp.sh` creates everything per environment (Cloud SQL only with an
explicit flag and confirmation). Region default: `europe-west1`.

## LangGraph agent status

Implemented and tested with a scripted model and the real API. Without `GOOGLE_API_KEY` the service runs in a
safe degraded mode (keyword routing + “try the app” reply). The Gemini model id is not pinned because the official
models page could not be fetched; pin a stable Flash id per ADR-0011.

## Payment integration status

Paystack and Flutterwave adapters are implemented to their documented contracts and tested with mocked HTTP;
the full pipeline is exercised with the local sandbox provider. **No real provider call has been made** (no keys).
The Yummy Chops wallet, pay on delivery and vendor cash on delivery run inside Yummy Chops' ledger; gateway failover
is tested with a simulated outage. Seller payouts, rider hand-ins and carrier payouts are recorded manually by finance.

## Security status

Implemented: token verification, RBAC, data isolation, deny-by-default rules, webhook signatures, idempotency,
append-only ledger/audit, rate limits, AI guardrails, WhatsApp webhook signatures, customer-only channel
tokens, service-account identity between the agents service and the API, App Check tokens from the websites
(reCAPTCHA Enterprise, once a site key is set). Outstanding: App Check in the mobile apps (blocks production),
App Check enforcement, penetration test,
dependency scanning, distributed rate limiting, NDPA documentation.

## Outstanding issues

1. Emulator-based tests run only in CI (this machine has no Java); they pass there.
2. Real payments (Paystack test mode) and real Gemini calls are unverified.
3. Restaurant artwork uses branded placeholders until restaurants upload photos; no live map yet.
4. Order tracking polls the API every 5 s (Firestore listeners are the production upgrade).
5. Rate limiting is per Cloud Run instance; refunds via Flutterwave need the transaction id.
6. The rider Flutter app is covered by widget/unit tests and the analyzer only; it has not been run on a device
   or emulator (it has no web build, and its GPS flows need a phone).
7. Yummy without a Gemini key runs in offline mode: a fixed set of intents, full replies in English and Pidgin
   only (Igbo, Yoruba and Hausa get a greeting, then English). Natural conversation in all five languages needs
   the key.
8. Until the Google Maps server key is added, address search only finds neighbourhoods (their centres, about 1 km
   accuracy) and every distance, fee and time is a labelled straight-line estimate. "Use my current location"
   already keeps the device's exact position. The package-delivery form still uses neighbourhood pickers (the
   address picker is in checkout and saved addresses).
9. Yummy on WhatsApp is built but **switched off**: it needs the Meta WhatsApp Business account, number and
   keys, and the owner's approval of Meta's messaging charges. Limits for now:
   - Yummy Chops only replies to messages. Proactive updates (order status, Plus reminders) need
     Meta-approved templates.
   - Voice notes, photos and WhatsApp Flows are not supported.
   - A shared location is matched to the nearer of Lagos and Enugu; the API still checks the delivery
     zone.
10. Support WhatsApp and phone numbers do not exist yet. The websites and apps show them as "coming soon", and
    Yummy and the WhatsApp messages leave them out. The email `customercare@yummy247.com` is real, and it is shown
    and offered everywhere since 2026-11-21. Set `SUPPORT_WHATSAPP` and `SUPPORT_PHONE` when the numbers exist.
    Test APKs built before 2026-11-21 still show all three as "coming soon" until they are rebuilt.
11. Store artwork is generated (gradient + illustration) until partners upload photos; field names still say
    `restaurant_*` for all merchants (rename deferred, see ADR-0012).
12. The wallet is closed-loop stored value with product-default limits (top-up ₦500–₦100,000, balance ≤ ₦300,000);
    it needs a **legal/CBN review** before launch (ADR-0013).
13. Refused or failed cash deliveries: support can cancel the order and switch pay on delivery off for the
    customer, but compensating the merchant/rider is a manual finance step, and return trips for refused COD
    packages are not automated.
14. Seller payouts and rider cash hand-ins are recorded by finance by hand (no automated bank transfers yet).
15. Local dev uses a new SQLite file (`gudmeal_local_v3.db`; phase 4 changed a payment constraint) because
    local dev creates tables directly; older `gudmeal_local*.db` files were left untouched.
16. The interstate waybill runs on a **sample network**: Yummy Chops hubs in Lagos (Ikeja, Lekki) and Enugu,
    partner terminals in Abuja and Port Harcourt, three sample carriers and sample prices. Real carriers, hub
    addresses, hours and rates are needed ([ADR-0015](adr/0015-interstate-waybill.md)).
17. Carrier payouts are recorded by finance by hand. There is no carrier portal or manifest exchange; a trip is
    a free-text reference.
18. Waybill exceptions are manual support processes: failed door deliveries, unclaimed packages, returns,
    refused cash-on-delivery packages, and lost or damaged packages. The declared value is recorded but not
    insured.
19. Hub agents can scan at any hub; there is no per-hub staff assignment yet.
20. Growth settings are **product defaults** for the owner to confirm: the Plus price and benefits, points
    rates, referral amounts and caps, and group limits. Accounting simplifications:
    - Plus fees are recognised when paid, not spread over the 30 days.
    - Outstanding points are reported, not booked.
21. Plus auto-renews from the wallet only. Card members renew by hand after a reminder; stored card
    authorisations are not used.
22. Referral abuse controls are basic: once per account, before the first paid order, a monthly cap and a
    minimum order.
23. A split-bill refund that needs finance approval appears as one request per payer, and finance should
    decide them together. Group orders use the host's address, voucher and Plus benefits. Members follow
    the order inside the group, not in their own order list.
24. **App Check blocks production for the mobile apps.** The production API enforces App Check, and the
    customer and rider apps do not send App Check tokens yet (they need `firebase_app_check` with Play
    Integrity and App Attest). The websites send tokens, but only once a reCAPTCHA Enterprise site key is set,
    and that has not been tried with a real key yet.
25. The website images are built and smoke-tested in CI only: this machine has no Docker. The standalone
    server was checked locally for the Command Centre (page, static files, security headers).

## Required user actions

1. Create `yummy-chops-dev|staging|prod` GCP projects, add Firebase, enable billing and budgets. In each
   Firebase project, register one Web app for the three websites, create a reCAPTCHA Enterprise key for App
   Check, and add the website domains to Authentication's authorized domains. Then fill in the GitHub
   Environment variables (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `APP_CHECK_SITE_KEY`; see
   [DEPLOYMENT.md](DEPLOYMENT.md) sections 3 and 5).
2. Provide Paystack **test** keys (and Flutterwave if wanted) for sandbox verification.
3. Provide a Gemini API key (turns Yummy's offline mode into the full multilingual assistant); choose and pin a
   stable Flash model.
4. Install Java 21 locally if you want to run emulator rules tests (`winget install EclipseAdoptium.Temurin.21.JDK`).
5. Legal: NDPA review, privacy policy/terms, fund-holding (collect-then-settle) review with Paystack and counsel.
6. Apple/Google developer accounts and signing keys for store releases.
7. Google Maps Platform: enable Places API (New), Geocoding and Routes, create a **server key** in Secret
   Manager, set quotas and a budget, and approve billing (see [GOOGLE_MAPS.md](GOOGLE_MAPS.md); within the free
   monthly allowances at launch volumes). Optional restricted app and browser keys for map tiles. Legal review
   of Google's caching terms.
8. Yummy on WhatsApp ([DEPLOYMENT.md](DEPLOYMENT.md) section 4a). **Deferred by the owner on 2026-11-16, to do
   later, after the first deployment** (the webhook needs a deployed API):
   - Meta Business verification and a WhatsApp Business number with an approved display name
   - a permanent system-user token, the app secret and a verify token
   - approval of Meta's messaging charges, and Meta-approved templates for order updates
   - a privacy notice that covers WhatsApp
9. Real support contacts (WhatsApp and phone; the email `customercare@yummy247.com` exists since 2026-11-20) and
   real partner restaurants and beauty shops for both cities.
10. Legal/CBN review of the Yummy Chops wallet (closed-loop stored value, limits, KYC, who holds the funds) and
    confirmation of the money limits: wallet top-up/balance, pay on delivery ₦25,000, rider cash ₦50,000, COD
    ₦100,000 and the 1.5% (min ₦100) collection fee.
11. Real line-haul partners and hubs for the interstate waybill: carrier contracts, hub and terminal
    addresses and hours, lane prices and departure times, and the carrier share. Also a legal review of the
    waybill terms: prohibited items, liability limits and ID checks at collection.
12. Confirm the growth defaults:
    - Yummy Chops Plus: ₦1,500 per 30 days, free delivery from ₦3,000, 50% off service fees, 2x points
    - Yummy points: 1 point per ₦100; 500 points = ₦500
    - Referrals: ₦1,000 for each side, 10 rewards a month
    - Group orders: 10 people, 3 hours to order, 30 minutes to pay

    Also get a legal review of the subscription terms (auto-renewal consent, cancellation, no partial
    refunds) and of the points and referral terms.

## Estimated monthly infrastructure cost

About **$430–820/month for production** at launch scale (300 orders/day, 2,000 AI turns/day), $65–130 staging,
$0–80 dev, including the three websites — excluding payment fees and SMS. Details and assumptions: [COST_ESTIMATE.md](COST_ESTIMATE.md).

## Recommended next steps

1. Bootstrap `yummy-chops-dev`, deploy via the manual workflow, and run the Paystack test-mode flow end-to-end.
2. Add a Gemini key, pin the model, run `pytest -m live_gemini` and build an evaluation set for Yummy in all five
   languages (Pidgin, Igbo, Yoruba and Hausa reviewed by native speakers).
3. Switch on Yummy on WhatsApp once the Meta account is ready ([DEPLOYMENT.md](DEPLOYMENT.md) section 4a; deferred
   by the owner on 2026-11-16), then add Meta-approved templates for order updates. Also replace the sample waybill
   network with real carriers and hubs, and confirm the growth defaults.
4. Switch customer tracking to Firestore listeners and add Google Maps (address search, pins, live map).
5. Partner photo uploads (Storage rules already allow it), partner staff management, shop wording for beauty
   partners in the dashboard.
6. Monitoring dashboards/alerts, load test, security review, then closed betas in Lekki/VI and Independence
   Layout (Enugu).
