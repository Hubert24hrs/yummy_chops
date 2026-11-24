# ADR-0029: The owner's new logo (Yummy247, with the chef) and app icon (a chef's hat with "yc")

- **Status:** Accepted. It replaces the icons and cut-outs of [ADR-0022](0022-brand.md); that ADR's colours and its
  rule (everything is cut from the owner's pictures, never redrawn) stay.
- **Date:** 2026-11-24
- **Context owner:** owner's request of 2026-11-24 with two pictures: "use the first reference image as the business
  logo and the second as the app icon", for the entire platform (the phone apps and the websites).

## Decision

1. **Two masters** in `assets/brand`:
   - `yummychops-logo.webp`, the logo (1080 px square): the chef in her kitchen under an arch with the "Yummy Chops"
     ribbon, the name "Yummy247" (dark brown "Yummy", red "247"), a red swoosh, "Good Food. Great Mood.", a rider
     on a scooter and three badges. It replaces the chef's-hat-on-a-cloche logo, which stays in git history;
   - `yummychops-app-icon.png`, the app icon (1190 px square): a white chef's hat with a green "yc" and a yellow
     sparkle, on red (`#CF0C12`).
2. **Where each goes** (`scripts/make-brand-assets.py`):
   - the whole logo: the sign-in screens of both apps and the three websites, the Android launch screen and link
     previews;
   - the emblem (the chef under her arch, with the ribbon) beside the name "Yummy247": website headers, the partner
     dashboard and the Command Centre. On a dark page "Yummy" turns cream; "247" stays red;
   - the app icon: Android launcher icons, the iOS icon sets, the apps' browser builds (tab, install and maskable
     icons) and the websites' tab and home-screen icons. The phone install page shows each app's launcher icon.
     Where a platform cuts icons with a mask (Android launchers keep a 66dp circle of the 108dp layer, maskable web
     icons the middle 80%), the drawing is scaled to stay inside it, sparkle included; elsewhere it keeps the owner's
     framing.
   - The rider app's icon is the same drawing on chocolate brown (`#3A0D05`) instead of red, so the two apps can be
     told apart on one phone, as the owner chose in ADR-0022.
   - The rider-on-the-scooter cut-out is no longer used anywhere and was removed.
3. **Lifting the red off the icon's drawing**: each pixel gets the least opacity that explains it as the drawing's
   colour over the red (allowing for the 8 levels the red varies by), so soft edges keep their true colour (the
   hat's edge stays white, not pink) on the brown, and put back on the red it is the owner's icon again.
4. **The names**: the headers read "Yummy247" because that is the name the new logo shows; the ribbon above it says
   "Yummy Chops". App names, page titles and messages still say "Yummy Chops" ([ADR-0023](0023-yummy-chops.md)).

## Consequences

- Phones show the new icons after the next build and install of the test apps.
- The icon master is 1190 px, enough for the store listings (Google Play asks for 512 px, the App Store for 1024 px).
- The design tokens stay as they are: the new pictures use the same palette (dark brown, red, orange) plus the
  icon's green and yellow.
- If the owner prefers "Yummy Chops" in the headers, the ribbon's lettering is too small to cut out; the name would
  come from the old logo's lettering or from text.
