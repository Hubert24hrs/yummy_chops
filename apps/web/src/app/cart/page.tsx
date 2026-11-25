"use client";

import { formatNaira, type MenuItem, type RestaurantDetail } from "@gudmeal/api-client";
import { Button, EmptyState, Price, Skeleton } from "@gudmeal/ui";
import { useQueries } from "@tanstack/react-query";
import { ChevronLeft, ChevronRight, Plus, ShoppingBag, Trash2 } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";
import { cartSummary, needsChoice, Stepper, suggestions, Thumb, type Suggestion } from "@/components/cart-parts";
import { ItemDialog } from "@/components/item-dialog";
import { Sheet } from "@/components/sheet";
import { publicApi } from "@/lib/api";
import { cartKey, useCart } from "@/lib/cart";
import { listPrice, serviceCopy } from "@/lib/services";

export default function CartPage() {
  const router = useRouter();
  const { cart, shops, setQuantity, remove, clear, add, subtotalKobo, ready } = useCart();
  const [confirmClear, setConfirmClear] = useState(false);
  const [choosing, setChoosing] = useState<Suggestion | null>(null);

  // The shops' menus: photos for the cart's lines, and what to suggest next to them.
  const menus = useQueries({
    queries: shops.map((s) => ({
      queryKey: ["restaurant", s.restaurant_id],
      queryFn: () => publicApi.catalog.restaurant(s.restaurant_id),
      staleTime: 300_000,
    })),
  });
  const details = menus.map((m) => m.data).filter((d): d is RestaurantDetail => Boolean(d));
  const products = useMemo(() => {
    const byKey = new Map<string, MenuItem>();
    for (const d of details) for (const s of d.sections) for (const i of s.items) byKey.set(`${d.restaurant.id}/${i.id}`, i);
    return byKey;
  }, [details]);
  const inCart = new Set(cart.items.map((i) => `${i.restaurant_id}/${i.item_id}`));
  const liked = suggestions(details, inCart);

  function addSuggestion(s: Suggestion) {
    if (needsChoice(s.item, s.shop.option_groups)) {
      setChoosing(s);
      return;
    }
    const shop = s.shop.restaurant;
    add(shop.id, shop.name, {
      key: cartKey(shop.id, s.item.id, []), item_id: s.item.id, name: s.item.name, unit_price_kobo: s.item.price_kobo,
      quantity: 1, selections: [], selection_labels: [],
    });
  }

  const back = () => (window.history.length > 1 ? router.back() : router.push("/"));
  const summary = cartSummary(shops);
  const several = shops.length > 1;

  return (
    <div className="mx-auto w-full max-w-2xl px-4 pb-36 md:px-6">
      <div className="relative flex h-16 items-center justify-center">
        <button type="button" onClick={back} aria-label="Back"
          className="absolute left-0 grid size-11 place-items-center rounded-full bg-surface-muted hover:bg-border">
          <ChevronLeft className="size-5" aria-hidden="true" />
        </button>
        <p className="text-lg font-semibold">Cart</p>
      </div>

      {!ready ? (
        <div className="space-y-3 py-6" aria-busy="true"><Skeleton className="h-10 w-2/3" /><Skeleton className="h-24" /><Skeleton className="h-24" /></div>
      ) : shops.length === 0 ? (
        <div className="py-12">
          <EmptyState icon={<ShoppingBag className="size-8" />} title="Your cart is empty"
            body="Add food, medicines, groceries and more — from as many shops as you like."
            action={<Link href="/restaurants"><Button>Browse shops</Button></Link>} />
        </div>
      ) : (
        <>
          <div className="mt-4 flex items-start justify-between gap-4">
            <div>
              <h1 className="font-display text-3xl md:text-4xl">Your cart</h1>
              <p className="mt-1.5">{summary.products} <strong>{summary.from}</strong></p>
            </div>
            <button type="button" onClick={() => setConfirmClear(true)} aria-label="Empty cart"
              className="grid size-12 shrink-0 place-items-center rounded-full bg-surface-muted hover:bg-border hover:text-danger">
              <Trash2 className="size-5" aria-hidden="true" />
            </button>
          </div>

          <div className="mt-6 space-y-8 border-t border-border pt-6">
            {shops.map((shop) => (
              <section key={shop.restaurant_id} aria-label={shop.restaurant_name} className="space-y-4">
                {several && (
                  <div className="flex items-baseline justify-between gap-3">
                    <h2 className="text-lg font-bold">{shop.restaurant_name}</h2>
                    <Price kobo={shop.subtotal_kobo} className="text-sm text-muted" />
                  </div>
                )}
                <ul className="space-y-4">
                  {shop.items.map((item) => (
                    <li key={item.key} className="flex items-center gap-4">
                      <Thumb item={products.get(`${item.restaurant_id}/${item.item_id}`)} className="size-20" />
                      <div className="min-w-0 flex-1">
                        <p className="font-semibold leading-snug">{item.name}</p>
                        {item.selection_labels.length > 0 && <p className="text-xs text-muted">{item.selection_labels.join(" · ")}</p>}
                        {item.notes && <p className="text-xs italic text-muted">“{item.notes}”</p>}
                        <Price kobo={item.unit_price_kobo * item.quantity} className="mt-1 block font-semibold" />
                      </div>
                      <Stepper item={item} onQuantity={setQuantity} onRemove={remove} />
                    </li>
                  ))}
                </ul>
                <div className="flex justify-end">
                  <Link href={`/restaurants/${shop.restaurant_id}`}
                    className="inline-flex h-11 items-center rounded-full bg-surface-muted px-5 font-semibold hover:bg-border">
                    Add more items{several ? <span className="sr-only"> from {shop.restaurant_name}</span> : null}
                  </Link>
                </div>
              </section>
            ))}
          </div>

          {liked.length > 0 && (
            <section aria-label="You might also like" className="mt-10">
              <h2 className="font-display text-2xl">You might also like</h2>
              <ul className="-mx-4 mt-4 flex gap-3 overflow-x-auto px-4 pb-2 [scrollbar-width:none] md:-mx-6 md:px-6">
                {liked.map((s) => {
                  const price = listPrice(s.item, s.shop.option_groups);
                  return (
                    <li key={`${s.shop.restaurant.id}/${s.item.id}`} className="w-[150px] shrink-0 sm:w-[170px]">
                      <div className="relative">
                        <Thumb item={s.item} className="aspect-square w-full" />
                        <button type="button" onClick={() => addSuggestion(s)} aria-label={`Add ${s.item.name}`}
                          className="absolute bottom-2 right-2 grid size-10 place-items-center rounded-full bg-surface text-text shadow-raised hover:bg-primary hover:text-on-primary">
                          <Plus className="size-5" aria-hidden="true" />
                        </button>
                      </div>
                      <p className="mt-2 line-clamp-2 text-sm font-semibold leading-snug">{s.item.name}</p>
                      <p className="text-sm">{price.from ? "From " : ""}{formatNaira(price.kobo)}</p>
                      {several && <p className="truncate text-xs text-muted">{s.shop.restaurant.name}</p>}
                    </li>
                  );
                })}
              </ul>
            </section>
          )}

          <div className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-surface/95 pb-[env(safe-area-inset-bottom)] backdrop-blur">
            <div className="mx-auto flex w-full max-w-2xl items-center justify-between gap-4 px-4 py-3 md:px-6">
              <div className="min-w-0">
                <Price kobo={subtotalKobo} className="block text-xl font-bold" />
                <span className="text-xs text-muted">Fees at checkout</span>
              </div>
              <Link href="/checkout"
                className="inline-flex h-12 shrink-0 items-center gap-1 whitespace-nowrap rounded-full bg-primary pl-6 pr-4 font-semibold text-on-primary shadow-sm hover:bg-primary-strong">
                Go to checkout <ChevronRight className="size-5" aria-hidden="true" />
              </Link>
            </div>
          </div>
        </>
      )}

      <Sheet open={confirmClear} onClose={() => setConfirmClear(false)} title="Empty your cart?" footer={
        <>
          <Button block size="lg" variant="danger" onClick={() => { clear(); setConfirmClear(false); }}>Empty cart</Button>
          <Button block size="lg" variant="ghost" className="bg-surface-muted" onClick={() => setConfirmClear(false)}>Keep my items</Button>
        </>
      }>
        <p className="text-muted">Everything in your cart{several ? `, from all ${shops.length} shops,` : ""} will be taken out.</p>
      </Sheet>

      {choosing && (
        <ItemDialog item={choosing.item} groups={choosing.shop.option_groups} restaurantId={choosing.shop.restaurant.id}
          restaurantName={choosing.shop.restaurant.name} goToCart={false}
          notesFor={serviceCopy(choosing.shop.restaurant.vertical).notesFor} notesHint={serviceCopy(choosing.shop.restaurant.vertical).notesHint} onClose={() => setChoosing(null)} />
      )}
    </div>
  );
}
