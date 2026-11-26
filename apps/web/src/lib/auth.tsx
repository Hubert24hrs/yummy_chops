"use client";

import {
  EmailAuthProvider,
  GoogleAuthProvider,
  OAuthProvider,
  createUserWithEmailAndPassword,
  linkWithCredential,
  linkWithPopup,
  onIdTokenChanged,
  signInAnonymously,
  signInWithCredential,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  updateProfile,
  type AuthCredential,
  type AuthProvider as FirebaseAuthProvider,
  type User,
} from "firebase/auth";
import { useQueryClient } from "@tanstack/react-query";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { firebaseAuth } from "./firebase";

/**
 * How saving the account with Google/Apple went: "linked" kept the guest account (its orders, wallet and addresses)
 * and added the provider to it; "switched" means that Google/Apple account already existed, so we signed in to it
 * instead (the cart stays in this browser; the guest's orders stay with the guest); "signed-in" is a plain sign-in.
 */
export type SaveResult = "linked" | "switched" | "signed-in";

interface AuthState {
  user: User | null;
  /** Firebase has not said yet who is signed in. */
  loading: boolean;
  /** The signed-in user is a guest (Firebase anonymous sign-in, ADR-0032). */
  isGuest: boolean;
  /** The quiet guest sign-in failed (no network, ...); `retryGuest` tries again. */
  guestError: unknown;
  retryGuest: () => Promise<void>;
  /** True from the moment a fresh guest is signed in until they have been asked where to deliver. */
  askWhereToDeliver: boolean;
  askedWhereToDeliver: () => void;
  getToken: () => Promise<string | null>;
  /** A fresh sign-in token now, e.g. after the account became a rider (the token carries the role). */
  refreshToken: () => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  /** Creates an email account; from a guest it links the email to the guest so the account keeps its orders. */
  signUp: (name: string, email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<SaveResult>;
  signInWithApple: () => Promise<SaveResult>;
  /** Signs out; a fresh guest is signed in right after. */
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

/** Apple sign-in shows only once it is set up (Apple Developer account, Firebase provider): ADR-0032. */
export const APPLE_SIGN_IN = process.env.NEXT_PUBLIC_APPLE_SIGN_IN === "true";

function credentialFromError(provider: "google" | "apple", err: unknown): AuthCredential | null {
  const e = err as Parameters<typeof GoogleAuthProvider.credentialFromError>[0];
  return provider === "google" ? GoogleAuthProvider.credentialFromError(e) : OAuthProvider.credentialFromError(e);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isGuest, setIsGuest] = useState(false);
  const [loading, setLoading] = useState(true);
  const [guestError, setGuestError] = useState<unknown>(null);
  const [askWhereToDeliver, setAskWhereToDeliver] = useState(false);
  const [, setVersion] = useState(0);
  const guestBusy = useRef(false);

  const queryClient = useQueryClient();

  /** The user object stays the same when a guest is linked: read it again so the page shows the saved account. */
  const sync = useCallback(() => {
    const current = firebaseAuth().currentUser;
    setUser(current);
    setIsGuest(Boolean(current?.isAnonymous));
    setVersion((v) => v + 1);
  }, []);

  const signInGuest = useCallback(async () => {
    const auth = firebaseAuth();
    if (guestBusy.current || auth.currentUser) return;
    guestBusy.current = true;
    setGuestError(null);
    try {
      await signInAnonymously(auth);
      setAskWhereToDeliver(true);
    } catch (e) {
      setGuestError(e ?? new Error("guest sign-in failed"));
    } finally {
      guestBusy.current = false;
    }
  }, []);

  useEffect(() => {
    const auth = firebaseAuth();
    let uid: string | null | undefined; // undefined until Firebase says who is signed in
    return onIdTokenChanged(auth, (u) => {
      // Someone else (or nobody) is signed in now: nothing the last account loaded may stay in memory.
      if (uid !== undefined && uid !== (u?.uid ?? null)) queryClient.clear();
      uid = u?.uid ?? null;
      setUser(u);
      setIsGuest(Boolean(u?.isAnonymous));
      setVersion((v) => v + 1);
      setLoading(false);
      // Guest mode (ADR-0032): nobody has to sign in to order, so nobody signed in means a guest, quietly.
      if (!u) void signInGuest();
    });
  }, [queryClient, signInGuest]);

  // Stable, so API clients made from it (lib/api.ts) do not change on every sign-in state update.
  const getToken = useCallback(async () => (firebaseAuth().currentUser ? firebaseAuth().currentUser!.getIdToken() : null), []);
  const refreshToken = useCallback(async () => {
    await firebaseAuth().currentUser?.getIdToken(true);
  }, []);

  const value = useMemo<AuthState>(() => {
    async function withProvider(kind: "google" | "apple"): Promise<SaveResult> {
      const auth = firebaseAuth();
      const provider: FirebaseAuthProvider = kind === "google" ? new GoogleAuthProvider() : new OAuthProvider("apple.com");
      const current = auth.currentUser;
      if (!current?.isAnonymous) {
        await signInWithPopup(auth, provider);
        sync();
        return "signed-in";
      }
      try {
        await linkWithPopup(current, provider);
        await current.getIdToken(true);
        sync();
        await queryClient.invalidateQueries({ queryKey: ["profile"] });
        return "linked";
      } catch (err) {
        const code = (err as { code?: string })?.code ?? "";
        const credential = code.includes("credential-already-in-use") ? credentialFromError(kind, err) : null;
        if (!credential) throw err;
        await signInWithCredential(auth, credential); // that account exists: sign in to it (the cart stays)
        sync();
        return "switched";
      }
    }

    return {
      user,
      loading,
      isGuest,
      guestError,
      retryGuest: signInGuest,
      askWhereToDeliver,
      askedWhereToDeliver: () => setAskWhereToDeliver(false),
      getToken,
      refreshToken,
      signIn: async (email, password) => {
        await signInWithEmailAndPassword(firebaseAuth(), email, password);
      },
      signUp: async (name, email, password) => {
        const auth = firebaseAuth();
        const current = auth.currentUser;
        const account = current?.isAnonymous
          ? (await linkWithCredential(current, EmailAuthProvider.credential(email, password))).user
          : (await createUserWithEmailAndPassword(auth, email, password)).user;
        await updateProfile(account, { displayName: name });
        await account.getIdToken(true);
        sync();
      },
      signInWithGoogle: () => withProvider("google"),
      signInWithApple: () => withProvider("apple"),
      signOut: () => signOut(firebaseAuth()),
    };
  }, [user, loading, isGuest, guestError, askWhereToDeliver, signInGuest, sync, queryClient, getToken, refreshToken]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}

export function authErrorMessage(err: unknown): string {
  const code = (err as { code?: string })?.code ?? "";
  if (code.includes("invalid-credential") || code.includes("wrong-password") || code.includes("user-not-found")) {
    return "That email and password don't match.";
  }
  if (code.includes("email-already-in-use")) return "An account with this email already exists. Sign in instead.";
  if (code.includes("credential-already-in-use")) return "That account is already in use. Sign in to it instead.";
  if (code.includes("weak-password")) return "Use at least 6 characters for your password.";
  if (code.includes("network-request-failed")) return "Network error — check your connection.";
  if (code.includes("popup-closed") || code.includes("cancelled-popup-request")) return "Sign-in was cancelled.";
  if (code.includes("popup-blocked")) return "Your browser blocked the sign-in window. Allow pop-ups and try again.";
  return "We couldn't sign you in. Please try again.";
}
