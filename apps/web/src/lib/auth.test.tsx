import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, cleanup, render, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

interface FakeUser { uid: string; isAnonymous?: boolean; getIdToken: (force?: boolean) => Promise<string> }
const fakeUser = (uid: string, isAnonymous = false): FakeUser => ({ uid, isAnonymous, getIdToken: vi.fn(async () => "token") });

let tell: (user: FakeUser | null) => void = () => undefined;
const fakeAuth = { currentUser: null as FakeUser | null };
const fb = vi.hoisted(() => ({
  signInAnonymously: vi.fn(),
  linkWithPopup: vi.fn(),
  linkWithCredential: vi.fn(),
  signInWithCredential: vi.fn(),
  signInWithPopup: vi.fn(),
  createUserWithEmailAndPassword: vi.fn(),
  updateProfile: vi.fn(),
  credentialFromError: vi.fn(),
}));
vi.mock("firebase/auth", () => ({
  onIdTokenChanged: (_auth: unknown, listener: typeof tell) => { tell = listener; return () => undefined; },
  GoogleAuthProvider: class { static credentialFromError = fb.credentialFromError; },
  OAuthProvider: class { constructor(public id: string) {} static credentialFromError = fb.credentialFromError; },
  EmailAuthProvider: { credential: (email: string, password: string) => ({ email, password }) },
  createUserWithEmailAndPassword: fb.createUserWithEmailAndPassword, signInWithEmailAndPassword: vi.fn(),
  signInWithPopup: fb.signInWithPopup, signOut: vi.fn(), updateProfile: fb.updateProfile,
  signInAnonymously: fb.signInAnonymously, linkWithPopup: fb.linkWithPopup, linkWithCredential: fb.linkWithCredential,
  signInWithCredential: fb.signInWithCredential,
}));
vi.mock("./firebase", () => ({ firebaseAuth: () => fakeAuth }));

const { AuthProvider, useAuth } = await import("./auth");

let auth: ReturnType<typeof useAuth>;
function Probe() {
  auth = useAuth();
  return <p>{auth.isGuest ? "guest" : auth.user ? "saved" : "nobody"}</p>;
}
function show(qc = new QueryClient()) {
  return render(<QueryClientProvider client={qc}><AuthProvider><Probe /></AuthProvider></QueryClientProvider>);
}

afterEach(() => {
  cleanup();
  fakeAuth.currentUser = null;
  Object.values(fb).forEach((f) => f.mockReset());
});

describe("what one account loaded never shows to the next", () => {
  it("clears everything kept in memory when another account signs in or the account signs out", () => {
    fb.signInAnonymously.mockReturnValue(new Promise(() => undefined));
    const qc = new QueryClient();
    show(qc);
    const kept = () => qc.getQueryData(["addresses"]);

    act(() => tell(fakeUser("ada"))); // the first answer from Firebase
    qc.setQueryData(["addresses"], ["Ada's home"]);
    act(() => tell(fakeUser("ada"))); // a refreshed token for the same account
    expect(kept()).toEqual(["Ada's home"]);

    act(() => tell(null)); // signed out
    expect(kept()).toBeUndefined();

    qc.setQueryData(["addresses"], ["seen while signed out"]);
    act(() => tell(fakeUser("bayo"))); // someone else signs in
    expect(kept()).toBeUndefined();
  });
});

describe("guest mode (ADR-0032)", () => {
  it("signs in a guest by itself when nobody is signed in, and asks where to deliver once", async () => {
    fb.signInAnonymously.mockImplementation(async () => {
      fakeAuth.currentUser = fakeUser("guest-1", true);
      tell(fakeAuth.currentUser);
    });
    const view = show();
    act(() => tell(null));
    await waitFor(() => expect(view.getByText("guest")).toBeTruthy());
    expect(fb.signInAnonymously).toHaveBeenCalledTimes(1);
    expect(auth.askWhereToDeliver).toBe(true);
    act(() => auth.askedWhereToDeliver());
    expect(auth.askWhereToDeliver).toBe(false);
  });

  it("reports a failed guest sign-in, and Try again signs in", async () => {
    fb.signInAnonymously.mockRejectedValueOnce(Object.assign(new Error("offline"), { code: "auth/network-request-failed" }));
    show();
    act(() => tell(null));
    await waitFor(() => expect(auth.guestError).toBeTruthy());

    fb.signInAnonymously.mockImplementation(async () => {
      fakeAuth.currentUser = fakeUser("guest-2", true);
      tell(fakeAuth.currentUser);
    });
    await act(() => auth.retryGuest());
    expect(auth.guestError).toBeNull();
    expect(auth.isGuest).toBe(true);
  });

  it("Continue with Google links Google to the guest, so the account keeps its orders", async () => {
    const guest = fakeUser("guest-1", true);
    fakeAuth.currentUser = guest;
    fb.linkWithPopup.mockImplementation(async () => { guest.isAnonymous = false; });
    const view = show();
    act(() => tell(guest));
    let result: string | undefined;
    await act(async () => { result = await auth.signInWithGoogle(); });
    expect(fb.linkWithPopup).toHaveBeenCalledWith(guest, expect.anything());
    expect(fb.signInWithPopup).not.toHaveBeenCalled();
    expect(result).toBe("linked");
    expect(view.getByText("saved")).toBeTruthy();
  });

  it("signs in to the Google account instead when it already exists", async () => {
    const guest = fakeUser("guest-1", true);
    fakeAuth.currentUser = guest;
    const error = Object.assign(new Error("in use"), { code: "auth/credential-already-in-use" });
    fb.linkWithPopup.mockRejectedValue(error);
    fb.credentialFromError.mockReturnValue({ providerId: "google.com" });
    show();
    act(() => tell(guest));
    let result: string | undefined;
    await act(async () => { result = await auth.signInWithGoogle(); });
    expect(fb.credentialFromError).toHaveBeenCalledWith(error);
    expect(fb.signInWithCredential).toHaveBeenCalledWith(fakeAuth, { providerId: "google.com" });
    expect(result).toBe("switched");
  });

  it("Continue with Apple links the Apple provider the same way", async () => {
    const guest = fakeUser("guest-1", true);
    fakeAuth.currentUser = guest;
    show();
    act(() => tell(guest));
    await act(async () => { await auth.signInWithApple(); });
    expect(fb.linkWithPopup).toHaveBeenCalledWith(guest, expect.objectContaining({ id: "apple.com" }));
  });

  it("an email sign-up from a guest links the email instead of making a new account", async () => {
    const guest = fakeUser("guest-1", true);
    fakeAuth.currentUser = guest;
    fb.linkWithCredential.mockResolvedValue({ user: guest });
    show();
    act(() => tell(guest));
    await act(() => auth.signUp("Ada", "ada@example.com", "secret1"));
    expect(fb.linkWithCredential).toHaveBeenCalledWith(guest, { email: "ada@example.com", password: "secret1" });
    expect(fb.createUserWithEmailAndPassword).not.toHaveBeenCalled();
    expect(fb.updateProfile).toHaveBeenCalledWith(guest, { displayName: "Ada" });
  });
});
