"use client";

import type { MerchantVertical, RestaurantCard } from "@gudmeal/api-client";
import { formatNaira } from "@gudmeal/api-client";
import { ErrorState, Skeleton } from "@gudmeal/ui";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Footprints, Search } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useDeferredValue, useMemo, useState } from "react";
import { publicApi } from "@/lib/api";
import { useLocation } from "@/lib/location";
import { serviceCopy } from "@/lib/services";
import { AddressPill, BrandTile, CategoryBubble, EmptyBlock, FilterPill, MerchantCard, SectionTitle, ServiceNote } from "./storefront";

const SORTS: Record<string, string> = { recommended: "Recommended", rating: "Top rated", distance: "Nearest", delivery_fee: "Lowest delivery fee" };

/** A service page: Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries or Buy Foodstuff. */
export function VerticalPage({ vertical, initialCategory }: { vertical: MerchantVertical; initialCategory?: string }) {
  const router = useRouter();
  const { area } = useLocation();
  const [category, setCategory] = useState<string | undefined>(initialCategory);
  const [cuisine, setCuisine] = useState<string | undefined>();
  const [pickup, setPickup] = useState(false);
  const [sort, setSort] = useState("recommended");
  const [q, setQ] = useState("");
  const query = useDeferredValue(q.trim());
  const service = serviceCopy(vertical);
  const title = service.title;
  const ItemIcon = service.icon;

  const cats = useQuery({ queryKey: ["categories", vertical, area.city], queryFn: () => publicApi.catalog.categories(vertical, area.city) });
  const base = { ...area.location, vertical, city: area.city };
  const all = useQuery({ queryKey: ["merchants", vertical, area.name], queryFn: () => publicApi.catalog.restaurants(base) });
  const list = useQuery({
    queryKey: ["merchants", vertical, area.name, category, cuisine, pickup, sort, query],
    queryFn: () => publicApi.catalog.restaurants({ ...base, category, cuisine, pickup: pickup || undefined, sort, q: query.length >= 2 ? query : undefined }),
  });
  const hits = useQuery({
    queryKey: ["search", vertical, query, area.name],
    queryFn: () => publicApi.catalog.search(query, area.location, vertical),
    enabled: query.length >= 2,
  });
  const cuisines = useMemo(() => [...new Set((all.data ?? []).flatMap((m) => m.cuisines))].sort(), [all.data]);
  const popular = useMemo(() => [...(all.data ?? [])].sort((a, b) => b.rating - a.rating).slice(0, 10), [all.data]);

  return (
    <div className="container-page pb-28 pt-4 md:pb-12">
      <div className="flex items-center gap-2">
        <button type="button" onClick={() => router.back()} aria-label="Back" className="grid size-10 place-items-center rounded-full hover:bg-surface-muted">
          <ArrowLeft className="size-5" aria-hidden="true" />
        </button>
        <div className="flex flex-1 justify-center"><AddressPill /></div>
        <span className="size-10" aria-hidden="true" />
      </div>
      <h1 className="mt-4 text-4xl font-black tracking-tight">{title}</h1>
      {service.note && <ServiceNote className="mt-3">{service.note}</ServiceNote>}

      <label className="mt-4 flex items-center gap-2 rounded-full bg-surface-muted px-4 py-3">
        <Search className="size-5 text-muted" aria-hidden="true" />
        <span className="sr-only">Search in {title}</span>
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={`Search in ${service.searchIn}`}
          className="w-full bg-transparent outline-none placeholder:text-muted" />
      </label>

      <div className="-mx-4 mt-4 flex gap-1 overflow-x-auto px-2 pb-1 [scrollbar-width:none]">
        {cats.isLoading && <Skeleton className="h-24 w-full" />}
        {(cats.data ?? []).map((c) => (
          <CategoryBubble key={c.id} label={c.name} emoji={c.emoji} selected={category === c.id}
            onClick={() => setCategory(category === c.id ? undefined : c.id)} />
        ))}
      </div>

      <div className="-mx-4 mt-3 flex gap-2 overflow-x-auto px-4 [scrollbar-width:none]">
        <label className="relative shrink-0">
          <FilterPill dropdown selected={!!cuisine} onClick={() => undefined}>{cuisine ?? service.typeFilter}</FilterPill>
          <select aria-label={service.typeFilter} value={cuisine ?? ""} onChange={(e) => setCuisine(e.target.value || undefined)}
            className="absolute inset-0 cursor-pointer opacity-0">
            <option value="">Any</option>
            {cuisines.map((c) => <option key={c}>{c}</option>)}
          </select>
        </label>
        <FilterPill selected={pickup} onClick={() => setPickup(!pickup)}><Footprints className="size-4" aria-hidden="true" /> Pickup</FilterPill>
        <label className="relative shrink-0">
          <FilterPill dropdown selected={sort !== "recommended"} onClick={() => undefined}>{sort === "recommended" ? "Sort by" : SORTS[sort]}</FilterPill>
          <select aria-label="Sort by" value={sort} onChange={(e) => setSort(e.target.value)} className="absolute inset-0 cursor-pointer opacity-0">
            {Object.entries(SORTS).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </select>
        </label>
      </div>

      {query.length < 2 && !category && popular.length > 0 && (
        <>
          <SectionTitle info="Highest-rated near you">{service.popular}</SectionTitle>
          <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-1 [scrollbar-width:none]">
            {popular.map((r) => <BrandTile key={r.id} card={r} />)}
          </div>
        </>
      )}

      {query.length >= 2 && (hits.data?.items.length ?? 0) > 0 && (
        <>
          <SectionTitle>{service.items}</SectionTitle>
          <ul className="divide-y divide-border rounded-2xl border border-border">
            {hits.data!.items.slice(0, 6).map((h) => (
              <li key={h.item.id}>
                <Link href={`/restaurants/${h.restaurant_id}`} className="flex items-center gap-3 p-3 hover:bg-surface-muted">
                  <span className="grid size-10 place-items-center rounded-full bg-primary-soft text-primary">
                    <ItemIcon className="size-5" aria-hidden="true" />
                  </span>
                  <span className="flex-1">
                    <span className="block font-semibold">{h.item.name}{h.item.unit_label ? ` · ${h.item.unit_label}` : ""}</span>
                    <span className="text-sm text-muted">{h.restaurant_name}</span>
                  </span>
                  <span className="font-bold">{formatNaira(h.item.price_kobo)}</span>
                </Link>
              </li>
            ))}
          </ul>
        </>
      )}

      <SectionTitle>
        {category ? (cats.data?.find((c) => c.id === category)?.name ?? "Results") : service.allShops}
      </SectionTitle>
      {list.isLoading ? (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">{[0, 1, 2].map((i) => <Skeleton key={i} className="aspect-[16/10] rounded-3xl" />)}</div>
      ) : list.error ? (
        <ErrorState message={(list.error as Error).message} onRetry={() => list.refetch()} />
      ) : (list.data ?? []).length === 0 ? (
        <EmptyBlock
          icon={<Search className="size-8" aria-hidden="true" />}
          title="No matches nearby"
          body="Try another category, turn off filters, or change your area."
          action={<button type="button" className="font-semibold text-primary" onClick={() => { setCategory(undefined); setCuisine(undefined); setPickup(false); }}>Clear filters</button>}
        />
      ) : (
        <div className="grid gap-7 md:grid-cols-2 lg:grid-cols-3">
          {(list.data as RestaurantCard[]).map((r) => <MerchantCard key={r.id} card={r} />)}
        </div>
      )}
    </div>
  );
}
