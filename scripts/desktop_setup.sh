#!/bin/bash

# ============================================
# 08. DESKTOP SETUP SCRIPT
# ============================================
#
# This script themes the KDE Plasma desktop.
#
# Caelestia is offered here as the alternative, and lives in
# caelestia_setup.sh. Picking it hands over entirely: it replaces the Plasma
# shell rather than theming it, so nothing below runs.
#
# The colour schemes are generated from the Kitty themes by
# scripts/generate_kde_colors.py, so the desktop and the terminal cannot drift
# apart. See config/kde/.
#
# Functions:
#   - setup_desktop: Main function
#   - install_kde_color_schemes: Copy the schemes and select one
#   - apply_kde_color_scheme: Make a scheme the active one
#   - apply_kde_settings: Apply config/kde/settings.conf with kwriteconfig6
#   - install_papirus_icons: Install the icon theme
#   - install_theme_switcher: Install the plasma-theme helper
#   - install_wallpapers: Copy the generated wallpapers and the rotator
#   - install_wallpaper_shortcut: Bind Meta+K to the rotator
#   - install_wallpaper_menu: Grid picker on Meta+Shift+K
#   - install_desktop_switcher: The desktop-mode command
#   - install_panel: Create the floating panel
#   - apply_window_decoration: Darkly if present, Breeze otherwise
#   - setup_krunner: KRunner plugin, lives in krunner_setup.sh
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for run_logged, backup_file, add_post_install_note)
#   - Colors defined in main script

# Set by install.sh; recomputed when this file is sourced on its own.
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

KDE_SCHEME_DIR="$HOME/.local/share/color-schemes"
# Kanagawa rather than Sakura: Sakura's accent is a gold, and Plasma paints
# the accent on the active task in the panel, where a gold badge reads as an
# unread notification. Kanagawa's is a blue and does not.
DEFAULT_KDE_SCHEME="Kanagawa"
DEFAULT_KDE_THEME="kanagawa"

setup_desktop() {
    log_info "Starting desktop setup"

    if [ ! -d "$DOTFILES_DIR/config/kde" ]; then
        log_warning "No KDE configuration found at config/kde/, skipping"
        return 0
    fi

    # Everything below writes to Plasma's own configuration. On GNOME, which is
    # what Ubuntu ships by default, none of it has any effect.
    if ! command -v kwriteconfig6 &> /dev/null; then
        log_info "KDE Plasma not detected, skipping the desktop theme"
        return 0
    fi

    install_desktop_switcher

    log_info "Select a desktop theme"
    echo ""
    echo "  1) Nach0_0 (Plasma theming: colours, fonts, icons, wallpapers)"
    echo "  2) Caelestia (replaces the Plasma shell with a Quickshell one)"
    echo "  3) Skip"
    echo ""

    read -rp "Enter your choice [1|2|3]: " choice

    case "$choice" in
    1) ;;
    2)
        install_caelestia
        return $?
        ;;
    *)
        log_info "Skipping the desktop theme"
        return 0
        ;;
    esac

    install_kde_color_schemes

    install_papirus_icons

    apply_kde_settings

    install_theme_switcher

    install_wallpapers

    install_wallpaper_shortcut

    install_wallpaper_menu

    install_panel

    apply_window_decoration

    setup_krunner

    apply_palette_settings

    log_success "Desktop setup completed"
}

# Caelestia and the Plasma theme cannot both be live: Caelestia's bar would sit
# on top of our panel, and its colour daemon rewrites the palette we just set.
# Neither installer turns the other off, so this switches between them.
install_desktop_switcher() {
    local target="$HOME/.local/bin/desktop-mode"

    mkdir -p "$HOME/.local/bin"

    cat > "$target" <<'SWITCH'
#!/bin/bash
# Switch between the Caelestia shell and the Plasma theme.
# Installed by the dotfiles; see scripts/desktop_setup.sh.

set -u

AUTOSTART="$HOME/.config/autostart/caelestiashell.desktop"
APPS="$HOME/.local/share/applications"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-desktop-mode"
LOCK_GROUPS=(--group Greeter --group Wallpaper
             --group net.dosowisko.PlasmaApplicationWallpaper --group General)

usage() {
    echo "Usage: desktop-mode [caelestia|plasma|status]"
    echo ""
    echo "  caelestia  the Quickshell desktop"
    echo "  plasma     the themed Plasma desktop"
    echo "  status     print which one is active"
    exit "${1:-0}"
}

evaluate() {
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1" 2>/dev/null
}

# Prints the panel count, or nothing when plasmashell will not answer. Keeping
# those two apart is the whole point: the first version compared the raw query
# to "0", so an unanswered query read as "a panel already exists" and it
# skipped creating one without a word. plasmashell is briefly unreachable right
# after the Caelestia shell is killed, which is exactly when this is asked.
panel_count() {
    local count attempt

    for attempt in 1 2 3 4 5; do
        count="$(evaluate 'print(panels().length)')"
        case "$count" in
        "" | *[!0-9]*) sleep 1 ;;
        *)
            echo "$count"
            return 0
            ;;
        esac
    done

    return 1
}

# Hidden=true is the freedesktop way of saying "deleted for this user". It
# takes the shortcut out of the service database without losing the file, so
# switching back does not have to rebuild it.
set_hidden() {
    [ -f "$1" ] || return 0
    kwriteconfig6 --file "$1" --group "Desktop Entry" --key Hidden "$2"
}

# Caelestia does not ask KWin to share Alt+Tab, Meta+Tab, Meta+W and the
# desktop switching keys: it empties them. Its own stolen-shortcuts.json is
# meant to record what it took so it can hand them back, and it stays empty, so
# nothing gives them back on the way out.
#
# An entry is active,default,description. The description can hold commas of
# its own, so only the first two fields are split off, and alternatives within
# a field are separated by a literal \t.
#
# The rule is: restore when what is active is a strict subset of what the entry
# declares as its default. That catches an entry emptied outright ("\t"), one
# left half-cleared ("Meta+Shift+Tab\t") and one set to "none", while leaving a
# binding the user actually chose alone, since that is not a subset.
restore_kwin_shortcuts() {
    local rc="$HOME/.config/kglobalshortcutsrc"
    local tmp count

    [ -f "$rc" ] || return 0
    tmp="$(mktemp)" || return 1

    awk '
    function slots(spec, out,   n, i, parts, kept) {
        n = split(spec, parts, "\\\\t")
        kept = 0
        for (i = 1; i <= n; i++) {
            if (parts[i] != "" && parts[i] != "none") {
                out[parts[i]] = 1
                kept++
            }
        }
        return kept
    }
    /^\[/ { inkwin = ($0 == "[kwin]") }
    {
        if (!inkwin || $0 !~ /=/) { print; next }

        eq = index($0, "=")
        key = substr($0, 1, eq)
        rest = substr($0, eq + 1)

        c1 = index(rest, ",")
        if (!c1) { print; next }
        active = substr(rest, 1, c1 - 1)
        tail = substr(rest, c1 + 1)

        c2 = index(tail, ",")
        if (!c2) { print; next }
        fallback = substr(tail, 1, c2 - 1)
        desc = substr(tail, c2 + 1)

        delete A; delete D
        na = slots(active, A)
        nd = slots(fallback, D)

        subset = (na < nd)
        for (k in A) { if (!(k in D)) subset = 0 }

        if (subset && nd > 0) {
            printf "%s%s,%s,%s\n", key, fallback, fallback, desc
            restored++
        } else {
            print
        }
    }
    END { printf("%d", restored) > "/dev/stderr" }
    ' "$rc" > "$tmp" 2> "$tmp.count"

    if [ -s "$tmp" ]; then
        mv "$tmp" "$rc"
        count="$(cat "$tmp.count" 2>/dev/null)"
        [ "${count:-0}" -gt 0 ] &&
            echo "Restored $count KWin shortcuts (Alt+Tab, Meta+W, desktops)"
    fi

    rm -f "$tmp" "$tmp.count"
}

rebuild_cache() {
    command -v kbuildsycoca6 > /dev/null 2>&1 && kbuildsycoca6 > /dev/null 2>&1
}

unit() {
    systemctl --user "$1" "$2" > /dev/null 2>&1 || true
}

to_caelestia() {
    echo "Switching to Caelestia..."

    evaluate 'panels().forEach(function (p) { p.remove(); })' > /dev/null

    set_hidden "$APPS/dotfiles-wallpaper-next.desktop" true
    set_hidden "$APPS/dotfiles-wallpaper-menu.desktop" true
    unit disable dotfiles-runner.service
    unit stop dotfiles-runner.service

    set_hidden "$AUTOSTART" false
    unit enable kde-material-you-colors.service
    unit start kde-material-you-colors.service

    # Its lock screen runs quickshell, which needs the import path its own
    # installer leaves out. See caelestia-fixups.
    if [ -f "$HOME/.config/quickshell/caelestia/lockscreen.qml" ]; then
        kwriteconfig6 --file kscreenlockerrc --group Greeter             --key WallpaperPlugin net.dosowisko.PlasmaApplicationWallpaper
        kwriteconfig6 --file kscreenlockerrc "${LOCK_GROUPS[@]}" --key command             "QML2_IMPORT_PATH=$HOME/.local/lib/qt6/qml quickshell -p $HOME/.config/quickshell/caelestia/lockscreen.qml"
    fi

    rebuild_cache
    command -v caelestia > /dev/null 2>&1 && caelestia shell -d > /dev/null 2>&1

    echo "caelestia" > "$STATE"
    echo "Done. Log out and back in if the bar does not appear."
}

to_plasma() {
    local theme="${1:-kanagawa}"

    # This switches between two installed desktops; it does not install either.
    # Without the check the Plasma side comes up bare - no shortcuts, no
    # KRunner entries - with nothing on screen to say why.
    if [ ! -x "$HOME/.local/bin/plasma-theme" ] ||
        [ ! -f "$HOME/.local/share/krunner/dbusplugins/dotfiles-runner.desktop" ]; then
        echo "The Plasma desktop is not installed yet." >&2
        echo "Run ./install.sh --desktop and pick option 1 first." >&2
        return 1
    fi

    echo "Switching to Plasma..."

    command -v caelestia > /dev/null 2>&1 && caelestia shell -k > /dev/null 2>&1
    set_hidden "$AUTOSTART" true

    # The one that matters: it derives the palette from the wallpaper on a
    # timer, so left running it undoes the colour scheme within seconds.
    unit stop kde-material-you-colors.service
    unit disable kde-material-you-colors.service

    release_caelestia_shortcuts
    restore_kwin_shortcuts

    set_hidden "$APPS/dotfiles-wallpaper-next.desktop" false
    set_hidden "$APPS/dotfiles-wallpaper-menu.desktop" false
    unit enable dotfiles-runner.service
    unit start dotfiles-runner.service

    local panels
    if ! panels="$(panel_count)"; then
        echo "plasmashell is not answering; the panel was not created." >&2
        echo "Run 'desktop-mode plasma' again once the desktop has settled." >&2
        panels="unknown"
    fi

    if [ "$panels" = "0" ]; then
        evaluate '
var panel = new Panel("org.kde.panel");
panel.location = "bottom";
panel.height = 46;
panel.floating = true;
panel.lengthMode = "fit";
panel.alignment = "center";
panel.addWidget("org.kde.plasma.kickoff");
panel.addWidget("org.kde.plasma.icontasks");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
' > /dev/null
    fi

    rebuild_cache

    # Restores the colours the daemon may have overwritten, and points the lock
    # screen back at a plain image.
    if command -v plasma-theme > /dev/null 2>&1; then
        plasma-theme "$theme" || true
    fi

    mkdir -p "$(dirname "$STATE")"
    echo "plasma" > "$STATE"
    echo "Done. Log out and back in to drop the last of Caelestia's shortcuts."
}

case "${1:-status}" in
-h | --help) usage 0 ;;
caelestia) to_caelestia ;;
plasma) to_plasma "${2:-kanagawa}" ;;
status)
    if [ -r "$STATE" ]; then
        echo "Mode: $(cat "$STATE")"
    else
        echo "Mode: unknown (never switched)"
    fi
    pgrep -f 'quickshell.*caelestia' > /dev/null && echo "  Caelestia shell: running"
    echo "  Plasma panels: $(evaluate 'print(panels().length)')"
    ;;
*)
    echo "Unknown mode: $1" >&2
    usage 1
    ;;
esac
SWITCH

    chmod +x "$target"

    log_success "desktop-mode installed to $target"
}

# Built through Plasma's scripting API over D-Bus rather than by writing
# plasma-org.kde.plasma.desktop-appletsrc. plasmashell keeps that file open and
# rewrites it from its own memory, so edits to it are either ignored or undone
# at the next save.
#
# lengthMode "fit" is what makes it a floating bar rather than a full-width
# one: the panel shrinks to its contents instead of spanning the screen.
install_panel() {
    local existing

    if ! command -v qdbus6 &> /dev/null; then
        log_info "qdbus6 not found, skipping the panel"
        return 0
    fi

    if ! qdbus6 org.kde.plasmashell &> /dev/null; then
        log_info "plasmashell is not running, skipping the panel"
        return 0
    fi

    # evaluateScript returns whatever the script prints, not what it evaluates
    # to, so every value that has to come back goes through print().
    existing="$(qdbus6 org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript 'print(panels().length)' 2>/dev/null)"

    if [ "${existing:-0}" != "0" ]; then
        log_info "A panel already exists, leaving the layout alone"
        log_info "Remove it in Edit Mode first if you want ours instead"
        return 0
    fi

    local script
    script='
var panel = new Panel("org.kde.panel");
panel.location = "bottom";
panel.height = 46;
panel.floating = true;
panel.lengthMode = "fit";
panel.alignment = "center";
panel.addWidget("org.kde.plasma.kickoff");
panel.addWidget("org.kde.plasma.icontasks");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
print(panel.widgetIds.length);
'

    local widgets
    widgets="$(qdbus6 org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript "$script" 2>/dev/null)"

    if [ "${widgets:-0}" = "5" ]; then
        log_success "Floating panel created with $widgets widgets"
    else
        log_warning "The panel may not have been created correctly"
    fi
}

# The colour scheme is only part of a theme: the Plasma theme, the accent and
# the lock screen wallpaper follow the palette too. Rather than repeat that
# list here, the installer runs the switcher it just installed, so a fresh
# install and a later `plasma-theme sakura` cannot mean different things.
apply_palette_settings() {
    local switcher="$HOME/.local/bin/plasma-theme"

    if [ ! -x "$switcher" ]; then
        log_warning "The theme switcher is not installed, skipping"
        return 0
    fi

    if ! command -v plasma-apply-colorscheme &> /dev/null; then
        log_info "Not a Plasma session, the theme applies at the next login"
        return 0
    fi

    if run_logged "$switcher" "$DEFAULT_KDE_THEME"; then
        log_success "Palette settings applied: $DEFAULT_KDE_THEME"
    else
        log_warning "Could not apply every palette setting"
    fi
}

install_kde_color_schemes() {
    local src="$DOTFILES_DIR/config/kde/color-schemes"

    if [ ! -d "$src" ]; then
        log_warning "No colour schemes at config/kde/color-schemes/"
        return 0
    fi

    mkdir -p "$KDE_SCHEME_DIR"

    local file name count=0

    for file in "$src"/*.colors; do
        [ -f "$file" ] || continue
        name="$(basename "$file")"

        if [ -f "$KDE_SCHEME_DIR/$name" ]; then
            backup_file "$KDE_SCHEME_DIR/$name"
        fi

        if cp "$file" "$KDE_SCHEME_DIR/$name"; then
            count=$((count + 1))
        else
            log_error "Could not install $name"
        fi
    done

    if [ "$count" -eq 0 ]; then
        log_error "No colour schemes were installed"
        return 1
    fi

    log_success "$count colour schemes installed to $KDE_SCHEME_DIR"

    apply_kde_color_scheme "$DEFAULT_KDE_SCHEME"
}

apply_kde_color_scheme() {
    local scheme="$1"

    if [ ! -f "$KDE_SCHEME_DIR/${scheme}.colors" ]; then
        log_error "Colour scheme $scheme is not installed"
        return 1
    fi

    backup_file "$HOME/.config/kdeglobals"

    # plasma-apply-colorscheme only works against a running Plasma session. On
    # any other desktop it cannot do anything, so the scheme is written into
    # kdeglobals directly and Plasma reads it at the next login.
    if [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ] && command -v plasma-apply-colorscheme &> /dev/null; then
        if run_logged plasma-apply-colorscheme "$scheme"; then
            log_success "Colour scheme applied to the running session: $scheme"
            return 0
        fi
        log_warning "plasma-apply-colorscheme failed, writing kdeglobals instead"
    else
        log_info "Not in a Plasma session, writing kdeglobals for the next login"
    fi

    write_kdeglobals_colors "$KDE_SCHEME_DIR/${scheme}.colors" "$scheme" || return 1

    log_success "Colour scheme set to $scheme"
    add_post_install_note "Log into a Plasma session to see the $scheme colour scheme. Switch themes in System Settings > Colors, or with: plasma-apply-colorscheme Kanagawa"
}

# Plasma reads the active colours out of kdeglobals rather than out of the
# scheme file, so selecting a scheme means copying its sections across.
write_kdeglobals_colors() {
    local scheme_file="$1"
    local scheme_name="$2"

    if ! command -v kwriteconfig6 &> /dev/null; then
        log_error "kwriteconfig6 not found, cannot write kdeglobals"
        return 1
    fi

    local group="" line key value

    while IFS= read -r line; do
        case "$line" in
        "") continue ;;
        \#*) continue ;;
        \[*\])
            group="${line#[}"
            group="${group%]}"
            continue
            ;;
        esac

        # Only the colour groups are copied: the scheme's [General] Name and
        # the ColorEffects belong to the scheme, not to the global config.
        case "$group" in
        Colors:* | WM) ;;
        *) continue ;;
        esac

        key="${line%%=*}"
        value="${line#*=}"

        # "Colors:Header][Inactive" is a nested group in KDE's config format,
        # and kwriteconfig6 takes nesting as repeated --group arguments. Passing
        # the whole string as one group wrote a literal [Colors:Header\x5d\x5bInactive]
        # section that Plasma then ignored.
        local -a group_args=()
        local part
        local rest="$group"

        while [ "$rest" != "${rest#*][}" ]; do
            part="${rest%%\]\[*}"
            group_args+=(--group "$part")
            rest="${rest#*][}"
        done
        group_args+=(--group "$rest")

        kwriteconfig6 --file kdeglobals "${group_args[@]}" --key "$key" "$value" || {
            log_error "Could not write $group/$key to kdeglobals"
            return 1
        }
    done < "$scheme_file"

    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$scheme_name"
    kwriteconfig6 --file kdeglobals --group General --key Name "$scheme_name"
}

install_papirus_icons() {
    if pkg_installed papirus-icon-theme; then
        log_success "Papirus icons are already installed"
        return 0
    fi

    log_info "Installing Papirus icons..."

    if run_logged sudo apt install -y papirus-icon-theme; then
        log_success "Papirus icons installed"
    else
        log_error "Failed to install Papirus icons"
        return 1
    fi
}

# Binding a shortcut that Plasma already uses does not fail: kwriteconfig6
# writes it happily and the existing owner keeps winning, so the new binding
# silently does nothing. Meta+W went in that way and stayed dead because KWin
# has it for Overview.
shortcut_is_free() {
    local combo="$1"
    local owner="$2"
    # "=" counts as a delimiter: the first shortcut on a line sits right after
    # it, as in "Show Desktop=Meta+A,,". Matching only on commas and line
    # boundaries missed every action whose binding has no alternatives.
    local pattern="(^|,|=)${combo//+/\\+}(,|$)"

    # Alternative bindings for one action are joined with a literal \t, as in
    # "Lock Session=Meta+L\tScreensaver,...". Matching on commas alone reported
    # Meta+L as free, so the separators are normalised first.
    normalise() {
        sed 's/\\t/,/g'
    }

    # The user's own file, skipping the whole section this run is about to
    # write. Filtering by line only removed the [services][x.desktop] header
    # and left its _launch= key behind, so a rerun saw its own binding as
    # somebody else's and refused to renew it.
    if [ -f "$HOME/.config/kglobalshortcutsrc" ] &&
       awk -v owner="$owner" '
           /^\[/ { skip = index($0, owner) > 0 }
           !skip
       ' "$HOME/.config/kglobalshortcutsrc" 2>/dev/null |
       normalise | grep -qE "$pattern"; then
        return 1
    fi

    # Defaults shipped by applications, which the user's file does not repeat.
    if grep -rh "" /usr/share/kglobalaccel/ 2>/dev/null |
       normalise | grep -qE "$pattern"; then
        return 1
    fi

    # Applications declare their own shortcuts with X-KDE-Shortcuts in their
    # desktop entry. Skipping this reported Meta+I as free when System Settings
    # already claims it.
    #
    # The owner's own file is excluded: on a second run the entry written by
    # the first one would otherwise be read as somebody else's claim, and the
    # binding would refuse to renew itself.
    if grep -rh --exclude="$owner" "^X-KDE-Shortcuts=" \
           /usr/share/applications/ "$HOME/.local/share/applications/" 2>/dev/null |
       sed 's/^X-KDE-Shortcuts=/,/' | normalise | grep -qE "$pattern"; then
        return 1
    fi

    return 0
}

# Drop a [services][<desktop>] block from kglobalshortcutsrc.
#
# kglobalaccel builds a component per group it finds there. For a group whose
# desktop file it has not yet scanned, that component is created with nothing
# behind it, and an empty component never grabs its keys. The stale group then
# shadows the real one for the rest of the session. Earlier versions of this
# script wrote such a group, so clear it out before it can do that again.
drop_shortcut_group() {
    local desktop="$1"
    local rc="$HOME/.config/kglobalshortcutsrc"

    [ -f "$rc" ] || return 0
    grep -qF "[services][$desktop]" "$rc" 2>/dev/null || return 0

    local tmp
    tmp="$(mktemp)" || return 1

    awk -v header="[services][$desktop]" '
        /^\[/ { drop = ($0 == header) }
        !drop
    ' "$rc" > "$tmp" && mv "$tmp" "$rc" || {
        rm -f "$tmp"
        return 1
    }
}

# Bind a key combination to a desktop entry.
#
# The binding itself lives in the desktop file, as X-KDE-Shortcuts. That is how
# Plasma's own entries do it, and it is the only form kglobalaccel turns into a
# working grab: it scans the service cache at session start and registers what
# it finds. Writing the combination into kglobalshortcutsrc instead produces an
# entry that System Settings displays but no key press ever reaches.
#
# Nothing here takes effect until the next login, because the scan only runs
# when the session starts.
bind_shortcut() {
    local desktop="$1"
    local combo="$2"
    local description="$3"

    if ! shortcut_is_free "$combo" "$desktop"; then
        log_warning "$combo is already taken, not binding $description"
        log_info "Bind it by hand in System Settings > Shortcuts, or pick another combo"
        return 1
    fi

    if ! grep -qF "X-KDE-Shortcuts=$combo" \
        "$HOME/.local/share/applications/$desktop" 2>/dev/null; then
        log_warning "$desktop does not declare X-KDE-Shortcuts=$combo"
        return 1
    fi

    drop_shortcut_group "$desktop"

    # A desktop file is invisible to kglobalaccel until the cache is rebuilt.
    if command -v kbuildsycoca6 &> /dev/null; then
        kbuildsycoca6 > /dev/null 2>&1 || true
    fi

    log_success "$combo bound to $description"
}

# Breeze in Plasma 6.6 has no corner radius setting at all, so rounded windows
# mean a different decoration. Darkly is a Breeze fork that rounds them and is
# what Caelestia uses, but it is not in apt on Ubuntu 26.04 and only ends up
# installed if Caelestia built it, so it is used when present and not required.
#
# Its own options are left at their defaults, which already round the corners.
# They live in darklyrc under key names this repo has not verified against a
# real config file, and guessing them would write keys that silently do
# nothing. Tune them in System Settings > Window Decorations > Darkly.
apply_window_decoration() {
    local plugins="/usr/lib/x86_64-linux-gnu/qt6/plugins/org.kde.kdecoration3"
    local library="org.kde.breeze"
    local theme="Breeze"

    if [ -f "$plugins/org.kde.darkly.so" ]; then
        library="org.kde.darkly"
        theme="Darkly"
    else
        log_info "Darkly is not installed, using Breeze (square corners)"
    fi

    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "$library"
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "$theme"

    if command -v qdbus6 &> /dev/null; then
        qdbus6 org.kde.KWin /KWin reconfigure > /dev/null 2>&1 || true
    fi

    log_success "Window decoration set to $theme"
}

icon_theme_exists() {
    local theme="$1"
    local dir

    for dir in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons; do
        [ -d "$dir/$theme" ] && return 0
    done

    return 1
}

# Applied key by key rather than by copying files: kdeglobals and kwinrc hold a
# lot of state this repo never set, and overwriting them would discard it.
apply_kde_settings() {
    local settings="$DOTFILES_DIR/config/kde/settings.conf"

    if [ ! -f "$settings" ]; then
        log_warning "No settings at config/kde/settings.conf"
        return 0
    fi

    if ! command -v kwriteconfig6 &> /dev/null; then
        log_error "kwriteconfig6 not found, cannot apply KDE settings"
        return 1
    fi

    log_info "Applying KDE settings..."

    local applied=0
    local failed=0
    local line file group key value

    while IFS='|' read -r file group key value; do
        file="$(echo "$file" | xargs)"
        group="$(echo "$group" | xargs)"
        key="$(echo "$key" | xargs)"
        # Not passed through xargs: a value can legitimately be empty, which is
        # how ButtonsOnLeft clears the left-hand titlebar buttons.
        value="${value# }"
        value="${value% }"

        case "$file" in
        "" | \#*) continue ;;
        esac

        [ -n "$group" ] && [ -n "$key" ] || continue

        # Pointing Plasma at an icon theme that is not installed leaves the
        # desktop on a fallback with no warning, which looks like a broken
        # theme rather than a missing package.
        if [ "$group" = "Icons" ] && [ "$key" = "Theme" ] && ! icon_theme_exists "$value"; then
            log_warning "Icon theme $value is not installed, leaving the current one"
            continue
        fi

        if kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value" 2>> "$LOG"; then
            applied=$((applied + 1))
        else
            log_error "Could not set $file $group/$key"
            failed=$((failed + 1))
        fi
    done < <(grep -vE '^\s*(#|$)' "$settings")

    log_success "$applied KDE settings applied"

    if [ "$failed" -gt 0 ]; then
        log_warning "$failed settings could not be applied"
        return 1
    fi
}

# One command to switch every layer at once. The icon variant has to move with
# the palette: Papirus-Dark is drawn for dark panels and looks wrong on Yuki.
install_theme_switcher() {
    local target="$HOME/.local/bin/plasma-theme"
    local map="$DOTFILES_DIR/config/kde/themes.conf"

    if [ ! -f "$map" ]; then
        log_warning "No theme map at config/kde/themes.conf"
        return 0
    fi

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/dotfiles"

    # The switcher reads the generated map rather than carrying its own copy of
    # the values, so a palette change reaches it without editing the script.
    cp "$map" "$HOME/.local/share/dotfiles/kde-themes.conf"

    cat > "$target" <<'SWITCHER'
#!/bin/bash
# Switch every Plasma layer that follows the palette: colour scheme, icon
# variant and window shadow. Installed by the dotfiles; see config/kde/.

set -u

MAP="$HOME/.local/share/dotfiles/kde-themes.conf"

usage() {
    echo "Usage: plasma-theme [name]"
    echo ""
    if [ -r "$MAP" ]; then
        echo "Available:"
        grep -vE '^\s*(#|$)' "$MAP" | while IFS='|' read -r name scheme icons shadow; do
            printf "  %-10s scheme %-10s icons %s\n" \
                "$(echo "$name" | xargs)" "$(echo "$scheme" | xargs)" "$(echo "$icons" | xargs)"
        done
    else
        echo "  no theme map at $MAP"
    fi
    exit "${1:-0}"
}

[ $# -eq 1 ] || usage 0
case "$1" in -h | --help) usage 0 ;; esac

[ -r "$MAP" ] || { echo "No theme map at $MAP" >&2; exit 1; }

# The name is trimmed into a copy on purpose: assigning to $1 makes awk
# rebuild $0 with OFS, which is a space, and the | separators the caller
# needs to split on would be gone.
line="$(grep -vE '^\s*(#|$)' "$MAP" | awk -F'|' -v want="$1" '
    { name = $1; gsub(/^[ \t]+|[ \t]+$/, "", name); if (name == want) print }')"

if [ -z "$line" ]; then
    echo "Unknown theme: $1" >&2
    usage 1
fi

IFS='|' read -r _ scheme icons shadow plasma accent <<< "$line"
scheme="$(echo "$scheme" | xargs)"
icons="$(echo "$icons" | xargs)"
shadow="$(echo "$shadow" | xargs)"
plasma="$(echo "$plasma" | xargs)"
accent="$(echo "$accent" | xargs)"

if ! command -v plasma-apply-colorscheme > /dev/null 2>&1; then
    echo "plasma-apply-colorscheme not found: is this a Plasma session?" >&2
    exit 1
fi

plasma-apply-colorscheme "$scheme" || exit 1

# Skipped rather than set blindly: pointing Plasma at an icon theme that is not
# installed leaves the desktop on a fallback and looks like a broken theme.
if [ -d "/usr/share/icons/$icons" ] || [ -d "$HOME/.local/share/icons/$icons" ]; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icons"
else
    echo "Icon theme $icons is not installed, keeping the current one" >&2
fi

kwriteconfig6 --file breezerc --group Common --key ShadowColor "$shadow"

# The colour scheme leaves the panel and the popups alone: those follow the
# Plasma theme, which is a separate setting and stays on its default unless
# it is set too.
#
# Darkly's Plasma theme is the match for its window decoration, and it rounds
# the panel, the popups and the notifications, all of which breeze-dark leaves
# square. It ships a dark variant only, so it stands in for breeze-dark and
# never for breeze-light.
if [ "$plasma" = "breeze-dark" ] && [ -d /usr/share/plasma/desktoptheme/darkly ]; then
    plasma="darkly"
fi

if [ -n "$plasma" ] && command -v plasma-apply-desktoptheme > /dev/null 2>&1; then
    plasma-apply-desktoptheme "$plasma" > /dev/null 2>&1 ||
        echo "Could not apply the $plasma Plasma theme" >&2
fi

# Plasma picks its highlight from the wallpaper by default, which drifts from
# the palette. Pin it to the colour the terminal uses for a focused border.
if [ -n "$accent" ]; then
    kwriteconfig6 --file kdeglobals --group General --key AccentColor "$accent"
    kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper false
fi

# Installing wallpapers is not the same as using one. Without this the
# desktop keeps whatever image was already set, which is the largest thing
# on screen and the one that decides whether any of this reads as a theme.
desktop_wallpaper="$HOME/Pictures/Wallpapers/$1-seigaiha.png"
if [ -f "$desktop_wallpaper" ] &&
    command -v plasma-apply-wallpaperimage > /dev/null 2>&1; then
    plasma-apply-wallpaperimage "$desktop_wallpaper" > /dev/null 2>&1 ||
        echo "Could not set the desktop wallpaper" >&2
    # Keep the rotator in step, so Meta+K carries on from here rather than
    # jumping back to wherever it had got to.
    state="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-next"
    mkdir -p "$(dirname "$state")"
    printf '%s\n' "$desktop_wallpaper" > "$state"
fi

lock_wallpaper="$HOME/Pictures/Wallpapers/$1-torii.png"
if [ -f "$lock_wallpaper" ]; then
    kwriteconfig6 --file kscreenlockerrc --group Greeter \
        --key WallpaperPlugin org.kde.image
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper \
        --group org.kde.image --group General --key Image "file://$lock_wallpaper"
fi

# KWin rereads its decoration config on reconfigure; without this the shadow
# keeps its old colour until the next login.
if command -v qdbus6 > /dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure > /dev/null 2>&1 || true
fi

echo "Theme set to $1: scheme $scheme, icons $icons, plasma $plasma, accent $accent"
SWITCHER

    chmod +x "$target"
    log_success "Theme switcher installed: plasma-theme [$(grep -vE '^\s*(#|$)' "$map" | cut -d'|' -f1 | xargs | tr ' ' '|')]"
}

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

install_wallpapers() {
    local src="$DOTFILES_DIR/config/wallpapers"

    if [ ! -d "$src" ]; then
        log_warning "No wallpapers at config/wallpapers/"
        return 0
    fi

    mkdir -p "$WALLPAPER_DIR"

    local count=0
    local file

    # The torii backgrounds come along: the lock screen uses one, and it reads
    # from this directory the same way the desktop does.
    for file in "$src"/*.png "$DOTFILES_DIR/config/login"/*.png; do
        [ -f "$file" ] || continue
        if cp "$file" "$WALLPAPER_DIR/"; then
            count=$((count + 1))
        fi
    done

    log_success "$count wallpapers installed to $WALLPAPER_DIR"

    install_wallpaper_rotator
}

install_wallpaper_rotator() {
    local target="$HOME/.local/bin/wallpaper-next"
    local config="$HOME/.config/dotfiles-wallpapers.conf"

    mkdir -p "$HOME/.local/bin"

    # A list of directories rather than a single one, so a collection that
    # already lives somewhere else keeps working alongside the generated set.
    if [ ! -f "$config" ]; then
        cat > "$config" <<CONFIG
# Directories the wallpaper rotator scans, one per line.
# Lines starting with # are ignored.
$WALLPAPER_DIR
CONFIG
        # Pick up an existing collection if there is an obvious one.
        local extra
        for extra in "$HOME/Desktop/fondos" "$HOME/Pictures/wallpapers" "$HOME/Wallpapers"; do
            if [ -d "$extra" ] && [ "$extra" != "$WALLPAPER_DIR" ]; then
                echo "$extra" >> "$config"
                log_info "Also scanning $extra"
            fi
        done
        log_success "Wallpaper directories listed in $config"
    else
        log_info "Keeping the existing $config"
    fi

    cat > "$target" <<'ROTATOR'
#!/bin/bash
# Cycle the desktop wallpaper through every image in the configured
# directories. Installed by the dotfiles; see config/wallpapers/.

set -u

CONFIG="$HOME/.config/dotfiles-wallpapers.conf"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-next"

usage() {
    echo "Usage: wallpaper-next [--random|--list|--current]"
    echo ""
    echo "  no arguments  advance to the next wallpaper"
    echo "  --random      pick one at random"
    echo "  --list        print every wallpaper found"
    echo "  --current     print the one in use"
    echo ""
    echo "Directories are listed in $CONFIG"
    exit "${1:-0}"
}

collect() {
    [ -r "$CONFIG" ] || return 0
    local dir
    while IFS= read -r dir; do
        case "$dir" in "" | \#*) continue ;; esac
        dir="${dir/#\~/$HOME}"
        [ -d "$dir" ] || continue
        find "$dir" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
            2>/dev/null
    done < "$CONFIG" | sort
}

mapfile -t papers < <(collect)

if [ "${#papers[@]}" -eq 0 ]; then
    echo "No wallpapers found. Check the directories in $CONFIG" >&2
    exit 1
fi

case "${1:-}" in
-h | --help) usage 0 ;;
--list)
    printf '%s\n' "${papers[@]}"
    exit 0
    ;;
--current)
    [ -r "$STATE" ] && cat "$STATE" || echo "(none recorded)"
    exit 0
    ;;
--random)
    next="${papers[RANDOM % ${#papers[@]}]}"
    ;;
"")
    current=""
    [ -r "$STATE" ] && current="$(cat "$STATE")"

    index=-1
    for i in "${!papers[@]}"; do
        if [ "${papers[i]}" = "$current" ]; then
            index="$i"
            break
        fi
    done

    next="${papers[$(((index + 1) % ${#papers[@]}))]}"
    ;;
*)
    echo "Unknown option: $1" >&2
    usage 1
    ;;
esac

if ! command -v plasma-apply-wallpaperimage > /dev/null 2>&1; then
    echo "plasma-apply-wallpaperimage not found: is this a Plasma session?" >&2
    exit 1
fi

plasma-apply-wallpaperimage "$next" || exit 1

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$next" > "$STATE"

echo "Wallpaper: $(basename "$next")"
ROTATOR

    chmod +x "$target"
    log_success "Wallpaper rotator installed: wallpaper-next"
}

# Plasma binds shortcuts to .desktop entries rather than to bare commands, so
# the rotator needs one before kglobalshortcutsrc can reach it.
install_wallpaper_shortcut() {
    local desktop_dir="$HOME/.local/share/applications"
    local desktop_file="$desktop_dir/dotfiles-wallpaper-next.desktop"

    if [ ! -x "$HOME/.local/bin/wallpaper-next" ]; then
        log_warning "The rotator is not installed, skipping the shortcut"
        return 0
    fi

    mkdir -p "$desktop_dir"

    # X-KDE-Shortcuts is the binding. See bind_shortcut for why it does not
    # also go into kglobalshortcutsrc.
    cat > "$desktop_file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Next Wallpaper
Comment=Cycle the desktop wallpaper
Exec=$HOME/.local/bin/wallpaper-next
Icon=preferences-desktop-wallpaper
Terminal=false
NoDisplay=true
X-KDE-Shortcuts=Meta+K
DESKTOP

    backup_file "$HOME/.config/kglobalshortcutsrc"

    # K for 壁紙 (kabegami, wallpaper). Meta+W is KWin's Overview.
    bind_shortcut "dotfiles-wallpaper-next.desktop" "Meta+K" "Next Wallpaper"

    add_post_install_note "Log out and back in to activate Meta+K (cycle wallpaper) and Meta+Shift+K (picker). Plasma only registers new shortcuts when a session starts. Directories are listed in ~/.config/dotfiles-wallpapers.conf"
}

# A floating grid of wallpaper thumbnails, the way the Hyprland setups do it.
#
# rofi 2.0 in Ubuntu 26.04 speaks Wayland natively, so it runs under KWin
# without XWayland and gives the grid with previews. When it is not installed
# the picker falls back to kdialog, which is already part of Plasma and whose
# file dialog renders thumbnails through kio-extras.
install_wallpaper_menu() {
    local target="$HOME/.local/bin/wallpaper-menu"

    mkdir -p "$HOME/.local/bin"

    cat > "$target" <<'MENU'
#!/bin/bash
# Pick a wallpaper from a floating grid.
# Installed by the dotfiles; see config/wallpapers/.

set -u

CONFIG="$HOME/.config/dotfiles-wallpapers.conf"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-next"

collect() {
    [ -r "$CONFIG" ] || return 0
    local dir
    while IFS= read -r dir; do
        case "$dir" in "" | \#*) continue ;; esac
        dir="${dir/#\~/$HOME}"
        [ -d "$dir" ] || continue
        find "$dir" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
            2>/dev/null
    done < "$CONFIG" | sort
}

mapfile -t papers < <(collect)

if [ "${#papers[@]}" -eq 0 ]; then
    echo "No wallpapers found. Check the directories in $CONFIG" >&2
    exit 1
fi

choice=""

if command -v rofi > /dev/null 2>&1; then
    # rofi's dmenu protocol takes an icon per row after a unit separator, so
    # each wallpaper is its own preview.
    listing=""
    for paper in "${papers[@]}"; do
        name="$(basename "${paper%.*}")"
        listing+="${name}\x00icon\x1f${paper}\n"
    done

    selected="$(printf "%b" "$listing" | rofi -dmenu -i \
        -p "壁紙" \
        -show-icons \
        -theme-str 'window { width: 60%; } listview { columns: 4; lines: 3; } element-icon { size: 12em; }' \
        2>/dev/null)"

    if [ -n "$selected" ]; then
        for paper in "${papers[@]}"; do
            if [ "$(basename "${paper%.*}")" = "$selected" ]; then
                choice="$paper"
                break
            fi
        done
    fi
elif command -v kdialog > /dev/null 2>&1; then
    start="$(dirname "${papers[0]}")"
    choice="$(kdialog --title "Choose a wallpaper" \
        --getopenfilename "$start" \
        'image/png image/jpeg image/webp' 2>/dev/null)"
else
    echo "Neither rofi nor kdialog is available" >&2
    echo "Install rofi for the grid picker:  sudo apt install rofi" >&2
    exit 1
fi

[ -n "$choice" ] || exit 0

if ! command -v plasma-apply-wallpaperimage > /dev/null 2>&1; then
    echo "plasma-apply-wallpaperimage not found: is this a Plasma session?" >&2
    exit 1
fi

plasma-apply-wallpaperimage "$choice" || exit 1

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$choice" > "$STATE"

echo "Wallpaper: $(basename "$choice")"
MENU

    chmod +x "$target"

    local desktop_file="$HOME/.local/share/applications/dotfiles-wallpaper-menu.desktop"
    mkdir -p "$(dirname "$desktop_file")"

    cat > "$desktop_file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Wallpaper Picker
Comment=Choose a wallpaper from a grid
Exec=$HOME/.local/bin/wallpaper-menu
Icon=preferences-desktop-wallpaper
Terminal=false
NoDisplay=true
X-KDE-Shortcuts=Meta+Shift+K
DESKTOP

    if command -v kwriteconfig6 &> /dev/null; then
        bind_shortcut "dotfiles-wallpaper-menu.desktop" "Meta+Shift+K" "Wallpaper Picker"
    fi

    if command -v rofi &> /dev/null; then
        log_success "Wallpaper picker installed (rofi grid)"
    else
        log_success "Wallpaper picker installed (kdialog fallback)"
        add_post_install_note "Install rofi for the grid picker with previews: sudo apt install rofi"
    fi
}
