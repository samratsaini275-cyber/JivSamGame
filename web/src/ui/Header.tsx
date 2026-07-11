import { useEffect, useRef, useState } from "react";
import { useGame } from "./hooks";
import { money } from "./format";
import { HUSTLES, baseLookByID } from "../engine/data";
import { game as gameInstance } from "../engine/game";
import { IconSound } from "./Icons";
import { isMuted, setMuted } from "./sfx";
import { GAME, LABELS, PRESS, LAUNDER, RESPECT } from "../theme/content";
import { HeatBadge } from "./Law";

export function Header({ onProfileTap, onHeatTap }: { onProfileTap: () => void; onHeatTap: () => void }) {
  const game = useGame();
  const look = baseLookByID(game.state.baseLook);
  const perSec = game.incomePerSecond;
  const viral = game.effectiveViralTier;
  const [muted, setMutedState] = useState(isMuted());
  const cashRef = useRef<HTMLDivElement>(null);

  // Bump the cash number when a payout lands.
  useEffect(() => {
    let last = 0;
    return gameInstance.onEvent((e) => {
      if (e.kind !== "payout") return;
      const now = performance.now();
      if (now - last < 450) return;
      last = now;
      const el = cashRef.current;
      if (!el) return;
      el.classList.remove("bump");
      void el.offsetWidth;
      el.classList.add("bump");
    });
  }, []);

  return (
    <header className="header">
      <div className="header-top">
        <button className="avatar-btn" onClick={onProfileTap} aria-label="The Boss">
          <span className="avatar-emoji">{look.emoji}</span>
          <span className="avatar-ring" />
        </button>
        <div className="header-id">
          <div className="header-handle">"{game.state.handle || "the new face"}"</div>
          <div className="header-brand">{GAME.title} · {GAME.year}</div>
        </div>
        <HeatBadge onTap={onHeatTap} />
        <button
          className="sound-btn"
          aria-label={muted ? "Unmute" : "Mute"}
          onClick={() => { setMuted(!muted); setMutedState(!muted); }}
        >
          <IconSound muted={muted} />
        </button>
        <div
          className="clout-chip"
          title={`${LABELS.respect} — ${game.respectProgress.into}/${game.respectProgress.needed} XP to the next level`}
        >
          <span>{RESPECT.levelChip(game.respectLevel)}</span>
        </div>
      </div>

      <div className="ledger-plate">
        <div className="plate-col" title={LAUNDER.dirtyHint}>
          <div className="ledger-tag dirty">{LAUNDER.dirtyLabel}</div>
          <div className="cash-amount dirty" ref={cashRef}>{money(game.state.cash)}</div>
          <div className="plate-sub">{money(perSec)}{LABELS.perSec}</div>
        </div>
        <div className="plate-divider" aria-hidden>
          <span className="plate-rule" />
          <span className="plate-diamond">◆</span>
          <span className="plate-rule" />
        </div>
        <div className="plate-col" title={LAUNDER.cleanHint}>
          <div className="ledger-tag clean">{LAUNDER.cleanLabel}</div>
          <div className="cash-amount clean">{money(game.state.cleanCash)}</div>
          <div className="plate-sub">
            <span className={`press-tag ${game.viralBuffActive ? "buffed" : ""}`}>
              {PRESS.chip} ×{Math.pow(2, viral)}
            </span>
            {game.milleBuffActive && <span className="buff-chip">×2 INCOME</span>}
          </div>
        </div>
      </div>

      <div className="viral-track" title="Grow every racket to make the front page">
        <span className="viral-track-label">{PRESS.tracker}</span>
        <div className="viral-bar">
          <div
            className="viral-bar-fill"
            style={{ width: `${(game.hustlesAtNextViralTier / HUSTLES.length) * 100}%` }}
          />
        </div>
        <span className="viral-count">{game.hustlesAtNextViralTier}/{HUSTLES.length}</span>
      </div>
    </header>
  );
}
