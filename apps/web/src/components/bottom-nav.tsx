"use client";

import { cn } from "@gudmeal/ui";
import { CircleUserRound, Headset, Home, Search, ShoppingBag } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth";

const TABS = [
  { href: "/", label: "Home", icon: Home, match: (p: string) => p === "/" },
  { href: "/discover", label: "Discover", icon: Search, match: (p: string) => p.startsWith("/discover") },
  { href: "/orders", label: "Orders", icon: ShoppingBag, match: (p: string) => p.startsWith("/orders") },
  { href: "/support", label: "Support", icon: Headset, match: (p: string) => p.startsWith("/support") || p.startsWith("/help") },
  { href: "/account", label: "Profile", icon: CircleUserRound, match: (p: string) => p.startsWith("/account") || p.startsWith("/login") },
] as const;

/** Mobile bottom tab bar: Home · Discover · Orders · Support · Profile (hidden on wide screens). */
export function BottomNav() {
  const path = usePathname() ?? "/";
  const { user } = useAuth();
  const initial = user?.displayName?.trim()?.[0]?.toUpperCase();
  if (path.startsWith("/assistant") || path.startsWith("/checkout") || path === "/cart") return null;
  return (
    <nav aria-label="Main" className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-surface/95 pb-[env(safe-area-inset-bottom)] backdrop-blur md:hidden">
      <ul className="grid grid-cols-5">
        {TABS.map(({ href, label, icon: Icon, match }) => {
          const active = match(path);
          return (
            <li key={href}>
              <Link href={href} aria-current={active ? "page" : undefined}
                className={cn("flex flex-col items-center gap-1 py-2 text-[11px] font-semibold", active ? "text-text" : "text-muted")}>
                <span className={cn("grid h-8 w-12 place-items-center rounded-full transition-colors", active && "bg-primary-soft")}>
                  {label === "Profile" && initial ? (
                    <span className={cn("grid size-6 place-items-center rounded-full text-xs font-extrabold text-white", active ? "bg-primary" : "bg-[#F7B48F]")}>
                      {initial}
                    </span>
                  ) : (
                    <Icon className={cn("size-5", active && "text-primary-strong")} aria-hidden="true" />
                  )}
                </span>
                {label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
