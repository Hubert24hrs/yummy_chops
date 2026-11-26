"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Card, Field, Input, Select } from "@gudmeal/ui";
import { useMutation } from "@tanstack/react-query";
import { CheckCircle2, Plus, X } from "lucide-react";
import { useFieldArray, useForm } from "react-hook-form";
import { z } from "zod";
import { RequireSavedAccount } from "@/components/save-account";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { AREAS } from "@/lib/location";

/** The kinds of business that can sell on Yummy Chops (ADR-0025), with what the form asks them to list. */
const KINDS = [
  { id: "food", label: "Restaurant (Order Food)", sells: "Cuisines", example: "Nigerian, Grills" },
  { id: "pharmacy", label: "Pharmacy", sells: "What you sell", example: "Pain relief, Vitamins, First aid" },
  { id: "beauty", label: "Beauty & Skin Care shop", sells: "What you sell", example: "Skincare, Hair care, Make-up" },
  { id: "grocery", label: "Supermarket or store (Shop & Groceries)", sells: "What you sell", example: "Drinks, Household, Baby" },
  { id: "market", label: "Market shopper (Buy Foodstuff)", sells: "What you buy at the market", example: "Foodstuff, Pepper & vegetables, Meat & fish" },
] as const;

// Register your business (docs/adr/0028-business-branches-and-split-payments.md): one main address and any number of
// branch addresses; the bank account comes later, in the partner dashboard (it sets up split payments).
const branch = z.object({ address: z.string().trim().min(5, "Enter the branch's street address").max(200), area: z.string() });
const schema = z.object({
  vertical: z.enum(["food", "pharmacy", "beauty", "grocery", "market"]),
  pcn_licence_number: z.string().max(30).optional(),
  business_name: z.string().trim().min(2, "Enter your business name").max(80),
  contact_phone: z.string().trim().min(7, "Enter your phone number").max(20),
  email: z.string().trim().email("Enter a valid email address").max(120),
  contact_name: z.string().trim().min(2, "Enter your name").max(80),
  cac_number: z.string().trim().min(4, "Enter your CAC registration number").max(20),
  address: z.string().trim().min(5, "Enter your street address").max(200),
  area: z.string(),
  branches: z.array(branch).max(20),
  cuisines: z.string().min(2, "List at least one"),
}).refine((v) => v.vertical !== "pharmacy" || (v.pcn_licence_number ?? "").trim().length >= 4, {
  path: ["pcn_licence_number"], message: "Enter your PCN premises licence number",
});
type Values = z.infer<typeof schema>;

const placeOf = (area: string) => (AREAS.find((a) => a.name === area) ?? AREAS[0]!).location;

export default function PartnerPage() {
  return (
    <div className="container-page grid gap-10 py-10 lg:grid-cols-2">
      <div className="space-y-4">
        <h1 className="font-display text-4xl">Register your business</h1>
        <p className="text-muted">Restaurants, pharmacies, beauty &amp; skin care shops, supermarkets and market shoppers sell on Yummy Chops.</p>
        <ul className="space-y-2 text-muted">
          <li>• Add every branch: customers order from the one nearest to them, with one menu for all.</li>
          <li>• Your own business ID, a live order board and a manager&apos;s number for each branch.</li>
          <li>• Paid straight away: Paystack sends your share of every card payment to your bank account.</li>
        </ul>
        <p className="text-sm text-muted">We verify every partner (CAC registration and, for pharmacies, the PCN premises licence) before going live.
          After approval, add your bank account in your partner dashboard.</p>
      </div>
      <RequireSavedAccount note="Your account becomes your Yummy Chops Partner login, so save it with Google or email before you apply."><PartnerForm /></RequireSavedAccount>
    </div>
  );
}

function PartnerForm() {
  const api = useApi();
  const { user } = useAuth();
  const { register, handleSubmit, formState, watch, control } = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: {
      area: AREAS[0]!.name, vertical: "food", branches: [], email: user?.email ?? "", contact_name: user?.displayName ?? "",
    },
  });
  const branches = useFieldArray({ control, name: "branches" });
  const kind = KINDS.find((k) => k.id === watch("vertical")) ?? KINDS[0];
  const submit = useMutation({
    mutationFn: ({ pcn_licence_number, ...v }: Values) => api.applications.restaurant({
      ...v,
      location: placeOf(v.area),
      branches: v.branches.map((b) => ({ address: b.address, area: b.area, location: placeOf(b.area) })),
      cuisines: v.cuisines.split(",").map((c) => c.trim()).filter(Boolean),
      ...(v.vertical === "pharmacy" ? { pcn_licence_number: pcn_licence_number?.trim() } : {}),
    }),
  });
  if (submit.isSuccess) {
    return (
      <Card className="space-y-3 p-8 text-center">
        <CheckCircle2 className="mx-auto size-12 text-secondary" />
        <h2 className="font-display text-2xl">Application received</h2>
        <p className="text-sm text-muted">Our partnerships team will review it within 2 business days. When you are approved, your
          partner dashboard shows your business ID, your branches and where to add your bank account.</p>
      </Card>
    );
  }
  const e = formState.errors;
  const areaOptions = AREAS.map((a) => <option key={`${a.city}-${a.name}`}>{a.name}</option>);
  return (
    <Card className="p-6">
      <form onSubmit={handleSubmit((v) => submit.mutate(v))} className="grid gap-4 sm:grid-cols-2" noValidate>
        <div className="sm:col-span-2">
          <Field label="Kind of business" htmlFor="kd">
            <Select id="kd" {...register("vertical")}>{KINDS.map((k) => <option key={k.id} value={k.id}>{k.label}</option>)}</Select>
          </Field>
        </div>
        <Field label="Business name" htmlFor="bn" error={e.business_name?.message}><Input id="bn" {...register("business_name")} /></Field>
        <Field label="Phone number" htmlFor="cp" error={e.contact_phone?.message}><Input id="cp" inputMode="tel" autoComplete="tel" {...register("contact_phone")} /></Field>
        <Field label="Email" htmlFor="em" error={e.email?.message}><Input id="em" type="email" autoComplete="email" {...register("email")} /></Field>
        <Field label="Your name" htmlFor="cn" error={e.contact_name?.message}><Input id="cn" autoComplete="name" {...register("contact_name")} /></Field>
        <Field label="Address (main branch)" htmlFor="ad" error={e.address?.message}><Input id="ad" {...register("address")} /></Field>
        <Field label="Area" htmlFor="ar"><Select id="ar" {...register("area")}>{areaOptions}</Select></Field>

        {branches.fields.map((f, i) => (
          <div key={f.id} className="grid gap-4 rounded-xl border border-border p-3 sm:col-span-2 sm:grid-cols-[1fr,12rem,auto]">
            <Field label={`Branch ${i + 2} address`} htmlFor={`b${i}`} error={e.branches?.[i]?.address?.message}>
              <Input id={`b${i}`} {...register(`branches.${i}.address`)} />
            </Field>
            <Field label={`Branch ${i + 2} area`} htmlFor={`ba${i}`}>
              <Select id={`ba${i}`} {...register(`branches.${i}.area`)}>{areaOptions}</Select>
            </Field>
            <button type="button" onClick={() => branches.remove(i)} aria-label={`Remove branch ${i + 2}`}
              className="self-end rounded-lg p-2 text-muted hover:bg-surface-muted hover:text-text">
              <X className="size-5" aria-hidden="true" />
            </button>
          </div>
        ))}
        <div className="sm:col-span-2">
          <Button type="button" variant="outline" onClick={() => branches.append({ address: "", area: AREAS[0]!.name })} disabled={branches.fields.length >= 20}>
            <Plus className="size-4" aria-hidden="true" /> Add another branch
          </Button>
        </div>

        <Field label="CAC number" htmlFor="cac" error={e.cac_number?.message}><Input id="cac" {...register("cac_number")} /></Field>
        <Field label={kind.sells} htmlFor="cu" hint="Comma separated" error={e.cuisines?.message}><Input id="cu" placeholder={kind.example} {...register("cuisines")} /></Field>
        {kind.id === "pharmacy" && (
          <Field label="PCN premises licence number" htmlFor="pcn" hint="From the Pharmacists Council of Nigeria" error={e.pcn_licence_number?.message}>
            <Input id="pcn" {...register("pcn_licence_number")} />
          </Field>
        )}
        {submit.error && <p role="alert" className="text-sm text-danger sm:col-span-2">{(submit.error as Error).message}</p>}
        <Button type="submit" size="lg" className="sm:col-span-2" loading={submit.isPending}>Submit application</Button>
      </form>
    </Card>
  );
}
