import { useEffect, useRef, useState } from "react";
import { useGame } from "./hooks";
import { money } from "./format";
import { HUSTLES, baseLookByID } from "../engine/data";
import { game as gameInstance } from "../engine/game";
import { IconSound } from "./Icons";
import { isMuted, setMuted } from "./sfx";

export function Header({ onProfileTap }: { onProfileTap: () => void }) {
  const game = useGame();
  const look = baseLookByID(game.state.baseLook);
  const perSec = game.incomePerSecond;
  const viral = game.effectiveViralTier;
  const [muted, setMutedState] = useState(isMuted());
  const cashRef = useRef<HTMLDivElement>(null);

  // Bump the cash number when a payout lands (rate-limited by Effects' emitter cadence).
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
      void el.offsetWidth; // restart the animation
      el.classList.add("bump");
    });
  }, []);

  return (
    <header className="header">
      <div className="header-top">
        <button className="avatar-btn" onClick={onProfileTap} aria-label="Profile">
          <img src={`/images/${look.image}.png`} alt="" className="avatar-img" />
          <span className="avatar-ring" />
        </button>
        <div className="header-id">
          <div className="header-handle">@{game.state.handle || "you"}</div>
          <div className="header-brand">CLOUT EMPIRE</div>
        </div>
        <button
          className="sound-btn"
          aria-label={muted ? "Unmute" : "Mute"}
          onClick={() => { setMuted(!muted); setMutedState(!muted); }}
        >
          <IconSound muted={muted} />
        </button>
        <div className="clout-chip" title="Clout — permanent income bonus">
          <img src="/images/icon_clout.png" alt="" className="chip-icon" />
          <span>{game.state.clout.toLocaleString()}</span>
        </div>
      </div>

      <div className="cash-block">
        <div className="cash-amount" ref={cashRef}>{money(game.state.cash)}</div>
        <div className="cash-meta">
          <span className="persec">
            <img src="/images/icon_sparkle.png" alt="" className="chip-icon" />
            {money(perSec)}/sec
          </span>
          <span className={`viral-chip ${game.viralBuffActive ? "buffed" : ""}`}>
            <img src="/images/icon_hype.png" alt="" className="chip-icon" />
            VIRAL ×{Math.pow(2, viral)}
          </span>
          {game.milleBuffActive && <span className="buff-chip">⚡ ×2 INCOME</span>}
        </div>
      </div>

      <div className="viral-track" title="Level up every hustle to trigger a Viral Moment">
        <div className="viral-track-label">
          <img src="/images/icon_fire.png" alt="" className="chip-icon" />
          Next Viral Moment
        </div>
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
