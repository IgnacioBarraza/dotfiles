#!/bin/bash

# ============================================
# 02. GIT SETUP SCRIPT
# ============================================
#
# This script configures Git with sane defaults and optional user info.
#
# Functions:
#   - configure_git: Main function to set up Git
#   - set_git_user: Set user name and email
#   - set_git_defaults: Set default branch, editor, etc.
#   - generate_ssh_key: Generate SSH Key pair fot Github/Gitlab.
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error)
#   - Colors defined in main script

check_for_git() {
    log_info "Check if Git is installed"

    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install Git first."
        return 1
    fi
}

configure_git() {
    log_info "Starting Git configuration..."

    check_for_git()

    # Check if user already has a global config
    if git config --global --get user.name &> /dev/null; then
        local current_name=$(git config --global --get user.name)
        local current_email=$(git config --global --get user.email)
        log_info "Git user already configured: $current_name <$current_email>"
        
        read -rp "Do you want to update the user info? [y/N]: " update_user
        case "$update_user" in
            [yY][eE][sS] | [yY])
                set_git_user
                ;;
            *)
                log_info "Keeping existing Git user configuration"
                ;;
        esac
    else
        log_info "No Git user configured. Let's set it up."
        set_git_user
    fi
    
    # Set Git defaults
    set_git_defaults
    
    # Show final configuration
    log_info "=== Git Configuration Summary ==="
    git config --global --list | grep -E "user\.(name|email)|core\.(editor|autocrlf)|pull\.rebase|init\.defaultBranch" | tee -a "$LOG"
    
    read -rp "Do you want to generate an SSH key for GitHub/GitLab? [y/N]: " generate_ssh
    case "$generate_ssh" in
        [yY][eE][sS] | [yY])
            generate_ssh_key
            ;;
        *)
            log_info "Skipping SSH key generation."
            ;;
    esac
    
    log_success "Git configuration completed"
}

set_git_user() {
    log_info "Setting Git user information..."
    
    # Get user name
    read -rp "Enter your Git user name (e.g., 'Your Name'): " git_name
    if [ -n "$git_name" ]; then
        git config --global user.name "$git_name"
        log_success "Git user name set: $git_name"
    else
        log_warning "Git user name not set (empty input)"
    fi
    
    # Get user email
    read -rp "Enter your Git email (e.g., 'you@email.com'): " git_email
    if [ -n "$git_email" ]; then
        git config --global user.email "$git_email"
        log_success "Git email set: $git_email"
    else
        log_warning "Git email not set (empty input)"
    fi
}

set_git_defaults() {
    log_info "Setting Git defaults..."
    
    # Default branch name
    git config --global init.defaultBranch main
    log_info "Default branch set to 'main'"
    
    # Core editor (use VS Code if available, fallback to nano)
    if command -v code &> /dev/null; then
        git config --global core.editor "code --wait"
        log_info "Git editor set to: VS Code"
    elif command -v nano &> /dev/null; then
        git config --global core.editor "nano"
        log_info "Git editor set to: nano"
    else
        git config --global core.editor "vim"
        log_info "Git editor set to: vim"
    fi
    
    # Pull behavior: rebase instead of merge
    git config --global pull.rebase false
    log_info "Pull behavior set to: merge (default)"
    
    # Credential helper (cache for 1 hour)
    git config --global credential.helper "cache --timeout=3600"
    log_info "Credential helper set to: cache (1 hour)"
    
    # Color UI
    git config --global color.ui auto
    log_info "Color UI enabled"
    
    # Autocrlf: input (recommended for Linux)
    git config --global core.autocrlf input
    log_info "Core.autocrlf set to: input"
    
    log_success "Git defaults configured"
}

generate_ssh_key() {
    log_info "Checking for existing SSH keys..."
    
    if [ -f ~/.ssh/id_ed25519 ] || [ -f ~/.ssh/id_rsa ]; then
        log_info "SSH key already exists."
        read -rp "Do you want to generate a new SSH key? (This will overwrite existing keys) [y/N]: " generate_new
        case "$generate_new" in
            [yY][eE][sS] | [yY])
                log_info "Generating new SSH key..."
                ;;
            *)
                log_info "Skipping SSH key generation."
                return 0
                ;;
        esac
    fi
    
    local ssh_email=""
    if git config --global --get user.email &> /dev/null; then
        local git_email=$(git config --global --get user.email)
        log_info "Git email detected: $git_email"
        read -rp "Use this email for SSH key? [Y/n]: " use_git_email
        case "$use_git_email" in
            [nN][oO] | [nN])
                read -rp "Enter email for SSH key: " ssh_email
                ;;
            *)
                ssh_email="$git_email"
                ;;
        esac
    else
        read -rp "Enter email for SSH key: " ssh_email
    fi
    
    if [ -z "$ssh_email" ]; then
        log_error "No email provided. Skipping SSH key generation."
        return 1
    fi
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    log_info "Generating SSH key with email: $ssh_email"
    
    if ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519 -N "" 2>&1 | tee -a "$LOG"; then
        log_success "SSH key generated: ~/.ssh/id_ed25519"
        local ssh_key_path="~/.ssh/id_ed25519.pub"
    else
        log_warning "ed25519 failed, falling back to RSA (4096-bit)"
        ssh-keygen -t rsa -b 4096 -C "$ssh_email" -f ~/.ssh/id_rsa -N "" 2>&1 | tee -a "$LOG"
        log_success "SSH key generated: ~/.ssh/id_rsa"
        local ssh_key_path="~/.ssh/id_rsa.pub"
    fi
    
    chmod 600 ~/.ssh/id_* 2>/dev/null
    chmod 644 ~/.ssh/id_*.pub 2>/dev/null
    
    log_info "Your SSH public key is:"
    echo ""
    cat "${ssh_key_path/#\~/$HOME}" 2>/dev/null || cat ~/.ssh/id_*.pub 2>/dev/null
    echo ""
    
    log_info "Add this key to your GitHub/GitLab account:"
    log_info "  - GitHub: https://github.com/settings/ssh/new"
    log_info "  - GitLab: https://gitlab.com/-/profile/keys"
    
    if command -v xclip &> /dev/null; then
        read -rp "Do you want to copy the SSH key to clipboard? [y/N]: " copy_key
        case "$copy_key" in
            [yY][eE][sS] | [yY])
                cat "${ssh_key_path/#\~/$HOME}" | xclip -selection clipboard 2>/dev/null || \
                cat "${ssh_key_path/#\~/$HOME}" | xclip -i 2>/dev/null
                log_success "SSH key copied to clipboard!"
                ;;
            *)
                log_info "You can copy it manually from above."
                ;;
        esac
    else
        log_info "To copy the key, select and copy it from above."
    fi
    
    eval "$(ssh-agent -s)" 2>&1 | tee -a "$LOG"
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null
    
    log_success "SSH key generation completed"
}