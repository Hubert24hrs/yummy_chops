"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Card, Field, Input, Select } from "@gudmeal/ui";
import { useMutation } from "@tanstack/react-query";
import { CheckCircle2, FileText } from "lucide-react";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { RequireSavedAccount } from "@/components/save-account";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

// Rider sign-up (docs/adr/0027-rider-kyc.md). The KYC follows in the Yummy Chops Rider app.
const schema = z.object({
  full_name: z.string().trim().min(2, "Enter your full name").max(80),
  phone: z.string().trim().min(7, "Enter your WhatsApp number").max(20),
  email: z.string().trim().email("Enter a valid email address").max(120),
  residential_address: z.string().trim().min(5, "Enter where you live").max(200),
  vehicle: z.enum(["motorcycle", "bicycle", "car"]),
});
type Values = z.infer<typeof schema>;

const GUARANTOR_FORM = "/ride/guarantor-form";

export default function RidePage() {
  return (
    <div className="container-page grid gap-10 py-10 lg:grid-cols-2">
      <div className="space-y-5">
        <h1 className="font-display text-4xl">Become our rider</h1>
        <p className="text-muted">Flexible hours, clear earnings for every delivery, and withdrawals to your bank.</p>
        <ol className="space-y-3 text-sm">
          <li><strong>1. Sign up</strong> here.</li>
          <li>
            <strong>2. Complete your KYC</strong> in the Yummy Chops Rider app or <Link href="/ride/kyc" className="font-semibold text-primary hover:underline">here on the website</Link>, signed in with the same account: your
            permanent address and NIN; photos of your plate number, Hackney permit, rider&apos;s card or licence and
            your bike; two guarantors, each with a signed guarantor form; and a selfie for the face check.
          </li>
          <li>
            <strong>3. We check everything</strong> and you get the <strong>Verified</strong> badge. Then go online and
            start delivering.
          </li>
        </ol>
        <Link href={GUARANTOR_FORM} className="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline">
          <FileText className="size-4" /> Print the guarantor form
        </Link>
      </div>
      <RequireSavedAccount note="Your account becomes your Yummy Chops Rider login, so save it with Google or email before you sign up.">
        <RiderForm />
      </RequireSavedAccount>
    </div>
  );
}

function RiderForm() {
  const api = useApi();
  const { user, refreshToken } = useAuth();
  const { register, handleSubmit, formState } = useForm<Values>({
    resolver: zodResolver(schema),
    defaultValues: { vehicle: "motorcycle", email: user?.email ?? "", full_name: user?.displayName ?? "" },
  });
  const submit = useMutation({
    mutationFn: async (v: Values) => {
      const application = await api.applications.rider({ ...v, city: "Lagos" });
      await refreshToken(); // the account is now a rider: its sign-in token must say so for the KYC
      return application;
    },
  });
  if (submit.isSuccess) {
    return (
      <Card className="space-y-4 p-8 text-center">
        <CheckCircle2 className="mx-auto size-12 text-secondary" />
        <h2 className="font-display text-2xl">You&apos;re signed up</h2>
        <p className="text-sm text-muted">
          Next, your KYC: complete it here, or in the <strong>Yummy Chops Rider</strong> app signed in with this account.
          It asks for each document and photo in turn; then submit it and we check it.
        </p>
        <Link href="/ride/kyc" className="inline-flex items-center justify-center rounded-xl bg-primary px-5 py-3 font-semibold text-on-primary shadow-sm hover:bg-primary-strong">
          Complete your KYC
        </Link>
        <Link href={GUARANTOR_FORM} className="flex items-center justify-center gap-2 text-sm font-semibold text-primary hover:underline">
          <FileText className="size-4" /> Print the guarantor form
        </Link>
      </Card>
    );
  }
  const e = formState.errors;
  return (
    <Card className="p-6">
      <form onSubmit={handleSubmit((v) => submit.mutate(v))} className="grid gap-4" noValidate>
        <Field label="Full name" htmlFor="fn" error={e.full_name?.message}>
          <Input id="fn" autoComplete="name" {...register("full_name")} />
        </Field>
        <Field label="WhatsApp phone number" htmlFor="ph" error={e.phone?.message}>
          <Input id="ph" inputMode="tel" autoComplete="tel" placeholder="+234 803 000 0000" {...register("phone")} />
        </Field>
        <Field label="Email" htmlFor="em" error={e.email?.message}>
          <Input id="em" type="email" autoComplete="email" {...register("email")} />
        </Field>
        <Field label="Residential address" htmlFor="ra" error={e.residential_address?.message}>
          <Input id="ra" autoComplete="street-address" {...register("residential_address")} />
        </Field>
        <Field label="Vehicle" htmlFor="vh">
          <Select id="vh" {...register("vehicle")}>
            <option value="motorcycle">Motorcycle</option>
            <option value="bicycle">Bicycle</option>
            <option value="car">Car</option>
          </Select>
        </Field>
        {submit.error && <p role="alert" className="text-sm text-danger">{(submit.error as Error).message}</p>}
        <Button type="submit" size="lg" loading={submit.isPending}>Sign up as a rider</Button>
      </form>
    </Card>
  );
}
