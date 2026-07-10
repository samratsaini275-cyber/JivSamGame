// Persisted game snapshot — port of Model/GameState.swift + Game/Persistence.swift.
import { HUSTLES } from "./data";
import { PLOTS } from "../theme/content";

export interface HustleState {
  unitsOwned: number;
  ghostwriterHired: boolean;
  cycleProgress: number; // seconds elapsed in the current post cycle
  cycleRunning: boolean; // manual hustles need a tap to start a cycle
}

export interface GameState {
  /** Save-format version. v1 (absent) = single-currency CloutEmpire saves. */
  saveVersion: number;
  /** DIRTY cash. Persisted key kept as `cash` so v1 saves migrate for free. */
  cash: number;
  /** CLEAN cash — laundered money; the real progression currency. */
  cleanCash: number;
  lifetimeCash: number; // lifetime DIRTY earned; survives prestige, drives Respect formula
  lifetimeClean: number; // lifetime CLEAN earned — the Family Fortune
  clout: number;
  hustles: HustleState[];
  /** Front-business levels by front id; missing/0 = deed not bought. */
  fronts: Record<string, number>;
  /** District ids the family controls. Always includes "docks". */
  districtsUnlocked: string[];
  lastSaved: number | null; // epoch ms

  // Rex Calloway's flex economy (wiped on Rebrand except Daytona count)
  ownedItems: string[];
  equippedWrist: string | null;
  equippedGarage: string | null;
  daytonaPurchases: number;
  rexMet: boolean;
  rexIntroAcknowledged: boolean;
  rexIntroReply: string | null;
  rexPitchReplies: Record<string, string>;
  rexPitchFollowUp: Record<string, string>;
  rexDismissedPitches: string[];
  milleBuffUntil: number | null; // epoch ms
  viralBuffUntil: number | null; // epoch ms

  // Persona — identity; all of it survives Rebrand
  handle: string;
  baseLook: string;
  colorway: string;
  ownedCosmetics: string[];
  equippedCosmetics: Record<string, string>;
}

function freshHustles(): HustleState[] {
  return HUSTLES.map(() => ({
    unitsOwned: 0, ghostwriterHired: false, cycleProgress: 0, cycleRunning: false,
  }));
}

export function newGame(): GameState {
  const hustles = freshHustles();
  hustles[0].unitsOwned = 1; // start with the family still bubbling
  return {
    saveVersion: 2,
    cash: 0, cleanCash: 0, lifetimeCash: 0, lifetimeClean: 0,
    clout: 0, hustles, fronts: {}, districtsUnlocked: ["docks"], lastSaved: null,
    ownedItems: [], equippedWrist: null, equippedGarage: null,
    daytonaPurchases: 0, rexMet: false,
    rexIntroAcknowledged: false, rexIntroReply: null,
    rexPitchReplies: {}, rexPitchFollowUp: {}, rexDismissedPitches: [],
    milleBuffUntil: null, viralBuffUntil: null,
    handle: "", baseLook: "hoodie", colorway: "gold",
    ownedCosmetics: [], equippedCosmetics: {},
  };
}

/// Rebrand keeps clout + lifetime cash (and Daytona's permanent bonus),
/// wipes everything else. Persona survives — the account gets deleted, the player doesn't.
export function applyRebrand(state: GameState, gained: number): void {
  state.clout += gained;
  state.cash = 0;
  state.hustles = freshHustles();
  state.hustles[0].unitsOwned = 1;
  state.ownedItems = [];
  state.equippedWrist = null;
  state.equippedGarage = null;
  state.milleBuffUntil = null;
  state.viralBuffUntil = null;
  state.rexPitchReplies = {};
  state.rexPitchFollowUp = {};
  state.rexDismissedPitches = [];
  // Clean cash and the fronts' deeds survive — they're legitimate businesses.
}

/** v1 (CloutEmpire) → v2 (Bootleg Empire): old cash becomes dirty cash. */
function migrate(parsed: Partial<GameState>): Partial<GameState> {
  const version = parsed.saveVersion ?? 1;
  if (version < 2) {
    parsed.saveVersion = 2;
    parsed.cleanCash = parsed.cleanCash ?? 0;
    parsed.lifetimeClean = parsed.lifetimeClean ?? 0;
    parsed.fronts = parsed.fronts ?? {};
    // v1 players already ran rackets across the city — grant districts that
    // cover any racket they own so nothing they had gets locked away.
    if (!parsed.districtsUnlocked) {
      const owned = new Set<string>(["docks"]);
      (parsed.hustles ?? []).forEach((h, i) => {
        if (h.unitsOwned > 0) {
          const plot = PLOTS.find((p) => p.kind === "racket" && p.ref === i);
          if (plot) owned.add(plot.district);
        }
      });
      parsed.districtsUnlocked = [...owned];
    }
  }
  if (!parsed.districtsUnlocked?.includes("docks")) {
    parsed.districtsUnlocked = ["docks", ...(parsed.districtsUnlocked ?? [])];
  }
  return parsed;
}

const SAVE_KEY = "clout-empire-save-v1";

export function loadState(): GameState | null {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    const parsed = migrate(JSON.parse(raw) as Partial<GameState>);
    const base = newGame();
    const merged: GameState = { ...base, ...parsed };
    // Defensive: hustle array must match the current roster length.
    const fresh = freshHustles();
    (parsed.hustles ?? []).slice(0, fresh.length).forEach((h, i) => {
      fresh[i] = { ...fresh[i], ...h };
    });
    merged.hustles = fresh;
    return merged;
  } catch {
    return null;
  }
}

export function saveState(state: GameState): void {
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify(state));
  } catch {
    // storage full / private mode — skip silently
  }
}

export function wipeSave(): void {
  localStorage.removeItem(SAVE_KEY);
}
