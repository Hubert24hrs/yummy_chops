"use client";

import {
  ApiError,
  formatNaira,
  idempotentCalls,
  type ParcelCategory,
  type ParcelSize,
  type PlaceArea,
  type WaybillParty,
  type WaybillQuote,
} from "@gudmeal/api-client";
import { Button, Field, Input, Select, cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Building2, Home, Package, Truck } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { checkoutProvider, continueAfterCheckout, PaymentMethodPicker, type PayMethod } from "@/components/payment-method";
import { publicApi, useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { AREAS } from "@/lib/location";

const SIZES: { id: ParcelSize; label: string; hint: string }[] = [
  { id: "small", label: "Small", hint: "Documents, phone, shoes · up to 5 kg" },
  { id: "medium", label: "Medium", hint: "Shoebox to small carton · up to 10 kg" },
  { id: "large", label: "Large", hint: "Bulky but fits a bike · up to 20 kg" },
];
const CATEGORIES: Record<ParcelCategory, string> = {
  documents: "Documents", clothing: "Clothing", electronics: "Electronics", food: "Food",
  cosmetics: "Cosmetics", household: "Household", other: "Other",
};
const PHONE = /^\+?[0-9 ]{7,20}$/;

interface Person { name: string; phone: string; area: string; line1: string; notes: string }
const BLANK: Person = { name: "", phone: "", area: "", line1: "", notes: "" };

function Choice({ checked, onClick, icon: Icon, title, note, disabled = false }: {
  checked: boolean; onClick: () => void; icon: typeof Home; title: string; note: string; disabled?: boolean;
}) {
  return (
    <button type="button" role="radio" aria-checked={checked} disabled={disabled} onClick={onClick}
      className={cn("flex w-full items-center gap-3 rounded-2xl border-2 p-3 text-left",
        checked ? "border-primary bg-primary-soft" : "border-border", disabled && "cursor-not-allowed opacity-50")}>
      <Icon className="size-5 shrink-0 text-primary" aria-hidden="true" />
      <span><span className="block font-bold">{title}</span><span className="text-sm text-muted">{note}</span></span>
    </button>
  );
}

export function WaybillForm() {
  const api = useApi();
  const router = useRouter();
  const { user } = useAuth();
  const origins = useQuery({ queryKey: ["waybill-origins"], queryFn: () => publicApi.waybills.origins(), staleTime: 300_000 });
  const areas = useQuery({ queryKey: ["areas"], queryFn: () => publicApi.catalog.areas() });
  const areaList: PlaceArea[] = areas.data ?? AREAS.map((a) => ({ name: a.name, city: a.city, lat: a.location.lat, lng: a.location.lng }));
  const [origin, setOrigin] = useState("lagos");
  const routes = useQuery({
    queryKey: ["waybill-destinations", origin], queryFn: () => publicApi.waybills.destinations(origin), staleTime: 300_000,
  });
  const [destination, setDestination] = useState("");
  const [firstMile, setFirstMile] = useState<"pickup" | "dropoff">("pickup");
  const [originHub, setOriginHub] = useState("");
  const [lastMile, setLastMile] = useState<"door" | "collect">("door");
  const [destHub, setDestHub] = useState("");
  const [sender, setSender] = useState<Person>(BLANK);
  const [recipient, setRecipient] = useState<Person>(BLANK);
  const [size, setSize] = useState<ParcelSize>("small");
  const [weight, setWeight] = useState("1");
  const [category, setCategory] = useState<ParcelCategory>("clothing");
  const [what, setWhat] = useState("");
  const [codOn, setCodOn] = useState(false);
  const [codNaira, setCodNaira] = useState("");
  const [quote, setQuote] = useState<WaybillQuote | null>(null);
  const [method, setMethod] = useState<PayMethod>("card");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [sendBooking] = useState(() => idempotentCalls("waybill"));
  const [sendCheckout] = useState(() => idempotentCalls("checkout"));

  useEffect(() => {
    setSender((s) => ({ ...s, name: s.name || user?.displayName || "", phone: s.phone || user?.phoneNumber || "" }));
  }, [user]);

  const originInfo = origins.data?.find((o) => o.id === origin);
  const dest = routes.data?.destinations.find((d) => d.city === destination);
  const canPickup = originInfo?.home_pickup ?? true;
  const canDoor = dest?.door_delivery ?? true;
  const pickup = firstMile === "pickup" && canPickup;
  const door = lastMile === "door" && canDoor;
  const codKobo = codOn ? Math.round(Number(codNaira.replace(/[^0-9.]/g, "")) * 100) : 0;
  const changed = () => setQuote(null);
  const find = (name: string, city: string) => areaList.find((a) => a.name === name && a.city === city);

  function party(p: Person, city: string, withAddress: boolean): WaybillParty {
    const base = { name: p.name.trim(), phone: p.phone.trim() };
    if (!withAddress) return base;
    const a = find(p.area, city)!;
    return { ...base, line1: p.line1.trim(), area: a.name, location: { lat: a.lat, lng: a.lng }, instructions: p.notes.trim() || null };
  }

  function validate(): string | null {
    if (!dest) return "Choose where the package is going";
    const people = [["sender", sender, pickup, origin, "pickup"], ["recipient", recipient, door, destination, "delivery"]] as const;
    for (const [who, p, withAddress, city, place] of people) {
      if (p.name.trim().length < 2) return `Enter the ${who}’s name`;
      if (!PHONE.test(p.phone.trim())) return `Enter a valid ${who} phone number`;
      if (withAddress && !find(p.area, city)) return `Choose the ${place} area`;
      if (withAddress && p.line1.trim().length < 3) return `Enter the ${place} street address`;
    }
    if (!(Number(weight) > 0)) return "Enter the weight in kg";
    if (codOn && door && !(codKobo >= 100)) return "Enter the amount the rider should collect from your buyer";
    return null;
  }

  async function getPrice() {
    const problem = validate();
    if (problem) return setError(problem);
    setBusy(true);
    setError(null);
    try {
      setQuote(await api.waybills.quote({
        origin_city: origin, destination_city: destination,
        first_mile: pickup ? "pickup" : "dropoff", last_mile: door ? "door" : "collect",
        origin_hub_id: !pickup && originHub ? originHub : null,
        destination_hub_id: !door && destHub ? destHub : null,
        sender: party(sender, origin, pickup), recipient: party(recipient, destination, door),
        size, weight_kg: Number(weight), category, description: what.trim(),
        cod_amount_kobo: codOn && door ? codKobo : null,
      }));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Couldn’t get a price. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  async function book() {
    if (!quote) return;
    setBusy(true);
    setError(null);
    try {
      // A new price or payment method is a new request with a new key, and so is trying again after a refusal;
      // only a request the API may not have answered keeps its key. Booking one quote twice gives the same order.
      const order = await sendBooking({ quote: quote.id }, (key) => api.waybills.book(quote.id, key));
      const provider = checkoutProvider(method);
      const res = await sendCheckout({ order: order.id, provider }, (key) => api.orders.checkout(order.id, key, provider));
      continueAfterCheckout(res, router.push);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Couldn’t book the waybill. Please try again.");
      setBusy(false);
    }
  }

  const personFields = (p: Person, set: (v: Person) => void, who: "Sender" | "Recipient", city: string, withAddress: boolean) => (
    <div className="grid gap-3 sm:grid-cols-2">
      <Field label={`${who} name`} htmlFor={`wb-${who}-name`}>
        <Input id={`wb-${who}-name`} value={p.name} onChange={(e) => { set({ ...p, name: e.target.value }); changed(); }} />
      </Field>
      <Field label={`${who} phone`} htmlFor={`wb-${who}-phone`}>
        <Input id={`wb-${who}-phone`} inputMode="tel" value={p.phone} onChange={(e) => { set({ ...p, phone: e.target.value }); changed(); }} />
      </Field>
      {withAddress && (
        <>
          <Field label="Area" htmlFor={`wb-${who}-area`}>
            <Select id={`wb-${who}-area`} value={p.area} onChange={(e) => { set({ ...p, area: e.target.value }); changed(); }}>
              <option value="">Choose area</option>
              {areaList.filter((a) => a.city === city).map((a) => <option key={a.name} value={a.name}>{a.name}</option>)}
            </Select>
          </Field>
          <Field label="Street address and landmark" htmlFor={`wb-${who}-line`}>
            <Input id={`wb-${who}-line`} value={p.line1} onChange={(e) => { set({ ...p, line1: e.target.value }); changed(); }} />
          </Field>
        </>
      )}
    </div>
  );

  const b = quote?.breakdown;
  return (
    <div className="space-y-6">
      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-extrabold"><Truck className="size-5 text-primary" aria-hidden="true" /> Route</h2>
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="From" htmlFor="wb-from">
            <Select id="wb-from" value={origin} onChange={(e) => { setOrigin(e.target.value); setDestination(""); setOriginHub(""); changed(); }}>
              {(origins.data ?? [{ id: "lagos", name: "Lagos" }, { id: "enugu", name: "Enugu" }]).map((o) => <option key={o.id} value={o.id}>{o.name}</option>)}
            </Select>
          </Field>
          <Field label="To" htmlFor="wb-to">
            <Select id="wb-to" value={destination} onChange={(e) => { setDestination(e.target.value); setDestHub(""); changed(); }}>
              <option value="">Choose city</option>
              {routes.data?.destinations.map((d) => (
                <option key={d.city} value={d.city}>
                  {d.name}: from {formatNaira(d.from_kobo)}, {d.transit_days[0] === d.transit_days[1] ? `${d.transit_days[0]} day` : `${d.transit_days[0]}–${d.transit_days[1]} days`}
                </option>
              ))}
            </Select>
          </Field>
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="text-lg font-extrabold">How does it start?</h2>
        <div className="grid gap-2 sm:grid-cols-2" role="radiogroup" aria-label="First mile">
          <Choice checked={pickup} disabled={!canPickup} onClick={() => { setFirstMile("pickup"); changed(); }} icon={Home}
            title="A rider picks it up" note={canPickup ? "From your address, taken to our hub" : "Not available in this city"} />
          <Choice checked={!pickup} onClick={() => { setFirstMile("dropoff"); changed(); }} icon={Building2}
            title="I’ll drop it at a hub" note="No pickup fee" />
        </div>
        {!pickup && (
          <Field label="Drop-off hub" htmlFor="wb-origin-hub" hint="Opening hours are on your booking confirmation.">
            <Select id="wb-origin-hub" value={originHub} onChange={(e) => { setOriginHub(e.target.value); changed(); }}>
              <option value="">Nearest hub</option>
              {routes.data?.dropoff_hubs.map((h) => <option key={h.id} value={h.id}>{h.name} · {h.address}</option>)}
            </Select>
          </Field>
        )}
        {personFields(sender, setSender, "Sender", origin, pickup)}
      </section>

      <section className="space-y-3">
        <h2 className="text-lg font-extrabold">How does it end?</h2>
        <div className="grid gap-2 sm:grid-cols-2" role="radiogroup" aria-label="Last mile">
          <Choice checked={door} disabled={!canDoor} onClick={() => { setLastMile("door"); changed(); }} icon={Home}
            title="Door delivery" note={canDoor ? "A rider delivers to the recipient" : "Not available in this city yet"} />
          <Choice checked={!door} onClick={() => { setLastMile("collect"); changed(); }} icon={Building2}
            title="Collect at a hub" note="The recipient shows a collection code" />
        </div>
        {!door && (
          <Field label="Collection point" htmlFor="wb-dest-hub">
            <Select id="wb-dest-hub" value={destHub} onChange={(e) => { setDestHub(e.target.value); changed(); }}>
              <option value="">Nearest collection point</option>
              {dest?.collection_hubs.map((h) => <option key={h.id} value={h.id}>{h.name} · {h.address}</option>)}
            </Select>
          </Field>
        )}
        {personFields(recipient, setRecipient, "Recipient", destination, door)}
      </section>

      <section className="space-y-3">
        <h2 className="flex items-center gap-2 text-lg font-extrabold"><Package className="size-5 text-primary" aria-hidden="true" /> The package</h2>
        <div className="grid gap-2 sm:grid-cols-3" role="radiogroup" aria-label="Package size">
          {SIZES.map((s) => (
            <button key={s.id} type="button" role="radio" aria-checked={size === s.id} onClick={() => { setSize(s.id); changed(); }}
              className={`rounded-2xl border-2 p-3 text-left ${size === s.id ? "border-primary bg-primary-soft" : "border-border"}`}>
              <span className="block font-bold">{s.label}</span>
              <span className="text-sm text-muted">{s.hint}</span>
            </button>
          ))}
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="Weight (kg)" htmlFor="wb-weight">
            <Input id="wb-weight" inputMode="decimal" value={weight} onChange={(e) => { setWeight(e.target.value); changed(); }} />
          </Field>
          <Field label="What is it? (optional)" htmlFor="wb-what">
            <Input id="wb-what" maxLength={200} value={what} onChange={(e) => { setWhat(e.target.value); changed(); }} />
          </Field>
        </div>
        <div className="flex flex-wrap gap-2">
          {(Object.keys(CATEGORIES) as ParcelCategory[]).map((c) => (
            <button key={c} type="button" aria-pressed={category === c} onClick={() => { setCategory(c); changed(); }}
              className={`rounded-full border px-3 py-1.5 text-sm font-semibold ${category === c ? "border-primary bg-primary-soft" : "border-border"}`}>
              {CATEGORIES[c]}
            </button>
          ))}
        </div>
        {door && (
          <label className="flex cursor-pointer items-start gap-3 rounded-2xl border border-border p-3">
            <input type="checkbox" className="mt-1 size-5 accent-[var(--color-primary)]" checked={codOn}
              onChange={(e) => { setCodOn(e.target.checked); changed(); }} />
            <span>
              <span className="block font-bold">Collect cash from my buyer</span>
              <span className="block text-sm text-muted">The rider collects the price at the door; it shows in your wallet.</span>
            </span>
          </label>
        )}
        {door && codOn && (
          <Field label="Amount to collect (₦)" htmlFor="wb-cod" hint="Up to ₦100,000. A 1.5% collection fee (min ₦100) is added.">
            <Input id="wb-cod" inputMode="decimal" value={codNaira} onChange={(e) => { setCodNaira(e.target.value); changed(); }} />
          </Field>
        )}
      </section>

      {quote && b && (
        <div className="rounded-2xl border border-border bg-surface p-4" aria-live="polite">
          <Row label={`${quote.details.origin_city_name} → ${quote.details.destination_city_name} (${quote.details.weight_kg} kg)`} value={b.linehaul_fee_kobo ?? 0} />
          {(b.pickup_fee_kobo ?? 0) > 0 && <Row label="Rider pickup" value={b.pickup_fee_kobo!} />}
          {b.delivery_fee_kobo > 0 && <Row label="Door delivery" value={b.delivery_fee_kobo} />}
          <Row label="Booking fee" value={b.service_fee_kobo} />
          {(b.cod_fee_kobo ?? 0) > 0 && <Row label="Cash collection fee" value={b.cod_fee_kobo!} />}
          <Row label="VAT (7.5%)" value={b.vat_kobo} />
          <div className="my-2 border-t border-border" />
          <Row label="Total" value={b.total_kobo} bold />
          <p className="mt-2 text-sm">Expected <strong>{quote.eta_text}</strong></p>
          <p className="mt-1 text-xs text-muted">
            {quote.details.first_mile === "dropoff" ? `Drop it at ${quote.details.origin_hub_name}. ` : ""}
            {quote.details.last_mile === "collect" ? `Collect at ${quote.details.destination_hub_name}. ` : ""}
            Carried by {quote.details.carrier_name}. Hubs and carriers are samples until launch.
          </p>
        </div>
      )}
      {quote && (
        <section className="space-y-2">
          <h2 className="text-lg font-extrabold">Pay with</h2>
          <PaymentMethodPicker totalKobo={quote.breakdown.total_kobo} value={method} onChange={setMethod} cash={{ offered: false }} />
        </section>
      )}

      <div className="fixed inset-x-0 bottom-[64px] z-20 border-t border-border bg-background/95 p-3 backdrop-blur md:static md:border-0 md:bg-transparent md:p-0">
        {error && <p role="alert" className="mb-2 text-sm font-semibold text-danger">{error}</p>}
        <Button size="lg" block loading={busy} onClick={quote ? book : getPrice}>
          {quote ? `Book & pay ${formatNaira(quote.breakdown.total_kobo)}${method === "wallet" ? " from wallet" : ""}` : "See price"}
        </Button>
      </div>
    </div>
  );
}

function Row({ label, value, bold = false }: { label: string; value: number; bold?: boolean }) {
  return (
    <p className={`flex justify-between gap-3 py-0.5 ${bold ? "text-lg font-extrabold" : ""}`}>
      <span>{label}</span>
      <span className="shrink-0">{formatNaira(value)}</span>
    </p>
  );
}
