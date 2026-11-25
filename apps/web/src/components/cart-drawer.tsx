"use client";

import { Button, EmptyState, Price } from "@gudmeal/ui";
import { Minus, Plus, ShoppingBag, Trash2, X } from "lucide-react";
import Link from "next/link";
import { useEffect } from "react";
import { useCart, type CartItem } from "@/lib/cart";

export function CartDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { cart, shops, setQuantity, remove, subtotalKobo, clear } = useCart();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-40" role="dialog" aria-modal="true" aria-label="Your cart">
      <button className="absolute inset-0 bg-black/40" aria-label="Close cart" onClick={onClose} />
      <aside className="absolute right-0 top-0 flex h-dvh w-full max-w-md flex-col bg-background shadow-raised">
        <div className="flex items-center justify-between border-b border-border px-5 py-4">
          <div>
            <h2 className="font-display text-xl">Your cart</h2>
            {shops.length > 1 && <p className="text-sm text-muted">From {shops.length} shops · one payment for all</p>}
          </div>
          <button onClick={onClose} className="rounded-full p-2 hover:bg-surface-muted" aria-label="Close"><X className="size-5" /></button>
        </div>
        <div className="flex-1 space-y-5 overflow-y-auto px-5 py-4">
          {shops.length === 0 ? (
            <EmptyState icon={<ShoppingBag className="size-8" />} title="Your cart is empty"
              body="Add food, medicines, groceries and more — from as many shops as you like."
              action={<Link href="/restaurants" onClick={onClose}><Button size="sm">Browse shops</Button></Link>} />
          ) : shops.map((shop) => (
            <section key={shop.restaurant_id} aria-label={shop.restaurant_name} className="space-y-2">
              <div className="flex items-baseline justify-between gap-3">
                <h3 className="font-semibold">
                  <Link href={`/restaurants/${shop.restaurant_id}`} onClick={onClose} className="hover:underline">{shop.restaurant_name}</Link>
                </h3>
                <Price kobo={shop.subtotal_kobo} className="text-sm text-muted" />
              </div>
              {shop.items.map((item) => <CartLineRow key={item.key} item={item} onQuantity={setQuantity} onRemove={remove} />)}
            </section>
          ))}
        </div>
        {cart.items.length > 0 && (
          <div className="space-y-3 border-t border-border px-5 py-4">
            <div className="flex justify-between text-sm">
              <span className="text-muted">Items subtotal</span>
              <Price kobo={subtotalKobo} className="font-semibold" />
            </div>
            <p className="text-xs text-muted">
              Delivery, service fee and VAT are calculated at checkout{shops.length > 1 ? ", for each shop" : ""}.
            </p>
            <Link href="/checkout" onClick={onClose}><Button block size="lg">Go to checkout</Button></Link>
            <button onClick={clear} className="w-full text-center text-xs text-muted underline-offset-2 hover:underline">Clear cart</button>
          </div>
        )}
      </aside>
    </div>
  );
}

/** One line of the cart: what it is, its price, − / + and remove. Also used on the checkout page. */
export function CartLineRow({ item, onQuantity, onRemove }: {
  item: CartItem; onQuantity: (key: string, quantity: number) => void; onRemove: (key: string) => void;
}) {
  return (
    <div className="flex gap-3 rounded-md border border-border bg-surface p-3">
      <div className="min-w-0 flex-1">
        <p className="font-semibold">{item.name}</p>
        {item.selection_labels.length > 0 && <p className="text-xs text-muted">{item.selection_labels.join(" · ")}</p>}
        {item.notes && <p className="text-xs italic text-muted">“{item.notes}”</p>}
        <Price kobo={item.unit_price_kobo * item.quantity} className="mt-1 block text-sm font-semibold" />
      </div>
      <div className="flex items-center gap-1 self-center">
        <button type="button" className="grid size-8 place-items-center rounded-full border border-border hover:bg-surface-muted"
          onClick={() => onQuantity(item.key, item.quantity - 1)} aria-label={`Remove one ${item.name}`}>
          <Minus className="size-4" />
        </button>
        <span className="w-6 text-center tabular-nums" aria-live="polite">{item.quantity}</span>
        <button type="button" className="grid size-8 place-items-center rounded-full border border-border hover:bg-surface-muted"
          onClick={() => onQuantity(item.key, item.quantity + 1)} aria-label={`Add one ${item.name}`}>
          <Plus className="size-4" />
        </button>
        <button type="button" className="ml-1 grid size-8 place-items-center rounded-full text-muted hover:bg-surface-muted hover:text-danger"
          onClick={() => onRemove(item.key)} aria-label={`Remove ${item.name} from cart`}>
          <Trash2 className="size-4" />
        </button>
      </div>
    </div>
  );
}
