"use client";

import { formatDateTime, formatTime, idempotentCalls, isMeasured, TRACKING_STEPS, type Order, type Tracking } from "@gudmeal/api-client";
import { Badge, Button, Card, ErrorState, MapView, Price, Skeleton, StatusBadge, Textarea, cn, type MapPin } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Banknote, Bike, KeyRound, MessageCircleWarning, Printer, Star, Wallet } from "lucide-react";
import Link from "next/link";
import { use, useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { WaybillPanel } from "@/components/waybill-panel";
import { useApi } from "@/lib/api";
import { GOOGLE_MAPS_BROWSER_KEY } from "@/lib/maps";

const LIVE = new Set(["pending_payment", "paid", "submitted_to_restaurant", "restaurant_accepted", "preparing", "ready_for_pickup", "rider_assigned", "picked_up", "in_transit", "delivered", "refund_pending"]);

export default function OrderPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <RequireAuth><OrderDetail id={id} /></RequireAuth>;
}

function OrderDetail({ id }: { id: string }) {
  const api = useApi();
  const qc = useQueryClient();
  // Polls the API while the order is live; production can switch to a Firestore listener on orders/{id}.
  const order = useQuery({
    queryKey: ["order", id], queryFn: () => api.orders.get(id),
    refetchInterval: (q) => (q.state.data && LIVE.has(q.state.data.status) ? 5000 : false),
  });
  const o = order.data;
  const enRoute = o && ["rider_assigned", "picked_up", "in_transit"].includes(o.status);
  const payOnDelivery = o?.payment.provider === "cash";
  const cashDue = Boolean(payOnDelivery && o && o.payment.status !== "paid" && !["cancelled", "draft", "pending_payment"].includes(o.status));
  // Pay-on-delivery orders get their delivery code as soon as the kitchen has them (cash is paid at the door).
  const codes = useQuery({ queryKey: ["codes", id], queryFn: () => api.orders.codes(id), enabled: Boolean(o && (o.payment.status === "paid" || cashDue)) });
  const tracking = useQuery({ queryKey: ["tracking", id], queryFn: () => api.orders.tracking(id), enabled: Boolean(enRoute), refetchInterval: 5000 });
  // The key is kept only until the API answers: trying again after a refusal is a new request (see `idempotentCalls`).
  const [sendPay] = useState(() => idempotentCalls("checkout"));
  const pay = useMutation({
    mutationFn: () => sendPay({ order: id }, (key) => api.orders.checkout(id, key)),
    onSuccess: (r) => (r.authorization_url ? window.location.assign(r.authorization_url) : order.refetch()),
  });
  const cancel = useMutation({ mutationFn: () => api.orders.cancel(id, "Cancelled from website"), onSuccess: () => qc.invalidateQueries({ queryKey: ["order", id] }) });

  if (order.isLoading) return <div className="container-page py-10"><Skeleton className="h-72" /></div>;
  if (order.error || !o) return <div className="container-page py-10"><ErrorState message={(order.error as Error)?.message ?? "Not found"} onRetry={() => order.refetch()} /></div>;

  const step = o.progress.step;
  const waybill = o.waybill ?? null;
  const earlyWaybill = Boolean(waybill && o.status === "paid" && [null, "awaiting_dropoff", "pickup_scheduled"].includes(waybill.stage));
  const canCancel = ["draft", "pending_payment", "submitted_to_restaurant"].includes(o.status) || earlyWaybill;
  const showCode = waybill ? ["paid", "in_transit"].includes(o.status) : step < 5 && step >= 1;

  return (
    <div className="container-page grid max-w-5xl gap-6 py-8 lg:grid-cols-[1fr_340px]">
      <div className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-sm text-muted">Order #{o.short_code} · {formatDateTime(o.created_at)}</p>
            <h1 className="font-display text-3xl">{o.progress.label}</h1>
          </div>
          <StatusBadge status={o.status} />
        </div>

        {waybill && <WaybillPanel order={o} />}

        {step >= 0 && !waybill && (
          <Card className="p-5">
            <ol className="grid grid-cols-5 gap-2" aria-label="Order progress">
              {TRACKING_STEPS.map((label, i) => (
                <li key={label} className="space-y-2">
                  <div className={cn("h-1.5 rounded-full", i < step ? "bg-secondary" : i === step ? "bg-primary" : "bg-border")} />
                  <p className={cn("text-[11px] sm:text-xs", i <= step ? "font-semibold" : "text-muted")}>{label}</p>
                </li>
              ))}
            </ol>
            {o.estimated_delivery_at && step < 5 && (
              <p className="mt-4 text-sm">Estimated {o.fulfillment === "delivery" ? "arrival" : "ready time"}: <strong>{formatTime(o.estimated_delivery_at)}</strong></p>
            )}
          </Card>
        )}

        {o.status === "pending_payment" && (
          <Card className="flex flex-wrap items-center justify-between gap-3 border-accent bg-accent-soft p-5">
            <p className="text-sm">Payment hasn&apos;t been completed for this order yet.</p>
            <Button onClick={() => pay.mutate()} loading={pay.isPending}>Complete payment</Button>
          </Card>
        )}

        {cashDue && (
          <Card className="flex items-center gap-4 border-secondary/40 bg-secondary-soft p-5">
            <Banknote className="size-6 shrink-0 text-secondary" aria-hidden="true" />
            <div className="text-sm">
              <p className="font-semibold">Pay {o.breakdown.total_kobo ? <Price kobo={o.breakdown.total_kobo} /> : null} in cash when it arrives</p>
              <p className="text-muted">Have the exact amount ready if you can. Share your delivery code only after you pay and get your order.</p>
            </div>
          </Card>
        )}

        {enRoute && (
          <Card className="space-y-4 p-5">
            {tracking.data && <MapView height={260} route={tracking.data.route_polyline} googleKey={GOOGLE_MAPS_BROWSER_KEY} pins={livePins(o, tracking.data)} />}
            <div className="flex items-center gap-4">
              <span className="grid size-12 shrink-0 place-items-center rounded-full bg-secondary-soft text-secondary"><Bike className="size-6" aria-hidden="true" /></span>
              <div className="text-sm">
                <p className="font-semibold">{o.rider_name ?? "Your rider"} {o.status === "rider_assigned" ? "is heading to the restaurant" : "is on the way"}</p>
                <p className="text-muted">
                  {tracking.data?.eta_minutes ? `About ${tracking.data.eta_minutes} min away` : "Live location updates every few seconds"}
                  {tracking.data?.eta_minutes ? (isMeasured(tracking.data.eta_source) ? " (live traffic)" : " (estimate)") : ""}
                  {tracking.data?.updated_at && ` · updated ${formatTime(tracking.data.updated_at)}`}
                </p>
              </div>
            </div>
          </Card>
        )}

        {codes.data && showCode && (
          <Card className="flex items-center gap-4 border-primary/40 p-5">
            <KeyRound className="size-6 text-primary" aria-hidden="true" />
            <div className="text-sm">
              <p className="font-semibold">
                {waybill ? (waybill.last_mile === "door" ? "Delivery code" : "Collection code") : o.fulfillment === "delivery" ? "Delivery code" : "Pickup code"}:{" "}
                <span className="font-display text-2xl tracking-[0.3em]">{o.fulfillment === "delivery" ? codes.data.delivery_code : codes.data.pickup_code}</span>
              </p>
              <p className="text-muted">
                {waybill
                  ? waybill.last_mile === "door"
                    ? `Send it to ${waybill.recipient.name}: they give it to the rider when the package arrives.`
                    : `Send it to ${waybill.recipient.name}: they show it at ${waybill.destination_hub_name} to collect the package.`
                  : "Share it only when you have your food. Yummy Chops will never ask for it by phone."}
              </p>
            </div>
          </Card>
        )}

        {(o.status === "completed" || o.status === "partially_refunded") && <AfterSales order={o} />}
      </div>

      <aside className="space-y-4">
        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">{o.restaurant_name}</h2>
          <ul className="space-y-2 text-sm">
            {o.lines.map((ln, i) => (
              <li key={i} className="flex justify-between gap-2">
                <span>{ln.quantity} × {ln.name}{ln.selection_labels.length > 0 && <span className="block text-xs text-muted">{ln.selection_labels.join(" · ")}</span>}</span>
                <Price kobo={ln.line_total_kobo} />
              </li>
            ))}
          </ul>
          <div className="flex justify-between border-t border-border pt-2 font-bold"><span>Total</span><Price kobo={o.breakdown.total_kobo} /></div>
          {o.payment.provider === "wallet" && o.payment.status !== "unpaid" && (
            <p className="flex items-center gap-1.5 text-xs text-muted"><Wallet className="size-4" aria-hidden="true" /> Paid from your Yummy Chops wallet</p>
          )}
          {payOnDelivery && o.payment.status === "paid" && (
            <p className="flex items-center gap-1.5 text-xs text-muted"><Banknote className="size-4" aria-hidden="true" /> Paid in cash on delivery</p>
          )}
          {o.parcel?.cod_amount_kobo ? (
            <p className="rounded-lg bg-secondary-soft p-2 text-xs">
              {o.cash_collected_at ? "Collected" : "Rider collects"} <strong><Price kobo={o.parcel.cod_amount_kobo} /></strong> from {o.parcel.dropoff.name} for you
              {o.cash_collected_at ? ": it's in your wallet's cash-on-delivery balance." : "."}
            </p>
          ) : null}
          {o.refund_total_kobo > 0 && (
            <Badge tone="warning">
              Refunded <Price kobo={o.refund_total_kobo} />{["wallet", "cash"].includes(o.payment.provider ?? "") ? " to your wallet" : ""}
            </Badge>
          )}
          {o.delivery_address && <p className="text-xs text-muted">Delivering to {o.delivery_address.line1}, {o.delivery_address.area}</p>}
        </Card>
        {canCancel && (
          <Button variant="outline" block onClick={() => cancel.mutate()} loading={cancel.isPending}>Cancel order</Button>
        )}
        {cancel.error && <ErrorState message={(cancel.error as Error).message} />}
        {["paid", "partially_refunded", "refunded"].includes(o.payment.status) && (
          <Link href={`/orders/${o.id}/receipt`} className="block">
            <Button variant="outline" block><Printer className="size-4" aria-hidden="true" /> Print my receipt</Button>
          </Link>
        )}
        <Link href="/help" className="block text-center text-sm text-muted underline-offset-2 hover:underline">Need help with this order?</Link>
      </aside>
    </div>
  );
}

/** Kitchen (or package pickup), the customer's door and the rider (only shared while on this delivery). */
function livePins(o: Order, t: Tracking): MapPin[] {
  const parcel = o.vertical === "parcel";
  const pins: MapPin[] = [];
  if (t.pickup_location) pins.push({ point: t.pickup_location, kind: "kitchen", label: parcel ? "Pickup" : o.restaurant_name });
  if (t.dropoff_location) pins.push({ point: t.dropoff_location, kind: "home", label: parcel ? "Drop-off" : "You" });
  if (t.rider_location) pins.push({ point: t.rider_location, kind: "rider", label: o.rider_name ?? "Rider" });
  return pins;
}

function AfterSales({ order }: { order: Order }) {
  const api = useApi();
  const qc = useQueryClient();
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState("");
  const [issue, setIssue] = useState("");
  const review = useMutation({
    mutationFn: () => api.orders.review(order.id, { food_rating: rating, delivery_rating: order.fulfillment === "delivery" ? rating : undefined, comment: comment || undefined }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["order", order.id] }),
  });
  const report = useMutation({ mutationFn: () => api.support.open({ order_id: order.id, category: "missing_item", description: issue }) });
  return (
    <div className="grid gap-4 sm:grid-cols-2">
      {!order.reviewed && !review.isSuccess && (
        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">How was it?</h2>
          <div className="flex gap-1" role="radiogroup" aria-label="Rating">
            {[1, 2, 3, 4, 5].map((n) => (
              <button key={n} role="radio" aria-checked={rating === n} aria-label={`${n} stars`} onClick={() => setRating(n)}>
                <Star className={cn("size-7", n <= rating ? "fill-accent text-accent" : "text-border")} />
              </button>
            ))}
          </div>
          <Textarea value={comment} onChange={(e) => setComment(e.target.value)} placeholder="Tell others what you loved (optional)" maxLength={1000} />
          <Button onClick={() => review.mutate()} loading={review.isPending}>Submit review</Button>
          {review.error && <p className="text-sm text-danger">{(review.error as Error).message}</p>}
        </Card>
      )}
      <Card className="space-y-3 p-5">
        <h2 className="flex items-center gap-2 font-semibold"><MessageCircleWarning className="size-5 text-primary" /> Something missing or wrong?</h2>
        {report.isSuccess ? <p className="text-sm text-secondary">Thanks — our support team will review this and get back to you.</p> : (
          <>
            <Textarea value={issue} onChange={(e) => setIssue(e.target.value)} placeholder="Describe what was missing or wrong" maxLength={2000} />
            <Button variant="outline" disabled={issue.trim().length < 5} onClick={() => report.mutate()} loading={report.isPending}>Report an issue</Button>
          </>
        )}
      </Card>
    </div>
  );
}
