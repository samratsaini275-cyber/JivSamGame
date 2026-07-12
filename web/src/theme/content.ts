// ============================================================================
// BOOTLEG EMPIRE — theme config. THE single source of truth for every
// player-facing name, string, and color. New Carthage, 1926. Fictional city,
// fictional people, alcohol prohibition only, bloodless pulp tone.
// If a store review ever demands changes, this is the only file to edit.
// ============================================================================

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

export const GAME = {
  title: "BOOTLEG EMPIRE",
  city: "New Carthage",
  year: "1926",
  tagline: "Wet the city's whistle. Keep the badge off your door.",
  masthead: "THE NEW CARTHAGE HERALD", // newspaper toasts
} as const;

// ---------------------------------------------------------------------------
// Palette — Pulp Deco. Gold is EXCLUSIVELY money; red is EXCLUSIVELY heat.
// ---------------------------------------------------------------------------

export const PALETTE = {
  ink: "#10131a",
  inkRaised: "#1a1f2a",
  inkDeep: "#0a0c11",
  paper: "#e8dcc3",
  paperDark: "#d5c5a3",
  paperInk: "#2a2018", // text on paper
  gold: "#e0b64f",
  goldDeep: "#8a6a1d",
  heatRed: "#c22a33",
  teal: "#3d7a74",
  dirtyGreen: "#7ca163",
  textMuted: "rgba(232, 220, 195, 0.55)",
  textFaint: "rgba(232, 220, 195, 0.32)",
} as const;

/** Player-picked accent — identity moments only (avatar ring, wardrobe). */
export interface ColorwayDef {
  id: string; // persisted — do not rename
  name: string;
  accent: string;
  accentDeep: string;
}

export const COLORWAYS: ColorwayDef[] = [
  { id: "gold", name: "Brass", accent: "#e0b64f", accentDeep: "#8a6a1d" },
  { id: "volt", name: "Absinthe", accent: "#9fc86a", accentDeep: "#3f6023" },
  { id: "ice", name: "Gin Ice", accent: "#a8d5e2", accentDeep: "#39708a" },
  { id: "crimson", name: "Bordeaux", accent: "#c65a5a", accentDeep: "#5c1420" },
  { id: "amethyst", name: "Velvet", accent: "#b58ed0", accentDeep: "#4a2a66" },
];

export function colorwayByID(id: string): ColorwayDef {
  return COLORWAYS.find((c) => c.id === id) ?? COLORWAYS[0];
}

// ---------------------------------------------------------------------------
// Currencies & core labels
// ---------------------------------------------------------------------------

export const LABELS = {
  cash: "Cash",
  dirtyCash: "Dirty Cash",
  cleanCash: "Clean Cash",
  fortune: "Family Fortune",
  respect: "Respect",
  legacy: "Legacy",
  heat: "Heat",
  perSec: "/sec",
  buy: "BUY",
  start: "OPEN",
  runBatch: "RUN A BATCH",
  shipment: "SHIPMENT",
  automated: "CREW",
  maxed: "LEGENDARY",
  tabs: { map: "City", ledger: "Rackets", fixer: "The Fixer", family: "Family", boss: "The Boss" },
} as const;

/** Milestone tier names (25/50/100/200/300/400 units). */
export const TIER_NAMES = [
  "Unknown",
  "Corner Rumors",
  "Neighborhood Fixture",
  "Ward Boss",
  "City Legend",
  "State Menace",
  "Front-Page Story",
  "Untouchable",
];

export function tierName(tier: number): string {
  return TIER_NAMES[Math.min(tier, TIER_NAMES.length - 1)];
}

/** The old "viral moment" — the whole city talks, income ×2^tier. */
export const PRESS = {
  chip: "PRESS",
  tracker: "Next Front Page",
  toastTitle: "EXTRA! EXTRA!",
  toastSub: (mult: number) => `The whole city's talking — every racket earns ×${mult}`,
  milestoneToast: (name: string, tier: string) => `${name} is now a ${tier}!`,
  milestoneSub: "Income ×2, batches twice as fast",
} as const;

// ---------------------------------------------------------------------------
// Rackets (illegal producers) — indices are load-bearing: they map 1:1 onto
// the original tuned stat rows (baseCost/baseIncome/baseCycle) and old saves.
// ---------------------------------------------------------------------------

export interface BizContent {
  name: string;
  flavor: string;
  emoji: string;
  crew: string; // the staff hire that automates it (old "ghostwriter")
}

export const BIZ: BizContent[] = [
  { name: "Corner Still", emoji: "🫙",
    flavor: "Grandma's cough remedy. Cures sobriety.", crew: "Pot Watcher" },
  { name: "The Rusty Anchor", emoji: "⚓",
    flavor: "A bait shop out front. Nobody has ever bought bait.", crew: "Barkeep" },
  { name: "Bathtub Gin Works", emoji: "🛁",
    flavor: "Small batch. Very small. It's one bathtub.", crew: "Tub Chemist" },
  { name: "Basement Brewery", emoji: "🛢️",
    flavor: "Under the bakery. The bread smells suspiciously of hops.", crew: "Brewmaster" },
  { name: "Smuggling Route", emoji: "⛵",
    flavor: "Canadian whiskey takes the scenic route south.", crew: "Boat Captain" },
  { name: "Whiskey Warehouse", emoji: "🥃",
    flavor: "The ledger says 'molasses.' Everything says molasses.", crew: "Night Foreman" },
  { name: "The Broken Clock", emoji: "🎷",
    flavor: "Knock twice, hum a bar of jazz, know the word.", crew: "Door Man" },
  { name: "Casino Back Room", emoji: "🎰",
    flavor: "The roulette wheel is honest. The room isn't.", crew: "Pit Boss" },
  { name: "Rum-Running Fleet", emoji: "🚤",
    flavor: "Twelve boats. Zero fishing licenses.", crew: "Fleet Commodore" },
  { name: "Racetrack Fix", emoji: "🐎",
    flavor: "The horses are fast. The results are faster.", crew: "Track Insider" },
  { name: "Uptown Supper Club", emoji: "🥂",
    flavor: "The soup course is soup. The 'tea' course isn't.", crew: "Maître d'" },
  { name: "Country Club Cellar", emoji: "⛳",
    flavor: "Eighteen holes, one very deep wine cellar.", crew: "Club Steward" },
  { name: "Mega-Distillery", emoji: "🏭",
    flavor: "Industrial-grade 'vinegar' by the tanker car.", crew: "Plant Overseer" },
  { name: "Harbor Freight Co.", emoji: "🚢",
    flavor: "Crates labeled BIBLES. Heavy, clinking bibles.", crew: "Harbor Master" },
  { name: "Railroad Skim", emoji: "🚂",
    flavor: "Every boxcar through New Carthage tithes to the family.", crew: "Rail Agent" },
  { name: "The Syndicate", emoji: "👑",
    flavor: "Five families, one table, your chair at the head.", crew: "Consigliere" },
];

export const MYSTERY_CARD = {
  title: (n: number) => `${n} more rackets in the wings`,
  sub: "Grow the family to see what New Carthage offers next.",
  icon: "🗞️",
} as const;

// ---------------------------------------------------------------------------
// Sal the Haberdasher (the Fixer) — flex economy reskin. IDs persisted.
// ---------------------------------------------------------------------------

export const FIXER = {
  name: "Sal the Haberdasher",
  status: "around · probably at the cigar counter",
  role: "procurer of fine things",
  greeting: "Evenin'. Been hearing your name in the good rooms. Let me dress the part for you — that's just good business.",
  introFollowYes: "That's the spirit. Check my other lines — pocket and garage — when you're ready to look the part.",
  introFollowWho: "Sal. I make serious people look serious. Stick around.",
  purchaseBarks: [
    "That's not a purchase. That's a reputation.",
    "Receipts are for citizens.",
    "We don't buy things. We buy respect.",
    "An heirloom now. Historically significant.",
  ],
  downgradeBark: "The street didn't understand my vision.",
  brokeBark: "Come back when the till's heavier.",
  idleCarBarks: [
    "I don't drive to work. I drive to be seen not working.",
    "Mileage? Kings don't read odometers.",
  ],
  idleWatchBarks: [
    "Time is money. That's why I keep it in my pocket.",
    "It loses four minutes a day. So do I.",
  ],
  idleBarks: [
    "Rise and grind. Mostly rise.",
    "My morning routine is forty minutes of hat angles.",
  ],
  tier4Bark: "The hangar is rented. The altitude is real.",
  stashBark: "It's in the wardrobe. Wear it when you want to be seen.",
  passBark: "Fair. Class waits for cash.",
  dmsLockedTitle: "Someone's asking about you",
  dmsLockedSub: "A certain haberdasher only calls on operators who move product. Open <b>The Rusty Anchor</b> to get his attention.",
  dmsLockedCta: "SHOW ME THE RACKETS",
  waiting: "Sal is waiting on you…",
  idleReply: "Keep stacking — Sal will come around.",
  threads: {
    intro: { title: "Sal the Haberdasher", preview: "Evenin'. Been hearing your name…" },
    wrist: { title: "Sal · Pocket Watches", preview: "The watch chain is the whole argument." },
    garage: { title: "Sal · Garage", preview: "You don't drive it. You park it where the papers eat lunch." },
  },
  tierNames: ["", "Knockoff", "Genuine", "Heirloom", "Legend"],
} as const;

/** Fixer item display content, keyed by persisted item id. */
export const FIXER_ITEMS: Record<string, { name: string; blurb: string; boost: string; emoji: string }> = {
  fauxlex: { name: "Pawnshop Pocket Watch", emoji: "⌚",
    blurb: "Ticks loud enough to hear across the bar.",
    boost: "+5% income, all rackets" },
  tagheuer: { name: "Swiss Chronometer", emoji: "⏱️",
    blurb: "Genuine. The customs stamp is the fake part.",
    boost: "+15% income, established rackets (Tier 1+)" },
  daytona: { name: "The Judge's Heirloom", emoji: "🕰️",
    blurb: "Won in a card game the judge denies attending.",
    boost: "+2% Legacy gain — permanent, survives a New Family" },
  mille: { name: "The Minute Repeater", emoji: "💎",
    blurb: "Chimes the hour. Nobody who owns one needs to know the hour.",
    boost: "×2 income for 10s whenever you expand a racket" },
  civic: { name: "Rusty Flivver", emoji: "🚗",
    blurb: "Backfires like a starter pistol. Keeps meetings short.",
    boost: "−5% batch time, all rackets" },
  charger: { name: "Bootlegger's Ford", emoji: "🚙",
    blurb: "Stock body, souped engine, false floor.",
    boost: "−10% batch time, established rackets (Tier 1+)" },
  lambo: { name: "Borrowed Duesenberg", emoji: "🏎️",
    blurb: "Borrowed indefinitely. The owner is very understanding.",
    boost: "25% chance a milestone makes the FRONT PAGE early (×2, 60s)" },
  bugatti: { name: "The Silver Phantom", emoji: "🚘",
    blurb: "Paid in full. Do not ask in what.",
    boost: "Your smallest racket runs at your best milestone tier" },
};

// ---------------------------------------------------------------------------
// The Boss (persona) — IDs persisted, display re-themed.
// ---------------------------------------------------------------------------

export const BOSS = {
  screenTitle: "THE BOSS",
  colorwayLabel: "FAMILY COLORS",
  wardrobeLabel: "WARDROBE",
  lifetimeStat: "fortune",
  footnote: "Style is forever — your alias, look and wardrobe survive a New Family.",
  creation: {
    kicker: "NEW CARTHAGE · 1926",
    title: "BOOTLEG EMPIRE",
    sub: "Build the outfit. Wet the city's whistle.",
    handleLabel: "YOUR ALIAS",
    handlePlaceholder: "lucky",
    lookLabel: "PICK YOUR LOOK",
    colorLabel: "FAMILY COLORS",
    cta: "OPEN FOR BUSINESS",
  },
  looks: {
    // ids persisted from the old game — display only here
    hoodie: { name: "Flat Cap & Suspenders", emoji: "🧢" },
    bizcaz: { name: "Three-Piece Suit", emoji: "🎩" },
    street: { name: "Dockworker Denim", emoji: "⚓" },
    gym: { name: "Silk Robe & Slippers", emoji: "🥂" },
  } as Record<string, { name: string; emoji: string }>,
  slots: { Clothes: "Suits", Jewelry: "Rings", Watch: "Watches" } as Record<string, string>,
  tierNames: ["", "Modest", "Sharp", "Stately", "Heirloom"],
  grailNote: " · +0.5% Legacy on New Family",
  items: {
    thrifted: { name: "Secondhand Tweed", emoji: "🧥" },
    streetdrop: { name: "Tailored Pinstripe", emoji: "🤵" },
    designer: { name: "Paris Import Suit", emoji: "🎩" },
    couture: { name: "Bespoke White Tuxedo", emoji: "🕊️" },
    fakechain: { name: "Brass Ring", emoji: "💍" },
    realchain: { name: "Gold Signet Ring", emoji: "🪙" },
    grill: { name: "Diamond Stickpin", emoji: "📌" },
    iced: { name: "Ruby Everything", emoji: "♦️" },
    p_fauxlex: { name: "Pawnshop Pocket Watch", emoji: "⌚" },
    p_tagheuer: { name: "Swiss Chronometer", emoji: "⏱️" },
    p_daytona: { name: "The Judge's Heirloom", emoji: "🕰️" },
    p_mille: { name: "The Minute Repeater", emoji: "💎" },
  } as Record<string, { name: string; emoji: string }>,
} as const;

// ---------------------------------------------------------------------------
// New Family (prestige)
// ---------------------------------------------------------------------------

export const FAMILY = {
  title: "START A NEW FAMILY",
  sub: "Burn the ledgers. Keep the name. Every Legacy token boosts all income by 2% — forever.",
  statHeld: "LEGACY HELD",
  statBonus: "INCOME BONUS",
  statGain: "ON NEW FAMILY",
  keepTitle: "✓ THE FAMILY KEEPS",
  keeps: ["Legacy & its income bonus", "Respect & the fortune's record", "Your alias & wardrobe", "The Judge's favor"],
  loseTitle: "✗ THE FAMILY LOSES",
  loses: (cash: string) => [`Cash on hand (${cash})`, "All rackets & crews", "Sal's rented finery", "Heat, payrolls & buffs"],
  cta: "START A NEW FAMILY",
  ctaArmed: (gain: string) => `TAP AGAIN — GAIN ${gain} LEGACY`,
  lockedTitle: "Grow the Family Fortune (clean cash) to earn the first Legacy token.",
  perksTitle: "WHAT LEGACY BUYS",
  toastTitle: "A NEW FAMILY RISES",
  toastSub: (gain: string) => `+${gain} Legacy secured`,
  bonusNote: (pct: number, daytonas: number) =>
    `🕰️ Legacy gain boosted +${pct}%${daytonas > 0 ? ` (Judge's Heirloom ×${daytonas})` : ""}`,
} as const;

/** Family Fortune (lifetime clean) per √-step of Legacy. */
export const LEGACY_DIVISOR = 10_000;

// ---------------------------------------------------------------------------
// Offline earnings & misc UI copy
// ---------------------------------------------------------------------------

export const MISC = {
  offlineTitle: "While you were lying low…",
  offlineSub: "The crews kept the stills warm.",
  offlineCta: "COLLECT THE TAKE",
  portfolio: "THE RACKETS",
  running: (a: number, b: number) => `${a}/${b} rackets running`,
  soundOn: "Sound on",
  soundOff: "Sound off",
} as const;

// ---------------------------------------------------------------------------
// Front businesses (laundering) — §2. IDs persisted; stats live here because
// fronts are new in this version (no legacy tuning to protect).
// ---------------------------------------------------------------------------

export interface FrontDef {
  id: string;
  name: string;
  flavor: string;
  emoji: string;
  district: string;
  /** Plot price. Clean cash — except the Laundromat, the scripted starter. */
  price: number;
  priceCurrency: "dirty" | "clean";
  /** $/s of dirty cash washed at level 1. */
  baseThroughput: number;
  /** Fraction lost in the wash at level 1. */
  baseCut: number;
  /** Cut shrinks this much per level (floored at cutFloor). */
  cutPerLevel: number;
  cutFloor: number;
  /** Throughput multiplies by this per level. */
  throughputGrowth: number;
  /** Level-2 upgrade price (clean); grows ×upgradeGrowth per level. */
  upgradeBase: number;
  upgradeGrowth: number;
  /** Optional flavor-visible perk, wired in later phases. */
  perk?: "velvet_income" | "less_shipment_heat";
}

export const FRONTS: FrontDef[] = [
  { id: "laundromat", name: "Sunrise Laundromat", emoji: "🧺",
    flavor: "We clean shirts. Mostly shirts. Some paper.",
    district: "docks", price: 600, priceCurrency: "dirty",
    baseThroughput: 26, baseCut: 0.35, cutPerLevel: 0.012, cutFloor: 0.2,
    throughputGrowth: 1.55, upgradeBase: 1_400, upgradeGrowth: 1.85 },
  { id: "barber", name: "Kowalski's Barber Shop", emoji: "💈",
    flavor: "Two chairs, one till, zero questions.",
    district: "warsaw", price: 30_000, priceCurrency: "clean",
    baseThroughput: 140, baseCut: 0.32, cutPerLevel: 0.012, cutFloor: 0.18,
    throughputGrowth: 1.55, upgradeBase: 45_000, upgradeGrowth: 1.85 },
  { id: "velvet", name: "The Velvet Room", emoji: "🎷",
    flavor: "Feathers, brass, a band that never sleeps — and a very busy till.",
    district: "downtown", price: 900_000, priceCurrency: "clean",
    baseThroughput: 1_100, baseCut: 0.28, cutPerLevel: 0.01, cutFloor: 0.16,
    throughputGrowth: 1.55, upgradeBase: 1_300_000, upgradeGrowth: 1.85,
    perk: "velvet_income" },
  { id: "hotel", name: "The Grand Carthage Hotel", emoji: "🏨",
    flavor: "Four stars in the paper. Five ledgers in the safe.",
    district: "row", price: 75_000_000, priceCurrency: "clean",
    baseThroughput: 11_000, baseCut: 0.25, cutPerLevel: 0.01, cutFloor: 0.14,
    throughputGrowth: 1.55, upgradeBase: 100_000_000, upgradeGrowth: 1.85 },
  { id: "importexport", name: "Meridian Import/Export Co.", emoji: "🚢",
    flavor: "Everything is 'olive oil.' The manifests are works of art.",
    district: "islands", price: 4_000_000_000, priceCurrency: "clean",
    baseThroughput: 120_000, baseCut: 0.22, cutPerLevel: 0.008, cutFloor: 0.12,
    throughputGrowth: 1.55, upgradeBase: 5_500_000_000, upgradeGrowth: 1.85,
    perk: "less_shipment_heat" },
];

/** The Velvet Room's own legit take, per level, per second (clean). */
export const VELVET_CLEAN_INCOME_PER_LEVEL = 45;

export const LAUNDER = {
  sectionTitle: "THE FRONTS",
  sectionSub: "Dirty money goes in. Respectable money comes out. Some evaporates.",
  washing: (rate: string) => `washing ${rate}/s`,
  keeps: (pct: number) => `keeps ${pct}%`,
  idle: "till is quiet — no dirty cash to wash",
  buy: "BUY THE DEED",
  upgrade: "EXPAND",
  dirtyLabel: "DIRTY",
  cleanLabel: "CLEAN",
  dirtyHint: "Dirty cash runs the rackets: expansions, crews, bribes, Sal.",
  cleanHint: "Clean cash buys deeds, front upgrades, lawyers and bail.",
} as const;

// ---------------------------------------------------------------------------
// The city map — §3. World coordinates in a 2000×1400 space.
// ---------------------------------------------------------------------------

export interface DistrictDef {
  id: string;
  name: string;
  blurb: string;
  /** Clean-cash price to unlock (docks is free/start). */
  price: number;
  /** Respect level required (enforced from Phase 5). */
  respectLevel: number;
  /** Land rectangle in world coords. */
  rect: { x: number; y: number; w: number; h: number };
  /** Muted land tint (drawn over paper base). */
  tint: string;
}

export const WORLD = { w: 2000, h: 1400 } as const;

export const DISTRICTS: DistrictDef[] = [
  { id: "docks", name: "The Docks", price: 0, respectLevel: 0,
    blurb: "Salt air, crooked cranes, and everything falls off a truck eventually.",
    rect: { x: 110, y: 860, w: 580, h: 420 }, tint: "#8f8672" },
  { id: "warsaw", name: "Little Warsaw", price: 15_000, respectLevel: 3,
    blurb: "Working folk, warm kitchens, basements with very thick doors.",
    rect: { x: 110, y: 390, w: 580, h: 420 }, tint: "#948a70" },
  { id: "downtown", name: "Downtown", price: 1_500_000, respectLevel: 6,
    blurb: "Neon, brass, and City Hall — everything here has a price tag.",
    rect: { x: 750, y: 340, w: 540, h: 540 }, tint: "#9a8e74" },
  { id: "row", name: "Millionaire's Row", price: 100_000_000, respectLevel: 10,
    blurb: "Old money, new friends. The Judge takes his tea at four.",
    rect: { x: 1350, y: 150, w: 540, h: 430 }, tint: "#a29677" },
  { id: "islands", name: "The Harbor Islands", price: 5_000_000_000, respectLevel: 14,
    blurb: "Past the breakwater, past the law. The empire's blue-water edge.",
    rect: { x: 1400, y: 950, w: 480, h: 360 }, tint: "#8a8168" },
];

export function districtByID(id: string): DistrictDef {
  return DISTRICTS.find((d) => d.id === id) ?? DISTRICTS[0];
}

export type PlotKind = "racket" | "front" | "precinct" | "landmark";

export interface PlotDef {
  id: string;
  kind: PlotKind;
  /** racket → HUSTLES index; front → FrontDef id; else landmark id. */
  ref: number | string;
  district: string;
  /** Building footprint center, world coords. */
  x: number;
  y: number;
  /** Footprint scale (1 = standard 90×70 building). */
  size?: number;
}

export const PLOTS: PlotDef[] = [
  // The Docks
  { id: "p_still", kind: "racket", ref: 0, district: "docks", x: 220, y: 1010 },
  { id: "p_anchor", kind: "racket", ref: 1, district: "docks", x: 440, y: 1155 },
  { id: "p_gin", kind: "racket", ref: 2, district: "docks", x: 615, y: 1010 },
  { id: "p_smuggle", kind: "racket", ref: 4, district: "docks", x: 590, y: 1230, size: 1.1 },
  { id: "p_laundromat", kind: "front", ref: "laundromat", district: "docks", x: 235, y: 1160 },
  { id: "pr_docks", kind: "precinct", ref: "precinct_docks", district: "docks", x: 425, y: 1010, size: 0.9 },
  // Little Warsaw
  { id: "p_brewery", kind: "racket", ref: 3, district: "warsaw", x: 240, y: 520 },
  { id: "p_warehouse", kind: "racket", ref: 5, district: "warsaw", x: 560, y: 500, size: 1.15 },
  { id: "p_clock", kind: "racket", ref: 6, district: "warsaw", x: 300, y: 690 },
  { id: "p_barber", kind: "front", ref: "barber", district: "warsaw", x: 520, y: 700, size: 0.9 },
  { id: "pr_warsaw", kind: "precinct", ref: "precinct_warsaw", district: "warsaw", x: 420, y: 590, size: 0.9 },
  // Downtown
  { id: "p_casino", kind: "racket", ref: 7, district: "downtown", x: 880, y: 460 },
  { id: "p_racetrack", kind: "racket", ref: 9, district: "downtown", x: 1150, y: 480, size: 1.2 },
  { id: "p_supper", kind: "racket", ref: 10, district: "downtown", x: 870, y: 640 },
  { id: "p_velvet", kind: "front", ref: "velvet", district: "downtown", x: 1050, y: 700, size: 1.25 },
  { id: "lm_cityhall", kind: "landmark", ref: "cityhall", district: "downtown", x: 1010, y: 430, size: 1.2 },
  { id: "pr_downtown", kind: "precinct", ref: "precinct_downtown", district: "downtown", x: 1190, y: 800 },
  // Millionaire's Row
  { id: "p_country", kind: "racket", ref: 11, district: "row", x: 1480, y: 270 },
  { id: "p_railroad", kind: "racket", ref: 14, district: "row", x: 1760, y: 240, size: 1.15 },
  { id: "p_hotel", kind: "front", ref: "hotel", district: "row", x: 1550, y: 450, size: 1.3 },
  { id: "lm_judge", kind: "landmark", ref: "judge", district: "row", x: 1780, y: 430, size: 1.1 },
  { id: "pr_row", kind: "precinct", ref: "precinct_row", district: "row", x: 1650, y: 320, size: 0.9 },
  // The Harbor Islands
  { id: "p_fleet", kind: "racket", ref: 8, district: "islands", x: 1500, y: 1040 },
  { id: "p_distillery", kind: "racket", ref: 12, district: "islands", x: 1730, y: 1030, size: 1.2 },
  { id: "p_freight", kind: "racket", ref: 13, district: "islands", x: 1500, y: 1210 },
  { id: "p_syndicate", kind: "racket", ref: 15, district: "islands", x: 1780, y: 1220, size: 1.3 },
  { id: "p_importexport", kind: "front", ref: "importexport", district: "islands", x: 1620, y: 1120 },
];

export const LANDMARKS: Record<string, { name: string; emoji: string; blurb: string }> = {
  cityhall: { name: "City Hall", emoji: "🏛️",
    blurb: "Marble halls, flexible morals. Late-game friends live here." },
  judge: { name: "The Judge's Mansion", emoji: "⚖️",
    blurb: "The Judge takes his tea at four. Lawyer favors, coming soon." },
  precinct_docks: { name: "Precinct No. 1", emoji: "🚓",
    blurb: "The desk sergeant enjoys long lunches. Noted." },
  precinct_warsaw: { name: "Precinct No. 2", emoji: "🚓",
    blurb: "The captain admires a well-pressed suit. Noted." },
  precinct_downtown: { name: "Police Headquarters", emoji: "🚓",
    blurb: "Marble lobby. Everyone watches everyone." },
  precinct_row: { name: "Precinct No. 4", emoji: "🚓",
    blurb: "Quiet streets. Expensive quiet." },
};

export const MAP_COPY = {
  forSale: "FOR SALE",
  locked: (name: string, respect: number) =>
    `${name} — Reach Respect ${respect}`,
  unlockCta: (price: string) => `BUY INTO THE WARD · ${price}`,
  unlockToast: (name: string) => `${name.toUpperCase()} JOINS THE EMPIRE`,
  unlockToastSub: "New plots just hit the market",
  comingSoon: "COMING SOON",
  precinctIdle: "Nothing to discuss with the law. Yet.",
  landmarkIdle: "The doors are closed to you. For now.",
} as const;

// ---------------------------------------------------------------------------
// Heat, police & prison — §4. Consequences are a core mechanic.
// ---------------------------------------------------------------------------

export const HEAT_TUNING = {
  /** Passive heat/sec per racket unit, scaled up for later rackets. */
  passivePerUnit: 0.0008,
  racketWeight: (index: number) => 1 + index * 0.35,
  /** Dirty stockpile above this many seconds of laundering capacity heats up. */
  stockpileGraceSeconds: 150,
  stockpileFloor: 9_000,
  stockpileMaxRate: 0.08,
  stockpileRateK: 0.02,
  /** Passive cool-down when lying low. */
  decayPerSec: 0.012,
  /** Each active precinct payroll multiplies heat gain by this. */
  payrollFactor: 0.76,
  /** Payroll cost per minute, per precinct (dirty). */
  payrollPerMin: [90, 900, 40_000, 4_000_000] as number[],
  /** One-time bribe: cost scales with income and current heat. */
  bribeBase: (incomePerSec: number) => Math.max(150, incomePerSec * 25),
  bribeHeatScale: (heat: number) => Math.pow(1 + heat / 28, 2),
  bribeRelief: (heat: number) => 12 + heat * 0.22,
  investigationStartsAt: 70,
  investigationCallsOffBelow: 60,
  investigationSeconds: 120,
  investigationSecondsWithLawyer: 200,
  prisonBaseSeconds: 90,
  prisonMaxSeconds: 300,
  bailRate: 0.04, // × Family Fortune (lifetime clean)
  bailFloor: 500,
  heatAfterRelease: 30,
  /** Reopen fee: multiple of the racket's next-unit price (clean). */
  reopenFeeUnits: 2.5,
  caseDismissCooldownMs: 3_600_000,
} as const;

export const LAWYER_PERKS: { id: string; name: string; blurb: string; cost: number }[] = [
  { id: "retainer", name: "Counsel on Retainer",
    blurb: "Motions, continuances, lunches. Investigations take far longer to stick.",
    cost: 25_000_000 },
  { id: "bagman", name: "The Bail Bondsman",
    blurb: "Half-price bail. He knows the night clerk by her first name.",
    cost: 250_000_000 },
  { id: "silk_glove", name: "The Judge's Favor",
    blurb: "Once an hour, a case simply… evaporates. Terrible filing system down there.",
    cost: 2_000_000_000 },
];

export const HEAT_COPY = {
  label: "HEAT",
  safe: "The badge is bored",
  warm: "Eyes on the street",
  investigation: "UNDER INVESTIGATION",
  investigationSub: "The Feds are building a case…",
  raidToast: "RAID! FEDS SEIZE",
  raidToastSub: (name: string) => `${name} boarded up — the boss is downtown`,
  dismissToast: "CASE THROWN OUT!",
  dismissSub: "The Judge's favor holds. The file is lost.",
  releaseToast: "THE BOSS WALKS",
  releaseSub: "Heat settles to a simmer. You're a known face now.",
  panelTitle: "THE LAW",
  panelSub: "Heat rises with rackets, shipments and idle dirty cash. Pay it down or lie low.",
  sourcesTitle: "WHY THEY'RE WATCHING",
  srcRackets: "Rackets running",
  srcStockpile: "Dirty cash stockpile",
  srcPayroll: (n: number) => `${n} precinct${n === 1 ? "" : "s"} on payroll`,
  bribeCta: (cost: string) => `GREASE PALMS · 💵 ${cost}`,
  bribeDone: "The captain suddenly remembers a fishing trip.",
  payrollOn: (cost: string) => `PUT ON PAYROLL · 💵 ${cost}/min`,
  payrollActive: "CAPTAIN'S ON THE PAYROLL",
  payrollOff: "STOP PAYMENTS",
  prisonTitle: "COUNTY LOCKUP",
  prisonSub: "The family keeps the fronts washing at half speed. The rackets run without you.",
  prisonWait: "Sit tight",
  prisonBail: (cost: string) => `POST BAIL · 🏦 ${cost}`,
  prisonAd: "TELL IT TO THE PAPERS (soon)",
  raidedTag: "RAIDED",
  reopenCta: (cost: string) => `REOPEN · 🏦 ${cost}`,
  reopenNote: "Legal fees, new locks, a fresh coat of paint — and the ward remembers.",
  lawyerTitle: "THE JUDGE'S PARLOR",
  lawyerSub: "Favors, retainers, and a very understanding legal system.",
  owned: "SECURED",
} as const;

// ---------------------------------------------------------------------------
// Shipments — §5, the active-play moment.
// ---------------------------------------------------------------------------

export interface ShipmentRouteDef {
  id: string;
  name: string;
  blurb: string;
  emoji: string;
  vehicle: "truck" | "boat";
  /** Racket indices that must be owned (and not raided). */
  requires: number[];
  /** Plot ids the vehicle travels between. */
  fromPlot: string;
  toPlot: string;
  /** Multipliers on the base payout/heat table. */
  payoutMult: number;
  heatMult: number;
  travelSeconds: number;
}

export const SHIPMENT_ROUTES: ShipmentRouteDef[] = [
  { id: "still_run", name: "Still Run", emoji: "🚚", vehicle: "truck",
    blurb: "Mason jars under flour sacks, back roads the whole way.",
    requires: [0, 1], fromPlot: "p_still", toPlot: "p_anchor",
    payoutMult: 1, heatMult: 1, travelSeconds: 12 },
  { id: "rum_run", name: "Rum Run", emoji: "⛵", vehicle: "boat",
    blurb: "Twelve miles out, the law ends. The ledger doesn't.",
    requires: [4], fromPlot: "p_smuggle", toPlot: "p_anchor",
    payoutMult: 2.2, heatMult: 1.5, travelSeconds: 16 },
  { id: "harbor_convoy", name: "Harbor Convoy", emoji: "🚢", vehicle: "boat",
    blurb: "Three freighters of 'olive oil.' The manifests sing.",
    requires: [13], fromPlot: "p_freight", toPlot: "p_smuggle",
    payoutMult: 5, heatMult: 2.2, travelSeconds: 18 },
];

export const SHIPMENT_SIZES = [
  { id: "small", name: "Light Load", seconds: 25, heat: 3, floor: 120 },
  { id: "medium", name: "Full Truck", seconds: 75, heat: 7, floor: 600 },
  { id: "large", name: "The Works", seconds: 200, heat: 12, floor: 2_600 },
] as const;

export const SHIPMENT_COPY = {
  cta: "SHIPMENT",
  panelTitle: "SEND A SHIPMENT",
  panelSub: "Big loads pay big and draw eyes. The badge is watching the roads.",
  confirm: (pay: string, heat: number) => `+${pay} · +${heat} HEAT`,
  departed: "SHIPMENT ROLLING",
  departedSub: (name: string) => `${name} is on the move`,
  arrivedToast: "SHIPMENT LANDS!",
  arrivedSub: (pay: string) => `${pay} in dirty cash hits the till`,
  seizedToast: "SHIPMENT SEIZED!",
  seizedSub: "The raid caught the load on the road.",
  inTransit: (s: number) => `IN TRANSIT · ${s}s`,
  checkpointTitle: "CHECKPOINT AHEAD!",
  checkpointSub: "A badge waves the traffic down.",
  detour: (s: number) => `TAKE THE DETOUR · +${s}s, −half heat`,
  barrel: "BARREL THROUGH · +2 heat",
  needRoute: "Open the right rackets to run this route.",
  onlyOne: "One load at a time — the roads have eyes.",
} as const;

export const SHIPMENT_TUNING = {
  /** Payout ≈ potential income/sec × size.seconds, min size.floor. */
  checkpointChance: 0.5,
  detourExtraSeconds: 6,
  barrelExtraHeat: 2,
  respectXP: { still_run: 10, rum_run: 25, harbor_convoy: 60 } as Record<string, number>,
} as const;

// ---------------------------------------------------------------------------
// Respect levels (XP) & Legacy prestige — §6.
// ---------------------------------------------------------------------------

export const RESPECT = {
  label: "Respect",
  /** XP needed to go from level L to L+1 (L is 1-based). */
  xpForNext: (level: number) => Math.round(150 * Math.pow(1.55, level - 1)),
  xp: {
    perUnit: 1,
    firstPlot: 25,
    crewHire: 15,
    fixerItem: 5,
    districtUnlock: 200,
  },
  levelChip: (level: number) => `🤝 L${level}`,
  levelUpToast: (level: number) => `RESPECT RISES — LEVEL ${level}`,
  levelUpSub: "New doors open across New Carthage",
} as const;

export const LEGACY = {
  label: "Legacy",
  /** Each token: +2% income, −0.1% launder cut (cap 5%), −0.5 release heat. */
  cutPerToken: 0.001,
  cutCap: 0.05,
  releaseHeatPerToken: 0.5,
  releaseHeatFloor: 10,
  perks: (n: number) => [
    `+${(n * 2).toLocaleString()}% all production`,
    `−${Math.min(5, n * 0.1).toFixed(1)}% laundering cut`,
    `Release heat ${Math.max(10, 30 - n * 0.5).toFixed(0)} instead of 30`,
  ],
} as const;

/** Lawyer perk Respect-level requirements (id → level). */
export const LAWYER_RESPECT: Record<string, number> = {
  retainer: 10,
  bagman: 11,
  silk_glove: 13,
};

// ---------------------------------------------------------------------------
// Enzo the Consigliere — the guide who pops up when something new unlocks,
// so nobody has to guess what to do next. One tip at a time, each shown once.
// ---------------------------------------------------------------------------

export const GUIDE = {
  name: "Enzo",
  title: "CONSIGLIERE",
  avatar: "👴",
  dismiss: "GOT IT",
  show: "SHOW ME",
} as const;

export interface GuideTipDef {
  id: string;
  text: string;
  /** Tab the SHOW ME button jumps to. */
  tab?: "map" | "empire" | "dms" | "rebrand" | "profile";
}

export const GUIDE_TIPS: GuideTipDef[] = [
  { id: "welcome", tab: "empire",
    text: "Welcome to New Carthage, boss. Tap the Corner Still to RUN A BATCH — every empire starts with grandma's recipe." },
  { id: "first_expand", tab: "empire",
    text: "Cash in the till. BUY more stills — every 25 you own doubles the take and halves the wait." },
  { id: "laundromat_ready", tab: "empire",
    text: "You can afford the Sunrise Laundromat. Buy the deed — dirty money in, respectable money out. Clean cash is what buys this city." },
  { id: "first_clean", tab: "empire",
    text: "That's clean money now, boss. Deeds, front upgrades, lawyers, bail — the legitimate world only takes clean." },
  { id: "crew_ready", tab: "empire",
    text: "You've got enough to put a Pot Watcher on the still. Crews run the racket so it earns while you sleep." },
  { id: "shipment_ready", tab: "map",
    text: "The Rusty Anchor's pouring. Run a SHIPMENT from the City map — big dirty payout, big heat. That's the trade." },
  { id: "stockpile_warning", tab: "empire",
    text: "That pile of dirty cash is drawing eyes. Wash it faster — expand the fronts — or the badge starts asking questions." },
  { id: "heat_warning",
    text: "Heat's climbing, boss. Tap the badge up top — grease a palm, or put the precinct captain on the payroll." },
  { id: "investigation_help",
    text: "The Feds are building a case! Get the heat under 60 — bribe, lie low, stop shipping — or they kick a door in." },
  { id: "reopen_hint", tab: "empire",
    text: "They boarded up our racket. Reopen it with clean cash — legal fees, new locks. It comes back a little smaller. The ward remembers." },
  { id: "district_ready", tab: "map",
    text: "We've got the Respect and the clean cash for the next ward. Tap it on the City map and buy in — new rackets, new fronts." },
  { id: "velvet_ready", tab: "map",
    text: "Downtown's ours — and The Velvet Room is for sale. The showpiece front: washes a river and earns its own clean take." },
  { id: "prestige_ready", tab: "rebrand",
    text: "The fortune's big enough to become a legend, boss. Start a New Family — burn it all for Legacy that boosts every family after." },
];

// ---------------------------------------------------------------------------
// One-time milestone headlines — §6.
// ---------------------------------------------------------------------------

export const MILESTONES: Record<string, { title: string; sub: string; xp: number }> = {
  first_shipment: {
    title: "FIRST LOAD DELIVERED",
    sub: "Somewhere, a thirsty city sighs with relief", xp: 50 },
  velvet_open: {
    title: "THE VELVET ROOM OPENS ITS DOORS",
    sub: "Feathers! Brass! A trumpet solo the papers call 'indecently good'", xp: 150 },
  first_raid_survived: {
    title: "THE BOSS WALKS FREE",
    sub: "Reporters swarm the courthouse steps. The city takes notes", xp: 100 },
  bridge_islands: {
    title: "BRIDGE TO THE HARBOR ISLANDS COMPLETE",
    sub: "The empire reaches blue water at last", xp: 250 },
};
