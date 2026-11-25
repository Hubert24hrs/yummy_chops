# ADR-0017: Yummy on WhatsApp (WhatsApp Business Cloud API)

- **Status:** Accepted (built and tested against a local sandbox; Meta account, number and keys pending)
- **Date:** 2026-11-15
- **Context owner:** owner's product decisions of 2026-11-15 (see [ROADMAP](../ROADMAP.md)), phase 5

## Context

The owner wants customers to order and get support by chatting with Yummy on WhatsApp, the channel most
Nigerians already use. The Meta WhatsApp Business account is not set up yet, and no credential may be invented.
The feature must keep every existing rule:

- Yummy acts only through typed API tools with the customer's own identity.
- Orders still need an explicit approval.
- Money stays in the API.
- Webhooks are verified.
- Personal data is minimised (NDPA).

Two gaps had to be closed first:

- **Identity.** A WhatsApp message carries a phone number, not a Firebase ID token.
- **App Check.** In production the API enforces App Check, which would also block Yummy's server-to-server tool
  calls.

## Decision

### 1. The WhatsApp channel lives in the API

- **Verification.**
  - `GET /v1/webhooks/whatsapp` answers Meta's verification challenge, using the configured verify token.
  - `POST /v1/webhooks/whatsapp` checks `X-Hub-Signature-256` (HMAC-SHA256 of the raw body with the app secret,
    compared in constant time) and returns 401 when the signature is missing or wrong.
- **Queueing.** Each incoming message is de-duplicated by its WhatsApp message id
  (`whatsapp_messages/{id}`, create-once) and queued as a Cloud Task (`/internal/tasks/whatsapp-message`). The
  webhook therefore answers within milliseconds, and Meta's retries never produce two replies.
- **Handling.** The task handler (`WhatsAppService`) links accounts, runs Yummy and sends the reply. It is
  rate-limited per number (20 messages, then one every 5 seconds). Text longer than 1,000 characters is
  refused. Voice notes, photos and other media get a polite note that Yummy reads text and shared
  locations for now.

### 2. Linking a number to an account by one-time code

- In the app or on the website, **Connect WhatsApp** creates an 8-digit code (single use, valid 10 minutes, at
  most 5 an hour). It comes with a `wa.me` link that pre-fills `LINK 123456`.
- Sending that message from WhatsApp links the number to the signed-in account (`whatsapp_links/{wa_id}`). One
  number belongs to one account and one account has one number; linking again replaces the old link.
- `STOP` (or Disconnect in the app) removes the link.
- An **unlinked number** only gets instructions and support contacts. Yummy is never run without a linked
  account, so no account data or action is reachable from an unknown number.

### 3. Delegated channel tokens

For a linked number, the API mints a **channel token**:

- **Shape.** An HMAC-SHA256-signed token, `gmc1.<payload>.<signature>`, valid 10 minutes, with a unique id and
  `ch=whatsapp`.
- **Customer only.** It carries the customer's uid and **only the `customer` role**. Staff, merchant and rider
  powers never act over WhatsApp.
- **Who accepts it.** Both the API and the agents service accept it alongside Firebase ID tokens, using a shared
  secret (`CHANNEL_TOKEN_SECRET`, from Secret Manager).
- **How it is used.** The API calls Yummy's normal `POST /v1/chat` with the token and `channel: "whatsapp"`. Yummy's
  tools call the API with the same token, so authentication, ownership checks, pricing, the order state machine,
  rate limits and audit are unchanged.
- **Storage.** Tokens live only in contextvars and request headers, never in graph state or the database.

### 4. Conversations, approvals and links

- **Threads.** There is one Yummy thread per linked number, stored on the link. A new thread starts after 24 hours
  of silence or when the old one is gone.
- **Style.** The `whatsapp` channel tells Yummy to keep replies short and in plain text.
- **What is sent back.** The reply text, plus only the cards that need an action:
  - **Approvals** (placing an order, booking a package) become two reply buttons, *Yes* and *No*. Their ids carry
    the pending tool call, and typing "yes" or "no" also answers. The approval summary, including the exact total,
    comes from the server's preview, never from the model.
  - **Payment links** become a "Pay now" button that opens the provider's hosted checkout. Card details never pass
    through WhatsApp or Yummy Chops.
  - **Screen buttons** (Plus, Rewards, an order, tracking) become links to the website.
- **Locations.** A location shared in the chat (📎 → Location) is kept on the link and sent to Yummy as the
  `delivery_address`, so plans, quotes and drafts use it instead of the first saved address. It is matched to
  the nearer launch city, and the API still checks the delivery zone. Sharing another location replaces it;
  disconnecting deletes it.
- **Where it goes.** WhatsApp has no order screen, so the approval text names the delivery address
  ("Delivering to Lekki Phase 1, Lagos"), and package bookings name both ends. The address comes from the
  server's preview and is kept out of the order summaries the model reads.
- **Order channel.** Orders and support tickets Yummy creates in a WhatsApp chat are saved with channel
  `whatsapp` (from the app and website they stay `ai_agent`), so WhatsApp orders can be counted.
- **Timing.** Yummy Chops only replies to messages, inside WhatsApp's 24-hour customer-service window. Proactive
  updates (order status, Plus reminders) need Meta-approved templates and are left for later.

### 5. Sending

- **Cloud API.** `CloudApiSender` posts to the Graph API `/{phone-number-id}/messages` with the system-user
  access token, sending text, reply buttons or a call-to-action link.
- **Sandbox.** `SandboxSender` records messages instead. Local development and tests use it together with a
  **WhatsApp simulator** at `/v1/dev/whatsapp` (local and test only). The simulator signs its fake webhooks with
  the sandbox secret, so the whole pipeline (signature, de-duplication, task, linking, Yummy, reply) runs
  without Meta.

### 6. Service identity for Yummy's tool calls

- **The credential.** The agents service attaches a service credential to every API call:
  - in the cloud, a Google-signed OIDC token from its service account in `X-Service-Authorization`
  - locally, the shared internal secret
- **Effect on App Check.** The API accepts that credential in place of an App Check token, but only from the
  accounts in `TRUSTED_SERVICE_ACCOUNTS` (the agents service). That list does not open `/internal/*`, which
  stays limited to Cloud Tasks, Pub/Sub and Scheduler. App Check stays enforced for client apps, and the
  user's identity is still required on every call.

## Consequences

- **New pieces:**
  - API settings: WhatsApp keys, `CHANNEL_TOKEN_SECRET`, `AGENTS_BASE_URL`, `PUBLIC_WEB_URL` and
    `TRUSTED_SERVICE_ACCOUNTS`; agents settings: `CHANNEL_TOKEN_SECRET` and `INTERNAL_AUTH_MODE`
  - Firestore collections: `whatsapp_links`, `whatsapp_accounts`, `whatsapp_link_codes`,
    `whatsapp_messages` (the last two with a TTL on `expire_at`)
  - order channel `whatsapp`
  - customer endpoints: `/v1/me/whatsapp`
  - the webhook routes, the internal task and the dev simulator
- **Dependencies.** The API now calls the agents service, over HTTP and only from the WhatsApp task. The agents
  service still calls the API for everything else.
- **Unchanged.** Ordering on WhatsApp is the same Yummy, with the same approvals and the same payment pages as in
  the app. There is no new money pathway.

## Open items (before launch)

1. **Meta setup (owner):**
   - Meta Business verification
   - a WhatsApp Business number and an approved display name
   - a permanent system-user access token, the app secret and a verify token in Secret Manager
   - the webhook URL `https://<api>/v1/webhooks/whatsapp`
2. **Cost.** WhatsApp Business messaging is a **paid** Meta service, priced per conversation. The owner approves
   the costs before it is switched on in production (`WHATSAPP_ENABLED=true`).
3. **Templates** for proactive messages (order updates, Plus renewal reminders) and the opt-in wording, approved
   by Meta.
4. **Not yet supported:** voice notes and images (speech-to-text, photo complaints) and WhatsApp Flows.
5. **Privacy notice.** The NDPA notice must cover WhatsApp: what Meta processes, how long chats are kept, and how
   to disconnect.
