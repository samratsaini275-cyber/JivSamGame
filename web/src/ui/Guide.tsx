// Von, the right hand — the AdCap-style guide. Watches game state and pops
// up the first not-yet-seen tip whose trigger is currently true, so the
// player is told what to do next instead of guessing. One tip at a time.
import { useEffect, useState } from "react";
import { useGame } from "./hooks";
import { Game } from "../engine/game";
import { FRONTS, GUIDE, GUIDE_TIPS, GuideTipDef } from "../theme/content";
import { HUSTLES } from "../engine/data";
import { sfx } from "./sfx";
import { Portrait, Ic } from "./Icon";

type Tab = "map" | "empire" | "dms" | "rebrand" | "profile";

/** True when a tip is relevant right now (and hasn't been shown before). */
function triggered(id: string, g: Game): boolean {
  const st = g.state;
  switch (id) {
    case "welcome":
      return true; // right after persona creation
    case "first_expand":
      return st.hustles[0].unitsOwned >= 2;
    case "laundromat_ready":
      return g.frontLevel("laundromat") === 0 && g.canAffordFront(FRONTS[0]);
    case "first_clean":
      return st.cleanCash > 0;
    case "crew_ready":
      return st.hustles.some((h, i) => h.unitsOwned > 0 && !h.ghostwriterHired &&
        st.cash >= HUSTLES[i].ghostwriterCost);
    case "front_upgrade_ready":
      return g.frontLevel("laundromat") >= 1 && st.cleanCash >= FRONTS[0].upgradeBase;
    case "milestone_hint":
      return st.hustles.some((h) => h.unitsOwned >= 25);
    case "shipment_ready":
      return st.hustles[1].unitsOwned > 0 && !st.activeShipment;
    case "shipment_live":
      return st.activeShipment !== null;
    case "fixer_ready":
      return g.rexUnlocked;
    case "respect_hint":
      return g.respectLevel >= 2;
    case "stockpile_warning":
      return g.launderRate > 0 && st.cash > g.stockpileThreshold * 1.5;
    case "heat_warning":
      return st.heat >= 45 && !g.underInvestigation;
    case "investigation_help":
      return g.underInvestigation;
    case "reopen_hint":
      return st.raidedHustles.length > 0 && !g.inPrison;
    case "district_ready": {
      const d = g.nextLockedDistrict;
      return d !== null && g.canUnlockDistrict(d);
    }
    case "velvet_ready":
      return g.districtUnlocked("downtown") && g.frontLevel("velvet") === 0 &&
        st.cleanCash >= FRONTS.find((f) => f.id === "velvet")!.price;
    case "prestige_ready":
      return g.cloutOnRebrand > 0 && st.clout === 0;
    default:
      return false;
  }
}

export function GuideLayer({ onGoTab }: { onGoTab: (tab: Tab) => void }) {
  const game = useGame();
  const [active, setActive] = useState<GuideTipDef | null>(null);

  // Each render (driven by the 10 Hz tick) look for the next tip to show.
  useEffect(() => {
    if (active || game.inPrison) return;
    if (!game.personaCreated) return;
    const next = GUIDE_TIPS.find((t) => !game.guideSeen(t.id) && triggered(t.id, game));
    if (next) {
      setActive(next);
      sfx.message();
    }
  });

  if (!active) return null;

  const dismiss = () => {
    game.markGuideSeen(active.id);
    setActive(null);
  };

  const showMe = () => {
    if (active.tab) onGoTab(active.tab);
    dismiss();
  };

  return (
    <div className="guide-pop" role="dialog" aria-label={`${GUIDE.name}, ${GUIDE.title}`}>
      <Portrait name="enzo" size={54} className="guide-avatar" />
      <div className="guide-body">
        <div className="guide-name">{GUIDE.name} <span className="guide-title">· {GUIDE.title}</span></div>
        <div className="guide-headline">{active.headline}</div>
        <div className="guide-text">{active.text}</div>
        <div className="guide-actions">
          {active.tab && (
            <button className="btn-mini buy" onClick={showMe}>
              {GUIDE.show} <Ic name="chevron" size={13} />
            </button>
          )}
          <button className="btn-mini" onClick={dismiss}>{GUIDE.dismiss}</button>
        </div>
      </div>
    </div>
  );
}
