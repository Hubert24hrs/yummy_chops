import type { MenuItem, MerchantVertical, OptionGroup } from "@gudmeal/api-client";
import { Pill, ShoppingBasket, ShoppingCart, Sparkles, UtensilsCrossed, type LucideIcon } from "lucide-react";

/**
 * How the website names a merchant service and its shops (ADR-0018, names from ADR-0025). The API calls a service a
 * "vertical". The services, in the owner's order: Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries, Buy
 * Foodstuff (and Package Delivery, a courier job rather than a shop).
 */
export interface ServiceCopy {
  /** The API's id. */
  id: MerchantVertical;
  title: string;
  /** The service's page. */
  href: string;
  icon: LucideIcon;
  /** Short name for the search box: "Search in Beauty". */
  searchIn: string;
  /** "restaurants", "stores", "pharmacies", "markets", "shops". */
  shops: string;
  allShops: string;
  /** "Popular brands", "Popular stores" ... */
  popular: string;
  /** What the shop sells, for search results: "Dishes", "Products", "Foodstuff". */
  items: string;
  /** The label of the filter by what a shop carries: "Food type", "Department" ... */
  typeFilter: string;
  /** "ready in", "packed in", "bought in" (before "~12 min"). */
  readyIn: string;
  /** Who reads a note the customer leaves on a product. */
  notesFor: string;
  notesHint: string;
  /** schema.org type of the shop's page. */
  schemaType: string;
  /** Something customers should know before they shop. */
  note?: string;
  /** Shops that sell products by the aisle: their pages show aisles, sizes and stock instead of a menu. */
  retail: boolean;
}

export const SERVICES: ServiceCopy[] = [
  {
    id: "food", title: "Order Food", href: "/food", icon: UtensilsCrossed, searchIn: "Food", shops: "restaurants", allShops: "All restaurants",
    popular: "Popular brands", items: "Dishes", typeFilter: "Food type", readyIn: "ready in", notesFor: "the kitchen",
    notesHint: "e.g. less pepper, no onions", schemaType: "Restaurant", retail: false,
  },
  {
    id: "pharmacy", title: "Pharmacy", href: "/pharmacy", icon: Pill, searchIn: "Pharmacy", shops: "pharmacies", allShops: "All pharmacies",
    popular: "Popular pharmacies", items: "Products", typeFilter: "Health need", readyIn: "packed in", notesFor: "the pharmacy",
    notesHint: "e.g. the children's flavour", schemaType: "Pharmacy", retail: true,
    note: "Over-the-counter products only. For prescription medicines, take your prescription to a pharmacy.",
  },
  {
    id: "beauty", title: "Beauty & Skin Care", href: "/beauty", icon: Sparkles, searchIn: "Beauty", shops: "shops", allShops: "All shops",
    popular: "Popular shops", items: "Products", typeFilter: "Product type", readyIn: "packed in", notesFor: "the shop",
    notesHint: "e.g. the lighter shade", schemaType: "Store", retail: false,
  },
  {
    id: "grocery", title: "Shop & Groceries", href: "/groceries", icon: ShoppingCart, searchIn: "Groceries", shops: "stores", allShops: "All stores",
    popular: "Popular stores", items: "Products", typeFilter: "Department", readyIn: "packed in", notesFor: "the store",
    notesHint: "e.g. a far expiry date, the ripest ones", schemaType: "GroceryStore", retail: true,
  },
  {
    id: "market", title: "Buy Foodstuff", href: "/foodstuff", icon: ShoppingBasket, searchIn: "Foodstuff", shops: "markets",
    allShops: "All markets", popular: "Popular markets", items: "Foodstuff", typeFilter: "Foodstuff type", readyIn: "bought in",
    notesFor: "your shopper", notesHint: "e.g. not too ripe, cut the fish into six", schemaType: "GroceryStore", retail: true,
    note: "A shopper buys these fresh for you at the market. Sizes are market measures: derica, paint, bunch.",
  },
];

/** The copy for a service; unknown services read like Food, so the page still shows something sensible. */
export function serviceCopy(vertical: string | null | undefined): ServiceCopy {
  return SERVICES.find((s) => s.id === vertical) ?? SERVICES[0]!;
}

/** Names of every kind of order, for spending summaries and order lists. */
export const SERVICE_NAMES: Record<string, string> = {
  ...Object.fromEntries(SERVICES.map((s) => [s.id, s.title])),
  parcel: "Package Delivery",
  waybill: "Interstate",
};

/**
 * The price to show on a product: its lowest real price, and whether it starts "From" because a choice the
 * customer must make can cost more (beef by weight, eggs by the crate). Mirrors how the server prices a line.
 */
export function listPrice(item: Pick<MenuItem, "price_kobo" | "option_group_ids">, groups: Record<string, OptionGroup>): { kobo: number; from: boolean } {
  let kobo = item.price_kobo;
  let from = false;
  for (const id of item.option_group_ids) {
    const group = groups[id];
    if (!group || group.min_select <= 0 || group.choices.length === 0) continue;
    const deltas = group.choices.map((c) => c.price_delta_kobo).sort((a, b) => a - b);
    kobo += deltas.slice(0, group.min_select).reduce((a, b) => a + b, 0);
    if (deltas[deltas.length - 1]! > deltas[0]!) from = true;
  }
  return { kobo, from };
}
