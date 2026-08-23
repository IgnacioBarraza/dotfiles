#!/bin/bash

# ============================================
# 03. TERMINAL SETUP SCRIPT
# ============================================
#
# This script installs and configures the terminal emulator, fonts,
# ZSH with Oh My Zsh, Starship and Pokémon ASCII art.
#
# Functions:
#   - setup_terminal: Main function
#   - install_terminal: Prompt for and install a terminal emulator
#   - install_selected_terminal: Install the chosen emulator
#   - install_fonts: Install FiraCode Nerd Font and Noto Sans CJK
#   - configure_kitty: Install the kitty config from config/kitty/
#   - install_zsh: Install ZSH and Oh My Zsh
#   - configure_shell: Install Starship and ZSH plugins
#   - install_cli_tools: Install additional CLI utilities
#   - install_pokemon_art: Install Pokémon ASCII art
#   - configure_fastfetch: Install the fastfetch config from config/fastfetch/
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error)
#   - Colors defined in main script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup_terminal() {
    log_info "Starting terminal environment setup"

    install_terminal

    install_fonts

    configure_kitty

    install_zsh

    configure_shell

    install_pokemon_art

    log_success "Terminal environment setup completed"
}

install_zsh() {
    log_info "Starting ZSH setup and installation"

    read -rp "Do you want to install ZSH? [y/N]: " confirm

    case "$confirm" in
    [yY][eE][sS] | [yY])
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
        ;;
    *)
        log_info "Skipping Zsh installation"
        ;;
    esac
}

configure_shell() {
    log_info "Starting shell configuration..."

    read -rp "Do you want to configure the default shell with starship and other plugins? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY])
        install_cli_tools

        if ! command -v starship &> /dev/null; then
            log_info "Installing Starship and preset"
            curl -sS https://starship.rs/install.sh | sh -s -- -y 2>&1 | tee -a "$LOG"

            if ! grep -q "starship init zsh" ~/.zshrc; then
                echo "" >> ~/.zshrc
                echo "# Initialize Starship prompt" >> ~/.zshrc
                echo 'eval "$(starship init zsh)"' >> ~/.zshrc
                log_info "Starship init added to .zshrc"
            fi

            if [ $? -eq 0 ]; then
                log_success "Starship installed successfully"
            else
                log_error "Failed to install starship"
                return 1
            fi
        else
            log_success "Starship already installed"
        fi

        mkdir -p ~/.config

        if [ -f "$SCRIPT_DIR/../config/starship/starship.toml" ]; then
            cp "$SCRIPT_DIR/../config/starship/starship.toml" ~/.config/starship.toml
            log_success "starship.toml copied from config/starship/ to ~/.config/"
        else
            log_warning "starship.toml not found at /config/starship/ using default config"
        fi

        log_info "Installing essential ZSH plugins..."
        local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
        mkdir -p "$plugins_dir"

        if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions" 2>&1 | tee -a "$LOG"
        log_success "zsh-autosuggestions installed"
        fi

        if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting" 2>&1 | tee -a "$LOG"
            log_success "zsh-syntax-highlighting installed"
        fi

        if [ ! -d "$plugins_dir/zsh-history-enquirer" ]; then
            git clone --depth=1 https://github.com/zthxxx/zsh-history-enquirer.git "$plugins_dir/zsh-history-enquirer" 2>&1 | tee -a "$LOG"
            log_success "zsh-history-enquirer installed"
        fi

        # Remove old Jovial theme line if it exists
        if grep -q "ZSH_THEME=\"jovial\"" ~/.zshrc; then
            sed -i 's/ZSH_THEME=".*"/ZSH_THEME="robbyrussell"/' ~/.zshrc
            log_info "Reverted ZSH_THEME to robbyrussell (to be overridden by Starship)"
        fi

        if grep -q "^plugins=" ~/.zshrc; then
            if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
                sed -i 's/plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-enquirer)/' ~/.zshrc
                log_info "Plugins updated in .zshrc"
            fi
        else
            echo 'plugins=(git zoxide urltools bgnotify zsh-autosuggestions zsh-syntax-highlighting zsh-history-enquirer)' >> ~/.zshrc
            log_info "Plugins added to .zshrc"
        fi

        log_success "Shell configuration with Starship and plugins completed"
        ;;
    *)
        log_info "Skipping shell configuration"
        ;;
    esac
}

install_cli_tools() {
    log_info "Installing additional CLI tools..."

    local tools=(
        zoxide
        eza
        bat
        ripgrep
        fd-find
        jq
        fzf
        htop
        btop
        tree
    )

    log_info "Tools to install:: ${tools[*]}"

    local total_tools=${#tools[@]}
    local installed_count=0
    local failed_count=0
    local failed_tools=()

    for tool in "${tools[@]}"; do
        if ! dpkg -l | grep -q "^ii $tool"; then
            log_info "Installing $tool..."
            sudo apt install -y "$tool" 2>&1 | tee -a "$LOG"

            local exit_code=${PIPESTATUS[0]}  # Captura el código de salida de apt, no de tee

            if [ $exit_code -eq 0 ]; then
                log_success "$tool installed successfully"
                ((installed_count++))
            else
                log_error "Failed to install $tool"
                ((failed_count++))
                failed_tools+=("$tool")
            fi
        else
            log_success "$tool already installed"
            ((installed_count++))
        fi
    done

    log_info "=== Base Installation Summary ==="
    log_info "Total packages: $total_tools"
    log_info "Installed: $installed_count"
    if [ $failed_count -gt 0 ]; then
        log_warning "Failed: $failed_count"
        log_warning "Packages failed to install: ${failed_tools[*]}"
        log_warning "Some packages may need manual installation"
    fi
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
            if [ "${PIPESTATUS[0]}" -eq 0 ]; then
                log_success "Fastfetch installed successfully"
            else
                log_error "Failed to install fastfetch"
            fi
        fi

        configure_fastfetch

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

configure_kitty() {
    log_info "Configuring kitty terminal..."

    if ! command -v kitty &> /dev/null; then
        log_warning "Kitty is not installed, skipping kitty configuration"
        return 0
    fi

    local src="$SCRIPT_DIR/../config/kitty"
    local dest="$HOME/.config/kitty"

    if [ ! -d "$src" ]; then
        log_warning "Kitty config not found at config/kitty/. Using default."
        return 0
    fi

    # The config is modular: a partial copy leaves broken includes.
    if [ -d "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
        local backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
        if cp -r "$dest" "$backup"; then
            log_info "Existing kitty config backed up to $backup"
        else
            log_error "Could not back up existing kitty config. Aborting to avoid data loss."
            return 1
        fi
    fi

    mkdir -p "$dest"

    # cp -r (not cp -L) keeps theme.conf as a symlink, so themes stay switchable.
    if cp -r "$src/." "$dest/"; then
        log_success "Kitty configuration installed to $dest"
    else
        log_error "Failed to copy kitty configuration"
        return 1
    fi

    local active
    active="$(basename "$(readlink "$dest/theme.conf" 2>/dev/null || echo "theme.conf")" .conf)"
    log_info "Active kitty theme: $active"
    log_info "Available themes: $(cd "$src/themes" && ls -1 *.conf 2>/dev/null | sed 's/\.conf$//' | tr '\n' ' ')"
    log_info "Switch with: ln -sfn themes/<name>.conf $dest/theme.conf  (then ctrl+shift+f5)"

    log_success "Kitty configuration completed"
}

install_fonts() {
    log_info "Starting font installation..."

    read -rp "Do you want to install the required fonts (FiraCode Nerd Font + Noto CJK)? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY]) ;;
    *)
        log_info "Skipping font installation"
        return 0
        ;;
    esac

    # No Nerd Font ships kanji or kana, so Noto CJK is required, not optional.
    if fc-list :lang=ja 2>/dev/null | grep -qi "noto sans cjk"; then
        log_success "Noto Sans CJK already installed"
    else
        log_info "Installing fonts-noto-cjk..."
        sudo apt install -y fonts-noto-cjk 2>&1 | tee -a "$LOG"
        if [ "${PIPESTATUS[0]}" -eq 0 ]; then
            log_success "fonts-noto-cjk installed"
        else
            log_error "Failed to install fonts-noto-cjk (Japanese glyphs will render as tofu)"
        fi
    fi

    # fonts-firacode from apt has no Nerd glyphs: the patched build is required.
    if fc-list -f '%{family[0]}\n' 2>/dev/null | grep -qx "FiraCode Nerd Font Mono"; then
        log_success "FiraCode Nerd Font already installed"
        return 0
    fi

    local font_dir="$HOME/.local/share/fonts"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    local tmp
    tmp="$(mktemp -d)"

    mkdir -p "$font_dir"
    log_info "Downloading FiraCode Nerd Font..."

    if curl -fL --retry 3 -o "$tmp/FiraCode.zip" "$url" >> "$LOG" 2>&1; then
        if unzip -o -q "$tmp/FiraCode.zip" -x "*.md" "LICENSE*" -d "$font_dir" >> "$LOG" 2>&1; then
            fc-cache -f "$font_dir" >> "$LOG" 2>&1
            log_success "FiraCode Nerd Font installed to $font_dir"
        else
            log_error "Failed to extract FiraCode Nerd Font (is unzip installed?)"
            rm -rf "$tmp"
            return 1
        fi
    else
        log_error "Failed to download FiraCode Nerd Font from $url"
        log_warning "Icons in starship and fastfetch will render as boxes until a Nerd Font is installed"
        rm -rf "$tmp"
        return 1
    fi

    rm -rf "$tmp"
    log_success "Font installation completed"
}

configure_fastfetch() {
    log_info "Configuring fastfetch..."

    local src="$SCRIPT_DIR/../config/fastfetch/config.jsonc"
    local dest="$HOME/.config/fastfetch"

    if [ ! -f "$src" ]; then
        log_warning "Fastfetch config not found at config/fastfetch/config.jsonc. Using default."
        return 0
    fi

    mkdir -p "$dest"

    if [ -f "$dest/config.jsonc" ]; then
        local backup="$dest/config.jsonc.bak.$(date +%Y%m%d-%H%M%S)"
        if cp "$dest/config.jsonc" "$backup"; then
            log_info "Existing fastfetch config backed up to $backup"
        else
            log_error "Could not back up existing fastfetch config. Aborting to avoid data loss."
            return 1
        fi
    fi

    if cp "$src" "$dest/config.jsonc"; then
        log_success "Fastfetch configuration installed to $dest/config.jsonc"
    else
        log_error "Failed to copy fastfetch configuration"
        return 1
    fi
}
