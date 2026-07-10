// THE FRONTS — laundering panel. Dirty in, respectable out, some evaporates.
import { useGame } from "./hooks";
import { FRONTS, LAUNDER } from "../theme/content";
import { money } from "./format";
import { sfx } from "./sfx";

export function FrontsSection() {
  const game = useGame();
  const rate = game.launderRate;
  const anyOwned = FRONTS.some((f) => game.frontLevel(f.id) > 0);
  // Progressive disclosure: owned fronts + the next unowned one.
  const firstUnowned = FRONTS.findIndex((f) => game.frontLevel(f.id) === 0);
  const visible = FRONTS.filter(
    (f, i) => game.frontLevel(f.id) > 0 || i === firstUnowned,
  );

  return (
    <div className="fronts-section">
      <div className="fronts-head">
        <div>
          <div className="section-title small">{LAUNDER.sectionTitle}</div>
          <div className="section-sub">
            {anyOwned
              ? game.state.cash > 1
                ? `${LAUNDER.washing(money(rate))} · ${LAUNDER.keeps(Math.round(game.launderKeep * 100))}`
                : LAUNDER.idle
              : LAUNDER.sectionSub}
          </div>
        </div>
        <div className="wash-flow" aria-hidden>
          <span className="wash-dirty">💵</span>
          <span className="wash-arrow">→</span>
          <span className="wash-clean">🏦</span>
        </div>
      </div>

      <div className="front-list">
        {visible.map((f) => {
          const level = game.frontLevel(f.id);
          if (level === 0) {
            const afford = game.canAffordFront(f);
            return (
              <div key={f.id} className={`front-row locked ${afford ? "ready" : ""}`}>
                <span className="front-emoji dim">{f.emoji}</span>
                <div className="front-info">
                  <div className="front-name">{f.name}</div>
                  <div className="front-flavor">{f.flavor}</div>
                </div>
                <button
                  className={`btn-mini buy ${afford ? "" : "disabled"} ${f.priceCurrency === "clean" ? "clean" : ""}`}
                  disabled={!afford}
                  onClick={() => { if (game.buyFront(f)) sfx.hire(); }}
                >
                  {f.priceCurrency === "clean" ? "🏦" : "💵"} {money(f.price)}
                </button>
              </div>
            );
          }
          const upgradeCost = game.frontUpgradeCost(f);
          const affordUp = game.state.cleanCash >= upgradeCost;
          return (
            <div key={f.id} className="front-row">
              <span className="front-emoji">{f.emoji}</span>
              <div className="front-info">
                <div className="front-name">
                  {f.name} <span className="front-level">Lv {level}</span>
                </div>
                <div className="front-stats">
                  {LAUNDER.washing(money(game.frontThroughput(f)))} · {LAUNDER.keeps(Math.round((1 - game.frontCut(f)) * 100))}
                </div>
              </div>
              <button
                className={`btn-mini buy clean ${affordUp ? "" : "disabled"}`}
                disabled={!affordUp}
                onClick={() => { if (game.upgradeFront(f)) sfx.buy(); }}
              >
                {LAUNDER.upgrade} · {money(upgradeCost)}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
