#!/usr/bin/env node
// The front door of the public test link (docs/adr/0024-public-test-link.md). ngrok brings requests from the
// internet to this one port, and the gateway hands each to the right service of the phone test running on this
// computer: the API, the assistant Yummy (under /agents) and the sign-in emulator. It turns away everything a
// tester's customer app never needs: staff and internal routes, developer tools, the emulator's admin calls, new
// accounts, and sign-ins or tokens for anyone but the tester.
//
// The sign-in emulator's tokens are not signed, so anyone could write one that names the tester. The gateway
// therefore passes only the sessions it has seen start: a token counts when it came out of a sign-in with the
// tester's password (or a refresh of that session) that went through this gateway.
//   node scripts/remote-gateway.mjs      (`node scripts/dev.mjs gateway`; listens on 127.0.0.1:8088)
import { createHash } from "node:crypto";
import { createReadStream, existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import http from "node:http";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const PORT = Number(process.env.REMOTE_GATEWAY_PORT ?? 8088);
export const TESTER_EMAIL = "tester@yummychops.test";
export const TESTER_UID = "demo-tester-1";
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const APK = join(root, "mobile", "dist", "yummy-chops-remote.apk");
const LOGO = join(root, "apps", "web", "public", "brand", "yummychops-logo.webp");
const SERVICES = { api: 8000, agents: 8100, auth: 9099 };
/** Where the sessions seen so far are kept between restarts: fingerprints only, never a token. */
const SESSIONS_FILE = join(tmpdir(), "yummy-chops-test-link-sessions.json");

const METHODS = new Set(["GET", "POST", "PUT", "PATCH", "DELETE"]);
// A path is letters, digits and - _ . : ~ between single slashes. Percent-encoding, backslashes, empty segments and
// dot segments are refused outright: the services decode a path before they route it, so `/v1/%61dmin` would
// reach `/v1/admin` past any rule written for the plain spelling.
const PLAIN_PATH = /^(\/[A-Za-z0-9_.:~-]+)*\/?$/;
const DOT_SEGMENT = /(^|\/)\.{1,2}(\/|$)/;
const MAX_BODY = 12 * 1024 * 1024; // the largest thing a tester sends is a photo

const AUTH_PREFIXES = ["/identitytoolkit.googleapis.com/", "/securetoken.googleapis.com/"];
// The calls the app's sign-in makes: sign in, read the signed-in account, refresh the session.
const AUTH_OPEN = {
  "/identitytoolkit.googleapis.com/v1/accounts:signinwithpassword": "signIn",
  "/identitytoolkit.googleapis.com/v1/accounts:lookup": "lookup",
  "/securetoken.googleapis.com/v1/token": "refresh",
};
// Yummy: its health check, chats and their approvals, and the tester's own conversations.
const AGENTS_OPEN = [/^\/health$/, /^\/v1\/(chat|threads)(\/|$)/];
const API_REFUSED = [/^\/v1\/(admin|partner|rider|webhooks)(\/|$)/];
// Of the developer tools only the payment pages: the pretend payment page and where a payment page sends the
// payer back.
const DEV_OPEN = [/^\/v1\/dev\/sandbox-checkout\/[a-z0-9_-]+(\/complete)?$/, /^\/v1\/dev\/payment-return$/];
// A request from the internet never carries the services' own credentials, or a hop-by-hop header.
const NEVER_FORWARDED = [
  "x-internal-token", "x-service-authorization", "connection", "keep-alive", "proxy-authorization",
  "proxy-authenticate", "proxy-connection", "te", "trailer", "upgrade",
];

const CODES = { 400: "invalid_request", 401: "unauthenticated", 403: "permission_denied", 404: "not_found", 405: "method_not_allowed", 413: "too_large" };
const refuse = (status, reason) => ({ status, reason });
const fingerprint = (token) => createHash("sha256").update(token).digest("base64url");

function claimsOf(token) {
  const parts = String(token).split(".");
  if (parts.length < 2 || parts.length > 3 || !parts[0] || !parts[1]) return null;
  try {
    const claims = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
    return claims && typeof claims === "object" && !Array.isArray(claims) ? claims : null;
  } catch {
    return null;
  }
}

/** True when a token's claims name the tester and nobody else, with no staff or shop roles of any shape. */
function namesOnlyTheTester(claims) {
  const ids = [claims.user_id, claims.sub, claims.uid].filter((id) => id !== undefined);
  if (!ids.length || ids.some((id) => id !== TESTER_UID)) return false;
  for (const key of ["roles", "restaurant_roles"]) {
    const value = claims[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== "object" || Object.keys(value).length) return false;
  }
  return true;
}

/**
 * The sessions that started on the test link: fingerprints of the tokens the sign-in emulator gave out through
 * this gateway. Kept in a small file so the tester stays signed in when the gateway restarts.
 */
export class Sessions {
  constructor(file = null) {
    this.file = file;
    this.ids = new Set();
    this.refreshes = new Set();
    if (!file || !existsSync(file)) return;
    try {
      const saved = JSON.parse(readFileSync(file, "utf8"));
      for (const print of saved.ids ?? []) if (typeof print === "string") this.ids.add(print);
      for (const print of saved.refreshes ?? []) if (typeof print === "string") this.refreshes.add(print);
    } catch {
      // An unreadable file only means the tester signs in again.
    }
  }

  /** Remember what a sign-in or a refresh answered. A token naming anyone but the tester is never remembered. */
  remember(idToken, refreshToken) {
    if (typeof idToken !== "string" || !idToken) return;
    const claims = claimsOf(idToken);
    if (!claims || !namesOnlyTheTester(claims)) return;
    this.#add(this.ids, idToken);
    if (typeof refreshToken === "string" && refreshToken) this.#add(this.refreshes, refreshToken);
    if (!this.file) return;
    try {
      writeFileSync(this.file, JSON.stringify({ ids: [...this.ids], refreshes: [...this.refreshes] }), { mode: 0o600 });
    } catch {
      // Not saved: after a restart the tester signs in again.
    }
  }

  #add(set, token) {
    set.add(fingerprint(token));
    while (set.size > 400) set.delete(set.values().next().value); // the oldest first
  }

  knowsId(token) {
    return typeof token === "string" && this.ids.has(fingerprint(token));
  }

  knowsRefresh(token) {
    return typeof token === "string" && this.refreshes.has(fingerprint(token));
  }
}

/** Wrong passwords are counted for everyone together: after `max` in `windowMs`, sign-in waits. */
export class Throttle {
  constructor(max = 8, windowMs = 10 * 60_000) {
    this.max = max;
    this.windowMs = windowMs;
    this.failures = [];
  }

  blocked(now = Date.now()) {
    this.failures = this.failures.filter((at) => now - at < this.windowMs);
    return this.failures.length >= this.max;
  }

  fail(now = Date.now()) {
    this.failures.push(now);
  }
}

const openSessions = new Sessions(process.env.REMOTE_GATEWAY_SESSIONS === "memory" ? null : SESSIONS_FILE);
const signInThrottle = new Throttle();

/**
 * What to do with a request: `{ service, path }` to pass it on, `{ page }` to answer here, or `{ status, reason }`
 * to turn it away. `guard` means the body must be read and checked first (see `guardSignIn`).
 */
export function decide(method, url, headers = {}, sessions = openSessions) {
  if (!METHODS.has(method)) return refuse(405, "This kind of request is not open on the test link.");
  const raw = typeof url === "string" ? url.split(/[?#]/, 1)[0] : "";
  if (!raw.startsWith("/") || !PLAIN_PATH.test(raw) || DOT_SEGMENT.test(raw)) {
    return refuse(400, "This address is not open on the test link.");
  }
  const { pathname, search } = new URL(url, "http://gateway");
  if (pathname !== raw) return refuse(400, "This address is not open on the test link.");
  const path = pathname.toLowerCase(); // the rules do not depend on the spelling's case
  if (method === "GET" && pathname === "/") return { page: "home" };
  if (method === "GET" && pathname === "/download") return { page: "apk" };
  if (method === "GET" && pathname === "/logo.webp") return { page: "logo" };

  if (AUTH_PREFIXES.some((prefix) => path.startsWith(prefix))) {
    // The app's sign-in sends no Authorization header; the emulator takes one as its administrator.
    if (headers.authorization) return refuse(403, "The sign-in emulator's admin calls are not open on the test link.");
    const guard = AUTH_OPEN[path];
    if (!guard || method !== "POST") return refuse(403, "This sign-in call is not open on the test link.");
    return { service: "auth", path: pathname + search, guard };
  }
  if (path === "/emulator" || path.startsWith("/emulator/")) {
    return refuse(403, "The sign-in emulator's admin pages are not open on the test link.");
  }

  if (path === "/agents" || path.startsWith("/agents/")) {
    const inner = pathname.slice("/agents".length) || "/";
    if (!AGENTS_OPEN.some((rule) => rule.test(inner.toLowerCase()))) {
      return refuse(403, "This part of Yummy is not open on the test link.");
    }
    return checkToken(headers.authorization, sessions) ?? { service: "agents", path: inner + search };
  }

  if (!path.startsWith("/v1/")) return refuse(403, "Staff and internal routes are not open on the test link.");
  if (path === "/v1/dev" || path.startsWith("/v1/dev/")) {
    if (!DEV_OPEN.some((rule) => rule.test(path))) return refuse(403, "Developer tools are not open on the test link.");
  } else if (API_REFUSED.some((rule) => rule.test(path))) {
    return refuse(403, "Staff and internal routes are not open on the test link.");
  }
  return checkToken(headers.authorization, sessions) ?? { service: "api", path: pathname + search };
}

/**
 * A token on the test link must be the tester's own, with no staff roles, from a session that signed in through
 * this gateway. Null when there is no token (public pages) or the token is good.
 */
export function checkToken(authorization, sessions = openSessions) {
  if (authorization === undefined || authorization === null || authorization === "") return null;
  const match = /^Bearer\s+(\S+)$/i.exec(String(authorization));
  const claims = match ? claimsOf(match[1]) : null;
  if (!claims) return refuse(401, "The sign-in token could not be read.");
  if (!namesOnlyTheTester(claims)) return refuse(403, "Only the tester account works on the test link.");
  if (!sessions.knowsId(match[1])) return refuse(401, "Please sign out and sign in again with the tester account.");
  return null;
}

/** Only the tester signs in on the test link: the demo accounts' password is public in the repository. */
export function signInAllowed(body) {
  try {
    return String(JSON.parse(body).email ?? "").trim().toLowerCase() === TESTER_EMAIL;
  } catch {
    return false;
  }
}

// What the Firebase sign-in emulator itself answers, so the app shows its usual messages.
const emulatorError = (message) => ({
  status: 400,
  body: JSON.stringify({ error: { code: 400, message, errors: [{ message, domain: "global", reason: "invalid" }] } }),
});

function fieldsOf(body, contentType = "") {
  if (String(contentType).toLowerCase().includes("application/x-www-form-urlencoded")) {
    return Object.fromEntries(new URLSearchParams(body));
  }
  try {
    const parsed = JSON.parse(body);
    return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
  } catch {
    return {};
  }
}

/**
 * The checks on a sign-in call's body, before it reaches the emulator: null to let it through, or the answer to
 * give instead. The emulator believes any token it is shown, so a call that carries one is only passed for a
 * session that started here.
 */
export function guardSignIn(kind, body, contentType, sessions = openSessions, throttle = signInThrottle, now = Date.now()) {
  if (kind === "signIn") {
    if (throttle.blocked(now)) return emulatorError("TOO_MANY_ATTEMPTS_TRY_LATER");
    if (signInAllowed(body)) return null;
    throttle.fail(now);
    return emulatorError("INVALID_LOGIN_CREDENTIALS");
  }
  const fields = fieldsOf(body, contentType);
  if (kind === "lookup") {
    // Only "who am I" for the signed-in tester: never an account picked by id, email or phone number.
    const asked = Object.keys(fields);
    const claims = typeof fields.idToken === "string" ? claimsOf(fields.idToken) : null;
    const own = asked.length === 1 && claims && namesOnlyTheTester(claims) && sessions.knowsId(fields.idToken);
    return own ? null : emulatorError("INVALID_ID_TOKEN");
  }
  if (kind === "refresh") {
    const grant = fields.grant_type ?? fields.grantType;
    const token = fields.refresh_token ?? fields.refreshToken;
    return grant === "refresh_token" && sessions.knowsRefresh(token) ? null : emulatorError("INVALID_REFRESH_TOKEN");
  }
  return emulatorError("OPERATION_NOT_ALLOWED");
}

/** What the emulator answered a sign-in call: remember the session it started or continued. */
export function afterSignIn(kind, status, text, sessions = openSessions, throttle = signInThrottle, now = Date.now()) {
  if (kind === "lookup") return;
  if (status !== 200) {
    if (kind === "signIn") throttle.fail(now); // a wrong password
    return;
  }
  const answer = fieldsOf(text);
  sessions.remember(answer.idToken ?? answer.id_token ?? answer.access_token, answer.refreshToken ?? answer.refresh_token);
}

const SAFE_HEADERS = { "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff", "Referrer-Policy": "no-referrer", "X-Frame-Options": "DENY" };

function send(res, status, body, type = "text/plain; charset=utf-8", extra = {}) {
  res.writeHead(status, { "Content-Type": type, ...SAFE_HEADERS, ...extra });
  res.end(body);
}

/** A refusal in the shape of the API's own errors, so the app shows the reason. */
function sendRefusal(res, { status, reason }) {
  send(res, status, JSON.stringify({ error: { code: CODES[status] ?? "error", message: reason } }), "application/json; charset=utf-8");
}

/** Pass a request on. With `onAnswer` (sign-in calls) the answer is read whole first, so it can be looked at. */
function forward(req, res, decision, body, onAnswer) {
  const headers = { ...req.headers };
  for (const name of NEVER_FORWARDED) delete headers[name];
  // The services see the address the tester used (the payment page link is built from it), over https when the
  // tester's request came in over https, and the tester's own address rather than this gateway's.
  headers["x-forwarded-proto"] = String(headers["x-forwarded-proto"] ?? "http").split(",")[0].trim();
  const peer = req.socket.remoteAddress ?? "";
  headers["x-forwarded-for"] = headers["x-forwarded-for"] ? `${headers["x-forwarded-for"]}, ${peer}` : peer;
  if (body !== undefined) {
    headers["content-length"] = String(Buffer.byteLength(body));
    delete headers["transfer-encoding"];
  }
  if (onAnswer) delete headers["accept-encoding"]; // read as plain text
  const upstream = http.request(
    { host: "127.0.0.1", port: SERVICES[decision.service], method: req.method, path: decision.path, headers },
    (answer) => {
      if (!onAnswer) {
        res.writeHead(answer.statusCode ?? 502, answer.headers);
        answer.pipe(res);
        return;
      }
      const chunks = [];
      let size = 0;
      answer.on("data", (chunk) => {
        size += chunk.length;
        if (size <= 256 * 1024) chunks.push(chunk);
      });
      answer.on("end", () => {
        const whole = Buffer.concat(chunks);
        if (size <= 256 * 1024) onAnswer(answer.statusCode ?? 502, whole.toString("utf8"));
        const answerHeaders = { ...answer.headers, "content-length": String(whole.length) };
        delete answerHeaders["transfer-encoding"];
        res.writeHead(answer.statusCode ?? 502, answerHeaders);
        res.end(whole);
      });
      answer.on("error", () => res.destroy());
    },
  );
  upstream.on("error", () => {
    if (res.headersSent) res.destroy();
    else send(res, 502, "The Yummy Chops test server on this computer is not running.");
  });
  if (body !== undefined) return upstream.end(body);
  let seen = 0;
  req.on("data", (chunk) => {
    seen += chunk.length;
    if (seen > MAX_BODY) {
      upstream.destroy();
      req.destroy();
    }
  });
  req.pipe(upstream);
}

function readBody(req, limit = 64 * 1024) {
  return new Promise((done, fail) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > limit) fail(new Error("too large"));
    });
    req.on("end", () => done(body));
    req.on("error", fail);
  });
}

function homePage() {
  const ready = existsSync(APK);
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Yummy Chops test app</title><style>
body{margin:0;font-family:system-ui,sans-serif;background:#FFFBF8;color:#2A0D06;display:grid;place-items:center;min-height:100vh}
main{max-width:420px;width:90%;text-align:center;padding:24px 0}img{width:180px;height:auto;border-radius:24px;background:#fff}
h1{font-size:26px;margin:12px 0 4px}p,li{line-height:1.5}ol{text-align:left;padding-left:22px}
a.button{display:block;background:#E0040B;color:#fff;text-decoration:none;font-weight:700;padding:14px;border-radius:999px;margin:18px 0}
code{background:#F8EFEA;padding:2px 6px;border-radius:6px}.muted{color:#7A625A;font-size:13px}</style></head><body><main>
<img src="/logo.webp" alt="Yummy Chops"><h1>Try the Yummy Chops app</h1><p>An early test version for Android phones.</p>
${ready ? '<a class="button" href="/download">Download the app</a>' : "<p><b>The test app is not ready yet.</b> Try again later.</p>"}
<ol><li>Open the download. If Android asks, allow your browser to <b>install unknown apps</b>, then tap <b>Install</b>.</li>
<li>Sign in with the email <code>${TESTER_EMAIL}</code> and the password you were given.</li>
<li>Order anything: shops, riders and payments are all for testing, and no real money moves.</li></ol>
<p class="muted">The app works while the test server it talks to is running. If it can't connect, ask the person who sent you this link.</p>
</main></body></html>`;
}

function serveFile(res, file, type, extra = {}) {
  if (!existsSync(file)) return send(res, 404, "Not here yet.");
  res.writeHead(200, { "Content-Type": type, "Content-Length": statSync(file).size, ...SAFE_HEADERS, ...extra });
  createReadStream(file).pipe(res);
}

export async function handle(req, res) {
  const decision = decide(req.method ?? "GET", req.url ?? "/", req.headers);
  if (decision.page === "home") {
    return send(res, 200, homePage(), "text/html; charset=utf-8", {
      "Content-Security-Policy": "default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
    });
  }
  if (decision.page === "logo") return serveFile(res, LOGO, "image/webp");
  if (decision.page === "apk") {
    return serveFile(res, APK, "application/vnd.android.package-archive", {
      "Content-Disposition": 'attachment; filename="yummy-chops.apk"',
    });
  }
  if (decision.status) return sendRefusal(res, decision);
  if (Number(req.headers["content-length"] ?? 0) > MAX_BODY) return sendRefusal(res, refuse(413, "That is too large for the test link."));
  if (decision.guard) {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return sendRefusal(res, refuse(413, "That is too large for the test link."));
    }
    const refused = guardSignIn(decision.guard, body, req.headers["content-type"]);
    if (refused) return send(res, refused.status, refused.body, "application/json; charset=utf-8");
    return forward(req, res, decision, body, (status, text) => afterSignIn(decision.guard, status, text));
  }
  return forward(req, res, decision);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  http
    .createServer((req, res) => {
      handle(req, res).catch(() => {
        if (res.headersSent) res.destroy();
        else send(res, 500, "The test link gateway failed.");
      });
    })
    .listen(PORT, "127.0.0.1", () => console.log(`Test link gateway on http://127.0.0.1:${PORT} (ngrok forwards to it)`));
}
