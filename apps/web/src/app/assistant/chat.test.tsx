import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";

const agents = { chat: vi.fn(async () => ({ thread_id: "t1", status: "ok", reply: "Jollof with chicken.", cards: [], approval: null })), approve: vi.fn() };
const api = { me: { addresses: vi.fn(async () => [] as object[]) } };
vi.mock("@/lib/api", () => ({ useApi: () => api, useAgentsApi: () => agents }));
vi.mock("@/lib/auth", () => ({ useAuth: () => ({ user: { uid: "u1" }, loading: false }) }));
vi.mock("next/navigation", () => ({
  useSearchParams: () => new URLSearchParams({ q: "Tell me about the Jollof rice from Mama Put." }),
  usePathname: () => "/assistant",
}));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

const { Chat } = await import("./chat");
const { LocationProvider } = await import("@/lib/location");

beforeAll(() => {
  Element.prototype.scrollIntoView ??= () => undefined; // not in jsdom
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("Ask Yummy with a question in the link", () => {
  it("puts the question in the message box and sends it only when the customer presses Send", async () => {
    const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    render(<QueryClientProvider client={qc}><LocationProvider><Chat /></LocationProvider></QueryClientProvider>);
    const box = screen.getByLabelText("Message") as HTMLInputElement;
    expect(box.value).toBe("Tell me about the Jollof rice from Mama Put.");
    await waitFor(() => expect(api.me.addresses).toHaveBeenCalled());
    await new Promise((done) => setTimeout(done, 50));
    expect(agents.chat).not.toHaveBeenCalled(); // opening the link says nothing to Yummy

    fireEvent.click(screen.getByRole("button", { name: "Send" }));
    await waitFor(() => expect(agents.chat).toHaveBeenCalledTimes(1));
    expect(agents.chat).toHaveBeenCalledWith(expect.objectContaining({ message: "Tell me about the Jollof rice from Mama Put.", channel: "web" }));
    expect(await screen.findByText("Jollof with chicken.")).toBeTruthy();
  });
});
