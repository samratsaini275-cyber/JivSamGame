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
  { name: "The Velvet Room", emoji: "🎭",
    flavor: "Feathers, brass, and a band that never sleeps.", crew: "Stage Manager" },
  { name: "Grand Hotel Skim", emoji: "🏨",
    flavor: "Every suite pays twice. Once at the front desk.", crew: "Concierge" },
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
    boost: "+2% Respect gain — permanent, survives a New Family" },
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
  grailNote: " · +0.5% Respect on New Family",
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
  sub: "Burn the ledgers. Keep the name. Every point of Respect boosts all income by 2% — forever.",
  statHeld: "RESPECT HELD",
  statBonus: "INCOME BONUS",
  statGain: "ON NEW FAMILY",
  keepTitle: "✓ THE FAMILY KEEPS",
  keeps: ["Respect & its income bonus", "The fortune's record", "Your alias & wardrobe", "The Judge's favor"],
  loseTitle: "✗ THE FAMILY LOSES",
  loses: (cash: string) => [`Cash on hand (${cash})`, "All rackets & crews", "Sal's rented finery", "Active buffs"],
  cta: "START A NEW FAMILY",
  ctaArmed: (gain: string) => `TAP AGAIN — GAIN ${gain} RESPECT`,
  lockedTitle: "Grow the fortune to earn the family's first Respect.",
  toastTitle: "A NEW FAMILY RISES",
  toastSub: (gain: string) => `+${gain} Respect secured`,
  bonusNote: (pct: number, daytonas: number) =>
    `🕰️ Respect gain boosted +${pct}%${daytonas > 0 ? ` (Judge's Heirloom ×${daytonas})` : ""}`,
} as const;

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
    baseThroughput: 14, baseCut: 0.35, cutPerLevel: 0.012, cutFloor: 0.2,
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
// Later-phase content (districts, heat, shipments) lands here too so the
// whole skin stays in one file. Populated in Phases 3–5.
// ---------------------------------------------------------------------------
