# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"Drip Empire" (formerly Clout Empire) — a satirical AdVenture Capitalist-style idle game about faking a streetwear empire. SwiftPM macOS executable (macOS 13+), SwiftUI, no external dependencies. The window is phone-shaped (390×~800) and views are kept iOS-portable for a possible future Xcode target. The original design doc (`readme.md.rtf`, referenced by section number in code comments like "README §4") was removed in commit 319c80f; recover it from git history and read with `textutil -convert txt -stdout` if needed.

## Commands

```bash
swift build              # build
swift run CloutEmpire    # run the app
```

**This machine has no Xcode, only Command Line Tools** — `swift test` fails with "XCTest not available". Tests in `Tests/CloutEmpireTests/` are kept for a future Xcode setup. To verify game math now, concatenate the relevant `Formulas`/`Model` sources plus assertions into a standalone script and run `swift script.swift`.

Save file: `~/Library/Application Support/CloutEmpire/save.json` (delete to reset). **Note:** `Persistence.enabled` in `Sources/CloutEmpire/Game/Persistence.swift` is a dev toggle and is currently `false` — every launch is a fresh run until it's flipped back.

## Naming: display vs. internal

The game was renamed/reskinned from influencer theme to streetwear, but **internal names were deliberately not renamed**: types still say `Hustle`, `ghostwriterHired`, `RexItem`, `CloutEmpire`, and all item IDs, hustle indices, and costs are load-bearing for save compatibility. Change display strings only; never rename persisted keys or IDs.

## Architecture

All game logic lives in three layers, strictly ordered:

- **`Engine/Formulas.swift`** — pure, deterministic math (costs ×1.14 geometric growth, milestone tiers at 25/50/100/200/300/400 units, viral tier = min tier across all 8 hustles, Clout = floor(√(lifetimeCash/25 000)) with a `+1e-9` epsilon that guards against FP rounding eating a point). No state, no side effects.
- **`Model/`** — data definitions (`Hustle.all`, `RexItem`, `PersonaItem`, `CloutStore` constants) and `GameState`, the single Codable save snapshot.
- **`Game/Game.swift`** — the `ObservableObject` that owns `GameState`, runs the 10 Hz `Timer` tick loop, and is the *only* place state is mutated. Views call methods on `Game`; derived values (income, cycle times, prices with dealer discounts) are computed properties here. Autosaves every 50 ticks; offline earnings granted on launch (capped at 24 h).

**Save migration:** `GameState` has a hand-written `init(from:)`/`encode(to:)` with explicit `CodingKeys`. Every new persisted field must use `decodeIfPresent` with a default and be added to `CodingKeys` and `encode`, or old saves break. Legacy per-dealer fields (`vault*`, `whip*`) are migrated into the generic `dmThreads` dictionary on decode.

**Events → UI:** `Game.lastEvent: GameEvent?` is the celebration channel (milestones, hype waves, payouts, new DMs, rebrand). `GameEvent` has a per-emission UUID so identical payloads still retrigger animations. `ContentView` observes it and drives toasts + particles; particle spawn positions come from `CardFramesKey` preference frames measured in the `"game"` coordinate space.

**DM system (the largest subsystem):** 8 dealers (`DMDealer`, one per hustle, unlocked when that hustle has ≥1 unit) run node-based chat scripts. Nodes/choices/effects are declared via `DMScriptBuilder` (shared intro→offer→bought tree shape per dealer, from a `DMTreeSpec`) plus `DMComebackScripts` for respect-level-1 comeback arcs. Node effects (`DMEffect`) buy/equip items, set respect, grant referral discounts. Per-dealer runtime state lives in `GameState.dmThreads` (`DMThreadState`: transcript, current node, closed/reopen bookkeeping — comeback threads have a parallel set of fields) and `GameState.dealerRelationships` (`DealerRelationship`: respect level, comeback progress, discounts).

**Rebrand (prestige) semantics** — what survives vs. resets, per `GameState.rebrand`:
- Reset: cash, hustle units/ghostwriters, active buffs, Rex items (with one exception), DM threads.
- Survive: Clout Store upgrades (`hustleCloutUpgrades`), persona cosmetics, `daytonaPurchases` (permanent +2% Clout gain per purchase), dealer relationships.
- Persona cosmetics are pure vanity except grail items: +0.5% Clout on Rebrand each, never income.

**Theme:** design tokens in `Views/Theme/Theme.swift` — "Midnight Atelier / Drop Night" system, documented in `DESIGN.md` (obsidian elevation surfaces, `money` gold reserved for money values only, one `hype` magenta accent, one `go` confirm green; type = SF compressed display / SF Mono receipt print / plain sans body). `Colorway` is the player-picked accent, demoted to identity moments only (avatar ring, Fit). Legacy names (`coinGreen`, `cloutPink`, `luxeGold`, `panelTop`, …) are aliases into the new palette so old call sites stay coherent. Helpers: `gameCard()`, `kicker()`, `ShimmerSweep`, `StatChip`, `TickerTape`/`TickerFeed` (the "DROP WIRE" headline strip). Images are loaded by name from `Resources/Images` via `GameImage`/`GameBundle`. All motion respects `accessibilityReduceMotion`.

## Misc

- `scripts/` holds Python asset generators (icons); `work/generated-assets` is intermediate output, not shipped.
- `swift run` has no app bundle, so `CloutEmpireApp.init` manually sets `NSApp.setActivationPolicy(.regular)` to get a Dock icon and focus.
- **UI screenshots without screen-recording perms:** `SNAPSHOT_PATH=/tmp/shot.png swift run CloutEmpire` renders the window to PNG after 2.5 s and quits. Combine with `DEV_SEED=1` (mid-game state) or `DEV_SEED=locked` (early game, all three unlock-affordability bands) and `DEV_TAB=rex|rebrand|profile` to capture specific screens/states. All three are dev-only env hooks in `CloutEmpireApp`/`ContentView`.
