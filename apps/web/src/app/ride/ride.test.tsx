import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const api = { applications: { rider: vi.fn(async (body: object) => ({ id: "app-1", ...body })) } };
const auth = {
  user: { uid: "u1", email: "bayo@gmail.com", displayName: "Bayo Rider" },
  loading: false,
  signIn: vi.fn(),
  signUp: vi.fn(),
  signInWithGoogle: vi.fn(),
  refreshToken: vi.fn(async () => undefined),
};
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("@/lib/auth", () => ({ useAuth: () => auth, authErrorMessage: (e: Error) => e.message }));
vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: vi.fn(), push: vi.fn() }),
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => "/ride",
}));

const { default: RidePage } = await import("./page");
const { default: GuarantorFormPage } = await import("./guarantor-form/page");

function show(page: React.ReactNode) {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}>{page}</QueryClientProvider>);
}

afterEach(() => {
  cleanup();
  api.applications.rider.mockClear();
});

describe("Become our rider (docs/adr/0027-rider-kyc.md)", () => {
  it("asks for the sign-up details, sends them, then points to the KYC in the rider app", async () => {
    show(<RidePage />);
    expect(screen.getByRole("heading", { name: "Become our rider" })).toBeTruthy();
    expect((screen.getByLabelText("Full name") as HTMLInputElement).value).toBe("Bayo Rider"); // from the account
    expect((screen.getByLabelText("Email") as HTMLInputElement).value).toBe("bayo@gmail.com");
    fireEvent.change(screen.getByLabelText("WhatsApp phone number"), { target: { value: "+2348033333333" } });
    fireEvent.change(screen.getByLabelText("Residential address"), { target: { value: "12 Admiralty Way, Lekki" } });
    fireEvent.click(screen.getByRole("button", { name: "Sign up as a rider" }));
    await waitFor(() =>
      expect(api.applications.rider).toHaveBeenCalledWith({
        full_name: "Bayo Rider",
        phone: "+2348033333333",
        email: "bayo@gmail.com",
        residential_address: "12 Admiralty Way, Lekki",
        vehicle: "motorcycle",
        city: "Lagos",
      }),
    );
    expect(await screen.findByRole("heading", { name: "You're signed up" })).toBeTruthy();
    expect(auth.refreshToken).toHaveBeenCalled(); // the KYC needs a token that says "rider"
    expect(screen.getByRole("link", { name: "Complete your KYC" }).getAttribute("href")).toBe("/ride/kyc");
    expect(screen.getAllByRole("link", { name: /Print the guarantor form/ }).length).toBeGreaterThan(0);
  });

  it("does not sign up without a WhatsApp number and an address", async () => {
    show(<RidePage />);
    fireEvent.click(screen.getByRole("button", { name: "Sign up as a rider" }));
    expect(await screen.findByText("Enter your WhatsApp number")).toBeTruthy();
    expect(screen.getByText("Enter where you live")).toBeTruthy();
    expect(api.applications.rider).not.toHaveBeenCalled();
  });

  it("prints a guarantor form with the guarantor's details, the declaration and a signature line", () => {
    show(<GuarantorFormPage />);
    expect(screen.getByRole("heading", { name: "Rider guarantor form" })).toBeTruthy();
    for (const label of ["Rider's full name", "Occupation", "Home address", "Relationship to the rider", "Guarantor's signature"]) {
      expect(screen.getByText(label)).toBeTruthy();
    }
    expect(screen.getByRole("button", { name: /Print the form/ })).toBeTruthy();
  });
});
