#!/usr/bin/env node
// Local development launcher: `node scripts/dev.mjs <api|agents|auth|customer-web|downloads> [--lan]`.
// Uses safe local defaults (memory data + payment sandbox + Firebase Auth emulator). Real keys go in .env files.
// --lan: also listen on this computer's Wi-Fi address so a phone on the same Wi-Fi can use a test APK
// (see docs/LOCAL_DEVELOPMENT.md, "Test on your phone"). Set LAN_IP to choose the address yourself.
// customer-web takes --port=5051, the spare address (see WEB_APP_PORTS below).
// Several names run together, and --seed creates the demo accounts: `auth api agents downloads --lan --seed`.
// --paystack: card payments in Paystack TEST mode, with the key from the git-ignored .env.paystack.
import { spawn, spawnSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { lanIp } from "./lan.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const isWin = process.platform === "win32";
const py = (svc) => join(root, "services", svc, ".venv", isWin ? "Scripts/python.exe" : "bin/python");
const lan = process.argv.includes("--lan");
const ip = lan ? lanIp() : null;

// The web build of the customer app is served on 5050. `customer-web --port=5051` is the spare address, for a
// browser that holds broken site data for 5050 and shows a blank page. The API and Yummy allow both.
const WEB_APP_PORTS = ["5050", "5051"];
const webPort = process.argv.find((arg) => arg.startsWith("--port="))?.slice("--port=".length) ?? WEB_APP_PORTS[0];
// Web pages that may call the local services: the three websites (3010: the customer website when other
// projects hold 3000-3002, preview server `web-3010`) and the web build of the customer app.
const corsOrigins = process.env.CORS_ORIGINS
  ?? JSON.stringify(["3000", "3001", "3002", "3010", ...WEB_APP_PORTS].map((port) => `http://localhost:${port}`));

// The Auth emulator reads its listen address from firebase.json; --lan uses a copy that listens on every interface.
function lanFirebaseConfig() {
  const config = JSON.parse(readFileSync(join(root, "firebase/firebase.json"), "utf8"));
  config.emulators.auth.host = "0.0.0.0";
  writeFileSync(join(root, "firebase/firebase.lan.json"), JSON.stringify(config, null, 2));
  return ["--config", "firebase.lan.json"];
}

const shared = {
  ENVIRONMENT: "local",
  FIREBASE_PROJECT_ID: "demo-gudmeal",
  FIREBASE_AUTH_EMULATOR_HOST: process.env.FIREBASE_AUTH_EMULATOR_HOST ?? "127.0.0.1:9099",
  PYTHONUNBUFFERED: "1",
};

const targets = {
  api: {
    cmd: py("api"),
    args: ["-m", "uvicorn", "--factory", "gudmeal_api.main:app_factory", "--port", "8000", ...(lan ? ["--host", "0.0.0.0"] : [])],
    cwd: join(root, "services/api"),
    env: {
      // Local dev creates tables directly (no migrations): bump the file name when the money schema changes
      // (v4: split card payments, ADR-0028).
      DATA_BACKEND: "memory", SEED_DEMO_DATA: "true", DATABASE_URL: "sqlite+aiosqlite:///./gudmeal_local_v4.db",
      // With --lan the payment sandbox page is opened by the phone, so its links use the Wi-Fi address.
      PUBLIC_BASE_URL: `http://${ip ?? "localhost"}:8000`, PAYMENT_CALLBACK_URL: "http://localhost:3000/checkout/callback",
      // ...and they follow this computer when it joins another Wi-Fi and gets a new address.
      SANDBOX_FOLLOWS_LAN_ADDRESS: lan ? "true" : "false",
      INTERNAL_SHARED_SECRET: "local-dev-only", CHECK_TOKEN_REVOCATION: "false", CORS_ORIGINS: corsOrigins,
      // Testing at any hour, anywhere in the city: shops stay open, riders up to 40 km away get offers, and a
      // missed offer comes back within about a minute.
      DEMO_SHOPS_ALWAYS_OPEN: process.env.DEMO_SHOPS_ALWAYS_OPEN ?? "true",
      DISPATCH_PICKUP_RADIUS_KM: process.env.DISPATCH_PICKUP_RADIUS_KM ?? "40",
      DISPATCH_REOFFER_SECONDS: process.env.DISPATCH_REOFFER_SECONDS ?? "20",
      // Riders normally stop getting cash jobs once they hold N50,000; a tester would hit that after a few
      // pay-on-delivery orders (cash is handed in on the Command Centre's Cash page). N1,000,000 locally.
      RIDER_CASH_LIMIT_KOBO: process.env.RIDER_CASH_LIMIT_KOBO ?? "100000000",
      // Phone tests (--lan) have nobody at the shop's dashboard: demo shops accept and pack orders by themselves
      // after a few seconds. Set DEMO_SHOP_AUTOPILOT=false to play the shop in the partner dashboard instead.
      DEMO_SHOP_AUTOPILOT: process.env.DEMO_SHOP_AUTOPILOT ?? (lan ? "true" : "false"),
      // Yummy on WhatsApp with the sandbox sender: try it at http://localhost:8000/v1/dev/whatsapp
      WHATSAPP_ENABLED: "true", WHATSAPP_PROVIDER: "sandbox", AGENTS_BASE_URL: "http://localhost:8100",
    },
  },
  agents: {
    cmd: py("agents"),
    args: ["-m", "uvicorn", "--factory", "gudmeal_agents.main:app_factory", "--port", "8100", ...(lan ? ["--host", "0.0.0.0"] : [])],
    cwd: join(root, "services/agents"),
    env: { API_BASE_URL: "http://localhost:8000", CHECKPOINTER: "sqlite", CORS_ORIGINS: corsOrigins },
  },
  // Serves test APKs (mobile/dist, made by scripts/build-test-apk.mjs) to phones on the same Wi-Fi.
  downloads: {
    cmd: isWin ? "python" : "python3",
    args: ["-m", "http.server", "8090", "--bind", lan ? "0.0.0.0" : "127.0.0.1", "--directory", join(root, "mobile/dist")],
    cwd: root,
    env: {},
  },
  // Serves the last `flutter build web` of the customer app (run that first) for browser testing.
  "customer-web": {
    cmd: isWin ? "python" : "python3",
    args: ["-m", "http.server", webPort, "--bind", "127.0.0.1", "--directory", join(root, "mobile/customer/build/web")],
    cwd: root,
    env: {},
  },
  auth: {
    cmd: isWin ? "firebase.cmd" : "firebase",
    args: ["--non-interactive", "emulators:start", "--only", "auth", "--project", "demo-gudmeal", ...(lan ? lanFirebaseConfig() : [])],
    cwd: join(root, "firebase"),
    env: {},
    shell: isWin,
  },
};

// One name runs that service. Several names run together and stop together: the phone test is
// `node scripts/dev.mjs auth api agents downloads --lan --seed`.
const names = process.argv.slice(2).filter((arg) => !arg.startsWith("--"));
if (!names.length || names.some((name) => !targets[name])) {
  console.error(`usage: node scripts/dev.mjs <${Object.keys(targets).join("|")}> [another ...] [--lan] [--seed]`);
  process.exit(2);
}
if (names.includes("customer-web") && !WEB_APP_PORTS.includes(webPort)) {
  console.error(`customer-web runs on ${WEB_APP_PORTS.join(" or ")}: the local API and Yummy allow only those addresses`);
  process.exit(2);
}
if (lan) console.log(`LAN mode: phones on this Wi-Fi reach ${names.join(", ")} at http://${ip} (allow it if Windows Firewall asks)`);
for (const name of names) {
  const { cmd, cwd } = targets[name];
  if ((cmd.endsWith("python.exe") || cmd.endsWith("/python")) && !existsSync(cmd)) {
    console.error(`Missing virtualenv: run "uv sync" in ${cwd}`);
    process.exit(1);
  }
}

// --paystack: card payments go to Paystack in TEST mode instead of the local sandbox (docs/PAYSTACK_TEST_MODE.md).
// The key stays out of the repository, in the git-ignored .env.paystack (PAYSTACK_SECRET_KEY=sk_test_...), and only
// a test key is accepted: the local stack must never take real money.
const paystack = {};
if (process.argv.includes("--paystack")) {
  const file = join(root, ".env.paystack");
  const found = existsSync(file) && /^[ \t]*PAYSTACK_SECRET_KEY[ \t]*=[ \t]*["']?([^"'\s#]+)/m.exec(readFileSync(file, "utf8"));
  if (!found || !found[1].startsWith("sk_test_")) {
    console.error("--paystack needs a Paystack TEST secret key: PAYSTACK_SECRET_KEY=sk_test_... in .env.paystack (live keys are refused)");
    process.exit(2);
  }
  paystack.PAYSTACK_SECRET_KEY = found[1];
  console.log("Card payments: Paystack TEST mode (no real money moves; pay with Paystack's test cards)");
}

const children = names.map((name) => {
  const target = targets[name];
  const child = spawn(target.cmd, target.args, {
    cwd: target.cwd, stdio: "inherit", shell: target.shell ?? false,
    env: { ...process.env, ...shared, ...target.env, ...(name === "api" ? paystack : {}) },
  });
  child.on("error", (error) => {
    console.error(`${name} did not start: ${error.message}`);
    stopAll(1);
  });
  // When one service stops, the rest stop with it, so a half-running stack never looks healthy.
  child.on("exit", (code) => stopAll(code ?? 0));
  return child;
});
// On Windows the Auth emulator runs under a shell, and stopping the shell alone leaves it holding its port:
// stop the whole process tree.
function stop(child) {
  if (!child.pid || child.exitCode !== null || child.signalCode !== null) return;
  if (isWin) spawnSync("taskkill", ["/pid", String(child.pid), "/T", "/F"], { stdio: "ignore" });
  else child.kill("SIGTERM");
}
let stopping = false;
function stopAll(code) {
  if (stopping) return;
  stopping = true;
  children.forEach(stop);
  process.exit(code);
}
for (const sig of ["SIGINT", "SIGTERM"]) process.on(sig, () => stopAll(0));

// --seed: create the demo accounts once the Auth emulator answers (the script in docs/LOCAL_DEVELOPMENT.md,
// section 2). The emulator forgets every account when it stops, so a restarted stack needs them again.
if (process.argv.includes("--seed") && names.includes("auth")) seedDemoAccounts();

async function seedDemoAccounts() {
  // The emulator waits on requests to Google while it starts: seconds on a good internet connection, minutes on
  // a poor one. Keep waiting for as long as it runs (when it stops, this launcher stops too).
  for (let waited = 0; ; waited += 2) {
    try {
      if ((await fetch(`http://${shared.FIREBASE_AUTH_EMULATOR_HOST}/`)).ok) {
        const seed = spawn(py("api"), ["scripts/seed_auth_emulator.py"], {
          cwd: join(root, "services/api"), stdio: "inherit", env: { ...process.env, ...shared },
        });
        seed.on("error", (error) => console.error(`The demo accounts were not created: ${error.message}`));
        return;
      }
    } catch {
      // The emulator is still starting.
    }
    if (waited === 60) console.log("Still waiting for the Auth emulator before creating the demo accounts (a poor internet connection slows its start)");
    await new Promise((resolve) => setTimeout(resolve, 2000));
  }
}
