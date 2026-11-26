# ADR-0033: City-wide delivery, nearest goods first, phone required, faster payment, native Google sign-in

- **Status:** Accepted
- **Date:** 2026-11-26
- **Context owner:** owner's phone test of 2026-11-26 on the online test server (a guest ordering from three shops).

## Problems found and decisions

1. **"This shop does not deliver to this address."** Each shop had a delivery radius (8–12 km). Decision: every shop
   delivers anywhere in its own city (Lagos, Enugu); its radius only matters outside the cities we serve. Motorcycle
   and car riders take jobs up to 60 km so such orders still find a rider. The delivery fee keeps its ₦4,000 cap for
   usual distances but is never less than the rider's pay for the trip (past about 25 km), so a long city-wide
   delivery never costs Yummy Chops money.
2. **Goods nearest the customer first.** Search results list goods from open shops nearest the customer first (each
   with `distance_km`), then the best match; shop lists put open shops in order of distance (half-kilometre steps,
   then featured and rating).
3. **Payment felt very slow.** The server answered in about a second, but Paystack's webhook does not reach it yet,
   so the app only checked the payment when the customer came back from the payment page. The app now opens the
   payment page inside the app, checks every 2 seconds while it is open, and closes it as soon as the payment is
   confirmed; the website's return page checks straight away and keeps checking for a minute. (Setting the test
   webhook URL `https://<api-url>/v1/webhooks/paystack` in the Paystack dashboard makes it instant on the server too.)
4. **Orders looked empty after paying.** The app kept an old empty list. Orders now refresh when the tab is shown,
   when the app comes back, after checkout, every 10 seconds while an order is in progress, and on pull-to-refresh;
   the website refetches on focus and every 10 seconds while an order is in progress.
5. **The rider had no phone number for the customer.** A guest has no phone on their account. A delivery order now
   needs a phone number (the API refuses one without it); checkout asks for it, prefills it and remembers it.
6. **Google sign-in showed "Unable to process request due to missing initial state".** That is Firebase's browser
   sign-in page losing its storage in the phone's browser. Phones now use Android's own Google account picker
   (`google_sign_in`, Credential Manager) with the project's web client ID (`GOOGLE_WEB_CLIENT_ID`), so no browser
   page opens.
7. The profile no longer says "You're ordering as a guest".
