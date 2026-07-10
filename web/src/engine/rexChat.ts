// DM threads & message builder — port of Model/RexChat.swift.
import { Game } from "./game";
import {
  ItemSlot, RexItemDef, rexItemByID, rexItemsForSlot, REX, REX_TIER_NAMES,
} from "./data";
import { money } from "../ui/format";

export interface RexDMThread {
  id: string;
  title: string;
  preview: string;
  unlockMoneyTier: number;
  unlockLifetimeCash: number;
  slot: ItemSlot | null;
}

export const REX_THREADS: RexDMThread[] = [
  { id: "intro", title: "Rex Calloway", preview: "Yo. Been watching the brand…",
    unlockMoneyTier: 0, unlockLifetimeCash: 0, slot: null },
  { id: "wrist", title: "Rex · Wrist Game", preview: "The watch is the whole argument.",
    unlockMoneyTier: REX.unlockMoneyTier, unlockLifetimeCash: 500, slot: "wrist" },
  { id: "garage", title: "Rex · Garage Era", preview: "You don't drive it. You park it where people eat.",
    unlockMoneyTier: REX.unlockMoneyTier, unlockLifetimeCash: 1_200, slot: "garage" },
];

export function unlockedThreads(game: Game): RexDMThread[] {
  if (!game.rexUnlocked) return [];
  return REX_THREADS.filter(
    (t) => game.maxMoneyTier >= t.unlockMoneyTier && game.state.lifetimeCash >= t.unlockLifetimeCash,
  );
}

export interface RexChatMessage {
  id: string;
  sender: "rex" | "player";
  text: string;
  itemID: string | null;
  pitchID: string | null;
}

export interface RexReply {
  id: string;
  label: string;
  action:
    | { type: "introAck"; label: string }
    | { type: "buy"; item: RexItemDef; label: string }
    | { type: "equip"; item: RexItemDef; label: string }
    | { type: "dismiss"; label: string };
  disabled?: boolean;
}

export function threadMessages(thread: RexDMThread, game: Game): RexChatMessage[] {
  switch (thread.id) {
    case "intro": return introMessages(game);
    case "wrist": return slotMessages("wrist", game);
    case "garage": return slotMessages("garage", game);
    default: return [];
  }
}

export function pendingPitch(messages: RexChatMessage[], game: Game): string | null {
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.sender !== "rex" || !msg.pitchID) continue;
    if (playerResponded(msg.pitchID, game)) continue;
    return msg.pitchID;
  }
  return null;
}

export function rexUnreadCount(game: Game): number {
  if (!game.rexUnlocked) return 0;
  return unlockedThreads(game).filter(
    (t) => pendingPitch(threadMessages(t, game), game) !== null,
  ).length;
}

export function repliesFor(pitchID: string, game: Game): RexReply[] {
  if (pitchID === "intro") {
    if (game.state.rexIntroAcknowledged) return [];
    return [
      { id: "intro_yes", label: "Put me on the map",
        action: { type: "introAck", label: "Put me on the map" } },
      { id: "intro_huh", label: "Who is this?",
        action: { type: "introAck", label: "Who is this?" } },
    ];
  }
  const item = itemForPitch(pitchID);
  if (!item) return [];
  if (game.isItemEquipped(item)) return [];
  if (game.ownsItem(item)) {
    return [
      { id: `eq_${item.id}`, label: "Put it on",
        action: { type: "equip", item, label: "Put it on" } },
      { id: `later_${item.id}`, label: "Not right now",
        action: { type: "dismiss", label: "Not right now" } },
    ];
  }
  const afford = game.state.cash >= item.cost;
  const buyLabel = afford ? `Send it · ${money(item.cost)}` : `Need ${money(item.cost)} — broke`;
  return [
    { id: `buy_${item.id}`, label: buyLabel,
      action: { type: "buy", item, label: buyLabel }, disabled: !afford },
    { id: `pass_${item.id}`, label: "Hard pass for now",
      action: { type: "dismiss", label: "Hard pass for now" } },
  ];
}

// MARK: - Private

function introMessages(game: Game): RexChatMessage[] {
  const msgs: RexChatMessage[] = [
    { id: "intro_pitch", sender: "rex", text: REX.greeting, itemID: null, pitchID: "intro" },
  ];
  if (game.state.rexIntroAcknowledged) {
    msgs.push({
      id: "intro_player", sender: "player",
      text: game.state.rexIntroReply ?? "Put me on the map", itemID: null, pitchID: null,
    });
    msgs.push({
      id: "intro_followup", sender: "rex",
      text: game.state.rexIntroReply === "Who is this?"
        ? "I'm Rex. I make brands look expensive. Stick around."
        : "That's the energy. Check the other threads — wrist and garage — when you're ready to level up the flex.",
      itemID: null, pitchID: null,
    });
  }
  return msgs;
}

function slotMessages(slot: ItemSlot, game: Game): RexChatMessage[] {
  const msgs: RexChatMessage[] = [];
  const opener = slot === "wrist"
    ? "Alright. Wrist game separates tourists from founders. Pick your lane."
    : "Garage talk. The car doesn't matter — the photo angle does.";
  msgs.push({ id: `${slot}_opener`, sender: "rex", text: opener, itemID: null, pitchID: null });

  for (const item of rexItemsForSlot(slot)) {
    const pitchID = `pitch_${item.id}`;
    if (!pitchVisible(item, game)) continue;

    msgs.push({
      id: pitchID, sender: "rex", text: pitchText(item), itemID: item.id, pitchID,
    });

    const player = playerMessage(pitchID, item, game);
    if (player) msgs.push(player);
    const followUp = rexFollowUp(item, pitchID, game);
    if (followUp) msgs.push(followUp);
  }
  return msgs;
}

export function pitchVisible(item: RexItemDef, game: Game): boolean {
  if (game.ownsItem(item) || game.state.rexDismissedPitches.includes(`pitch_${item.id}`)) {
    return true;
  }
  return game.state.lifetimeCash >= item.cost * 0.35;
}

function pitchText(item: RexItemDef): string {
  return `${item.name} — ${item.blurb}\n\n${item.boostText}. ${REX_TIER_NAMES[item.tier]} tier.`;
}

function playerMessage(pitchID: string, item: RexItemDef, game: Game): RexChatMessage | null {
  if (!playerResponded(pitchID, game)) return null;
  let text: string;
  if (game.isItemEquipped(item) || game.ownsItem(item)) {
    text = game.state.rexPitchReplies[pitchID] ?? "Send it.";
  } else if (game.state.rexDismissedPitches.includes(pitchID)) {
    text = game.state.rexPitchReplies[pitchID] ?? "Hard pass for now";
  } else {
    return null;
  }
  return { id: `player_${pitchID}`, sender: "player", text, itemID: item.id, pitchID: null };
}

function rexFollowUp(item: RexItemDef, pitchID: string, game: Game): RexChatMessage | null {
  if (!playerResponded(pitchID, game)) return null;
  const stored = game.state.rexPitchFollowUp[pitchID];
  let text: string;
  if (stored) {
    text = stored;
  } else if (game.isItemEquipped(item)) {
    text = "Looking expensive. That's the whole point.";
  } else if (game.ownsItem(item)) {
    text = "It's in the stash. Equip when you're ready to be seen.";
  } else if (game.state.rexDismissedPitches.includes(pitchID)) {
    text = "Fair. The flex will still be there when the bag catches up.";
  } else {
    return null;
  }
  return { id: `rex_follow_${pitchID}`, sender: "rex", text, itemID: item.id, pitchID: null };
}

function playerResponded(pitchID: string, game: Game): boolean {
  if (pitchID === "intro") return game.state.rexIntroAcknowledged;
  const item = itemForPitch(pitchID);
  if (!item) return false;
  return (
    game.ownsItem(item) ||
    game.isItemEquipped(item) ||
    game.state.rexDismissedPitches.includes(pitchID) ||
    game.state.rexPitchReplies[pitchID] !== undefined
  );
}

function itemForPitch(pitchID: string): RexItemDef | null {
  if (!pitchID.startsWith("pitch_")) return null;
  return rexItemByID(pitchID.slice(6));
}
