"use client";

import { decodePolyline, newPlacesSession, type GeoPoint, type PlaceLookup, type PlaceSuggestion } from "@gudmeal/api-client";
import { useEffect, useId, useMemo, useRef, useState } from "react";
import { cn } from "./utils";

// ------------------------------------------------------------------------------------- MapView
/** `rider-idle`: an online rider without a delivery (only an area-level position is known). */
export type PinKind = "kitchen" | "home" | "rider" | "rider-idle" | "place" | "you";

export interface MapPin {
  point: GeoPoint;
  kind: PinKind;
  id?: string;
  label?: string;
}

const PIN_COLOR: Record<PinKind, string> = {
  kitchen: "var(--gm-primary)",
  place: "var(--gm-primary)",
  home: "var(--gm-secondary)",
  you: "var(--gm-secondary)",
  rider: "var(--gm-info)",
  "rider-idle": "var(--gm-muted)",
};

const PIN_RANK: Record<PinKind, number> = { place: 0, kitchen: 0, "rider-idle": 1, home: 2, you: 3, rider: 4 };

const PIN_NAME: Record<PinKind, string> = {
  kitchen: "kitchen", place: "place", home: "delivery address", you: "you", rider: "rider", "rider-idle": "available rider",
};

/** 16×16 glyphs drawn in white on the pin. */
const PIN_ICON: Record<PinKind, string> = {
  kitchen: "M2.5 7.5h11c0 3-2.5 5-5.5 5s-5.5-2-5.5-5zM6 2.5v3M8 2.5v3M10 2.5v3",
  place: "M2.5 7.5h11c0 3-2.5 5-5.5 5s-5.5-2-5.5-5zM6 2.5v3M8 2.5v3M10 2.5v3",
  home: "M3 8l5-4.5L13 8v5H9.5v-3h-3v3H3z",
  you: "M8 2v2.5M8 11.5V14M2 8h2.5M11.5 8H14M8 5.5a2.5 2.5 0 1 1 0 5a2.5 2.5 0 1 1 0-5z",
  rider: "M4 12.5a1.8 1.8 0 1 1 0-.01zM12 12.5a1.8 1.8 0 1 1 0-.01zM4 12.5l3-4h3l2 4M9 8.5l1-2.5h2",
  "rider-idle": "M4 12.5a1.8 1.8 0 1 1 0-.01zM12 12.5a1.8 1.8 0 1 1 0-.01zM4 12.5l3-4h3l2 4M9 8.5l1-2.5h2",
};

interface Box { width: number; height: number }

/** North-up equirectangular projection into a box (aspect kept, at least ~1.2 km across). Not to scale. */
export function projectPoints(points: GeoPoint[], box: Box, padding = 36): (p: GeoPoint) => { x: number; y: number } {
  const pts = points.length ? points : [{ lat: 6.5244, lng: 3.3792 }];
  let minLat = pts[0]!.lat, maxLat = minLat, minLng = pts[0]!.lng, maxLng = minLng;
  for (const p of pts) {
    minLat = Math.min(minLat, p.lat); maxLat = Math.max(maxLat, p.lat);
    minLng = Math.min(minLng, p.lng); maxLng = Math.max(maxLng, p.lng);
  }
  const k = Math.cos((((minLat + maxLat) / 2) * Math.PI) / 180);
  const spanX = Math.max((maxLng - minLng) * k, 0.011);
  const spanY = Math.max(maxLat - minLat, 0.011);
  const scale = Math.min(Math.max(box.width - padding * 2, 1) / spanX, Math.max(box.height - padding * 2, 1) / spanY);
  const cx = ((minLng + maxLng) / 2) * k, cy = (minLat + maxLat) / 2;
  return (p) => ({ x: box.width / 2 + (p.lng * k - cx) * scale, y: box.height / 2 - (p.lat - cy) * scale });
}

export interface MapViewProps {
  pins: MapPin[];
  /** Google encoded polyline or decoded points for the route line. */
  route?: string | GeoPoint[] | null;
  height?: number;
  className?: string;
  selectedId?: string | null;
  onPinClick?: (id: string) => void;
  /** Join kitchen and home with a dashed line when there is no route. */
  connect?: boolean;
  /**
   * Restricted Maps JavaScript API browser key (NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY). Without it, or if the script
   * fails, a schematic map is drawn from the same data.
   */
  googleKey?: string;
  /**
   * With Google tiles, the "home" pin can be dragged to the customer's gate ("Choose on the map"); this gets where
   * it was dropped. The schematic map has no real streets, so it never offers dragging.
   */
  onPinMoved?: (point: GeoPoint) => void;
}

export function MapView({ pins, route, height = 260, className, selectedId, onPinClick, connect = true, googleKey, onPinMoved }: MapViewProps) {
  const routePoints = useMemo(() => (typeof route === "string" ? safeDecode(route) : route ?? []), [route]);
  const [googleFailed, setGoogleFailed] = useState(false);
  const label = `Map showing ${pins.map((p) => p.label ?? PIN_NAME[p.kind]).join(", ")}`;
  return (
    <div className={cn("relative overflow-hidden rounded-xl border border-border bg-surface-muted", className)} style={{ height }}>
      {googleKey && !googleFailed ? (
        <GoogleCanvas apiKey={googleKey} pins={pins} route={routePoints} label={label} onFail={() => setGoogleFailed(true)} onPinClick={onPinClick} onPinMoved={onPinMoved} />
      ) : (
        <Schematic pins={pins} route={routePoints} height={height} selectedId={selectedId} onPinClick={onPinClick} connect={connect} label={label} />
      )}
    </div>
  );
}

function safeDecode(encoded: string): GeoPoint[] {
  try {
    return decodePolyline(encoded);
  } catch {
    return [];
  }
}

const VIEW_W = 640;

function Schematic({ pins, route, height, selectedId, onPinClick, connect, label }: {
  pins: MapPin[]; route: GeoPoint[]; height: number; selectedId?: string | null; onPinClick?: (id: string) => void; connect: boolean; label: string;
}) {
  const box = { width: VIEW_W, height: Math.round((VIEW_W * height) / 520) };
  const project = projectPoints([...pins.map((p) => p.point), ...route], box);
  const kitchen = pins.find((p) => p.kind === "kitchen");
  const home = pins.find((p) => p.kind === "home");
  // Places first; the customer's own pins and the rider last so they sit on top.
  const ordered = [...pins].sort((a, b) => PIN_RANK[a.kind] - PIN_RANK[b.kind]);
  const gridId = useId().replace(/:/g, "");
  return (
    <>
      <svg viewBox={`0 0 ${box.width} ${box.height}`} preserveAspectRatio="xMidYMid meet" className="block h-full w-full" role="img" aria-label={label}>
        <defs>
          <pattern id={`grid-${gridId}`} width="44" height="44" patternUnits="userSpaceOnUse">
            <path d="M44 0H0V44" fill="none" style={{ stroke: "var(--gm-border)" }} strokeWidth="1" />
          </pattern>
        </defs>
        <rect width={box.width} height={box.height} fill={`url(#grid-${gridId})`} />
        {route.length >= 2 ? (
          <polyline
            points={route.map((p) => { const o = project(p); return `${o.x.toFixed(1)},${o.y.toFixed(1)}`; }).join(" ")}
            fill="none" style={{ stroke: "var(--gm-primary)" }} strokeWidth="5" strokeLinecap="round" strokeLinejoin="round"
          />
        ) : connect && kitchen && home ? (
          <line
            x1={project(kitchen.point).x} y1={project(kitchen.point).y} x2={project(home.point).x} y2={project(home.point).y}
            style={{ stroke: "var(--gm-muted)" }} strokeWidth="2.5" strokeDasharray="7 7" strokeLinecap="round"
          />
        ) : null}
        {ordered.map((p, i) => {
          const o = project(p.point);
          const selected = Boolean(p.id && p.id === selectedId);
          const r = selected ? 17 : 14;
          const clickable = Boolean(onPinClick && p.id);
          const showLabel = p.label && (selected || pins.length <= 4);
          return (
            <g
              key={p.id ?? `${p.kind}-${i}`}
              transform={`translate(${o.x.toFixed(1)} ${o.y.toFixed(1)})`}
              role={clickable ? "button" : undefined}
              tabIndex={clickable ? 0 : undefined}
              aria-label={clickable ? p.label ?? PIN_NAME[p.kind] : undefined}
              onClick={clickable ? () => onPinClick!(p.id!) : undefined}
              onKeyDown={clickable ? (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onPinClick!(p.id!); } } : undefined}
              className={clickable ? "cursor-pointer outline-none" : undefined}
            >
              <circle r={r + 3} fill="white" style={{ filter: "drop-shadow(0 1px 2px rgb(0 0 0 / 0.25))" }} />
              <circle r={r} style={{ fill: PIN_COLOR[p.kind] }} />
              <path d={PIN_ICON[p.kind]} transform={`translate(-${r * 0.6} -${r * 0.6}) scale(${(r * 1.2) / 16})`} fill="none" stroke="white" strokeWidth={1.6} strokeLinecap="round" strokeLinejoin="round" />
              {showLabel && (
                <text y={r + 16} textAnchor="middle" fontSize="12" fontWeight="700" style={{ fill: "var(--gm-text)", paintOrder: "stroke", stroke: "var(--gm-surface)", strokeWidth: 4 }}>
                  {p.label!.length > 22 ? `${p.label!.slice(0, 21)}…` : p.label}
                </text>
              )}
            </g>
          );
        })}
      </svg>
      <span className="pointer-events-none absolute bottom-2 left-2 rounded-md bg-surface/90 px-2 py-0.5 text-[11px] text-muted">Map preview · not to scale</span>
    </>
  );
}

// ------------------------------------------------------------------------------------- Google tiles (optional)
interface GoogleMapsGlobal {
  maps: {
    Map: new (el: HTMLElement, opts: Record<string, unknown>) => { fitBounds: (b: unknown, pad?: number) => void; setCenter: (p: unknown) => void; setZoom: (z: number) => void };
    LatLngBounds: new () => { extend: (p: { lat: number; lng: number }) => void };
    Marker: new (opts: Record<string, unknown>) => {
      setMap: (m: unknown) => void; addListener: (e: string, f: () => void) => void;
      getPosition: () => { lat: () => number; lng: () => number } | null | undefined;
    };
    Polyline: new (opts: Record<string, unknown>) => { setMap: (m: unknown) => void };
  };
}

let mapsScript: Promise<GoogleMapsGlobal> | null = null;

function loadGoogleMaps(apiKey: string): Promise<GoogleMapsGlobal> {
  const w = window as unknown as { google?: GoogleMapsGlobal };
  if (w.google?.maps) return Promise.resolve(w.google);
  mapsScript ??= new Promise<GoogleMapsGlobal>((resolve, reject) => {
    const s = document.createElement("script");
    s.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}&region=NG`;
    s.async = true;
    s.onload = () => (w.google?.maps ? resolve(w.google) : reject(new Error("Google Maps unavailable")));
    s.onerror = () => { mapsScript = null; reject(new Error("Google Maps failed to load")); };
    document.head.appendChild(s);
  });
  return mapsScript;
}

const MARKER_LETTER: Record<PinKind, string> = { kitchen: "K", place: "R", home: "H", you: "•", rider: "R", "rider-idle": "r" };

function GoogleCanvas({ apiKey, pins, route, label, onFail, onPinClick, onPinMoved }: {
  apiKey: string; pins: MapPin[]; route: GeoPoint[]; label: string; onFail: () => void; onPinClick?: (id: string) => void;
  onPinMoved?: (point: GeoPoint) => void;
}) {
  const el = useRef<HTMLDivElement>(null);
  const mapRef = useRef<{ g: GoogleMapsGlobal; map: InstanceType<GoogleMapsGlobal["maps"]["Map"]> } | null>(null);
  const [ready, setReady] = useState(false);
  const fitted = useRef("");
  const latest = useRef({ pins, route, onPinClick, onPinMoved });
  latest.current = { pins, route, onPinClick, onPinMoved };
  // Only redraw when the data actually changes (the order page polls every few seconds).
  const sig = JSON.stringify([pins, route]);

  useEffect(() => {
    let cancelled = false;
    loadGoogleMaps(apiKey).then((g) => {
      if (cancelled || !el.current) return;
      mapRef.current = { g, map: new g.maps.Map(el.current, { disableDefaultUI: true, zoomControl: true, clickableIcons: false, gestureHandling: "cooperative" }) };
      setReady(true);
    }).catch(() => !cancelled && onFail());
    return () => { cancelled = true; };
  }, [apiKey, onFail]);

  useEffect(() => {
    const m = mapRef.current;
    if (!ready || !m) return;
    const { pins: ps, route: rt, onPinClick: click } = latest.current;
    const movable = Boolean(latest.current.onPinMoved);
    const cleanup: (() => void)[] = [];
    const bounds = new m.g.maps.LatLngBounds();
    for (const p of ps) {
      const draggable = movable && p.kind === "home";
      const marker = new m.g.maps.Marker({ position: p.point, map: m.map, title: p.label ?? PIN_NAME[p.kind], label: MARKER_LETTER[p.kind], draggable });
      if (p.id && click) marker.addListener("click", () => click(p.id!));
      if (draggable) {
        marker.addListener("dragend", () => {
          const at = marker.getPosition();
          if (at) latest.current.onPinMoved?.({ lat: at.lat(), lng: at.lng() });
        });
      }
      cleanup.push(() => marker.setMap(null));
      bounds.extend(p.point);
    }
    if (rt.length >= 2) {
      const line = new m.g.maps.Polyline({ path: rt, map: m.map, strokeColor: "#E0040B", strokeWeight: 5 });
      cleanup.push(() => line.setMap(null));
      rt.forEach((p) => bounds.extend(p));
    }
    // Fit once per set of places (a moving rider shouldn't keep re-zooming the map).
    const fitKey = ps.filter((p) => p.kind !== "rider").map((p) => `${p.point.lat},${p.point.lng}`).join("|");
    if (fitted.current !== fitKey) {
      fitted.current = fitKey;
      if (ps.length + rt.length > 1) m.map.fitBounds(bounds, 48);
      else if (ps[0]) { m.map.setCenter(ps[0].point); m.map.setZoom(15); }
    }
    return () => cleanup.forEach((f) => f());
  }, [ready, sig]);

  return <div ref={el} className="h-full w-full" role="img" aria-label={label} />;
}

// ------------------------------------------------------------------------------------- AddressSearch
export interface AddressSearchProps {
  /** Calls the Yummy Chops API (Google Places behind it when configured); never Google directly. */
  search: (query: string, session: string) => Promise<PlaceSuggestion[]>;
  details: (placeId: string, session: string) => Promise<PlaceLookup>;
  /** "Use my current location": the browser's fix is sent once to find the address. */
  reverse?: (point: GeoPoint) => Promise<PlaceLookup>;
  onPicked: (lookup: PlaceLookup) => void;
  label?: string;
  placeholder?: string;
  id?: string;
}

export function AddressSearch({ search, details, reverse, onPicked, label = "Find your address", placeholder = "Street, estate or landmark", id }: AddressSearchProps) {
  const fallbackId = useId();
  const inputId = id ?? `addr-${fallbackId}`;
  const listId = `${inputId}-list`;
  const [query, setQuery] = useState("");
  const [items, setItems] = useState<PlaceSuggestion[]>([]);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const [busy, setBusy] = useState<"search" | "pick" | "locate" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const session = useRef(newPlacesSession());
  const seq = useRef(0);
  // Parents usually pass inline callbacks: keep the latest without re-running the search on every render.
  const searchRef = useRef(search);
  searchRef.current = search;
  /** The text a pick just filled in: no new search for it. */
  const picked = useRef<string | null>(null);

  useEffect(() => {
    const q = query.trim();
    if (q.length < 3) { setItems([]); return; }
    if (picked.current === q) return;
    const mine = ++seq.current;
    const t = window.setTimeout(async () => {
      setBusy("search");
      try {
        const found = await searchRef.current(q, session.current);
        if (mine === seq.current) { setItems(found); setOpen(true); setActive(-1); setError(null); }
      } catch (e) {
        if (mine === seq.current) setError((e as Error).message);
      } finally {
        if (mine === seq.current) setBusy(null);
      }
    }, 350);
    return () => window.clearTimeout(t);
  }, [query]);

  async function pick(s: PlaceSuggestion) {
    setBusy("pick");
    setOpen(false);
    setItems([]);
    seq.current++; // drop any search still in flight
    try {
      const found = await details(s.place_id, session.current);
      session.current = newPlacesSession(); // the pick ends this billing session
      picked.current = s.title.trim();
      setQuery(s.title);
      setError(null);
      onPicked(found);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(null);
    }
  }

  function locate() {
    if (!reverse) return;
    if (!("geolocation" in navigator)) { setError("Your browser can't share a location. Search for your address instead."); return; }
    setBusy("locate");
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          onPicked(await reverse({ lat: pos.coords.latitude, lng: pos.coords.longitude }));
          setError(null);
        } catch (e) {
          setError((e as Error).message);
        } finally {
          setBusy(null);
        }
      },
      () => { setBusy(null); setError("Location is off or blocked. Search for your address instead."); },
      { enableHighAccuracy: true, timeout: 12000, maximumAge: 60000 },
    );
  }

  return (
    <div className="space-y-2">
      <label htmlFor={inputId} className="text-sm font-semibold">{label}</label>
      <div className="relative">
        <input
          id={inputId}
          role="combobox"
          aria-expanded={open && items.length > 0}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-activedescendant={active >= 0 ? `${listId}-${active}` : undefined}
          value={query}
          placeholder={placeholder}
          autoComplete="off"
          onChange={(e) => { picked.current = null; setQuery(e.target.value); }}
          onFocus={() => items.length && setOpen(true)}
          onKeyDown={(e) => {
            if (e.key === "ArrowDown") { e.preventDefault(); setOpen(true); setActive((a) => Math.min(a + 1, items.length - 1)); }
            else if (e.key === "ArrowUp") { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)); }
            else if (e.key === "Enter" && open && active >= 0 && items[active]) { e.preventDefault(); void pick(items[active]!); }
            else if (e.key === "Escape") setOpen(false);
          }}
          className="h-11 w-full rounded-md border border-border bg-surface px-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
        {open && items.length > 0 && (
          <ul id={listId} role="listbox" className="absolute z-20 mt-1 max-h-72 w-full overflow-auto rounded-md border border-border bg-surface py-1 shadow-raised">
            {items.map((s, i) => (
              <li
                key={s.place_id}
                id={`${listId}-${i}`}
                role="option"
                aria-selected={i === active}
                onMouseDown={(e) => { e.preventDefault(); void pick(s); }}
                className={cn("cursor-pointer px-3 py-2 text-sm", i === active ? "bg-primary-soft" : "hover:bg-surface-muted")}
              >
                <span className="font-semibold">{s.title}</span>
                <span className="block text-xs text-muted">
                  {[s.subtitle, s.source === "google" ? null : "Neighbourhood", s.distance_m != null ? formatMetres(s.distance_m) : null].filter(Boolean).join(" · ")}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
      <div className="flex flex-wrap items-center gap-3 text-sm">
        {reverse && (
          <button type="button" onClick={locate} disabled={busy !== null} className="font-semibold text-primary hover:underline disabled:opacity-60">
            {busy === "locate" ? "Finding you…" : "Use my current location"}
          </button>
        )}
        {busy === "search" || busy === "pick" ? <span className="text-muted">Searching…</span> : null}
        {query.trim().length >= 3 && busy === null && items.length === 0 && !error && picked.current !== query.trim() && (
          <span className="text-muted">No matches yet. Try the estate, street or a nearby landmark.</span>
        )}
      </div>
      {error && <p className="text-sm text-danger" role="alert">{error}</p>}
    </div>
  );
}

function formatMetres(m: number) {
  return m < 1000 ? `${m} m` : `${(m / 1000).toFixed(1)} km`;
}
