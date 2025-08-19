#!/usr/bin/env bash

# Package management utilities for dotfiles installation scripts
# Source this file in other scripts: source "$(dirname "$0")/lib/package-managers.sh"

# Ensure common.sh is loaded
if [[ -z "${DOTFILES_OS:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# Package manager detection
detect_package_manager() {
    local os="${DOTFILES_OS:-$(detect_os)}"
    
    case "$os" in
        linux)
            if command_exists apt-get; then
                echo "apt"
            elif command_exists dnf; then
                echo "dnf"
            elif command_exists yum; then
                echo "yum"
            elif command_exists pacman; then
                echo "pacman"
            elif command_exists zypper; then
                echo "zypper"
            elif command_exists apk; then
                echo "apk"
            else
                echo "unknown"
            fi
            ;;
        macos)
            if command_exists brew; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Update package lists
update_package_lists() {
    local pm="${1:-$(detect_package_manager)}"
    
    info "Updating package lists..."
    
    case "$pm" in
        apt)
            sudo apt-get update -qq
            ;;
        dnf)
            sudo dnf check-update -q || true
            ;;
        yum)
            sudo yum check-update -q || true
            ;;
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        zypper)
            sudo zypper refresh -q
            ;;
        apk)
            sudo apk update
            ;;
        brew)
            brew update
            ;;
        *)
            warning "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# Install packages
install_packages() {
    local packages=("$@")
    local pm="${PM:-$(detect_package_manager)}"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages specified for installation"
        return 0
    fi
    
    info "Installing packages: ${packages[*]} (using $pm)"
    
    case "$pm" in
        apt)
            sudo apt-get install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        zypper)
            sudo zypper install -y "${packages[@]}"
            ;;
        apk)
            sudo apk add "${packages[@]}"
            ;;
        brew)
            brew install "${packages[@]}"
            ;;
        *)
            error "Cannot install packages: unknown package manager '$pm'"
            ;;
    esac
}

# Install packages with OS-specific names
install_packages_multi() {
    local -A package_map
    local packages_to_install=()
    local pm="${PM:-$(detect_package_manager)}"
    
    # Parse arguments: "common_name:apt_name:dnf_name:pacman_name:brew_name"
    for package_spec in "$@"; do
        IFS=':' read -ra parts <<< "$package_spec"
        local common_name="${parts[0]}"
        local apt_name="${parts[1]:-$common_name}"
        local dnf_name="${parts[2]:-$common_name}"
        local pacman_name="${parts[3]:-$common_name}"
        local brew_name="${parts[4]:-$common_name}"
        
        case "$pm" in
            apt) packages_to_install+=("$apt_name") ;;
            dnf|yum) packages_to_install+=("$dnf_name") ;;
            pacman) packages_to_install+=("$pacman_name") ;;
            brew) packages_to_install+=("$brew_name") ;;
            *) packages_to_install+=("$common_name") ;;
        esac
    done
    
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        install_packages "${packages_to_install[@]}"
    fi
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    local pm="${PM:-$(detect_package_manager)}"
    
    case "$pm" in
        apt)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"
            ;;
        dnf)
            dnf list installed "$package" &>/dev/null
            ;;
        yum)
            yum list installed "$package" &>/dev/null
            ;;
        pacman)
            pacman -Qi "$package" &>/dev/null
            ;;
        zypper)
            zypper search --installed-only "$package" &>/dev/null
            ;;
        apk)
            apk info --installed "$package" &>/dev/null
            ;;
        brew)
            brew list --formula "$package" &>/dev/null || brew list --cask "$package" &>/dev/null
            ;;
        *)
            command_exists "$package"
            ;;
    esac
}

# Remove packages
remove_packages() {
    local packages=("$@")
    local pm="${PM:-$(detect_package_manager)}"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages specified for removal"
        return 0
    fi
    
    info "Removing packages: ${packages[*]} (using $pm)"
    
    case "$pm" in
        apt)
            sudo apt-get remove -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf remove -y "${packages[@]}"
            ;;
        yum)
            sudo yum remove -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -Rs --noconfirm "${packages[@]}"
            ;;
        zypper)
            sudo zypper remove -y "${packages[@]}"
            ;;
        apk)
            sudo apk del "${packages[@]}"
            ;;
        brew)
            brew uninstall "${packages[@]}"
            ;;
        *)
            error "Cannot remove packages: unknown package manager '$pm'"
            ;;
    esac
}

# Clean package cache
clean_package_cache() {
    local pm="${PM:-$(detect_package_manager)}"
    
    info "Cleaning package cache..."
    
    case "$pm" in
        apt)
            sudo apt-get autoremove -y
            sudo apt-get autoclean
            ;;
        dnf)
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
        yum)
            sudo yum autoremove -y
            sudo yum clean all
            ;;
        pacman)
            sudo pacman -Sc --noconfirm
            ;;
        zypper)
            sudo zypper clean --all
            ;;
        apk)
            sudo apk cache clean
            ;;
        brew)
            brew cleanup
            ;;
        *)
            warning "Cannot clean cache: unknown package manager '$pm'"
            ;;
    esac
}

# Add external repository
add_repository() {
    local repo="$1"
    local key_url="${2:-}"
    local pm="${PM:-$(detect_package_manager)}"
    
    info "Adding repository: $repo"
    
    case "$pm" in
        apt)
            if [[ -n "$key_url" ]]; then
                curl -fsSL "$key_url" | sudo gpg --dearmor -o "/usr/share/keyrings/$(basename "$key_url" .gpg).gpg"
            fi
            echo "$repo" | sudo tee "/etc/apt/sources.list.d/dotfiles-$(date +%s).list" > /dev/null
            update_package_lists
            ;;
        dnf|yum)
            sudo "$pm" config-manager --add-repo "$repo"
            ;;
        *)
            warning "Repository addition not supported for package manager: $pm"
            ;;
    esac
}

# Install build essentials
install_build_essentials() {
    local pm="${PM:-$(detect_package_manager)}"
    
    info "Installing build essentials..."
    
    case "$pm" in
        apt)
            install_packages build-essential gcc g++ make
            ;;
        dnf)
            install_packages "@Development Tools" gcc gcc-c++ make
            ;;
        yum)
            install_packages groupinstall "Development Tools"
            install_packages gcc gcc-c++ make
            ;;
        pacman)
            install_packages base-devel
            ;;
        zypper)
            install_packages -t pattern devel_basis
            ;;
        apk)
            install_packages build-base gcc g++ make
            ;;
        brew)
            # Xcode command line tools should be installed separately
            info "For macOS, ensure Xcode command line tools are installed:"
            info "xcode-select --install"
            ;;
        *)
            warning "Build essentials installation not supported for: $pm"
            ;;
    esac
}

# Install package from URL (for .deb, .rpm files)
install_package_from_url() {
    local url="$1"
    local temp_file="/tmp/$(basename "$url")"
    local pm="${PM:-$(detect_package_manager)}"
    
    info "Installing package from URL: $url"
    
    download_file "$url" "$temp_file"
    
    case "$pm" in
        apt)
            if [[ "$temp_file" == *.deb ]]; then
                sudo dpkg -i "$temp_file" || sudo apt-get install -f -y
            else
                error "Unsupported package format for apt"
            fi
            ;;
        dnf|yum)
            if [[ "$temp_file" == *.rpm ]]; then
                sudo "$pm" install -y "$temp_file"
            else
                error "Unsupported package format for $pm"
            fi
            ;;
        *)
            error "Package installation from URL not supported for: $pm"
            ;;
    esac
    
    rm -f "$temp_file"
}

# Setup package manager (install if needed)
setup_package_manager() {
    local os="${DOTFILES_OS:-$(detect_os)}"
    
    case "$os" in
        macos)
            if ! command_exists brew; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add to PATH
                if [[ -x "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -x "/usr/local/bin/brew" ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            ;;
        linux)
            # Most Linux distros come with a package manager
            local pm="$(detect_package_manager)"
            if [[ "$pm" == "unknown" ]]; then
                error "No supported package manager found"
            fi
            ;;
    esac
}

# Install snap packages
install_snap_packages() {
    local packages=("$@")
    
    if ! command_exists snap; then
        warning "Snap not available, skipping snap packages"
        return 0
    fi
    
    for package in "${packages[@]}"; do
        if [[ "$package" == *"--classic" ]]; then
            # Extract package name and install with classic confinement
            local pkg_name="${package% --classic}"
            info "Installing snap package with classic confinement: $pkg_name"
            sudo snap install "$pkg_name" --classic
        else
            info "Installing snap package: $package"
            sudo snap install "$package"
        fi
    done
}

# Install flatpak packages
install_flatpak_packages() {
    local packages=("$@")
    
    if ! command_exists flatpak; then
        warning "Flatpak not available, skipping flatpak packages"
        return 0
    fi
    
    for package in "${packages[@]}"; do
        info "Installing flatpak package: $package"
        flatpak install flathub "$package" -y
    done
}