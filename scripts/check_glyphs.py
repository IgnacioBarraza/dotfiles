#!/usr/bin/env python3
"""Check that every glyph in the config files survives and has a font.

Two separate problems are checked here:

1. Lost glyphs. Writing these files through a pipeline that mangles the
   Private Use Area silently turns `symbol = " "` into `symbol = " "`.
   The file still parses as valid TOML, so no other check notices.

2. Missing coverage. A glyph that no installed font provides renders as a
   tofu box. This half is skipped when the fonts are not installed.

Usage: check_glyphs.py <repo_dir>
"""

import glob
import os
import re
import struct
import subprocess
import sys


def font_charset(path, index=0):
    """Return the set of codepoints a TTF or TTC covers, read from its cmap."""
    data = open(path, "rb").read()

    if data[:4] == b"ttcf":
        count = struct.unpack(">I", data[8:12])[0]
        base = struct.unpack(f">{count}I", data[12:12 + 4 * count])[index]
    else:
        base = 0

    num_tables = struct.unpack(">H", data[base + 4:base + 6])[0]
    cmap = None
    for i in range(num_tables):
        rec = base + 12 + 16 * i
        if data[rec:rec + 4] == b"cmap":
            cmap = struct.unpack(">I", data[rec + 8:rec + 12])[0]
            break
    if cmap is None:
        return set()

    charset = set()
    for i in range(struct.unpack(">H", data[cmap + 2:cmap + 4])[0]):
        rec = cmap + 4 + 8 * i
        sub = cmap + struct.unpack(">I", data[rec + 4:rec + 8])[0]
        fmt = struct.unpack(">H", data[sub:sub + 2])[0]

        if fmt == 12:
            for j in range(struct.unpack(">I", data[sub + 12:sub + 16])[0]):
                grp = sub + 16 + 12 * j
                start, end, _ = struct.unpack(">III", data[grp:grp + 12])
                charset.update(range(start, min(end, start + 0x10000) + 1))

        elif fmt == 4:
            seg_x2 = struct.unpack(">H", data[sub + 6:sub + 8])[0]
            seg = seg_x2 // 2
            ends = struct.unpack(f">{seg}H", data[sub + 14:sub + 14 + seg_x2])
            starts = struct.unpack(f">{seg}H",
                                   data[sub + 16 + seg_x2:sub + 16 + 2 * seg_x2])
            for start, end in zip(starts, ends):
                if start != 0xFFFF:
                    charset.update(range(start, end + 1))

    return charset


def resolve_font(family):
    """Path to an installed font family, or None if fontconfig substituted it."""
    out = subprocess.run(["fc-match", "-f", "%{family[0]}\t%{file}", family],
                         capture_output=True, text=True).stdout
    if "\t" not in out:
        return None
    matched, path = out.split("\t", 1)
    return path.strip() if matched.strip() == family else None


def check_symbols(repo):
    """Every `symbol =` in starship.toml must still hold a glyph."""
    ok = True
    path = os.path.join(repo, "config/starship/starship.toml")
    body = open(path).read()

    for match in re.finditer(r"^\[([a-z_.]+)\]((?:(?!\n\[).)*)", body, re.M | re.S):
        section, section_body = match.group(1), match.group(2)
        symbol = re.search(r'^symbol\s*=\s*"(.*?)"', section_body, re.M)
        if symbol and not symbol.group(1).strip():
            print(f"    [{section}] symbol is empty, its glyph was probably lost")
            ok = False

    return ok


def check_coverage(repo):
    """Every non-ASCII glyph in the configs must come from an installed font."""
    nerd = resolve_font("FiraCode Nerd Font Mono")
    cjk = resolve_font("Noto Sans CJK JP")

    if not nerd or not cjk:
        print("    fonts not installed, skipping coverage check")
        return True

    covered = font_charset(nerd) | font_charset(cjk)
    ok = True

    files = ([os.path.join(repo, "config/starship/starship.toml")]
             + glob.glob(os.path.join(repo, "config/kitty/*.conf"))
             + glob.glob(os.path.join(repo, "config/fastfetch/*.jsonc")))

    for path in files:
        missing = {c for c in open(path).read()
                   if ord(c) > 0x2000 and ord(c) not in covered}
        for char in sorted(missing):
            rel = os.path.relpath(path, repo)
            print(f"    {rel}: U+{ord(char):04X} has no font")
            ok = False

    return ok


def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    return 0 if all([check_symbols(repo), check_coverage(repo)]) else 1


if __name__ == "__main__":
    sys.exit(main())
