"use client";

import { cn } from "@gudmeal/ui";
import { X } from "lucide-react";
import { useEffect, useId, useRef, type ReactNode } from "react";

/**
 * A sheet that slides up from the bottom on phones and sits in the middle of the screen on wider screens. Used by
 * the cart and checkout for small questions (allergies, phone number, "is this address correct?").
 */
export function Sheet({ open, onClose, title, children, footer, hideTitle, className }: {
  open: boolean; onClose: () => void; title: string; children?: ReactNode; footer?: ReactNode;
  /** Keep the title for screen readers only (the sheet draws its own big heading). */
  hideTitle?: boolean; className?: string;
}) {
  const panel = useRef<HTMLDivElement>(null);
  const titleId = useId();

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    const before = document.activeElement as HTMLElement | null;
    const first = panel.current?.querySelector<HTMLElement>("input, textarea, select, [data-autofocus]") ?? panel.current;
    first?.focus();
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = overflow;
      before?.focus?.();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- only when it opens or closes
  }, [open]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center sm:p-6">
      <button type="button" className="absolute inset-0 bg-black/45" aria-label="Close" tabIndex={-1} onClick={onClose} />
      <div ref={panel} role="dialog" aria-modal="true" aria-labelledby={titleId} tabIndex={-1}
        className={cn("relative flex max-h-[90dvh] w-full flex-col rounded-t-[28px] bg-surface text-text shadow-raised outline-none",
          "pb-[env(safe-area-inset-bottom)] sm:max-w-md sm:rounded-[28px]", className)}>
        <div className="mx-auto mt-2.5 h-1.5 w-10 shrink-0 rounded-full bg-border sm:hidden" aria-hidden="true" />
        <div className={cn("flex items-start justify-between gap-3 px-6 pt-4", hideTitle && "sr-only")}>
          <h2 id={titleId} className="font-display text-2xl leading-tight">{title}</h2>
          <button type="button" onClick={onClose} aria-label="Close"
            className="grid size-9 shrink-0 place-items-center rounded-full bg-surface-muted hover:bg-border">
            <X className="size-4" aria-hidden="true" />
          </button>
        </div>
        <div className="overflow-y-auto px-6 py-4">{children}</div>
        {footer && <div className="space-y-2 px-6 pb-6 pt-1">{footer}</div>}
      </div>
    </div>
  );
}
