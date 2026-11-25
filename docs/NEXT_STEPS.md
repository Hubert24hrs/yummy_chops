# Yummy Chops: what to do next so we can start

Saved on 17 Nov 2026 to do later. Tick each one off as you go.

- [x] **Domain, websites and email (20 Nov).** yummy247.com is yours (Namecheap). The customer website is at
  https://yummy247.com (www goes there too), the partner dashboard at https://partner.yummy247.com and the
  Command Centre at https://admin.yummy247.com, all on Vercel's free Hobby plan. The mailbox
  customercare@yummy247.com is on Zoho Mail's Forever Free plan: read it at https://mail.zoho.com or in the
  Zoho Mail phone app. Details: [DEPLOYMENT.md](DEPLOYMENT.md), sections 5a and 5b.
- [ ] **Send the first test email yourself** from customercare@yummy247.com to your Gmail, and reply to it, to
  check that mail goes both ways.
- [ ] **Turn on two-step sign-in** on Namecheap, Vercel, Zoho and GitHub. Whoever gets into one of these
  accounts controls the websites or the mail.
- [ ] **Before Yummy Chops starts trading, move Vercel to Pro** ($20 per month). Vercel allows the free Hobby
  plan only for personal, non-commercial use.
- [ ] **The websites open, but they can't show shops, sign anyone in or take orders yet.** That needs the next
  step: the Google Cloud and Firebase project, so the API and Yummy can run at api.yummy247.com and
  assistant.yummy247.com.
- [ ] **Test on your phone** and tell me what breaks. To pay through Paystack's test mode instead of the pretend
  payment page, start `phone-test-paystack` ([PAYSTACK_TEST_MODE.md](PAYSTACK_TEST_MODE.md); tested 23 Nov).
  QR code page: https://claude.ai/artifact/G8H3KNWTrxetV8iwS7z5Kg. To start the test servers again after a restart,
  see [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md), section 6.
- [ ] **Activate your Paystack business** so businesses can connect their bank accounts and get their share of
  each card payment straight away ([ADR-0028](adr/0028-business-branches-and-split-payments.md)). In test mode
  Paystack refused to add their accounts ("Sorry, We cannot add subaccount at the moment"). Until then businesses
  are paid weekly, as before. On the `phone-test` server, which has no Paystack key, the whole flow works with
  pretend banks.
- [ ] **Create a Google Cloud and Firebase project with billing, and get Paystack test keys.** Then I deploy a
  staging version that works anywhere, not just on your Wi-Fi.
- [x] **Gemini key for Yummy (22 Nov).** A Google AI Studio key, for testing only. It lives in the git-ignored
  `services/agents/.env`.
- [x] **Yummy runs on Vertex AI (25 Nov).** On the online test server Gemini (`gemini-3.5-flash`) is billed to the
  Google Cloud project, keeps customers' chats out of Google's product improvement and needs no key; production
  refuses an AI Studio key. The AI Studio key's prepaid credit ran out on 25 Nov, so Yummy on this computer answers in
  its rule-based mode until it is topped up (or deleted, if you no longer need AI answers in the phone test).
- [ ] **Add a Google Maps key** for real addresses and routes.
- [ ] **Line up a pilot:** 3–5 restaurants and 5 riders in one area, for example Lekki. Simulated on 22 Nov with
  pretend shops, riders and customers: 30 of 30 orders delivered, no server errors and the money balanced
  ([PILOT_SIMULATION.md](PILOT_SIMULATION.md)).
- [ ] **Confirm the prices set as defaults** (Plus at ₦1,500 for 30 days, fees, points), and arrange the legal
  reviews (privacy notice, wallet, terms).
- [ ] **Open Google Play and Apple developer accounts.** The apps now use your new red chef's-hat icon and the
  Yummy247 logo (24 Nov, [ADR-0029](adr/0029-new-logo-and-app-icon.md)); the icon picture is 1190 pixels, big
  enough for both stores' listings.
- [ ] **WhatsApp ordering is still off.** When you're ready, it needs a Meta business account, verification and
  approval of Meta's message charges.
- [x] **Plus minimum basket** for supermarkets and market shoppers: **₦3,000**, the same as food (decided 22 Nov).
- [ ] **Two more things for Pharmacy, Shop & Groceries and Buy Foodstuff** ([ADR-0025](adr/0025-six-services.md)): the
  commission for these shops (now the platform default), and a legal review of selling over-the-counter medicines
  and supplements online (NAFDAC registration, no health claims) before real pharmacies join, including how the team
  checks each pharmacy's PCN premises licence.
