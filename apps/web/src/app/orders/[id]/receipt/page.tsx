"use client";

import { use } from "react";
import { ReceiptScreen } from "@/components/receipt-screen";
import { RequireAuth } from "@/components/require-auth";

/** The receipt printer for an order the customer has paid for (ADR-0019). */
export default function ReceiptPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return <RequireAuth><ReceiptScreen orderId={id} /></RequireAuth>;
}
