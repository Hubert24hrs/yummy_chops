import type { MenuItem } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Suspense } from "react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";

const ITEM: MenuItem = {
  id: "i1", restaurant_id: "r-main", category_id: "c1", name: "Ofada rice", description: "With ayamase", price_kobo: 350_000,
  image_url: "https://storage.googleapis.com/demo/public/restaurants/r-main/ofada.jpg", kind: "main", tags: ["rice"], dietary: [],
  allergens: [], serves: 1, spice_level: 2, is_available: true, is_active: true, popularity: 5, option_group_ids: ["g1"],
  prep_minutes: 25, position: 3,
};
const api = {
  partner: {
    menu: vi.fn(async () => ({ restaurant: { id: "r-main", vertical: "food" }, categories: [{ id: "c1", name: "Mains", position: 0 }], items: [ITEM], option_groups: [] })),
    updateItem: vi.fn(async (_rid: string, _id: string, _body: Record<string, unknown>) => ITEM),
    createItem: vi.fn(),
    setAvailability: vi.fn(),
    setItemPhoto: vi.fn(async (_rid: string, _id: string, _data: string) => ({ ...ITEM, image_url: "https://api.test/v1/media/public/restaurants/r-main/items/i1-abc.jpg" })),
    removeItemPhoto: vi.fn(async () => ({ ...ITEM, image_url: null })),
    importMenu: vi.fn(async (_rid: string, _csv: string, apply: boolean) => ({
      applied: apply, created: 1, updated: 1, unchanged: 0, errors: 0, new_categories: ["Drinks"],
      rows: [
        { row: 2, name: "Table water", category: "Drinks", price_kobo: 230_000, action: "create", error: null, changes: [] },
        { row: 3, name: "Ofada rice", category: "Mains", price_kobo: 400_000, action: "update", error: null, changes: ["price"] },
      ],
    })),
  },
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("@/lib/photo", async (orig) => ({ ...(await orig<typeof import("@/lib/photo")>()), shrinkPhoto: vi.fn(async () => "data:image/jpeg;base64,AAAA") }));

const { default: MenuPage } = await import("./page");
const known = <T,>(value: T) => Object.assign(Promise.resolve(value), { status: "fulfilled", value });

beforeAll(() => {
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

function renderPage() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  render(
    <QueryClientProvider client={qc}>
      <Suspense fallback={<p>Loading</p>}><MenuPage params={known({ rid: "r-main" })} /></Suspense>
    </QueryClientProvider>,
  );
}

describe("photos", () => {
  it("adds a photo from the item editor at once, shrunk first", async () => {
    renderPage();
    fireEvent.click(await screen.findByRole("button", { name: "Edit Ofada rice" }));
    const file = new File(["x"], "ofada.jpg", { type: "image/jpeg" });
    fireEvent.change(screen.getByLabelText("Change photo"), { target: { files: [file] } });
    await waitFor(() => expect(api.partner.setItemPhoto).toHaveBeenCalledWith("r-main", "i1", "data:image/jpeg;base64,AAAA"));
    expect((await screen.findByAltText("Photo of Ofada rice")).getAttribute("src")).toContain("/v1/media/");
    fireEvent.click(screen.getByRole("button", { name: "Remove photo" }));
    await waitFor(() => expect(api.partner.removeItemPhoto).toHaveBeenCalledWith("r-main", "i1"));
  });
});

describe("importing from a spreadsheet", () => {
  it("shows the preview, then imports only when asked", async () => {
    renderPage();
    fireEvent.click(await screen.findByRole("button", { name: "Import from spreadsheet" }));
    const file = new File(["category,name,price\nDrinks,Table water,2300\n"], "prices.csv", { type: "text/csv" });
    fireEvent.change(screen.getByLabelText("Choose CSV file"), { target: { files: [file] } });
    expect(await screen.findByText(/prices\.csv: 1 new, 1 to update, 0 unchanged/)).toBeTruthy();
    expect(api.partner.importMenu).toHaveBeenCalledTimes(1);
    expect(api.partner.importMenu.mock.calls[0]![2]).toBe(false);
    expect(screen.getByText("New categories: Drinks")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Import 2 items" }));
    expect(await screen.findByText("Done: 1 added, 1 updated.")).toBeTruthy();
    expect(api.partner.importMenu.mock.calls[1]![2]).toBe(true);
  });

  it("will not import while a line has a problem", async () => {
    api.partner.importMenu.mockResolvedValueOnce({
      applied: false, created: 0, updated: 0, unchanged: 0, errors: 1, new_categories: [],
      rows: [{ row: 2, name: "Zobo", category: "Drinks", price_kobo: null, action: "error", error: '"abc" is not a price', changes: [] }],
    });
    renderPage();
    fireEvent.click(await screen.findByRole("button", { name: "Import from spreadsheet" }));
    fireEvent.change(screen.getByLabelText("Choose CSV file"), { target: { files: [new File(["x"], "bad.csv")] } });
    expect(await screen.findByText('"abc" is not a price')).toBeTruthy();
    expect((screen.getByRole("button", { name: "Fix 1 problem first" }) as HTMLButtonElement).disabled).toBe(true);
  });
});

describe("editing a menu item", () => {
  it("keeps the item's photo, prep time and place in the list, which the form does not show", async () => {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
    render(
      <QueryClientProvider client={qc}>
        <Suspense fallback={<p>Loading</p>}><MenuPage params={known({ rid: "r-main" })} /></Suspense>
      </QueryClientProvider>,
    );
    fireEvent.click(await screen.findByRole("button", { name: "Edit Ofada rice" }));
    fireEvent.change(screen.getByLabelText("Price (₦)"), { target: { value: "4000" } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.partner.updateItem).toHaveBeenCalled());
    expect(api.partner.updateItem.mock.calls[0]![2]).toMatchObject({
      price_kobo: 400_000, image_url: ITEM.image_url, prep_minutes: 25, position: 3, option_group_ids: ["g1"], spice_level: 2,
    });
  });
});
