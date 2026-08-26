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
# The background is a torii, generated per palette by
# scripts/generate_login_backgrounds.py. A torii marks the boundary between the
# ordinary and the sacred, which is a fair description of a login screen.
#
# The colours come from the same generated schemes as everything else, so the
# login screen cannot drift from the terminal and the desktop. See config/kde/.
#
# Functions:
#   - setup_login_screen: Main function
#   - install_sddm_theme: Install the Breeze theme package
#   - fork_sddm_theme: Copy Breeze into a directory this repo owns
#   - configure_sddm_theme: Point the theme at our background
#   - apply_sddm_colours: Give the greeter our colour scheme
#   - select_sddm_theme: Make Breeze the active theme
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, add_post_install_note)
#   - Colors defined in main script

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# SDDM has no theme.conf.user or any other override file: it reads the single
# theme.conf named by the theme's metadata.desktop, and that file belongs to
# the package, which replaces it on upgrade without asking (it is not a dpkg
# conffile). So Breeze is copied into a directory this repo owns and the copy
# is what gets configured. The theme carries no absolute paths back to itself,
# so it relocates cleanly.
SDDM_SOURCE_THEME="/usr/share/sddm/themes/breeze"
SDDM_THEME_DIR="/usr/share/sddm/themes/breeze-dotfiles"
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
    echo "  1) Kanagawa (dark, blue)"
    echo "  2) Sakura (dark, gold accent)"
    echo "  3) Yuki (light)"
    echo "  4) Skip"
    echo ""

    read -rp "Enter your choice [1|2|3|4]: " choice

    local palette
    case "$choice" in
    1) palette="kanagawa" ;;
    2) palette="sakura" ;;
    3) palette="yuki" ;;
    *)
        log_info "Skipping the login screen"
        return 0
        ;;
    esac

    install_sddm_theme || return 1

    fork_sddm_theme || return 1

    configure_sddm_theme "$palette" || return 1

    apply_sddm_colours "$palette"

    select_sddm_theme || return 1

    add_post_install_note "The login screen is themed. Preview it without rebooting: sddm-greeter-qt6 --test-mode --theme $SDDM_THEME_DIR"

    log_success "Login screen setup completed"
}

install_sddm_theme() {
    if [ -d "$SDDM_SOURCE_THEME" ]; then
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

fork_sddm_theme() {
    # Earlier versions of this script wrote a theme.conf.user into the stock
    # theme, believing SDDM would read it. It does not, so clear it out.
    run_logged sudo rm -f "$SDDM_SOURCE_THEME/theme.conf.user"

    if ! run_logged sudo rm -rf "$SDDM_THEME_DIR"; then
        log_error "Could not clear $SDDM_THEME_DIR"
        return 1
    fi

    if ! run_logged sudo cp -a "$SDDM_SOURCE_THEME" "$SDDM_THEME_DIR"; then
        log_error "Could not copy the Breeze theme"
        return 1
    fi

    # So the copy is tellable from the original in System Settings.
    run_logged sudo sed -i 's/^Name=Breeze$/Name=Breeze (Nach0_0)/' \
        "$SDDM_THEME_DIR/metadata.desktop"

    log_success "Breeze copied to $SDDM_THEME_DIR"
}

# The background cannot live under the user's home: the greeter runs as the
# sddm user, which cannot read it.
configure_sddm_theme() {
    local palette="$1"
    local wallpaper="$DOTFILES_DIR/config/login/${palette}-torii.png"

    if [ ! -f "$wallpaper" ]; then
        log_error "No login background at $wallpaper"
        log_info "Generate it with: python3 scripts/generate_login_backgrounds.py"
        return 1
    fi

    if ! run_logged sudo cp "$wallpaper" "$SDDM_BACKGROUND"; then
        log_error "Could not install the login background"
        return 1
    fi

    run_logged sudo chmod 644 "$SDDM_BACKGROUND"

    # Every key the theme reads is written, not just the changed ones: this
    # replaces theme.conf rather than overriding it, and a missing key leaves
    # its QML binding undefined.
    local fallback
    fallback="$(awk '/^background / { print $2; exit }' \
        "$DOTFILES_DIR/config/kitty/themes/${palette}.conf" 2>/dev/null)"

    if ! sudo tee "$SDDM_THEME_DIR/theme.conf" > /dev/null <<CONF
[General]
type=image
background=$SDDM_BACKGROUND
color=${fallback:-#222335}
showClock=true
showlogo=hidden
logo=$SDDM_THEME_DIR/default-logo.svg
fontSize=10
needsFullUserModel=false
CONF
    then
        log_error "Could not write the theme configuration"
        return 1
    fi

    log_success "Login background set to the ${palette} torii"
}

# The greeter is a Plasma session like any other: it reads its colours, icons
# and fonts from kdeglobals in the sddm user's config. The .colors files this
# repo generates are already in that format, so one goes straight in, and the
# icon theme and fonts are appended to it.
#
# The icon theme is what draws the shutdown, restart and sleep buttons in the
# footer, so setting it is what changes those.
apply_sddm_colours() {
    local palette="$1"
    local scheme icons colours

    scheme="$(awk -F'|' -v p="$palette" '
        $1 ~ p { gsub(/ /, "", $2); print $2; exit }
    ' "$DOTFILES_DIR/config/kde/themes.conf" 2>/dev/null)"

    icons="$(awk -F'|' -v p="$palette" '
        $1 ~ p { gsub(/ /, "", $3); print $3; exit }
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

    # Appended after the copy, since the .colors file carries neither.
    if [ -n "$icons" ] && [ -d "/usr/share/icons/$icons" ]; then
        run_logged sudo kwriteconfig6 --file "$SDDM_HOME/.config/kdeglobals" \
            --group Icons --key Theme "$icons"
    else
        log_info "Icon theme $icons is not installed, the greeter keeps its own"
    fi

    local font="Noto Sans,10,-1,0,400,0,0,0,0,0,0,0,0,0,0,1"

    run_logged sudo kwriteconfig6 --file "$SDDM_HOME/.config/kdeglobals" \
        --group General --key font "$font"
    run_logged sudo kwriteconfig6 --file "$SDDM_HOME/.config/kdeglobals" \
        --group General --key menuFont "$font"

    run_logged sudo chown -R sddm:sddm "$SDDM_HOME/.config"

    log_success "Greeter set to $scheme with $icons icons"
}

# Two files already pin the theme here: /etc/sddm.conf and the one KDE writes.
# Ordering settles it rather than editing either: SDDM reads /etc/sddm.conf
# first, then /etc/sddm.conf.d/*.conf in name order, and the last value wins.
select_sddm_theme() {
    if ! sudo tee /etc/sddm.conf.d/zz-dotfiles.conf > /dev/null <<CONF
[Theme]
Current=$(basename "$SDDM_THEME_DIR")
CONF
    then
        log_error "Could not select the Breeze login theme"
        return 1
    fi

    log_success "Breeze selected as the login theme"
}
