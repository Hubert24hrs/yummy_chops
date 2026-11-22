import type { PlaceLookup } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const replace = vi.fn();
const lookup: PlaceLookup = {
  place: {
    place_id: "ChIJ-admiralty", formatted_address: "5 Admiralty Way, Lekki Phase 1, Lagos", location: { lat: 6.4478, lng: 3.4723 },
    area: "Lekki Phase 1", city: "lagos", precision: "rooftop", source: "google",
  },
  serviceable: true, zone: "island", city: "lagos",
};
const api = {
  places: {
    suggestions: vi.fn(async () => ({
      suggestions: [{ place_id: "ChIJ-admiralty", title: "5 Admiralty Way", subtitle: "Lekki Phase 1, Lagos", distance_m: 900, source: "google" }],
      provider: "google",
    })),
    details: vi.fn(async () => lookup),
    reverse: vi.fn(async () => lookup),
  },
  me: { addAddress: vi.fn(async (a: object) => ({ id: "a1", ...a })), addresses: vi.fn(async () => [] as object[]) },
};
const auth = { signIn: vi.fn(async () => undefined), signUp: vi.fn(), signInWithGoogle: vi.fn(), user: { uid: "u1" }, loading: false };
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("@/lib/auth", () => ({ useAuth: () => auth, authErrorMessage: (e: Error) => e.message }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace, push: vi.fn() }),
  useSearchParams: () => new URLSearchParams("next=/orders"),
  usePathname: () => "/where-to-deliver",
}));

const { default: WhereToDeliverPage } = await import("./page");
const { default: LoginPage } = await import("../login/page");
const { LocationProvider } = await import("@/lib/location");

function show(page: React.ReactNode) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><LocationProvider>{page}</LocationProvider></QueryClientProvider>);
}

afterEach(() => {
  cleanup();
  replace.mockClear();
  api.me.addAddress.mockClear();
  window.localStorage.clear();
});

describe("Where should we deliver? (after signing in)", () => {
  it("offers GPS and typing (the map needs a Google key), saves the address as Home and goes on", async () => {
    show(<WhereToDeliverPage />);
    expect(screen.getByRole("heading", { name: "Where should we deliver?" })).toBeTruthy();
    expect(screen.getByRole("button", { name: "Use my current location" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: /Choose on the map/ })).toBeNull(); // no browser key in tests

    fireEvent.change(screen.getByRole("combobox", { name: "Use my current location, or type your address" }), { target: { value: "Admiralty" } });
    fireEvent.mouseDown(await screen.findByRole("option", { name: /5 Admiralty Way/ }));
    expect(await screen.findByText(/Yummy Chops delivers here/)).toBeTruthy();
    expect((screen.getByLabelText("Street and house number") as HTMLInputElement).value).toBe("5 Admiralty Way, Lekki Phase 1, Lagos");

    fireEvent.change(screen.getByLabelText("Landmark or directions (optional)"), { target: { value: "Blue gate" } });
    fireEvent.click(screen.getByRole("button", { name: "Use this address" }));
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/orders"));
    expect(api.me.addAddress).toHaveBeenCalledWith(expect.objectContaining({
      label: "Home", line1: "5 Admiralty Way, Lekki Phase 1, Lagos", area: "Lekki Phase 1",
      location: { lat: 6.4478, lng: 3.4723 }, place_id: "ChIJ-admiralty", instructions: "Blue gate",
    }));
    expect(window.localStorage.getItem("gudmeal.area.v1")).toBe("Lekki Phase 1"); // Home shows that area now
  });

  it("“Not now” goes on without saving anything", () => {
    show(<WhereToDeliverPage />);
    fireEvent.click(screen.getByRole("button", { name: "Not now" }));
    expect(replace).toHaveBeenCalledWith("/orders");
    expect(api.me.addAddress).not.toHaveBeenCalled();
  });
});

describe("signing in", () => {
  it("a customer with no saved address is asked where to deliver first", async () => {
    api.me.addresses.mockResolvedValueOnce([]);
    show(<LoginPage />);
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "ada@example.com" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "secret1" } });
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/where-to-deliver?next=%2Forders"));
  });

  it("a customer who has an address goes straight on, and a failed check never blocks signing in", async () => {
    api.me.addresses.mockResolvedValueOnce([{ id: "a1", line1: "5 Admiralty Way", location: { lat: 6.4478, lng: 3.4723 } }]);
    show(<LoginPage />);
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "ada@example.com" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "secret1" } });
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/orders"));

    cleanup();
    replace.mockClear();
    api.me.addresses.mockRejectedValueOnce(new Error("offline"));
    show(<LoginPage />);
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "ada@example.com" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "secret1" } });
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/orders"));
  });
});
