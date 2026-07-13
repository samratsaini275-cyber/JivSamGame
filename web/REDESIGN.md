# Bootleg Empire — Premium Art Direction

> **Historical note (July 2026):** the game has since been re-themed to
> "Drug Empire" — a modern-day street-to-cartel tycoon set in Eastport
> (see `src/theme/content.ts`). The craft rules below (ink field, gold =
> money, red = heat, motion discipline) still govern the UI; the
> Prohibition-era fiction and Limelight display font do not.

## Player fantasy
You are a Prohibition-era crime boss quietly buying a city. The feeling is
*command over a glittering, dangerous underworld* — a ledger of secrets, brass
and lamplight, jazz behind a locked door, the constant hum of the law outside.

## Emotional tone
Cinematic pulp noir with warmth. Not grim — *seductive*. Smoky, gold-lit,
theatrical. Every screen should feel like a scene, lit from a single warm source.

## Palette
- **Ink** `#0b0e14 → #171d29` — the night, the field everything sits on.
- **Brass** `#d4a943 / #ecd08a / #6e5416` — money, power, the ONLY gold. Engraved, lit.
- **Paper** `#e8dcc3` — ledgers, posters, headlines. Aged cream.
- **Absinthe green** `#87a86a` — dirty cash only.
- **Siren red** `#c1272f` — heat & danger only.
- **Deco teal** `#37716b` — water, the fronts, cool accents.
- **Ember** `#e8a24a` warm rim-light used sparingly for atmosphere glow.

## Typography roles
- **Display**: Limelight — titles, hero numbers, poster headlines. Used with restraint, big.
- **Condensed**: Barlow Condensed 900 — labels, currency, tickers, buttons. Tabular figures on all money.
- **Body**: Barlow — flavor and instructions.

## Materials & surfaces
- **Ink panels**: not flat — top rim-light, inner hairline in brass, a 2px inset
  shadow so they read as pressed metal plates, not divs.
- **Brass plaques**: bevel highlight top, engraved text with a light shadow,
  a hard `0 2px 0` bottom edge and press-down on tap.
- **Paper**: newspaper toasts and the creation modal — aged cream with a
  letterpress masthead and an inset keyline.
- **Glass is banned.** Depth comes from light and shadow, not blur.

## Global atmosphere (the "expensive" layer)
Every screen sits under: a warm top-down key light, a soft vignette, a very
faint film grain, and a barely-there art-deco chevron texture. This is what
separates "template" from "art-directed."

## Iconography
Hand-drawn deco line glyphs (currentColor) + octagonal brass medallions for
buildings + illustrated character busts. No OS emoji anywhere. One ornament: ◆.

## Rarity / status language (must be instant)
- **Locked**: desaturated, iron frame, lock glyph, dashed keyline.
- **For sale / affordable**: brass keyline breathes (slow glow); price in brass.
- **Unaffordable**: iron plaque, muted.
- **Owned / running**: lit, green production bar, tier chip.
- **Milestone tier** (rarity): chip + card edge tint climbs Bronze→Teal→Violet→Brass.
- **Raided**: police-tape stripe, red edge, boarded.
- **Rewarded/press**: paper headline burst.

## Motion principles
Restrained but juicy. Count-up on money, spring on card entrance, press-down on
buttons, one-shot bursts on milestones, ambient drift on the map. Everything
respects `prefers-reduced-motion`. 60fps on mid phones — capped particles,
pre-rendered map base, no per-frame layout.

## Restrained vs spectacular
- **Restrained**: panels, lists, labels, nav — quiet, legible, consistent.
- **Spectacular**: the map atmosphere, milestone/viral/raid/prestige moments,
  the money hero numbers, the prison and newspaper beats.

## The map (home screen) — from wireframe to illustrated board
Layered like a vintage board-game map: textured water with animated deco swells
and a coastline, illustrated district grounds (paper tint + road grid + park/
pier detail), buildings with real silhouettes, lit flickering windows, chimney
smoke, ambient traffic, a compass rose and a framed deco border, day/night key
light, and atmospheric edge fog. Labels on engraved plates.
