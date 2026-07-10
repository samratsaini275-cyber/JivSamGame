# Drip Empire — Visual Overhaul: "Midnight Atelier / Drop Night"

The fantasy: you run a hyped streetwear label. The UI is a dark showroom on drop
night — spotlit product, receipt-paper spec print, a hype wire that never sleeps.
Not a casino, not a candy arcade. Everything below derives from this one scene.

## 1. Tokens (`Views/Theme/Theme.swift` — single source of truth)

### Color

| Token | Value | Role |
|---|---|---|
| `bg0` | `#0A0A0F` | Obsidian floor. Vertical gradient `#12121A → #08080C` + faint static grain so large dark areas aren't flat. |
| `surface1` | `#15151C` | Card fill (elevation step 1). Separation by fill + shadow, **not** glowing borders. |
| `surface2` | `#1D1D26` | Raised fill: wells, chips, segmented track. |
| `hairline` | `white @ 7%` | The only stroke allowed at rest. |
| `textPrimary` | `#F2F1EC` | Warm paper white. |
| `textMuted` | `white @ 62%` | Secondary copy (≥4.5:1 on surfaces). |
| `money` | `#E8C87C` (gradient `#F4E3B2 → #D9A94E`) | **Reserved exclusively for money values and money moments.** Nothing else is gold — not borders, not tabs at rest, not buttons. |
| `hype` | `#FF4D9D` | The one hot accent: Hype, Clout, exposure heat, celebration. Matches the pink tee art. |
| `go` | `#3EDC85` | The one confirm color: DROP, COP (buy) when affordable, positive income. |
| `locked` | `white @ 60%` text, art at 70% opacity / 50% saturation | Legible desire, not a bug. Warm shimmer at ≥80% affordable. |

`Colorway` (player-picked accent) survives but is demoted to *identity only*:
avatar ring, Fit screen, persona flourishes. It no longer paints buy buttons or
the segmented control — that's what made the old accents incoherent.

Tier colors collapse into the system: tier 1 silver → tier 2–3 hype tints →
tier 4+ hype full. (Old blue/purple/orange arcade colors are retired; legacy
`Theme` names stay as aliases so untouched views inherit the new palette.)

### Typography

| Role | Face | Usage |
|---|---|---|
| Display | SF **compressed, black**, uppercase (`.fontWidth(.compressed)`) | Fashion-poster energy: wordmark, machine names, the Empire number, celebration callouts. Restraint: never in body copy. |
| Numbers | Display or body **+ `.monospacedDigit()`** on every money/stat value | Non-negotiable: count-ups can't jitter horizontally. |
| Receipt | SF Mono, 9–10pt, `+1.2` tracking, uppercase for labels | Spec-sheet print: section labels, stat lines, the flavor jokes ("Condolences to people with feet") so the humor reads as brand voice. |
| Body | SF Pro (default sans) | Everything else. The old rounded "cartoon" face is retired globally. |

Type scale: 44 (hero money) / 22 (screen title) / 16 (machine name) / 13 (body) /
10 (receipt) / 9 (micro-label).

### Layout
Phone-shaped 390–480pt. Screen padding 16. Card radius 18, chip radius 10.
Tap targets ≥44pt. Money containers fixed-width-stable via tabular digits.

## 2. Signature element — the DROP WIRE

A thin ticker strip docked under the header: mono uppercase headlines scrolling
right-to-left like a stock wire, separated by `///`. It mixes canned streetwear
satire ("FW26 LOOKBOOK LEAK: IT'S JUST THE SS25 LOOKBOOK") with live game events
("@wavycheckz COPPED SNEAKER RESELLS ×10", "SOLD-OUT DROP: BOOTLEG TEES").
Money amounts render in `money` gold; event items in white; satire in muted.
It makes the world feel alive while idling and absorbs the old floating flavor
line. Reduced motion: items crossfade in place instead of scrolling.

## 3. Motion inventory (trigger · duration · easing)

| # | Animation | Trigger | Duration / easing |
|---|---|---|---|
| 1 | Money roll (odometer) | any cash change | 350ms easeOut (existing `AnimatedMoney`) |
| 2 | Money pop 1.0→1.05→1.0 | cash jumps ≥6% in one tick | 320ms spring(0.3, 0.55) |
| 3 | DROP squash-and-stretch | press | 180ms spring (existing style) |
| 4 | `+$X` cash particle | payout event | 1.1s ease, pooled Canvas (existing field) |
| 5 | Almost-affordable shimmer | cash ≥80% of price | 900ms linear sweep every 2.8s |
| 6 | Affordable pulse | cash ≥ price | 1.6s easeInOut loop, glow 0.25↔0.55 |
| 7 | Machine idle bob | owned card art | y ±1.5pt, period = cycle time clamped 1.2–3s |
| 8 | Progress leading-edge shimmer | bar active | 1.4s linear loop |
| 9 | Milestone confetti + toast | milestone event | ≤1.2s, non-blocking (existing, recolored) |
| 10 | Hype-wave takeover | hypeWave event | 1.1s: dim → display callout ×N count-up → out; `allowsHitTesting(false)` |
| 11 | Tab transition | tab change | 180ms easeOut, opacity + 12pt directional slide |
| 12 | Ticker scroll | always | linear ~55pt/s, seamless loop |
| 13 | Hype-ready breathing | POST A FLEX enabled | 2.2s easeInOut glow loop |

All motion is transform/opacity only. `accessibilityReduceMotion` swaps
scroll/bob/shimmer/pulse for static states and opacity fades.

## 4. Component decisions

- **Header = hero.** Empire number in compressed black 44pt champagne gradient —
  the only gold on screen. `+$X/s` docked tight beneath it, `go` green only when
  income > 0 (a gray `$0.00/s` never lies). All-time as receipt print. Wordmark
  "DRIP EMPIRE" small, white, compressed — the number outranks the logo.
- **Stat chips (Clout/Hype):** small capsule chips in `hype` tints, clearly not
  cards. Zero state invites: "0 CLOUT — rebrand to earn →" (taps to Rebrand tab).
- **Buy multiplier row:** quiet segmented control on `surface2`; selected segment
  is white-on-ink, not gold.
- **Machine cards:** product cards. Art sits in a spotlit "display case" well
  (radial highlight from top), name in display face, stats in receipt mono,
  owned count as a corner badge on the case. Right column = action zone.
- **Locked machines = merch you want:** art visible behind dim glass, padlock +
  price + "62% THERE" receipt line with a thin progress bar, flavor joke as the
  tease, shimmer when close. Never sub-60% text opacity.
- **Buttons:** one primary (`go` fill, ink text) for DROP/COP-when-affordable;
  one secondary (tinted fill); disabled = quiet well showing progress-to-afford
  as a subtle inner fill. "BUY" renames to "COP" (copy polish, on-voice).
- **Tab bar:** active tab in `money` gold with a 3pt indicator dot, inactive
  muted; actionable badge dot in `hype`.

## 5. What deliberately did NOT change
Game logic, economy math, state mutation, persisted keys/IDs, the DM system's
flow, and the existing particle/event architecture — presentation only.
