#!/usr/bin/env python3
"""Generate the Plasma theme: the shape of the panel and of every popup.

The colours are deliberately not written here. Plasma rewrites the
<style id="current-color-scheme"> block of a theme SVG at runtime with the
active colour scheme, so an element that carries class="ColorScheme-Background"
and fill="currentColor" follows the palette on its own. One theme therefore
covers Kanagawa, Sakura and Yuki, and switching palettes needs no regeneration.

What is written here is the geometry the colour scheme cannot reach: corner
radius, margins and the mask Plasma uses to round and blur what sits behind.

A theme only has to define what it wants to change. Plasma falls back to the
default theme for every element it does not find, which is why this ships four
SVGs rather than the hundred and twenty of a complete theme.

Usage:
    generate_plasma_theme.py [--check]
"""

import argparse
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, "config/plasma/desktoptheme/Nach0_0")

# Popups are rounded harder than the panel: they float free, while the panel
# sits against an edge for most of its length.
DIALOG_RADIUS = 18
PANEL_RADIUS = 10
WIDGET_RADIUS = 14

# Below one, the wallpaper shows through and Plasma's blur behind the mask
# becomes visible. At one the blur is still computed and still drawn, just
# behind an opaque fill, which looks exactly like no blur at all.
DIALOG_OPACITY = 0.82
WIDGET_OPACITY = 0.82

STYLE = """  <defs>
    <style type="text/css" id="current-color-scheme">
      .ColorScheme-Background { color: #eff0f1; }
      .ColorScheme-Text { color: #232629; }
      .ColorScheme-Highlight { color: #3daee9; }
    </style>
  </defs>
"""


def corner(x, y, r, which, prefix, klass, opacity):
    """One rounded corner of the nine slice grid.

    The filled shape is the pie between the arc and the inner angle of the
    cell, so the bite is taken out of the outer angle and the four together
    close into a rounded rectangle. Written out per corner rather than derived
    from a sign, because a generic formula got the sweep flag wrong on two of
    them and the corners came out notched inwards instead of round.
    """
    # start, end, sweep. The pivot is always the inner angle of the cell.
    shapes = {
        "topleft": ((x, y + r), (x + r, y), 1, (x + r, y + r)),
        "topright": ((x, y), (x + r, y + r), 1, (x, y + r)),
        "bottomleft": ((x, y), (x + r, y + r), 0, (x + r, y)),
        "bottomright": ((x + r, y), (x, y + r), 1, (x, y)),
    }
    (sx, sy), (ex, ey), sweep, (px, py) = shapes[which]

    path = f"M {sx},{sy} A {r},{r} 0 0 {sweep} {ex},{ey} L {px},{py} Z"
    return (
        f'  <path id="{prefix}{which}" d="{path}" class="{klass}"\n'
        f'        fill="currentColor" fill-opacity="{opacity}"/>\n'
    )


def nine_slice(radius, klass, opacity, prefix=""):
    """The nine elements a FrameSvg looks up by id, laid out on a grid of
    radius-sized cells. Position is irrelevant to Plasma, which finds each
    element by its id and draws it on its own, but a grid keeps the file
    readable in an editor."""
    r = radius
    p = prefix
    out = []

    names = [
        ("topleft", 0, 0),
        ("topright", 2 * r, 0),
        ("bottomleft", 0, 2 * r),
        ("bottomright", 2 * r, 2 * r),
    ]
    for name, x, y in names:
        out.append(corner(x, y, r, name, p, klass, opacity))

    flats = [
        ("top", r, 0),
        ("bottom", r, 2 * r),
        ("left", 0, r),
        ("right", 2 * r, r),
        ("center", r, r),
    ]
    for name, x, y in flats:
        out.append(
            f'  <rect id="{p}{name}" x="{x}" y="{y}" width="{r}" height="{r}"\n'
            f'        class="{klass}" fill="currentColor" fill-opacity="{opacity}"/>\n'
        )

    return "".join(out)


def hints(radius, inset=0):
    """Margin hints keep content off the rounded corners. Without them Plasma
    uses the frame borders, and text ends up touching the curve."""
    margin = max(2, radius // 2)
    out = []
    for side in ("top", "bottom", "left", "right"):
        out.append(
            f'  <rect id="hint-{side}-margin" x="0" y="0"'
            f' width="{margin}" height="{margin}" opacity="0"/>\n'
        )
        if inset:
            out.append(
                f'  <rect id="hint-{side}-inset" x="0" y="0"'
                f' width="{inset}" height="{inset}" opacity="0"/>\n'
            )
    return "".join(out)


def frame_svg(radius, opacity=1.0, inset=0):
    size = 3 * radius
    body = (
        nine_slice(radius, "ColorScheme-Background", opacity)
        # The mask is what Plasma clips and blurs behind the frame. Without it
        # a rounded popup still casts a square shadow.
        + nine_slice(radius, "ColorScheme-Background", 1.0, prefix="mask-")
        + hints(radius, inset)
    )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}"\n'
        f'     viewBox="0 0 {size} {size}">\n{STYLE}{body}</svg>\n'
    )


# Shaped after the metadata of a theme that is known to work rather than cut to
# the minimum, since the format is not documented anywhere authoritative.
#
# Note that `kpackagetool6 --list -t Plasma/Theme` rejects this, and rejects
# every shipped theme too, so it is no guide at all: Plasma finds desktop themes
# by scanning plasma/desktoptheme directories, not through KPackage.
METADATA = """{
    "KPlugin": {
        "Authors": [
            {
                "Name": "Nach0_0"
            }
        ],
        "Category": "Plasma Theme",
        "Description": "Rounded panel and popups, coloured by the active scheme",
        "EnabledByDefault": true,
        "Id": "Nach0_0",
        "License": "GPL-3.0",
        "Name": "Nach0_0",
        "Version": "1.0",
        "Website": "https://github.com/IgnacioBarraza"
    },
    "X-Plasma-API": "5.0"
}
"""

FILES = {
    "metadata.json": METADATA,
    "dialogs/background.svg": frame_svg(DIALOG_RADIUS, DIALOG_OPACITY, inset=1),
    # The panel keeps a solid frame: Panel Colorizer hides it anyway and paints
    # each widget itself, so translucency here would only stack with its own.
    "widgets/panel-background.svg": frame_svg(PANEL_RADIUS),
    "widgets/background.svg": frame_svg(WIDGET_RADIUS, WIDGET_OPACITY),
    "widgets/tooltip.svg": frame_svg(DIALOG_RADIUS, DIALOG_OPACITY),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    missing = []

    for name, content in FILES.items():
        target = os.path.join(OUT_DIR, name)

        if args.check:
            if not os.path.exists(target):
                missing.append(os.path.relpath(target, REPO))
            continue

        os.makedirs(os.path.dirname(target), exist_ok=True)
        open(target, "w").write(content)

    if not args.check:
        print(f"  wrote {os.path.relpath(OUT_DIR, REPO)}/ ({len(FILES)} files)")

    for item in missing:
        print(f"    {item} is missing")

    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
