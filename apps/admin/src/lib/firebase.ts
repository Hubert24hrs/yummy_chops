"use client";

import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getToken, initializeAppCheck, ReCaptchaEnterpriseProvider, type AppCheck } from "firebase/app-check";
import { browserSessionPersistence, connectAuthEmulator, getAuth, setPersistence, type Auth } from "firebase/auth";

let app: FirebaseApp | undefined;
let auth: Auth | undefined;
let appCheck: AppCheck | undefined;

// reCAPTCHA Enterprise site key for Firebase App Check. In production the API refuses signed-in calls that have no
// App Check token. Locally (emulators, no key) App Check stays off and the API does not ask for it.
const APP_CHECK_SITE_KEY = process.env.NEXT_PUBLIC_APP_CHECK_SITE_KEY;

function firebaseApp(): FirebaseApp {
  if (app) return app;
  app = getApps().length
    ? getApp()
    : initializeApp({
        apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "demo-api-key",
        authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? "demo-gudmeal.firebaseapp.com",
        projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "demo-gudmeal",
        appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
      });
  if (APP_CHECK_SITE_KEY && typeof window !== "undefined") {
    appCheck = initializeAppCheck(app, {
      provider: new ReCaptchaEnterpriseProvider(APP_CHECK_SITE_KEY),
      isTokenAutoRefreshEnabled: true,
    });
  }
  return app;
}

export function firebaseAuth(): Auth {
  if (auth) return auth;
  auth = getAuth(firebaseApp());
  if (process.env.NEXT_PUBLIC_USE_FIREBASE_EMULATORS === "true") {
    connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  }
  // The Command Centre keeps staff signed in only while the browser is open: closing it signs them out, so a shared
  // computer is not left signed in. (After the emulator line: that one must come before anything else uses `auth`.)
  void setPersistence(auth, browserSessionPersistence).catch(() => undefined);
  return auth;
}

/** App Check token for signed-in calls to the Yummy Chops API, or null while App Check is off (no site key). */
export async function appCheckToken(): Promise<string | null> {
  if (!APP_CHECK_SITE_KEY || typeof window === "undefined") return null;
  firebaseApp();
  if (!appCheck) return null;
  try {
    return (await getToken(appCheck)).token;
  } catch {
    return null; // the API then answers "App Check token required", which the page shows
  }
}
