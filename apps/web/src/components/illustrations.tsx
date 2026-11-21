/**
 * Original Yummy Chops illustrations (SVG, 100×100 design space). Shared look with the mobile app's painters.
 * No third-party artwork.
 */
import type { SVGProps } from "react";

type ArtProps = SVGProps<SVGSVGElement> & { title?: string };

function Svg({ title, children, ...rest }: ArtProps & { children: React.ReactNode }) {
  return (
    <svg viewBox="0 0 100 100" role={title ? "img" : "presentation"} aria-hidden={title ? undefined : true} {...rest}>
      {title ? <title>{title}</title> : null}
      {children}
    </svg>
  );
}

const grains = [
  [26, 44], [33, 48], [41, 43], [47, 50], [55, 45], [62, 49], [69, 44], [74, 50], [37, 52], [58, 52],
  [30, 50], [66, 53], [45, 46], [52, 42], [72, 47],
];

/** A bowl of smoky jollof with a drumstick, dodo and a sprig of green. */
export function FoodArt(props: ArtProps) {
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-bowl" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor="#EF6E3E" />
          <stop offset="1" stopColor="#B3050B" />
        </linearGradient>
        <linearGradient id="gm-drum" x1="0" x2="1">
          <stop offset="0" stopColor="#B4561F" />
          <stop offset="1" stopColor="#7A3512" />
        </linearGradient>
      </defs>
      <ellipse cx="50" cy="86" rx="33" ry="4" fill="#000" opacity=".12" />
      <path d="M40 24c-6-6 6-11 0-18M56 24c-6-6 6-11 0-18" stroke="#D9CFC4" strokeWidth="3" fill="none" strokeLinecap="round" />
      <path d="M16 56C18 30 82 30 84 56Z" fill="#E2622C" />
      {grains.map(([x, y], i) => (
        <rect key={i} x={x - 2.2} y={y - 0.9} width="4.4" height="1.8" rx="1" fill="#F08A4B" transform={`rotate(${(i * 37) % 180} ${x} ${y})`} />
      ))}
      {[
        [28, 44, -23],
        [36, 40, 11],
        [24, 37, 34],
      ].map(([x, y, a], i) => (
        <ellipse key={i} cx={x} cy={y} rx="5.5" ry="3.5" fill="#F5A21A" stroke="#B8741C" strokeWidth="1.4" transform={`rotate(${a} ${x} ${y})`} />
      ))}
      <g transform="translate(63 40) rotate(-31)">
        <rect x="-12" y="-7" width="22" height="14" rx="7" fill="url(#gm-drum)" />
        <rect x="9" y="-2" width="9" height="4" fill="#F7EBDD" />
        <circle cx="19" cy="-2.5" r="3" fill="#F7EBDD" />
        <circle cx="19" cy="2.5" r="3" fill="#F7EBDD" />
      </g>
      <ellipse cx="46" cy="33" rx="2.5" ry="6" fill="#2E8B57" transform="rotate(-34 46 33)" />
      <ellipse cx="51" cy="33" rx="2.5" ry="6" fill="#2E8B57" transform="rotate(29 51 33)" />
      <path d="M12 55H88C86 74 70 86 50 86S14 74 12 55Z" fill="url(#gm-bowl)" />
      <rect x="10" y="52" width="80" height="7" rx="4" fill="#F5A21A" />
      {[30, 50, 70].map((x) => (
        <circle key={x} cx={x} cy="70" r="3.2" fill="none" stroke="#fff" strokeOpacity=".4" strokeWidth="2" />
      ))}
    </Svg>
  );
}

/** A cream jar, a serum dropper and a lipstick with sparkles. */
export function BeautyArt(props: ArtProps) {
  const sparkle = (x: number, y: number, r: number) =>
    `M${x} ${y - r}Q${x} ${y} ${x + r} ${y}Q${x} ${y} ${x} ${y + r}Q${x} ${y} ${x - r} ${y}Q${x} ${y} ${x} ${y - r}Z`;
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-serum" x1="0" x2="1">
          <stop offset="0" stopColor="#D9893A" />
          <stop offset="1" stopColor="#A85A1A" />
        </linearGradient>
        <linearGradient id="gm-lid" x1="0" x2="1">
          <stop offset="0" stopColor="#F59AA8" />
          <stop offset="1" stopColor="#E06A7E" />
        </linearGradient>
        <linearGradient id="gm-gold" x1="0" x2="1">
          <stop offset="0" stopColor="#E9C25A" />
          <stop offset="1" stopColor="#B98A22" />
        </linearGradient>
      </defs>
      <ellipse cx="52" cy="88" rx="35" ry="4" fill="#000" opacity=".12" />
      <path d={sparkle(18, 22, 6)} fill="#F5A21A" />
      <path d={sparkle(86, 18, 4.5)} fill="#F5A21A" />
      <path d={sparkle(30, 10, 3)} fill="#F5A21A" />
      <rect x="44" y="30" width="18" height="6" rx="2" fill="#2B2B2B" />
      <rect x="47" y="16" width="12" height="16" rx="6" fill="#3A3A3A" />
      <rect x="41" y="36" width="24" height="46" rx="7" fill="url(#gm-serum)" />
      <rect x="45" y="52" width="16" height="14" rx="3" fill="#FDF1D6" />
      <rect x="44" y="40" width="4" height="34" rx="2" fill="#fff" opacity=".25" />
      <rect x="10" y="56" width="36" height="30" rx="8" fill="#FFF7F0" stroke="#EBD8C8" strokeWidth="1.6" />
      <rect x="8" y="47" width="40" height="12" rx="5" fill="url(#gm-lid)" />
      <rect x="14" y="66" width="28" height="10" rx="3" fill="#FDE7E6" />
      <circle cx="28" cy="71" r="3" fill="#E0040B" />
      <rect x="68" y="58" width="18" height="28" rx="3" fill="url(#gm-gold)" />
      <rect x="70" y="46" width="14" height="13" fill="#C9A03A" />
      <path d="M71 46V34Q76 26 83 28V46Z" fill="#D23B4E" />
      <path d="M73 44V34" stroke="#fff" strokeOpacity=".33" strokeWidth="2" strokeLinecap="round" />
    </Svg>
  );
}

/** A delivery scooter carrying a Yummy Chops parcel box. */
export function ParcelArt(props: ArtProps) {
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-scooter" x1="0" x2="1">
          <stop offset="0" stopColor="#F0262B" />
          <stop offset="1" stopColor="#3A0D05" />
        </linearGradient>
      </defs>
      <ellipse cx="52" cy="88" rx="36" ry="3.5" fill="#000" opacity=".12" />
      <path d="M2 58h10M2 66h14M2 74h9" stroke="#D9CFC4" strokeWidth="3" strokeLinecap="round" />
      <rect x="16" y="24" width="34" height="32" rx="4" fill="#E4AB6E" stroke="#B4743A" strokeWidth="1.4" />
      <rect x="30" y="24" width="6" height="32" fill="#C98A4B" />
      <circle cx="23" cy="47" r="3.4" fill="#E0040B" />
      <path d="M14 62H60Q70 62 74 70L80 72H18Q12 70 14 62Z" fill="url(#gm-scooter)" />
      <rect x="34" y="54" width="24" height="7" rx="3.5" fill="#2B2B2B" />
      <path d="M70 66L80 32" stroke="#3A0D05" strokeWidth="5" strokeLinecap="round" />
      <path d="M74 31H88" stroke="#2B2B2B" strokeWidth="4" strokeLinecap="round" />
      <circle cx="84" cy="40" r="3" fill="#F5A21A" />
      {[26, 76].map((x) => (
        <g key={x}>
          <circle cx={x} cy="78" r="10" fill="#2B2B2B" />
          <circle cx={x} cy="78" r="4" fill="#C8C8C8" />
        </g>
      ))}
    </Svg>
  );
}

/** A shopping basket with bread, a carton of milk, leafy greens and an orange. */
export function GroceryArt(props: ArtProps) {
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-bread" x1="0" x2="1">
          <stop offset="0" stopColor="#E9B565" />
          <stop offset="1" stopColor="#C98632" />
        </linearGradient>
        <linearGradient id="gm-basket" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor="#3FA66B" />
          <stop offset="1" stopColor="#237247" />
        </linearGradient>
      </defs>
      <ellipse cx="50" cy="88" rx="35" ry="4" fill="#000" opacity=".12" />
      <g transform="translate(30 34) rotate(-20)">
        <rect x="-7" y="-22" width="14" height="46" rx="7" fill="url(#gm-bread)" />
        {[-12, -3, 6].map((y) => (
          <line key={y} x1="-4" y1={y} x2="4" y2={y + 3} stroke="#A9661F" strokeWidth="1.6" strokeLinecap="round" />
        ))}
      </g>
      <path d="M44 26L53 16L62 26Z" fill="#DCEBFA" />
      <rect x="44" y="26" width="18" height="34" fill="#F7FBFF" />
      <rect x="44" y="36" width="18" height="10" fill="#4C8FDB" />
      {[
        [70, -20],
        [76, 6],
        [82, 29],
      ].map(([x, a]) => (
        <g key={x} transform={`translate(${x} 40) rotate(${a})`}>
          <ellipse cx="0" cy="-3" rx="5" ry="15" fill="#2E8B57" />
          <line x1="0" y1="-12" x2="0" y2="10" stroke="#1F6B41" strokeWidth="1.2" strokeLinecap="round" />
        </g>
      ))}
      <circle cx="63" cy="50" r="8" fill="#F5A623" />
      <circle cx="60.5" cy="47.5" r="2.2" fill="#fff" opacity=".33" />
      <path d="M14 52H86L78 84Q77 88 73 88H27Q23 88 22 84Z" fill="url(#gm-basket)" />
      <rect x="10" y="48" width="80" height="8" rx="4" fill="#2F8A57" />
      {[32, 44, 56, 68].map((x) => (
        <line key={x} x1={x} y1="62" x2={x + (x - 50) * -0.06} y2="80" stroke="#fff" strokeOpacity=".33" strokeWidth="2.4" strokeLinecap="round" />
      ))}
    </Svg>
  );
}

/** A medicine bottle with a green cross, a capsule and a plaster. */
export function PharmacyArt(props: ArtProps) {
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-bottle" x1="0" x2="1">
          <stop offset="0" stopColor="#FFFFFF" />
          <stop offset="1" stopColor="#E6EEF2" />
        </linearGradient>
      </defs>
      <ellipse cx="50" cy="88" rx="34" ry="4" fill="#000" opacity=".12" />
      <rect x="30" y="12" width="28" height="12" rx="3" fill="#1F9D63" />
      {[35, 41, 47, 53].map((x) => (
        <line key={x} x1={x} y1="14" x2={x} y2="22" stroke="#fff" strokeOpacity=".33" strokeWidth="1.4" strokeLinecap="round" />
      ))}
      <rect x="24" y="24" width="40" height="62" rx="9" fill="url(#gm-bottle)" stroke="#D3DEE4" strokeWidth="1.6" />
      <rect x="29" y="40" width="30" height="30" rx="5" fill="#E6F6EE" />
      <rect x="40.5" y="45" width="7" height="20" rx="2" fill="#1F9D63" />
      <rect x="34" y="51.5" width="20" height="7" rx="2" fill="#1F9D63" />
      <g transform="translate(77 66) rotate(-34)">
        <rect x="-15" y="-7" width="30" height="14" rx="7" fill="#FFF7F0" />
        <path d="M0-7H-8A7 7 0 0 0-8 7H0Z" fill="#E0040B" />
        <rect x="-15" y="-7" width="30" height="14" rx="7" fill="none" stroke="#000" strokeOpacity=".2" strokeWidth="1" />
      </g>
      <g transform="translate(76 34) rotate(29)">
        <rect x="-14" y="-5" width="28" height="10" rx="5" fill="#F0C9A0" />
        <rect x="-5" y="-5" width="10" height="10" rx="1.5" fill="#FBE3C8" />
        {[-10, 10].map((x) => (
          <g key={x} fill="#C79B6B">
            <circle cx={x} cy="-2" r=".9" />
            <circle cx={x} cy="2" r=".9" />
          </g>
        ))}
      </g>
    </Svg>
  );
}

/** A woven market basket of tomatoes, pepper, leaves and a tuber of yam. */
export function MarketArt(props: ArtProps) {
  const basket = "M12 54H88C86 74 72 88 50 88C28 88 14 74 12 54Z";
  return (
    <Svg {...props}>
      <defs>
        <linearGradient id="gm-yam" x1="0" x2="1">
          <stop offset="0" stopColor="#8A5A33" />
          <stop offset="1" stopColor="#5F3B1E" />
        </linearGradient>
        <linearGradient id="gm-woven" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor="#DDA85B" />
          <stop offset="1" stopColor="#B07A2E" />
        </linearGradient>
        <clipPath id="gm-woven-clip">
          <path d={basket} />
        </clipPath>
      </defs>
      <ellipse cx="50" cy="88" rx="36" ry="4" fill="#000" opacity=".12" />
      <g transform="translate(70 36) rotate(26)">
        <rect x="-8" y="-22" width="16" height="44" rx="8" fill="url(#gm-yam)" />
        <ellipse cx="0" cy="-18.5" rx="6" ry="3.5" fill="#F3E3C4" />
      </g>
      {[
        [22, -29],
        [29, -6],
        [36, 17],
      ].map(([x, a]) => (
        <g key={x} transform={`translate(${x} 38) rotate(${a})`}>
          <ellipse cx="0" cy="-4" rx="5.5" ry="16" fill="#2E8B57" />
          <line x1="0" y1="-14" x2="0" y2="10" stroke="#1F6B41" strokeWidth="1.2" strokeLinecap="round" />
        </g>
      ))}
      {[
        [44, 44, 9],
        [58, 47, 8],
        [50, 36, 7.5],
      ].map(([x, y, r]) => (
        <g key={`${x}-${y}`}>
          <circle cx={x} cy={y} r={r} fill="#E2412B" />
          <circle cx={x - r * 0.3} cy={y - r * 0.35} r={r * 0.25} fill="#fff" opacity=".4" />
          <circle cx={x} cy={y - r + 1} r="1.8" fill="#2E8B57" />
        </g>
      ))}
      <rect x="-3.5" y="-9" width="7" height="18" rx="3.5" fill="#F5B942" transform="translate(33 49) rotate(-52)" />
      <path d={basket} fill="url(#gm-woven)" />
      <g clipPath="url(#gm-woven-clip)" stroke="#704514" strokeOpacity=".4" strokeWidth="1.6">
        {[60, 67, 74, 81].map((y) => (
          <line key={`h${y}`} x1="10" y1={y} x2="90" y2={y} />
        ))}
        {[18, 27, 36, 45, 54, 63, 72, 81].map((x) => (
          <line key={`v${x}`} x1={x} y1="54" x2={x + (50 - x) * 0.18} y2="90" />
        ))}
      </g>
      <rect x="9" y="50" width="82" height="8" rx="4" fill="#C98C3C" />
    </Svg>
  );
}

/** Yummy, the Yummy Chops AI assistant: a friendly robot in a disc of the logo's chocolate brown (the cloche), with a gold antenna and a chat-bubble tail. */
export function GudyArt({ blink = false, ...props }: ArtProps & { blink?: boolean }) {
  return (
    <Svg {...props}>
      <defs>
        <radialGradient id="gm-gudy" cx=".35" cy=".3" r=".9">
          <stop offset="0" stopColor="#B4561F" />
          <stop offset=".55" stopColor="#6B2410" />
          <stop offset="1" stopColor="#3A0D05" />
        </radialGradient>
      </defs>
      <circle cx="50" cy="50" r="50" fill="url(#gm-gudy)" />
      <path d="M50 31V21" stroke="#fff" strokeWidth="3.4" strokeLinecap="round" />
      <circle cx="50" cy="18.5" r="4.6" fill="#F5A21A" />
      <rect x="19" y="44" width="8" height="15" rx="4" fill="#F6DCC6" />
      <rect x="73" y="44" width="8" height="15" rx="4" fill="#F6DCC6" />
      <path d="M42 31H58A17 17 0 0 1 75 48V52A17 17 0 0 1 58 69H50L33 78L36 65A17 17 0 0 1 25 52V48A17 17 0 0 1 42 31Z" fill="#fff" />
      <rect x="32" y="40" width="36" height="19" rx="9.5" fill="#6B2410" />
      <g className={blink ? "gm-blink" : undefined} style={{ transformOrigin: "50px 49.5px" }}>
        <ellipse cx="42" cy="49.5" rx="4.2" ry="4.2" fill="#fff" />
        <ellipse cx="58" cy="49.5" rx="4.2" ry="4.2" fill="#fff" />
      </g>
    </Svg>
  );
}
