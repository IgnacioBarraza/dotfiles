#!/usr/bin/env python3
"""Generate the torii login backgrounds from the Kitty palettes.

A torii marks the boundary between the ordinary and the sacred, which is a
fair description of a login screen. One file per palette.

Unlike the desktop wallpapers this is a scene rather than a tiling pattern, but
it draws from the same palettes and reuses their sea wave pattern for the
water, so the login screen cannot drift from the rest of the theme.

Usage:
    generate_login_backgrounds.py [--width 1920] [--height 1080] [--check]
"""

import argparse
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from generate_wallpapers import blend, hex_to_rgb, luminance, read_palette, seigaiha

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KITTY_THEMES = os.path.join(REPO, "config/kitty/themes")
OUT_DIR = os.path.join(REPO, "config/login")


def sky(image, top, bottom, horizon):
    """Vertical gradient, darkest at the top, lifting towards the horizon."""
    from PIL import ImageDraw

    draw = ImageDraw.Draw(image)
    for y in range(horizon):
        draw.line([(0, y), (image.width, y)],
                  fill=blend(top, bottom, y / horizon))


def sun(draw, cx, cy, r, colour):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=colour)


def beam(draw, cx, y, half, thickness, sag, colour, flare=1.0):
    """A torii lintel. The ends lift, which is what separates a 明神 torii from
    the plain 神明 one, so the curve is the whole character of the shape."""
    steps = 80
    top, bottom = [], []

    for i in range(steps + 1):
        t = i / steps
        x = cx - half + 2 * half * t
        # Ends rise: the offset is negative at the edges, zero at the centre.
        lift = sag * ((x - cx) / half) ** 2
        # The beam also deepens towards the ends on a real torii.
        thick = thickness * (1 + (flare - 1) * abs(x - cx) / half)
        top.append((x, y - lift - thick / 2))
        bottom.append((x, y - lift + thick / 2))

    draw.polygon(top + bottom[::-1], fill=colour)


def torii(draw, w, h, waterline, ink, dark):
    height = int(h * 0.62)
    top = waterline - height
    cx = w // 2

    # Pillars lean inwards (転び) and taper. Both are slight; overdo either and
    # the gate reads as a cartoon rather than a structure.
    base_half = int(w * 0.170)
    lean = 0.93
    base_w = int(height * 0.040)
    top_w = int(base_w * 0.86)

    pillar_top = top + int(height * 0.10)

    for side in (-1, 1):
        bx = cx + side * base_half
        tx = cx + side * base_half * lean
        draw.polygon([
            (bx - base_w / 2, waterline),
            (bx + base_w / 2, waterline),
            (tx + top_w / 2, pillar_top),
            (tx - top_w / 2, pillar_top),
        ], fill=dark)

    top_half = base_half * lean

    # 貫, the tie beam. It passes through the pillars and juts out a little.
    nuki_y = top + int(height * 0.26)
    nuki_h = int(height * 0.028)
    draw.rectangle([cx - top_half * 1.18, nuki_y - nuki_h / 2,
                    cx + top_half * 1.18, nuki_y + nuki_h / 2], fill=dark)

    # 額束, the strut between the two beams.
    strut_w = int(base_w * 0.55)
    draw.rectangle([cx - strut_w / 2, top + int(height * 0.10),
                    cx + strut_w / 2, nuki_y], fill=dark)

    # 島木 then 笠木: the lower beam is squarer, the crowning one sweeps wider.
    beam(draw, cx, top + int(height * 0.105), top_half * 1.24,
         height * 0.032, height * 0.028, dark)
    beam(draw, cx, top + int(height * 0.058), top_half * 1.34,
         height * 0.026, height * 0.040, ink, flare=1.30)


def render(palette, sun_colour, width, height):
    # See generate_wallpapers.render: --check must not need Pillow.
    from PIL import Image, ImageDraw, ImageFilter

    bg = palette["bg"]
    light = luminance(bg) > 0.5

    waterline = int(height * 0.78)

    # Kept close to the background. The login form sits in the middle of this
    # with nothing but a text shadow behind it, so the scene has to stay a
    # backdrop rather than become a picture.
    if light:
        top_sky = blend(bg, palette["fg"], 0.09)
        low_sky = bg
    else:
        top_sky = blend(bg, (0, 0, 0), 0.22)
        low_sky = blend(bg, palette["accent"], 0.10)

    image = Image.new("RGB", (width, height), bg)
    sky(image, top_sky, low_sky, waterline)

    # Low and small: a setting sun inside the gate. Higher or larger and it
    # lands behind the password field.
    sun_y = int(height * 0.66)
    sun_r = int(height * 0.075)
    disc = blend(low_sky, sun_colour, 0.60 if not light else 0.45)

    # Drawn as a halo and then a disc on top. Blurring one mask for both turns
    # the sun into a smudge with no edge; the halo alone carries the softness.
    #
    # The source image is filled with the sun's colour edge to edge and the
    # mask decides what shows. Filling it with black instead leaves a dark ring
    # where the blur feathers out, invisible on a dark palette and glaring on
    # a light one.
    source = Image.new("RGB", (width, height), disc)

    halo = Image.new("L", (width, height), 0)
    sun(ImageDraw.Draw(halo), width // 2, sun_y, int(sun_r * 1.3), 90)
    image.paste(source, (0, 0),
                halo.filter(ImageFilter.GaussianBlur(sun_r * 0.55)))

    edge = Image.new("L", (width, height), 0)
    sun(ImageDraw.Draw(edge), width // 2, sun_y, sun_r, 255)
    image.paste(source, (0, 0), edge.filter(ImageFilter.GaussianBlur(1.5)))

    water = blend(bg, (0, 0, 0), 0.14) if not light else blend(bg, palette["fg"], 0.07)
    ImageDraw.Draw(image).rectangle([0, waterline, width, height], fill=water)

    # Same 青海波 as the desktop wallpapers, clipped to the water.
    sea = Image.new("RGB", (width, height - waterline), water)
    seigaiha(ImageDraw.Draw(sea), width, height - waterline,
             blend(water, palette["fg"], 0.10),
             blend(water, sun_colour, 0.22))
    image.paste(sea, (0, waterline))

    draw = ImageDraw.Draw(image)

    # A silhouette against the sky, so it darkens rather than picking up the
    # accent. The two beams differ slightly to keep the crown readable.
    dark = blend(bg, (0, 0, 0), 0.45) if not light else blend(bg, palette["fg"], 0.62)
    ink = blend(dark, (0, 0, 0), 0.30) if not light else blend(dark, palette["fg"], 0.20)

    torii(draw, width, height, waterline, ink, dark)
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
        target = os.path.join(OUT_DIR, f"{name}-torii.png")

        if args.check:
            if not os.path.exists(target):
                missing.append(os.path.relpath(target, REPO))
            continue

        # The accent is not always warm (Sakura's is gold), and a torii sun
        # wants vermilion, so it comes from the palette's red instead.
        match = re.search(r"^color1\s+(#[0-9A-Fa-f]{6})", open(path).read(), re.M)
        sun_colour = hex_to_rgb(match.group(1)) if match else palette["accent"]

        render(palette, sun_colour, args.width, args.height).save(
            target, optimize=True)
        size = os.path.getsize(target) // 1024
        print(f"  wrote {os.path.relpath(target, REPO)} ({size} KB)")

    for item in missing:
        print(f"    {item} is missing")

    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
