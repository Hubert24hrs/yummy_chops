# Pilot simulation

Run on 2026-11-22 at 19:36 with `services/api/scripts/pilot_sim.py --orders 30 --minutes 8 --seed 11`, on a separate copy of the local API (port 8010), so the phone test was not touched. Re-running the script rewrites this page.

## The pilot that was simulated

- **Area:** Lekki Phase 1. Customers live within 2.5 km of its centre; half the parcels go to Victoria Island.
- **Shops:** the nearest demo shop of each kind: Kiln & Crust Pizza (Order Food, 0.9 km); Oniru Grill House (Order Food, 2.8 km); FreshBasket Supermarket (Shop & Groceries, 0.3 km); CareFirst Pharmacy (Pharmacy, 2.1 km); Lekki Market Shopper (Buy Foodstuff, 0.9 km).
- **Riders:** 5. Demo riders 2 to 4, plus 2 new people who signed up, applied to ride and were approved by an admin at the start of the run.
- **Customers:** 12, ordering at random: 30 orders in about 8 minutes (about one every 16 s), about 1 in 10 a parcel. Customers wanted to pay by card (50%), wallet (20%) or cash on delivery (30%).
- **Business rules:** the production defaults. Offers run out after 45 s; a rider who missed an offer is asked again only after 5 minutes; dispatch first looks 6 km around the pickup; riders stop getting cash jobs at ₦50,000 held; pay on delivery needs one completed prepaid order first and is capped at ₦25,000.
- **Stand-ins for people:** the shops are the local autopilot (accepts after about 12 s, packed 30 s later), and the riders are simulated: they ride 30 times faster than real life and leave 1 offer in 10 to run out.

## Results

- **Delivered: 30 of 30.** Not delivered: none.
- **Paid by:** card 18, wallet 9, cash on delivery 3.
- **Wanted cash but paid by card:** 1 of 4 (Pay on delivery unlocks after your first order).
- **Orders that could not be placed:** 0.
- **Server errors in the API log:** 0.

## Time for each step

Median · 90% of orders within · slowest.

| Step | Time | What it measures |
|---|---|---|
| Shop accepts the order | 14 s · 16 s · 16 s | stand-in: the autopilot accepts after about 12 s |
| A rider takes the job | 2 s · 18 s · 38 s | real: offers, offers that run out, the next rider (counted from the shop accepting; parcels from payment) |
| Shop packs it | 32 s · 33 s · 33 s | stand-in: the autopilot marks it ready 30 s after accepting |
| Rider waits at the counter | 24 s · 28 s · 30 s | follows from the packing time and how fast the rider got there |
| Ride to the customer | 10 s · 21 s · 28 s | 30 times faster than real life |
| Whole order, paid to delivered | 56 s · 69 s · 77 s | all of the above together |

## Offers to riders

- Offers sent: 30 for 30 orders.
- Left to run out on purpose (a rider looking away): 0.
- Already gone when the rider pressed accept: 0.

## Riders

| Rider | Deliveries | Earned | Cash collected, handed in at the end |
|---|---|---|---|
| rider2 (demo-rider-2) | 6 | ₦5,054 | ₦0 |
| rider3 (demo-rider-3) | 5 | ₦3,740 | ₦0 |
| rider4 (demo-rider-4) | 5 | ₦2,738 | ₦5,604 |
| rider5 (Lq5W99yIHlXFQZGiqjcvbQtbxkGu) | 9 | ₦6,259 | ₦11,765 |
| rider6 (htolwlQUtc07E3R5rqjmbDccI6N7) | 5 | ₦3,226 | ₦10,032 |

## Shops

| Shop | Service | Orders | Delivered | Products sold | Shop earns | Commission |
|---|---|---|---|---|---|---|
| Kiln & Crust Pizza | Order Food | 9 | 9 | ₦88,300 | ₦75,055 | ₦13,245 |
| Oniru Grill House | Order Food | 8 | 8 | ₦216,500 | ₦184,025 | ₦32,475 |
| FreshBasket Supermarket | Shop & Groceries | 3 | 3 | ₦47,200 | ₦40,120 | ₦7,080 |
| CareFirst Pharmacy | Pharmacy | 4 | 4 | ₦30,800 | ₦26,180 | ₦4,620 |
| Lekki Market Shopper | Buy Foodstuff | 1 | 1 | ₦1,100 | ₦935 | ₦165 |
| Package Delivery | Package Delivery | 5 | 5 | ₦0 | ₦0 | ₦0 |

## Money

- Customers paid ₦437,365 in all; delivered orders ₦437,365.
- Riders earned ₦21,016.
- Riders collected ₦27,401 in cash; finance recorded each rider handing it in, and every rider now holds ₦0.
- Ledger: debits ₦1,053,730, credits ₦1,053,730 before the cash was handed in, debits ₦1,081,131, credits ₦1,081,131 after: **balanced**.

## Problems met

- None.

## Every order

| Order | Service | Shop | Paid by | Rider | Paid to delivered | Status |
|---|---|---|---|---|---|---|
| KQMM2J | Pharmacy | CareFirst Pharmacy | card | rider5 | 67 s | completed |
| RWB4R2 | Order Food | Kiln & Crust Pizza | card | rider6 | 61 s | completed |
| DMJTHV | Order Food | Oniru Grill House | card | rider3 | 54 s | completed |
| FG624Z | Order Food | Oniru Grill House | card | rider3 | 50 s | completed |
| G7PGFG | Order Food | Oniru Grill House | card | rider2 | 57 s | completed |
| YN778B | Order Food | Kiln & Crust Pizza | wallet | rider4 | 51 s | completed |
| SBHXHF | Order Food | Kiln & Crust Pizza | cash | rider5 | 52 s | completed |
| 2CVQJW | Order Food | Kiln & Crust Pizza | wallet | rider5 | 59 s | completed |
| V9U8MK | Shop & Groceries | FreshBasket Supermarket | card | rider4 | 53 s | completed |
| RNCJSR | Order Food | Oniru Grill House | card | rider3 | 67 s | completed |
| VHWZX9 | Order Food | Kiln & Crust Pizza | cash | rider4 | 56 s | completed |
| FX9A2U | Order Food | Oniru Grill House | wallet | rider5 | 64 s | completed |
| NHYGF8 | Package Delivery | Package Delivery | wallet | rider2 | 34 s | completed |
| 4FCGMC | Order Food | Kiln & Crust Pizza | card | rider3 | 55 s | completed |
| E47PHF | Order Food | Kiln & Crust Pizza | card | rider5 | 60 s | completed |
| M25WZU | Order Food | Kiln & Crust Pizza | wallet | rider5 | 70 s | completed |
| YSRASG | Package Delivery | Package Delivery | card | rider3 | 25 s | completed |
| SKTUBH | Order Food | Oniru Grill House | card | rider2 | 69 s | completed |
| 2FPB47 | Order Food | Oniru Grill House | wallet | rider4 | 54 s | completed |
| FBCV3G | Pharmacy | CareFirst Pharmacy | wallet | rider2 | 54 s | completed |
| CXSXWS | Package Delivery | Package Delivery | card | rider6 | 8 s | completed |
| 6XN8YZ | Shop & Groceries | FreshBasket Supermarket | wallet | rider5 | 53 s | completed |
| 7GTRG5 | Pharmacy | CareFirst Pharmacy | card | rider2 | 62 s | completed |
| 7DFA5K | Pharmacy | CareFirst Pharmacy | card | rider4 | 50 s | completed |
| 6W9Y4Y | Order Food | Oniru Grill House | card | rider2 | 69 s | completed |
| U3Z4GF | Package Delivery | Package Delivery | card | rider6 | 15 s | completed |
| WWGVMA | Buy Foodstuff | Lekki Market Shopper | wallet | rider6 | 60 s | completed |
| XVVQ6V | Order Food | Kiln & Crust Pizza | cash | rider6 | 77 s | completed |
| ZTCUCF | Shop & Groceries | FreshBasket Supermarket | card | rider5 | 59 s | completed |
| DTYQ7T | Package Delivery | Package Delivery | card | rider5 | 10 s | completed |

The run took 11.1 min on the clock.
