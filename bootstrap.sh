#!/bin/sh

# █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
# █ Nach0_0 Dotfiles (2026) - Bootstrap                 █
# █ project_url: https://github.com/IgnacioBarraza      █
# █ License: GNU GPLv3                                  █
# █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

# Clones the repository and hands over to install.sh.
#
# install.sh cannot be run straight from a pipe or a process substitution:
# it resolves its own directory to source scripts/*.sh, and that path does
# not exist when the script has no location on disk.
#
# Usage:
#   sh <(curl -L https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/bootstrap.sh)
#   curl -fsSL https://raw.githubusercontent.com/IgnacioBarraza/dotfiles/main/bootstrap.sh | sh
#
# Override the clone location with DOTFILES_DIR.

set -e

REPO_URL="https://github.com/IgnacioBarraza/dotfiles.git"
TARGET="${DOTFILES_DIR:-$HOME/dotfiles}"

info() { printf '\033[34m[INFO]\033[0m %s\n' "$1"; }
ok() { printf '\033[32m[OK]\033[0m %s\n' "$1"; }
error() { printf '\033[31m[ERROR]\033[0m %s\n' "$1" >&2; }

if [ "$(id -u)" -eq 0 ]; then
    error "Do not run this installer as root."
    exit 1
fi

if ! command -v git > /dev/null 2>&1; then
    info "git not found, installing it..."
    sudo apt update
    sudo apt install -y git
fi

if [ -d "$TARGET/.git" ]; then
    info "Existing clone found at $TARGET, updating..."
    git -C "$TARGET" pull --ff-only
elif [ -e "$TARGET" ]; then
    error "$TARGET already exists and is not a git clone."
    error "Move it out of the way or set DOTFILES_DIR to another path."
    exit 1
else
    info "Cloning into $TARGET..."
    git clone --depth=1 "$REPO_URL" "$TARGET"
fi

chmod +x "$TARGET/install.sh"
ok "Repository ready at $TARGET"

# install.sh is interactive. When this script arrives through a pipe, stdin is
# the pipe instead of the terminal, so the prompts need the tty re-attached.
if ( : < /dev/tty ) 2> /dev/null; then
    exec bash "$TARGET/install.sh" < /dev/tty
else
    error "No terminal available to run the interactive installer."
    error "Run it directly instead:  cd $TARGET && ./install.sh"
    exit 1
fi
