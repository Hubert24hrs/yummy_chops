import { describe, expect, it } from "vitest";
import { safeNext } from "./next-path";

/** `next` as the sign-in page reads it from a link such as /login?next=... */
const fromLink = (query: string) => new URLSearchParams(query).get("next");

describe("where to go after signing in", () => {
  it("keeps paths on this site, with their query and fragment", () => {
    expect(safeNext("/orders")).toBe("/orders");
    expect(safeNext("/orders/o1/receipt")).toBe("/orders/o1/receipt");
    expect(safeNext("/checkout/callback?order_id=o1&reference=YC-ABC123")).toBe("/checkout/callback?order_id=o1&reference=YC-ABC123");
    expect(safeNext("/food?category=promotions#top")).toBe("/food?category=promotions#top");
    expect(safeNext(fromLink("next=%2Fgroup%3Fcode%3DAB3K7P"))).toBe("/group?code=AB3K7P");
  });

  it("goes home when there is nothing to go to", () => {
    expect(safeNext(null)).toBe("/");
    expect(safeNext(undefined)).toBe("/");
    expect(safeNext("")).toBe("/");
  });

  it("never leaves the site: other hosts and schemes go home", () => {
    for (const next of ["//evil.example", "//evil.example/orders", "https://evil.example", "http://evil.example/x", "javascript:alert(1)", "evil.example", "orders"]) {
      expect(safeNext(next), next).toBe("/");
    }
  });

  it("a backslash counts as a slash, as browsers read it", () => {
    for (const next of ["/\\evil.example", "/\\/evil.example", "\\\\evil.example", "/\\\\evil.example/orders"]) {
      expect(safeNext(next), JSON.stringify(next)).toBe("/");
    }
    expect(safeNext(fromLink("next=%2F%5Cevil.example"))).toBe("/");
  });

  it("a tab or line break inside the path does not hide another host (browsers drop them)", () => {
    for (const next of ["/\t/evil.example", "/\n/evil.example", "/\r/evil.example", "/\r\n/evil.example", "/\t\\evil.example", "/\t\t/evil.example/orders"]) {
      expect(safeNext(next), JSON.stringify(next)).toBe("/");
    }
    // As a link would carry them: /login?next=%2F%09%2Fevil.example
    expect(safeNext(fromLink("next=%2F%09%2Fevil.example"))).toBe("/");
    expect(safeNext(fromLink("next=%2F%0A%2Fevil.example"))).toBe("/");
    expect(safeNext(fromLink("next=%2F%0D%2Fevil.example"))).toBe("/");
  });

  it("a tab inside an ordinary path is simply dropped", () => {
    expect(safeNext("/or\tders")).toBe("/orders");
  });
});
