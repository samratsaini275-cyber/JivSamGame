#!/usr/bin/env python3
"""Download transparent game icons and colorize for Clout Empire.

Icons from https://game-icons.net (CC BY 3.0). See Resources/ATTRIBUTION.txt.
"""

from __future__ import annotations

import io
import ssl
import urllib.request
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "Sources" / "CloutEmpire" / "Resources" / "Images"
SIZE = 256
BASE = "https://game-icons.net/icons/000000/transparent/1x1"

# output_name -> (author, slug, RGB tint)
ICONS: dict[str, tuple[str, str, tuple[int, int, int]]] = {
    # Hustles
    "hustle_0": ("delapouite", "t-shirt", (255, 95, 120)),
    "hustle_1": ("delapouite", "running-shoe", (90, 200, 255)),
    "hustle_2": ("delapouite", "hoodie", (160, 120, 255)),
    "hustle_3": ("skoll", "stopwatch", (255, 200, 60)),
    "hustle_4": ("delapouite", "smartphone", (255, 150, 200)),
    "hustle_5": ("delapouite", "shop", (120, 230, 160)),
    "hustle_6": ("lorc", "castle", (180, 180, 255)),
    "hustle_7": ("delapouite", "large-dress", (255, 220, 120)),
    # Tabs
    "tab_empire": ("lorc", "castle", (255, 180, 80)),
    "tab_rex": ("delapouite", "sperm-whale", (100, 180, 255)),
    "tab_rebrand": ("delapouite", "paint-brush", (255, 120, 60)),
    "tab_profile": ("delapouite", "mug-shot", (200, 150, 255)),
    # HUD icons
    "icon_clout": ("delapouite", "round-star", (220, 160, 255)),
    "icon_hype": ("delapouite", "histogram", (80, 180, 255)),
    "icon_fire": ("sbed", "fire", (255, 140, 60)),
    "icon_sparkle": ("delapouite", "sparkles", (255, 230, 120)),
    # Rex — watches
    "rex_fauxlex": ("skoll", "pocket-watch", (180, 180, 180)),
    "rex_tagheuer": ("delapouite", "watch", (220, 180, 80)),
    "rex_daytona": ("delapouite", "watch", (255, 210, 80)),
    "rex_mille": ("lorc", "gem-pendant", (120, 255, 220)),
    # Rex — cars
    "rex_civic": ("delapouite", "city-car", (150, 200, 255)),
    "rex_charger": ("delapouite", "police-car", (255, 80, 80)),
    "rex_lambo": ("skoll", "f1-car", (255, 220, 60)),
    "rex_bugatti": ("skoll", "f1-car", (180, 100, 255)),
    # Persona — clothes
    "persona_thrifted": ("delapouite", "t-shirt", (200, 200, 200)),
    "persona_streetdrop": ("delapouite", "hoodie", (120, 200, 255)),
    "persona_designer": ("delapouite", "kimono", (255, 180, 100)),
    "persona_couture": ("delapouite", "large-dress", (255, 120, 200)),
    # Persona — jewelry
    "persona_fakechain": ("delapouite", "necklace-display", (210, 180, 90)),
    "persona_realchain": ("lorc", "gem-chain", (255, 210, 80)),
    "persona_grill": ("lorc", "front-teeth", (200, 240, 255)),
    "persona_iced": ("lorc", "gem-necklace", (180, 220, 255)),
    # Persona — watches
    "persona_p_fauxlex": ("skoll", "pocket-watch", (180, 180, 180)),
    "persona_p_tagheuer": ("delapouite", "watch", (220, 180, 80)),
    "persona_p_daytona": ("delapouite", "watch", (255, 210, 80)),
    "persona_p_mille": ("lorc", "gem-pendant", (120, 255, 220)),
    # Base looks
    "look_hoodie": ("delapouite", "hoodie", (120, 180, 255)),
    "look_bizcaz": ("delapouite", "tie", (80, 120, 200)),
    "look_street": ("delapouite", "heavy-collar", (40, 40, 50)),
    "look_gym": ("lorc", "muscle-up", (255, 100, 120)),
    # Rex lifestyle scenes
    "rex_scene_0": ("delapouite", "smartphone", (140, 200, 255)),
    "rex_scene_1": ("delapouite", "shower", (180, 220, 255)),
    "rex_scene_2": ("delapouite", "sunrise", (255, 180, 80)),
    "rex_scene_3": ("delapouite", "plane-wing", (200, 220, 255)),
    "rex_scene_4": ("delapouite", "plane-wing", (255, 200, 100)),
}

FALLBACKS: dict[str, tuple[str, str]] = {
    "tab_profile": ("delapouite", "plain-circle"),
}


def fetch_png(author: str, slug: str) -> Image.Image:
    url = f"{BASE}/{author}/{slug}.png"
    req = urllib.request.Request(url, headers={"User-Agent": "CloutEmpire/1.0"})
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
        data = resp.read()
    return Image.open(io.BytesIO(data)).convert("RGBA")


def tint_silhouette(img: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    """Recolor black-on-transparent icon."""
    r, g, b = rgb
    alpha = img.split()[3]
    colored = Image.new("RGBA", img.size, (r, g, b, 0))
    colored.putalpha(alpha)
    return colored


def add_cartoon_outline(img: Image.Image, stroke: int = 6) -> Image.Image:
    """Thick comic outline behind the tinted icon."""
    alpha = img.split()[3]
    # Expand silhouette for outline
    outline_mask = alpha.filter(ImageFilter.MaxFilter(stroke * 2 + 1))
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    border = Image.new("RGBA", img.size, (20, 16, 32, 255))
    border.putalpha(outline_mask)
    # Center icon on canvas with padding
    pad = 28
    scale = SIZE - pad * 2
    fitted = fit_icon(img, scale)
    fitted_border = fit_icon(border, scale)
    ox = (SIZE - fitted.width) // 2
    oy = (SIZE - fitted.height) // 2
    canvas.paste(fitted_border, (ox, oy), fitted_border)
    canvas.paste(fitted, (ox, oy), fitted)
    return canvas


def fit_icon(img: Image.Image, target: int) -> Image.Image:
    w, h = img.size
    scale = target / max(w, h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    return img.resize((nw, nh), Image.Resampling.LANCZOS)


def process(name: str, author: str, slug: str, rgb: tuple[int, int, int]) -> None:
    try:
        raw = fetch_png(author, slug)
    except Exception as e:
        if name in FALLBACKS:
            fb_author, fb_slug = FALLBACKS[name]
            print(f"  fallback {name}: {fb_author}/{fb_slug} ({e})")
            raw = fetch_png(fb_author, fb_slug)
        else:
            raise
    tinted = tint_silhouette(raw, rgb)
    final = add_cartoon_outline(tinted)
    OUT.mkdir(parents=True, exist_ok=True)
    final.save(OUT / f"{name}.png", "PNG")
    print(f"ok {name} <- {author}/{slug}")


def main() -> None:
    failed: list[str] = []
    for name, (author, slug, rgb) in ICONS.items():
        try:
            process(name, author, slug, rgb)
        except Exception as e:
            failed.append(f"{name}: {e}")
            print(f"FAIL {name}: {e}")
    print(f"\nWrote {len(ICONS) - len(failed)}/{len(ICONS)} icons to {OUT}")
    if failed:
        raise SystemExit("Failed icons:\n" + "\n".join(failed))


if __name__ == "__main__":
    main()
