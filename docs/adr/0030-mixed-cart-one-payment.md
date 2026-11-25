# ADR-0030: One cart for every shop, one order per shop, one payment

- **Status:** Accepted
- **Date:** 2026-11-25
- **Context owner:** owner's phone test of 2026-11-25: adding a pharmacy item while the cart held a beauty shop's
  items showed "Start a new cart? Your cart has items from Shea Harbour Skin Bar. Keep cart / New cart". The owner
  asked for one cart for items from any shop and any service, to be taken to the cart after adding, to remove items
  there before paying, and for the phone field to say just "Phone number".

## Context

A cart held one shop's items. In the API an order belongs to one shop: one quote, one kitchen or shop that accepts
it, one rider, one delivery fee, one settlement. A payment (`payment_records`) paid one order; a group order's
shares (ADR-0009) are several payments for one order — the opposite of what a mixed cart needs.

## Decision

1. **One cart, grouped by shop.** The customer app and the website keep items from any number of shops in one cart
   (each item remembers its shop). Adding never asks to start a new cart; the item sheet says **Add to cart · ₦…** and
   takes the customer to the cart, which lists the items under each shop's name with − / + and a remove button.
2. **One order per shop.** "Review total" asks for one quote per shop (same address and delivery/pickup), so each shop's
   order has its own delivery fee, service fee and VAT from `domain/pricing.py`. The cart shows each shop's total and
   the **Total to pay**. A voucher goes with the first shop's order. Placing the cart creates one order per quote.
3. **One payment: `POST /v1/checkouts {order_ids, provider}`.** For a card it starts ONE gateway checkout for the sum
   (a `basket` payment whose `covers` lists each order and its amount; not split, so each shop is paid in its
   settlement). When the gateway confirms it, every order gets its own succeeded payment — its **share**, with
   `parent_id` pointing at the basket — and its own ledger posting and `payment.succeeded` event, in the same
   transaction. From there each order is exactly an order paid on its own: sent to its shop, dispatched, delivered,
   refunded and settled by itself. The basket posts nothing to the ledger, so nothing is counted twice and the
   ledger stays balanced. The wallet pays the whole cart in one debit (the balance must cover all of it); cash places
   each order as pay on delivery (checked one by one). One order in the list is an ordinary checkout.
4. **Refunds per order.** A share is refunded like any order payment; the gateway is asked to refund that amount from
   the one charge it knows (the basket's reference and transaction id), and Paystack's refund events are matched to
   the share. A share paid after its order was cancelled is refunded automatically, as for any orphaned payment.
5. **Schema:** migration 0005 adds `payment_records.covers` and `parent_id` and the purpose `basket` (local SQLite
   test databases are now `gudmeal_local_v5.db`). The online server gets it with the next deploy's `alembic upgrade
   head`.

## Consequences

- A cart from three shops has three delivery fees; the cart shows them before the customer pays. One rider collects
  all three in one trip (ADR-0031).
- Orders list shows each shop's order on its own; the receipt is per order.
- A mixed-cart card payment is never split to a business's subaccount (ADR-0028): those shops are paid in their
  settlement, as before splits existed. Single-shop carts still split.
- The end-to-end check has a journey `mixed_cart_one_payment` (a meal, a pharmacy item and a beauty item, one item
  removed, paid once, each order delivered).
