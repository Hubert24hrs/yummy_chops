import type { BranchInput, Business, BusinessBranch, MyBusinesses, PlaceLookup } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { Suspense } from "react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";

const BRANCHES: BusinessBranch[] = [
  {
    restaurant_id: "r-main", branch_name: "Ikeja", address: "1 Allen Avenue", area: "Ikeja", location: { lat: 6.6018, lng: 3.3515 },
    manager_phone: null, main: true, status: "active", is_accepting_orders: true,
  },
  {
    restaurant_id: "r-lekki", branch_name: "Lekki", address: "5 Admiralty Way", area: "Lekki Phase 1", location: { lat: 6.4478, lng: 3.4723 },
    manager_phone: "+2348033333333", main: false, status: "pending", is_accepting_orders: false,
  },
];
const BUSINESS: Business = {
  id: "YCB-7KQ2MX", name: "Ofada Hub", owner_uid: "owner-1", vertical: "food", phone: "+2348022222222", email: "hello@ofadahub.ng",
  main_restaurant_id: "r-main", settlement_bank_code: null, settlement_bank_name: null, settlement_account_name: null,
  settlement_account_last4: null, created_at: "2026-11-24T10:00:00Z", bank_connected: false, branches: BRANCHES,
};
const ENUGU: PlaceLookup = {
  place: {
    place_id: "p-ogui", formatted_address: "12 Ogui Road, Enugu", location: { lat: 6.4402, lng: 7.4943 }, area: "Ogui", city: "enugu",
    precision: "street", source: "google",
  },
  serviceable: true, zone: "Enugu", city: "enugu",
};

let mine: MyBusinesses = { businesses: [BUSINESS], without_business: [] };
const api = {
  partner: {
    business: vi.fn(async () => mine),
    claimBusiness: vi.fn(async (_rid: string) => BUSINESS),
    addBranch: vi.fn(async (_bid: string, b: BranchInput): Promise<Business> => ({
      ...BUSINESS,
      branches: [...BRANCHES, {
        restaurant_id: "r-enugu", branch_name: b.branch_name ?? null, address: b.address, area: b.area ?? "", location: b.location,
        manager_phone: b.manager_phone ?? null, main: false, status: "pending", is_accepting_orders: false,
      }],
    })),
    updateBranch: vi.fn(async (_bid: string, rid: string, body: { branch_name?: string | null; manager_phone?: string | null }): Promise<Business> => ({
      ...BUSINESS, branches: BRANCHES.map((b) => (b.restaurant_id === rid ? { ...b, ...body } : b)),
    })),
    banks: vi.fn(async () => [{ code: "044", name: "Access Bank" }, { code: "058", name: "Guaranty Trust Bank" }]),
    connectBank: vi.fn(async (_bid: string, code: string, account: string): Promise<Business> => ({
      ...BUSINESS, bank_connected: true, settlement_bank_code: code, settlement_bank_name: "Guaranty Trust Bank",
      settlement_account_name: "OFADA HUB LTD", settlement_account_last4: account.slice(-4),
    })),
  },
  places: {
    suggestions: vi.fn(async () => ({
      suggestions: [{ place_id: "p-ogui", title: "12 Ogui Road", subtitle: "Enugu", distance_m: null, source: "google" as const }],
      provider: "google" as const,
    })),
    details: vi.fn(async (): Promise<PlaceLookup> => ENUGU),
  },
};
const refreshToken = vi.fn(async () => {});
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ refreshToken }) }));

const { default: BusinessPage } = await import("./page");

/** A promise React's `use` reads at once (as Next.js passes already-known route params), so nothing suspends. */
const known = <T,>(value: T) => Object.assign(Promise.resolve(value), { status: "fulfilled", value });

function show(rid = "r-main") {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <Suspense fallback={<p>Loading</p>}><BusinessPage params={known({ rid })} /></Suspense>
    </QueryClientProvider>,
  );
}

async function pickAddress(query: string) {
  fireEvent.change(screen.getByRole("combobox", { name: "Find the branch's address" }), { target: { value: query } });
  fireEvent.mouseDown(await screen.findByRole("option", { name: /12 Ogui Road/ }));
}

beforeAll(() => {
  // jsdom has no modal dialogs
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  mine = { businesses: [BUSINESS], without_business: [] };
});

describe("the business page (ADR-0028)", () => {
  it("shows the business ID, every branch with its manager's number, and connects the bank account", async () => {
    show();
    expect(await screen.findByText("YCB-7KQ2MX")).toBeTruthy();
    const branches = screen.getByRole("list", { name: "Branches" });
    expect(within(branches).getByText("Main branch")).toBeTruthy();
    expect(within(branches).getByText("Taking orders")).toBeTruthy();
    expect(within(branches).getByText("Not live yet")).toBeTruthy();
    expect(within(branches).getByText("No manager's number yet")).toBeTruthy();
    expect(within(branches).getByRole("link", { name: "+2348033333333" }).getAttribute("href")).toBe("tel:+2348033333333");
    expect(within(branches).getByRole("link", { name: "Open" }).getAttribute("href")).toBe("/r/r-lekki/orders");

    // No bank account yet: the owner connects one. Only the last 4 digits come back.
    await screen.findByRole("option", { name: "Guaranty Trust Bank" });
    const connect = screen.getByRole("button", { name: "Check and connect" }) as HTMLButtonElement;
    expect(connect.disabled).toBe(true);
    fireEvent.change(screen.getByLabelText("Bank"), { target: { value: "058" } });
    fireEvent.change(screen.getByLabelText("Account number"), { target: { value: "0123-456-789" } });
    expect((screen.getByLabelText("Account number") as HTMLInputElement).value).toBe("0123456789");
    fireEvent.click(connect);
    await waitFor(() => expect(api.partner.connectBank).toHaveBeenCalledWith("YCB-7KQ2MX", "058", "0123456789"));
    expect(await screen.findByText("Connected for split payments")).toBeTruthy();
    expect(screen.getByText("Guaranty Trust Bank · account ending 6789")).toBeTruthy();
    expect(screen.queryByText(/0123456789/)).toBeNull();
  });

  it("adds a branch picked from the address search and refreshes the sign-in so its dashboard opens", async () => {
    show();
    fireEvent.click(await screen.findByRole("button", { name: "Add a branch" }));
    const add = screen.getByRole("button", { name: "Add branch" }) as HTMLButtonElement;
    expect(add.disabled).toBe(true); // no address yet

    // An address outside the delivery areas cannot be a branch.
    api.places.details.mockResolvedValueOnce({ ...ENUGU, serviceable: false, zone: null });
    await pickAddress("12 Ogui");
    expect(await screen.findByText(/outside the areas we deliver/)).toBeTruthy();
    expect(add.disabled).toBe(true);

    await pickAddress("12 Ogui Rd");
    expect(((await screen.findByLabelText("Address customers and riders see")) as HTMLInputElement).value).toBe("12 Ogui Road, Enugu");
    fireEvent.change(screen.getByLabelText("Branch name"), { target: { value: "Enugu" } });
    fireEvent.change(screen.getByLabelText("Branch manager's phone number"), { target: { value: "0803 444 4444" } });
    fireEvent.click(add);
    await waitFor(() => expect(api.partner.addBranch).toHaveBeenCalledWith("YCB-7KQ2MX", {
      branch_name: "Enugu", address: "12 Ogui Road, Enugu", area: "Ogui", location: { lat: 6.4402, lng: 7.4943 }, manager_phone: "0803 444 4444",
    }));
    await waitFor(() => expect(refreshToken).toHaveBeenCalledTimes(1));
    expect(await within(screen.getByRole("list", { name: "Branches" })).findByText("Enugu")).toBeTruthy();
  });

  it("changes a branch's name and manager's number; its address moves in its own settings", async () => {
    show();
    fireEvent.click(await screen.findByRole("button", { name: "Edit Lekki" }));
    expect(screen.getByRole("link", { name: "Settings, Kitchen location" }).getAttribute("href")).toBe("/r/r-lekki/settings");
    fireEvent.change(screen.getByLabelText("Branch manager's phone number"), { target: { value: "12" } });
    expect(screen.getByText("Enter the full phone number")).toBeTruthy();
    fireEvent.change(screen.getByLabelText("Branch manager's phone number"), { target: { value: "+2348055555555" } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.partner.updateBranch).toHaveBeenCalledWith("YCB-7KQ2MX", "r-lekki", {
      branch_name: "Lekki", manager_phone: "+2348055555555",
    }));
    expect(await screen.findByRole("link", { name: "+2348055555555" })).toBeTruthy();
  });

  it("gives an existing shop its business ID", async () => {
    mine = { businesses: [], without_business: [{ restaurant_id: "r-main", name: "Ofada Hub", address: "1 Allen Avenue", area: "Ikeja" }] };
    show();
    fireEvent.click(await screen.findByRole("button", { name: "Get my business ID" }));
    await waitFor(() => expect(api.partner.claimBusiness).toHaveBeenCalledWith("r-main"));
    expect(await screen.findByText("YCB-7KQ2MX")).toBeTruthy();
  });

  it("tells kitchen staff that only the owner manages the business", async () => {
    mine = { businesses: [], without_business: [] };
    show();
    expect(await screen.findByText("Only the owner manages the business")).toBeTruthy();
  });
});
