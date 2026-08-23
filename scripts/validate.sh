#!/bin/bash

# ============================================
# VALIDATION SCRIPT
# ============================================
#
# Runs every static check on the repository. Used by CI and safe to run
# locally before opening a Pull Request:
#
#   ./scripts/validate.sh
#
# Checks:
#   - Shell syntax (bash -n / sh -n)
#   - ShellCheck, when installed
#   - Config files parse (TOML, JSONC, kitty)
#   - Theme symlinks resolve
#   - Kitty and Alacritty palettes stay in sync
#   - Every theme color meets 4.5:1 contrast against its background

set -u

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR" || exit 1

FAILED=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAILED=1; }
skip() { printf '  \033[33m-\033[0m %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

head_ "Shell syntax"
for f in install.sh scripts/*.sh config/bin/*.sh; do
    [ "$f" = "scripts/validate.sh" ] && continue
    if bash -n "$f" 2>/dev/null; then pass "$f"; else fail "$f"; fi
done
if sh -n bootstrap.sh 2>/dev/null; then pass "bootstrap.sh (POSIX sh)"; else fail "bootstrap.sh"; fi

head_ "ShellCheck"
if command -v shellcheck &> /dev/null; then
    # SC2155 is style only; the color variables are used by sourced scripts.
    if shellcheck -x -S warning -e SC2155 install.sh bootstrap.sh scripts/*.sh config/bin/*.sh; then
        pass "no warnings or errors"
    else
        fail "see findings above"
    fi
else
    skip "shellcheck not installed"
fi

head_ "Config files parse"
python3 - <<'PY' && pass "TOML and JSONC" || fail "TOML or JSONC"
import json, re, sys, glob
try:
    import tomllib
except ImportError:
    import tomli as tomllib
ok = True
for f in ["config/starship/starship.toml"] + glob.glob("config/alacritty/**/*.toml", recursive=True):
    try:
        tomllib.load(open(f, "rb"))
    except Exception as e:
        print(f"    {f}: {e}"); ok = False
for f in glob.glob("config/**/*.jsonc", recursive=True):
    try:
        json.loads(re.sub(r"^\s*//.*$", "", open(f).read(), flags=re.M))
    except Exception as e:
        print(f"    {f}: {e}"); ok = False
sys.exit(0 if ok else 1)
PY

if command -v kitty &> /dev/null; then
    if kitty +runpy "from kitty.config import load_config; load_config('config/kitty/kitty.conf')" &> /dev/null; then
        pass "kitty config"
    else
        fail "kitty config"
    fi
else
    skip "kitty not installed"
fi

if command -v alacritty &> /dev/null; then
    if alacritty migrate --dry-run -c config/alacritty/alacritty.toml 2>&1 | grep -qiE "error|unknown"; then
        fail "alacritty config"
    else
        pass "alacritty config"
    fi
else
    skip "alacritty not installed"
fi

head_ "Theme symlinks"
for link in config/kitty/theme.conf config/alacritty/theme.toml; do
    if [ -L "$link" ] && [ -e "$link" ]; then
        pass "$link -> $(readlink "$link")"
    else
        fail "$link is missing, not a symlink, or dangling"
    fi
done

head_ "Palettes and contrast"
python3 - <<'PY' && pass "palettes in sync, all colors >= 4.5:1" || fail "see findings above"
import re, glob, os, sys

NAMES = ["black","red","green","yellow","blue","magenta","cyan","white"]
ok = True

def lum(h):
    h = h.lstrip("#"); r,g,b = [int(h[i:i+2],16)/255 for i in (0,2,4)]
    f = lambda c: c/12.92 if c <= 0.03928 else ((c+0.055)/1.055)**2.4
    return .2126*f(r) + .7152*f(g) + .0722*f(b)

def contrast(a,b):
    x,y = sorted([lum(a),lum(b)], reverse=True)
    return (x+.05)/(y+.05)

for kf in sorted(glob.glob("config/kitty/themes/*.conf")):
    name = os.path.basename(kf)[:-5]
    kt = open(kf).read()
    bg = re.search(r"^background\s+(#\w{6})", kt, re.M).group(1)
    kc = {m.group(1): m.group(2).upper()
          for m in re.finditer(r"^(color\d+)\s+(#\w{6})", kt, re.M)}

    # color0 is the background by design, so it is exempt.
    for slot, hexv in kc.items():
        if slot == "color0":
            continue
        r = contrast(bg, hexv)
        if r < 4.5:
            print(f"    {name}/{slot} {hexv} is {r:.2f}:1 against {bg}, needs 4.5:1")
            ok = False

    af = f"config/alacritty/themes/{name}.toml"
    if not os.path.exists(af):
        print(f"    {af} is missing"); ok = False; continue
    at = open(af).read()
    for section, off in (("normal",0), ("bright",8)):
        body = re.search(rf"\[colors\.{section}\](.*?)(?=\n\[|\Z)", at, re.S).group(1)
        for i, n in enumerate(NAMES):
            av = re.search(rf'^{n}\s*=\s*"(#\w{{6}})"', body, re.M).group(1).upper()
            kv = kc[f"color{i+off}"]
            if av != kv:
                print(f"    {name}: alacritty {section}.{n} is {av}, kitty color{i+off} is {kv}")
                ok = False

sys.exit(0 if ok else 1)
PY

head_ "Result"
if [ "$FAILED" -eq 0 ]; then
    printf '  \033[32mAll checks passed\033[0m\n\n'
else
    printf '  \033[31mSome checks failed\033[0m\n\n'
fi
exit "$FAILED"
