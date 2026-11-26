"use client";

import { formatDateTime, formatNaira } from "@gudmeal/api-client";
import { ErrorState, Price, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Receipt as ReceiptIcon } from "lucide-react";
import Link from "next/link";
import { RequireAuth } from "@/components/require-auth";
import { EmptyBlock } from "@/components/storefront";
import { useApi } from "@/lib/api";

export default function ReceiptsPage() {
  return <RequireAuth><Receipts /></RequireAuth>;
}

/** My receipts (ADR-0019): every receipt the customer printed after paying, on any device. */
function Receipts() {
  const api = useApi();
  const list = useQuery({ queryKey: ["receipts"], queryFn: () => api.receipts.list() });
  return (
    <div className="container-page max-w-3xl pb-28 pt-6 md:pb-12">
      <h1 className="text-4xl font-black tracking-tight">My receipts</h1>
      <p className="mt-1 text-muted">Receipts you printed after paying. Open one to read it or print another copy.</p>
      <div className="mt-6">
        {list.isLoading ? (
          <Skeleton className="h-40" />
        ) : list.error ? (
          <ErrorState message={(list.error as Error).message} onRetry={() => list.refetch()} />
        ) : (list.data ?? []).length === 0 ? (
          <EmptyBlock
            icon={<ReceiptIcon className="size-8" aria-hidden="true" />}
            title="No receipts yet"
            body="After you pay for an order, press the red PRINT button on the receipt printer. Your receipt is then kept here."
            action={<Link href="/orders" className="font-semibold text-primary">My orders</Link>}
          />
        ) : (
          <ul className="space-y-3">
            {list.data!.map((r) => (
              <li key={r.id}>
                <Link href={`/orders/${r.order_id}/receipt`} className="flex items-center gap-4 rounded-2xl border border-border bg-surface p-4 hover:border-primary">
                  <span className="grid size-11 shrink-0 place-items-center rounded-full bg-primary-soft text-primary">
                    <ReceiptIcon className="size-5" aria-hidden="true" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block font-bold">{r.seller}</span>
                    <span className="block truncate text-sm text-muted">{r.service_name} · {r.number} · {formatDateTime(r.paid_at ?? r.issued_at)}</span>
                  </span>
                  <span className="shrink-0 text-right font-bold">
                    <Price kobo={r.total_kobo} />
                    {r.refunded_kobo > 0 && <span className="block text-xs font-normal text-muted">Refunded {formatNaira(r.refunded_kobo)}</span>}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
