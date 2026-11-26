"use client";

import { ApiError, type SupportContacts } from "@gudmeal/api-client";
import { Button, Field, Select, Textarea } from "@gudmeal/ui";
import { useMutation, useQuery } from "@tanstack/react-query";
import { ChevronRight, Headset, Mail, MessageCircle, Phone } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { GudyArt } from "@/components/illustrations";
import { publicApi, useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

const CATEGORIES: Record<string, string> = {
  missing_item: "Missing item", wrong_order: "Wrong order", late_delivery: "Late delivery", payment: "Payment",
  quality: "Food or product quality", rider: "Rider", account: "Account", other: "Something else",
};

const FAQ = [
  ["How do refunds work?", "If a store rejects your order, or you cancel before it is accepted (or before a rider is assigned to your package), you get a full refund automatically. For anything else, open a ticket and our team reviews it within 24 hours."],
  ["How do I pay?", "Card, bank transfer or USSD on a secure payment page (Yummy Chops never sees your card details), from your Yummy Chops wallet in one tap, or in cash on delivery once you have completed an order."],
  ["What is the delivery code?", "A 4-digit code in your order. Only give it to the rider once you have your order. For packages, share it with the person receiving it."],
  ["Where do you deliver?", "Lagos and Enugu for now. Choose your area at the top of the page; more cities are coming."],
  ["Is Yummy a real person?", "Yummy is Yummy Chops’ AI assistant. It always asks you to approve before placing an order or creating a payment, and you can ask for a person at any time."],
];

export default function SupportPage() {
  const config = useQuery({ queryKey: ["public-config"], queryFn: () => publicApi.catalog.publicConfig() });
  const support = (config.data?.support ?? null) as SupportContacts | null;
  return (
    <div className="container-page max-w-3xl space-y-5 pb-28 pt-6 md:pb-12">
      <div>
        <h1 className="text-4xl font-black tracking-tight">Support</h1>
        <p className="mt-1 text-muted">How can we help?</p>
      </div>

      <Link href="/assistant" className="flex items-center gap-4 rounded-2xl border border-[#F3D7A6] bg-[#FEF1DA] p-4 text-[#2A0D06] hover:border-[#6B2410]">
        <GudyArt blink className="size-14 shrink-0" />
        <div className="flex-1">
          <p className="text-lg font-extrabold text-[#3A0D05]">Chat with Yummy</p>
          <p className="text-sm">Instant answers in English, Pidgin, Igbo, Yoruba or Hausa</p>
        </div>
        <ChevronRight className="size-5 text-[#3A0D05]" aria-hidden="true" />
      </Link>

      <TicketCard />

      {/* A contact that is not set up yet comes back empty and shows as "coming soon". */}
      <div className="divide-y divide-border rounded-2xl border border-border">
        <Contact icon={<MessageCircle className="size-5" />} title="WhatsApp" value={support?.whatsapp}
          href={support?.whatsapp ? `https://wa.me/${support.whatsapp.replace(/[^0-9]/g, "")}` : undefined} />
        <Contact icon={<Phone className="size-5" />} title="Call us" value={support?.phone}
          href={support?.phone ? `tel:${support.phone.replace(/\s/g, "")}` : undefined} />
        <Contact icon={<Mail className="size-5" />} title="Email" value={support?.email}
          href={support?.email ? `mailto:${support.email}` : undefined} />
        {support?.hours && <p className="px-4 py-2 text-xs text-muted">{support.hours}</p>}
      </div>

      <section>
        <h2 className="mb-2 text-xl font-extrabold">Frequently asked</h2>
        <div className="divide-y divide-border rounded-2xl border border-border">
          {FAQ.map(([q, a]) => (
            <details key={q} className="p-4">
              <summary className="cursor-pointer font-semibold">{q}</summary>
              <p className="mt-2 text-sm text-muted">{a}</p>
            </details>
          ))}
        </div>
        <p className="mt-3 text-sm"><Link href="/help" className="font-semibold text-primary">Fees, privacy and terms →</Link></p>
      </section>
    </div>
  );
}

function Contact({ icon, title, value, href }: { icon: React.ReactNode; title: string; value?: string; href?: string }) {
  const live = Boolean(value && href);
  const body = (
    <>
      <span className="grid size-10 place-items-center rounded-full bg-surface-muted" aria-hidden="true">{icon}</span>
      <span className="flex-1">
        <span className="block font-bold">{title}</span>
        <span className="text-sm text-muted">{live ? value : "Coming soon. Use Yummy or open a ticket for now."}</span>
      </span>
    </>
  );
  return live && href ? (
    <a href={href} target="_blank" rel="noreferrer" className="flex items-center gap-3 p-4 hover:bg-surface-muted">{body}</a>
  ) : (
    <div className="flex items-center gap-3 p-4 opacity-70" aria-disabled="true">{body}</div>
  );
}

function TicketCard() {
  const { user } = useAuth();
  const api = useApi();
  const [open, setOpen] = useState(false);
  const [category, setCategory] = useState("other");
  const [orderId, setOrderId] = useState("");
  const [text, setText] = useState("");
  const orders = useQuery({ queryKey: ["orders"], queryFn: () => api.orders.list(10), enabled: !!user && open });
  const send = useMutation({
    mutationFn: () => api.support.open({ category, description: text.trim(), order_id: orderId || undefined }),
    onSuccess: () => { setText(""); setOpen(false); },
  });

  if (!user) {
    return (
      // The guest is still being signed in (ADR-0032): the ticket form opens in a moment.
      <div className="flex items-center gap-3 rounded-2xl border border-border p-4 opacity-70" aria-busy="true">
        <span className="grid size-10 place-items-center rounded-full bg-primary-soft text-primary"><Headset className="size-5" aria-hidden="true" /></span>
        <span className="flex-1"><span className="block font-bold">Talk to a person</span><span className="text-sm text-muted">Getting ready…</span></span>
      </div>
    );
  }
  return (
    <div className="rounded-2xl border border-border p-4">
      <button type="button" onClick={() => setOpen(!open)} className="flex w-full items-center gap-3 text-left" aria-expanded={open}>
        <span className="grid size-10 place-items-center rounded-full bg-primary-soft text-primary"><Headset className="size-5" aria-hidden="true" /></span>
        <span className="flex-1"><span className="block font-bold">Talk to a person</span><span className="text-sm text-muted">Open a ticket; our team replies in the app</span></span>
        <ChevronRight className={`size-5 transition-transform ${open ? "rotate-90" : ""}`} aria-hidden="true" />
      </button>
      {send.isSuccess && !open && <p role="status" className="mt-3 text-sm font-semibold text-secondary">Ticket opened. A Yummy Chops support agent will reply in the app.</p>}
      {open && (
        <form className="mt-4 space-y-3" onSubmit={(e) => { e.preventDefault(); if (text.trim().length >= 5) send.mutate(); }}>
          <Field label="What is it about?" htmlFor="cat">
            <Select id="cat" value={category} onChange={(e) => setCategory(e.target.value)}>
              {Object.entries(CATEGORIES).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </Select>
          </Field>
          {(orders.data?.length ?? 0) > 0 && (
            <Field label="Which order? (optional)" htmlFor="ord">
              <Select id="ord" value={orderId} onChange={(e) => setOrderId(e.target.value)}>
                <option value="">Not about an order</option>
                {orders.data!.map((o) => <option key={o.id} value={o.id}>#{o.short_code} · {o.restaurant_name}</option>)}
              </Select>
            </Field>
          )}
          <Field label="What happened?" htmlFor="what" hint="At least 5 characters">
            <Textarea id="what" rows={4} maxLength={1500} value={text} onChange={(e) => setText(e.target.value)} />
          </Field>
          {send.error && <p role="alert" className="text-sm text-danger">{send.error instanceof ApiError ? send.error.message : "Couldn’t send. Please try again."}</p>}
          <Button type="submit" loading={send.isPending} disabled={text.trim().length < 5}>Send to support</Button>
        </form>
      )}
    </div>
  );
}
