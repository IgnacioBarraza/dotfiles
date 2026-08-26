#!/usr/bin/env python3
"""Generate KDE color schemes from the Kitty themes.

The Kitty themes in config/kitty/themes/ are the single source of truth for
every palette in this repository. Rather than transcribing 13 sections and
about 90 keys per theme by hand, the .colors files are derived from them.

CI runs this with --check, which regenerates in memory and fails if the
committed files differ, so a palette can never drift between the terminal and
the desktop.

Usage:
    generate_kde_colors.py            write config/kde/color-schemes/*.colors
    generate_kde_colors.py --check    verify the committed files match
"""

import colorsys
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KITTY_THEMES = os.path.join(REPO, "config/kitty/themes")
OUT_DIR = os.path.join(REPO, "config/kde/color-schemes")

# Display names, since KDE shows these in System Settings.
NAMES = {"sakura": "Sakura", "kanagawa": "Kanagawa", "yuki": "Yuki"}


def hex_to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def triplet(value):
    """KDE stores colours as decimal R,G,B rather than hex."""
    return "{},{},{}".format(*hex_to_rgb(value))


def shift(value, delta):
    """Move a colour by a fixed number of RGB units.

    Breeze derives its section backgrounds this way: Window 32,35,38 against
    Button 41,44,48 is a delta of nine. Blending by a fraction of the distance
    to the foreground instead produced jumps several times larger on a dark
    palette, and the foregrounds lost their contrast as a result."""
    r, g, b = hex_to_rgb(value)

    def clamp(component):
        return max(0, min(255, component + delta))

    return "#{:02X}{:02X}{:02X}".format(clamp(r), clamp(g), clamp(b))


def relative_luminance(value):
    def channel(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(c) for c in hex_to_rgb(value))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    high, low = sorted((relative_luminance(a), relative_luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def ensure_contrast(color, bg, target=4.5):
    """Nudge a colour's lightness until it clears `target` against bg.

    The terminal palettes are tuned against a single background. KDE derives
    eight, so a colour that only just clears 4.5:1 on the base background will
    not clear it on a lighter panel or a selection highlight. Hue and
    saturation are preserved, only lightness moves, so the colour still reads
    as the same colour."""
    if contrast(bg, color) >= target:
        return color

    hue, lightness, saturation = colorsys.rgb_to_hls(*(c / 255 for c in hex_to_rgb(color)))
    lighten = relative_luminance(bg) < 0.5
    best = color

    for step in range(1, 1001):
        fraction = step / 1000
        moved = (lightness + fraction * (1 - lightness)) if lighten else (lightness * (1 - fraction))
        candidate = "#{:02X}{:02X}{:02X}".format(
            *(max(0, min(255, round(v * 255)))
              for v in colorsys.hls_to_rgb(hue, moved, saturation))
        )
        best = candidate
        if contrast(bg, candidate) >= target:
            break

    return best


def read_kitty_theme(path):
    text = open(path).read()

    def one(key):
        match = re.search(rf"^{key}\s+(#[0-9A-Fa-f]{{6}})", text, re.M)
        return match.group(1) if match else None

    colors = {
        int(m.group(1)): m.group(2)
        for m in re.finditer(r"^color(\d+)\s+(#[0-9A-Fa-f]{6})", text, re.M)
    }

    return {
        "background": one("background"),
        "foreground": one("foreground"),
        "selection_bg": one("selection_background"),
        "selection_fg": one("selection_foreground"),
        # The theme already nominates its own accent for the focused border,
        # so there is no need to invent one here.
        "accent": one("active_border_color"),
        "colors": colors,
    }


def build(theme):
    bg = theme["background"]
    fg = theme["foreground"]
    c = theme["colors"]
    accent = theme["accent"]

    light = relative_luminance(bg) > 0.5

    # Breeze raises buttons, headers and tooltips above the window, and sinks
    # views below it. On a light palette both directions flip.
    raise_by = -12 if light else 9
    sink_by = 10 if light else -8
    alt_by = -6 if light else 6

    window_bg = bg
    view_bg = shift(bg, sink_by)
    raised_bg = shift(bg, raise_by)

    backgrounds = {
        "Colors:Button": raised_bg,
        "Colors:Complementary": window_bg,
        "Colors:Header": raised_bg,
        "Colors:Header][Inactive": window_bg,
        "Colors:Selection": theme["selection_bg"],
        "Colors:Tooltip": raised_bg,
        "Colors:View": view_bg,
        "Colors:Window": window_bg,
    }

    dim = c[8]

    def foregrounds(section_bg, normal=None, inactive=None):
        """Every foreground is checked against the background it actually sits
        on, not against the base background of the theme."""
        raw = {
            "DecorationFocus": accent,
            "DecorationHover": accent,
            "ForegroundActive": accent,
            "ForegroundInactive": inactive or dim,
            "ForegroundLink": c[4],
            "ForegroundNegative": c[1],
            "ForegroundNeutral": c[3],
            "ForegroundNormal": normal or fg,
            "ForegroundPositive": c[2],
            "ForegroundVisited": c[5],
        }
        out = {}
        for key, value in raw.items():
            # Decoration* are focus rings and hover fills rather than text, so
            # they are held to the 3:1 that WCAG asks of non-text contrast.
            target = 3.0 if key.startswith("Decoration") else 4.5
            out[key] = ensure_contrast(value, section_bg, target)
        return out

    sections = {}
    for section, section_bg in backgrounds.items():
        if section == "Colors:Selection":
            keys = foregrounds(section_bg,
                               normal=theme["selection_fg"],
                               inactive=theme["selection_fg"])
        else:
            keys = foregrounds(section_bg)

        keys["BackgroundNormal"] = section_bg
        keys["BackgroundAlternate"] = shift(section_bg, alt_by)
        sections[section] = keys

    wm_active_bg = raised_bg
    wm = {
        "activeBackground": wm_active_bg,
        "activeBlend": ensure_contrast(accent, wm_active_bg, 3.0),
        "activeForeground": ensure_contrast(fg, wm_active_bg),
        "inactiveBackground": window_bg,
        "inactiveBlend": ensure_contrast(dim, window_bg),
        "inactiveForeground": ensure_contrast(dim, window_bg),
    }

    return sections, wm


def render(name, theme):
    sections, wm = build(theme)
    display = NAMES[name]

    out = [
        f"# {display} colour scheme",
        "#",
        "# Generated by scripts/generate_kde_colors.py from",
        f"# config/kitty/themes/{name}.conf. Do not edit by hand: CI regenerates",
        "# this file and fails if the result differs.",
        "",
        "[ColorEffects:Disabled]",
        f"Color={triplet(theme['colors'][8])}",
        "ColorAmount=0",
        "ColorEffect=0",
        "ContrastAmount=0.65",
        "ContrastEffect=1",
        "IntensityAmount=0.1",
        "IntensityEffect=2",
        "",
        "[ColorEffects:Inactive]",
        "ChangeSelectionColor=true",
        f"Color={triplet(theme['colors'][8])}",
        "ColorAmount=0.025",
        "ColorEffect=2",
        "ContrastAmount=0.1",
        "ContrastEffect=2",
        "Enable=false",
        "IntensityAmount=0",
        "IntensityEffect=0",
        "",
    ]

    for section in sorted(sections):
        out.append(f"[{section}]")
        for key in sorted(sections[section]):
            out.append(f"{key}={triplet(sections[section][key])}")
        out.append("")

    out += [
        "[General]",
        f"ColorScheme={display}",
        f"Name={display}",
        "shadeSortColumn=true",
        "",
        "[KDE]",
        "contrast=4",
        "",
        "[WM]",
    ]
    for key in sorted(wm):
        out.append(f"{key}={triplet(wm[key])}")
    out.append("")

    return "\n".join(out)


def check_contrast(name, theme):
    """The terminal palettes are held to 4.5:1, and the desktop derived from
    them should not quietly fall below that."""
    sections, wm = build(theme)
    problems = []

    for section, keys in sections.items():
        bg = keys["BackgroundNormal"]
        for key, value in keys.items():
            if not key.startswith("Foreground"):
                continue
            ratio = contrast(bg, value)
            if ratio < 4.5:
                problems.append(f"{name}: {section} {key} {value} on {bg} is {ratio:.2f}:1")

    for pair in (("activeBackground", "activeForeground"),
                 ("inactiveBackground", "inactiveForeground")):
        ratio = contrast(wm[pair[0]], wm[pair[1]])
        if ratio < 4.5:
            problems.append(f"{name}: WM {pair[1]} on {pair[0]} is {ratio:.2f}:1")

    return problems


def render_theme_map(themes):
    """A small table the plasma-theme switcher reads, so the shadow colour and
    the icon variant move with the palette instead of being pinned to whichever
    theme happened to be the default."""
    lines = [
        "# Generated by scripts/generate_kde_colors.py. Do not edit by hand.",
        "#",
        "# name | colour scheme | icon theme | shadow | plasma theme | accent",
        "#",
        "# The shadow colour is the darkest colour in the palette, taken down a",
        "# little further: tinted rather than pure black, but still a shadow.",
        "# Papirus-Dark is drawn for dark panels, so a light palette takes",
        "# Papirus-Light instead, and the Plasma theme follows the same split:",
        "# it is what colours the panel and the popups, which the colour scheme",
        "# alone does not touch.",
        "#",
        "# The accent is the palette's own focused-border colour, so the",
        "# highlight Plasma draws matches the one the terminal draws.",
        "",
    ]

    for name in sorted(themes):
        theme = themes[name]
        light = relative_luminance(theme["background"]) > 0.5

        # A shadow is always darker than what it falls on. Deriving it from the
        # View background worked on the dark themes by coincidence and gave a
        # light theme pure white, which is not a shadow at all. Start from the
        # darkest colour the palette defines and take it down a little further.
        darkest = min(theme["background"], theme["colors"][0], key=relative_luminance)
        shadow = shift(darkest, -8)
        icons = "Papirus-Light" if light else "Papirus-Dark"
        plasma = "breeze-light" if light else "breeze-dark"
        lines.append(
            f"{name} | {NAMES[name]} | {icons} | {triplet(shadow)} | "
            f"{plasma} | {triplet(theme['accent'])}"
        )

    return "\n".join(lines) + "\n"


def main():
    check = "--check" in sys.argv
    failures = []
    themes = {}
    os.makedirs(OUT_DIR, exist_ok=True)

    for path in sorted(glob.glob(os.path.join(KITTY_THEMES, "*.conf"))):
        name = os.path.basename(path)[:-5]
        if name not in NAMES:
            continue

        theme = read_kitty_theme(path)
        themes[name] = theme
        content = render(name, theme)
        target = os.path.join(OUT_DIR, f"{NAMES[name]}.colors")

        failures.extend(check_contrast(name, theme))

        if check:
            if not os.path.exists(target):
                failures.append(f"{target} is missing")
            elif open(target).read() != content:
                failures.append(f"{os.path.relpath(target, REPO)} is stale, regenerate it")
        else:
            open(target, "w").write(content)
            print(f"  wrote {os.path.relpath(target, REPO)}")

    map_target = os.path.join(os.path.dirname(OUT_DIR), "themes.conf")
    map_content = render_theme_map(themes)

    if check:
        if not os.path.exists(map_target):
            failures.append(f"{map_target} is missing")
        elif open(map_target).read() != map_content:
            failures.append(f"{os.path.relpath(map_target, REPO)} is stale, regenerate it")
    else:
        open(map_target, "w").write(map_content)
        print(f"  wrote {os.path.relpath(map_target, REPO)}")

    for problem in failures:
        print(f"    {problem}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
