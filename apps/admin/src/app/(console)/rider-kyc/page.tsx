"use client";

import { formatDateTime, type RiderKyc } from "@gudmeal/api-client";
import { Badge, Button, Card, EmptyState, ErrorState, Select, Skeleton, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { useApi } from "@/lib/api";

/** Riders' KYC, checked by hand by the team (docs/adr/0027-rider-kyc.md): verify the rider (the Verified badge; they
 * can then go online) or say what they must change. */
const STATUS_TONE: Record<string, "info" | "success" | "danger" | "progress"> = {
  submitted: "info", verified: "success", needs_changes: "progress", rejected: "danger", draft: "progress",
};
const STATUS_LABEL: Record<string, string> = {
  submitted: "Waiting for review", verified: "Verified", needs_changes: "Changes asked", rejected: "Turned down", draft: "Not submitted",
};

export default function RiderKycPage() {
  const api = useApi();
  const [status, setStatus] = useState("submitted");
  const [open, setOpen] = useState<string | null>(null);
  const list = useQuery({ queryKey: ["rider-kyc", status], queryFn: () => api.admin.riderKyc(status || undefined) });
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-3xl">Rider KYC</h1>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-52" aria-label="Status">
          <option value="submitted">Waiting for review</option>
          <option value="needs_changes">Changes asked</option>
          <option value="verified">Verified</option>
          <option value="draft">Not submitted yet</option>
          <option value="">All</option>
        </Select>
      </div>
      {list.isLoading ? <Skeleton className="h-48" /> : list.error ? <ErrorState message={(list.error as Error).message} /> : !list.data?.length ? (
        <EmptyState title="Nothing to review" body="Riders' KYC appears here when they submit it from the rider app." />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {list.data.map((k) => (
            <Card key={k.uid} className="space-y-2 p-4">
              <div className="flex items-center justify-between gap-2">
                <h2 className="font-semibold">{k.full_name || k.uid}</h2>
                <Badge tone={STATUS_TONE[k.status] ?? "info"}>{STATUS_LABEL[k.status] ?? k.status}</Badge>
              </div>
              <p className="text-sm text-muted">
                WhatsApp {k.whatsapp_phone || "—"} · NIN {k.nin || "—"} · {k.documents} of 7 photos
                {k.submitted_at ? ` · submitted ${formatDateTime(k.submitted_at)}` : ""}
              </p>
              <Button variant="outline" onClick={() => setOpen(open === k.uid ? null : k.uid)}>{open === k.uid ? "Close" : "Review"}</Button>
              {open === k.uid && <KycReview uid={k.uid} onDone={() => setOpen(null)} />}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

function KycReview({ uid, onDone }: { uid: string; onDone: () => void }) {
  const api = useApi();
  const qc = useQueryClient();
  const detail = useQuery({ queryKey: ["rider-kyc", "detail", uid], queryFn: () => api.admin.riderKycDetail(uid) });
  const [note, setNote] = useState("");
  const [redo, setRedo] = useState<string[]>([]);
  const decide = useMutation({
    mutationFn: (approve: boolean) => api.admin.decideRiderKyc(uid, { approve, note: note || undefined, changes_needed: approve ? [] : redo }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["rider-kyc"] });
      onDone();
    },
  });
  if (detail.isLoading) return <Skeleton className="h-64" />;
  if (detail.error || !detail.data) return <ErrorState message={(detail.error as Error)?.message ?? "Not found"} />;
  const k: RiderKyc = detail.data;
  const toggle = (item: string) => setRedo((r) => (r.includes(item) ? r.filter((x) => x !== item) : [...r, item]));
  return (
    <div className="space-y-4 border-t border-border pt-3">
      <dl className="grid grid-cols-[auto,1fr] gap-x-3 gap-y-1 text-sm">
        <dt className="text-muted">Email</dt><dd>{k.email || "—"}</dd>
        <dt className="text-muted">Residential</dt><dd>{k.residential_address || "—"}</dd>
        <dt className="text-muted">Permanent</dt><dd>{k.permanent_address || "—"}</dd>
        <dt className="text-muted">NIN</dt><dd className="font-mono">{k.nin || "—"}</dd>
      </dl>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={redo.includes("details")} onChange={() => toggle("details")} disabled={k.status !== "submitted"} />
        Ask to correct the details or NIN
      </label>
      <div>
        <h3 className="mb-1 text-sm font-semibold">Guarantors</h3>
        <ul className="space-y-1 text-sm">
          {k.guarantors.map((g, i) => (
            <li key={i}>{i + 1}. <strong>{g.name || "—"}</strong> · {g.phone || "—"} · {g.email || "no email"} · {g.occupation || "—"} · {g.address || "—"}</li>
          ))}
        </ul>
        <label className="mt-1 flex items-center gap-2 text-sm">
          <input type="checkbox" checked={redo.includes("guarantors")} onChange={() => toggle("guarantors")} disabled={k.status !== "submitted"} />
          Ask to correct the guarantors
        </label>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        {Object.entries(k.documents).map(([kind, doc]) => (
          <figure key={kind} className="space-y-1">
            <figcaption className="text-sm font-semibold">{doc.label}</figcaption>
            {doc.uploaded ? <KycFile uid={uid} kind={kind} pdf={doc.content_type === "application/pdf"} label={doc.label} /> : <p className="text-sm text-muted">Not uploaded</p>}
            <label className="flex items-center gap-2 text-xs">
              <input type="checkbox" checked={redo.includes(kind)} onChange={() => toggle(kind)} disabled={k.status !== "submitted"} />
              Ask to upload again
            </label>
          </figure>
        ))}
      </div>
      {k.review_note && <p className="text-sm text-muted">Last note: {k.review_note}</p>}
      {k.status === "submitted" ? (
        <>
          <Textarea placeholder="Note to the rider (shown in the rider app when you ask for changes)" value={note} onChange={(e) => setNote(e.target.value)} />
          {decide.error && <ErrorState message={(decide.error as Error).message} />}
          <div className="flex flex-wrap gap-2">
            <Button onClick={() => decide.mutate(true)} loading={decide.isPending} disabled={redo.length > 0}>Verify rider</Button>
            <Button variant="outline" onClick={() => decide.mutate(false)} disabled={!note && redo.length === 0}>Ask for changes</Button>
          </div>
        </>
      ) : (
        <Badge tone={STATUS_TONE[k.status] ?? "info"}>{STATUS_LABEL[k.status] ?? k.status}</Badge>
      )}
    </div>
  );
}

/** A KYC photo (or scanned PDF), fetched with the reviewer's sign-in: the files are private. */
function KycFile({ uid, kind, pdf, label }: { uid: string; kind: string; pdf: boolean; label: string }) {
  const api = useApi();
  const blob = useQuery({ queryKey: ["rider-kyc", "file", uid, kind], queryFn: () => api.admin.riderKycDocument(uid, kind), staleTime: Infinity });
  const [url, setUrl] = useState<string | null>(null);
  useEffect(() => {
    if (!blob.data) return;
    const u = URL.createObjectURL(blob.data);
    setUrl(u);
    return () => URL.revokeObjectURL(u);
  }, [blob.data]);
  if (blob.error) return <p className="text-sm text-danger">{(blob.error as Error).message}</p>;
  if (!url) return <Skeleton className="h-40" />;
  return pdf ? (
    <a href={url} target="_blank" rel="noreferrer" className="text-sm font-semibold text-primary underline">Open the PDF</a>
  ) : (
    <a href={url} target="_blank" rel="noreferrer">
      {/* eslint-disable-next-line @next/next/no-img-element -- a private blob URL, not an optimisable image */}
      <img src={url} alt={label} className="max-h-56 w-full rounded-lg border border-border object-contain" />
    </a>
  );
}
