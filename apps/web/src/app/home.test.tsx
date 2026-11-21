import type { RestaurantCard } from "@gudmeal/api-client";
import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn(), replace: vi.fn() }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));

const card = (over: Partial<RestaurantCard>): RestaurantCard => ({
  id: "r1", vertical: "food", city: "lagos", promotions: [], name: "Jollof Junction", slug: "jj", description: "",
  cuisines: ["Nigerian"], tags: [], image_url: null, cover_url: null, area: "Lekki", rating: 4.7, rating_count: 100,
  price_level: 2, is_open: true, is_accepting_orders: true, is_featured: false, next_opening_at: null, distance_km: 2,
  eta_minutes: 30, delivery_fee_kobo: 90_000, min_order_kobo: 0, supports_delivery: true, supports_pickup: true,
  delivers_to_location: true, ...over,
});

vi.mock("@/lib/server-api", () => ({
  safe: async <T,>(p: Promise<T>) => ({ data: await p, error: null }),
  serverApi: {
    catalog: {
      restaurants: async ({ vertical }: { vertical: string }) =>
        ({
          food: [card({ id: "r-jj", promotions: [{ code: "JOLLOF20", label: "20% off at Jollof Junction" }] })],
          beauty: [card({ id: "b-ivie", vertical: "beauty", name: "Ivie & Oak Beauty", delivery_fee_kobo: 170_000 })],
          pharmacy: [card({ id: "p-1", vertical: "pharmacy", name: "Lekki Health Pharmacy" })],
          grocery: [card({ id: "g-1", vertical: "grocery", name: "Admiralty Fresh Mart" })],
          market: [card({ id: "m-1", vertical: "market", name: "Lekki Market Shopper" })],
        })[vertical] ?? [],
    },
  },
}));

const { default: HomePage } = await import("./page");
const { LocationProvider } = await import("@/lib/location");

describe("website home", () => {
  afterEach(cleanup);

  it("is minimal like the app: the area, the six services and the picks, nothing else", async () => {
    render(<LocationProvider>{await HomePage()}</LocationProvider>);
    for (const [name, href] of [["Order Food", "/food"], ["Pharmacy", "/pharmacy"], ["Beauty & Skin Care", "/beauty"],
      ["Shop & Groceries", "/groceries"], ["Buy Foodstuff", "/foodstuff"], ["Package Delivery", "/send"]]) {
      expect(screen.getByRole("link", { name }).getAttribute("href")).toBe(href);
    }
    expect(screen.getByText("These are for you")).toBeTruthy();
    // One shop of each kind among the picks, so people find the newer services from the home page too.
    for (const shop of ["Ivie & Oak Beauty", "Lekki Health Pharmacy", "Admiralty Fresh Mart", "Lekki Market Shopper"]) {
      expect(screen.getByText(shop), shop).toBeTruthy();
    }
    expect(screen.getByText("Promo")).toBeTruthy(); // the deal is a tag on the shop's tile
    for (const gone of ["Ask Yummy", "Send a package", "Yummy plans to your budget", "Transparent, safe payments",
      "Live tracking to your door", "Sell on Yummy Chops. Ride with Yummy Chops.", "Supplements & Skin Care", "Market Shopping"]) {
      expect(screen.queryByText(gone), gone).toBeNull();
    }
  });
});
