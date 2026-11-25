"use client";

import { formatNaira, type CheckoutResult, type MultiCheckoutResult } from "@gudmeal/api-client";
import { cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { Banknote, CreditCard, Wallet } from "lucide-react";
import Link from "next/link";
import { useEffect } from "react";
import { publicApi, useApi } from "@/lib/api";

export type PayMethod = "card" | "wallet" | "cash";

/** Provider value sent to checkout: none for card (the server picks the gateway, with failover). */
export function checkoutProvider(method: PayMethod): string | undefined {
  return method === "card" ? undefined : method;
}

const PAID_TOGETHER_KEY = "gudmeal.checkout.orders.v1";

/**
 * A card payment for several orders (one per shop) comes back to /checkout/callback with the first order's id only.
 * The page remembers which orders the payment covers, so the return page can show all of them.
 */
export function rememberPaidTogether(reference: string | null, orderIds: string[]): void {
  try {
    if (reference && orderIds.length > 1) window.sessionStorage.setItem(PAID_TOGETHER_KEY, JSON.stringify({ reference, orderIds }));
    else window.sessionStorage.removeItem(PAID_TOGETHER_KEY);
  } catch {
    /* storage unavailable: the return page still verifies the payment and shows the first order */
  }
}

/** The orders one payment covered, when it covered more than one (see `rememberPaidTogether`). */
export function ordersPaidTogether(reference: string | null): string[] {
  try {
    const saved = JSON.parse(window.sessionStorage.getItem(PAID_TOGETHER_KEY) ?? "null") as { reference: string; orderIds: string[] } | null;
    return saved && reference && saved.reference === reference && Array.isArray(saved.orderIds) ? saved.orderIds : [];
  } catch {
    return [];
  }
}

/**
 * Card payments continue on the gateway's page; wallet and cash orders are already placed. Works for one order
 * (`POST /v1/orders/{id}/checkout`) and for one payment covering several (`POST /v1/checkouts`).
 */
export function continueAfterCheckout(res: CheckoutResult | MultiCheckoutResult, go: (path: string) => void): void {
  const orderIds = "order_ids" in res ? res.order_ids : [res.order_id];
  if (res.authorization_url) {
    rememberPaidTogether(res.reference, orderIds);
    window.location.assign(res.authorization_url);
  } else if (orderIds.length > 1) {
    // Several shops: each order is listed on its own on the Orders page.
    go("/orders");
  } else {
    // Paid from the wallet: the money has moved, so the receipt printer comes next (ADR-0019). A
    // pay-on-delivery order is paid at the door; its receipt is on the order page once the cash is in.
    go(res.provider === "wallet" ? `/orders/${orderIds[0]}/receipt` : `/orders/${orderIds[0]}`);
  }
}

interface CashRules {
  /** Whether this kind of order can be paid in cash at the door at all (not for packages). */
  offered: boolean;
  /** A reason the page already knows (e.g. pickup orders). */
  reason?: string | null;
}

/**
 * Card / Yummy Chops wallet / pay on delivery. The hints here (balance, first order, limits) come from the API so
 * customers see why an option is off, but the server re-checks everything at checkout.
 */
export function PaymentMethodPicker({ totalKobo, value, onChange, cash, variant = "cards" }: {
  totalKobo: number | null; value: PayMethod; onChange: (m: PayMethod) => void; cash: CashRules;
  /** "rows": a plain list with a radio dot on the right (checkout), "cards": bordered tiles. */
  variant?: "cards" | "rows";
}) {
  const api = useApi();
  const wallet = useQuery({ queryKey: ["wallet"], queryFn: () => api.wallet.get() });
  const summary = useQuery({ queryKey: ["order-summary"], queryFn: () => api.orders.summary(), enabled: cash.offered });
  const config = useQuery({
    queryKey: ["public-config"], queryFn: () => publicApi.catalog.publicConfig(), enabled: cash.offered, staleTime: 300_000,
  });

  const enabled = wallet.data?.enabled ?? false;
  const balance = wallet.data?.balance_kobo ?? 0;
  const short = totalKobo == null ? 0 : Math.max(0, totalKobo - balance);
  const walletOk = enabled && totalKobo != null && short === 0;

  const pod = config.data?.pay_on_delivery as { enabled: boolean; max_order_kobo: number } | undefined;
  let cashReason: string | null = cash.reason ?? null;
  if (!cashReason && cash.offered) {
    if (pod && !pod.enabled) cashReason = "Not available right now";
    else if (summary.data && summary.data.completed_count < 1) cashReason = "Unlocks after your first order";
    else if (pod && totalKobo != null && totalKobo > pod.max_order_kobo) cashReason = `For orders up to ${formatNaira(pod.max_order_kobo)}`;
  }
  const cashOk = cash.offered && !cashReason;

  useEffect(() => {
    if ((value === "wallet" && wallet.data && !walletOk) || (value === "cash" && !cashOk)) onChange("card");
  }, [value, wallet.data, walletOk, cashOk, onChange]);

  const options: { id: PayMethod; Icon: typeof Wallet; title: string; note: string; ok: boolean }[] = [
    { id: "card", Icon: CreditCard, title: "Card, bank transfer or USSD", note: "On a secure payment page", ok: true },
    {
      id: "wallet", Icon: Wallet, title: "Yummy Chops wallet",
      note: wallet.isLoading ? "Checking your balance…"
        : !enabled ? "Not available right now"
          : walletOk ? `Balance ${formatNaira(balance)} · pays in one tap`
            : `Balance ${formatNaira(balance)} · top up ${formatNaira(short)} more`,
      ok: walletOk,
    },
  ];
  if (cash.offered) {
    options.push({
      id: "cash", Icon: Banknote, title: "Pay on delivery",
      note: cashOk ? "Pay the rider in cash when it arrives" : (cashReason ?? ""), ok: cashOk,
    });
  }

  return (
    <div className="space-y-2">
      <div role="radiogroup" aria-label="Payment method" className={variant === "rows" ? "divide-y divide-border" : "space-y-2"}>
        {options.map(({ id, Icon, title, note, ok }) => variant === "rows" ? (
          <button key={id} type="button" role="radio" aria-checked={value === id} disabled={!ok} onClick={() => onChange(id)}
            className={cn("flex w-full items-center gap-4 py-4 text-left", !ok && "cursor-not-allowed opacity-60")}>
            <Icon className="size-6 shrink-0" aria-hidden="true" />
            <span className="min-w-0 flex-1">
              <span className="block font-semibold">{title}</span>
              <span className="block text-sm text-muted">{note}</span>
            </span>
            <span aria-hidden="true" className={cn("grid size-6 shrink-0 place-items-center rounded-full border-2",
              value === id ? "border-primary" : "border-border")}>
              {value === id && <span className="size-3 rounded-full bg-primary" />}
            </span>
          </button>
        ) : (
          <button key={id} type="button" role="radio" aria-checked={value === id} disabled={!ok} onClick={() => onChange(id)}
            className={cn("flex w-full items-center gap-3 rounded-xl border-2 p-3 text-left transition",
              value === id ? "border-primary bg-primary-soft" : "border-border hover:border-primary/40",
              !ok && "cursor-not-allowed opacity-60")}>
            <Icon className="size-5 shrink-0 text-primary" aria-hidden="true" />
            <span className="min-w-0 flex-1">
              <span className="block font-semibold">{title}</span>
              <span className="block text-sm text-muted">{note}</span>
            </span>
          </button>
        ))}
      </div>
      {enabled && !walletOk && !wallet.isLoading && (
        <Link href="/wallet" className="inline-block text-sm font-semibold text-primary underline-offset-2 hover:underline">
          Top up your wallet
        </Link>
      )}
    </div>
  );
}
