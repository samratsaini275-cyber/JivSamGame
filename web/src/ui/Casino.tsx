// The Gilded Ace — casino tab. Locked entrance (buy the deed) → blackjack table.
// Presentation only; all rules, money, and persistence live in the engine/Game.
import { useEffect, useRef, useState } from "react";
import { useGame } from "./hooks";
import { CASINO_COST, CASINO_BIG_BET_FRACTION } from "../engine/game";
import { handScore, cardValue, wagerPresets } from "../engine/blackjack";
import { CASINO } from "../theme/content";
import { money } from "./format";
import { sfx } from "./sfx";
import { Ic } from "./Icon";
import { PlayingCard } from "./PlayingCard";

export function CasinoScreen() {
  const game = useGame();
  const [showRules, setShowRules] = useState(false);
  return game.casinoUnlocked
    ? <BlackjackTable onRules={() => setShowRules(true)} rulesOpen={showRules} onCloseRules={() => setShowRules(false)} />
    : <CasinoEntrance />;
}

// ---------------------------------------------------------------------------
// Locked entrance — a dramatic "buy the deed" moment.
// ---------------------------------------------------------------------------

function CasinoEntrance() {
  const game = useGame();
  const [confirming, setConfirming] = useState(false);
  const afford = game.canUnlockCasino;

  return (
    <div className="screen casino-entrance">
      <div className="entrance-marquee">
        <div className="marquee-bulbs" aria-hidden>
          {Array.from({ length: 11 }).map((_, i) => <span key={i} style={{ animationDelay: `${i * 90}ms` }} />)}
        </div>
        <div className="entrance-kicker">{CASINO.lockedKicker}</div>
        <div className="entrance-title">{CASINO.lockedTitle}</div>
        <div className="entrance-sub">{CASINO.sub}</div>
      </div>

      <div className="entrance-body">
        <p className="entrance-blurb">{CASINO.lockedBlurb}</p>
        <div className="entrance-feature">
          <span className="feature-suit"><Ic name="star" size={16} /></span>
          {CASINO.lockedFeature}
        </div>
      </div>

      <div className="entrance-price">
        <span className="price-tag"><Ic name="clean" size={22} /> {money(CASINO_COST)}</span>
        <span className="price-note">clean cash · one-time</span>
      </div>

      {afford ? (
        <button className="btn-cta entrance-cta" onClick={() => setConfirming(true)}>
          {CASINO.unlockCta}
        </button>
      ) : (
        <>
          <button className="btn-cta disabled" disabled>{CASINO.unlockCta}</button>
          <div className="entrance-cantafford">{CASINO.cantAfford}</div>
        </>
      )}

      <div className="casino-notice">{CASINO.notice}</div>

      {confirming && (
        <ConfirmDialog
          text={CASINO.unlockConfirm}
          confirmLabel={CASINO.unlockConfirmYes}
          onConfirm={() => { if (game.unlockCasino()) sfx.rebrand(); setConfirming(false); }}
          onCancel={() => setConfirming(false)}
        />
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Blackjack table
// ---------------------------------------------------------------------------

function BlackjackTable({ onRules, rulesOpen, onCloseRules }: {
  onRules: () => void; rulesOpen: boolean; onCloseRules: () => void;
}) {
  const game = useGame();
  const round = game.casinoRound;

  return (
    <div className="screen casino-table">
      <div className="casino-topbar">
        <div className="casino-brand">
          <span className="casino-name">{CASINO.name}</span>
          <span className="casino-chips"><Ic name="clean" size={14} /> {money(game.state.cleanCash)}</span>
        </div>
        <button className="rules-btn" onClick={onRules} aria-label={CASINO.helpButton}>
          <Ic name="writ" size={16} /> {CASINO.helpButton}
        </button>
      </div>

      <div className="felt">
        {round ? <Hand round={round} /> : <EmptyFelt />}
      </div>

      {round && round.state !== "completed"
        ? <PlayControls />
        : <BetControls key={round ? "post" : "bet"} />}

      <div className="casino-notice small">{CASINO.notice}</div>

      {rulesOpen && <RulesModal onClose={onCloseRules} />}
    </div>
  );
}

function EmptyFelt() {
  return (
    <div className="felt-empty">
      <div className="felt-crest" aria-hidden><Ic name="star" size={30} /></div>
      <div className="felt-hint">Place your bet to be dealt in.</div>
    </div>
  );
}

function Hand({ round }: { round: NonNullable<ReturnType<typeof useGame>["casinoRound"]> }) {
  const done = round.state === "completed";
  // During the player's turn the dealer's hole card (index 1) stays hidden.
  const dealerScore = done ? handScore(round.dealer).total : cardValue(round.dealer[0]);
  const playerScore = handScore(round.player);

  return (
    <>
      <div className="hand-area dealer">
        <div className="hand-head">
          <span className="hand-label">{CASINO.dealerLabel}</span>
          <span className="hand-total">{done ? dealerScore : `${dealerScore}+`}</span>
        </div>
        <div className="card-row">
          {round.dealer.map((c, i) => (
            <PlayingCard key={i} card={c} faceDown={!done && i === 1} index={i} />
          ))}
        </div>
      </div>

      <div className="hand-divider" aria-hidden><span /><span className="hd-diamond">◆</span><span /></div>

      <div className="hand-area player">
        <div className="hand-head">
          <span className="hand-label">{CASINO.youLabel}</span>
          <span className={`hand-total ${playerScore.total > 21 ? "bust" : ""}`}>
            {playerScore.total}{playerScore.soft && playerScore.total <= 21 ? ` (${CASINO.soft})` : ""}
          </span>
        </div>
        <div className="card-row">
          {round.player.map((c, i) => <PlayingCard key={i} card={c} index={i} />)}
        </div>
      </div>

      {done && <ResultBanner round={round} />}
    </>
  );
}

function ResultBanner({ round }: { round: NonNullable<ReturnType<typeof useGame>["casinoRound"]> }) {
  const profit = (round.payout ?? 0) - round.wager;
  let title: string = CASINO.resultLose;
  let sub = "";
  let tone: "win" | "lose" | "push" = "lose";
  if (round.outcome === "blackjack") { title = CASINO.resultBlackjack; sub = CASINO.resultBlackjackSub; tone = "win"; }
  else if (round.outcome === "win") { title = round.reason === "dealer_bust" ? CASINO.resultDealerBust : CASINO.resultWin; tone = "win"; }
  else if (round.outcome === "push") { title = CASINO.resultPush; sub = CASINO.resultPushSub; tone = "push"; }
  else if (round.reason === "player_bust") { title = CASINO.resultBust; }

  // Fire the outcome sound once when the banner mounts.
  useEffect(() => {
    if (round.outcome === "blackjack") sfx.blackjack();
    else if (round.outcome === "win") sfx.win();
    else if (round.outcome === "push") sfx.push();
    else sfx.lose();
  }, []);

  return (
    <div className={`result-banner ${tone}`}>
      <div className="result-title">{title}</div>
      {sub && <div className="result-sub">{sub}</div>}
      {tone !== "push" && (
        <div className="result-amount">
          {profit >= 0 ? CASINO.wonAmount(money(profit)) : CASINO.lostAmount(money(round.wager))}
        </div>
      )}
    </div>
  );
}

function PlayControls() {
  const game = useGame();
  return (
    <div className="play-controls">
      <button className="btn-play hit" onClick={() => { game.blackjackHit(); sfx.card(); }}>
        {CASINO.hit}
      </button>
      <button className="btn-play stand" onClick={() => { game.blackjackStand(); sfx.flip(); }}>
        {CASINO.stand}
      </button>
    </div>
  );
}

function BetControls() {
  const game = useGame();
  const round = game.casinoRound;
  const finished = round?.state === "completed";
  const balance = game.state.cleanCash;
  const [bet, setBet] = useState(() => Math.max(1, Math.floor(balance * 0.05)));
  const [pending, setPending] = useState<number | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Keep the bet within a valid range as the balance changes.
  const max = game.maxWager;
  const clamped = Math.min(Math.max(1, bet), Math.max(1, max));
  const check = game.checkWager(clamped);
  const canDeal = check.ok && max >= 1;
  const potential = clamped * 2;

  if (finished) {
    return (
      <div className="bet-controls">
        <button
          className="btn-cta"
          onClick={() => { game.acknowledgeBlackjack(); }}
        >
          {CASINO.newHand}
        </button>
      </div>
    );
  }

  const doDeal = (amount: number) => {
    const res = game.startBlackjack(amount);
    if (res.ok) sfx.chip();
  };

  const attemptDeal = () => {
    if (!canDeal) return;
    // Confirm unusually large wagers to prevent accidental loss.
    if (clamped === max || clamped > balance * CASINO_BIG_BET_FRACTION) {
      setPending(clamped);
    } else {
      doDeal(clamped);
    }
  };

  const presets = wagerPresets(balance);

  return (
    <div className="bet-controls">
      <div className="bet-readout">
        <div className="bet-figure">
          <span className="bet-cap">{CASINO.betLabel}</span>
          <span className="bet-value"><Ic name="clean" size={15} /> {money(clamped)}</span>
        </div>
        <div className="bet-figure right">
          <span className="bet-cap">{CASINO.payoutLabel}</span>
          <span className="bet-value win">{money(potential)}</span>
        </div>
      </div>

      <div className="chip-row">
        {presets.map((p) => (
          <button
            key={p.label}
            className={`chip ${clamped === p.amount ? "active" : ""} ${p.label === "MAX" ? "max" : ""}`}
            onClick={() => { setBet(p.amount); sfx.post(); }}
            disabled={p.amount < 1 || p.amount > max}
          >
            {p.label}
          </button>
        ))}
      </div>

      <div className="bet-input-row">
        <span className="bet-input-icon"><Ic name="clean" size={15} /></span>
        <input
          ref={inputRef}
          className="bet-input"
          type="number"
          inputMode="numeric"
          min={1}
          max={max}
          value={Number.isFinite(bet) ? bet : ""}
          onChange={(e) => {
            const v = Math.floor(Number(e.target.value));
            setBet(Number.isFinite(v) ? v : 0);
          }}
          aria-label={CASINO.customBet}
        />
        <button className={`btn-deal ${canDeal ? "" : "disabled"}`} disabled={!canDeal} onClick={attemptDeal}>
          {CASINO.deal}
        </button>
      </div>

      {pending !== null && (
        <ConfirmDialog
          text={CASINO.bigBetConfirm(money(pending))}
          confirmLabel={CASINO.bigBetYes}
          onConfirm={() => { doDeal(pending); setPending(null); }}
          onCancel={() => setPending(null)}
        />
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Small dialogs
// ---------------------------------------------------------------------------

function ConfirmDialog({ text, confirmLabel, onConfirm, onCancel }: {
  text: string; confirmLabel: string; onConfirm: () => void; onCancel: () => void;
}) {
  return (
    <div className="modal-backdrop" onClick={onCancel}>
      <div className="confirm-card" onClick={(e) => e.stopPropagation()}>
        <div className="confirm-text">{text}</div>
        <div className="confirm-actions">
          <button className="btn-mini" onClick={onCancel}>{CASINO.cancel}</button>
          <button className="btn-mini buy" onClick={onConfirm}>{confirmLabel}</button>
        </div>
      </div>
    </div>
  );
}

function RulesModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="rules-card" onClick={(e) => e.stopPropagation()}>
        <div className="rules-title">{CASINO.rulesTitle}</div>
        <ul className="rules-list">
          {CASINO.rules.map((r) => (
            <li key={r}><span className="rules-diamond">◆</span>{r}</li>
          ))}
        </ul>
        <div className="casino-notice">{CASINO.notice}</div>
        <button className="btn-cta" onClick={onClose}>{CASINO.rulesClose}</button>
      </div>
    </div>
  );
}
