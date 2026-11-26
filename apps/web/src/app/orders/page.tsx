"use client";

import { formatDateTime, formatNaira, type Order, type OrderSummary } from "@gudmeal/api-client";
import { ErrorState, Price, Skeleton, StatusBadge, cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Package, Receipt, ShoppingBag, ShoppingCart, Truck } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { EmptyBlock } from "@/components/storefront";
import { useApi } from "@/lib/api";
import { useCart } from "@/lib/cart";
import { SERVICE_NAMES as SERVICE, serviceCopy } from "@/lib/services";

/** Every status of an order still on its way (the API's `OrderStatus` without draft, completed, cancelled and refunds). */
const ACTIVE = new Set([
  "pending_payment", "paid", "submitted_to_restaurant", "restaurant_accepted", "preparing", "ready_for_pickup",
  "rider_assigned", "picked_up", "in_transit", "delivered", "disputed", "refund_pending",
]);

/** How often the list looks again while an order is in progress: its status moves on by itself. */
const ORDERS_REFRESH_MS = 10_000;

export default function OrdersPage() {
  return <RequireAuth><Orders /></RequireAuth>;
}

function Orders() {
  const api = useApi();
  const [tab, setTab] = useState<"progress" | "history">("progress");
  // Always read again when the page opens and when the customer comes back to the tab (an empty answer from before
  // paying was kept), and every 10 s while an order is in progress.
  const orders = useQuery({
    queryKey: ["orders"], queryFn: () => api.orders.list(50),
    staleTime: 0, refetchOnMount: "always", refetchOnWindowFocus: true,
    refetchInterval: (q) => (q.state.data?.some((o) => ACTIVE.has(o.status)) ? ORDERS_REFRESH_MS : false),
  });
  const summary = useQuery({
    queryKey: ["order-summary"], queryFn: () => api.orders.summary(), staleTime: 0, refetchOnMount: "always", refetchOnWindowFocus: true,
  });
  const { cart, shops, count, subtotalKobo } = useCart();
  const list = (orders.data ?? []).filter((o) => (tab === "progress" ? ACTIVE.has(o.status) : !ACTIVE.has(o.status)));

  return (
    <div className="container-page max-w-3xl pb-28 pt-6 md:pb-12">
      <h1 className="text-4xl font-black tracking-tight">Orders</h1>
      <div role="tablist" aria-label="Orders" className="mt-4 grid grid-cols-2 border-b border-border">
        {(["progress", "history"] as const).map((t) => (
          <button key={t} role="tab" aria-selected={tab === t} onClick={() => setTab(t)}
            className={cn("pb-3 font-semibold", tab === t ? "border-b-[3px] border-text" : "text-muted")}>
            {t === "progress" ? "In progress" : "History"}
          </button>
        ))}
      </div>

      <div className="mt-5 space-y-3">
        {tab === "history" && summary.data && summary.data.orders_count > 0 && <SpendCard s={summary.data} />}
        {orders.isLoading ? <Skeleton className="h-40" /> : orders.error ? (
          <ErrorState message={(orders.error as Error).message} onRetry={() => orders.refetch()} />
        ) : list.length === 0 ? (
          tab === "progress"
            ? <EmptyBlock icon={<ShoppingBag className="size-8" aria-hidden="true" />} title="Track your orders" body="Your ongoing orders will be listed here" />
            : <EmptyBlock icon={<Receipt className="size-8" aria-hidden="true" />} title="No past orders yet" body="Completed, cancelled and refunded orders appear here" />
        ) : (
          <ul className="space-y-3">{list.map((o) => <OrderRow key={o.id} o={o} />)}</ul>
        )}
      </div>

      {tab === "progress" && (
        <>
          <h2 className="mb-3 mt-8 text-2xl font-extrabold">Continue your order</h2>
          {cart.items.length === 0 ? (
            <EmptyBlock icon={<ShoppingCart className="size-8" aria-hidden="true" />} title="No carts yet" body="Add items from stores to create new carts" />
          ) : (
            <Link href="/cart" className="flex items-center gap-3 rounded-2xl border border-border p-4 hover:border-primary">
              <ShoppingCart className="size-6 text-primary" aria-hidden="true" />
              <span className="flex-1"><span className="block font-bold">{shops.map((sh) => sh.restaurant_name).join(", ")}</span><span className="text-sm text-muted">{count} item(s) · {formatNaira(subtotalKobo)}</span></span>
              <span className="rounded-full bg-primary px-4 py-2 text-sm font-bold text-on-primary">Checkout</span>
            </Link>
          )}
        </>
      )}
    </div>
  );
}

function SpendCard({ s }: { s: OrderSummary }) {
  return (
    <div className="rounded-2xl bg-gradient-to-b from-[#F25C22] to-primary p-5 text-white">
      <p className="font-semibold">You’ve spent</p>
      <p className="text-4xl font-black">{formatNaira(s.total_spent_kobo)}</p>
      <p className="text-sm">{s.orders_count} paid order(s) · {formatNaira(s.this_month_spent_kobo)} this month</p>
      <div className="mt-3 flex flex-wrap gap-2">
        {Object.entries(s.by_vertical).filter(([, v]) => v.orders > 0).map(([k, v]) => (
          <span key={k} className="rounded-full bg-white/25 px-3 py-1 text-sm font-bold">{SERVICE[k] ?? k}: {formatNaira(v.spent_kobo)}</span>
        ))}
      </div>
      {s.refunded_kobo > 0 && <p className="mt-2 text-sm">Refunded: {formatNaira(s.refunded_kobo)}</p>}
    </div>
  );
}

function OrderRow({ o }: { o: Order }) {
  const parcel = o.vertical === "parcel" ? o.parcel : null;
  const waybill = o.waybill ?? null;
  const Icon = waybill ? Truck : parcel ? Package : serviceCopy(o.vertical).icon;
  return (
    <li>
      <Link href={`/orders/${o.id}`} className="flex items-center gap-4 rounded-2xl border border-border bg-surface p-4 hover:border-primary">
        <span className="grid size-11 shrink-0 place-items-center rounded-full bg-primary-soft text-primary"><Icon className="size-5" aria-hidden="true" /></span>
        <div className="min-w-0 flex-1">
          <p className="font-bold">{waybill ? `Waybill to ${waybill.recipient.name}` : parcel ? `Package to ${parcel.dropoff.name}` : o.restaurant_name}</p>
          <p className="truncate text-sm text-muted">
            {waybill
              ? `${waybill.origin_city_name} → ${waybill.destination_city_name} · ${waybill.tracking_code ?? ""}`
              : parcel
                ? `${parcel.pickup.area ?? parcel.pickup.line1} → ${parcel.dropoff.area ?? parcel.dropoff.line1}`
                : o.lines.map((l) => `${l.quantity}× ${l.name}`).join(", ")}
          </p>
          <p className="text-xs text-muted">#{o.short_code} · {formatDateTime(o.created_at)}</p>
        </div>
        <div className="flex shrink-0 flex-col items-end gap-1">
          {parcel || waybill ? <span className="rounded-full bg-primary-soft px-2 py-0.5 text-xs font-bold text-primary-strong">{(o as Order & { progress?: { label: string } }).progress?.label ?? o.status}</span> : <StatusBadge status={o.status} />}
          <Price kobo={o.breakdown.total_kobo} className="text-sm font-semibold" />
        </div>
      </Link>
    </li>
  );
}
