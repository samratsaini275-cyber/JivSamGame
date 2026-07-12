// The Boss: alias, family colors, wardrobe. Style survives a New Family.
import { useState } from "react";
import { useGame } from "./hooks";
import {
  BASE_LOOKS, COLORWAYS, PERSONA_SLOTS, PERSONA_TIER_NAMES,
  baseLookByID, personaItemsForSlot,
} from "../engine/data";
import { money } from "./format";
import { sfx } from "./sfx";
import { BOSS, LABELS } from "../theme/content";
import { Ic, IconName, Portrait, PortraitName } from "./Icon";

const LOOK_PORTRAIT: Record<string, PortraitName> = {
  hoodie: "look-hoodie", bizcaz: "look-bizcaz", street: "look-street", gym: "look-gym",
};
const SLOT_ICON: Record<string, IconName> = { Clothes: "suit", Jewelry: "ring", Watch: "watch" };

export function PersonaScreen() {
  const game = useGame();
  const look = baseLookByID(game.state.baseLook);

  return (
    <div className="screen persona">
      <div className="profile-card">
        <Portrait name={LOOK_PORTRAIT[look.id] ?? "look-hoodie"} size={84} className="profile-portrait" />
        <div className="profile-info">
          <div className="profile-handle">"{game.state.handle}"</div>
          <div className="profile-stats">
            <span className="stat"><Ic name="respect" size={13} /> {LABELS.respect} L{game.respectLevel}</span>
            <span className="stat"><Ic name="legacy" size={13} /> {game.state.clout.toLocaleString()} {LABELS.legacy}</span>
            <span className="stat"><Ic name="clean" size={13} /> {money(game.state.lifetimeClean)} {BOSS.lifetimeStat}</span>
          </div>
          <div className="profile-slots">
            {PERSONA_SLOTS.map((slot) => {
              const item = game.equippedCosmetic(slot);
              return (
                <span key={slot} className={`slot-chip ${item ? `t${item.tier}` : "empty"}`}>
                  <Ic name={SLOT_ICON[slot]} size={12} /> {item ? PERSONA_TIER_NAMES[item.tier] : "—"}
                </span>
              );
            })}
          </div>
        </div>
      </div>

      <div className="section-block">
        <div className="section-title small">{BOSS.colorwayLabel}</div>
        <div className="swatch-row">
          {COLORWAYS.map((c) => (
            <button
              key={c.id}
              className={`swatch ${game.state.colorway === c.id ? "active" : ""}`}
              style={{ background: `linear-gradient(135deg, ${c.accent}, ${c.accentDeep})` }}
              onClick={() => game.setColorway(c.id)}
              aria-label={c.name}
            >
              {game.state.colorway === c.id && <Ic name="check" size={16} />}
            </button>
          ))}
        </div>
      </div>

      {PERSONA_SLOTS.map((slot) => (
        <div className="section-block" key={slot}>
          <div className="section-title small">{BOSS.slots[slot].toUpperCase()} · {BOSS.wardrobeLabel}</div>
          <div className="drip-list">
            {personaItemsForSlot(slot).map((item) => {
              const owns = game.ownsCosmetic(item);
              const equipped = game.isCosmeticEquipped(item);
              const afford = game.state.cleanCash >= item.cost;
              return (
                <div key={item.id} className={`drip-row ${equipped ? "equipped" : ""}`}>
                  <span className={`drip-icon t${item.tier}`}><Ic name={SLOT_ICON[slot]} size={18} /></span>
                  <div className="drip-info">
                    <div className="drip-name">{item.name}</div>
                    <div className={`drip-tier t${item.tier}`}>
                      {PERSONA_TIER_NAMES[item.tier]}{item.tier === 4 ? BOSS.grailNote : ""}
                    </div>
                  </div>
                  {equipped ? (
                    <span className="drip-state">WEARING</span>
                  ) : owns ? (
                    <button className="btn-mini" onClick={() => game.equipCosmetic(item)}>WEAR</button>
                  ) : (
                    <button
                      className={`btn-mini buy ${afford ? "" : "disabled"}`}
                      disabled={!afford}
                      onClick={() => { game.buyCosmetic(item); sfx.buy(); }}
                    >
                      <Ic name="clean" size={12} /> {money(item.cost)}
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}
      <div className="persona-footnote">{BOSS.footnote}</div>
    </div>
  );
}

// MARK: First-run boss creation

export function PersonaCreation() {
  const game = useGame();
  const [handle, setHandle] = useState("");
  const [look, setLook] = useState("hoodie");
  const [colorway, setColorway] = useState("gold");
  const ready = handle.trim().length > 0;

  return (
    <div className="modal-backdrop creation">
      <div className="creation-card">
        <div className="creation-kicker">{BOSS.creation.kicker}</div>
        <div className="creation-title">{BOSS.creation.title}</div>
        <div className="creation-sub">{BOSS.creation.sub}</div>

        <label className="field-label" htmlFor="handle">{BOSS.creation.handleLabel}</label>
        <div className="handle-field">
          <span>"</span>
          <input
            id="handle"
            value={handle}
            maxLength={18}
            placeholder={BOSS.creation.handlePlaceholder}
            onChange={(e) => setHandle(e.target.value.replace(/\s/g, ""))}
            autoFocus
          />
          <span>"</span>
        </div>

        <label className="field-label">{BOSS.creation.lookLabel}</label>
        <div className="look-grid">
          {BASE_LOOKS.map((l) => (
            <button
              key={l.id}
              className={`look-tile ${look === l.id ? "active" : ""}`}
              onClick={() => setLook(l.id)}
            >
              <Portrait name={LOOK_PORTRAIT[l.id] ?? "look-hoodie"} size={52} ring={false} />
              <span>{l.name}</span>
            </button>
          ))}
        </div>

        <label className="field-label">{BOSS.creation.colorLabel}</label>
        <div className="swatch-row center">
          {COLORWAYS.map((c) => (
            <button
              key={c.id}
              className={`swatch ${colorway === c.id ? "active" : ""}`}
              style={{ background: `linear-gradient(135deg, ${c.accent}, ${c.accentDeep})` }}
              onClick={() => setColorway(c.id)}
              aria-label={c.name}
            >
              {colorway === c.id && <Ic name="check" size={16} />}
            </button>
          ))}
        </div>

        <button
          className={`btn-cta ${ready ? "" : "disabled"}`}
          disabled={!ready}
          onClick={() => game.createPersona(handle, look, colorway)}
        >
          {BOSS.creation.cta}
        </button>
      </div>
    </div>
  );
}
