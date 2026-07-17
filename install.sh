#!/bin/bash

# █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
# █ Nach0_0 Dotfiles (2026)                             █
# █ project_url: https://github.com/IgnacioBarraza      █
# █ License: GNU GPLv3                                  █
# █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

# Inspired by JaKooLit and Irichu dotfiles's repo
# JaKooLit's github     https://github.com/JaKooLit
# Irichu's github       https://github.com/irichu

clear

# Colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

print_color() {
    printf "%b%s%b\n" "$1" "$2" "$RESET"
}

print_info() {
    cat <<'EOF'
    Welcome to Nach0_0 setup script for Ubuntu 26.04

    Usage: ./install.sh [option]

    Option:
    • --dry-run     Print what would be done and exit (non-interactive)
    • -h, --help    Show this message and exit

    Notes:
    • Run as regular user with sudo privileges, not as a root
    • Script checks for Ubuntu 26.04, so if Ubuntu 26.04 not installed this script would exit
EOF
}

# Get the directory where install.sh is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load logging system
source "$SCRIPT_DIR/scripts/logging.sh"
source "$SCRIPT_DIR/scripts/base_packages.sh"
source "$SCRIPT_DIR/scripts/setup_git.sh"

DO_DRY_RUN=0
SHOW_HELP=0

for arg in "$@"; do
    case "$arg" in
    -h | --help)
        SHOW_HELP=1
        ;;
    --dry-run)
        DO_DRY_RUN=1
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
    print_color $GREEN "  ✓ Install Node.js (via NVM)"
    print_color $GREEN "  ✓ Setup terminal environment (ZSH, Oh My Zsh, Jovial theme, Pokémon art)"
    print_color $GREEN "  ✓ Install development tools (Python, Java, Go, C/C++)"
    print_color $GREEN "  ✓ Install Docker and Docker Compose"
    print_color $GREEN "  ✓ Install database clients (PostgreSQL, Redis, MongoDB)"
    print_color $GREEN "  ✓ Install CLI utilities (eza, bat, ripgrep, fd, jq)"
    print_color $GREEN "  ✓ Configure KDE customizations (Kvantum, Fira Code, kio-gdrive)"
    echo ""
    print_color $NOTE "[DRY-RUN] No changes were made to your system."
    print_color $INFO "[DRY-RUN] Run without --dry-run to proceed with installation."
    exit 0
fi

echo -e "\n\n"
print_color $WARNING "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
    █           Nach0_0's UBUNTU 26.04 - Setup            █
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    - This repo install and setup dependencies to generate a development environment
    - These scripts will install and configure a development environment based on the following langs and packages
        - Node.JS
        - Angular
        - React.js
        - PostgreSQL & PgAdmin4
        - Zsh (with Jovial theme, this can be changed later if you want another theme)
        - TypeScript
        - Go
        - C/C++
        - Python
        - Java 21
        - And more
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
    ;;
*)
    echo
    echo
    echo -e "${NOTE} You chose not to continue. Exiting..."
    echo
    exit 1
    ;;
esac

# Check ubuntu version
if ! grep -q "Ubuntu 26.04" /etc/os-release; then
    print_color $ERROR "This script is designed for Ubuntu 26.04 only."
    print_color $ERROR "Detected: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    exit 1
fi

# Initialize logs
LOG_DIR="Dotfiles-Logs"
init_logging

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
    printf "\n%.0s" {1..2}
    exit 1
fi

log_info "Starting main installation at $(date)"
    
# Install base packages
install_base_packages || {
    log_error "Base packages installation failed."
    exit 1
}

# Configure Git
configure_git()