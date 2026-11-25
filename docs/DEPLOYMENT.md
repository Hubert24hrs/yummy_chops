# Deployment guide

Live since 2026-11-20: the three websites on Vercel at yummy247.com, partner.yummy247.com and
admin.yummy247.com, and the customercare@yummy247.com mailbox on Zoho Mail (sections 5a and 5b). The API and
Yummy are not deployed yet, so the websites cannot list shops, sign anyone in or take orders. These are the steps
to stand up each environment; every billable step is yours to run and approve.

## 0. Prerequisites (per environment: dev, staging, prod)

1. Create GCP projects `yummy-chops-dev`, `yummy-chops-staging`, `yummy-chops-prod` and **add Firebase** to each.
2. Link billing and create a **budget alert** (the bootstrap script prints the command).
3. In Firebase Console:
   - enable Authentication providers (Phone, Email/Password, Google)
   - register the Android and iOS apps (bundle `com.yummy247.app` / `com.yummy247.rider`)
   - register **one Web app** for the three websites; its `apiKey` and `appId` become GitHub Environment
     variables (section 3)
   - set up App Check: Play Integrity, App Attest, and a **reCAPTCHA Enterprise** key for the website domains
     (section 5)
4. Payment providers: Paystack (and optionally Flutterwave) business accounts; use **test keys** for dev/staging.

## 1. Bootstrap infrastructure

```bash
infra/scripts/bootstrap-gcp.sh yummy-chops-dev europe-west1
```

Add `--with-cloud-sql` to create the PostgreSQL instance (billed hourly — the script asks first). Then
store secrets (never in the repo):

```bash
printf '%s' 'postgresql+asyncpg://gudmeal_api:<password>@/gudmeal?host=/cloudsql/yummy-chops-dev:europe-west1:gudmeal-sql' | gcloud secrets versions add api-database-url --data-file=-
```

Required secrets: `api-database-url`, `agents-database-url`, `agents-checkpoint-url`, `paystack-secret-key`,
`api-code-pepper`, `gemini-model` (Yummy runs Gemini on Vertex AI with its own identity, no key: a pinned stable Flash id — verify with
`services/agents/scripts/check_gemini_models.py`), `channel-token-secret` (a long random value, read by both
the API and the agents service). Optional: `flutterwave-*`, `google-maps-server-key` (bound by `deploy.sh` as soon
as it has a value; see [GOOGLE_MAPS.md](GOOGLE_MAPS.md)), and the `whatsapp-*` secrets when Yummy on WhatsApp is
switched on (section 4a).

```bash
openssl rand -base64 48 | tr -d '\n' | gcloud secrets versions add channel-token-secret --data-file=-
```

`deploy.sh` also sets the service identities: the agents service calls the API with its own Google-signed token
(`INTERNAL_AUTH_MODE=oidc`), and the API lists that account in `TRUSTED_SERVICE_ACCOUNTS` so Yummy's calls pass App
Check. That list does not open `/internal/*`, which stays limited to `gudmeal-tasks`.

**Service URLs.** Deploys use Cloud Run's deterministic URLs, `https://SERVICE-PROJECT_NUMBER.REGION.run.app`
([`infra/scripts/urls.sh`](../infra/scripts/urls.sh)). They are known before the first deploy, so the OIDC
audience, the CORS origins, the payment return page and the websites' build settings are right from the start.
The bootstrap script prints them.

## 2. Firebase rules and indexes

```bash
cd firebase && firebase deploy --only firestore,storage --project yummy-chops-dev
```

## 3. CI/CD

- `.github/workflows/ci.yml` runs on every push/PR: API on SQLite and PostgreSQL, Alembic, agents, Firebase
  emulator rules tests, web builds, Flutter analyze/tests, and Docker image builds. The API image and the three
  website images are smoke-tested.
- `.github/workflows/deploy.yml` is manual (`workflow_dispatch`) per GitHub Environment. Configure Workload
  Identity Federation for the `gudmeal-deployer` service account and protect `production` with required
  reviewers.

GitHub Environment settings (per environment):

| Kind | Name | Value |
|---|---|---|
| Variable | `GCP_PROJECT_ID`, `GCP_REGION`, `ARTIFACT_REPO` | e.g. `yummy-chops-dev`, `europe-west1`, `gudmeal` |
| Variable | `FIREBASE_API_KEY`, `FIREBASE_APP_ID` | the Firebase Web app's config (public values) |
| Variable | `FIREBASE_AUTH_DOMAIN` | optional; defaults to `<project>.firebaseapp.com` |
| Variable | `APP_CHECK_SITE_KEY` | reCAPTCHA Enterprise site key for the websites; **required for production** |
| Variable | `MAPS_BROWSER_KEY` | optional Maps JavaScript key, restricted to the website domains |
| Variable | `API_URL`, `AGENTS_URL`, `WEB_URL`, `PARTNER_URL`, `ADMIN_URL` | optional custom domains (default: the run.app URLs) |
| Secret | `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT` | Workload Identity Federation (no JSON keys) |

The deploy job builds five images with Cloud Build (API, agents and the three websites), runs
`alembic upgrade head` as a Cloud Run job, then runs `infra/scripts/deploy.sh`: resource limits, autoscaling
bounds, the Cloud SQL connector, Secret Manager bindings and the five Cloud Run services.

## 4. After the first deploy

Run the follow-up commands printed by the bootstrap script: Cloud Run invoker for `gudmeal-tasks`, the
Pub/Sub push subscription to `/internal/events` (with dead-letter topic) and Cloud Scheduler jobs for
`relay-outbox`, `reconcile-payments`, `sweep` and `renew-plus` (daily, Yummy Chops Plus wallet renewals). Then set the Paystack webhook URL to
`https://<api-url>/v1/webhooks/paystack` and (optionally) restrict by Paystack's source IPs via
`PAYSTACK_WEBHOOK_IP_ALLOWLIST`.

## 4a. Yummy on WhatsApp (optional; paid Meta service)

WhatsApp Business messaging is billed by Meta per conversation, so it stays off (`WHATSAPP_ENABLED=false`) until
the owner approves the cost ([ADR-0017](adr/0017-assistant-on-whatsapp.md)). To switch it on:

1. In Meta Business Manager: verify the business, add a WhatsApp Business number with an approved display name,
   and create a system user with a **permanent access token** for the WhatsApp Business Account.
2. Store the secrets (the verify token is any long random value you choose):

   ```bash
   gcloud secrets versions add whatsapp-access-token --data-file=-   # paste the system-user token, then Ctrl-D
   gcloud secrets versions add whatsapp-app-secret --data-file=-     # Meta app → Settings → Basic → App secret
   openssl rand -hex 32 | tr -d '\n' | gcloud secrets versions add whatsapp-verify-token --data-file=-
   ```

3. Deploy with WhatsApp on (links in Yummy's messages point to the customer website automatically):

   ```bash
   WHATSAPP_ENABLED=true WHATSAPP_PHONE_NUMBER_ID=<id from Meta> WHATSAPP_BUSINESS_NUMBER='+234 …' \
     infra/scripts/deploy.sh <environment> <project> <region> <repo> <tag>
   ```

4. In the Meta app's WhatsApp → Configuration, set the callback URL to `https://<api-url>/v1/webhooks/whatsapp`,
   enter the verify token, and subscribe to the `messages` field. Meta's verification call must succeed.
5. Check it: send `HELP` from a phone, then link a test account from the app (Profile → Order on WhatsApp).

The bootstrap script also turns on Firestore TTL for `whatsapp_messages` and `whatsapp_link_codes` (field
`expire_at`), so de-duplication records and old link codes delete themselves.

## 5. Websites

**Since 2026-11-20 the live websites are on Vercel (section 5a).** The Cloud Run setup below still works and is
kept as an option: it puts the websites next to the API in one Google Cloud project.

The customer website, the partner dashboard and the Command Centre run on Cloud Run as `gudmeal-web`,
`gudmeal-partner` and `gudmeal-admin`.

- **Image.** [`infra/docker/web.Dockerfile`](../infra/docker/web.Dockerfile) builds one app (`APP=web`, `partner`
  or `admin`) with Next.js standalone output (`BUILD_STANDALONE=true`). It runs `node server.js` as a non-root
  user on port 8080.
- **Settings.** The browser settings (`NEXT_PUBLIC_*`) are compiled in at build time, so every environment has
  its own images. They are the API and Yummy URLs, the site's own URL, the Firebase web config, the App Check site
  key and the optional Maps browser key. Cloud Build gets them from the deploy workflow. They are public by
  design, so never put a secret there. The build stops if a required value is missing. The customer site also
  reads `API_URL` at run time for its server-rendered pages.
- **Service.** Public, scales to zero (production keeps one customer-site instance warm), and runs as the
  role-less `gudmeal-web` service account.
- **API side.** `deploy.sh` sets the API's and Yummy's `CORS_ORIGINS` to the three sites, the payment return page
  to `<website>/checkout/callback`, and `PUBLIC_WEB_URL` (links in WhatsApp messages).
- **Firebase.** Add the three `run.app` hosts (the bootstrap script prints them) to Authentication → Settings →
  Authorized domains, or signing in on the sites fails.
- **App Check.** With `APP_CHECK_SITE_KEY` set, the sites send an App Check token (reCAPTCHA Enterprise) with
  every signed-in API call. The production API enforces App Check, so the deploy workflow refuses a production
  build without the key. Register the key for the Firebase Web app and list the three domains on it.
- **Custom domains**: the owner bought `yummy247.com` on 2026-11-20 ([ADR-0023](adr/0023-yummy-chops.md)). The
  addresses are `yummy247.com` and `www.yummy247.com` (customer website), `partner.yummy247.com`,
  `admin.yummy247.com`, `api.yummy247.com` and `assistant.yummy247.com` (Yummy). The first four point to Vercel
  (sections 5a and 5b). For the API and Yummy, use Cloud Run domain mapping or a load balancer, add their records
  at Namecheap, set the `*_URL` variables and redeploy. Then update the authorized domains, the reCAPTCHA key's
  domains and the Maps browser key's referrers. The support mailbox is `customercare@yummy247.com`
  (`SUPPORT_EMAIL`, the API's default, shown in the apps and by Yummy). Set `SUPPORT_WHATSAPP` and
  `SUPPORT_PHONE` when the real numbers exist; until then they stay empty and show as "coming soon".

To build an image yourself (CI does this for all three with demo settings):

```bash
docker build -f infra/docker/web.Dockerfile --build-arg APP=web --build-arg NEXT_PUBLIC_API_URL=https://<api> \
  --build-arg NEXT_PUBLIC_AGENTS_URL=https://<agents> --build-arg NEXT_PUBLIC_SITE_URL=https://<site> \
  --build-arg NEXT_PUBLIC_FIREBASE_API_KEY=<key> --build-arg NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=<project>.firebaseapp.com \
  --build-arg NEXT_PUBLIC_FIREBASE_PROJECT_ID=<project> --build-arg NEXT_PUBLIC_FIREBASE_APP_ID=<app id> -t gudmeal-web .
```

## 5a. Websites on Vercel (live)

The owner chose Vercel for the three websites on 2026-11-20. The API and Yummy stay on Cloud Run (sections 1–4).

| Site | Vercel project | Root Directory | Address |
|---|---|---|---|
| Customer website | `yummy-chops-web` | `apps/web` | https://yummy247.com (`www` redirects to it, 308) |
| Partner dashboard | `yummy-chops-partner` | `apps/partner` | https://partner.yummy247.com |
| Command Centre | `yummy-chops-admin` | `apps/admin` | https://admin.yummy247.com |

- **Account and cost.** The owner's Vercel account, signed in with GitHub. It is on the free **Hobby** plan, at
  the owner's choice. Vercel's terms allow Hobby only for personal, non-commercial
  use, so move to **Pro** ($20 per member per month, including $20 of usage) before the platform trades.
- **Builds.** Each project builds from GitHub `main` of `Hubert24hrs/yummy_chops` on every push, and every
  other branch or pull request gets a preview deployment. Each project uses the Next.js preset with the default
  commands. Vercel installs the npm workspaces from the repository root (`package-lock.json`), so
  `packages/ui`, `packages/api-client` and `packages/tokens` are built from source, as in CI. There is no
  `vercel.json` and no `BUILD_STANDALONE`. Hobby runs one build at a time, so a push queues three builds (about a
  minute each).
- **Settings** (Project → Settings → Environment Variables, for Production and Preview). They are compiled into
  the browser code at build time, so they are public: never put a secret in one. After changing a value, redeploy
  (Deployments → ⋯ → Redeploy).

  | Variable | web | partner | admin | Value |
  |---|---|---|---|---|
  | `NEXT_PUBLIC_API_URL` | ✓ | ✓ | ✓ | `https://api.yummy247.com` |
  | `API_URL` (server-rendered pages) | ✓ | | | `https://api.yummy247.com` |
  | `NEXT_PUBLIC_AGENTS_URL` | ✓ | | ✓ | `https://assistant.yummy247.com` |
  | `NEXT_PUBLIC_SITE_URL` | ✓ | | | `https://yummy247.com` |
  | `NEXT_PUBLIC_FIREBASE_API_KEY`, `_AUTH_DOMAIN`, `_PROJECT_ID`, `_APP_ID` | ✓ | ✓ | ✓ | **not set**: no Firebase project yet |
  | `NEXT_PUBLIC_APP_CHECK_SITE_KEY` | ✓ | ✓ | ✓ | **not set**: no reCAPTCHA Enterprise key yet |
  | `NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY` | optional | optional | optional | **not set** (schematic maps until then) |
  | `NEXT_PUBLIC_USE_FIREBASE_EMULATORS` | | | | **never set on Vercel** |

  The API and Yummy addresses are the planned custom domains, so the sites need no rebuild when the backend goes
  live there. Until it does, the sites load but cannot list shops, sign anyone in (the Firebase settings fall
  back to the emulator demo project) or take orders.
- **When the backend is deployed**, run `deploy.sh` with `WEB_URL=https://yummy247.com`,
  `PARTNER_URL=https://partner.yummy247.com`, `ADMIN_URL=https://admin.yummy247.com`,
  `API_URL=https://api.yummy247.com` and `AGENTS_URL=https://assistant.yummy247.com`. CORS, the payment
  return page (`https://yummy247.com/checkout/callback`) and `PUBLIC_WEB_URL` then use the real addresses. The
  script also deploys the Cloud Run copies of the websites, which are not needed while Vercel serves them. In
  Firebase, add `yummy247.com`, `www.yummy247.com`, `partner.yummy247.com` and `admin.yummy247.com` to
  Authentication → Settings → Authorized domains, to the reCAPTCHA Enterprise key and to the Maps browser key's
  referrers. Then set the Firebase and App Check variables above and redeploy the three projects.

## 5b. Domain and email: Namecheap DNS and Zoho Mail (live)

`yummy247.com` is registered at Namecheap, with Namecheap BasicDNS (nameservers `dns1/dns2.registrar-servers.com`).
Records are in Namecheap → Domain List → yummy247.com → Advanced DNS. The values come from the Vercel and Zoho
consoles: copy them from there again if anything is re-created.

| Type | Host | Value | For |
|---|---|---|---|
| A | `@` | `216.198.79.1` | customer website (Vercel) |
| CNAME | `www` | `26564e387b6053cf.vercel-dns-017.com.` | redirect to yummy247.com (Vercel) |
| CNAME | `partner` | `733ebc0d40410c82.vercel-dns-017.com.` | partner dashboard (Vercel) |
| CNAME | `admin` | `d6db04535776b80d.vercel-dns-017.com.` | Command Centre (Vercel) |
| MX | `@` | `mx.zoho.com` (10), `mx2.zoho.com` (20), `mx3.zoho.com` (50) | Zoho Mail |
| TXT | `@` | `v=spf1 include:zohomail.com ~all` | SPF |
| TXT | `zmail._domainkey` | `v=DKIM1; k=rsa; p=…` (Zoho → Domains → yummy247.com → DKIM) | DKIM |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:customercare@yummy247.com` | DMARC, report only |
| TXT | `@` | `zoho-verification=zb95984097.zmverify.zoho.com` | Zoho domain ownership |

- **Removed** on 2026-11-20: Namecheap's parking records (`www` → `parkingpage.namecheap.com`, and a URL redirect
  on `@`). Mail Settings were switched from Email Forwarding to **Custom MX**, which also removed Namecheap's
  forwarding SPF record. A domain may have only one SPF record: add any new sender, such as a newsletter tool, to
  the same record (`include:`).
- **Zoho Mail**: the Forever Free plan (up to 5 users, 5 GB each, the web and the Zoho Mail phone app only, no
  IMAP, POP or SMTP; Mail Lite is about $1 per user per month and adds them). It is in Zoho's US data centre
  (zoho.com), organisation "Yummy247". The super admin is `customercare@yummy247.com`: read it at
  https://mail.zoho.com and manage it at https://mailadmin.zoho.com. Zoho verified the domain, MX, SPF and DKIM on
  2026-11-20.
- **DMARC** only reports (`p=none`). Daily reports from the big mail providers arrive at customercare@ as zip or
  xml attachments, and they can be filtered away. After a few weeks of clean reports, change the policy to
  `p=quarantine`.
- **Check** from any computer:
  `nslookup -type=mx yummy247.com 8.8.8.8`, `nslookup -type=txt zmail._domainkey.yummy247.com 8.8.8.8`, and
  Vercel → Project → Settings → Domains ("Valid Configuration").

## 6. Mobile releases

```bash
flutter build appbundle --release --dart-define=API_URL=https://<api> --dart-define=AGENTS_URL=https://<agents> --dart-define=USE_FIREBASE_EMULATORS=false --dart-define=FIREBASE_API_KEY=<key> --dart-define=FIREBASE_APP_ID=<id> --dart-define=FIREBASE_PROJECT_ID=<project> --dart-define=FIREBASE_SENDER_ID=<sender>
```

Requires an upload keystore (`android/key.properties`, never committed) and Play Console setup; iOS needs an
Apple Developer account, signing certificates and App Store Connect. The apps do not send App Check tokens yet,
so they cannot use the production API (which enforces App Check) until they do (see [PROGRESS.md](PROGRESS.md)).

## 7. Rollback

`gcloud run services update-traffic <service> --to-revisions=<previous>=100` for any of the five services
(`gudmeal-api`, `gudmeal-agents`, `gudmeal-web`, `gudmeal-partner`, `gudmeal-admin`). Database migrations are
forward-only in production; ship a new migration to revert schema changes.

## 8. The online test server (`yummy-chops-dev`, ADR-0026)

For testers anywhere, without the owner's computer: the API and Yummy on Cloud Run, real Firebase sign-in (anyone can
sign up), Paystack test mode and the invented demo shops. Done so far (2026-11-22): project created, Firebase added
(customer app, rider app and websites registered), Firestore created and its rules deployed, Email/Password sign-in
on, US$10 prepaid at Google's request. Left: billing on the project (Google's project-quota review), then:

1. `gcloud billing projects link yummy-chops-dev --billing-account <id>` and a US$20 budget alert.
2. The bootstrap steps of section 1 with `--project yummy-chops-dev` on each command (do not change the default
   gcloud project; the owner has other projects), but Cloud SQL as **db-f1-micro** (`--tier db-f1-micro
   --availability-type ZONAL`), databases `gudmeal` and `gudmeal_agents`, users with generated passwords, and the
   secrets `api-database-url`, `agents-database-url`, `agents-checkpoint-url`, `api-code-pepper`,
   `channel-token-secret`, plus `paystack-secret-key` from `.env.paystack` (then delete that file).
3. Firestore indexes: `cd firebase && firebase deploy --only firestore --project yummy-chops-dev`.
4. Images with Cloud Build (`gudmeal-api`, `gudmeal-agents`), `alembic upgrade head` as a Cloud Run job, then
   `WEB_URL=https://yummy247.com PARTNER_URL=https://partner.yummy247.com ADMIN_URL=https://admin.yummy247.com
   DEPLOY_WEBSITES=false infra/scripts/deploy.sh development yummy-chops-dev europe-west1 gudmeal <tag>`.
5. Section 4's invoker, Pub/Sub push and Scheduler jobs, plus `demo-shops` every minute
   (`/internal/jobs/demo-shops`); run `/internal/jobs/seed-demo` once (a one-off Scheduler job, `gcloud scheduler
   jobs run`). Paystack test webhook: `https://<api-url>/v1/webhooks/paystack`.
6. `services/api/.venv/Scripts/python services/api/scripts/online_accounts.py yummy-chops-dev` (staff logins).
7. Google Maps ([GOOGLE_MAPS.md](GOOGLE_MAPS.md); free monthly limits cover testing): enable Maps SDK for Android,
   Maps JavaScript API, Places API (New), Geocoding and Routes, then three keys: a server key in Secret Manager
   `google-maps-server-key` (exact addresses for search and GPS), an Android key restricted to the two apps' package
   names and SHA-1 as `MAPS_ANDROID_KEY` in `.env.online` ("Choose on the map" in the apps), and a browser key for the
   yummy247.com domains as `NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY` on Vercel (the website's map).
8. `node scripts/build-online-apk.mjs`, then `node scripts/build-online-apk.mjs --publish`: testers download from
   https://yummy-chops-dev.web.app.

Sign-in on the test server: Email/Password and Google are on (Firebase console); the tester apps' signing key
(the debug keystore, SHA-1 `0E:0C:D9:…:67:F3`) is registered for both Android apps, which Google sign-in needs.
