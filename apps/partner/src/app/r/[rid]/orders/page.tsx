"use client";

import { formatTime, type Order, type OrderStatus } from "@gudmeal/api-client";
import { Badge, Button, Card, Dialog, EmptyState, ErrorState, Input, Price, Skeleton, StatusBadge, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Banknote, BellRing, Bike, ChefHat, CircleCheck, PackageCheck, Phone, Store, X } from "lucide-react";
import { use, useEffect, useRef, useState } from "react";
import { useApi } from "@/lib/api";

const ACTIVE: OrderStatus[] = [
  "submitted_to_restaurant", "restaurant_accepted", "preparing", "ready_for_pickup", "rider_assigned", "picked_up", "in_transit",
];
const COLUMNS: { title: string; statuses: OrderStatus[]; icon: typeof BellRing }[] = [
  { title: "New", statuses: ["submitted_to_restaurant"], icon: BellRing },
  { title: "In the kitchen", statuses: ["restaurant_accepted", "preparing"], icon: ChefHat },
  { title: "Ready / awaiting rider", statuses: ["ready_for_pickup", "rider_assigned"], icon: Bike },
  // The rider has it: shown until it is delivered (docs/adr/0028-business-branches-and-split-payments.md).
  { title: "Picked up", statuses: ["picked_up", "in_transit"], icon: PackageCheck },
];

/** Paid before it reached the kitchen (card, transfer, wallet), as opposed to cash on delivery. */
const prepaid = (o: Order) => o.payment.provider !== "cash";

export default function OrdersBoard({ params }: { params: Promise<{ rid: string }> }) {
  const { rid } = use(params);
  const api = useApi();
  const orders = useQuery({ queryKey: ["orders", rid], queryFn: () => api.partner.orders(rid, ACTIVE), refetchInterval: 5000 });
  const seen = useRef<Set<string> | null>(null);
  const [arrived, setArrived] = useState<Order | null>(null);

  // Audible + title alert for new orders (kitchens are noisy), and a note saying the payment is in.
  useEffect(() => {
    if (!orders.data) return;
    const fresh = orders.data.filter((o) => o.status === "submitted_to_restaurant");
    const newcomer = seen.current ? fresh.find((o) => !seen.current!.has(o.id)) : undefined;
    if (newcomer) {
      setArrived(newcomer);
      try {
        const ctx = new AudioContext();
        const osc = ctx.createOscillator();
        osc.frequency.value = 880;
        osc.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.25);
      } catch { /* audio blocked until user interaction */ }
    }
    seen.current = new Set(fresh.map((o) => o.id));
    document.title = fresh.length ? `(${fresh.length}) New orders · Yummy Chops Partner` : "Orders · Yummy Chops Partner";
  }, [orders.data]);

  if (orders.isLoading) return <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{[0, 1, 2, 3].map((i) => <Skeleton key={i} className="h-80" />)}</div>;
  if (orders.error) return <ErrorState message={(orders.error as Error).message} onRetry={() => orders.refetch()} />;

  return (
    <div className="space-y-4">
      <div role="status" aria-live="polite">
        {arrived && (
          <div className="flex items-start justify-between gap-3 rounded-lg border border-border bg-secondary-soft p-3 text-sm">
            <p>
              <strong>{prepaid(arrived) ? "Payment received" : "New order"}</strong> for #{arrived.short_code}
              {prepaid(arrived) && arrived.payment.split_to_business_kobo
                ? <>: <Price kobo={arrived.payment.split_to_business_kobo} className="font-semibold" /> is on its way to your bank account (Paystack)</>
                : !prepaid(arrived) ? " (the customer pays cash on delivery)" : ""}
              . Confirm the order to start.
            </p>
            <button onClick={() => setArrived(null)} aria-label="Dismiss" className="rounded p-1 text-muted hover:text-text">
              <X className="size-4" aria-hidden="true" />
            </button>
          </div>
        )}
      </div>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {COLUMNS.map((col) => {
          const list = (orders.data ?? []).filter((o) => col.statuses.includes(o.status));
          return (
            <section key={col.title} className="min-w-0 space-y-3 rounded-lg bg-surface-muted p-3" aria-label={col.title}>
              <h2 className="flex items-center gap-2 px-1 text-sm font-semibold"><col.icon className="size-4" /> {col.title}
                <Badge tone={col.title === "New" && list.length ? "progress" : "neutral"}>{list.length}</Badge></h2>
              {list.length === 0 ? <p className="px-1 py-6 text-center text-sm text-muted">Nothing here</p>
                : list.map((o) => <OrderCard key={o.id} order={o} rid={rid} />)}
            </section>
          );
        })}
        {orders.data?.length === 0 && (
          <div className="md:col-span-2 xl:col-span-4"><EmptyState title="No active orders" body="New orders appear here instantly with a sound alert." /></div>
        )}
      </div>
    </div>
  );
}

function OrderCard({ order, rid }: { order: Order; rid: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const [prep, setPrep] = useState(order.prep_minutes ?? 20);
  const [rejecting, setRejecting] = useState(false);
  const [reason, setReason] = useState("");
  const [code, setCode] = useState("");
  const done = () => qc.invalidateQueries({ queryKey: ["orders", rid] });
  const act = useMutation({ mutationFn: (fn: () => Promise<unknown>) => fn(), onSuccess: done });
  const split = order.payment.split_to_business_kobo ?? 0;

  return (
    <Card className="space-y-3 p-4">
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="font-display text-lg">#{order.short_code}</p>
          <p className="text-xs text-muted">{formatTime(order.created_at)} · {order.customer_name ?? "Customer"}</p>
        </div>
        <div className="flex flex-col items-end gap-1">
          <StatusBadge status={order.status} />
          <Badge tone={order.fulfillment === "pickup" ? "warning" : "info"}>
            {order.fulfillment === "pickup" ? <><Store className="size-3" /> Pickup</> : <><Bike className="size-3" /> Delivery</>}
          </Badge>
        </div>
      </div>
      <ul className="space-y-1 text-sm">
        {order.lines.map((ln, i) => (
          <li key={i}><strong>{ln.quantity}×</strong> {ln.name}
            {ln.selection_labels.length > 0 && <span className="block text-xs text-muted">{ln.selection_labels.join(" · ")}</span>}
            {ln.notes && <span className="block text-xs italic text-primary-strong">“{ln.notes}”</span>}
          </li>
        ))}
      </ul>
      <div className="space-y-1 text-xs">
        {prepaid(order)
          ? <Badge tone="success"><CircleCheck className="size-3" aria-hidden="true" /> Payment received</Badge>
          : <Badge tone="warning"><Banknote className="size-3" aria-hidden="true" /> Cash on delivery</Badge>}
        <p className="text-muted">Your earning: <Price kobo={order.restaurant_earning_kobo} className="font-semibold text-text" />
          {split > 0 ? " · sent to your bank account by Paystack" : " · in your weekly payout"}</p>
      </div>
      <RiderInfo order={order} />
      {act.error && <p role="alert" className="text-xs text-danger">{(act.error as Error).message}</p>}

      {order.status === "submitted_to_restaurant" && (
        <div className="space-y-2">
          <label className="flex items-center gap-2 text-sm">Prep time
            <Input type="number" min={1} max={180} value={prep} onChange={(e) => setPrep(Number(e.target.value))} className="h-9 w-20" /> min
          </label>
          <div className="flex gap-2">
            <Button block onClick={() => act.mutate(() => api.partner.accept(rid, order.id, prep))} loading={act.isPending}>Confirm order</Button>
            <Button variant="outline" onClick={() => setRejecting(true)}>Reject</Button>
          </div>
        </div>
      )}
      {order.status === "restaurant_accepted" && (
        <Button block variant="secondary" onClick={() => act.mutate(() => api.partner.preparing(rid, order.id))} loading={act.isPending}>Start preparing</Button>
      )}
      {(order.status === "preparing" || (order.status === "rider_assigned" && !order.ready_at)) && (
        <Button block variant="secondary" onClick={() => act.mutate(() => api.partner.ready(rid, order.id))} loading={act.isPending}>Mark ready</Button>
      )}
      {order.status === "ready_for_pickup" && order.fulfillment === "pickup" && (
        <form className="flex gap-2" onSubmit={(e) => { e.preventDefault(); act.mutate(() => api.partner.handover(rid, order.id, code)); }}>
          <label htmlFor={`code-${order.id}`} className="sr-only">Customer pickup code</label>
          <Input id={`code-${order.id}`} value={code} onChange={(e) => setCode(e.target.value)} inputMode="numeric" maxLength={4} placeholder="Pickup code" className="h-9" />
          <Button type="submit" size="sm" disabled={code.length !== 4}>Hand over</Button>
        </form>
      )}
      <Dialog open={rejecting} onClose={() => setRejecting(false)} title={`Reject #${order.short_code}?`} footer={
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => setRejecting(false)}>Keep order</Button>
          <Button variant="danger" disabled={reason.trim().length < 3} loading={act.isPending}
            onClick={() => act.mutate(() => api.partner.reject(rid, order.id, reason.trim()), { onSuccess: () => setRejecting(false) })}>Reject & refund</Button>
        </div>
      }>
        <p className="mb-3 text-sm text-muted">The customer is refunded in full automatically. Frequent rejections affect your ranking.</p>
        <Textarea value={reason} onChange={(e) => setReason(e.target.value)} placeholder="Reason, e.g. item sold out" />
      </Dialog>
    </Card>
  );
}

/** The rider coming for the order (name, number, about how many minutes away) or the one who has it. */
function RiderInfo({ order }: { order: Order }) {
  const rider = order.rider;
  if (!rider) {
    return order.rider_name
      ? <p className="text-xs">Rider: <strong>{order.rider_name}</strong>{order.ready_at ? " · marked ready" : ""}</p>
      : null;
  }
  const coming = order.status === "rider_assigned";
  return (
    <div className="space-y-1 rounded-md border border-border p-2 text-xs">
      <p className="flex flex-wrap items-center gap-1">
        <Bike className="size-3" aria-hidden="true" /> {coming ? "Rider on the way:" : "Picked up by"} <strong>{rider.name}</strong>
        {rider.verified && <Badge tone="success">Verified</Badge>}
      </p>
      {rider.phone && (
        <a href={`tel:${rider.phone}`} className="flex items-center gap-1 font-semibold text-primary-strong">
          <Phone className="size-3" aria-hidden="true" /> {rider.phone}
        </a>
      )}
      {coming && rider.eta_minutes != null && <p>Arrives in about {rider.eta_minutes} min{order.ready_at ? " · marked ready" : ""}</p>}
      {coming && rider.eta_minutes == null && order.ready_at && <p>Marked ready</p>}
    </div>
  );
}
