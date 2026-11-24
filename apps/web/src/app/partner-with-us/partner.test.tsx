import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const restaurant = vi.fn(async (_body: Record<string, unknown>) => ({ id: "app-1" }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: { uid: "cust-1", email: "tobi@allenpharmacy.ng", displayName: "Tobi Ade" }, loading: false }) }));
vi.mock("@/lib/api", () => ({ useApi: () => ({ applications: { restaurant } }) }));
vi.mock("next/navigation", () => ({ usePathname: () => "/partner-with-us" }));

const { default: PartnerPage } = await import("./page");

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><PartnerPage /></QueryClientProvider>);
}

function fill(values: Record<string, string>) {
  for (const [label, value] of Object.entries(values)) {
    fireEvent.change(screen.getByLabelText(label), { target: { value } });
  }
}

const BUSINESS = {
  "Business name": "Allen Avenue Pharmacy", "CAC number": "RC654321", "Phone number": "08033333333",
  "Address (main branch)": "12 Allen Avenue",
};

afterEach(() => {
  cleanup();
  restaurant.mockClear();
});

describe("Register your business (ADR-0025, ADR-0028)", () => {
  it("lets every kind of shop apply, and a pharmacy must give its PCN premises licence", async () => {
    show();
    expect(screen.getByRole("heading", { name: "Register your business" })).toBeTruthy();
    expect(screen.queryByLabelText(/Account/)).toBeNull(); // bank details come later, in the dashboard
    const kind = screen.getByLabelText("Kind of business") as HTMLSelectElement;
    expect([...kind.options].map((o) => o.textContent)).toEqual([
      "Restaurant (Order Food)", "Pharmacy", "Beauty & Skin Care shop", "Supermarket or store (Shop & Groceries)", "Market shopper (Buy Foodstuff)",
    ]);
    expect(screen.getByLabelText("Cuisines")).toBeTruthy(); // a restaurant lists its cuisines
    expect(screen.queryByLabelText("PCN premises licence number")).toBeNull();

    fireEvent.change(kind, { target: { value: "pharmacy" } });
    fill({ ...BUSINESS, "What you sell": "Pain relief, Vitamins" });
    fireEvent.click(screen.getByRole("button", { name: "Submit application" }));
    expect(await screen.findByText("Enter your PCN premises licence number")).toBeTruthy();
    expect(restaurant).not.toHaveBeenCalled();

    fill({ "PCN premises licence number": "PCN/PR/12345" });
    fireEvent.click(screen.getByRole("button", { name: "Submit application" }));
    await waitFor(() => expect(restaurant).toHaveBeenCalledTimes(1));
    expect(restaurant.mock.calls[0]![0]).toMatchObject({
      vertical: "pharmacy", pcn_licence_number: "PCN/PR/12345", business_name: "Allen Avenue Pharmacy", cuisines: ["Pain relief", "Vitamins"],
      email: "tobi@allenpharmacy.ng", contact_name: "Tobi Ade", branches: [],
    });
    expect(await screen.findByText("Application received")).toBeTruthy();
  });

  it("adds as many branch addresses as the business has", async () => {
    show();
    fill({ ...BUSINESS, Cuisines: "Nigerian" });
    fireEvent.click(screen.getByRole("button", { name: "Add another branch" }));
    fireEvent.click(screen.getByRole("button", { name: "Add another branch" }));
    fill({ "Branch 2 address": "5 Admiralty Way", "Branch 3 address": "x" });
    fireEvent.change(screen.getByLabelText("Branch 2 area"), { target: { value: "Victoria Island" } });
    fireEvent.click(screen.getByRole("button", { name: "Submit application" }));
    expect(await screen.findByText("Enter the branch's street address")).toBeTruthy(); // branch 3 is too short
    fireEvent.click(screen.getByRole("button", { name: "Remove branch 3" }));
    fireEvent.click(screen.getByRole("button", { name: "Submit application" }));
    await waitFor(() => expect(restaurant).toHaveBeenCalledTimes(1));
    expect(restaurant.mock.calls[0]![0].branches).toEqual([
      { address: "5 Admiralty Way", area: "Victoria Island", location: { lat: 6.4281, lng: 3.4219 } },
    ]);
  });
});
