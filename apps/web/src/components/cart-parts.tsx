"use client";

import type { MenuItem, OptionGroup, RestaurantDetail } from "@gudmeal/api-client";
import { cn } from "@gudmeal/ui";
import { Minus, Plus, Trash2, UtensilsCrossed } from "lucide-react";
import type { CartItem, CartShop } from "@/lib/cart";

/** How many suggestions "You might also like" shows. */
const SUGGESTIONS = 10;

/** "1 product from Shop", "3 products from Shop", "5 products from 3 shops". */
export function cartSummary(shops: CartShop[]): { products: string; from: string } {
  const n = shops.reduce((sum, s) => sum + s.count, 0);
  return {
    products: `${n} ${n === 1 ? "product" : "products"} from`,
    from: shops.length === 1 ? shops[0]!.restaurant_name : `${shops.length} shops`,
  };
}

/** A menu item's photo, or a soft placeholder with its emoji (or a plate) until the shop uploads one. */
export function Thumb({ item, className }: { item?: Pick<MenuItem, "image_url" | "emoji"> | null; className?: string }) {
  return (
    <span className={cn("grid shrink-0 place-items-center overflow-hidden rounded-2xl bg-primary-soft text-primary", className)}>
      {item?.image_url ? (
        // eslint-disable-next-line @next/next/no-img-element -- shop photos come from many hosts
        <img src={item.image_url} alt="" className="size-full object-cover" />
      ) : item?.emoji ? (
        <span className="text-3xl" aria-hidden="true">{item.emoji}</span>
      ) : (
        <UtensilsCrossed className="size-6" aria-hidden="true" />
      )}
    </span>
  );
}

/** − / quantity / + in a pill; at one, the − becomes a bin that takes the line out. */
export function Stepper({ item, onQuantity, onRemove }: {
  item: CartItem; onQuantity: (key: string, quantity: number) => void; onRemove: (key: string) => void;
}) {
  return (
    <div className="flex h-10 items-center rounded-full bg-surface-muted px-1">
      {item.quantity <= 1 ? (
        <button type="button" onClick={() => onRemove(item.key)} aria-label={`Remove ${item.name} from cart`}
          className="grid size-8 place-items-center rounded-full hover:bg-border hover:text-danger">
          <Trash2 className="size-4" aria-hidden="true" />
        </button>
      ) : (
        <button type="button" onClick={() => onQuantity(item.key, item.quantity - 1)} aria-label={`Remove one ${item.name}`}
          className="grid size-8 place-items-center rounded-full hover:bg-border">
          <Minus className="size-4" aria-hidden="true" />
        </button>
      )}
      <span className="w-7 text-center font-bold tabular-nums" aria-live="polite">{item.quantity}</span>
      <button type="button" onClick={() => onQuantity(item.key, item.quantity + 1)} aria-label={`Add one ${item.name}`}
        className="grid size-8 place-items-center rounded-full hover:bg-border">
        <Plus className="size-4" aria-hidden="true" />
      </button>
    </div>
  );
}

export interface Suggestion { item: MenuItem; shop: RestaurantDetail }

/** Popular, available products of the shops in the cart that are not in it yet, most popular first. */
export function suggestions(details: RestaurantDetail[], inCart: Set<string>, limit = SUGGESTIONS): Suggestion[] {
  return details
    .filter((d) => d.restaurant.is_open && d.restaurant.is_accepting_orders)
    .flatMap((shop) => shop.sections.flatMap((s) => s.items).map((item) => ({ item, shop })))
    .filter(({ item, shop }) => item.is_available && item.is_active && !item.requires_prescription
      && !inCart.has(`${shop.restaurant.id}/${item.id}`))
    .sort((a, b) => b.item.popularity - a.item.popularity)
    .slice(0, limit);
}

export const needsChoice = (item: MenuItem, groups: Record<string, OptionGroup>) =>
  item.option_group_ids.some((id) => (groups[id]?.min_select ?? 1) > 0);
