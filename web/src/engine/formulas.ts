// Pure game math — direct port of Engine/Formulas.swift. Deterministic.

export const COST_GROWTH = 1.14;
export const MILESTONE_THRESHOLDS = [25, 50, 100, 200, 300, 400];
export const CLOUT_DIVISOR = 25_000;
export const CLOUT_BONUS_PER_POINT = 0.02;

export const LAMBO_VIRAL_CHANCE = 0.25;
export const LAMBO_VIRAL_DURATION_MS = 60_000;
export const MILLE_BUFF_DURATION_MS = 10_000;
export const DAYTONA_GAIN_RATE_PER_PURCHASE = 0.02;
export const GRAIL_REBRAND_BONUS_PER_ITEM = 0.005;

export function unitCost(base: number, owned: number): number {
  return base * Math.pow(COST_GROWTH, owned);
}

export function bulkCost(base: number, owned: number, count: number): number {
  if (count <= 0) return 0;
  const r = COST_GROWTH;
  return (unitCost(base, owned) * (Math.pow(r, count) - 1)) / (r - 1);
}

export function maxAffordable(base: number, owned: number, cash: number): number {
  const first = unitCost(base, owned);
  if (cash < first) return 0;
  const r = COST_GROWTH;
  const n = Math.floor(Math.log((cash * (r - 1)) / first + 1) / Math.log(r));
  if (bulkCost(base, owned, n + 1) <= cash) return n + 1;
  if (n > 0 && bulkCost(base, owned, n) > cash) return n - 1;
  return n;
}

export function milestoneTier(units: number): number {
  return MILESTONE_THRESHOLDS.filter((t) => units >= t).length;
}

export function nextThreshold(units: number): number | null {
  return MILESTONE_THRESHOLDS.find((t) => units < t) ?? null;
}

export function incomeMultiplier(tier: number): number {
  return Math.pow(2, tier);
}

export function cycleTime(base: number, tier: number): number {
  return base / Math.pow(2, tier);
}

/// The account "goes viral" at the tier every hustle has reached.
export function viralTier(unitCounts: number[]): number {
  return Math.min(...unitCounts.map(milestoneTier));
}

export function cloutMultiplier(clout: number): number {
  return 1 + CLOUT_BONUS_PER_POINT * clout;
}

export function cloutGain(lifetimeCash: number, currentClout: number, gainRateBonus = 0): number {
  return Math.max(
    0,
    Math.floor(Math.sqrt(lifetimeCash / CLOUT_DIVISOR) * (1 + gainRateBonus) + 1e-9) - currentClout,
  );
}

export function wristIncomeMultiplier(itemID: string | null, hustleTier: number): number {
  switch (itemID) {
    case "fauxlex": return 1.05;
    case "tagheuer": return hustleTier >= 1 ? 1.15 : 1;
    default: return 1;
  }
}

export function garageCycleMultiplier(itemID: string | null, hustleTier: number): number {
  switch (itemID) {
    case "civic": return 0.95;
    case "charger": return hustleTier >= 1 ? 0.9 : 1;
    default: return 1;
  }
}
