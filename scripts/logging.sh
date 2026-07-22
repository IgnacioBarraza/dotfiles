#!/bin/bash

# ============================================
# LOGGING SYSTEM
# ============================================

# This file provides logging functions for the installation scripts.
# It writes timestamps and log levels to a log file while also displaying
# colored output to the terminal.

# Variables:
#   LOG      - Path to the current log file
#   LOG_DIR  - Directory where log files are stored

log_write() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG"
}

log_info() {
    local message="$1"
    print_color $INFO "$message"
    log_write "INFO" "$message"
}

log_success() {
    local message="$1"
    print_color $OK "$message"
    log_write "SUCCESS" "$message"
}

log_error() {
    local message="$1"
    print_color $ERROR "$message"
    log_write "ERROR" "$message"
}

log_warning() {
    local message="$1"
    print_color $WARN "$message"
    log_write "WARNING" "$message"
}

# Initialize the logging system
# Creates the log directory and a new log file with a timestamp
init_logging() {
    # Create log directory if it doesn't exist and give permissions
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi
    
    # Generate log filename with current date and time
    LOG="$LOG_DIR/Nach0_0-Install-Scripts-$(date +%d-%H%M%S).log"
    
    # Write header to log file
    echo "========================================" >> "$LOG"
    echo "Nach0_0 Ubuntu 26.04 Setup Script" >> "$LOG"
    echo "Started at: $(date)" >> "$LOG"
    echo "User: $USER" >> "$LOG"
    echo "Host: $(hostname)" >> "$LOG"
    echo "========================================" >> "$LOG"
    
    log_info "Logging initialized."
    log_info "Log file: $LOG"
}