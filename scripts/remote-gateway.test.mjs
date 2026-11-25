// Rules of the public test link's gateway (docs/adr/0024-public-test-link.md).   node --test scripts/remote-gateway.test.mjs
process.env.REMOTE_GATEWAY_SESSIONS = "memory"; // these tests never touch the sessions file
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

const { Sessions, Throttle, TESTER_EMAIL, TESTER_UID, afterSignIn, checkToken, decide, guardSignIn, signInAllowed } =
  await import("./remote-gateway.mjs");

const jwt = (claims) =>
  `${Buffer.from('{"alg":"none"}').toString("base64url")}.${Buffer.from(JSON.stringify(claims)).toString("base64url")}.`;
const testerClaims = { user_id: TESTER_UID, sub: TESTER_UID, email: TESTER_EMAIL, roles: [], restaurant_roles: {} };

/** A gateway that has seen the tester sign in: the emulator's answer went through it. */
function signedIn() {
  const sessions = new Sessions();
  const idToken = jwt({ ...testerClaims, iat: Date.now() });
  afterSignIn("signIn", 200, JSON.stringify({ idToken, refreshToken: "refresh-1" }), sessions, new Throttle());
  return { sessions, idToken, bearer: `Bearer ${idToken}` };
}

test("the app's API calls reach the API, with the path and query kept", () => {
  const { sessions, bearer } = signedIn();
  assert.deepEqual(decide("GET", "/v1/restaurants?city=lagos&limit=50", {}, sessions), { service: "api", path: "/v1/restaurants?city=lagos&limit=50" });
  assert.deepEqual(decide("POST", "/v1/orders/o1/checkout", { authorization: bearer }, sessions), { service: "api", path: "/v1/orders/o1/checkout" });
  assert.deepEqual(decide("POST", "/v1/payments/verify", { authorization: bearer }, sessions), { service: "api", path: "/v1/payments/verify" });
});

test("Yummy: chats and the tester's conversations only", () => {
  const { sessions, bearer } = signedIn();
  assert.deepEqual(decide("POST", "/agents/v1/chat", { authorization: bearer }, sessions), { service: "agents", path: "/v1/chat" });
  assert.deepEqual(decide("GET", "/agents/v1/threads", { authorization: bearer }, sessions), { service: "agents", path: "/v1/threads" });
  assert.deepEqual(decide("GET", "/agents/health", {}, sessions), { service: "agents", path: "/health" });
  for (const path of ["/agents/v1/admin/metrics", "/agents/docs", "/agents/openapi.json", "/agents"]) {
    assert.equal(decide("GET", path, { authorization: bearer }, sessions).status, 403, path);
  }
});

test("the payment pages open; other developer tools do not", () => {
  assert.equal(decide("GET", "/v1/dev/sandbox-checkout/YC-ABC").service, "api");
  assert.equal(decide("POST", "/v1/dev/sandbox-checkout/YC-ABC/complete?outcome=success").service, "api");
  assert.equal(decide("GET", "/v1/dev/payment-return?reference=YC-ABC").service, "api");
  assert.equal(decide("POST", "/v1/dev/whatsapp/2348000000000/send").status, 403);
  assert.equal(decide("GET", "/v1/dev/whatsapp").status, 403);
});

test("staff, internal and documentation routes are turned away, in any spelling", () => {
  const { sessions, bearer } = signedIn();
  for (const path of [
    "/v1/admin/orders", "/V1/ADMIN/orders", "/v1/partner/orders", "/v1/rider/offers", "/v1/webhooks/paystack",
    "/internal/events", "/Internal/jobs/sweep", "/docs", "/openapi.json", "/redoc",
  ]) {
    assert.equal(decide("GET", path, { authorization: bearer }, sessions).status, 403, path);
  }
});

test("encoded, dotted and doubled paths are refused before anything else", () => {
  // The services decode a path before routing it: /v1/%61dmin would reach /v1/admin.
  for (const url of [
    "/v1/%61dmin/users", "/%69nternal/events", "/v1/dev%2fwhatsapp", "/v1/%2e%2e/internal/events", "/v1/admin%2forders",
    "/v1//admin", "/v1/./admin", "/v1/x/../admin", "/v1/..", "/v1/restaurants\\..\\admin", "//evil.example/v1/me",
    "http://gateway/v1/admin", "/v1/admin;x", "",
  ]) {
    assert.equal(decide("GET", url).status, 400, url);
  }
});

test("only the methods the app uses", () => {
  for (const method of ["CONNECT", "TRACE", "OPTIONS", "HEAD", "PROPFIND"]) {
    assert.equal(decide(method, "/v1/restaurants").status, 405, method);
  }
});

test("sign-in: only the calls the app makes, and never the emulator's admin calls", () => {
  assert.deepEqual(decide("POST", "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=k"), {
    service: "auth", path: "/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=k", guard: "signIn",
  });
  assert.equal(decide("POST", "/identitytoolkit.googleapis.com/v1/accounts:lookup?key=k").guard, "lookup");
  assert.equal(decide("POST", "/securetoken.googleapis.com/v1/token?key=k").guard, "refresh");
  for (const call of ["accounts:signUp", "accounts:update", "accounts:signInWithIdp", "accounts:sendOobCode", "accounts:delete"]) {
    assert.equal(decide("POST", `/identitytoolkit.googleapis.com/v1/${call}?key=k`).status, 403, call);
  }
  // The emulator takes any Authorization header ("Bearer owner", "Bearer ya29...") as its administrator.
  for (const authorization of ["Bearer owner", "Bearer ya29.anything", "Bearer x"]) {
    assert.equal(decide("POST", "/identitytoolkit.googleapis.com/v1/accounts:lookup", { authorization }).status, 403);
  }
  assert.equal(decide("GET", "/identitytoolkit.googleapis.com/v1/accounts:lookup").status, 403);
  assert.equal(decide("DELETE", "/emulator/v1/projects/demo-gudmeal/accounts").status, 403);
});

test("a token counts only if it came out of a sign-in through the gateway", () => {
  const { sessions, bearer } = signedIn();
  assert.equal(checkToken(undefined, sessions), null);
  assert.equal(checkToken(bearer, sessions), null);
  // Written by hand: the emulator does not sign its tokens, so a made-up one names the tester just as well.
  assert.equal(checkToken(`Bearer ${jwt(testerClaims)}`, sessions).status, 401);
  assert.equal(checkToken(`Bearer ${jwt({ ...testerClaims, roles: { super_admin: true } })}`, sessions).status, 403);
  assert.equal(checkToken(`Bearer ${jwt({ ...testerClaims, sub: "demo-admin-1" })}`, sessions).status, 403);
  assert.equal(checkToken(`Bearer ${jwt({ ...testerClaims, uid: "demo-customer-1" })}`, sessions).status, 403);
  assert.equal(checkToken(`Bearer ${jwt({ ...testerClaims, restaurant_roles: { r1: "owner" } })}`, sessions).status, 403);
  assert.equal(checkToken("Bearer nonsense", sessions).status, 401);
  assert.equal(checkToken("Basic dGVzdGVy", sessions).status, 401);
  assert.equal(decide("GET", "/v1/me", { authorization: `Bearer ${jwt(testerClaims)}` }, sessions).status, 401);
});

test("only the tester signs in, and wrong passwords soon have to wait", () => {
  const sessions = new Sessions();
  const throttle = new Throttle(3, 60_000);
  const tester = JSON.stringify({ email: ` ${TESTER_EMAIL.toUpperCase()} `, password: "x", returnSecureToken: true });
  assert.equal(signInAllowed(tester), true);
  assert.equal(signInAllowed("not json"), false);
  assert.equal(guardSignIn("signIn", tester, "application/json", sessions, throttle, 0), null);
  const other = guardSignIn("signIn", JSON.stringify({ email: "admin@yummychops.test" }), "application/json", sessions, throttle, 0);
  assert.match(other.body, /INVALID_LOGIN_CREDENTIALS/);
  afterSignIn("signIn", 400, "{}", sessions, throttle, 1); // a wrong password for the tester
  afterSignIn("signIn", 400, "{}", sessions, throttle, 2);
  assert.match(guardSignIn("signIn", tester, "application/json", sessions, throttle, 3).body, /TOO_MANY_ATTEMPTS_TRY_LATER/);
  assert.equal(guardSignIn("signIn", tester, "application/json", sessions, throttle, 61_000), null); // later on
});

test("account lookups: the signed-in tester asking about themself, nothing else", () => {
  const { sessions, idToken } = signedIn();
  assert.equal(guardSignIn("lookup", JSON.stringify({ idToken }), "application/json", sessions), null);
  // The emulator answers a lookup with the stored password, so nobody else's token or account may be asked about.
  assert.match(guardSignIn("lookup", JSON.stringify({ idToken: jwt(testerClaims) }), "application/json", sessions).body, /INVALID_ID_TOKEN/);
  assert.match(guardSignIn("lookup", JSON.stringify({ idToken, localId: ["demo-admin-1"] }), "application/json", sessions).body, /INVALID_ID_TOKEN/);
  assert.match(guardSignIn("lookup", JSON.stringify({ email: [TESTER_EMAIL] }), "application/json", sessions).body, /INVALID_ID_TOKEN/);
});

test("refreshing: only sessions that started here, in either body format", () => {
  const { sessions } = signedIn();
  assert.equal(guardSignIn("refresh", "grant_type=refresh_token&refresh_token=refresh-1", "application/x-www-form-urlencoded", sessions), null);
  assert.equal(guardSignIn("refresh", JSON.stringify({ grantType: "refresh_token", refreshToken: "refresh-1" }), "application/json", sessions), null);
  assert.match(guardSignIn("refresh", "grant_type=refresh_token&refresh_token=made-up", "application/x-www-form-urlencoded", sessions).body, /INVALID_REFRESH_TOKEN/);
  // A refreshed session keeps working: its new tokens are remembered too.
  const fresh = jwt({ ...testerClaims, iat: 2 });
  afterSignIn("refresh", 200, JSON.stringify({ id_token: fresh, refresh_token: "refresh-2", access_token: fresh }), sessions);
  assert.equal(checkToken(`Bearer ${fresh}`, sessions), null);
  assert.equal(guardSignIn("refresh", "grant_type=refresh_token&refresh_token=refresh-2", "application/x-www-form-urlencoded", sessions), null);
});

test("sessions: never anyone but the tester, kept across restarts, oldest dropped first", () => {
  const sessions = new Sessions();
  const admin = jwt({ user_id: "demo-admin-1", sub: "demo-admin-1", roles: ["super_admin"] });
  sessions.remember(admin, "r");
  assert.equal(sessions.knowsId(admin), false);
  assert.equal(sessions.knowsRefresh("r"), false);

  const dir = mkdtempSync(join(tmpdir(), "gateway-test-"));
  try {
    const file = join(dir, "sessions.json");
    const first = new Sessions(file);
    const token = jwt({ ...testerClaims, iat: 1 });
    first.remember(token, "refresh-a");
    const again = new Sessions(file);
    assert.equal(again.knowsId(token), true);
    assert.equal(again.knowsRefresh("refresh-a"), true);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }

  const many = new Sessions();
  const tokens = Array.from({ length: 401 }, (_, i) => jwt({ ...testerClaims, iat: i }));
  for (const token of tokens) many.remember(token);
  assert.equal(many.knowsId(tokens[0]), false);
  assert.equal(many.knowsId(tokens[400]), true);
});

test("the landing page, the logo and the app download are answered by the gateway itself", () => {
  assert.deepEqual(decide("GET", "/"), { page: "home" });
  assert.deepEqual(decide("GET", "/download"), { page: "apk" });
  assert.deepEqual(decide("GET", "/logo.webp"), { page: "logo" });
});
