"use client";

import type { DeliveryAddress, GeoPoint, PlaceLookup } from "@gudmeal/api-client";
import { AddressSearch, Button, Card, Field, Input, MapView } from "@gudmeal/ui";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, Map as MapIcon, XCircle } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { CITY_NAMES, nearestArea, useLocation } from "@/lib/location";
import { GOOGLE_MAPS_BROWSER_KEY } from "@/lib/maps";
import { safeNext } from "@/lib/next-path";

/**
 * Right after signing in, a customer with no saved address chooses where to deliver, as in the app: "Use my current
 * location" (the browser's GPS, once), typing the address, or "Choose on the map" (when the site has a Google Maps
 * browser key). The address is saved as Home and its neighbourhood becomes the delivery area. "Not now" skips it.
 */
export default function WhereToDeliverPage() {
  return (
    <Suspense>
      <RequireAuth reason="Sign in to save your delivery address."><WhereToDeliver /></RequireAuth>
    </Suspense>
  );
}

function WhereToDeliver() {
  const api = useApi();
  const router = useRouter();
  const next = safeNext(useSearchParams().get("next"));
  const { area, setArea } = useLocation();
  const queryClient = useQueryClient();
  const [picked, setPicked] = useState<PlaceLookup | null>(null);
  const [pin, setPin] = useState<GeoPoint | null>(null);
  const [onMap, setOnMap] = useState(false);
  const [line1, setLine1] = useState("");
  const [landmark, setLandmark] = useState("");
  const [error, setError] = useState<string | null>(null);

  function onPicked(found: PlaceLookup, exact?: GeoPoint) {
    setPicked(found);
    setPin(exact ?? found.place.location);
    setLine1(found.place.precision === "rooftop" || found.place.precision === "street" ? found.place.formatted_address : "");
    setError(null);
  }

  const spot = useMutation({
    mutationFn: (point: GeoPoint) => api.places.reverse(point),
    onSuccess: (found, point) => {
      onPicked(found, point); // keep the exact spot the customer chose, not the looked-up centre
      setOnMap(false);
    },
    onError: (e) => setError((e as Error).message),
  });

  const save = useMutation({
    mutationFn: (address: DeliveryAddress) => api.me.addAddress(address),
    onSuccess: async (_saved, address) => {
      await queryClient.invalidateQueries({ queryKey: ["addresses"] });
      const near = nearestArea(address.location);
      if (near) setArea(near.name);
      router.replace(next);
    },
    onError: (e) => setError((e as Error).message),
  });

  function confirm() {
    if (!picked || !pin) return;
    if (line1.trim().length < 3) {
      setError("Add your street and house number so the rider can find you");
      return;
    }
    const city = picked.place.city === "enugu" ? CITY_NAMES.enugu : CITY_NAMES.lagos;
    save.mutate({
      label: "Home", line1: line1.trim(), area: picked.place.area ?? nearestArea(pin)?.name ?? null, city, state: city,
      location: pin, place_id: picked.place.place_id, instructions: landmark.trim() || null,
    });
  }

  return (
    <div className="container-page grid place-items-center py-10">
      <Card className="w-full max-w-lg space-y-5 p-6 sm:p-8">
        <div className="space-y-1">
          <h1 className="font-display text-2xl">Where should we deliver?</h1>
          <p className="text-sm text-muted">
            Set your delivery address so we show the shops that deliver to you. You can change it any time.
          </p>
        </div>

        {picked ? (
          <div className="space-y-4">
            <MapView height={200} pins={[{ point: pin ?? picked.place.location, kind: "home", label: picked.place.area ?? "Your address" }]}
              googleKey={GOOGLE_MAPS_BROWSER_KEY} onPinMoved={setPin} />
            <p className={`flex items-start gap-2 rounded-lg p-3 text-sm font-semibold ${picked.serviceable ? "bg-secondary-soft text-secondary" : "bg-danger/10 text-danger"}`}>
              {picked.serviceable ? <CheckCircle2 className="mt-0.5 size-4 shrink-0" aria-hidden="true" /> : <XCircle className="mt-0.5 size-4 shrink-0" aria-hidden="true" />}
              <span>{picked.serviceable ? "Yummy Chops delivers here" : "Outside our delivery area for now"} · {picked.place.formatted_address}</span>
            </p>
            <Field label="Street and house number" htmlFor="line1"><Input id="line1" value={line1} onChange={(e) => setLine1(e.target.value)} /></Field>
            <Field label="Landmark or directions (optional)" htmlFor="landmark"><Input id="landmark" value={landmark} onChange={(e) => setLandmark(e.target.value)} /></Field>
            {error && <p role="alert" className="text-sm font-semibold text-danger">{error}</p>}
            <div className="flex flex-wrap gap-2">
              <Button onClick={confirm} disabled={!picked.serviceable} loading={save.isPending}>Use this address</Button>
              <Button variant="outline" onClick={() => { setPicked(null); setError(null); }}>Choose another</Button>
            </div>
          </div>
        ) : onMap ? (
          <div className="space-y-3">
            <p className="text-sm">Drag the pin to where the rider should stop, then use that spot.</p>
            <MapView height={340} pins={[{ point: pin ?? area.location, kind: "home", label: "Deliver here" }]}
              googleKey={GOOGLE_MAPS_BROWSER_KEY} onPinMoved={setPin} />
            {error && <p role="alert" className="text-sm font-semibold text-danger">{error}</p>}
            <div className="flex flex-wrap gap-2">
              <Button onClick={() => spot.mutate(pin ?? area.location)} loading={spot.isPending}>Use this spot</Button>
              <Button variant="outline" onClick={() => setOnMap(false)}>Back</Button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <AddressSearch
              label="Use my current location, or type your address"
              search={(q, session) => api.places.suggestions(q, session, area.location, area.city).then((r) => r.suggestions)}
              details={(placeId, session) => api.places.details(placeId, session)}
              reverse={(point) => api.places.reverse(point)}
              onPicked={(found) => onPicked(found)}
            />
            {GOOGLE_MAPS_BROWSER_KEY && (
              <Button variant="outline" block onClick={() => { setPin(area.location); setOnMap(true); }}>
                <MapIcon className="size-4" aria-hidden="true" /> Choose on the map
              </Button>
            )}
            {error && <p role="alert" className="text-sm font-semibold text-danger">{error}</p>}
            <div className="text-center">
              <Button variant="ghost" onClick={() => router.replace(next)}>Not now</Button>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
