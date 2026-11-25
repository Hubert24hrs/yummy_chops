"use client";

import { ApiError, formatNaira, idempotentCalls } from "@gudmeal/api-client";
import { Button, Card, ErrorState, Field, Input, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { RewardsSummary } from "@/components/growth";
import { useApi } from "@/lib/api";

const errorText = (e: unknown) => (e instanceof ApiError ? e.message : "Something went wrong. Please try again.");

export function RewardsView() {
  const api = useApi();
  const qc = useQueryClient();
  const rewards = useQuery({ queryKey: ["rewards"], queryFn: () => api.rewards.get() });
  // The key is kept only until the API answers: other points, or trying again after a refusal, is a new request.
  const [sendRedeem] = useState(() => idempotentCalls("redeem"));
  const [code, setCode] = useState("");

  const redeem = useMutation({
    mutationFn: (points: number) => sendRedeem({ points }, (key) => api.rewards.redeem(points, key)),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["rewards"] });
    },
  });
  const apply = useMutation({
    mutationFn: () => api.rewards.applyReferral(code),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["rewards"] }),
  });

  if (rewards.isLoading) return <div className="container-page max-w-2xl py-8"><Skeleton className="h-80" /></div>;
  if (rewards.error || !rewards.data) {
    return <div className="container-page max-w-2xl py-8"><ErrorState message={errorText(rewards.error)} onRetry={() => rewards.refetch()} /></div>;
  }
  const data = rewards.data;
  return (
    <div className="container-page max-w-2xl space-y-5 py-8 pb-28 md:pb-12">
      <h1 className="sr-only">Rewards</h1>
      <RewardsSummary data={data} onRedeem={(p) => redeem.mutate(p)} redeeming={redeem.isPending} />
      {redeem.data && (
        <p className="rounded-md bg-secondary-soft p-3 text-sm font-semibold text-secondary" role="status">
          Your {formatNaira(redeem.data.voucher.value_kobo)} voucher {redeem.data.voucher.code} is ready. Pick it at checkout.
        </p>
      )}
      {redeem.error && <p className="text-sm text-danger" role="alert">{errorText(redeem.error)}</p>}
      {data.referral.can_apply && (
        <Card className="space-y-3 p-5">
          <h2 className="text-lg font-extrabold">Got a friend&apos;s code?</h2>
          <form className="flex flex-wrap items-end gap-3" onSubmit={(e) => { e.preventDefault(); if (code.trim()) apply.mutate(); }}>
            <div className="min-w-48 flex-1">
              <Field label="Referral code" htmlFor="ref-code" hint={`Get ${formatNaira(data.referral.friend_gets_kobo)} off your first order`}>
                <Input id="ref-code" value={code} onChange={(e) => setCode(e.target.value)} className="uppercase" autoComplete="off" />
              </Field>
            </div>
            <Button type="submit" loading={apply.isPending} disabled={!code.trim()}>Apply</Button>
          </form>
          {apply.error && <p className="text-sm text-danger" role="alert">{errorText(apply.error)}</p>}
        </Card>
      )}
      {apply.data?.voucher && (
        <p className="rounded-md bg-secondary-soft p-3 text-sm font-semibold text-secondary" role="status">
          Welcome! {formatNaira(apply.data.voucher.value_kobo)} off your first order is waiting at checkout.
        </p>
      )}
    </div>
  );
}
