import { describe, it, expect } from "vitest";
import {
  Card, Rank, Suit, cardValue, freshDeck, shuffle, handScore, handTotal, isBust,
  isBlackjack, dealerShouldHit, validateWager, wagerPresets, payoutFor,
  startRound, playerHit, playerStand, isComplete, newRoundId,
} from "../blackjack";

const C = (rank: Rank, suit: Suit = "spades"): Card => ({ rank, suit });

/** Build a deck that deals a scripted sequence. startRound draws from the END,
 *  alternating player, dealer, player, dealer — then hits draw from the end. */
function deckDealing(order: Card[]): Card[] {
  // startRound pops from the end, so reverse the intended deal order.
  return order.slice().reverse();
}

describe("card values & scoring", () => {
  it("number cards use pips, faces are 10, ace is 11 by default", () => {
    expect(cardValue(C("2"))).toBe(2);
    expect(cardValue(C("10"))).toBe(10);
    expect(cardValue(C("K"))).toBe(10);
    expect(cardValue(C("Q"))).toBe(10);
    expect(cardValue(C("A"))).toBe(11);
  });

  it("a fresh deck has 52 unique cards", () => {
    const d = freshDeck();
    expect(d).toHaveLength(52);
    expect(new Set(d.map((c) => `${c.rank}${c.suit}`)).size).toBe(52);
  });

  it("scores a hard total", () => {
    expect(handScore([C("10"), C("7")])).toEqual({ total: 17, soft: false });
  });

  it("counts a single ace as 11 when it fits (soft)", () => {
    expect(handScore([C("A"), C("6")])).toEqual({ total: 17, soft: true });
  });

  it("demotes the ace to 1 to avoid busting (hard)", () => {
    expect(handScore([C("A"), C("6"), C("10")])).toEqual({ total: 17, soft: false });
  });

  it("handles multiple aces, keeping at most one as 11", () => {
    expect(handScore([C("A"), C("A")])).toEqual({ total: 12, soft: true });
    expect(handScore([C("A"), C("A"), C("9")])).toEqual({ total: 21, soft: true });
    expect(handScore([C("A"), C("A"), C("9"), C("K")])).toEqual({ total: 21, soft: false });
    expect(handScore([C("A"), C("A"), C("A"), C("8")])).toEqual({ total: 21, soft: true });
  });

  it("detects bust and blackjack", () => {
    expect(isBust([C("10"), C("10"), C("5")])).toBe(true);
    expect(isBlackjack([C("A"), C("K")])).toBe(true);
    expect(isBlackjack([C("A"), C("9"), C("A")])).toBe(false); // 21 but 3 cards
    expect(isBlackjack([C("10"), C("6"), C("5")])).toBe(false);
  });
});

describe("dealer behaviour — stands on all 17 incl. soft 17", () => {
  it("hits below 17", () => {
    expect(dealerShouldHit([C("10"), C("6")])).toBe(true); // 16
  });
  it("stands on hard 17", () => {
    expect(dealerShouldHit([C("10"), C("7")])).toBe(false);
  });
  it("stands on soft 17 (A+6)", () => {
    expect(dealerShouldHit([C("A"), C("6")])).toBe(false);
  });
});

describe("wager validation", () => {
  it("accepts a whole-dollar wager within balance", () => {
    expect(validateWager(100, 1000)).toEqual({ ok: true, wager: 100 });
  });
  it("floors fractional wagers", () => {
    expect(validateWager(99.9, 1000)).toEqual({ ok: true, wager: 99 });
  });
  it("rejects zero, negative, NaN, Infinity", () => {
    expect(validateWager(0, 1000).ok).toBe(false);
    expect(validateWager(-5, 1000).ok).toBe(false);
    expect(validateWager(NaN, 1000).ok).toBe(false);
    expect(validateWager(Infinity, 1000).ok).toBe(false);
    expect(validateWager(-Infinity, 1000).ok).toBe(false);
  });
  it("rejects wagers above the balance", () => {
    expect(validateWager(1001, 1000)).toEqual({ ok: false, error: "insufficient" });
  });
  it("allows exactly the balance (max bet)", () => {
    expect(validateWager(1000, 1000)).toEqual({ ok: true, wager: 1000 });
  });
  it("handles very large balances without overflow", () => {
    const big = 1e15;
    expect(validateWager(big, big)).toEqual({ ok: true, wager: big });
  });
  it("presets never exceed balance and are ≥ 1", () => {
    const p = wagerPresets(1000);
    expect(p.map((x) => x.amount)).toEqual([10, 50, 100, 250, 1000]);
    for (const x of wagerPresets(3)) {
      expect(x.amount).toBeGreaterThanOrEqual(1);
      expect(x.amount).toBeLessThanOrEqual(3);
    }
  });
});

describe("payout & rounding", () => {
  it("pays 1:1 for a win, returns wager for push, nothing for a loss", () => {
    expect(payoutFor("win", 100)).toBe(200);
    expect(payoutFor("push", 100)).toBe(100);
    expect(payoutFor("lose", 100)).toBe(0);
  });
  it("pays 3:2 for a natural, floored on odd wagers", () => {
    expect(payoutFor("blackjack", 100)).toBe(250); // 100 + 150
    expect(payoutFor("blackjack", 25)).toBe(62); // 25 + floor(37.5)=37
    expect(payoutFor("blackjack", 3)).toBe(7); // 3 + floor(4.5)=4
    expect(payoutFor("blackjack", 1)).toBe(2); // 1 + floor(1.5)=1
  });
});

describe("round flow", () => {
  it("deals two cards each; both player cards, both dealer cards present", () => {
    const deck = deckDealing([C("10", "hearts"), C("9", "clubs"), C("7", "hearts"), C("8", "clubs")]);
    const r = startRound(100, deck, "t1");
    expect(r.player).toHaveLength(2);
    expect(r.dealer).toHaveLength(2);
    expect(r.state).toBe("playerTurn");
    expect(handTotal(r.player)).toBe(17); // 10 + 7
    expect(handTotal(r.dealer)).toBe(17); // 9 + 8
  });

  it("player natural blackjack pays 3:2 immediately", () => {
    const deck = deckDealing([C("A"), C("2"), C("K"), C("5")]); // player A+K=21, dealer 2+5
    const r = startRound(100, deck, "t2");
    expect(isComplete(r)).toBe(true);
    expect(r.outcome).toBe("blackjack");
    expect(r.reason).toBe("player_blackjack");
    expect(r.payout).toBe(250);
  });

  it("dealer natural blackjack loses for the player", () => {
    const deck = deckDealing([C("9"), C("A"), C("8"), C("K")]); // player 9+8=17, dealer A+K=21
    const r = startRound(100, deck, "t3");
    expect(r.outcome).toBe("lose");
    expect(r.reason).toBe("dealer_blackjack");
    expect(r.payout).toBe(0);
  });

  it("simultaneous blackjack is a push", () => {
    const deck = deckDealing([C("A"), C("A"), C("K"), C("Q")]); // both 21
    const r = startRound(100, deck, "t4");
    expect(r.outcome).toBe("push");
    expect(r.reason).toBe("push");
    expect(r.payout).toBe(100);
  });

  it("player bust on hit loses immediately", () => {
    // player 10+7=17, dealer 9+8; next draw (end of remaining) is a 10 → 27 bust
    const deck = deckDealing([C("10"), C("9"), C("7"), C("8"), C("10", "diamonds")]);
    let r = startRound(50, deck, "t5");
    r = playerHit(r);
    expect(isBust(r.player)).toBe(true);
    expect(r.outcome).toBe("lose");
    expect(r.reason).toBe("player_bust");
  });

  it("player wins with a higher total after standing", () => {
    // player 10+9=19, dealer 10+7=17 → dealer stands, player higher
    const deck = deckDealing([C("10"), C("10", "clubs"), C("9"), C("7")]);
    let r = startRound(100, deck, "t6");
    r = playerStand(r);
    expect(r.outcome).toBe("win");
    expect(r.reason).toBe("higher");
    expect(r.payout).toBe(200);
  });

  it("dealer draws to 17 then busts → player wins", () => {
    // player 10+8=18. dealer 10+6=16, must hit; next card 10 → 26 bust.
    const deck = deckDealing([C("10"), C("10", "clubs"), C("8"), C("6"), C("10", "diamonds")]);
    let r = startRound(100, deck, "t7");
    r = playerStand(r);
    expect(handTotal(r.dealer)).toBeGreaterThan(21);
    expect(r.outcome).toBe("win");
    expect(r.reason).toBe("dealer_bust");
  });

  it("dealer higher total → player loses", () => {
    // player 10+8=18, dealer 10+10=20
    const deck = deckDealing([C("10"), C("10", "clubs"), C("8"), C("10", "diamonds")]);
    let r = startRound(100, deck, "t8");
    r = playerStand(r);
    expect(r.outcome).toBe("lose");
    expect(r.reason).toBe("lower");
  });

  it("equal totals → push", () => {
    const deck = deckDealing([C("10"), C("10", "clubs"), C("8"), C("8", "diamonds")]);
    let r = startRound(100, deck, "t9");
    r = playerStand(r);
    expect(r.outcome).toBe("push");
    expect(r.reason).toBe("equal");
  });

  it("dealer stands on soft 17 (does not draw)", () => {
    // player 10+9=19, dealer A+6 = soft 17 → must stand, player wins
    const deck = deckDealing([C("10"), C("A"), C("9"), C("6")]);
    let r = startRound(100, deck, "t10");
    r = playerStand(r);
    expect(r.dealer).toHaveLength(2); // did not hit soft 17
    expect(r.outcome).toBe("win");
  });
});

describe("state guards — no actions after a round ends", () => {
  it("ignores hit/stand once completed", () => {
    const deck = deckDealing([C("A"), C("2"), C("K"), C("5")]); // player natural
    const r = startRound(100, deck, "t11");
    const before = JSON.stringify(r);
    playerHit(r);
    playerStand(r);
    expect(JSON.stringify(r)).toBe(before);
  });
});

describe("shuffle & ids", () => {
  it("shuffle preserves the multiset of cards", () => {
    const d = shuffle(freshDeck(), () => 0.42);
    expect(d).toHaveLength(52);
    expect(new Set(d.map((c) => `${c.rank}${c.suit}`)).size).toBe(52);
  });
  it("round ids are unique", () => {
    const ids = new Set(Array.from({ length: 1000 }, () => newRoundId()));
    expect(ids.size).toBe(1000);
  });
});
