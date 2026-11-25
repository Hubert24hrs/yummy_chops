"use client";

import { formatDateTime, formatNaira, nairaToKobo, ORDER_STATUS, type OrderStatus } from "@gudmeal/api-client";
import { Badge, Button, Card, ErrorState, Field, Input, Select, Skeleton, StatusBadge, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { use, useState } from "react";
import { useApi } from "@/lib/api";

export default function OrderDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const api = useApi();
  const qc = useQueryClient();
  const d = useQuery({ queryKey: ["admin-order", id], queryFn: () => api.admin.order(id) });
  const riders = useQuery({ queryKey: ["riders"], queryFn: () => api.admin.riders() });
  const [to, setTo] = useState<OrderStatus>("refund_pending");
  const [reason, setReason] = useState("");
  const [amount, setAmount] = useState("");
  const [liability, setLiability] = useState("platform");
  const [rider, setRider] = useState("");
  const refresh = () => qc.invalidateQueries({ queryKey: ["admin-order", id] });
  const transition = useMutation({
    // A part refund is only possible once the order is completed: before that the API always refunds in full.
    mutationFn: () => api.admin.transition(id, {
      to, reason, liability,
      refund_amount_kobo: to === "refund_pending" && d.data?.order.completed_at && amount ? nairaToKobo(Number(amount)) : undefined,
    }),
    onSuccess: () => { setReason(""); refresh(); },
  });
  const assign = useMutation({ mutationFn: () => api.admin.assignRider(id, rider, reason || "Manual dispatch"), onSuccess: refresh });

  if (d.isLoading) return <Skeleton className="h-96" />;
  if (d.error || !d.data) return <ErrorState message={(d.error as Error)?.message ?? "Not found"} />;
  const o = d.data.order;
  const s = o.settlement;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center gap-3">
        <h1 className="font-display text-3xl">Order #{o.short_code}</h1>
        <StatusBadge status={o.status} />
        <Badge>{o.channel}</Badge>
      </div>
      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="space-y-2 p-5 text-sm">
          <h2 className="font-semibold">Order</h2>
          <p>{o.restaurant_name} → {o.customer_name ?? o.customer_id}</p>
          {o.lines.map((l, i) => <p key={i}>{l.quantity}× {l.name} <span className="text-muted">{formatNaira(l.line_total_kobo)}</span></p>)}
          <p className="pt-2">Total <strong>{formatNaira(o.breakdown.total_kobo)}</strong> · refunded {formatNaira(o.refund_total_kobo)}</p>
          {o.rider_name && <p>Rider: {o.rider_name}</p>}
          {o.delivery_address && <p className="text-muted">{o.delivery_address.line1}, {o.delivery_address.area}</p>}
        </Card>
        <Card className="space-y-2 p-5 text-sm">
          <h2 className="font-semibold">Money split</h2>
          {s && <>
            <p>Commission ({(s.commission_bps / 100).toFixed(1)}%): {formatNaira(s.commission_kobo)}</p>
            <p>Restaurant earning: {formatNaira(s.restaurant_earning_kobo)}</p>
            <p>Rider pay: {formatNaira(s.rider_pay_kobo)}</p>
          </>}
          {d.data.payments?.map((p) => <p key={p.id}>Payment {p.reference}: <Badge tone={p.status === "succeeded" ? "success" : "warning"}>{p.status}</Badge></p>)}
        </Card>
        <Card className="space-y-2 p-5 text-sm">
          <h2 className="font-semibold">Ledger entries</h2>
          {d.data.ledger?.length ? d.data.ledger.map((e, i) => (
            <p key={i} className="flex justify-between gap-2 font-mono text-xs"><span>{e.direction === "debit" ? "Dr" : "Cr"} {e.account}</span><span>{formatNaira(e.amount_kobo)}</span></p>
          )) : <p className="text-muted">No postings yet</p>}
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Manual intervention</h2>
          <p className="text-xs text-muted">Every action is validated by the order state machine and written to the audit log.</p>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Move to" htmlFor="to">
              <Select id="to" value={to} onChange={(e) => setTo(e.target.value as OrderStatus)}>
                {Object.entries(ORDER_STATUS).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
              </Select>
            </Field>
            {to === "refund_pending" && <>
              {o.completed_at
                ? <Field label="Refund amount (₦, optional)" htmlFor="amt"><Input id="amt" type="number" min={0} value={amount} onChange={(e) => setAmount(e.target.value)} /></Field>
                : <p className="self-end text-sm text-muted">This order is not completed yet, so the customer is refunded in full ({formatNaira(o.breakdown.total_kobo)}).</p>}
              <Field label="Liability" htmlFor="lia"><Select id="lia" value={liability} onChange={(e) => setLiability(e.target.value)}>
                <option value="platform">Platform</option><option value="restaurant">Restaurant</option></Select></Field>
            </>}
          </div>
          <Field label="Reason (required)" htmlFor="why"><Textarea id="why" value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
          {transition.error && <ErrorState message={(transition.error as Error).message} />}
          <Button onClick={() => transition.mutate()} disabled={reason.trim().length < 3} loading={transition.isPending}>Apply</Button>
        </Card>
        <Card className="space-y-3 p-5">
          <h2 className="font-semibold">Manual dispatch</h2>
          <Select value={rider} onChange={(e) => setRider(e.target.value)} aria-label="Rider">
            <option value="">Choose a rider…</option>
            {riders.data?.filter((r) => r.status === "active").map((r) => (
              <option key={r.uid} value={r.uid}>{r.name} · {r.vehicle} · {r.is_online ? "online" : "offline"} · {r.active_order_ids.length} active</option>
            ))}
          </Select>
          {assign.error && <ErrorState message={(assign.error as Error).message} />}
          <Button variant="secondary" disabled={!rider} onClick={() => assign.mutate()} loading={assign.isPending}>Assign rider</Button>
        </Card>
      </div>

      <Card className="p-5">
        <h2 className="mb-3 font-semibold">Timeline</h2>
        <ol className="space-y-2 text-sm">
          {d.data.events.map((e) => (
            <li key={e.id} className="flex flex-wrap gap-2">
              <span className="w-36 text-muted">{formatDateTime(e.at)}</span>
              <StatusBadge status={e.to_status} />
              <span className="text-muted">by {e.actor_type}{e.actor_id && e.actor_type !== "system" ? ` (${e.actor_id.slice(0, 10)})` : ""}</span>
              {e.reason && <span>— {e.reason}</span>}
            </li>
          ))}
        </ol>
      </Card>
    </div>
  );
}
