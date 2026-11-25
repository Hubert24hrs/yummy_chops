import { ApiError, type Quote, type QuoteRequest } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const push = vi.fn();
let quotes = 0;
/** Which shop each quote was for. */
const quoteShop = new Map<string, string>();
const quoteFor = (req: QuoteRequest): Quote => ({
  id: (() => { const id = `q${++quotes}`; quoteShop.set(id, req.restaurant_id); return id; })(), restaurant_id: req.restaurant_id, restaurant_name: "Ofada Hub",
  lines: [{
    item_id: "ofada", name: "Ofada rice", kind: "main", quantity: 1, unit_price_kobo: 350_000, options_unit_price_kobo: 0,
    line_total_kobo: 350_000, selections: [], selection_labels: [], notes: null,
  }],
  breakdown: {
    subtotal_kobo: 350_000, delivery_fee_kobo: 80_000, service_fee_kobo: 20_000, small_order_fee_kobo: 0, vat_kobo: 0,
    discount_kobo: 0, total_kobo: 450_000, discount_funded_by: null, voucher_code: null,
  },
  fulfillment: req.fulfillment, delivery_address: req.delivery_address ?? null, distance_km: 2, eta_minutes: 30,
  estimated_delivery_at: "2026-11-24T12:30:00Z", scheduled_for: req.scheduled_for ?? null, created_at: "2026-11-24T12:00:00Z", expires_at: "2026-11-24T12:10:00Z",
});
const api = {
  me: { addresses: vi.fn(async () => [] as object[]), addAddress: vi.fn(async (a: object) => ({ id: "a1", ...a })) },
  rewards: { vouchers: vi.fn(async () => [] as object[]) },
  wallet: { get: vi.fn(async () => ({ enabled: true, balance_kobo: 0 })) },
  orders: {
    quote: vi.fn(async (req: QuoteRequest) => quoteFor(req)),
    create: vi.fn(async (_quote: string, _key: string, _channel: string, _phone?: string) => ({ id: "o1" })),
    checkout: vi.fn(async (orderId: string, _key: string, _provider?: string) => ({ order_id: orderId, provider: "cash", authorization_url: null })),
    checkoutMany: vi.fn(async (orderIds: string[], _key: string, provider?: string) => ({
      order_ids: orderIds, provider: provider ?? "paystack", reference: null, authorization_url: null, amount_kobo: 0, currency: "NGN",
      payment_status: "pending", orders: [],
    })),
    summary: vi.fn(async () => ({ completed_count: 3 })),
  },
  places: { suggestions: vi.fn(async () => ({ suggestions: [] })), details: vi.fn(), reverse: vi.fn() },
  plus: { get: vi.fn(async () => ({ member: false, membership: null, plan: { enabled: true } })) },
};
vi.mock("@/lib/api", () => ({ useApi: () => api, publicApi: { catalog: { publicConfig: async () => ({}) } } }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: { uid: "u1" }, loading: false }) }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push, replace: vi.fn() }), usePathname: () => "/checkout" }));
vi.mock("next/link", () => ({
  default: ({ href, children, ...rest }: { href: string; children: React.ReactNode; "aria-label"?: string }) =>
    <a href={href} aria-label={rest["aria-label"]}>{children}</a>,
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

const line = (restaurant_id: string, restaurant_name: string, item_id: string, name: string, quantity = 1, notes?: string) => ({
  key: `${restaurant_id}/${item_id}##${notes ?? ""}`, restaurant_id, restaurant_name, item_id, name, unit_price_kobo: 350_000, quantity,
  selections: [], selection_labels: [], ...(notes ? { notes } : {}),
});
const saveCart = (items: ReturnType<typeof line>[]) => window.localStorage.setItem("gudmeal.cart.v2", JSON.stringify({ items }));
const home = { id: "a1", label: "Home", line1: "5 Admiralty Way", area: "Lekki Phase 1", location: { lat: 6.4478, lng: 3.4723 } };

/** Opens a row's sheet, fills it in, then closes it with its own button. */
function inSheet(row: RegExp, fill: () => void, done = /^(Save|Done)$/) {
  fireEvent.click(screen.getByRole("button", { name: row }));
  fill();
  fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: done }));
}

/** The browser's location permission and position (Ikeja by default: far from Lekki). */
function browserLocation(state: PermissionState, at = { latitude: 6.6018, longitude: 3.3515 }) {
  const getCurrentPosition = vi.fn((ok: PositionCallback) => ok({ coords: at } as GeolocationPosition));
  Object.defineProperty(navigator, "permissions", { configurable: true, value: { query: vi.fn(async () => ({ state })) } });
  Object.defineProperty(navigator, "geolocation", { configurable: true, value: { getCurrentPosition } });
  return getCurrentPosition;
}

beforeEach(() => {
  quotes = 0;
  quoteShop.clear();
  saveCart([line("r1", "Ofada Hub", "ofada", "Ofada rice")]);
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  window.localStorage.clear();
  Reflect.deleteProperty(navigator, "permissions");
  Reflect.deleteProperty(navigator, "geolocation");
  api.me.addresses.mockImplementation(async () => []);
  api.orders.create.mockImplementation(async () => ({ id: "o1" }));
});

describe("checkout", () => {
  it("lets a customer in Enugu type an address: their own areas are offered and one price is asked for", async () => {
    window.localStorage.setItem("gudmeal.area.v1", "Independence Layout");
    show();
    expect(await screen.findByText(/1 product from/)).toBeTruthy();
    expect(screen.getByText("Add your phone number")).toBeTruthy();

    fireEvent.click(await screen.findByRole("button", { name: /Add a delivery address/ }));
    const area = screen.getByLabelText("Area") as HTMLSelectElement;
    await waitFor(() => expect(area.value).toBe("Independence Layout"));
    const offered = [...area.options].map((o) => o.value);
    expect(offered).toEqual(expect.arrayContaining(["Independence Layout", "Enugu GRA", "Lekki Phase 1"]));
    type("Street address", "12 Ogui Road");
    fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: "Done" }));

    inSheet(/Instructions for the rider/, () => type("Delivery instructions", "Blue gate"));
    inSheet(/Phone number/, () => type("Phone number", "08030000000"));
    expect(screen.getByRole("button", { name: /Phone number\s*08030000000/ })).toBeTruthy();
    expect(payButton().disabled).toBe(true); // nothing is paid for while the address is still being typed

    await waitFor(() => expect(api.orders.quote).toHaveBeenCalled(), ready);
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);
    // One request for the finished address, not one for each letter; the phone number asks for none.
    expect(api.orders.quote).toHaveBeenCalledTimes(1);
    expect(api.orders.quote.mock.calls[0]![0].delivery_address).toEqual({
      line1: "12 Ogui Road", area: "Independence Layout", city: "Enugu", state: "Enugu",
      location: { lat: 6.4473, lng: 7.5214 }, instructions: "Blue gate",
    });
    expect(api.orders.quote.mock.calls[0]![0].scheduled_for).toBeNull();
    // The address shows on the page, with the summary and the total.
    expect(screen.getByRole("button", { name: "Edit address" })).toBeTruthy();
    expect(screen.getByText("Total to pay")).toBeTruthy();
    expect(payButton().textContent).toBe("Pay to order · ₦4,500");

    fireEvent.click(payButton());
    await waitFor(() => expect(push).toHaveBeenCalledWith("/orders/o1"));
    expect(api.orders.create).toHaveBeenCalledWith("q1", expect.stringMatching(/^order-/), "web", "08030000000");
    expect(api.me.addAddress).toHaveBeenCalledWith(expect.objectContaining({ line1: "12 Ogui Road", contact_phone: "08030000000", label: "Saved at checkout" }));
  });

  it("asks again with a new key after the API refused, and with the same key after a network error", async () => {
    api.me.addresses.mockResolvedValue([home]);
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

  it("pays once for a cart with items from two shops: one quote and one order per shop, one checkout", async () => {
    saveCart([
      line("r1", "Ofada Hub", "ofada", "Ofada rice"),
      line("p1", "MedPlus", "para", "Paracetamol", 2),
      line("r1", "Ofada Hub", "water", "Table water"),
    ]);
    api.me.addresses.mockResolvedValue([home]);
    api.orders.create.mockImplementation(async (quote: string) => ({ id: `o-${quoteShop.get(quote)}` }));
    show();

    expect(await screen.findByText(/4 products from/)).toBeTruthy();
    expect(screen.getByText("2 shops")).toBeTruthy();
    // Plus is offered to customers who are not members.
    expect((await screen.findByRole("link", { name: "More info" })).getAttribute("href")).toBe("/plus");

    // Each shop has its own small summary, then the totals for all of them.
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);
    expect(payButton().textContent).toBe("Pay to order · ₦9,000");
    expect(screen.getAllByText("Shop total")).toHaveLength(2);
    expect(screen.getByText("Total to pay")).toBeTruthy();
    expect(screen.getByRole("region", { name: "MedPlus order" })).toBeTruthy();
    expect(within(screen.getByRole("region", { name: "Ofada Hub order" })).getByText("2 items")).toBeTruthy();
    const quoted = api.orders.quote.mock.calls.map(([req]) => req);
    expect(new Set(quoted.map((r) => r.restaurant_id))).toEqual(new Set(["r1", "p1"]));
    expect(quoted.filter((r) => r.restaurant_id === "r1").at(-1)!.lines).toEqual([
      { item_id: "ofada", quantity: 1, selections: [], notes: null }, { item_id: "water", quantity: 1, selections: [], notes: null },
    ]);
    expect(quoted.filter((r) => r.restaurant_id === "p1").at(-1)!.lines).toEqual([{ item_id: "para", quantity: 2, selections: [], notes: null }]);
    expect(quoted.every((r) => r.delivery_address?.line1 === "5 Admiralty Way")).toBe(true);

    // A voucher goes with the first shop's quote only.
    fireEvent.click(screen.getByRole("button", { name: /Got a promo code\?/ }));
    expect(screen.getByText(/Voucher applies to one shop's order/)).toBeTruthy();
    fireEvent.change(screen.getByLabelText("Voucher code"), { target: { value: "welcome500" } });
    fireEvent.click(screen.getByRole("button", { name: "Apply" }));
    await waitFor(() => expect(api.orders.quote).toHaveBeenCalledWith(expect.objectContaining({ restaurant_id: "r1", voucher_code: "WELCOME500" })));
    expect(api.orders.quote.mock.calls.filter(([r]) => r.restaurant_id === "p1").every(([r]) => r.voucher_code === null)).toBe(true);

    fireEvent.click(await screen.findByRole("radio", { name: /Pay on delivery/ }));
    const place = await screen.findByRole("button", { name: "Place orders · ₦9,000" });
    await waitFor(() => expect((place as HTMLButtonElement).disabled).toBe(false), ready);
    fireEvent.click(place);

    await waitFor(() => expect(push).toHaveBeenCalledWith("/orders"));
    expect(api.orders.create).toHaveBeenCalledTimes(2);
    const [first, second] = api.orders.create.mock.calls;
    expect([quoteShop.get(first![0]), quoteShop.get(second![0])]).toEqual(["r1", "p1"]);
    expect(first![1]).not.toBe(second![1]); // each order has its own key
    expect(api.orders.checkoutMany).toHaveBeenCalledTimes(1);
    expect(api.orders.checkoutMany).toHaveBeenCalledWith(["o-r1", "o-p1"], expect.stringMatching(/^checkout-/), "cash");
    expect(api.orders.checkout).not.toHaveBeenCalled();
    expect(JSON.parse(window.localStorage.getItem("gudmeal.cart.v2")!).items).toEqual([]);
  });

  it("sends the allergy note with each shop's order, on that shop's first line", async () => {
    saveCart([
      line("r1", "Ofada Hub", "ofada", "Ofada rice", 1, "less pepper"),
      line("r1", "Ofada Hub", "water", "Table water"),
      line("p1", "MedPlus", "para", "Paracetamol"),
    ]);
    api.me.addresses.mockResolvedValue([home]);
    show();
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);

    inSheet(/Any allergies\?/, () => type("Allergies", "peanuts"));
    expect(screen.getByRole("button", { name: /Any allergies\?\s*peanuts/ })).toBeTruthy();
    const last = (shop: string) => api.orders.quote.mock.calls.filter(([r]) => r.restaurant_id === shop).at(-1)![0].lines;
    await waitFor(() => expect(last("p1")).toEqual([{ item_id: "para", quantity: 1, selections: [], notes: "Allergies: peanuts" }]), ready);
    expect(last("r1")).toEqual([
      { item_id: "ofada", quantity: 1, selections: [], notes: "less pepper · Allergies: peanuts" },
      { item_id: "water", quantity: 1, selections: [], notes: null },
    ]);
  });

  it("asks for prices at the scheduled time", async () => {
    api.me.addresses.mockResolvedValue([home]);
    show();
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);

    fireEvent.click(screen.getByRole("button", { name: /^Standard/ }));
    fireEvent.click(screen.getByRole("radio", { name: /Schedule/ }));
    const d = new Date(Date.now() + 3 * 60 * 60_000);
    const pad = (n: number) => String(n).padStart(2, "0");
    const value = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
    fireEvent.change(screen.getByLabelText("Date and time"), { target: { value } });
    await waitFor(() => expect(api.orders.quote).toHaveBeenCalledWith(expect.objectContaining({ scheduled_for: new Date(value).toISOString() })), ready);

    // Too soon: no price until the time is valid.
    fireEvent.change(screen.getByLabelText("Date and time"), { target: { value: "2020-01-01T10:00" } });
    expect(screen.getByText(/Choose a time from 30 minutes to 7 days from now to see your total/)).toBeTruthy();
    expect(payButton().disabled).toBe(true);
  });

  it("asks whether the address is right when it is far from where the customer is, before paying", async () => {
    browserLocation("granted");
    api.me.addresses.mockResolvedValue([home]);
    show();
    expect(await screen.findByText("Far from current location")).toBeTruthy();
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);

    fireEvent.click(payButton());
    const sheet = screen.getByRole("dialog", { name: "Far from current location" });
    expect(within(sheet).getByText("Is this address correct?")).toBeTruthy();
    expect(within(sheet).getByText("Home")).toBeTruthy();
    expect(api.orders.create).not.toHaveBeenCalled();

    // "Edit address" opens the address picker instead.
    fireEvent.click(within(sheet).getByRole("button", { name: "Edit address" }));
    fireEvent.click(within(screen.getByRole("dialog", { name: "Delivery address" })).getByRole("button", { name: "Done" }));

    fireEvent.click(payButton());
    fireEvent.click(within(screen.getByRole("dialog", { name: "Far from current location" })).getByRole("button", { name: /^Pay to order/ }));
    await waitFor(() => expect(push).toHaveBeenCalledWith("/orders/o1"));
    expect(api.orders.create).toHaveBeenCalledTimes(1);
  });

  it("never asks the browser for the location just for this, and pays straight away when the address is near", async () => {
    const asked = browserLocation("prompt");
    api.me.addresses.mockResolvedValue([home]);
    show();
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);
    expect(asked).not.toHaveBeenCalled();
    cleanup();

    browserLocation("granted", { latitude: 6.448, longitude: 3.4725 }); // at home
    show();
    await waitFor(() => expect(payButton().disabled).toBe(false), ready);
    expect(screen.queryByText("Far from current location")).toBeNull();
    fireEvent.click(payButton());
    expect(screen.queryByRole("dialog")).toBeNull();
    await waitFor(() => expect(push).toHaveBeenCalledWith("/orders/o1"));
  });
});
