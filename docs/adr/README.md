# Architecture Decision Records

| # | Decision | Status |
|---|---|---|
| [0001](0001-monorepo-separate-deployables.md) | Monorepo with separately deployable apps | Accepted |
| [0002](0002-firestore-plus-postgres.md) | Firestore for real-time data, PostgreSQL for money | Accepted |
| [0003](0003-langgraph-separate-service.md) | LangGraph as an independent Cloud Run service | Accepted |
| [0004](0004-order-state-machine-in-backend.md) | Order state machine only in the API | Accepted |
| [0005](0005-integer-kobo-and-server-quotes.md) | Integer kobo and server-stored quotes | Accepted |
| [0006](0006-payment-provider-adapter.md) | Payment provider adapter; platform collects then settles | Accepted |
| [0007](0007-append-only-double-entry-ledger.md) | Append-only double-entry ledger | Accepted |
| [0008](0008-agent-tool-registry.md) | Typed, permissioned agent tool registry with approval | Accepted |
| [0009](0009-repository-ports-and-adapters.md) | Repository ports with Firestore and in-memory adapters | Accepted |
| [0010](0010-events-outbox-pubsub-tasks.md) | Transactional outbox → Pub/Sub; Cloud Tasks for timers | Accepted |
| [0011](0011-gemini-model-configuration.md) | Gemini model chosen by environment, pinned in production | Accepted |
| [0012](0012-multi-service-platform.md) | One order pipeline for Food, Beauty & Skin care and Package Delivery | Accepted |
| [0013](0013-wallet-and-cash.md) | Yummy Chops wallet, pay on delivery, vendor cash-on-delivery, gateway failover | Accepted (legal review pending) |
| [0014](0014-google-maps-platform.md) | Google Maps Platform behind the API: places, routes, private live tracking | Accepted (key and billing approval pending) |
| [0015](0015-interstate-waybill.md) | Interstate waybill: hubs, rider legs, partner line haul, public tracking | Accepted (sample network) |
| [0016](0016-plus-rewards-group-orders.md) | Yummy Chops Plus, Yummy points and referrals, group orders with split bill | Accepted (defaults to confirm) |
| [0017](0017-assistant-on-whatsapp.md) | Yummy on WhatsApp: number linking, customer-only channel tokens, signed webhooks | Accepted (Meta account pending) |
| [0018](0018-groceries-pharmacy-market.md) | Groceries, Pharmacy and Market Shopping: three more shop services, products by the aisle, over-the-counter only | Accepted again 2026-11-21 under new names (see 0025) |
| [0019](0019-receipt-printer.md) | Receipts: the receipt printer after payment, receipts kept under the customer's profile | Accepted |
| [0020](0020-test-apps-find-the-test-server.md) | Phone test apps find the test server on the Wi-Fi by themselves; the payment sandbox page follows the computer's address | Accepted (not yet run on a phone) |
| [0021](0021-supplements-and-skin-care-minimal-home.md) | Three services: Food, Supplements & Skin Care (was Beauty & Skin care), Package Delivery; a minimal home page in the app and on the website | Accepted; services superseded by 0025 |
| [0022](0022-brand.md) | The brand: logo, icons and colours from the owner's logo (named GudMeals at first) | Accepted; name superseded by 0023 |
| [0023](0023-yummy-chops.md) | The name Yummy Chops (logo lettering, every name people read, YC numbers, Yummy points), the assistant renamed Yummy (was Gudy), and the yummy247.com domain | Accepted |
| [0024](0024-public-test-link.md) | A temporary public test link (ngrok, a gateway that lets only the tester in) so someone elsewhere can try the app | Accepted |
| [0025](0025-six-services.md) | Six services in the owner's order: Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy Foodstuff, Package Delivery; every kind of shop can sign up | Accepted (owner decisions open) |
| [0026](0026-online-test-server.md) | An online test server anyone with the tester app can use: Cloud Run, real sign-in (email and Google), Paystack test mode, the demo shops | Accepted (waiting for Google to allow billing) |
| [0027](0027-rider-kyc.md) | Rider sign-up and KYC (documents, NIN, two guarantors, a selfie) checked by hand by the team, with a Verified badge | Accepted |
| [0028](0028-business-branches-and-split-payments.md) | Businesses with a unique ID (YCB-…), branches that sell one menu (customers order from the nearest), and card payments split by Paystack so the business's share goes straight to its bank account | Accepted (subaccounts wait for Paystack activation) |
| [0029](0029-new-logo-and-app-icon.md) | The owner's new logo (the chef under her arch, Yummy247) and app icon (a white chef's hat with a green "yc" on red; the rider app's on chocolate brown) across the apps and websites | Accepted |
| [0030](0030-mixed-cart-one-payment.md) | One cart for items from every shop and service, one order per shop (each with its own delivery fee and rider), all paid with one payment (`POST /v1/checkouts`); items removable in the cart; "Phone number" label | Accepted |
| [0031](0031-rider-trips.md) | A mixed cart is one rider trip: one offer for every shop, stops in the quickest order then the customer (`GET /v1/rider/trip`, Google Maps link), each shop's phone, one delivery code | Accepted |
