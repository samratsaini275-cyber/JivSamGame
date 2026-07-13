// ============================================================================
// The icon system. Every player-visible mark is drawn here in one shared line
// style — no OS emoji anywhere. `Ic` = a currentColor line glyph for UI;
// `Portrait` = a small illustrated character bust.
// ============================================================================

export type IconName =
  | "dirty" | "clean" | "respect" | "legacy" | "lock" | "crew" | "post"
  | "truck" | "boat" | "ship" | "crate" | "shipment"
  | "badge" | "cuffs" | "gavel" | "writ" | "cityhall" | "precinct"
  | "press" | "star" | "check" | "cross" | "chevron" | "sound-on" | "sound-off"
  | "watch" | "car" | "ring" | "suit" | "up" | "down" | "warn" | "wash";

const G: Record<IconName, string> = {
  // ---- currency & progression ----
  dirty: // banknote with a $
    `<rect x="3" y="7" width="18" height="10" rx="1.5"/><circle cx="12" cy="12" r="2.4"/><path d="M6 10.5v3M18 10.5v3" stroke-linecap="round"/>`,
  clean: // bank / columns
    `<path d="M12 3 3 8h18Z"/><path d="M5 9v8M9.5 9v8M14.5 9v8M19 9v8"/><path d="M3 20h18"/>`,
  respect: // clasped-hands pact, abstracted
    `<path d="M3 12l4-3 5 3 5-3 4 3"/><path d="M7 9v7l5 3 5-3V9" stroke-linecap="round"/>`,
  legacy: // laurel/crown for the Family legacy
    `<path d="M4 18V9l4 3 4-6 4 6 4-3v9Z"/><path d="M4 20h16"/>`,
  lock:
    `<rect x="5" y="10.5" width="14" height="9.5" rx="2"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>`,
  crew: // person in a cap
    `<path d="M6 8.5c1-2.5 4-3.5 6-3.5s5 1 6 3.5"/><path d="M5 8.5h14"/><circle cx="12" cy="13" r="2.6"/><path d="M6 21c1-3.5 3.6-5 6-5s5 1.5 6 5"/>`,
  post: // paper going out
    `<path d="M4 5h11l5 5v9H4Z"/><path d="M15 5v5h5"/><path d="M8 13h7M8 16h5"/>`,
  // ---- shipment / vehicles ----
  truck:
    `<path d="M2 7h12v8H2Z"/><path d="M14 10h4l3 3v2h-7Z"/><circle cx="7" cy="18" r="1.8"/><circle cx="17" cy="18" r="1.8"/>`,
  boat:
    `<path d="M4 15h16l-2 4H6Z"/><path d="M12 15V4M12 4c4 1.5 5.5 5 5.5 9M11 6C7.5 7 6 10 6 13h5"/>`,
  ship:
    `<path d="M3 14h18l-2.5 5H5.5Z"/><path d="M6 14V9h7l3 5"/><path d="M9 9V6h2"/>`,
  crate:
    `<rect x="4" y="6" width="16" height="13"/><path d="M4 10h16M4 15h16M12 6v13"/>`,
  shipment: // crate with a motion chevron
    `<rect x="3" y="7" width="12" height="11"/><path d="M3 11h12M9 7v11"/><path d="M17 9l4 3.5-4 3.5" stroke-linecap="round" stroke-linejoin="round"/>`,
  // ---- law ----
  badge: // police shield
    `<path d="M12 3l7 2.5v6c0 5-3 8.5-7 10-4-1.5-7-5-7-10v-6Z"/><path d="M12 8l1.3 2.7 2.9.3-2.1 2 .6 2.9L12 16.5 9.3 18l.6-2.9-2.1-2 2.9-.3Z"/>`,
  cuffs:
    `<circle cx="7" cy="14" r="4"/><circle cx="17" cy="14" r="4"/><path d="M10.5 12.5h3"/>`,
  gavel:
    `<path d="M13 4l5 5-3 3-5-5Z"/><path d="M9.5 10.5L4 16l2 2 5.5-5.5"/><path d="M12 20h8"/>`,
  writ: // legal document
    `<path d="M6 3h8l4 4v14H6Z"/><path d="M14 3v4h4"/><path d="M9 12h6M9 15h6M9 18h4"/>`,
  cityhall:
    `<path d="M12 3 3 8h18Z"/><path d="M5 9v8M9.5 9v8M14.5 9v8M19 9v8"/><path d="M3 20h18"/><circle cx="12" cy="6" r="1"/>`,
  precinct: // shield-star, simplified from badge
    `<path d="M12 3l7 2.5v6c0 5-3 8.5-7 10-4-1.5-7-5-7-10v-6Z"/><path d="M9 12h6M12 9v6"/>`,
  // ---- misc ----
  press: // newspaper
    `<path d="M4 5h13v14H4Z"/><path d="M17 8h3v9a2 2 0 0 1-2 2h-1Z"/><path d="M7 8h7M7 11h7M7 14h5"/>`,
  star:
    `<path d="M12 3l2.4 5.6 6 .5-4.6 4 1.4 5.9L12 20.9 6.8 19l1.4-5.9-4.6-4 6-.5Z"/>`,
  check: `<path d="M4 12.5l5 5 11-11" stroke-linecap="round" stroke-linejoin="round"/>`,
  cross: `<path d="M6 6l12 12M18 6L6 18" stroke-linecap="round"/>`,
  chevron: `<path d="M9 6l6 6-6 6" stroke-linecap="round" stroke-linejoin="round"/>`,
  "sound-on": `<path d="M4 9v6h4l5 4V5L8 9Z"/><path d="M16 9.5a4 4 0 0 1 0 5M18.5 7a7.5 7.5 0 0 1 0 10"/>`,
  "sound-off": `<path d="M4 9v6h4l5 4V5L8 9Z"/><path d="M16 9.5l5 5M21 9.5l-5 5" stroke-linecap="round"/>`,
  watch:
    `<circle cx="12" cy="13" r="6"/><path d="M12 10v3l2 1.5"/><path d="M9.5 6l.6-2.5h3.8L14.5 6M9.5 20l.6 2.5h3.8l.6-2.5"/>`,
  car:
    `<path d="M4 15l1.5-5h13L20 15"/><path d="M3 15h18v3h-2v-1.5H5V18H3Z"/><circle cx="7.5" cy="18" r="1.3"/><circle cx="16.5" cy="18" r="1.3"/>`,
  ring:
    `<circle cx="12" cy="14" r="6"/><path d="M9 8l1.5-4h3L15 8" stroke-linejoin="round"/><path d="M12 4.5l1.5 2-1.5 2-1.5-2Z"/>`,
  suit:
    `<path d="M8 4l4 4 4-4 4 2v14H4V6Z"/><path d="M12 8v12M9 12l3 3 3-3"/>`,
  up: `<path d="M12 5v14M6 11l6-6 6 6" stroke-linecap="round" stroke-linejoin="round"/>`,
  down: `<path d="M12 5v14M6 13l6 6 6-6" stroke-linecap="round" stroke-linejoin="round"/>`,
  warn: `<path d="M12 4l9 16H3Z"/><path d="M12 10v4M12 17h.01" stroke-linecap="round"/>`,
  wash: // washing-machine circle
    `<rect x="5" y="4" width="14" height="16" rx="2"/><circle cx="12" cy="13" r="4.5"/><path d="M8 7h.01M11 7h.01"/>`,
};

interface IcProps {
  name: IconName;
  size?: number;
  className?: string;
  strokeWidth?: number;
}

/** A line glyph that inherits `color` (via currentColor). */
export function Ic({ name, size = 18, className, strokeWidth = 1.7 }: IcProps) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinejoin="round"
      aria-hidden
      dangerouslySetInnerHTML={{ __html: G[name] }}
    />
  );
}

// ---------------------------------------------------------------------------
// Character portraits — small illustrated busts, colored, framed round.
// ---------------------------------------------------------------------------

export type PortraitName =
  | "enzo" | "sal"
  | "look-hoodie" | "look-bizcaz" | "look-street" | "look-gym";

const SKIN = "#c99a6a";
const SKIN_D = "#a97c4f";
const INK = "#171d29";

/** Bust artwork drawn in a 48×48 box (frame added by wrapper). */
const BUST: Record<PortraitName, string> = {
  // Von — the right hand: bald, grey beard, dark crewneck, gold chain
  enzo: `
    <rect width="48" height="48" fill="${INK}"/>
    <path d="M12 48c1-9 6-13 12-13s11 4 12 13Z" fill="#2b3446"/>
    <path d="M18 41c4 3 8 3 12 0" stroke="#d4a943" stroke-width="1.8" fill="none" stroke-linecap="round"/>
    <path d="M24 20c5 0 8 3 8 8s-3 9-8 9-8-4-8-9 3-8 8-8Z" fill="${SKIN}"/>
    <path d="M16 27c0-6 3-10 8-10s8 4 8 10c1-8-3-12-8-12s-9 4-8 12Z" fill="${SKIN_D}"/>
    <path d="M18 30c1.5-1.5 4-1.5 5 0M25 30c1.5-1.5 4-1.5 5 0" stroke="#5a4636" stroke-width="1.4" fill="none" stroke-linecap="round"/>
    <path d="M19 32c2 4 8 4 10 0M22 36c1.5 1.5 4.5 1.5 6 0" stroke="#c9c4bb" stroke-width="2" fill="none" stroke-linecap="round"/>
    <circle cx="20.5" cy="30" r="1" fill="#2b2118"/><circle cx="27.5" cy="30" r="1" fill="#2b2118"/>
  `,
  // Ray — sharp fixer: fresh fade, thin beard, gold-trimmed collar
  sal: `
    <rect width="48" height="48" fill="${INK}"/>
    <path d="M12 48c1-8 6-12 12-12s11 4 12 12Z" fill="#20283a"/>
    <path d="M18 42l-3 6M30 42l3 6" stroke="#d4a943" stroke-width="1.6"/>
    <path d="M24 22c5 0 7 3 7 7s-3 8-7 8-7-4-7-8 2-7 7-7Z" fill="${SKIN}"/>
    <path d="M22 32c1.5 1 3.5 1 5 0" stroke="#4a3a28" stroke-width="1.4" fill="none" stroke-linecap="round"/>
    <circle cx="21" cy="29" r="1" fill="#2b2118"/><circle cx="27" cy="29" r="1" fill="#2b2118"/>
    <path d="M15 25c0-6 4-10 9-10s9 4 9 10l-2 1c-1-4-3-6-7-6s-6 2-7 6Z" fill="#1a1108"/>
  `,
  // Boss looks — hood up
  "look-hoodie": `
    <rect width="48" height="48" fill="${INK}"/>
    <path d="M13 48c1-8 5-12 11-12s10 4 11 12Z" fill="#3a3f4a"/>
    <path d="M24 22c5 0 7 3 7 8s-3 8-7 8-7-3-7-8 2-8 7-8Z" fill="${SKIN}"/>
    <path d="M13 24c0-8 5-13 11-13s11 5 11 13l-3 1c0-6-3-10-8-10s-8 4-8 10Z" fill="#3a3f4a"/>
    <circle cx="21" cy="30" r="1" fill="#2b2118"/><circle cx="27" cy="30" r="1" fill="#2b2118"/>
  `,
  // Boss looks — business casual, open collar
  "look-bizcaz": `
    <rect width="48" height="48" fill="${INK}"/>
    <path d="M14 48c1-8 5-11 10-11s9 3 10 11Z" fill="#1c2230"/>
    <path d="M18 40h12l-1 8H19Z" fill="#e7ebf2"/>
    <path d="M24 23c4 0 6 3 6 7s-2 7-6 7-6-3-6-7 2-7 6-7Z" fill="${SKIN}"/>
    <path d="M17 24c0-5 3-9 7-9s7 4 7 9l-2 1c-1-4-2-6-5-6s-4 2-5 6Z" fill="#1c1610"/>
    <circle cx="21.5" cy="30" r="1" fill="#2b2118"/><circle cx="26.5" cy="30" r="1" fill="#2b2118"/>
  `,
  // Boss looks — streetwear, beanie
  "look-street": `
    <rect width="48" height="48" fill="${INK}"/>
    <path d="M12 48c1-8 6-12 12-12s11 4 12 12Z" fill="#2e4257"/>
    <path d="M24 22c5 0 7 3 7 8s-3 8-7 8-7-3-7-8 2-8 7-8Z" fill="${SKIN}"/>
    <path d="M15 18c1-4 5-6 9-6s8 2 9 6l-2 2c-2-2-4-3-7-3s-5 1-7 3Z" fill="#3a3020"/>
    <circle cx="21" cy="30" r="1" fill="#2b2118"/><circle cx="27" cy="30" r="1" fill="#2b2118"/>
  `,
  // Boss looks — designer tracksuit, zipped
  "look-gym": `
    <rect width="48" height="48" fill="${INK}"/>
    <path d="M12 48c1-9 6-12 12-12s11 3 12 12Z" fill="#5a2140"/>
    <path d="M24 38v9" stroke="#e7ebf2" stroke-width="1.8" fill="none"/>
    <path d="M24 22c5 0 7 3 7 8s-3 8-7 8-7-3-7-8 2-8 7-8Z" fill="${SKIN}"/>
    <path d="M17 26c0-6 3-10 7-10s7 4 7 10c1-7-2-11-7-11s-8 4-7 11Z" fill="#3a2c22"/>
    <circle cx="21" cy="30" r="1" fill="#2b2118"/><circle cx="27" cy="30" r="1" fill="#2b2118"/>
  `,
};

interface PortraitProps {
  name: PortraitName;
  size?: number;
  className?: string;
  ring?: boolean;
}

/** A framed circular character bust. */
export function Portrait({ name, size = 46, className, ring = true }: PortraitProps) {
  return (
    <span
      className={`portrait-frame ${ring ? "ringed" : ""} ${className ?? ""}`}
      style={{ width: size, height: size }}
    >
      <svg viewBox="0 0 48 48" width="100%" height="100%" aria-hidden
        dangerouslySetInnerHTML={{ __html: BUST[name] }} />
    </span>
  );
}
