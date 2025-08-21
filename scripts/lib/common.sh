#!/usr/bin/env bash

# Common utilities for dotfiles installation scripts
# Source this file in other scripts: source "$(dirname "$0")/lib/common.sh"

set -euo pipefail

# Prevent multiple sourcing
export DOTFILES_COMMON_LOADED=1

# Colors for output (only define if not already defined)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly NC='\033[0m' # No Color
fi

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
LOG_FILE="${LOG_FILE:-/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S).log}"

# Logging functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $1${NC}" >&2
    exit 1
}

warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

info() {
    log "${CYAN}→ $1${NC}"
}

debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        log "${PURPLE}DEBUG: $1${NC}"
    fi
}

print_header() {
    log "${WHITE}${1}${NC}"
    log "${WHITE}$(printf '%.0s=' {1..${#1}})${NC}"
}

# OS Detection
detect_os() {
    local os=""
    case "$OSTYPE" in
        linux-gnu*) os="linux" ;;
        darwin*)    os="macos" ;;
        msys*)      os="windows" ;;
        cygwin*)    os="windows" ;;
        *)          os="unknown" ;;
    esac
    echo "$os"
}

detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi
    
    local distro_id
    distro_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo "${distro_id,,}"  # lowercase
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

# Display server detection (Linux only)
detect_display_server() {
    if [[ "$(detect_os)" != "linux" ]]; then
        echo "none"
        return
    fi
    
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        echo "wayland"
    elif [[ -n "${DISPLAY:-}" ]]; then
        echo "x11"
    else
        echo "console"
    fi
}

# Environment detection
is_desktop_environment() {
    local os
    os=$(detect_os)
    
    case "$os" in
        macos)
            return 0  # macOS is always desktop
            ;;
        linux)
            # Check for desktop environment
            if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || \
               [[ -n "${DESKTOP_SESSION:-}" ]] || \
               [[ -n "${DISPLAY:-}" ]] || \
               [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || \
    [[ "$(uname -r)" == *microsoft* ]] || \
    [[ "$(uname -r)" == *WSL* ]]
}

is_ssh_session() {
    [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_TTY:-}" ]]
}

# File operations
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d-%H%M%S)}"
    
    if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
        local backup_file="${file}${backup_suffix}"
        # Only backup if backup doesn't already exist
        if [[ ! -e "$backup_file" ]]; then
            cp "$file" "$backup_file"
            info "Backed up $file to $backup_file"
        else
            debug "Backup already exists: $backup_file"
        fi
    fi
}

safe_symlink() {
    local source="$1"
    local target="$2"
    local backup="${3:-true}"
    
    # Check if symlink already exists and points to correct target
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        debug "Symlink already exists and is correct: $target -> $source"
        return 0
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    # Backup existing file if not a symlink
    if [[ "$backup" == "true" ]]; then
        backup_file "$target"
    fi
    
    # Remove existing file/symlink
    [[ -e "$target" ]] && rm -f "$target"
    
    # Create symlink
    ln -sf "$source" "$target"
    debug "Created symlink: $target -> $source"
}

# Network utilities
check_internet() {
    if command -v curl >/dev/null 2>&1; then
        curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=5 --tries=1 --spider https://www.google.com >/dev/null 2>&1
    else
        return 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget is available"
    fi
}

# Command utilities
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        error "Required command '$1' not found"
    fi
}

# User interaction
ask_yes_no() {
    local question="$1"
    local default="${2:-no}"
    local response
    
    if [[ "$default" == "yes" ]]; then
        question="${question} [Y/n]: "
    else
        question="${question} [y/N]: "
    fi
    
    while true; do
        read -r -p "$question" response
        # Convert to lowercase - compatible with older bash
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        case "$response" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            "") 
                if [[ "$default" == "yes" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Process management
is_process_running() {
    local process_name="$1"
    pgrep -x "$process_name" >/dev/null 2>&1
}

wait_for_process() {
    local process_name="$1"
    local timeout="${2:-30}"
    local count=0
    
    while is_process_running "$process_name" && [[ $count -lt $timeout ]]; do
        sleep 1
        ((count++))
    done
    
    if [[ $count -ge $timeout ]]; then
        warning "Timeout waiting for process '$process_name' to finish"
        return 1
    fi
}

# Validation functions
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_url() {
    local url="$1"
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}.*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Environment setup
setup_environment() {
    export DOTFILES_OS="$(detect_os)"
    export DOTFILES_DISTRO="$(detect_distro)"
    export DOTFILES_ARCH="$(detect_arch)"
    export DOTFILES_DISPLAY="$(detect_display_server)"
    
    if is_desktop_environment; then
        export DOTFILES_ENV="desktop"
    elif is_wsl; then
        export DOTFILES_ENV="wsl"
    else
        export DOTFILES_ENV="server"
    fi
    
    debug "Environment: OS=$DOTFILES_OS, DISTRO=$DOTFILES_DISTRO, ARCH=$DOTFILES_ARCH, ENV=$DOTFILES_ENV"
}

# Script initialization
init_script() {
    local script_name="$1"
    
    print_header "$script_name"
    info "Starting at $(date)"
    info "Log file: $LOG_FILE"
    
    setup_environment
    
    # Ensure internet connectivity
    if ! check_internet; then
        warning "No internet connection detected. Some features may not work."
    fi
}

cleanup_and_exit() {
    local exit_code="${1:-0}"
    info "Script finished at $(date)"
    exit "$exit_code"
}

# Idempotent utilities
is_already_installed() {
    local check_type="$1"
    local identifier="$2"
    
    case "$check_type" in
        command)
            command_exists "$identifier"
            ;;
        directory)
            [[ -d "$identifier" ]]
            ;;
        file)
            [[ -f "$identifier" ]]
            ;;
        symlink)
            [[ -L "$identifier" ]]
            ;;
        git_repo)
            [[ -d "$identifier/.git" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if configuration is already applied
is_config_applied() {
    local config_file="$1"
    local pattern="$2"
    
    [[ -f "$config_file" ]] && grep -q "$pattern" "$config_file"
}

# Install or update git repository
install_or_update_git_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-master}"
    
    if [[ -d "$target_dir/.git" ]]; then
        info "Updating existing repository: $target_dir"
        cd "$target_dir" && git pull origin "$branch"
    else
        info "Cloning repository: $repo_url"
        git clone --depth=1 -b "$branch" "$repo_url" "$target_dir"
    fi
}

# Add line to file if not present
add_line_to_file() {
    local file="$1"
    local line="$2"
    local create_if_missing="${3:-true}"
    
    if [[ ! -f "$file" ]]; then
        if [[ "$create_if_missing" == "true" ]]; then
            mkdir -p "$(dirname "$file")"
            touch "$file"
        else
            return 1
        fi
    fi
    
    if ! grep -Fxq "$line" "$file"; then
        echo "$line" >> "$file"
        debug "Added line to $file: $line"
        return 0
    else
        debug "Line already exists in $file: $line"
        return 1
    fi
}

# Remove line from file if present
remove_line_from_file() {
    local file="$1"
    local line="$2"
    
    if [[ -f "$file" ]] && grep -Fxq "$line" "$file"; then
        # Use sed to remove the exact line
        sed -i.bak "/^$(printf '%s\n' "$line" | sed 's/[[]]/\\&/g')$/d" "$file"
        rm -f "$file.bak"
        debug "Removed line from $file: $line"
        return 0
    else
        debug "Line not found in $file: $line"
        return 1
    fi
}

# Ensure directory exists with proper permissions
ensure_directory() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chmod "$mode" "$dir"
        debug "Created directory: $dir (mode: $mode)"
    else
        debug "Directory already exists: $dir"
    fi
}

# Check if service is running
is_service_running() {
    local service="$1"
    
    if command_exists systemctl; then
        systemctl is-active --quiet "$service"
    elif command_exists service; then
        service "$service" status >/dev/null 2>&1
    else
        pgrep -x "$service" >/dev/null 2>&1
    fi
}

# Start service if not running
ensure_service_running() {
    local service="$1"
    
    if is_service_running "$service"; then
        debug "Service already running: $service"
        return 0
    fi
    
    info "Starting service: $service"
    if command_exists systemctl; then
        sudo systemctl start "$service"
    elif command_exists service; then
        sudo service "$service" start
    else
        warning "Cannot start service $service - no service manager found"
        return 1
    fi
}

# Enable service for auto-start
ensure_service_enabled() {
    local service="$1"
    
    if command_exists systemctl; then
        if systemctl is-enabled --quiet "$service"; then
            debug "Service already enabled: $service"
            return 0
        fi
        
        info "Enabling service: $service"
        sudo systemctl enable "$service"
    else
        warning "Cannot enable service $service - systemctl not found"
        return 1
    fi
}

# Skip if already completed (using marker files)
mark_completed() {
    local marker_name="$1"
    local marker_dir="${HOME}/.dotfiles-markers"
    local marker_file="${marker_dir}/${marker_name}"
    
    ensure_directory "$marker_dir"
    touch "$marker_file"
    debug "Marked as completed: $marker_name"
}

is_completed() {
    local marker_name="$1"
    local marker_dir="${HOME}/.dotfiles-markers"
    local marker_file="${marker_dir}/${marker_name}"
    
    [[ -f "$marker_file" ]]
}

clear_marker() {
    local marker_name="$1"
    local marker_dir="${HOME}/.dotfiles-markers"
    local marker_file="${marker_dir}/${marker_name}"
    
    [[ -f "$marker_file" ]] && rm -f "$marker_file"
    debug "Cleared marker: $marker_name"
}

# Enhanced Installation Planning and Execution Tracking
declare -a INSTALLATION_PLAN=()
declare -a INSTALLATION_SUMMARY=()
declare -a EXECUTION_LOG=()

# Progress tracking
CURRENT_STEP=0
TOTAL_STEPS=0

# Enhanced logging with execution details
log_execution() {
    local step="$1"
    local details="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    EXECUTION_LOG+=("[$timestamp] $step: $details")
    debug "EXEC: $step - $details"
}

# Planning functions
show_installation_plan() {
    local title="$1"
    
    if [[ ${#INSTALLATION_PLAN[@]} -eq 0 ]]; then
        return
    fi
    
    print_header "INSTALLATION PLAN: $title"
    info "The following changes will be made:"
    echo
    
    local step_num=1
    for item in "${INSTALLATION_PLAN[@]}"; do
        printf "  %2d. %s\n" "$step_num" "$item"
        ((step_num++))
    done
    
    TOTAL_STEPS=${#INSTALLATION_PLAN[@]}
    echo
    info "Total steps: $TOTAL_STEPS"
    echo
    
    if ! ask_yes_no "Proceed with installation?" "yes"; then
        info "Installation cancelled by user"
        exit 0
    fi
    echo
}

add_to_plan() {
    local description="$1"
    INSTALLATION_PLAN+=("$description")
}

add_to_summary() {
    local description="$1"
    INSTALLATION_SUMMARY+=("$description")
}

# Enhanced step execution with progress
execute_step() {
    local step_description="$1"
    local command="$2"
    
    ((CURRENT_STEP++))
    
    info "Step $CURRENT_STEP/$TOTAL_STEPS: $step_description"
    
    local start_time=$(date +%s)
    local result=0
    
    if [[ -n "$command" ]]; then
        log_execution "$step_description" "Started"
        if eval "$command"; then
            log_execution "$step_description" "Completed successfully"
            add_to_summary "$step_description"
        else
            result=$?
            log_execution "$step_description" "Failed with exit code $result"
            error "Step failed: $step_description"
        fi
    else
        log_execution "$step_description" "Manual step completed"
        add_to_summary "$step_description"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    debug "Step duration: ${duration}s"
    
    return $result
}

show_installation_summary() {
    local title="$1"
    
    print_header "INSTALLATION SUMMARY: $title"
    
    if [[ ${#INSTALLATION_SUMMARY[@]} -gt 0 ]]; then
        success "Successfully completed $CURRENT_STEP/$TOTAL_STEPS steps:"
        echo
        
        local step_num=1
        for item in "${INSTALLATION_SUMMARY[@]}"; do
            printf "  %s %2d. %s\n" "✓" "$step_num" "$item"
            ((step_num++))
        done
        echo
    fi
    
    if [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; then
        warning "Some steps were not completed ($((TOTAL_STEPS - CURRENT_STEP)) remaining)"
    fi
    
    info "Installation log: $LOG_FILE"
    
    if [[ "${DEBUG:-}" == "1" ]] && [[ ${#EXECUTION_LOG[@]} -gt 0 ]]; then
        echo
        info "Execution timeline:"
        for entry in "${EXECUTION_LOG[@]}"; do
            echo "    $entry"
        done
    fi
    
    echo
}

# Reset planning state for new installation
reset_installation_state() {
    INSTALLATION_PLAN=()
    INSTALLATION_SUMMARY=()
    EXECUTION_LOG=()
    CURRENT_STEP=0
    TOTAL_STEPS=0
}

# Trap cleanup on script exit
trap 'cleanup_and_exit $?' EXIT