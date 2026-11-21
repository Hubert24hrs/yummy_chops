import type { Metadata } from "next";
import { VerticalPage } from "@/components/vertical-page";

export const metadata: Metadata = {
  title: "Pharmacy delivery in Lagos and Enugu",
  description: "Pain relief, cold and flu care, vitamins, first aid and baby care from partner pharmacies near you in Lagos and Enugu. Over-the-counter products only.",
  alternates: { canonical: "/pharmacy" },
};

export default async function PharmacyPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  return <VerticalPage vertical="pharmacy" initialCategory={category} />;
}
