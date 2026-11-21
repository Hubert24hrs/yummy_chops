# Yummy Chops — Implementation Roadmap

Staged delivery, as agreed: **core marketplace → delivery infrastructure → AI → administration → launch.**
Live status of each item is tracked in [PROGRESS.md](PROGRESS.md).

## Stage 0 — Discovery & architecture
- Environment inspection, architecture, ADRs, data model, security model.

## Stage 1 — Core marketplace
- API foundation: config, auth (Firebase ID tokens), RBAC, errors, logging, rate limits.
- Domain: money (kobo), opening hours, geo, pricing engine, vouchers, order state machine.
- Catalog: restaurants, menus, items, customisations, search, discovery filters.
- Quotes → orders → checkout with idempotency.
- Payments: Paystack + Flutterwave adapters, webhooks, verification, ledger postings.
- Customer website: discovery, restaurant pages, cart, checkout, tracking.
- Partner dashboard: incoming orders, accept/reject, menu & availability management.
- Customer mobile app: discovery, cart, checkout, tracking.

## Stage 2 — Delivery infrastructure
- Rider onboarding & verification, availability, location updates (geohash).
- Dispatch scoring, offers with Cloud Tasks timeouts, manual dispatch.
- Pickup / delivery with OTP, live tracking, notifications (FCM).
- Rider app: offers, active delivery, earnings, payouts.

## Stage 3 — AI multi-agent ecosystem
- LangGraph orchestrator, router, eight specialist agents, tool registry, approvals.
- Budget meal planner ("₦10,000 for two before 8pm"), Postgres checkpoints, memory isolation.
- Gemini integration, cost/latency tracking, LangSmith tracing, AI chat in web + mobile, voice input.

## Stage 4 — Administration
- Command Centre: overview, orders intervention, verification queues, refunds, payments,
  commission/fee configuration, feature flags, audit logs, AI monitoring, disputes, settlements.

## Stage 5 — Production launch
- GCP projects per environment, Cloud SQL, Secret Manager, Cloud Run, Pub/Sub, Tasks, Scheduler.
- Security review (OWASP ASVS L2), rules tests, load tests, payment sandbox → live verification.
- NDPA compliance review, privacy/cookie policies, Play Store / App Store submissions.

---

# Multi-service expansion (owner decisions of 2026-11-15)

The owner asked for a Glovo-style customer experience in **Yummy Chops' own colours** (orange at first; the colours of the Yummy Chops logo since 2026-11-18, ADR-0022) (own logo and original
illustrations, no competitor branding) on **both the mobile app and the website, mobile app first**, with three
services, two launch cities and a set of stand-out features. Answers to the product questionnaire:

| Topic | Decision |
|---|---|
| Design | Animated, finger-draggable service bubbles; Food page with category bubbles, filters, popular brands; bottom bar Home · Discover · Orders · Support · Profile; Yummy robot button everywhere |
| Services | Six, in this order since 2026-11-21 ([ADR-0025](adr/0025-six-services.md)): **Order Food**; **Pharmacy** (over-the-counter only); **Beauty & Skin Care** (partner shops' products; named Supplements & Skin Care on 18-21 Nov); **Shop & Groceries** (supermarkets and stores); **Buy Foodstuff** (a shopper buys it at the market); **Package Delivery** (instant bike, scheduled pickups, cash-on-delivery for vendors, interstate waybill) |
| Cities | **Lagos and Enugu** first |
| Payments | Paystack (card/transfer/USSD), **Yummy Chops wallet**, **pay on delivery**, Flutterwave backup |
| AI assistant | **Yummy**; English, Nigerian Pidgin, Igbo, Yoruba, Hausa |
| Support | AI first then a human in-app, WhatsApp, phone, email (contacts are placeholders until provided) |
| Stand-out features | WhatsApp ordering with Yummy, group orders & split bill, Yummy Chops Plus membership, referral & loyalty rewards |
| Data | Original sample partners for Lagos and Enugu until real partners onboard |

Added on 2026-11-17 at the owner's request, outside the numbered phases:

- **Groceries, Pharmacy and Market Shopping** ([ADR-0018](adr/0018-groceries-pharmacy-market.md)): built on 17 Nov,
  removed on 18 Nov ([ADR-0021](adr/0021-supplements-and-skin-care-minimal-home.md)) and back on 21 Nov as
  Shop & Groceries, Pharmacy and Buy Foodstuff ([ADR-0025](adr/0025-six-services.md)). To confirm: the Plus minimum
  basket for these services, their commission, and a legal review of selling over-the-counter medicines online.
- **Receipts and the receipt printer** ([ADR-0019](adr/0019-receipt-printer.md)): done and tested.

Delivery phases (each tested, documented and pushed before the next):

1. **Redesign + services** — API: verticals, cities, beauty shops, parcels (instant + scheduled), browse
   categories, promotions, order totals, neighbourhood gazetteer, support contacts. Yummy: multi-service tools,
   five languages, offline mode. Mobile app and website redesign. *(done 2026-11-15)*
2. **Money** — Yummy Chops wallet (top-up, instant refunds, one-tap pay), pay on delivery with rider cash
   reconciliation, cash-on-delivery collection for vendors with seller payouts, Flutterwave failover.
   *(done 2026-11-15; legal review of the wallet pending, see ADR-0013)*
3. **Logistics** — interstate waybill (Lagos ↔ Enugu ↔ other states) via partner logistics and hubs.
   *(done 2026-11-15 with a sample network of hubs and carriers; real partners pending, see ADR-0015)*
4. **Growth** — Yummy Chops Plus membership, referral and loyalty rewards, group orders with split bill.
   *(done 2026-11-15 with product-default prices and rewards to be confirmed; see ADR-0016)*
5. **WhatsApp** — Yummy on WhatsApp Business (ordering and support).
   *(built 2026-11-16 and tested with a local WhatsApp sandbox; switching it on needs the Meta account and
   the owner's approval of the messaging charges, see ADR-0017)*
