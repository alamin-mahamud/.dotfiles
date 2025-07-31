#!/bin/bash
# core/utils/platform.sh - Platform detection and abstraction

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Platform detection
detect_platform() {
    local os_type=""
    local env_type=""
    local distro=""
    local version=""
    local arch=""
    
    # Detect architecture
    arch=$(uname -m)
    
    # Detect OS
    case "$OSTYPE" in
        linux-gnu*)
            os_type="linux"
            detect_linux_environment
            ;;
        darwin*)
            os_type="macos"
            env_type="desktop"
            version="$(sw_vers -productVersion)"
            ;;
        msys*|cygwin*)
            os_type="windows"
            env_type="wsl"
            ;;
        *)
            log_fatal "Unsupported OS: $OSTYPE"
            ;;
    esac
    
    # Export platform variables
    export DOTFILES_OS="$os_type"
    export DOTFILES_ENV="$env_type"
    export DOTFILES_DISTRO="${distro:-unknown}"
    export DOTFILES_VERSION="${version:-unknown}"
    export DOTFILES_ARCH="$arch"
    
    log_info "Platform detected: $os_type/$env_type ($distro $version) on $arch"
}

detect_linux_environment() {
    # Check for WSL
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        env_type="wsl"
    else
        # Check for docker container
        if [[ -f /.dockerenv ]]; then
            env_type="container"
        # Check for desktop environment
        elif [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || [[ -n "${DESKTOP_SESSION:-}" ]]; then
            env_type="desktop"
        else
            env_type="server"
        fi
    fi
    
    # Get distribution info
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$ID"
        version="$VERSION_ID"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        distro="$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')"
        version="$DISTRIB_RELEASE"
    fi
}

# Package manager abstraction
get_package_manager() {
    case "$DOTFILES_OS" in
        linux)
            case "$DOTFILES_DISTRO" in
                ubuntu|debian)
                    echo "apt"
                    ;;
                fedora|centos|rhel)
                    echo "dnf"
                    ;;
                arch|manjaro)
                    echo "pacman"
                    ;;
                *)
                    log_error "Unsupported Linux distribution: $DOTFILES_DISTRO"
                    return 1
                    ;;
            esac
            ;;
        macos)
            if command -v brew &> /dev/null; then
                echo "brew"
            else
                log_error "Homebrew not found. Please install Homebrew first."
                return 1
            fi
            ;;
        *)
            log_error "Package manager not supported on: $DOTFILES_OS"
            return 1
            ;;
    esac
}

# Package installation abstraction
install_package() {
    local package=$1
    local options=${2:-""}
    local package_manager
    
    package_manager=$(get_package_manager) || return 1
    
    log_info "Installing package: $package using $package_manager"
    
    case "$package_manager" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y $options "$package"
            ;;
        dnf)
            sudo dnf install -y $options "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm $options "$package"
            ;;
        brew)
            brew install $options "$package"
            ;;
        *)
            log_error "Unknown package manager: $package_manager"
            return 1
            ;;
    esac
}

# Package check
is_package_installed() {
    local package=$1
    local package_manager
    
    package_manager=$(get_package_manager) || return 1
    
    case "$package_manager" in
        apt)
            dpkg -l "$package" &> /dev/null
            ;;
        dnf)
            dnf list installed "$package" &> /dev/null
            ;;
        pacman)
            pacman -Q "$package" &> /dev/null
            ;;
        brew)
            brew list "$package" &> /dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Service management abstraction
manage_service() {
    local action=$1
    local service=$2
    
    case "$action" in
        start|stop|restart|enable|disable|status)
            if command -v systemctl &> /dev/null; then
                sudo systemctl "$action" "$service"
            elif command -v service &> /dev/null; then
                case "$action" in
                    enable|disable)
                        log_warn "Service $action not supported with legacy service command"
                        ;;
                    *)
                        sudo service "$service" "$action"
                        ;;
                esac
            elif [[ "$DOTFILES_OS" == "macos" ]]; then
                case "$action" in
                    start)
                        sudo launchctl load -w "/Library/LaunchDaemons/$service.plist" 2>/dev/null ||
                        launchctl load -w "/Library/LaunchAgents/$service.plist" 2>/dev/null
                        ;;
                    stop)
                        sudo launchctl unload -w "/Library/LaunchDaemons/$service.plist" 2>/dev/null ||
                        launchctl unload -w "/Library/LaunchAgents/$service.plist" 2>/dev/null
                        ;;
                    *)
                        log_warn "Service action '$action' not fully supported on macOS"
                        ;;
                esac
            else
                log_error "No service manager found"
                return 1
            fi
            ;;
        *)
            log_error "Invalid service action: $action"
            return 1
            ;;
    esac
}

# User management helpers
is_root() {
    [[ $EUID -eq 0 ]]
}

has_sudo() {
    sudo -n true 2>/dev/null
}

require_sudo() {
    if ! has_sudo; then
        log_info "Sudo access required. Please enter your password:"
        sudo -v || log_fatal "Sudo access required but not available"
    fi
}

# Network connectivity check
check_internet_connection() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 5 "$host" &> /dev/null; then
            log_debug "Internet connection verified via $host"
            return 0
        fi
    done
    
    log_error "No internet connection detected"
    return 1
}

# System resource checks
check_system_requirements() {
    local min_memory_gb=${1:-4}
    local min_disk_gb=${2:-20}
    
    # Check available memory
    local available_memory_gb
    case "$DOTFILES_OS" in
        linux)
            available_memory_gb=$(free -g | awk '/^Mem:/{print $2}')
            ;;
        macos)
            available_memory_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
            ;;
        *)
            log_warn "Memory check not implemented for $DOTFILES_OS"
            return 0
            ;;
    esac
    
    if [[ $available_memory_gb -lt $min_memory_gb ]]; then
        log_warn "Insufficient memory: ${available_memory_gb}GB available, ${min_memory_gb}GB required"
        return 1
    fi
    
    # Check available disk space
    local available_disk_gb
    available_disk_gb=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [[ $available_disk_gb -lt $min_disk_gb ]]; then
        log_warn "Insufficient disk space: ${available_disk_gb}GB available, ${min_disk_gb}GB required"
        return 1
    fi
    
    log_info "System requirements check passed"
    return 0
}

# Initialize platform detection
init_platform() {
    detect_platform
    log_debug "Platform variables exported:"
    log_debug "  DOTFILES_OS=$DOTFILES_OS"
    log_debug "  DOTFILES_ENV=$DOTFILES_ENV"
    log_debug "  DOTFILES_DISTRO=$DOTFILES_DISTRO"
    log_debug "  DOTFILES_VERSION=$DOTFILES_VERSION"
    log_debug "  DOTFILES_ARCH=$DOTFILES_ARCH"
}

# Export functions for use in other scripts
export -f detect_platform get_package_manager install_package is_package_installed
export -f manage_service is_root has_sudo require_sudo check_internet_connection
export -f check_system_requirements init_platform