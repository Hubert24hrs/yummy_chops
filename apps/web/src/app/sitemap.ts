import type { MetadataRoute } from "next";
import { safe, serverApi } from "@/lib/server-api";

export const dynamic = "force-dynamic";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  const { data } = await safe(serverApi.catalog.restaurants({ limit: 100, vertical: "all" }));
  const pages = ["", "/food", "/pharmacy", "/beauty", "/groceries", "/foodstuff", "/send", "/discover", "/support", "/restaurants", "/assistant", "/partner-with-us", "/ride", "/help"].map((p) => ({
    url: `${site}${p}`, changeFrequency: "daily" as const, priority: p === "" ? 1 : 0.7,
  }));
  return [...pages, ...(data ?? []).map((r) => ({ url: `${site}/restaurants/${r.id}`, changeFrequency: "daily" as const, priority: 0.8 }))];
}
