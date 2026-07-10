// The main idle screen: buy-mode picker + hustle cards.
// Locked hustles reveal progressively — only the next two are visible,
// the rest stay a mystery so the list never overwhelms a new player.
import { useGame } from "./hooks";
import { BUY_MODES } from "../engine/game";
import { HUSTLES, tierName } from "../engine/data";
import { nextThreshold, unitCost } from "../engine/formulas";
import { money, duration } from "./format";
import { sfx } from "./sfx";

export function Empire() {
  const game = useGame();
  const states = game.state.hustles;
  const ownedCount = states.filter((h) => h.unitsOwned > 0).length;
  const maxOwned = states.reduce((max, h, i) => (h.unitsOwned > 0 ? i : max), 0);
  const visibleCount = Math.min(HUSTLES.length, maxOwned + 3); // owned + next 2 locked
  const hiddenCount = HUSTLES.length - visibleCount;

  return (
    <div className="screen empire">
      <div className="empire-toolbar">
        <div>
          <div className="section-title">PORTFOLIO</div>
          <div className="section-sub">{ownedCount}/{HUSTLES.length} hustles running</div>
        </div>
        <div className="segmented" role="tablist" aria-label="Buy amount">
          {BUY_MODES.map((m) => (
            <button
              key={m.id}
              className={`seg ${game.buyMode === m.id ? "active" : ""}`}
              onClick={() => game.setBuyMode(m.id)}
            >
              {m.label}
            </button>
          ))}
        </div>
      </div>

      <div className="card-list">
        {HUSTLES.slice(0, visibleCount).map((h) => <HustleCard key={h.id} index={h.id} />)}
        {hiddenCount > 0 && (
          <div className="mystery-card">
            <span className="mystery-icon">🔮</span>
            <div>
              <div className="mystery-title">{hiddenCount} more hustles await</div>
              <div className="mystery-sub">Grow the empire to reveal what's next.</div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function HustleArt({ index }: { index: number }) {
  const def = HUSTLES[index];
  if (def.image) return <img src={`/images/${def.image}.png`} alt="" />;
  return (
    <span className="emoji-art" style={{ ["--hue" as string]: `${(index * 47) % 360}deg` }}>
      {def.emoji}
    </span>
  );
}

function HustleCard({ index }: { index: number }) {
  const game = useGame();
  const def = HUSTLES[index];
  const s = game.state.hustles[index];
  const owned = s.unitsOwned > 0;
  const tier = game.tier(index);

  const count = game.buyCount(index);
  const cost = game.buyCost(index);
  const canBuy = game.state.cash >= cost && count > 0;

  const next = nextThreshold(s.unitsOwned);
  const milestonePct = next ? (s.unitsOwned / next) * 100 : 100;
  const almostMilestone = next !== null && next - s.unitsOwned <= 3;

  const cycle = game.cycleTime(index);
  const running = s.ghostwriterHired || s.cycleRunning;
  const progressPct = running ? Math.min((s.cycleProgress / cycle) * 100, 100) : 0;
  // Sub-second cycles read as a constant blur — show them as always-full.
  const instant = s.ghostwriterHired && cycle < 0.35;

  if (!owned) {
    const firstCost = unitCost(def.baseCost, 0);
    const canUnlock = game.state.cash >= firstCost;
    return (
      <div className={`hustle-card locked ${canUnlock ? "ready" : ""}`} data-hustle-card={index}>
        <div className="hustle-art dim">
          <HustleArt index={index} />
          <span className="lock-badge">🔒</span>
        </div>
        <div className="hustle-body">
          <div className="hustle-name">{def.name}</div>
          <div className="hustle-flavor">{def.flavor}</div>
        </div>
        <button
          className={`btn-buy unlock ${canUnlock ? "" : "disabled"}`}
          disabled={!canUnlock}
          onClick={() => { game.buyOne(index); sfx.buy(); }}
        >
          <span className="btn-buy-label">START</span>
          <span className="btn-buy-cost">{money(firstCost)}</span>
        </button>
      </div>
    );
  }

  return (
    <div className={`hustle-card tier-${Math.min(tier, 4)}`} data-hustle-card={index}>
      <button
        className="hustle-art"
        onClick={() => { if (!s.ghostwriterHired && !s.cycleRunning) { game.post(index); sfx.post(); } }}
        aria-label={s.ghostwriterHired ? def.name : `Post ${def.name}`}
      >
        <HustleArt index={index} />
        <span className="units-badge">×{s.unitsOwned.toLocaleString()}</span>
      </button>

      <div className="hustle-body">
        <div className="hustle-title-row">
          <span className="hustle-name">{def.name}</span>
          {tier > 0 && <span className="tier-chip">{tierName(tier)}</span>}
        </div>

        <button
          className={`cycle-bar ${running ? "running" : "idle"} ${instant ? "instant" : ""}`}
          onClick={() => { game.post(index); sfx.post(); }}
          disabled={s.ghostwriterHired}
        >
          <div className="cycle-fill" style={{ width: instant ? "100%" : `${progressPct}%` }} />
          <span className="cycle-label">
            {s.ghostwriterHired
              ? `${money(game.incomePerCycle(index) / cycle)}/sec`
              : s.cycleRunning
                ? `${money(game.incomePerCycle(index))} · ${duration(Math.max(cycle - s.cycleProgress, 0))}`
                : `TAP TO POST · ${money(game.incomePerCycle(index))}`}
          </span>
          {s.ghostwriterHired && <span className="auto-chip">AUTO</span>}
        </button>

        <div className="milestone-row">
          <div className={`milestone-bar ${almostMilestone ? "almost" : ""}`}>
            <div className="milestone-fill" style={{ width: `${milestonePct}%` }} />
          </div>
          <span className={`milestone-label ${almostMilestone ? "almost" : ""}`}>
            {next ? `${s.unitsOwned}/${next}` : "MAXED"}
          </span>
        </div>
      </div>

      <div className="hustle-actions">
        <button
          className={`btn-buy ${canBuy ? "" : "disabled"}`}
          disabled={!canBuy}
          onClick={() => { game.buy(index); sfx.buy(); }}
        >
          <span className="btn-buy-label">BUY ×{count.toLocaleString()}</span>
          <span className="btn-buy-cost">{money(cost)}</span>
        </button>
        {!s.ghostwriterHired && (
          <button
            className={`btn-hire ${game.state.cash >= def.ghostwriterCost ? "" : "disabled"}`}
            disabled={game.state.cash < def.ghostwriterCost}
            onClick={() => { game.hireGhostwriter(index); sfx.hire(); }}
            title={`${def.ghostwriterName} posts automatically`}
          >
            🤖 {def.ghostwriterName} · {money(def.ghostwriterCost)}
          </button>
        )}
      </div>
    </div>
  );
}
