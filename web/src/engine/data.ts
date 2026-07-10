// Static game data. STATS AND IDS ARE LOAD-BEARING (save compat + tuned
// economy curve) — display strings all come from ../theme/content.
import {
  BIZ, FIXER, FIXER_ITEMS, BOSS, COLORWAYS as THEME_COLORWAYS,
  TIER_NAMES as THEME_TIERS, tierName as themeTierName, ColorwayDef,
} from "../theme/content";

export interface HustleDef {
  id: number;
  name: string;
  flavor: string;
  emoji: string;
  baseCost: number;
  baseIncome: number;
  baseCycle: number;
  ghostwriterName: string; // internal name kept for save compat; displays as "crew"
  ghostwriterCost: number;
}

/** Tuned stat rows — index-mapped to theme content. Do not reorder. */
const STATS: [number, number, number, number][] = [
  // baseCost, baseIncome, baseCycle, crewCost
  [4, 1, 1, 1_000],
  [60, 15, 3, 15_000],
  [720, 100, 4, 100_000],
  [8_640, 520, 5, 500_000],
  [103_680, 3_600, 6, 1_200_000],
  [1_240_000, 24_000, 8, 10_000_000],
  [14_900_000, 180_000, 10, 120_000_000],
  [180_000_000, 1_400_000, 15, 1_000_000_000],
  [550_000_000, 3_200_000, 20, 5_000_000_000],
  [1_800_000_000, 8_000_000, 30, 15_000_000_000],
  [6_000_000_000, 20_000_000, 45, 50_000_000_000],
  [20_000_000_000, 52_000_000, 70, 160_000_000_000],
  [65_000_000_000, 130_000_000, 110, 500_000_000_000],
  [210_000_000_000, 330_000_000, 170, 1_600_000_000_000],
  [600_000_000_000, 800_000_000, 260, 5_000_000_000_000],
  [1_200_000_000_000, 1_600_000_000, 400, 12_000_000_000_000],
];

export const HUSTLES: HustleDef[] = STATS.map(([cost, income, cycle, crewCost], i) => ({
  id: i,
  name: BIZ[i].name,
  flavor: BIZ[i].flavor,
  emoji: BIZ[i].emoji,
  baseCost: cost,
  baseIncome: income,
  baseCycle: cycle,
  ghostwriterName: BIZ[i].crew,
  ghostwriterCost: crewCost,
}));

export const TIER_NAMES = THEME_TIERS;
export const tierName = themeTierName;

// MARK: The Fixer's flex economy (internal names Rex* kept for save compat)

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

/** id, slot, tier, cost — ids/costs persisted; display from theme. */
const FIXER_STATS: [string, ItemSlot, number, number][] = [
  ["fauxlex", "wrist", 1, 500],
  ["tagheuer", "wrist", 2, 12_000],
  ["daytona", "wrist", 3, 400_000],
  ["mille", "wrist", 4, 18_000_000],
  ["civic", "garage", 1, 1_200],
  ["charger", "garage", 2, 30_000],
  ["lambo", "garage", 3, 900_000],
  ["bugatti", "garage", 4, 40_000_000],
];

export const REX_ITEMS: RexItemDef[] = FIXER_STATS.map(([id, slot, tier, cost]) => ({
  id, slot, tier, cost,
  name: FIXER_ITEMS[id].name,
  blurb: FIXER_ITEMS[id].blurb,
  boostText: FIXER_ITEMS[id].boost,
  emoji: FIXER_ITEMS[id].emoji,
}));

export const REX_TIER_NAMES = FIXER.tierNames as readonly string[];

export function rexItemByID(id: string | null): RexItemDef | null {
  if (!id) return null;
  return REX_ITEMS.find((i) => i.id === id) ?? null;
}

export function rexItemsForSlot(slot: ItemSlot): RexItemDef[] {
  return REX_ITEMS.filter((i) => i.slot === slot).sort((a, b) => a.tier - b.tier);
}

export const REX = {
  unlockMoneyTier: 2,
  greeting: FIXER.greeting,
  purchaseBarks: [...FIXER.purchaseBarks],
  downgradeBark: FIXER.downgradeBark,
  brokeBark: FIXER.brokeBark,
  idleCarBarks: [...FIXER.idleCarBarks],
  idleWatchBarks: [...FIXER.idleWatchBarks],
  idleBarks: [...FIXER.idleBarks],
  tier4Bark: FIXER.tier4Bark,
};

export function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

// MARK: The Boss's wardrobe (persona — ids persisted)

export type PersonaSlot = "Clothes" | "Jewelry" | "Watch";

export interface PersonaItemDef {
  id: string;
  slot: PersonaSlot;
  tier: number;
  name: string;
  cost: number;
  emoji: string;
}

const WARDROBE_STATS: [string, PersonaSlot, number, number][] = [
  ["thrifted", "Clothes", 1, 250],
  ["streetdrop", "Clothes", 2, 5_000],
  ["designer", "Clothes", 3, 150_000],
  ["couture", "Clothes", 4, 8_000_000],
  ["fakechain", "Jewelry", 1, 350],
  ["realchain", "Jewelry", 2, 8_000],
  ["grill", "Jewelry", 3, 250_000],
  ["iced", "Jewelry", 4, 12_000_000],
  ["p_fauxlex", "Watch", 1, 500],
  ["p_tagheuer", "Watch", 2, 12_000],
  ["p_daytona", "Watch", 3, 400_000],
  ["p_mille", "Watch", 4, 18_000_000],
];

export const PERSONA_TIER_NAMES = BOSS.tierNames as readonly string[];

export const PERSONA_ITEMS: PersonaItemDef[] = WARDROBE_STATS.map(([id, slot, tier, cost]) => ({
  id, slot, tier, cost,
  name: BOSS.items[id].name,
  emoji: BOSS.items[id].emoji,
}));

export const PERSONA_SLOTS: PersonaSlot[] = ["Clothes", "Jewelry", "Watch"];

export function personaItemByID(id: string | null | undefined): PersonaItemDef | null {
  if (!id) return null;
  return PERSONA_ITEMS.find((i) => i.id === id) ?? null;
}

export function personaItemsForSlot(slot: PersonaSlot): PersonaItemDef[] {
  return PERSONA_ITEMS.filter((i) => i.slot === slot).sort((a, b) => a.tier - b.tier);
}

export interface BaseLookDef {
  id: string; // persisted
  name: string;
  emoji: string;
}

export const BASE_LOOKS: BaseLookDef[] = ["hoodie", "bizcaz", "street", "gym"].map((id) => ({
  id,
  name: BOSS.looks[id].name,
  emoji: BOSS.looks[id].emoji,
}));

export function baseLookByID(id: string): BaseLookDef {
  return BASE_LOOKS.find((l) => l.id === id) ?? BASE_LOOKS[0];
}

// MARK: Colorways (accent — ids persisted)

export type { ColorwayDef };
export const COLORWAYS = THEME_COLORWAYS;

export function colorwayByID(id: string): ColorwayDef {
  return COLORWAYS.find((c) => c.id === id) ?? COLORWAYS[0];
}
