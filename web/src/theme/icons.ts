// ============================================================================
// Hand-authored "luxury render" marks — Pulp Deco medallions, pure SVG.
// Brass linework on ink inside an octagonal engraved frame. No bitmaps,
// no external services: these are the game's icon plates, minted in code.
// ============================================================================

const BRASS = "#d4a943";
const BRASS_BRIGHT = "#ecd08a";
const BRASS_DEEP = "#8a6a1d";
const PAPER = "#e8dcc3";
const INK = "#10141d";
const INK_2 = "#1a202c";

/** Octagonal deco plate that frames every mark. `art` draws in a 64×64 box. */
function medallion(art: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<defs>
<linearGradient id="b" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="${BRASS_BRIGHT}"/><stop offset=".55" stop-color="${BRASS}"/><stop offset="1" stop-color="${BRASS_DEEP}"/>
</linearGradient>
<radialGradient id="g" cx=".5" cy=".35" r=".9">
<stop offset="0" stop-color="${INK_2}"/><stop offset="1" stop-color="${INK}"/>
</radialGradient>
</defs>
<path d="M19 2h26l17 17v26L45 62H19L2 45V19Z" fill="url(#g)" stroke="url(#b)" stroke-width="2.5"/>
<path d="M20.5 6h23L58 20.5v23L43.5 58h-23L6 43.5v-23Z" fill="none" stroke="${BRASS}" stroke-opacity=".35" stroke-width="1"/>
${art}
</svg>`;
}

const S = `fill="none" stroke="url(#b)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"`;
const SF = `fill="url(#b)"`;
const ST = `fill="none" stroke="${PAPER}" stroke-opacity=".8" stroke-width="1.6" stroke-linecap="round"`;

/** The rackets, by index — one deco mark each. */
const RACKET_ART: string[] = [
  // 0 Corner Still — mason jar, XXX label
  `<path d="M24 18h16M25 18v-4h14v4" ${S}/>
   <path d="M23 18c-2 3-2 6-2 9v14c0 4 3 6 6 6h10c3 0 6-2 6-6V27c0-3 0-6-2-9" ${S}/>
   <path d="M27 30h10M27 36h10" ${ST}/>
   <text x="32" y="34.5" text-anchor="middle" font-family="serif" font-weight="bold" font-size="7" fill="${PAPER}">XXX</text>`,
  // 1 The Rusty Anchor
  `<circle cx="32" cy="17" r="4" ${S}/>
   <path d="M32 21v26M22 30h20" ${S}/>
   <path d="M16 38c2 7 8 11 16 11s14-4 16-11" ${S}/>
   <path d="M16 38l-3 6M16 38l6 2M48 38l3 6M48 38l-6 2" ${S}/>`,
  // 2 Bathtub Gin Works — clawfoot tub + bubbles
  `<path d="M14 34h36v4c0 6-5 10-11 10H25c-6 0-11-4-11-10Z" ${S}/>
   <path d="M14 34v-8c0-3 2-5 5-5s5 2 5 5" ${S}/>
   <path d="M22 48l-3 5M42 48l3 5" ${S}/>
   <circle cx="34" cy="26" r="2.5" ${ST}/><circle cx="41" cy="22" r="1.8" ${ST}/><circle cx="38" cy="29" r="1.4" ${ST}/>`,
  // 3 Basement Brewery — barrel
  `<path d="M22 14c-3 5-4 11-4 18s1 13 4 18M42 14c3 5 4 11 4 18s-1 13-4 18" ${S}/>
   <path d="M22 14h20M22 50h20" ${S}/>
   <path d="M19 24h26M19 40h26" ${S}/>
   <path d="M32 14v50" stroke="${BRASS}" stroke-opacity=".4" stroke-width="1.4"/>`,
  // 4 Smuggling Route — sloop under sail
  `<path d="M14 44h36l-5 8H19Z" ${SF} fill-opacity=".9"/>
   <path d="M31 40V14M31 14c9 4 12 14 12 26H31M29 22c-6 4-8 10-8 18h8" ${S}/>
   <path d="M12 57c3-2 5-2 8 0s5 2 8 0 5-2 8 0 5 2 8 0 5-2 8 0" ${ST}/>`,
  // 5 Whiskey Warehouse — crate stack, "molasses"
  `<rect x="15" y="34" width="16" height="14" ${S}/>
   <rect x="33" y="34" width="16" height="14" ${S}/>
   <rect x="24" y="18" width="16" height="14" ${S}/>
   <path d="M24 18l16 14M40 18L24 32" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M15 34l16 14M31 34L15 48M33 34l16 14M49 34L33 48" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>`,
  // 6 The Broken Clock — two minutes to midnight, cracked
  `<circle cx="32" cy="32" r="17" ${S}/>
   <circle cx="32" cy="32" r="13" fill="none" stroke="${BRASS}" stroke-opacity=".35" stroke-width="1"/>
   <path d="M32 22v-3M32 45v-3M22 32h-3M45 32h-3" ${ST}/>
   <path d="M32 32V23M32 32l-4-6" stroke="${PAPER}" stroke-width="2.2" stroke-linecap="round"/>
   <path d="M40 20l-4 7 5 4-3 6" ${ST}/>`,
  // 7 Casino Back Room — poker chip & pips
  `<circle cx="32" cy="32" r="16" ${S}/>
   <circle cx="32" cy="32" r="10" fill="none" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M32 16v6M32 42v6M16 32h6M42 32h6M21 21l4 4M39 39l4 4M43 21l-4 4M25 39l-4 4" stroke="${PAPER}" stroke-opacity=".85" stroke-width="2.4" stroke-linecap="round"/>
   <path d="M32 27l4 5-4 5-4-5Z" ${SF}/>`,
  // 8 Rum-Running Fleet — speedboat, wake
  `<path d="M12 38c14-3 26-3 40-7l-6 10c-10 2-20 2-28 1Z" ${SF} fill-opacity=".9"/>
   <path d="M34 31v-6h8l4 6" ${S}/>
   <path d="M10 48c4-2 7-2 11 0s7 2 11 0 7-2 11 0 7 2 11 0" ${ST}/>`,
  // 9 Racetrack Fix — lucky horseshoe, fixed star
  `<path d="M20 46V26c0-7 5-12 12-12s12 5 12 12v20" ${S}/>
   <path d="M17 46h9M38 46h9" ${S}/>
   <circle cx="21.5" cy="30" r="1.3" ${SF}/><circle cx="42.5" cy="30" r="1.3" ${SF}/>
   <circle cx="23" cy="22" r="1.3" ${SF}/><circle cx="41" cy="22" r="1.3" ${SF}/>
   <path d="M32 28l1.8 3.6 4 .6-2.9 2.8.7 4-3.6-1.9-3.6 1.9.7-4-2.9-2.8 4-.6Z" ${SF}/>`,
  // 10 Uptown Supper Club — champagne coupe
  `<path d="M18 16h28c0 9-6 14-14 14s-14-5-14-14Z" ${S}/>
   <path d="M32 30v16M22 52h20M26 46h12" ${S}/>
   <circle cx="26" cy="12" r="1.4" ${ST}/><circle cx="33" cy="9" r="1.8" ${ST}/><circle cx="40" cy="12" r="1.4" ${ST}/>`,
  // 11 Country Club Cellar — flag in cup, cellar hatch
  `<path d="M30 44V16l14 5-14 5" ${S}/>
   <path d="M22 44h20l-3 8H25Z" ${S}/>
   <path d="M25 48h14" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.4"/>`,
  // 12 Mega-Distillery — sawtooth roofline + chimneys
  `<path d="M14 50V30l8-6v6l8-6v6l8-6v20" ${S}/>
   <path d="M14 50h36" ${S}/>
   <path d="M42 44V22h6v28" ${S}/>
   <circle cx="45" cy="16" r="2.2" ${ST}/><circle cx="49" cy="11" r="1.6" ${ST}/>
   <path d="M19 42h4M27 42h4" ${ST}/>`,
  // 13 Harbor Freight Co. — freighter, stacked crates
  `<path d="M12 42h40l-6 9H17Z" ${SF} fill-opacity=".9"/>
   <rect x="20" y="34" width="9" height="8" ${S}/><rect x="30" y="34" width="9" height="8" ${S}/><rect x="25" y="26" width="9" height="8" ${S}/>
   <path d="M44 42V30h4" ${S}/>
   <circle cx="50" cy="24" r="1.8" ${ST}/>`,
  // 14 Railroad Skim — locomotive head-on
  `<circle cx="32" cy="28" r="12" ${S}/>
   <circle cx="32" cy="28" r="4" ${SF}/>
   <path d="M32 12v-4M20 44l-6 8M44 44l6 8M18 52h28" ${S}/>
   <path d="M22 38l10 14 10-14" ${S}/>`,
  // 15 The Syndicate — deco crown over the five families
  `<path d="M16 40V24l8 7 8-13 8 13 8-7v16Z" ${S}/>
   <path d="M16 44h32v4H16Z" ${SF}/>
   <circle cx="16" cy="20" r="2" ${SF}/><circle cx="32" cy="14" r="2.4" ${SF}/><circle cx="48" cy="20" r="2" ${SF}/>
   <path d="M32 32l2.5 4-2.5 4-2.5-4Z" fill="${PAPER}"/>`,
];

/** The fronts, by id. */
const FRONT_ART: Record<string, string> = {
  laundromat:
  `<rect x="16" y="14" width="32" height="36" rx="2" ${S}/>
   <circle cx="32" cy="35" r="9.5" ${S}/>
   <circle cx="32" cy="35" r="5.5" fill="none" stroke="${PAPER}" stroke-opacity=".7" stroke-width="1.6" stroke-dasharray="3 3"/>
   <path d="M20 19h6M40 19h4" ${ST}/>`,
  barber:
  `<path d="M26 14h12v36H26Z" ${S}/>
   <path d="M26 20l12 7M26 30l12 7M26 40l12 7" stroke="${PAPER}" stroke-opacity=".85" stroke-width="3" stroke-linecap="round"/>
   <path d="M24 12h16M24 52h16" ${S}/>`,
  velvet:
  `<path d="M32 10c-4 10-4 20 0 30M32 10c4 10 4 20 0 30" ${S}/>
   <path d="M32 40v10M26 52h12" ${S}/>
   <path d="M20 16c6 2 8 8 6 14M44 16c-6 2-8 8-6 14" fill="none" stroke="${BRASS}" stroke-opacity=".55" stroke-width="1.8" stroke-linecap="round"/>
   <circle cx="32" cy="24" r="2" fill="${PAPER}"/>`,
  hotel:
  `<circle cx="32" cy="21" r="8" ${S}/>
   <circle cx="32" cy="21" r="3.4" fill="none" stroke="${PAPER}" stroke-opacity=".75" stroke-width="1.6"/>
   <path d="M32 29v22M32 51h8v-5M32 44h6" ${S}/>
   <path d="M27 34h10" stroke="${BRASS}" stroke-opacity=".4" stroke-width="1.4"/>`,
  importexport:
  `<rect x="18" y="26" width="28" height="22" ${S}/>
   <path d="M18 33h28M32 26v22" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M24 26v-6c0-4 3-7 8-7s8 3 8 7" ${S}/>
   <text x="32" y="44" text-anchor="middle" font-family="serif" font-size="6.5" letter-spacing="1" fill="${PAPER}">OIL</text>`,
};

function toDataURI(svg: string): string {
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}

const racketCache = new Map<number, string>();
const frontCache = new Map<string, string>();

export function racketIcon(index: number): string | null {
  if (index < 0 || index >= RACKET_ART.length) return null;
  let uri = racketCache.get(index);
  if (!uri) {
    uri = toDataURI(medallion(RACKET_ART[index]));
    racketCache.set(index, uri);
  }
  return uri;
}

export function frontIcon(id: string): string | null {
  const art = FRONT_ART[id];
  if (!art) return null;
  let uri = frontCache.get(id);
  if (!uri) {
    uri = toDataURI(medallion(art));
    frontCache.set(id, uri);
  }
  return uri;
}
