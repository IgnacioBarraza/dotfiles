#!/bin/bash

# ============================================
# 03. TERMINAL SETUP SCRIPT
# ============================================
#
# This script installs and configures ZSH, Oh My Zsh,
# the Jovial theme, and Pokémon ASCII art.
#
# Functions:
#   - setup_terminal: Main function
#   - install_zsh: Install ZSH
#   - install_oh_my_zsh: Install Oh My Zsh
#   - install_jovial_theme: Install Jovial theme
#   - install_pokemon_art: Install Pokémon ASCII art
#   - install_zsh_plugins: Install additional plugins
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error)
#   - Colors defined in main script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_terminal() {
    log_info "Starting terminal environment setup"

    install_terminal

    install_zsh

    install_jovial_theme

    install_pokemon_art

    log_success "Terminal environment setup completed"
}

install_zsh() {
    log_info "Starting ZSH setup and installation"

    read -rp "Do you want to install ZSH? [y/N]: " confirm

    if ! command -v zsh &> /dev/null; then
        log_info "ZSH not found, Installing ZSH"
        sudo apt install -y zsh 2>&1 | tee -a "$LOG"
        if [ $? -eq 0 ]; then
            log_success "ZSH installed successfully"
        else
            log_error "Failed to install ZSH"
            return 1
        fi
    else
        log_success "ZSH already installed: $(zsh --version)"
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | tee -a "$LOG"
        if [ $? -eq 0 ]; then
            log_success "Oh My Zsh installed successfully"
        else
            log_error "Failed to install Oh My Zsh"
            return 1
        fi
    else
        log_success "Oh My Zsh already installed"
    fi

    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Changing default shell to ZSH..."
        sudo chsh -s $(which zsh) $USER 2>&1 | tee -a "$LOG"
        if [ $? -eq 0 ]; then
            log_warning "Default shell changed to ZSH. Please log out and log back in for changes to take effect."
        else
            log_error "Failed to change default shell to ZSH"
            return 1
        fi
    else
        log_info "ZSH is already the default shell"
    fi

    log_success "ZSH and Oh My Zsh setup completed"
    return 0
}

install_jovial_theme() {
    log_info "Installing terminal customization"

    read -rp "Do you want to install Jovial Theme and related plugins? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY])
        log_info "Installing needed plugins..."
        
        local deps=(
            fzf
            jq
        )
        local installed_count=0
        local failed_count=0
        local failed_deps=()
        local total_packages=${#deps[@]}


        for dep in "${deps[@]}"; do
            if dpkg -l | grep -q "^ii $dep"; then
                log_info "$dep already installed"
                ((installed_count++))
                continue
            fi

            log_info "Installing $dep..."
            sudo apt install -y "$dep" 2>&1 | tee -a "$LOG"

            if [ $? -eq 0 ]; then
                log_success "$dep installed successfully"
                ((installed_count++))
            else
                log_error "Failed to install $dep"
                ((failed_count++))
                failed_deps+=("$dep")
            fi
        done

        log_info "=== Base Installation Summary ==="
        log_info "Total packages: $total_packages"
        log_info "Installed: $installed_count"
        if [ $failed_count -gt 0 ]; then
            log_warning "Failed: $failed_count"
            log_warning "Packages failed to install: ${failed_deps[*]}"
            log_warning "Some packages may need manual installation"
        fi

        if [ ! -f "$HOME/.oh-my-zsh/custom/themes/jovial.zsh-theme" ]; then
            log_info "Installing Jovial theme..."
            curl -sSL https://github.com/zthxxx/jovial/raw/master/installer.sh | sudo -E bash -s ${USER:=`whoami`} | tee -a "$LOG"

            if [ $? -eq 0 ]; then
                log_success "Jovial theme installed successfully"
            else
                log_error "Failed to install Jovial theme"
            fi
        else
            log_success "Jovial theme already installed"
            return 0
        fi
    ;;
    *)
        log_info "Skip jovial theme installation..."
        ;;
    esac

    log_success "Terminal customization terminated"
}

install_terminal() {
    log_info "Select a terminal to install"
    echo ""
    echo "  1) Kitty (recommended, feature-rich)"
    echo "  2) Alacritty (minimalist, GPU-accelerated)"
    echo "  3) Skip (use default terminal)"
    echo ""

    read -rp "Enter your choice [1|2|3]: " term_choice

    case "$term_choice" in
        1)
            install_selected_terminal "kitty"
            ;;
        2)
            install_selected_terminal "alacritty"
            ;;
        3)
            log_info "Using default terminal"
            ;;
        *)
            log_warning "Invalid choice. Skipping terminal setup and installation"
            ;;
    esac
}

install_selected_terminal() {
    local terminal="$1"

    if dpkg -l | grep -q "^ii  $terminal"; then
        log_success "$terminal is already installed"
        return 0
    fi

    log_info "Installing $terminal..."

    sudo apt install -y "$terminal" 2>&1 | tee -a "$LOG"

    if [ $? -eq 0 ]; then
        log_success "$terminal installed successfully"
        sudo update-alternatives --set x-terminal-emulator "/usr/bin/$terminal" 2>/dev/null || true
    else
        log_error "Failed to install $terminal"
        return 1
    fi
}


install_pokemon_art() {
    log_info "Starting with terminal customization"

    read -rp "Do you want to customize the terminal with Pokemon Art? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY])
        log_info "Installing dependencies..."

        log_info "Installing fastfetch..."
        if dpkg -l | grep -q "^ii  fastfetch"; then
            log_success "Fastfetch is already installed"
        else
            log_info "Installing Fastfetch..."
            sudo apt install -y fastfetch 2>&1 | tee -a "$LOG"
            if [ $? -eq 0 ]; then
                log_success "Fastfetch installed successfully"
            else
                log_error "Failed to install fastfetch"
            fi
        fi

        log_info "Check if cargo is already installed"

        if ! command -v cargo &> /dev/null; then
            log_info "Cargo not found. Installing Rust and Cargo..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOG"
            source "$HOME/.cargo/env"
            if [ $? -eq 0 ]; then
                log_success "Rust and Cargo installed successfully"
            else
                log_error "Failed to install Rust and Cargo"
                return 1
            fi
        else
            log_success "Cargo already installed"
        fi

        log_info "Installing pokeget via cargo..."
        if ! command -v pokeget &> /dev/null; then
            cargo install pokeget 2>&1 | tee -a "$LOG"

            if [ $? -eq 0 ]; then
                log_success "pokeget installed successfully"
            else
                log_error "Failed to install pokeget"
                return 1
            fi
        else
            log_success "Pokeget already installed"
        fi

        if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.zshrc; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
            log_info "~/.cargo/bin added to PATH in .zshrc"
        fi

        # Create local bin directory if it doesn't exist
        mkdir -p ~/.local/bin

        if [ -f "$SCRIPT_DIR/../config/bin/pokemon.sh" ]; then
            cp "$SCRIPT_DIR/../config/bin/pokemon.sh" ~/.local/bin/
            chmod +x ~/.local/bin/pokemon.sh
            log_success "pokemon.sh copied from config/bin/"
        fi

        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
            log_info "~/.local/bin added to PATH in .zshrc"
        fi

        if ! grep -q "pokemon.sh" ~/.zshrc; then
            echo "" >> ~/.zshrc
            echo "# Pokémon Art on terminal startup" >> ~/.zshrc
            echo '[ -t 1 ] && ~/.local/bin/pokemon.sh' >> ~/.zshrc
            log_success "pokemon.sh added to .zshrc (runs on terminal start)"
        else
            log_info "pokemon.sh already configured in .zshrc"
        fi

        log_success "Terminal customization completed successfully!"
        ;;
    *)
        log_info "Skipping terminal customization"
        ;;
    esac
}