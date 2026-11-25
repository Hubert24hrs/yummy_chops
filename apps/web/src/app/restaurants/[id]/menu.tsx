"use client";

import type { MenuItem, RestaurantDetail } from "@gudmeal/api-client";
import { Badge, Button, Price, cn } from "@gudmeal/ui";
import { Flame, Leaf, Plus } from "lucide-react";
import { useState } from "react";
import { ItemDialog } from "@/components/item-dialog";
import { useCart } from "@/lib/cart";
import { serviceCopy } from "@/lib/services";

/** `openItemId`: open that dish's options straight away (from the Discover carousel), if it can be ordered now. */
export function Menu({ detail, openItemId }: { detail: RestaurantDetail; openItemId?: string }) {
  const canOrder = detail.restaurant.is_open && detail.restaurant.is_accepting_orders;
  const [selected, setSelected] = useState<MenuItem | null>(() => {
    if (!openItemId || !canOrder) return null;
    const item = detail.sections.flatMap((s) => s.items).find((i) => i.id === openItemId);
    return item?.is_available ? item : null;
  });
  const { count, subtotalKobo } = useCart();
  const service = serviceCopy(detail.restaurant.vertical);

  return (
    <div className="grid gap-8 py-8 lg:grid-cols-[200px_1fr]">
      <nav className="hidden lg:block" aria-label="Menu categories">
        <ul className="sticky top-24 space-y-1 text-sm">
          {detail.sections.map((s) => (
            <li key={s.category.id}>
              <a href={`#cat-${s.category.id}`} className="block rounded-md px-3 py-2 font-medium hover:bg-surface-muted">{s.category.name}</a>
            </li>
          ))}
        </ul>
      </nav>
      <div className="space-y-10">
        {detail.sections.map((section) => (
          <section key={section.category.id} id={`cat-${section.category.id}`} className="scroll-mt-24">
            <h2 className="mb-4 font-display text-2xl">{section.category.name}</h2>
            <div className="grid gap-4 md:grid-cols-2">
              {section.items.map((item) => (
                <button key={item.id} onClick={() => setSelected(item)} disabled={!item.is_available || !canOrder}
                  className={cn("group flex gap-4 rounded-lg border border-border bg-surface p-4 text-left shadow-card transition-colors hover:border-primary disabled:cursor-not-allowed disabled:opacity-60")}>
                  <div className="min-w-0 flex-1 space-y-1">
                    <h3 className="font-semibold">{item.name}{item.unit_label ? <span className="font-normal text-muted"> · {item.unit_label}</span> : null}</h3>
                    {item.description && <p className="line-clamp-2 text-sm text-muted">{item.description}</p>}
                    <div className="flex flex-wrap items-center gap-2 pt-1">
                      <Price kobo={item.price_kobo} className="font-semibold" />
                      {item.serves > 1 && <Badge tone="info">Serves {item.serves}</Badge>}
                      {item.spice_level >= 2 && <Badge tone="danger"><Flame className="size-3" /> Spicy</Badge>}
                      {item.dietary.includes("vegetarian") && <Badge tone="success"><Leaf className="size-3" /> Veg</Badge>}
                      {!item.is_available && <Badge>Sold out</Badge>}
                    </div>
                  </div>
                  <span className="grid size-9 shrink-0 place-items-center self-end rounded-full bg-primary-soft text-primary-strong group-hover:bg-primary group-hover:text-on-primary">
                    <Plus className="size-5" aria-hidden="true" />
                    <span className="sr-only">Add {item.name}</span>
                  </span>
                </button>
              ))}
            </div>
          </section>
        ))}
      </div>
      {selected && (
        <ItemDialog item={selected} groups={detail.option_groups} restaurantId={detail.restaurant.id}
          restaurantName={detail.restaurant.name} notesFor={service.notesFor} notesHint={service.notesHint} onClose={() => setSelected(null)} />
      )}
      {count > 0 && (
        <div className="fixed inset-x-0 bottom-4 z-20 px-4 lg:hidden">
          <a href="/checkout" className="block">
            <Button block size="lg">View cart · {count} · <Price kobo={subtotalKobo} /></Button>
          </a>
        </div>
      )}
    </div>
  );
}
