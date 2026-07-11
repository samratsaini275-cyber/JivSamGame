// Deterministic fast-forward sim: a greedy bot plays 15 minutes of a fresh
// session so balance can be checked without playing in real time.
// Targets (§2/§8): laundering bottleneck ~8–10 min, first investigation ~12 min.
import { describe, it, expect, beforeEach, vi, afterEach } from "vitest";
import { Game } from "../game";
import { newGame } from "../state";
import { FRONTS } from "../../theme/content";

const store = new Map<string, string>();
beforeEach(() => {
  store.clear();
  vi.stubGlobal("localStorage", {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
    removeItem: (k: string) => void store.delete(k),
  });
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-06-01T20:00:00Z"));
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

/** One greedy player step: keep stills bubbling, expand, wash, ship. */
function botStep(g: Game): void {
  const st = g.state;

  // Keep manual rackets posting.
  for (let i = 0; i < 3; i++) {
    const s = st.hustles[i];
    if (s.unitsOwned > 0 && !s.ghostwriterHired && !s.cycleRunning) g.post(i);
  }

  // Laundromat first — the tutorial beat.
  if (g.frontLevel("laundromat") === 0 && g.canAffordFront(FRONTS[0])) {
    g.buyFront(FRONTS[0]);
  }

  // Hire crews when affordable (dirty).
  for (let i = 0; i < 3; i++) {
    const s = st.hustles[i];
    if (s.unitsOwned > 0 && !s.ghostwriterHired) g.hireGhostwriter(i);
  }

  // Expand the open rackets greedily, keeping a small cash buffer.
  for (const i of [0, 1, 2]) {
    if (!g.hustleAvailable(i) || g.isRaided(i)) continue;
    while (st.cash > g.buyCost(i) * 1.5 && st.hustles[i].unitsOwned < 150) {
      g.buy(i);
    }
  }

  // Upgrade the wash when clean allows.
  const laundromat = FRONTS[0];
  if (g.frontLevel("laundromat") > 0 &&
      st.cleanCash > g.frontUpgradeCost(laundromat) * 1.2 &&
      g.frontLevel("laundromat") < 12) {
    g.upgradeFront(laundromat);
  }

  // Run shipments whenever the road is open (the heat driver).
  if (!st.activeShipment && !g.inPrison) {
    g.startShipment("still_run", "small");
  }
  // Bot always barrels through checkpoints (worst-case heat).
  if (st.activeShipment && !st.activeShipment.checkpointResolved &&
      Date.now() >= st.activeShipment.checkpointAt && st.activeShipment.checkpointAt > 0) {
    g.resolveCheckpoint(false);
  }
}

describe("15-minute fresh-session sim", () => {
  it("hits the laundering bottleneck ~8-10 min and investigation by ~13 min", () => {
    vi.spyOn(Math, "random").mockReturnValue(0.3); // deterministic checkpoints/lambo
    const g = new Game(newGame());
    g.createPersona("simboss", "hoodie", "gold");

    const STEP = 0.5; // seconds
    let bottleneckAt: number | null = null;
    let investigationAt: number | null = null;
    let raidAt: number | null = null;

    for (let t = 0; t <= 15 * 60; t += STEP) {
      vi.setSystemTime(Date.now() + STEP * 1000);
      botStep(g);
      g.debugTick(STEP);

      if (bottleneckAt === null &&
          g.frontLevel("laundromat") > 0 &&
          g.state.cash > g.stockpileThreshold) {
        bottleneckAt = t;
      }
      if (investigationAt === null && g.underInvestigation) investigationAt = t;
      if (raidAt === null && g.inPrison) raidAt = t;
    }

    // Laundering falls behind production well inside the session.
    expect(bottleneckAt).not.toBeNull();
    expect(bottleneckAt!).toBeGreaterThan(2 * 60);
    expect(bottleneckAt!).toBeLessThan(11 * 60);

    // The badge comes knocking before the session ends.
    expect(investigationAt).not.toBeNull();
    expect(investigationAt!).toBeLessThan(13.5 * 60);
    expect(investigationAt!).toBeGreaterThan(5 * 60);

    // And the whole raid → prison pipeline actually fires under pressure.
    expect(raidAt).not.toBeNull();
  });

  it("prison halves laundering and blocks purchases until release", () => {
    const g = new Game(newGame());
    g.state.hustles[0].unitsOwned = 30;
    g.state.fronts.laundromat = 3;
    g.state.cash = 1e6;

    const freeRate = FRONTS[0].baseThroughput * Math.pow(FRONTS[0].throughputGrowth, 2);
    g.state.heat = 100;
    g.debugTick(0.1); // investigation
    g.state.investigationEndsAt = Date.now() - 1;
    g.debugTick(0.1); // raid
    expect(g.inPrison).toBe(true);

    const before = g.state.cash;
    g.debugTick(1);
    const washed = before - g.state.cash;
    expect(washed).toBeCloseTo(freeRate * 0.5, 0);

    expect(g.buyFront(FRONTS[1])).toBe(false);
    g.buy(0); // silently refused
    expect(g.state.hustles[0].unitsOwned).toBe(30);

    // Serve the sentence.
    vi.setSystemTime((g.state.prisonUntil ?? 0) + 1000);
    g.debugTick(0.1);
    expect(g.inPrison).toBe(false);
  });
});
