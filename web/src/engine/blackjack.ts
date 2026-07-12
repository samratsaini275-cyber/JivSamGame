// ============================================================================
// Blackjack engine — pure, deterministic given its RNG, zero UI/persistence.
// Everything the casino needs to be correct and testable lives here.
// ============================================================================

export type Suit = "spades" | "hearts" | "diamonds" | "clubs";
export type Rank = "A" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "J" | "Q" | "K";

export interface Card {
  rank: Rank;
  suit: Suit;
}

export const SUITS: Suit[] = ["spades", "hearts", "diamonds", "clubs"];
export const RANKS: Rank[] = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];

/** Printed value; ace is scored separately (1 or 11). */
export function cardValue(card: Card): number {
  if (card.rank === "A") return 11;
  if (card.rank === "J" || card.rank === "Q" || card.rank === "K") return 10;
  return parseInt(card.rank, 10);
}

/** A fresh ordered 52-card deck. */
export function freshDeck(): Card[] {
  const deck: Card[] = [];
  for (const suit of SUITS) for (const rank of RANKS) deck.push({ rank, suit });
  return deck;
}

/** Unbiased Fisher–Yates shuffle. `rng` defaults to Math.random. */
export function shuffle(deck: Card[], rng: () => number = Math.random): Card[] {
  const out = deck.slice();
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

export function shuffledDeck(rng: () => number = Math.random): Card[] {
  return shuffle(freshDeck(), rng);
}

/** Best valid total (aces demoted from 11→1 as needed) + whether it's soft. */
export function handScore(cards: Card[]): { total: number; soft: boolean } {
  let total = 0;
  let aces = 0;
  for (const c of cards) {
    total += cardValue(c);
    if (c.rank === "A") aces++;
  }
  // Demote aces (11→1, i.e. subtract 10) while busting and aces remain.
  let softAces = aces;
  while (total > 21 && softAces > 0) {
    total -= 10;
    softAces--;
  }
  // Soft = an ace is still counted as 11.
  return { total, soft: softAces > 0 };
}

export function handTotal(cards: Card[]): number {
  return handScore(cards).total;
}

export function isBust(cards: Card[]): boolean {
  return handTotal(cards) > 21;
}

/** A natural blackjack: exactly two cards totalling 21. */
export function isBlackjack(cards: Card[]): boolean {
  return cards.length === 2 && handTotal(cards) === 21;
}

/** Dealer rule: hit below 17, STAND on all 17s (including soft 17). */
export function dealerShouldHit(cards: Card[]): boolean {
  return handTotal(cards) < 17;
}

// ---------------------------------------------------------------------------
// Wager validation
// ---------------------------------------------------------------------------

export type WagerCheck =
  | { ok: true; wager: number }
  | { ok: false; error: "invalid" | "min" | "insufficient" };

/** Whole-dollar, positive, ≤ balance, finite. Fractions are floored. */
export function validateWager(raw: number, balance: number): WagerCheck {
  if (typeof raw !== "number" || !Number.isFinite(raw)) return { ok: false, error: "invalid" };
  const wager = Math.floor(raw);
  if (!Number.isFinite(wager) || wager < 1) return { ok: false, error: "min" };
  const max = Math.floor(balance);
  if (!Number.isFinite(max) || wager > max) return { ok: false, error: "insufficient" };
  return { ok: true, wager };
}

/** Preset wager amounts from the balance: 1/5/10/25% and Max, floored, ≥ 1. */
export function wagerPresets(balance: number): { label: string; amount: number; pct?: number }[] {
  const max = Math.max(0, Math.floor(balance));
  const pct = (p: number) => Math.max(1, Math.floor(max * p));
  return [
    { label: "1%", amount: pct(0.01), pct: 0.01 },
    { label: "5%", amount: pct(0.05), pct: 0.05 },
    { label: "10%", amount: pct(0.1), pct: 0.1 },
    { label: "25%", amount: pct(0.25), pct: 0.25 },
    { label: "MAX", amount: max },
  ];
}

// ---------------------------------------------------------------------------
// Round model & state machine
// ---------------------------------------------------------------------------

export type RoundState = "playerTurn" | "dealerTurn" | "settling" | "completed";

/** Outcome that determines the payout. */
export type Outcome = "blackjack" | "win" | "push" | "lose";

/** Fine-grained reason, for display. */
export type Reason =
  | "player_blackjack"
  | "dealer_blackjack"
  | "push"
  | "player_bust"
  | "dealer_bust"
  | "higher"
  | "lower"
  | "equal";

export interface Round {
  id: string;
  wager: number;
  /** Remaining, ordered draw pile. Cards are dealt from the end (`pop`). */
  deck: Card[];
  player: Card[];
  dealer: Card[];
  state: RoundState;
  /** Set once the round reaches `completed`. */
  outcome: Outcome | null;
  reason: Reason | null;
  /** Amount returned to the balance on settlement (0 for a loss). */
  payout: number | null;
  /** Idempotency guard — the payout is applied to the balance exactly once. */
  settled: boolean;
}

let idCounter = 0;
export function newRoundId(rng: () => number = Math.random): string {
  idCounter = (idCounter + 1) % 1_000_000;
  return `r_${Date.now().toString(36)}_${Math.floor(rng() * 1e9).toString(36)}_${idCounter}`;
}

function draw(round: Round): Card {
  if (round.deck.length === 0) {
    // Defensive: a single hand can never exhaust 52 cards, but never crash.
    round.deck = shuffledDeck();
  }
  return round.deck.pop()!;
}

/** Net amount to return to the balance for an outcome (wager already reserved). */
export function payoutFor(outcome: Outcome, wager: number): number {
  switch (outcome) {
    case "blackjack": return wager + Math.floor((wager * 3) / 2); // original + 3:2, floored
    case "win": return wager * 2; // original + 1:1
    case "push": return wager; // original back
    case "lose": return 0;
  }
}

/** Resolve to a terminal state, recording outcome/reason/payout. Idempotent-safe. */
function finish(round: Round, outcome: Outcome, reason: Reason): void {
  round.state = "completed";
  round.outcome = outcome;
  round.reason = reason;
  round.payout = payoutFor(outcome, round.wager);
}

/**
 * Begin a round: deal two cards each and resolve any naturals immediately.
 * `wager` must already be validated & reserved by the caller.
 */
export function startRound(wager: number, deck: Card[], id: string): Round {
  const round: Round = {
    id,
    wager,
    deck: deck.slice(),
    player: [],
    dealer: [],
    state: "playerTurn",
    outcome: null,
    reason: null,
    payout: null,
    settled: false,
  };
  round.player.push(draw(round));
  round.dealer.push(draw(round));
  round.player.push(draw(round));
  round.dealer.push(draw(round));

  const pBJ = isBlackjack(round.player);
  const dBJ = isBlackjack(round.dealer);
  if (pBJ || dBJ) {
    round.state = "settling";
    if (pBJ && dBJ) finish(round, "push", "push");
    else if (pBJ) finish(round, "blackjack", "player_blackjack");
    else finish(round, "lose", "dealer_blackjack");
  }
  return round;
}

/** Player hits. Only valid during playerTurn. Auto-resolves a bust. */
export function playerHit(round: Round): Round {
  if (round.state !== "playerTurn") return round;
  round.player.push(draw(round));
  if (isBust(round.player)) {
    round.state = "settling";
    finish(round, "lose", "player_bust");
  }
  return round;
}

/** Player stands → dealer plays out → settle. Only valid during playerTurn. */
export function playerStand(round: Round): Round {
  if (round.state !== "playerTurn") return round;
  round.state = "dealerTurn";
  while (dealerShouldHit(round.dealer)) {
    round.dealer.push(draw(round));
  }
  round.state = "settling";
  resolveShowdown(round);
  return round;
}

/** Compare final totals (neither is a natural at this point). */
function resolveShowdown(round: Round): void {
  const p = handTotal(round.player);
  const d = handTotal(round.dealer);
  if (d > 21) { finish(round, "win", "dealer_bust"); return; }
  if (p > d) { finish(round, "win", "higher"); return; }
  if (p < d) { finish(round, "lose", "lower"); return; }
  finish(round, "push", "equal");
}

/** True once the round is over and the payout is known. */
export function isComplete(round: Round): boolean {
  return round.state === "completed";
}
