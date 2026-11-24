import type { Application, Business, Restaurant } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, render, screen, within } from "@testing-library/react";
import type { ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";

const branch = (over: Partial<Restaurant>): Restaurant => ({
  id: "r-main", vertical: "food", name: "Ofada Hub", slug: "ofada-hub", description: "", cuisines: [], area: "Ikeja", address: "1 Allen Avenue",
  location: { lat: 6.6018, lng: 3.3515 }, rating: 0, rating_count: 0, avg_prep_minutes: 20, opening_hours: {} as Restaurant["opening_hours"],
  is_accepting_orders: true, status: "active", min_order_kobo: 0, supports_delivery: true, supports_pickup: true, image_url: null,
  cover_url: null, owner_uid: "owner-1", commission_bps: null, phone: null, business_id: "YCB-7KQ2MX", branch_name: "Ikeja", ...over,
});
const BUSINESS: Business = {
  id: "YCB-7KQ2MX", name: "Ofada Hub", owner_uid: "owner-1", vertical: "food", phone: "+2348022222222", email: "hello@ofadahub.ng",
  main_restaurant_id: "r-main", settlement_bank_code: "058", settlement_bank_name: "Guaranty Trust Bank", settlement_account_name: "OFADA HUB LTD",
  settlement_account_last4: "6789", created_at: "2026-11-24T10:00:00Z", bank_connected: true,
  branches: [
    { restaurant_id: "r-main", branch_name: "Ikeja", address: "1 Allen Avenue", area: "Ikeja", location: { lat: 6.6018, lng: 3.3515 },
      manager_phone: null, main: true, status: "active", is_accepting_orders: true },
    { restaurant_id: "r-lekki", branch_name: "Lekki", address: "5 Admiralty Way", area: "Lekki Phase 1", location: { lat: 6.4478, lng: 3.4723 },
      manager_phone: "+2348033333333", main: false, status: "pending", is_accepting_orders: false },
  ],
};
const APPLICATION: Application = {
  id: "app-1", type: "restaurant", applicant_uid: "cust-2", status: "submitted", submitted_at: "2026-11-24T09:00:00Z",
  decided_at: null, decision_reason: null, created_entity_id: null, document_paths: [],
  data: {
    business_name: "Ofada Hub", vertical: "food", email: "hello@ofadahub.ng", address: "1 Allen Avenue", area: "Ikeja",
    location: { lat: 6.6018, lng: 3.3515 },
    branches: [
      { address: "5 Admiralty Way", area: "Lekki Phase 1", location: { lat: 6.4478, lng: 3.4723 } },
      { address: "12 Ogui Road", area: "Enugu", location: { lat: 6.4402, lng: 7.4943 }, manager_phone: "+2348033333333" },
    ],
  },
};

const api = {
  admin: {
    restaurants: vi.fn(async () => [branch({}), branch({ id: "r-lekki", area: "Lekki Phase 1", branch_name: "Lekki", status: "pending" }), branch({ id: "r-solo", name: "Suya Lane", business_id: null, branch_name: null })]),
    businesses: vi.fn(async () => [BUSINESS]),
    applications: vi.fn(async () => [APPLICATION]),
  },
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));

const { default: RestaurantsPage } = await import("./page");
const { default: ApplicationsPage } = await import("../applications/page");

function show(page: ReactNode) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}>{page}</QueryClientProvider>);
}

afterEach(cleanup);

describe("businesses in the Command Centre (ADR-0028)", () => {
  it("shows each shop's business and branch, and every business with its branches and bank", async () => {
    show(<RestaurantsPage />);
    const lekki = (await screen.findAllByText("Lekki branch"))[0]!.closest("tr")!;
    expect(within(lekki).getByText("YCB-7KQ2MX")).toBeTruthy();
    const businesses = screen.getByRole("heading", { name: "Businesses" }).nextElementSibling as HTMLElement;
    const row = within(businesses).getByText("Ofada Hub").closest("tr")!;
    expect(within(row).getByText("1 taking orders")).toBeTruthy();
    expect(within(row).getByText("Bank connected")).toBeTruthy();
    expect(within(row).getByText("Guaranty Trust Bank · ending 6789")).toBeTruthy();
  });

  it("lists the branch addresses a business signed up with", async () => {
    show(<ApplicationsPage />);
    const branches = await screen.findByText(/5 Admiralty Way, Lekki Phase 1/);
    expect(branches.textContent).toBe("5 Admiralty Way, Lekki Phase 1\n12 Ogui Road, Enugu, +2348033333333");
    expect(screen.queryByText(/object Object/)).toBeNull();
  });
});
