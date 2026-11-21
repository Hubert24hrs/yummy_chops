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
- [ ] **Test on your phone** and tell me what breaks.
  QR code page: https://claude.ai/artifact/G8H3KNWTrxetV8iwS7z5Kg. To start the test servers again after a restart,
  see [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md), section 6.
- [ ] **Create a Google Cloud and Firebase project with billing, and get Paystack test keys.** Then I deploy a
  staging version that works anywhere, not just on your Wi-Fi.
- [ ] **Add a Gemini key for Yummy and a Google Maps key** for real addresses and routes.
- [ ] **Line up a pilot:** 3–5 restaurants and 5 riders in one area, for example Lekki.
- [ ] **Confirm the prices set as defaults** (Plus at ₦1,500 for 30 days, fees, points), and arrange the legal
  reviews (privacy notice, wallet, terms).
- [ ] **Open Google Play and Apple developer accounts.** The Android apps now use the Yummy Chops pin from your
  logo as their icon (17 Nov). The store listings and the iPhone app need a bigger picture: send the original
  logo file (SVG, or a PNG at least 1024 pixels wide per symbol).
- [ ] **WhatsApp ordering is still off.** When you're ready, it needs a Meta business account, verification and
  approval of Meta's message charges.
- [ ] **Decide three things for Pharmacy, Shop & Groceries and Buy Foodstuff** (back on 21 Nov with your names,
  [ADR-0025](adr/0025-six-services.md)): the Plus minimum basket for supermarkets and market shoppers (now the
  same ₦3,000 as food), the commission for these shops (now the platform default), and a legal review of selling
  over-the-counter medicines and supplements online (NAFDAC registration, no health claims) before real pharmacies
  join, including how the team checks each pharmacy's PCN premises licence.
