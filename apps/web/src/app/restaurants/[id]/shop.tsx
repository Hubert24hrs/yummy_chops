"use client";

import type { MenuItem, MenuSection, OptionGroup, RestaurantDetail } from "@gudmeal/api-client";
import { formatNaira } from "@gudmeal/api-client";
import { Button, Price, cn } from "@gudmeal/ui";
import { Plus, Search } from "lucide-react";
import { useDeferredValue, useMemo, useState } from "react";
import { ItemDialog } from "@/components/item-dialog";
import { EmptyBlock, SectionTitle, ServiceNote } from "@/components/storefront";
import { cartKey, useCart } from "@/lib/cart";
import { listPrice, serviceCopy } from "@/lib/services";

/** Products shown per aisle before "View more". */
export const AISLE_PREVIEW = 6;

const GRID = "grid grid-cols-3 gap-x-3 gap-y-5 sm:grid-cols-4 lg:grid-cols-6";

const inStockFirst = (items: MenuItem[]) => [...items].sort((a, b) => Number(b.is_available) - Number(a.is_available));

/** The best sellers of a shop that can be bought now, most popular first. */
export function popularProducts(sections: MenuSection[], limit = 8): MenuItem[] {
  return sections.flatMap((s) => s.items).filter((i) => i.is_available).sort((a, b) => b.popularity - a.popularity).slice(0, limit);
}

/** Products matching every word of the search by name, brand or size; products in stock come first. */
export function searchProducts(sections: MenuSection[], query: string): MenuItem[] {
  const words = query.toLowerCase().split(" ").filter(Boolean);
  if (words.length === 0) return [];
  return inStockFirst(sections.flatMap((s) => s.items).filter((i) => {
    const text = `${i.name} ${i.brand ?? ""} ${i.unit_label ?? ""}`.toLowerCase();
    return words.every((w) => text.includes(w));
  }));
}

/**
 * A shop browsed by the aisle: supermarkets, pharmacies and market shoppers (ADR-0018). Search, the popular
 * products, the aisles, a few products per aisle with "View more", sizes or market measures, "From" prices and
 * out-of-stock labels. `openItemId` opens that product straight away, if it can be ordered now.
 */
export function Shop({ detail, openItemId }: { detail: RestaurantDetail; openItemId?: string }) {
  const shop = detail.restaurant;
  const service = serviceCopy(shop.vertical);
  const canOrder = shop.is_open && shop.is_accepting_orders;
  const sections = useMemo(() => detail.sections.filter((s) => s.items.length > 0), [detail.sections]);
  const [selected, setSelected] = useState<MenuItem | null>(() => {
    if (!openItemId || !canOrder) return null;
    const item = detail.sections.flatMap((s) => s.items).find((i) => i.id === openItemId);
    return item?.is_available ? item : null;
  });
  const [q, setQ] = useState("");
  const query = useDeferredValue(q.trim());
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const { cart, add, count, subtotalKobo } = useCart();
  const inThisCart = cart.restaurant_id === shop.id;
  const otherShop = cart.restaurant_id !== null && !inThisCart && cart.items.length > 0;

  const popular = useMemo(() => popularProducts(sections), [sections]);
  const hits = useMemo(() => searchProducts(sections, query), [sections, query]);
  const inCart = (item: MenuItem) => (inThisCart ? cart.items.filter((l) => l.item_id === item.id).reduce((n, l) => n + l.quantity, 0) : 0);

  /** One tap adds a product that needs no choice; anything else opens its options. */
  function quickAdd(item: MenuItem) {
    if (item.option_group_ids.length > 0 || otherShop) {
      setSelected(item);
      return;
    }
    add(shop.id, shop.name, {
      key: cartKey(item.id, []), item_id: item.id, name: item.name, unit_price_kobo: item.price_kobo, quantity: 1,
      selections: [], selection_labels: [],
    });
  }

  const card = (item: MenuItem, className?: string) => (
    <ProductCard key={item.id} item={item} groups={detail.option_groups} canOrder={canOrder} inCart={inCart(item)}
      onOpen={() => setSelected(item)} onAdd={() => quickAdd(item)} className={className} />
  );

  return (
    <div className="py-6">
      {service.note && <ServiceNote className="mb-4">{service.note}</ServiceNote>}
      <label className="flex items-center gap-2 rounded-full bg-surface-muted px-4 py-3">
        <Search className="size-5 text-muted" aria-hidden="true" />
        <span className="sr-only">Search in {shop.name}</span>
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={`Search in ${shop.name}`} type="search"
          className="w-full bg-transparent outline-none placeholder:text-muted" />
      </label>

      {query ? (
        hits.length === 0 ? (
          <div className="mt-6">
            <EmptyBlock icon={<Search className="size-8" aria-hidden="true" />} title={`Nothing matches “${query}”`}
              body="Check the spelling, or browse the aisles."
              action={<button type="button" className="font-semibold text-primary" onClick={() => setQ("")}>Clear search</button>} />
          </div>
        ) : (
          <>
            <SectionTitle>{hits.length} found</SectionTitle>
            <div className={GRID}>{hits.map((i) => card(i))}</div>
          </>
        )
      ) : (
        <>
          {popular.length >= 3 && (
            <section aria-label="Popular">
              <SectionTitle info="What people buy most here">Popular</SectionTitle>
              <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-1 [scrollbar-width:none]">
                {popular.map((i) => card(i, "w-[116px] shrink-0 sm:w-[140px]"))}
              </div>
            </section>
          )}

          <nav aria-label="Aisles">
            <SectionTitle>Browse all</SectionTitle>
            <ul className="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1 [scrollbar-width:none]">
              {sections.map((s) => (
                <li key={s.category.id} className="shrink-0">
                  <a href={`#aisle-${s.category.id}`} className="block whitespace-nowrap rounded-full bg-surface-muted px-4 py-2 text-sm font-semibold hover:bg-primary-soft">
                    {s.category.name} <span className="font-normal text-muted">{s.items.length}</span>
                  </a>
                </li>
              ))}
            </ul>
          </nav>

          {sections.map((s) => {
            const open = expanded[s.category.id] ?? false;
            const items = inStockFirst(s.items);
            return (
              <section key={s.category.id} id={`aisle-${s.category.id}`} aria-label={s.category.name} className="scroll-mt-24">
                <SectionTitle
                  action={s.items.length > AISLE_PREVIEW ? (
                    <button type="button" aria-expanded={open} className="text-sm font-semibold text-primary hover:underline"
                      onClick={() => setExpanded((e) => ({ ...e, [s.category.id]: !open }))}>
                      {open ? "Show less" : `View more (${s.items.length})`}
                    </button>
                  ) : undefined}
                >
                  {s.category.name}
                </SectionTitle>
                <div className={GRID}>{(open ? items : items.slice(0, AISLE_PREVIEW)).map((i) => card(i))}</div>
              </section>
            );
          })}
        </>
      )}

      {selected && (
        <ItemDialog item={selected} groups={detail.option_groups} restaurantId={shop.id} restaurantName={shop.name}
          notesFor={service.notesFor} notesHint={service.notesHint} onClose={() => setSelected(null)} />
      )}
      {inThisCart && count > 0 && (
        <div className="fixed inset-x-0 bottom-4 z-20 px-4 lg:hidden">
          <a href="/checkout" className="block">
            <Button block size="lg">View order · {count} · <Price kobo={subtotalKobo} /></Button>
          </a>
        </div>
      )}
    </div>
  );
}

/** A product on the shelf: picture, name, brand and size, price ("From" when a choice changes it), stock. */
export function ProductCard({ item, groups, canOrder, inCart, onOpen, onAdd, className }: {
  item: MenuItem; groups: Record<string, OptionGroup>; canOrder: boolean; inCart: number; onOpen: () => void; onAdd: () => void; className?: string;
}) {
  const price = listPrice(item, groups);
  const meta = [item.brand, item.unit_label].filter(Boolean).join(" · ");
  const buyable = canOrder && item.is_available;
  return (
    <div className={cn("relative", className)}>
      <button type="button" onClick={onOpen} disabled={!buyable} className="group block w-full text-left focus-visible:outline-none disabled:cursor-not-allowed">
        <span className={cn("relative grid aspect-square place-items-center overflow-hidden rounded-2xl bg-surface-muted text-4xl transition-colors group-hover:bg-primary-soft sm:text-5xl", !item.is_available && "opacity-60")}>
          {item.image_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={item.image_url} alt="" className="size-full object-cover" />
          ) : (
            <span aria-hidden="true">{item.emoji ?? "🛒"}</span>
          )}
          {!item.is_available && (
            <span className="absolute inset-x-0 bottom-0 bg-black/65 py-1 text-center text-[11px] font-bold text-white">Out of stock</span>
          )}
        </span>
        <span className="mt-1.5 line-clamp-2 block text-sm font-semibold leading-snug">{item.name}</span>
        {meta && <span className="block truncate text-xs text-muted">{meta}</span>}
        <span className="block text-sm font-bold">{price.from ? "From " : ""}{formatNaira(price.kobo)}</span>
      </button>
      {buyable && (
        <button type="button" onClick={onAdd} aria-label={inCart > 0 ? `Add another ${item.name} (${inCart} in your order)` : `Add ${item.name}`}
          className={cn("absolute right-1.5 top-1.5 grid size-8 place-items-center rounded-full text-sm font-bold shadow", inCart > 0 ? "bg-primary text-on-primary" : "bg-white text-primary-strong hover:bg-primary hover:text-on-primary")}>
          {inCart > 0 ? <span className="tabular-nums">{inCart}</span> : <Plus className="size-4" aria-hidden="true" />}
        </button>
      )}
    </div>
  );
}
