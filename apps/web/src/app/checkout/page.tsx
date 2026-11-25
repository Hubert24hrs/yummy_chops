"use client";

import { ApiError, formatNaira, formatTime, idempotentCalls, isMeasured, type DeliveryAddress, type Fulfillment, type PlaceLookup, type Quote } from "@gudmeal/api-client";
import { AddressSearch, Button, Card, EmptyState, ErrorState, Field, Input, MapView, Price, Select, Skeleton, cn } from "@gudmeal/ui";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Bike, ShieldCheck, Store } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { checkoutProvider, continueAfterCheckout, PaymentMethodPicker, type PayMethod } from "@/components/payment-method";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { toCartLines, useCart } from "@/lib/cart";
import { AREAS, CITY_NAMES, useLocation } from "@/lib/location";
import { GOOGLE_MAPS_BROWSER_KEY } from "@/lib/maps";

/** `value` once it has stopped changing for `ms`: typing asks for one price, not one for every letter. */
function useSettled<T>(value: T, ms = 500): T {
  const [settled, setSettled] = useState(value);
  const key = JSON.stringify(value);
  useEffect(() => {
    const timer = window.setTimeout(() => setSettled(value), ms);
    return () => window.clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- `key` is `value` as text: the same text is the same value
  }, [key, ms]);
  return settled;
}

export default function CheckoutPage() {
  return (
    <RequireAuth reason="Sign in to place your order and track it live.">
      <Checkout />
    </RequireAuth>
  );
}

function Checkout() {
  const api = useApi();
  const { cart, clear } = useCart();
  const { area } = useLocation();
  const [fulfillment, setFulfillment] = useState<Fulfillment>("delivery");
  const [addressId, setAddressId] = useState<string>("new");
  const [line1, setLine1] = useState("");
  /** The area chosen in the list. Until the customer chooses one, it is their delivery area (Lagos or Enugu). */
  const [areaChoice, setAreaChoice] = useState<string | null>(null);
  const areaName = areaChoice ?? area.name;
  /** Exact place from address search or "use my location"; without it the neighbourhood centre is used. */
  const [picked, setPicked] = useState<PlaceLookup | null>(null);
  const [phone, setPhone] = useState("");
  const [instructions, setInstructions] = useState("");
  const [voucher, setVoucher] = useState("");
  const [appliedVoucher, setAppliedVoucher] = useState<string | null>(null);
  const [method, setMethod] = useState<PayMethod>("card");
  const router = useRouter();
  const [sendOrder] = useState(() => idempotentCalls("order"));
  const [sendCheckout] = useState(() => idempotentCalls("checkout"));
  // The street and the instructions are part of the quote (the order takes its address from it), so the price is
  // asked for again when they change: once typing stops, because the API allows about one quote every two seconds.
  const { street, notes } = useSettled({ street: line1.trim(), notes: instructions.trim() });
  const typing = street !== line1.trim() || notes !== instructions.trim();

  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });
  const myVouchers = useQuery({ queryKey: ["my-vouchers"], queryFn: () => api.rewards.vouchers() });
  useEffect(() => {
    if (addresses.data?.length && addressId === "new") setAddressId(addresses.data[0]!.id);
  }, [addresses.data, addressId]);

  const address: DeliveryAddress | null = useMemo(() => {
    if (fulfillment === "pickup") return null;
    const saved = addresses.data?.find((a) => a.id === addressId);
    if (saved) return saved;
    if (street.length < 3) return null;
    // The rider's phone number is not here: it does not change the price, and the order gets it when it is placed.
    if (picked) {
      const city = picked.place.city === "enugu" ? CITY_NAMES.enugu : CITY_NAMES.lagos;
      return {
        line1: street, area: picked.place.area ?? areaName, city, state: city, location: picked.place.location,
        place_id: picked.place.place_id, instructions: notes || null,
      };
    }
    const a = AREAS.find((x) => x.name === areaName) ?? area;
    const city = CITY_NAMES[a.city];
    return { line1: street, area: a.name, city, state: city, location: a.location, instructions: notes || null };
  }, [fulfillment, addresses.data, addressId, street, areaName, area, notes, picked]);

  function onPicked(found: PlaceLookup) {
    setPicked(found);
    if (found.place.precision === "rooftop" || found.place.precision === "street") setLine1(found.place.formatted_address);
    if (found.place.area && AREAS.some((a) => a.name === found.place.area)) setAreaChoice(found.place.area);
  }

  const quoteReady = cart.items.length > 0 && cart.restaurant_id && (fulfillment === "pickup" || address);
  const quote = useQuery({
    queryKey: ["quote", cart, fulfillment, address, appliedVoucher],
    enabled: Boolean(quoteReady),
    queryFn: () => api.orders.quote({
      restaurant_id: cart.restaurant_id!, lines: toCartLines(cart), fulfillment,
      delivery_address: address, voucher_code: appliedVoucher,
    }),
    retry: false,
  });

  const placeOrder = useMutation({
    mutationFn: async (q: Quote) => {
      const contact = phone || undefined;
      if (addressId === "new" && address && fulfillment === "delivery") {
        await api.me.addAddress({ ...address, contact_phone: contact ?? null, label: "Saved at checkout" }).catch(() => undefined);
      }
      // Each request keeps its key only until the API answers it: a new quote, phone number or payment method is a
      // new request, and so is trying again after a refusal. Asking twice for one quote gives the same order.
      const order = await sendOrder({ quote: q.id, contact }, (key) => api.orders.create(q.id, key, "web", contact));
      const provider = checkoutProvider(method);
      return sendCheckout({ order: order.id, provider }, (key) => api.orders.checkout(order.id, key, provider));
    },
    onSuccess: (res) => {
      clear();
      continueAfterCheckout(res, router.push);
    },
    onError: (e) => {
      // The price is no longer valid: get a new one, so the next press of the button can go through.
      if (e instanceof ApiError && (e.code === "quote_expired" || e.code === "price_changed")) void quote.refetch();
    },
  });

  if (!cart.items.length) {
    return (
      <div className="container-page py-16">
        <EmptyState title="Your cart is empty" body="Pick a restaurant and add something delicious."
          action={<Link href="/restaurants"><Button>Browse restaurants</Button></Link>} />
      </div>
    );
  }

  const voucherError = quote.error instanceof ApiError && quote.error.code === "voucher_invalid" ? quote.error.message : null;

  return (
    <div className="container-page grid gap-8 py-8 lg:grid-cols-[1fr_400px]">
      <div className="space-y-6">
        <h1 className="font-display text-3xl">Checkout</h1>
        <Card className="space-y-4 p-5">
          <h2 className="font-semibold">How would you like it?</h2>
          <div className="grid grid-cols-2 gap-3" role="radiogroup" aria-label="Fulfilment">
            {([["delivery", "Delivery", Bike], ["pickup", "Pickup", Store]] as const).map(([value, label, Icon]) => (
              <button key={value} role="radio" aria-checked={fulfillment === value} onClick={() => setFulfillment(value)}
                className={cn("flex items-center gap-2 rounded-md border p-3 text-sm font-semibold",
                  fulfillment === value ? "border-primary bg-primary-soft" : "border-border")}>
                <Icon className="size-5" aria-hidden="true" /> {label}
              </button>
            ))}
          </div>
        </Card>

        {fulfillment === "delivery" && (
          <Card className="space-y-4 p-5">
            <h2 className="font-semibold">Delivery address</h2>
            {addresses.isLoading ? <Skeleton className="h-11" /> : (
              <Field label="Address" htmlFor="addr">
                <Select id="addr" value={addressId} onChange={(e) => setAddressId(e.target.value)}>
                  {addresses.data?.map((a) => <option key={a.id} value={a.id}>{a.label ? `${a.label} — ` : ""}{a.line1}, {a.area}</option>)}
                  <option value="new">+ New address</option>
                </Select>
              </Field>
            )}
            {addressId === "new" && (
              <div className="space-y-3">
                <AddressSearch
                  search={(q, session) => api.places.suggestions(q, session, area.location, area.city).then((r) => r.suggestions)}
                  details={(placeId, session) => api.places.details(placeId, session)}
                  reverse={(point) => api.places.reverse(point)}
                  onPicked={onPicked}
                />
                {picked && (
                  <div className="space-y-2">
                    <MapView height={180} pins={[{ point: picked.place.location, kind: "home", label: picked.place.area ?? "Your address" }]} googleKey={GOOGLE_MAPS_BROWSER_KEY} />
                    <p className={cn("text-sm font-semibold", picked.serviceable ? "text-secondary" : "text-danger")} role="status">
                      {picked.serviceable ? "Yummy Chops delivers here." : "This address is outside our delivery area for now."}
                      {picked.place.precision !== "rooftop" && picked.place.precision !== "street" && (
                        <span className="block font-normal text-muted">Add your street, house number and a landmark below so the rider can find you.</span>
                      )}
                    </p>
                    <button type="button" className="text-sm text-muted underline-offset-2 hover:underline" onClick={() => setPicked(null)}>
                      Clear and choose an area instead
                    </button>
                  </div>
                )}
              </div>
            )}
            {addressId === "new" && (
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Street address" htmlFor="line1">
                  <Input id="line1" value={line1} onChange={(e) => setLine1(e.target.value)} placeholder="12 Admiralty Way" autoComplete="street-address" />
                </Field>
                {!picked && (
                  <Field label="Area" htmlFor="area">
                    <Select id="area" value={areaName} onChange={(e) => setAreaChoice(e.target.value)}>
                      {(["lagos", "enugu"] as const).map((city) => (
                        <optgroup key={city} label={CITY_NAMES[city]}>
                          {AREAS.filter((a) => a.city === city).map((a) => <option key={a.name}>{a.name}</option>)}
                        </optgroup>
                      ))}
                    </Select>
                  </Field>
                )}
                <Field label="Phone for the rider" htmlFor="phone">
                  <Input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="0803 000 0000" inputMode="tel" autoComplete="tel" />
                </Field>
                <Field label="Delivery instructions" htmlFor="ins">
                  <Input id="ins" value={instructions} onChange={(e) => setInstructions(e.target.value)} placeholder="Gate code, landmark…" />
                </Field>
              </div>
            )}
          </Card>
        )}

        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Payment</h2>
          <PaymentMethodPicker totalKobo={quote.data?.breakdown.total_kobo ?? null} value={method} onChange={setMethod}
            cash={{ offered: true, reason: fulfillment === "pickup" ? "Only for delivery orders" : null }} />
        </Card>

        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Voucher</h2>
          <form className="flex gap-2" onSubmit={(e) => { e.preventDefault(); setAppliedVoucher(voucher.trim().toUpperCase() || null); }}>
            <label htmlFor="voucher" className="sr-only">Voucher code</label>
            <Input id="voucher" value={voucher} onChange={(e) => setVoucher(e.target.value)} placeholder="e.g. WELCOME500" className="uppercase" />
            <Button type="submit" variant="outline">Apply</Button>
          </form>
          {(myVouchers.data?.length ?? 0) > 0 && (
            <div className="flex flex-wrap gap-2" aria-label="Your vouchers">
              {myVouchers.data!.map((v) => (
                <button key={v.code} type="button" onClick={() => { setVoucher(v.code); setAppliedVoucher(v.code); }}
                  className={cn("rounded-full border px-3 py-1.5 text-xs font-bold", appliedVoucher === v.code ? "border-primary bg-primary-soft" : "border-border")}>
                  {formatNaira(v.value_kobo)} off · {v.code}
                </button>
              ))}
            </div>
          )}
          {voucherError && <p className="text-sm text-danger" role="alert">{voucherError}</p>}
          {appliedVoucher && quote.data?.breakdown.voucher_code && <p className="text-sm text-secondary">Voucher {appliedVoucher} applied.</p>}
        </Card>
      </div>

      <aside className="lg:sticky lg:top-24 lg:self-start">
        <Card className="space-y-4 p-5">
          <div>
            <h2 className="font-display text-xl">{cart.restaurant_name}</h2>
            <p className="text-sm text-muted">{cart.items.reduce((n, i) => n + i.quantity, 0)} items</p>
          </div>
          <ul className="space-y-2 text-sm">
            {(quote.data?.lines ?? []).map((ln) => (
              <li key={ln.item_id + ln.selection_labels.join()} className="flex justify-between gap-3">
                <span>{ln.quantity} × {ln.name}{ln.selection_labels.length > 0 && <span className="block text-xs text-muted">{ln.selection_labels.join(" · ")}</span>}</span>
                <Price kobo={ln.line_total_kobo} />
              </li>
            ))}
          </ul>
          {!quoteReady ? (
            <p className="text-sm text-muted">Add a delivery address to see your total.</p>
          ) : quote.isLoading ? (
            <Skeleton className="h-32" />
          ) : quote.error && !voucherError ? (
            <ErrorState message={(quote.error as Error).message} onRetry={() => quote.refetch()} />
          ) : quote.data ? (
            <Breakdown quote={quote.data} />
          ) : null}
          {placeOrder.error && <ErrorState message={(placeOrder.error as Error).message} />}
          <Button block size="lg" disabled={!quote.data || typing || placeOrder.isPending} loading={placeOrder.isPending}
            onClick={() => quote.data && placeOrder.mutate(quote.data)}>
            {method === "cash"
              ? `Place order · pay ${quote.data ? formatNaira(quote.data.breakdown.total_kobo) : ""} on delivery`
              : `Pay ${quote.data ? formatNaira(quote.data.breakdown.total_kobo) : ""}${method === "wallet" ? " from wallet" : ""}`}
          </Button>
          <p className="flex items-start gap-2 text-xs text-muted">
            <ShieldCheck className="mt-0.5 size-4 shrink-0 text-secondary" aria-hidden="true" />
            {method === "card" && "You'll pay on a secure payment page. Your order is sent to the kitchen once we verify the payment."}
            {method === "wallet" && "Paid instantly from your Yummy Chops wallet. If the order is cancelled, the money goes straight back."}
            {method === "cash" && "Your order goes to the kitchen now. Pay the rider in cash when it arrives, then share your delivery code."}
          </p>
        </Card>
      </aside>
    </div>
  );
}

function Breakdown({ quote }: { quote: Quote }) {
  const b = quote.breakdown;
  const rows: [string, number][] = [
    ["Subtotal", b.subtotal_kobo],
    ...(b.delivery_fee_kobo ? [["Delivery", b.delivery_fee_kobo] as [string, number]] : []),
    ["Service fee", b.service_fee_kobo],
    ...(b.small_order_fee_kobo ? [["Small order fee", b.small_order_fee_kobo] as [string, number]] : []),
    ["VAT (7.5% on fees)", b.vat_kobo],
  ];
  return (
    <dl className="space-y-1.5 border-t border-border pt-3 text-sm">
      {rows.map(([label, value]) => (
        <div key={label} className="flex justify-between"><dt className="text-muted">{label}</dt><dd><Price kobo={value} /></dd></div>
      ))}
      {b.discount_kobo > 0 && (
        <div className="flex justify-between text-secondary"><dt>Discount</dt><dd>-<Price kobo={b.discount_kobo} /></dd></div>
      )}
      {(b.plus_savings_kobo ?? 0) > 0 && (
        <div className="flex justify-between font-semibold text-secondary"><dt>Yummy Chops Plus saved you</dt><dd><Price kobo={b.plus_savings_kobo} /></dd></div>
      )}
      <div className="flex justify-between border-t border-border pt-2 text-base font-bold">
        <dt>Total</dt><dd><Price kobo={b.total_kobo} /></dd>
      </div>
      {quote.fulfillment === "delivery" && quote.road_distance_km ? (
        <p className="pt-1 text-xs text-muted">
          Delivery priced on a {quote.road_distance_km.toFixed(1)} km road trip{isMeasured(quote.route_source) ? " (measured with live traffic)" : " (estimate)"}.
        </p>
      ) : null}
      <p className="pt-1 text-xs text-muted">
        {quote.fulfillment === "delivery" ? `Estimated arrival ${formatTime(quote.estimated_delivery_at)}` : `Ready in about ${quote.eta_minutes} min`}
        {" · "}price held until {formatTime(quote.expires_at)}
      </p>
      {!b.plus_savings_kobo && b.delivery_fee_kobo > 0 && (
        <Link href="/plus" className="block pt-1 text-xs font-bold text-primary underline-offset-2 hover:underline">Get free delivery with Yummy Chops Plus →</Link>
      )}
    </dl>
  );
}
