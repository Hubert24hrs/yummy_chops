import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { act, cleanup, render } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

let tell: (user: { uid: string } | null) => void = () => undefined;
vi.mock("firebase/auth", () => ({
  onIdTokenChanged: (_auth: unknown, listener: typeof tell) => { tell = listener; return () => undefined; },
  GoogleAuthProvider: class {}, createUserWithEmailAndPassword: vi.fn(), signInWithEmailAndPassword: vi.fn(),
  signInWithPopup: vi.fn(), signOut: vi.fn(), updateProfile: vi.fn(),
}));
vi.mock("./firebase", () => ({ firebaseAuth: () => ({ currentUser: null }) }));

const { AuthProvider } = await import("./auth");

afterEach(cleanup);

describe("what one account loaded never shows to the next", () => {
  it("clears everything kept in memory when another account signs in or the account signs out", () => {
    const qc = new QueryClient();
    render(<QueryClientProvider client={qc}><AuthProvider><p>page</p></AuthProvider></QueryClientProvider>);
    const kept = () => qc.getQueryData(["addresses"]);

    act(() => tell({ uid: "ada" })); // the first answer from Firebase
    qc.setQueryData(["addresses"], ["Ada's home"]);
    act(() => tell({ uid: "ada" })); // a refreshed token for the same account
    expect(kept()).toEqual(["Ada's home"]);

    act(() => tell(null)); // signed out
    expect(kept()).toBeUndefined();

    qc.setQueryData(["addresses"], ["seen while signed out"]);
    act(() => tell({ uid: "bayo" })); // someone else signs in
    expect(kept()).toBeUndefined();
  });
});
