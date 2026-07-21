#!/bin/bash

# ============================================
# 01. BASE PACKAGE INSTALLATION SCRIPT
# ============================================

# This script installs essential system packages required for
# the rest of the setup process.

# Functions:
#   - update_system: Updates system package lists
#   - check_base_dependencies: Checks critical dependencies
#   - install_base_packages: Main installation function
#   - cleanup_after_base_install: Cleanup after installation

# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - Colors defined in main script

update_system() {
    log_info "Updating system packages..."

    sudo apt update 2>&1 | tee -a "$LOG"

    if [ $? -eq 0 ]; then
        log_success "System packages updated"
    else
        log_error "Failed to update system packages"
        return 1
    fi

    log_info "Upgrading system packages..."

    sudo apt upgrade -y 2>&1 | tee -a "$LOG"

    if [ $? -eq 0 ]; then
        log_success "System packages updated"
    else
        log_error "Failed to update system packages"
        return 1
    fi
}

check_base_dependencies() {
    log_info "Checking base dependencies..."

    local missing=()
    local base_dependencies=(
        apt
        dpkg
        sudo
    )

    for cmd in "${base_dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Base dependencies missing: ${missing[*]}"
        log_error "Please ensure your system is properly configured"
        return 1
    else
        log_success "All base dependencies present and ready to go"
        return 0
    fi
}

install_base_packages() {
    log_info "Starting base packages installation..."

    check_base_dependencies || {
        log_error "Dependency check failed. Exiting..."
        return 1
    }

    update_system || {
        log_error "System update failed. Continuing anyway..."
    }

    local base_packages=(
        curl
        wget
        git
        build-essential
        unzip
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release
        python3
        python3-pip
        cargo
    )

    log_info "Packages to install: ${base_packages[*]}"

    local total_packages=${#base_packages[@]}
    local installed_count=0
    local failed_count=0
    local failed_packages=()

    for pkg in "${base_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            log_info "$pkg already installed"
            ((installed_count++))
            continue
        fi
        
        log_info "Installing $pkg..."
        sudo apt install -y "$pkg" 2>&1 | tee -a "$LOG"
        
        if [ $? -eq 0 ]; then
            log_success "$pkg installed successfully"
            ((installed_count++))
        else
            log_error "Failed to install $pkg"
            ((failed_count++))
            failed_packages+=("$pkg")
        fi
    done

    log_info "=== Base Installation Summary ==="
    log_info "Total packages: $total_packages"
    log_info "Installed: $installed_count"
    if [ $failed_count -gt 0 ]; then
        log_warning "Failed: $failed_count"
        log_warning "Packages failed to install: ${failed_packages[*]}"
        log_warning "Some packages may need manual installation"
    fi
    
    # Cleanup
    cleanup_after_base_install
    
    if [ $failed_count -eq 0 ]; then
        log_success "All base packages installed successfully"
        return 0
    else
        log_warning "Installation completed with errors"
        return 1
    fi
}

cleanup_after_base_install() {
    log_info "Cleaning up package cache..."
    sudo apt clean 2>&1 | tee -a "$LOG"
    
    log_info "Removing unnecessary packages..."
    sudo apt autoremove -y 2>&1 | tee -a "$LOG"
    
    log_success "Cleanup completed"
}