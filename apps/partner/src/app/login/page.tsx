"use client";

import { Button, Card, Field, FullLogo, Input } from "@gudmeal/ui";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { authErrorMessage, useAuth } from "@/lib/auth";

export default function LoginPage() {
  const { signIn } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  return (
    <div className="grid min-h-dvh place-items-center bg-secondary-soft px-4">
      <Card className="w-full max-w-sm space-y-6 p-8">
        <div className="space-y-1 text-center">
          <FullLogo />
          <p className="text-sm font-semibold uppercase tracking-wide text-secondary">Partner</p>
        </div>
        <form className="space-y-4" onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          setError(null);
          try { await signIn(email, password); router.replace("/"); } catch (err) { setError(authErrorMessage(err)); } finally { setBusy(false); }
        }}>
          <Field label="Email" htmlFor="email"><Input id="email" type="email" autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} required /></Field>
          <Field label="Password" htmlFor="pw"><Input id="pw" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required /></Field>
          {error && <p role="alert" className="text-sm text-danger">{error}</p>}
          <Button type="submit" block size="lg" loading={busy}>Sign in</Button>
        </form>
        <p className="text-center text-xs text-muted">New business? Use “Register your business” on the Yummy Chops website.</p>
      </Card>
    </div>
  );
}
