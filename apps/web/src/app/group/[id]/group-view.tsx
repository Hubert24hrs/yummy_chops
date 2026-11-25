"use client";

import { ApiError, formatNaira, formatTime, idempotentCalls, type CartLine, type GroupOrder, type MenuItem, type SplitMode } from "@gudmeal/api-client";
import { Badge, Button, Card, ErrorState, Field, Input, Price, Skeleton, Toggle, cn } from "@gudmeal/ui";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Lock, LockOpen, Plus, Users } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { CodeChip, GroupBill, GroupItems, groupStatusLabel, ShareButton } from "@/components/growth";
import { ItemDialog } from "@/components/item-dialog";
import { checkoutProvider, continueAfterCheckout, PaymentMethodPicker, type PayMethod } from "@/components/payment-method";
import { useApi } from "@/lib/api";

const errorText = (e: unknown) => (e instanceof ApiError ? e.message : "Something went wrong. Please try again.");

function myCartLines(g: GroupOrder, exceptLineId?: string): CartLine[] {
  const me = g.members.find((m) => m.me);
  return g.lines
    .filter((l) => l.member_uid === me?.uid && l.id !== exceptLineId)
    .map((l) => ({ item_id: l.item_id, quantity: l.quantity, selections: l.selections, notes: l.notes }));
}

export function GroupView({ id }: { id: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const router = useRouter();
  const group = useQuery({ queryKey: ["group", id], queryFn: () => api.groups.get(id), refetchInterval: 5000 });
  const g = group.data;
  const menu = useQuery({
    queryKey: ["restaurant", g?.restaurant.id],
    enabled: Boolean(g && g.status === "open"),
    queryFn: () => api.catalog.restaurant(g!.restaurant.id),
    staleTime: 60_000,
  });
  const [selected, setSelected] = useState<MenuItem | null>(null);
  const [voucher, setVoucher] = useState("");
  const [method, setMethod] = useState<PayMethod>("card");
  // One sender for each kind of payment. A request keeps its key only until the API answers it: another voucher or
  // payment method, or trying again after a refusal, is a new request (see `idempotentCalls`).
  const [send] = useState(() => ({
    checkout: idempotentCalls("group"), share: idempotentCalls("share"), rest: idempotentCalls("rest"), order: idempotentCalls("checkout"),
  }));
  const set = (next: GroupOrder) => qc.setQueryData(["group", id], next);

  const lines = useMutation({ mutationFn: (next: CartLine[]) => api.groups.setLines(id, next), onSuccess: set });
  const ready = useMutation({ mutationFn: (v: boolean) => api.groups.setReady(id, v), onSuccess: set });
  const lock = useMutation({ mutationFn: (v: boolean) => (v ? api.groups.lock(id) : api.groups.unlock(id)), onSuccess: set });
  const split = useMutation({ mutationFn: (mode: SplitMode) => api.groups.setSplitMode(id, mode), onSuccess: set });
  const place = useMutation({
    mutationFn: () => {
      const body = { voucher_code: voucher.trim() || undefined };
      return send.checkout(body, (key) => api.groups.checkout(id, key, body));
    },
    onSuccess: set,
  });
  const pay = useMutation({
    mutationFn: (rest: boolean) => {
      const body = { provider: checkoutProvider(method), cover_rest: rest };
      return (rest ? send.rest : send.share)(body, (key) => api.groups.pay(id, key, body));
    },
    onSuccess: (res) => {
      if (res.payment.authorization_url) {
        window.location.assign(res.payment.authorization_url);
        return;
      }
      set(res.group);
      qc.invalidateQueries({ queryKey: ["wallet"] });
    },
  });
  const hostPays = useMutation({
    mutationFn: () => {
      const order = g!.order!.id;
      const provider = checkoutProvider(method);
      return send.order({ order, provider }, (key) => api.orders.checkout(order, key, provider));
    },
    onSuccess: (res) => continueAfterCheckout(res, router.push),
  });
  const cancel = useMutation({ mutationFn: () => api.groups.cancel(id), onSuccess: set });
  const leave = useMutation({
    mutationFn: () => api.groups.removeMember(id, g!.members.find((m) => m.me)!.uid),
    onSuccess: () => router.push("/group"),
  });

  if (group.isLoading) return <div className="container-page max-w-3xl py-8"><Skeleton className="h-96" /></div>;
  if (group.error || !g) {
    const missing = group.error instanceof ApiError && group.error.status === 404;
    return (
      <div className="container-page max-w-3xl py-8">
        <ErrorState message={missing ? "This group order isn't available. Ask the host for the code and join from the Group orders page." : errorText(group.error)}
          onRetry={missing ? undefined : () => group.refetch()} />
      </div>
    );
  }

  const me = g.members.find((m) => m.me);
  const beforeOrder = g.status === "open" || g.status === "locked";
  const error = [lines, ready, lock, split, place, pay, hostPays, cancel, leave].map((m) => m.error).find(Boolean);
  const origin = typeof window === "undefined" ? "" : window.location.origin;

  return (
    <div className="container-page max-w-3xl space-y-5 py-8 pb-28 md:pb-12">
      <Card className="space-y-3 p-5">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="flex items-center gap-2 text-sm font-semibold text-muted">
              <Users className="size-4" aria-hidden="true" /> Group order · {g.is_host ? "you're the host" : `hosted by ${g.host_name}`}
            </p>
            <h1 className="font-display text-3xl">{g.restaurant.name}</h1>
            <p className="text-sm text-muted">
              {g.fulfillment === "delivery" ? `Delivery to ${g.delivery_area ?? "the host's address"}` : "Pickup"} ·{" "}
              {g.split_mode === "each" ? "everyone pays their share" : `${g.host_name} pays for everyone`}
            </p>
          </div>
          <Badge tone={g.status === "cancelled" || g.status === "expired" ? "danger" : g.status === "ordered" ? "success" : "progress"}>
            {groupStatusLabel(g)}
          </Badge>
        </div>
        {g.status === "open" && (
          <div className="flex flex-wrap items-center gap-3">
            <CodeChip code={g.code} />
            <ShareButton text={`Join my Yummy Chops group order at ${g.restaurant.name}, code ${g.code}:`} url={`${origin}/group?code=${g.code}`} label="Invite friends" />
            <span className="text-xs text-muted">{g.members.length}/{g.max_members} people · open until {formatTime(g.expires_at)}</span>
          </div>
        )}
        {g.cancel_reason && <p className="text-sm font-semibold text-danger">{g.cancel_reason}</p>}
      </Card>

      {g.status === "open" && (
        <Card className="space-y-3 p-5">
          <h2 className="text-lg font-extrabold">Add your items</h2>
          {menu.isLoading ? <Skeleton className="h-40" /> : menu.data ? (
            <div className="space-y-4">
              {menu.data.sections.map((s) => (
                <section key={s.category.id} aria-label={s.category.name}>
                  <h3 className="mb-2 text-sm font-bold text-muted">{s.category.name}</h3>
                  <div className="grid gap-2 sm:grid-cols-2">
                    {s.items.map((item) => (
                      <button key={item.id} type="button" disabled={!item.is_available || lines.isPending} onClick={() => setSelected(item)}
                        className="flex items-center justify-between gap-3 rounded-lg border border-border p-3 text-left text-sm hover:border-primary disabled:opacity-50">
                        <span className="min-w-0"><span className="block font-semibold">{item.name}</span><Price kobo={item.price_kobo} className="text-muted" /></span>
                        <Plus className="size-4 shrink-0 text-primary" aria-hidden="true" />
                        <span className="sr-only">Add {item.name}</span>
                      </button>
                    ))}
                  </div>
                </section>
              ))}
            </div>
          ) : <ErrorState message="The menu isn't available right now." onRetry={() => menu.refetch()} />}
        </Card>
      )}
      {selected && menu.data && (
        <ItemDialog item={selected} groups={menu.data.option_groups} restaurantId={g.restaurant.id} restaurantName={g.restaurant.name}
          onClose={() => setSelected(null)} onAdd={(line) => lines.mutate([...myCartLines(g), line])} />
      )}

      <Card className="space-y-4 p-5">
        <div className="flex items-center justify-between gap-3">
          <h2 className="text-lg font-extrabold">Everyone&apos;s items</h2>
          <span className="text-sm text-muted">{beforeOrder ? `about ${formatNaira(g.estimated_items_kobo)}` : ""}</span>
        </div>
        <GroupItems group={g} busy={lines.isPending} onRemove={g.status === "open" ? (lineId) => lines.mutate(myCartLines(g, lineId)) : undefined} />
        {g.status === "open" && me && <Toggle checked={me.ready} disabled={ready.isPending} onChange={(v) => ready.mutate(v)} label="I'm done choosing" />}
      </Card>

      {g.is_host && beforeOrder && (
        <Card className="space-y-4 p-5">
          <h2 className="text-lg font-extrabold">Place the order</h2>
          <div role="radiogroup" aria-label="Who pays" className="grid gap-2 sm:grid-cols-2">
            {([["each", "Everyone pays their share"], ["host", "I'll pay for everyone"]] as const).map(([mode, label]) => (
              <button key={mode} type="button" role="radio" aria-checked={g.split_mode === mode} onClick={() => split.mutate(mode)}
                className={cn("rounded-xl border-2 p-3 text-left text-sm font-semibold", g.split_mode === mode ? "border-primary bg-primary-soft" : "border-border")}>
                {label}
              </button>
            ))}
          </div>
          <Field label="Voucher (optional)" htmlFor="group-voucher">
            <Input id="group-voucher" value={voucher} onChange={(e) => setVoucher(e.target.value)} className="uppercase" autoComplete="off" />
          </Field>
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" loading={lock.isPending} onClick={() => lock.mutate(g.status === "open")}>
              {g.status === "open" ? <><Lock className="size-4" aria-hidden="true" /> Lock the cart</> : <><LockOpen className="size-4" aria-hidden="true" /> Unlock</>}
            </Button>
            <Button loading={place.isPending} disabled={!g.lines.length} onClick={() => place.mutate()}>Place group order</Button>
            <Button variant="ghost" loading={cancel.isPending} onClick={() => cancel.mutate()}>Cancel group order</Button>
          </div>
          <p className="text-xs text-muted">
            {g.members.filter((m) => m.ready).length} of {g.members.length} ready. Lock the cart when everyone has chosen so nothing
            changes while you check out. Prices are confirmed when you place the order.
          </p>
        </Card>
      )}
      {!g.is_host && beforeOrder && (
        <Button variant="ghost" loading={leave.isPending} onClick={() => leave.mutate()}>Leave this group order</Button>
      )}

      {g.status === "ordered" && (
        <GroupBill group={g}>
          {(g.can_pay || g.can_cover_rest) && (
            <div className="space-y-3 border-t border-border pt-3">
              <PaymentMethodPicker totalKobo={g.can_pay && g.my_share ? g.my_share.amount_kobo : g.remaining_kobo} value={method}
                onChange={setMethod} cash={{ offered: false }} />
              {g.can_pay && g.my_share && (
                <Button block size="lg" loading={pay.isPending && pay.variables === false} onClick={() => pay.mutate(false)}>
                  Pay my share · {formatNaira(g.my_share.amount_kobo)}
                </Button>
              )}
              {g.can_cover_rest && (
                <Button block variant="outline" loading={pay.isPending && pay.variables === true} onClick={() => pay.mutate(true)}>
                  Pay the rest · {formatNaira(g.remaining_kobo)}
                </Button>
              )}
            </div>
          )}
          {g.split_mode === "each" && g.my_share?.status === "paid" && g.remaining_kobo > 0 && (
            <p className="text-sm text-secondary">You&apos;ve paid your share. Waiting for the others.</p>
          )}
          {g.split_mode === "host" && g.is_host && g.order?.status === "draft" && (
            <div className="space-y-3 border-t border-border pt-3">
              <PaymentMethodPicker totalKobo={g.total_kobo} value={method} onChange={setMethod} cash={{ offered: false }} />
              <Button block size="lg" loading={hostPays.isPending} onClick={() => hostPays.mutate()}>Pay {formatNaira(g.total_kobo)}</Button>
            </div>
          )}
          {g.is_host && g.order && <Link href={`/orders/${g.order.id}`} className="inline-block text-sm font-bold text-primary underline">Track the order</Link>}
        </GroupBill>
      )}

      {error && <p className="text-sm font-semibold text-danger" role="alert">{errorText(error)}</p>}
    </div>
  );
}
