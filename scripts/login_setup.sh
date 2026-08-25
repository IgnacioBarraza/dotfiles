#!/bin/bash

# ============================================
# 10. LOGIN SCREEN SETUP SCRIPT
# ============================================
#
# Themes the SDDM login screen, the one that greets you at boot.
#
# This is independent of the desktop choice: Caelestia does not touch SDDM at
# all, and neither does the Plasma theme, so the login screen is themed here
# whichever of the two is installed.
#
# The colours come from the same generated schemes as everything else, so the
# login screen cannot drift from the terminal and the desktop. See config/kde/.
#
# Functions:
#   - setup_login_screen: Main function
#   - install_sddm_theme: Install the Breeze theme package
#   - configure_sddm_theme: Point the theme at our background
#   - apply_sddm_colours: Give the greeter our colour scheme
#   - select_sddm_theme: Make Breeze the active theme
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, add_post_install_note)
#   - Colors defined in main script

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

SDDM_THEME_DIR="/usr/share/sddm/themes/breeze"
SDDM_BACKGROUND="/usr/share/backgrounds/dotfiles-login.png"
SDDM_HOME="/var/lib/sddm"

setup_login_screen() {
    log_info "Starting login screen setup"

    if ! command -v sddm &> /dev/null; then
        log_info "SDDM is not the display manager here, skipping the login screen"
        return 0
    fi

    log_info "Select a login screen theme"
    echo ""
    echo "  1) Sakura (dark, pink)"
    echo "  2) Kanagawa (dark, blue)"
    echo "  3) Yuki (light)"
    echo "  4) Skip"
    echo ""

    read -rp "Enter your choice [1|2|3|4]: " choice

    local palette
    case "$choice" in
    1) palette="sakura" ;;
    2) palette="kanagawa" ;;
    3) palette="yuki" ;;
    *)
        log_info "Skipping the login screen"
        return 0
        ;;
    esac

    install_sddm_theme || return 1

    configure_sddm_theme "$palette" || return 1

    apply_sddm_colours "$palette"

    select_sddm_theme || return 1

    add_post_install_note "The login screen is themed. Preview it without rebooting: sddm-greeter-qt6 --test-mode --theme $SDDM_THEME_DIR"

    log_success "Login screen setup completed"
}

install_sddm_theme() {
    if [ -d "$SDDM_THEME_DIR" ]; then
        log_success "The Breeze login theme is already installed"
        return 0
    fi

    log_info "Installing the Breeze login theme..."

    if ! run_logged sudo apt install -y sddm-theme-breeze; then
        log_error "Failed to install sddm-theme-breeze"
        return 1
    fi

    log_success "Breeze login theme installed"
}

# The background cannot live under the user's home: the greeter runs as the
# sddm user, which cannot read it. It also cannot live inside the theme, which
# a package upgrade replaces.
configure_sddm_theme() {
    local palette="$1"
    local wallpaper="$DOTFILES_DIR/config/wallpapers/${palette}-seigaiha.png"

    if [ ! -f "$wallpaper" ]; then
        log_error "No wallpaper at $wallpaper"
        return 1
    fi

    if ! run_logged sudo cp "$wallpaper" "$SDDM_BACKGROUND"; then
        log_error "Could not install the login background"
        return 1
    fi

    run_logged sudo chmod 644 "$SDDM_BACKGROUND"

    # theme.conf.user overrides theme.conf and is not owned by the package, so
    # it survives upgrades. theme.conf itself would be replaced by them.
    if ! sudo tee "$SDDM_THEME_DIR/theme.conf.user" > /dev/null <<CONF
[General]
type=image
background=$SDDM_BACKGROUND
showClock=true
showlogo=hidden
CONF
    then
        log_error "Could not write the theme configuration"
        return 1
    fi

    log_success "Login background set to ${palette}-seigaiha"
}

# The greeter reads a Plasma colour scheme from the sddm user's config, the
# same way any Plasma session does. The .colors files this repo generates are
# already in that format, so one goes straight in as kdeglobals.
apply_sddm_colours() {
    local palette="$1"
    local scheme
    local colours

    scheme="$(awk -F'|' -v p="$palette" '
        $1 ~ p { gsub(/ /, "", $2); print $2; exit }
    ' "$DOTFILES_DIR/config/kde/themes.conf" 2>/dev/null)"

    colours="$DOTFILES_DIR/config/kde/color-schemes/${scheme}.colors"

    if [ ! -f "$colours" ]; then
        log_warning "No colour scheme for $palette, the greeter keeps its own"
        return 0
    fi

    run_logged sudo mkdir -p "$SDDM_HOME/.config"

    if ! run_logged sudo cp "$colours" "$SDDM_HOME/.config/kdeglobals"; then
        log_warning "Could not give the greeter the $scheme colours"
        return 0
    fi

    run_logged sudo chown -R sddm:sddm "$SDDM_HOME/.config"

    log_success "Greeter colours set to $scheme"
}

# Two files already pin the theme here: /etc/sddm.conf and the one KDE writes.
# Ordering settles it rather than editing either: SDDM reads /etc/sddm.conf
# first, then /etc/sddm.conf.d/*.conf in name order, and the last value wins.
select_sddm_theme() {
    if ! sudo tee /etc/sddm.conf.d/zz-dotfiles.conf > /dev/null <<'CONF'
[Theme]
Current=breeze
CONF
    then
        log_error "Could not select the Breeze login theme"
        return 1
    fi

    log_success "Breeze selected as the login theme"
}
