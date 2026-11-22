# ADR-0026: An online test server anyone with the tester app can use

- **Status:** Accepted; being set up (waiting for Google to allow billing on the project)
- **Date:** 2026-11-22
- **Context owner:** owner's request of 2026-11-21: "i want to test it so everyone with apk can test it", plus Paystack's
  test mode. Asked to choose, the owner picked an online server over the test link from their computer
  (ADR-0024, not yet in the repository) and "anyone can sign up" over separate or shared test accounts, and approved
  about US$10-15 a month with a US$20 budget alert.

## Context

The phone test and the public test link both run on the owner's computer: they stop when it sleeps, ngrok's free
plan allows about 20,000 requests a month, and the link lets one shared test account in. Many testers need a server
that runs all day with real sign-up. The deployment design (Cloud Run, Firestore, Cloud SQL, Pub/Sub, Cloud Tasks,
Scheduler; `infra/scripts`) existed but had never been run.

## Decision

1. **Google Cloud project `yummy-chops-dev`** (europe-west1) with Firebase, on the owner's billing account. The API and
   Yummy run on Cloud Run as designed (`ENVIRONMENT=development`), with Firestore, a small Cloud SQL PostgreSQL
   instance (db-f1-micro, about US$10 a month) for the money ledger, and Secret Manager. The websites stay on Vercel
   (`DEPLOY_WEBSITES=false`); `WEB_URL=https://yummy247.com` makes the payment return page and CORS point there.
2. **Real Firebase sign-in:** Email/Password is on, so anyone with the tester app creates their own account. The
   tokens are signed by Google, so the API checks them as in production (unlike the emulator's).
3. **Paystack test mode:** the owner's TEST secret key goes to Secret Manager (`paystack-secret-key`); it never
   passes through chat or the repository (it waits in the git-ignored `.env.paystack` and is deleted once stored).
   Testers pay with Paystack's published test card.
4. **The invented demo shops on a real database:** two internal jobs, refused in staging and production and switched
   on by `deploy.sh` only for `development`:
   - `POST /internal/jobs/seed-demo` fills Firestore once with the demo shops, menus, riders and vouchers, opens the
     shops around the clock and keeps only rider@'s profile for jobs.
   - `POST /internal/jobs/demo-shops` (Cloud Scheduler, every minute) lets demo shops accept waiting orders and mark
     them ready, as the local stack's autopilot does every few seconds.
5. **Staff logins are private:** `services/api/scripts/online_accounts.py` makes rider@, owner@ and admin@ on the real
   project with their own random passwords in the git-ignored `.env.online-accounts` (never the emulator's public
   demo password). Customers sign up in the app.
6. **Tester apps:** `node scripts/build-online-apk.mjs` builds the customer and rider apps for the online services
   (settings from the git-ignored `.env.online`), and `--publish` puts the download page on Firebase Hosting at
   https://yummy-chops-dev.web.app.
7. **Yummy without an AI key** answers in its offline mode: `deploy.sh` binds the Gemini secrets only once they have a
   value.

## Consequences

- About US$10-15 a month while it runs, nearly all Cloud SQL; the project can be deleted after testing.
- A rider is needed to finish deliveries: the owner (rider@ in the online rider app) or another rider account.
- Google first asked for a US$10 prepayment (paid 2026-11-22) before allowing a sixth project on the billing account.

## Tests

API `tests/integration/test_retail_services.py`: the seed and autopilot jobs on a development server, and both
refused without the scheduler's credentials or with the switches off.
