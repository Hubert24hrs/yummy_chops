# Security Model

## Identity & roles

- Firebase Authentication for every user type (phone OTP, email/password, Google where enabled).
- Roles are Firebase **custom claims** set only by the API's admin endpoints:
  `roles: [..]`, `restaurant_roles: {restaurantId: "owner"|"manager"|"staff"}`.
- Roles: `customer`, `restaurant_owner`, `restaurant_manager`, `restaurant_staff`, `rider`,
  `support_agent`, `operations_manager`, `finance_manager`, `marketing_manager`, `hub_agent`, `super_admin`.
- The API verifies ID tokens with the Firebase Admin SDK (`check_revoked=True` for privileged routes)
  and maps roles to fine-grained permissions in `security/rbac.py` (deny by default).
- **WhatsApp channel tokens** ([ADR-0017](../adr/0017-assistant-on-whatsapp.md)). A WhatsApp message has no ID
  token, so for a linked number the API mints a short-lived token for Yummy:
  - HMAC-SHA256 signed with `CHANNEL_TOKEN_SECRET`, valid 10 minutes, with a unique id
  - **customer role only**, whatever roles the account has, so staff, merchant and rider powers never act over
    WhatsApp
  - accepted by the API and the agents service next to Firebase ID tokens, and kept only in contextvars and request
    headers (never in graph state, logs or the database)

## Data isolation

| Boundary | Enforcement |
|---|---|
| Customer ↔ customer | API ownership checks (others get 404); clients cannot read Firestore at all |
| Restaurant ↔ restaurant | `restaurant_roles` claim must contain the order's `restaurant_id`; a shop sees the delivery area, never the customer's address, phone or live pin |
| Rider ↔ rider | `order.rider_id == uid`; the live map and drop-off pin are for the order's customer, its rider and staff only |
| Staff | permission-based; every privileged mutation writes an `audit_events` row |
| AI threads | thread ownership table checked on every call; memory never shared across users |
| Group orders | only members can read a group (others get 404); members change only their own items; the host alone locks, checks out, cancels or removes people; joining by code is rate-limited per user and groups expire |
| Personal vouchers | a reward voucher carries `customer_id`; anyone else's quote reports an unknown code |
| Waybill tracking | public `GET /v1/track/{code}` returns progress, places and dates only (no names, phones or addresses), rate-limited per client address; hub scans need `hubs:operate` and are accepted only at the package's booked hub for each step |
| WhatsApp numbers | a number reaches an account only after the signed-in customer creates a one-time code and sends it from that number (single use, 10 minutes, 5 an hour). One number per account and one account per number. Unlinked numbers get instructions only, never Yummy. Numbers are masked in responses and audit events |

## Platform controls

- **Firestore and Storage rules**: closed to every client (`allow read, write: if false`). Every read and write
  goes through the API (Admin SDK), which gives each person their own view; riders' KYC documents are uploaded
  and opened through the API only. Opening a collection for live listeners needs a purpose-made collection
  and a rules test (`firebase/tests`).
- **App Check**: the API verifies App Check tokens (`X-Firebase-AppCheck`) when `APP_CHECK_ENFORCED=true`
  (required in production), and so does Yummy for chats. The websites send tokens from reCAPTCHA Enterprise once
  `APP_CHECK_SITE_KEY` is set; the mobile apps do not send them yet, which blocks production for them.
  Yummy Chops' own agents service proves itself instead with a Google-signed OIDC
  token (`X-Service-Authorization`, audience and service account checked; the shared internal secret locally),
  and still needs the user's own token on every call.
- **Secrets**: Secret Manager only; `.env` files are git-ignored; the repo is public.
- **IAM**: one service account per service with least-privilege roles, and each service may read only its own
  secrets (see `infra/scripts/bootstrap-gcp.sh`).
- **Start-up checks**: every service in the cloud refuses to start with an emulator switch set, a default or
  short secret, local KYC storage, a live Paystack key outside production or a test key in production
  (`Settings.validate_for_environment` in the API and in Yummy).
- **Public test link** (ADR-0024, the owner's computer only): the gateway passes only sessions that signed in
  through it with the tester's password, refuses encoded or dotted paths, staff, internal and developer routes,
  and slows down wrong passwords.
- **Internal endpoints** (`/internal/*`): Google-signed OIDC tokens from Pub/Sub / Cloud Tasks / Scheduler,
  audience and service-account email verified.
- **Webhooks**: signature verification (constant time), optional source IP allow-list, idempotent processing.
  WhatsApp webhooks are checked with `X-Hub-Signature-256` (HMAC-SHA256 of the raw body with the Meta app
  secret) and de-duplicated by message id.
- **Rate limiting**: per-principal token buckets on sensitive routes (OTP, location updates, AI chat).
- **Input validation**: Pydantic models with strict bounds on every request body.
- **Headers**: HSTS, no-sniff, frame-deny on web apps; CORS restricted to known origins.

## Compliance notes (Nigeria)

- Nigeria Data Protection Act 2023 (NDPA) and NDPC guidance: lawful basis & consent records for marketing and
  personalisation, data subject access / deletion procedure (`/v1/me/data-export`, `/v1/me` delete request),
  breach notification runbook, Data Protection Impact Assessment before launch, local DPO designation.
- Location data: precise rider location retained 30 days by default, customer addresses only while saved. A
  location shared on WhatsApp is kept on the number's link and deleted when the customer disconnects.
- WhatsApp: Meta processes the chat. The privacy notice must say so and explain how to disconnect (`STOP` or the
  app). Message ids used for de-duplication expire after 7 days.
- Payment data: card data never touches Yummy Chops systems (provider-hosted checkout) — PCI DSS scope stays SAQ-A.
- These are engineering notes, not legal advice; a Nigerian data-protection counsel review is a launch gate.
