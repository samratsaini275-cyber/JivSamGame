// Casino ↔ economy integration: unlock, wager reservation, idempotent
// settlement, reload recovery, prestige, and save migration.
import { describe, it, expect, beforeEach, vi, afterEach } from "vitest";
import { Game, CASINO_COST } from "../game";
import { newGame, loadState, saveState } from "../state";

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

describe("unlock", () => {
  it("cannot unlock below $1B and does not deduct", () => {
    const g = fresh();
    g.state.cleanCash = CASINO_COST - 1;
    expect(g.canUnlockCasino).toBe(false);
    expect(g.unlockCasino()).toBe(false);
    expect(g.casinoUnlocked).toBe(false);
    expect(g.state.cleanCash).toBe(CASINO_COST - 1);
  });

  it("unlocks at exactly $1B, deducting exactly once", () => {
    const g = fresh();
    g.state.cleanCash = CASINO_COST;
    expect(g.canUnlockCasino).toBe(true);
    expect(g.unlockCasino()).toBe(true);
    expect(g.casinoUnlocked).toBe(true);
    expect(g.state.cleanCash).toBe(0);
  });

  it("never double-charges on repeated unlock taps", () => {
    const g = fresh();
    g.state.cleanCash = CASINO_COST + 500;
    expect(g.unlockCasino()).toBe(true);
    expect(g.unlockCasino()).toBe(false);
    expect(g.unlockCasino()).toBe(false);
    expect(g.state.cleanCash).toBe(500); // charged once
  });

  it("stays unlocked across a save/reload", () => {
    const g = fresh();
    g.state.cleanCash = CASINO_COST;
    g.unlockCasino();
    const loaded = loadState()!;
    expect(loaded.casino.unlocked).toBe(true);
  });

  it("survives a prestige (New Family) but clears any live hand", () => {
    const g = fresh();
    g.state.cleanCash = CASINO_COST;
    g.unlockCasino();
    g.state.cleanCash = 10_000;
    g.startBlackjack(100);
    g.state.lifetimeClean = 1e9; // enough to prestige
    g.rebrand();
    expect(g.casinoUnlocked).toBe(true);
    expect(g.casinoRound).toBeNull();
  });
});

describe("wagering & settlement", () => {
  function unlocked(cash: number): Game {
    const g = fresh();
    g.state.casino.unlocked = true;
    g.state.cleanCash = cash;
    return g;
  }

  it("reserves the wager from clean cash at deal", () => {
    const g = unlocked(10_000);
    g.startBlackjack(1000);
    // 1000 reserved; balance dropped by exactly the wager
    expect(g.state.cleanCash).toBe(9_000);
    expect(g.casinoRound).not.toBeNull();
  });

  it("rejects wagers over balance and never deducts", () => {
    const g = unlocked(500);
    const res = g.startBlackjack(1000);
    expect(res.ok).toBe(false);
    expect(g.state.cleanCash).toBe(500);
    expect(g.casinoRound).toBeNull();
  });

  it("rejects malformed wagers (NaN, Infinity, 0, negative)", () => {
    const g = unlocked(1000);
    for (const bad of [NaN, Infinity, -Infinity, 0, -50]) {
      expect(g.startBlackjack(bad).ok).toBe(false);
    }
    expect(g.state.cleanCash).toBe(1000);
  });

  it("settles a completed hand exactly once, even if the tick re-runs", () => {
    const g = unlocked(10_000);
    // Force a scripted round via direct construction is hard here; instead play
    // until completion by hitting to bust or stand, then re-settle repeatedly.
    g.startBlackjack(1000);
    // finish the hand deterministically: stand (dealer resolves)
    if (g.casinoRound && g.casinoRound.state === "playerTurn") g.blackjackStand();
    const balAfter = g.state.cleanCash;
    // Attempt to settle again several times — idempotent, no change.
    (g as unknown as { settleCasinoRound: () => void }).settleCasinoRound?.();
    (g as unknown as { settleCasinoRound: () => void }).settleCasinoRound?.();
    expect(g.state.cleanCash).toBe(balAfter);
    expect(g.casinoRound?.settled).toBe(true);
  });

  it("blocks a second deal while a hand is live", () => {
    const g = unlocked(10_000);
    g.startBlackjack(1000);
    if (g.casinoRound?.state === "playerTurn") {
      const res = g.startBlackjack(1000);
      expect(res.ok).toBe(false);
      expect(g.state.cleanCash).toBe(9_000); // no second reservation
    }
  });

  it("net clean-cash change over a hand equals the round payout minus wager", () => {
    const g = unlocked(10_000);
    const before = g.state.cleanCash;
    g.startBlackjack(1000);
    if (g.casinoRound?.state === "playerTurn") g.blackjackStand();
    const r = g.casinoRound!;
    const net = g.state.cleanCash - before;
    expect(net).toBe((r.payout ?? 0) - r.wager);
  });

  it("gambling never inflates lifetimeClean (Respect/prestige stay isolated)", () => {
    const g = unlocked(10_000);
    const life = g.state.lifetimeClean;
    g.startBlackjack(5000);
    if (g.casinoRound?.state === "playerTurn") g.blackjackStand();
    expect(g.state.lifetimeClean).toBe(life);
  });

  it("acknowledge clears the finished hand so a new one can start", () => {
    const g = unlocked(10_000);
    g.startBlackjack(1000);
    if (g.casinoRound?.state === "playerTurn") g.blackjackStand();
    expect(g.casinoRound?.state).toBe("completed");
    g.acknowledgeBlackjack();
    expect(g.casinoRound).toBeNull();
    expect(g.startBlackjack(1000).ok).toBe(true);
  });

  it("handles a max bet on a very large balance without overflow", () => {
    const g = unlocked(1e14);
    const res = g.startBlackjack(g.maxWager);
    expect(res.ok).toBe(true);
    expect(g.state.cleanCash).toBe(0);
    if (g.casinoRound?.state === "playerTurn") g.blackjackStand();
    expect(Number.isFinite(g.state.cleanCash)).toBe(true);
  });
});

describe("reload recovery mid-round", () => {
  it("restores a live player-turn hand exactly (same deck → same cards)", () => {
    const g = new Game(newGame());
    g.state.casino.unlocked = true;
    g.state.cleanCash = 10_000;
    g.startBlackjack(1000);
    // Only meaningful if the deal didn't resolve to a natural.
    if (g.casinoRound?.state === "playerTurn") {
      const deckBefore = JSON.stringify(g.casinoRound.deck);
      const playerBefore = JSON.stringify(g.casinoRound.player);
      saveState(g.state);
      const g2 = new Game(loadState()!);
      expect(g2.casinoRound?.state).toBe("playerTurn");
      expect(JSON.stringify(g2.casinoRound?.deck)).toBe(deckBefore);
      expect(JSON.stringify(g2.casinoRound?.player)).toBe(playerBefore);
      // reserved wager preserved (not refunded, not double-charged)
      expect(g2.state.cleanCash).toBe(9_000);
    }
  });

  it("settles a completed-but-unsettled hand on load, exactly once", () => {
    const g = new Game(newGame());
    g.state.casino.unlocked = true;
    g.state.cleanCash = 10_000;
    g.startBlackjack(1000);
    if (g.casinoRound?.state === "playerTurn") g.blackjackStand();
    // Simulate a crash *between* completion and settlement: unset the flag.
    const r = g.casinoRound!;
    const payout = r.payout ?? 0;
    r.settled = false;
    g.state.cleanCash -= payout; // pretend the payout hadn't been applied
    saveState(g.state);
    const g2 = new Game(loadState()!);
    expect(g2.casinoRound?.settled).toBe(true);
    // payout applied exactly once on recovery
    expect(g2.state.cleanCash).toBe(g.state.cleanCash + payout);
  });
});

describe("save migration", () => {
  it("old saves with no casino field default to locked, no round", () => {
    // A pre-casino v2 save.
    const old = newGame();
    // remove the casino field to mimic an older save
    delete (old as Partial<typeof old>).casino;
    saveState(old as never);
    const loaded = loadState()!;
    expect(loaded.casino).toEqual({ unlocked: false, round: null });
  });
});
