import { useEffect, useState } from "react";
import { useGame } from "./ui/hooks";
import { Game } from "./engine/game";
import { colorwayByID } from "./engine/data";
import { rexUnreadCount } from "./engine/rexChat";
import { Header } from "./ui/Header";
import { Empire } from "./ui/Empire";
import { RexScreen } from "./ui/RexChat";
import { PersonaScreen, PersonaCreation } from "./ui/Persona";
import { RebrandScreen } from "./ui/Rebrand";
import { EffectsLayer } from "./ui/Effects";
import { IconEmpire, IconChat, IconSpark, IconProfile, IconMap } from "./ui/Icons";
import { Ic } from "./ui/Icon";
import { Atmosphere } from "./ui/Atmosphere";
import { money } from "./ui/format";
import { LABELS, MISC } from "./theme/content";
import { MapScreen } from "./map/MapScreen";
import { LawPanel, PrisonOverlay } from "./ui/Law";
import { CheckpointPopup } from "./ui/Shipment";
import { GuideLayer } from "./ui/Guide";

type Tab = "map" | "empire" | "dms" | "rebrand" | "profile";

const TABS: { id: Tab; label: string; Icon: (p: { size?: number }) => JSX.Element }[] = [
  { id: "empire", label: LABELS.tabs.ledger, Icon: IconEmpire },
  { id: "map", label: LABELS.tabs.map, Icon: IconMap },
  { id: "dms", label: LABELS.tabs.fixer, Icon: IconChat },
  { id: "rebrand", label: LABELS.tabs.family, Icon: IconSpark },
  { id: "profile", label: LABELS.tabs.boss, Icon: IconProfile },
];

/** Progressive disclosure: a tab exists only once the game has earned it,
 *  so Von's guidance carries the early run instead of a wall of chrome. */
function tabUnlocked(id: Tab, game: Game): boolean {
  const st = game.state;
  switch (id) {
    case "empire":
    case "profile":
      return true;
    case "map": // the operation goes city-scale with a second hustle or a deed
      return st.hustles[1].unitsOwned > 0 || game.frontLevel("laundromat") > 0 ||
        st.clout > 0 || st.districtsUnlocked.length > 1;
    case "dms":
      return game.rexUnlocked;
    case "rebrand": // prestige appears once it means something
      return game.cloutOnRebrand > 0 || st.clout > 0;
  }
}

export function App() {
  const game = useGame();
  const [tab, setTab] = useState<Tab>("empire");
  const [lawOpen, setLawOpen] = useState(false);
  const colorway = colorwayByID(game.state.colorway);
  const unread = rexUnreadCount(game);
  const visibleTabs = TABS.filter(({ id }) => tabUnlocked(id, game));

  // Colorway tints the whole UI via CSS variables.
  useEffect(() => {
    const root = document.documentElement;
    root.style.setProperty("--accent", colorway.accent);
    root.style.setProperty("--accent-deep", colorway.accentDeep);
  }, [colorway.id]);

  // If the active tab disappears (e.g. a fresh run re-locks it), fall home.
  useEffect(() => {
    if (!tabUnlocked(tab, game)) setTab("empire");
  }, [tab, game.version]);

  return (
    <div className="stage">
      <div className="stage-glow" aria-hidden />
      <div className="phone">
        <div className="phone-bg" aria-hidden />
        {(tab === "empire" || tab === "map") && (
          <Header onProfileTap={() => setTab("profile")} onHeatTap={() => setLawOpen(true)} />
        )}

        <main className="phone-content">
          {tab === "map" && <MapScreen />}
          {tab === "empire" && <Empire />}
          {tab === "dms" && <RexScreen onGoEmpire={() => setTab("map")} />}
          {tab === "rebrand" && <RebrandScreen />}
          {tab === "profile" && <PersonaScreen />}
        </main>

        <nav className="tab-bar">
          {visibleTabs.map(({ id, label, Icon }) => (
            <button
              key={id}
              className={`tab ${tab === id ? "active" : ""}`}
              onClick={() => setTab(id)}
            >
              <span className="tab-icon">
                <Icon />
                {id === "dms" && unread > 0 && <span className="tab-badge">{unread}</span>}
              </span>
              <span className="tab-label">{label}</span>
            </button>
          ))}
        </nav>

        <Atmosphere />
        <EffectsLayer />
        <CheckpointPopup />
        {game.personaCreated && !game.inPrison && <GuideLayer onGoTab={setTab} />}
        {lawOpen && <LawPanel onClose={() => setLawOpen(false)} />}
        {game.inPrison && <PrisonOverlay />}
        {!game.personaCreated && <PersonaCreation />}
        {game.offlineEarnings > 0 && <OfflineModal />}
      </div>
    </div>
  );
}

function OfflineModal() {
  const game = useGame();
  return (
    <div className="modal-backdrop">
      <div className="offline-card">
        <div className="offline-emoji"><Ic name="dirty" size={38} /></div>
        <div className="offline-title">{MISC.offlineTitle}</div>
        <div className="offline-sub">{MISC.offlineSub}</div>
        <div className="offline-amount">+{money(game.offlineEarnings)}</div>
        <button className="btn-cta" onClick={() => game.dismissOfflineEarnings()}>
          {MISC.offlineCta}
        </button>
      </div>
    </div>
  );
}
