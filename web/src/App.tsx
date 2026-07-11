import { useEffect, useState } from "react";
import { useGame } from "./ui/hooks";
import { colorwayByID } from "./engine/data";
import { rexUnreadCount } from "./engine/rexChat";
import { Header } from "./ui/Header";
import { Empire } from "./ui/Empire";
import { RexScreen } from "./ui/RexChat";
import { PersonaScreen, PersonaCreation } from "./ui/Persona";
import { RebrandScreen } from "./ui/Rebrand";
import { EffectsLayer } from "./ui/Effects";
import { IconEmpire, IconChat, IconSpark, IconProfile, IconLock, IconMap } from "./ui/Icons";
import { money } from "./ui/format";
import { LABELS, MISC } from "./theme/content";
import { MapScreen } from "./map/MapScreen";
import { LawPanel, PrisonOverlay } from "./ui/Law";

type Tab = "map" | "empire" | "dms" | "rebrand" | "profile";

const TABS: { id: Tab; label: string; Icon: (p: { size?: number }) => JSX.Element }[] = [
  { id: "map", label: LABELS.tabs.map, Icon: IconMap },
  { id: "empire", label: LABELS.tabs.ledger, Icon: IconEmpire },
  { id: "dms", label: LABELS.tabs.fixer, Icon: IconChat },
  { id: "rebrand", label: LABELS.tabs.family, Icon: IconSpark },
  { id: "profile", label: LABELS.tabs.boss, Icon: IconProfile },
];

export function App() {
  const game = useGame();
  const [tab, setTab] = useState<Tab>("map");
  const [lawOpen, setLawOpen] = useState(false);
  const colorway = colorwayByID(game.state.colorway);
  const unread = rexUnreadCount(game);

  // Colorway tints the whole UI via CSS variables.
  useEffect(() => {
    const root = document.documentElement;
    root.style.setProperty("--accent", colorway.accent);
    root.style.setProperty("--accent-deep", colorway.accentDeep);
  }, [colorway.id]);

  return (
    <div className="stage">
      <div className="stage-glow" aria-hidden />
      <div className="phone">
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
          {TABS.map(({ id, label, Icon }) => (
            <button
              key={id}
              className={`tab ${tab === id ? "active" : ""}`}
              onClick={() => setTab(id)}
            >
              <span className="tab-icon">
                <Icon />
                {id === "dms" && unread > 0 && <span className="tab-badge">{unread}</span>}
                {id === "dms" && !game.rexUnlocked && (
                  <span className="tab-lock"><IconLock size={10} /></span>
                )}
              </span>
              <span className="tab-label">{label}</span>
            </button>
          ))}
        </nav>

        <EffectsLayer />
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
        <div className="offline-emoji">🕰️</div>
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
