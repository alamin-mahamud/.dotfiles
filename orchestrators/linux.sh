#!/usr/bin/env bash
# Linux platform orchestrator
# Following Python's Zen: "Complex is better than complicated"

# Get the orchestrator directory
ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$ORCHESTRATOR_DIR/.." && pwd)"
LIB_DIR="$DOTFILES_ROOT/lib"
RECIPES_DIR="$DOTFILES_ROOT/recipes"

# Import ingredients
source "$LIB_DIR/core.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/package.sh"

# Linux-specific orchestration
main() {
    info "=== Linux Platform Orchestrator ==="
    
    local distro
    distro=$(detect_distro)
    
    # Check prerequisites
    if ! check_internet; then
        die "Internet connection required"
    fi
    
    # Update package cache
    update_packages
    
    # Install build essentials first
    install_build_essentials
    
    # Run recipes in order
    local recipes=(
        "$RECIPES_DIR/shell.sh"
        "$RECIPES_DIR/python.sh"
    )
    
    # Add desktop recipes if desktop environment is available
    if has_desktop; then
        recipes+=("$RECIPES_DIR/desktop.sh")
    fi
    
    # Execute all recipes
    for recipe in "${recipes[@]}"; do
        if [[ -x "$recipe" ]]; then
            info "Running recipe: $(basename "$recipe")"
            "$recipe"
        else
            warning "Recipe not found or not executable: $recipe"
        fi
    done
    
    # Linux-specific post-installation
    post_install_linux
    
    success "=== Linux setup complete! ==="
}

# Linux-specific post-installation tasks
post_install_linux() {
    info "Running Linux-specific post-installation tasks..."
    
    # Set up basic security for servers
    if ! has_desktop && ! is_wsl; then
        setup_server_security
    fi
    
    # Install additional Linux tools
    install_linux_tools
    
    success "Linux post-installation complete"
}

# Server security setup
setup_server_security() {
    info "Setting up basic server security..."
    
    local distro
    distro=$(detect_distro)
    
    case "$distro" in
        debian)
            # Install security packages
            install_packages ufw fail2ban unattended-upgrades
            
            # Configure UFW
            if command_exists ufw; then
                sudo ufw --force reset >/dev/null 2>&1
                sudo ufw default deny incoming >/dev/null 2>&1
                sudo ufw default allow outgoing >/dev/null 2>&1
                sudo ufw --force enable >/dev/null 2>&1
                success "UFW firewall configured"
            fi
            
            # Configure automatic updates
            if [[ -f /etc/apt/apt.conf.d/50unattended-upgrades ]]; then
                if ! grep -q "security" /etc/apt/apt.conf.d/50unattended-upgrades; then
                    echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null
                fi
            fi
            ;;
    esac
    
    success "Server security configured"
}

# Install Linux-specific tools
install_linux_tools() {
    info "Installing Linux-specific tools..."
    
    local distro
    distro=$(detect_distro)
    
    # Common Linux packages
    local packages=(
        "neofetch"
        "htop"
        "tree"
        "unzip"
        "zip"
        "rsync"
    )
    
    case "$distro" in
        debian)
            packages+=(
                "software-properties-common"
                "apt-transport-https"
                "ca-certificates"
                "gnupg"
                "lsb-release"
            )
            ;;
        redhat)
            packages+=(
                "epel-release"
                "dnf-plugins-core"
            )
            ;;
    esac
    
    install_packages "${packages[@]}"
    
    success "Linux tools installed"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi