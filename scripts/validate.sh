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
    if bash -n "$f" 2>/dev/null; then pass "$f"; else fail "$f"; fi
done
if python3 -c "import ast,sys;ast.parse(open(sys.argv[1]).read())" scripts/check_glyphs.py 2>/dev/null; then
    pass "scripts/check_glyphs.py"
else
    fail "scripts/check_glyphs.py"
fi
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

head_ "Entry points"
# install.sh must survive being started with sh, not just bash: it re-execs
# itself. Without that it printed a few errors and carried on into the
# installer with none of its functions loaded.
for shell in bash sh; do
    if out="$("$shell" install.sh --help 2>&1)" \
       && ! printf '%s' "$out" | grep -q "Bad substitution\|not found"; then
        pass "$shell install.sh --help"
    else
        fail "$shell install.sh --help"
    fi
done

if bash install.sh --dry-run > /dev/null 2>&1; then
    pass "install.sh --dry-run"
else
    fail "install.sh --dry-run"
fi

for shell in bash sh; do
    if "$shell" -n bootstrap.sh 2>/dev/null; then
        pass "bootstrap.sh parses under $shell"
    else
        fail "bootstrap.sh under $shell"
    fi
done

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

head_ "Glyphs"
if python3 "$REPO_DIR/scripts/check_glyphs.py" "$REPO_DIR"; then
    pass "every symbol has a glyph, every glyph has a font"
else
    fail "see findings above"
fi

head_ "Compose stack"
python3 - "$REPO_DIR" <<'COMPOSE_EOF' && pass "compose stack parses, every port bound to 127.0.0.1" || fail "see findings above"
import os, re, sys

repo = sys.argv[1]
path = os.path.join(repo, "config/docker/docker-compose.yml")

if not os.path.exists(path):
    print("    no compose stack in the repo, nothing to check")
    sys.exit(0)

try:
    import yaml
except ImportError:
    # Without PyYAML, still enforce the property that matters: a published port
    # with no explicit host is bound to 0.0.0.0 and exposes the database.
    ok = True
    for n, line in enumerate(open(path), 1):
        m = re.match(r'\s*-\s*"([^"]+)"\s*$', line)
        if m and re.match(r"^\d+:\d+$", m.group(1)):
            print(f"    line {n}: port {m.group(1)} has no host, which binds 0.0.0.0")
            ok = False
    print("    PyYAML missing, checked ports only")
    sys.exit(0 if ok else 1)

data = yaml.safe_load(open(path))
ok = True

services = data.get("services") or {}

# Anything another service waits on with condition: service_healthy has to
# have a healthcheck, or compose refuses to start the stack.
depended_on = set()
for svc in services.values():
    dep = svc.get("depends_on")
    if isinstance(dep, dict):
        depended_on.update(dep)
    elif isinstance(dep, list):
        depended_on.update(dep)

for name, svc in services.items():
    # The port rule applies everywhere: a bare "5432:5432" binds 0.0.0.0.
    for port in svc.get("ports", []):
        if not str(port).startswith("127.0.0.1:"):
            print(f"    {name}: port {port} is not bound to 127.0.0.1")
            ok = False

    # Services behind a profile are opt-in extras that nothing waits on, so a
    # healthcheck is optional for them.
    needs_health = name in depended_on or not svc.get("profiles")
    if needs_health and not svc.get("healthcheck"):
        print(f"    {name}: no healthcheck")
        ok = False

sys.exit(0 if ok else 1)
COMPOSE_EOF

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
