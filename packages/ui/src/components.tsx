"use client";

import { cn } from "./utils";
import type { ButtonHTMLAttributes, HTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from "react";
import { forwardRef, useEffect, useId, useRef } from "react";
import { ORDER_STATUS, formatNaira, type OrderStatus, type Tone } from "@gudmeal/api-client";

// ------------------------------------------------------------------------------------- Button
type ButtonVariant = "primary" | "secondary" | "outline" | "ghost" | "danger";
type ButtonSize = "sm" | "md" | "lg";

const variants: Record<ButtonVariant, string> = {
  primary: "bg-primary text-on-primary hover:bg-primary-strong shadow-sm",
  secondary: "bg-secondary text-on-secondary hover:opacity-90 shadow-sm",
  outline: "border border-border bg-surface text-text hover:bg-surface-muted",
  ghost: "text-text hover:bg-surface-muted",
  danger: "bg-danger text-white hover:opacity-90",
};
const sizes: Record<ButtonSize, string> = {
  sm: "h-8 px-3 text-sm gap-1.5",
  md: "h-10 px-4 text-sm gap-2",
  lg: "h-12 px-6 text-base gap-2",
};

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  block?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", size = "md", loading, block, className, children, disabled, type = "button", ...rest }, ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cn(
        "inline-flex items-center justify-center whitespace-nowrap rounded-full font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50",
        variants[variant], sizes[size], block && "w-full", className,
      )}
      {...rest}
    >
      {loading && <Spinner className="size-4" />}
      {children}
    </button>
  );
});

export function Spinner({ className }: { className?: string }) {
  return (
    <svg className={cn("animate-spin", className)} viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeOpacity=".25" strokeWidth="3" />
      <path d="M21 12a9 9 0 0 0-9-9" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
}

// ------------------------------------------------------------------------------------- Surfaces
export function Card({ className, ...rest }: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("rounded-lg border border-border bg-surface shadow-card", className)} {...rest} />;
}

const tones: Record<Tone, string> = {
  neutral: "bg-surface-muted text-muted",
  info: "bg-[color-mix(in_srgb,var(--gm-info)_14%,transparent)] text-info",
  progress: "bg-primary-soft text-primary-strong",
  success: "bg-secondary-soft text-secondary",
  warning: "bg-accent-soft text-warning",
  danger: "bg-[color-mix(in_srgb,var(--gm-danger)_12%,transparent)] text-danger",
};

export function Badge({ tone = "neutral", className, children }: { tone?: Tone; className?: string; children: ReactNode }) {
  return (
    <span className={cn("inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold", tones[tone], className)}>
      {children}
    </span>
  );
}

export function StatusBadge({ status }: { status: OrderStatus }) {
  const s = ORDER_STATUS[status];
  return <Badge tone={s.tone}>{s.label}</Badge>;
}

export function Price({ kobo, className, strike }: { kobo: number | null | undefined; className?: string; strike?: boolean }) {
  return <span className={cn("tabular-nums", strike && "line-through text-muted", className)}>{formatNaira(kobo)}</span>;
}

export function Skeleton({ className }: { className?: string }) {
  return <div className={cn("gm-skeleton rounded-md", className)} aria-hidden="true" />;
}

export function EmptyState({ title, body, action, icon }: { title: string; body?: string; action?: ReactNode; icon?: ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 rounded-lg border border-dashed border-border px-6 py-12 text-center">
      {icon && <div className="text-primary">{icon}</div>}
      <p className="font-display text-xl">{title}</p>
      {body && <p className="max-w-sm text-sm text-muted">{body}</p>}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div role="alert" className="flex flex-col items-start gap-3 rounded-lg border border-danger/30 bg-surface p-4 text-sm">
      <p className="font-semibold text-danger">Something went wrong</p>
      <p className="text-muted">{message}</p>
      {onRetry && <Button size="sm" variant="outline" onClick={onRetry}>Try again</Button>}
    </div>
  );
}

export function Stat({ label, value, hint, tone }: { label: string; value: ReactNode; hint?: ReactNode; tone?: "danger" | "success" }) {
  return (
    <Card className="p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-muted">{label}</p>
      <p className={cn("mt-1 font-display text-3xl tabular-nums", tone === "danger" && "text-danger", tone === "success" && "text-secondary")}>{value}</p>
      {hint && <p className="mt-1 text-xs text-muted">{hint}</p>}
    </Card>
  );
}

// ------------------------------------------------------------------------------------- Forms
export function Field({ label, error, hint, children, htmlFor }: { label: string; error?: string; hint?: string; children: ReactNode; htmlFor?: string }) {
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={htmlFor} className="text-sm font-semibold">{label}</label>
      {children}
      {hint && !error && <p className="text-xs text-muted">{hint}</p>}
      {error && <p className="text-xs font-medium text-danger" role="alert">{error}</p>}
    </div>
  );
}

const inputBase = "w-full rounded-md border border-border bg-surface px-3 text-sm text-text placeholder:text-muted focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20 disabled:opacity-60";

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(function Input({ className, ...rest }, ref) {
  return <input ref={ref} className={cn(inputBase, "h-11", className)} {...rest} />;
});

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(function Textarea({ className, ...rest }, ref) {
  return <textarea ref={ref} className={cn(inputBase, "min-h-24 py-2", className)} {...rest} />;
});

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Select({ className, ...rest }, ref) {
  return <select ref={ref} className={cn(inputBase, "h-11", className)} {...rest} />;
});

/**
 * Switch with a visible label. Pass `ariaLabel` when several switches share the same visible text
 * (e.g. "Open" per weekday) so screen-reader users can tell them apart; keep the visible text inside it.
 */
export function Toggle({ checked, onChange, label, disabled, ariaLabel }: { checked: boolean; onChange: (v: boolean) => void; label: string; disabled?: boolean; ariaLabel?: string }) {
  const id = useId();
  return (
    <label htmlFor={id} className={cn("inline-flex cursor-pointer items-center gap-2 text-sm", disabled && "cursor-not-allowed opacity-60")}>
      <span className="relative inline-flex">
        <input id={id} type="checkbox" role="switch" aria-label={ariaLabel} className="peer sr-only" checked={checked} disabled={disabled}
          onChange={(e) => onChange(e.target.checked)} />
        <span className="h-6 w-11 rounded-full bg-border transition-colors peer-checked:bg-secondary" />
        <span className="absolute left-0.5 top-0.5 size-5 rounded-full bg-white shadow transition-transform peer-checked:translate-x-5" />
      </span>
      <span>{label}</span>
    </label>
  );
}

// ------------------------------------------------------------------------------------- Dialog
export function Dialog({ open, onClose, title, children, footer }: { open: boolean; onClose: () => void; title: string; children: ReactNode; footer?: ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (open && !el.open) el.showModal();
    if (!open && el.open) el.close();
  }, [open]);
  return (
    <dialog
      ref={ref}
      onClose={onClose}
      onClick={(e) => { if (e.target === ref.current) onClose(); }}
      className="m-auto w-[min(560px,calc(100vw-32px))] rounded-xl border border-border bg-surface p-0 text-text shadow-raised backdrop:bg-black/40"
    >
      <div className="flex max-h-[85vh] flex-col">
        <div className="flex items-center justify-between border-b border-border px-5 py-4">
          <h2 className="font-display text-xl">{title}</h2>
          <button onClick={onClose} className="rounded-full p-1 text-muted hover:bg-surface-muted" aria-label="Close">✕</button>
        </div>
        <div className="overflow-y-auto px-5 py-4">{children}</div>
        {footer && <div className="border-t border-border px-5 py-4">{footer}</div>}
      </div>
    </dialog>
  );
}

// ------------------------------------------------------------------------------------- Brand
/**
 * The Yummy Chops logo: the emblem (the chef under her arch, with the "Yummy Chops" ribbon) beside the name
 * "Yummy247", both cut from the brand logo (assets/brand/yummychops-logo.webp, docs/adr/0029-new-logo-and-app-icon.md;
 * scripts/make-brand-assets.py writes them to each website's public/brand).
 * The name's dark-brown "Yummy" turns cream wherever it sits on something dark: on the page in dark mode
 * (`surface="page"`), or on a panel drawn in the text colour, which is dark in light mode (`surface="inverse"`).
 */
export function Logo({ className, withWordmark = true, surface = "page" }: {
  className?: string; withWordmark?: boolean; surface?: "page" | "inverse";
}) {
  const darkName = "/brand/yummychops-wordmark.png";
  const creamName = "/brand/yummychops-wordmark-light.png";
  const [normal, inDarkMode] = surface === "inverse" ? [creamName, darkName] : [darkName, creamName];
  return (
    <span className={cn("inline-flex shrink-0 items-center gap-1.5", className)}>
      {/* eslint-disable-next-line @next/next/no-img-element -- small static brand files, no image optimisation needed */}
      <img src="/brand/yummychops-emblem.png" alt="" width={44} height={36} className="h-9 w-auto" />
      {withWordmark ? (
        <picture>
          <source srcSet={inDarkMode} media="(prefers-color-scheme: dark)" />
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={normal} alt="Yummy247" width={165} height={28} className="h-7 w-auto" />
        </picture>
      ) : (
        <span className="sr-only">Yummy Chops</span>
      )}
    </span>
  );
}

/**
 * The whole Yummy Chops logo (the chef, the names, the tagline, the rider and the badges), for sign-in pages like the
 * apps' sign-in screens. It sits on white, as in the apps, so its dark brown still reads in dark mode.
 */
export function FullLogo({ className, size = 160 }: { className?: string; size?: number }) {
  return (
    <span className={cn("inline-block rounded-3xl bg-white p-2", className)}>
      {/* eslint-disable-next-line @next/next/no-img-element -- a small static brand file, no image optimisation needed */}
      <img src="/brand/yummychops-logo.webp" alt="Yummy Chops" width={size} height={size} className="block" />
    </span>
  );
}

// ------------------------------------------------------------------------------------- Table
export interface Column<T> { key: string; header: string; render: (row: T) => ReactNode; className?: string }

export function DataTable<T>({ rows, columns, rowKey, empty, onRowClick }: {
  rows: T[]; columns: Column<T>[]; rowKey: (row: T) => string; empty?: string; onRowClick?: (row: T) => void;
}) {
  if (!rows.length) return <EmptyState title={empty ?? "Nothing here yet"} />;
  return (
    <div className="overflow-x-auto rounded-lg border border-border bg-surface">
      <table className="w-full min-w-[640px] text-left text-sm">
        <thead className="border-b border-border bg-surface-muted text-xs uppercase tracking-wide text-muted">
          <tr>{columns.map((c) => <th key={c.key} className={cn("px-4 py-3 font-semibold", c.className)}>{c.header}</th>)}</tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={rowKey(row)} onClick={onRowClick ? () => onRowClick(row) : undefined}
              className={cn("border-b border-border last:border-0", onRowClick && "cursor-pointer hover:bg-surface-muted")}>
              {columns.map((c) => <td key={c.key} className={cn("px-4 py-3 align-middle", c.className)}>{c.render(row)}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ------------------------------------------------------------------------------------- Charts
export function BarChart({ data, format = (v) => String(v), height = 160, label }: {
  data: { label: string; value: number }[]; format?: (v: number) => string; height?: number; label: string;
}) {
  const max = Math.max(1, ...data.map((d) => d.value));
  return (
    <figure aria-label={label} className="w-full">
      <div className="flex items-end gap-1.5" style={{ height }}>
        {data.map((d) => (
          <div key={d.label} className="group relative flex h-full flex-1 flex-col justify-end">
            <div className="rounded-t-sm bg-primary/85 transition-colors group-hover:bg-primary"
              style={{ height: `${Math.max(2, (d.value / max) * 100)}%` }} />
            <span className="pointer-events-none absolute -top-7 left-1/2 hidden -translate-x-1/2 whitespace-nowrap rounded bg-text px-1.5 py-0.5 text-[11px] text-background group-hover:block">
              {format(d.value)}
            </span>
          </div>
        ))}
      </div>
      <div className="mt-2 flex gap-1.5 text-[10px] text-muted">
        {data.map((d, i) => (
          <span key={d.label} className="flex-1 text-center">{i % Math.ceil(data.length / 7) === 0 ? d.label : ""}</span>
        ))}
      </div>
    </figure>
  );
}
