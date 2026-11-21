"use client";

import { ApiError, formatDateTime, formatNaira, newIdempotencyKey, type WalletTransaction } from "@gudmeal/api-client";
import { Button, Card, ErrorState, Field, Input, Skeleton, Toggle, cn } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowDownLeft, ArrowUpRight, Banknote, Landmark, ShieldCheck, Wallet } from "lucide-react";
import { useRef, useState } from "react";
import { useApi } from "@/lib/api";

const QUICK_AMOUNTS = [100_000, 200_000, 500_000, 1_000_000]; // ₦1,000 – ₦10,000

const toKobo = (naira: string) => Math.round(Number(naira.replace(/[^0-9.]/g, "")) * 100) || 0;
const errorText = (e: unknown) => (e instanceof ApiError ? e.message : "Something went wrong. Please try again.");

export function WalletView() {
  const api = useApi();
  const qc = useQueryClient();
  const wallet = useQuery({ queryKey: ["wallet"], queryFn: () => api.wallet.get() });
  const [amount, setAmount] = useState("");
  const topUpKey = useRef(newIdempotencyKey("topup"));

  const topUp = useMutation({
    mutationFn: (kobo: number) => api.wallet.topUp(kobo, topUpKey.current),
    onSuccess: (res) => {
      topUpKey.current = newIdempotencyKey("topup");
      if (res.authorization_url) window.location.assign(res.authorization_url);
    },
  });
  const refundPref = useMutation({
    mutationFn: (on: boolean) => api.wallet.setRefundToWallet(on),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["wallet"] }),
  });

  if (wallet.isLoading) return <div className="container-page max-w-3xl py-8"><Skeleton className="h-64" /></div>;
  if (wallet.error || !wallet.data) {
    return <div className="container-page max-w-3xl py-8"><ErrorState message={errorText(wallet.error)} onRetry={() => wallet.refetch()} /></div>;
  }
  const w = wallet.data;
  const kobo = toKobo(amount);
  const room = Math.max(0, w.limits.max_balance_kobo - w.balance_kobo);
  const amountProblem = !amount ? null
    : kobo < w.limits.min_topup_kobo ? `The minimum top-up is ${formatNaira(w.limits.min_topup_kobo)}`
      : kobo > w.limits.max_topup_kobo ? `The maximum top-up is ${formatNaira(w.limits.max_topup_kobo)}`
        : kobo > room ? `Your wallet can hold up to ${formatNaira(w.limits.max_balance_kobo)}; you can add ${formatNaira(room)} now`
          : null;

  return (
    <div className="pb-28 md:pb-12">
      <div className="bg-gradient-to-b from-[#F25C22] to-primary pb-12 pt-8 text-white">
        <div className="container-page max-w-3xl">
          <p className="flex items-center gap-2 text-sm font-semibold text-white/90"><Wallet className="size-4" aria-hidden="true" /> Yummy Chops wallet</p>
          <p className="mt-1 text-5xl font-black tracking-tight" aria-live="polite">{formatNaira(w.balance_kobo)}</p>
          <p className="mt-2 max-w-md text-sm text-white/90">Pay for food, pharmacy, beauty, groceries, foodstuff and package deliveries in one tap. Refunds come back here instantly.</p>
        </div>
      </div>

      <div className="container-page -mt-6 max-w-3xl space-y-5 rounded-t-3xl bg-background pt-5">
        {!w.enabled && <ErrorState message="Top-ups and wallet payments are paused right now. Your balance is safe." />}

        <Card className="space-y-4 p-5">
          <h2 className="text-lg font-extrabold">Top up</h2>
          <div className="flex flex-wrap gap-2" role="group" aria-label="Quick amounts">
            {QUICK_AMOUNTS.map((k) => (
              <button key={k} type="button" aria-pressed={kobo === k} onClick={() => setAmount(String(k / 100))}
                className={cn("rounded-full border-2 px-4 py-2 font-bold", kobo === k ? "border-primary bg-primary-soft" : "border-border")}>
                {formatNaira(k)}
              </button>
            ))}
          </div>
          <form className="flex flex-wrap items-end gap-3" onSubmit={(e) => { e.preventDefault(); if (kobo && !amountProblem) topUp.mutate(kobo); }}>
            <div className="min-w-48 flex-1">
              <Field label="Amount (₦)" htmlFor="topup" hint={`From ${formatNaira(w.limits.min_topup_kobo)} to ${formatNaira(w.limits.max_topup_kobo)} per top-up`}>
                <Input id="topup" inputMode="decimal" placeholder="e.g. 5000" value={amount} onChange={(e) => setAmount(e.target.value)} />
              </Field>
            </div>
            <Button type="submit" size="lg" disabled={!kobo || Boolean(amountProblem) || !w.enabled} loading={topUp.isPending}>
              Top up {kobo ? formatNaira(kobo) : ""}
            </Button>
          </form>
          {(amountProblem || topUp.error) && <p role="alert" className="text-sm font-semibold text-danger">{amountProblem ?? errorText(topUp.error)}</p>}
          <p className="flex items-start gap-2 text-xs text-muted">
            <ShieldCheck className="mt-0.5 size-4 shrink-0 text-secondary" aria-hidden="true" />
            You pay by card, bank transfer or USSD on a secure payment page. The money is added once the payment is confirmed.
            Wallet money is for Yummy Chops orders and deliveries; it can&apos;t be withdrawn as cash.
          </p>
        </Card>

        <Card className="p-5">
          <Toggle checked={w.refund_to_wallet} onChange={(on) => refundPref.mutate(on)}
            label="Send refunds for card payments to my wallet instantly (instead of back to the card, which can take days)" />
          {refundPref.error && <p className="mt-2 text-sm text-danger">{errorText(refundPref.error)}</p>}
        </Card>

        {w.seller && <SellerSection />}

        <Card className="space-y-3 p-5">
          <h2 className="text-lg font-extrabold">History</h2>
          {w.transactions.length === 0 ? (
            <p className="text-sm text-muted">No wallet activity yet. Top up to pay for your next order in one tap.</p>
          ) : (
            <ul className="divide-y divide-border">{w.transactions.map((t) => <TransactionRow key={t.id} t={t} />)}</ul>
          )}
        </Card>
      </div>
    </div>
  );
}

function TransactionRow({ t }: { t: WalletTransaction }) {
  const incoming = t.direction === "in";
  const Icon = incoming ? ArrowDownLeft : ArrowUpRight;
  return (
    <li className="flex items-center gap-3 py-3">
      <span className={cn("grid size-9 shrink-0 place-items-center rounded-full", incoming ? "bg-secondary-soft text-secondary" : "bg-surface-muted")}>
        <Icon className="size-4" aria-hidden="true" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate font-medium">{t.description}</span>
        <span className="block text-xs text-muted">{formatDateTime(t.created_at)}</span>
      </span>
      <span className={cn("font-bold", incoming && "text-secondary")}>{incoming ? "+" : "−"}{formatNaira(t.amount_kobo)}</span>
    </li>
  );
}

function SellerSection() {
  const api = useApi();
  const qc = useQueryClient();
  const seller = useQuery({ queryKey: ["seller"], queryFn: () => api.seller.balance() });
  const [move, setMove] = useState("");
  const [bank, setBank] = useState({ bank_name: "", account_number: "", account_name: "", amount: "" });
  const moveKey = useRef(newIdempotencyKey("cod-move"));
  const payoutKey = useRef(newIdempotencyKey("payout"));
  const refresh = () => Promise.all([qc.invalidateQueries({ queryKey: ["seller"] }), qc.invalidateQueries({ queryKey: ["wallet"] })]);

  const moveToWallet = useMutation({
    mutationFn: () => api.seller.moveToWallet(toKobo(move), moveKey.current),
    onSuccess: async () => { moveKey.current = newIdempotencyKey("cod-move"); setMove(""); await refresh(); },
  });
  const payout = useMutation({
    mutationFn: () => api.seller.requestPayout({
      amount_kobo: toKobo(bank.amount), bank_name: bank.bank_name.trim(),
      account_number: bank.account_number.trim(), account_name: bank.account_name.trim(),
    }, payoutKey.current),
    onSuccess: async () => {
      payoutKey.current = newIdempotencyKey("payout");
      setBank((b) => ({ ...b, amount: "" }));
      await refresh();
    },
  });

  if (!seller.data) return <Skeleton className="h-40" />;
  const s = seller.data;
  const accountOk = /^\d{10}$/.test(bank.account_number.trim());
  return (
    <Card className="space-y-4 p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="flex items-center gap-2 text-lg font-extrabold"><Banknote className="size-5 text-secondary" aria-hidden="true" /> Cash-on-delivery money</h2>
          <p className="text-sm text-muted">Collected from your buyers by our riders.</p>
        </div>
        <div className="text-right">
          <p className="text-2xl font-black">{formatNaira(s.available_kobo)}</p>
          <p className="text-xs text-muted">available{s.pending_payouts_kobo ? ` · ${formatNaira(s.pending_payouts_kobo)} being paid out` : ""}</p>
        </div>
      </div>

      <form className="flex flex-wrap items-end gap-3" onSubmit={(e) => { e.preventDefault(); moveToWallet.mutate(); }}>
        <div className="min-w-40 flex-1">
          <Field label="Move to my wallet (₦)" htmlFor="move" hint="Instant. Use it for orders and deliveries.">
            <Input id="move" inputMode="decimal" value={move} onChange={(e) => setMove(e.target.value)} />
          </Field>
        </div>
        <Button type="submit" variant="outline" disabled={!toKobo(move)} loading={moveToWallet.isPending}>Move</Button>
      </form>
      {moveToWallet.error && <p role="alert" className="text-sm text-danger">{errorText(moveToWallet.error)}</p>}

      <form className="grid gap-3 sm:grid-cols-2" onSubmit={(e) => { e.preventDefault(); payout.mutate(); }}>
        <p className="flex items-center gap-2 font-bold sm:col-span-2"><Landmark className="size-4" aria-hidden="true" /> Withdraw to your bank</p>
        <Field label="Bank" htmlFor="bank"><Input id="bank" value={bank.bank_name} onChange={(e) => setBank({ ...bank, bank_name: e.target.value })} /></Field>
        <Field label="Account number (10 digits)" htmlFor="acct">
          <Input id="acct" inputMode="numeric" maxLength={10} value={bank.account_number} onChange={(e) => setBank({ ...bank, account_number: e.target.value })} />
        </Field>
        <Field label="Account name" htmlFor="acctname"><Input id="acctname" value={bank.account_name} onChange={(e) => setBank({ ...bank, account_name: e.target.value })} /></Field>
        <Field label="Amount (₦)" htmlFor="payamt" hint={`Minimum ${formatNaira(s.min_payout_kobo)}. We review and pay within 1–2 working days.`}>
          <Input id="payamt" inputMode="decimal" value={bank.amount} onChange={(e) => setBank({ ...bank, amount: e.target.value })} />
        </Field>
        <div className="sm:col-span-2">
          <Button type="submit" disabled={!accountOk || bank.bank_name.trim().length < 2 || bank.account_name.trim().length < 2 || !toKobo(bank.amount)}
            loading={payout.isPending}>Request withdrawal</Button>
          {payout.error && <p role="alert" className="mt-2 text-sm text-danger">{errorText(payout.error)}</p>}
          {payout.isSuccess && <p className="mt-2 text-sm text-secondary">Withdrawal requested. We&apos;ll notify you when it&apos;s paid.</p>}
        </div>
      </form>

      {s.payouts.length > 0 && (
        <ul className="divide-y divide-border text-sm">
          {s.payouts.map((p) => (
            <li key={p.id} className="flex items-center justify-between gap-3 py-2">
              <span>{p.bank_name} {p.account_number} · {formatDateTime(p.requested_at)}</span>
              <span className="font-semibold">{formatNaira(p.amount_kobo)} · {p.status === "requested" ? "in review" : p.status}</span>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
