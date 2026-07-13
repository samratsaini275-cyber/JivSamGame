// ============================================================================
// DRUG EMPIRE — theme config. THE single source of truth for every
// player-facing name, string, and color. Eastport, present day. Fictional
// city, fictional people, bloodless crime-drama tone (The Wire, not slapstick).
// If a store review ever demands changes, this is the only file to edit.
// ============================================================================

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

export const GAME = {
  title: "DRUG EMPIRE",
  city: "Eastport",
  year: "Present Day",
  tagline: "Own every corner. Keep the heat off your back.",
  masthead: "EASTPORT BREAKING NEWS", // news toasts
} as const;

// ---------------------------------------------------------------------------
// Palette — Street Noir: cold concrete + night ink. Gold is EXCLUSIVELY money;
// red is EXCLUSIVELY heat.
// ---------------------------------------------------------------------------

export const PALETTE = {
  ink: "#10131a",
  inkRaised: "#1a1f2a",
  inkDeep: "#0a0c11",
  paper: "#e7ebf2",
  paperDark: "#c7cdd8",
  paperInk: "#12161e", // text on light surfaces
  gold: "#e0b64f",
  goldDeep: "#8a6a1d",
  heatRed: "#c22a33",
  teal: "#3a7080",
  dirtyGreen: "#7ca163",
  textMuted: "rgba(231, 235, 242, 0.55)",
  textFaint: "rgba(231, 235, 242, 0.32)",
} as const;

/** Player-picked accent — identity moments only (avatar ring, wardrobe). */
export interface ColorwayDef {
  id: string; // persisted — do not rename
  name: string;
  accent: string;
  accentDeep: string;
}

export const COLORWAYS: ColorwayDef[] = [
  { id: "gold", name: "24K", accent: "#e0b64f", accentDeep: "#8a6a1d" },
  { id: "volt", name: "Volt", accent: "#9fc86a", accentDeep: "#3f6023" },
  { id: "ice", name: "Ice", accent: "#a8d5e2", accentDeep: "#39708a" },
  { id: "crimson", name: "Blood", accent: "#c65a5a", accentDeep: "#5c1420" },
  { id: "amethyst", name: "Purp", accent: "#b58ed0", accentDeep: "#4a2a66" },
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
  fortune: "Net Worth",
  respect: "Respect",
  legacy: "Legacy",
  heat: "Heat",
  perSec: "/sec",
  buy: "BUY",
  start: "OPEN",
  runBatch: "MOVE A PACK",
  shipment: "SHIPMENT",
  automated: "CREW",
  maxed: "KINGPIN",
  tabs: { map: "City", ledger: "Hustles", fixer: "The Fixer", family: "Empire", boss: "The Boss" },
} as const;

/** Milestone tier names (25/50/100/200/300/400 units). */
export const TIER_NAMES = [
  "Unknown",
  "Corner Talk",
  "Block Famous",
  "Hood Legend",
  "City Legend",
  "State Menace",
  "Prime-Time News",
  "Untouchable",
];

export function tierName(tier: number): string {
  return TIER_NAMES[Math.min(tier, TIER_NAMES.length - 1)];
}

/** The old "viral moment" — the whole city talks, income ×2^tier. */
export const PRESS = {
  chip: "NEWS",
  tracker: "Next Headline",
  toastTitle: "BREAKING NEWS",
  toastSub: (mult: number) => `The whole city's talking — every hustle earns ×${mult}`,
  milestoneToast: (name: string, tier: string) => `${name} is now a ${tier}!`,
  milestoneSub: "Income ×2, packs move twice as fast",
} as const;

// ---------------------------------------------------------------------------
// Hustles (illegal producers) — indices are load-bearing: they map 1:1 onto
// the original tuned stat rows (baseCost/baseIncome/baseCycle) and old saves.
// The ladder tells the story: weed corners → coke money → the cartel table.
// ---------------------------------------------------------------------------

export interface BizContent {
  name: string;
  flavor: string;
  emoji: string;
  crew: string; // the staff hire that automates it (old "ghostwriter")
}

export const BIZ: BizContent[] = [
  { name: "Corner Spot", emoji: "🌿",
    flavor: "Dime bags and hand signals. Everybody starts somewhere.", crew: "Lookout" },
  { name: "Smoke Shop", emoji: "🏪",
    flavor: "Sells rolling papers out front. The back room sells the reason.", crew: "Counter Guy" },
  { name: "Grow House", emoji: "🏠",
    flavor: "A rented two-bed with blacked-out windows and a stadium light bill.", crew: "Grower" },
  { name: "Pill Mill", emoji: "💊",
    flavor: "A strip-mall clinic. The doctor's pen never runs dry.", crew: "Crooked Doc" },
  { name: "Smuggling Route", emoji: "🎣",
    flavor: "Product comes up the coast in fishing boats. The catch is never fish.", crew: "Skipper" },
  { name: "Stash Warehouse", emoji: "📦",
    flavor: "The manifest says office furniture. Everything says office furniture.", crew: "Night Foreman" },
  { name: "After-Hours Club", emoji: "🔊",
    flavor: "No sign, no listing. Bass you feel through the sidewalk.", crew: "Door Man" },
  { name: "Underground Casino", emoji: "🎰",
    flavor: "The tables are honest. The room isn't.", crew: "Pit Boss" },
  { name: "Go-Fast Fleet", emoji: "🚤",
    flavor: "Twelve cigarette boats. Zero fishing licenses.", crew: "Fleet Captain" },
  { name: "Chop Shop", emoji: "🔧",
    flavor: "Cars come in. VIN numbers don't come out.", crew: "Shop Foreman" },
  { name: "Uptown Nightclub", emoji: "🍾",
    flavor: "Bottle service out front. The office safe does the real volume.", crew: "Club Manager" },
  { name: "Country Club Connect", emoji: "⛳",
    flavor: "Eighteen holes, one very discreet clientele.", crew: "Club Steward" },
  { name: "The Superlab", emoji: "⚗️",
    flavor: "Industrial-grade product by the pallet.", crew: "Head Chemist" },
  { name: "Container Line", emoji: "🚢",
    flavor: "One container in ten thousand gets opened. Yours never is.", crew: "Harbor Master" },
  { name: "Trucking Network", emoji: "🚛",
    flavor: "Every eighteen-wheeler through Eastport tithes to the operation.", crew: "Dispatcher" },
  { name: "The Cartel", emoji: "👑",
    flavor: "Five crews, one table, your chair at the head.", crew: "The Underboss" },
];

export const MYSTERY_CARD = {
  title: (n: number) => `${n} more hustles in the wings`,
  sub: "Grow the operation to see what Eastport offers next.",
  icon: "💼",
} as const;

// ---------------------------------------------------------------------------
// Sosa the Fixer — flex economy reskin. IDs persisted.
// ---------------------------------------------------------------------------

export const SHOP = {
  title: "SOSA'S IMPORTS",
  sub: "Sosa sells one thing: an edge. Wear a watch, earn more. Drive right, work faster.",
  pitch: "Evening, boss. Everything on this table makes your whole operation richer or faster. Pick your poison.",
  wristTitle: "WATCHES",
  wristSub: "Boost the money every hustle earns",
  garageTitle: "CARS",
  garageSub: "Speed up every hustle you run",
  equipped: "WEARING",
  wearing: "WEARING NOW",
  equip: "WEAR THIS",
  owned: "IN THE STASH",
  buy: "BUY",
  bestOwned: "Your best is equipped automatically.",
  lockedTitle: "Sosa only deals with real operators",
  lockedSub: "Open your second hustle — the Smoke Shop — and Sosa comes calling with his catalog.",
  lockedCta: "SHOW ME THE HUSTLES",
} as const;

export const FIXER = {
  name: "Sosa the Fixer",
  status: "around · probably in the parking garage",
  role: "procurer of fine things",
  greeting: "Evening. Been hearing your name in the right rooms. Let me put you in something that fits the résumé — that's just good business.",
  introFollowYes: "That's the spirit. Check my other lines — wrist and garage — when you're ready to look the part.",
  introFollowWho: "Sosa. I make serious people look serious. Stick around.",
  purchaseBarks: [
    "That's not a purchase. That's a reputation.",
    "Receipts are for civilians.",
    "We don't buy things. We buy respect.",
    "Instant classic. Museum grade.",
  ],
  downgradeBark: "The street didn't understand my vision.",
  brokeBark: "Come back when the count's heavier.",
  idleCarBarks: [
    "I don't drive to work. I drive to be seen not working.",
    "Mileage? Bosses don't read odometers.",
  ],
  idleWatchBarks: [
    "Time is money. Mine's iced.",
    "It loses four minutes a day. So do I.",
  ],
  idleBarks: [
    "Rise and grind. Mostly rise.",
    "My morning routine is forty minutes of mirror.",
  ],
  tier4Bark: "The hangar is rented. The altitude is real.",
  stashBark: "It's in the stash. Wear it when you want to be seen.",
  passBark: "Fair. Class waits for cash.",
  dmsLockedTitle: "Someone's asking about you",
  dmsLockedSub: "A certain fixer only calls on operators who move product. Open the <b>Smoke Shop</b> to get his attention.",
  dmsLockedCta: "SHOW ME THE HUSTLES",
  waiting: "Sosa is waiting on you…",
  idleReply: "Keep stacking — Sosa will come around.",
  threads: {
    intro: { title: "Sosa the Fixer", preview: "Evening. Been hearing your name…" },
    wrist: { title: "Sosa · Watches", preview: "The wrist is the whole argument." },
    garage: { title: "Sosa · Garage", preview: "You don't drive it. You park it where everyone eats lunch." },
  },
  tierNames: ["", "Knockoff", "Genuine", "Collector", "Legend"],
} as const;

/** Fixer item display content, keyed by persisted item id. */
export const FIXER_ITEMS: Record<string, { name: string; blurb: string; boost: string; emoji: string }> = {
  fauxlex: { name: "Canal Street Rolex", emoji: "⌚",
    blurb: "Ticks loud enough to hear across the club.",
    boost: "Every hustle earns +5% more money" },
  tagheuer: { name: "TAG Heuer Carrera", emoji: "⏱️",
    blurb: "Genuine. The customs paperwork is the fake part.",
    boost: "Your bigger hustles earn +15% more money" },
  daytona: { name: "The Steel Daytona", emoji: "🕰️",
    blurb: "Ten-year waitlist. Sosa's list took ten minutes.",
    boost: "+2% Legacy forever — this one you keep after a reset" },
  mille: { name: "The Richard Mille", emoji: "💎",
    blurb: "Costs more than the building. Tells worse time.",
    boost: "Double money for 10s every time you buy a hustle" },
  civic: { name: "Beater Civic", emoji: "🚗",
    blurb: "A quarter-million miles and invisible to police.",
    boost: "Every hustle runs 5% faster" },
  charger: { name: "Blacked-Out Charger", emoji: "🚙",
    blurb: "Stock body, built motor, false floor.",
    boost: "Your bigger hustles run 10% faster" },
  lambo: { name: "Leased Lambo", emoji: "🏎️",
    blurb: "The lease is in someone else's name. So are the tickets.",
    boost: "Level-ups sometimes make the news — double money, 60s" },
  bugatti: { name: "The Bugatti", emoji: "🚘",
    blurb: "Paid in full. Do not ask in what.",
    boost: "Your smallest hustle runs at your best speed" },
};

// ---------------------------------------------------------------------------
// The Boss (persona) — IDs persisted, display re-themed.
// ---------------------------------------------------------------------------

export const BOSS = {
  screenTitle: "THE BOSS",
  colorwayLabel: "CREW COLORS",
  wardrobeLabel: "WARDROBE",
  lifetimeStat: "net worth",
  footnote: "Style is forever — your alias, look and wardrobe survive a New Operation.",
  creation: {
    kicker: "EASTPORT · PRESENT DAY",
    title: "DRUG EMPIRE",
    sub: "Build the operation. Own every corner.",
    handleLabel: "YOUR ALIAS",
    handlePlaceholder: "ghost",
    lookLabel: "PICK YOUR LOOK",
    colorLabel: "CREW COLORS",
    cta: "OPEN FOR BUSINESS",
  },
  looks: {
    // ids persisted from the old game — display only here
    hoodie: { name: "Hoodie & Joggers", emoji: "🧢" },
    bizcaz: { name: "Business Casual", emoji: "💼" },
    street: { name: "Head-to-Toe Streetwear", emoji: "👟" },
    gym: { name: "Designer Tracksuit", emoji: "🕶️" },
  } as Record<string, { name: string; emoji: string }>,
  slots: { Clothes: "Fits", Jewelry: "Chains", Watch: "Watches" } as Record<string, string>,
  tierNames: ["", "Basic", "Fresh", "Designer", "Grail"],
  grailNote: " · +0.5% Legacy on New Operation",
  items: {
    thrifted: { name: "Thrift-Store Fit", emoji: "🧥" },
    streetdrop: { name: "Limited Drop", emoji: "🤵" },
    designer: { name: "Designer Head-to-Toe", emoji: "🕶️" },
    couture: { name: "Custom Couture", emoji: "🕊️" },
    fakechain: { name: "Fake Cuban Link", emoji: "💍" },
    realchain: { name: "Solid Gold Cuban", emoji: "🪙" },
    grill: { name: "Diamond Grill", emoji: "😬" },
    iced: { name: "Iced-Out Everything", emoji: "♦️" },
    p_fauxlex: { name: "Canal Street Rolex", emoji: "⌚" },
    p_tagheuer: { name: "TAG Heuer Carrera", emoji: "⏱️" },
    p_daytona: { name: "The Steel Daytona", emoji: "🕰️" },
    p_mille: { name: "The Richard Mille", emoji: "💎" },
  } as Record<string, { name: string; emoji: string }>,
} as const;

// ---------------------------------------------------------------------------
// New Operation (prestige)
// ---------------------------------------------------------------------------

export const FAMILY = {
  title: "START A NEW OPERATION",
  sub: "Burn it all down. Keep the name. Every Legacy token makes every hustle earn +3% more — forever.",
  statHeld: "LEGACY HELD",
  statBonus: "INCOME BONUS",
  statGain: "ON NEW OPERATION",
  keepTitle: "YOU KEEP",
  keeps: [
    "Legacy & its permanent income bonus",
    "Your Respect level & the turf you control",
    "Your alias, look & wardrobe",
    "The Judge's favor",
  ],
  loseTitle: "YOU LOSE",
  loses: (_cash: string) => [
    "All your cash — dirty and clean",
    "Every hustle, crew and front",
    "Sosa's watches & cars",
    "All heat, payoffs & buffs",
  ],
  cta: "START A NEW OPERATION",
  ctaArmed: (gain: string) => `TAP AGAIN — GAIN ${gain} LEGACY`,
  lockedTitle: "Build up your Net Worth (gold cash) to earn your first Legacy token.",
  perksTitle: "WHAT LEGACY GIVES YOU",
  toastTitle: "A NEW OPERATION RISES",
  toastSub: (gain: string) => `+${gain} Legacy secured`,
  bonusNote: (pct: number, daytonas: number) =>
    `Legacy gain boosted +${pct}%${daytonas > 0 ? ` (Steel Daytona ×${daytonas})` : ""}`,
} as const;

/** Net Worth (lifetime clean) per √-step of Legacy. */
export const LEGACY_DIVISOR = 2_500;

// ---------------------------------------------------------------------------
// Offline earnings & misc UI copy
// ---------------------------------------------------------------------------

export const MISC = {
  offlineTitle: "While you were lying low…",
  offlineSub: "The crew kept the corners moving.",
  offlineCta: "COLLECT THE TAKE",
  portfolio: "THE HUSTLES",
  running: (a: number, b: number) => `${a}/${b} hustles running`,
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
  { id: "laundromat", name: "Sunrise Coin Laundry", emoji: "🧺",
    flavor: "We clean clothes. Mostly clothes. Some paper.",
    district: "docks", price: 600, priceCurrency: "dirty",
    baseThroughput: 26, baseCut: 0.35, cutPerLevel: 0.012, cutFloor: 0.2,
    throughputGrowth: 1.55, upgradeBase: 1_400, upgradeGrowth: 1.85 },
  { id: "barber", name: "Fadeaway Barbershop", emoji: "💈",
    flavor: "Two chairs, one register, zero questions.",
    district: "warsaw", price: 30_000, priceCurrency: "clean",
    baseThroughput: 140, baseCut: 0.32, cutPerLevel: 0.012, cutFloor: 0.18,
    throughputGrowth: 1.55, upgradeBase: 45_000, upgradeGrowth: 1.85 },
  { id: "velvet", name: "Club Velour", emoji: "🪩",
    flavor: "Velvet ropes, bottle service, and a very busy register.",
    district: "downtown", price: 900_000, priceCurrency: "clean",
    baseThroughput: 1_100, baseCut: 0.28, cutPerLevel: 0.01, cutFloor: 0.16,
    throughputGrowth: 1.55, upgradeBase: 1_300_000, upgradeGrowth: 1.85,
    perk: "velvet_income" },
  { id: "hotel", name: "The Grandview Hotel", emoji: "🏨",
    flavor: "Four stars online. Five ledgers in the safe.",
    district: "row", price: 75_000_000, priceCurrency: "clean",
    baseThroughput: 11_000, baseCut: 0.25, cutPerLevel: 0.01, cutFloor: 0.14,
    throughputGrowth: 1.55, upgradeBase: 100_000_000, upgradeGrowth: 1.85 },
  { id: "importexport", name: "Meridian Logistics", emoji: "🚢",
    flavor: "Everything is 'flat-screen TVs.' The manifests are works of art.",
    district: "islands", price: 4_000_000_000, priceCurrency: "clean",
    baseThroughput: 120_000, baseCut: 0.22, cutPerLevel: 0.008, cutFloor: 0.12,
    throughputGrowth: 1.55, upgradeBase: 5_500_000_000, upgradeGrowth: 1.85,
    perk: "less_shipment_heat" },
];

/** Club Velour's own legit take, per level, per second (clean). */
export const VELVET_CLEAN_INCOME_PER_LEVEL = 45;

export const LAUNDER = {
  sectionTitle: "THE FRONTS",
  sectionSub: "Dirty money goes in. Respectable money comes out. Some evaporates.",
  washing: (rate: string) => `washing ${rate}/s`,
  keeps: (pct: number) => `keeps ${pct}%`,
  idle: "register is quiet — no dirty cash to wash",
  buy: "BUY THE DEED",
  upgrade: "EXPAND",
  dirtyLabel: "DIRTY",
  cleanLabel: "CLEAN",
  dirtyHint: "Dirty cash runs the hustles: expansions, crews, payoffs, Sosa.",
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
  { id: "docks", name: "The Terminal", price: 0, respectLevel: 0,
    blurb: "Container cranes, chain-link, and everything falls off a truck eventually.",
    rect: { x: 110, y: 860, w: 580, h: 420 }, tint: "#848b95" },
  { id: "warsaw", name: "O'Block", price: 15_000, respectLevel: 3,
    blurb: "Every window watching, every corner spoken for.",
    rect: { x: 110, y: 390, w: 580, h: 420 }, tint: "#8a9099" },
  { id: "downtown", name: "Downtown", price: 1_500_000, respectLevel: 6,
    blurb: "Glass towers, City Hall — everything here has a price tag.",
    rect: { x: 750, y: 340, w: 540, h: 540 }, tint: "#9199a4" },
  { id: "row", name: "Crestwood Hills", price: 100_000_000, respectLevel: 10,
    blurb: "Old money, new friends. The Judge plays golf at four.",
    rect: { x: 1350, y: 150, w: 540, h: 430 }, tint: "#99a1ad" },
  { id: "islands", name: "The Keys", price: 5_000_000_000, respectLevel: 14,
    blurb: "Past the breakwater, past the law. The empire's blue-water edge.",
    rect: { x: 1400, y: 950, w: 480, h: 360 }, tint: "#7f868f" },
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
  // The Terminal
  { id: "p_still", kind: "racket", ref: 0, district: "docks", x: 220, y: 1010 },
  { id: "p_anchor", kind: "racket", ref: 1, district: "docks", x: 440, y: 1155 },
  { id: "p_gin", kind: "racket", ref: 2, district: "docks", x: 615, y: 1010 },
  { id: "p_smuggle", kind: "racket", ref: 4, district: "docks", x: 590, y: 1230, size: 1.1 },
  { id: "p_laundromat", kind: "front", ref: "laundromat", district: "docks", x: 235, y: 1160 },
  { id: "pr_docks", kind: "precinct", ref: "precinct_docks", district: "docks", x: 425, y: 1010, size: 0.9 },
  // O'Block
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
  // Crestwood Hills
  { id: "p_country", kind: "racket", ref: 11, district: "row", x: 1480, y: 270 },
  { id: "p_railroad", kind: "racket", ref: 14, district: "row", x: 1760, y: 240, size: 1.15 },
  { id: "p_hotel", kind: "front", ref: "hotel", district: "row", x: 1550, y: 450, size: 1.3 },
  { id: "lm_judge", kind: "landmark", ref: "judge", district: "row", x: 1780, y: 430, size: 1.1 },
  { id: "pr_row", kind: "precinct", ref: "precinct_row", district: "row", x: 1650, y: 320, size: 0.9 },
  // The Keys
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
    blurb: "The Judge plays golf at four. Lawyer favors, coming soon." },
  precinct_docks: { name: "1st Precinct", emoji: "🚓",
    blurb: "The desk sergeant enjoys long lunches. Noted." },
  precinct_warsaw: { name: "2nd Precinct", emoji: "🚓",
    blurb: "The captain drives a nicer car than a captain should. Noted." },
  precinct_downtown: { name: "Police Headquarters", emoji: "🚓",
    blurb: "Glass lobby. Everyone watches everyone." },
  precinct_row: { name: "4th Precinct", emoji: "🚓",
    blurb: "Quiet streets. Expensive quiet." },
};

export const MAP_COPY = {
  forSale: "FOR SALE",
  locked: (name: string, respect: number) =>
    `${name} — Reach Respect ${respect}`,
  unlockCta: (price: string) => `BUY THE TURF · ${price}`,
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
  /** Passive heat/sec per hustle unit, scaled up for later hustles. */
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
  bailRate: 0.04, // × Net Worth (lifetime clean)
  bailFloor: 500,
  heatAfterRelease: 30,
  /** Reopen fee: multiple of the hustle's next-unit price (clean). */
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
  investigationSub: "The DEA is building a case…",
  raidToast: "RAID! DEA SEIZES",
  raidToastSub: (name: string) => `${name} taped off — the boss is downtown`,
  dismissToast: "CASE THROWN OUT!",
  dismissSub: "The Judge's favor holds. The file is lost.",
  releaseToast: "FIRST DAY OUT",
  releaseSub: "Heat settles to a simmer. You're a known face now.",
  panelTitle: "THE LAW",
  panelSub: "Heat rises with hustles, shipments and idle dirty cash. Pay it down or lie low.",
  sourcesTitle: "WHY THEY'RE WATCHING",
  srcRackets: "Hustles running",
  srcStockpile: "Dirty cash stockpile",
  srcPayroll: (n: number) => `${n} precinct${n === 1 ? "" : "s"} on payroll`,
  bribeCta: (cost: string) => `GREASE PALMS · ${cost}`,
  bribeDone: "The captain suddenly remembers a fishing trip.",
  payrollOn: (cost: string) => `PAYROLL · ${cost}/min`,
  payrollActive: "CAPTAIN'S ON THE PAYROLL",
  payrollOff: "STOP PAYMENTS",
  prisonTitle: "COUNTY LOCKUP",
  prisonSub: "The crew keeps the fronts washing at half speed. The hustles run without you.",
  prisonWait: "Sit tight",
  prisonBail: (cost: string) => `POST BAIL · ${cost}`,
  prisonAd: "CALL A PRESS CONFERENCE (soon)",
  raidedTag: "RAIDED",
  reopenCta: (cost: string) => `REOPEN · ${cost}`,
  reopenNote: "Legal fees, new locks, a fresh coat of paint — and the block remembers.",
  lawyerTitle: "THE LAW OFFICE",
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
  /** Hustle indices that must be owned (and not raided). */
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
  { id: "still_run", name: "City Run", emoji: "🚚", vehicle: "truck",
    blurb: "Vacuum-sealed packs under pizza boxes, side streets the whole way.",
    requires: [0, 1], fromPlot: "p_still", toPlot: "p_anchor",
    payoutMult: 1, heatMult: 1, travelSeconds: 12 },
  { id: "rum_run", name: "Coast Run", emoji: "🚤", vehicle: "boat",
    blurb: "Twelve miles out, the law ends. The ledger doesn't.",
    requires: [4], fromPlot: "p_smuggle", toPlot: "p_anchor",
    payoutMult: 2.2, heatMult: 1.5, travelSeconds: 16 },
  { id: "harbor_convoy", name: "Container Run", emoji: "🚢", vehicle: "boat",
    blurb: "Three containers of 'flat-screen TVs.' The manifests sing.",
    requires: [13], fromPlot: "p_freight", toPlot: "p_smuggle",
    payoutMult: 5, heatMult: 2.2, travelSeconds: 18 },
];

export const SHIPMENT_SIZES = [
  { id: "small", name: "Light Pack", seconds: 25, heat: 3, floor: 120 },
  { id: "medium", name: "Full Trunk", seconds: 75, heat: 7, floor: 600 },
  { id: "large", name: "The Motherlode", seconds: 200, heat: 12, floor: 2_600 },
] as const;

export const SHIPMENT_COPY = {
  cta: "SHIPMENT",
  panelTitle: "SEND A SHIPMENT",
  panelSub: "Big loads pay big and draw eyes. The cops are watching the roads.",
  confirm: (pay: string, heat: number) => `+${pay} · +${heat} HEAT`,
  departed: "SHIPMENT ROLLING",
  departedSub: (name: string) => `${name} is on the move`,
  arrivedToast: "SHIPMENT LANDS!",
  arrivedSub: (pay: string) => `${pay} in dirty cash hits the count`,
  seizedToast: "SHIPMENT SEIZED!",
  seizedSub: "The raid caught the load on the road.",
  inTransit: (s: number) => `IN TRANSIT · ${s}s`,
  checkpointTitle: "CHECKPOINT AHEAD!",
  checkpointSub: "A cruiser waves the traffic down.",
  detour: (s: number) => `TAKE THE DETOUR · +${s}s, −half heat`,
  barrel: "BLOW THROUGH · +2 heat",
  needRoute: "Open the right hustles to run this route.",
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
  levelUpSub: "New doors open across Eastport",
} as const;

export const LEGACY = {
  label: "Legacy",
  /** Each token: +3% income, −0.1% launder cut (cap 5%), −0.5 release heat. */
  cutPerToken: 0.001,
  cutCap: 0.05,
  releaseHeatPerToken: 0.5,
  releaseHeatFloor: 10,
  perks: (n: number) => [
    `+${(n * 3).toLocaleString()}% money from every hustle`,
    `−${Math.min(5, n * 0.1).toFixed(1)}% lost in the wash`,
    `Come out of jail at ${Math.max(10, 30 - n * 0.5).toFixed(0)} heat instead of 30`,
  ],
} as const;

/** Lawyer perk Respect-level requirements (id → level). */
export const LAWYER_RESPECT: Record<string, number> = {
  retainer: 10,
  bagman: 11,
  silk_glove: 13,
};

// ---------------------------------------------------------------------------
// Von, your right hand — the guide who pops up when something new unlocks,
// so nobody has to guess what to do next. One tip at a time, each shown once.
// ---------------------------------------------------------------------------

export const GUIDE = {
  name: "Von",
  title: "YOUR RIGHT HAND",
  dismiss: "GOT IT",
  show: "TAKE ME THERE",
} as const;

export interface GuideTipDef {
  id: string;
  /** One short bold instruction — what to do, right now. */
  headline: string;
  /** One plain sentence of why. */
  text: string;
  /** Tab the button jumps to. */
  tab?: "map" | "empire" | "dms" | "rebrand" | "profile";
}

// Direct, action-first, for someone who doesn't play games. Headline = the
// verb. Text = the full explanation of the mechanic, taught the moment it
// first matters. Von is the tutorial — every system gets its own tip.
export const GUIDE_TIPS: GuideTipDef[] = [
  { id: "welcome", tab: "empire",
    headline: "Tap the corner spot to make your first dollar.",
    text: "Hit the green MOVE A PACK bar and the meter fills — when it lands, the money's yours. Keep tapping; every pack builds the pile." },
  { id: "first_expand", tab: "empire",
    headline: "Now buy more corners with the BUY button.",
    text: "Every corner you own adds money to each pack you move. Prices climb as you buy — the ×10, ×100 and MAX buttons up top buy in bulk when you're rich enough." },
  { id: "laundromat_ready", tab: "empire",
    headline: "Buy the Coin Laundry at the top.",
    text: "Everything you earn is dirty green cash — cops can smell it. The laundry washes it into clean gold cash for a small cut, and only gold buys property." },
  { id: "first_clean", tab: "empire",
    headline: "That gold number is your real money.",
    text: "Green (dirty) pays for hustles, crew and payoffs. Gold (clean) buys deeds, turf, lawyers and bail. The laundry converts on its own — you just keep earning." },
  { id: "crew_ready", tab: "empire",
    headline: "Hire a Lookout so the corner runs itself.",
    text: "The HIRE button is a one-time fee for crew who move packs for you — no more tapping that hustle, and it keeps earning even while you're away." },
  { id: "front_upgrade_ready", tab: "empire",
    headline: "EXPAND the laundry with gold cash.",
    text: "Every front level washes dirty cash faster and skims a smaller cut. Washing speed is your whole operation's bottleneck — never stop growing it." },
  { id: "milestone_hint", tab: "empire",
    headline: "25 corners — you hit a milestone.",
    text: "At 25, 50, 100, 200+ units a hustle doubles its income and moves packs twice as fast. And when EVERY hustle levels up evenly, the NEWS bar up top doubles everything." },
  { id: "shipment_ready", tab: "map",
    headline: "The city just opened up.",
    text: "Your operation is on the map now. Hit the gold SHIPMENT button there to send a load: pick a route and a size. Bigger loads pay way more dirty cash — and draw way more heat." },
  { id: "shipment_live", tab: "map",
    headline: "Your load is rolling. Watch the road.",
    text: "If a checkpoint pops up, you choose: the detour is slower but cuts the heat in half, blowing through is fast but the cops remember. One load at a time." },
  { id: "fixer_ready", tab: "dms",
    headline: "Sosa's been asking about you.",
    text: "He sells edges, not product: watches make every hustle earn more, cars make them run faster. Pricey — and it all burns on a New Operation. Check your messages." },
  { id: "stockpile_warning", tab: "empire",
    headline: "That green pile is evidence.",
    text: "When dirty cash stacks up faster than the laundry can wash it, heat starts climbing on its own. Buy or EXPAND fronts to raise your washing speed." },
  { id: "heat_warning",
    headline: "Cops are watching — tap the shield up top.",
    text: "Heat rises from hustles, shipments and idle dirty cash. In THE LAW you can grease palms (a one-time bribe) or put a precinct captain on payroll — dirty cash every minute, but all heat builds slower." },
  { id: "investigation_help",
    headline: "You're under investigation — act fast.",
    text: "The DEA is building a case. Push heat back down before the clock runs out — bribe, pause shipments, lie low — or they raid a hustle and the boss does time." },
  { id: "reopen_hint", tab: "empire",
    headline: "The DEA taped off a business. Reopen it.",
    text: "Tap REOPEN and pay the legal fees in gold cash. It comes back one unit smaller — that's the price of getting caught. Keep the heat lower this time." },
  { id: "respect_hint",
    headline: "Respect opens doors.",
    text: "That L badge up top grows from buying hustles, hiring crew and landing shipments. Higher levels unlock new turf on the map — and eventually serious lawyers." },
  { id: "district_ready", tab: "map",
    headline: "You can claim new turf.",
    text: "Tap the glowing district on the map and buy it with gold cash. New turf means new hustles to open, new fronts to wash with, and a bigger operation." },
  { id: "velvet_ready", tab: "map",
    headline: "Club Velour is up for grabs.",
    text: "The best front in Eastport: it washes huge volume AND its bottle service earns clean cash on its own. Grab the deed Downtown before you spend that gold." },
  { id: "prestige_ready", tab: "rebrand",
    headline: "You're rich enough to start over stronger.",
    text: "A New Operation burns your cash, hustles, crew and Sosa's toys — but each Legacy token pays +3% on everything, forever. Turf, Respect and your wardrobe stay." },
];

// ---------------------------------------------------------------------------
// One-time milestone headlines — §6.
// ---------------------------------------------------------------------------

export const MILESTONES: Record<string, { title: string; sub: string; xp: number }> = {
  first_shipment: {
    title: "FIRST LOAD DELIVERED",
    sub: "Somewhere, a hungry city exhales", xp: 50 },
  velvet_open: {
    title: "CLUB VELOUR OPENS ITS DOORS",
    sub: "Velvet ropes! Bass! A line around the block by midnight", xp: 150 },
  first_raid_survived: {
    title: "THE BOSS WALKS FREE",
    sub: "News vans swarm the courthouse steps. The city takes notes", xp: 100 },
  bridge_islands: {
    title: "BRIDGE TO THE KEYS COMPLETE",
    sub: "The empire reaches blue water at last", xp: 250 },
};
