"use client";

import { formatDateTime, formatNaira } from "@gudmeal/api-client";
import { Badge, Button, Card, DataTable, ErrorState, Field, Input, Skeleton, Stat } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useApi } from "@/lib/api";

export default function FinancePage() {
  const api = useApi();
  const qc = useQueryClient();
  const ledger = useQuery({ queryKey: ["ledger"], queryFn: () => api.admin.ledger() });
  const settlements = useQuery({ queryKey: ["settlements"], queryFn: () => api.admin.settlements() });
  const payouts = useQuery({ queryKey: ["payouts"], queryFn: () => api.admin.payouts("requested") });
  const weekAgo = new Date(Date.now() - 7 * 864e5).toISOString().slice(0, 10);
  const [start, setStart] = useState(weekAgo);
  const [end, setEnd] = useState(new Date().toISOString().slice(0, 10));
  const generate = useMutation({
    mutationFn: () => api.admin.generateSettlements(new Date(`${start}T00:00:00+01:00`).toISOString(), new Date(`${end}T23:59:59+01:00`).toISOString()),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["settlements"] }),
  });
  const markPaid = useMutation({
    mutationFn: (id: string) => {
      const ref = window.prompt("Bank transfer reference") ?? "";
      if (ref.trim().length < 4) throw new Error("A bank reference is required");
      return api.admin.markSettlementPaid(id, ref.trim());
    },
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["settlements"] }); qc.invalidateQueries({ queryKey: ["ledger"] }); },
  });
  const payout = useMutation({
    mutationFn: ({ id, approve, reference }: { id: string; approve: boolean; reference?: string }) => api.admin.decidePayout(id, approve, reference),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["payouts"] }); qc.invalidateQueries({ queryKey: ["ledger"] }); },
  });
  /** "Paid" asks for the bank reference and "Reject" asks first. Cancel stops here: the request stays as it is. */
  const decidePayout = (id: string, approve: boolean) => {
    if (!approve) {
      if (window.confirm("Reject this withdrawal request?")) payout.mutate({ id, approve });
      return;
    }
    const reference = window.prompt("Bank transfer reference");
    if (reference === null) return;
    payout.mutate({ id, approve, reference: reference.trim() || undefined });
  };

  const tb = ledger.data?.trial_balance;
  const accounts = ledger.data?.accounts ?? [];
  const sum = (prefix: string) => accounts.filter((a) => a.account.startsWith(prefix)).reduce((s, a) => s + a.balance_kobo, 0);

  return (
    <div className="space-y-6">
      <h1 className="font-display text-3xl">Finance</h1>
      {ledger.isLoading ? <Skeleton className="h-28" /> : ledger.error ? <ErrorState message={(ledger.error as Error).message} /> : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Stat label="Trial balance" value={tb && tb.debits_kobo === tb.credits_kobo ? "Balanced" : "UNBALANCED"} tone={tb && tb.debits_kobo === tb.credits_kobo ? "success" : "danger"}
            hint={`Dr ${formatNaira(tb?.debits_kobo)} · Cr ${formatNaira(tb?.credits_kobo)}`} />
          <Stat label="Held for open orders" value={formatNaira(sum("liability:customer_funds"))} />
          <Stat label="Owed to restaurants" value={formatNaira(sum("liability:restaurant:"))} hint={`Riders ${formatNaira(sum("liability:rider:"))}`} />
          <Stat label="Platform revenue" value={formatNaira(sum("revenue:"))} hint={`VAT payable ${formatNaira(sum("liability:vat"))}`} />
        </div>
      )}

      <Card className="space-y-4 p-5">
        <h2 className="font-semibold">Restaurant settlements</h2>
        <div className="flex flex-wrap items-end gap-3">
          <Field label="From" htmlFor="from"><Input id="from" type="date" value={start} onChange={(e) => setStart(e.target.value)} /></Field>
          <Field label="To" htmlFor="to"><Input id="to" type="date" value={end} onChange={(e) => setEnd(e.target.value)} /></Field>
          <Button onClick={() => generate.mutate()} loading={generate.isPending}>Generate statements</Button>
        </div>
        {(generate.error || markPaid.error) && <ErrorState message={((generate.error ?? markPaid.error) as Error).message} />}
        <DataTable rows={settlements.data ?? []} rowKey={(s) => s.id} empty="No statements yet" columns={[
          { key: "r", header: "Restaurant", render: (s) => s.restaurant_id },
          { key: "p", header: "Period", render: (s) => `${formatDateTime(s.period_start)} – ${formatDateTime(s.period_end)}` },
          { key: "o", header: "Orders", render: (s) => s.orders_count },
          { key: "n", header: "Net", render: (s) => <strong>{formatNaira(s.net_kobo)}</strong> },
          { key: "s", header: "Status", render: (s) => <Badge tone={s.status === "paid" ? "success" : "warning"}>{s.status}</Badge> },
          { key: "a", header: "", render: (s) => (s.status === "pending" ? <Button size="sm" onClick={() => markPaid.mutate(s.id)}>Mark paid</Button> : s.payout_reference) },
        ]} />
      </Card>

      <Card className="space-y-4 p-5">
        <h2 className="font-semibold">Rider withdrawal requests</h2>
        {payout.error && <ErrorState message={(payout.error as Error).message} />}
        <DataTable rows={payouts.data ?? []} rowKey={(p) => p.id} empty="No pending withdrawals" columns={[
          { key: "r", header: "Rider", render: (p) => p.rider_id },
          { key: "a", header: "Amount", render: (p) => formatNaira(p.amount_kobo) },
          { key: "t", header: "Requested", render: (p) => formatDateTime(p.requested_at) },
          { key: "x", header: "", render: (p) => (
            <div className="flex gap-2">
              <Button size="sm" onClick={() => decidePayout(p.id, true)}>Paid</Button>
              <Button size="sm" variant="outline" onClick={() => decidePayout(p.id, false)}>Reject</Button>
            </div>
          ) },
        ]} />
      </Card>

      <Card className="p-5">
        <h2 className="mb-3 font-semibold">Chart of accounts</h2>
        <div className="grid gap-x-8 gap-y-1 font-mono text-xs sm:grid-cols-2">
          {accounts.map((a) => (
            <p key={a.account} className="flex justify-between gap-2 border-b border-border py-1"><span>{a.account}</span><span>{formatNaira(a.balance_kobo)}</span></p>
          ))}
        </div>
      </Card>
    </div>
  );
}
