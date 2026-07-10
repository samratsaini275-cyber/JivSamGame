# Bootleg Empire — Implementation Plan

## What exists today (exploration summary)

The canonical game is the **web app in `web/`** (Vite + React 18 + TypeScript). The Swift app in
`Sources/` is a legacy macOS build of the same design; it is untouched by this work.

| Area | Where | Notes |
|---|---|---|
| Economy math | `web/src/engine/formulas.ts` | Pure functions: cost growth ×1.14, geometric bulk buys, milestone tiers (25/50/100/200/300/400 units → income ×2, cycle ÷2), prestige `floor(√(lifetime/divisor))`. **Reused unchanged.** |
| Game loop | `web/src/engine/game.ts` | `Game` class, 10 Hz `setInterval` tick, listener/`useSyncExternalStore` React binding, event emitter for celebrations. **Pattern reused; class extended.** |
| Content data | `web/src/engine/data.ts` | 16 businesses w/ base cost/income/cycle, staff automation costs. **Stats reused; names move to theme config.** |
| Save system | `web/src/engine/state.ts` | localStorage JSON, autosave 5 s, offline earnings capped 24 h, defensive merge on load. **Reused + versioned migration added.** |
| UI | `web/src/ui/*` | React screens (list-of-businesses, chat shop, profile, prestige), CSS design system in `styles.css`, WebAudio sfx in `sfx.ts`. **Restyled + extended.** |

## How the spec maps onto the code

- **§1 Rebrand** → new `web/src/theme/content.ts` holds every string, palette token, business
  name/flavor, district/plot layout. Components read content by id; no scattered string edits.
  Old business stat rows keep their indices so the tuned economy curve survives 1:1.
- **§2 Dual currency** → `Game` gains `dirty`/`clean` wallets. Producers deposit dirty; fronts are a
  new entity type with `throughput/cut/level` that continuously converts dirty→clean in the tick.
  Purchase rules: plots = clean (Laundromat is the scripted starter exception, "paid in favors"),
  illegal levels/crew/bribes/shipments = dirty, fronts' upgrades/lawyers/bail/reopen = clean.
  Save bumps to `v2` with a lossy-but-fair v1 migration (units→levels, cash→dirty, clout→Legacy).
- **§3 Map** → **decision: procedural vector drawing on a single `<canvas>`**, no bitmap assets.
  Rationale: resolution-independent (Capacitor/retina for free), zero asset pipeline, a stylized
  deco map is exactly the look procedural paths are good at, and ~30 buildings + capped particles
  is trivial fill-rate. The static base map is pre-rendered to an offscreen canvas per zoom level
  and blitted each frame; only dynamic elements (particles, vehicles, signs, day/night tint) redraw.
  DOM stays on top for HUD/panels/sheets. Camera: pointer events (pan + momentum + clamp),
  two-pointer pinch, wheel zoom on desktop, double-tap toggling city↔district zoom.
- **§4 Heat** → new fields on state (`heat`, `payroll[]`, `investigationT`, `prison`, `raidedPlot`),
  all advanced in the same 10 Hz tick. UI: badge dial in HUD, precinct sheets, prison overlay.
  Rewarded-ad early release is `adRelease(): Promise<boolean>` stub returning unavailable.
- **§5 Shipments** → replaces the manual "run a batch" tap as the active-play verb. Routes derived
  from owned plots; a vehicle entity animates on the map; checkpoint popups are DOM.
- **§6 Progression** → Respect = XP levels (gates districts); prestige reuses `cloutGain()`math with
  a bigger divisor for Legacy tokens (production ×, launder cut −, starting-heat −).
- **§7 Art** → all tokens in `content.ts` → CSS variables; Limelight (display) + Barlow (body/nums)
  bundled via @fontsource; newspaper toast component is the signature event surface.

## Phases (one commit each)

1. **Re-theme:** `content.ts`, palette/typography swap, every screen re-skinned, playable.
2. **Dual currency:** wallets, 5 fronts, laundering tick, purchase rules, save v2 migration.
3. **Map:** canvas renderer + camera + plots + sheets + particles/vehicles; list view stays as Ledger tab.
4. **Heat/prison:** meter, bribes, payroll, investigation, raid, prison, reopen, lawyer perks.
5. **Shipments + progression:** routes, checkpoints, Respect, prestige, milestone events.
6. **Polish/QA:** newspaper toasts everywhere, day/night, perf caps, vitest economy tests,
   deterministic fast-forward sim (balance: laundering bottleneck ~8–10 min, first investigation
   ~12 min), full raid→prison→bail→reopen self-playtest, screenshots + critique.

## Content guardrails (enforced in content.ts, checked in QA)

Fictional New Carthage 1926 · alcohol only · bloodless "muscled out" flavor · The Velvet Room is a
jazz club · consequences are core · dark-comedy pulp tone. All themed strings live in one file.
