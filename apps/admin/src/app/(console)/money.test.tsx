import { ApiError } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { Suspense, type ReactNode } from "react";
import { afterEach, describe, expect, it, vi } from "vitest";

const PRICING = {
  version: 7, default_commission_bps: 1500, service_fee_bps: 500, vat_bps: 750, service_fee_min_kobo: 10_000, service_fee_max_kobo: 100_000,
  small_order_threshold_kobo: 200_000, delivery: { base_kobo: 50_000, per_km_kobo: 10_000 }, rider_pay: { per_km_kobo: 8_000 }, zones: [],
};
const order = (completed: boolean) => ({
  order: {
    id: "o1", short_code: "A1B2", status: completed ? "completed" : "preparing", channel: "web", restaurant_name: "Ofada Hub",
    customer_name: "Ada", customer_id: "c1", lines: [], breakdown: { total_kobo: 810_000 }, refund_total_kobo: 0, rider_name: null,
    delivery_address: null, settlement: null, completed_at: completed ? "2026-11-24T11:00:00Z" : null,
  },
  events: [],
});
const api = {
  admin: {
    refunds: vi.fn(async () => [{ id: "rf1", order_id: "order-123456", amount_kobo: 250_000, reason: "Missing item", liability: "restaurant", status: "requested", created_at: "2026-11-24T10:00:00Z" }]),
    decideRefund: vi.fn(async (_id: string, _approve: boolean, _note?: string) => ({})),
    cash: vi.fn(async () => ({
      totals: { cash_with_riders_kobo: 0, wallet_balances_kobo: 0, seller_balances_kobo: 0 }, rider_cash_limit_kobo: 0, riders: [],
      carriers: [{ carrier_id: "car1", name: "ABC Transport", owed_kobo: 500_000 }],
    })),
    sellerPayouts: vi.fn(async () => [{ id: "sp1", vendor_id: "v1", account_name: "Ada Obi", bank_name: "GTB", account_number: "0123456789", amount_kobo: 300_000, requested_at: "2026-11-24T10:00:00Z" }]),
    decideSellerPayout: vi.fn(async (_id: string, _approve: boolean, _ref?: string, _note?: string) => ({})),
    carrierPayout: vi.fn(async (_id: string, _amount: number, _ref: string, _key: string) => ({})),
    ledger: vi.fn(async () => ({ trial_balance: { debits_kobo: 0, credits_kobo: 0 }, accounts: [] })),
    settlements: vi.fn(async () => []),
    payouts: vi.fn(async () => [{ id: "rp1", rider_id: "rider-1", amount_kobo: 100_000, status: "requested", requested_at: "2026-11-24T10:00:00Z" }]),
    decidePayout: vi.fn(async (_id: string, _approve: boolean, _ref?: string) => ({})),
    pricing: vi.fn(async () => PRICING),
    flags: vi.fn(async () => ({})),
    updatePricing: vi.fn(async (_cfg: object) => PRICING),
    order: vi.fn(async () => order(false)),
    riders: vi.fn(async () => []),
    transition: vi.fn(async (_id: string, _body: object) => ({})),
  },
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: ReactNode }) => <a href={href}>{children}</a>,
}));

const { default: RefundsPage } = await import("./refunds/page");
const { default: CashPage } = await import("./cash/page");
const { default: FinancePage } = await import("./finance/page");
const { default: ConfigPage } = await import("./config/page");
const { default: OrderDetail } = await import("./orders/[id]/page");

const known = <T,>(value: T) => Object.assign(Promise.resolve(value), { status: "fulfilled", value });
function show(page: ReactNode) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><Suspense fallback={<p>Loading</p>}>{page}</Suspense></QueryClientProvider>);
}
/** What the staff member answers to the browser's questions, in order (null is Cancel). */
function answers(...replies: (string | null)[]) {
  window.prompt = vi.fn(() => replies.shift() ?? null);
}
const settle = () => new Promise((done) => setTimeout(done, 30));

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("money actions in the Command Centre", () => {
  it("a cancelled note does not approve or reject a refund", async () => {
    show(<RefundsPage />);
    answers(null, null, "  Checked with the kitchen ", "");
    fireEvent.click(await screen.findByRole("button", { name: "Approve" }));
    fireEvent.click(screen.getByRole("button", { name: "Reject" }));
    await settle();
    expect(api.admin.decideRefund).not.toHaveBeenCalled();

    fireEvent.click(screen.getByRole("button", { name: "Approve" }));
    await waitFor(() => expect(api.admin.decideRefund).toHaveBeenCalledWith("rf1", true, "Checked with the kitchen"));
    fireEvent.click(screen.getByRole("button", { name: "Reject" }));
    await waitFor(() => expect(api.admin.decideRefund).toHaveBeenCalledWith("rf1", false, undefined)); // an empty note is still a yes
  });

  it("a cancelled reason does not reject a seller's withdrawal", async () => {
    show(<CashPage />);
    const row = within((await screen.findByText("Ada Obi")).closest("tr")!);
    answers(null, null, "Wrong account name");
    fireEvent.click(row.getByRole("button", { name: "Reject" }));
    fireEvent.click(row.getByRole("button", { name: "Paid" }));
    await settle();
    expect(api.admin.decideSellerPayout).not.toHaveBeenCalled();
    fireEvent.click(row.getByRole("button", { name: "Reject" }));
    await waitFor(() => expect(api.admin.decideSellerPayout).toHaveBeenCalledWith("sp1", false, undefined, "Wrong account name"));
  });

  it("a carrier payout sent again after a network error is the same request, so it is recorded once", async () => {
    show(<CashPage />);
    const record = await screen.findByRole("button", { name: "Record payout" });
    answers("5000", null); // cancelled at the bank reference
    fireEvent.click(record);
    await settle();
    expect(api.admin.carrierPayout).not.toHaveBeenCalled();

    api.admin.carrierPayout.mockRejectedValueOnce(new ApiError(0, "network_error", "We couldn't reach Yummy Chops. Check your connection and try again."));
    answers("5000", "TRF-0001", "5000", "TRF-0001", "5000", "TRF-0002");
    fireEvent.click(record);
    expect(await screen.findByText(/We couldn't reach Yummy Chops/)).toBeTruthy();
    fireEvent.click(record);
    await waitFor(() => expect(api.admin.carrierPayout).toHaveBeenCalledTimes(2));
    fireEvent.click(record);
    await waitFor(() => expect(api.admin.carrierPayout).toHaveBeenCalledTimes(3));
    const [lost, again, other] = api.admin.carrierPayout.mock.calls;
    expect(lost!.slice(0, 3)).toEqual(["car1", 500_000, "TRF-0001"]);
    expect(again![3]).toBe(lost![3]); // the same key: the API records it once
    expect(other![3]).not.toBe(lost![3]); // another transfer is another request
  });

  it("rejecting a rider's withdrawal asks first, and a cancelled bank reference pays nothing", async () => {
    show(<FinancePage />);
    const row = within((await screen.findByText("rider-1")).closest("tr")!);
    window.confirm = vi.fn(() => false);
    answers(null);
    fireEvent.click(row.getByRole("button", { name: "Reject" }));
    fireEvent.click(row.getByRole("button", { name: "Paid" }));
    await settle();
    expect(window.confirm).toHaveBeenCalledWith("Reject this withdrawal request?");
    expect(api.admin.decidePayout).not.toHaveBeenCalled();

    window.confirm = vi.fn(() => true);
    fireEvent.click(row.getByRole("button", { name: "Reject" }));
    await waitFor(() => expect(api.admin.decidePayout).toHaveBeenCalledWith("rp1", false, undefined));
  });

  it("says so when someone else changed the settings first", async () => {
    api.admin.updatePricing.mockRejectedValueOnce(new ApiError(409, "conflict", "Pricing changed since version 7"));
    show(<ConfigPage />);
    fireEvent.click(await screen.findByRole("button", { name: "Publish pricing v8" }));
    expect(await screen.findByText("Someone else changed the settings. Reload and try again.")).toBeTruthy();
    expect(api.admin.updatePricing).toHaveBeenCalledWith(expect.objectContaining({ version: 7 })); // the version it loaded
  });

  it("offers a part refund only for a completed order", async () => {
    show(<OrderDetail params={known({ id: "o1" })} />);
    expect(await screen.findByText(/This order is not completed yet, so the customer is refunded in full \(₦8,100\)/)).toBeTruthy();
    expect(screen.queryByLabelText("Refund amount (₦, optional)")).toBeNull();
    cleanup();

    api.admin.order.mockResolvedValue(order(true));
    show(<OrderDetail params={known({ id: "o1" })} />);
    fireEvent.change(await screen.findByLabelText("Refund amount (₦, optional)"), { target: { value: "1500" } });
    fireEvent.change(screen.getByLabelText("Reason (required)"), { target: { value: "Missing drink" } });
    fireEvent.click(screen.getByRole("button", { name: "Apply" }));
    await waitFor(() => expect(api.admin.transition).toHaveBeenCalledWith("o1", expect.objectContaining({ to: "refund_pending", refund_amount_kobo: 150_000 })));
  });
});
