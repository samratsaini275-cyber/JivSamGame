// The main idle screen: buy-mode picker + hustle cards.
// Locked hustles reveal progressively — only the next two are visible,
// the rest stay a mystery so the list never overwhelms a new player.
import { useGame } from "./hooks";
import { BUY_MODES } from "../engine/game";
import { HUSTLES, tierName } from "../engine/data";
import { nextThreshold, unitCost } from "../engine/formulas";
import { money, duration } from "./format";
import { sfx } from "./sfx";
import { LABELS, MISC, MYSTERY_CARD, DISTRICTS, HEAT_COPY } from "../theme/content";
import { racketIcon } from "../theme/icons";
import { FrontsSection } from "./Fronts";

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
          <div className="section-title">{MISC.portfolio}</div>
          <div className="section-sub">{MISC.running(ownedCount, HUSTLES.length)}</div>
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

      <FrontsSection />

      <div className="card-list">
        {HUSTLES.slice(0, visibleCount).map((h) => <HustleCard key={h.id} index={h.id} />)}
        {hiddenCount > 0 && (
          <div className="mystery-card">
            <span className="mystery-icon">{MYSTERY_CARD.icon}</span>
            <div>
              <div className="mystery-title">{MYSTERY_CARD.title(hiddenCount)}</div>
              <div className="mystery-sub">{MYSTERY_CARD.sub}</div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function HustleArt({ index }: { index: number }) {
  const def = HUSTLES[index];
  const icon = racketIcon(index);
  if (icon) return <img className="medallion-art" src={icon} alt="" draggable={false} />;
  return (
    <span className="emoji-art" style={{ ["--hue" as string]: `${(index * 47) % 360}deg` }}>
      {def.emoji}
    </span>
  );
}

export function HustleCard({ index }: { index: number }) {
  const game = useGame();
  const def = HUSTLES[index];
  const s = game.state.hustles[index];
  const owned = s.unitsOwned > 0;
  const tier = game.tier(index);
  const available = game.hustleAvailable(index);

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

  if (owned && game.isRaided(index)) {
    const fee = game.reopenCost(index);
    const canReopen = !game.inPrison && game.state.cleanCash >= fee;
    return (
      <div className="hustle-card raided" data-hustle-card={index}>
        <div className="hustle-art dim">
          <HustleArt index={index} />
          <span className="lock-badge">🚧</span>
        </div>
        <div className="hustle-body">
          <div className="hustle-title-row">
            <span className="hustle-name">{def.name}</span>
            <span className="raided-chip">{HEAT_COPY.raidedTag}</span>
          </div>
          <div className="hustle-flavor">{HEAT_COPY.reopenNote}</div>
        </div>
        <div className="hustle-actions">
          <button
            className={`btn-buy ${canReopen ? "" : "disabled"}`}
            disabled={!canReopen}
            onClick={() => { if (game.reopenHustle(index)) sfx.hire(); }}
          >
            <span className="btn-buy-label">{HEAT_COPY.reopenCta(money(fee))}</span>
          </button>
        </div>
      </div>
    );
  }

  if (!owned) {
    const firstCost = unitCost(def.baseCost, 0);
    const canUnlock = available && game.state.cash >= firstCost;
    const districtName = DISTRICTS.find((d) => d.id === game.hustleDistrict(index))?.name ?? "";
    return (
      <div className={`hustle-card locked ${canUnlock ? "ready" : ""}`} data-hustle-card={index}>
        <div className="hustle-art dim">
          <HustleArt index={index} />
          <span className="lock-badge">🔒</span>
        </div>
        <div className="hustle-body">
          <div className="hustle-name">{def.name}</div>
          <div className="hustle-flavor">
            {available ? def.flavor : `Buy into ${districtName} to open this racket.`}
          </div>
        </div>
        <button
          className={`btn-buy unlock ${canUnlock ? "" : "disabled"}`}
          disabled={!canUnlock}
          onClick={() => { game.buyOne(index); sfx.buy(); }}
        >
          <span className="btn-buy-label">{available ? LABELS.start : "🔒"}</span>
          <span className="btn-buy-cost">{available ? money(firstCost) : districtName}</span>
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
                : `${LABELS.runBatch} · ${money(game.incomePerCycle(index))}`}
          </span>
          {s.ghostwriterHired && <span className="auto-chip">{LABELS.automated}</span>}
        </button>

        <div className="milestone-row">
          <div className={`milestone-bar ${almostMilestone ? "almost" : ""}`}>
            <div className="milestone-fill" style={{ width: `${milestonePct}%` }} />
          </div>
          <span className={`milestone-label ${almostMilestone ? "almost" : ""}`}>
            {next ? `${s.unitsOwned}/${next}` : LABELS.maxed}
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
            title={`${def.ghostwriterName} runs batches automatically`}
          >
            🤵 {def.ghostwriterName} · {money(def.ghostwriterCost)}
          </button>
        )}
      </div>
    </div>
  );
}
