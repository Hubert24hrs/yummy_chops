"use client";

import { formatDateTime } from "@gudmeal/api-client";
import { Badge, Button, Card, EmptyState, ErrorState, Select, Skeleton, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useApi } from "@/lib/api";

/** What a business application is for: the service its shop will appear under (ADR-0025). */
const BUSINESS_KINDS: Record<string, string> = {
  food: "Restaurant", pharmacy: "Pharmacy", beauty: "Beauty & Skin Care shop", grocery: "Supermarket or store", market: "Market shopper",
};

export default function ApplicationsPage() {
  const api = useApi();
  const qc = useQueryClient();
  const [status, setStatus] = useState("submitted");
  const [notes, setNotes] = useState<Record<string, string>>({});
  const apps = useQuery({ queryKey: ["applications", status], queryFn: () => api.admin.applications(status || undefined) });
  const decide = useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) => api.admin.decideApplication(id, approve, notes[id]),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["applications"] }),
  });
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Verification queue</h1>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-44" aria-label="Status">
          <option value="submitted">Submitted</option><option value="approved">Approved</option><option value="rejected">Rejected</option><option value="">All</option>
        </Select>
      </div>
      {decide.error && <ErrorState message={(decide.error as Error).message} />}
      {apps.isLoading ? <Skeleton className="h-64" /> : apps.error ? <ErrorState message={(apps.error as Error).message} /> : !apps.data?.length ? (
        <EmptyState title="Queue is clear" body="New business and rider applications appear here." />
      ) : (
        <div className="grid gap-4 lg:grid-cols-2">
          {apps.data.map((a) => (
            <Card key={a.id} className="space-y-3 p-5">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold">{String(a.data.business_name ?? a.data.full_name ?? "Applicant")}</h2>
                <Badge tone={a.type === "restaurant" ? "progress" : "info"}>{a.type === "restaurant" ? BUSINESS_KINDS[String(a.data.vertical ?? "food")] ?? "Business" : "Rider"}</Badge>
              </div>
              <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
                {Object.entries(a.data).filter(([k]) => !["location", "document_paths"].includes(k)).map(([k, v]) => (
                  <div key={k} className="contents"><dt className="text-muted">{k.replaceAll("_", " ")}</dt><dd className="truncate">{Array.isArray(v) ? v.join(", ") : String(v ?? "—")}</dd></div>
                ))}
              </dl>
              <p className="text-xs text-muted">Submitted {formatDateTime(a.submitted_at)} · {a.document_paths.length} document(s) in secure storage</p>
              {a.status === "submitted" ? (
                <>
                  <Textarea placeholder="Decision note (shown in audit log)" value={notes[a.id] ?? ""} onChange={(e) => setNotes({ ...notes, [a.id]: e.target.value })} />
                  <div className="flex gap-2">
                    <Button onClick={() => decide.mutate({ id: a.id, approve: true })} loading={decide.isPending}>Approve</Button>
                    <Button variant="outline" onClick={() => decide.mutate({ id: a.id, approve: false })}>Reject</Button>
                  </div>
                </>
              ) : <Badge tone={a.status === "approved" ? "success" : "danger"}>{a.status}{a.decision_reason ? ` — ${a.decision_reason}` : ""}</Badge>}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
