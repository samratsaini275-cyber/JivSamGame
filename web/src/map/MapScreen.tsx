// Map home screen: canvas + selection bottom-sheets (DOM).
import { useState } from "react";
import { MapCanvas, MapSelection } from "./MapCanvas";
import { useGame } from "../ui/hooks";
import { HUSTLES } from "../engine/data";
import {
  DISTRICTS, FRONTS, LANDMARKS, MAP_COPY, LAUNDER, districtByID, PLOTS,
} from "../theme/content";
import { money } from "../ui/format";
import { sfx } from "../ui/sfx";
import { HustleCard } from "../ui/Empire";

export function MapScreen() {
  const game = useGame();
  const [sel, setSel] = useState<MapSelection | null>(null);

  const close = () => setSel(null);

  return (
    <div className="map-screen">
      <MapCanvas onSelect={setSel} />
      {sel && (
        <div className="sheet-backdrop" onClick={close}>
          <div className="sheet" onClick={(e) => e.stopPropagation()}>
            <div className="sheet-grip" />
            <SheetContent sel={sel} onClose={close} />
          </div>
        </div>
      )}
    </div>
  );
}

function SheetContent({ sel, onClose }: { sel: MapSelection; onClose: () => void }) {
  const game = useGame();

  if (sel.type === "district") {
    const d = districtByID(sel.id);
    if (game.districtUnlocked(d.id)) return <DistrictInfo id={d.id} />;
    const afford = game.canUnlockDistrict(d);
    return (
      <div className="sheet-body">
        <div className="sheet-title">{d.name}</div>
        <div className="sheet-flavor">{d.blurb}</div>
        <div className="sheet-note">Reach Respect {d.respectLevel} · pay in clean cash</div>
        <button
          className={`btn-cta ${afford ? "" : "disabled"}`}
          disabled={!afford}
          onClick={() => { if (game.unlockDistrict(d)) { sfx.viral(); onClose(); } }}
        >
          {MAP_COPY.unlockCta(money(d.price))}
        </button>
      </div>
    );
  }

  const plot = PLOTS.find((p) => p.id === sel.id);
  if (!plot) return null;

  if (plot.kind === "racket") {
    return (
      <div className="sheet-body">
        <HustleCard index={plot.ref as number} />
      </div>
    );
  }

  if (plot.kind === "front") {
    const def = FRONTS.find((f) => f.id === plot.ref)!;
    const level = game.frontLevel(def.id);
    const owned = level > 0;
    const upgradeCost = game.frontUpgradeCost(def);
    return (
      <div className="sheet-body">
        <div className="sheet-title">{def.emoji} {def.name}</div>
        <div className="sheet-flavor">{def.flavor}</div>
        {owned ? (
          <>
            <div className="sheet-stats">
              <span>Lv {level}</span>
              <span>{LAUNDER.washing(money(game.frontThroughput(def)))}</span>
              <span>{LAUNDER.keeps(Math.round((1 - game.frontCut(def)) * 100))}</span>
            </div>
            <button
              className={`btn-cta ${game.state.cleanCash >= upgradeCost ? "" : "disabled"}`}
              disabled={game.state.cleanCash < upgradeCost}
              onClick={() => { if (game.upgradeFront(def)) sfx.buy(); }}
            >
              {LAUNDER.upgrade} · 🏦 {money(upgradeCost)}
            </button>
          </>
        ) : (
          <button
            className={`btn-cta ${game.canAffordFront(def) ? "" : "disabled"}`}
            disabled={!game.canAffordFront(def)}
            onClick={() => { if (game.buyFront(def)) sfx.hire(); }}
          >
            {LAUNDER.buy} · {def.priceCurrency === "clean" ? "🏦" : "💵"} {money(def.price)}
          </button>
        )}
      </div>
    );
  }

  // precinct / landmark
  const lm = LANDMARKS[plot.ref as string];
  return (
    <div className="sheet-body">
      <div className="sheet-title">{lm.emoji} {lm.name}</div>
      <div className="sheet-flavor">{lm.blurb}</div>
      <div className="sheet-note">
        {plot.kind === "precinct" ? MAP_COPY.precinctIdle : MAP_COPY.landmarkIdle}
      </div>
    </div>
  );
}

function DistrictInfo({ id }: { id: string }) {
  const game = useGame();
  const d = districtByID(id);
  const plots = PLOTS.filter((p) => p.district === id);
  const ownedCount = plots.filter((p) =>
    p.kind === "racket"
      ? game.state.hustles[p.ref as number].unitsOwned > 0
      : p.kind === "front"
        ? game.frontLevel(p.ref as string) > 0
        : false,
  ).length;
  return (
    <div className="sheet-body">
      <div className="sheet-title">{d.name}</div>
      <div className="sheet-flavor">{d.blurb}</div>
      <div className="sheet-note">
        {ownedCount} properties held here · tap a building to manage it
      </div>
    </div>
  );
}
