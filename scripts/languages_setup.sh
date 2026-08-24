#!/bin/bash

# ============================================
# 05. LANGUAGE SETUP SCRIPT
# ============================================
#
# This script installs language runtimes and their tooling.
#
# Version managers are preferred over system packages where the ecosystem has
# one: nvm for Node and SDKMAN for the JVM. Both let a project pin its own
# version, and SDKMAN also sidesteps the Gradle in the Ubuntu archive, which
# is stuck on 4.4.1 from 2017.
#
# Functions:
#   - setup_languages: Main function
#   - install_language_stack: Multi-select menu
#   - ensure_sdkman: Install SDKMAN and make it usable in this shell
#   - install_*: Individual installers
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, zshrc_ensure_line)
#   - Colors defined in main script

# Pinned rather than tracking master, so a run is reproducible. Bump this
# deliberately when nvm cuts a release.
NVM_VERSION="v0.40.7"

# The JDK major version to install through SDKMAN. Temurin is the default
# vendor; SDKMAN identifiers look like "21.0.12+1.1-tem".
JDK_MAJOR="21"
JDK_VENDOR="tem"

# category | display name | how it is installed | installer function
LANGUAGES=(
    "JavaScript and TypeScript|nvm and Node.js LTS|install script|install_node"
    "JavaScript and TypeScript|pnpm and yarn|corepack|install_pnpm_yarn"
    "Python|pipx and dev tools|apt, then pipx|install_python_tools"
    "Java and JVM|SDKMAN and OpenJDK ${JDK_MAJOR}|install script|install_java"
    "Java and JVM|Maven and Gradle|via SDKMAN|install_maven_gradle"
    "Go|Go toolchain|apt|install_go"
)

setup_languages() {
    log_info "Starting language setup"

    install_language_stack

    log_success "Language setup completed"
}

install_language_stack() {
    log_info "Select the languages and tooling to install"
    echo ""

    local i=1
    local last_category=""
    local entry category name method

    for entry in "${LANGUAGES[@]}"; do
        IFS='|' read -r category name method _ <<< "$entry"
        if [ "$category" != "$last_category" ]; then
            [ -n "$last_category" ] && echo ""
            echo "  ${MAGENTA}${category}${RESET}"
            last_category="$category"
        fi
        printf "    %2d) %-26s %s\n" "$i" "$name" "($method)"
        i=$((i + 1))
    done

    echo ""
    echo "  Enter numbers separated by commas or spaces (for example: 1,3)"
    echo "  Type 'all' for everything, or leave empty to skip."
    echo ""

    read -rp "Your choice: " selection

    if [ -z "${selection// /}" ]; then
        log_info "Skipping language installation"
        return 0
    fi

    local chosen=()

    if [ "${selection,,}" = "all" ]; then
        local n
        for n in $(seq 1 ${#LANGUAGES[@]}); do
            chosen+=("$n")
        done
    else
        local raw
        read -ra raw <<< "${selection//,/ }"
        local token
        for token in "${raw[@]}"; do
            if ! [[ "$token" =~ ^[0-9]+$ ]] || [ "$token" -lt 1 ] || [ "$token" -gt ${#LANGUAGES[@]} ]; then
                log_warning "Ignoring invalid choice: $token"
                continue
            fi
            chosen+=("$token")
        done
    fi

    if [ ${#chosen[@]} -eq 0 ]; then
        log_warning "Nothing valid selected, skipping language installation"
        return 0
    fi

    local installed=0
    local failed=0
    local failed_items=()
    local index installer

    for index in "${chosen[@]}"; do
        IFS='|' read -r _ name _ installer <<< "${LANGUAGES[index - 1]}"

        log_info "=== $name ==="

        if "$installer"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
            failed_items+=("$name")
        fi
    done

    log_info "=== Language Installation Summary ==="
    log_info "Selected: ${#chosen[@]}"
    log_info "Installed: $installed"

    if [ "$failed" -gt 0 ]; then
        log_warning "Failed: $failed"
        log_warning "Items that failed: ${failed_items[*]}"
    fi
}

# ---------------------------------------------
# JavaScript and TypeScript
# ---------------------------------------------

# nvm is a shell function, not a binary, so it has to be sourced before use.
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    command -v nvm &> /dev/null
}

install_node() {
    if [ -d "$HOME/.nvm" ]; then
        log_success "nvm is already installed"
    else
        log_info "Installing nvm $NVM_VERSION..."
        if ! run_logged bash -c \
            "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"; then
            log_error "Failed to install nvm"
            return 1
        fi
        log_success "nvm installed"
    fi

    if ! load_nvm; then
        log_error "nvm was installed but could not be loaded"
        return 1
    fi

    log_info "Installing the latest Node.js LTS..."

    if ! run_logged nvm install --lts; then
        log_error "Failed to install Node.js"
        return 1
    fi

    nvm alias default 'lts/*' >> "$LOG" 2>&1

    log_success "Node.js $(node --version 2>/dev/null) installed"

    # The nvm installer appends to whichever profile it detects, and it does not
    # detect .zshrc when it is itself running under bash.
    zshrc_ensure_line 'export NVM_DIR="$HOME/.nvm"' "Node Version Manager"
    zshrc_ensure_line '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' ""
    zshrc_ensure_line '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' ""
}

install_pnpm_yarn() {
    if ! load_nvm && ! command -v node &> /dev/null; then
        log_error "Node.js is required for pnpm and yarn. Install it first."
        return 1
    fi

    if ! command -v corepack &> /dev/null; then
        log_error "corepack not found. It ships with Node.js, so install Node first."
        return 1
    fi

    log_info "Enabling corepack..."

    if ! run_logged corepack enable; then
        log_error "Failed to enable corepack"
        return 1
    fi

    local ok=0

    if run_logged corepack prepare pnpm@latest --activate; then
        log_success "pnpm $(pnpm --version 2>/dev/null) activated"
    else
        log_warning "Could not activate pnpm"
        ok=1
    fi

    if run_logged corepack prepare yarn@stable --activate; then
        log_success "yarn $(yarn --version 2>/dev/null) activated"
    else
        log_warning "Could not activate yarn"
        ok=1
    fi

    return "$ok"
}

# ---------------------------------------------
# Python
# ---------------------------------------------

# Ubuntu marks the system interpreter as externally managed (PEP 668), so
# `pip install` into it fails by design. pipx gives every tool its own venv,
# which is the supported way to install Python applications here.
install_python_tools() {
    if ! pkg_installed pipx; then
        if ! run_logged sudo apt install -y pipx; then
            log_error "Failed to install pipx"
            return 1
        fi
    else
        log_success "pipx is already installed"
    fi

    pipx ensurepath >> "$LOG" 2>&1 || true
    export PATH="$HOME/.local/bin:$PATH"

    # ruff replaces both black and flake8: it formats and lints, much faster.
    local tools=(ruff mypy ipython)
    local tool
    local failed=0

    for tool in "${tools[@]}"; do
        if pipx list --short 2>/dev/null | grep -q "^$tool "; then
            log_success "$tool is already installed"
            continue
        fi

        if run_logged pipx install "$tool"; then
            log_success "$tool installed"
        else
            log_error "Failed to install $tool"
            failed=1
        fi
    done

    return "$failed"
}

# ---------------------------------------------
# Java and the JVM
# ---------------------------------------------

ensure_sdkman() {
    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        log_success "SDKMAN is already installed"
    else
        log_info "Installing SDKMAN..."
        if ! run_logged bash -c "curl -s https://get.sdkman.io | bash"; then
            log_error "Failed to install SDKMAN"
            return 1
        fi
        log_success "SDKMAN installed"
    fi

    # Without this, `sdk install` stops to ask whether to set the new version
    # as the default, which never gets answered in a scripted run.
    local config="$HOME/.sdkman/etc/config"
    if [ -f "$config" ] && ! grep -q "^sdkman_auto_answer=true" "$config"; then
        sed -i 's/^sdkman_auto_answer=.*/sdkman_auto_answer=true/' "$config"
    fi

    # shellcheck source=/dev/null
    . "$HOME/.sdkman/bin/sdkman-init.sh"

    if ! command -v sdk &> /dev/null; then
        log_error "SDKMAN was installed but the sdk function is not available"
        return 1
    fi

    zshrc_ensure_line 'export SDKMAN_DIR="$HOME/.sdkman"' "SDKMAN"
    zshrc_ensure_line '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' ""
}

install_java() {
    ensure_sdkman || return 1

    if sdk current java 2>/dev/null | grep -q "$JDK_MAJOR"; then
        log_success "A Java $JDK_MAJOR is already the current SDKMAN JDK"
        return 0
    fi

    # SDKMAN identifiers are not predictable from the major version alone:
    # Temurin 21 is published as "21.0.12+1.1-tem". Read the real list instead
    # of guessing a string.
    #
    # Only digits, dots and + are allowed between the major and the vendor, so
    # variant builds like "21.0.12.fx-zulu" (bundled JavaFX) or
    # "21.0.12-crac+1.2-librca" are not picked up by accident.
    local candidate
    candidate="$(sdk list java 2>/dev/null \
        | awk -F'|' 'NF>3 {gsub(/^ +| +$/,"",$4); print $4}' \
        | grep -E "^${JDK_MAJOR}\.[0-9.+]*-${JDK_VENDOR}$" | head -1)"

    if [ -z "$candidate" ]; then
        log_error "No Java $JDK_MAJOR build from '$JDK_VENDOR' is available in SDKMAN"
        log_info "Run 'sdk list java' and install one by hand"
        return 1
    fi

    log_info "Installing Java $candidate..."

    if ! run_logged sdk install java "$candidate"; then
        log_error "Failed to install Java $candidate"
        return 1
    fi

    log_success "Java installed: $(java -version 2>&1 | head -1)"
}

install_maven_gradle() {
    ensure_sdkman || return 1

    local failed=0
    local tool

    for tool in maven gradle; do
        if sdk current "$tool" &> /dev/null; then
            log_success "$tool is already installed"
            continue
        fi

        log_info "Installing $tool..."

        if run_logged sdk install "$tool"; then
            log_success "$tool installed"
        else
            log_error "Failed to install $tool"
            failed=1
        fi
    done

    return "$failed"
}

# ---------------------------------------------
# Go
# ---------------------------------------------

install_go() {
    if pkg_installed golang-go; then
        log_success "Go is already installed"
    elif ! run_logged sudo apt install -y golang-go; then
        log_error "Failed to install Go"
        return 1
    fi

    # `go install` drops binaries in GOPATH/bin, which is not on PATH by default.
    zshrc_ensure_line 'export PATH="$HOME/go/bin:$PATH"' "Go binaries"

    log_success "Go installed: $(go version 2>/dev/null)"
}
