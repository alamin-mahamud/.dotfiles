#!/usr/bin/env bash
# Package management abstraction
# Following Python's Zen: "Explicit is better than implicit"

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
source "$(dirname "${BASH_SOURCE[0]}")/os.sh"

# Package manager detection
detect_package_manager() {
    local os distro
    os=$(detect_os)
    
    if [[ "$os" == "macos" ]]; then
        if command_exists brew; then
            echo "brew"
        else
            echo "none"
        fi
    elif [[ "$os" == "linux" ]]; then
        distro=$(detect_distro)
        case "$distro" in
            debian)
                command_exists apt && echo "apt" || echo "apt-get"
                ;;
            redhat)
                if command_exists dnf; then
                    echo "dnf"
                elif command_exists yum; then
                    echo "yum"
                else
                    echo "none"
                fi
                ;;
            arch)
                command_exists pacman && echo "pacman" || echo "none"
                ;;
            alpine)
                command_exists apk && echo "apk" || echo "none"
                ;;
            suse)
                command_exists zypper && echo "zypper" || echo "none"
                ;;
            *)
                echo "none"
                ;;
        esac
    else
        echo "none"
    fi
}

# Update package manager cache
update_packages() {
    local pm
    pm=$(detect_package_manager)
    
    info "Updating package cache..."
    
    case "$pm" in
        apt|apt-get)
            sudo "$pm" update
            ;;
        dnf|yum)
            sudo "$pm" check-update || true
            ;;
        pacman)
            sudo pacman -Sy
            ;;
        brew)
            brew update
            ;;
        apk)
            sudo apk update
            ;;
        zypper)
            sudo zypper refresh
            ;;
        *)
            warning "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# Install single package
install_package() {
    local package="$1"
    local pm
    pm=$(detect_package_manager)
    
    if package_installed "$package"; then
        debug "Package already installed: $package"
        return 0
    fi
    
    info "Installing package: $package"
    
    case "$pm" in
        apt|apt-get)
            sudo "$pm" install -y "$package"
            ;;
        dnf|yum)
            sudo "$pm" install -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        brew)
            brew install "$package"
            ;;
        apk)
            sudo apk add "$package"
            ;;
        zypper)
            sudo zypper install -y "$package"
            ;;
        *)
            error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# Install multiple packages
install_packages() {
    local packages=("$@")
    local failed=()
    
    for package in "${packages[@]}"; do
        if ! install_package "$package"; then
            failed+=("$package")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        error "Failed to install packages: ${failed[*]}"
        return 1
    fi
    
    success "All packages installed successfully"
}

# Check if package is installed
package_installed() {
    local package="$1"
    local pm
    pm=$(detect_package_manager)
    
    case "$pm" in
        apt|apt-get)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$package" &>/dev/null
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
        brew)
            brew list "$package" &>/dev/null
            ;;
        apk)
            apk info -e "$package" &>/dev/null
            ;;
        zypper)
            rpm -q "$package" &>/dev/null
            ;;
        *)
            command_exists "$package"
            ;;
    esac
}

# Remove package
remove_package() {
    local package="$1"
    local pm
    pm=$(detect_package_manager)
    
    if ! package_installed "$package"; then
        debug "Package not installed: $package"
        return 0
    fi
    
    info "Removing package: $package"
    
    case "$pm" in
        apt|apt-get)
            sudo "$pm" remove -y "$package"
            ;;
        dnf|yum)
            sudo "$pm" remove -y "$package"
            ;;
        pacman)
            sudo pacman -R --noconfirm "$package"
            ;;
        brew)
            brew uninstall "$package"
            ;;
        apk)
            sudo apk del "$package"
            ;;
        zypper)
            sudo zypper remove -y "$package"
            ;;
        *)
            error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# Install package with OS-specific name mapping
install_package_multi() {
    local -n package_map=$1
    local os distro pm
    
    os=$(detect_os)
    distro=$(detect_distro)
    pm=$(detect_package_manager)
    
    # Try OS-specific package name first
    local package_name=""
    
    if [[ -n "${package_map[$os]:-}" ]]; then
        package_name="${package_map[$os]}"
    elif [[ -n "${package_map[$distro]:-}" ]]; then
        package_name="${package_map[$distro]}"
    elif [[ -n "${package_map[$pm]:-}" ]]; then
        package_name="${package_map[$pm]}"
    elif [[ -n "${package_map[default]:-}" ]]; then
        package_name="${package_map[default]}"
    else
        error "No package mapping found"
        return 1
    fi
    
    install_package "$package_name"
}

# Install build essentials
install_build_essentials() {
    local os distro
    os=$(detect_os)
    distro=$(detect_distro)
    
    info "Installing build essentials..."
    
    case "$os" in
        macos)
            if ! command_exists gcc; then
                info "Installing Xcode Command Line Tools..."
                xcode-select --install 2>/dev/null || true
            fi
            ;;
        linux)
            case "$distro" in
                debian)
                    install_packages build-essential git curl wget
                    ;;
                redhat)
                    install_packages gcc gcc-c++ make git curl wget
                    ;;
                arch)
                    install_packages base-devel git curl wget
                    ;;
                alpine)
                    install_packages build-base git curl wget
                    ;;
                suse)
                    install_packages gcc gcc-c++ make git curl wget
                    ;;
            esac
            ;;
    esac
}

# Export functions
export -f detect_package_manager update_packages
export -f install_package install_packages
export -f package_installed remove_package
export -f install_package_multi install_build_essentials