# Yummy Chops — Discover. Order. Eat.

AI-native delivery for Nigeria (Lagos and Enugu) with six services: **Order Food**, **Pharmacy**, **Beauty & Skin Care**,
**Shop & Groceries**, **Buy Foodstuff** (a shopper buys it fresh at the market) and **Package Delivery** by bike and by **interstate waybill** (Lagos, Enugu, Abuja, Port Harcourt), with **Yummy**, an AI
assistant that speaks English, Nigerian Pidgin, Igbo, Yoruba and Hausa, in the app and on WhatsApp. A customer app and website (Glovo-style, in
the colours of the Yummy Chops logo, with animated draggable service bubbles), a partner dashboard, a rider app, a super-admin Command
Centre, a FastAPI core API and a LangGraph multi-agent service — one ecosystem sharing identity (Firebase Auth),
data (Firestore + PostgreSQL) and business rules.

> “Yummy Chops, I have ₦10,000. Find me the best meal for two people, order it, and have it delivered before 8pm.”
> — the assistant plans options with exact totals, drafts the order, asks you to approve, and hands you a
> secure payment link. This flow is covered end-to-end by `services/agents/tests/test_agent_flows.py`.

## Repository map

| Path | What | Stack |
|---|---|---|
| `services/api` | Core API: merchants (food, beauty), parcels, interstate waybills and hubs, Yummy Chops Plus, points and referrals, group orders with split bill, pricing, quotes, orders, payments (gateways with failover, wallet, pay on delivery, vendor COD), ledger, dispatch, admin | Python 3.13, FastAPI, SQLAlchemy, Firestore |
| `services/agents` | Yummy: LangGraph orchestrator + 8 specialist agents, 43 approval-gated tools, offline mode, WhatsApp channel | LangGraph, Gemini |
| `apps/web` | Customer website (service bubbles, Food, Beauty, Send a package, interstate waybill and tracking, Plus, Rewards, group orders, Discover, Support, Yummy) | Next.js 16, Tailwind 4 |
| `apps/partner` | Yummy Chops Partner — restaurant dashboard | Next.js 16 |
| `apps/admin` | Yummy Chops Command Centre — super admin, hub console, cash and carrier payouts, growth | Next.js 16 |
| `mobile/customer` · `mobile/rider` · `mobile/core` | Customer & rider apps + shared package | Flutter, Riverpod, GoRouter, Dio, Freezed |
| `packages/*` | Design tokens (→ CSS/TS/Dart), typed API client, React UI kit | TypeScript |
| `firebase/` | Firestore/Storage rules, indexes, emulator config, rules tests | Firebase |
| `infra/` · `.github/workflows` | Cloud Build, deploy & bootstrap scripts, CI/CD | GCP |
| `docs/` | Architecture, ADRs, roadmap, deployment, costs, readiness, status | |

## Quick start (local, no cloud account needed)

Prerequisites: Python 3.13 + [uv](https://docs.astral.sh/uv/), Node 22, Flutter 3.47, Firebase CLI.

```bash
cd services/api && uv sync && cd ../agents && uv sync && cd ../.. && npm install
```

```bash
node scripts/dev.mjs auth      # Firebase Auth emulator (no Java needed)
```

```bash
node scripts/dev.mjs api       # API on :8000 with Lagos demo data + local payment sandbox
```

```bash
npm run dev:web                # customer site on :3000 (also dev:partner :3001, dev:admin :3002)
```

Seed demo accounts into the emulator (`customer@`, `owner@`, `rider@`, `admin@yummychops.test`):
`FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 uv run --directory services/api python scripts/seed_auth_emulator.py`.
Details: [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md).

## Tests

| Suite | Command | Result (last run) |
|---|---|---|
| API (unit + HTTP integration) | `cd services/api && uv run pytest` | 610 passed |
| API on PostgreSQL | `TEST_DATABASE_URL=postgresql+asyncpg://… uv run pytest tests/integration` | 116 passed (CI) |
| Agents | `cd services/agents && uv run pytest` | 49 passed (1 live-Gemini test skipped without a key) |
| Web | `npx vitest run --root packages/api-client` · `--root apps/web` · `npm run build` | 30 passed, 3 builds |
| Flutter | `flutter test` in `mobile/core`, `mobile/customer`, `mobile/rider` | 55 passed |
| Firestore/Storage rules + Firestore adapter | `npm run test:rules` (needs Java 21 for the emulators) | passed in CI |

## Key documents

[Architecture](docs/architecture/overview.md) · [ADRs](docs/adr/README.md) · [Status report](docs/PROGRESS.md) ·
[Deployment](docs/DEPLOYMENT.md) · [Cost estimate](docs/COST_ESTIMATE.md) · [Production readiness](docs/PRODUCTION_READINESS.md)

Money is always integer **kobo**; the server prices everything; the AI never touches payment amounts.
