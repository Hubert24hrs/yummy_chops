import type { MenuItem, OptionGroup } from "@gudmeal/api-client";
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { validateSelections } from "@/components/item-dialog";
import { CartProvider, cartKey, cartReducer, cartShops, migrateCart, subtotal, toCartLines, useCart, type CartState } from "./cart";

const EMPTY: CartState = { items: [] };
const sel = [{ group_id: "p", choice_ids: ["chicken"] }];
const jollof = (qty = 1) => ({
  key: cartKey("r1", "jj", sel), item_id: "jj", name: "Jollof", unit_price_kobo: 550_000,
  quantity: qty, selections: sel, selection_labels: ["Protein: Chicken"],
});
const paracetamol = (qty = 1) => ({
  key: cartKey("p1", "para", []), item_id: "para", name: "Paracetamol", unit_price_kobo: 80_000,
  quantity: qty, selections: [], selection_labels: [],
});

describe("cart reducer", () => {
  it("merges identical lines and sums the subtotal", () => {
    let s = cartReducer(EMPTY, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof(1) });
    s = cartReducer(s, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof(2) });
    expect(s.items).toHaveLength(1);
    expect(s.items[0]!.quantity).toBe(3);
    expect(s.items[0]!.restaurant_id).toBe("r1");
    expect(subtotal(s.items)).toBe(1_650_000);
    expect(toCartLines(s.items)).toEqual([{ item_id: "jj", quantity: 3, selections: sel, notes: null }]);
  });

  it("keeps items from several shops in one cart, grouped by shop in the order they were first added", () => {
    let s = cartReducer(EMPTY, { type: "add", restaurant_id: "r1", restaurant_name: "Jollof Hub", item: jollof() });
    s = cartReducer(s, { type: "add", restaurant_id: "p1", restaurant_name: "MedPlus", item: paracetamol(2) });
    s = cartReducer(s, { type: "add", restaurant_id: "r1", restaurant_name: "Jollof Hub", item: { ...jollof(), key: cartKey("r1", "plantain", []), item_id: "plantain", name: "Plantain" } });
    expect(s.items).toHaveLength(3);
    const shops = cartShops(s);
    expect(shops.map((sh) => sh.restaurant_name)).toEqual(["Jollof Hub", "MedPlus"]);
    expect(shops[0]!.items.map((i) => i.name)).toEqual(["Jollof", "Plantain"]);
    expect(shops[1]).toMatchObject({ restaurant_id: "p1", count: 2, subtotal_kobo: 160_000 });
  });

  it("the same product from two shops is two lines", () => {
    expect(cartKey("r1", "water", [])).not.toBe(cartKey("r2", "water", []));
  });

  it("removes a line, and lines at zero", () => {
    let s = cartReducer(EMPTY, { type: "add", restaurant_id: "r1", restaurant_name: "R1", item: jollof() });
    s = cartReducer(s, { type: "add", restaurant_id: "p1", restaurant_name: "P1", item: paracetamol() });
    s = cartReducer(s, { type: "remove", key: jollof().key });
    expect(cartShops(s).map((sh) => sh.restaurant_id)).toEqual(["p1"]);
    s = cartReducer(s, { type: "quantity", key: paracetamol().key, quantity: 0 });
    expect(s).toEqual(EMPTY);
  });

  it("selection order does not change the line key", () => {
    expect(cartKey("r", "x", [{ group_id: "a", choice_ids: ["2", "1"] }])).toBe(cartKey("r", "x", [{ group_id: "a", choice_ids: ["1", "2"] }]));
  });

  it("turns a saved one-shop cart (v1) into items of that shop", () => {
    const v1 = { restaurant_id: "r1", restaurant_name: "R1", items: [{ ...jollof(2), key: "jj#p:chicken#" }] };
    const migrated = migrateCart(v1);
    expect(migrated.items).toEqual([{ ...jollof(2), restaurant_id: "r1", restaurant_name: "R1" }]);
    expect(migrateCart(null)).toEqual(EMPTY);
    expect(migrateCart({ items: [{ nonsense: true }] })).toEqual(EMPTY);
  });
});

describe("option validation mirrors the API", () => {
  const group: OptionGroup = { id: "p", restaurant_id: "r1", name: "Protein", min_select: 1, max_select: 1,
    choices: [{ id: "chicken", name: "Chicken", price_delta_kobo: 0, is_available: true }] };
  const item = { option_group_ids: ["p"] } as MenuItem;
  it("requires mandatory choices", () => {
    expect(validateSelections(item, { p: group }, {})).toMatch(/Choose 1/);
    expect(validateSelections(item, { p: group }, { p: ["chicken"] })).toBeNull();
  });
});

function Harness() {
  const { count, add } = useCart();
  return <button onClick={() => add("r1", "R1", jollof())}>items: {count}</button>;
}

describe("CartProvider", () => {
  it("keeps a saved cart across reloads (StrictMode double effects)", async () => {
    const { StrictMode } = await import("react");
    window.localStorage.setItem("gudmeal.cart.v2", JSON.stringify({ items: [{ ...jollof(2), restaurant_id: "r1", restaurant_name: "R1" }] }));
    const { unmount } = render(<StrictMode><CartProvider><Harness /></CartProvider></StrictMode>);
    expect(await screen.findByText("items: 2")).toBeTruthy();
    expect(JSON.parse(window.localStorage.getItem("gudmeal.cart.v2")!).items).toHaveLength(1);
    unmount();
    window.localStorage.clear();
  });

  it("moves a cart saved by the one-shop website to the new storage, so nothing is lost", async () => {
    window.localStorage.setItem("gudmeal.cart.v1", JSON.stringify({ restaurant_id: "r1", restaurant_name: "R1", items: [{ ...jollof(2), key: "old" }] }));
    const { unmount } = render(<CartProvider><Harness /></CartProvider>);
    expect(await screen.findByText("items: 2")).toBeTruthy();
    expect(window.localStorage.getItem("gudmeal.cart.v1")).toBeNull();
    expect(JSON.parse(window.localStorage.getItem("gudmeal.cart.v2")!).items[0]).toMatchObject({ restaurant_id: "r1", restaurant_name: "R1", key: jollof().key });
    // Adding the same dish again joins the migrated line.
    fireEvent.click(screen.getByRole("button"));
    expect(screen.getByRole("button").textContent).toBe("items: 3");
    unmount();
    window.localStorage.clear();
  });

  it("persists to localStorage", () => {
    render(<CartProvider><Harness /></CartProvider>);
    fireEvent.click(screen.getByRole("button"));
    expect(screen.getByRole("button").textContent).toBe("items: 1");
    expect(JSON.parse(window.localStorage.getItem("gudmeal.cart.v2")!).items).toHaveLength(1);
  });
});
