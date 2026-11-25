import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const auth = { user: null as null | { uid: string }, loading: false };
const verify = vi.fn();
const replace = vi.fn();
vi.mock("@/lib/auth", () => ({ useAuth: () => auth }));
vi.mock("@/lib/api", () => ({ useApi: () => ({ payments: { verify } }) }));
vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams("order_id=o1&reference=YC-ABC123"),
  useRouter: () => ({ replace }),
}));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

const { default: CallbackPage } = await import("./page");

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={qc}><CallbackPage /></QueryClientProvider>);
}

afterEach(() => {
  cleanup();
  verify.mockReset();
  replace.mockReset();
});

describe("payment return page", () => {
  it("sends app payments (no website session) back to the app instead of asking to sign in", () => {
    auth.user = null;
    show();
    expect(screen.getByRole("heading", { name: "Return to the Yummy Chops app" })).toBeTruthy();
    const signIn = screen.getByRole("link", { name: /Paid on the website\? Sign in/ });
    // Signing in on the website comes back here with the payment reference intact.
    expect(signIn.getAttribute("href")).toBe(
      `/login?next=${encodeURIComponent("/checkout/callback?order_id=o1&reference=YC-ABC123")}`,
    );
    expect(verify).not.toHaveBeenCalled();
  });

  it("verifies the payment for a signed-in website customer", async () => {
    auth.user = { uid: "cust-1" };
    verify.mockResolvedValue({ status: "succeeded", order_id: "o1", purpose: "order" });
    show();
    await waitFor(() => expect(screen.getByRole("heading", { name: "Payment confirmed" })).toBeTruthy());
    expect(verify).toHaveBeenCalledWith("YC-ABC123");
    // The order is paid for: the receipt printer comes next (ADR-0019).
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/orders/o1/receipt"));
    expect(screen.getByRole("link", { name: "Print my receipt" }).getAttribute("href")).toBe("/orders/o1/receipt");
  });

  it("does not open the receipt printer for a membership payment or while a payment is unconfirmed", async () => {
    auth.user = { uid: "cust-1" };
    verify.mockResolvedValue({ status: "succeeded", order_id: null, purpose: "plus" });
    show();
    await waitFor(() => expect(screen.getByRole("heading", { name: "Welcome to Yummy Chops Plus" })).toBeTruthy());
    expect(replace).not.toHaveBeenCalled();
    cleanup();

    verify.mockResolvedValue({ status: "failed", order_id: "o1", purpose: "order", failure_reason: "Declined" });
    show();
    await waitFor(() => expect(screen.getByRole("heading", { name: "Payment not completed" })).toBeTruthy());
    expect(replace).not.toHaveBeenCalled();
  });

  it("says “not charged” only when the API said the payment failed", async () => {
    auth.user = { uid: "cust-1" };
    verify.mockResolvedValue({ status: "failed", order_id: "o1", purpose: "order", failure_reason: null });
    show();
    expect(await screen.findByText("The payment was not successful. You have not been charged.")).toBeTruthy();
    expect(screen.getByRole("link", { name: "View order" }).getAttribute("href")).toBe("/orders/o1");
    cleanup();

    // Left unfinished (a bank transfer can still arrive): no promise that nothing was taken.
    verify.mockResolvedValue({ status: "abandoned", order_id: "o1", purpose: "order", failure_reason: "abandoned" });
    show();
    expect(await screen.findByText(/The payment was not finished\. If you did send the money, your order updates by itself/)).toBeTruthy();
    expect(screen.queryByText(/not been charged/)).toBeNull();
    cleanup();

    // The money came in but does not match the order: the team checks it, and the customer must not pay again.
    verify.mockResolvedValue({ status: "flagged", order_id: "o1", purpose: "order", failure_reason: "amount_mismatch" });
    show();
    expect(await screen.findByRole("heading", { name: "We are checking your payment" })).toBeTruthy();
    expect(screen.getByText(/Please do not pay again/)).toBeTruthy();
    expect(screen.queryByText(/not been charged|amount_mismatch/)).toBeNull();
  });

  it("when the check itself fails, says so, offers to try again and never says “not charged”", async () => {
    auth.user = { uid: "cust-1" };
    verify.mockRejectedValueOnce(new Error("We couldn't reach Yummy Chops. Check your connection and try again."));
    show();
    expect(await screen.findByRole("heading", { name: "We could not check your payment" })).toBeTruthy();
    expect(screen.getByText(/If you were charged, your order updates by itself: you do not need to pay again/)).toBeTruthy();
    expect(screen.queryByText(/not been charged/)).toBeNull();
    expect(screen.queryByRole("heading", { name: "Payment not completed" })).toBeNull();
    expect(replace).not.toHaveBeenCalled();

    verify.mockResolvedValue({ status: "succeeded", order_id: "o1", purpose: "order" });
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(await screen.findByRole("heading", { name: "Payment confirmed" })).toBeTruthy();
    expect(verify).toHaveBeenCalledTimes(2);
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/orders/o1/receipt"));
  });
});
