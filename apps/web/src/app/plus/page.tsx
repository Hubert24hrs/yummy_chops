import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { PlusView } from "./plus-view";

export const metadata: Metadata = {
  title: "Yummy Chops Plus",
  description: "Free delivery on restaurant and shop orders, half-price service fees and double Yummy points.",
  alternates: { canonical: "/plus" },
  robots: { index: false },
};

export default function PlusPage() {
  return (
    <RequireAuth>
      <PlusView />
    </RequireAuth>
  );
}
