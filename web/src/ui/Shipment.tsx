// SHIPMENT — the active-play verb. Route picker + in-transit chip +
// the one-tap checkpoint decision popup.
import { useEffect, useState } from "react";
import { useGame } from "./hooks";
import { game as gameInstance } from "../engine/game";
import { SHIPMENT_ROUTES, SHIPMENT_SIZES, SHIPMENT_COPY } from "../theme/content";
import { money } from "./format";
import { sfx } from "./sfx";

export function ShipmentButton() {
  const game = useGame();
  const [open, setOpen] = useState(false);
  const sh = game.state.activeShipment;

  if (game.inPrison) return null;

  return (
    <>
      {sh ? (
        <div className="shipment-fab in-transit">
          🚚 {SHIPMENT_COPY.inTransit(Math.max(0, Math.ceil((sh.arrivesAt - Date.now()) / 1000)))}
        </div>
      ) : (
        <button className="shipment-fab" onClick={() => setOpen(true)}>
          📦 {SHIPMENT_COPY.cta}
        </button>
      )}
      {open && !sh && <ShipmentPanel onClose={() => setOpen(false)} />}
    </>
  );
}

function ShipmentPanel({ onClose }: { onClose: () => void }) {
  const game = useGame();
  const [sizeID, setSizeID] = useState("small");

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="law-card shipment-card" onClick={(e) => e.stopPropagation()}>
        <div className="sheet-title">📦 {SHIPMENT_COPY.panelTitle}</div>
        <div className="sheet-note">{SHIPMENT_COPY.panelSub}</div>

        <div className="segmented ship-sizes">
          {SHIPMENT_SIZES.map((s) => (
            <button
              key={s.id}
              className={`seg ${sizeID === s.id ? "active" : ""}`}
              onClick={() => setSizeID(s.id)}
            >
              {s.name}
            </button>
          ))}
        </div>

        {SHIPMENT_ROUTES.map((route) => {
          const available = game.routeAvailable(route);
          const quote = game.shipmentQuote(route, sizeID);
          return (
            <div key={route.id} className={`route-row ${available ? "" : "unavailable"}`}>
              <span className="front-emoji">{route.emoji}</span>
              <div className="front-info">
                <div className="front-name">{route.name}</div>
                <div className="front-flavor">
                  {available ? route.blurb : SHIPMENT_COPY.needRoute}
                </div>
              </div>
              <button
                className={`btn-mini buy ${available ? "" : "disabled"}`}
                disabled={!available}
                onClick={() => {
                  if (game.startShipment(route.id, sizeID)) {
                    sfx.hire();
                    onClose();
                  }
                }}
              >
                {SHIPMENT_COPY.confirm(money(quote.payout), quote.heat)}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

/** Checkpoint decision — mounts at App level so it pops on any tab. */
export function CheckpointPopup() {
  const game = useGame();
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    return gameInstance.onEvent((e) => {
      if (e.kind === "checkpoint") { setVisible(true); sfx.warning(); }
      if (e.kind === "shipmentArrived" || e.kind === "shipmentSeized") setVisible(false);
    });
  }, []);

  const sh = game.state.activeShipment;
  if (!visible || !sh || sh.checkpointResolved) return null;

  const choose = (detour: boolean) => {
    game.resolveCheckpoint(detour);
    sfx.post();
    setVisible(false);
  };

  return (
    <div className="checkpoint-pop">
      <div className="checkpoint-title">🚨 {SHIPMENT_COPY.checkpointTitle}</div>
      <div className="checkpoint-sub">{SHIPMENT_COPY.checkpointSub}</div>
      <div className="checkpoint-actions">
        <button className="btn-mini buy" onClick={() => choose(true)}>
          {SHIPMENT_COPY.detour(6)}
        </button>
        <button className="btn-mini" onClick={() => choose(false)}>
          {SHIPMENT_COPY.barrel}
        </button>
      </div>
    </div>
  );
}
