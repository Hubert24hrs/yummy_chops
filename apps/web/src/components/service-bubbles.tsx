"use client";

import { useRouter } from "next/navigation";
import { cn } from "@gudmeal/ui";
import { useEffect, useRef, type ReactNode } from "react";

export interface BubbleSpec {
  id: string;
  label: string;
  href: string;
  art: ReactNode;
  /** Relative diameter (1 = default). */
  size?: number;
}

interface Body {
  home: { x: number; y: number };
  pos: { x: number; y: number };
  vel: { x: number; y: number };
  target: { x: number; y: number };
  r: number;
  phase: number;
  dragging: boolean;
  moved: number;
  pointerId: number | null;
  last: { x: number; y: number; t: number };
}

const LAYOUT = [
  { x: 0.29, y: 0.33 },
  { x: 0.72, y: 0.36 },
  { x: 0.49, y: 0.75 },
];
/** Five or more services share the field: two rows of three, as in the mobile app. */
const LAYOUT_MANY = [
  { x: 0.19, y: 0.19 },
  { x: 0.5, y: 0.16 },
  { x: 0.81, y: 0.19 },
  { x: 0.19, y: 0.65 },
  { x: 0.5, y: 0.62 },
  { x: 0.81, y: 0.65 },
];

/**
 * Yummy Chops' services as animated, draggable bubbles (home hero). Bubbles float, follow the pointer when
 * dragged (pushing neighbours aside) and spring back when released; a click or Enter opens the service.
 * Floating is off when the user prefers reduced motion.
 */
export function ServiceBubbles({ bubbles, height = 340 }: { bubbles: BubbleSpec[]; height?: number }) {
  const router = useRouter();
  const field = useRef<HTMLDivElement>(null);
  const els = useRef<(HTMLAnchorElement | null)[]>([]);
  const bodies = useRef<Body[]>([]);
  const many = bubbles.length > 4;

  useEffect(() => {
    const root = field.current;
    if (!root) return;
    const reduce = typeof window.matchMedia === "function" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;
    let t = 0;
    let last = performance.now();
    let width = root.clientWidth;

    const inBounds = (x: number, y: number, r: number) => ({
      x: Math.min(Math.max(x, r), Math.max(r, width - r)),
      y: Math.min(Math.max(y, r), Math.max(r, height - r - 14)),
    });

    const layout = () => {
      width = root.clientWidth;
      const spots = many ? LAYOUT_MANY : LAYOUT;
      const base = many ? Math.min(width * 0.135, 62) : Math.min(width * 0.17, 76);
      bubbles.forEach((b, i) => {
        const r = base * (b.size ?? 1);
        const rel = spots[i % spots.length]!;
        const home = inBounds(rel.x * width, rel.y * height, r);
        const body = bodies.current[i];
        if (body) {
          body.home = home;
          body.r = r;
        } else {
          bodies.current[i] = {
            home, pos: { ...home }, vel: { x: 0, y: 0 }, target: { ...home }, r, phase: i * 1.7,
            dragging: false, moved: 0, pointerId: null, last: { x: 0, y: 0, t: 0 },
          };
        }
      });
    };
    layout();
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(layout);
    ro?.observe(root);

    const step = (now: number) => {
      const dt = Math.min((now - last) / 1000, 1 / 30);
      last = now;
      t += dt;
      const list = bodies.current;
      for (const b of list) {
        if (b.dragging) {
          const nx = b.pos.x + (b.target.x - b.pos.x) * 0.45;
          const ny = b.pos.y + (b.target.y - b.pos.y) * 0.45;
          b.vel = { x: (nx - b.pos.x) / dt, y: (ny - b.pos.y) / dt };
          b.pos = { x: nx, y: ny };
          continue;
        }
        const fx = reduce ? 0 : Math.sin(t * 0.9 + b.phase) * 7;
        const fy = reduce ? 0 : Math.cos(t * 1.1 + b.phase * 1.3) * 6;
        const gx = b.home.x + fx, gy = b.home.y + fy;
        b.vel.x += ((gx - b.pos.x) * 70 - b.vel.x * 9) * dt;
        b.vel.y += ((gy - b.pos.y) * 70 - b.vel.y * 9) * dt;
        b.pos.x += b.vel.x * dt;
        b.pos.y += b.vel.y * dt;
      }
      for (let i = 0; i < list.length; i++) {
        for (let j = i + 1; j < list.length; j++) {
          const a = list[i], b = list[j];
          const dx = b.pos.x - a.pos.x, dy = b.pos.y - a.pos.y;
          const dist = Math.hypot(dx, dy);
          const min = (a.r + b.r) * 0.96;
          if (dist <= 0 || dist >= min) continue;
          const nx = dx / dist, ny = dy / dist, overlap = min - dist;
          if (a.dragging && !b.dragging) {
            b.pos.x += nx * overlap; b.pos.y += ny * overlap; b.vel.x += nx * overlap * 30; b.vel.y += ny * overlap * 30;
          } else if (b.dragging && !a.dragging) {
            a.pos.x -= nx * overlap; a.pos.y -= ny * overlap; a.vel.x -= nx * overlap * 30; a.vel.y -= ny * overlap * 30;
          } else {
            a.pos.x -= (nx * overlap) / 2; a.pos.y -= (ny * overlap) / 2; b.pos.x += (nx * overlap) / 2; b.pos.y += (ny * overlap) / 2;
          }
        }
      }
      list.forEach((b, i) => {
        const c = inBounds(b.pos.x, b.pos.y, b.r);
        if (c.x !== b.pos.x) b.vel.x *= -0.4;
        if (c.y !== b.pos.y) b.vel.y *= -0.4;
        b.pos = c;
        const el = els.current[i];
        if (el) {
          const enter = reduce ? 1 : Math.min(1, Math.max(0, (t - i * 0.12) / 0.7));
          const pop = enter >= 1 ? 1 : 1 - Math.pow(2, -10 * enter) * Math.cos(enter * 10);
          const scale = pop * (b.dragging ? 1.08 : 1);
          const tilt = Math.max(-0.18, Math.min(0.18, b.vel.x / 2500));
          el.style.transform = `translate(${b.pos.x - b.r}px, ${b.pos.y - b.r}px) rotate(${tilt}rad) scale(${scale})`;
          el.style.width = el.style.height = `${b.r * 2}px`;
          el.dataset.dragging = b.dragging ? "true" : "false";
        }
      });
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => {
      cancelAnimationFrame(raf);
      ro?.disconnect();
    };
  }, [bubbles, height, many]);

  const down = (i: number) => (e: React.PointerEvent<HTMLAnchorElement>) => {
    const b = bodies.current[i];
    if (!b || e.button !== 0) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    b.pointerId = e.pointerId;
    b.dragging = true;
    b.moved = 0;
    b.target = { ...b.pos };
    b.last = { x: e.clientX, y: e.clientY, t: performance.now() };
  };
  const move = (i: number) => (e: React.PointerEvent<HTMLAnchorElement>) => {
    const b = bodies.current[i];
    if (!b?.dragging || b.pointerId !== e.pointerId) return;
    const dx = e.clientX - b.last.x, dy = e.clientY - b.last.y;
    b.moved += Math.hypot(dx, dy);
    b.target = { x: b.target.x + dx, y: b.target.y + dy };
    b.last = { x: e.clientX, y: e.clientY, t: performance.now() };
  };
  const up = (i: number) => (e: React.PointerEvent<HTMLAnchorElement>) => {
    const b = bodies.current[i];
    if (!b || b.pointerId !== e.pointerId) return;
    b.dragging = false;
    b.pointerId = null;
    b.vel = { x: b.vel.x * 0.6, y: b.vel.y * 0.6 };
  };

  return (
    <div ref={field} className="relative w-full select-none" style={{ height, touchAction: "pan-y" }}>
      {bubbles.map((bubble, i) => (
        <a
          key={bubble.id}
          ref={(el) => { els.current[i] = el; }}
          href={bubble.href}
          data-bubble={bubble.id}
          aria-label={bubble.label}
          draggable={false}
          onPointerDown={down(i)}
          onPointerMove={move(i)}
          onPointerUp={up(i)}
          onPointerCancel={up(i)}
          onClick={(e) => {
            e.preventDefault();
            const b = bodies.current[i];
            if (b && b.moved > 8) return; // it was a drag, not a tap
            router.push(bubble.href);
          }}
          className="group absolute left-0 top-0 block cursor-grab touch-none rounded-full outline-none will-change-transform focus-visible:ring-4 focus-visible:ring-white/80 data-[dragging=true]:cursor-grabbing"
          style={{ width: 0, height: 0 }}
        >
          <span className="absolute inset-0 rounded-full bg-white/25 shadow-[0_10px_24px_rgba(0,0,0,.14)] transition-shadow group-data-[dragging=true]:shadow-[0_18px_34px_rgba(0,0,0,.24)]" />
          <span className="absolute inset-[6%] grid place-items-center rounded-full bg-white p-[14%]">{bubble.art}</span>
          {/* A long name wraps to two even lines ("Beauty &" / "Skin Care") instead of running past the bubble or
              covering a neighbour; the link's aria-label keeps the plain name. */}
          <span aria-hidden="true" className={cn(
            "absolute left-1/2 top-[80%] w-max -translate-x-1/2 text-balance rounded-2xl border border-[#F1DCD3] bg-white py-1 text-center font-bold leading-tight text-[#2A0D06] shadow-sm",
            many ? "max-w-[108%] px-2.5 text-xs" : "max-w-[118%] px-3 text-[13px]",
          )}>
            {bubble.label.replace(/ &/g, "\u00a0&")}
          </span>
        </a>
      ))}
    </div>
  );
}
