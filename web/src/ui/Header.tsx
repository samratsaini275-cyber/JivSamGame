import { useEffect, useRef, useState } from "react";
import { useGame } from "./hooks";
import { money } from "./format";
import { HUSTLES, baseLookByID } from "../engine/data";
import { game as gameInstance } from "../engine/game";
import { isMuted, setMuted } from "./sfx";
import { GAME, LABELS, PRESS, LAUNDER } from "../theme/content";
import { HeatBadge } from "./Law";
import { Ic, Portrait, PortraitName } from "./Icon";

const LOOK_PORTRAIT: Record<string, PortraitName> = {
  hoodie: "look-hoodie", bizcaz: "look-bizcaz", street: "look-street", gym: "look-gym",
};

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
          <Portrait name={LOOK_PORTRAIT[look.id] ?? "look-hoodie"} size={44} />
        </button>
        <div className="header-id">
          <div className="header-handle">"{game.state.handle || "the new face"}"</div>
          <div className="header-brand">{GAME.title} · {GAME.city}</div>
        </div>
        <HeatBadge onTap={onHeatTap} />
        <button
          className="sound-btn"
          aria-label={muted ? "Unmute" : "Mute"}
          onClick={() => { setMuted(!muted); setMutedState(!muted); }}
        >
          <Ic name={muted ? "sound-off" : "sound-on"} size={16} />
        </button>
        <div
          className="clout-chip"
          title={`${LABELS.respect} — level ${game.respectLevel}, ${game.respectProgress.into}/${game.respectProgress.needed} to next`}
        >
          <Ic name="respect" size={13} />
          <span>L{game.respectLevel}</span>
        </div>
      </div>

      <div className="ledger-plate">
        <div className="plate-col" title={LAUNDER.dirtyHint}>
          <div className="ledger-tag dirty"><Ic name="dirty" size={12} /> {LAUNDER.dirtyLabel}</div>
          <div className="cash-amount dirty" ref={cashRef}>{money(game.state.cash)}</div>
          <div className="plate-sub">{money(perSec)}{LABELS.perSec}</div>
        </div>
        <div className="plate-divider" aria-hidden>
          <span className="plate-rule" />
        </div>
        <div className="plate-col" title={LAUNDER.cleanHint}>
          <div className="ledger-tag clean"><Ic name="clean" size={12} /> {LAUNDER.cleanLabel}</div>
          <div className="cash-amount clean">{money(game.state.cleanCash)}</div>
          <div className="plate-sub">
            <span className={`press-tag ${game.viralBuffActive ? "buffed" : ""}`}>
              {PRESS.chip} ×{Math.pow(2, viral)}
            </span>
            {game.milleBuffActive && <span className="buff-chip">×2 INCOME</span>}
          </div>
        </div>
      </div>

      <div className="viral-track" title="Grow every hustle to make the news">
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
