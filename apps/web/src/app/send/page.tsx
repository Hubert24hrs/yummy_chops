import { cn } from "@gudmeal/ui";
import type { Metadata } from "next";
import Link from "next/link";
import { ParcelArt } from "@/components/illustrations";
import { RequireAuth } from "@/components/require-auth";
import { SendForm } from "./send-form";
import { WaybillForm } from "./waybill-form";

export const metadata: Metadata = {
  title: "Package delivery in Lagos and Enugu, and interstate waybill",
  description:
    "Send documents, clothes, electronics and more across Lagos or Enugu by bike, or to other cities by waybill. See the exact price before you pay.",
  alternates: { canonical: "/send" },
};

export default async function SendPage({ searchParams }: { searchParams: Promise<{ mode?: string }> }) {
  const interstate = (await searchParams).mode === "interstate";
  const tab = (active: boolean) =>
    cn("flex-1 rounded-full px-4 py-2 text-center text-sm font-bold", active ? "bg-background shadow" : "text-muted");
  return (
    <RequireAuth>
      <div className="container-page max-w-3xl pt-4">
        <nav aria-label="Delivery type" className="flex gap-1 rounded-full bg-surface-muted p-1">
          <Link href="/send" aria-current={interstate ? undefined : "page"} className={tab(!interstate)}>Within the city</Link>
          <Link href="/send?mode=interstate" aria-current={interstate ? "page" : undefined} className={tab(interstate)}>Interstate</Link>
        </nav>
      </div>
      {interstate ? (
        <div className="container-page max-w-3xl space-y-6 pb-32 pt-4 md:pb-12">
          <div className="flex items-center gap-4 rounded-2xl bg-secondary-soft p-4">
            <ParcelArt className="w-24 shrink-0" />
            <div>
              <h1 className="text-3xl font-black tracking-tight">Interstate waybill</h1>
              <p className="text-muted">
                Send between Lagos, Enugu and other cities. We pick up or you drop off at a hub; we deliver to the door or
                the recipient collects. Track it all the way.
              </p>
            </div>
          </div>
          <WaybillForm />
        </div>
      ) : (
        <SendForm />
      )}
    </RequireAuth>
  );
}
