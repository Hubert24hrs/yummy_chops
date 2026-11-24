"use client";

import { Button } from "@gudmeal/ui";
import { ArrowLeft, Printer } from "lucide-react";
import Link from "next/link";

/** The guarantor form a new rider prints, has filled and signed by each of their two guarantors, then photographs
 * into the KYC in the rider app (docs/adr/0027-rider-kyc.md). */
export default function GuarantorFormPage() {
  return (
    <div className="container-page max-w-3xl py-6">
      <div className="mb-4 flex items-center justify-between gap-3 print:hidden">
        <Link href="/ride" className="inline-flex items-center gap-1 text-sm font-semibold text-muted hover:text-text">
          <ArrowLeft className="size-4" aria-hidden="true" /> Become our rider
        </Link>
        <Button onClick={() => window.print()}><Printer className="size-4" aria-hidden="true" /> Print the form</Button>
      </div>
      <p className="mb-4 text-sm text-muted print:hidden">
        Print one form for each of your two guarantors. Each guarantor fills it in, signs it and attaches a passport
        photograph and a copy of a valid ID. Then take a clear photo of each signed form and upload it in the KYC step of
        the Yummy Chops Rider app.
      </p>
      <article className="print-area space-y-5 rounded-xl border-2 border-text bg-white p-6 text-black">
        <header className="flex items-start justify-between gap-4 border-b-2 border-black pb-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider">Yummy Chops · yummy247.com</p>
            <h1 className="text-2xl font-black">Rider guarantor form</h1>
          </div>
          <div className="grid size-28 shrink-0 place-items-center border-2 border-dashed border-black text-center text-xs">
            Guarantor&apos;s passport photograph
          </div>
        </header>

        <section className="space-y-3">
          <h2 className="text-sm font-bold uppercase tracking-wider">The rider</h2>
          <Line label="Rider's full name" />
          <Line label="Rider's WhatsApp phone number" />
        </section>

        <section className="space-y-3">
          <h2 className="text-sm font-bold uppercase tracking-wider">The guarantor</h2>
          <Line label="Full name" />
          <div className="grid gap-3 sm:grid-cols-2">
            <Line label="Phone number" />
            <Line label="Email" />
          </div>
          <Line label="Home address" />
          <div className="grid gap-3 sm:grid-cols-2">
            <Line label="Occupation" />
            <Line label="Employer or business name" />
          </div>
          <Line label="Office or business address" />
          <div className="grid gap-3 sm:grid-cols-2">
            <Line label="Relationship to the rider" />
            <Line label="How long you have known the rider" />
          </div>
          <Line label="ID type and number (attach a copy)" />
        </section>

        <section className="space-y-2 text-sm leading-relaxed">
          <h2 className="text-sm font-bold uppercase tracking-wider">Declaration</h2>
          <p>
            I know the rider named above personally and vouch for their identity, honesty and good conduct. I confirm that
            the information on this form is true, and I agree that Yummy Chops may contact me to confirm it and if the
            rider cannot be reached while they work with Yummy Chops.
          </p>
        </section>

        <section className="grid gap-6 pt-4 sm:grid-cols-2">
          <Line label="Guarantor's signature" tall />
          <Line label="Date" tall />
        </section>
      </article>
      <p className="mt-4 text-xs text-muted print:hidden">
        This form is a template for Yummy Chops to have reviewed by a lawyer before riders use it.
      </p>
    </div>
  );
}

function Line({ label, tall = false }: { label: string; tall?: boolean }) {
  return (
    <div>
      <div className={`border-b border-black ${tall ? "h-12" : "h-7"}`} />
      <p className="mt-1 text-xs">{label}</p>
    </div>
  );
}
