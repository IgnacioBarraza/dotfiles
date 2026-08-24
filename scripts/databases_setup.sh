#!/bin/bash

# ============================================
# 07. DATABASE SETUP SCRIPT
# ============================================
#
# This script installs database CLIENTS on the host, and optionally drops the
# example docker compose stack that runs the SERVERS.
#
# Servers are deliberately not installed on the host: three daemons starting on
# every boot and holding ports is rarely what a development machine wants. The
# compose stack in config/docker/ runs them only while you need them.
#
# Functions:
#   - setup_databases: Main function
#   - install_database_clients: Multi-select menu
#   - install_compose_stack: Copy the example compose stack into place
#
# Dependencies:
#   - logging.sh (for log_info, log_success, log_error, log_warning)
#   - utils.sh (for pkg_installed, run_logged, add_apt_repo, backup_file)
#   - Colors defined in main script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# MongoDB keys its repository per major version.
MONGODB_VERSION="8.0"

# Where the compose stack is copied to, so it can be edited and run from a
# predictable place instead of from inside the cloned repository.
STACK_DIR="$HOME/dev-stack"

# display name | how it is installed | installer function
DATABASE_ITEMS=(
    "PostgreSQL client|apt|install_postgres_client"
    "Redis CLI|apt|install_redis_client"
    "SQLite|apt|install_sqlite"
    "MongoDB Shell|apt, MongoDB repo|install_mongosh"
    "Example compose stack|copy to ~/dev-stack|install_compose_stack"
)

setup_databases() {
    log_info "Starting database setup"

    install_database_clients

    log_success "Database setup completed"
}

install_database_clients() {
    log_info "Select the database tooling to install"
    echo ""
    echo "  ${MAGENTA}Clients run on the host, servers run in the compose stack${RESET}"
    echo ""

    local i=1
    local entry name method

    for entry in "${DATABASE_ITEMS[@]}"; do
        IFS='|' read -r name method _ <<< "$entry"
        printf "    %2d) %-24s %s\n" "$i" "$name" "($method)"
        i=$((i + 1))
    done

    echo ""
    echo "  Enter numbers separated by commas or spaces (for example: 1,2,5)"
    echo "  Type 'all' for everything, or leave empty to skip."
    echo ""

    read -rp "Your choice: " selection

    if [ -z "${selection// /}" ]; then
        log_info "Skipping database setup"
        return 0
    fi

    local chosen=()

    if [ "${selection,,}" = "all" ]; then
        local n
        for n in $(seq 1 ${#DATABASE_ITEMS[@]}); do
            chosen+=("$n")
        done
    else
        local raw
        read -ra raw <<< "${selection//,/ }"
        local token
        for token in "${raw[@]}"; do
            if ! [[ "$token" =~ ^[0-9]+$ ]] || [ "$token" -lt 1 ] || [ "$token" -gt ${#DATABASE_ITEMS[@]} ]; then
                log_warning "Ignoring invalid choice: $token"
                continue
            fi
            chosen+=("$token")
        done
    fi

    if [ ${#chosen[@]} -eq 0 ]; then
        log_warning "Nothing valid selected, skipping database setup"
        return 0
    fi

    local installed=0
    local failed=0
    local failed_items=()
    local index installer

    for index in "${chosen[@]}"; do
        IFS='|' read -r name _ installer <<< "${DATABASE_ITEMS[index - 1]}"

        log_info "=== $name ==="

        if "$installer"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
            failed_items+=("$name")
        fi
    done

    log_info "=== Database Installation Summary ==="
    log_info "Selected: ${#chosen[@]}"
    log_info "Installed: $installed"

    if [ "$failed" -gt 0 ]; then
        log_warning "Failed: $failed"
        log_warning "Items that failed: ${failed_items[*]}"
    fi
}

# ---------------------------------------------
# Clients
# ---------------------------------------------

install_postgres_client() {
    if pkg_installed postgresql-client; then
        log_success "postgresql-client is already installed"
        return 0
    fi
    run_logged sudo apt install -y postgresql-client
}

install_redis_client() {
    if pkg_installed redis-tools; then
        log_success "redis-tools is already installed"
        return 0
    fi
    run_logged sudo apt install -y redis-tools
}

install_sqlite() {
    if pkg_installed sqlite3; then
        log_success "sqlite3 is already installed"
        return 0
    fi
    run_logged sudo apt install -y sqlite3
}

# mongosh is the only client here that is not in the Ubuntu archive, so it
# needs MongoDB's own repository. Note the unusual suite: MongoDB nests the
# product and version inside it, as in "resolute/mongodb-org/8.0".
install_mongosh() {
    if pkg_installed mongodb-mongosh; then
        log_success "mongosh is already installed"
        return 0
    fi

    local codename
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"

    if [ -z "$codename" ]; then
        log_error "Could not determine the Ubuntu codename from /etc/os-release"
        return 1
    fi

    add_apt_repo "mongodb-org-${MONGODB_VERSION}" \
        "https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc" \
        "https://repo.mongodb.org/apt/ubuntu" \
        "${codename}/mongodb-org/${MONGODB_VERSION}" \
        "multiverse" || return 1

    run_logged sudo apt install -y mongodb-mongosh
}

# ---------------------------------------------
# Compose stack
# ---------------------------------------------

install_compose_stack() {
    local src="$SCRIPT_DIR/../config/docker/docker-compose.yml"

    if [ ! -f "$src" ]; then
        log_warning "Compose stack not found at config/docker/docker-compose.yml"
        return 0
    fi

    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not installed, so the stack cannot be started yet"
        log_info "The file is still copied; install Docker and it will work"
    fi

    mkdir -p "$STACK_DIR"

    if [ -f "$STACK_DIR/docker-compose.yml" ]; then
        backup_file "$STACK_DIR/docker-compose.yml"
    fi

    if ! cp "$src" "$STACK_DIR/docker-compose.yml"; then
        log_error "Could not copy the compose stack to $STACK_DIR"
        return 1
    fi

    log_success "Compose stack copied to $STACK_DIR/docker-compose.yml"
    log_info "Start it with:  cd $STACK_DIR && docker compose up -d"
    log_info "Ports are bound to 127.0.0.1 only: 5432 postgres, 6379 redis, 27017 mongo"
    log_info "Credentials are dev/dev, meant for local development only"
}
