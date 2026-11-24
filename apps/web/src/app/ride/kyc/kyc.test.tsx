import { ApiError, type RiderKyc } from "@gudmeal/api-client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const KINDS = ["plate_number", "hackney_permit", "riders_card", "bike", "guarantor_1_form", "guarantor_2_form", "face"];
function kycOf(over: Partial<RiderKyc> = {}): RiderKyc {
  return {
    uid: "u1", status: "draft", full_name: "Bayo Rider", whatsapp_phone: "+2348033333333", email: "bayo@gmail.com",
    residential_address: "12 Admiralty Way, Lekki", permanent_address: "", nin: "",
    documents: Object.fromEntries(KINDS.map((k) => [k, { label: k, uploaded: false, content_type: null, uploaded_at: null, needs_change: false }])),
    guarantors: [0, 1].map(() => ({ name: "", phone: "", email: "", address: "", occupation: "" })),
    submitted_at: null, reviewed_at: null, reviewed_by: null, review_note: null, changes_needed: [],
    missing: ["permanent address", "NIN"], editable: true,
    ...over,
  };
}

const api = {
  riderKyc: {
    get: vi.fn(async () => kycOf()),
    update: vi.fn(async (d: object) => kycOf(d as Partial<RiderKyc>)),
    upload: vi.fn(async (_kind: string, _data: string) => kycOf()),
    document: vi.fn(),
    submit: vi.fn(async () => kycOf({ status: "submitted", editable: false, missing: [] })),
  },
};
const auth = { user: { uid: "u1" }, loading: false, refreshToken: vi.fn(async () => undefined), signIn: vi.fn(), signUp: vi.fn(), signInWithGoogle: vi.fn() };
vi.mock("@/lib/api", () => ({ useApi: () => api }));
vi.mock("@/lib/auth", () => ({ useAuth: () => auth, authErrorMessage: (e: Error) => e.message }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ replace: vi.fn(), push: vi.fn() }), useSearchParams: () => new URLSearchParams(), usePathname: () => "/ride/kyc" }));

const { default: RiderKycPage } = await import("./page");

function show() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={qc}><RiderKycPage /></QueryClientProvider>);
}

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  api.riderKyc.get.mockImplementation(async () => kycOf());
});

describe("A rider's KYC on the website (docs/adr/0027-rider-kyc.md)", () => {
  it("shows what is left, uploads a photo and submits the typed details", async () => {
    show();
    expect(await screen.findByRole("heading", { name: "Complete your KYC" })).toBeTruthy();
    expect(screen.getByText(/2 things still to do: permanent address, NIN/)).toBeTruthy();

    const photo = new File([new Uint8Array([0xff, 0xd8, 0xff, 0xe0])], "plate.jpg", { type: "image/jpeg" });
    fireEvent.change(screen.getByLabelText("Upload: plate_number"), { target: { files: [photo] } });
    await waitFor(() => expect(api.riderKyc.upload).toHaveBeenCalledTimes(1));
    const [kind, data] = api.riderKyc.upload.mock.calls[0]!;
    expect(kind).toBe("plate_number");
    expect(data).toMatch(/^data:image\/jpeg;base64,/);

    fireEvent.change(screen.getByLabelText("Permanent address"), { target: { value: "4 Ogui Road, Enugu" } });
    fireEvent.change(screen.getByLabelText("NIN (National Identification Number)"), { target: { value: "1234 5678 901" } });
    fireEvent.change(screen.getAllByLabelText("Full name")[0]!, { target: { value: "Ada Obi" } });
    fireEvent.click(screen.getByRole("button", { name: "Submit for checking" }));
    await waitFor(() => expect(api.riderKyc.submit).toHaveBeenCalled());
    const saved = api.riderKyc.update.mock.calls[0]![0] as { permanent_address: string; nin: string; guarantors: { name: string }[] };
    expect(saved.permanent_address).toBe("4 Ogui Road, Enugu");
    expect(saved.nin).toBe("12345678901"); // digits only
    expect(saved.guarantors[0]!.name).toBe("Ada Obi");
    expect(await screen.findByRole("heading", { name: "With the team for review" })).toBeTruthy();
  });

  it("a rider who signed up a moment ago gets a fresh sign-in token, then their KYC", async () => {
    api.riderKyc.get.mockRejectedValueOnce(new ApiError(403, "forbidden", "Riders only"));
    show();
    expect(await screen.findByRole("heading", { name: "Complete your KYC" })).toBeTruthy();
    expect(auth.refreshToken).toHaveBeenCalledTimes(1);
  });

  it("an account that is not a rider is sent to sign up", async () => {
    api.riderKyc.get.mockRejectedValue(new ApiError(403, "forbidden", "Riders only"));
    show();
    expect(await screen.findByText("This account is not a rider yet.")).toBeTruthy();
    expect(screen.getByRole("link", { name: "Sign up as a rider first" }).getAttribute("href")).toBe("/ride");
  });

  it("the team's note and the items to redo show when changes are asked", async () => {
    api.riderKyc.get.mockImplementation(async () =>
      kycOf({ status: "needs_changes", review_note: "The plate number photo is blurred",
        documents: { ...kycOf().documents, plate_number: { label: "Plate number", uploaded: true, content_type: "image/jpeg", uploaded_at: null, needs_change: true } } }));
    show();
    expect(await screen.findByRole("heading", { name: "Please fix your KYC" })).toBeTruthy();
    expect(screen.getByText("The plate number photo is blurred")).toBeTruthy();
    expect(screen.getByText("Please upload this again")).toBeTruthy();
  });
});
