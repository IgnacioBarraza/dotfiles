#!/usr/bin/env python3
"""Generate Japanese pattern wallpapers from the Kitty palettes.

Three traditional geometric patterns, one file per pattern and palette, so a
theme switch has a matching background to move to.

The patterns are drawn deliberately low contrast. A wallpaper competes with
desktop icons, panel widgets and window shadows, so the lines sit only a little
above the background and the accent appears sparingly.

Usage:
    generate_wallpapers.py [--width 1920] [--height 1080] [--check]
"""

import argparse
import glob
import math
import os
import re
import sys

from PIL import Image, ImageDraw

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KITTY_THEMES = os.path.join(REPO, "config/kitty/themes")
OUT_DIR = os.path.join(REPO, "config/wallpapers")


def hex_to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def luminance(rgb):
    def channel(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def blend(a, b, amount):
    return tuple(round(x + (y - x) * amount) for x, y in zip(a, b))


def read_palette(path):
    text = open(path).read()

    def one(key):
        match = re.search(rf"^{key}\s+(#[0-9A-Fa-f]{{6}})", text, re.M)
        return hex_to_rgb(match.group(1)) if match else None

    return {
        "bg": one("background"),
        "fg": one("foreground"),
        "accent": one("active_border_color"),
    }


def seigaiha(draw, w, h, ink, accent):
    """青海波, blue sea waves: overlapping concentric arcs, the pattern used on
    Edo period maps for the sea."""
    unit = 120
    rings = 5
    step = unit // (rings * 2)

    row = 0
    y = -unit // 2
    while y < h + unit:
        offset = 0 if row % 2 == 0 else unit // 2
        x = -unit + offset
        while x < w + unit:
            for ring in range(rings):
                r = unit // 2 - ring * step
                if r <= 2:
                    continue
                colour = accent if (ring == 0 and (row + x // unit) % 7 == 0) else ink
                draw.arc(
                    [x - r, y - r, x + r, y + r],
                    start=180, end=360, fill=colour, width=2,
                )
            x += unit
        y += unit // 2
        row += 1


def asanoha(draw, w, h, ink, accent):
    """麻の葉, hemp leaf: a hexagonal star repeated on a triangular grid.
    Traditionally used on children's clothing, hemp being a fast grower."""
    # Larger than the other patterns on purpose: at a hundred pixels the
    # six-pointed star stops reading and the whole thing collapses into a plain
    # triangular grid.
    unit = 190
    height = unit * math.sqrt(3) / 2

    row = 0
    y = -height
    while y < h + height:
        offset = 0 if row % 2 == 0 else unit / 2
        x = -unit + offset
        while x < w + unit:
            cx, cy = x, y
            points = [
                (cx + unit / 2 * math.cos(math.radians(a)),
                 cy + unit / 2 * math.sin(math.radians(a)))
                for a in range(0, 360, 60)
            ]
            colour = accent if (row + int(x // unit)) % 11 == 0 else ink

            for i, point in enumerate(points):
                draw.line([cx, cy, point[0], point[1]], fill=colour, width=1)
                draw.line([point[0], point[1], points[(i + 1) % 6][0],
                           points[(i + 1) % 6][1]], fill=ink, width=1)
            x += unit
        y += height
        row += 1


def shippo(draw, w, h, ink, accent):
    """七宝, seven treasures: interlocking circles, a lattice standing for
    harmony and repetition."""
    # The circles have to overlap, otherwise the interlocking petals never
    # appear and the result is just a grid of circles. On a square grid of
    # spacing `unit` that means a radius of unit/sqrt(2), not half of it.
    unit = 150
    r = unit / math.sqrt(2)

    row = 0
    y = -unit
    while y < h + unit:
        offset = 0 if row % 2 == 0 else unit / 2
        x = -unit + offset
        while x < w + unit:
            colour = accent if (row * 3 + int(x // unit)) % 13 == 0 else ink
            draw.ellipse([x - r, y - r, x + r, y + r], outline=colour, width=2)
            x += unit
        y += unit / 2
        row += 1


PATTERNS = {"seigaiha": seigaiha, "asanoha": asanoha, "shippo": shippo}


def render(palette, pattern, width, height):
    bg = palette["bg"]
    light = luminance(bg) > 0.5

    # The lines have to stay close to the background: a wallpaper shares the
    # screen with icons and panels, so a high contrast pattern fights them.
    ink = blend(bg, palette["fg"], 0.10 if light else 0.13)
    accent = blend(bg, palette["accent"], 0.45 if light else 0.40)

    image = Image.new("RGB", (width, height), bg)
    draw = ImageDraw.Draw(image)
    PATTERNS[pattern](draw, width, height, ink, accent)
    return image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--width", type=int, default=1920)
    parser.add_argument("--height", type=int, default=1080)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)
    missing = []

    for path in sorted(glob.glob(os.path.join(KITTY_THEMES, "*.conf"))):
        name = os.path.basename(path)[:-5]
        palette = read_palette(path)

        for pattern in sorted(PATTERNS):
            target = os.path.join(OUT_DIR, f"{name}-{pattern}.png")

            if args.check:
                if not os.path.exists(target):
                    missing.append(os.path.relpath(target, REPO))
                continue

            render(palette, pattern, args.width, args.height).save(
                target, optimize=True
            )
            size = os.path.getsize(target) // 1024
            print(f"  wrote {os.path.relpath(target, REPO)} ({size} KB)")

    for item in missing:
        print(f"    {item} is missing")

    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
