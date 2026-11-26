import { cleanup, render, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const auth = { user: { uid: "guest-1" } as { uid: string } | null, askWhereToDeliver: true, askedWhereToDeliver: vi.fn() };
const addresses = vi.fn(async () => [] as object[]);
const replace = vi.fn();
let path = "/";
vi.mock("@/lib/auth", () => ({ useAuth: () => auth }));
vi.mock("@/lib/api", () => ({ useApi: () => ({ me: { addresses } }) }));
vi.mock("next/navigation", () => ({ useRouter: () => ({ replace }), usePathname: () => path }));

const { WhereToDeliverPrompt } = await import("./where-to-deliver-prompt");

beforeEach(() => {
  auth.user = { uid: "guest-1" };
  auth.askWhereToDeliver = true;
  path = "/";
});
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("Where should we deliver? prompt", () => {
  it("asks a fresh guest with no saved address once, from the page they are on", async () => {
    path = "/restaurants";
    render(<WhereToDeliverPrompt />);
    expect(auth.askedWhereToDeliver).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/where-to-deliver?next=%2Frestaurants"));
  });

  it("waits on pages where it would get in the way", () => {
    path = "/checkout/callback";
    render(<WhereToDeliverPrompt />);
    expect(auth.askedWhereToDeliver).not.toHaveBeenCalled();
    expect(addresses).not.toHaveBeenCalled();
  });

  it("never sends a guest away from the cart or checkout, and still asks later on another page", async () => {
    for (const p of ["/cart", "/checkout", "/checkout/callback"]) {
      path = p;
      const view = render(<WhereToDeliverPrompt />);
      expect(auth.askedWhereToDeliver).not.toHaveBeenCalled();
      expect(addresses).not.toHaveBeenCalled();
      view.unmount();
    }
    path = "/orders";
    render(<WhereToDeliverPrompt />);
    expect(auth.askedWhereToDeliver).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(replace).toHaveBeenCalledWith("/where-to-deliver?next=%2Forders"));
  });

  it("on the question itself counts as asked, so “Not now” does not bring it back", () => {
    path = "/where-to-deliver";
    render(<WhereToDeliverPrompt />);
    expect(auth.askedWhereToDeliver).toHaveBeenCalledTimes(1);
    expect(addresses).not.toHaveBeenCalled();
    expect(replace).not.toHaveBeenCalled();
  });
});
