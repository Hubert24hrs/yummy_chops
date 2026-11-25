"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { GudyArt } from "./illustrations";

const SIZE = 62;

/** Floating, draggable Yummy button on every page (snaps to the nearest side). Opens the assistant on click. */
export function GudyFab() {
  const router = useRouter();
  const path = usePathname();
  const [pos, setPos] = useState<{ x: number; y: number } | null>(null);
  const [dragging, setDragging] = useState(false);
  const [hint, setHint] = useState(true);
  const drag = useRef<{ id: number; dx: number; dy: number; moved: number } | null>(null);

  useEffect(() => {
    const place = () => setPos((p) => p ?? { x: window.innerWidth - SIZE - 16, y: window.innerHeight - SIZE - (window.innerWidth < 768 ? 96 : 28) });
    place();
    const t = window.setTimeout(() => setHint(false), 6000);
    const onResize = () => setPos((p) => (p ? clamp(p.x, p.y) : p));
    window.addEventListener("resize", onResize);
    return () => {
      window.clearTimeout(t);
      window.removeEventListener("resize", onResize);
    };
  }, []);

  // Not over the cart and checkout bars at the bottom either.
  if (!pos || path?.startsWith("/assistant") || path === "/cart" || path?.startsWith("/checkout")) return null;
  const onRight = pos.x > window.innerWidth / 2;

  return (
    <div className="fixed z-40" style={{ left: pos.x, top: pos.y, width: SIZE, height: SIZE, transition: dragging ? "none" : "left .35s cubic-bezier(.34,1.56,.64,1)" }}>
      {hint && !dragging && (
        <span
          className={`pointer-events-none absolute top-3 whitespace-nowrap rounded-xl bg-white px-3 py-2 text-sm font-bold text-[#2A0D06] shadow-lg ${onRight ? "right-[70px]" : "left-[70px]"}`}
        >
          Hi, I’m Yummy!
        </span>
      )}
      <button
        type="button"
        aria-label="Chat with Yummy, your AI assistant"
        title="Chat with Yummy"
        className="gm-pulse block size-full touch-none rounded-full shadow-[0_6px_16px_rgba(58,13,5,.35)] outline-none transition-transform focus-visible:ring-4 focus-visible:ring-[#6B2410]/40 data-[dragging=true]:scale-110"
        data-dragging={dragging}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          drag.current = { id: e.pointerId, dx: e.clientX - pos.x, dy: e.clientY - pos.y, moved: 0 };
        }}
        onPointerMove={(e) => {
          const d = drag.current;
          if (!d || d.id !== e.pointerId) return;
          const next = clamp(e.clientX - d.dx, e.clientY - d.dy);
          d.moved += Math.abs(next.x - pos.x) + Math.abs(next.y - pos.y);
          if (d.moved > 4) {
            setDragging(true);
            setHint(false);
          }
          setPos(next);
        }}
        onPointerUp={(e) => {
          const d = drag.current;
          drag.current = null;
          if (!d || d.id !== e.pointerId) return;
          if (d.moved <= 4) {
            router.push("/assistant");
            return;
          }
          setDragging(false);
          setPos((p) => (p ? clamp(p.x + SIZE / 2 < window.innerWidth / 2 ? 12 : window.innerWidth - SIZE - 12, p.y) : p));
        }}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            router.push("/assistant");
          }
        }}
      >
        <GudyArt blink className="size-full" />
      </button>
    </div>
  );
}

function clamp(x: number, y: number) {
  const bottom = window.innerWidth < 768 ? 84 : 12;
  return {
    x: Math.min(Math.max(x, 8), window.innerWidth - SIZE - 8),
    y: Math.min(Math.max(y, 72), window.innerHeight - SIZE - bottom),
  };
}
