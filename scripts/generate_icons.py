#!/usr/bin/env python3
"""Generate cartoon game icons for Clout Empire (thick outline, bright fills)."""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "Sources" / "CloutEmpire" / "Resources" / "Images"
SIZE = 256
STROKE = 10


def new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def outline(draw: ImageDraw.ImageDraw, xy, fill, width: int = STROKE, **kwargs):
    draw.rounded_rectangle(xy, radius=18, fill=(20, 16, 32), width=width, **kwargs)
    inner = [xy[0] + width, xy[1] + width, xy[2] - width, xy[3] - width]
    draw.rounded_rectangle(inner, radius=14, fill=fill, **kwargs)


def save(img: Image.Image, name: str):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.png", "PNG")
    print("wrote", name)


def hustle_bootleg(draw, s):
    outline(draw, [40, 50, 216, 200], (255, 95, 120))
    draw.polygon([(128, 58), (188, 95), (170, 175), (86, 175), (68, 95)], fill=(255, 200, 80))
    draw.rectangle([98, 115, 158, 145], fill=(40, 40, 60))
    draw.text((108, 118), "FAKE", fill=(255, 255, 255))


def hustle_sneaker(draw, s):
    outline(draw, [35, 95, 221, 185], (90, 200, 255))
    draw.polygon([(55, 145), (205, 145), (185, 115), (75, 115)], fill=(255, 255, 255))
    draw.ellipse([70, 125, 200, 175], fill=(255, 80, 120))
    draw.line([(90, 140), (180, 140)], fill=(40, 40, 60), width=6)


def hustle_hoodie(draw, s):
    outline(draw, [45, 45, 211, 205], (160, 120, 255))
    draw.rounded_rectangle([70, 70, 186, 185], radius=30, fill=(90, 70, 200))
    draw.ellipse([108, 95, 148, 125], fill=(200, 180, 255))
    draw.polygon([(55, 95), (70, 130), (70, 185), (45, 185)], fill=(70, 50, 160))
    draw.polygon([(201, 95), (186, 130), (186, 185), (211, 185)], fill=(70, 50, 160))


def hustle_drop(draw, s):
    outline(draw, [50, 50, 206, 206], (255, 200, 60))
    draw.rounded_rectangle([78, 88, 178, 148], radius=12, fill=(40, 40, 60))
    draw.text((98, 100), "00:59", fill=(255, 80, 80))
    draw.polygon([(128, 155), (98, 195), (158, 195)], fill=(255, 120, 60))


def hustle_collab(draw, s):
    outline(draw, [40, 40, 216, 216], (255, 150, 200))
    draw.rounded_rectangle([95, 55, 161, 175], radius=16, fill=(50, 50, 70))
    draw.ellipse([108, 75, 148, 115], fill=(255, 210, 180))
    draw.rectangle([118, 120, 138, 140], fill=(255, 255, 255))


def hustle_popup(draw, s):
    outline(draw, [35, 70, 221, 200], (120, 230, 160))
    draw.polygon([(40, 95), (216, 95), (200, 185), (56, 185)], fill=(255, 240, 200))
    draw.rectangle([95, 120, 161, 165], fill=(255, 100, 100))
    draw.text((108, 128), "POP", fill=(255, 255, 255))


def hustle_flagship(draw, s):
    outline(draw, [30, 55, 226, 205], (180, 180, 255))
    draw.rectangle([55, 85, 201, 185], fill=(240, 240, 255))
    for x in range(70, 190, 28):
        draw.rectangle([x, 95, x + 14, 175], fill=(100, 120, 255))
    draw.polygon([(128, 55), (95, 85), (161, 85)], fill=(255, 200, 80))


def hustle_couture(draw, s):
    outline(draw, [40, 40, 216, 216], (255, 220, 120))
    draw.polygon([(128, 60), (185, 120), (165, 200), (91, 200), (71, 120)], fill=(255, 255, 255))
    draw.line([(128, 75), (128, 190)], fill=(255, 180, 200), width=8)
    for i in range(5):
        draw.ellipse([60 + i * 28, 35, 88 + i * 28, 55], fill=(255, 200, 80))


def tab_empire(draw, s):
    outline(draw, [45, 65, 211, 195], (255, 180, 80))
    draw.rectangle([75, 95, 181, 175], fill=(255, 240, 200))
    draw.polygon([(75, 95), (128, 60), (181, 95)], fill=(255, 100, 100))
    draw.rectangle([115, 125, 141, 175], fill=(120, 80, 50))


def tab_rex(draw, s):
    outline(draw, [40, 40, 216, 216], (100, 180, 255))
    draw.ellipse([70, 70, 186, 186], fill=(180, 220, 255))
    draw.ellipse([95, 100, 120, 125], fill=(40, 40, 60))
    draw.ellipse([136, 100, 161, 125], fill=(40, 40, 60))
    draw.arc([95, 120, 161, 155], 10, 170, fill=(40, 40, 60), width=6)
    draw.polygon([(170, 55), (210, 75), (195, 95), (165, 80)], fill=(100, 180, 255))


def tab_rebrand(draw, s):
    outline(draw, [50, 50, 206, 206], (255, 120, 60))
    draw.polygon([(128, 65), (175, 175), (81, 175)], fill=(255, 220, 80))
    draw.polygon([(128, 95), (155, 155), (101, 155)], fill=(255, 140, 60))


def tab_profile(draw, s):
    outline(draw, [45, 45, 211, 211], (200, 150, 255))
    draw.rounded_rectangle([85, 90, 171, 190], radius=20, fill=(255, 200, 220))
    draw.ellipse([108, 55, 148, 95], fill=(255, 210, 180))


def icon_clout(draw, s):
    outline(draw, [50, 50, 206, 206], (220, 160, 255))
    draw.polygon([
        (128, 70), (145, 115), (195, 120), (155, 150),
        (168, 200), (128, 175), (88, 200), (101, 150),
        (61, 120), (111, 115),
    ], fill=(255, 240, 120))


def icon_hype(draw, s):
    outline(draw, [35, 85, 221, 195], (80, 180, 255))
    for i, h in enumerate([40, 65, 50, 75, 55]):
        x = 55 + i * 34
        draw.polygon([(x, 175), (x + 17, 175 - h), (x + 34, 175)], fill=(200, 240, 255))


def icon_fire(draw, s):
    outline(draw, [55, 55, 201, 201], (255, 140, 60))
    draw.polygon([(128, 75), (165, 140), (145, 190), (111, 190), (91, 140)], fill=(255, 220, 80))


def icon_sparkle(draw, s):
    icon_clout(draw, s)


def rex_watch(draw, s, tier: int):
    colors = [(180, 180, 180), (220, 180, 80), (255, 210, 80), (120, 255, 220)]
    outline(draw, [55, 70, 201, 186], colors[tier - 1])
    draw.rounded_rectangle([88, 95, 168, 165], radius=20, fill=(60, 60, 80))
    draw.ellipse([108, 110, 148, 150], fill=(240, 240, 255))


def rex_car(draw, s, tier: int):
    colors = [(150, 200, 255), (255, 80, 80), (255, 220, 60), (180, 100, 255)]
    outline(draw, [35, 100, 221, 175], colors[tier - 1])
    draw.rounded_rectangle([55, 115, 201, 155], radius=20, fill=(255, 255, 255))
    draw.ellipse([70, 145, 100, 175], fill=(40, 40, 60))
    draw.ellipse([156, 145, 186, 175], fill=(40, 40, 60))


def persona_slot(draw, s, slot: str, tier: int):
    colors = [(200, 200, 200), (120, 200, 255), (255, 180, 100), (255, 120, 200)]
    c = colors[tier - 1]
    if slot == "clothes":
        outline(draw, [45, 45, 211, 211], c)
        draw.rounded_rectangle([80, 85, 176, 190], radius=24, fill=(255, 255, 255) if tier > 1 else (180, 180, 200))
    elif slot == "jewelry":
        outline(draw, [50, 80, 206, 176], c)
        draw.arc([78, 80, 178, 180], 200, 340, fill=(255, 220, 80), width=14)
    else:
        rex_watch(draw, s, tier)


def look_avatar(draw, s, kind: str):
    outline(draw, [40, 40, 216, 216], (255, 200, 150))
    draw.ellipse([88, 75, 168, 145], fill=(255, 220, 190))
    if kind == "hoodie":
        draw.rounded_rectangle([75, 140, 181, 210], radius=20, fill=(120, 180, 255))
        draw.rectangle([95, 55, 161, 85], fill=(255, 80, 80))
    elif kind == "bizcaz":
        draw.polygon([(128, 145), (181, 210), (75, 210)], fill=(80, 120, 200))
        draw.rectangle([108, 145, 148, 190], fill=(255, 255, 255))
    elif kind == "street":
        draw.rounded_rectangle([75, 145, 181, 210], radius=16, fill=(40, 40, 50))
        draw.rectangle([95, 60, 161, 80], fill=(40, 40, 50))
    else:
        draw.rounded_rectangle([85, 140, 171, 210], radius=16, fill=(255, 100, 120))


HUSTLES = [
    ("hustle_0", hustle_bootleg),
    ("hustle_1", hustle_sneaker),
    ("hustle_2", hustle_hoodie),
    ("hustle_3", hustle_drop),
    ("hustle_4", hustle_collab),
    ("hustle_5", hustle_popup),
    ("hustle_6", hustle_flagship),
    ("hustle_7", hustle_couture),
]

REX_IDS = ["fauxlex", "tagheuer", "daytona", "mille", "civic", "charger", "lambo", "bugatti"]
PERSONA_IDS = [
    "thrifted", "streetdrop", "designer", "couture",
    "fakechain", "realchain", "grill", "iced",
    "p_fauxlex", "p_tagheuer", "p_daytona", "p_mille",
]
PERSONA_SLOTS = ["clothes"] * 4 + ["jewelry"] * 4 + ["watch"] * 4
LOOKS = ["hoodie", "bizcaz", "street", "gym"]


def main():
    for name, fn in HUSTLES:
        img, draw = new_canvas()
        fn(draw, SIZE)
        save(img, name)

    for name, fn in [
        ("tab_empire", tab_empire),
        ("tab_rex", tab_rex),
        ("tab_rebrand", tab_rebrand),
        ("tab_profile", tab_profile),
        ("icon_clout", icon_clout),
        ("icon_hype", icon_hype),
        ("icon_fire", icon_fire),
        ("icon_sparkle", icon_sparkle),
    ]:
        img, draw = new_canvas()
        fn(draw, SIZE)
        save(img, name)

    for i, rid in enumerate(REX_IDS):
        img, draw = new_canvas()
        if i < 4:
            rex_watch(draw, SIZE, (i % 4) + 1)
        else:
            rex_car(draw, SIZE, (i % 4) + 1)
        save(img, f"rex_{rid}")

    for pid, slot in zip(PERSONA_IDS, PERSONA_SLOTS):
        tier = (PERSONA_IDS.index(pid) % 4) + 1
        if pid.startswith("p_"):
            tier = ["p_fauxlex", "p_tagheuer", "p_daytona", "p_mille"].index(pid) + 1
        elif pid in ("thrifted", "fakechain"):
            tier = 1
        elif pid in ("streetdrop", "realchain"):
            tier = 2
        elif pid in ("designer", "grill"):
            tier = 3
        else:
            tier = 4
        img, draw = new_canvas()
        persona_slot(draw, SIZE, slot, tier)
        save(img, f"persona_{pid}")

    for look in LOOKS:
        img, draw = new_canvas()
        look_avatar(draw, SIZE, look)
        save(img, f"look_{look}")

    # Rex scene tiers
    for tier in range(5):
        img, draw = new_canvas()
        outline(draw, [30, 60, 226, 196], (140, 200, 255))
        draw.text((90, 120), f"LV{tier}", fill=(255, 255, 255))
        save(img, f"rex_scene_{tier}")


if __name__ == "__main__":
    main()
