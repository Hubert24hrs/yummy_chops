"use client";

import { ApiError, formatNaira } from "@gudmeal/api-client";
import { Button, Card, EmptyState, ErrorState, Field, Input, Skeleton } from "@gudmeal/ui";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Users } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useState } from "react";
import { groupStatusLabel } from "@/components/growth";
import { useApi } from "@/lib/api";

const errorText = (e: unknown) => (e instanceof ApiError ? e.message : "Something went wrong. Please try again.");

export function GroupHub() {
  const api = useApi();
  const router = useRouter();
  const params = useSearchParams();
  const [code, setCode] = useState(params.get("code") ?? "");
  const groups = useQuery({ queryKey: ["groups"], queryFn: () => api.groups.mine() });
  const join = useMutation({ mutationFn: () => api.groups.join(code), onSuccess: (g) => router.push(`/group/${g.id}`) });

  return (
    <div className="container-page max-w-2xl space-y-5 py-8 pb-28 md:pb-12">
      <div>
        <h1 className="font-display text-3xl">Group orders</h1>
        <p className="text-muted">Order together from one store. Everyone picks their own food, and pays their own share or lets the host pay.</p>
      </div>

      <Card className="space-y-3 p-5">
        <h2 className="text-lg font-extrabold">Join with a code</h2>
        <form className="flex flex-wrap items-end gap-3" onSubmit={(e) => { e.preventDefault(); if (code.trim()) join.mutate(); }}>
          <div className="min-w-48 flex-1">
            <Field label="Group code" htmlFor="group-code" hint="6 letters and numbers, from the host">
              <Input id="group-code" value={code} onChange={(e) => setCode(e.target.value)} className="font-mono uppercase tracking-widest" autoComplete="off" />
            </Field>
          </div>
          <Button type="submit" loading={join.isPending} disabled={!code.trim()}>Join</Button>
        </form>
        {join.error && <p className="text-sm text-danger" role="alert">{errorText(join.error)}</p>}
      </Card>

      <section className="space-y-3" aria-label="Your group orders">
        <h2 className="text-lg font-extrabold">Your group orders</h2>
        {groups.isLoading ? <Skeleton className="h-24" /> : groups.error ? (
          <ErrorState message={errorText(groups.error)} onRetry={() => groups.refetch()} />
        ) : !groups.data?.length ? (
          <EmptyState icon={<Users className="size-8 text-primary" aria-hidden="true" />} title="No group orders yet"
            body="Open any restaurant or beauty shop and tap “Order with friends” to start one, then share the code."
            action={<Link href="/food"><Button variant="outline">Find a store</Button></Link>} />
        ) : (
          <ul className="space-y-2">
            {groups.data.map((g) => (
              <li key={g.id}>
                <Link href={`/group/${g.id}`} className="flex items-center gap-3 rounded-xl border border-border bg-surface p-4 shadow-card hover:border-primary">
                  <Users className="size-5 shrink-0 text-primary" aria-hidden="true" />
                  <span className="min-w-0 flex-1">
                    <span className="block font-bold">{g.restaurant.name}</span>
                    <span className="block text-sm text-muted">{groupStatusLabel(g)} · {g.members.length} people{g.is_host ? " · you're the host" : ""}</span>
                  </span>
                  {g.my_share && <span className="text-sm font-semibold">{formatNaira(g.my_share.amount_kobo)}</span>}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
