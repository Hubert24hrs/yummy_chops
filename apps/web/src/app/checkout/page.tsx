"use client";

import {
  ApiError, formatDateTime, formatNaira, formatTime, idempotentCalls, isMeasured,
  type CheckoutResult, type DeliveryAddress, type Fulfillment, type GeoPoint, type MultiCheckoutResult, type PlaceLookup, type Quote,
} from "@gudmeal/api-client";
import { AddressSearch, Button, EmptyState, ErrorState, Field, Input, MapView, Price, Select, Skeleton, Textarea, cn } from "@gudmeal/ui";
import { useMutation, useQueries, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Bike, ChevronDown, ChevronLeft, ChevronRight, Crown, MapPin, MapPinned, MessageSquareText, Pencil, PiggyBank, ShieldCheck,
  Smartphone, Store, TicketPercent, TriangleAlert, WheatOff,
} from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, type ReactNode } from "react";
import { cartSummary } from "@/components/cart-parts";
import { checkoutProvider, continueAfterCheckout, PaymentMethodPicker, type PayMethod } from "@/components/payment-method";
import { RequireAuth } from "@/components/require-auth";
import { Sheet } from "@/components/sheet";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { normaliseNigerianPhone, phoneProblem, rememberedPhone, rememberPhone } from "@/lib/contact-phone";
import { toCartLines, useCart, withAllergies } from "@/lib/cart";
import { AREAS, CITY_NAMES, kmBetween, useLocation } from "@/lib/location";
import { GOOGLE_MAPS_BROWSER_KEY } from "@/lib/maps";

/** The most orders (shops) one payment can cover (`POST /v1/checkouts`). */
const MAX_SHOPS_PER_PAYMENT = 10;
/** A line's note holds at most 200 characters (API); the allergy note leaves room for "Allergies: ". */
const ALLERGIES_MAX = 180;
/** An address this far from where the customer is now gets a second look before paying. */
const FAR_KM = 1;
const MIN_SCHEDULE_MS = 30 * 60_000;
const MAX_SCHEDULE_MS = 7 * 24 * 60 * 60_000;

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

/** A `datetime-local` value (the browser's own time) `ms` from now, rounded up to the next quarter hour. */
function localInput(ms: number): string {
  const d = new Date(Date.now() + ms);
  d.setSeconds(0, 0);
  d.setMinutes(Math.ceil(d.getMinutes() / 15) * 15);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** Where the browser says the customer is, only when they have already allowed it: never asks just for this. */
function useCurrentPlace(): GeoPoint | null {
  const [here, setHere] = useState<GeoPoint | null>(null);
  useEffect(() => {
    let gone = false;
    const perms = typeof navigator !== "undefined" ? navigator.permissions : undefined;
    if (!perms?.query || !navigator.geolocation) return;
    perms.query({ name: "geolocation" as PermissionName }).then((status) => {
      if (gone || status.state !== "granted") return;
      navigator.geolocation.getCurrentPosition(
        (p) => { if (!gone) setHere({ lat: p.coords.latitude, lng: p.coords.longitude }); },
        () => undefined, { maximumAge: 300_000, timeout: 10_000 },
      );
    }).catch(() => undefined);
    return () => { gone = true; };
  }, []);
  return here;
}

export default function CheckoutPage() {
  return (
    <RequireAuth>
      <Checkout />
    </RequireAuth>
  );
}

type SheetName = "allergies" | "address" | "instructions" | "phone" | "far";

function Checkout() {
  const api = useApi();
  const { shops, clear, ready } = useCart();
  const { area } = useLocation();
  const [fulfillment, setFulfillment] = useState<Fulfillment>("delivery");
  const [addressId, setAddressId] = useState<string>("new");
  const [line1, setLine1] = useState("");
  /** The area chosen in the list. Until the customer chooses one, it is their delivery area (Lagos or Enugu). */
  const [areaChoice, setAreaChoice] = useState<string | null>(null);
  const areaName = areaChoice ?? area.name;
  /** Exact place from address search or "use my location"; without it the neighbourhood centre is used. */
  const [picked, setPicked] = useState<PlaceLookup | null>(null);
  /** The number the rider calls, as typed: required for delivery. Filled in until the customer types one. */
  const [phone, setPhone] = useState("");
  const [phoneTyped, setPhoneTyped] = useState(false);
  const contactPhone = normaliseNigerianPhone(phone);
  const { user } = useAuth();
  const qc = useQueryClient();
  const [instructions, setInstructions] = useState("");
  const [allergies, setAllergies] = useState("");
  const [voucher, setVoucher] = useState("");
  const [appliedVoucher, setAppliedVoucher] = useState<string | null>(null);
  const [promoOpen, setPromoOpen] = useState(false);
  const [method, setMethod] = useState<PayMethod>("card");
  const [when, setWhen] = useState<"now" | "later">("now");
  const [at, setAt] = useState("");
  const [optionsOpen, setOptionsOpen] = useState(false);
  const [sheet, setSheet] = useState<SheetName | null>(null);
  const here = useCurrentPlace();
  const router = useRouter();
  // One sender per quote: each shop's order is its own request with its own key (see `idempotentCalls`).
  const [orderSenders] = useState(() => new Map<string, ReturnType<typeof idempotentCalls>>());
  const sendOrder = (quoteId: string) => {
    let send = orderSenders.get(quoteId);
    if (!send) orderSenders.set(quoteId, (send = idempotentCalls("order")));
    return send;
  };
  const [sendCheckout] = useState(() => idempotentCalls("checkout"));
  // The street, the instructions and the allergy note are part of the quote (the order takes its address and lines
  // from it), so the price is asked for again when they change: once typing stops, because the API allows about one
  // quote every two seconds. Quantities changed on the cart page are settled the same way.
  const basket = shops.map((sh) => ({ restaurant_id: sh.restaurant_id, lines: withAllergies(toCartLines(sh.items), allergies) }));
  // The phone number is on the delivery address of the quote too, settled the same way.
  const { street, notes, priced, contact } = useSettled({ street: line1.trim(), notes: instructions.trim(), priced: basket, contact: contactPhone });
  const typing = street !== line1.trim() || notes !== instructions.trim() || JSON.stringify(priced) !== JSON.stringify(basket)
    || contact !== contactPhone;

  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });
  const myVouchers = useQuery({ queryKey: ["my-vouchers"], queryFn: () => api.rewards.vouchers() });
  const plus = useQuery({ queryKey: ["plus"], queryFn: () => api.plus.get(), retry: false });

  function chooseAddress(id: string) {
    setAddressId(id);
    const saved = addresses.data?.find((a) => a.id === id);
    setInstructions(saved?.instructions ?? "");
  }
  useEffect(() => {
    if (addresses.data?.length && addressId === "new") chooseAddress(addresses.data[0]!.id);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- once the saved addresses arrive
  }, [addresses.data]);
  // Until the customer types a number: the chosen address's, the one used last time in this browser, the Home
  // address's, or the account's.
  useEffect(() => {
    if (phoneTyped || phone.trim()) return;
    const chosen = addresses.data?.find((a) => a.id === addressId);
    const home = addresses.data?.find((a) => (a.label ?? "").trim().toLowerCase() === "home");
    const found = chosen?.contact_phone || rememberedPhone() || home?.contact_phone || user?.phoneNumber;
    if (found) setPhone(found);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- when the addresses or the choice change
  }, [addresses.data, addressId, user, phoneTyped]);

  const address: DeliveryAddress | null = useMemo(() => {
    if (fulfillment === "pickup") return null;
    // The rider's phone number goes on the address (and with the order when it is placed).
    const phoneOn = contact ? { contact_phone: contact } : {};
    const saved = addresses.data?.find((a) => a.id === addressId);
    if (saved) return { ...saved, instructions: notes || null, ...phoneOn };
    if (street.length < 3) return null;
    if (picked) {
      const city = picked.place.city === "enugu" ? CITY_NAMES.enugu : CITY_NAMES.lagos;
      return {
        line1: street, area: picked.place.area ?? areaName, city, state: city, location: picked.place.location,
        place_id: picked.place.place_id, instructions: notes || null, ...phoneOn,
      };
    }
    const a = AREAS.find((x) => x.name === areaName) ?? area;
    const city = CITY_NAMES[a.city];
    return { line1: street, area: a.name, city, state: city, location: a.location, instructions: notes || null, ...phoneOn };
  }, [fulfillment, addresses.data, addressId, street, areaName, area, notes, picked, contact]);
  const savedAddress = addresses.data?.find((a) => a.id === addressId);
  const far = Boolean(fulfillment === "delivery" && address && here && kmBetween(here, address.location) > FAR_KM);

  function onPicked(found: PlaceLookup) {
    setPicked(found);
    if (found.place.precision === "rooftop" || found.place.precision === "street") setLine1(found.place.formatted_address);
    if (found.place.area && AREAS.some((a) => a.name === found.place.area)) setAreaChoice(found.place.area);
  }

  // Scheduled orders: 30 minutes to 7 days ahead (the API checks too, and that the shops are open then).
  const atMs = at ? new Date(at).getTime() : NaN;
  const scheduleOk = when === "now" || (Number.isFinite(atMs) && atMs >= Date.now() + MIN_SCHEDULE_MS - 60_000 && atMs <= Date.now() + MAX_SCHEDULE_MS);
  const scheduledFor = when === "later" && scheduleOk ? new Date(atMs).toISOString() : null;

  const quoteReady = priced.length > 0 && (fulfillment === "pickup" || Boolean(address)) && scheduleOk;
  // One quote per shop, same fulfilment, address and time. The voucher goes with the first shop's quote only. The API
  // allows a burst of about 30 quotes, then one every two seconds: a shop is asked again only when its own items change.
  const quotes = useQueries({
    queries: priced.map((shop, i) => {
      const voucher = i === 0 ? appliedVoucher : null;
      return {
        queryKey: ["quote", shop.restaurant_id, shop.lines, fulfillment, address, voucher, scheduledFor],
        enabled: quoteReady,
        queryFn: () => api.orders.quote({
          restaurant_id: shop.restaurant_id, lines: shop.lines, fulfillment, delivery_address: address, voucher_code: voucher,
          scheduled_for: scheduledFor,
        }),
        retry: false,
      };
    }),
  });
  const allQuotes = quoteReady && quotes.length > 0 && quotes.every((q) => q.data) ? quotes.map((q) => q.data!) : null;
  const totalKobo = allQuotes ? allQuotes.reduce((sum, q) => sum + q.breakdown.total_kobo, 0) : null;
  const refetchQuotes = () => quotes.forEach((q) => void q.refetch());
  const tooManyShops = shops.length > MAX_SHOPS_PER_PAYMENT;

  /** Delivery needs a number the rider can call; pickup does not. */
  const missingPhone = fulfillment === "delivery" ? phoneProblem(phone) : null;

  const placeOrder = useMutation({
    mutationFn: async (qs: Quote[]) => {
      const contact = contactPhone ?? undefined;
      if (fulfillment === "delivery" && !contact) throw new Error(phoneProblem(phone) ?? "");
      if (addressId === "new" && address && fulfillment === "delivery") {
        await api.me.addAddress({ ...address, contact_phone: contact ?? null, label: "Saved at checkout" }).catch(() => undefined);
      }
      // Each request keeps its key only until the API answers it: a new quote, phone number or payment method is a
      // new request, and so is trying again after a refusal. Asking twice for one quote gives the same order.
      const ids: string[] = [];
      for (const q of qs) {
        const order = await sendOrder(q.id)({ quote: q.id, contact }, (key) => api.orders.create(q.id, key, "web", contact));
        ids.push(order.id);
      }
      const provider = checkoutProvider(method);
      // Several shops: one payment for all their orders. One shop: that order's own checkout (the same answer).
      return sendCheckout({ orders: ids, provider }, (key): Promise<CheckoutResult | MultiCheckoutResult> =>
        ids.length === 1 ? api.orders.checkout(ids[0]!, key, provider) : api.orders.checkoutMany(ids, key, provider));
    },
    onSuccess: (res) => {
      clear();
      // The new orders are on Orders straight away (an earlier answer is not kept).
      void qc.invalidateQueries({ queryKey: ["orders"] });
      void qc.invalidateQueries({ queryKey: ["order-summary"] });
      if (contactPhone) keepPhone(contactPhone);
      continueAfterCheckout(res, router.push);
    },
    onError: (e) => {
      // The price is no longer valid: get new ones, so the next press of the button can go through.
      if (e instanceof ApiError && (e.code === "quote_expired" || e.code === "price_changed")) refetchQuotes();
    },
  });

  /**
   * The number fills in the next checkout: kept in this browser, and on the saved address the order went to (or the
   * Home address) when that one does not have it yet. Never holds up the order.
   */
  function keepPhone(number: string) {
    rememberPhone(number);
    if (fulfillment !== "delivery") return;
    const target = savedAddress ?? addresses.data?.find((a) => (a.label ?? "").trim().toLowerCase() === "home");
    if (!target || normaliseNigerianPhone(target.contact_phone) === number) return;
    const { id, ...rest } = target;
    void api.request("PUT", `/v1/me/addresses/${id}`, { body: { ...rest, contact_phone: number } })
      .then(() => qc.invalidateQueries({ queryKey: ["addresses"] }), () => undefined);
  }

  if (!ready) {
    return <div className="container-page space-y-3 py-16" aria-busy="true"><Skeleton className="h-10 w-1/2" /><Skeleton className="h-40" /></div>;
  }
  if (!shops.length) {
    return (
      <div className="container-page py-16">
        <EmptyState title="Your cart is empty" body="Pick a restaurant and add something delicious."
          action={<Link href="/restaurants"><Button>Browse restaurants</Button></Link>} />
      </div>
    );
  }

  const firstError = quotes[0]?.error;
  const voucherError = firstError instanceof ApiError && firstError.code === "voucher_invalid" ? firstError.message : null;
  const several = shops.length > 1;
  const summary = cartSummary(shops);
  const eta = allQuotes ? Math.max(...allQuotes.map((q) => q.eta_minutes)) : null;
  const standardText = fulfillment === "pickup"
    ? (eta != null ? `Ready in about ${eta} min` : "As soon as it's ready")
    : (eta != null ? `${eta}–${eta + 10} min` : "As soon as possible");
  const canPay = Boolean(allQuotes) && !typing && !tooManyShops && !missingPhone && !placeOrder.isPending;
  const payLabel = method === "cash"
    ? `Place ${several ? "orders" : "order"}${totalKobo != null ? ` · ${formatNaira(totalKobo)}` : ""}`
    : `Pay to order${totalKobo != null ? ` · ${formatNaira(totalKobo)}` : ""}`;
  const pay = () => { if (allQuotes) placeOrder.mutate(allQuotes); };
  const showPlusBanner = Boolean(plus.data && !plus.data.member && plus.data.plan?.enabled);
  const addressTitle = savedAddress ? (savedAddress.label || savedAddress.line1) : address?.line1;
  const addressLine = savedAddress ? [savedAddress.label ? savedAddress.line1 : null, savedAddress.area].filter(Boolean).join(", ") : address?.area;

  return (
    <div className="mx-auto w-full max-w-6xl px-4 pb-32 md:px-6 lg:grid lg:grid-cols-[minmax(0,1fr)_400px] lg:gap-12 lg:pb-12">
      <div className="mx-auto w-full max-w-2xl">
        <div className="flex h-16 items-center">
          <Link href="/cart" aria-label="Back to cart" className="grid size-11 place-items-center rounded-full bg-surface-muted hover:bg-border">
            <ChevronLeft className="size-5" aria-hidden="true" />
          </Link>
        </div>
        <h1 className="mt-4 font-display text-4xl">Checkout</h1>

        <Link href="/cart" className="mt-6 flex items-center justify-between gap-4 py-2">
          <span>
            <span className="block text-lg font-semibold">Your order</span>
            <span className="block">{summary.products} <strong>{summary.from}</strong></span>
          </span>
          <ChevronRight className="size-5 shrink-0" aria-hidden="true" />
        </Link>

        <div className="mt-4 grid grid-cols-2 gap-1 rounded-full bg-surface-muted p-1" role="radiogroup" aria-label="Fulfilment">
          {([["delivery", "Delivery", Bike], ["pickup", "Pickup", Store]] as const).map(([value, label, Icon]) => (
            <button key={value} type="button" role="radio" aria-checked={fulfillment === value} onClick={() => setFulfillment(value)}
              className={cn("flex h-11 items-center justify-center gap-2 rounded-full text-sm font-semibold transition",
                fulfillment === value ? "bg-surface text-text shadow-sm" : "text-muted hover:text-text")}>
              <Icon className="size-4" aria-hidden="true" /> {label}
            </button>
          ))}
        </div>

        <Row icon={<WheatOff className="size-6" />} title="Any allergies?" subtitle={allergies.trim() || null} onClick={() => setSheet("allergies")} />

        {fulfillment === "delivery" && (
          <section aria-label="Delivery address" className="mt-6">
            <h2 className="font-display text-2xl">Delivery address</h2>
            {addresses.isLoading ? <Skeleton className="mt-4 h-40" /> : address ? (
              <>
                <MapView className="mt-4" height={180} googleKey={GOOGLE_MAPS_BROWSER_KEY}
                  pins={[{ point: address.location, kind: "home", label: addressTitle ?? "Your address" }]} />
                <div className="flex items-center gap-4 py-4">
                  <MapPin className="size-6 shrink-0" aria-hidden="true" />
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold">{addressTitle}</p>
                    {addressLine && <p className="text-sm text-muted">{addressLine}</p>}
                    {far && <p className="text-sm font-semibold text-warning">Far from current location</p>}
                  </div>
                  <button type="button" onClick={() => setSheet("address")} aria-label="Edit address"
                    className="grid size-11 shrink-0 place-items-center rounded-full bg-surface-muted hover:bg-border">
                    <Pencil className="size-5" aria-hidden="true" />
                  </button>
                </div>
              </>
            ) : (
              <Row icon={<MapPinned className="size-6" />} title="Add a delivery address" subtitle="Search, use your location or pick a saved one"
                onClick={() => setSheet("address")} />
            )}
            <Row icon={<MessageSquareText className="size-6" />} title="Instructions for the rider"
              subtitle={instructions.trim() || "Gate code, landmark, floor…"} onClick={() => setSheet("instructions")} />
          </section>
        )}

        <Row icon={<Smartphone className="size-6" />} title="Phone number" subtitle={phone.trim() || "Add your phone number"}
          muted={!phone.trim()} onClick={() => setSheet("phone")} />
        {missingPhone && <p className="-mt-2 text-sm font-semibold text-danger" data-testid="phone-problem">{missingPhone}</p>}

        <section aria-label={fulfillment === "pickup" ? "Pickup time" : "Delivery options"} className="mt-8">
          <h2 className="font-display text-2xl">{fulfillment === "pickup" ? "Pickup time" : "Delivery options"}</h2>
          <div className="mt-4 rounded-2xl border border-border">
            <button type="button" aria-expanded={optionsOpen} onClick={() => setOptionsOpen((o) => !o)}
              className="flex w-full items-center justify-between gap-3 p-4 text-left">
              <span>
                <span className="block font-semibold">{when === "now" ? "Standard" : "Scheduled"}</span>
                <span className="block text-sm text-muted">{when === "now" ? standardText : scheduledFor ? formatDateTime(scheduledFor) : "Choose a time"}</span>
              </span>
              <ChevronDown className={cn("size-5 shrink-0 transition", optionsOpen && "rotate-180")} aria-hidden="true" />
            </button>
            {optionsOpen && (
              <div className="space-y-3 px-4 pb-4">
                <div role="radiogroup" aria-label="When" className="space-y-2">
                  {([["now", "Standard", standardText], ["later", "Schedule", "Pick a time up to 7 days ahead"]] as const).map(([value, label, note]) => (
                    <button key={value} type="button" role="radio" aria-checked={when === value}
                      onClick={() => { setWhen(value); if (value === "later" && !at) setAt(localInput(60 * 60_000)); }}
                      className={cn("flex w-full items-baseline gap-2 rounded-xl border-2 px-4 py-3 text-left",
                        when === value ? "border-text" : "border-border hover:border-muted")}>
                      <span className="font-semibold">{label}</span><span className="text-sm text-muted">{note}</span>
                    </button>
                  ))}
                </div>
                {when === "later" && (
                  <Field label="Date and time" htmlFor="when-at" error={scheduleOk ? undefined : "Choose a time from 30 minutes to 7 days from now"}>
                    <Input id="when-at" type="datetime-local" value={at} onChange={(e) => setAt(e.target.value)}
                      min={localInput(MIN_SCHEDULE_MS)} max={localInput(MAX_SCHEDULE_MS - 15 * 60_000)} />
                  </Field>
                )}
              </div>
            )}
          </div>
        </section>

        <section aria-label="Payment method" className="mt-8">
          <h2 className="font-display text-2xl">Payment method</h2>
          {showPlusBanner && (
            <div className="mt-4 flex items-center gap-4 rounded-2xl bg-primary-soft p-4">
              <span className="grid size-14 shrink-0 place-items-center rounded-xl bg-surface text-primary">
                <Crown className="size-7" aria-hidden="true" />
              </span>
              <span>
                <span className="block">Free delivery with Yummy Chops Plus.</span>
                <Link href="/plus" className="font-bold text-primary underline underline-offset-2">More info</Link>
              </span>
            </div>
          )}
          <div className="mt-2">
            <PaymentMethodPicker variant="rows" totalKobo={totalKobo} value={method} onChange={setMethod}
              cash={{ offered: true, reason: fulfillment === "pickup" ? "Only for delivery orders" : null }} />
          </div>

          <button type="button" aria-expanded={promoOpen} onClick={() => setPromoOpen((o) => !o)}
            className="flex w-full items-center gap-4 border-t border-border py-4 text-left">
            <TicketPercent className="size-6 shrink-0" aria-hidden="true" />
            <span className="flex-1">
              <span className="block font-semibold">Got a promo code?</span>
              {appliedVoucher && quotes[0]?.data?.breakdown.voucher_code && <span className="block text-sm text-success">{appliedVoucher} applied</span>}
            </span>
            <ChevronDown className={cn("size-5 shrink-0 transition", promoOpen && "rotate-180")} aria-hidden="true" />
          </button>
          {promoOpen && (
            <div className="space-y-3 pb-4">
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
              {appliedVoucher && quotes[0]?.data?.breakdown.voucher_code && <p className="text-sm text-success">Voucher {appliedVoucher} applied.</p>}
              {several && <p className="text-xs text-muted">Voucher applies to one shop&apos;s order ({shops[0]!.restaurant_name}).</p>}
            </div>
          )}
        </section>
      </div>

      <aside className="mt-8 lg:sticky lg:top-24 lg:mt-24 lg:self-start">
        <section aria-label="Summary" className="-mx-4 space-y-4 bg-surface-muted px-4 py-6 md:mx-0 md:rounded-3xl md:px-6">
          <h2 className="font-display text-2xl">Summary</h2>
          {several && shops.map((shop, i) => {
            const q = quotes[i];
            const quoteError = q?.error && !(i === 0 && voucherError) ? (q.error as Error).message : null;
            return (
              <section key={shop.restaurant_id} aria-label={`${shop.restaurant_name} order`} className="space-y-2 rounded-2xl bg-surface p-4">
                <div className="flex items-baseline justify-between gap-3">
                  <h3 className="font-semibold">{shop.restaurant_name}</h3>
                  <span className="text-sm text-muted">{shop.count} {shop.count === 1 ? "item" : "items"}</span>
                </div>
                {!quoteReady ? null : !q || q.isLoading ? <Skeleton className="h-20" /> : quoteError ? (
                  <ErrorState message={quoteError} onRetry={() => q.refetch()} />
                ) : q.data ? (
                  <>
                    <Breakdown quotes={[q.data]} compact />
                    <div className="flex justify-between border-t border-border pt-2 text-sm font-bold">
                      <span>Shop total</span><Price kobo={q.data.breakdown.total_kobo} />
                    </div>
                    <QuoteNotes quote={q.data} />
                  </>
                ) : null}
              </section>
            );
          })}

          {!several && quoteReady && quotes[0] && (quotes[0].isLoading ? <Skeleton className="h-28" /> : quotes[0].error && !voucherError ? (
            <ErrorState message={(quotes[0].error as Error).message} onRetry={() => quotes[0]!.refetch()} />
          ) : null)}

          {!quoteReady && (
            <p className="text-sm text-muted">
              {!scheduleOk ? "Choose a time from 30 minutes to 7 days from now to see your total." : "Add a delivery address to see your total."}
            </p>
          )}

          {allQuotes && (
            <>
              <Breakdown quotes={allQuotes} />
              <div className="flex items-baseline justify-between border-t border-border pt-4 text-xl font-bold">
                <span>Total to pay</span><Price kobo={totalKobo} />
              </div>
              {!several && <QuoteNotes quote={allQuotes[0]!} />}
              <Savings quotes={allQuotes} />
            </>
          )}
          {quoteReady && !allQuotes && quotes.some((q) => q.isLoading) && several && <Skeleton className="h-24" />}

          {tooManyShops && (
            <p className="text-sm text-danger" role="alert">
              One payment can cover up to {MAX_SHOPS_PER_PAYMENT} shops. Remove the items of {shops.length - MAX_SHOPS_PER_PAYMENT} {shops.length - MAX_SHOPS_PER_PAYMENT === 1 ? "shop" : "shops"} to continue.
            </p>
          )}
          {placeOrder.error && <ErrorState message={(placeOrder.error as Error).message} />}
          {missingPhone && allQuotes && (
            <button type="button" onClick={() => setSheet("phone")} className="flex w-full items-center gap-2 text-left text-sm font-semibold text-danger">
              <Smartphone className="size-4 shrink-0" aria-hidden="true" /> {missingPhone}
            </button>
          )}
          <p className="flex items-start gap-2 text-xs text-muted">
            <ShieldCheck className="mt-0.5 size-4 shrink-0 text-success" aria-hidden="true" />
            {method === "card" && `You'll pay on a secure payment page. Your ${several ? "orders are" : "order is"} sent once we verify the payment.`}
            {method === "wallet" && `Paid instantly from your Yummy Chops wallet. If ${several ? "an" : "the"} order is cancelled, the money goes straight back.`}
            {method === "cash" && `Your ${several ? "orders go to their shops" : "order goes to the kitchen"} now. Pay the rider in cash when it arrives, then share your delivery code.`}
          </p>
        </section>
        <div className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-surface/95 px-4 py-3 pb-[max(12px,env(safe-area-inset-bottom))] backdrop-blur lg:static lg:mt-4 lg:border-0 lg:bg-transparent lg:p-0">
          <Button block size="lg" className="h-14 text-lg" disabled={!canPay} loading={placeOrder.isPending}
            onClick={() => (far ? setSheet("far") : pay())}>
            {payLabel}
          </Button>
        </div>
      </aside>

      <Sheet open={sheet === "allergies"} onClose={() => setSheet(null)} title="Any allergies?"
        footer={<Button block size="lg" onClick={() => setSheet(null)}>Save</Button>}>
        <Field label="Allergies" htmlFor="allergies" hint={`Every shop in this order sees it with your items. ${allergies.length}/${ALLERGIES_MAX}`}>
          <Textarea id="allergies" value={allergies} maxLength={ALLERGIES_MAX} onChange={(e) => setAllergies(e.target.value)}
            placeholder="e.g. peanuts, shellfish, lactose" />
        </Field>
      </Sheet>

      <Sheet open={sheet === "instructions"} onClose={() => setSheet(null)} title="Instructions for the rider"
        footer={<Button block size="lg" onClick={() => setSheet(null)}>Save</Button>}>
        <Field label="Delivery instructions" htmlFor="ins">
          <Textarea id="ins" value={instructions} maxLength={300} onChange={(e) => setInstructions(e.target.value)} placeholder="Gate code, landmark, floor…" />
        </Field>
      </Sheet>

      <Sheet open={sheet === "phone"} onClose={() => setSheet(null)} title="Your phone number"
        footer={<Button block size="lg" onClick={() => setSheet(null)}>Save</Button>}>
        <Field label="Phone number" htmlFor="phone" hint="The rider and the shop call this number about your order."
          error={phone.trim() && !contactPhone ? phoneProblem(phone) ?? undefined : undefined}>
          <Input id="phone" value={phone} onChange={(e) => { setPhoneTyped(true); setPhone(e.target.value); }} placeholder="0803 000 0000"
            inputMode="tel" autoComplete="tel" maxLength={20} />
        </Field>
      </Sheet>

      <Sheet open={sheet === "address"} onClose={() => setSheet(null)} title="Delivery address"
        footer={<Button block size="lg" onClick={() => setSheet(null)}>Done</Button>}>
        <div className="space-y-4">
          {(addresses.data?.length ?? 0) > 0 && (
            <div role="radiogroup" aria-label="Saved addresses" className="divide-y divide-border">
              {[...addresses.data!.map((a) => ({ id: a.id, title: a.label || a.line1, line: [a.label ? a.line1 : null, a.area].filter(Boolean).join(", ") })),
                { id: "new", title: "New address", line: "Search or use your location" }].map((a) => (
                <button key={a.id} type="button" role="radio" aria-checked={addressId === a.id} onClick={() => chooseAddress(a.id)}
                  className="flex w-full items-center gap-3 py-3 text-left">
                  <MapPin className="size-5 shrink-0" aria-hidden="true" />
                  <span className="min-w-0 flex-1">
                    <span className="block font-semibold">{a.title}</span>
                    {a.line && <span className="block truncate text-sm text-muted">{a.line}</span>}
                  </span>
                  <span aria-hidden="true" className={cn("grid size-6 shrink-0 place-items-center rounded-full border-2", addressId === a.id ? "border-primary" : "border-border")}>
                    {addressId === a.id && <span className="size-3 rounded-full bg-primary" />}
                  </span>
                </button>
              ))}
            </div>
          )}
          {addressId === "new" && (
            <div className="space-y-4">
              <AddressSearch
                search={(q, session) => api.places.suggestions(q, session, area.location, area.city).then((r) => r.suggestions)}
                details={(placeId, session) => api.places.details(placeId, session)}
                reverse={(point) => api.places.reverse(point)}
                onPicked={onPicked}
              />
              {picked && (
                <div className="space-y-2">
                  <p className={cn("text-sm font-semibold", picked.serviceable ? "text-success" : "text-danger")} role="status">
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
            </div>
          )}
        </div>
      </Sheet>

      <Sheet open={sheet === "far"} onClose={() => setSheet(null)} title="Far from current location" hideTitle footer={
        <>
          <Button block size="lg" className="h-14 text-lg" disabled={!canPay} loading={placeOrder.isPending}
            onClick={() => { setSheet(null); pay(); }}>
            {payLabel}
          </Button>
          <Button block size="lg" variant="ghost" className="h-14 bg-surface-muted text-lg" onClick={() => setSheet("address")}>Edit address</Button>
        </>
      }>
        <div className="space-y-4 pt-2">
          <span className="mx-auto grid size-28 place-items-center rounded-full bg-accent-soft text-warning">
            <span className="relative">
              <MapPinned className="size-14" aria-hidden="true" />
              <TriangleAlert className="absolute -bottom-1 -right-3 size-7 fill-accent text-surface" aria-hidden="true" />
            </span>
          </span>
          <p className="font-display text-3xl leading-tight" aria-hidden="true">Far from current location</p>
          <p>Is this address correct?</p>
          <p className="flex items-center gap-3 font-semibold">
            <MapPin className="size-5 shrink-0" aria-hidden="true" /> {addressTitle}
          </p>
        </div>
      </Sheet>
    </div>
  );
}

/** A tappable line: icon, title (and what is set), chevron. */
function Row({ icon, title, subtitle, onClick, muted }: { icon: ReactNode; title: string; subtitle?: string | null; onClick: () => void; muted?: boolean }) {
  return (
    <button type="button" onClick={onClick} className="flex w-full items-center gap-4 py-4 text-left">
      <span className="shrink-0" aria-hidden="true">{icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block font-semibold">{title}</span>
        {subtitle && <span className={cn("block truncate text-sm", muted ? "text-muted" : "text-text/80")}>{subtitle}</span>}
      </span>
      <ChevronRight className="size-5 shrink-0" aria-hidden="true" />
    </button>
  );
}

/** Products, delivery, fees, VAT and discount of one or several quotes (several shops: their sums). */
function Breakdown({ quotes, compact }: { quotes: Quote[]; compact?: boolean }) {
  const sum = (pick: (q: Quote) => number | undefined) => quotes.reduce((s, q) => s + (pick(q) ?? 0), 0);
  const delivery = quotes.some((q) => q.fulfillment === "delivery");
  const deliveryFee = sum((q) => q.breakdown.delivery_fee_kobo);
  const freeWithPlus = delivery && deliveryFee === 0 && sum((q) => q.breakdown.plus_savings_kobo) > 0;
  const small = sum((q) => q.breakdown.small_order_fee_kobo);
  const discount = sum((q) => q.breakdown.discount_kobo);
  const row = "flex items-center justify-between gap-3";
  return (
    <dl className={cn("space-y-2", compact ? "text-sm" : "space-y-3")}>
      <div className={row}><dt>Products</dt><dd><Price kobo={sum((q) => q.breakdown.subtotal_kobo)} /></dd></div>
      {delivery && (
        <div className={row}>
          <dt>Delivery</dt>
          <dd>{freeWithPlus ? <span className="rounded-md bg-primary px-1.5 py-0.5 text-xs font-bold text-on-primary">FREE</span> : <Price kobo={deliveryFee} />}</dd>
        </div>
      )}
      <div className={row}><dt>Service fee</dt><dd><Price kobo={sum((q) => q.breakdown.service_fee_kobo)} /></dd></div>
      {small > 0 && <div className={row}><dt>Small order fee</dt><dd><Price kobo={small} /></dd></div>}
      <div className={row}><dt>VAT (7.5% on fees)</dt><dd><Price kobo={sum((q) => q.breakdown.vat_kobo)} /></dd></div>
      {discount > 0 && <div className={cn(row, "text-success")}><dt>Discount</dt><dd>-<Price kobo={discount} /></dd></div>}
    </dl>
  );
}

/** "You're saving ₦X on this order": vouchers and Yummy Chops Plus together. */
function Savings({ quotes }: { quotes: Quote[] }) {
  const plus = quotes.reduce((s, q) => s + (q.breakdown.plus_savings_kobo ?? 0), 0);
  const saved = quotes.reduce((s, q) => s + q.breakdown.discount_kobo, 0) + plus;
  if (saved <= 0) return null;
  return (
    <p className="flex items-center gap-3 rounded-2xl bg-success/10 p-4 text-sm">
      <PiggyBank className="size-6 shrink-0 text-success" aria-hidden="true" />
      <span>You&apos;re saving <strong>{formatNaira(saved)}</strong> on this order{plus > 0 ? " (Yummy Chops Plus included)" : ""}</span>
    </p>
  );
}

/** Road distance, arrival or ready time, and how long the price is held. */
function QuoteNotes({ quote }: { quote: Quote }) {
  return (
    <p className="text-xs text-muted">
      {quote.fulfillment === "delivery" && quote.road_distance_km
        ? `Delivery priced on a ${quote.road_distance_km.toFixed(1)} km road trip${isMeasured(quote.route_source) ? " (measured with live traffic)" : " (estimate)"}. `
        : null}
      {quote.scheduled_for ? `Scheduled for ${formatDateTime(quote.scheduled_for)}`
        : quote.fulfillment === "delivery" ? `Estimated arrival ${formatTime(quote.estimated_delivery_at)}` : `Ready in about ${quote.eta_minutes} min`}
      {" · "}price held until {formatTime(quote.expires_at)}
    </p>
  );
}
