import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const restaurant = vi.fn(async (_body: Record<string, unknown>) => ({ id: "app-1" }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: { uid: "cust-1" }, loading: false }) }));
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
  "Business name": "Allen Avenue Pharmacy", "CAC number": "RC654321", "Contact name": "Tobi Ade", "Contact phone": "08033333333",
  "Street address": "12 Allen Avenue", Bank: "GTBank", "Account name": "Allen Avenue Pharmacy Ltd", "Account number (last 4)": "4321",
};

afterEach(() => {
  cleanup();
  restaurant.mockClear();
});

describe("Add your business (ADR-0025)", () => {
  it("lets every kind of shop apply, and a pharmacy must give its PCN premises licence", async () => {
    show();
    expect(screen.getByRole("heading", { name: "Grow your business with Yummy Chops" })).toBeTruthy();
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
    });
    expect(await screen.findByText("Application received")).toBeTruthy();
  });
});
