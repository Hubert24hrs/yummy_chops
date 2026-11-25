import { afterEach, describe, expect, it, vi } from "vitest";

const calls: string[] = [];
const auth = { name: "auth" };
const setPersistence = vi.fn(async (..._args: unknown[]) => { calls.push("setPersistence"); });
const connectAuthEmulator = vi.fn((..._args: unknown[]) => { calls.push("connectAuthEmulator"); });
vi.mock("firebase/app", () => ({ getApps: () => [], getApp: vi.fn(), initializeApp: () => ({}) }));
vi.mock("firebase/app-check", () => ({ getToken: vi.fn(), initializeAppCheck: vi.fn(), ReCaptchaEnterpriseProvider: class {} }));
vi.mock("firebase/auth", () => ({ getAuth: () => auth, connectAuthEmulator, setPersistence, browserSessionPersistence: "SESSION" }));

async function load(emulators: boolean) {
  vi.resetModules();
  vi.stubEnv("NEXT_PUBLIC_USE_FIREBASE_EMULATORS", emulators ? "true" : "");
  return (await import("./firebase")).firebaseAuth;
}

afterEach(() => {
  vi.unstubAllEnvs();
  vi.clearAllMocks();
  calls.length = 0;
});

describe("the Command Centre's sign-in", () => {
  it("lasts only while the browser is open", async () => {
    const firebaseAuth = await load(false);
    expect(firebaseAuth()).toBe(auth);
    expect(setPersistence).toHaveBeenCalledWith(auth, "SESSION");
    expect(connectAuthEmulator).not.toHaveBeenCalled();
    firebaseAuth();
    expect(setPersistence).toHaveBeenCalledTimes(1); // set once, not on every use
  });

  it("still uses the sign-in emulator locally, connected before anything else", async () => {
    (await load(true))();
    expect(calls).toEqual(["connectAuthEmulator", "setPersistence"]);
    expect(connectAuthEmulator).toHaveBeenCalledWith(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  });
});
