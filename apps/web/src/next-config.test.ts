import { afterEach, describe, expect, it, vi } from "vitest";

async function load(project?: string) {
  vi.resetModules();
  if (project) vi.stubEnv("NEXT_PUBLIC_FIREBASE_PROJECT_ID", project);
  else vi.stubEnv("NEXT_PUBLIC_FIREBASE_PROJECT_ID", "");
  return (await import("../next.config")).default;
}

afterEach(() => vi.unstubAllEnvs());

describe("the website's Next.js settings", () => {
  it("sends the security headers and does not say what the site runs on", async () => {
    const config = await load();
    expect(config.poweredByHeader).toBe(false);
    const headers = Object.fromEntries((await config.headers!())[0]!.headers.map((h) => [h.key, h.value]));
    expect(headers["Strict-Transport-Security"]).toBe("max-age=63072000");
    expect(headers["Content-Security-Policy"]).toBe("base-uri 'self'; object-src 'none'; frame-ancestors 'none'; form-action 'self'");
    expect(headers["X-Frame-Options"]).toBe("DENY");
  });

  it("lets only this project's shop pictures through the image optimizer", async () => {
    expect((await load()).images?.remotePatterns).toEqual([]); // no Firebase project: nothing from other hosts
    const patterns = (await load("yummy-chops")).images!.remotePatterns as { hostname: string; pathname: string }[];
    expect(patterns.map((p) => `${p.hostname}${p.pathname}`)).toEqual([
      "firebasestorage.googleapis.com/v0/b/yummy-chops.firebasestorage.app/o/public%2Frestaurants%2F*",
      "storage.googleapis.com/yummy-chops.firebasestorage.app/public/restaurants/**",
      "firebasestorage.googleapis.com/v0/b/yummy-chops.appspot.com/o/public%2Frestaurants%2F*",
      "storage.googleapis.com/yummy-chops.appspot.com/public/restaurants/**",
    ]);
  });
});
