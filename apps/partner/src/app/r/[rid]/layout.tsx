"use client";

import { Logo, Toggle, cn } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { BarChart3, Building2, ClipboardList, Settings, UtensilsCrossed, Wallet } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { use, type ReactNode } from "react";
import { Gate } from "@/components/gate";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { branchLine } from "@/lib/branch";

const NAV = [
  ["orders", "Orders", ClipboardList], ["menu", "Menu", UtensilsCrossed], ["insights", "Insights", BarChart3],
  ["payouts", "Payouts", Wallet], ["settings", "Settings", Settings],
] as const;
/** Owners also manage the business: its ID, branches and bank account (ADR-0028). */
const OWNER_NAV = [["business", "Business", Building2]] as const;

export default function RestaurantLayout({ children, params }: { children: ReactNode; params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  return <Gate><Shell rid={rid}>{children}</Shell></Gate>;
}

function Shell({ rid, children }: { rid: string; children: ReactNode }) {
  const api = useApi();
  const qc = useQueryClient();
  const path = usePathname();
  const { user, signOut } = useAuth();
  const menu = useQuery({ queryKey: ["menu", rid], queryFn: () => api.partner.menu(rid) });
  const mine = useQuery({ queryKey: ["my-restaurants"], queryFn: () => api.partner.restaurants() });
  const owner = mine.data?.some((m) => m.restaurant.id === rid && m.role === "owner") ?? false;
  const accepting = useMutation({
    mutationFn: (v: boolean) => api.partner.setAccepting(rid, v),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["menu", rid] }),
  });
  const r = menu.data?.restaurant;

  return (
    // Mobile: header row sized to content (auto) so short pages don't stretch it; min-w-0 lets the nav scroll
    // instead of widening the page.
    <div className="grid min-h-dvh grid-cols-1 grid-rows-[auto_1fr] lg:grid-cols-[240px_1fr] lg:grid-rows-1">
      <aside className="min-w-0 border-b border-border bg-surface lg:border-b-0 lg:border-r">
        <div className="flex items-center justify-between p-4 lg:block lg:space-y-4">
          <Logo />
          <p className="hidden text-xs font-semibold uppercase tracking-wide text-secondary lg:block">Partner</p>
          {/* Small screens (kitchen tablets, phones) hide the sidebar footer, so sign-out lives up here. */}
          <button className="text-xs font-semibold text-primary lg:hidden" onClick={() => signOut()}>Sign out</button>
        </div>
        <nav className="flex gap-1 overflow-x-auto px-2 pb-2 lg:flex-col lg:px-3" aria-label="Restaurant">
          {[...NAV, ...(owner ? OWNER_NAV : [])].map(([slug, label, Icon]) => {
            const href = `/r/${rid}/${slug}`;
            const active = path.startsWith(href);
            return (
              <Link key={slug} href={href} aria-current={active ? "page" : undefined}
                className={cn("flex shrink-0 items-center gap-2 rounded-md px-3 py-2 text-sm font-semibold",
                  active ? "bg-primary-soft text-primary-strong" : "text-muted hover:bg-surface-muted hover:text-text")}>
                <Icon className="size-4" aria-hidden="true" /> {label}
              </Link>
            );
          })}
        </nav>
        <div className="hidden space-y-2 border-t border-border p-4 text-xs text-muted lg:block">
          <p className="truncate">{user?.email}</p>
          <button className="font-semibold text-primary" onClick={() => signOut()}>Sign out</button>
        </div>
      </aside>
      <div className="min-w-0">
        <header className="flex flex-wrap items-center justify-between gap-3 border-b border-border bg-background px-4 py-3 sm:px-6">
          <div>
            <h1 className="font-display text-xl">{r?.name ?? "…"}</h1>
            <p className="text-xs text-muted">{r ? branchLine(r) : ""}</p>
          </div>
          {r && <Toggle checked={r.is_accepting_orders} disabled={accepting.isPending} onChange={(v) => accepting.mutate(v)}
            label={r.is_accepting_orders ? "Accepting orders" : "Paused"} />}
        </header>
        {(r?.status === "pending" || accepting.error) && (
          <div role={accepting.error ? "alert" : "status"}
            className="border-b border-border bg-surface-muted px-4 py-3 text-sm sm:px-6">
            {accepting.error ? <p className="text-danger">{(accepting.error as Error).message}</p> : r?.menu_restaurant_id ? (
              // A branch sells its business's one menu (ADR-0028): nothing to add before it opens.
              <p><span className="font-semibold">This branch isn&apos;t live yet.</span> It sells your main branch&apos;s
                menu: switch on <span className="font-semibold">Accepting orders</span> when it is ready and customers
                nearby will see it.</p>
            ) : (
              <p><span className="font-semibold">Your shop isn&apos;t live yet.</span> Add at least one item to your menu,
                then switch on <span className="font-semibold">Accepting orders</span> and customers will see it.</p>
            )}
          </div>
        )}
        <div className="p-4 sm:p-6">{children}</div>
      </div>
    </div>
  );
}
