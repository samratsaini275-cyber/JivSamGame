// Prestige screen: Start a New Family — burn the ledgers, keep the Respect.
import { useEffect, useState } from "react";
import { useGame } from "./hooks";
import { cloutMultiplier } from "../engine/formulas";
import { money } from "./format";
import { FAMILY, LABELS } from "../theme/content";

export function RebrandScreen() {
  const game = useGame();
  const gain = game.cloutOnRebrand;
  const clout = game.state.clout;
  const [armed, setArmed] = useState(false);

  useEffect(() => {
    if (!armed) return;
    const t = window.setTimeout(() => setArmed(false), 3500);
    return () => window.clearTimeout(t);
  }, [armed]);

  return (
    <div className="screen rebrand">
      <div className="rebrand-hero">
        <span className="rebrand-icon">🤝</span>
        <div className="rebrand-title">{FAMILY.title}</div>
        <div className="rebrand-sub">{FAMILY.sub}</div>
      </div>

      <div className="rebrand-stats">
        <div className="rstat">
          <div className="rstat-value">{clout.toLocaleString()}</div>
          <div className="rstat-label">{FAMILY.statHeld}</div>
        </div>
        <div className="rstat">
          <div className="rstat-value">×{cloutMultiplier(clout).toFixed(2)}</div>
          <div className="rstat-label">{FAMILY.statBonus}</div>
        </div>
        <div className="rstat highlight">
          <div className="rstat-value">+{gain.toLocaleString()}</div>
          <div className="rstat-label">{FAMILY.statGain}</div>
        </div>
      </div>

      {game.cloutGainRateBonus > 0 && (
        <div className="rebrand-bonus">
          {FAMILY.bonusNote(Math.round(game.cloutGainRateBonus * 1000) / 10, game.state.daytonaPurchases)}
        </div>
      )}

      <div className="rebrand-ledger">
        <div className="ledger-col keep">
          <div className="ledger-title">{FAMILY.keepTitle}</div>
          <ul>{FAMILY.keeps.map((k) => <li key={k}>{k}</li>)}</ul>
        </div>
        <div className="ledger-col lose">
          <div className="ledger-title">{FAMILY.loseTitle}</div>
          <ul>{FAMILY.loses(money(game.state.cash)).map((k) => <li key={k}>{k}</li>)}</ul>
        </div>
      </div>

      {gain > 0 ? (
        <button
          className={`btn-cta rebrand-btn ${armed ? "armed" : ""}`}
          onClick={() => {
            if (!armed) { setArmed(true); return; }
            setArmed(false);
            game.rebrand();
          }}
        >
          {armed ? FAMILY.ctaArmed(gain.toLocaleString()) : FAMILY.cta}
        </button>
      ) : (
        <div className="rebrand-locked">
          {FAMILY.lockedTitle}
          <div className="clout-progress">
            <div
              className="clout-progress-fill"
              style={{
                width: `${Math.min(
                  (game.state.lifetimeCash /
                    Math.max(nextCloutTarget(game.state.lifetimeCash, clout, game.cloutGainRateBonus), 1)) * 100,
                  100,
                )}%`,
              }}
            />
          </div>
          <span>
            {money(game.state.lifetimeCash)} / {money(nextCloutTarget(game.state.lifetimeCash, clout, game.cloutGainRateBonus))} {LABELS.fortune.toLowerCase()}
          </span>
        </div>
      )}
    </div>
  );
}

function nextCloutTarget(lifetime: number, clout: number, bonus: number): number {
  // Invert floor(√(L/divisor)·(1+bonus)) − clout ≥ 1.
  const needSqrt = (clout + 1) / (1 + bonus);
  return Math.max(0, needSqrt * needSqrt * 25_000);
}
