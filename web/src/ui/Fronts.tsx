// THE FRONTS — laundering panel. Dirty in, respectable out, some evaporates.
import { useGame } from "./hooks";
import { FRONTS, LAUNDER } from "../theme/content";
import { frontIcon } from "../theme/icons";
import { Ic } from "./Icon";
import { money } from "./format";
import { sfx } from "./sfx";

function FrontArt({ id, emoji, dim }: { id: string; emoji: string; dim?: boolean }) {
  const icon = frontIcon(id);
  if (icon) {
    return <img className={`medallion-art small ${dim ? "dim" : ""}`} src={icon} alt="" draggable={false} />;
  }
  return <span className={`front-emoji ${dim ? "dim" : ""}`}>{emoji}</span>;
}

export function FrontsSection() {
  const game = useGame();
  const rate = game.launderRate;
  const anyOwned = FRONTS.some((f) => game.frontLevel(f.id) > 0);
  // Progressive disclosure: owned fronts + the next unowned one whose
  // district the family controls.
  const firstUnowned = FRONTS.findIndex(
    (f) => game.frontLevel(f.id) === 0 && game.districtUnlocked(f.district),
  );
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
          <span className="wash-dirty"><Ic name="dirty" size={16} /></span>
          <span className="wash-arrow"><Ic name="chevron" size={12} /></span>
          <span className="wash-clean"><Ic name="clean" size={16} /></span>
        </div>
      </div>

      <div className="front-list">
        {visible.map((f) => {
          const level = game.frontLevel(f.id);
          if (level === 0) {
            const afford = game.canAffordFront(f);
            return (
              <div key={f.id} className={`front-row locked ${afford ? "ready" : ""}`}>
                <FrontArt id={f.id} emoji={f.emoji} dim />
                <div className="front-info">
                  <div className="front-name">{f.name}</div>
                  <div className="front-flavor">{f.flavor}</div>
                </div>
                <button
                  className={`btn-mini buy ${afford ? "" : "disabled"} ${f.priceCurrency === "clean" ? "clean" : ""}`}
                  disabled={!afford}
                  onClick={() => { if (game.buyFront(f)) sfx.hire(); }}
                >
                  <Ic name={f.priceCurrency === "clean" ? "clean" : "dirty"} size={13} /> {money(f.price)}
                </button>
              </div>
            );
          }
          const upgradeCost = game.frontUpgradeCost(f);
          const affordUp = game.state.cleanCash >= upgradeCost;
          return (
            <div key={f.id} className="front-row">
              <FrontArt id={f.id} emoji={f.emoji} />
              <div className="front-info">
                <div className="front-name">
                  <span className="front-name-text">{f.name}</span>
                  <span className="front-level">LV {level}</span>
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
