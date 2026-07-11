// Economy math unit tests — laundering, heat, bail/bribe scaling.
import { describe, it, expect, beforeEach, vi, afterEach } from "vitest";
import * as F from "../formulas";
import { Game } from "../game";
import { newGame } from "../state";
import { FRONTS, HEAT_TUNING, LEGACY_DIVISOR } from "../../theme/content";

// Node has no localStorage — a throwaway shim keeps autosaves harmless.
const store = new Map<string, string>();
beforeEach(() => {
  store.clear();
  vi.stubGlobal("localStorage", {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
    removeItem: (k: string) => void store.delete(k),
  });
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-06-01T12:00:00Z"));
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

function fresh(): Game {
  return new Game(newGame());
}

describe("formulas", () => {
  it("unit costs grow geometrically", () => {
    expect(F.unitCost(4, 0)).toBe(4);
    expect(F.unitCost(4, 1)).toBeCloseTo(4 * 1.14);
    expect(F.bulkCost(4, 0, 3)).toBeCloseTo(4 + 4 * 1.14 + 4 * 1.14 ** 2);
  });

  it("milestone tiers double income and halve cycles", () => {
    expect(F.milestoneTier(24)).toBe(0);
    expect(F.milestoneTier(25)).toBe(1);
    expect(F.milestoneTier(400)).toBe(6);
    expect(F.incomeMultiplier(3)).toBe(8);
    expect(F.cycleTime(8, 2)).toBe(2);
  });

  it("legacy gain converts the fortune with the configured divisor", () => {
    expect(F.cloutGain(LEGACY_DIVISOR * 25, 0, 0, LEGACY_DIVISOR)).toBe(5);
    expect(F.cloutGain(LEGACY_DIVISOR * 25, 3, 0, LEGACY_DIVISOR)).toBe(2);
    expect(F.cloutGain(0, 0, 0, LEGACY_DIVISOR)).toBe(0);
  });
});

describe("laundering", () => {
  it("washes dirty into clean at the front's throughput minus the cut", () => {
    const g = fresh();
    g.state.cash = 10_000;
    g.state.fronts.laundromat = 1;
    const def = FRONTS[0];
    const thr = g.frontThroughput(def);
    const keep = 1 - g.frontCut(def);
    g.debugTick(1);
    // one second: thr washed, thr*keep landed clean
    expect(g.state.cash).toBeCloseTo(10_000 - thr, 1);
    expect(g.state.cleanCash).toBeCloseTo(thr * keep, 1);
  });

  it("upgrades raise throughput and shrink the cut toward its floor", () => {
    const g = fresh();
    const def = FRONTS[0];
    g.state.fronts.laundromat = 1;
    const thr1 = g.frontThroughput(def);
    const cut1 = g.frontCut(def);
    g.state.fronts.laundromat = 10;
    expect(g.frontThroughput(def)).toBeGreaterThan(thr1 * 10);
    expect(g.frontCut(def)).toBeLessThan(cut1);
    g.state.fronts.laundromat = 99;
    expect(g.frontCut(def)).toBeGreaterThanOrEqual(def.cutFloor - 1e-9);
  });

  it("never washes more dirty cash than exists", () => {
    const g = fresh();
    g.state.cash = 5;
    g.state.fronts.laundromat = 8; // way more capacity than cash
    g.debugTick(1);
    expect(g.state.cash).toBeGreaterThanOrEqual(0);
    expect(g.state.cleanCash).toBeLessThanOrEqual(5);
  });
});

describe("heat", () => {
  it("accumulates from rackets and stockpiles, dampened by payroll", () => {
    const g = fresh();
    g.state.hustles[0].unitsOwned = 100;
    const base = g.heatRatePerSec;
    expect(base).toBeGreaterThan(0);

    g.state.cash = g.stockpileThreshold * 3; // big dirty pile
    expect(g.heatRatePerSec).toBeGreaterThan(base);

    g.state.payrolls = ["precinct_docks", "precinct_warsaw"];
    const damped = g.heatRatePerSec;
    g.state.payrolls = [];
    expect(damped).toBeLessThan(g.heatRatePerSec);
  });

  it("bribes cost more at higher heat and relieve more", () => {
    const g = fresh();
    g.state.heat = 10;
    const cheap = g.bribeCost;
    g.state.heat = 90;
    expect(g.bribeCost).toBeGreaterThan(cheap * 5);
    expect(g.bribeRelief).toBeGreaterThan(HEAT_TUNING.bribeRelief(10));
  });

  it("bail scales with the family fortune and lawyer perk halves it", () => {
    const g = fresh();
    g.state.lifetimeClean = 1_000_000;
    const bail = g.bailCost;
    expect(bail).toBeCloseTo(1_000_000 * HEAT_TUNING.bailRate);
    g.state.lawyerPerks = ["bagman"];
    expect(g.bailCost).toBeCloseTo(bail / 2);
  });

  it("raid boards the top earner, jails the boss, reopening costs a tier", () => {
    const g = fresh();
    g.state.hustles[0].unitsOwned = 60; // tier 2 earner
    g.state.hustles[1].unitsOwned = 5;
    g.state.heat = 70;
    g.debugTick(0.1); // opens the investigation
    expect(g.underInvestigation).toBe(true);

    g.state.heat = 100; // force the case to land
    g.debugTick(0.1);
    expect(g.inPrison).toBe(true);
    expect(g.isRaided(0)).toBe(true);

    // bail out
    g.state.cleanCash = g.bailCost + 1;
    expect(g.payBail()).toBe(true);
    expect(g.inPrison).toBe(false);
    expect(g.state.heat).toBe(HEAT_TUNING.heatAfterRelease);

    // reopen: one milestone tier down (60 → 49)
    g.state.cleanCash = g.reopenCost(0) + 1;
    expect(g.reopenHustle(0)).toBe(true);
    expect(g.isRaided(0)).toBe(false);
    expect(g.state.hustles[0].unitsOwned).toBe(49);
  });
});

describe("save integrity", () => {
  it("round-trips mid-prison state through the save layer", async () => {
    const g = fresh();
    g.state.hustles[0].unitsOwned = 30;
    g.state.heat = 100;
    g.debugTick(0.1); // investigation
    g.state.investigationEndsAt = Date.now() - 1;
    g.debugTick(0.1); // raid → prison
    expect(g.inPrison).toBe(true);

    // force an autosave then reload
    for (let i = 0; i < 51; i++) g.debugTick(0.1);
    const { loadState } = await import("../state");
    const loaded = loadState();
    expect(loaded).not.toBeNull();
    expect(loaded!.prisonUntil).toBe(g.state.prisonUntil);
    expect(loaded!.raidedHustles).toEqual(g.state.raidedHustles);
    expect(loaded!.saveVersion).toBe(2);
  });
});
