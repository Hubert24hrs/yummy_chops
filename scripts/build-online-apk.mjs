#!/usr/bin/env node
// Builds the TESTER apps for the online test server (ADR-0026): the customer app and the rider app talking to the
// API and Yummy on Google Cloud Run and to the real Firebase project, not to this computer. Anyone with the customer
// app can sign up; payments use Paystack's test mode.
//
// Settings come from the git-ignored .env.online (public Firebase client values and the two service addresses,
// written when the project was set up). With MAPS_ANDROID_KEY there (a Maps SDK for Android key restricted to the two
// apps), the apps show Google map tiles and customers can "Choose on the map"; without it, maps are schematic.
//
//   node scripts/build-online-apk.mjs                 # both apps, 64-bit Android phones (smaller; less disk to build)
//   node scripts/build-online-apk.mjs rider           # one app
//   node scripts/build-online-apk.mjs --universal     # also 32-bit phones (bigger)
//   node scripts/build-online-apk.mjs --publish       # put the download page and the APKs on Firebase Hosting
//
// Output: mobile/dist/online (git-ignored): yummy-chops-online.apk, yummy-chops-rider-online.apk and index.html.
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const isWin = process.platform === "win32";
const args = process.argv.slice(2);
const universal = args.includes("--universal");
const publish = args.includes("--publish");

const envFile = join(root, ".env.online");
if (!existsSync(envFile)) {
  console.error("Missing .env.online: the online test server is not set up yet (docs/DEPLOYMENT.md §8).");
  process.exit(1);
}
const env = Object.fromEntries(
  readFileSync(envFile, "utf8").split(/\r?\n/).filter((l) => l && !l.startsWith("#") && l.includes("="))
    .map((l) => [l.slice(0, l.indexOf("=")).trim(), l.slice(l.indexOf("=") + 1).trim()]),
);
for (const key of ["API_URL", "AGENTS_URL", "FIREBASE_API_KEY", "FIREBASE_PROJECT_ID", "FIREBASE_SENDER_ID", "CUSTOMER_FIREBASE_APP_ID", "RIDER_FIREBASE_APP_ID"]) {
  if (!env[key]) { console.error(`.env.online has no ${key}`); process.exit(1); }
}

const APPS = [
  { id: "customer", file: "yummy-chops-online.apk", title: "Yummy Chops", appId: env.CUSTOMER_FIREBASE_APP_ID,
    note: "Order food, pharmacy, beauty, groceries and foodstuff, and send packages" },
  { id: "rider", file: "yummy-chops-rider-online.apk", title: "Yummy Chops Rider", appId: env.RIDER_FIREBASE_APP_ID,
    note: "For riders: accept deliveries and confirm them with the customer's code" },
];
const wanted = APPS.filter((a) => args.includes(a.id));
const toBuild = publish ? [] : (wanted.length ? wanted : APPS);
const dist = join(root, "mobile/dist/online");
mkdirSync(dist, { recursive: true });

for (const app of toBuild) {
  console.log(`\n==> Building ${app.title} for ${env.API_URL}${universal ? "" : " (64-bit Android)"}`);
  const res = spawnSync(isWin ? "flutter.bat" : "flutter", [
    "build", "apk", "--release",
    `--dart-define=API_URL=${env.API_URL}`,
    `--dart-define=AGENTS_URL=${env.AGENTS_URL}`,
    "--dart-define=USE_FIREBASE_EMULATORS=false",
    `--dart-define=FIREBASE_API_KEY=${env.FIREBASE_API_KEY}`,
    `--dart-define=FIREBASE_APP_ID=${app.appId}`,
    `--dart-define=FIREBASE_PROJECT_ID=${env.FIREBASE_PROJECT_ID}`,
    `--dart-define=FIREBASE_SENDER_ID=${env.FIREBASE_SENDER_ID}`,
    // Google sign-in through Android's account picker (no browser page): the project's web OAuth client (public).
    ...(env.GOOGLE_WEB_CLIENT_ID ? [`--dart-define=GOOGLE_WEB_CLIENT_ID=${env.GOOGLE_WEB_CLIENT_ID}`] : []),
    ...(env.MAPS_ANDROID_KEY ? ["--dart-define=MAPS_ENABLED=true"] : []),
    ...(universal ? [] : ["--target-platform", "android-arm64"]),
  ], {
    cwd: join(root, "mobile", app.id), stdio: "inherit", shell: isWin,
    // android/app/build.gradle.kts puts MAPS_API_KEY into the manifest; it is never committed.
    env: { ...process.env, ...(env.MAPS_ANDROID_KEY ? { MAPS_API_KEY: env.MAPS_ANDROID_KEY } : {}) },
  });
  if (res.status !== 0) process.exit(res.status ?? 1);
  copyFileSync(join(root, "mobile", app.id, "build/app/outputs/flutter-apk/app-release.apk"), join(dist, app.file));
  rmSync(join(root, "mobile", app.id, "build/app"), { recursive: true, force: true }); // ~0.5 GB of intermediates
}

// The download page testers open on their phones.
const built = APPS.filter((a) => existsSync(join(dist, a.file)));
const size = (a) => `${(statSync(join(dist, a.file)).size / 1024 / 1024).toFixed(0)} MB`;
writeFileSync(join(dist, "index.html"), `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Try Yummy Chops</title>
<style>body{font-family:system-ui,sans-serif;margin:0;background:#FFF8F2;color:#2A0D06}main{max-width:560px;margin:auto;padding:24px 16px}
h1{color:#E0040B;margin:0 0 8px}a.app{display:block;background:#fff;border:1px solid #F1DCD3;border-radius:16px;padding:16px;margin:12px 0;color:inherit;text-decoration:none}
a.app b{display:block;font-size:18px;color:#E0040B}.note{font-size:14px;color:#6B4A3F}code{background:#fff;border:1px solid #F1DCD3;border-radius:6px;padding:1px 5px}</style></head>
<body><main><h1>Try Yummy Chops</h1><p>Test version for Android phones. Install, open, tap <b>Sign up</b> and create your own account.</p>
${built.map((a) => `<a class="app" href="${a.file}"><b>${a.title}</b>${a.note} · ${size(a)}</a>`).join("\n")}
<p class="note">Android may ask you to allow installing from your browser: allow it once. This is a test: shops, riders and prices are made up, and
no real money moves. To pay by card, use Paystack's test card <code>4084 0840 8408 4081</code>, any future expiry date, CVV <code>408</code>,
PIN <code>0000</code> and OTP <code>123456</code>.</p>
<p class="note">Problems or ideas? Write to <a href="mailto:customercare@yummy247.com">customercare@yummy247.com</a>.</p></main></body></html>
`);
console.log(`\nReady in mobile/dist/online: ${built.map((a) => a.file).join(", ") || "no APKs yet"}.`);

if (publish) {
  writeFileSync(join(dist, "firebase.json"), JSON.stringify({
    hosting: {
      public: ".", ignore: ["firebase.json", ".firebaserc"],
      headers: [{ source: "**/*.apk", headers: [{ key: "Content-Type", value: "application/vnd.android.package-archive" }] }],
    },
  }, null, 2));
  const res = spawnSync(isWin ? "firebase.cmd" : "firebase", ["deploy", "--only", "hosting", "--project", env.FIREBASE_PROJECT_ID, "--non-interactive"],
    { cwd: dist, stdio: "inherit", shell: isWin });
  if (res.status !== 0) process.exit(res.status ?? 1);
  console.log(`\nTesters download from https://${env.FIREBASE_PROJECT_ID}.web.app`);
}
