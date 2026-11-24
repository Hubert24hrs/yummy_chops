"use client";

import { formatDateTime } from "@gudmeal/api-client";
import { Badge, Button, DataTable, ErrorState, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useApi } from "@/lib/api";

export default function RestaurantsPage() {
  const api = useApi();
  const qc = useQueryClient();
  const list = useQuery({ queryKey: ["admin-restaurants"], queryFn: () => api.admin.restaurants() });
  const businesses = useQuery({ queryKey: ["admin-businesses"], queryFn: () => api.admin.businesses() });
  const setStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) => {
      const reason = window.prompt(`Reason for setting ${status}?`) ?? "";
      if (reason.trim().length < 3) throw new Error("A reason of at least 3 characters is required");
      return api.admin.setRestaurantStatus(id, status, reason);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-restaurants"] }),
  });
  return (
    <div className="space-y-4">
      <h1 className="font-display text-3xl">Restaurants</h1>
      {setStatus.error && <ErrorState message={(setStatus.error as Error).message} />}
      {list.isLoading ? <Skeleton className="h-96" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : (
        <DataTable rows={list.data ?? []} rowKey={(r) => r.id} columns={[
          { key: "name", header: "Restaurant", render: (r) => <span className="font-semibold">{r.name}</span> },
          { key: "area", header: "Area", render: (r) => r.area },
          { key: "business", header: "Business", render: (r) => (r.business_id
            ? <span className="font-mono text-xs">{r.business_id}<span className="block font-sans text-muted">{r.branch_name ? `${r.branch_name} branch` : ""}</span></span>
            : <span className="text-muted">—</span>) },
          { key: "rating", header: "Rating", render: (r) => `${r.rating.toFixed(1)} (${r.rating_count})` },
          { key: "commission", header: "Commission", render: (r) => (r.commission_bps === null ? "Default" : `${r.commission_bps / 100}%`) },
          { key: "accepting", header: "Orders", render: (r) => (r.is_accepting_orders ? <Badge tone="success">Accepting</Badge> : <Badge>Paused</Badge>) },
          { key: "status", header: "Status", render: (r) => <Badge tone={r.status === "active" ? "success" : r.status === "suspended" ? "danger" : "warning"}>{r.status}</Badge> },
          { key: "actions", header: "", render: (r) => r.status === "active"
            ? <Button size="sm" variant="outline" onClick={() => setStatus.mutate({ id: r.id, status: "suspended" })}>Suspend</Button>
            : <Button size="sm" onClick={() => setStatus.mutate({ id: r.id, status: "active" })}>Activate</Button> },
        ]} />
      )}

      {/* Businesses (docs/adr/0028-business-branches-and-split-payments.md): one ID, its branches, one bank account. */}
      <h2 className="pt-4 font-display text-2xl">Businesses</h2>
      {businesses.isLoading ? <Skeleton className="h-40" /> : businesses.error ? <ErrorState message={(businesses.error as Error).message} /> : (
        <DataTable rows={businesses.data ?? []} rowKey={(b) => b.id} empty="No businesses yet" columns={[
          { key: "id", header: "Business ID", render: (b) => <span className="font-mono text-sm font-semibold">{b.id}</span> },
          { key: "name", header: "Name", render: (b) => <span>{b.name}<span className="block text-xs text-muted">{[b.phone, b.email].filter(Boolean).join(" · ")}</span></span> },
          { key: "branches", header: "Branches", render: (b) => (
            <span>{b.branches.length}<span className="block text-xs text-muted">
              {b.branches.filter((br) => br.status === "active" && br.is_accepting_orders).length} taking orders</span></span>
          ) },
          { key: "bank", header: "Split payments", render: (b) => (b.bank_connected
            ? <span><Badge tone="success">Bank connected</Badge><span className="block text-xs text-muted">{b.settlement_bank_name} · ending {b.settlement_account_last4}</span></span>
            : <Badge tone="warning">Weekly payouts</Badge>) },
          { key: "created", header: "Since", render: (b) => formatDateTime(b.created_at) },
        ]} />
      )}
    </div>
  );
}
