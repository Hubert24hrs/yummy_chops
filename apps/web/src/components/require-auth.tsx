"use client";

import { Button, Skeleton } from "@gudmeal/ui";
import { WifiOff } from "lucide-react";
import type { ReactNode } from "react";
import { useAuth } from "@/lib/auth";

/**
 * Shows the page once someone is signed in: a guest (signed in quietly, ADR-0032) or a saved account. Nobody is asked
 * to sign in here; while the guest sign-in runs the page shows a skeleton, and if it fails, a "Try again".
 */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, guestError, retryGuest } = useAuth();
  if (user) return <>{children}</>;
  if (guestError) return <CantConnect onRetry={retryGuest} />;
  return <div className="container-page space-y-3 py-10" aria-busy="true"><Skeleton className="h-10 w-1/3" /><Skeleton className="h-40" /></div>;
}

export function CantConnect({ onRetry }: { onRetry: () => void }) {
  return (
    <div className="container-page flex flex-col items-center gap-3 py-20 text-center" role="alert">
      <WifiOff className="size-12 text-muted" aria-hidden="true" />
      <h1 className="font-display text-3xl">We can&apos;t connect right now</h1>
      <p className="max-w-md text-muted">Check your internet connection and try again.</p>
      <Button size="lg" onClick={onRetry}>Try again</Button>
    </div>
  );
}
