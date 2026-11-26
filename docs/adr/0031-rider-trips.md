# ADR-0031: One rider trip for a mixed cart, planned by the quickest route

- **Status:** Accepted
- **Date:** 2026-11-25
- **Context owner:** owner, 2026-11-25: "plan the trip for the rider … fastest route possible (the rider has to go
  get the customer's goods from the restaurant, pharmacy, shop, market etc.) … from accepting the order to going to
  pick them and finally delivery to the customer. In the rider dashboard … the phone number of that particular
  shop/pharmacy/restaurant he is going to (the list of the places to get those items too in case it's a mixed order)."

## Context

ADR-0030 lets a customer pay once for a cart from several shops: one order per shop. Each order was then dispatched
on its own, so three shops meant up to three riders arriving at one door, each with a different delivery code. The
rider app showed one order at a time, with the shop's address but not its phone number.

## Decision

1. **Orders paid together are one trip.** `POST /v1/checkouts` with several orders gives them a shared `trip_id`.
2. **One offer, one rider.** Dispatch offers the trip as one job: the offer lists every place to collect from (in
   the planned order) and pays the sum of the orders' rider pay. When a rider accepts, every order of the trip that
   is ready for a rider is assigned to them; an order whose shop accepts later joins that rider's trip without a new
   offer (the rider is notified). While one order of a trip has an open offer, the others wait for it. A trip counts
   once against the rider's limit of active jobs. Each order still has its own status, rider pay, settlement and
   refund.
3. **The planned route.** `GET /v1/rider/trip` returns each active trip as stops: the shops still to visit in the
   order that makes rider → shops → customer quickest (every order is tried for up to 8 shops; more use the nearest
   next shop), then the customer. Each pickup has the shop's phone (branch manager, else shop, else business), what
   to collect, its order code and whether it is ready; the drop-off has the customer's name, address, phone,
   instructions and any cash to collect. Each remaining leg has its km and minutes (Google road times with traffic
   when the server has them, else estimates), and `navigation_url` opens the whole route in Google Maps (shops as
   waypoints, the customer as destination; bicycle riders get a cycling route).
4. **One delivery code** for all orders of a trip: the customer reads one code to the rider.
5. Rider order views carry `restaurant_phone` (only while the job is in progress) and `trip_id`.
6. The rider app's dashboard shows a trip offer's pickups and total pay; the trip screen shows the steps from
   accepting to delivering, with Call/WhatsApp for each place, "Picked up" per shop, one code field and "Delivered".

## Consequences

- No new tables or money rules: trips are a field on orders and offers; the ledger is unchanged.
- The stop order is planned with road estimates (cheap, no Maps calls per permutation); the times the rider sees for
  each leg are measured when Google is configured. The turn-by-turn route itself comes from Google Maps on the phone.
- A trip from many shops can exceed the usual two active jobs for one rider; that is intended, since it is one door.
- End-to-end journey `mixed_cart_one_payment` now checks one offer, one rider, the planned stops with phones, one code.
- Audit of 2026-11-26: wrong delivery codes count across the whole trip (orders sharing a code share the tries and
  the lock), and a correct code does not use up the rider's tries; a rider who declined or let a trip offer run out
  is not offered its other orders; an order the rider hands back goes to another rider; the rider's cash limit counts
  every cash order of the trip; an order called off while the trip offer is out frees the rest of the trip for a new
  offer; only orders going to the same door (within 100 m) become one trip; the rider's trip is read from the
  orders themselves, so it always matches the delivery list.
