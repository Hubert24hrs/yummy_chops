"use client";

import type { CartLine, OptionSelection } from "@gudmeal/api-client";
import { createContext, useCallback, useContext, useEffect, useMemo, useReducer, useState, type ReactNode } from "react";

/**
 * One cart holds items from any number of shops (food, pharmacy, beauty, groceries...); each item keeps its shop.
 * At checkout there is one order per shop and one payment for all of them. Prices here are for display only — the
 * server quote is authoritative.
 */
export interface CartItem {
  key: string;
  restaurant_id: string;
  restaurant_name: string;
  item_id: string;
  name: string;
  unit_price_kobo: number;
  quantity: number;
  selections: OptionSelection[];
  selection_labels: string[];
  notes?: string;
}

/** What a page hands to `add`: the shop comes as its own arguments. */
export type NewCartItem = Omit<CartItem, "restaurant_id" | "restaurant_name">;

export interface CartState {
  items: CartItem[];
}

/** The items of one shop in the cart, in the order they were added. */
export interface CartShop {
  restaurant_id: string;
  restaurant_name: string;
  items: CartItem[];
  subtotal_kobo: number;
  count: number;
}

type Action =
  | { type: "add"; restaurant_id: string; restaurant_name: string; item: NewCartItem }
  | { type: "quantity"; key: string; quantity: number }
  | { type: "remove"; key: string }
  | { type: "clear" }
  | { type: "hydrate"; state: CartState };

const EMPTY: CartState = { items: [] };
export const STORAGE_KEY = "gudmeal.cart.v2";
/** The cart of one shop that older versions of the website saved. */
export const LEGACY_STORAGE_KEY = "gudmeal.cart.v1";
const MAX_QUANTITY = 50;

/** A line's identity: the same product with the same choices and note from the same shop is one line. */
export function cartKey(restaurantId: string, itemId: string, selections: OptionSelection[], notes?: string): string {
  const sel = selections.map((s) => `${s.group_id}:${[...s.choice_ids].sort().join(",")}`).sort().join("|");
  return `${restaurantId}/${itemId}#${sel}#${notes ?? ""}`;
}

function isItem(x: unknown): x is CartItem {
  const i = x as CartItem;
  return Boolean(i) && typeof i.item_id === "string" && typeof i.restaurant_id === "string" && typeof i.quantity === "number"
    && i.quantity > 0 && typeof i.unit_price_kobo === "number";
}

/**
 * A saved cart in today's shape. A cart saved by the one-shop website (v1: the shop on the cart, not on the items)
 * becomes items of that shop, so nobody loses what they had put aside.
 */
export function migrateCart(raw: unknown): CartState {
  if (!raw || typeof raw !== "object") return EMPTY;
  const saved = raw as { restaurant_id?: string | null; restaurant_name?: string | null; items?: unknown };
  if (!Array.isArray(saved.items)) return EMPTY;
  const items = saved.items.map((x) => {
    const i = x as Partial<CartItem>;
    if (typeof i?.restaurant_id === "string") return i;
    if (!saved.restaurant_id || typeof i?.item_id !== "string") return null;
    return {
      ...i, restaurant_id: saved.restaurant_id, restaurant_name: saved.restaurant_name ?? "",
      key: cartKey(saved.restaurant_id, i.item_id, i.selections ?? [], i.notes),
      selections: i.selections ?? [], selection_labels: i.selection_labels ?? [],
    };
  }).filter(isItem);
  return { items };
}

export function cartReducer(state: CartState, action: Action): CartState {
  switch (action.type) {
    case "hydrate":
      return action.state;
    case "clear":
      return EMPTY;
    case "add": {
      // Adding never replaces the cart: a product from another shop joins it.
      const item: CartItem = { ...action.item, restaurant_id: action.restaurant_id, restaurant_name: action.restaurant_name };
      const existing = state.items.find((i) => i.key === item.key);
      const items = existing
        ? state.items.map((i) => (i.key === item.key ? { ...i, quantity: Math.min(MAX_QUANTITY, i.quantity + item.quantity) } : i))
        : [...state.items, item];
      return { items };
    }
    case "quantity": {
      const items = state.items
        .map((i) => (i.key === action.key ? { ...i, quantity: Math.max(0, Math.min(MAX_QUANTITY, action.quantity)) } : i))
        .filter((i) => i.quantity > 0);
      return { items };
    }
    case "remove":
      return { items: state.items.filter((i) => i.key !== action.key) };
  }
}

export function subtotal(items: CartItem[]): number {
  return items.reduce((sum, i) => sum + i.unit_price_kobo * i.quantity, 0);
}

/** The cart grouped by shop, shops in the order their first item was added. */
export function cartShops(state: CartState): CartShop[] {
  const shops = new Map<string, CartShop>();
  for (const item of state.items) {
    let shop = shops.get(item.restaurant_id);
    if (!shop) {
      shop = { restaurant_id: item.restaurant_id, restaurant_name: item.restaurant_name, items: [], subtotal_kobo: 0, count: 0 };
      shops.set(item.restaurant_id, shop);
    }
    shop.items.push(item);
    shop.subtotal_kobo += item.unit_price_kobo * item.quantity;
    shop.count += item.quantity;
  }
  return [...shops.values()];
}

export function toCartLines(items: CartItem[]): CartLine[] {
  return items.map((i) => ({ item_id: i.item_id, quantity: i.quantity, selections: i.selections, notes: i.notes || null }));
}

/** The allergy note rides on each shop's first line, so every shop sees it with the order. */
export function withAllergies(lines: CartLine[], allergies: string): CartLine[] {
  const note = allergies.trim();
  if (!note || !lines.length) return lines;
  const [first, ...rest] = lines;
  const text = first!.notes ? `${first!.notes} · Allergies: ${note}` : `Allergies: ${note}`;
  return [{ ...first!, notes: text.slice(0, 200) }, ...rest];
}

interface CartContextValue {
  cart: CartState;
  shops: CartShop[];
  count: number;
  subtotalKobo: number;
  /** False until the saved cart has been read: pages wait for it instead of flashing "Your cart is empty". */
  ready: boolean;
  add: (restaurantId: string, restaurantName: string, item: NewCartItem) => void;
  setQuantity: (key: string, quantity: number) => void;
  remove: (key: string) => void;
  clear: () => void;
}

const CartContext = createContext<CartContextValue | null>(null);

function readSaved(): CartState | null {
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (raw) return migrateCart(JSON.parse(raw));
  const legacy = window.localStorage.getItem(LEGACY_STORAGE_KEY);
  if (!legacy) return null;
  const migrated = migrateCart(JSON.parse(legacy));
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
  window.localStorage.removeItem(LEGACY_STORAGE_KEY);
  return migrated;
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, dispatch] = useReducer(cartReducer, EMPTY);
  // Persist only after the saved cart has been loaded; otherwise the first (empty) render would overwrite it.
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    try {
      const saved = readSaved();
      if (saved) dispatch({ type: "hydrate", state: saved });
    } catch {
      /* storage unavailable or unreadable — start empty */
    }
    setHydrated(true);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(cart));
    } catch {
      /* ignore */
    }
  }, [cart, hydrated]);

  const add = useCallback((rid: string, name: string, item: NewCartItem) => dispatch({ type: "add", restaurant_id: rid, restaurant_name: name, item }), []);
  const setQuantity = useCallback((key: string, quantity: number) => dispatch({ type: "quantity", key, quantity }), []);
  const remove = useCallback((key: string) => dispatch({ type: "remove", key }), []);
  const clear = useCallback(() => {
    // Write synchronously: checkout clears the cart right before redirecting to the payment page.
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(EMPTY));
    } catch {
      /* ignore */
    }
    dispatch({ type: "clear" });
  }, []);

  const value = useMemo(() => ({
    cart, add, setQuantity, remove, clear, ready: hydrated,
    shops: cartShops(cart),
    count: cart.items.reduce((n, i) => n + i.quantity, 0),
    subtotalKobo: subtotal(cart.items),
  }), [cart, add, setQuantity, remove, clear, hydrated]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartContextValue {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used inside CartProvider");
  return ctx;
}
