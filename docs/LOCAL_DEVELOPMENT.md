# Local development

## 1. Install

| Tool | Version used | Notes |
|---|---|---|
| Python | 3.13 | via `uv` (0.12) |
| Node.js | 22.12+ | npm workspaces |
| Flutter | 3.47 (Dart 3.13) | Android SDK for device builds |
| Firebase CLI | 14.x | Auth emulator works without Java |
| Java | 21 (optional) | required only for the Firestore/Storage emulators and rules tests |
| PostgreSQL | 16 (optional) | SQLite is used by default for the money DB locally |

```bash
cd services/api && uv sync
```

```bash
cd services/agents && uv sync
```

```bash
npm install
```

## 2. Run the stack

| Process | Command | URL |
|---|---|---|
| Auth emulator | `node scripts/dev.mjs auth` | http://127.0.0.1:9099 (UI :4000) |
| API (memory data, sandbox payments) | `node scripts/dev.mjs api` | http://localhost:8000/docs |
| Agents (needs `GOOGLE_API_KEY` for real answers) | `node scripts/dev.mjs agents` | http://localhost:8100/docs |
| Customer web | `npm run dev:web` | http://localhost:3000 |
| Partner dashboard | `npm run dev:partner` | http://localhost:3001 |
| Command Centre | `npm run dev:admin` | http://localhost:3002 |
| Flutter customer app | `cd mobile/customer && flutter run` | Android emulator reaches the API at 10.0.2.2 |
| Customer app in a browser | `flutter build web --dart-define=USE_FIREBASE_EMULATORS=true` in `mobile/customer`, then `node scripts/dev.mjs customer-web` | http://localhost:5050 (add `--port=5051` if that address stays blank: the browser holds broken site data for it) |

Copy each `apps/*/.env.example` to `.env.local` (emulator mode is the default).

Demo users (emulator only):

```bash
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 uv run --directory services/api python scripts/seed_auth_emulator.py
```

The password comes from `DEMO_USER_PASSWORD` (the script has an emulator-only default). Accounts:
`customer@yummychops.test`, `friend@yummychops.test` (a second customer, for group orders and referrals),
`owner@yummychops.test` (Jollof Junction), `kitchen@yummychops.test`, `rider@yummychops.test` (demo-rider-1),
`support@`, `finance@`, `hub@` (interstate hubs), `admin@yummychops.test` (super admin).

## 3. Payments locally

Without provider keys the API enables the **local payment sandbox** (only when `ENVIRONMENT` is `local`/`test`):
checkout redirects to `http://localhost:8000/v1/dev/sandbox-checkout/<reference>`; “Approve” sends an
HMAC-signed webhook through the same verification → ledger → order pipeline Paystack uses.
To test real Paystack test mode, set `PAYSTACK_SECRET_KEY=sk_test_…` in `services/api/.env` and expose the
webhook URL (`/v1/webhooks/paystack`) with a tunnel.

## 3a. Yummy on WhatsApp locally

`node scripts/dev.mjs api` switches WhatsApp on with the **sandbox sender**, so no Meta account is needed. Run the
agents service too (`node scripts/dev.mjs agents`; without `GOOGLE_API_KEY`, Yummy runs in offline mode).

1. Open the **WhatsApp simulator** at http://localhost:8000/v1/dev/whatsapp (local and test only) and pick a
   phone number. Messages you send there are signed like Meta's webhooks and go through the real pipeline:
   signature check, de-duplication, task, linking, Yummy, reply.
2. Sign in on the website as `customer@yummychops.test`, open Account → **Connect WhatsApp** and send the
   `LINK 123456` message it shows from the simulator.
3. Chat: "What do you offer?", share a location, "I have ₦10,000, find me food for 2 people", "plan 1", then tap
   **Yes, go ahead** and pay on the sandbox payment page. `STOP` disconnects.

To try Meta's real Cloud API, set `WHATSAPP_PROVIDER=cloud`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_APP_SECRET`,
`WHATSAPP_VERIFY_TOKEN` and `WHATSAPP_PHONE_NUMBER_ID` in `services/api/.env` (git-ignored, never committed) and
expose `/v1/webhooks/whatsapp` with a tunnel.

## 4. Using real Firestore / PostgreSQL locally

- Firestore emulator: install Java 21, run `firebase emulators:start --only auth,firestore`, then start the API
  with `DATA_BACKEND=firestore FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 SEED_DEMO_DATA=false` and seed with
  the API container (`gudmeal_api.seed.seed`).
- PostgreSQL: `DATABASE_URL=postgresql+asyncpg://…` then `uv run alembic upgrade head` in `services/api`.

## 5. Tests

See the table in the root README. Rules tests: `npm run test:rules` (starts the Firestore + Storage emulators).

**End-to-end check of a running stack** (auth, api and agents started as above): every journey over HTTP with
real emulator accounts, from browsing to food (including one checkout paying food, delivery fee, service fee and VAT
together, and how that payment is split), beauty, pickup, wallet, pay on delivery, bike packages, interstate
waybills, group orders, Plus, rewards, support, partner tools, sign-up approvals, payouts, the Command Centre,
access control and Yummy. It prints PASS/FAIL per step:

```bash
services/api/.venv/Scripts/python services/api/scripts/e2e_local.py            # Windows (bin/python elsewhere)
services/api/.venv/Scripts/python services/api/scripts/e2e_local.py parcel_bike_delivery   # one journey
```

Shops keep their real opening hours (Lagos time), so at night the check opens its test shops all day and puts
the real hours back when it finishes.

## 6. Test on your phone (Android)

Your phone and this computer must be on the same Wi-Fi. Use this only on a network you trust (home or office):
while it runs, anyone on that Wi-Fi can reach the test servers.

1. Start the stack in **LAN mode** (Windows may ask to let Python/Node through the firewall: allow it). In one
   terminal:
   ```bash
   node scripts/dev.mjs auth api agents downloads --lan --seed
   ```
   That runs the sign-in emulator, the API, Yummy and the download page of step 3 together (when one stops, the
   rest stop), and `--seed` creates the demo accounts of section 2 once the emulator is up. Or run them one by
   one, each in its own terminal (`node scripts/dev.mjs auth --lan`, `... api --lan`, `... agents --lan`), then
   seed the demo accounts (section 2) or run the end-to-end check once: it seeds them too.
   In the Claude desktop app this is the preview server `phone-test` (`.claude/launch.json`). The app runs at
   most five preview servers for a project, and they keep running between chat turns.
2. Build the test APKs (needs the Android SDK; set `LAN_IP` to choose the address):
   `node scripts/build-test-apk.mjs` (or `... customer` / `... rider`). They go to `mobile/dist` (git-ignored).
3. Serve them (`node scripts/dev.mjs downloads --lan`, unless step 1 already started it), then open
   `http://<this computer's address>:8090` on the phone (or scan a QR code of that address), install, and sign in
   with a demo account.

Test builds talk plain http to this computer and use the Auth emulator and the payment sandbox, so never publish
them. After **Approve** on the sandbox payment page, the page says
"Return to the Yummy Chops app": go back to the app, which confirms the payment. An order whose payment page was
closed shows **Finish paying** on its order screen.

**When the computer changes Wi-Fi** its address changes, and the test apps find it again by themselves
([ADR-0020](adr/0020-test-apps-find-the-test-server.md)): put the phone on the same Wi-Fi and open the app. At
startup the app tries the address that worked last time, the address it was built for and the addresses of
earlier builds, then asks every address on the phone's own Wi-Fi (port 8000, `GET /v1/health`). If it cannot
find the computer it says so, tries again when asked and takes a typed address. If the server stops answering
while the app is open, the app says so when you come back to it; a server found at a new address needs the app
closed and opened again (the notice has the button). The payment page follows the computer too
(`SANDBOX_FOLLOWS_LAN_ADDRESS`, which `--lan` sets), so the stack needs no restart. Only the download page keeps
the old address: make it again (`node scripts/build-test-apk.mjs --page`) before installing on another phone.

**Rider jobs:** locally only `rider@yummychops.test` is online among the demo riders (the API starts the others
offline), so every job is offered to the rider app. Keep the app open and online: an offer lasts 45 seconds and
the phone buzzes (the countdown comes from the server's `expires_in_seconds`, so it is right even when the
phone's or this computer's clock is not). The app shares its position every minute even when standing still
(dispatch ignores riders it has not heard from for 3 minutes). Running the end-to-end check puts demo riders 2-4 online while it runs and
offline again at the end.

**Testing alone, at any hour, from anywhere in the city.** `node scripts/dev.mjs api` sets these for local testing
(each is an environment variable you can override; the server ignores the two `DEMO_` switches unless
`ENVIRONMENT=local`, and refuses to start with them in staging or production):

| Local setting | What it does | Normal value |
|---|---|---|
| `DEMO_SHOPS_ALWAYS_OPEN=true` | Every demo shop takes orders around the clock | shops keep their hours (most 10:00-23:00 Lagos time) |
| `DEMO_SHOP_AUTOPILOT=true` (only with `--lan`) | Nobody is at the shop's dashboard during a phone test, so a demo shop (restaurant, pharmacy, beauty shop, supermarket or market shopper) accepts an order left unanswered for about 12 seconds and marks it ready about 30 seconds later. Set it to `false` to play the shop yourself in the partner dashboard. Pickup orders are accepted but still handed over by a person, with the customer's code | off: the shop's staff accept |
| `DISPATCH_PICKUP_RADIUS_KM=40` | Riders up to 40 km from the pickup get the offer at once | 6 km first, then 3 km further each round with nobody to ask, up to 30 km |
| `DISPATCH_REOFFER_SECONDS=20` | A rider who missed an offer (it ran out) is asked again 20 seconds later | 300 (5 minutes); riders who declined are never asked again |
| `RIDER_CASH_LIMIT_KOBO=100000000` | Riders keep getting cash jobs until they hold N1,000,000 | N50,000; cash is handed in on the Command Centre's Cash page |

The rider app also runs in a browser (no GPS there, so pin a position):
`flutter build web --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=RIDER_TEST_LOCATION=6.4478,3.4723` in `mobile/rider`.

In a browser, both apps keep you signed in for one page load only while they use the sign-in emulator: reload
the page and you sign in again. (Once the Firebase web SDK has checked a remembered session with Google, the
emulator can no longer be attached, and every sign-in would fail.) Phones are not affected.

"Continue with Google" on the test server: the sign-in emulator has no Google account chooser, so the app asks
which Google address to use and signs in with it. The live app will open Google's chooser once the Firebase
project exists.

## 7. Let someone elsewhere try the app (a temporary public link)

The phone-test apps only work on the same Wi-Fi as this computer. For a tester somewhere else, a free ngrok
account brings the internet to this computer through one fixed address (docs/adr/0024-public-test-link.md).

1. **Once:** sign up at dashboard.ngrok.com, then in PowerShell run `ngrok config add-authtoken <your token>`
   (never commit or share the token). Your free domain is under **Domains** (e.g. `something.ngrok-free.app`).
2. Put it in `.env.remote-link` at the repository root (git-ignored), next to the tester's password that is
   already there:
   ```
   REMOTE_LINK_DOMAIN=something.ngrok-free.app
   REMOTE_TESTER_PASSWORD=...
   ```
   The link lets only `tester@yummychops.test` sign in, with that password (the demo accounts' password is public).
3. Run the phone test and the link: preview servers `phone-test` and `remote-link`, or in two terminals
   `node scripts/dev.mjs auth api agents downloads --lan --seed` and `node scripts/dev.mjs gateway tunnel`.
4. Build the tester's app once: `node scripts/build-test-apk.mjs --remote --arm64` (makes
   `mobile/dist/yummy-chops-remote.apk`; rebuild only if the domain changes).
5. Send the tester `https://<your domain>` and, separately, the password. The page has the download; they sign in
   as `tester@yummychops.test`. Browsers show ngrok's "Visit Site" notice the first time.

The app works only while this computer is on and both servers run. Stop `remote-link` when testing is done.
The gateway's rules are tested with `node --test scripts/remote-gateway.test.mjs`.
