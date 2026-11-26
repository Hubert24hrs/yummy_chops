"use client";

import { formatNaira, type MenuImportResult } from "@gudmeal/api-client";
import { Badge, Button, Dialog } from "@gudmeal/ui";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Download, FileUp } from "lucide-react";
import { useState } from "react";
import { useApi } from "@/lib/api";
import { MENU_TEMPLATE } from "@/lib/photo";

const ACTION: Record<string, { label: string; tone: "success" | "neutral" | "danger" | "warning" }> = {
  create: { label: "New", tone: "success" },
  update: { label: "Update", tone: "warning" },
  unchanged: { label: "No change", tone: "neutral" },
  error: { label: "Problem", tone: "danger" },
};

function downloadTemplate() {
  const url = URL.createObjectURL(new Blob([MENU_TEMPLATE], { type: "text/csv;charset=utf-8" }));
  const a = document.createElement("a");
  a.href = url;
  a.download = "yummy-chops-menu-template.csv";
  a.click();
  URL.revokeObjectURL(url);
}

/** Add or update a whole menu or product list from a spreadsheet saved as CSV: a preview first, then the import. */
export function ImportDialog({ rid, shop, onClose }: { rid: string; shop: boolean; onClose: () => void }) {
  const api = useApi();
  const qc = useQueryClient();
  const [csv, setCsv] = useState<string | null>(null);
  const [fileName, setFileName] = useState("");
  const [result, setResult] = useState<MenuImportResult | null>(null);
  const things = shop ? "products" : "items";

  const preview = useMutation({
    mutationFn: (text: string) => api.partner.importMenu(rid, text, false),
    onSuccess: setResult,
  });
  const apply = useMutation({
    mutationFn: () => api.partner.importMenu(rid, csv!, true),
    onSuccess: (r) => { setResult(r); qc.invalidateQueries({ queryKey: ["menu", rid] }); },
  });

  async function choose(file: File | undefined) {
    if (!file) return;
    setResult(null);
    apply.reset();
    const text = await file.text();
    setFileName(file.name);
    setCsv(text);
    preview.mutate(text);
  }

  const done = result?.applied === true;
  const count = result ? result.created + result.updated : 0;
  const error = (preview.error ?? apply.error) as Error | null;

  return (
    <Dialog open onClose={onClose} title={`Import ${things} from a spreadsheet`} footer={
      <div className="flex flex-wrap justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>{done ? "Close" : "Cancel"}</Button>
        {result && !done && (
          <Button onClick={() => apply.mutate()} loading={apply.isPending} disabled={result.errors > 0 || count === 0}>
            {result.errors > 0
              ? `Fix ${result.errors} ${result.errors === 1 ? "problem" : "problems"} first`
              : count === 0 ? "Nothing to import" : `Import ${count} ${count === 1 ? things.slice(0, -1) : things}`}
          </Button>
        )}
      </div>
    }>
      <div className="space-y-4 text-sm">
        {!done && (
          <ol className="list-decimal space-y-1 pl-5 text-muted">
            <li>Download the template and fill in one {shop ? "product" : "item"} per line: category, name and price (in naira) are needed; size, brand, description, in stock (yes / no) and tags are optional.</li>
            <li>In Excel or Google Sheets, save it as <strong>CSV</strong> (File → Save as / Download → CSV).</li>
            <li>Choose the file below. You see every change before anything is saved. Sending the same sheet again later updates prices instead of adding copies.</li>
          </ol>
        )}
        {!done && (
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" onClick={downloadTemplate}><Download className="size-4" /> Download template</Button>
            <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-border px-3 py-2 font-semibold hover:bg-surface-muted">
              <FileUp className="size-4" /> {fileName ? "Choose another file" : "Choose CSV file"}
              <input type="file" accept=".csv,text/csv" className="sr-only" aria-label="Choose CSV file"
                onChange={(e) => { void choose(e.target.files?.[0]); e.target.value = ""; }} />
            </label>
          </div>
        )}
        {preview.isPending && <p>Reading {fileName}…</p>}
        {error && <p role="alert" className="text-danger">{error.message}</p>}
        {result && (
          <div className="space-y-3">
            <p role="status" className={done ? "font-semibold text-success" : "font-semibold"}>
              {done
                ? `Done: ${result.created} added, ${result.updated} updated.`
                : `${fileName}: ${result.created} new, ${result.updated} to update, ${result.unchanged} unchanged${result.errors ? `, ${result.errors} with a problem` : ""}.`}
            </p>
            {result.new_categories.length > 0 && (
              <p className="text-muted">New categories: {result.new_categories.join(", ")}</p>
            )}
            {result.errors > 0 && !done && (
              <p className="text-danger">Fix the lines marked “Problem” in your sheet, save it as CSV again and choose it again. Nothing is saved until every line is right.</p>
            )}
            <div className="max-h-80 overflow-auto rounded-lg border border-border">
              <table className="w-full text-left text-sm">
                <thead className="sticky top-0 bg-surface-muted text-xs uppercase text-muted">
                  <tr><th className="p-2">Line</th><th className="p-2">Name</th><th className="p-2">Price</th><th className="p-2">What happens</th></tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {result.rows.map((r) => (
                    <tr key={r.row} className={r.action === "error" ? "bg-danger/5" : undefined}>
                      <td className="p-2 text-muted">{r.row}</td>
                      <td className="p-2">{r.name || "—"}<span className="block text-xs text-muted">{r.category}</span></td>
                      <td className="p-2 whitespace-nowrap">{r.price_kobo != null ? formatNaira(r.price_kobo) : "—"}</td>
                      <td className="p-2">
                        <Badge tone={ACTION[r.action]!.tone}>{ACTION[r.action]!.label}</Badge>
                        {r.error && <span className="block text-xs text-danger">{r.error}</span>}
                        {r.changes.length > 0 && <span className="block text-xs text-muted">{r.changes.join(", ")}</span>}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </Dialog>
  );
}
