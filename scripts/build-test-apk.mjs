#!/usr/bin/env node
// Builds Android test APKs of the customer and rider apps that talk to the local stack on THIS computer over Wi-Fi,
// and puts them in mobile/dist with a download page. Then: `node scripts/dev.mjs downloads --lan` and open
// http://<this computer's Wi-Fi address>:8090 on the phone (see docs/LOCAL_DEVELOPMENT.md, "Test on your phone").
// These builds use the Firebase Auth emulator and the payment sandbox: they are for testing, never for the store.
// The apps find this computer on the phone's Wi-Fi by themselves, so a build keeps working after the computer
// joins another Wi-Fi and gets a new address (docs/adr/0020-test-apps-find-the-test-server.md).
//   node scripts/build-test-apk.mjs                  # both apps, for every Android phone
//   node scripts/build-test-apk.mjs rider --arm64    # one app, 64-bit phones only (smaller; needs less disk to build)
//   node scripts/build-test-apk.mjs --page           # only rewrite the download page for the APKs already built
//   node scripts/build-test-apk.mjs --remote --arm64 # the customer app for the public test link: it reaches this
//       computer through https://<REMOTE_LINK_DOMAIN> from anywhere (docs/adr/0024-public-test-link.md)
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { lanIp } from "./lan.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const ip = lanIp();
const args = process.argv.slice(2);
const wanted = args.filter((a) => !a.startsWith("-"));
const arm64 = args.includes("--arm64");
const pageOnly = args.includes("--page");
// --remote[=domain]: the domain comes from .env.remote-link (REMOTE_LINK_DOMAIN) unless given here.
const remoteArg = args.find((a) => a === "--remote" || a.startsWith("--remote="));
const remoteDomain = remoteArg ? remoteArg.split("=")[1] || readRemoteDomain() : null;
// The domain goes into the build's command line (through a shell on Windows): only a plain host name.
if (remoteDomain && !/^[a-z0-9-]+(\.[a-z0-9-]+)+$/i.test(remoteDomain)) {
  console.error(`--remote needs a plain domain such as something.ngrok-free.app, not "${remoteDomain}"`);
  process.exit(2);
}
function readRemoteDomain() {
  const file = join(root, ".env.remote-link");
  const found = existsSync(file) && /^[ \t]*REMOTE_LINK_DOMAIN[ \t]*=[ \t]*(\S+)[ \t]*$/m.exec(readFileSync(file, "utf8"));
  if (!found) {
    console.error("--remote needs your ngrok domain: put REMOTE_LINK_DOMAIN=<it> in .env.remote-link");
    process.exit(2);
  }
  return found[1];
}
const apps = [
  { id: "customer", file: "yummy-chops.apk", title: "Yummy Chops", note: "Order food, supplements and skin care, and send packages" },
  { id: "rider", file: "yummy-chops-rider.apk", title: "Yummy Chops Rider", note: "Accept deliveries and confirm them with the customer's code" },
];

const dist = join(root, "mobile/dist");
mkdirSync(dist, { recursive: true });

// The apps try this computer's address of today first, then the addresses it had at earlier builds, and only
// then search the phone's Wi-Fi (mobile/core/lib/src/test_server.dart). The earlier ones are kept here.
const hostsFile = join(dist, "test-server-hosts.json");
let earlier = [];
try {
  earlier = JSON.parse(readFileSync(hostsFile, "utf8"));
} catch {
  // the first build on this computer
}
const isAddress = (host) => typeof host === "string" && /^\d{1,3}(\.\d{1,3}){3}$/.test(host);
const hosts = [ip, ...(Array.isArray(earlier) ? earlier : []).filter((host) => isAddress(host) && host !== ip)].slice(0, 6);
if (!pageOnly && !remoteDomain) writeFileSync(hostsFile, `${JSON.stringify(hosts, null, 2)}\n`);

// What each kind of build is told about the test server.
const lanDefines = [
  `--dart-define=API_URL=http://${ip}:8000`,
  `--dart-define=AGENTS_URL=http://${ip}:8100`,
  `--dart-define=AUTH_EMULATOR_HOST=${ip}`,
  "--dart-define=FIND_TEST_SERVER=true",
  `--dart-define=TEST_SERVER_HOSTS=${hosts.join("+")}`,
];
// Through the link: the API and Yummy over https, the sign-in emulator over plain http on port 80 (the only way
// Firebase talks to an emulator). The gateway behind the link hands each to its service.
const remoteDefines = [
  `--dart-define=API_URL=https://${remoteDomain}`,
  `--dart-define=AGENTS_URL=https://${remoteDomain}/agents`,
  `--dart-define=AUTH_EMULATOR_HOST=${remoteDomain}`,
  "--dart-define=AUTH_EMULATOR_PORT=80",
  "--dart-define=FIND_TEST_SERVER=false",
];
// A test-link build is for a tester elsewhere: the customer app unless an app is named, saved as *-remote.apk so
// the Wi-Fi builds stay as they are.
const chosen = remoteDomain && wanted.length === 0 ? ["customer"] : wanted;
const outputFile = (app) => (remoteDomain ? app.file.replace(/\.apk$/, "-remote.apk") : app.file);

for (const app of pageOnly ? [] : apps.filter((a) => chosen.length === 0 || chosen.includes(a.id))) {
  console.log(`\n== Building ${app.title} for ${remoteDomain ? `https://${remoteDomain}` : `http://${ip}`} ...`);
  const result = spawnSync(
    "flutter",
    [
      "build", "apk", "--release",
      ...(remoteDomain ? remoteDefines : lanDefines),
      "--dart-define=USE_FIREBASE_EMULATORS=true",
      ...(arm64 ? ["--target-platform", "android-arm64"] : []),
    ],
    // Plain http to this computer is allowed only in these test builds (see android/app/build.gradle.kts).
    { cwd: join(root, "mobile", app.id), stdio: "inherit", shell: process.platform === "win32",
      env: { ...process.env, GUDMEAL_ALLOW_CLEARTEXT: "true" } },
  );
  if (result.status !== 0) process.exit(result.status ?? 1);
  copyFileSync(join(root, "mobile", app.id, "build/app/outputs/flutter-apk/app-release.apk"), join(dist, outputFile(app)));
  // The Android build leaves ~0.5-1 GB of intermediates; they are rebuilt next time, so free the disk now.
  rmSync(join(root, "mobile", app.id, "build/app"), { recursive: true, force: true });
}

if (remoteDomain) {
  // The link serves its own page and download (scripts/remote-gateway.mjs); the Wi-Fi download page stays as it is.
  console.log(`\nReady: send https://${remoteDomain} to your tester (the phone test and the link must be running).`);
  process.exit(0);
}

for (const app of apps) {
  const apk = join(dist, app.file);
  if (existsSync(apk)) app.size = `${(statSync(apk).size / 1024 / 1024).toFixed(0)} MB`;
  // The app's own icon next to its download link, so the two apps are easy to tell apart.
  const icon = join(root, "mobile", app.id, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png");
  if (existsSync(icon)) {
    copyFileSync(icon, join(dist, `${app.id}-icon.png`));
    app.icon = `${app.id}-icon.png`;
  }
}
const ready = apps.filter((a) => a.size);
const built = new Date().toLocaleString("en-GB", { dateStyle: "medium", timeStyle: "short" });
writeFileSync(join(dist, "index.html"), `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Yummy Chops test apps</title>
<style>body{font-family:system-ui,sans-serif;background:#FFFBF8;color:#2A0D06;margin:0;padding:24px}
main{max-width:440px;margin:0 auto}h1{font-size:26px}a.app{display:flex;align-items:center;gap:14px;background:#E0040B;color:#fff;text-decoration:none;
border-radius:14px;padding:18px 20px;margin:14px 0;font-weight:700;font-size:18px}a.app small{display:block;font-weight:400;
font-size:14px;opacity:.9;margin-top:4px}a.app img{width:56px;height:56px;border-radius:13px;flex:none}ol{padding-left:20px;line-height:1.6}.note{font-size:13px;color:#7A625A}</style>
</head><body><main><h1>Yummy Chops test apps</h1>
${ready.map((a) => `<a class="app" href="${a.file}" download>${a.icon ? `<img src="${a.icon}" alt="">` : ""}<span>${a.title} (${a.size})<small>${a.note}</small></span></a>`).join("\n")}
<ol><li>Tap an app to download it, then open the download.</li>
<li>If Android asks, allow your browser to <b>install unknown apps</b>, then tap <b>Install</b>.</li>
<li>Keep this phone on the same Wi-Fi as the computer running Yummy Chops.</li></ol>
<p class="note">Test builds made ${built}${arm64 ? " for 64-bit Android phones" : ""}. They find the computer running Yummy Chops on your Wi-Fi by themselves (it was at ${ip} when this page was made). They use test accounts and a payment sandbox: no real money moves.</p>
</main></body></html>`);
console.log(`\nReady: ${ready.map((a) => a.file).join(", ") || "no APKs yet"} in mobile/dist.`);
console.log(`Serve them with: node scripts/dev.mjs downloads --lan   ->   http://${ip}:8090`);
