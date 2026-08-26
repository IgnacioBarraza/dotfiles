#!/bin/bash

# ============================================
# 09. CAELESTIA SETUP SCRIPT
# ============================================
#
# Installs the Caelestia KDE port as an alternative to the theme in
# desktop_setup.sh. The two are mutually exclusive: Caelestia replaces Plasma's
# shell with its own Quickshell one, so the panel, launcher, lock screen and
# colour scheme all stop coming from Plasma.
#
# Upstream: https://github.com/ladybug-me/caelestia-dots-kde (GPL-3.0)
#
# Functions:
#   - install_caelestia: Main function
#   - caelestia_preflight: Check the session can host it
#   - fetch_caelestia: Clone or update the checkout
#   - install_caelestia_fixups: Install the patches that updates undo
#   - remove_wallpaper_shortcuts: Hand the wallpaper over to Caelestia
#   - clear_stdbuf_preload: Stop LD_PRELOAD leaking into every terminal
#   - restore_terminal_configs: Put this repo's terminal theme back
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for backup_file, add_post_install_note)
#   - terminal_setup.sh (for configure_kitty, configure_alacritty,
#     configure_fastfetch)
#   - Colors defined in main script

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

CAELESTIA_REPO="https://github.com/ladybug-me/caelestia-dots-kde.git"
CAELESTIA_DIR="${CAELESTIA_DIR:-$HOME/caelestia-dots-kde}"

install_caelestia() {
    log_info "Starting Caelestia setup"

    caelestia_preflight || return 1

    cat <<'NOTICE'

  Caelestia replaces the Plasma shell with its own, built on Quickshell.
  It takes over the panel, launcher, notifications, lock screen and colours,
  and derives the colour scheme from the wallpaper, so Plasma's own wallpaper
  manager must not be used afterwards.

  Installing it will:
    - add the ppa:avengemedia/danklinux repository, for quickshell
    - compile cava, app2unit, gpu-screen-recorder, wl-clip-persist, satty,
      the Darkly style and konsave from source, which takes a while
    - replace the Plasma style, window decoration and icon theme
    - hand over to its own interactive installer

  It ships bash ./uninstall.sh to undo this.

NOTICE

    read -rp "Do you want to install Caelestia? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY]) ;;
    *)
        log_info "Skipping Caelestia"
        return 0
        ;;
    esac

    fetch_caelestia || return 1

    # Its installer is a full-screen TUI, so it gets the terminal to itself:
    # piping it through tee for the log would break the display.
    log_info "Handing over to the Caelestia installer..."

    if ! bash "$CAELESTIA_DIR/scripts/setup.sh"; then
        log_error "The Caelestia installer failed"
        log_info "Re-run it with: bash $CAELESTIA_DIR/scripts/setup.sh"
        return 1
    fi

    log_success "Caelestia installed"

    install_caelestia_fixups

    remove_wallpaper_shortcuts

    clear_stdbuf_preload

    restore_terminal_configs

    add_post_install_note "Caelestia is installed. Log out and back in to start its shell. Set wallpapers from its own manager (Super, then >Wallpaper), not Plasma's. Uninstall with: bash $CAELESTIA_DIR/uninstall.sh"
}

caelestia_preflight() {
    if ! command -v plasmashell &> /dev/null; then
        log_error "Caelestia is a Plasma 6 port, and Plasma was not found"
        return 1
    fi

    if ! command -v git &> /dev/null; then
        log_error "git is required to fetch Caelestia"
        return 1
    fi

    # quickshell comes from a PPA that only publishes for 26.04 and 25.10.
    # Everywhere else the installer falls back to building it, which rarely
    # ends well.
    if ! grep -q "Ubuntu 26.04" /etc/os-release 2>/dev/null; then
        log_warning "quickshell is only published for Ubuntu 26.04, this may fail"
    fi

    return 0
}

fetch_caelestia() {
    if [ -d "$CAELESTIA_DIR/.git" ]; then
        log_info "Updating the existing checkout at $CAELESTIA_DIR"

        if ! git -C "$CAELESTIA_DIR" pull --ff-only --recurse-submodules 2>&1 | tee -a "$LOG"; then
            log_warning "Could not update the checkout, using it as it is"
        fi

        return 0
    fi

    if [ -e "$CAELESTIA_DIR" ]; then
        log_error "$CAELESTIA_DIR exists and is not a git checkout"
        return 1
    fi

    log_info "Cloning Caelestia into $CAELESTIA_DIR..."

    if ! run_logged git clone -b main --single-branch --depth 1 \
        --recurse-submodules "$CAELESTIA_REPO" "$CAELESTIA_DIR"; then
        log_error "Failed to clone Caelestia"
        return 1
    fi

    log_success "Caelestia cloned to $CAELESTIA_DIR"
}

# Two things this repo fixes in Caelestia are undone by every update, so they
# are installed as a script that can be re-run rather than applied once:
#
#   - 08-build-shell.sh rewrites kscreenlockerrc with a bare `quickshell`
#     command. Only Caelestia's wrappers export QML2_IMPORT_PATH, so the lock
#     greeter cannot resolve the Caelestia.* QML modules and Meta+L dies with
#     'module "Caelestia.Config" is not installed'.
#
#   - The terminal shortcut hardcodes foot instead of reading
#     general.apps.terminal, which every other caller of that setting uses.
#     The shell is installed with cmake, which overwrites the file outright.
#
# A path unit watches .current_commit, which the build script rewrites when it
# finishes, so the patches go back on by themselves after an update.
install_caelestia_fixups() {
    local target="$HOME/.local/bin/caelestia-fixups"
    local units="$HOME/.config/systemd/user"

    mkdir -p "$HOME/.local/bin" "$units"

    cat > "$target" <<'FIXUPS'
#!/bin/bash
# Re-apply the dotfiles patches to Caelestia. Safe to run at any time.
# Installed by the dotfiles; see scripts/caelestia_setup.sh.

set -u

shortcuts="$HOME/.config/quickshell/caelestia/modules/Shortcuts.qml"
lock_groups=(
    --group "Greeter" --group "Wallpaper"
    --group "net.dosowisko.PlasmaApplicationWallpaper" --group "General"
)

if command -v kreadconfig6 > /dev/null 2>&1 && command -v kwriteconfig6 > /dev/null 2>&1; then
    current="$(kreadconfig6 --file kscreenlockerrc "${lock_groups[@]}" --key command 2>/dev/null)"

    case "$current" in
    quickshell*)
        kwriteconfig6 --file kscreenlockerrc "${lock_groups[@]}" \
            --key command "QML2_IMPORT_PATH=$HOME/.local/lib/qt6/qml $current" &&
            echo "lock screen: QML import path restored"
        ;;
    esac
fi

if [ -f "$shortcuts" ] && grep -qF '"kstart", "--", "foot"' "$shortcuts"; then
    sed -i 's|\["kstart", "--", "foot"\]|["kstart", "--", ...GlobalConfig.general.apps.terminal]|' "$shortcuts" &&
        echo "terminal shortcut: now follows general.apps.terminal"
fi
FIXUPS

    chmod +x "$target"

    cat > "$units/caelestia-fixups.service" <<'UNIT'
[Unit]
Description=Re-apply the dotfiles patches to Caelestia

[Service]
Type=oneshot
ExecStart=%h/.local/bin/caelestia-fixups
UNIT

    cat > "$units/caelestia-fixups.path" <<'UNIT'
[Unit]
Description=Watch for Caelestia updates

[Path]
PathChanged=%h/.config/quickshell/caelestia/.current_commit
Unit=caelestia-fixups.service

[Install]
WantedBy=default.target
UNIT

    if command -v systemctl &> /dev/null; then
        systemctl --user daemon-reload > /dev/null 2>&1 || true
        systemctl --user enable --now caelestia-fixups.path > /dev/null 2>&1 ||
            log_warning "Could not enable caelestia-fixups.path, run the script by hand after updates"
    fi

    run_logged "$target"

    log_success "Caelestia fixups installed and armed"
}

# Caelestia owns the wallpaper once it is installed: it derives the colour
# scheme from it and asks that Plasma's wallpaper manager be left alone. Our
# Meta+K shortcuts do exactly what it asks not to, so they are switched off.
# The rotator and the wallpapers themselves stay, and Caelestia picks the
# images up from ~/Pictures/Wallpapers on its own.
remove_wallpaper_shortcuts() {
    local desktop_dir="$HOME/.local/share/applications"
    local removed=0
    local name

    for name in dotfiles-wallpaper-next dotfiles-wallpaper-menu; do
        # Hidden rather than deleted. Hidden=true takes the entry out of the
        # service database exactly as removing the file would, but leaves the
        # file for desktop-mode to switch back on. Deleting it meant a later
        # switch to Plasma had nothing to restore and came up without the
        # wallpaper shortcuts.
        if [ -f "$desktop_dir/$name.desktop" ]; then
            kwriteconfig6 --file "$desktop_dir/$name.desktop" \
                --group "Desktop Entry" --key Hidden true &&
                removed=$((removed + 1))
        fi

        # Older versions of this repo also wrote the binding into the config.
        if declare -F drop_shortcut_group > /dev/null; then
            drop_shortcut_group "$name.desktop"
        fi
    done

    [ "$removed" -eq 0 ] && return 0

    command -v kbuildsycoca6 &> /dev/null && kbuildsycoca6 > /dev/null 2>&1

    log_info "Meta+K removed, Caelestia handles wallpapers (Meta+Ctrl+T)"
}

# Caelestia starts its shell through stdbuf, to keep its log line buffered:
#
#   exec stdbuf -oL -eL quickshell -d -n -p .../shell.qml
#
# stdbuf works by setting LD_PRELOAD, so quickshell carries it, and so does
# every process quickshell launches, terminals included. Programs under an
# AppArmor profile that does not allow that path then fail to load it and the
# dynamic linker prints
#
#   ERROR: ld.so: object '.../libstdbuf.so' from LD_PRELOAD cannot be
#   preloaded (cannot open shared object file): ignored.
#
# Harmless, since the linker carries on, but it lands in the middle of unrelated
# output. Line buffering means nothing in an interactive shell, so drop it
# there and leave Caelestia's own launch alone.
clear_stdbuf_preload() {
    zshrc_ensure_line \
        '[[ "${LD_PRELOAD:-}" != */libstdbuf.so ]] || unset LD_PRELOAD' \
        "Caelestia starts its shell through stdbuf, which leaks LD_PRELOAD into every terminal it opens" &&
        log_success "LD_PRELOAD cleared for interactive shells"
}

# Caelestia deploys its own kitty, starship, fastfetch and btop configurations.
# It keeps a checksum of what it wrote and leaves locally edited files alone on
# later runs, but on a first install there is no checksum yet, so it overwrites
# whatever this repo put there. Putting ours back afterwards is what keeps the
# Japanese terminal theme.
restore_terminal_configs() {
    log_info "Restoring this repository's terminal configuration..."

    configure_kitty
    configure_alacritty
    configure_fastfetch

    local starship_src="$DOTFILES_DIR/config/starship/starship.toml"

    if [ -f "$starship_src" ]; then
        backup_file "$HOME/.config/starship.toml"

        if cp "$starship_src" "$HOME/.config/starship.toml"; then
            log_success "starship.toml restored"
        else
            log_error "Failed to restore starship.toml"
        fi
    fi

    log_success "Terminal configuration restored"
}
