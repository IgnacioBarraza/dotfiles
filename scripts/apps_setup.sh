#!/bin/bash

# ============================================
# 04. APPLICATION SETUP SCRIPT
# ============================================
#
# This script installs the desktop applications and terminal tools that make
# up the development environment, plus a browser.
#
# Functions:
#   - setup_apps: Main function
#   - install_browser: Prompt for and install a browser
#   - install_dev_apps: Multi-select menu for everything else
#   - install_vscode, install_jetbrains_toolbox, ...: Individual installers
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, add_apt_repo, snap_install)
#   - Colors defined in main script

# category | display name | how it is installed | installer function
APPS=(
    "Editors and IDEs|Visual Studio Code|apt, Microsoft repo|install_vscode"
    "Editors and IDEs|JetBrains Toolbox|tarball to /opt|install_jetbrains_toolbox"
    "API clients|Postman|snap|install_postman"
    "Databases|DBeaver Community|snap|install_dbeaver"
    "Terminal tools|lazygit|apt|install_lazygit"
    "Terminal tools|git-delta|apt|install_git_delta"
    "Terminal tools|k9s|snap|install_k9s"
    "Notes and chat|Obsidian|snap|install_obsidian"
    "Notes and chat|Slack|snap|install_slack"
)

setup_apps() {
    log_info "Starting application setup"

    install_browser

    install_dev_apps

    log_success "Application setup completed"
}

# ---------------------------------------------
# Browser
# ---------------------------------------------

install_browser() {
    log_info "Select a browser to install"
    echo ""
    echo "  1) Brave (privacy focused, Chromium based)"
    echo "  2) Google Chrome"
    echo "  3) Keep Firefox (already installed on Ubuntu)"
    echo "  4) Skip"
    echo ""

    read -rp "Enter your choice [1|2|3|4]: " choice

    case "$choice" in
    1)
        if pkg_installed brave-browser; then
            log_success "Brave is already installed"
            return 0
        fi
        add_apt_repo "brave-browser" \
            "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" \
            "https://brave-browser-apt-release.s3.brave.com" \
            "stable" || return 1
        run_logged sudo apt install -y brave-browser &&
            log_success "Brave installed" ||
            log_error "Failed to install Brave"
        ;;
    2)
        if pkg_installed google-chrome-stable; then
            log_success "Google Chrome is already installed"
            return 0
        fi
        add_apt_repo "google-chrome" \
            "https://dl.google.com/linux/linux_signing_key.pub" \
            "https://dl.google.com/linux/chrome/deb/" \
            "stable" || return 1
        run_logged sudo apt install -y google-chrome-stable &&
            log_success "Google Chrome installed" ||
            log_error "Failed to install Google Chrome"
        ;;
    3)
        log_info "Keeping Firefox, which Ubuntu ships as a snap"
        ;;
    4)
        log_info "Skipping browser installation"
        ;;
    *)
        log_warning "Invalid choice. Skipping browser installation"
        ;;
    esac
}

# ---------------------------------------------
# Multi-select menu
# ---------------------------------------------

install_dev_apps() {
    log_info "Select the applications to install"
    echo ""

    local i=1
    local last_category=""
    local entry category name method

    for entry in "${APPS[@]}"; do
        IFS='|' read -r category name method _ <<< "$entry"
        if [ "$category" != "$last_category" ]; then
            [ -n "$last_category" ] && echo ""
            echo "  ${MAGENTA}${category}${RESET}"
            last_category="$category"
        fi
        printf "    %2d) %-22s %s\n" "$i" "$name" "($method)"
        i=$((i + 1))
    done

    echo ""
    echo "  Enter numbers separated by commas or spaces (for example: 1,3,5)"
    echo "  Type 'all' for everything, or leave empty to skip."
    echo ""

    read -rp "Your choice: " selection

    if [ -z "${selection// /}" ]; then
        log_info "Skipping application installation"
        return 0
    fi

    local chosen=()

    if [ "${selection,,}" = "all" ]; then
        local n
        for n in $(seq 1 ${#APPS[@]}); do
            chosen+=("$n")
        done
    else
        local raw
        # Accept both separators, then validate every token.
        read -ra raw <<< "${selection//,/ }"
        local token
        for token in "${raw[@]}"; do
            if ! [[ "$token" =~ ^[0-9]+$ ]] || [ "$token" -lt 1 ] || [ "$token" -gt ${#APPS[@]} ]; then
                log_warning "Ignoring invalid choice: $token"
                continue
            fi
            chosen+=("$token")
        done
    fi

    if [ ${#chosen[@]} -eq 0 ]; then
        log_warning "Nothing valid selected, skipping application installation"
        return 0
    fi

    local installed=0
    local failed=0
    local failed_apps=()
    local index installer

    for index in "${chosen[@]}"; do
        IFS='|' read -r _ name _ installer <<< "${APPS[index - 1]}"

        log_info "=== $name ==="

        if "$installer"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
            failed_apps+=("$name")
        fi
    done

    log_info "=== Application Installation Summary ==="
    log_info "Selected: ${#chosen[@]}"
    log_info "Installed: $installed"

    if [ "$failed" -gt 0 ]; then
        log_warning "Failed: $failed"
        log_warning "Applications that failed: ${failed_apps[*]}"
    fi
}

# ---------------------------------------------
# Individual installers
# ---------------------------------------------

install_vscode() {
    if pkg_installed code; then
        log_success "Visual Studio Code is already installed"
        return 0
    fi

    add_apt_repo "vscode" \
        "https://packages.microsoft.com/keys/microsoft.asc" \
        "https://packages.microsoft.com/repos/code" \
        "stable" || return 1

    run_logged sudo apt install -y code
}

# JetBrains publishes neither an apt repository nor an official snap, so the
# tarball is the only supported route. Toolbox then manages the IDEs itself.
install_jetbrains_toolbox() {
    if [ -x "$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox" ] ||
       command -v jetbrains-toolbox &> /dev/null; then
        log_success "JetBrains Toolbox is already installed"
        return 0
    fi

    local url="https://data.services.jetbrains.com/products/download?code=TBA&platform=linux"
    local tmp
    tmp="$(mktemp -d)"

    log_info "Downloading JetBrains Toolbox..."

    if ! curl -fL --retry 3 -o "$tmp/toolbox.tar.gz" "$url" >> "$LOG" 2>&1; then
        log_error "Could not download JetBrains Toolbox"
        rm -rf "$tmp"
        return 1
    fi

    if ! tar -xzf "$tmp/toolbox.tar.gz" -C "$tmp" >> "$LOG" 2>&1; then
        log_error "Could not extract JetBrains Toolbox"
        rm -rf "$tmp"
        return 1
    fi

    local extracted
    extracted="$(find "$tmp" -maxdepth 1 -type d -name 'jetbrains-toolbox-*' | head -1)"

    if [ -z "$extracted" ]; then
        log_error "Unexpected archive layout, could not find the Toolbox directory"
        rm -rf "$tmp"
        return 1
    fi

    sudo rm -rf /opt/jetbrains-toolbox
    sudo mv "$extracted" /opt/jetbrains-toolbox
    sudo ln -sfn /opt/jetbrains-toolbox/bin/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox
    rm -rf "$tmp"

    log_success "JetBrains Toolbox installed to /opt/jetbrains-toolbox"
    log_info "Launch it once to sign in and pick your IDEs"
}

install_postman() {
    snap_install postman
}

install_dbeaver() {
    snap_install dbeaver-ce
}

install_lazygit() {
    if pkg_installed lazygit; then
        log_success "lazygit is already installed"
        return 0
    fi
    run_logged sudo apt install -y lazygit
}

# The package is git-delta, not delta: "delta" in the Ubuntu archive is an
# unrelated delta-debugging tool.
install_git_delta() {
    if pkg_installed git-delta; then
        log_success "git-delta is already installed"
        return 0
    fi

    run_logged sudo apt install -y git-delta || return 1

    if command -v delta &> /dev/null; then
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        log_success "git configured to use delta as its pager"
    fi
}

install_k9s() {
    snap_install k9s
}

install_obsidian() {
    snap_install obsidian --classic
}

install_slack() {
    snap_install slack
}
