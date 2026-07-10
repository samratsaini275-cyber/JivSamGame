// Prestige screen: burn the account, keep the Clout.
import { useEffect, useState } from "react";
import { useGame } from "./hooks";
import { cloutMultiplier } from "../engine/formulas";
import { money } from "./format";

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
        <img src="/images/icon_clout.png" alt="" className="rebrand-icon" />
        <div className="rebrand-title">REBRAND</div>
        <div className="rebrand-sub">
          Delete the account. Keep the aura. Every point of Clout boosts all income by 2% — forever.
        </div>
      </div>

      <div className="rebrand-stats">
        <div className="rstat">
          <div className="rstat-value">{clout.toLocaleString()}</div>
          <div className="rstat-label">CLOUT HELD</div>
        </div>
        <div className="rstat">
          <div className="rstat-value">×{cloutMultiplier(clout).toFixed(2)}</div>
          <div className="rstat-label">INCOME BONUS</div>
        </div>
        <div className="rstat highlight">
          <div className="rstat-value">+{gain.toLocaleString()}</div>
          <div className="rstat-label">ON REBRAND</div>
        </div>
      </div>

      {game.cloutGainRateBonus > 0 && (
        <div className="rebrand-bonus">
          ⌚ Gain rate boosted +{Math.round(game.cloutGainRateBonus * 1000) / 10}%
          {game.state.daytonaPurchases > 0 && ` (Daytona ×${game.state.daytonaPurchases})`}
        </div>
      )}

      <div className="rebrand-ledger">
        <div className="ledger-col keep">
          <div className="ledger-title">✓ YOU KEEP</div>
          <ul>
            <li>Clout &amp; its income bonus</li>
            <li>Lifetime earnings record</li>
            <li>Your persona &amp; all drip</li>
            <li>Daytona clout-rate bonus</li>
          </ul>
        </div>
        <div className="ledger-col lose">
          <div className="ledger-title">✗ YOU LOSE</div>
          <ul>
            <li>Cash ({money(game.state.cash)})</li>
            <li>All hustles &amp; staff</li>
            <li>Rex's rented gear</li>
            <li>Active buffs</li>
          </ul>
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
          {armed ? `TAP AGAIN — GAIN ${gain.toLocaleString()} CLOUT` : "REBRAND THE EMPIRE"}
        </button>
      ) : (
        <div className="rebrand-locked">
          Stack more lifetime cash to earn your first Clout.
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
            {money(game.state.lifetimeCash)} / {money(nextCloutTarget(game.state.lifetimeCash, clout, game.cloutGainRateBonus))} lifetime
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
