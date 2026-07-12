// The law: heat badge dial, precinct bribe/payroll panel, prison overlay.
import { useEffect, useState } from "react";
import { useGame } from "./hooks";
import { Ic } from "./Icon";
import { PRECINCTS } from "../engine/game";
import { HEAT_COPY, LANDMARKS, PLOTS, districtByID } from "../theme/content";
import { money, duration } from "./format";
import { sfx } from "./sfx";

// ---------------------------------------------------------------------------
// Heat badge — always visible in the HUD. Green: safe · amber: warming ·
// red pulsing: under investigation. Tap opens the Law panel.
// ---------------------------------------------------------------------------

export function heatColor(heat: number): string {
  if (heat >= 70) return "#c22a33";
  if (heat >= 40) return "#d9993b";
  return "#5f8f5f";
}

export function HeatBadge({ onTap }: { onTap: () => void }) {
  const game = useGame();
  const heat = game.state.heat;
  const color = heatColor(heat);
  const investigating = game.underInvestigation;
  // Badge arc: 270° sweep starting bottom-left.
  const pct = heat / 100;
  const dash = 66; // arc length of the ring path
  return (
    <button
      className={`heat-badge ${investigating ? "investigating" : ""}`}
      onClick={onTap}
      aria-label={`${HEAT_COPY.label} ${Math.round(heat)}`}
      title={HEAT_COPY.panelTitle}
    >
      <svg viewBox="0 0 36 36" width="34" height="34">
        <path
          d="M18 3l11 4v9c0 8-5 14-11 17C12 30 7 24 7 16V7z"
          fill="rgba(10,12,17,0.8)"
          stroke={color}
          strokeWidth="2"
        />
        <circle
          cx="18" cy="17" r="10.5"
          fill="none"
          stroke="rgba(232,220,195,0.15)"
          strokeWidth="3"
        />
        <circle
          cx="18" cy="17" r="10.5"
          fill="none"
          stroke={color}
          strokeWidth="3"
          strokeLinecap="round"
          strokeDasharray={`${pct * dash} ${dash}`}
          transform="rotate(90 18 17)"
        />
        <text
          x="18" y="21"
          textAnchor="middle"
          fontSize="10"
          fontWeight="900"
          fill={color}
          fontFamily="'Barlow Condensed', sans-serif"
        >
          {Math.round(heat)}
        </text>
      </svg>
      {investigating && (
        <span className="heat-countdown">{Math.ceil(game.investigationSecondsLeft)}s</span>
      )}
    </button>
  );
}

// ---------------------------------------------------------------------------
// Law panel — heat sources + every unlocked precinct's bribe/payroll.
// ---------------------------------------------------------------------------

export function LawPanel({ onClose }: { onClose: () => void }) {
  const game = useGame();
  const heat = game.state.heat;
  const rate = game.heatRatePerSec;
  const stockpiled = game.state.cash > game.stockpileThreshold;

  const precincts = PRECINCTS.filter((pid) => {
    const plot = PLOTS.find((p) => p.ref === pid);
    return plot && game.districtUnlocked(plot.district);
  });

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="law-card" onClick={(e) => e.stopPropagation()}>
        <div className="law-head">
          <div className="sheet-title"><Ic name="badge" size={18} /> {HEAT_COPY.panelTitle}</div>
          <div className="law-status" style={{ color: heatColor(heat) }}>
            {game.underInvestigation
              ? `${HEAT_COPY.investigation} · ${Math.ceil(game.investigationSecondsLeft)}s`
              : heat >= 40 ? HEAT_COPY.warm : HEAT_COPY.safe}
          </div>
        </div>
        <div className="heat-meter">
          <div className="heat-meter-fill" style={{ width: `${heat}%`, background: heatColor(heat) }} />
        </div>
        <div className="law-rate">
          {rate >= 0 ? "▲" : "▼"} {Math.abs(rate * 60).toFixed(1)} heat/min
          {stockpiled && <span className="law-warn"> · <Ic name="warn" size={12} /> {HEAT_COPY.srcStockpile}!</span>}
          {game.state.payrolls.length > 0 && (
            <span className="law-ok"> · {HEAT_COPY.srcPayroll(game.state.payrolls.length)}</span>
          )}
        </div>
        <div className="sheet-note">{HEAT_COPY.panelSub}</div>

        {precincts.map((pid) => <PrecinctRow key={pid} precinctID={pid} />)}

        <button className="btn-cta" onClick={onClose}>DONE</button>
      </div>
    </div>
  );
}

export function PrecinctRow({ precinctID }: { precinctID: string }) {
  const game = useGame();
  const lm = LANDMARKS[precinctID];
  const plot = PLOTS.find((p) => p.ref === precinctID);
  const districtName = plot ? districtByID(plot.district).name : "";
  const onPayroll = game.payrollActive(precinctID);
  const payrollCost = game.payrollCostPerMin(precinctID);
  const bribeCost = game.bribeCost;
  const canBribe = game.state.cash >= bribeCost && game.state.heat > 2;

  return (
    <div className="precinct-row">
      <div className="precinct-head">
        <span className="precinct-name"><Ic name="precinct" size={15} /> {lm.name}</span>
        <span className="precinct-district">{districtName}</span>
      </div>
      <div className="precinct-actions">
        <button
          className={`btn-mini ${canBribe ? "buy" : "disabled"}`}
          disabled={!canBribe}
          onClick={() => { if (game.bribe()) sfx.hire(); }}
          title={`−${Math.round(game.bribeRelief)} heat`}
        >
          {HEAT_COPY.bribeCta(money(bribeCost))}
        </button>
        <button
          className={`btn-mini ${onPayroll ? "active-payroll" : ""}`}
          onClick={() => { game.togglePayroll(precinctID); sfx.post(); }}
        >
          {onPayroll ? HEAT_COPY.payrollOff : HEAT_COPY.payrollOn(money(payrollCost))}
        </button>
      </div>
      {onPayroll && <div className="precinct-note"><Ic name="check" size={12} /> {HEAT_COPY.payrollActive}</div>}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Prison overlay — full-screen cell with wait / bail / (stubbed) ad release.
// ---------------------------------------------------------------------------

export function PrisonOverlay() {
  const game = useGame();
  const [, force] = useState(0);
  useEffect(() => {
    const t = window.setInterval(() => force((n) => n + 1), 500);
    return () => window.clearInterval(t);
  }, []);

  const left = game.prisonSecondsLeft;
  const bail = game.bailCost;
  const canBail = game.state.cleanCash >= bail;

  return (
    <div className="prison-overlay">
      <div className="prison-bars" aria-hidden />
      <div className="prison-inner">
        <div className="prison-title">{HEAT_COPY.prisonTitle}</div>
        <div className="prison-clock">{duration(left)}</div>
        <div className="prison-sub">{HEAT_COPY.prisonSub}</div>
        <div className="prison-actions">
          <button
            className={`btn-cta ${canBail ? "" : "disabled"}`}
            disabled={!canBail}
            onClick={() => { if (game.payBail()) sfx.rebrand(); }}
          >
            {HEAT_COPY.prisonBail(money(bail))}
          </button>
          <button className="btn-cta disabled prison-ad" disabled>
            {HEAT_COPY.prisonAd}
          </button>
        </div>
        <div className="prison-note">{HEAT_COPY.prisonWait} — the clock does the rest.</div>
      </div>
    </div>
  );
}
