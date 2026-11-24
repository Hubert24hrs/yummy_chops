import type { Order, OrderStatus } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { Suspense } from "react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";

const order = (over: Partial<Order> & { status: OrderStatus }): Order => ({
  id: `o-${over.short_code ?? "A1B2"}`, short_code: "A1B2", customer_id: "c1", customer_name: "Ada Obi", restaurant_id: "r-main",
  restaurant_name: "Ofada Hub", restaurant_address: "1 Allen Avenue", restaurant_location: { lat: 6.6018, lng: 3.3515 },
  fulfillment: "delivery", lines: [{
    item_id: "ofada", name: "Ofada rice", kind: "main", quantity: 2, unit_price_kobo: 350_000, options_unit_price_kobo: 0,
    line_total_kobo: 700_000, selections: [], selection_labels: [], notes: null,
  }],
  breakdown: {
    subtotal_kobo: 700_000, delivery_fee_kobo: 80_000, service_fee_kobo: 30_000, small_order_fee_kobo: 0, vat_kobo: 0,
    discount_kobo: 0, total_kobo: 810_000, discount_funded_by: null, voucher_code: null,
  },
  delivery_address: null, distance_km: 2, scheduled_for: null,
  payment: { provider: "paystack", reference: "ref", status: "paid", paid_at: "2026-11-24T10:00:00Z" },
  rider_id: null, rider_name: null, prep_minutes: null, estimated_delivery_at: null, accepted_at: null, ready_at: null,
  picked_up_at: null, delivered_at: null, completed_at: null, cancelled_at: null, cancellation_reason: null, refund_total_kobo: 0,
  reviewed: false, channel: "web", created_at: "2026-11-24T10:00:00Z", updated_at: "2026-11-24T10:00:00Z",
  progress: { step: 1, total_steps: 5, label: "" }, audience: "restaurant", restaurant_earning_kobo: 595_000, ...over,
});

let board: Order[] = [];
const api = {
  partner: {
    orders: vi.fn(async () => board),
    accept: vi.fn(async (_rid: string, _oid: string, _prep: number) => ({})),
    preparing: vi.fn(async () => ({})),
    ready: vi.fn(async () => ({})),
    reject: vi.fn(async () => ({})),
    handover: vi.fn(async () => ({})),
  },
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));

const { default: OrdersBoard } = await import("./page");

/** A promise React's `use` reads at once (as Next.js passes already-known route params), so nothing suspends. */
const known = <T,>(value: T) => Object.assign(Promise.resolve(value), { status: "fulfilled", value });

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <Suspense fallback={<p>Loading</p>}><OrdersBoard params={known({ rid: "r-main" })} /></Suspense>
    </QueryClientProvider>,
  );
}

beforeAll(() => {
  HTMLDialogElement.prototype.showModal ??= function (this: HTMLDialogElement) { this.setAttribute("open", ""); };
  HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) { this.removeAttribute("open"); };
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("the order board (ADR-0028)", () => {
  it("shows that a split payment is in, and the kitchen confirms the order", async () => {
    board = [order({
      status: "submitted_to_restaurant", short_code: "K7Q2",
      payment: { provider: "paystack", reference: "ref", status: "paid", paid_at: "2026-11-24T10:00:00Z", split_to_business_kobo: 595_000 },
    })];
    show();
    const card = within(await screen.findByRole("region", { name: "New" }));
    expect(card.getByText("Payment received")).toBeTruthy();
    expect(card.getByText(/sent to your bank account by Paystack/)).toBeTruthy();
    fireEvent.click(card.getByRole("button", { name: "Confirm order" }));
    await waitFor(() => expect(api.partner.accept).toHaveBeenCalledWith("r-main", "o-K7Q2", 20));
  });

  it("marks cash orders and orders paid out weekly", async () => {
    board = [order({ status: "submitted_to_restaurant", payment: { provider: "cash", reference: null, status: "unpaid", paid_at: null } })];
    show();
    const card = within(await screen.findByRole("region", { name: "New" }));
    expect(card.getByText("Cash on delivery")).toBeTruthy();
    expect(card.getByText(/in your weekly payout/)).toBeTruthy();
    expect(card.queryByText("Payment received")).toBeNull();
  });

  it("shows the rider coming with their number and minutes away, then who picked the order up", async () => {
    board = [
      order({
        status: "rider_assigned", short_code: "R1D3", rider_id: "rider-1", rider_name: "Musa",
        rider: { name: "Musa Bello", phone: "+2348011112222", eta_minutes: 6, verified: true },
      }),
      order({
        status: "picked_up", short_code: "P1CK", rider_id: "rider-2", rider_name: "Tunde",
        rider: { name: "Tunde Ade", phone: "+2348033334444", eta_minutes: null, verified: false },
      }),
    ];
    show();
    const waiting = within(await screen.findByRole("region", { name: "Ready / awaiting rider" }));
    expect(waiting.getByText("Musa Bello")).toBeTruthy();
    expect(waiting.getByText("Verified")).toBeTruthy();
    expect(waiting.getByRole("link", { name: "+2348011112222" }).getAttribute("href")).toBe("tel:+2348011112222");
    expect(waiting.getByText("Arrives in about 6 min")).toBeTruthy();

    const gone = within(screen.getByRole("region", { name: "Picked up" }));
    expect(gone.getByText(/Picked up by/)).toBeTruthy();
    expect(gone.getByText("Tunde Ade")).toBeTruthy();
    expect(gone.queryByText(/Arrives in/)).toBeNull();
  });
});
