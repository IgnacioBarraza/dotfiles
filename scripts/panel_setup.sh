#!/bin/bash

# ============================================
# 12. PANEL EXTRAS SETUP SCRIPT
# ============================================
#
# Two things Plasma cannot do on its own:
#
#   - Panel Colorizer, which paints each widget its own rounded background so
#     one panel reads as a row of floating islands, and which can swap that
#     look automatically when a window touches the panel
#   - Widgets on the desktop itself rather than in a panel
#
# Upstream: https://github.com/luisbocanegra/plasma-panel-colorizer (GPL-3.0)
#
# Functions:
#   - setup_panel_extras: Main function
#   - install_panel_colorizer: Build and install the widget and its plugin
#   - add_panel_colorizer: Put it in the panel
#   - install_colorizer_presets: The panel-preset command
#   - apply_colorizer_preset: Pick the look
#   - configure_colorizer_autoloading: Stop its own rules overriding that
#   - apply_colorizer_translucency: Let the blur show through
#   - install_desktop_widgets: Clock, calendar, weather and media on the desktop
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, add_post_install_note)
#   - Colors defined in main script

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

COLORIZER_REPO="https://github.com/luisbocanegra/plasma-panel-colorizer"
COLORIZER_DIR="${COLORIZER_DIR:-$HOME/.local/src/plasma-panel-colorizer}"
COLORIZER_ID="luisbocanegra.panel.colorizer"

setup_panel_extras() {
    log_info "Starting panel extras setup"

    if ! command -v qdbus6 &> /dev/null || ! qdbus6 org.kde.plasmashell &> /dev/null; then
        log_info "plasmashell is not running, skipping the panel extras"
        return 0
    fi

    read -rp "Do you want the floating panel islands (Panel Colorizer)? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY])
        install_panel_colorizer && add_panel_colorizer &&
            install_colorizer_presets && apply_colorizer_preset &&
            configure_colorizer_autoloading && apply_colorizer_translucency
        ;;
    *)
        log_info "Skipping Panel Colorizer"
        ;;
    esac

    read -rp "Do you want clock, calendar, weather and media widgets on the desktop? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY]) install_desktop_widgets ;;
    *) log_info "Skipping the desktop widgets" ;;
    esac

    log_success "Panel extras setup completed"
}

install_panel_colorizer() {
    local packages=(
        git build-essential cmake extra-cmake-modules libplasma-dev
        kde-spectacle python3-dbus python3-gi gettext
    )
    local missing=()
    local package

    for package in "${packages[@]}"; do
        pkg_installed "$package" || missing+=("$package")
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        log_info "Installing build dependencies: ${missing[*]}"
        run_logged sudo apt install -y "${missing[@]}" || {
            log_error "Could not install the build dependencies"
            return 1
        }
    fi

    mkdir -p "$(dirname "$COLORIZER_DIR")"

    if [ -d "$COLORIZER_DIR/.git" ]; then
        log_info "Updating the existing checkout"
        run_logged git -C "$COLORIZER_DIR" pull --ff-only ||
            log_warning "Could not update, building what is there"
    else
        run_logged git clone --depth 1 "$COLORIZER_REPO" "$COLORIZER_DIR" || {
            log_error "Could not clone Panel Colorizer"
            return 1
        }
    fi

    # Its install.sh calls `python`, which Ubuntu does not provide: only
    # python3 exists unless python-is-python3 is installed. Rather than
    # reimplement the build, or install a package for the sake of one line, a
    # shim is put at the front of PATH for the length of the build. That keeps
    # working if upstream changes the steps.
    local shim
    shim="$(mktemp -d)" || return 1
    ln -sf "$(command -v python3)" "$shim/python"

    log_info "Building Panel Colorizer (this compiles a C++ plugin, give it a minute)..."

    if ! (cd "$COLORIZER_DIR" && PATH="$shim:$PATH" ./install.sh) 2>&1 | tee -a "$LOG"; then
        rm -rf "$shim"
        log_error "The Panel Colorizer build failed"
        return 1
    fi

    rm -rf "$shim"

    if [ ! -d "$HOME/.local/share/plasma/plasmoids/$COLORIZER_ID" ]; then
        log_error "The widget did not end up installed"
        return 1
    fi

    log_success "Panel Colorizer installed"
}

# The widget has to sit in the panel to do anything: it styles the panel it
# belongs to, so adding it is part of installing it.
add_panel_colorizer() {
    local present

    present="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var found = 0;
panels().forEach(function (p) {
    p.widgetIds.forEach(function (id) {
        if (p.widgetById(id).type === '$COLORIZER_ID') { found = 1; }
    });
});
print(found);
" 2>/dev/null)"

    if [ "$present" = "1" ]; then
        log_success "Panel Colorizer is already in the panel"
        return 0
    fi

    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var ps = panels();
if (ps.length > 0) { ps[0].addWidget('$COLORIZER_ID'); print('added'); }
" > /dev/null 2>&1

    add_post_install_note "Panel Colorizer is in your panel. Right click it > Configure to pick a preset; its 'Window touching the panel' preset is what keeps the floating look from collapsing when a window is maximised."

    log_success "Panel Colorizer added to the panel"
}

COLORIZER_PRESET="${COLORIZER_PRESET:-Nach0_0}"
COLORIZER_ALPHA="${COLORIZER_ALPHA:-0.6}"

# Presets are applied over D-Bus rather than through the settings dialog, which
# is what makes the look reproducible instead of a sequence of clicks. The
# broadcast form is used on purpose: addressing one widget needs its instance
# name, which changes every time it is added to a panel.
apply_colorizer_preset() {
    local preset attempt
    local dirs=(
        "$HOME/.config/panel-colorizer/presets"
        "$HOME/.local/share/plasma/plasmoids/$COLORIZER_ID/contents/ui/presets"
    )
    local dir

    for dir in "${dirs[@]}"; do
        if [ -d "$dir/$COLORIZER_PRESET" ]; then
            preset="$dir/$COLORIZER_PRESET"
            break
        fi
    done

    if [ -z "${preset:-}" ]; then
        log_warning "No preset named $COLORIZER_PRESET, leaving the panel plain"
        return 0
    fi

    # The widget has to have finished loading before it listens, and it has
    # just been added, so the first signal can land on nothing.
    for attempt in 1 2 3; do
        sleep 2
        dbus-send --session --type=signal /preset \
            luisbocanegra.panel.colorizer.all.preset "string:$preset" 2> /dev/null && break
    done

    log_success "Panel preset set to $COLORIZER_PRESET"
    add_post_install_note "Try other panel looks with: panel-preset (no arguments lists them)"
}

install_colorizer_presets() {
    local target="$HOME/.local/bin/panel-preset"
    local src="$DOTFILES_DIR/config/panel-colorizer/presets"
    local dest="$HOME/.config/panel-colorizer/presets"
    local preset count=0

    mkdir -p "$HOME/.local/bin" "$dest"

    # ~/.config is where the widget looks for presets that are not its own, so
    # ours sit beside the shipped ones and show up in the same lists.
    if [ -d "$src" ]; then
        for preset in "$src"/*/; do
            [ -d "$preset" ] || continue
            if cp -r "$preset" "$dest/"; then
                count=$((count + 1))
            fi
        done
        [ "$count" -gt 0 ] && log_success "$count panel presets installed"
    fi

    cat > "$target" <<'PRESET'
#!/bin/bash
# List and apply Panel Colorizer presets.
# Installed by the dotfiles; see scripts/panel_setup.sh.

set -u

DIRS=(
    "$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets"
    "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets"
    "$HOME/.config/panel-colorizer/presets"
)

find_preset() {
    local dir
    for dir in "${DIRS[@]}"; do
        [ -d "$dir/$1" ] && { printf '%s
' "$dir/$1"; return 0; }
    done
    return 1
}

list_presets() {
    local dir entry
    for dir in "${DIRS[@]}"; do
        [ -d "$dir" ] || continue
        for entry in "$dir"/*/; do
            [ -d "$entry" ] || continue
            basename "$entry"
        done
    done | sort -u
}

if [ "$#" -eq 0 ]; then
    echo "Usage: panel-preset <name>"
    echo ""
    echo "Available:"
    list_presets | sed 's/^/  /'
    exit 0
fi

preset="$(find_preset "$1")" || {
    echo "Unknown preset: $1" >&2
    echo "Run panel-preset with no arguments to list them." >&2
    exit 1
}

dbus-send --session --type=signal /preset     luisbocanegra.panel.colorizer.all.preset "string:$preset" || {
    echo "Could not reach Panel Colorizer. Is the widget in a panel?" >&2
    exit 1
}

echo "Panel preset: $1"
PRESET

    chmod +x "$target"
    log_success "panel-preset installed"
}

# The widget reloads a preset by itself on every start, from rules keyed on the
# panel and window state, and that reload wins over anything applied here.
#
# It is switched off rather than pointed at our preset. Every condition would
# name the same preset anyway - the look is meant to hold whatever the windows
# are doing - so the feature buys nothing and costs the settings underneath it:
# the reload resets backgroundColor.alpha to 1 whatever the preset file says,
# which puts the island fill back to opaque and hides the blur behind it. With
# autoloading off the settings live in appletsrc and survive a restart.
#
# The key belongs to the applet rather than to globalSettings, which is as far
# as the widget's D-Bus property method reaches: it answers "saved" and changes
# nothing. plasmashell also holds appletsrc open and rewrites it from memory,
# so the write happens with it stopped.
configure_colorizer_autoloading() {
    local service containment applet running=0

    # The instance name carries the ids: luisbocanegra.panel.colorizer.c3.w23
    service="$(busctl --user list --no-pager 2>/dev/null |
        grep -oE "$COLORIZER_ID\.c[0-9]+\.w[0-9]+" | head -1)"

    if [ -z "$service" ]; then
        log_warning "Could not find the Panel Colorizer instance, skipping autoloading"
        return 0
    fi

    containment="${service##*.c}"
    containment="${containment%%.*}"
    applet="${service##*.w}"

    backup_file "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

    if systemctl --user is-active plasma-plasmashell.service &> /dev/null; then
        running=1
        systemctl --user stop plasma-plasmashell.service
        sleep 2
    fi

    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
        --group Containments --group "$containment" \
        --group Applets --group "$applet" \
        --group Configuration --group General \
        --key presetAutoloading '{"enabled":false}'

    if [ "$running" = "1" ]; then
        systemctl --user start plasma-plasmashell.service
        sleep 5
    fi

    log_success "Preset autoloading disabled, the panel keeps what it is given"
}

# blurBehind draws a blur and then covers it with the island's own fill, so it
# shows nothing until the fill stops being opaque. The two are one setting in
# practice even though the widget presents them apart.
#
# It goes here rather than in the preset because the preset does not hold it:
# loading one resets alpha to 1 regardless of the file, which is the reason
# autoloading is off above.
apply_colorizer_translucency() {
    local service

    service="$(busctl --user list --no-pager 2>/dev/null |
        grep -oE "$COLORIZER_ID\.c[0-9]+\.w[0-9]+" | head -1)"

    [ -n "$service" ] || return 0

    qdbus6 "$service" /preset "$service.property" \
        "widgets.normal.backgroundColor.alpha $COLORIZER_ALPHA" > /dev/null 2>&1

    log_success "Island fill set to $COLORIZER_ALPHA so the blur shows"
}

# Widgets can live on the desktop containment as well as in a panel, which is
# where the clock, calendar, weather and media player in those setups sit.
install_desktop_widgets() {
    if ! pkg_installed plasma-widgets-addons; then
        log_info "Installing plasma-widgets-addons for the weather widget"
        run_logged sudo apt install -y plasma-widgets-addons ||
            log_warning "The weather widget will be missing"
    fi

    local added
    added="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var d = desktops()[0];
var want = ['org.kde.plasma.digitalclock', 'org.kde.plasma.calendar',
            'org.kde.plasma.weather', 'org.kde.plasma.mediacontroller'];
var have = {};
d.widgetIds.forEach(function (id) { have[d.widgetById(id).type] = 1; });

var added = 0;
want.forEach(function (name) {
    if (!have[name]) {
        d.addWidget(name);
        added++;
    }
});
print(added);
" 2>/dev/null)"

    if [ "${added:-0}" -gt 0 ]; then
        log_success "$added desktop widgets added"
        add_post_install_note "The desktop widgets start stacked in a corner. Enter Edit Mode (right click the desktop) to drag and size them."
    else
        log_info "The desktop widgets are already there"
    fi
}
