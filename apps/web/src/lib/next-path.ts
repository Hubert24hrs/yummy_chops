/** Where to go after signing in: only same-site paths ("//host" and "/\host" would leave the site: open redirect). */
export function safeNext(next: string | null | undefined): string {
  return next && /^\/(?![/\\])/.test(next) ? next : "/";
}
