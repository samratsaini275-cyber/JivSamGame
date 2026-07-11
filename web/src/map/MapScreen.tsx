// Map home screen: canvas + selection bottom-sheets (DOM).
import { useState } from "react";
import { MapCanvas, MapSelection } from "./MapCanvas";
import { useGame } from "../ui/hooks";
import { HUSTLES } from "../engine/data";
import {
  DISTRICTS, FRONTS, LANDMARKS, MAP_COPY, LAUNDER, districtByID, PLOTS,
  LAWYER_PERKS, HEAT_COPY,
} from "../theme/content";
import { money } from "../ui/format";
import { sfx } from "../ui/sfx";
import { HustleCard } from "../ui/Empire";
import { PrecinctRow } from "../ui/Law";
import { ShipmentButton } from "../ui/Shipment";

export function MapScreen() {
  const game = useGame();
  const [sel, setSel] = useState<MapSelection | null>(null);

  const close = () => setSel(null);

  return (
    <div className="map-screen">
      <MapCanvas onSelect={setSel} />
      <ShipmentButton />
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
    const level = game.respectLevel;
    const needsRespect = level < d.respectLevel;
    return (
      <div className="sheet-body">
        <div className="sheet-title">{d.name}</div>
        <div className="sheet-flavor">{d.blurb}</div>
        <div className="sheet-note">
          {needsRespect
            ? `Reach Respect L${d.respectLevel} — the family is L${level}. Run shipments, open rackets.`
            : `Respect L${d.respectLevel} ✓ · pay the ward bosses in clean cash`}
        </div>
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

  // precinct: bribes + protection payroll
  if (plot.kind === "precinct") {
    const lm = LANDMARKS[plot.ref as string];
    return (
      <div className="sheet-body">
        <div className="sheet-title">{lm.emoji} {lm.name}</div>
        <div className="sheet-flavor">{lm.blurb}</div>
        <PrecinctRow precinctID={plot.ref as string} />
      </div>
    );
  }

  // landmark: the Judge's parlor sells lawyer perks; City Hall waits.
  if (plot.ref === "judge") {
    return <JudgeParlor />;
  }
  const lm = LANDMARKS[plot.ref as string];
  return (
    <div className="sheet-body">
      <div className="sheet-title">{lm.emoji} {lm.name}</div>
      <div className="sheet-flavor">{lm.blurb}</div>
      <div className="sheet-note">{MAP_COPY.landmarkIdle}</div>
    </div>
  );
}

function JudgeParlor() {
  const game = useGame();
  return (
    <div className="sheet-body">
      <div className="sheet-title">⚖️ {HEAT_COPY.lawyerTitle}</div>
      <div className="sheet-flavor">{HEAT_COPY.lawyerSub}</div>
      {LAWYER_PERKS.map((perk) => {
        const owned = game.hasLawyerPerk(perk.id);
        const afford = game.state.cleanCash >= perk.cost;
        return (
          <div key={perk.id} className={`drip-row ${owned ? "equipped" : ""}`}>
            <span className="drip-emoji">📜</span>
            <div className="drip-info">
              <div className="drip-name">{perk.name}</div>
              <div className="drip-tier t3">{perk.blurb}</div>
            </div>
            {owned ? (
              <span className="drip-state">{HEAT_COPY.owned}</span>
            ) : (
              <button
                className={`btn-mini buy clean ${afford ? "" : "disabled"}`}
                disabled={!afford}
                onClick={() => { if (game.buyLawyerPerk(perk.id)) sfx.rebrand(); }}
              >
                🏦 {money(perk.cost)}
              </button>
            )}
          </div>
        );
      })}
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
