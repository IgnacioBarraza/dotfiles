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
#   - fix_caelestia_lockscreen: Give the lock greeter its QML import path
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

    fix_caelestia_lockscreen

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

# The lock screen runs quickshell straight from kscreenlockerrc, which is the
# one path that goes through none of Caelestia's wrappers. Those wrappers are
# what export QML2_IMPORT_PATH, so without it the greeter cannot resolve the
# Caelestia.* QML modules under ~/.local/lib/qt6/qml and Meta+L dies with
# 'module "Caelestia.Config" is not installed'.
#
# The wallpaper plugin builds its command by prefixing variable assignments and
# handing the string to a shell, so one more assignment rides along fine.
fix_caelestia_lockscreen() {
    local group_args=(
        --group "Greeter" --group "Wallpaper"
        --group "net.dosowisko.PlasmaApplicationWallpaper" --group "General"
    )
    local current

    command -v kreadconfig6 &> /dev/null || return 0
    command -v kwriteconfig6 &> /dev/null || return 0

    current="$(kreadconfig6 --file kscreenlockerrc "${group_args[@]}" --key command 2>/dev/null)"

    # Nothing to do when the lock screen is not Caelestia's, or when a later
    # version has already set the path itself.
    case "$current" in
    "" | *QML2_IMPORT_PATH*) return 0 ;;
    quickshell*) ;;
    *) return 0 ;;
    esac

    backup_file "$HOME/.config/kscreenlockerrc"

    if kwriteconfig6 --file kscreenlockerrc "${group_args[@]}" \
        --key command "QML2_IMPORT_PATH=$HOME/.local/lib/qt6/qml $current"; then
        log_success "Lock screen QML import path set"
    else
        log_warning "Could not set the lock screen QML import path, Meta+L may fail"
    fi
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
