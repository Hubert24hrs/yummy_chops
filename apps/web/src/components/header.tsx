"use client";

import { Logo, Select, cn } from "@gudmeal/ui";
import { MapPin, ShoppingBag, User } from "lucide-react";
import Link from "next/link";
import { useCart } from "@/lib/cart";
import { AREAS, CITY_NAMES, useLocation } from "@/lib/location";
import { GudyArt } from "./illustrations";

/**
 * The first services in the owner's order (ADR-0025), as many as fit beside the area and the cart; all six are the
 * home page's bubbles and the footer's links, and phones use the bubbles and the bottom bar.
 */
const LINKS = [
  { href: "/food", label: "Order Food", show: "md:block" },
  { href: "/pharmacy", label: "Pharmacy", show: "md:block" },
  { href: "/beauty", label: "Beauty & Skin Care", show: "xl:block" },
];

export function Header() {
  const { count } = useCart();
  const { area, setArea } = useLocation();

  return (
    <header className="sticky top-0 z-30 border-b border-border/70 bg-background/90 backdrop-blur">
      <div className="container-page flex h-16 items-center gap-3">
        <Link href="/" aria-label="Yummy Chops home" className="shrink-0">
          <Logo />
        </Link>
        <label className="ml-2 hidden items-center gap-1.5 rounded-full border border-border bg-surface pl-3 lg:flex">
          <MapPin className="size-4 text-primary" aria-hidden="true" />
          <span className="sr-only">Delivery area</span>
          <Select value={area.name} onChange={(e) => setArea(e.target.value)} className="h-9 w-auto border-0 bg-transparent pr-8 font-semibold focus:ring-0">
            {(["lagos", "enugu"] as const).map((city) => (
              <optgroup key={city} label={CITY_NAMES[city]}>
                {AREAS.filter((a) => a.city === city).map((a) => <option key={a.name} value={a.name}>{a.name}</option>)}
              </optgroup>
            ))}
          </Select>
        </label>
        <nav className="ml-auto flex items-center gap-1 sm:gap-2" aria-label="Main">
          {LINKS.map((l) => (
            <Link key={l.href} href={l.href} className={cn("hidden whitespace-nowrap rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted", l.show)}>
              {l.label}
            </Link>
          ))}
          <Link href="/assistant" className="hidden items-center gap-1.5 rounded-full px-3 py-2 text-sm font-semibold text-[#3A0D05] hover:bg-[#FEF1DA] sm:flex">
            <GudyArt className="size-6" /> Ask Yummy
          </Link>
          {/* Guest mode (ADR-0032): no "Sign in" here; saving the account lives on the account page. */}
          <Link href="/account" className="hidden items-center gap-1.5 rounded-full px-3 py-2 text-sm font-semibold hover:bg-surface-muted md:flex">
            <User className="size-4" aria-hidden="true" /> Profile
          </Link>
          <Link href="/cart" aria-label={`Cart, ${count} items`}
            className="inline-flex h-8 items-center gap-1.5 rounded-full bg-primary px-3 text-sm font-semibold text-on-primary shadow-sm hover:bg-primary-strong">
            <ShoppingBag className="size-4" aria-hidden="true" />
            <span className="tabular-nums">{count}</span>
          </Link>
        </nav>
      </div>
    </header>
  );
}
