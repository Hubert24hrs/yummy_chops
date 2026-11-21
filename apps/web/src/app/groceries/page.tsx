import type { Metadata } from "next";
import { VerticalPage } from "@/components/vertical-page";

export const metadata: Metadata = {
  title: "Shop & Groceries: supermarket delivery in Lagos and Enugu",
  description: "Supermarket shopping without the queue: drinks, cupboard food, fresh produce, baby and household products from stores near you in Lagos and Enugu.",
  alternates: { canonical: "/groceries" },
};

export default async function GroceriesPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  return <VerticalPage vertical="grocery" initialCategory={category} />;
}
