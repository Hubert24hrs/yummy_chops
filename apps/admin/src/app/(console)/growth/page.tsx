"use client";

import { formatNaira, nairaToKobo, type GrowthConfig, type PlusPlanConfig } from "@gudmeal/api-client";
import { Button, Card, DataTable, ErrorState, Field, Input, Skeleton, Stat, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { useApi } from "@/lib/api";
import { settingsError } from "@/lib/errors";

const SOURCES: Record<string, string> = { points: "Yummy points", referral: "Friend's welcome gift", referrer: "Thanks for inviting" };

export default function GrowthPage() {
  const api = useApi();
  const qc = useQueryClient();
  const stats = useQuery({ queryKey: ["growth"], queryFn: () => api.admin.growth() });
  const pricing = useQuery({ queryKey: ["pricing"], queryFn: () => api.admin.pricing() });
  const config = useQuery({ queryKey: ["growth-config"], queryFn: () => api.admin.growthConfig() });
  const [plus, setPlus] = useState<PlusPlanConfig | null>(null);
  const [cfg, setCfg] = useState<GrowthConfig | null>(null);
  useEffect(() => { if (pricing.data?.plus) setPlus(pricing.data.plus); }, [pricing.data]);
  useEffect(() => { if (config.data) setCfg(config.data); }, [config.data]);

  const savePlus = useMutation({
    mutationFn: (p: PlusPlanConfig) => api.admin.updatePricing({ ...pricing.data!, plus: p }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["pricing"] }); qc.invalidateQueries({ queryKey: ["growth"] }); },
  });
  const saveGrowth = useMutation({
    mutationFn: (c: GrowthConfig) => api.admin.saveGrowthConfig(c),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["growth-config"] }),
  });

  const naira = (k: number) => (k / 100).toString();
  const num = (v: string) => Math.max(0, Math.round(Number(v) || 0));
  const s = stats.data;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-3xl">Growth</h1>
        <p className="text-sm text-muted">
          Yummy Chops Plus, Yummy points, referrals and group orders. Amounts are product defaults until the owner confirms them;
          rewards are platform-funded vouchers that settle through promotions.
        </p>
      </div>

      {stats.isLoading ? <Skeleton className="h-28" /> : stats.error ? <ErrorState message={(stats.error as Error).message} /> : s && (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <Stat label="Plus members" value={s.plus.active_members.toLocaleString()} hint={`${s.plus.auto_renew_on} renew from their wallet`} />
            <Stat label="Ending in 7 days" value={s.plus.ending_in_7_days.toLocaleString()} hint="Wallet renewals run daily" />
            <Stat label="Plus revenue" value={formatNaira(s.plus.revenue_kobo)} hint="Net of VAT, since launch" />
            <Stat label="Yummy points outstanding" value={s.rewards.points_outstanding.toLocaleString()}
              hint={`Worth ${formatNaira(s.rewards.points_outstanding_value_kobo)} in future discounts`} />
          </div>
          <Card className="space-y-3 p-5">
            <h2 className="font-semibold">Rewards</h2>
            <p className="text-sm text-muted">
              {s.rewards.customers_with_points} customers hold points · {s.rewards.referred_customers} joined with a friend&apos;s code ·{" "}
              {s.rewards.referrals_rewarded} of them completed a first order
            </p>
            <DataTable rows={Object.entries(s.rewards.vouchers)} rowKey={([k]) => k} empty="No reward vouchers yet" columns={[
              { key: "s", header: "Voucher", render: ([k]) => SOURCES[k] ?? k },
              { key: "i", header: "Issued", render: ([, v]) => v.issued },
              { key: "u", header: "Used", render: ([, v]) => v.used },
              { key: "v", header: "Value issued", render: ([, v]) => formatNaira(v.value_issued_kobo) },
            ]} />
          </Card>
        </>
      )}

      {plus && pricing.data && (
        <Card className="space-y-4 p-5">
          <div className="flex items-center justify-between gap-3">
            <h2 className="font-semibold">Yummy Chops Plus plan</h2>
            <Toggle checked={plus.enabled} label={plus.enabled ? "Open for new members" : "Paused"} onChange={(v) => setPlus({ ...plus, enabled: v })} />
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <Field label="Price (₦, VAT included)" htmlFor="pp"><Input id="pp" type="number" value={naira(plus.price_kobo)} onChange={(e) => setPlus({ ...plus, price_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
            <Field label="Period (days)" htmlFor="pd"><Input id="pd" type="number" value={plus.period_days} onChange={(e) => setPlus({ ...plus, period_days: num(e.target.value) })} /></Field>
            <Field label="Free delivery from subtotal (₦)" htmlFor="pf"><Input id="pf" type="number" value={naira(plus.free_delivery_min_subtotal_kobo)} onChange={(e) => setPlus({ ...plus, free_delivery_min_subtotal_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
            <Field label="Service fee discount (%)" htmlFor="ps"><Input id="ps" type="number" value={plus.service_fee_discount_bps / 100} onChange={(e) => setPlus({ ...plus, service_fee_discount_bps: Math.round(Number(e.target.value) * 100) })} /></Field>
            <Field label="Points multiplier" htmlFor="pm"><Input id="pm" type="number" value={plus.points_multiplier} onChange={(e) => setPlus({ ...plus, points_multiplier: num(e.target.value) })} /></Field>
            <Field label="Wallet renewal window (hours)" htmlFor="pw"><Input id="pw" type="number" value={plus.renew_window_hours} onChange={(e) => setPlus({ ...plus, renew_window_hours: num(e.target.value) })} /></Field>
          </div>
          {savePlus.error && <ErrorState message={settingsError(savePlus.error)} />}
          <Button onClick={() => savePlus.mutate(plus)} loading={savePlus.isPending}>Publish pricing v{pricing.data.version + 1}</Button>
          <p className="text-xs text-muted">The plan is part of pricing: changes apply to new quotes and new payments, and are audited.</p>
        </Card>
      )}

      {cfg && (
        <Card className="space-y-5 p-5">
          <h2 className="font-semibold">Yummy points, referrals and group orders (v{cfg.version})</h2>
          <section className="space-y-3">
            <Toggle checked={cfg.points_enabled} label="Yummy points" onChange={(v) => setCfg({ ...cfg, points_enabled: v })} />
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <Field label="Points per ₦100 spent" htmlFor="gp"><Input id="gp" type="number" value={cfg.points_per_100_naira} onChange={(e) => setCfg({ ...cfg, points_per_100_naira: num(e.target.value) })} /></Field>
              <Field label="Value of 1 point (₦)" htmlFor="gv"><Input id="gv" type="number" value={naira(cfg.point_value_kobo)} onChange={(e) => setCfg({ ...cfg, point_value_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
              <Field label="Redeem in steps of (points)" htmlFor="gs"><Input id="gs" type="number" value={cfg.redeem_step_points} onChange={(e) => setCfg({ ...cfg, redeem_step_points: num(e.target.value) })} /></Field>
              <Field label="Voucher minimum order (₦)" htmlFor="gm"><Input id="gm" type="number" value={naira(cfg.redeem_min_subtotal_kobo)} onChange={(e) => setCfg({ ...cfg, redeem_min_subtotal_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
              <Field label="Voucher valid for (days)" htmlFor="gd"><Input id="gd" type="number" value={cfg.redeem_valid_days} onChange={(e) => setCfg({ ...cfg, redeem_valid_days: num(e.target.value) })} /></Field>
            </div>
          </section>
          <section className="space-y-3">
            <Toggle checked={cfg.referrals_enabled} label="Referrals" onChange={(v) => setCfg({ ...cfg, referrals_enabled: v })} />
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <Field label="New customer's gift (₦)" htmlFor="rf"><Input id="rf" type="number" value={naira(cfg.referee_reward_kobo)} onChange={(e) => setCfg({ ...cfg, referee_reward_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
              <Field label="Reward for inviting (₦)" htmlFor="ry"><Input id="ry" type="number" value={naira(cfg.referrer_reward_kobo)} onChange={(e) => setCfg({ ...cfg, referrer_reward_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
              <Field label="Minimum order (₦)" htmlFor="rm"><Input id="rm" type="number" value={naira(cfg.referee_min_subtotal_kobo)} onChange={(e) => setCfg({ ...cfg, referee_min_subtotal_kobo: nairaToKobo(Number(e.target.value)) })} /></Field>
              <Field label="Rewards per inviter per month" htmlFor="rc"><Input id="rc" type="number" value={cfg.referrer_monthly_cap} onChange={(e) => setCfg({ ...cfg, referrer_monthly_cap: num(e.target.value) })} /></Field>
              <Field label="Vouchers valid for (days)" htmlFor="rv"><Input id="rv" type="number" value={cfg.referral_valid_days} onChange={(e) => setCfg({ ...cfg, referral_valid_days: num(e.target.value) })} /></Field>
            </div>
          </section>
          <section className="space-y-3">
            <Toggle checked={cfg.group_orders_enabled} label="Group orders" onChange={(v) => setCfg({ ...cfg, group_orders_enabled: v })} />
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <Field label="People per group (with the host)" htmlFor="go"><Input id="go" type="number" value={cfg.group_max_members} onChange={(e) => setCfg({ ...cfg, group_max_members: num(e.target.value) })} /></Field>
              <Field label="Open for (hours)" htmlFor="gh"><Input id="gh" type="number" value={cfg.group_open_hours} onChange={(e) => setCfg({ ...cfg, group_open_hours: num(e.target.value) })} /></Field>
            </div>
          </section>
          {saveGrowth.error && <ErrorState message={settingsError(saveGrowth.error)} />}
          <Button onClick={() => saveGrowth.mutate(cfg)} loading={saveGrowth.isPending}>Save growth settings v{cfg.version + 1}</Button>
        </Card>
      )}
      {(pricing.error || config.error) && <ErrorState message={((pricing.error ?? config.error) as Error).message} />}
    </div>
  );
}
