import type { Metadata } from "next";
import type { ReactNode } from "react";

export const metadata: Metadata = {
  title: "Discover",
  description: "Search restaurants, dishes, groceries, pharmacy and beauty products, and see what's most in demand near you in Lagos and Enugu.",
  alternates: { canonical: "/discover" },
};

export default function DiscoverLayout({ children }: { children: ReactNode }) {
  return children;
}
