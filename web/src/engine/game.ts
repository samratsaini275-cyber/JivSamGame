// Owns the game state and the 10 Hz tick loop — port of Game/Game.swift.
import * as F from "./formulas";
import {
  HUSTLES, REX, RexItemDef, rexItemByID, PersonaItemDef, personaItemByID,
  pick, PersonaSlot,
} from "./data";
import { GameState, newGame, loadState, saveState, applyRebrand } from "./state";
import {
  Round, validateWager, WagerCheck, shuffledDeck, startRound, newRoundId,
  playerHit as bjHit, playerStand as bjStand,
} from "./blackjack";
import {
  FIXER, FRONTS, FrontDef, VELVET_CLEAN_INCOME_PER_LEVEL,
  DISTRICTS, DistrictDef, PLOTS,
  HEAT_TUNING as HT, LAWYER_PERKS,
  SHIPMENT_ROUTES, ShipmentRouteDef, SHIPMENT_SIZES, SHIPMENT_TUNING,
  RESPECT, LEGACY, LEGACY_DIVISOR, LAWYER_RESPECT, MILESTONES,
} from "../theme/content";

export type BuyMode = "x1" | "x10" | "x100" | "max";
export const BUY_MODES: { id: BuyMode; label: string }[] = [
  { id: "x1", label: "×1" },
  { id: "x10", label: "×10" },
  { id: "x100", label: "×100" },
  { id: "max", label: "MAX" },
];

export type GameEvent =
  | { kind: "payout"; hustleIndex: number; amount: number }
  | { kind: "milestone"; hustleIndex: number; tier: number }
  | { kind: "hypeWave"; tier: number }
  | { kind: "rebranded"; clout: number }
  | { kind: "districtUnlocked"; districtID: string }
  | { kind: "investigation" }
  | { kind: "raid"; hustleIndex: number }
  | { kind: "caseDismissed" }
  | { kind: "released" }
  | { kind: "shipmentDeparted"; routeID: string }
  | { kind: "checkpoint" }
  | { kind: "shipmentArrived"; amount: number }
  | { kind: "shipmentSeized" }
  | { kind: "respectLevel"; level: number }
  | { kind: "headline"; title: string; sub: string }
  | { kind: "casinoUnlocked" };

/** The Gilded Ace unlock price — exactly one billion clean dollars. */
export const CASINO_COST = 1_000_000_000;
/** A wager above this fraction of balance asks for confirmation in the UI. */
export const CASINO_BIG_BET_FRACTION = 0.25;

/** Precinct landmark ids in payroll-cost order (matches district order). */
export const PRECINCTS = [
  "precinct_docks", "precinct_warsaw", "precinct_downtown", "precinct_row",
] as const;

type Listener = () => void;
type EventListener = (e: GameEvent) => void;

const TICK_MS = 100;
const SAVE_EVERY_TICKS = 50; // autosave every 5s

export class Game {
  state: GameState;
  buyMode: BuyMode = "x1";
  offlineEarnings = 0;
  version = 0;

  private listeners = new Set<Listener>();
  private eventListeners = new Set<EventListener>();
  private ticksSinceSave = 0;

  constructor(state: GameState) {
    this.state = state;
    this.grantOfflineEarnings();
    this.recoverCasinoRound();
    setInterval(() => this.tick(TICK_MS / 1000), TICK_MS);
  }

  static loadOrNew(): Game {
    return new Game(loadState() ?? newGame());
  }

  // MARK: React binding

  subscribe = (fn: Listener): (() => void) => {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  };

  onEvent(fn: EventListener): () => void {
    this.eventListeners.add(fn);
    return () => this.eventListeners.delete(fn);
  }

  private notify(): void {
    this.version++;
    this.listeners.forEach((fn) => fn());
  }

  private emit(e: GameEvent): void {
    this.eventListeners.forEach((fn) => fn(e));
  }

  // MARK: Derived values

  get viralTier(): number {
    return F.viralTier(this.state.hustles.map((h) => h.unitsOwned));
  }

  get viralBuffActive(): boolean {
    return this.state.viralBuffUntil !== null && Date.now() < this.state.viralBuffUntil;
  }

  get milleBuffActive(): boolean {
    return this.state.milleBuffUntil !== null && Date.now() < this.state.milleBuffUntil;
  }

  get effectiveViralTier(): number {
    return this.viralTier + (this.viralBuffActive ? 1 : 0);
  }

  get hustlesAtNextViralTier(): number {
    const vt = this.viralTier;
    return this.state.hustles.filter((h) => F.milestoneTier(h.unitsOwned) > vt).length;
  }

  tier(index: number): number {
    return F.milestoneTier(this.state.hustles[index].unitsOwned);
  }

  private get maxHustleTier(): number {
    return Math.max(...this.state.hustles.map((h) => F.milestoneTier(h.unitsOwned)));
  }

  get maxMoneyTier(): number {
    return this.maxHustleTier;
  }

  get lowestOwnedHustleIndex(): number | null {
    let best: number | null = null;
    this.state.hustles.forEach((h, i) => {
      if (h.unitsOwned > 0 && (best === null || h.unitsOwned < this.state.hustles[best].unitsOwned)) {
        best = i;
      }
    });
    return best;
  }

  cycleTime(index: number): number {
    let cycleTier = this.tier(index);
    // Bugatti: the lowest-owned hustle runs at the account's best milestone tier.
    if (this.state.equippedGarage === "bugatti" && index === this.lowestOwnedHustleIndex) {
      cycleTier = Math.max(cycleTier, this.maxHustleTier);
    }
    return (
      F.cycleTime(HUSTLES[index].baseCycle, cycleTier) *
      F.garageCycleMultiplier(this.state.equippedGarage, this.tier(index))
    );
  }

  incomePerCycle(index: number): number {
    const h = HUSTLES[index];
    const s = this.state.hustles[index];
    return (
      h.baseIncome * s.unitsOwned *
      F.incomeMultiplier(this.tier(index)) *
      Math.pow(2, this.effectiveViralTier) *
      F.cloutMultiplier(this.state.clout) *
      F.wristIncomeMultiplier(this.state.equippedWrist, this.tier(index)) *
      (this.milleBuffActive ? 2 : 1)
    );
  }

  get incomePerSecond(): number {
    return this.state.hustles.reduce((sum, s, i) => {
      if (s.unitsOwned <= 0 || !s.ghostwriterHired || this.isRaided(i)) return sum;
      return sum + this.incomePerCycle(i) / this.cycleTime(i);
    }, 0);
  }

  buyCount(index: number): number {
    const h = HUSTLES[index];
    const owned = this.state.hustles[index].unitsOwned;
    switch (this.buyMode) {
      case "x1": return 1;
      case "x10": return 10;
      case "x100": return 100;
      case "max": return Math.max(1, F.maxAffordable(h.baseCost, owned, this.state.cash));
    }
  }

  setBuyMode(mode: BuyMode): void {
    this.buyMode = mode;
    this.notify();
  }

  buyCost(index: number): number {
    return F.bulkCost(
      HUSTLES[index].baseCost,
      this.state.hustles[index].unitsOwned,
      this.buyCount(index),
    );
  }

  get cloutGainRateBonus(): number {
    return (
      this.state.daytonaPurchases * F.DAYTONA_GAIN_RATE_PER_PURCHASE +
      this.equippedGrailCount * F.GRAIL_REBRAND_BONUS_PER_ITEM
    );
  }

  /** Legacy tokens on prestige — converts the Family Fortune (clean lifetime). */
  get cloutOnRebrand(): number {
    return F.cloutGain(
      this.state.lifetimeClean,
      this.state.clout,
      this.cloutGainRateBonus,
      LEGACY_DIVISOR,
    );
  }

  // MARK: Districts

  districtUnlocked(id: string): boolean {
    return this.state.districtsUnlocked.includes(id);
  }

  /** District a racket lives in ("docks" fallback for safety). */
  hustleDistrict(index: number): string {
    return PLOTS.find((p) => p.kind === "racket" && p.ref === index)?.district ?? "docks";
  }

  hustleAvailable(index: number): boolean {
    return this.districtUnlocked(this.hustleDistrict(index));
  }

  canUnlockDistrict(def: DistrictDef): boolean {
    return (
      !this.districtUnlocked(def.id) &&
      this.state.cleanCash >= def.price &&
      this.respectLevel >= def.respectLevel
    );
  }

  unlockDistrict(def: DistrictDef): boolean {
    if (this.inPrison || !this.canUnlockDistrict(def)) return false;
    this.state.cleanCash -= def.price;
    this.state.districtsUnlocked.push(def.id);
    this.grantRespect(RESPECT.xp.districtUnlock);
    if (def.id === "islands") this.milestoneOnce("bridge_islands");
    this.emit({ kind: "districtUnlocked", districtID: def.id });
    this.save();
    this.notify();
    return true;
  }

  get nextLockedDistrict(): DistrictDef | null {
    return DISTRICTS.find((d) => !this.districtUnlocked(d.id)) ?? null;
  }

  // MARK: Respect (XP levels) & milestones

  get respectLevel(): number {
    let xp = this.state.respectXP;
    let level = 1;
    while (level < 40) {
      const need = RESPECT.xpForNext(level);
      if (xp < need) break;
      xp -= need;
      level++;
    }
    return level;
  }

  get respectProgress(): { into: number; needed: number } {
    let xp = this.state.respectXP;
    let level = 1;
    while (level < 40) {
      const need = RESPECT.xpForNext(level);
      if (xp < need) return { into: xp, needed: need };
      xp -= need;
      level++;
    }
    return { into: 0, needed: RESPECT.xpForNext(level) };
  }

  grantRespect(xp: number): void {
    const before = this.respectLevel;
    this.state.respectXP += xp;
    const after = this.respectLevel;
    if (after > before) this.emit({ kind: "respectLevel", level: after });
  }

  guideSeen(id: string): boolean {
    return this.state.guideSeen.includes(id);
  }

  markGuideSeen(id: string): void {
    if (this.guideSeen(id)) return;
    this.state.guideSeen.push(id);
    this.save();
    this.notify();
  }

  /** Fire a scripted headline exactly once, with its Respect reward. */
  private milestoneOnce(id: string): void {
    if (this.state.milestones.includes(id)) return;
    const m = MILESTONES[id];
    if (!m) return;
    this.state.milestones.push(id);
    this.grantRespect(m.xp);
    this.emit({ kind: "headline", title: m.title, sub: m.sub });
  }

  // MARK: Shipments — the active-play burst

  /** All owned rackets' potential $/s (manual ones count at full tilt). */
  get potentialIncomePerSec(): number {
    return this.state.hustles.reduce((sum, s, i) => {
      if (s.unitsOwned <= 0 || this.isRaided(i)) return sum;
      return sum + this.incomePerCycle(i) / this.cycleTime(i);
    }, 0);
  }

  routeAvailable(route: ShipmentRouteDef): boolean {
    return route.requires.every(
      (i) =>
        this.state.hustles[i].unitsOwned > 0 &&
        !this.isRaided(i) &&
        this.hustleAvailable(i),
    );
  }

  shipmentQuote(route: ShipmentRouteDef, sizeID: string): { payout: number; heat: number } {
    const size = SHIPMENT_SIZES.find((s) => s.id === sizeID) ?? SHIPMENT_SIZES[0];
    const payout = Math.max(
      size.floor,
      this.potentialIncomePerSec * size.seconds * route.payoutMult,
    );
    let heat = size.heat * route.heatMult;
    if (this.frontLevel("importexport") > 0) heat *= 0.75; // Meridian's manifests
    return { payout, heat: Math.round(heat) };
  }

  startShipment(routeID: string, sizeID: string): boolean {
    if (this.inPrison || this.state.activeShipment) return false;
    const route = SHIPMENT_ROUTES.find((r) => r.id === routeID);
    if (!route || !this.routeAvailable(route)) return false;
    const { payout, heat } = this.shipmentQuote(route, sizeID);
    const now = Date.now();
    const hasCheckpoint = Math.random() < SHIPMENT_TUNING.checkpointChance;
    this.state.activeShipment = {
      routeID,
      sizeID,
      departedAt: now,
      arrivesAt: now + route.travelSeconds * 1000,
      payout,
      heatOnArrive: heat,
      checkpointAt: hasCheckpoint ? now + route.travelSeconds * 450 : 0,
      checkpointResolved: !hasCheckpoint,
    };
    this.emit({ kind: "shipmentDeparted", routeID });
    this.notify();
    return true;
  }

  /** Checkpoint choice: detour (slower, half heat) or barrel (+2 heat now). */
  resolveCheckpoint(detour: boolean): void {
    const sh = this.state.activeShipment;
    if (!sh || sh.checkpointResolved) return;
    sh.checkpointResolved = true;
    if (detour) {
      sh.arrivesAt += SHIPMENT_TUNING.detourExtraSeconds * 1000;
      sh.heatOnArrive = Math.round(sh.heatOnArrive / 2);
    } else {
      this.state.heat = Math.min(100, this.state.heat + SHIPMENT_TUNING.barrelExtraHeat);
    }
    this.notify();
  }

  private checkpointEmitted = false;

  private shipmentTick(): void {
    const sh = this.state.activeShipment;
    if (!sh) return;
    const now = Date.now();
    if (sh.checkpointAt > 0 && !sh.checkpointResolved && now >= sh.checkpointAt) {
      if (!this.checkpointEmitted) {
        this.checkpointEmitted = true;
        this.emit({ kind: "checkpoint" });
      }
      // Safety: an unanswered checkpoint barrels through after 8s.
      if (now >= sh.checkpointAt + 8000) this.resolveCheckpoint(false);
      return; // hold the payout until the checkpoint resolves
    }
    if (now >= sh.arrivesAt) {
      this.checkpointEmitted = false;
      this.state.activeShipment = null;
      this.deposit(sh.payout);
      this.state.heat = Math.min(100, this.state.heat + sh.heatOnArrive);
      this.grantRespect(SHIPMENT_TUNING.respectXP[sh.routeID] ?? 10);
      this.milestoneOnce("first_shipment");
      this.emit({ kind: "shipmentArrived", amount: sh.payout });
      this.save();
    }
  }

  // MARK: The law — heat, bribes, payroll, investigation, raids, prison

  get inPrison(): boolean {
    return this.state.prisonUntil !== null && Date.now() < this.state.prisonUntil;
  }

  get prisonSecondsLeft(): number {
    if (this.state.prisonUntil === null) return 0;
    return Math.max(0, (this.state.prisonUntil - Date.now()) / 1000);
  }

  get underInvestigation(): boolean {
    return this.state.investigationEndsAt !== null;
  }

  get investigationSecondsLeft(): number {
    return Math.max(0, ((this.state.investigationEndsAt ?? 0) - Date.now()) / 1000);
  }

  isRaided(index: number): boolean {
    return this.state.raidedHustles.includes(index);
  }

  hasLawyerPerk(id: string): boolean {
    return this.state.lawyerPerks.includes(id);
  }

  payrollActive(precinctID: string): boolean {
    return this.state.payrolls.includes(precinctID);
  }

  payrollCostPerMin(precinctID: string): number {
    const i = PRECINCTS.indexOf(precinctID as (typeof PRECINCTS)[number]);
    return HT.payrollPerMin[Math.max(0, i)];
  }

  /** Dirty stockpile size above which the pile itself draws eyes. */
  get stockpileThreshold(): number {
    return Math.max(HT.stockpileFloor, this.launderRate * HT.stockpileGraceSeconds);
  }

  /** Current heat delta per second (for the dial + panel readout). */
  get heatRatePerSec(): number {
    if (this.inPrison) return -HT.decayPerSec;
    let passive = 0;
    for (let i = 0; i < this.state.hustles.length; i++) {
      const s = this.state.hustles[i];
      if (s.unitsOwned <= 0 || this.isRaided(i)) continue;
      passive += s.unitsOwned * HT.passivePerUnit * HT.racketWeight(i);
    }
    passive *= Math.pow(HT.payrollFactor, this.state.payrolls.length);
    const threshold = this.stockpileThreshold;
    const excess = this.state.cash / threshold - 1;
    const stockpile = excess > 0
      ? Math.min(HT.stockpileMaxRate, HT.stockpileRateK * excess)
      : 0;
    return passive + stockpile - HT.decayPerSec;
  }

  get bribeCost(): number {
    return HT.bribeBase(this.incomePerSecond + 1) * HT.bribeHeatScale(this.state.heat);
  }

  get bribeRelief(): number {
    return HT.bribeRelief(this.state.heat);
  }

  /** One-time palm grease at any precinct. Dirty cash. */
  bribe(): boolean {
    if (this.inPrison) return false;
    const cost = this.bribeCost;
    if (this.state.cash < cost) return false;
    this.state.cash -= cost;
    this.state.heat = Math.max(0, this.state.heat - this.bribeRelief);
    this.notify();
    return true;
  }

  togglePayroll(precinctID: string): void {
    if (this.inPrison) return;
    const i = this.state.payrolls.indexOf(precinctID);
    if (i >= 0) this.state.payrolls.splice(i, 1);
    else this.state.payrolls.push(precinctID);
    this.notify();
  }

  get bailCost(): number {
    const base = Math.max(HT.bailFloor, this.state.lifetimeClean * HT.bailRate);
    return this.hasLawyerPerk("bagman") ? base * 0.5 : base;
  }

  payBail(): boolean {
    if (!this.inPrison || this.state.cleanCash < this.bailCost) return false;
    this.state.cleanCash -= this.bailCost;
    this.release();
    return true;
  }

  /** Monetization hook (§4c) — rewarded-ad early release. Not wired yet. */
  adReleaseAvailable(): boolean {
    return false;
  }

  async adRelease(): Promise<boolean> {
    return false;
  }

  reopenCost(index: number): number {
    return HT.reopenFeeUnits *
      F.unitCost(HUSTLES[index].baseCost, this.state.hustles[index].unitsOwned);
  }

  /** Legal fees + repairs (clean). Comes back one milestone tier down. */
  reopenHustle(index: number): boolean {
    if (this.inPrison || !this.isRaided(index)) return false;
    const cost = this.reopenCost(index);
    if (this.state.cleanCash < cost) return false;
    this.state.cleanCash -= cost;
    this.state.raidedHustles = this.state.raidedHustles.filter((i) => i !== index);
    const s = this.state.hustles[index];
    const tier = F.milestoneTier(s.unitsOwned);
    s.unitsOwned = tier > 0
      ? Math.max(1, F.MILESTONE_THRESHOLDS[tier - 1] - 1)
      : Math.max(1, s.unitsOwned - 5);
    s.cycleProgress = 0;
    s.cycleRunning = false;
    this.save();
    this.notify();
    return true;
  }

  buyLawyerPerk(id: string): boolean {
    if (this.inPrison || this.hasLawyerPerk(id)) return false;
    const perk = LAWYER_PERKS.find((p) => p.id === id);
    if (!perk || !this.districtUnlocked("row")) return false;
    if (this.respectLevel < (LAWYER_RESPECT[id] ?? 0)) return false;
    if (this.state.cleanCash < perk.cost) return false;
    this.state.cleanCash -= perk.cost;
    this.state.lawyerPerks.push(id);
    this.save();
    this.notify();
    return true;
  }

  private release(): void {
    this.state.prisonUntil = null;
    // Legacy tokens teach the family how to walk out quieter.
    this.state.heat = Math.max(
      LEGACY.releaseHeatFloor,
      HT.heatAfterRelease - this.state.clout * LEGACY.releaseHeatPerToken,
    );
    this.milestoneOnce("first_raid_survived");
    this.emit({ kind: "released" });
    this.save();
    this.notify();
  }

  private prisonSeconds(): number {
    const scale = 1 + Math.log10(Math.max(1, this.state.lifetimeClean / 100_000));
    return Math.min(HT.prisonMaxSeconds, HT.prisonBaseSeconds * Math.max(1, scale));
  }

  /** Advance heat, payroll billing, investigations and lockup. */
  private lawTick(dt: number): void {
    const st = this.state;
    const now = Date.now();

    // Prison: countdown handled by timestamps; check for walk-out.
    if (st.prisonUntil !== null && now >= st.prisonUntil) {
      this.release();
      return;
    }

    // Payroll billing (dirty). Broke = the captain walks.
    for (const pid of [...st.payrolls]) {
      const charge = (this.payrollCostPerMin(pid) / 60) * dt;
      if (st.cash >= charge) st.cash -= charge;
      else st.payrolls = st.payrolls.filter((p) => p !== pid);
    }

    st.heat = Math.min(100, Math.max(0, st.heat + this.heatRatePerSec * dt));

    if (this.inPrison) return;

    // Investigation lifecycle.
    if (st.investigationEndsAt === null && st.heat >= HT.investigationStartsAt) {
      const secs = this.hasLawyerPerk("retainer")
        ? HT.investigationSecondsWithLawyer
        : HT.investigationSeconds;
      st.investigationEndsAt = now + secs * 1000;
      this.emit({ kind: "investigation" });
    } else if (st.investigationEndsAt !== null && st.heat < HT.investigationCallsOffBelow) {
      st.investigationEndsAt = null; // laid low; case goes cold
    } else if (
      st.investigationEndsAt !== null &&
      (now >= st.investigationEndsAt || st.heat >= 100)
    ) {
      this.raid();
    }
  }

  /** The Feds pick your best earner. It always hurts. */
  private raid(): void {
    const st = this.state;
    st.investigationEndsAt = null;

    // The Judge's favor: once an hour, the case evaporates instead.
    if (
      this.hasLawyerPerk("silk_glove") &&
      now_minus(st.lastCaseDismissedAt) >= HT.caseDismissCooldownMs
    ) {
      st.lastCaseDismissedAt = Date.now();
      st.heat = Math.max(40, st.heat - 25);
      this.emit({ kind: "caseDismissed" });
      this.notify();
      return;
    }

    let target = -1;
    let best = -1;
    for (let i = 0; i < st.hustles.length; i++) {
      if (st.hustles[i].unitsOwned <= 0 || this.isRaided(i)) continue;
      const rate = this.incomePerCycle(i) / this.cycleTime(i);
      if (rate > best) { best = rate; target = i; }
    }
    if (target < 0) { st.heat = 50; return; } // nothing to seize

    st.raidedHustles.push(target);
    st.prisonUntil = Date.now() + this.prisonSeconds() * 1000;
    if (st.activeShipment) {
      st.activeShipment = null; // the load is seized on the road
      this.checkpointEmitted = false;
      this.emit({ kind: "shipmentSeized" });
    }
    this.emit({ kind: "raid", hustleIndex: target });
    this.save();
    this.notify();
  }

  // MARK: Fronts & laundering (dirty → clean)

  frontLevel(id: string): number {
    return this.state.fronts[id] ?? 0;
  }

  /** Dirty $/s a front washes at a given level. */
  frontThroughput(def: FrontDef, level = this.frontLevel(def.id)): number {
    if (level <= 0) return 0;
    return def.baseThroughput * Math.pow(def.throughputGrowth, level - 1);
  }

  /** Fraction lost in the wash at a given level (Legacy shaves it further). */
  frontCut(def: FrontDef, level = this.frontLevel(def.id)): number {
    const legacyBonus = Math.min(LEGACY.cutCap, this.state.clout * LEGACY.cutPerToken);
    if (level <= 0) return def.baseCut;
    return Math.max(
      0.03,
      Math.max(def.cutFloor, def.baseCut - def.cutPerLevel * (level - 1)) - legacyBonus,
    );
  }

  frontUpgradeCost(def: FrontDef, level = this.frontLevel(def.id)): number {
    return def.upgradeBase * Math.pow(def.upgradeGrowth, Math.max(level - 1, 0));
  }

  /** Total dirty $/s the whole outfit can wash. */
  get launderRate(): number {
    return FRONTS.reduce((sum, f) => sum + this.frontThroughput(f), 0);
  }

  /** Weighted average keep-fraction across owned fronts (for display). */
  get launderKeep(): number {
    const owned = FRONTS.filter((f) => this.frontLevel(f.id) > 0);
    if (owned.length === 0) return 0;
    const totalThr = this.launderRate;
    return owned.reduce(
      (sum, f) => sum + (this.frontThroughput(f) / totalThr) * (1 - this.frontCut(f)),
      0,
    );
  }

  canAffordFront(def: FrontDef): boolean {
    if (!this.districtUnlocked(def.district)) return false;
    return def.priceCurrency === "dirty"
      ? this.state.cash >= def.price
      : this.state.cleanCash >= def.price;
  }

  buyFront(def: FrontDef): boolean {
    if (this.inPrison) return false;
    if (this.frontLevel(def.id) > 0 || !this.canAffordFront(def)) return false;
    if (def.priceCurrency === "dirty") this.state.cash -= def.price;
    else this.state.cleanCash -= def.price;
    this.state.fronts[def.id] = 1;
    this.grantRespect(RESPECT.xp.firstPlot);
    if (def.id === "velvet") this.milestoneOnce("velvet_open");
    this.notify();
    return true;
  }

  upgradeFront(def: FrontDef): boolean {
    if (this.inPrison) return false;
    const level = this.frontLevel(def.id);
    if (level <= 0) return false;
    const cost = this.frontUpgradeCost(def, level);
    if (this.state.cleanCash < cost) return false;
    this.state.cleanCash -= cost;
    this.state.fronts[def.id] = level + 1;
    this.notify();
    return true;
  }

  /** Run the wash for `dt` seconds. Factor for prison slowdown (phase 4). */
  private launder(dt: number, speedFactor = 1): void {
    for (const f of FRONTS) {
      const level = this.frontLevel(f.id);
      if (level <= 0) continue;
      const capacity = this.frontThroughput(f, level) * dt * speedFactor;
      const take = Math.min(this.state.cash, capacity);
      if (take > 0) {
        this.state.cash -= take;
        this.depositClean(take * (1 - this.frontCut(f, level)));
      }
      if (f.perk === "velvet_income") {
        this.depositClean(VELVET_CLEAN_INCOME_PER_LEVEL * level * dt * speedFactor);
      }
    }
  }

  private depositClean(amount: number): void {
    this.state.cleanCash += amount;
    this.state.lifetimeClean += amount;
  }

  // MARK: Persona

  get personaCreated(): boolean {
    return this.state.handle.length > 0;
  }

  createPersona(handle: string, look: string, colorway: string): void {
    const trimmed = handle.trim();
    if (!trimmed) return;
    this.state.handle = trimmed;
    this.state.baseLook = look;
    this.state.colorway = colorway;
    this.save();
    this.notify();
  }

  setColorway(id: string): void {
    this.state.colorway = id;
    this.notify();
  }

  get equippedGrailCount(): number {
    return Object.values(this.state.equippedCosmetics)
      .map(personaItemByID)
      .filter((i) => i?.tier === 4).length;
  }

  ownsCosmetic(item: PersonaItemDef): boolean {
    return this.state.ownedCosmetics.includes(item.id);
  }

  isCosmeticEquipped(item: PersonaItemDef): boolean {
    return this.state.equippedCosmetics[item.slot] === item.id;
  }

  /** Wardrobe is a legitimate purchase — clean cash only. */
  buyCosmetic(item: PersonaItemDef): boolean {
    if (this.inPrison) return false;
    if (this.ownsCosmetic(item) || this.state.cleanCash < item.cost) return false;
    this.state.cleanCash -= item.cost;
    this.state.ownedCosmetics.push(item.id);
    this.equipCosmetic(item);
    return true;
  }

  equipCosmetic(item: PersonaItemDef): void {
    if (!this.ownsCosmetic(item)) return;
    this.state.equippedCosmetics[item.slot] = item.id;
    this.notify();
  }

  equippedCosmetic(slot: PersonaSlot): PersonaItemDef | null {
    return personaItemByID(this.state.equippedCosmetics[slot]);
  }

  // MARK: Rex

  get sneakerResellsUnlocked(): boolean {
    return this.state.hustles[1].unitsOwned >= 1;
  }

  get rexUnlocked(): boolean {
    return this.sneakerResellsUnlocked || this.state.clout > 0;
  }

  get equippedWristItem(): RexItemDef | null {
    return rexItemByID(this.state.equippedWrist);
  }

  get equippedGarageItem(): RexItemDef | null {
    return rexItemByID(this.state.equippedGarage);
  }

  ownsItem(item: RexItemDef): boolean {
    return this.state.ownedItems.includes(item.id);
  }

  isItemEquipped(item: RexItemDef): boolean {
    return item.slot === "wrist"
      ? this.state.equippedWrist === item.id
      : this.state.equippedGarage === item.id;
  }

  /// Buying auto-equips. Returns false if unaffordable (Rex: "Manifest harder.")
  buyItem(item: RexItemDef): boolean {
    if (this.inPrison) return false;
    if (this.ownsItem(item) || this.state.cash < item.cost) return false;
    this.state.cash -= item.cost;
    this.state.ownedItems.push(item.id);
    if (item.id === "daytona") this.state.daytonaPurchases += 1;
    this.grantRespect(RESPECT.xp.fixerItem);
    this.equipItem(item);
    return true;
  }

  equipItem(item: RexItemDef): void {
    if (!this.ownsItem(item)) return;
    if (item.slot === "wrist") this.state.equippedWrist = item.id;
    else this.state.equippedGarage = item.id;
    this.notify();
  }

  markRexMet(): void {
    if (!this.state.rexMet) {
      this.state.rexMet = true;
      this.notify();
    }
  }

  // MARK: Player actions

  buy(index: number): void {
    if (this.inPrison || this.isRaided(index) || !this.hustleAvailable(index)) return;
    const count = this.buyCount(index);
    const cost = F.bulkCost(HUSTLES[index].baseCost, this.state.hustles[index].unitsOwned, count);
    if (count <= 0 || this.state.cash < cost) return;
    const tierBefore = this.tier(index);
    const viralBefore = this.viralTier;
    const firstBuy = this.state.hustles[index].unitsOwned === 0;
    this.state.cash -= cost;
    this.state.hustles[index].unitsOwned += count;
    this.grantRespect(count * RESPECT.xp.perUnit + (firstBuy ? RESPECT.xp.firstPlot : 0));

    // "Richard Mille": every unit purchase doubles income for 10 seconds.
    if (this.state.equippedWrist === "mille") {
      this.state.milleBuffUntil = Date.now() + F.MILLE_BUFF_DURATION_MS;
    }
    // Borrowed Lambo: crossing a milestone has a 25% chance to go viral early.
    if (
      this.state.equippedGarage === "lambo" &&
      this.tier(index) > tierBefore &&
      Math.random() < F.LAMBO_VIRAL_CHANCE
    ) {
      this.state.viralBuffUntil = Date.now() + F.LAMBO_VIRAL_DURATION_MS;
    }

    if (this.viralTier > viralBefore) {
      this.emit({ kind: "hypeWave", tier: this.viralTier });
    } else if (this.tier(index) > tierBefore) {
      this.emit({ kind: "milestone", hustleIndex: index, tier: this.tier(index) });
    }
    this.notify();
  }

  /// Unlock path for a hustle the player doesn't own yet — always a single unit.
  buyOne(index: number): void {
    const prev = this.buyMode;
    this.buyMode = "x1";
    this.buy(index);
    this.buyMode = prev;
  }

  post(index: number): void {
    const s = this.state.hustles[index];
    if (s.unitsOwned <= 0 || s.ghostwriterHired || s.cycleRunning) return;
    s.cycleRunning = true;
    s.cycleProgress = 0;
    this.notify();
  }

  hireGhostwriter(index: number): void {
    if (this.inPrison || this.isRaided(index)) return;
    const s = this.state.hustles[index];
    if (s.ghostwriterHired || this.state.cash < HUSTLES[index].ghostwriterCost) return;
    this.state.cash -= HUSTLES[index].ghostwriterCost;
    s.ghostwriterHired = true;
    this.grantRespect(RESPECT.xp.crewHire);
    this.notify();
  }

  rebrand(): void {
    const gained = this.cloutOnRebrand;
    if (gained <= 0) return;
    applyRebrand(this.state, gained);
    this.save();
    this.emit({ kind: "rebranded", clout: gained });
    this.notify();
  }

  dismissOfflineEarnings(): void {
    this.offlineEarnings = 0;
    this.notify();
  }

  // MARK: The Gilded Ace — casino (blackjack). Uses CLEAN cash only, and its
  // wins/losses never touch lifetimeClean/Respect: gambling is walled off from
  // progression. All wager money moves through `cleanCash`, settled exactly once.

  get casinoUnlocked(): boolean {
    return this.state.casino.unlocked;
  }

  get canUnlockCasino(): boolean {
    return !this.state.casino.unlocked && this.state.cleanCash >= CASINO_COST;
  }

  /** Open the casino for exactly $1B clean, once. Guarded against double-spend. */
  unlockCasino(): boolean {
    if (this.state.casino.unlocked) return false;
    if (this.state.cleanCash < CASINO_COST) return false;
    this.state.cleanCash -= CASINO_COST;
    this.state.casino.unlocked = true;
    this.emit({ kind: "casinoUnlocked" });
    this.save();
    this.notify();
    return true;
  }

  get casinoRound(): Round | null {
    return this.state.casino.round;
  }

  /** Largest whole-dollar wager the player can currently make. */
  get maxWager(): number {
    return Math.max(0, Math.floor(this.state.cleanCash));
  }

  checkWager(raw: number): WagerCheck {
    return validateWager(raw, this.state.cleanCash);
  }

  /**
   * Deal a new blackjack hand. Reserves the (validated) wager from clean cash
   * so it can't be double-spent, then deals from a freshly shuffled deck.
   * Refuses if the casino is locked or a hand is already in progress.
   */
  startBlackjack(raw: number): WagerCheck {
    if (!this.state.casino.unlocked) return { ok: false, error: "invalid" };
    const existing = this.state.casino.round;
    if (existing && existing.state !== "completed") return { ok: false, error: "invalid" };
    const check = validateWager(raw, this.state.cleanCash);
    if (!check.ok) return check;

    this.state.cleanCash -= check.wager; // reserve
    this.state.casino.round = startRound(check.wager, shuffledDeck(), newRoundId());
    this.settleCasinoRound(); // resolves & pays out immediately on a natural
    this.save();
    this.notify();
    return check;
  }

  blackjackHit(): void {
    const r = this.state.casino.round;
    if (!r || r.state !== "playerTurn") return;
    bjHit(r);
    this.settleCasinoRound();
    this.save();
    this.notify();
  }

  blackjackStand(): void {
    const r = this.state.casino.round;
    if (!r || r.state !== "playerTurn") return;
    bjStand(r);
    this.settleCasinoRound();
    this.save();
    this.notify();
  }

  /** Clear a finished, acknowledged hand so a new one can begin. */
  acknowledgeBlackjack(): void {
    const r = this.state.casino.round;
    if (!r || r.state !== "completed") return;
    this.state.casino.round = null;
    this.save();
    this.notify();
  }

  /** Apply a completed round's payout to clean cash exactly once. */
  private settleCasinoRound(): void {
    const r = this.state.casino.round;
    if (!r || r.state !== "completed" || r.settled) return;
    this.state.cleanCash += r.payout ?? 0; // wager was reserved at deal
    r.settled = true;
  }

  /** On load: pay out any finished-but-unsettled hand; leave live hands to resume. */
  private recoverCasinoRound(): void {
    this.settleCasinoRound();
  }

  // MARK: Rex replies

  handleRexReply(
    action:
      | { type: "introAck"; label: string }
      | { type: "buy"; item: RexItemDef; label: string }
      | { type: "equip"; item: RexItemDef; label: string }
      | { type: "dismiss"; label: string },
    pitchID: string,
  ): void {
    const st = this.state;
    switch (action.type) {
      case "introAck":
        st.rexIntroAcknowledged = true;
        st.rexIntroReply = action.label;
        break;
      case "buy":
        st.rexPitchReplies[pitchID] = action.label;
        st.rexPitchFollowUp[pitchID] = this.buyItem(action.item)
          ? pick(REX.purchaseBarks)
          : REX.brokeBark;
        break;
      case "equip": {
        st.rexPitchReplies[pitchID] = action.label;
        const prev = action.item.slot === "wrist"
          ? this.equippedWristItem?.tier ?? 0
          : this.equippedGarageItem?.tier ?? 0;
        this.equipItem(action.item);
        st.rexPitchFollowUp[pitchID] = action.item.tier < prev
          ? REX.downgradeBark
          : rexIdleBarkFor(this);
        break;
      }
      case "dismiss":
        st.rexDismissedPitches.push(pitchID);
        st.rexPitchReplies[pitchID] = action.label;
        st.rexPitchFollowUp[pitchID] = FIXER.passBark;
        break;
    }
    this.notify();
  }

  // MARK: Tick loop

  /** Test/sim hook: advance the simulation without the wall-clock interval. */
  debugTick(dt: number): void {
    this.tick(dt);
  }

  private tick(dt: number): void {
    let changed = false;
    for (let i = 0; i < this.state.hustles.length; i++) {
      const s = this.state.hustles[i];
      if (s.unitsOwned <= 0 || this.isRaided(i)) continue;
      const cycle = this.cycleTime(i);

      if (s.ghostwriterHired) {
        const progress = s.cycleProgress + dt;
        const completed = Math.floor(progress / cycle);
        if (completed > 0) {
          const amount = completed * this.incomePerCycle(i);
          this.deposit(amount);
          // Only slow (≥1s) cycles pop particles — sub-second lines would spam.
          if (cycle >= 1) this.emit({ kind: "payout", hustleIndex: i, amount });
        }
        s.cycleProgress = progress - completed * cycle;
        changed = true;
      } else if (s.cycleRunning) {
        const progress = s.cycleProgress + dt;
        if (progress >= cycle) {
          const amount = this.incomePerCycle(i);
          this.deposit(amount);
          s.cycleRunning = false;
          s.cycleProgress = 0;
          this.emit({ kind: "payout", hustleIndex: i, amount });
        } else {
          s.cycleProgress = progress;
        }
        changed = true;
      }
    }

    // In lockup the family keeps the wash running at half speed.
    this.launder(dt, this.inPrison ? 0.5 : 1);
    this.shipmentTick();
    this.lawTick(dt);

    this.ticksSinceSave++;
    if (this.ticksSinceSave >= SAVE_EVERY_TICKS) {
      this.ticksSinceSave = 0;
      this.save();
    }

    // Always notify: countdown buffs and affordability states depend on time.
    void changed;
    this.notify();
  }

  private deposit(amount: number): void {
    this.state.cash += amount;
    this.state.lifetimeCash += amount;
  }

  // MARK: Persistence & offline earnings

  private grantOfflineEarnings(): void {
    const last = this.state.lastSaved;
    if (!last) return;
    const elapsed = Math.min((Date.now() - last) / 1000, 24 * 3600);
    if (elapsed <= 1) return;
    let earned = 0;
    this.state.hustles.forEach((s, i) => {
      if (s.ghostwriterHired) earned += (elapsed / this.cycleTime(i)) * this.incomePerCycle(i);
    });
    if (earned > 0) {
      this.deposit(earned);
      this.offlineEarnings = earned;
    }
    // The fronts kept washing while you were away.
    if (this.state.cash > 0) this.launder(elapsed);
  }

  private save(): void {
    this.state.lastSaved = Date.now();
    saveState(this.state);
  }
}

function now_minus(t: number | null): number {
  return t === null ? Infinity : Date.now() - t;
}

function rexIdleBarkFor(game: Game): string {
  const { equippedWristItem, equippedGarageItem } = game;
  const bestTier = Math.max(equippedWristItem?.tier ?? 0, equippedGarageItem?.tier ?? 0);
  if (bestTier >= 4) return REX.tier4Bark;
  if (equippedGarageItem) return pick(REX.idleCarBarks);
  if (equippedWristItem) return pick(REX.idleWatchBarks);
  return pick(REX.idleBarks);
}

export const game = Game.loadOrNew();

// Dev console access: window.game.state.cash += 1e6, etc.
if (typeof window !== "undefined" && import.meta.env.DEV) {
  (window as unknown as { game: Game }).game = game;
}
