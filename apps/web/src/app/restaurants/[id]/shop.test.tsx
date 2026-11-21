import type { MenuItem, OptionGroup, RestaurantDetail } from "@gudmeal/api-client";
import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { CartProvider, useCart } from "@/lib/cart";
import { listPrice, SERVICE_NAMES, SERVICES, serviceCopy } from "@/lib/services";
import { popularProducts, searchProducts, Shop } from "./shop";

/** Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, ADR-0025): shops browsed by the aisle. */
const product = (id: string, name: string, naira: number, over: Partial<MenuItem> = {}): MenuItem => ({
  id, restaurant_id: "m-lekki", category_id: "c", name, description: "", price_kobo: naira * 100, image_url: null, kind: "product",
  tags: [], dietary: [], allergens: [], serves: 1, spice_level: 0, is_available: true, is_active: true, popularity: 0,
  option_group_ids: [], prep_minutes: null, position: 0, emoji: "🧺", ...over,
});

const weight: OptionGroup = {
  id: "weight", restaurant_id: "m-lekki", name: "How much?", min_select: 1, max_select: 1,
  choices: [
    { id: "500g", name: "500 g", price_delta_kobo: 0, is_available: true },
    { id: "1kg", name: "1 kg", price_delta_kobo: 380_000, is_available: true },
  ],
};

const grains = ["Ijebu garri", "Yam flour (elubo)", "Local rice", "Honey beans", "Brown beans", "White garri", "Ofada rice", "Guinea corn"]
  .map((name, i) => product(`g${i}`, name, 600 + i * 100, { unit_label: "derica", popularity: 200 - i }));

const market = (over: Partial<RestaurantDetail["restaurant"]> = {}): RestaurantDetail => ({
  restaurant: {
    id: "m-lekki", vertical: "market", city: "lagos", promotions: [], name: "Lekki Market Shopper", slug: "lekki-market",
    description: "A shopper buys your foodstuff fresh at the market.", cuisines: ["Foodstuff"], tags: [], image_url: null, cover_url: null,
    area: "Lekki", rating: 4.5, rating_count: 760, price_level: 1, is_open: true, is_accepting_orders: true, is_featured: false,
    next_opening_at: null, distance_km: null, eta_minutes: null, delivery_fee_kobo: null, min_order_kobo: 0, supports_delivery: true,
    supports_pickup: false, delivers_to_location: null, badge: "Shopper", ...over,
  },
  address: "Market road, Lekki Phase 1", location: { lat: 6.44, lng: 3.47 }, opening_hours: {} as RestaurantDetail["opening_hours"],
  avg_prep_minutes: 35,
  sections: [
    { category: { id: "combos", name: "Soup & stew combos", position: 0 }, items: [product("c1", "Egusi soup combo", 7500, { kind: "combo", popularity: 310 })] },
    { category: { id: "grains", name: "Rice, grains & garri", position: 1 }, items: grains },
    {
      category: { id: "meat", name: "Meat (raw)", position: 2 },
      items: [
        product("m2", "Goat meat", 9500, { unit_label: "1 kg", is_available: false, popularity: 500 }),
        product("m1", "Beef (raw)", 4200, { unit_label: "from 500 g", popularity: 295, option_group_ids: ["weight"], brand: "Fresh cut" }),
      ],
    },
    { category: { id: "empty", name: "Nothing here", position: 3 }, items: [] },
  ],
  option_groups: { weight },
});

function CartCount() {
  const { count, cart } = useCart();
  return <output aria-label="cart">{count} from {cart.restaurant_name ?? "nowhere"}</output>;
}

const renderShop = (d: RestaurantDetail = market(), openItemId?: string) =>
  render(<CartProvider><Shop detail={d} openItemId={openItemId} /><CartCount /></CartProvider>);

beforeAll(() => {
  // jsdom has no modal dialogs
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
afterEach(() => {
  cleanup();
  window.localStorage.clear();
});

describe("service wording", () => {
  it("names the five kinds of shop in the order the home screen shows them (the owner's order, ADR-0025)", () => {
    expect(SERVICES.map((s) => s.id)).toEqual(["food", "pharmacy", "beauty", "grocery", "market"]);
    expect(SERVICES.map((s) => s.title)).toEqual(["Order Food", "Pharmacy", "Beauty & Skin Care", "Shop & Groceries", "Buy Foodstuff"]);
    expect(SERVICES.map((s) => s.href)).toEqual(["/food", "/pharmacy", "/beauty", "/groceries", "/foodstuff"]);
    expect(SERVICES.filter((s) => s.retail).map((s) => s.id)).toEqual(["pharmacy", "grocery", "market"]);
    expect(serviceCopy("pharmacy").note).toContain("Over-the-counter products only");
    expect(serviceCopy("market").readyIn).toBe("bought in");
    expect(serviceCopy("something-new").id).toBe("food"); // an unknown service still shows something sensible
    expect(SERVICE_NAMES).toMatchObject({ food: "Order Food", beauty: "Beauty & Skin Care", grocery: "Shop & Groceries", pharmacy: "Pharmacy", market: "Buy Foodstuff", parcel: "Package Delivery" });
  });

  it('shows "From" only when a choice the customer must make changes the price', () => {
    const groups: Record<string, OptionGroup> = {
      weight,
      pack: { ...weight, id: "pack", choices: [{ ...weight.choices[0]!, price_delta_kobo: 50_000 }, { ...weight.choices[1]!, price_delta_kobo: 300_000 }] },
      extra: { ...weight, id: "extra", min_select: 0 },
      same: { ...weight, id: "same", choices: weight.choices.map((c) => ({ ...c, price_delta_kobo: 0 })) },
    };
    expect(listPrice({ price_kobo: 420_000, option_group_ids: ["weight"] }, groups)).toEqual({ kobo: 420_000, from: true });
    // Eggs: even the cheapest pack costs something on top of the base price.
    expect(listPrice({ price_kobo: 100_000, option_group_ids: ["pack"] }, groups)).toEqual({ kobo: 150_000, from: true });
    // An optional extra, or a required choice that costs the same either way, leaves the price as it is.
    expect(listPrice({ price_kobo: 50_000, option_group_ids: ["extra"] }, groups)).toEqual({ kobo: 50_000, from: false });
    expect(listPrice({ price_kobo: 50_000, option_group_ids: ["same"] }, groups)).toEqual({ kobo: 50_000, from: false });
    expect(listPrice({ price_kobo: 270_000, option_group_ids: ["gone"] }, groups)).toEqual({ kobo: 270_000, from: false });
  });
});

describe("a shop browsed by the aisle", () => {
  it("finds popular products that are in stock, and searches by name, brand or size", () => {
    const sections = market().sections;
    expect(popularProducts(sections, 3).map((i) => i.name)).toEqual(["Egusi soup combo", "Beef (raw)", "Ijebu garri"]); // not the sold-out goat
    expect(searchProducts(sections, "  ").length).toBe(0);
    expect(searchProducts(sections, "RICE").map((i) => i.name)).toEqual(["Local rice", "Ofada rice"]);
    expect(searchProducts(sections, "fresh cut").map((i) => i.name)).toEqual(["Beef (raw)"]);
    expect(searchProducts(sections, "1 kg").map((i) => i.name)).toEqual(["Goat meat"]);
  });

  it("shows the note, what's popular, the aisles, measures, From prices and stock", () => {
    renderShop();
    expect(screen.getByRole("note").textContent).toContain("A shopper buys these fresh for you");
    const popular = screen.getByRole("region", { name: "Popular" });
    expect(within(popular).getByText("Egusi soup combo")).toBeTruthy();
    expect(within(popular).queryByText("Goat meat")).toBeNull();

    // Aisles with something on the shelf, each with its number of products.
    const aisles = within(screen.getByRole("navigation", { name: "Aisles" })).getAllByRole("link");
    expect(aisles.map((a) => a.textContent)).toEqual(["Soup & stew combos 1", "Rice, grains & garri 8", "Meat (raw) 2"]);
    expect(aisles[1]!.getAttribute("href")).toBe("#aisle-grains");

    const meat = screen.getByRole("region", { name: "Meat (raw)" });
    expect(within(meat).getByText("From ₦4,200")).toBeTruthy(); // beef, by weight
    expect(within(meat).getByText("Fresh cut · from 500 g")).toBeTruthy();
    expect(within(meat).getByText("Out of stock")).toBeTruthy();
    // What is in stock comes first; the sold-out product stays listed but cannot be opened or added.
    expect(Array.from(meat.querySelectorAll("span.line-clamp-2")).map((e) => e.textContent)).toEqual(["Beef (raw)", "Goat meat"]);
    expect((within(meat).getByText("Goat meat").closest("button") as HTMLButtonElement).disabled).toBe(true);
    expect(within(meat).queryByRole("button", { name: "Add Goat meat" })).toBeNull();
  });

  it('shows a few products per aisle and the rest behind "View more"', () => {
    renderShop();
    const grainsAisle = screen.getByRole("region", { name: "Rice, grains & garri" });
    expect(within(grainsAisle).getAllByText("derica")).toHaveLength(6);
    expect(within(grainsAisle).queryByText("Guinea corn")).toBeNull();
    const more = within(grainsAisle).getByRole("button", { name: "View more (8)" });
    expect(more.getAttribute("aria-expanded")).toBe("false");
    fireEvent.click(more);
    expect(within(grainsAisle).getAllByText("derica")).toHaveLength(8);
    expect(within(grainsAisle).getByText("Guinea corn")).toBeTruthy();
    fireEvent.click(within(grainsAisle).getByRole("button", { name: "Show less" }));
    expect(within(grainsAisle).getAllByText("derica")).toHaveLength(6);
    // A short aisle needs no button.
    expect(within(screen.getByRole("region", { name: "Meat (raw)" })).queryByRole("button", { name: /View more/ })).toBeNull();
  });

  it("searches inside the shop", () => {
    renderShop();
    fireEvent.change(screen.getByRole("searchbox", { name: "Search in Lekki Market Shopper" }), { target: { value: "beef" } });
    expect(screen.getByText("1 found")).toBeTruthy();
    expect(screen.queryByRole("region", { name: "Popular" })).toBeNull();
    expect(screen.getByText("Beef (raw)")).toBeTruthy();

    fireEvent.change(screen.getByRole("searchbox"), { target: { value: "caviar" } });
    expect(screen.getByText("Nothing matches “caviar”")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Clear search" }));
    expect(screen.getByRole("region", { name: "Popular" })).toBeTruthy();
  });

  it("adds a simple product with one tap, and asks for the choice when there is one", () => {
    renderShop();
    const grainsAisle = screen.getByRole("region", { name: "Rice, grains & garri" });
    fireEvent.click(within(grainsAisle).getByRole("button", { name: "Add Local rice" }));
    fireEvent.click(within(grainsAisle).getByRole("button", { name: "Add another Local rice (1 in your order)" }));
    expect(screen.getByLabelText("cart").textContent).toBe("2 from Lekki Market Shopper");
    expect(document.querySelector("dialog")).toBeNull();

    // Beef is sold by weight: the weight must be picked, and the note goes to the shopper.
    fireEvent.click(within(screen.getByRole("region", { name: "Meat (raw)" })).getByRole("button", { name: "Add Beef (raw)" }));
    const dialog = document.querySelector("dialog")!;
    expect(dialog.querySelector("h2")?.textContent).toBe("Beef (raw)");
    expect(within(dialog).getByText("How much?")).toBeTruthy();
    expect(within(dialog).getByText("+₦3,800")).toBeTruthy();
    expect(within(dialog).getByText(/Notes for your shopper/)).toBeTruthy();
    expect((within(dialog).getByRole("button", { name: /Add · / }) as HTMLButtonElement).disabled).toBe(true);
    fireEvent.click(within(dialog).getByLabelText(/1 kg/));
    fireEvent.click(within(dialog).getByRole("button", { name: "Add · ₦8,000" }));
    expect(screen.getByLabelText("cart").textContent).toBe("3 from Lekki Market Shopper");
  });

  it("asks before replacing an order from another shop", () => {
    window.localStorage.setItem("gudmeal.cart.v1", JSON.stringify({
      restaurant_id: "r-jollof", restaurant_name: "Jollof Junction",
      items: [{ key: "jj#", item_id: "jj", name: "Jollof", unit_price_kobo: 350_000, quantity: 1, selections: [], selection_labels: [] }],
    }));
    renderShop();
    expect(screen.getByLabelText("cart").textContent).toBe("1 from Jollof Junction");
    fireEvent.click(within(screen.getByRole("region", { name: "Rice, grains & garri" })).getByRole("button", { name: "Add Local rice" }));
    const dialog = document.querySelector("dialog")!;
    fireEvent.click(within(dialog).getByRole("button", { name: /Add · / }));
    expect(within(dialog).getByRole("alert").textContent).toContain("Your cart has items from Jollof Junction");
    expect(screen.getByLabelText("cart").textContent).toBe("1 from Jollof Junction");
    fireEvent.click(within(dialog).getByRole("button", { name: /Start new cart/ }));
    expect(screen.getByLabelText("cart").textContent).toBe("1 from Lekki Market Shopper");
  });

  it("lets people look but not buy while the shop is closed, and opens a linked product when it can be bought", () => {
    renderShop(market({ is_open: false }), "c1");
    expect(document.querySelector("dialog")).toBeNull();
    expect(screen.queryByRole("button", { name: "Add Local rice" })).toBeNull();
    expect((screen.getAllByText("Local rice")[0]!.closest("button") as HTMLButtonElement).disabled).toBe(true);
    cleanup();

    renderShop(market(), "c1");
    expect(document.querySelector("dialog")?.querySelector("h2")?.textContent).toBe("Egusi soup combo");
    cleanup();
    renderShop(market(), "m2"); // sold out
    expect(document.querySelector("dialog")).toBeNull();
  });
});
