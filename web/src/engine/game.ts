// Owns the game state and the 10 Hz tick loop — port of Game/Game.swift.
import * as F from "./formulas";
import {
  HUSTLES, REX, RexItemDef, rexItemByID, PersonaItemDef, personaItemByID,
  pick, PersonaSlot,
} from "./data";
import { GameState, newGame, loadState, saveState, applyRebrand } from "./state";

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
  | { kind: "rebranded"; clout: number };

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
    return (this.state.viralBuffUntil ?? 0) > Date.now();
  }

  get milleBuffActive(): boolean {
    return (this.state.milleBuffUntil ?? 0) > Date.now();
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
      if (s.unitsOwned <= 0 || !s.ghostwriterHired) return sum;
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

  get cloutOnRebrand(): number {
    return F.cloutGain(this.state.lifetimeCash, this.state.clout, this.cloutGainRateBonus);
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

  buyCosmetic(item: PersonaItemDef): boolean {
    if (this.ownsCosmetic(item) || this.state.cash < item.cost) return false;
    this.state.cash -= item.cost;
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
    if (this.ownsItem(item) || this.state.cash < item.cost) return false;
    this.state.cash -= item.cost;
    this.state.ownedItems.push(item.id);
    if (item.id === "daytona") this.state.daytonaPurchases += 1;
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
    const count = this.buyCount(index);
    const cost = F.bulkCost(HUSTLES[index].baseCost, this.state.hustles[index].unitsOwned, count);
    if (count <= 0 || this.state.cash < cost) return;
    const tierBefore = this.tier(index);
    const viralBefore = this.viralTier;
    this.state.cash -= cost;
    this.state.hustles[index].unitsOwned += count;

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
    const s = this.state.hustles[index];
    if (s.ghostwriterHired || this.state.cash < HUSTLES[index].ghostwriterCost) return;
    this.state.cash -= HUSTLES[index].ghostwriterCost;
    s.ghostwriterHired = true;
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
        st.rexPitchFollowUp[pitchID] = "Fair. The flex will still be there when the bag catches up.";
        break;
    }
    this.notify();
  }

  // MARK: Tick loop

  private tick(dt: number): void {
    let changed = false;
    for (let i = 0; i < this.state.hustles.length; i++) {
      const s = this.state.hustles[i];
      if (s.unitsOwned <= 0) continue;
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
  }

  private save(): void {
    this.state.lastSaved = Date.now();
    saveState(this.state);
  }
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
if (import.meta.env.DEV) {
  (window as unknown as { game: Game }).game = game;
}
