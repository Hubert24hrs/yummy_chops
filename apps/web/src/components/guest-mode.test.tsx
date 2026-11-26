import type { PlaceLookup } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// Guest mode on the website (ADR-0032): nobody is asked to sign in outside the account page.
const guest: { uid: string; isAnonymous: boolean; displayName: string | null; email: string | null; phoneNumber: string | null } =
  { uid: "guest-1", isAnonymous: true, displayName: null, email: null, phoneNumber: null };
const auth = {
  user: guest as typeof guest | null, loading: false, isGuest: true, guestError: null as unknown,
  retryGuest: vi.fn(async () => undefined), signOut: vi.fn(async () => undefined),
  signInWithGoogle: vi.fn(async () => "linked"), signInWithApple: vi.fn(async () => "linked"),
  askWhereToDeliver: false, askedWhereToDeliver: vi.fn(),
};
let apple = false;
vi.mock("@/lib/auth", () => ({
  useAuth: () => auth,
  authErrorMessage: (e: Error) => e.message,
  get APPLE_SIGN_IN() { return apple; },
}));

const lookup: PlaceLookup = {
  place: {
    place_id: "ChIJ-admiralty", formatted_address: "5 Admiralty Way, Lekki Phase 1, Lagos", location: { lat: 6.4478, lng: 3.4723 },
    area: "Lekki Phase 1", city: "lagos", precision: "rooftop", source: "google",
  },
  serviceable: true, zone: "island", city: "lagos",
};
let saved: object[] = [];
const api = {
  me: {
    profile: vi.fn(async () => ({ allergens: [], dietary: [], personalisation_consent: true })),
    addresses: vi.fn(async () => saved),
    addAddress: vi.fn(async (a: object) => { const s = { id: "home-1", ...a }; saved = [s]; return s; }),
    deleteAddress: vi.fn(async () => undefined),
    updateProfile: vi.fn(),
  },
  wallet: { get: vi.fn(async () => ({ enabled: true, balance_kobo: 0 })) },
  places: { reverse: vi.fn(async () => lookup) },
  whatsapp: { status: vi.fn(async () => ({ enabled: false, linked: false })) },
  orders: { list: vi.fn(async () => []), summary: vi.fn(async () => ({ completed_count: 0 })) },
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  usePathname: () => "/account",
  useSearchParams: () => new URLSearchParams(),
}));
vi.mock("next/link", () => ({
  default: ({ href, children, className }: { href: string; children: React.ReactNode; className?: string }) =>
    <a href={href} className={className}>{children}</a>,
}));

const { RequireAuth } = await import("./require-auth");
const { Header } = await import("./header");
const { default: AccountPage } = await import("@/app/account/page");
const { default: OrdersPage } = await import("@/app/orders/page");
const { CartProvider } = await import("@/lib/cart");
const { LocationProvider } = await import("@/lib/location");

function show(page: React.ReactNode) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><LocationProvider><CartProvider>{page}</CartProvider></LocationProvider></QueryClientProvider>);
}

beforeEach(() => {
  auth.user = guest;
  auth.isGuest = true;
  auth.guestError = null;
  apple = false;
  saved = [];
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  Reflect.deleteProperty(navigator, "geolocation");
});

describe("no sign-in walls", () => {
  it("a guest gets the page straight away", () => {
    show(<RequireAuth><p>orders here</p></RequireAuth>);
    expect(screen.getByText("orders here")).toBeTruthy();
    expect(screen.queryByText(/Sign in/i)).toBeNull();
  });

  it("while the guest signs in it shows a skeleton, never a sign-in prompt", () => {
    auth.user = null;
    const view = show(<RequireAuth><p>orders here</p></RequireAuth>);
    expect(screen.queryByText("orders here")).toBeNull();
    expect(view.container.querySelector("[aria-busy='true']")).toBeTruthy();
    expect(screen.queryByText(/Sign in/i)).toBeNull();
  });

  it("when the guest sign-in fails it offers Try again", () => {
    auth.user = null;
    auth.guestError = new Error("offline");
    show(<RequireAuth><p>orders here</p></RequireAuth>);
    expect(screen.getByRole("heading", { name: "We can't connect right now" })).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(auth.retryGuest).toHaveBeenCalled();
  });

  it("a guest opens Orders with no sign-in prompt", async () => {
    show(<OrdersPage />);
    expect(screen.getByRole("heading", { name: "Orders" })).toBeTruthy();
    await waitFor(() => expect(api.orders.list).toHaveBeenCalled());
    expect(screen.queryByText(/Sign in/i)).toBeNull();
  });

  it("the header has no Sign in link; Profile goes to the account page", () => {
    show(<Header />);
    expect(screen.queryByText(/Sign in/i)).toBeNull();
    expect(screen.getByRole("link", { name: /Profile/ }).getAttribute("href")).toBe("/account");
  });
});

describe("account page", () => {
  it("a guest is offered to save the account with Google; Apple stays hidden until it is set up", async () => {
    show(<AccountPage />);
    expect(screen.getByRole("heading", { name: "You're ordering as a guest" })).toBeTruthy();
    expect(screen.getByRole("heading", { name: "Save your account" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Continue with Apple" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Sign out" })).toBeNull();
    expect(screen.getByRole("link", { name: "Other ways to sign in" }).getAttribute("href")).toBe("/login?next=%2Faccount");

    fireEvent.click(screen.getByRole("button", { name: "Continue with Google" }));
    await waitFor(() => expect(auth.signInWithGoogle).toHaveBeenCalledTimes(1));
  });

  it("shows Continue with Apple when NEXT_PUBLIC_APPLE_SIGN_IN is on", async () => {
    apple = true;
    show(<AccountPage />);
    fireEvent.click(screen.getByRole("button", { name: "Continue with Apple" }));
    await waitFor(() => expect(auth.signInWithApple).toHaveBeenCalledTimes(1));
  });

  it("says so when the Google account already existed and we signed in to it", async () => {
    auth.signInWithGoogle.mockResolvedValueOnce("switched");
    show(<AccountPage />);
    fireEvent.click(screen.getByRole("button", { name: "Continue with Google" }));
    expect(await screen.findByText(/You already had an account/)).toBeTruthy();
  });

  it("a saved account sees its details and Sign out, and no Save card", () => {
    auth.user = { ...guest, isAnonymous: false, displayName: "Ada Obi", email: "ada@example.com" };
    auth.isGuest = false;
    show(<AccountPage />);
    expect(screen.getByRole("heading", { name: "Ada Obi" })).toBeTruthy();
    expect(screen.getByText("ada@example.com")).toBeTruthy();
    expect(screen.queryByRole("heading", { name: "Save your account" })).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Sign out" }));
    expect(auth.signOut).toHaveBeenCalled();
  });

  it("Use my location saves the browser's position as Home and shows it with Change", async () => {
    const getCurrentPosition = vi.fn((ok: PositionCallback) => ok({ coords: { latitude: 6.448, longitude: 3.4724 } } as GeolocationPosition));
    Object.defineProperty(navigator, "geolocation", { value: { getCurrentPosition }, configurable: true });
    show(<AccountPage />);
    fireEvent.click(await screen.findByRole("button", { name: "Use my location" }));

    await waitFor(() => expect(api.me.addAddress).toHaveBeenCalledWith(expect.objectContaining({
      label: "Home", line1: "5 Admiralty Way, Lekki Phase 1, Lagos", area: "Lekki Phase 1",
      location: { lat: 6.448, lng: 3.4724 }, place_id: "ChIJ-admiralty",
    })));
    expect(api.places.reverse).toHaveBeenCalledWith({ lat: 6.448, lng: 3.4724 });
    expect(await screen.findByRole("button", { name: "Change" })).toBeTruthy();
    expect(screen.getAllByText(/5 Admiralty Way/).length).toBeGreaterThan(0);
  });
});
