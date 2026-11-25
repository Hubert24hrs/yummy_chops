"use client";

import { ApiError, type RiderKyc, type RiderKycGuarantor } from "@gudmeal/api-client";
import { Button, Card, ErrorState, Field, Input, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { BadgeCheck, CheckCircle2, Circle, CircleAlert, FileText, Hourglass } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

// A rider's KYC on the website: the same steps as in the Yummy Chops Rider app (docs/adr/0027-rider-kyc.md).
const VEHICLE_DOCUMENTS = ["plate_number", "hackney_permit", "riders_card", "bike"];
const GUARANTOR_FIELDS: [keyof RiderKycGuarantor, string][] = [
  ["name", "Full name"], ["phone", "Phone number"], ["email", "Email (if they have one)"], ["address", "Address"], ["occupation", "Occupation"],
];
const EMPTY_GUARANTOR: RiderKycGuarantor = { name: "", phone: "", email: "", address: "", occupation: "" };
/** The API takes files up to 5 MB. */
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;

/** A photo made smaller (at most 1600 px, JPEG) so it uploads quickly and stays under the 5 MB limit; PDFs as they are. */
async function readForUpload(file: File): Promise<string> {
  // A file sent as it is (a PDF, or a photo the browser cannot redraw) is checked before it is read: reading and
  // sending a big file only for the API to refuse it wastes the rider's time and data.
  const asDataUrl = (blob: Blob) => new Promise<string>((resolve, reject) => {
    if (blob.size > MAX_UPLOAD_BYTES) {
      reject(new Error("This file is too large (at most 5 MB). Choose a smaller file."));
      return;
    }
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error("The file could not be read"));
    reader.readAsDataURL(blob);
  });
  if (!file.type.startsWith("image/") || typeof createImageBitmap !== "function") return asDataUrl(file);
  try {
    const bitmap = await createImageBitmap(file);
    const scale = Math.min(1, 1600 / Math.max(bitmap.width, bitmap.height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(bitmap.width * scale);
    canvas.height = Math.round(bitmap.height * scale);
    canvas.getContext("2d")?.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL("image/jpeg", 0.8);
  } catch {
    return asDataUrl(file); // the browser cannot redraw it: send it as it is and let the API check it
  }
}

export default function RiderKycPage() {
  return (
    <div className="container-page max-w-3xl space-y-6 py-8">
      <h1 className="font-display text-4xl">Your rider KYC</h1>
      <RequireAuth reason="Sign in with the account you signed up to ride with."><KycForm /></RequireAuth>
    </div>
  );
}

function KycForm() {
  const api = useApi();
  const { refreshToken } = useAuth();
  const qc = useQueryClient();
  const kyc = useQuery({
    queryKey: ["rider-kyc"],
    retry: false,
    queryFn: async () => {
      try {
        return await api.riderKyc.get();
      } catch (e) {
        // Signed up a moment ago (here or in the app): this browser's sign-in token may predate the rider role.
        if (e instanceof ApiError && e.status === 403) {
          await refreshToken();
          return api.riderKyc.get();
        }
        throw e;
      }
    },
  });
  if (kyc.isLoading) return <Skeleton className="h-96" />;
  if (kyc.error instanceof ApiError && kyc.error.status === 403) {
    return (
      <Card className="space-y-3 p-6">
        <p>This account is not a rider yet.</p>
        <Link href="/ride" className="font-semibold text-primary hover:underline">Sign up as a rider first</Link>
      </Card>
    );
  }
  if (kyc.error || !kyc.data) return <ErrorState message={(kyc.error as Error)?.message ?? "Could not load your KYC"} />;
  return <KycSteps kyc={kyc.data} onChange={(k) => qc.setQueryData(["rider-kyc"], k)} />;
}

function KycSteps({ kyc, onChange }: { kyc: RiderKyc; onChange: (k: RiderKyc) => void }) {
  const api = useApi();
  const [address, setAddress] = useState(kyc.permanent_address);
  const [nin, setNin] = useState("");
  const [guarantors, setGuarantors] = useState<RiderKycGuarantor[]>(() =>
    [0, 1].map((i) => ({ ...EMPTY_GUARANTOR, ...(kyc.guarantors[i] ?? {}) })));
  const [message, setMessage] = useState<{ text: string; error: boolean } | null>(null);
  const [uploading, setUploading] = useState<string | null>(null);
  useEffect(() => setAddress((a) => a || kyc.permanent_address), [kyc.permanent_address]);

  const details = () => ({ permanent_address: address.trim(), guarantors, ...(nin.trim() ? { nin: nin.trim() } : {}) });
  const save = useMutation({
    mutationFn: () => api.riderKyc.update(details()),
    onSuccess: (k) => { onChange(k); setNin(""); setMessage({ text: "Saved.", error: false }); },
    onError: (e) => setMessage({ text: (e as Error).message, error: true }),
  });
  const submit = useMutation({
    mutationFn: async () => {
      onChange(await api.riderKyc.update(details()));
      setNin("");
      return api.riderKyc.submit();
    },
    onSuccess: (k) => { onChange(k); setMessage({ text: "Submitted. We check everything and let you know.", error: false }); },
    onError: (e) => setMessage({ text: (e as Error).message, error: true }),
  });
  async function upload(kind: string, file: File | undefined) {
    if (!file) return;
    setUploading(kind);
    setMessage(null);
    try {
      onChange(await api.riderKyc.upload(kind, await readForUpload(file)));
      setMessage({ text: "Uploaded.", error: false });
    } catch (e) {
      setMessage({ text: (e as Error).message, error: true });
    } finally {
      setUploading(null);
    }
  }

  const editable = kyc.editable;
  const doc = (kind: string) => (
    <DocumentRow key={kind} kind={kind} state={kyc.documents[kind]} editable={editable} busy={uploading === kind} onFile={(f) => upload(kind, f)} />
  );
  return (
    <div className="space-y-6">
      <StatusCard kyc={kyc} />
      {message && <p role={message.error ? "alert" : "status"} className={message.error ? "text-sm text-danger" : "text-sm text-muted"}>{message.text}</p>}

      <Card className="space-y-4 p-6">
        <h2 className="font-display text-2xl">Your details</h2>
        <p className="text-sm text-muted">{kyc.full_name} · WhatsApp {kyc.whatsapp_phone} · lives at {kyc.residential_address || "—"}</p>
        <Field label="Permanent address" htmlFor="pa">
          <Input id="pa" value={address} onChange={(e) => setAddress(e.target.value)} disabled={!editable} />
        </Field>
        <Field label="NIN (National Identification Number)" htmlFor="nin" hint={kyc.nin ? `Saved: ${kyc.nin}. Type it again only to change it.` : "11 digits"}>
          <Input id="nin" inputMode="numeric" maxLength={11} value={nin} onChange={(e) => setNin(e.target.value.replace(/\D/g, ""))} disabled={!editable} />
        </Field>
      </Card>

      <Card className="space-y-2 p-6">
        <h2 className="font-display text-2xl">Your vehicle papers</h2>
        {VEHICLE_DOCUMENTS.map(doc)}
      </Card>

      <Card className="space-y-4 p-6">
        <h2 className="font-display text-2xl">Your two guarantors</h2>
        <p className="text-sm text-muted">
          Each guarantor fills in and signs a printed form.{" "}
          <Link href="/ride/guarantor-form" className="inline-flex items-center gap-1 font-semibold text-primary hover:underline">
            <FileText className="size-4" /> Print the guarantor form
          </Link>
        </p>
        {guarantors.map((g, i) => (
          <fieldset key={i} className="space-y-3 rounded-xl border border-border p-4">
            <legend className="px-1 text-sm font-semibold">Guarantor {i + 1}</legend>
            <div className="grid gap-3 sm:grid-cols-2">
              {GUARANTOR_FIELDS.map(([field, label]) => (
                <Field key={field} label={label} htmlFor={`g${i}-${field}`}>
                  <Input id={`g${i}-${field}`} value={g[field]} disabled={!editable}
                    onChange={(e) => setGuarantors((all) => all.map((x, j) => (j === i ? { ...x, [field]: e.target.value } : x)))} />
                </Field>
              ))}
            </div>
            {doc(`guarantor_${i + 1}_form`)}
          </fieldset>
        ))}
      </Card>

      <Card className="space-y-2 p-6">
        <h2 className="font-display text-2xl">Face verification</h2>
        <p className="text-sm text-muted">A selfie in good light, looking straight at the camera, with nothing covering your face.</p>
        {doc("face")}
      </Card>

      {editable && (
        <div className="flex flex-wrap gap-3">
          <Button variant="outline" onClick={() => save.mutate()} loading={save.isPending}>Save details</Button>
          <Button onClick={() => submit.mutate()} loading={submit.isPending} disabled={uploading !== null}>Submit for checking</Button>
        </div>
      )}
    </div>
  );
}

function StatusCard({ kyc }: { kyc: RiderKyc }) {
  const missing = kyc.missing.length;
  const [Icon, title, body] = {
    verified: [BadgeCheck, "Verified", "You can go online in the Yummy Chops Rider app and take deliveries."],
    submitted: [Hourglass, "With the team for review", "We check everything and let you know. No changes meanwhile."],
    needs_changes: [CircleAlert, "Please fix your KYC", kyc.review_note || "The team asked for changes: see the items marked below."],
    rejected: [CircleAlert, "Not approved", kyc.review_note || "Your sign-up was not approved."],
    draft: [Circle, "Complete your KYC", missing === 0 ? "All done: submit it for checking." : `${missing === 1 ? "1 thing" : `${missing} things`} still to do: ${kyc.missing.join(", ")}.`],
  }[kyc.status] as [typeof BadgeCheck, string, string];
  return (
    <Card className="flex items-start gap-4 p-5" aria-live="polite">
      <Icon className={kyc.status === "verified" ? "size-8 text-success" : "size-8 text-primary"} aria-hidden="true" />
      <div>
        <h2 className="text-xl font-semibold">{title}</h2>
        <p className="text-sm text-muted">{body}</p>
      </div>
    </Card>
  );
}

function DocumentRow({ kind, state, editable, busy, onFile }: {
  kind: string; state?: RiderKyc["documents"][string]; editable: boolean; busy: boolean; onFile: (file: File | undefined) => void;
}) {
  const label = state?.label ?? kind;
  const form = kind.endsWith("_form");
  const done = state?.uploaded;
  const redo = state?.needs_change;
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border py-2 last:border-0">
      <div className="flex items-center gap-2">
        {redo ? <CircleAlert className="size-5 text-warning" aria-hidden="true" /> : done ? <CheckCircle2 className="size-5 text-success" aria-hidden="true" /> : <Circle className="size-5 text-muted" aria-hidden="true" />}
        <div>
          <p className="font-medium">{label}</p>
          <p className="text-xs text-muted">{redo ? "Please upload this again" : done ? "Uploaded" : "To do"}</p>
        </div>
      </div>
      {editable && (
        <label className="cursor-pointer rounded-lg border border-border px-3 py-1.5 text-sm font-semibold hover:bg-surface-muted">
          {busy ? "Uploading…" : done ? "Replace" : kind === "face" ? "Take or choose a selfie" : "Upload a photo"}
          <input
            type="file"
            className="sr-only"
            aria-label={`Upload: ${label}`}
            accept={form ? "image/*,application/pdf" : "image/*"}
            capture={kind === "face" ? "user" : form ? undefined : "environment"}
            disabled={busy}
            onChange={(e) => { onFile(e.target.files?.[0]); e.target.value = ""; }}
          />
        </label>
      )}
    </div>
  );
}
