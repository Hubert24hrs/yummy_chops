"use client";

import {
  GoogleAuthProvider,
  createUserWithEmailAndPassword,
  onIdTokenChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
  updateProfile,
  type User,
} from "firebase/auth";
import { useQueryClient } from "@tanstack/react-query";
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { firebaseAuth } from "./firebase";

interface AuthState {
  user: User | null;
  loading: boolean;
  getToken: () => Promise<string | null>;
  /** A fresh sign-in token now, e.g. after the account became a rider (the token carries the role). */
  refreshToken: () => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (name: string, email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const queryClient = useQueryClient();

  useEffect(() => {
    const auth = firebaseAuth();
    let uid: string | null | undefined; // undefined until Firebase says who is signed in
    return onIdTokenChanged(auth, (u) => {
      // Someone else (or nobody) is signed in now: nothing the last account loaded may stay in memory.
      if (uid !== undefined && uid !== (u?.uid ?? null)) queryClient.clear();
      uid = u?.uid ?? null;
      setUser(u);
      setLoading(false);
    });
  }, [queryClient]);

  const value = useMemo<AuthState>(() => ({
    user,
    loading,
    getToken: async () => (firebaseAuth().currentUser ? firebaseAuth().currentUser!.getIdToken() : null),
    refreshToken: async () => {
      await firebaseAuth().currentUser?.getIdToken(true);
    },
    signIn: async (email, password) => {
      await signInWithEmailAndPassword(firebaseAuth(), email, password);
    },
    signUp: async (name, email, password) => {
      const cred = await createUserWithEmailAndPassword(firebaseAuth(), email, password);
      await updateProfile(cred.user, { displayName: name });
      await cred.user.getIdToken(true);
    },
    signInWithGoogle: async () => {
      await signInWithPopup(firebaseAuth(), new GoogleAuthProvider());
    },
    signOut: () => signOut(firebaseAuth()),
  }), [user, loading]);

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
  if (code.includes("email-already-in-use")) return "An account with this email already exists.";
  if (code.includes("weak-password")) return "Use at least 6 characters for your password.";
  if (code.includes("network-request-failed")) return "Network error — check your connection.";
  if (code.includes("popup-closed")) return "Sign-in was cancelled.";
  return "We couldn't sign you in. Please try again.";
}
