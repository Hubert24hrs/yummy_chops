/** Stands in for the site's own address where there is no browser (pages rendered on the server). */
const STAND_IN = "https://yummy247.invalid";

/**
 * Where to go after signing in: only a path on this site. `next` comes from the link, so it is read the way the
 * browser will read it (resolved against the site's address: tabs and line breaks are dropped, "\" counts as "/")
 * and must still be on this site. "//host", "/\host", "/<tab>/host" and full addresses would leave it (an open
 * redirect), so they go home instead. What comes back is the resolved path with its query and fragment.
 */
export function safeNext(next: string | null | undefined): string {
  if (!next || !next.startsWith("/")) return "/";
  const origin = typeof window === "undefined" ? STAND_IN : window.location.origin;
  try {
    const url = new URL(next, origin);
    return url.origin === origin ? `${url.pathname}${url.search}${url.hash}` : "/";
  } catch {
    return "/";
  }
}
