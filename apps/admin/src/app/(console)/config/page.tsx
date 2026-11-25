"use client";

import { formatNaira, nairaToKobo, type PricingConfig } from "@gudmeal/api-client";
import { Button, Card, ErrorState, Field, Input, Skeleton, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { useApi } from "@/lib/api";
import { settingsError } from "@/lib/errors";

export default function ConfigPage() {
  const api = useApi();
  const qc = useQueryClient();
  const pricing = useQuery({ queryKey: ["pricing"], queryFn: () => api.admin.pricing() });
  const flags = useQuery({ queryKey: ["flags"], queryFn: () => api.admin.flags() });
  const [cfg, setCfg] = useState<PricingConfig | null>(null);
  useEffect(() => { if (pricing.data) setCfg(pricing.data); }, [pricing.data]);
  const save = useMutation({ mutationFn: (c: PricingConfig) => api.admin.updatePricing(c), onSuccess: () => qc.invalidateQueries({ queryKey: ["pricing"] }) });
  const flag = useMutation({
    mutationFn: ({ key, enabled, description }: { key: string; enabled: boolean; description: string }) => api.admin.setFlag(key, enabled, description),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["flags"] }),
  });

  if (pricing.isLoading || !cfg) return <Skeleton className="h-96" />;
  const pct = (bps: number) => (bps / 100).toString();
  const naira = (k: number) => (k / 100).toString();
  const set = (patch: Partial<PricingConfig>) => setCfg({ ...cfg, ...patch });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-3xl">Configuration</h1>
        <p className="text-sm text-muted">Pricing version {cfg.version}. Changes create a new version, apply to new quotes only, and are audited.</p>
      </div>
      <Card className="grid gap-4 p-5 sm:grid-cols-2 lg:grid-cols-3">
        <Field label="Default commission (%)" htmlFor="c"><Input id="c" type="number" step="0.5" value={pct(cfg.default_commission_bps)} onChange={(e) => set({ default_commission_bps: Math.round(Number(e.target.value) * 100) })} /></Field>
        <Field label="Service fee (%)" htmlFor="sf"><Input id="sf" type="number" step="0.5" value={pct(cfg.service_fee_bps)} onChange={(e) => set({ service_fee_bps: Math.round(Number(e.target.value) * 100) })} /></Field>
        <Field label="VAT on platform fees (%)" htmlFor="v"><Input id="v" type="number" step="0.5" value={pct(cfg.vat_bps)} onChange={(e) => set({ vat_bps: Math.round(Number(e.target.value) * 100) })} /></Field>
        <Field label="Service fee min (₦)" htmlFor="smin"><Input id="smin" type="number" value={naira(cfg.service_fee_min_kobo)} onChange={(e) => set({ service_fee_min_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
        <Field label="Service fee max (₦)" htmlFor="smax"><Input id="smax" type="number" value={naira(cfg.service_fee_max_kobo)} onChange={(e) => set({ service_fee_max_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
        <Field label="Small-order threshold (₦)" htmlFor="sot"><Input id="sot" type="number" value={naira(cfg.small_order_threshold_kobo)} onChange={(e) => set({ small_order_threshold_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
        <Field label="Delivery base (₦)" htmlFor="db"><Input id="db" type="number" value={naira(cfg.delivery.base_kobo)} onChange={(e) => set({ delivery: { ...cfg.delivery, base_kobo: nairaToKobo(Number(e.target.value)) } })} /></Field>
        <Field label="Delivery per km (₦)" htmlFor="dk"><Input id="dk" type="number" value={naira(cfg.delivery.per_km_kobo)} onChange={(e) => set({ delivery: { ...cfg.delivery, per_km_kobo: nairaToKobo(Number(e.target.value)) } })} /></Field>
        <Field label="Rider pay per km (₦)" htmlFor="rk"><Input id="rk" type="number" value={naira(cfg.rider_pay.per_km_kobo)} onChange={(e) => set({ rider_pay: { ...cfg.rider_pay, per_km_kobo: nairaToKobo(Number(e.target.value)) } })} /></Field>
      </Card>
      <Card className="space-y-2 p-5">
        <h2 className="font-semibold">Delivery zones</h2>
        {cfg.zones.map((z, i) => (
          <div key={z.id} className="flex flex-wrap items-center gap-3 text-sm">
            <span className="w-48 font-medium">{z.name}</span>
            <span className="text-muted">{z.radius_km} km radius</span>
            <label className="flex items-center gap-2">Surge ×
              <Input type="number" step="0.1" min="1" max="3" className="h-9 w-20" value={(z.surge_bps / 10000).toString()}
                onChange={(e) => set({ zones: cfg.zones.map((x, j) => (j === i ? { ...x, surge_bps: Math.round(Number(e.target.value) * 10000) } : x)) })} />
            </label>
            <Toggle checked={z.is_active} label={z.is_active ? "Active" : "Paused"} onChange={(v) => set({ zones: cfg.zones.map((x, j) => (j === i ? { ...x, is_active: v } : x)) })} />
          </div>
        ))}
      </Card>
      {save.error && <ErrorState message={settingsError(save.error)} />}
      <div className="flex items-center gap-3">
        <Button onClick={() => save.mutate(cfg)} loading={save.isPending}>Publish pricing v{cfg.version + 1}</Button>
        <span className="text-xs text-muted">Example: a 5 km delivery is about {formatNaira(cfg.delivery.base_kobo + Math.round(cfg.delivery.per_km_kobo * 5 * 1.35))} before surge.</span>
      </div>
      <Card className="space-y-3 p-5">
        <h2 className="font-semibold">Feature flags</h2>
        {flags.error && <ErrorState message={(flags.error as Error).message} />}
        {Object.values(flags.data ?? {}).map((f) => (
          <div key={f.key} className="flex items-center justify-between gap-3 text-sm">
            <span><strong className="font-mono text-xs">{f.key}</strong> <span className="text-muted">— {f.description}</span></span>
            <Toggle checked={f.enabled} label={f.enabled ? "On" : "Off"} onChange={(v) => flag.mutate({ key: f.key, enabled: v, description: f.description })} />
          </div>
        ))}
      </Card>
    </div>
  );
}
