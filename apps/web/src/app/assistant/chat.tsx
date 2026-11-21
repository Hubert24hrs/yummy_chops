"use client";

import { ApiError, type ChatApproval, type ChatCard, type ChatResponse } from "@gudmeal/api-client";
import { Badge, Button, Card, Spinner, cn } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { CreditCard, Headset, Mic, Package, Send, ShieldCheck, Store } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { GudyArt } from "@/components/illustrations";
import { RequireAuth } from "@/components/require-auth";
import { useAgentsApi, useApi } from "@/lib/api";
import { CITY_NAMES, useLocation } from "@/lib/location";
import { SERVICES, serviceCopy } from "@/lib/services";

interface Turn { role: "user" | "assistant"; text: string; cards?: ChatCard[]; approval?: ChatApproval | null }

export function Chat() {
  return (
    <RequireAuth reason="Sign in so Yummy can use your saved address, preferences and orders.">
      <ChatInner />
    </RequireAuth>
  );
}

type SpeechRecognitionLike = { lang: string; interimResults: boolean; start: () => void; onresult: ((e: { results: { 0: { transcript: string } }[] }) => void) | null; onend: (() => void) | null };

function ChatInner() {
  const agents = useAgentsApi();
  const api = useApi();
  const { area } = useLocation();
  const params = useSearchParams();
  const [turns, setTurns] = useState<Turn[]>([]);
  const [threadId, setThreadId] = useState<string | null>(null);
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [listening, setListening] = useState(false);
  const started = useRef(false);
  const bottom = useRef<HTMLDivElement>(null);
  const addresses = useQuery({ queryKey: ["addresses"], queryFn: () => api.me.addresses() });

  useEffect(() => bottom.current?.scrollIntoView({ behavior: "smooth" }), [turns, busy]);

  function apply(res: ChatResponse) {
    setThreadId(res.thread_id);
    setTurns((t) => [...t, {
      role: "assistant",
      text: res.status === "approval_required" ? "Please review and approve:" : (res.reply ?? ""),
      cards: res.cards, approval: res.approval,
    }]);
  }

  async function send(message: string) {
    if (!message.trim() || busy) return;
    setError(null);
    setTurns((t) => [...t, { role: "user", text: message }]);
    setText("");
    setBusy(true);
    try {
      const saved = addresses.data?.[0];
      const city = CITY_NAMES[area.city];
      const delivery_address = saved ?? { label: area.name, line1: `${area.name}, ${city}`, area: area.name, city, state: city, location: area.location };
      apply(await agents.chat({ message, thread_id: threadId, channel: "web", delivery_address: threadId ? undefined : delivery_address }));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Yummy is unavailable right now.");
    } finally {
      setBusy(false);
    }
  }

  async function decide(approval: ChatApproval, approved: boolean) {
    if (!threadId) return;
    setBusy(true);
    setTurns((t) => t.map((turn) => (turn.approval === approval ? { ...turn, approval: null, text: approved ? "Approved ✓" : "Declined" } : turn)));
    try {
      apply(await agents.approve(threadId, approved, approval.tool_call_id));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Could not send your decision.");
    } finally {
      setBusy(false);
    }
  }

  function listen() {
    const W = window as unknown as { SpeechRecognition?: new () => SpeechRecognitionLike; webkitSpeechRecognition?: new () => SpeechRecognitionLike };
    const Ctor = W.SpeechRecognition ?? W.webkitSpeechRecognition;
    if (!Ctor) { setError("Voice input isn't supported in this browser."); return; }
    const rec = new Ctor();
    rec.lang = "en-NG";
    rec.interimResults = false;
    rec.onresult = (e) => setText(e.results[0]?.[0]?.transcript ?? "");
    rec.onend = () => setListening(false);
    setListening(true);
    rec.start();
  }

  useEffect(() => {
    const q = params.get("q");
    if (q && !started.current && !addresses.isLoading) {
      started.current = true;
      void send(q);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params, addresses.isLoading]);

  return (
    <div className="container-page flex max-w-3xl flex-col py-6" style={{ minHeight: "calc(100dvh - 4rem)" }}>
      <div className="mb-4 flex items-center gap-3">
        <GudyArt blink className="size-11 shrink-0" />
        <div>
          <h1 className="text-2xl font-extrabold">Yummy</h1>
          <p className="text-xs text-muted">AI assistant · replies in your language · delivering to {addresses.data?.[0]?.line1 ?? area.name} · you approve every order before paying</p>
        </div>
      </div>

      <div className="flex-1 space-y-4" aria-live="polite">
        {turns.length === 0 && (
          <Card className="space-y-2 p-5 text-sm">
            <p className="font-semibold">Hi! I’m Yummy. I can find food, groceries, foodstuff, pharmacy items and beauty products, plan a meal within your budget, send packages across Lagos and Enugu, track orders and tell you how much you’ve spent. Write in English, Pidgin, Igbo, Yoruba or Hausa.</p>
            <p className="pt-1 text-muted">Try asking:</p>
            {["I have ₦10,000. Find me the best meal for two people, order it, and deliver before 8pm.",
              "What do you offer?", "How much have I spent?", "Find me a good sunscreen", "Abeg, where my order dey?", "I want to talk to a person"].map((s) => (
              <button key={s} onClick={() => send(s)} className="block w-full rounded-md bg-surface-muted px-3 py-2 text-left hover:bg-primary-soft">{s}</button>
            ))}
          </Card>
        )}
        {turns.map((turn, i) => (
          <div key={i} className={cn("flex items-end gap-2", turn.role === "user" ? "justify-end" : "justify-start")}>
            {turn.role === "assistant" && <GudyArt className="size-8 shrink-0" />}
            <div className={cn("max-w-[88%] space-y-3 rounded-lg px-4 py-3 text-sm",
              turn.role === "user" ? "rounded-br-sm bg-primary text-on-primary" : "rounded-bl-sm border border-border bg-surface")}>
              {turn.text && <p className="whitespace-pre-wrap">{turn.text}</p>}
              {turn.cards?.map((card, j) => <CardView key={j} card={card} />)}
              {turn.approval && <ApprovalCard approval={turn.approval} onDecide={(ok) => decide(turn.approval!, ok)} busy={busy} />}
            </div>
          </div>
        ))}
        {busy && <div className="flex items-center gap-2 text-sm text-muted"><Spinner className="size-4" /> Yummy is thinking…</div>}
        {error && <p role="alert" className="rounded-md bg-accent-soft p-3 text-sm">{error}</p>}
        <div ref={bottom} />
      </div>

      <form onSubmit={(e) => { e.preventDefault(); void send(text); }}
        className="sticky bottom-4 mt-4 flex items-center gap-2 rounded-full border border-border bg-surface p-1.5 pl-4 shadow-raised">
        <label htmlFor="msg" className="sr-only">Message</label>
        <input id="msg" value={text} onChange={(e) => setText(e.target.value)} maxLength={2000} placeholder="Ask Yummy anything…"
          className="min-w-0 flex-1 bg-transparent py-2 text-sm outline-none" disabled={busy} />
        <button type="button" onClick={listen} aria-label="Speak" className={cn("rounded-full p-2 hover:bg-surface-muted", listening && "text-primary")}>
          <Mic className="size-5" />
        </button>
        <Button type="submit" disabled={!text.trim() || busy} aria-label="Send"><Send className="size-4" /></Button>
      </form>
    </div>
  );
}

const SCREENS: Record<string, string> = {
  home: "/", food: "/food", grocery: "/groceries", pharmacy: "/pharmacy", market: "/foodstuff", beauty: "/beauty", parcel: "/send",
  discover: "/discover", orders: "/orders",
  support: "/support", profile: "/account", wallet: "/wallet", waybill: "/send?mode=interstate",
  plus: "/plus", rewards: "/rewards", group: "/group",
};

/** Route for a screen Yummy points to (`open_screen` card). */
export function routeForScreen(screen: string, params: Record<string, string | undefined> = {}): string | null {
  if (screen === "merchant") return params.merchant_id ? `/restaurants/${params.merchant_id}` : null;
  if (screen === "order") return params.order_id ? `/orders/${params.order_id}` : "/orders";
  const base = SCREENS[screen];
  if (!base) return null;
  return params.category && SERVICES.some((s) => s.id === screen) ? `${base}?category=${params.category}` : base;
}

const SERVICE_ROUTES: Record<string, string> = { ...Object.fromEntries(SERVICES.map((s) => [s.id, s.href])), parcel: "/send" };

function CardView({ card }: { card: ChatCard }) {
  if (card.type === "services") {
    const services = (card.services as { id: string; name: string }[]) ?? [];
    return (
      <div className="flex flex-wrap gap-2">
        {services.map((s) => {
          const Icon = s.id === "parcel" ? Package : serviceCopy(s.id).icon;
          return (
            <Link key={s.id} href={SERVICE_ROUTES[s.id] ?? "/"} className="inline-flex items-center gap-1.5 rounded-full border border-border bg-background px-3 py-1.5 text-xs font-semibold hover:border-primary">
              <Icon className="size-4 text-primary" aria-hidden="true" /> {s.name}
            </Link>
          );
        })}
      </div>
    );
  }
  if (card.type === "navigate") {
    const href = routeForScreen(String(card.screen), (card.params as Record<string, string>) ?? {});
    if (!href) return null;
    return <Link href={href} className="inline-flex rounded-full bg-primary-soft px-4 py-2 text-xs font-bold text-primary-strong">{String(card.label)} →</Link>;
  }
  if (card.type === "wallet") {
    const recent = (card.recent as { what: string; amount: string }[]) ?? [];
    return (
      <Link href="/wallet" className="block rounded-md bg-gradient-to-b from-[#F25C22] to-primary p-3 text-white">
        <p className="text-xs font-semibold">Yummy Chops wallet</p>
        <p className="text-2xl font-black">{String(card.balance)}</p>
        {recent.slice(0, 3).map((t, i) => <p key={i} className="text-xs">{t.what}: {t.amount}</p>)}
        {card.cash_on_delivery_balance ? <p className="text-xs">Cash on delivery: {String(card.cash_on_delivery_balance)}</p> : null}
        <p className="mt-1 text-xs font-bold underline">Open wallet · top up</p>
      </Link>
    );
  }
  if (card.type === "plus") {
    const benefits = (card.benefits as string[]) ?? [];
    return (
      <Link href="/plus" className="block rounded-md bg-gradient-to-br from-[#3A1A0C] to-primary p-3 text-white">
        <p className="text-xs font-semibold">Yummy Chops Plus · {String(card.price)}</p>
        {card.member ? <p className="text-sm font-black">Member until {String(card.member_until)} · saved {String(card.saved)}</p>
          : benefits.map((b) => <p key={b} className="text-xs">✓ {b}</p>)}
        <p className="mt-1 text-xs font-bold underline">{card.member ? "Open Plus" : "Join Plus"}</p>
      </Link>
    );
  }
  if (card.type === "rewards") {
    const vouchers = (card.vouchers as { code: string; worth: string }[]) ?? [];
    return (
      <Link href="/rewards" className="block space-y-1 rounded-md border border-border bg-background p-3 text-xs">
        <p className="text-sm font-black">{Number(card.points).toLocaleString()} Yummy points</p>
        <p>Referral code <span className="font-mono font-bold">{String(card.referral_code)}</span></p>
        {vouchers.map((v) => <p key={v.code}>{v.worth} off · <span className="font-mono">{v.code}</span></p>)}
        <p className="font-bold text-primary underline">Open Rewards</p>
      </Link>
    );
  }
  if (card.type === "group_orders") {
    const groups = (card.groups as { store: string; status: string; group_order_id: string; join_code?: string; your_share?: string }[]) ?? [];
    return (
      <div className="space-y-1 rounded-md border border-border bg-background p-3 text-xs">
        {groups.length === 0 ? <p>No group orders right now.</p> : groups.map((g) => (
          <Link key={g.group_order_id} href={`/group/${g.group_order_id}`} className="block">
            <strong>{g.store}</strong>: {g.status}{g.join_code ? ` · code ${g.join_code}` : ""}{g.your_share ? ` · your share ${g.your_share}` : ""}
          </Link>
        ))}
        <Link href="/group" className="font-bold text-primary underline">Open group orders</Link>
      </div>
    );
  }
  if (card.type === "waybill_options") {
    const rows = (card.destinations as { to: string; price_from: string; transit: string; door_delivery: boolean; collection_points: string[] }[]) ?? [];
    return (
      <div className="space-y-2 rounded-md border border-border bg-background p-3 text-xs">
        <p className="font-semibold">From {String(card.from)}</p>
        <ul className="space-y-1">
          {rows.map((d) => (
            <li key={d.to}><strong>{d.to}</strong>: from {d.price_from} · {d.transit} · {d.door_delivery ? "door delivery" : `collect at ${d.collection_points.join(", ")}`}</li>
          ))}
        </ul>
        <Link href="/send?mode=interstate" className="inline-flex rounded-full bg-primary-soft px-4 py-2 font-bold text-primary-strong">Send to another city →</Link>
      </div>
    );
  }
  if (card.type === "waybill_tracking") {
    const history = (card.history as string[]) ?? [];
    return (
      <div className="space-y-1 rounded-md border border-border bg-background p-3 text-xs">
        <p className="font-mono font-bold">{String(card.tracking_code)} · {String(card.route)}</p>
        <p className="text-sm font-bold">{String(card.status)}</p>
        {!card.delivered && <p>Expected {String(card.expected)}</p>}
        {history.length > 0 && <p className="text-muted">{history.join(" → ")}</p>}
        <Link href={`/track/${String(card.tracking_code)}`} className="font-bold text-primary underline">Open tracking</Link>
      </div>
    );
  }
  if (card.type === "payment_options") {
    const methods = (card.methods as { method: string; available: boolean; why_not?: string }[]) ?? [];
    return (
      <ul className="space-y-1 rounded-md border border-border bg-background p-3 text-xs">
        {methods.map((m) => (
          <li key={m.method} className={cn("flex gap-2", !m.available && "text-muted")}>
            <span aria-hidden="true">{m.available ? "✓" : "✗"}</span>
            <span><strong>{m.method}</strong>{m.why_not ? ` · ${m.why_not}` : ""}</span>
          </li>
        ))}
      </ul>
    );
  }
  if (card.type === "order_totals") {
    const byService = (card.by_service as Record<string, { orders: number; spent: string }>) ?? {};
    return (
      <div className="rounded-md bg-gradient-to-b from-[#F25C22] to-primary p-3 text-white">
        <p className="text-2xl font-black">{String(card.total_spent)}</p>
        <p className="text-xs">{String(card.paid_orders)} paid order(s) · {String(card.spent_this_month)} this month</p>
        {Object.entries(byService).map(([k, v]) => <p key={k} className="text-xs">{k}: {v.spent} ({v.orders})</p>)}
      </div>
    );
  }
  if (card.type === "restaurants") {
    const items = (card.items as { restaurant_id: string; name: string; service?: string; eta_minutes?: number | null; delivery_fee?: string | null }[]) ?? [];
    return (
      <ul className="divide-y divide-border rounded-md border border-border bg-background">
        {items.slice(0, 5).map((r) => (
          <li key={r.restaurant_id}>
            <Link href={`/restaurants/${r.restaurant_id}`} className="flex items-center gap-2 p-2 text-xs hover:bg-surface-muted">
              <Store className="size-4 text-primary" aria-hidden="true" />
              <span className="flex-1 font-semibold">{r.name}</span>
              <span className="text-muted">{[r.eta_minutes ? `${r.eta_minutes} min` : null, r.delivery_fee].filter(Boolean).join(" · ")}</span>
            </Link>
          </li>
        ))}
      </ul>
    );
  }
  if (card.type === "parcel_quote") {
    const q = card.quote as { size: string; distance_km: number; from: string; to: string; pickup: string; estimated_delivery: string; total: string };
    return (
      <div className="space-y-0.5 rounded-md border border-border bg-background p-3 text-xs">
        <p className="font-semibold">Package · {q.size} · {q.distance_km} km</p>
        <p>From {q.from}</p>
        <p>To {q.to}</p>
        <p className="text-muted">{q.pickup} · arrives ~{q.estimated_delivery}</p>
        <p className="text-sm font-bold">Total {q.total}</p>
      </div>
    );
  }
  if (card.type === "support_contacts") {
    return (
      <Link href="/support" className="inline-flex items-center gap-1.5 rounded-full bg-primary-soft px-4 py-2 text-xs font-bold text-primary-strong">
        <Headset className="size-4" aria-hidden="true" /> Open Support
      </Link>
    );
  }
  if (card.type === "meal_plans") {
    const plans = (card.plans as { plan_ref: string; restaurant: string; items: string[]; total: string; arrives_around: string | null }[]) ?? [];
    return (
      <div className="grid gap-2">
        {plans.map((p) => (
          <div key={p.plan_ref} className="rounded-md border border-border bg-background p-3">
            <div className="flex items-center justify-between gap-2"><p className="font-semibold">{p.restaurant}</p><Badge tone="success">{p.total}</Badge></div>
            <p className="text-xs text-muted">{p.items.join(" · ")}{p.arrives_around ? ` · arrives ~${p.arrives_around}` : ""}</p>
          </div>
        ))}
      </div>
    );
  }
  if (card.type === "payment_link") {
    return (
      <a href={String(card.url)} className="flex items-center justify-between gap-2 rounded-md bg-secondary px-4 py-3 font-semibold text-on-secondary">
        <span className="flex items-center gap-2"><CreditCard className="size-4" /> Pay {String(card.amount)} securely</span><span>→</span>
      </a>
    );
  }
  if (card.type === "order_status" || card.type === "order_draft") {
    const o = card.order as { order_id: string; status_label?: string; total?: string; restaurant?: string };
    return (
      <Link href={`/orders/${o.order_id}`} className="block rounded-md border border-border bg-background p-3 text-xs hover:border-primary">
        <span className="font-semibold">{o.restaurant}</span> · {o.status_label} · {o.total}
      </Link>
    );
  }
  return null;
}

function ApprovalCard({ approval, onDecide, busy }: { approval: ChatApproval; onDecide: (ok: boolean) => void; busy: boolean }) {
  const order = approval.preview.order as undefined | { items: string[]; subtotal: string; delivery_fee: string; service_fee: string; vat: string; discount: string | null; total: string; estimated_arrival: string | null };
  const parcel = approval.preview.parcel as undefined | { from: string; to: string; delivery_fee: string; service_fee: string; vat: string; total: string; estimated_delivery: string | null };
  return (
    <div className="space-y-3 rounded-md border-2 border-primary/40 bg-background p-4">
      <p className="flex items-center gap-2 font-semibold"><ShieldCheck className="size-4 text-secondary" /> {approval.preview.title}</p>
      {order && (
        <dl className="space-y-1 text-xs">
          {order.items.map((i) => <p key={i}>{i}</p>)}
          <div className="flex justify-between pt-1"><dt className="text-muted">Subtotal</dt><dd>{order.subtotal}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">Delivery</dt><dd>{order.delivery_fee}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">Service fee</dt><dd>{order.service_fee}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">VAT</dt><dd>{order.vat}</dd></div>
          {order.discount && <div className="flex justify-between text-secondary"><dt>Discount</dt><dd>-{order.discount}</dd></div>}
          <div className="flex justify-between border-t border-border pt-1 text-sm font-bold"><dt>Total</dt><dd>{order.total}</dd></div>
          {order.estimated_arrival && <p className="text-muted">Estimated arrival {order.estimated_arrival}</p>}
        </dl>
      )}
      {parcel && (
        <dl className="space-y-1 text-xs">
          <p>From {parcel.from}</p>
          <p>To {parcel.to}</p>
          <div className="flex justify-between pt-1"><dt className="text-muted">Delivery</dt><dd>{parcel.delivery_fee}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">Booking fee</dt><dd>{parcel.service_fee}</dd></div>
          <div className="flex justify-between"><dt className="text-muted">VAT</dt><dd>{parcel.vat}</dd></div>
          <div className="flex justify-between border-t border-border pt-1 text-sm font-bold"><dt>Total</dt><dd>{parcel.total}</dd></div>
        </dl>
      )}
      {approval.preview.message && <p className="text-xs text-muted">{approval.preview.message}</p>}
      <div className="flex gap-2">
        <Button size="sm" onClick={() => onDecide(true)} disabled={busy}>Approve</Button>
        <Button size="sm" variant="outline" onClick={() => onDecide(false)} disabled={busy}>Not now</Button>
      </div>
    </div>
  );
}
