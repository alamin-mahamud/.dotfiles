#!/usr/bin/env bash
# OS detection and platform-specific utilities
# Following Python's Zen: "There should be one-- and preferably only one --obvious way to do it"

# Source core library
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# OS detection
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}

# Linux distribution detection
detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi
    
    # Source os-release for distribution info
    source /etc/os-release
    
    case "${ID,,}" in
        ubuntu|debian) echo "debian" ;;
        fedora|rhel|centos|rocky|almalinux) echo "redhat" ;;
        arch|manjaro) echo "arch" ;;
        opensuse*) echo "suse" ;;
        alpine) echo "alpine" ;;
        *) echo "${ID,,}" ;;
    esac
}

# Architecture detection
detect_arch() {
    local arch
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7*) echo "armv7" ;;
        i386|i686) echo "x86" ;;
        *) echo "$arch" ;;
    esac
}

# Check if running in WSL
is_wsl() {
    [[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

# Check if running in container
is_container() {
    [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]
}

# Check if running over SSH
is_ssh() {
    [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_TTY:-}" ]]
}

# Check if desktop environment is available
has_desktop() {
    [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ "$(detect_os)" == "macos" ]]
}

# Get display server type
get_display_server() {
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        echo "wayland"
    elif [[ -n "${DISPLAY:-}" ]]; then
        echo "x11"
    elif [[ "$(detect_os)" == "macos" ]]; then
        echo "quartz"
    else
        echo "none"
    fi
}

# Check if running with sudo/root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Require root/sudo
require_root() {
    if ! is_root; then
        die "This script must be run with sudo/root privileges"
    fi
}

# Require non-root
require_non_root() {
    if is_root; then
        die "This script must not be run as root"
    fi
}

# Get current user (even when running with sudo)
get_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

# Get real home directory (even when running with sudo)
get_real_home() {
    local real_user
    real_user=$(get_real_user)
    eval echo "~$real_user"
}

# Platform-specific command wrapper
platform_command() {
    local os
    os=$(detect_os)
    
    case "$os" in
        linux)
            "${@}_linux" 2>/dev/null || "$@"
            ;;
        macos)
            "${@}_macos" 2>/dev/null || "$@"
            ;;
        *)
            "$@"
            ;;
    esac
}

# Export all functions
export -f detect_os detect_distro detect_arch
export -f is_wsl is_container is_ssh has_desktop
export -f get_display_server
export -f is_root require_root require_non_root
export -f get_real_user get_real_home
export -f platform_command