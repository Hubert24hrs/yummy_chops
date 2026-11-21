import type { Metadata } from "next";
import { VerticalPage } from "@/components/vertical-page";

export const metadata: Metadata = {
  title: "Buy Foodstuff: market foodstuff delivered in Lagos and Enugu",
  description: "A shopper buys your foodstuff fresh at the market: rice, garri and beans by the derica or paint, pepper, vegetables, meat, fish and soup combos, delivered to your door.",
  alternates: { canonical: "/foodstuff" },
};

export default async function FoodstuffPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  return <VerticalPage vertical="market" initialCategory={category} />;
}
