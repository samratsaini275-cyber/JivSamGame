// Static game content — port of Model/Hustle.swift, RexItem.swift, Persona.swift.

export interface HustleDef {
  id: number;
  name: string;
  flavor: string;
  /** PNG in /public/images — the original 8 have art. */
  image?: string;
  /** Emoji tile fallback for hustles without art. */
  emoji?: string;
  baseCost: number;
  baseIncome: number;
  baseCycle: number;
  ghostwriterName: string;
  ghostwriterCost: number;
}

export const HUSTLES: HustleDef[] = [
  { id: 0, name: "Bootleg Tees", flavor: "Heat-pressed in the garage. The logo is “inspired by.”",
    image: "hustle_0_luxury", baseCost: 4, baseIncome: 1, baseCycle: 1,
    ghostwriterName: "Print Plug", ghostwriterCost: 1_000 },
  { id: 1, name: "Sneaker Resells", flavor: "Buy retail, flip triple. Condolences to people with feet.",
    image: "hustle_1_luxury", baseCost: 60, baseIncome: 15, baseCycle: 3,
    ghostwriterName: "Sniper Bot", ghostwriterCost: 15_000 },
  { id: 2, name: "Custom Hoodies", flavor: "Cut-and-sew, “limited” runs. Limited by the sewing machine.",
    image: "hustle_2_luxury", baseCost: 720, baseIncome: 100, baseCycle: 4,
    ghostwriterName: "Production Manager", ghostwriterCost: 100_000 },
  { id: 3, name: "Hyped Drops", flavor: "Artificial scarcity as a service. Timer says 00:59.",
    image: "hustle_3_luxury", baseCost: 8_640, baseIncome: 520, baseCycle: 5,
    ghostwriterName: "Drop Coordinator", ghostwriterCost: 500_000 },
  { id: 4, name: "Influencer Collabs", flavor: "Their audience, your logo, everyone's cut.",
    image: "hustle_4", baseCost: 103_680, baseIncome: 3_600, baseCycle: 6,
    ghostwriterName: "Talent Agent", ghostwriterCost: 1_200_000 },
  { id: 5, name: "Pop-Up Shops", flavor: "The line around the block IS the product.",
    image: "hustle_5", baseCost: 1_240_000, baseIncome: 24_000, baseCycle: 8,
    ghostwriterName: "Store Manager", ghostwriterCost: 10_000_000 },
  { id: 6, name: "Flagship Store", flavor: "Retail as theater. The concrete floor cost six figures.",
    image: "hustle_6", baseCost: 14_900_000, baseIncome: 180_000, baseCycle: 10,
    ghostwriterName: "Creative Director", ghostwriterCost: 120_000_000 },
  { id: 7, name: "Fashion Week Line", flavor: "The bootleg goes couture. Critics call it “a journey.”",
    image: "hustle_7", baseCost: 180_000_000, baseIncome: 1_400_000, baseCycle: 15,
    ghostwriterName: "Atelier Director", ghostwriterCost: 1_000_000_000 },
  // Late game: paybacks stretch from hours into days — the empire takes real time.
  { id: 8, name: "Global E-Comm Empire", flavor: "One warehouse, seventeen shell brands, same hoodie.",
    emoji: "📦", baseCost: 550_000_000, baseIncome: 3_200_000, baseCycle: 20,
    ghostwriterName: "Fulfillment AI", ghostwriterCost: 5_000_000_000 },
  { id: 9, name: "Celebrity Fragrance", flavor: "Smells like ambition and a licensing dispute.",
    emoji: "🌸", baseCost: 1_800_000_000, baseIncome: 8_000_000, baseCycle: 30,
    ghostwriterName: "Perfumer in Residence", ghostwriterCost: 15_000_000_000 },
  { id: 10, name: "Streaming Reality Show", flavor: "Season 2 is just the lawsuits from Season 1.",
    emoji: "🎬", baseCost: 6_000_000_000, baseIncome: 20_000_000, baseCycle: 45,
    ghostwriterName: "Showrunner", ghostwriterCost: 50_000_000_000 },
  { id: 11, name: "Fashion House Buyout", flavor: "You bought the maison that sued you. Twice.",
    emoji: "🏛️", baseCost: 20_000_000_000, baseIncome: 52_000_000, baseCycle: 70,
    ghostwriterName: "Heritage Director", ghostwriterCost: 160_000_000_000 },
  { id: 12, name: "Sneaker Mega-Factory", flavor: "Robots gluing soles 24/7. The drops are still “limited.”",
    emoji: "🏭", baseCost: 65_000_000_000, baseIncome: 130_000_000, baseCycle: 110,
    ghostwriterName: "Automation Czar", ghostwriterCost: 500_000_000_000 },
  { id: 13, name: "Metaverse Flagship", flavor: "Digital hoodies, physical prices, imaginary foot traffic.",
    emoji: "🕶️", baseCost: 210_000_000_000, baseIncome: 330_000_000, baseCycle: 170,
    ghostwriterName: "Metaverse Architect", ghostwriterCost: 1_600_000_000_000 },
  { id: 14, name: "Fashion Conglomerate", flavor: "You are now the umbrella corporation your heroes sold out to.",
    emoji: "🌐", baseCost: 600_000_000_000, baseIncome: 800_000_000, baseCycle: 260,
    ghostwriterName: "Chief Empire Officer", ghostwriterCost: 5_000_000_000_000 },
  { id: 15, name: "Orbital Runway Show", flavor: "Fashion Week, but the venue is low Earth orbit.",
    emoji: "🚀", baseCost: 1_200_000_000_000, baseIncome: 1_600_000_000, baseCycle: 400,
    ghostwriterName: "Mission Control Stylist", ghostwriterCost: 12_000_000_000_000 },
];

export const TIER_NAMES = [
  "No Buzz", "Local Buzz", "Sold-Out Drop", "Cult Following",
  "Celebrity Co-sign", "Global Hype", "Icon Status",
];

export function tierName(tier: number): string {
  return TIER_NAMES[Math.min(tier, TIER_NAMES.length - 1)];
}

// MARK: Rex Calloway's flex economy

export type ItemSlot = "wrist" | "garage";

export interface RexItemDef {
  id: string;
  slot: ItemSlot;
  tier: number;
  name: string;
  blurb: string;
  cost: number;
  boostText: string;
  emoji: string;
}

export const REX_ITEMS: RexItemDef[] = [
  { id: "fauxlex", slot: "wrist", tier: 1, name: "Fauxlex Datejust",
    blurb: "Ticks audibly. Real ones sweep.", cost: 500,
    boostText: "+5% income, all Hustles", emoji: "⌚" },
  { id: "tagheuer", slot: "wrist", tier: 2, name: "Actual Tag Heuer",
    blurb: "Genuine. The receipt is the fake part.", cost: 12_000,
    boostText: "+15% income, verified Hustles (Tier 1+)", emoji: "⏱️" },
  { id: "daytona", slot: "wrist", tier: 3, name: "Vintage Daytona",
    blurb: "The flex is now load-bearing.", cost: 400_000,
    boostText: "+2% Clout gain rate — permanent, survives Rebrand", emoji: "🕛" },
  { id: "mille", slot: "wrist", tier: 4, name: "“Richard Mille”",
    blurb: "Customs won't confirm it's real. Neither will Richard.", cost: 18_000_000,
    boostText: "×2 income for 10s whenever you buy a Hustle unit", emoji: "💎" },
  { id: "civic", slot: "garage", tier: 1, name: "Leased Civic (wrapped)",
    blurb: "The wrap costs more per month than the lease.", cost: 1_200,
    boostText: "−5% cycle time, all Hustles", emoji: "🚗" },
  { id: "charger", slot: "garage", tier: 2, name: "Rented Charger",
    blurb: "Returned every Sunday night, photographed daily.", cost: 30_000,
    boostText: "−10% cycle time, verified Hustles (Tier 1+)", emoji: "🏎️" },
  { id: "lambo", slot: "garage", tier: 3, name: "Borrowed Lambo",
    blurb: "1-day rental, re-rented daily. The math is not mathing.", cost: 900_000,
    boostText: "25% chance a milestone triggers an early Viral Moment (×2, 60s)", emoji: "🚛" },
  { id: "bugatti", slot: "garage", tier: 4, name: "Actual Bugatti",
    blurb: "Owned outright. The one real asset. Do not ask about the financing.", cost: 40_000_000,
    boostText: "Your lowest-owned Hustle cycles at your best milestone tier", emoji: "🏁" },
];

export const REX_TIER_NAMES = ["", "Replica", "Genuine", "Grail", "Unreal"];

export function rexItemByID(id: string | null): RexItemDef | null {
  if (!id) return null;
  return REX_ITEMS.find((i) => i.id === id) ?? null;
}

export function rexItemsForSlot(slot: ItemSlot): RexItemDef[] {
  return REX_ITEMS.filter((i) => i.slot === slot).sort((a, b) => a.tier - b.tier);
}

export const REX = {
  unlockMoneyTier: 2,
  greeting: "Yo. Been watching the brand. Put me on and I put YOU on. That's just math.",
  purchaseBarks: [
    "This isn't a purchase. This is a statement.",
    "Receipts are for people who plan on being asked.",
    "We don't buy things. We acquire narratives.",
    "Grail secured. The fit is now historically significant.",
  ],
  downgradeBark: "The market didn't understand my vision.",
  brokeBark: "Manifest harder.",
  idleCarBarks: [
    "I don't drive to work. I drive to be seen not working.",
    "Mileage cap? Kings don't read contracts.",
  ],
  idleWatchBarks: [
    "Time is money. That's why I wear it.",
    "It loses four minutes a day. So do I.",
  ],
  idleBarks: [
    "Rise and grind. Mostly rise.",
    "My morning routine is 45 minutes of photos of my morning routine.",
  ],
  tier4Bark: "The hangar is rented. The altitude is real.",
};

export function rexIdleBark(wrist: RexItemDef | null, garage: RexItemDef | null): string {
  const bestTier = Math.max(wrist?.tier ?? 0, garage?.tier ?? 0);
  if (bestTier >= 4) return REX.tier4Bark;
  if (garage) return pick(REX.idleCarBarks);
  if (wrist) return pick(REX.idleWatchBarks);
  return pick(REX.idleBarks);
}

export function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

// MARK: Persona (cosmetic; survives Rebrand)

export type PersonaSlot = "Clothes" | "Jewelry" | "Watch";

export interface PersonaItemDef {
  id: string;
  slot: PersonaSlot;
  tier: number;
  name: string;
  cost: number;
  emoji: string;
}

export const PERSONA_TIER_NAMES = ["", "Low", "Mid", "High", "Grail"];

export const PERSONA_ITEMS: PersonaItemDef[] = [
  { id: "thrifted", slot: "Clothes", tier: 1, name: "Thrifted “Aesthetic” Fit", cost: 250, emoji: "🧥" },
  { id: "streetdrop", slot: "Clothes", tier: 2, name: "Streetwear Drop", cost: 5_000, emoji: "👕" },
  { id: "designer", slot: "Clothes", tier: 3, name: "Designer Fit", cost: 150_000, emoji: "🧣" },
  { id: "couture", slot: "Clothes", tier: 4, name: "Custom Couture, One-of-One", cost: 8_000_000, emoji: "🤵" },
  { id: "fakechain", slot: "Jewelry", tier: 1, name: "Fake Gold Chain", cost: 350, emoji: "📿" },
  { id: "realchain", slot: "Jewelry", tier: 2, name: "Real Gold Chain", cost: 8_000, emoji: "⛓️" },
  { id: "grill", slot: "Jewelry", tier: 3, name: "Diamond Grill", cost: 250_000, emoji: "😬" },
  { id: "iced", slot: "Jewelry", tier: 4, name: "Iced-Out Everything", cost: 12_000_000, emoji: "❄️" },
  { id: "p_fauxlex", slot: "Watch", tier: 1, name: "Fauxlex", cost: 500, emoji: "⌚" },
  { id: "p_tagheuer", slot: "Watch", tier: 2, name: "Actual Tag Heuer", cost: 12_000, emoji: "⏱️" },
  { id: "p_daytona", slot: "Watch", tier: 3, name: "Vintage Daytona", cost: 400_000, emoji: "🕛" },
  { id: "p_mille", slot: "Watch", tier: 4, name: "Unconfirmed “Richard Mille”", cost: 18_000_000, emoji: "💎" },
];

export const PERSONA_SLOTS: PersonaSlot[] = ["Clothes", "Jewelry", "Watch"];

export function personaItemByID(id: string | null | undefined): PersonaItemDef | null {
  if (!id) return null;
  return PERSONA_ITEMS.find((i) => i.id === id) ?? null;
}

export function personaItemsForSlot(slot: PersonaSlot): PersonaItemDef[] {
  return PERSONA_ITEMS.filter((i) => i.slot === slot).sort((a, b) => a.tier - b.tier);
}

export interface BaseLookDef {
  id: string;
  name: string;
  image: string;
}

export const BASE_LOOKS: BaseLookDef[] = [
  { id: "hoodie", name: "Hoodie & Hat", image: "look_hoodie" },
  { id: "bizcaz", name: "Business Casual", image: "look_bizcaz" },
  { id: "street", name: "Streetwear", image: "look_street" },
  { id: "gym", name: "Gym Mirror", image: "look_gym" },
];

export function baseLookByID(id: string): BaseLookDef {
  return BASE_LOOKS.find((l) => l.id === id) ?? BASE_LOOKS[0];
}

// MARK: Colorways (brand accent — tints the whole UI)

export interface ColorwayDef {
  id: string;
  name: string;
  accent: string;
  accentDeep: string;
}

export const COLORWAYS: ColorwayDef[] = [
  { id: "gold", name: "24K", accent: "#ffcc5c", accentDeep: "#a8641c" },
  { id: "volt", name: "Emerald", accent: "#6bf2a6", accentDeep: "#0f7047" },
  { id: "ice", name: "Platinum", accent: "#ade6ff", accentDeep: "#337ab3" },
  { id: "crimson", name: "Bordeaux", accent: "#f05463", accentDeep: "#6b0a1a" },
  { id: "amethyst", name: "Violet", accent: "#ba85ff", accentDeep: "#4f268c" },
];

export function colorwayByID(id: string): ColorwayDef {
  return COLORWAYS.find((c) => c.id === id) ?? COLORWAYS[0];
}
