#!/usr/bin/env bash

# Common utilities for dotfiles installation scripts
# Source this file in other scripts: source "$(dirname "$0")/lib/common.sh"

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

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
        cp "$file" "$backup_file"
        info "Backed up $file to $backup_file"
    fi
}

safe_symlink() {
    local source="$1"
    local target="$2"
    local backup="${3:-true}"
    
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
        case "${response,,}" in
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

# Trap cleanup on script exit
trap 'cleanup_and_exit $?' EXIT