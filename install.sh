#!/bin/bash

# The color variables below are consumed by the sourced scripts in scripts/,
# so shellcheck cannot see all of their uses from this file.
# This has to sit above the re-exec guard: a file-wide shellcheck directive
# only applies when it comes before any command.
# shellcheck disable=SC2034

# Re-exec under bash when started as `sh install.sh`. This script uses arrays,
# BASH_SOURCE and `source`, none of which dash has. Without this it would print
# a handful of errors and then carry on into the installer with no functions
# loaded at all, which is far worse than failing outright.
# Keep this block POSIX sh: dash has to be able to parse it.
if [ -z "${BASH_VERSION:-}" ]; then
    if command -v bash > /dev/null 2>&1; then
        exec bash "$0" "$@"
    fi
    echo "This installer requires bash, which was not found." >&2
    echo "Install it with: sudo apt install bash" >&2
    exit 1
fi


# █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
# █ Nach0_0 Dotfiles (2026)                             █
# █ project_url: https://github.com/IgnacioBarraza      █
# █ License: GNU GPLv3                                  █
# █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

# Inspired by JaKooLit and Irichu dotfiles's repo
# JaKooLit's github     https://github.com/JaKooLit
# Irichu's github       https://github.com/irichu

# Only clear when there is a terminal to clear. clear needs TERM just as tput
# does, and without one it writes to stderr, which is what broke CI.
[ -t 1 ] && clear

# Colors for output messages.
#
# tput needs a usable TERM. Without one it writes an error to stderr for every
# single call, which is noise in the log and enough to make `install.sh --help`
# fail in CI, in cron, or through a pipe. Fall back to plain labels instead of
# refusing to run without colour.
if [ -n "${TERM:-}" ] && [ "$TERM" != "dumb" ] && tput setaf 1 > /dev/null 2>&1; then
    _tput() { tput "$@" 2> /dev/null; }
else
    _tput() { :; }
fi

OK="$(_tput setaf 2)[OK]$(_tput sgr0)"
ERROR="$(_tput setaf 1)[ERROR]$(_tput sgr0)"
NOTE="$(_tput setaf 3)[NOTE]$(_tput sgr0)"
INFO="$(_tput setaf 4)[INFO]$(_tput sgr0)"
WARN="$(_tput setaf 1)[WARN]$(_tput sgr0)"
CAT="$(_tput setaf 6)[ACTION]$(_tput sgr0)"
MAGENTA="$(_tput setaf 5)"
ORANGE="$(_tput setaf 214)"
WARNING="$(_tput setaf 1)"
YELLOW="$(_tput setaf 3)"
GREEN="$(_tput setaf 2)"
BLUE="$(_tput setaf 4)"
SKY_BLUE="$(_tput setaf 6)"
RESET="$(_tput sgr0)"

unset -f _tput

print_color() {
    printf "%b%s%b\n" "$1" "$2" "$RESET"
}

print_info() {
    cat <<'EOF'
    Welcome to Nach0_0 setup script for Ubuntu 26.04

    Usage: ./install.sh [option]

    Option:
    • --desktop     Run only the desktop theme and login screen steps
    • --dry-run     Print what would be done and exit (non-interactive)
    • -h, --help    Show this message and exit

    Notes:
    • Run as regular user with sudo privileges, not as a root
    • Script checks for Ubuntu 26.04, so if Ubuntu 26.04 not installed this script would exit
EOF
}

# Get the directory where install.sh is located
# Repository root. Deliberately not called SCRIPT_DIR: the sourced scripts each
# resolve their own location into a variable of that name, so sharing it meant
# the first one sourced silently redirected every source after it.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# Load logging system
source "$DOTFILES_DIR/scripts/logging.sh"
source "$DOTFILES_DIR/scripts/utils.sh"
source "$DOTFILES_DIR/scripts/base_packages.sh"
source "$DOTFILES_DIR/scripts/setup_git.sh"
source "$DOTFILES_DIR/scripts/terminal_setup.sh"
source "$DOTFILES_DIR/scripts/apps_setup.sh"
source "$DOTFILES_DIR/scripts/languages_setup.sh"
source "$DOTFILES_DIR/scripts/docker_setup.sh"
source "$DOTFILES_DIR/scripts/databases_setup.sh"
source "$DOTFILES_DIR/scripts/caelestia_setup.sh"
source "$DOTFILES_DIR/scripts/krunner_setup.sh"
source "$DOTFILES_DIR/scripts/desktop_setup.sh"
source "$DOTFILES_DIR/scripts/login_setup.sh"

DO_DRY_RUN=0
DO_DESKTOP_ONLY=0
SHOW_HELP=0

for arg in "$@"; do
    case "$arg" in
    -h | --help)
        SHOW_HELP=1
        ;;
    --dry-run)
        DO_DRY_RUN=1
        ;;
    --desktop)
        DO_DESKTOP_ONLY=1
        ;;
    esac
done

if [ "$SHOW_HELP" = "1" ]; then 
    print_info
    exit 0
fi

# Non-interactive dry-run exits early (before any prompts)
if [ "$DO_DRY_RUN" = "1" ]; then
    print_color $SKY_BLUE "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
    █       [DRY-RUN] Nach0_0's Ubuntu 26.04 Setup        █
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█"
    echo ""
    print_color $YELLOW "[DRY-RUN] Would perform the following operations:"
    echo ""
    print_color $GREEN "  ✓ Update system packages"
    print_color $GREEN "  ✓ Install base packages (build-essential, curl, git, python3, cargo...)"
    print_color $GREEN "  ✓ Configure Git (user, defaults, optional SSH key)"
    print_color $GREEN "  ✓ Install a terminal emulator (Kitty or Alacritty)"
    print_color $GREEN "  ✓ Install fonts (FiraCode Nerd Font, Noto Sans CJK)"
    print_color $GREEN "  ✓ Install the Kitty and Alacritty configurations and themes"
    print_color $GREEN "  ✓ Install ZSH and Oh My Zsh, set it as the default shell"
    print_color $GREEN "  ✓ Install Starship, ZSH plugins and CLI utilities (eza, bat, ripgrep, fd, jq...)"
    print_color $GREEN "  ✓ Add shell aliases for the installed CLI tools"
    print_color $GREEN "  ✓ Install fastfetch and its configuration"
    print_color $GREEN "  ✓ Install Pokémon ASCII art on terminal startup (fastfetch + pokeget)"
    print_color $GREEN "  ✓ Install a browser (Brave, Chrome or keep Firefox)"
    print_color $GREEN "  ✓ Install applications: VS Code, JetBrains Toolbox, Postman, DBeaver,"
    print_color $GREEN "    lazygit, git-delta, k9s, Obsidian, Slack (multi-select)"
    print_color $GREEN "  ✓ Install languages: Node via nvm, Python tooling via pipx,"
    print_color $GREEN "    JDK/Maven/Gradle via SDKMAN, Go (multi-select)"
    print_color $GREEN "  ✓ Install Docker CE, add you to the docker group, optional lazydocker"
    print_color $GREEN "  ✓ Install database clients and the example compose stack"
    print_color $GREEN "  ✓ Theme the desktop: the Nach0_0 Plasma theme or the Caelestia shell"
    print_color $GREEN "  ✓ Theme the SDDM login screen with the same generated palette"
    echo ""
    print_color $NOTE "[DRY-RUN] No changes were made to your system."
    print_color $INFO "[DRY-RUN] Run without --dry-run to proceed with installation."
    exit 0
fi

if [ "$DO_DESKTOP_ONLY" != "1" ]; then
echo -e "\n\n"
print_color $WARNING "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
    █           Nach0_0's UBUNTU 26.04 - Setup            █
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    - This repo installs and configures a terminal-first development environment
    - These scripts will install and configure:
        - Base build tooling (build-essential, curl, git, python3, cargo)
        - Git (user, sane defaults, optional SSH key)
        - A terminal emulator (Kitty or Alacritty) with matching themes
        - Fonts (FiraCode Nerd Font, Noto Sans CJK)
        - ZSH + Oh My Zsh + Starship + plugins
        - CLI utilities (eza, bat, ripgrep, fd, jq, fzf, btop...)
        - Pokémon ASCII art on terminal startup
        - Applications: VS Code, JetBrains Toolbox, Postman, DBeaver, browser
        - Terminal tools: lazygit, git-delta, k9s
        - Languages: Node (nvm), Python tooling (pipx), JVM (SDKMAN), Go
        - Docker CE with compose, and optionally lazydocker
        - Database clients, with the servers left to a compose stack
        - A desktop theme: the Nach0_0 Plasma theme or the Caelestia shell
        - The SDDM login screen, themed from the same palette
    - Database servers run in a compose stack, not on the host
    - To know what it's being installed, check the README.md
    - Use at your own risk!
    - Note: This installer will refuse to run outside Ubuntu 26.04.
"
echo -e "\n\n"

read -rp "$YELLOW Do you want to continue with the installation using this scripts? [y/N]: " confirm
case "$confirm" in
[yY][eE][sS] | [yY])
    echo
    echo -e "${OK} Continuing with installation..."
    read -r -t 0.1 -N 10000 2>/dev/null || true
    ;;
*)
    echo
    echo
    echo -e "${NOTE} You chose not to continue. Exiting..."
    echo
    exit 1
    ;;
esac
fi

# Check ubuntu version
if ! grep -q "Ubuntu 26.04" /etc/os-release; then
    print_color $ERROR "This script is designed for Ubuntu 26.04 only."
    print_color $ERROR "Detected: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    exit 1
fi


# Initialize logs
LOG_DIR="Dotfiles-Logs"
init_logging

log_info "Starting main installation at $(date)"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    printf "\n%.0s" {1..2}
    exit 1
fi

log_info "Checking write permissions in current directory..."

# Try to create a temporary file to test write permissions
if ! touch .write_test 2>/dev/null; then
    log_error "No write permissions in current directory: $(pwd)"
    log_error "Please run this script from a directory where you have write permissions."
    log_error "Recommended: clone to ~/dotfiles or your home directory."
    exit 1
else
    rm -f .write_test
    log_success "Write permissions verified in: $(pwd)"
fi

if [ "$DO_DESKTOP_ONLY" = "1" ]; then
    setup_desktop
    setup_login_screen
    print_post_install_summary
    exit 0
fi

# Install base packages
install_base_packages || {
    log_error "Base packages installation failed."
    exit 1
}

# Configure Git
configure_git

# Setup terminal
setup_terminal

# Install applications
setup_apps

# Install language runtimes and tooling
setup_languages

# Install Docker
setup_docker

# Install database clients and the example compose stack
setup_databases

# Theme the desktop
setup_desktop

# Theme the login screen
setup_login_screen


log_info "Performing final system cleanup..."

run_logged sudo apt clean

run_logged sudo apt autoremove -y

log_success "Cleanup completed"

print_color $OK "✅ Installation completed successfully!"
print_color $INFO "📄 Log file saved at: $LOG"

# Anything that still needs a human, collected from every step and printed
# here rather than where it happened.
print_post_install_summary