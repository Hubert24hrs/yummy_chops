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
  },
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));

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
