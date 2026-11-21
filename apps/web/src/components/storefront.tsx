"use client";

import type { RestaurantCard } from "@gudmeal/api-client";
import { formatNaira } from "@gudmeal/api-client";
import { cn } from "@gudmeal/ui";
import { ChevronDown, Heart, Info, MapPin, ThumbsUp, Bike } from "lucide-react";
import Link from "next/link";
import { useEffect, useState, type ReactNode } from "react";
import { AREAS, CITY_NAMES, useLocation } from "@/lib/location";
import { BeautyArt, FoodArt, GroceryArt, MarketArt, PharmacyArt } from "./illustrations";

/** Delivery-area pill (Home and the service pages). A native select grouped by city keeps it accessible everywhere. */
export function AddressPill({ onDark = false }: { onDark?: boolean }) {
  const { area, setArea } = useLocation();
  return (
    <label
      className={cn(
        "relative inline-flex items-center gap-1.5 rounded-full py-2 pl-4 pr-9 text-[15px] font-bold shadow-sm",
        onDark ? "bg-white/90 text-[#3A1A0C]" : "bg-surface-muted text-text",
      )}
    >
      <MapPin className="size-4 text-primary" aria-hidden="true" />
      <span className="sr-only">Delivery area</span>
      <span aria-hidden="true">{area.name}, {CITY_NAMES[area.city]}</span>
      <ChevronDown className="pointer-events-none absolute right-3 size-4" aria-hidden="true" />
      <select
        value={area.name}
        onChange={(e) => setArea(e.target.value)}
        className="absolute inset-0 cursor-pointer opacity-0"
        aria-label={`Delivery area: ${area.name}, ${CITY_NAMES[area.city]}`}
      >
        {(["lagos", "enugu"] as const).map((city) => (
          <optgroup key={city} label={CITY_NAMES[city]}>
            {AREAS.filter((a) => a.city === city).map((a) => <option key={a.name} value={a.name}>{a.name}</option>)}
          </optgroup>
        ))}
      </select>
    </label>
  );
}

export function SectionTitle({ children, info, action }: { children: ReactNode; info?: string; action?: ReactNode }) {
  return (
    <div className="mb-3 mt-7 flex items-center gap-2">
      <h2 className="text-xl font-extrabold tracking-tight sm:text-2xl">{children}</h2>
      {info && (
        <span title={info} className="text-muted">
          <Info className="size-4" aria-hidden="true" />
          <span className="sr-only">{info}</span>
        </span>
      )}
      {action && <div className="ml-auto">{action}</div>}
    </div>
  );
}

const FOOD = [["#E0040B", "#F5A21A"], ["#B4442A", "#F28C5B"], ["#7A2E12", "#E2762E"], ["#6B2410", "#E8C468"]];
const BEAUTY = [["#C2557A", "#F6B9C6"], ["#6E4AA8", "#E2C7F4"], ["#2E8B1E", "#BFE5B0"]];
const GROCERY = [["#1F7A4D", "#BFE8CF"], ["#2B6CB0", "#CFE3F7"], ["#8A6A1F", "#F3E2A9"]];
const PHARMACY = [["#12746B", "#BDEBE4"], ["#2B5FA8", "#CADDF6"]];
const MARKET = [["#9A4A1B", "#F4CF9C"], ["#3F7A2E", "#D6ECB8"]];
/** Colours and artwork per kind of shop, the same as the mobile app's. */
const ART: Record<string, { palette: string[][]; Art: typeof FoodArt }> = {
  food: { palette: FOOD, Art: FoodArt },
  beauty: { palette: BEAUTY, Art: BeautyArt },
  grocery: { palette: GROCERY, Art: GroceryArt },
  pharmacy: { palette: PHARMACY, Art: PharmacyArt },
  market: { palette: MARKET, Art: MarketArt },
};

/** Store artwork until partners upload photos: warm gradient, initials and an original illustration. */
export function MerchantArt({ card, className, compact = false }: { card: Pick<RestaurantCard, "id" | "name" | "vertical" | "cover_url">; className?: string; compact?: boolean }) {
  if (card.cover_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={card.cover_url} alt="" className={cn("object-cover", className)} />;
  }
  const { palette, Art } = ART[card.vertical] ?? ART.food!;
  const [a, b] = palette[[...card.id].reduce((n, c) => n + c.charCodeAt(0), 0) % palette.length]!;
  const initials = card.name.split(/\s+/).filter((w) => w && w !== "&").slice(0, 2).map((w) => w[0]).join("");
  return (
    <div className={cn("relative overflow-hidden", className)} style={{ background: `linear-gradient(135deg, ${b}, ${a})` }} aria-hidden="true">
      <Art className={cn("absolute", compact ? "-bottom-2 -right-2 w-[90%]" : "-bottom-3 -right-3 w-[48%] max-w-[220px]")} />
      <span className={cn("absolute bottom-2 left-3 font-extrabold text-white drop-shadow", compact ? "text-2xl" : "text-4xl")}>{initials}</span>
    </div>
  );
}

export const ratingPercent = (rating: number) => `${Math.round(rating * 20)}%`;

/** The kind of shop, when it is worth saying: "Shopper" on a market where someone buys for you. */
export function ShopBadge({ children }: { children: ReactNode }) {
  return <span className="shrink-0 rounded-full bg-secondary-soft px-2 py-0.5 text-xs font-bold text-secondary">{children}</span>;
}

/** Something customers should know before they shop (over-the-counter only, market measures). */
export function ServiceNote({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <p role="note" className={cn("flex items-start gap-2 rounded-xl bg-secondary-soft p-3 text-sm text-secondary", className)}>
      <Info className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
      <span>{children}</span>
    </p>
  );
}

export function deliveryLabel(card: RestaurantCard): string {
  if (card.delivers_to_location === false) return "Pickup only";
  if (card.delivery_fee_kobo === null) return "";
  return card.delivery_fee_kobo === 0 ? "Free delivery" : formatNaira(card.delivery_fee_kobo);
}

export function PromoTag({ children }: { children: ReactNode }) {
  return <span className="inline-block max-w-[240px] truncate rounded-md bg-[#E0040B] px-2 py-1 text-xs font-bold text-white">{children}</span>;
}

/** Square logo tile ("Popular brands", "These are for you"). */
export function BrandTile({ card }: { card: RestaurantCard }) {
  const promo = card.promotions?.length > 0;
  return (
    <Link href={`/restaurants/${card.id}`} className="block w-[104px] shrink-0 text-center focus-visible:outline-none">
      <MerchantArt card={card} compact className="size-[104px] rounded-2xl transition-transform hover:-translate-y-0.5" />
      <p className="mt-1.5 truncate text-sm font-semibold">{card.name}</p>
      {(promo || card.delivery_fee_kobo !== null) && (
        <span className={cn("mt-1 inline-block rounded-md px-1.5 py-0.5 text-[11px] font-bold", promo ? "bg-[#E0040B] text-white" : "bg-secondary-soft text-secondary")}>
          {promo ? "Promo" : card.delivery_fee_kobo === 0 ? "Free" : formatNaira(card.delivery_fee_kobo)}
        </span>
      )}
    </Link>
  );
}

const FAV_KEY = "gudmeal.favourites.v1";

function useFavourite(id: string): [boolean, () => void] {
  const [fav, setFav] = useState(false);
  useEffect(() => {
    try {
      setFav((JSON.parse(window.localStorage.getItem(FAV_KEY) ?? "[]") as string[]).includes(id));
    } catch {
      /* storage unavailable */
    }
  }, [id]);
  const toggle = () => {
    setFav((was) => {
      try {
        const list = new Set(JSON.parse(window.localStorage.getItem(FAV_KEY) ?? "[]") as string[]);
        if (was) list.delete(id); else list.add(id);
        window.localStorage.setItem(FAV_KEY, JSON.stringify([...list]));
      } catch {
        /* storage unavailable */
      }
      return !was;
    });
  };
  return [fav, toggle];
}

/** Large store card: art, promo tag, favourite heart, rating, ETA and delivery fee. */
export function MerchantCard({ card }: { card: RestaurantCard }) {
  const [fav, toggle] = useFavourite(card.id);
  const available = card.is_open && card.is_accepting_orders;
  const promo = card.promotions?.[0];
  const fee = deliveryLabel(card);
  return (
    <article className="relative">
      <Link href={`/restaurants/${card.id}`} className="group block focus-visible:outline-none">
        <div className="relative overflow-hidden rounded-3xl">
          <MerchantArt card={card} className={cn("aspect-[16/8] w-full transition-transform group-hover:scale-[1.01]", !available && "opacity-60")} />
          {promo && <span className="absolute left-3 top-3"><PromoTag>{promo.label}</PromoTag></span>}
          {!available && (
            <span className="absolute inset-0 grid place-items-center">
              <span className="rounded-full bg-black/55 px-4 py-1.5 text-sm font-bold text-white">{card.is_open ? "Not taking orders" : "Closed now"}</span>
            </span>
          )}
        </div>
        <h3 className="mt-2.5 flex items-center gap-2 text-lg font-extrabold">
          {card.name}
          {card.badge && <ShopBadge>{card.badge}</ShopBadge>}
        </h3>
        <p className="flex flex-wrap items-center gap-x-2 gap-y-1 text-sm text-muted">
          <ThumbsUp className="size-4 text-secondary" aria-hidden="true" /> {ratingPercent(card.rating)}
          {card.eta_minutes !== null && <span>· {card.eta_minutes} min</span>}
          {fee && <span className="flex items-center gap-1">· <Bike className="size-4" aria-hidden="true" /> {fee}</span>}
          {card.cuisines.length > 0 && <span>· {card.cuisines.slice(0, 2).join(", ")}</span>}
        </p>
      </Link>
      <button
        type="button"
        onClick={toggle}
        aria-pressed={fav}
        aria-label={fav ? `Remove ${card.name} from favourites` : `Add ${card.name} to favourites`}
        className="absolute right-3 top-3 grid size-10 place-items-center rounded-full bg-white text-[#2A0D06] shadow"
      >
        <Heart className={cn("size-5", fav && "fill-[#E0040B] text-[#E0040B]")} aria-hidden="true" />
      </button>
    </article>
  );
}

export function CategoryBubble({ label, emoji, selected, onClick }: { label: string; emoji: string; selected: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} aria-pressed={selected} className="flex w-[84px] shrink-0 flex-col items-center gap-1.5 focus-visible:outline-none">
      <span className={cn("grid size-[68px] place-items-center rounded-full border-2 text-3xl transition-colors", selected ? "border-primary bg-primary-soft" : "border-transparent bg-surface-muted")} aria-hidden="true">
        {emoji}
      </span>
      <span className={cn("max-w-full truncate text-[13px]", selected ? "font-extrabold" : "font-medium")}>{label}</span>
    </button>
  );
}

export function FilterPill({ children, selected = false, onClick, dropdown = false }: { children: ReactNode; selected?: boolean; onClick: () => void; dropdown?: boolean }) {
  return (
    <button type="button" onClick={onClick} aria-pressed={selected}
      className={cn("inline-flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full border px-4 py-2 text-sm font-semibold", selected ? "border-primary bg-primary-soft" : "border-transparent bg-surface-muted")}>
      {children}
      {dropdown && <ChevronDown className="size-4" aria-hidden="true" />}
    </button>
  );
}

export function EmptyBlock({ icon, title, body, action }: { icon: ReactNode; title: string; body: string; action?: ReactNode }) {
  return (
    <div className="rounded-2xl border border-border px-5 py-8 text-center">
      <div className="mx-auto grid size-[76px] place-items-center rounded-full bg-surface-muted text-muted">{icon}</div>
      <p className="mt-3 text-lg font-extrabold">{title}</p>
      <p className="mt-1 text-muted">{body}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
