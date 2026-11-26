import { QueryClient, QueryClientProvider, focusManager } from "@tanstack/react-query";
import { act, cleanup, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const order = (status: string) => ({
  id: "o1", short_code: "ABC123", status, vertical: "food", restaurant_name: "Ofada Hub", lines: [{ quantity: 1, name: "Ofada rice" }],
  breakdown: { total_kobo: 450_000 }, created_at: "2026-11-24T12:00:00Z",
});
const api = { orders: { list: vi.fn(async () => [] as object[]), summary: vi.fn(async () => ({ orders_count: 0 })) } };
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: { uid: "u1", isAnonymous: true }, isGuest: true, loading: false }) }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn(), replace: vi.fn() }), usePathname: () => "/orders" }));
vi.mock("next/link", () => ({ default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a> }));

const { default: OrdersPage } = await import("./page");
const { CartProvider } = await import("@/lib/cart");

/** The site's own defaults: answers are kept for 30 s and not read again on focus (components/providers.tsx). */
function show(qc = new QueryClient({ defaultOptions: { queries: { retry: false, staleTime: 30_000, refetchOnWindowFocus: false } } })) {
  render(<QueryClientProvider client={qc}><CartProvider><OrdersPage /></CartProvider></QueryClientProvider>);
  return qc;
}

afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.clearAllMocks();
  api.orders.list.mockImplementation(async () => []);
});

describe("orders page", () => {
  it("reads the list again when it opens, even with an empty answer from before paying", async () => {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false, staleTime: 30_000, refetchOnWindowFocus: false } } });
    qc.setQueryData(["orders"], []); // read a moment ago, before the order existed
    api.orders.list.mockResolvedValue([order("paid")]);
    show(qc);
    expect(await screen.findByText("Ofada Hub")).toBeTruthy();
    expect(api.orders.list).toHaveBeenCalledTimes(1);
  });

  it("reads it again every 10 s while an order is in progress, and when the customer comes back to the tab", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    api.orders.list.mockResolvedValue([order("preparing")]);
    show();
    await waitFor(() => expect(api.orders.list).toHaveBeenCalledTimes(1));
    await act(() => vi.advanceTimersByTimeAsync(10_000));
    await waitFor(() => expect(api.orders.list).toHaveBeenCalledTimes(2));

    // Delivered and completed: nothing in progress, so no more asking on a timer.
    api.orders.list.mockResolvedValue([order("completed")]);
    await act(() => vi.advanceTimersByTimeAsync(10_000));
    await waitFor(() => expect(api.orders.list).toHaveBeenCalledTimes(3));
    await act(() => vi.advanceTimersByTimeAsync(30_000));
    expect(api.orders.list).toHaveBeenCalledTimes(3);

    act(() => { focusManager.setFocused(false); });
    act(() => { focusManager.setFocused(true); });
    await waitFor(() => expect(api.orders.list).toHaveBeenCalledTimes(4));
    focusManager.setFocused(undefined);
  });
});
