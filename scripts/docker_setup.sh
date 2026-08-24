#!/bin/bash

# ============================================
# 06. DOCKER SETUP SCRIPT
# ============================================
#
# This script installs Docker CE from Docker's own repository, adds the user to
# the docker group, and optionally installs lazydocker.
#
# Docker's repository is keyed by Ubuntu codename, so the suite is read from
# /etc/os-release rather than hardcoded.
#
# Functions:
#   - setup_docker: Main function
#   - install_docker: Docker CE, CLI, containerd, buildx and compose
#   - configure_docker_group: Add the user to the docker group
#   - install_lazydocker: Terminal UI for containers, from its GitHub release
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, add_apt_repo)
#   - Colors defined in main script

LAZYDOCKER_VERSION="0.25.2"

setup_docker() {
    log_info "Starting Docker setup"

    read -rp "Do you want to install Docker? [y/N]: " choice

    case "$choice" in
    [yY][eE][sS] | [yY]) ;;
    *)
        log_info "Skipping Docker installation"
        return 0
        ;;
    esac

    install_docker || return 1

    configure_docker_group

    read -rp "Do you want to install lazydocker (terminal UI for containers)? [y/N]: " lazy

    case "$lazy" in
    [yY][eE][sS] | [yY])
        install_lazydocker
        ;;
    *)
        log_info "Skipping lazydocker"
        ;;
    esac

    log_success "Docker setup completed"
}

install_docker() {
    if pkg_installed docker-ce; then
        log_success "Docker CE is already installed"
    else
        # Docker publishes per Ubuntu release, so the suite is the codename.
        local codename
        codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"

        if [ -z "$codename" ]; then
            log_error "Could not determine the Ubuntu codename from /etc/os-release"
            return 1
        fi

        add_apt_repo "docker" \
            "https://download.docker.com/linux/ubuntu/gpg" \
            "https://download.docker.com/linux/ubuntu" \
            "$codename" || return 1

        local packages=(
            docker-ce
            docker-ce-cli
            containerd.io
            docker-buildx-plugin
            docker-compose-plugin
        )

        log_info "Installing: ${packages[*]}"

        if ! run_logged sudo apt install -y "${packages[@]}"; then
            log_error "Failed to install Docker"
            return 1
        fi

        log_success "Docker installed: $(docker --version 2>/dev/null)"
    fi

    if ! systemctl is-enabled docker &> /dev/null; then
        run_logged sudo systemctl enable --now docker
    fi

    if systemctl is-active docker &> /dev/null; then
        log_success "Docker service is running"
    else
        log_warning "Docker is installed but its service is not running"
    fi
}

# Without this, every docker command needs sudo. The group only takes effect on
# a fresh login, which is the single most common "docker: permission denied"
# after a first install, so it is called out loudly rather than logged quietly.
configure_docker_group() {
    if getent group docker > /dev/null 2>&1; then
        log_success "The docker group exists"
    else
        run_logged sudo groupadd docker
    fi

    if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        log_success "$USER is already in the docker group"
        return 0
    fi

    if ! run_logged sudo usermod -aG docker "$USER"; then
        log_error "Could not add $USER to the docker group"
        return 1
    fi

    log_warning "=============================================================="
    log_warning "$USER was added to the docker group."
    log_warning "You must LOG OUT and LOG BACK IN before docker works without sudo."
    log_warning "Until then, 'docker ps' will fail with permission denied."
    log_warning "To test without logging out, run: newgrp docker"
    log_warning "=============================================================="
}

# lazydocker ships neither an apt package nor a snap, so it comes from the
# release tarball. The version is pinned so a run is reproducible.
install_lazydocker() {
    if command -v lazydocker &> /dev/null; then
        log_success "lazydocker is already installed: $(lazydocker --version 2>/dev/null | head -1)"
        return 0
    fi

    local arch
    case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64) arch="arm64" ;;
    *)
        log_error "No lazydocker build for $(uname -m)"
        return 1
        ;;
    esac

    local url="https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_${arch}.tar.gz"
    local tmp
    tmp="$(mktemp -d)"

    log_info "Downloading lazydocker ${LAZYDOCKER_VERSION}..."

    if ! curl -fL --retry 3 -o "$tmp/lazydocker.tar.gz" "$url" >> "$LOG" 2>&1; then
        log_error "Could not download lazydocker from $url"
        rm -rf "$tmp"
        return 1
    fi

    if ! tar -xzf "$tmp/lazydocker.tar.gz" -C "$tmp" lazydocker >> "$LOG" 2>&1; then
        log_error "Could not extract lazydocker"
        rm -rf "$tmp"
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/lazydocker" "$HOME/.local/bin/lazydocker"
    rm -rf "$tmp"

    log_success "lazydocker installed to ~/.local/bin"
}
