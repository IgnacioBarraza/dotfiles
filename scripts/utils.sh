#!/bin/bash

# ============================================
# 00. SHARED UTILITIES
# ============================================
#
# Small helpers shared by the installation scripts.
#
# Functions:
#   - pkg_installed: Check whether an apt package is installed
#   - run_logged: Run a command, mirror its output to the log, return its real exit code
#   - backup_file: Copy a file next to itself with a timestamp suffix
#   - zshrc_ensure_line: Append a line to .zshrc only if it is not already there
#   - zshrc_add_plugins: Merge plugins into the existing plugins=() list
#   - add_apt_repo: Register a third-party apt repository in deb822 format
#   - snap_install: Install a snap if it is not already there
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_warning, log_error)

# Query dpkg directly instead of grepping `dpkg -l` output, whose column
# layout is not a stable interface and matches partial package names.
pkg_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "^install ok installed$"
}

# `cmd | tee` makes $? the exit code of tee, which is always 0. Wrapping the
# command here keeps the log mirroring while returning the real exit code.
run_logged() {
    "$@" 2>&1 | tee -a "$LOG"
    return "${PIPESTATUS[0]}"
}

backup_file() {
    local file="$1"

    [ -f "$file" ] || return 0

    local backup="${file}.bak.$(date +%Y%m%d-%H%M%S)"

    if cp "$file" "$backup"; then
        log_info "Backed up $file to $backup"
        return 0
    else
        log_error "Could not back up $file"
        return 1
    fi
}

zshrc_ensure_line() {
    local line="$1"
    local comment="$2"
    local zshrc="$HOME/.zshrc"

    if [ ! -f "$zshrc" ]; then
        log_warning "No .zshrc found, skipping: $line"
        return 1
    fi

    if grep -qF -- "$line" "$zshrc"; then
        return 0
    fi

    {
        echo ""
        [ -n "$comment" ] && echo "# $comment"
        echo "$line"
    } >> "$zshrc"

    return 0
}

# Merges into the existing plugins=() list, in either the single-line form
# `plugins=(a b c)` or the multi-line form with one plugin per line.
# Overwriting the list wholesale would silently drop plugins the user had.
zshrc_add_plugins() {
    local zshrc="$HOME/.zshrc"
    local wanted=("$@")

    if [ ! -f "$zshrc" ]; then
        log_warning "No .zshrc found, skipping plugin configuration"
        return 1
    fi

    if ! grep -q "^plugins=(" "$zshrc"; then
        printf '\nplugins=(%s)\n' "${wanted[*]}" >> "$zshrc"
        log_success "Plugins added to .zshrc: ${wanted[*]}"
        return 0
    fi

    local multiline=0
    local current

    if grep -q "^plugins=(.*)" "$zshrc"; then
        current="$(sed -n 's/^plugins=(\(.*\)).*/\1/p' "$zshrc" | head -1)"
    else
        multiline=1
        # Everything between the opening plugins=( and its closing paren,
        # minus comments and indentation.
        current="$(awk '/^plugins=\(/{f=1;next} f&&/^[[:space:]]*\)/{f=0} f' "$zshrc" \
                   | sed 's/#.*//' | tr -s '[:space:]' ' ')"
    fi

    local existing=()
    read -ra existing <<< "$current"

    local merged=("${existing[@]}")
    local added=()
    local p e found

    for p in "${wanted[@]}"; do
        found=0
        for e in "${existing[@]}"; do
            if [ "$e" = "$p" ]; then
                found=1
                break
            fi
        done
        if [ "$found" -eq 0 ]; then
            merged+=("$p")
            added+=("$p")
        fi
    done

    if [ ${#added[@]} -eq 0 ]; then
        log_info "All plugins already present in .zshrc"
        return 0
    fi

    backup_file "$zshrc"

    if [ "$multiline" -eq 1 ]; then
        # Append before the closing paren, not after the opening one:
        # zsh-syntax-highlighting only works if it is sourced last.
        local close
        close="$(awk '/^plugins=\(/{f=1} f&&/^[[:space:]]*\)/{print NR; exit}' "$zshrc")"

        if [ -z "$close" ]; then
            log_warning "Could not find the end of plugins=() in .zshrc; add by hand: ${added[*]}"
            return 1
        fi

        local i
        for (( i=${#added[@]}-1; i>=0; i-- )); do
            sed -i "${close}i\\  ${added[i]}" "$zshrc"
        done
    else
        sed -i "s/^plugins=(.*)/plugins=(${merged[*]})/" "$zshrc"
    fi

    log_success "Plugins added to .zshrc: ${added[*]}"
}

# Registers a third-party apt repository:
#
#   add_apt_repo <name> <key_url> <repo_url> <suite> [components]
#
# Only the host architecture is declared. Listing extra ones makes apt download
# their package lists on every single update for nothing, which is how a stray
# "Architectures: amd64 arm64" ends up costing 292K per refresh on an amd64 box.
#
# deb822 (.sources) is used rather than the one-line .list format, so there is
# one canonical place per repository instead of two that can drift apart.
add_apt_repo() {
    local name="$1"
    local key_url="$2"
    local repo_url="$3"
    local suite="$4"
    local components="${5:-main}"

    local keyring="/etc/apt/keyrings/${name}.gpg"
    local source_file="/etc/apt/sources.list.d/${name}.sources"

    if [ -f "$source_file" ]; then
        log_success "$name repository already configured"
        return 0
    fi

    sudo install -d -m 0755 /etc/apt/keyrings

    log_info "Fetching the $name signing key..."

    local tmp
    tmp="$(mktemp)"

    if ! curl -fsSL --retry 3 -o "$tmp" "$key_url"; then
        log_error "Could not download the $name signing key from $key_url"
        rm -f "$tmp"
        return 1
    fi

    # Vendors publish keys both ASCII-armored and binary; only dearmor the former.
    if grep -q "BEGIN PGP PUBLIC KEY BLOCK" "$tmp"; then
        sudo gpg --dearmor --yes -o "$keyring" < "$tmp"
    else
        sudo install -m 0644 "$tmp" "$keyring"
    fi
    rm -f "$tmp"

    sudo chmod 0644 "$keyring"

    if ! sudo tee "$source_file" > /dev/null <<EOF
Types: deb
URIs: $repo_url
Suites: $suite
Components: $components
Architectures: $(dpkg --print-architecture)
Signed-By: $keyring
EOF
    then
        log_error "Could not write $source_file"
        sudo rm -f "$keyring"
        return 1
    fi

    log_success "$name repository configured"

    if run_logged sudo apt update; then
        return 0
    fi

    log_warning "apt update reported problems after adding the $name repository"
    return 1
}

snap_install() {
    local name="$1"
    shift

    if ! command -v snap &> /dev/null; then
        log_error "snapd is not installed, cannot install $name"
        return 1
    fi

    if snap list "$name" &> /dev/null; then
        log_success "$name is already installed"
        return 0
    fi

    # Snaps published with classic confinement refuse to install unless
    # --classic is passed, and the error is only visible in the log. Read the
    # confinement from the store rather than remembering, per call site, which
    # snap happens to need the flag.
    local extra=("$@")

    if [ ${#extra[@]} -eq 0 ] &&
       snap info --verbose "$name" 2>/dev/null | grep -qE "^ *confinement: *classic"; then
        extra+=(--classic)
        log_info "$name uses classic confinement, adding --classic"
    fi

    log_info "Installing $name via snap..."

    if run_logged sudo snap install "$name" "${extra[@]}"; then
        log_success "$name installed"
        return 0
    fi

    log_error "Failed to install $name"
    return 1
}
