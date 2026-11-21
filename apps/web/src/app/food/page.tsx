import type { Metadata } from "next";
import { VerticalPage } from "@/components/vertical-page";

export const metadata: Metadata = {
  title: "Order Food: food delivery in Lagos and Enugu",
  description: "Order jollof, suya, swallow, pizza, small chops and more from top-rated restaurants in Lagos and Enugu.",
  alternates: { canonical: "/food" },
};

export default async function FoodPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  return <VerticalPage vertical="food" initialCategory={category} />;
}
