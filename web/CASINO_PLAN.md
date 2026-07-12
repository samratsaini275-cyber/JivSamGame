# The Gilded Ace — Mini Casino (blackjack) implementation plan

## Economy integration (decisions)
- **Currency: clean cash** (`state.cleanCash`). Rationale: it's stable (never
  drained by laundering, unlike dirty cash), it's the premium "real money," and
  $1B clean is a genuine late-game milestone that fits "premium late-game."
- **Isolation:** winnings are added *directly* to `cleanCash`, never through
  `depositClean()`, so gambling does **not** inflate `lifetimeClean` / Family
  Fortune / Respect / prestige. Losses subtract `cleanCash`. Gambling is a pure
  clean-cash sink/source, walled off from progression metrics.
- **Unlock cost: exactly $1,000,000,000 clean.** Deducted once, guarded against
  double-spend. `casino.unlocked` **survives prestige** (permanent, like
  districts). Prestige clears any active round (cash is being zeroed anyway).

## Access
A **6th "Casino" tab** (locked-teaser pattern, same as the DMs tab). Tapping it
always opens the full-screen casino; internally it shows the locked entrance
(with the $1B unlock) or the blackjack table.

## Blackjack rules (traditional)
- Fresh, Fisher–Yates–shuffled 52-card deck **per round** (single-deck shoe,
  re-created each round). Unbiased; `Math.random`. Remaining deck is persisted so
  a mid-round reload draws the *same* cards (no refresh-for-better-cards exploit).
- 2 cards each; both player cards up, dealer shows one, hole card hidden.
- Number cards = pip; face = 10; ace = 1 or 11 (best valid total).
- Two-card 21 = natural blackjack (3:2). Simultaneous blackjack = push.
- Player Hit / Stand. Dealer hits to 17, **stands on all 17 incl. soft 17**.
- Player > 21 busts (immediate loss). Compare valid totals after dealer plays.

## Payouts & rounding
- Loss: −wager. Push: wager returned. Win (incl. dealer bust): +1:1 profit.
- Natural blackjack: **+3:2 profit, floored to whole dollars**
  (`profit = floor(wager * 3 / 2)`).
- Wagers are whole dollars (input floored, min $1).

## Round state machine
`betting → dealing → playerTurn → (dealerTurn) → settling → completed`.
Dealing/dealer/settling resolve synchronously in the engine; the UI animates the
reveal from the already-resolved, already-settled round. Invalid actions are
impossible outside `playerTurn`. A finished round must be **acknowledged**
("New Hand") before another can start.

## Wager safety
`validateWager(raw, balance)` rejects non-finite, NaN, Infinity, < 1, fractional
(floored), and > balance. Wager is **reserved** (deducted from cleanCash) at deal
so it can't be double-spent. Presets: 1/5/10/25% + Max, each floored, ≥ $1,
capped at balance. Max and unusually large (> 25% of balance) wagers confirm.

## Persistence & interruption safety
- `state.casino = { unlocked: boolean, round: RoundSnapshot | null }`.
- The full round (id, wager, remaining deck, hands, state, result, `settled`,
  `payout`) is saved on every mutation.
- **Idempotent settlement:** `settled` flag guards the single cleanCash payout.
  Reserve-at-deal + settle-once means no refresh/double-tap/rerender can refund
  or deduct twice.
- **Recovery on load:** a non-completed round is restored **exactly** (same deck
  → same future cards) so play resumes. A terminal-but-unsettled round is settled
  idempotently. A completed round shows its result awaiting acknowledgement.
- **Unique round id** per wager (`r_<time>_<rand>`).

## Save migration
Additive: old saves lack `casino`; `loadState`'s `{...newGame(), ...parsed}` merge
supplies the default `{unlocked:false, round:null}`, and `migrate()` sets it
explicitly. saveVersion stays 2 (backward-compatible additive field). Tested.

## Files
- `engine/blackjack.ts` (pure engine) + `engine/__tests__/blackjack.test.ts`
- `engine/state.ts` (+casino field, migrate), `engine/game.ts` (+casino methods)
- `theme/content.ts` (+CASINO copy), `ui/Casino.tsx`, `ui/sfx.ts` (+card/chip/win),
  `App.tsx` (+tab), `styles.css`

## App Store / responsible-play
Simulated gambling with **fictional in-game money only** — no real money,
deposits, cash-out, crypto, or purchasable chips. A persistent "SIMULATED
GAMBLING · FICTIONAL MONEY, NO REAL-WORLD VALUE" label + a rules/help panel.
Transparent odds; outcomes never adapt to player state. (Simulated gambling
typically warrants a 17+ rating.)
