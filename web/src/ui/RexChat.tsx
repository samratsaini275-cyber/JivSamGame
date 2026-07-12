// THE FIXER — Sal's shop. A plain, readable storefront: two shelves of goods,
// each item shows exactly what it does, what it costs, and one button. No chat,
// no threads — a new player should get it in three seconds.
import { useGame } from "./hooks";
import { REX_ITEMS, REX_TIER_NAMES, RexItemDef, ItemSlot } from "../engine/data";
import { SHOP } from "../theme/content";
import { money } from "./format";
import { sfx } from "./sfx";
import { Ic, Portrait } from "./Icon";

export function RexScreen({ onGoEmpire }: { onGoEmpire: () => void }) {
  const game = useGame();
  if (!game.rexUnlocked) return <ShopLocked onGoEmpire={onGoEmpire} />;
  return <Shop />;
}

function ShopLocked({ onGoEmpire }: { onGoEmpire: () => void }) {
  return (
    <div className="screen shop-locked">
      <Portrait name="sal" size={84} />
      <div className="lock-title">{SHOP.lockedTitle}</div>
      <div className="lock-sub">{SHOP.lockedSub}</div>
      <button className="btn-cta lock-cta" onClick={onGoEmpire}>{SHOP.lockedCta}</button>
    </div>
  );
}

function Shop() {
  return (
    <div className="screen shop">
      <div className="shop-hero">
        <Portrait name="sal" size={54} />
        <div>
          <div className="section-title">{SHOP.title}</div>
          <div className="shop-pitch">{SHOP.pitch}</div>
        </div>
      </div>

      <Shelf slot="wrist" icon="watch" title={SHOP.wristTitle} sub={SHOP.wristSub} />
      <Shelf slot="garage" icon="car" title={SHOP.garageTitle} sub={SHOP.garageSub} />

      <div className="shop-footnote">{SHOP.bestOwned}</div>
    </div>
  );
}

function Shelf({ slot, icon, title, sub }: { slot: ItemSlot; icon: "watch" | "car"; title: string; sub: string }) {
  const items = REX_ITEMS.filter((i) => i.slot === slot).sort((a, b) => a.tier - b.tier);
  return (
    <div className="shop-shelf">
      <div className="shelf-head">
        <span className="shelf-icon"><Ic name={icon} size={18} /></span>
        <div>
          <div className="shelf-title">{title}</div>
          <div className="shelf-sub">{sub}</div>
        </div>
      </div>
      <div className="ware-list">
        {items.map((item) => <Ware key={item.id} item={item} />)}
      </div>
    </div>
  );
}

function Ware({ item }: { item: RexItemDef }) {
  const game = useGame();
  const owns = game.ownsItem(item);
  const equipped = game.isItemEquipped(item);
  const afford = game.state.cash >= item.cost;

  return (
    <div className={`ware ${equipped ? "equipped" : ""}`}>
      <div className="ware-top">
        <span className={`ware-tier t${item.tier}`}>{REX_TIER_NAMES[item.tier]}</span>
        <span className="ware-name">{item.name}</span>
      </div>
      <div className="ware-effect"><Ic name="up" size={13} /> {item.boostText}</div>
      <div className="ware-foot">
        {equipped ? (
          <span className="ware-state wearing"><Ic name="check" size={13} /> {SHOP.wearing}</span>
        ) : owns ? (
          <button className="btn-mini" onClick={() => { game.equipItem(item); sfx.post(); }}>
            {SHOP.equip}
          </button>
        ) : (
          <button
            className={`btn-mini buy ${afford ? "" : "disabled"}`}
            disabled={!afford}
            onClick={() => { if (game.buyItem(item)) sfx.buy(); }}
          >
            {SHOP.buy} · <Ic name="dirty" size={12} /> {money(item.cost)}
          </button>
        )}
      </div>
    </div>
  );
}
