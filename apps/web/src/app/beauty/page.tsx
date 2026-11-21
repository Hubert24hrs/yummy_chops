import type { Metadata } from "next";
import { VerticalPage } from "@/components/vertical-page";

export const metadata: Metadata = {
  title: "Beauty & Skin Care delivery in Lagos and Enugu",
  description: "Skincare, hair care, make-up and fragrance from partner beauty shops in Lagos and Enugu, delivered fast.",
  alternates: { canonical: "/beauty" },
};

export default async function BeautyPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  return <VerticalPage vertical="beauty" initialCategory={category} />;
}
