"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Card, Field, Input, Select } from "@gudmeal/ui";
import { useMutation } from "@tanstack/react-query";
import { CheckCircle2 } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { RequireAuth } from "@/components/require-auth";
import { useApi } from "@/lib/api";
import { LAGOS_AREAS } from "@/lib/location";

/** The kinds of business that can sell on Yummy Chops (ADR-0025), with what the form asks them to list. */
const KINDS = [
  { id: "food", label: "Restaurant (Order Food)", sells: "Cuisines", example: "Nigerian, Grills" },
  { id: "pharmacy", label: "Pharmacy", sells: "What you sell", example: "Pain relief, Vitamins, First aid" },
  { id: "beauty", label: "Beauty & Skin Care shop", sells: "What you sell", example: "Skincare, Hair care, Make-up" },
  { id: "grocery", label: "Supermarket or store (Shop & Groceries)", sells: "What you sell", example: "Drinks, Household, Baby" },
  { id: "market", label: "Market shopper (Buy Foodstuff)", sells: "What you buy at the market", example: "Foodstuff, Pepper & vegetables, Meat & fish" },
] as const;

const schema = z.object({
  vertical: z.enum(["food", "pharmacy", "beauty", "grocery", "market"]),
  pcn_licence_number: z.string().max(30).optional(),
  business_name: z.string().min(2).max(80),
  cac_number: z.string().min(4, "Enter your CAC registration number").max(20),
  contact_name: z.string().min(2).max(80),
  contact_phone: z.string().min(7).max(20),
  address: z.string().min(5).max(200),
  area: z.string(),
  cuisines: z.string().min(2, "List at least one"),
  bank_name: z.string().min(2).max(60),
  bank_account_name: z.string().min(2).max(80),
  bank_account_last4: z.string().regex(/^\d{4}$/, "Last 4 digits only"),
}).refine((v) => v.vertical !== "pharmacy" || (v.pcn_licence_number ?? "").trim().length >= 4, {
  path: ["pcn_licence_number"], message: "Enter your PCN premises licence number",
});
type Values = z.infer<typeof schema>;

export default function PartnerPage() {
  return (
    <div className="container-page grid gap-10 py-10 lg:grid-cols-2">
      <div className="space-y-4">
        <h1 className="font-display text-4xl">Grow your business with Yummy Chops</h1>
        <p className="text-muted">Restaurants, pharmacies, beauty &amp; skin care shops, supermarkets and market shoppers sell on Yummy Chops.</p>
        <ul className="space-y-2 text-muted">
          <li>• Reach customers across Lagos and Enugu, including through Yummy, our AI assistant.</li>
          <li>• Live order board, menu and product tools, sales insights and demand forecasts.</li>
          <li>• Transparent commission and weekly settlement statements.</li>
        </ul>
        <p className="text-sm text-muted">We verify every partner (CAC registration, bank details and, for pharmacies, the PCN premises licence) before going live.
          Full bank account numbers are collected securely by our payment provider, never on this form.</p>
      </div>
      <RequireAuth reason="Create an account first — it becomes your Yummy Chops Partner login."><PartnerForm /></RequireAuth>
    </div>
  );
}

function PartnerForm() {
  const api = useApi();
  const { register, handleSubmit, formState, watch } = useForm<Values>({
    resolver: zodResolver(schema), defaultValues: { area: LAGOS_AREAS[0]!.name, vertical: "food" },
  });
  const kind = KINDS.find((k) => k.id === watch("vertical")) ?? KINDS[0];
  const submit = useMutation({
    mutationFn: ({ pcn_licence_number, ...v }: Values) => {
      const area = LAGOS_AREAS.find((a) => a.name === v.area)!;
      return api.applications.restaurant({
        ...v, location: area.location, cuisines: v.cuisines.split(",").map((c) => c.trim()).filter(Boolean),
        ...(v.vertical === "pharmacy" ? { pcn_licence_number: pcn_licence_number?.trim() } : {}),
      });
    },
  });
  if (submit.isSuccess) {
    return (
      <Card className="space-y-3 p-8 text-center">
        <CheckCircle2 className="mx-auto size-12 text-secondary" />
        <h2 className="font-display text-2xl">Application received</h2>
        <p className="text-sm text-muted">Our partnerships team will review your documents within 2 business days.</p>
      </Card>
    );
  }
  const e = formState.errors;
  return (
    <Card className="p-6">
      <form onSubmit={handleSubmit((v) => submit.mutate(v))} className="grid gap-4 sm:grid-cols-2" noValidate>
        <div className="sm:col-span-2">
          <Field label="Kind of business" htmlFor="kd">
            <Select id="kd" {...register("vertical")}>{KINDS.map((k) => <option key={k.id} value={k.id}>{k.label}</option>)}</Select>
          </Field>
        </div>
        <Field label="Business name" htmlFor="bn" error={e.business_name?.message}><Input id="bn" {...register("business_name")} /></Field>
        <Field label="CAC number" htmlFor="cac" error={e.cac_number?.message}><Input id="cac" {...register("cac_number")} /></Field>
        <Field label="Contact name" htmlFor="cn" error={e.contact_name?.message}><Input id="cn" {...register("contact_name")} /></Field>
        <Field label="Contact phone" htmlFor="cp" error={e.contact_phone?.message}><Input id="cp" inputMode="tel" {...register("contact_phone")} /></Field>
        <Field label="Street address" htmlFor="ad" error={e.address?.message}><Input id="ad" {...register("address")} /></Field>
        <Field label="Area" htmlFor="ar"><Select id="ar" {...register("area")}>{LAGOS_AREAS.map((a) => <option key={a.name}>{a.name}</option>)}</Select></Field>
        <Field label={kind.sells} htmlFor="cu" hint="Comma separated" error={e.cuisines?.message}><Input id="cu" placeholder={kind.example} {...register("cuisines")} /></Field>
        {kind.id === "pharmacy" && (
          <Field label="PCN premises licence number" htmlFor="pcn" hint="From the Pharmacists Council of Nigeria" error={e.pcn_licence_number?.message}>
            <Input id="pcn" {...register("pcn_licence_number")} />
          </Field>
        )}
        <Field label="Bank" htmlFor="bk" error={e.bank_name?.message}><Input id="bk" {...register("bank_name")} /></Field>
        <Field label="Account name" htmlFor="an" error={e.bank_account_name?.message}><Input id="an" {...register("bank_account_name")} /></Field>
        <Field label="Account number (last 4)" htmlFor="l4" error={e.bank_account_last4?.message}><Input id="l4" inputMode="numeric" maxLength={4} {...register("bank_account_last4")} /></Field>
        {submit.error && <p role="alert" className="text-sm text-danger sm:col-span-2">{(submit.error as Error).message}</p>}
        <Button type="submit" size="lg" className="sm:col-span-2" loading={submit.isPending}>Submit application</Button>
      </form>
    </Card>
  );
}
