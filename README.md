# Drug Empire

Two idle/incremental games live in this repo. They share the same DNA — geometric cost scaling, milestone tiers, a prestige loop — but are separate codebases with separate save formats.

| | Path | Stack | Theme |
|---|---|---|---|
| **Drug Empire** | [`web/`](web/) | Vite + React 18 + TypeScript | Modern-day street-to-cartel drug tycoon |
| **Drip Empire** | [`Sources/`](Sources/) | SwiftPM, SwiftUI (macOS 13+) | Streetwear/influencer idle game |

---

## Drug Empire (`web/`)

A mobile-first web idle game: build a modern drug operation in the port city of "Eastport" — start slinging weed on a corner, climb to coke-money hustles and the cartel table, launder dirty cash into clean, dodge police heat, and prestige ("start a New Operation") for permanent Legacy bonuses.

### Latest push — guided onboarding

The UI now uses **progressive disclosure**: only the Hustles and Boss tabs exist at first. The City map, Sosa (the fixer), and the Empire (prestige) tabs appear as the run earns them, and Von — your right hand — introduces each one. (The former mini casino was removed.)

### Core loop

1. **Buy hustles** — corner spots, grow houses, go-fast boats, superlabs, and more across five districts, telling a weed → cocaine → cartel progression
2. **Launder** dirty cash into clean cash through fronts (the economy's core bottleneck)
3. **Manage heat** — police investigations, bribes, and a prison mechanic push back against unchecked growth
4. **Ship** product, level up **Respect**, and unlock landmarks
5. **Start a New Operation** (prestige) — reset your run for permanent **Legacy** bonuses

### Run it

```bash
cd web
npm install
npm run dev      # vite dev server on port 5199
npm test         # vitest: economy unit tests + 15-min fast-forward balance sim
npm run build    # tsc + vite build
```

### Structure

```
web/src/
├── engine/           # formulas.ts (pure math), state.ts (save snapshot), game.ts (10 Hz tick loop)
├── theme/content.ts  # every player-facing string, palette, business/district/plot definition — single source of truth
├── map/              # procedural vector canvas city map, camera/pan/pinch
└── ui/               # React screens, hooks, HUD
```

- **Theme config is law:** all copy, tuning constants, and content definitions live in `web/src/theme/content.ts`. Never scatter player-facing strings across components.
- **Persisted IDs are load-bearing:** hustle indices, item/front/district ids and stat rows must not be renamed or reordered.
- In dev, `window.game` is exposed on `window` for console debugging.

---

## Drip Empire (`Sources/`)

The original streetwear-themed idle game — build the *appearance* of a fashion empire, one hustle at a time, until the appearance starts generating real money.

### Core loop

1. **Buy hustles** — Bootleg Tees, Sneaker Resells, Custom Hoodies, and more
2. **Earn cash** — Each hustle runs on a production cycle; hire ghostwriters to automate
3. **Hit hype tiers** — Milestones at 25/50/100/200/300/400 units double income and halve cycle time
4. **Go viral** — When every owned hustle reaches the same tier, unlock a universal 2× multiplier
5. **Rebrand** — Reset your run to convert lifetime cash into permanent **Clout** (+2% income per point)
6. **Repeat, faster**

### Features

- 8 hustles with exponential cost scaling (×1.14 per unit)
- Ghostwriters — staff hires that automate each hustle's production cycle
- Viral Moments — account-wide multipliers when hustles level evenly
- Rebrand (prestige) — square-root Clout formula, mirroring angel-investor pacing
- Rex Shop — spend Clout on powerful one-time upgrades
- Personas — equippable cosmetic identities, some with small permanent bonuses
- DM system — 8 dealers with node-based chat scripts, respect levels, and comeback arcs
- Offline earnings (capped at 24h) and autosave

### Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+

### Build & run

```bash
swift build
swift run CloutEmpire
```

**Note:** `Persistence.enabled` is currently `false` as a dev toggle — every launch starts a fresh run.

### Tests

This machine has no Xcode, only Command Line Tools, so `swift test` fails (`XCTest not available`). `Tests/CloutEmpireTests/` is kept for a future Xcode setup. To verify game math, concatenate the relevant `Formulas`/`Model` sources plus assertions into a standalone script and run with `swift script.swift`.

### Structure

```
Sources/CloutEmpire/
├── CloutEmpireApp.swift      # App entry point
├── Engine/Formulas.swift     # Game math (costs, tiers, clout)
├── Game/                     # Game loop, persistence
├── Model/                    # Hustles, state, personas, items, DM scripts
└── Views/                    # SwiftUI UI, effects, theme
Tests/CloutEmpireTests/       # Unit tests (Xcode-only)
```

Design tokens live in `Views/Theme/Theme.swift` ("Midnight Atelier / Drop Night"), documented in `DESIGN.md`. The original design doc (`readme.md.rtf`) was removed in commit `319c80f` — recover it from git history and read with `textutil -convert txt -stdout` if needed.

---

## License

Private project.
