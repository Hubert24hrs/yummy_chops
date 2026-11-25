"use client";

import { ApiError, formatNaira, idempotentCalls } from "@gudmeal/api-client";
import { Button, Card, ErrorState, Skeleton, Toggle } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ShieldCheck } from "lucide-react";
import { useState } from "react";
import { PlusSummary } from "@/components/growth";
import { checkoutProvider, PaymentMethodPicker, type PayMethod } from "@/components/payment-method";
import { useApi } from "@/lib/api";

const errorText = (e: unknown) => (e instanceof ApiError ? e.message : "Something went wrong. Please try again.");

export function PlusView() {
  const api = useApi();
  const qc = useQueryClient();
  const plus = useQuery({ queryKey: ["plus"], queryFn: () => api.plus.get() });
  const [method, setMethod] = useState<PayMethod>("wallet");
  const [autoRenew, setAutoRenew] = useState(true);
  // The key is kept only until the API answers: another payment method, or trying again after a refusal, is a
  // new request (see `idempotentCalls`).
  const [sendJoin] = useState(() => idempotentCalls("plus"));

  const join = useMutation({
    mutationFn: () => {
      const provider = checkoutProvider(method);
      return sendJoin({ provider, autoRenew }, (key) => api.plus.subscribe(key, provider, autoRenew));
    },
    onSuccess: (res) => {
      if (res.payment.authorization_url) {
        window.location.assign(res.payment.authorization_url);
        return;
      }
      qc.setQueryData(["plus"], { plan: res.plan, member: res.member, membership: res.membership });
      qc.invalidateQueries({ queryKey: ["wallet"] });
    },
  });
  const renew = useMutation({
    mutationFn: (on: boolean) => api.plus.setAutoRenew(on),
    onSuccess: (res) => qc.setQueryData(["plus"], res),
  });

  if (plus.isLoading) return <div className="container-page max-w-2xl py-8"><Skeleton className="h-80" /></div>;
  if (plus.error || !plus.data) {
    return <div className="container-page max-w-2xl py-8"><ErrorState message={errorText(plus.error)} onRetry={() => plus.refetch()} /></div>;
  }
  const data = plus.data;
  const m = data.membership;
  const canJoin = data.plan.enabled && (!data.member || Boolean(m?.can_renew));

  return (
    <div className="container-page max-w-2xl space-y-5 py-8 pb-28 md:pb-12">
      <PlusSummary data={data}>
        {data.member && m && (
          <Card className="space-y-2 p-5">
            <Toggle checked={m.auto_renew} disabled={renew.isPending} onChange={(on) => renew.mutate(on)}
              label="Renew automatically from my Yummy Chops wallet" />
            {!m.auto_renew && <p className="text-sm text-muted">Auto-renew is off: your benefits stay until {m.paid_through_text}. Turn it back on any time.</p>}
            {renew.error && <p className="text-sm text-danger" role="alert">{errorText(renew.error)}</p>}
          </Card>
        )}
        {!data.plan.enabled && <ErrorState message="Joining Yummy Chops Plus is paused right now." />}
        {canJoin && (
          <Card className="space-y-4 p-5">
            <h2 className="text-lg font-extrabold">{data.member ? "Renew early" : "Join Yummy Chops Plus"}</h2>
            <PaymentMethodPicker totalKobo={data.plan.price_kobo} value={method} onChange={setMethod} cash={{ offered: false }} />
            <label className="flex items-start gap-2 text-sm">
              <input type="checkbox" checked={autoRenew} onChange={(e) => setAutoRenew(e.target.checked)} className="mt-1 accent-[var(--gm-primary)]" />
              <span>Renew automatically from my Yummy Chops wallet every {data.plan.period_days} days. I can turn this off at any time.</span>
            </label>
            <Button size="lg" block loading={join.isPending} onClick={() => join.mutate()}>
              {data.member ? "Renew" : "Join"} for {formatNaira(data.plan.price_kobo)}{method === "wallet" ? " from wallet" : ""}
            </Button>
            {join.error && <p className="text-sm font-semibold text-danger" role="alert">{errorText(join.error)}</p>}
            <p className="flex items-start gap-2 text-xs text-muted">
              <ShieldCheck className="mt-0.5 size-4 shrink-0 text-secondary" aria-hidden="true" />
              Benefits start as soon as the payment is confirmed. Turning auto-renew off cancels the membership at the
              end of the period you paid for; fees for days already paid are not refunded.
            </p>
          </Card>
        )}
      </PlusSummary>
    </div>
  );
}
