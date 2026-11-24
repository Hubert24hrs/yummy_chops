# ADR-0028: Businesses with branches, one menu, and split card payments

- **Status:** Accepted
- **Date:** 2026-11-24
- **Context owner:** owner's spec of 2026-11-24, "Business partnership (Restaurants etc) and the way they should
  operate": register a business with its name, phone number, email and address, plus more branch addresses; signed in,
  a dashboard to add or edit branch addresses and update each branch manager's phone number; a unique ID for the
  business; every item it uploads tagged with that ID "to ensure accuracy during split order payments"; a "Payment
  received" notification from Paystack for each order; on the dashboard the order, the assigned rider with their phone
  number and arrival minutes, and **Confirm Order** once the split payment is in; the status changes to **Order picked
  up** when the rider has it. Asked, the owner chose to split card payments at checkout (Paystack sends the business's
  share to its bank account when the customer pays) and one menu for all branches, with customers ordering from the
  nearest branch.

## Context

Every shop was one `Restaurant` with one address. A business with several outlets had to apply once per outlet and
keep a menu for each. Shops were paid weekly from the ledger (settlements). The sign-up form asked for a bank name, an
account name and the account's last four digits, which was not enough to pay anyone automatically.

Paystack can split a card payment between the main account and a **subaccount** (a business's bank account registered
with Paystack): each payment says how much the main account keeps (`transaction_charge`) and who pays Paystack's fee
(`bearer`).

## Decision

1. **A business has a unique ID**, `YCB-` and six characters from an alphabet without 0/O and 1/I, so it can be read
   out over the phone. The business (`Business`: name, owner, phone, email, main branch, bank account) is created when
   the team approves a business application, or when the owner of an existing shop presses **Get my business ID** on
   the partner dashboard's new **Business** page.
2. **Each branch is a shop of its own**: a `Restaurant` with its own address and pin, opening hours, order board,
   staff and a manager's phone number, plus `business_id`, `branch_name` and `menu_restaurant_id` (the main branch).
   - **One menu.** Every branch sells the main branch's menu (`Restaurant.menu_id`); a dish added from any branch goes
     on that one menu.
   - **The nearest branch.** Customers see one card per business: the branch nearest to them that is open, and the
     order goes to that branch (`one_branch_each` in the catalogue).
   - A new branch stays hidden until its owner switches on **Accepting orders** in that branch's dashboard. It must be
     in one of our delivery zones (its address is picked from the address search) and belongs to that zone's city.
     After that, its address and pin change only through the kitchen location checks every shop has (Settings,
     Kitchen location: the pin near the address, bigger moves checked by Yummy Chops). A business has at most 30
     branches.
3. **Items carry the business ID** (`MenuItem.business_id`), set when the business is created and on every new item.
4. **Sign-up** (the website's `/partner-with-us` and the customer app's **Register your business**): the kind of
   business, business name, phone number, email, the owner's name, the main address and area, any number of branch
   addresses (**Add another branch**), the CAC number, what it sells and, for pharmacies, the PCN premises licence.
   Bank details are no longer asked at sign-up.
5. **The bank account is connected in the partner dashboard** (Business page): the bank from Paystack's list and the
   10-digit account number. The API checks the account name with Paystack (`/bank/resolve`), then creates or updates
   the business's Paystack subaccount. It keeps only the bank's name, the account name and the last four digits; the
   subaccount code never goes to the browser.
6. **Card payments are split at checkout.** When the order's business has a subaccount and the customer pays through
   Paystack's checkout, the payment carries the subaccount, `transaction_charge` = the order total minus the
   business's share (its earning, from `domain/pricing.py`), and `bearer: "account"`, so Yummy Chops pays Paystack's
   fee and the business gets exactly its share, in its bank account on Paystack's settlement schedule. Businesses
   without a connected account, cash on delivery, the wallet and Flutterwave keep the weekly payout.
7. **The ledger** (append-only, balanced): at capture, `split_settled` debits `liability:restaurant:{id}` and credits
   `cash:{provider}` by the share, because that money never reaches Yummy Chops' balance. The shop has been paid
   ahead, so its balance is minus the share until the order completes and `order_completed` credits its earning, which
   brings it back to zero. If the order is refunded before it completes, the customer's refund comes from Yummy Chops
   and the shop owes its share, which comes out of its next payout. The payment record keeps `split_subaccount` and
   `split_amount_kobo` (migration 0004).
8. **Payment received.** When a paid order reaches the shop, the shop is told **Payment received** ("Your ₦X is on its
   way to your bank account (Paystack)" when the payment was split); a cash order is a **New order**. Online the
   payment is confirmed by Paystack's webhook or the verify call; locally by the verify call, as webhooks cannot reach
   a laptop.
9. **The order board** shows Payment received or Cash on delivery, the shop's earning and where it goes, and
   **Confirm order** (it was Accept). Once a rider is assigned it shows who is coming (with the Verified badge from
   ADR-0027), their phone number and about how many minutes away they are; a new **Picked up** column keeps the order
   until it is delivered. The minutes come from the platform's own travel estimate (road factor and average speed
   from the pricing configuration, no paid Google call) and only from a rider location newer than dispatch trusts
   (3 minutes); without one, no time is shown. The shop never sees where the rider is.
10. **The Command Centre** shows each shop's business ID and branch on the Restaurants page, a Businesses table
    (branches, how many take orders, whether split payments are on) and, on applications, the branch addresses a
    business signed up with (`GET /v1/admin/businesses`).

## Consequences

- **Paystack must allow subaccounts.** In test mode Paystack answered "Sorry, We cannot add subaccount at the moment":
  subaccounts need the Paystack business to be activated. Until then connecting a bank account shows that message and
  the business keeps the weekly payout. Nothing else changes.
- **Refunds of split orders** come from Yummy Chops' Paystack balance; the shop's share is recovered from its next
  payout. A shop that stops selling while it owes money needs a finance procedure (collection).
- **One menu means one availability**: marking a dish sold out hides it at every branch. Per-branch availability is a
  follow-up if branches ask for it.
- A branch starts with the main branch's opening hours and settings; each branch changes its own in its dashboard.
- The owner's sign-in token lists the shops they manage, so the dashboard refreshes it after adding a branch.

## Alternatives considered

- **A menu per branch**: more work for every business and not what the owner chose.
- **Weekly payouts only**: simpler books, but the owner wants businesses paid when the customer pays.
- **Keeping full account numbers** to pay businesses ourselves: Paystack holds them instead; we keep the last four
  digits.
