import { describe, expect, it } from "vitest";
import { ApiError, createApi, formatDayLabel, formatNaira, idempotentCalls, ORDER_STATUS } from "./index";

function mockFetch(status: number, body: unknown, seen: Request[] = []) {
  return (async (input: URL | RequestInfo, init?: RequestInit) => {
    seen.push(new Request(input as URL, init));
    return new Response(body === undefined ? null : JSON.stringify(body), { status });
  }) as typeof fetch;
}

describe("formatNaira", () => {
  it("formats kobo as naira", () => {
    expect(formatNaira(1_000_000)).toBe("₦10,000");
    expect(formatNaira(150_050)).toBe("₦1,500.50");
    expect(formatNaira(-500)).toBe("-₦5");
    expect(formatNaira(null)).toBe("—");
  });
  it("labels chart days day-first, independent of the viewer's timezone", () => {
    expect(formatDayLabel("2026-11-02")).toBe("2 Nov");
    expect(formatDayLabel("2026-01-31T23:30:00Z")).toBe("31 Jan");
    expect(formatDayLabel("not-a-date")).toBe("not-a-date");
  });
  it("labels every order status", () => {
    expect(Object.keys(ORDER_STATUS)).toHaveLength(17);
  });
});

describe("createApi", () => {
  it("sends auth, idempotency and query parameters", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test/", getToken: async () => "tok", fetchImpl: mockFetch(201, { id: "o1" }, seen) });
    await api.orders.create("q1", "key-12345678");
    const req = seen[0]!;
    expect(req.url).toBe("http://api.test/v1/orders");
    expect(req.headers.get("authorization")).toBe("Bearer tok");
    expect(req.headers.get("idempotency-key")).toBe("key-12345678");
    expect(await req.json()).toEqual({ quote_id: "q1", channel: "web" });

    await api.partner.orders("r1", ["submitted_to_restaurant", "preparing"]);
    expect(seen[1]!.url).toBe("http://api.test/v1/partner/restaurants/r1/orders?status=submitted_to_restaurant&status=preparing&limit=100");
  });

  it("does not send tokens to public catalog endpoints", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch(200, [], seen) });
    await api.catalog.restaurants({ lat: 6.4, lng: 3.4 });
    expect(seen[0]!.headers.get("authorization")).toBeNull();
  });

  it("reads the Discover dish feed publicly, near the chosen area", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch(200, { city: "lagos", sections: [] }, seen) });
    await api.catalog.discover({ city: "lagos", lat: 6.4281, lng: 3.4219, limit: 8 });
    expect(seen[0]!.url).toBe("http://api.test/v1/discover/dishes?city=lagos&lat=6.4281&lng=3.4219&limit=8");
    expect(seen[0]!.headers.get("authorization")).toBeNull();
  });

  it("maps API errors", async () => {
    const api = createApi({ baseUrl: "http://api.test", fetchImpl: mockFetch(409, { error: { code: "price_changed", message: "Prices changed" } }) });
    await expect(api.orders.get("x")).rejects.toMatchObject({ status: 409, code: "price_changed", message: "Prices changed" });
    await expect(api.orders.get("x")).rejects.toBeInstanceOf(ApiError);
  });

  it("turns an answer that is not JSON (an error page from the host) into a plain error", async () => {
    const page = (status: number) => (async () => new Response("<html><body>502 Bad Gateway</body></html>", { status })) as typeof fetch;
    const api = createApi({ baseUrl: "http://api.test", fetchImpl: page(502) });
    const error = await api.orders.get("x").catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({ status: 502, code: "bad_response", message: "Yummy Chops sent an answer we couldn't read. Please try again in a moment." });
    // The same for a page that says 200 (a Wi-Fi sign-in page, for example): never the parser's own message.
    const portal = createApi({ baseUrl: "http://api.test", fetchImpl: page(200) });
    await expect(portal.orders.get("x")).rejects.toMatchObject({ status: 200, code: "bad_response" });
  });
});

describe("idempotentCalls", () => {
  const refused = new ApiError(409, "quote_expired", "Your price quote expired");
  /** Calls `send` and gives back the key it used, whatever the outcome. */
  async function keyOf(send: ReturnType<typeof idempotentCalls>, body: unknown, outcome: "ok" | ApiError | Error = "ok") {
    let used = "";
    await send(body, async (key) => {
      used = key;
      if (outcome !== "ok") throw outcome;
      return "done";
    }).catch(() => undefined);
    return used;
  }

  it("keeps the key for the same request after a network error, a server failure or an unreadable answer", async () => {
    const send = idempotentCalls("order");
    const first = await keyOf(send, { quote: "q1" }, new ApiError(0, "network_error", "offline"));
    expect(first).toMatch(/^order-[a-z0-9]{8,}$/);
    expect(await keyOf(send, { quote: "q1" }, new ApiError(503, "error", "down"))).toBe(first);
    expect(await keyOf(send, { quote: "q1" }, new ApiError(502, "bad_response", "unreadable"))).toBe(first);
    expect(await keyOf(send, { quote: "q1" }, new Error("the page broke before the answer was read"))).toBe(first);
    expect(await keyOf(send, { quote: "q1" })).toBe(first); // the retry that gets through still uses it
  });

  it("uses a new key after the API refused the request (4xx), so the refusal is not repeated", async () => {
    const send = idempotentCalls("order");
    const first = await keyOf(send, { quote: "q1" }, refused);
    const second = await keyOf(send, { quote: "q1" });
    expect(second).not.toBe(first);
  });

  it("uses a new key when the request body changes, even after a network error", async () => {
    const send = idempotentCalls("topup");
    const first = await keyOf(send, { kobo: 100_000 }, new ApiError(0, "network_error", "offline"));
    const second = await keyOf(send, { kobo: 200_000 }, new ApiError(0, "network_error", "offline"));
    expect(second).not.toBe(first);
    expect(await keyOf(send, { kobo: 200_000 })).toBe(second);
  });

  it("uses a new key after a request that went through: doing the same thing again is a new request", async () => {
    const send = idempotentCalls("redeem");
    const first = await keyOf(send, { points: 500 });
    expect(await keyOf(send, { points: 500 })).not.toBe(first);
  });

  it("gives back the answer and passes errors on", async () => {
    const send = idempotentCalls();
    await expect(send({ a: 1 }, async () => 42)).resolves.toBe(42);
    await expect(send({ a: 1 }, async () => { throw refused; })).rejects.toBe(refused);
  });
});

describe("growth calls", () => {
  it("sends Plus, rewards and group-order requests with idempotency keys where money moves", async () => {
    const seen: Request[] = [];
    const api = createApi({ baseUrl: "http://api.test", getToken: async () => "tok", fetchImpl: mockFetch(200, {}, seen) });
    await api.plus.subscribe("plus-key-0001", "wallet");
    await api.rewards.redeem(500, "redeem-key-01");
    await api.groups.join("ab3k7p");
    await api.groups.pay("g1", "pay-key-00001", { cover_rest: true });
    await api.groups.removeMember("g1", "cust-2");
    const [plus, redeem, join, pay, remove] = seen;
    expect(plus!.headers.get("idempotency-key")).toBe("plus-key-0001");
    expect(await plus!.json()).toEqual({ provider: "wallet", auto_renew: true });
    expect([redeem!.url, await redeem!.json()]).toEqual(["http://api.test/v1/rewards/redeem", { points: 500 }]);
    expect(join!.url).toBe("http://api.test/v1/group-orders/join");
    expect(await pay!.json()).toEqual({ cover_rest: true });
    expect(pay!.headers.get("idempotency-key")).toBe("pay-key-00001");
    expect([remove!.method, remove!.url]).toEqual(["DELETE", "http://api.test/v1/group-orders/g1/members/cust-2"]);
  });
});

