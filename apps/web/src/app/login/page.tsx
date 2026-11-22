"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Card, Field, FullLogo, Input } from "@gudmeal/ui";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { useApi } from "@/lib/api";
import { authErrorMessage, useAuth } from "@/lib/auth";
import { safeNext } from "@/lib/next-path";

const schema = z.object({
  name: z.string().max(80).optional(),
  email: z.email("Enter a valid email"),
  password: z.string().min(6, "At least 6 characters"),
});
type Values = z.infer<typeof schema>;

export default function LoginPage() {
  return <Suspense><Login /></Suspense>;
}

function Login() {
  const { signIn, signUp, signInWithGoogle } = useAuth();
  const api = useApi();
  const router = useRouter();
  const next = useSearchParams().get("next") ?? "/";
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [error, setError] = useState<string | null>(null);
  const { register, handleSubmit, formState } = useForm<Values>({ resolver: zodResolver(schema) });

  // Then on to `next` (same-site paths only). A customer with no saved address first chooses where to deliver: GPS,
  // typing it, or the map, as in the app. Reading the address book never blocks signing in.
  const done = async () => {
    const target = safeNext(next);
    try {
      if ((await api.me.addresses()).length === 0) {
        router.replace(`/where-to-deliver?next=${encodeURIComponent(target)}`);
        return;
      }
    } catch {
      /* go on without asking */
    }
    router.replace(target);
  };

  const onSubmit = handleSubmit(async (v) => {
    setError(null);
    try {
      if (mode === "signup") await signUp(v.name?.trim() || "Yummy Chops customer", v.email, v.password);
      else await signIn(v.email, v.password);
      await done();
    } catch (e) {
      setError(authErrorMessage(e));
    }
  });

  return (
    <div className="container-page grid place-items-center py-14">
      <Card className="w-full max-w-md space-y-6 p-8">
        <div className="space-y-2 text-center">
          <FullLogo />
          <h1 className="font-display text-2xl">{mode === "signin" ? "Welcome back" : "Create your account"}</h1>
        </div>
        <form onSubmit={onSubmit} className="space-y-4" noValidate>
          {mode === "signup" && (
            <Field label="Your name" htmlFor="name"><Input id="name" autoComplete="name" {...register("name")} /></Field>
          )}
          <Field label="Email" htmlFor="email" error={formState.errors.email?.message}>
            <Input id="email" type="email" autoComplete="email" {...register("email")} />
          </Field>
          <Field label="Password" htmlFor="password" error={formState.errors.password?.message}>
            <Input id="password" type="password" autoComplete={mode === "signin" ? "current-password" : "new-password"} {...register("password")} />
          </Field>
          {error && <p role="alert" className="text-sm text-danger">{error}</p>}
          <Button type="submit" block size="lg" loading={formState.isSubmitting}>{mode === "signin" ? "Sign in" : "Create account"}</Button>
        </form>
        <Button variant="outline" block onClick={async () => { try { await signInWithGoogle(); await done(); } catch (e) { setError(authErrorMessage(e)); } }}>
          Continue with Google
        </Button>
        <p className="text-center text-sm text-muted">
          {mode === "signin" ? "New to Yummy Chops?" : "Already have an account?"}{" "}
          <button className="font-semibold text-primary" onClick={() => setMode(mode === "signin" ? "signup" : "signin")}>
            {mode === "signin" ? "Create an account" : "Sign in"}
          </button>
        </p>
      </Card>
    </div>
  );
}
