import type { Metadata } from "next";
import { RequireAuth } from "@/components/require-auth";
import { RewardsView } from "./rewards-view";

export const metadata: Metadata = {
  title: "Rewards",
  description: "Yummy points on every order, vouchers you can redeem, and rewards for inviting friends.",
  alternates: { canonical: "/rewards" },
  robots: { index: false },
};

export default function RewardsPage() {
  return (
    <RequireAuth>
      <RewardsView />
    </RequireAuth>
  );
}
