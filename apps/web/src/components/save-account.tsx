"use client";

import { Button, Card } from "@gudmeal/ui";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState, type ReactNode } from "react";
import { APPLE_SIGN_IN, authErrorMessage, useAuth, type SaveResult } from "@/lib/auth";
import { RequireAuth } from "./require-auth";

/**
 * Continue with Google (and Apple, once it is set up): links Google/Apple to the guest, so the account keeps its
 * orders, wallet and addresses. If that account already exists we sign in to it instead (ADR-0032).
 */
export function SaveAccountButtons({ next = "/account" }: { next?: string }) {
  const { signInWithGoogle, signInWithApple } = useAuth();
  const [busy, setBusy] = useState<"google" | "apple" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<SaveResult | null>(null);

  async function save(kind: "google" | "apple") {
    setBusy(kind);
    setError(null);
    try {
      setResult(await (kind === "google" ? signInWithGoogle() : signInWithApple()));
    } catch (e) {
      setError(authErrorMessage(e));
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-3">
      <Button block size="lg" variant="outline" loading={busy === "google"} disabled={busy !== null} onClick={() => save("google")}>
        Continue with Google
      </Button>
      {APPLE_SIGN_IN && (
        <Button block size="lg" variant="outline" loading={busy === "apple"} disabled={busy !== null} onClick={() => save("apple")}>
          Continue with Apple
        </Button>
      )}
      {error && <p role="alert" className="text-sm text-danger">{error}</p>}
      {result === "switched" && (
        <p role="status" className="text-sm text-secondary">
          You already had an account, so we signed you in to it. Your cart is still here; orders placed as a guest stay with the guest.
        </p>
      )}
      <p className="text-center text-sm">
        <Link href={`/login?next=${encodeURIComponent(next)}`} className="font-semibold text-primary hover:underline">Other ways to sign in</Link>
      </p>
    </div>
  );
}

/**
 * For pages that create something tied to a real person (rider sign-up, rider KYC, business application): the
 * account becomes their login to the Rider or Partner app, and a guest cannot sign in there. A guest is asked, inside
 * the page, to save the account first; everyone else sees the page.
 */
export function RequireSavedAccount({ children, note }: { children: ReactNode; note: string }) {
  const { isGuest } = useAuth();
  const path = usePathname() ?? "/";
  return (
    <RequireAuth>
      {isGuest ? (
        <Card className="space-y-4 p-6">
          <h2 className="font-display text-2xl">Save your account first</h2>
          <p className="text-sm text-muted">{note}</p>
          <SaveAccountButtons next={path} />
        </Card>
      ) : children}
    </RequireAuth>
  );
}
