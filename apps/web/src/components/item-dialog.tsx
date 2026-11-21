"use client";

import type { CartLine, MenuItem, OptionGroup, OptionSelection } from "@gudmeal/api-client";
import { formatNaira } from "@gudmeal/api-client";
import { Button, Dialog, Textarea, cn } from "@gudmeal/ui";
import { Minus, Plus } from "lucide-react";
import { useMemo, useState } from "react";
import { cartKey, useCart } from "@/lib/cart";

/** Validates option groups exactly as the API does (min/max per group, available choices only). */
export function validateSelections(item: MenuItem, groups: Record<string, OptionGroup>, chosen: Record<string, string[]>): string | null {
  for (const gid of item.option_group_ids) {
    const g = groups[gid];
    if (!g) return "Some options are unavailable";
    const n = (chosen[gid] ?? []).length;
    if (n < g.min_select || n > g.max_select) {
      return g.min_select === g.max_select ? `Choose ${g.min_select} for “${g.name}”` : `Choose ${g.min_select}–${g.max_select} for “${g.name}”`;
    }
  }
  return null;
}

export function ItemDialog({ item, groups, restaurantId, restaurantName, onClose, onAdd, notesFor = "the kitchen", notesHint = "e.g. less pepper, no onions" }: {
  item: MenuItem; groups: Record<string, OptionGroup>; restaurantId: string; restaurantName: string; onClose: () => void;
  /** Who reads the note ("the kitchen", "your shopper") and an example of one. */
  notesFor?: string; notesHint?: string;
  /** Group orders: hand the chosen line to the caller instead of adding it to this device's cart. */
  onAdd?: (line: CartLine) => void;
}) {
  const { cart, add } = useCart();
  const [chosen, setChosen] = useState<Record<string, string[]>>({});
  const [quantity, setQuantity] = useState(1);
  const [notes, setNotes] = useState("");
  const [confirmReplace, setConfirmReplace] = useState(false);

  const itemGroups = item.option_group_ids.map((id) => groups[id]).filter((g): g is OptionGroup => Boolean(g));
  const extras = useMemo(() => itemGroups.reduce((sum, g) =>
    sum + (chosen[g.id] ?? []).reduce((s, cid) => s + (g.choices.find((c) => c.id === cid)?.price_delta_kobo ?? 0), 0), 0), [chosen, itemGroups]);
  const unit = item.price_kobo + extras;
  const error = validateSelections(item, groups, chosen);
  const otherRestaurant = !onAdd && cart.restaurant_id !== null && cart.restaurant_id !== restaurantId && cart.items.length > 0;

  function toggle(g: OptionGroup, choiceId: string) {
    setChosen((prev) => {
      const current = prev[g.id] ?? [];
      if (g.max_select === 1) return { ...prev, [g.id]: [choiceId] };
      if (current.includes(choiceId)) return { ...prev, [g.id]: current.filter((c) => c !== choiceId) };
      if (current.length >= g.max_select) return prev;
      return { ...prev, [g.id]: [...current, choiceId] };
    });
  }

  function addToCart() {
    if (error) return;
    if (otherRestaurant && !confirmReplace) {
      setConfirmReplace(true);
      return;
    }
    const selections: OptionSelection[] = itemGroups.filter((g) => (chosen[g.id] ?? []).length)
      .map((g) => ({ group_id: g.id, choice_ids: chosen[g.id]! }));
    const labels = itemGroups.flatMap((g) => (chosen[g.id] ?? []).map((cid) => `${g.name}: ${g.choices.find((c) => c.id === cid)?.name}`));
    if (onAdd) {
      onAdd({ item_id: item.id, quantity, selections, notes: notes.trim() || null });
      onClose();
      return;
    }
    add(restaurantId, restaurantName, {
      key: cartKey(item.id, selections, notes.trim() || undefined), item_id: item.id, name: item.name, unit_price_kobo: unit,
      quantity, selections, selection_labels: labels, notes: notes.trim() || undefined,
    });
    onClose();
  }

  return (
    <Dialog open onClose={onClose} title={item.name} footer={
      <div className="space-y-3">
      {confirmReplace && (
        // Next to the button (not at the end of a long options list) so it is seen before confirming.
        <p role="alert" className="rounded-md bg-accent-soft p-3 text-sm">
          Your cart has items from {cart.restaurant_name}. Adding this will start a new cart from {restaurantName}.
        </p>
      )}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1">
          <button className="grid size-9 place-items-center rounded-full border border-border" aria-label="Decrease quantity"
            onClick={() => setQuantity((q) => Math.max(1, q - 1))}><Minus className="size-4" /></button>
          <span className="w-8 text-center tabular-nums" aria-live="polite">{quantity}</span>
          <button className="grid size-9 place-items-center rounded-full border border-border" aria-label="Increase quantity"
            onClick={() => setQuantity((q) => Math.min(20, q + 1))}><Plus className="size-4" /></button>
        </div>
        <Button block size="lg" onClick={addToCart} disabled={Boolean(error)}>
          {confirmReplace ? "Start new cart" : "Add"} · {formatNaira(unit * quantity)}
        </Button>
      </div>
      </div>
    }>
      <div className="space-y-5">
        {(item.brand || item.unit_label) && (
          <p className="text-sm font-semibold">{[item.brand, item.unit_label].filter(Boolean).join(" · ")}</p>
        )}
        {item.description && <p className="text-sm text-muted">{item.description}</p>}
        {item.allergens.length > 0 && <p className="text-xs text-muted">Contains: {item.allergens.join(", ")}</p>}
        {itemGroups.map((g) => (
          <fieldset key={g.id} className="space-y-2">
            <legend className="flex w-full items-center justify-between text-sm font-semibold">
              {g.name}
              <span className="text-xs font-normal text-muted">
                {g.min_select > 0 ? "Required" : "Optional"}{g.max_select > 1 ? ` · up to ${g.max_select}` : ""}
              </span>
            </legend>
            {g.choices.map((c) => {
              const checked = (chosen[g.id] ?? []).includes(c.id);
              return (
                <label key={c.id} className={cn("flex cursor-pointer items-center justify-between rounded-md border px-3 py-2.5 text-sm",
                  checked ? "border-primary bg-primary-soft" : "border-border", !c.is_available && "cursor-not-allowed opacity-50")}>
                  <span className="flex items-center gap-2">
                    <input type={g.max_select === 1 ? "radio" : "checkbox"} name={g.id} checked={checked} disabled={!c.is_available}
                      onChange={() => toggle(g, c.id)} className="accent-[var(--gm-primary)]" />
                    {c.name}
                  </span>
                  {c.price_delta_kobo > 0 && <span className="text-muted">+{formatNaira(c.price_delta_kobo)}</span>}
                </label>
              );
            })}
          </fieldset>
        ))}
        <label className="block space-y-1.5 text-sm font-semibold">
          Notes for {notesFor} (optional)
          <Textarea value={notes} onChange={(e) => setNotes(e.target.value)} maxLength={200} placeholder={notesHint} />
        </label>
        {error && <p className="text-sm text-muted">{error}</p>}
      </div>
    </Dialog>
  );
}
