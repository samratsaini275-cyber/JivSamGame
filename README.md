# Clout Empire

A satirical idle/incremental game for macOS — build the *appearance* of a fashion empire, one hustle at a time, until the appearance starts generating real money.

Inspired by AdVenture Capitalist's systems, reskinned around fabricated online authority and streetwear hustle culture. The game knows you're faking it.

## Core Loop

1. **Buy hustles** — Bootleg Tees, Sneaker Resells, Custom Hoodies, and more
2. **Earn cash** — Each hustle runs on a production cycle; hire staff to automate
3. **Hit hype tiers** — Milestones at 25/50/100/200/300/400 units double income and halve cycle time
4. **Go viral** — When every owned hustle reaches the same tier, unlock a universal 2× multiplier
5. **Rebrand** — Reset your run to convert lifetime cash into permanent **Clout** (+2% income per point)
6. **Repeat, faster**

## Features

- **8 hustles** with exponential cost scaling (×1.14 per unit)
- **Ghostwriters** — Staff hires that automate each hustle's production cycle
- **Viral Moments** — Account-wide multipliers when hustles level evenly
- **Rebrand (prestige)** — Square-root Clout formula, mirroring angel-investor pacing
- **Rex Shop** — Spend Clout on powerful one-time upgrades
- **Personas** — Equippable identities with profit bonuses
- **Offline earnings** — Your staff keeps working while the app is closed
- **Save persistence** — Progress is saved automatically

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+

## Build & Run

```bash
swift build
swift run CloutEmpire
```

## Run Tests

```bash
swift test
```

## Project Structure

```
Sources/CloutEmpire/
├── CloutEmpireApp.swift      # App entry point
├── Engine/Formulas.swift     # Game math (costs, tiers, clout)
├── Game/                     # Game loop, persistence
├── Model/                    # Hustles, state, personas, items
└── Views/                    # SwiftUI UI, effects, theme
Tests/CloutEmpireTests/       # Unit tests
```

## Design

The full design document (currencies, platforms, trends, MVP roadmap) lived in `readme.md.rtf`, removed in commit 319c80f — recover it from git history if needed.

## License

Private project.
