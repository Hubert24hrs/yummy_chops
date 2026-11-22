"use client";

import type { GeoPoint } from "@gudmeal/api-client";
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

export interface Area {
  name: string;
  city: "lagos" | "enugu";
  location: GeoPoint;
}

/**
 * Popular neighbourhoods in our launch cities (approximate centres; the full list comes from /v1/places/areas).
 * Production uses Google Places autocomplete + geocoding when a Maps key is set.
 */
export const AREAS: Area[] = [
  { name: "Lekki Phase 1", city: "lagos", location: { lat: 6.4478, lng: 3.4723 } },
  { name: "Victoria Island", city: "lagos", location: { lat: 6.4281, lng: 3.4219 } },
  { name: "Ikoyi", city: "lagos", location: { lat: 6.452, lng: 3.435 } },
  { name: "Oniru", city: "lagos", location: { lat: 6.4366, lng: 3.4517 } },
  { name: "Ajah", city: "lagos", location: { lat: 6.4682, lng: 3.5852 } },
  { name: "Yaba", city: "lagos", location: { lat: 6.5095, lng: 3.3711 } },
  { name: "Surulere", city: "lagos", location: { lat: 6.4969, lng: 3.3602 } },
  { name: "Ikeja GRA", city: "lagos", location: { lat: 6.5833, lng: 3.35 } },
  { name: "Gbagada", city: "lagos", location: { lat: 6.555, lng: 3.389 } },
  { name: "Independence Layout", city: "enugu", location: { lat: 6.4473, lng: 7.5214 } },
  { name: "Enugu GRA", city: "enugu", location: { lat: 6.459, lng: 7.505 } },
  { name: "Trans-Ekulu", city: "enugu", location: { lat: 6.484, lng: 7.516 } },
  { name: "New Haven", city: "enugu", location: { lat: 6.44, lng: 7.515 } },
];
/** @deprecated kept for older imports; use AREAS. */
export const LAGOS_AREAS = AREAS.filter((a) => a.city === "lagos");
export const CITY_NAMES = { lagos: "Lagos", enugu: "Enugu" } as const;

interface LocationState {
  area: Area;
  setArea: (name: string) => void;
}

const STORAGE_KEY = "gudmeal.area.v1";
const LocationContext = createContext<LocationState | null>(null);

export function LocationProvider({ children }: { children: ReactNode }) {
  const [area, setAreaState] = useState<Area>(AREAS[0]!);
  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(STORAGE_KEY);
      const found = AREAS.find((a) => a.name === saved);
      if (found) setAreaState(found);
    } catch {
      /* storage unavailable: keep the default */
    }
  }, []);
  const value = useMemo<LocationState>(() => ({
    area,
    setArea: (name: string) => {
      const found = AREAS.find((a) => a.name === name);
      if (!found) return;
      setAreaState(found);
      try {
        window.localStorage.setItem(STORAGE_KEY, name);
      } catch {
        /* storage unavailable */
      }
    },
  }), [area]);
  return <LocationContext.Provider value={value}>{children}</LocationContext.Provider>;
}

export function useLocation(): LocationState {
  const ctx = useContext(LocationContext);
  if (!ctx) throw new Error("useLocation must be used inside LocationProvider");
  return ctx;
}

/** Distance in km between two points (haversine). */
function kmBetween(a: GeoPoint, b: GeoPoint): number {
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(h));
}

/** The delivery area nearest to `point`, or null when even the nearest is more than `withinKm` away. */
export function nearestArea(point: GeoPoint, withinKm = 25): Area | null {
  let best: Area | null = null;
  let bestKm = Infinity;
  for (const area of AREAS) {
    const km = kmBetween(point, area.location);
    if (km < bestKm) {
      bestKm = km;
      best = area;
    }
  }
  return best && bestKm <= withinKm ? best : null;
}
