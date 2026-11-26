# ADR-0032: Guest mode in the customer app; sign-in only in Profile

- **Status:** Accepted
- **Date:** 2026-11-26
- **Context owner:** owner, 2026-11-26: "remove the login feature seen on the order section and every other section
  except the profile; in the profile the customer should be able to log in using Google/Apple account, GPS (map
  location address), fingerprint". Asked, the owner chose a quiet guest account (Anonymous sign-in turned on in the
  online Firebase project), an Apple button hidden until Apple sign-in is set up, and "GPS" as saving the home
  address from the phone's location.

## Decision

1. **Guest first.** When nobody is signed in, the customer app signs in an anonymous Firebase user by itself. Orders,
   checkout, wallet, Yummy and the rest work with that guest; no screen outside Profile asks to sign in. The API
   needs no change: it accepts any Firebase ID token, and payments use an address on our own domain when the payer
   has no email.
2. **Profile saves the account.** A guest sees "Save your account" with Continue with Google (and Continue with Apple
   when the app is built with `APPLE_SIGN_IN=true` and Apple is set up in Firebase). This links the provider to the
   guest, so the same account keeps its orders, wallet and addresses. If that Google/Apple account already exists,
   the app signs in to it instead (the cart stays on the phone; guest orders stay with the guest). Email and phone
   sign-in stay under "Other ways to sign in" for staff and testers.
3. **Home address by GPS:** "Use my location" in Profile saves the phone's position (shown on the map) as Home.
4. **Fingerprint:** a saved account can turn on "Unlock with fingerprint" (or the phone PIN); the app then asks when
   it opens and after more than 5 minutes in the background.

## Consequences

- Guest accounts pile up in Firebase (no personal data); a clean-up of old unused guests can come later.
- A guest who reinstalls the app loses their guest orders unless they saved the account with Google/Apple first.
- The customer website works the same way (guest first; Google/Apple and the GPS home address on the account page;
  no fingerprint in browsers). Rider and partner sign-up pages ask a guest to save the account first, since that
  account becomes their Rider or Partner app login.
- Apple sign-in needs an Apple Developer account (Services ID, key) before the button is switched on.
