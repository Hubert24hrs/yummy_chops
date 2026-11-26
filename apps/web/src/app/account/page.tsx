"use client";

import { formatNaira, type GeoPoint, type SavedAddress } from "@gudmeal/api-client";
import { Button, Card, Field, Input, MapView, Skeleton, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useEffect, useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { SaveAccountButtons } from "@/components/save-account";
import { WhatsAppConnect } from "@/components/whatsapp-connect";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { CITY_NAMES, nearestArea, useLocation } from "@/lib/location";
import { GOOGLE_MAPS_BROWSER_KEY } from "@/lib/maps";

export default function AccountPage() {
  return <RequireAuth><Account /></RequireAuth>;
}

const split = (s: string) => s.split(",").map((x) => x.trim()).filter(Boolean);

function Account() {
  const api = useApi();
  const qc = useQueryClient();
  const { user, isGuest, signOut } = useAuth();
  const profile = useQuery({ queryKey: ["profile"], queryFn: () => api.me.profile() });
  const wallet = useQuery({ queryKey: ["wallet"], queryFn: () => api.wallet.get() });
  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });
  const [allergens, setAllergens] = useState("");
  const [dietary, setDietary] = useState("");
  const [personalise, setPersonalise] = useState(true);

  useEffect(() => {
    if (!profile.data) return;
    setAllergens(profile.data.allergens.join(", "));
    setDietary(profile.data.dietary.join(", "));
    setPersonalise(profile.data.personalisation_consent);
  }, [profile.data]);

  const save = useMutation({
    mutationFn: () => api.me.updateProfile({ allergens: split(allergens), dietary: split(dietary), personalisation_consent: personalise }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["profile"] }),
  });
  const remove = useMutation({ mutationFn: (id: string) => api.me.deleteAddress(id), onSuccess: () => qc.invalidateQueries({ queryKey: ["addresses"] }) });

  const name = isGuest ? undefined : user?.displayName?.trim();
  const soon = (msg: string) => () => window.alert(msg);
  return (
    <div className="pb-28 md:pb-12">
      <div className="bg-gradient-to-b from-[#F25C22] to-primary pb-10 pt-6 text-white">
        <div className="container-page max-w-3xl">
          <div className="flex justify-end">
            <Link href="/support" className="rounded-full bg-secondary px-4 py-2 text-sm font-bold text-white">Help</Link>
          </div>
          <div className="mt-2 flex items-center gap-4">
            <span className="grid size-16 place-items-center rounded-full bg-[#FDE7E6] text-3xl font-extrabold text-[#B3050B]" aria-hidden="true">
              {isGuest ? "G" : (name || user?.email || "?")[0]!.toUpperCase()}
            </span>
            <div>
              <h1 className="text-2xl font-black">{isGuest ? "You're ordering as a guest" : name || "Your profile"}</h1>
              <p className="text-sm text-white/90">
                {isGuest ? "Save your account to keep your orders on any device." : user?.email ?? user?.phoneNumber}
              </p>
            </div>
          </div>
        </div>
      </div>
      <div className="container-page -mt-5 max-w-3xl space-y-6 rounded-t-3xl bg-background pt-5">
        {isGuest && (
          <Card className="space-y-3 p-5">
            <h2 className="text-xl font-black">Save your account</h2>
            <p className="text-sm text-muted">
              Keep your orders, wallet and addresses, and sign in on any device. Nothing changes in your cart.
            </p>
            <SaveAccountButtons />
          </Card>
        )}
        <HomeAddress addresses={addresses.data} loading={addresses.isLoading} />
        <h2 className="text-2xl font-black">Profile</h2>
        <nav aria-label="Profile" className="divide-y divide-border rounded-2xl border border-border">
          <Link href="/orders" className="flex items-center justify-between p-4 hover:bg-surface-muted">
            <span className="font-medium">Order history</span><span className="rounded-full bg-surface-muted px-3 py-1 text-sm font-bold">View in Orders</span>
          </Link>
          <Link href="/receipts" className="flex items-center justify-between p-4 hover:bg-surface-muted">
            <span className="font-medium">My receipts</span><span aria-hidden="true">›</span>
          </Link>
          <Link href="/wallet" className="flex items-center justify-between p-4 hover:bg-surface-muted">
            <span className="font-medium">Yummy Chops wallet</span>
            <span className="rounded-full bg-secondary-soft px-3 py-1 text-sm font-bold text-secondary">
              {wallet.data ? formatNaira(wallet.data.balance_kobo) : "Open"}
            </span>
          </Link>
          <Link href="/food?category=promotions" className="flex items-center justify-between p-4 hover:bg-surface-muted"><span className="font-medium">Promo codes and deals</span><span aria-hidden="true">›</span></Link>
          <button type="button" onClick={soon("Pay with card, bank transfer or USSD on a secure payment page (Yummy Chops never stores your card), from your Yummy Chops wallet, or in cash on delivery once you have completed your first order.")} className="flex w-full items-center justify-between p-4 text-left hover:bg-surface-muted"><span className="font-medium">Payment methods</span><span aria-hidden="true">›</span></button>
          <Link href="/plus" className="flex items-center justify-between p-4 hover:bg-surface-muted"><span className="font-medium">Yummy Chops Plus</span><span className="rounded-full bg-primary-soft px-3 py-1 text-sm font-bold text-primary-strong">Free delivery</span></Link>
          <Link href="/rewards" className="flex items-center justify-between p-4 hover:bg-surface-muted"><span className="font-medium">Yummy points and invite friends</span><span aria-hidden="true">›</span></Link>
          <Link href="/group" className="flex items-center justify-between p-4 hover:bg-surface-muted"><span className="font-medium">Group orders</span><span aria-hidden="true">›</span></Link>
          <Link href="/help" className="flex items-center justify-between p-4 hover:bg-surface-muted"><span className="font-medium">FAQ, privacy and terms</span><span aria-hidden="true">›</span></Link>
          {/* A guest has nothing to sign out of: signing out would only lose the guest's orders. */}
          {!isGuest && (
            <button type="button" onClick={() => signOut()} className="w-full p-4 text-left font-medium text-danger hover:bg-surface-muted">Sign out</button>
          )}
        </nav>
        <WhatsAppConnect />
      <Card className="space-y-4 p-5">
        <h2 className="font-semibold">Food preferences</h2>
        {profile.isLoading ? <Skeleton className="h-28" /> : (
          <>
            <Field label="Allergies" htmlFor="allergens" hint="Comma separated, e.g. peanuts, shellfish. Yummy Chops' assistant never recommends these.">
              <Input id="allergens" value={allergens} onChange={(e) => setAllergens(e.target.value)} />
            </Field>
            <Field label="Dietary preferences" htmlFor="dietary" hint="e.g. vegetarian, halal">
              <Input id="dietary" value={dietary} onChange={(e) => setDietary(e.target.value)} />
            </Field>
            <Toggle checked={personalise} onChange={setPersonalise} label="Personalise recommendations using my orders and preferences" />
            <div className="flex items-center gap-3">
              <Button onClick={() => save.mutate()} loading={save.isPending}>Save preferences</Button>
              {save.isSuccess && <span className="text-sm text-secondary">Saved</span>}
            </div>
          </>
        )}
      </Card>
      <Card className="space-y-3 p-5">
        <h2 className="font-semibold">Saved addresses</h2>
        {addresses.data?.length ? addresses.data.map((a) => (
          <div key={a.id} className="flex items-center justify-between rounded-md border border-border p-3 text-sm">
            <span>{a.label && <strong>{a.label} · </strong>}{a.line1}, {a.area}</span>
            <button className="text-danger" onClick={() => remove.mutate(a.id)}>Remove</button>
          </div>
        )) : <p className="text-sm text-muted">Addresses you use at checkout are saved here.</p>}
      </Card>
      <Card className="space-y-2 p-5 text-sm">
        <h2 className="font-semibold">Your data</h2>
        <p className="text-muted">Under the Nigeria Data Protection Act you can request a copy of your data or ask us to delete your account.</p>
        <Button variant="outline" size="sm" onClick={async () => {
          const data = await api.request<unknown>("GET", "/v1/me/export");
          const url = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: "application/json" }));
          const a = Object.assign(document.createElement("a"), { href: url, download: "yummy-chops-my-data.json" });
          a.click();
          URL.revokeObjectURL(url);
        }}>Download my data</Button>
      </Card>
      </div>
    </div>
  );
}

/** The browser's position, asked only when the customer presses "Use my location". */
function currentPosition(): Promise<GeoPoint> {
  return new Promise((resolve, reject) => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      reject(new Error("This browser can't share your location. Add your address at checkout instead."));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
      (e) => reject(new Error(e.code === 1
        ? "Location is blocked for this site. Allow it in your browser settings, or add your address at checkout."
        : "We couldn't find your location. Try again.")),
      { enableHighAccuracy: true, timeout: 15_000, maximumAge: 60_000 },
    );
  });
}

/** Home address by GPS (ADR-0032): the browser's position, looked up, shown on the map and saved as "Home". */
function HomeAddress({ addresses, loading }: { addresses: SavedAddress[] | undefined; loading: boolean }) {
  const api = useApi();
  const qc = useQueryClient();
  const { setArea } = useLocation();
  const home = addresses?.find((a) => a.label?.toLowerCase() === "home");
  const [changing, setChanging] = useState(false);

  const locate = useMutation({
    mutationFn: async () => {
      const point = await currentPosition();
      const found = await api.places.reverse(point);
      if (!found.serviceable) throw new Error(`Yummy Chops doesn't deliver to ${found.place.formatted_address} yet.`);
      const city = found.place.city === "enugu" ? CITY_NAMES.enugu : CITY_NAMES.lagos;
      const saved = await api.me.addAddress({
        label: "Home", line1: found.place.formatted_address, area: found.place.area ?? nearestArea(point)?.name ?? null,
        city, state: city, location: point, place_id: found.place.place_id,
      });
      if (home) await api.me.deleteAddress(home.id).catch(() => undefined); // the new Home replaces the old one
      return saved;
    },
    onSuccess: async (saved) => {
      setChanging(false);
      const near = nearestArea(saved.location);
      if (near) setArea(near.name);
      await qc.invalidateQueries({ queryKey: ["addresses"] });
    },
  });

  const error = locate.error ? (locate.error as Error).message : null;
  return (
    <Card className="space-y-3 p-5">
      <h2 className="font-semibold">Home address</h2>
      {loading ? <Skeleton className="h-16" /> : home && !changing ? (
        <>
          <MapView height={180} pins={[{ point: home.location, kind: "home", label: "Home" }]} googleKey={GOOGLE_MAPS_BROWSER_KEY} />
          <div className="flex items-center justify-between gap-3 text-sm">
            <span><strong>Home · </strong>{home.line1}{home.area && !home.line1.includes(home.area) ? `, ${home.area}` : ""}</span>
            <Button variant="outline" size="sm" onClick={() => { locate.reset(); setChanging(true); }}>Change</Button>
          </div>
        </>
      ) : (
        <>
          <p className="text-sm text-muted">Save where you live so checkout fills it in. We ask your browser for your location only when you press the button.</p>
          <div className="flex flex-wrap gap-2">
            <Button onClick={() => locate.mutate()} loading={locate.isPending}>Use my location</Button>
            {changing && <Button variant="ghost" onClick={() => setChanging(false)}>Cancel</Button>}
          </div>
        </>
      )}
      {error && <p role="alert" className="text-sm text-danger">{error}</p>}
    </Card>
  );
}
