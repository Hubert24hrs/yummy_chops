"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { useApi } from "@/lib/api";
import { useAuth } from "@/lib/auth";

/**
 * Pages where being sent to "Where should we deliver?" would get in the way; the question waits for the next page.
 * The cart and checkout too: checkout asks for the address itself, and a guest with a leftover cart is about to pay.
 */
const NOT_HERE = ["/where-to-deliver", "/login", "/cart", "/checkout", "/ride", "/partner-with-us", "/track", "/help"];

/**
 * Guest mode (ADR-0032): nobody signs in through /login any more, so a fresh guest is asked where to deliver once,
 * as in the app, and only when the account has no saved address. Reading the address book never blocks the page.
 */
export function WhereToDeliverPrompt() {
  const { user, askWhereToDeliver, askedWhereToDeliver } = useAuth();
  const api = useApi();
  const router = useRouter();
  const path = usePathname() ?? "/";

  useEffect(() => {
    if (!askWhereToDeliver || !user) return;
    // Already on the question (e.g. sent there by the sign-in page): asked, so "Not now" is not followed by it again.
    if (path === "/where-to-deliver") {
      askedWhereToDeliver();
      return;
    }
    if (NOT_HERE.some((p) => path === p || path.startsWith(`${p}/`))) return;
    askedWhereToDeliver(); // once: the answer below is not cancelled when this page re-renders
    api.me.addresses().then((saved) => {
      if (saved.length === 0) router.replace(`/where-to-deliver?next=${encodeURIComponent(path)}`);
    }, () => undefined);
  }, [askWhereToDeliver, user, path, api, router, askedWhereToDeliver]);

  return null;
}
