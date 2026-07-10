import { useSyncExternalStore } from "react";
import { game, Game } from "../engine/game";

/// Subscribes the component tree to the 10 Hz game loop.
export function useGame(): Game {
  useSyncExternalStore(game.subscribe, () => game.version);
  return game;
}
