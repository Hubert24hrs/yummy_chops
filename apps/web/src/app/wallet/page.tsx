import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { WalletView } from "./wallet-view";

export const metadata: Metadata = {
  title: "Yummy Chops wallet",
  description: "Top up once and pay for food, pharmacy, beauty, groceries, foodstuff and package deliveries in one tap. Refunds land instantly.",
  alternates: { canonical: "/wallet" },
  robots: { index: false },
};

export default function WalletPage() {
  return (
    <RequireAuth>
      <WalletView />
    </RequireAuth>
  );
}
