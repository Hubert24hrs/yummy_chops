"use client";

import { formatDateTime, formatNaira } from "@gudmeal/api-client";
import { Badge, Button, DataTable, ErrorState, Select, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useState } from "react";
import { useApi } from "@/lib/api";

export default function RefundsPage() {
  const api = useApi();
  const qc = useQueryClient();
  const [status, setStatus] = useState("requested");
  const list = useQuery({ queryKey: ["refunds", status], queryFn: () => api.admin.refunds(status || undefined) });
  const decide = useMutation({
    mutationFn: ({ id, approve, note }: { id: string; approve: boolean; note?: string }) => api.admin.decideRefund(id, approve, note),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["refunds"] }),
  });
  /** Asks for the note first. Cancel (or Esc) stops here: nothing is approved, rejected or paid. */
  const ask = (id: string, approve: boolean) => {
    const note = window.prompt(`${approve ? "Approve" : "Reject"} this refund? Note for the audit log (you can leave it empty). Cancel changes nothing.`);
    if (note === null) return;
    decide.mutate({ id, approve, note: note.trim() || undefined });
  };
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Refunds</h1>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-44" aria-label="Status">
          {["requested", "approved", "processing", "succeeded", "failed", "rejected", ""].map((s) => <option key={s} value={s}>{s || "All"}</option>)}
        </Select>
      </div>
      <p className="text-sm text-muted">Approving a refund requires the finance role; it is executed through the payment provider and posted to the ledger.</p>
      {decide.error && <ErrorState message={(decide.error as Error).message} />}
      {list.isLoading ? <Skeleton className="h-64" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : (
        <DataTable rows={list.data ?? []} rowKey={(r) => r.id} empty="No refunds" columns={[
          { key: "when", header: "Requested", render: (r) => formatDateTime(r.created_at) },
          { key: "order", header: "Order", render: (r) => <Link className="text-primary" href={`/orders/${r.order_id}`}>{r.order_id.slice(0, 8)}</Link> },
          { key: "amount", header: "Amount", render: (r) => <strong>{formatNaira(r.amount_kobo)}</strong> },
          { key: "reason", header: "Reason", render: (r) => <span className="line-clamp-2 max-w-xs">{r.reason}</span> },
          { key: "liability", header: "Liability", render: (r) => r.liability },
          { key: "status", header: "Status", render: (r) => <Badge tone={r.status === "succeeded" ? "success" : r.status === "requested" ? "warning" : "neutral"}>{r.status}</Badge> },
          { key: "actions", header: "", render: (r) => r.status === "requested" ? (
            <div className="flex gap-2">
              <Button size="sm" onClick={() => ask(r.id, true)}>Approve</Button>
              <Button size="sm" variant="outline" onClick={() => ask(r.id, false)}>Reject</Button>
            </div>
          ) : null },
        ]} />
      )}
    </div>
  );
}
