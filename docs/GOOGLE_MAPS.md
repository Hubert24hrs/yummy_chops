# Google Maps Platform: setup, keys, costs and privacy

Yummy Chops uses Google Maps Platform for:

- address search;
- distances and road-based arrival times;
- delivery fees on road distance;
- live delivery maps;
- Yummy's "near me" answers.

The design is in [ADR-0014](adr/0014-google-maps-platform.md).

**Nothing calls Google until you add a key.** Until then every feature still works on the built-in neighbourhood
table and straight-line estimates. Screens and Yummy label those results as estimates.

## What uses which API

| Feature | Google API | Called by | Key |
|---|---|---|---|
| Address search (type-ahead) | Places API (New): Autocomplete | gudmeal-api `/v1/places/autocomplete` | server key |
| Chosen address (pin, area) | Places API (New): Place Details (Essentials fields) | `/v1/places/details` | server key |
| "Use my location" and checking a kitchen's address | Geocoding API | `/v1/places/reverse`, partner location | server key |
| Delivery fee, arrival time, live arrival time | Routes API: Compute Routes | quotes, rider tracking | server key |
| Comparing kitchens (Yummy, nearby) | Routes API: Compute Route Matrix | `/v1/delivery/estimates` | server key |
| Map tiles in the customer app (Android / iOS) | Maps SDK for Android / iOS | the app | restricted app keys (optional) |
| Map tiles on websites and the app's web build | Maps JavaScript API | the browser | restricted browser key (optional) |

Without app or browser keys, screens draw a schematic map (pins, route line, rider) from the same API data.
Navigation for riders opens the Google Maps app with a link and needs no key.

## Where it shows up

| Where | What |
|---|---|
| Customer app | Checkout "Pin your exact address" and Profile → Saved addresses → **Find on map**: search, "use my current location" (asked once, not tracked), saved addresses, a coverage check and a pin preview |
| Customer app | Food / Beauty → map icon: nearby restaurants or shops on a map, closest first, with estimated times |
| Customer app | Order screen: kitchen, door and rider with the route while a rider is on the delivery, arrival time marked "live traffic" or "estimate" |
| Rider app | Navigate to pickup or drop-off opens Google Maps turn-by-turn. Positions are sent only while online, and precise only on a delivery |
| Website | Checkout address search with "use my current location", pin preview, coverage and "delivery priced on a X km road trip"; order page live map |
| Partner dashboard | Settings → **Kitchen location**: move the pin by address search, address check, edit the street line |
| Command Centre | Riders → **Live riders** for Lagos or Enugu: live position only on a delivery, about 1 km areas otherwise, plus today's Google request count |
| Yummy | "Restaurants near me", "what can reach me in 30 minutes", "which of these is faster" |

## 1. Enable the APIs (owner, in the Google Cloud console or gcloud)

Use the same GCP project as the rest of Yummy Chops. Billing must be enabled.

```bash
gcloud services enable places.googleapis.com geocoding-backend.googleapis.com routes.googleapis.com --project <PROJECT_ID>
```

For map tiles in the apps and websites (optional; schematic maps work without them), also enable:

```bash
gcloud services enable maps-android-backend.googleapis.com maps-ios-backend.googleapis.com maps-backend.googleapis.com --project <PROJECT_ID>
```

## 2. Create the keys (Console → Google Maps Platform → Keys & Credentials)

| Key | API restrictions | Application restriction | Where it lives |
|---|---|---|---|
| **Server** | Places API (New), Geocoding API, Routes API | None on Cloud Run (no fixed outbound IP). If you add Cloud NAT with a static IP, restrict to that IP | Secret Manager `google-maps-server-key` → env `GOOGLE_MAPS_API_KEY` on gudmeal-api only |
| **Android** (customer app) | Maps SDK for Android | Package `com.yummy247.app` + SHA-1 of the release and debug signing certificates | `mobile/customer/android/local.properties` (`MAPS_API_KEY=…`, git-ignored) or env `MAPS_API_KEY` in CI |
| **iOS** (customer app) | Maps SDK for iOS | The customer app's bundle ID | `mobile/customer/ios/Flutter/Secrets.xcconfig` (copy `Secrets.xcconfig.example`; git-ignored) or CI secret |
| **Browser** | Maps JavaScript API | Website referrers: `https://yummy247.com/*`, `https://*.yummy247.com/*`, `http://localhost:*/*` (dev key only) | Websites: `NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY` at build time. App web build: `--dart-define=MAPS_BROWSER_KEY=…` |

The rider app needs no Maps key: navigation opens the Google Maps app.


Rules:

- **Never commit any key.** The repository is public. Restricted app and browser keys are visible inside the
  shipped apps by design; their restrictions are what protect them.
- The server key must never appear in an app, a website, logs or tickets. The API never logs it, and its errors
  leave it out.
- Use separate keys for development and production. Rotate a key immediately if it leaks.

### Server key in Secret Manager and Cloud Run

```bash
printf '%s' 'PASTE_KEY_HERE' | gcloud secrets versions add google-maps-server-key --data-file=- --project <PROJECT_ID>
```

The bootstrap script creates the empty `google-maps-server-key` secret, and `gudmeal-api` can already read
secrets. The next deploy binds it as `GOOGLE_MAPS_API_KEY` (`infra/scripts/deploy.sh` checks that the secret has
a value). Don't add it with `gcloud run services update`: every deploy replaces the secret bindings.

For local testing with a real key, put `GOOGLE_MAPS_API_KEY=…` in `services/api/.env`. That file is
git-ignored. Every call is billable, so ask the owner first.

### Turning on map tiles (optional)

Everything works without these: maps are schematic previews of the same data. To show Google tiles:

- **Customer app on Android/iOS:**
  1. Add the Android key to `mobile/customer/android/local.properties` as `MAPS_API_KEY=…`.
  2. Add the iOS key to `mobile/customer/ios/Flutter/Secrets.xcconfig`.
  3. Build with `--dart-define=MAPS_ENABLED=true`.

  The manifest and AppDelegate read the key from the build config; no key is in the source.
- **Customer app web build:** `flutter build web --dart-define=MAPS_ENABLED=true --dart-define=MAPS_BROWSER_KEY=…`.
  The Maps script loads only when a key is given. If it fails, the schematic map stays.
- **Websites** (customer site, partner dashboard, Command Centre): set `NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY`
  when building.

Address search, distances, fees and arrival times never need these keys: they always go through the API.

## 3. Settings (gudmeal-api)

| Variable | Default | Meaning |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | unset | Server key. Unset means the labelled estimates described above |
| `MAPS_TRAVEL_MODE` | `DRIVE` | `DRIVE` or `TWO_WHEELER` (motorbike routing where Google supports it in Nigeria; test before switching) |
| `MAPS_TRAFFIC_AWARE` | `true` | Traffic-aware routes give better Lagos ETAs at Google's **Pro** Routes rate; `false` uses the cheaper **Essentials** rate |
| `MAPS_ROUTES_ENABLED` | `true` | `false` never calls the Routes API; places still work |
| `MAPS_LIVE_ETA_REFRESH_SECONDS` | `180` | How often a live delivery's arrival time may be re-measured. In between it counts down locally |
| `MAPS_DAILY_REQUEST_CAP` | `20000` | Per API instance per Lagos day. Above it the API falls back to estimates and logs `maps daily request cap reached` |
| `MAPS_TIMEOUT_SECONDS` | `4` | A slower Google answer falls back to the estimate for that request |

`GET /v1/admin/maps/status` shows the provider, routes mode, traffic setting, requests today and the cap.

## 4. Quotas, budget and alerts (before turning the key on)

1. **Budget:** Billing → Budgets & alerts → a monthly budget for the project with alerts at 50 %, 90 % and 100 %,
   sent to the owner.
2. **Quotas** (APIs & Services → each API → Quotas). Starting caps per day:

   | API | Daily cap |
   |---|---|
   | Autocomplete | 3,000 requests |
   | Place Details | 1,000 |
   | Geocoding | 1,000 |
   | Compute Routes | 3,000 |
   | Route Matrix | 2,000 elements |

   Raise them as orders grow. Quotas are the hard stop; the API's own cap is a second guard.
3. Watch Google Maps Platform → Metrics weekly in the first month.

## 5. Cost model (approximate, check before enabling)

**These figures are Google's public list prices as shown when this was written, for the global price list.**
Check <https://mapsplatform.google.com/pricing/> and <https://developers.google.com/maps/billing-and-pricing/pricing>
before relying on them.

Each SKU has a free monthly allowance:

| Tier | Free calls per SKU per month |
|---|---|
| Essentials | 10,000 |
| Pro | 5,000 |
| Enterprise | 1,000 |

| What | SKU | List price after the free allowance |
|---|---|---|
| Autocomplete keystroke requests | Autocomplete Requests | about $2.83 per 1,000 (the first 12 requests in a session are billed, later ones are free) |
| Choosing a suggestion | Place Details Essentials | about $5 per 1,000 |
| Reverse geocode / address check | Geocoding | about $5 per 1,000 |
| Quote route, live arrival time | Compute Routes Essentials / **Pro** (traffic-aware) | about $5 / **$10** per 1,000 |
| Kitchen comparison | Compute Route Matrix (per element = kitchens × addresses) | Essentials or Pro per element; see the pricing page |

What Yummy Chops does per action, with the defaults:

| Action | Google calls |
|---|---|
| New address search (debounced, about 4 keystrokes + 1 pick) | about 4 Autocomplete + 1 Place Details |
| Saved address reused | none |
| Quote | 1 Compute Routes (cached 5 minutes for re-quotes) |
| Order | none (reuses the quote's route) |
| Live delivery, about 30 minutes | about 10–12 Compute Routes (one every 3 minutes, plus pickup) |
| Yummy "near me" | 1 matrix call, up to 10 elements |
| Restaurant lists and maps | none (they use the free local estimate) |

Rough total: **about 12–15 Routes calls per delivered order plus about 5 Places calls per new address.**

- At a few hundred orders a month this stays inside the free allowances.
- Beyond the free allowances, with traffic-aware routing, budget roughly $0.12–$0.15 per order for routes.
  About half of that with `MAPS_TRAFFIC_AWARE=false`, or by raising `MAPS_LIVE_ETA_REFRESH_SECONDS`.

## 6. Privacy rules (enforced by the API)

- Rider pings are refused while the rider is offline. The rider app also stops sending when they go offline.
- An idle online rider is stored only as an area of about 1 km, never a precise trail.
- The precise rider position and route line exist only while that rider is on an active delivery. Only that
  order's customer (and operations staff) can read them, and they are cleared when the delivery ends.
- Customer addresses are only sent to Google as search text or a pin, never with names or phone numbers.
- Google content caching follows the Service Specific Terms:
  - place IDs are kept;
  - Places coordinates are not cached longer than 30 days (our caches: 24 hours for places, 5 minutes for
    routes);
  - saved addresses hold the customer's confirmed pin.
- **Legal review of the current terms is still required before launch.**

## 7. Testing

- Unit and integration tests never call Google. They use recorded fake responses (`tests/unit/test_maps.py`,
  `tests/integration/test_maps_api.py`) and the keyless fallback. Agent tests check that Yummy only repeats API
  numbers (`services/agents/tests/test_location_tools.py`).
- **Smoke test with a real key** (owner approval needed, it is billable):
  1. Set the key in `services/api/.env` and start the API.
  2. As a signed-in user, call `/v1/places/autocomplete?q=Admiralty&session=test1`, then
     `/v1/places/details?place_id=…&session=test1`.
  3. Get a quote for a Lekki address.
  4. Check that `route_source` is `google` and `/v1/admin/maps/status` counts the calls.

## 8. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Results still say "estimate" | Key not set on this service, daily cap reached, or Google errors (see API logs: `maps request failed`) |
| `REQUEST_DENIED` / `PERMISSION_DENIED` in logs | API not enabled, or the key's API restrictions don't include it |
| `OVER_QUERY_LIMIT` / `RESOURCE_EXHAUSTED` | A GCP quota was reached. Raise it or wait for the reset |
| Map area is blank on a phone | App key missing or the package/SHA-1 restriction doesn't match the build |
| Map area is blank on the web | Browser key missing or the site isn't in the referrer list |
