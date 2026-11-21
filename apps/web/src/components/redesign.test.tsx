import type { RestaurantCard } from "@gudmeal/api-client";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const push = vi.fn();
vi.mock("next/navigation", () => ({
  useRouter: () => ({ push, back: vi.fn(), replace: vi.fn() }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));

const { ServiceBubbles } = await import("./service-bubbles");
const { routeForScreen } = await import("@/app/assistant/chat");
const { deliveryLabel, ratingPercent } = await import("./storefront");

const card = (over: Partial<RestaurantCard> = {}): RestaurantCard => ({
  id: "r1", vertical: "food", city: "lagos", promotions: [], name: "Jollof Junction", slug: "jj", description: "",
  cuisines: ["Nigerian"], tags: [], image_url: null, cover_url: null, area: "Lekki", rating: 4.7, rating_count: 100,
  price_level: 2, is_open: true, is_accepting_orders: true, is_featured: false, next_opening_at: null, distance_km: 2,
  eta_minutes: 30, delivery_fee_kobo: 90_000, min_order_kobo: 0, supports_delivery: true, supports_pickup: true,
  delivers_to_location: true, ...over,
});

describe("service bubbles", () => {
  beforeEach(() => push.mockClear());
  afterEach(cleanup);
  const bubbles = [
    { id: "food", label: "Order Food", href: "/food", art: <svg /> },
    { id: "beauty", label: "Beauty & Skin Care", href: "/beauty", art: <svg /> },
    { id: "parcel", label: "Package Delivery", href: "/send", art: <svg /> },
  ];

  it("renders each service as a real link (keyboard and search-engine friendly)", () => {
    render(<ServiceBubbles bubbles={bubbles} />);
    expect(screen.getByRole("link", { name: "Order Food" }).getAttribute("href")).toBe("/food");
    expect(screen.getByRole("link", { name: "Beauty & Skin Care" }).getAttribute("href")).toBe("/beauty");
    expect(screen.getByRole("link", { name: "Package Delivery" }).getAttribute("href")).toBe("/send");
  });

  it("shows six services in two rows, each a link to its page", () => {
    const six = [
      { id: "food", label: "Order Food", href: "/food", art: <svg /> },
      { id: "pharmacy", label: "Pharmacy", href: "/pharmacy", art: <svg /> },
      { id: "beauty", label: "Beauty & Skin Care", href: "/beauty", art: <svg /> },
      { id: "grocery", label: "Shop & Groceries", href: "/groceries", art: <svg /> },
      { id: "market", label: "Buy Foodstuff", href: "/foodstuff", art: <svg /> },
      { id: "parcel", label: "Package Delivery", href: "/send", art: <svg /> },
    ];
    render(<ServiceBubbles bubbles={six} height={372} />);
    expect(screen.getAllByRole("link").map((a) => a.getAttribute("href"))).toEqual(["/food", "/pharmacy", "/beauty", "/groceries", "/foodstuff", "/send"]);
    fireEvent.click(screen.getByRole("link", { name: "Buy Foodstuff" }));
    expect(push).toHaveBeenCalledWith("/foodstuff");
    // Long names wrap to two even lines instead of covering the next bubble; "&" never starts a line.
    const label = screen.getByRole("link", { name: "Beauty & Skin Care" }).lastElementChild as HTMLElement;
    expect(label.textContent).toBe("Beauty & Skin Care");
    expect(label.className).toContain("text-balance");
    expect(label.className).not.toContain("whitespace-nowrap");
  });

  it("a tap opens the service, a drag does not", () => {
    render(<ServiceBubbles bubbles={bubbles} />);
    const food = screen.getByRole("link", { name: "Order Food" });
    fireEvent.click(food);
    expect(push).toHaveBeenCalledWith("/food");

    push.mockClear();
    const parcel = screen.getByRole("link", { name: "Package Delivery" });
    parcel.setPointerCapture = () => undefined;
    fireEvent.pointerDown(parcel, { pointerId: 7, button: 0, clientX: 100, clientY: 100 });
    fireEvent.pointerMove(parcel, { pointerId: 7, clientX: 160, clientY: 150 });
    fireEvent.pointerUp(parcel, { pointerId: 7, clientX: 160, clientY: 150 });
    fireEvent.click(parcel);
    expect(push).not.toHaveBeenCalled();
  });
});

describe("Yummy navigation and store labels", () => {
  it("maps open_screen cards to website routes", () => {
    expect(routeForScreen("parcel")).toBe("/send");
    expect(routeForScreen("wallet")).toBe("/wallet");
    expect(routeForScreen("food", { category: "local" })).toBe("/food?category=local");
    expect(routeForScreen("beauty", { category: "makeup" })).toBe("/beauty?category=makeup");
    expect(routeForScreen("grocery")).toBe("/groceries");
    expect(routeForScreen("pharmacy", { category: "pain" })).toBe("/pharmacy?category=pain");
    expect(routeForScreen("market", { category: "combos" })).toBe("/foodstuff?category=combos");
    expect(routeForScreen("merchant", { merchant_id: "b-shea" })).toBe("/restaurants/b-shea");
    expect(routeForScreen("order", { order_id: "o1" })).toBe("/orders/o1");
    expect(routeForScreen("profile")).toBe("/account");
    expect(routeForScreen("merchant")).toBeNull();
  });

  it("formats ratings and delivery fees like the app", () => {
    expect(ratingPercent(4.8)).toBe("96%");
    expect(deliveryLabel(card())).toBe("₦900");
    expect(deliveryLabel(card({ delivery_fee_kobo: 0 }))).toBe("Free delivery");
    expect(deliveryLabel(card({ delivers_to_location: false }))).toBe("Pickup only");
  });
});
