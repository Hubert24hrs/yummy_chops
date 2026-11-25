# ADR-0024: A temporary public test link, so someone elsewhere can try the app

- **Status:** Accepted
- **Date:** 2026-11-20
- **Context owner:** owner's request of 2026-11-20: send the test APK to someone who is not on the owner's Wi-Fi.
  Asked to choose between an online test server (Google Cloud, billed), the same Wi-Fi only, or a temporary link
  from the owner's computer, the owner chose the temporary link.

## Context

The test APKs talk to the phone test running on the owner's computer (sign-in emulator, API, the assistant Yummy)
and find it on the phone's own Wi-Fi (ADR-0020). Someone elsewhere has no way to reach it. Nothing is deployed
yet, and an online test server needs a Google Cloud account with billing.

## Decision

1. **ngrok brings the internet to the owner's computer.** The owner's free ngrok account gives one fixed address
   (a dev domain such as `something.ngrok-free.app`), so an app built for it keeps working after restarts. ngrok
   serves it over https, and over plain http as well: Firebase talks to its Auth emulator only over http.
2. **One gateway behind it** (`scripts/remote-gateway.mjs`, 127.0.0.1:8088) hands each request to its service:
   `/identitytoolkit.googleapis.com/...` and `/securetoken.googleapis.com/...` to the sign-in emulator,
   `/agents/...` to Yummy, everything else to the API. It also serves a landing page with the download (`/` and
   `/download`, the APK `mobile/dist/yummy-chops-remote.apk`).
3. **The gateway turns away what a tester's customer app never needs:** staff and internal routes (`/v1/admin`,
   `/v1/partner`, `/v1/rider`, `/v1/webhooks`, `/internal`, Yummy's `/v1/admin`), developer tools (`/v1/dev`
   except the payment sandbox page), the API docs, the emulator's admin calls (`/emulator/...`, `Bearer owner`)
   and every sign-in call but signing in, reading or updating the signed-in account and refreshing the session.
4. **Only the tester gets in.** The demo accounts' password is public in this repository, so the link signs in only
   `tester@yummychops.test`, whose password is generated locally and kept in the git-ignored `.env.remote-link`
   with the domain. New accounts cannot be created through the link. The emulator's tokens are not signed, so the
   API alone cannot tell a made-up admin token from a real one: the gateway passes only tokens that name the
   tester and carry no staff roles.
5. **A build for the link** (`node scripts/build-test-apk.mjs --remote --arm64`): the customer app with
   `API_URL=https://<domain>`, `AGENTS_URL=https://<domain>/agents`, the emulator at `<domain>:80`
   (`AUTH_EMULATOR_PORT`) and no Wi-Fi search. It is saved as `yummy-chops-remote.apk`, so the Wi-Fi builds stay.
6. **Payments open where the payer is.** The API builds the payment sandbox link from the address the request came
   in on (ADR-0020): through the link that is `https://<domain>`. A payment Yummy starts for a user goes to the
   address that user's device last used, so the tester gets the link and the owner gets the Wi-Fi.
7. **It runs as preview server `remote-link`** (`node scripts/dev.mjs gateway tunnel`) next to `phone-test`.

## Alternatives considered

- **An online test server** (Cloud Run with a real Firebase project): works with the computer off and without
  ngrok's limits, but needs a Google Cloud account with billing. Still the way for anything beyond a few testers.
- **Cloudflare quick tunnels or SSH tunnels:** no account, but a new address every time they start, so the app would
  need rebuilding after every restart.
- **The same Wi-Fi only:** no work, but the tester has to be at the owner's place.

## Consequences

- The app works for the tester only while this computer is on and both `phone-test` and `remote-link` run. The
  Claude app stops preview servers when it restarts: start them again (or run the two `dev.mjs` commands in a
  terminal).
- ngrok's free plan: about 20,000 requests and 1 GB a month, and a "Visit Site" notice the first time a browser
  opens the link (the landing page, the payment page); the app's own calls are not affected.
- The sign-in emulator's traffic, including the tester's password, crosses the internet over plain http. Test data
  and a test-only password only; never use a real password there.
- Turn the link off when testing is done (stop `remote-link`).

## Tests

- `scripts/remote-gateway.test.mjs` (`node --test scripts/remote-gateway.test.mjs`): every route, sign-in and token rule.
- API: `tests/unit/test_phone_test_address.py` (each user's own device address).
- Checked on 2026-11-20 with the real phone test behind the gateway, as a tester elsewhere would use it: the
  landing page, a demo account refused, the tester signed in, sign-up and a made-up admin token refused, staff,
  internal and developer routes closed, an order paid through a payment page at the public https address, and
  Yummy answering through `/agents`.
