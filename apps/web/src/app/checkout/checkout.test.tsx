import { ApiError, type Quote, type QuoteRequest } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const push = vi.fn();
let quotes = 0;
const quoteFor = (req: QuoteRequest): Quote => ({
  id: `q${++quotes}`, restaurant_id: req.restaurant_id, restaurant_name: "Ofada Hub",
  lines: [{
    item_id: "ofada", name: "Ofada rice", kind: "main", quantity: 1, unit_price_kobo: 350_000, options_unit_price_kobo: 0,
    line_total_kobo: 350_000, selections: [], selection_labels: [], notes: null,
  }],
  breakdown: {
    subtotal_kobo: 350_000, delivery_fee_kobo: 80_000, service_fee_kobo: 20_000, small_order_fee_kobo: 0, vat_kobo: 0,
    discount_kobo: 0, total_kobo: 450_000, discount_funded_by: null, voucher_code: null,
  },
  fulfillment: req.fulfillment, delivery_address: req.delivery_address ?? null, distance_km: 2, eta_minutes: 30,
  estimated_delivery_at: "2026-11-24T12:30:00Z", scheduled_for: null, created_at: "2026-11-24T12:00:00Z", expires_at: "2026-11-24T12:10:00Z",
});
const api = {
  me: { addresses: vi.fn(async () => [] as object[]), addAddress: vi.fn(async (a: object) => ({ id: "a1", ...a })) },
  rewards: { vouchers: vi.fn(async () => [] as object[]) },
  wallet: { get: vi.fn(async () => ({ enabled: true, balance_kobo: 0 })) },
  orders: {
    quote: vi.fn(async (req: QuoteRequest) => quoteFor(req)),
    create: vi.fn(async (_quote: string, _key: string, _channel: string, _phone?: string) => ({ id: "o1" })),
    checkout: vi.fn(async (orderId: string, _key: string, _provider?: string) => ({ order_id: orderId, provider: "cash", authorization_url: null })),
    summary: vi.fn(async () => ({ completed_count: 3 })),
  },
  places: { suggestions: vi.fn(async () => ({ suggestions: [] })), details: vi.fn(), reverse: vi.fn() },
};
vi.mock("@/lib/api", () => ({ useApi: () => api, publicApi: { catalog: { publicConfig: async () => ({}) } } }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: { uid: "u1" }, loading: false }) }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push, replace: vi.fn() }), usePathname: () => "/checkout" }));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

const { default: CheckoutPage } = await import("./page");
const { CartProvider } = await import("@/lib/cart");
const { LocationProvider } = await import("@/lib/location");

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}><LocationProvider><CartProvider><CheckoutPage /></CartProvider></LocationProvider></QueryClientProvider>,
  );
}

/** Types into a field one letter at a time, as a person does. */
function type(label: string, text: string) {
  const field = screen.getByLabelText(label);
  for (let i = 1; i <= text.length; i++) fireEvent.change(field, { target: { value: text.slice(0, i) } });
}
const payButton = () => screen.getByRole("button", { name: /^Pay\b/ }) as HTMLButtonElement;
const ready = { timeout: 4000 };

beforeEach(() => {
  quotes = 0;
  window.localStorage.setItem("gudmeal.cart.v1", JSON.stringify({
    restaurant_id: "r1", restaurant_name: "Ofada Hub",
    items: [{ key: "ofada##", item_id: "ofada", name: "Ofada rice", unit_price_kobo: 350_000, quantity: 1, selections: [], selection_labels: [] }],
  }));
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  window.localStorage.clear();
});

describe("checkout", () => {
  it("lets a customer in Enugu type an address: their own areas are offered and one price is asked for", async () => {
    window.localStorage.setItem("gudmeal.area.v1", "Independence Layout");
    show();
    const area = (await screen.findByLabelText("Area")) as HTMLSelectElement;
    await waitFor(() => expect(area.value).toBe("Independence Layout"));
    const offered = [...area.options].map((o) => o.value);
    expect(offered).toEqual(expect.arrayContaining(["Independence Layout", "Enugu GRA", "Lekki Phase 1"]));

    type("Street address", "12 Ogui Road");
    type("Delivery instructions", "Blue gate");
    type("Phone for the rider", "08030000000");
    expect(payButton().disabled).toBe(true); // nothing is paid for while the address is still being typed

    await waitFor(() => expect(api.orders.quote).toHaveBeenCalled(), ready);
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);
    // One request for the finished address, not one for each letter; the phone number asks for none.
    expect(api.orders.quote).toHaveBeenCalledTimes(1);
    expect(api.orders.quote.mock.calls[0]![0].delivery_address).toEqual({
      line1: "12 Ogui Road", area: "Independence Layout", city: "Enugu", state: "Enugu",
      location: { lat: 6.4473, lng: 7.5214 }, instructions: "Blue gate",
    });

    fireEvent.click(payButton());
    await waitFor(() => expect(push).toHaveBeenCalledWith("/orders/o1"));
    expect(api.orders.create).toHaveBeenCalledWith("q1", expect.stringMatching(/^order-/), "web", "08030000000");
    expect(api.me.addAddress).toHaveBeenCalledWith(expect.objectContaining({ line1: "12 Ogui Road", contact_phone: "08030000000", label: "Saved at checkout" }));
  });

  it("asks again with a new key after the API refused, and with the same key after a network error", async () => {
    api.me.addresses.mockResolvedValue([{ id: "a1", label: "Home", line1: "5 Admiralty Way", area: "Lekki Phase 1", location: { lat: 6.4478, lng: 3.4723 } }]);
    show();
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);

    // The price quote ran out: the API refuses, and the page gets a new price.
    api.orders.create.mockRejectedValueOnce(new ApiError(409, "quote_expired", "Your price quote expired; please review your cart again"));
    fireEvent.click(payButton());
    expect(await screen.findByText(/Your price quote expired/)).toBeTruthy();
    await waitFor(() => expect(api.orders.quote).toHaveBeenCalledTimes(2));

    // The next press is a new request (new quote, new key); this time the network drops.
    api.orders.create.mockRejectedValueOnce(new ApiError(0, "network_error", "We couldn't reach Yummy Chops. Check your connection and try again."));
    await waitFor(() => expect(payButton().disabled).toBe(false));
    fireEvent.click(payButton());
    expect(await screen.findByText(/We couldn't reach Yummy Chops/)).toBeTruthy();

    // Trying again after the network error repeats the same request with the same key, so it cannot order twice.
    fireEvent.click(payButton());
    await waitFor(() => expect(push).toHaveBeenCalledWith("/orders/o1"));
    const [refused, dropped, retried] = api.orders.create.mock.calls;
    expect([refused![0], dropped![0], retried![0]]).toEqual(["q1", "q2", "q2"]);
    expect(dropped![1]).not.toBe(refused![1]);
    expect(retried![1]).toBe(dropped![1]);
    expect(api.orders.checkout).toHaveBeenCalledTimes(1);
  });
});
