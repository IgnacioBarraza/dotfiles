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
