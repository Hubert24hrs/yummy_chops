import type { MenuItem, OptionGroup, RestaurantDetail } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const push = vi.fn();
const item = (id: string, name: string, over: Partial<MenuItem> = {}): MenuItem => ({
  id, restaurant_id: "r1", category_id: "c1", name, description: "", price_kobo: 150_000, image_url: null, kind: "main", tags: [],
  dietary: [], allergens: [], serves: 1, spice_level: 0, is_available: true, is_active: true, popularity: 10, option_group_ids: [],
  prep_minutes: 10, position: 0, ...over,
});
const size: OptionGroup = {
  id: "size", restaurant_id: "r1", name: "Size", min_select: 1, max_select: 1,
  choices: [{ id: "reg", name: "Regular", price_delta_kobo: 0, is_available: true }, { id: "big", name: "Big", price_delta_kobo: 50_000, is_available: true }],
};
const detail = (id: string, name: string, items: MenuItem[], groups: Record<string, OptionGroup> = {}): RestaurantDetail => ({
  restaurant: {
    id, vertical: "food", city: "lagos", promotions: [], name, slug: id, description: "", cuisines: [], tags: [], image_url: null,
    cover_url: null, area: "Lekki", rating: 4.5, rating_count: 10, price_level: 2, is_open: true, is_accepting_orders: true,
    is_featured: false, next_opening_at: null, distance_km: null, eta_minutes: null, delivery_fee_kobo: null, min_order_kobo: 0,
    supports_delivery: true, supports_pickup: true, delivers_to_location: null,
  },
  address: "", location: { lat: 6.44, lng: 3.47 }, opening_hours: {} as RestaurantDetail["opening_hours"], avg_prep_minutes: 15,
  sections: [{ category: { id: "c1", name: "Menu", position: 0 }, items }], option_groups: groups,
});
const menus: Record<string, RestaurantDetail> = {
  r1: detail("r1", "Ofada Hub", [
    item("ofada", "Ofada rice", { popularity: 100, image_url: "https://img.test/ofada.jpg" }),
    item("water", "Table water", { popularity: 90 }),
    item("chin", "Chin chin", { popularity: 50 }),
    item("jollof", "Jollof rice", { popularity: 80, option_group_ids: ["size"] }),
    item("gone", "Sold-out stew", { popularity: 999, is_available: false }),
  ], { size }),
  p1: detail("p1", "MedPlus", [item("para", "Paracetamol", { restaurant_id: "p1", popularity: 5 })]),
};
const restaurant = vi.fn(async (id: string) => menus[id]!);
vi.mock("@/lib/api", () => ({ publicApi: { catalog: { restaurant: (id: string) => restaurant(id) } } }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push, replace: vi.fn(), back: vi.fn() }), usePathname: () => "/cart" }));
vi.mock("next/link", () => ({
  default: ({ href, children, ...rest }: { href: string; children: React.ReactNode; "aria-label"?: string }) =>
    <a href={href} aria-label={rest["aria-label"]}>{children}</a>,
}));

const { default: CartPage } = await import("./page");
const { CartProvider } = await import("@/lib/cart");

const line = (restaurant_id: string, restaurant_name: string, item_id: string, name: string, quantity = 1) => ({
  key: `${restaurant_id}/${item_id}##`, restaurant_id, restaurant_name, item_id, name, unit_price_kobo: 150_000, quantity,
  selections: [], selection_labels: [],
});
const saveCart = (items: ReturnType<typeof line>[]) => window.localStorage.setItem("gudmeal.cart.v2", JSON.stringify({ items }));
const saved = () => JSON.parse(window.localStorage.getItem("gudmeal.cart.v2")!).items as ReturnType<typeof line>[];

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><CartProvider><CartPage /></CartProvider></QueryClientProvider>);
}

beforeAll(() => {
  // jsdom has no modal dialogs
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
beforeEach(() => {
  saveCart([
    line("r1", "Ofada Hub", "ofada", "Ofada rice"),
    line("p1", "MedPlus", "para", "Paracetamol"),
    line("r1", "Ofada Hub", "water", "Table water", 2),
  ]);
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  window.localStorage.clear();
});

describe("cart page", () => {
  it("groups the items by shop, with a stepper on each line and a way back to each shop", async () => {
    show();
    expect(await screen.findByText(/4 products from/)).toBeTruthy();
    expect(screen.getByText("2 shops")).toBeTruthy();
    const ofada = screen.getByRole("region", { name: "Ofada Hub" });
    const medplus = screen.getByRole("region", { name: "MedPlus" });
    expect(within(ofada).getByText("Ofada rice")).toBeTruthy();
    expect(within(ofada).getByText("Table water")).toBeTruthy();
    expect(within(medplus).getByText("Paracetamol")).toBeTruthy();
    expect(within(ofada).getByRole("link", { name: /Add more items/ }).getAttribute("href")).toBe("/restaurants/r1");
    // The item's photo, from the shop's menu.
    await waitFor(() => expect(ofada.querySelector("img")?.getAttribute("src")).toBe("https://img.test/ofada.jpg"));

    // One of a kind: a bin takes the line out; more than one: − takes one away.
    expect(within(ofada).queryByRole("button", { name: "Remove one Ofada rice" })).toBeNull();
    fireEvent.click(within(ofada).getByRole("button", { name: "Add one Ofada rice" }));
    expect(saved().find((i) => i.item_id === "ofada")!.quantity).toBe(2);
    fireEvent.click(within(ofada).getByRole("button", { name: "Remove one Table water" }));
    expect(saved().find((i) => i.item_id === "water")!.quantity).toBe(1);
    fireEvent.click(within(medplus).getByRole("button", { name: "Remove Paracetamol from cart" }));
    expect(screen.queryByRole("region", { name: "MedPlus" })).toBeNull();
    expect(screen.getByText(/3 products from/)).toBeTruthy();
    expect(screen.getAllByText("Ofada Hub").length).toBeGreaterThan(0);

    // The bar at the bottom: the items' total and the way to checkout.
    expect(screen.getByText("₦4,500")).toBeTruthy();
    expect(screen.getByRole("link", { name: /Go to checkout/ }).getAttribute("href")).toBe("/checkout");
  });

  it("empties the cart only after the customer confirms", async () => {
    show();
    await screen.findByText(/4 products from/);
    fireEvent.click(screen.getByRole("button", { name: "Empty cart" }));
    const sheet = screen.getByRole("dialog", { name: "Empty your cart?" });
    fireEvent.click(within(sheet).getByRole("button", { name: "Keep my items" }));
    expect(saved()).toHaveLength(3);

    fireEvent.click(screen.getByRole("button", { name: "Empty cart" }));
    fireEvent.click(within(screen.getByRole("dialog", { name: "Empty your cart?" })).getByRole("button", { name: "Empty cart" }));
    expect(screen.getByText("Your cart is empty")).toBeTruthy();
    expect(saved()).toEqual([]);
  });

  it("suggests popular products of the cart's shops: + adds one, or asks for the choice first", async () => {
    show();
    const liked = await screen.findByRole("region", { name: "You might also like" });
    // Most popular first; nothing already in the cart, nothing sold out.
    const names = within(liked).getAllByRole("listitem").map((li) => li.querySelector("p")!.textContent);
    expect(names).toEqual(["Jollof rice", "Chin chin"]);

    fireEvent.click(within(liked).getByRole("button", { name: "Add Chin chin" }));
    expect(saved().at(-1)).toMatchObject({ restaurant_id: "r1", restaurant_name: "Ofada Hub", item_id: "chin", quantity: 1 });
    expect(within(screen.getByRole("region", { name: "Ofada Hub" })).getByText("Chin chin")).toBeTruthy();
    await waitFor(() => expect(within(liked).queryByRole("button", { name: "Add Chin chin" })).toBeNull());

    // Jollof needs a size: the item sheet opens, and the customer stays on the cart.
    fireEvent.click(within(liked).getByRole("button", { name: "Add Jollof rice" }));
    const dialog = document.querySelector("dialog")!;
    expect(dialog.querySelector("h2")?.textContent).toBe("Jollof rice");
    fireEvent.click(within(dialog).getByLabelText(/Big/));
    fireEvent.click(within(dialog).getByRole("button", { name: "Add to cart · ₦2,000" }));
    expect(saved().at(-1)).toMatchObject({ item_id: "jollof", selection_labels: ["Size: Big"], unit_price_kobo: 200_000 });
    expect(push).not.toHaveBeenCalled();
  });
});
