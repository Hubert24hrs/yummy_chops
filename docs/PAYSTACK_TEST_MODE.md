# Testing payments with Paystack test mode

The phone test normally pays on a pretend payment page (the local payment sandbox). In Paystack test mode, card
payments go through Paystack's real payment page instead, in **test mode**: nothing is charged and no real money moves.
It runs on this computer, for phones on the same Wi-Fi.

## Start it

- In the Claude app, start the preview server **`phone-test-paystack`** instead of `phone-test`. They use the same
  ports, so only one runs at a time. From a terminal: `node scripts/dev.mjs auth api agents downloads --lan --seed --paystack`.
- It needs the git-ignored file `.env.paystack` in the repository folder with one line,
  `PAYSTACK_SECRET_KEY=sk_test_...`. Copy the key from the Paystack dashboard (Settings → API Keys & Webhooks,
  with the dashboard in Test mode). Only a test key is accepted; a live key is refused. The key never goes to GitHub.
- The test apps already on the phone work as they are: nothing to rebuild or reinstall.

## Pay on the phone

1. Order as usual and choose **Card, bank transfer or USSD**. Wallet top-ups and Plus use the same page.
2. Paystack's page opens with a **TEST** label. Under **Card**, pick an option and press **Pay**:
   - **Success**: the payment goes through.
   - **Bank Authentication**: Paystack first asks you to confirm with your bank. Press **Authenticate** and
     its test bank page opens in a new window, as happens with cards that need a bank code.
   - **Declined**: the card is refused. The order stays unpaid. **Retry with test details** lets you pay again.
3. After paying, the phone shows **Payment approved**. Go back to the app: it asks the server to check the
   payment with Paystack and updates the order. The server never trusts the page alone.

Every test payment shows in the Paystack dashboard, in Test mode, under Transactions.

## What was tested (23 Nov 2026)

All of these used real Paystack test-mode transactions, and Paystack's own records matched:

| What | Result |
|---|---|
| Food order, ₦17,720 by test card | Paid, accepted and packed by the shop, delivered with the customer's code, completed; rider earnings recorded |
| Declined card, then **Retry** with Success | Marked failed and left unpaid; the retry on the same page paid the order |
| Wallet top-up, ₦5,000 | The wallet went up by exactly ₦5,000 |
| Plus, ₦1,500 | The customer became a Plus member |
| Package Delivery, ₦2,150 by test card | Paid, collected and delivered by the rider, completed |
| Partial refund, ₦2,000 back to the card | Accepted by Paystack ("pending" there); "processing" in Yummy Chops (see below) |
| Money records | Debits equal credits after every step |

Not tried yet: **Bank Authentication** (its bank page opens in a pop-up, which the laptop's test browser blocks)
and the **Transfer**, **Bank** and **USSD** tabs. Try those on the phone.

## What does not work on this computer

- **Businesses can't connect a bank account yet** ([ADR-0028](adr/0028-business-branches-and-split-payments.md)).
  The partner dashboard's Business page checks the account with Paystack, then asks Paystack to add it as a
  subaccount, and Paystack answers "Sorry, We cannot add subaccount at the moment" until the Paystack business is
  activated. Card payments for these businesses are not split; they are paid weekly. To try split payments, use
  `phone-test`: without a Paystack key it lists pretend banks and accepts any 10-digit account number.

- **Paystack's webhooks can't reach a laptop.** Payments still work, because the app and the return page ask
  Paystack directly. But a refund back to a card stays "processing" in Yummy Chops even after Paystack completes
  it. The online test server receives the webhooks. Customers who switched on instant refunds to their wallet
  get their refunds at once.
- **The automatic end-to-end check** (`services/api/scripts/e2e_local.py`) approves card payments on the pretend
  page, so run it against `phone-test`, not `phone-test-paystack`.
- **Demo accounts end in `@yummychops.test`**, an address Paystack refuses. For these, and for customers without
  an email, Yummy Chops gives Paystack `<account id>@customers.yummy247.com` instead.
