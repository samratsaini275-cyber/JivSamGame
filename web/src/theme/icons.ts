// ============================================================================
// Hand-authored "luxury render" marks — Street Noir medallions, pure SVG.
// Gold linework on ink inside an octagonal engraved frame. No bitmaps,
// no external services: these are the game's icon plates, minted in code.
// ============================================================================

const BRASS = "#d4a943";
const BRASS_BRIGHT = "#ecd08a";
const BRASS_DEEP = "#8a6a1d";
const PAPER = "#e7ebf2";
const INK = "#10141d";
const INK_2 = "#1a202c";

/** Octagonal plate that frames every mark. `art` draws in a 64×64 box. */
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

/** The hustles, by index — one mark each. */
const RACKET_ART: string[] = [
  // 0 Corner Spot — stylized leaf
  `<path d="M32 50V20" ${S}/>
   <path d="M32 14c3 4 3 9 0 13-3-4-3-9 0-13Z" ${S}/>
   <path d="M32 27c7-7 14-8 19-5-4 6-11 9-19 8" ${S}/>
   <path d="M32 27c-7-7-14-8-19-5 4 6 11 9 19 8" ${S}/>
   <path d="M32 38c6-4 12-4 16-1-4 4-10 5-16 4" ${S}/>
   <path d="M32 38c-6-4-12-4-16-1 4 4 10 5 16 4" ${S}/>`,
  // 1 Smoke Shop — storefront with striped awning
  `<path d="M16 26h32v24H16Z" ${S}/>
   <path d="M14 26l4-8h28l4 8Z" ${S}/>
   <path d="M22 50V38h8v12" ${S}/>
   <rect x="34" y="36" width="10" height="8" ${S}/>
   <path d="M19 22h4M27 22h4M35 22h4M43 22h4" ${ST}/>`,
  // 2 Grow House — potted plant under a grow lamp
  `<path d="M20 14h24l-4 5H24Z" ${SF} fill-opacity=".9"/>
   <path d="M32 10v4" ${S}/>
   <path d="M25 23l-2 3M32 23v4M39 23l2 3" ${ST}/>
   <path d="M32 44V32" ${S}/>
   <path d="M32 34c-5-4-10-4-13-1 4 3 8 4 13 3M32 34c5-4 10-4 13-1-4 3-8 4-13 3" ${S}/>
   <path d="M24 44h16l-2 8H26Z" ${S}/>`,
  // 3 Pill Mill — capsule and loose pills
  `<g transform="rotate(-25 30 27)"><rect x="16" y="21" width="28" height="13" rx="6.5" ${S}/><path d="M30 21v13" ${S}/></g>
   <circle cx="22" cy="46" r="4" ${S}/><path d="M19 46h6" ${ST}/>
   <circle cx="38" cy="48" r="4" ${S}/><path d="M35 48h6" ${ST}/>`,
  // 4 Smuggling Route — fishing boat under way
  `<path d="M14 44h36l-5 8H19Z" ${SF} fill-opacity=".9"/>
   <path d="M31 40V14M31 14c9 4 12 14 12 26H31M29 22c-6 4-8 10-8 18h8" ${S}/>
   <path d="M12 57c3-2 5-2 8 0s5 2 8 0 5-2 8 0 5 2 8 0 5-2 8 0" ${ST}/>`,
  // 5 Stash Warehouse — crate stack, "office furniture"
  `<rect x="15" y="34" width="16" height="14" ${S}/>
   <rect x="33" y="34" width="16" height="14" ${S}/>
   <rect x="24" y="18" width="16" height="14" ${S}/>
   <path d="M24 18l16 14M40 18L24 32" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M15 34l16 14M31 34L15 48M33 34l16 14M49 34L33 48" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>`,
  // 6 After-Hours Club — speaker cabinet, sound waves
  `<rect x="16" y="14" width="24" height="36" rx="2" ${S}/>
   <circle cx="28" cy="38" r="7.5" ${S}/><circle cx="28" cy="38" r="2.5" ${SF}/>
   <circle cx="28" cy="22" r="4" ${S}/>
   <path d="M46 26c2 2 2 6 0 8M50 22c3 4 3 12 0 16" ${ST}/>`,
  // 7 Underground Casino — poker chip & pips
  `<circle cx="32" cy="32" r="16" ${S}/>
   <circle cx="32" cy="32" r="10" fill="none" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M32 16v6M32 42v6M16 32h6M42 32h6M21 21l4 4M39 39l4 4M43 21l-4 4M25 39l-4 4" stroke="${PAPER}" stroke-opacity=".85" stroke-width="2.4" stroke-linecap="round"/>
   <path d="M32 27l4 5-4 5-4-5Z" ${SF}/>`,
  // 8 Go-Fast Fleet — speedboat, wake
  `<path d="M12 38c14-3 26-3 40-7l-6 10c-10 2-20 2-28 1Z" ${SF} fill-opacity=".9"/>
   <path d="M34 31v-6h8l4 6" ${S}/>
   <path d="M10 48c4-2 7-2 11 0s7 2 11 0 7-2 11 0 7 2 11 0" ${ST}/>`,
  // 9 Chop Shop — car up on a jack, wheel off
  `<path d="M16 36l5-10h20l7 10" ${S}/>
   <path d="M12 36h40v7h-6v-3H20v3h-8Z" ${S}/>
   <circle cx="42" cy="47" r="3.5" ${S}/>
   <path d="M19 43v6M15 49h8" ${S}/>
   <path d="M24 30h14" ${ST}/>`,
  // 10 Uptown Nightclub — champagne coupe
  `<path d="M18 16h28c0 9-6 14-14 14s-14-5-14-14Z" ${S}/>
   <path d="M32 30v16M22 52h20M26 46h12" ${S}/>
   <circle cx="26" cy="12" r="1.4" ${ST}/><circle cx="33" cy="9" r="1.8" ${ST}/><circle cx="40" cy="12" r="1.4" ${ST}/>`,
  // 11 Country Club Connect — flag in cup, clubhouse deal
  `<path d="M30 44V16l14 5-14 5" ${S}/>
   <path d="M22 44h20l-3 8H25Z" ${S}/>
   <path d="M25 48h14" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.4"/>`,
  // 12 The Superlab — flask on the burner
  `<path d="M27 12h10" ${S}/>
   <path d="M29 12v12L18 44c-2 4 1 8 5 8h18c4 0 7-4 5-8L35 24V12" ${S}/>
   <path d="M24 38h16" ${ST}/>
   <circle cx="30" cy="44" r="1.6" ${ST}/><circle cx="36" cy="46" r="1.2" ${ST}/>`,
  // 13 Container Line — freighter, stacked containers
  `<path d="M12 42h40l-6 9H17Z" ${SF} fill-opacity=".9"/>
   <rect x="20" y="34" width="9" height="8" ${S}/><rect x="30" y="34" width="9" height="8" ${S}/><rect x="25" y="26" width="9" height="8" ${S}/>
   <path d="M44 42V30h4" ${S}/>
   <circle cx="50" cy="24" r="1.8" ${ST}/>`,
  // 14 Trucking Network — semi cab head-on
  `<rect x="18" y="16" width="28" height="18" rx="2" ${S}/>
   <rect x="23" y="20" width="18" height="8" ${S}/>
   <path d="M18 34h28v8H18Z" ${S}/>
   <path d="M22 38h20" ${ST}/>
   <circle cx="22" cy="48" r="3.5" ${S}/><circle cx="42" cy="48" r="3.5" ${S}/>
   <path d="M20 16v-5M44 16v-5" ${ST}/>`,
  // 15 The Cartel — crown over the five crews
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
  `<circle cx="32" cy="28" r="12" ${S}/>
   <path d="M32 10v6" ${S}/>
   <path d="M20 28h24M32 16v24M23 21c5 4 13 4 18 0M23 35c5-4 13-4 18 0" fill="none" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M22 46l-2 5M32 44v7M42 46l2 5" ${ST}/>`,
  hotel:
  `<circle cx="32" cy="21" r="8" ${S}/>
   <circle cx="32" cy="21" r="3.4" fill="none" stroke="${PAPER}" stroke-opacity=".75" stroke-width="1.6"/>
   <path d="M32 29v22M32 51h8v-5M32 44h6" ${S}/>
   <path d="M27 34h10" stroke="${BRASS}" stroke-opacity=".4" stroke-width="1.4"/>`,
  importexport:
  `<rect x="18" y="26" width="28" height="22" ${S}/>
   <path d="M18 33h28M32 26v22" stroke="${BRASS}" stroke-opacity=".5" stroke-width="1.6"/>
   <path d="M24 26v-6c0-4 3-7 8-7s8 3 8 7" ${S}/>
   <text x="32" y="44" text-anchor="middle" font-family="serif" font-size="6.5" letter-spacing="1" fill="${PAPER}">TVS</text>`,
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
