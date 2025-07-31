#!/bin/bash
# core/system/system_updates.sh - System update and package management

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="system_updates"
COMPONENT_META[description]="System package updates and maintenance"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="core"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

component_install() {
    log_info "Updating system packages..."
    
    case "$DOTFILES_OS" in
        linux)
            update_linux_system
            ;;
        macos)
            update_macos_system
            ;;
        *)
            log_error "System updates not supported on $DOTFILES_OS"
            return 1
            ;;
    esac
}

update_linux_system() {
    local package_manager
    package_manager=$(get_package_manager) || return 1
    
    case "$package_manager" in
        apt)
            log_info "Updating APT package lists..."
            sudo apt-get update -qq
            
            log_info "Upgrading installed packages..."
            sudo apt-get upgrade -y
            
            log_info "Performing distribution upgrade..."
            sudo apt-get dist-upgrade -y
            
            log_info "Cleaning up obsolete packages..."
            sudo apt-get autoremove -y
            sudo apt-get autoclean
            ;;
        dnf)
            log_info "Updating DNF repositories..."
            sudo dnf check-update || true  # Exit code 100 means updates available
            
            log_info "Upgrading installed packages..."
            sudo dnf upgrade -y
            
            log_info "Cleaning up obsolete packages..."
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
        pacman)
            log_info "Updating Pacman repositories..."
            sudo pacman -Sy
            
            log_info "Upgrading installed packages..."
            sudo pacman -Su --noconfirm
            
            log_info "Cleaning package cache..."
            sudo pacman -Sc --noconfirm
            ;;
        *)
            log_error "Unknown package manager: $package_manager"
            return 1
            ;;
    esac
    
    # Enable automatic security updates if possible
    enable_automatic_updates
}

update_macos_system() {
    log_info "Updating macOS system..."
    
    # Update macOS system
    if command -v softwareupdate &> /dev/null; then
        log_info "Installing macOS system updates..."
        sudo softwareupdate -i -a --restart
    fi
    
    # Update Homebrew if installed
    if command -v brew &> /dev/null; then
        log_info "Updating Homebrew..."
        brew update
        
        log_info "Upgrading Homebrew packages..."
        brew upgrade
        
        log_info "Cleaning up Homebrew..."
        brew cleanup --prune=30
        
        log_info "Running Homebrew diagnostics..."
        brew doctor || log_warn "Homebrew doctor found issues (non-critical)"
    fi
    
    # Update Mac App Store apps if mas is available
    if command -v mas &> /dev/null; then
        log_info "Updating Mac App Store applications..."
        mas upgrade
    fi
}

enable_automatic_updates() {
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            log_info "Configuring automatic security updates..."
            
            # Install unattended-upgrades if not present
            if ! is_package_installed unattended-upgrades; then
                install_package unattended-upgrades
            fi
            
            # Configure automatic updates
            sudo dpkg-reconfigure -f noninteractive unattended-upgrades
            
            # Customize configuration
            cat | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
    // Add packages to avoid automatic updates
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

            # Configure auto-update intervals
            cat | sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
            
            log_success "Automatic security updates configured"
            ;;
        fedora|centos|rhel)
            log_info "Configuring automatic updates for DNF..."
            
            # Install dnf-automatic if not present
            if ! is_package_installed dnf-automatic; then
                install_package dnf-automatic
            fi
            
            # Configure automatic updates
            sudo sed -i 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf
            
            # Enable and start the service
            manage_service enable dnf-automatic.timer
            manage_service start dnf-automatic.timer
            
            log_success "DNF automatic updates configured"
            ;;
        *)
            log_warn "Automatic updates not configured for $DOTFILES_DISTRO"
            ;;
    esac
}

component_validate() {
    log_info "Validating system updates component..."
    
    # Check if package manager is available
    local package_manager
    if ! package_manager=$(get_package_manager); then
        log_error "Package manager validation failed"
        return 1
    fi
    
    log_info "Package manager available: $package_manager"
    
    # Check if automatic updates are configured (non-critical)
    case "$DOTFILES_OS" in
        linux)
            case "$DOTFILES_DISTRO" in
                ubuntu|debian)
                    if [[ -f /etc/apt/apt.conf.d/50unattended-upgrades ]]; then
                        log_success "Automatic updates configured"
                    else
                        log_warn "Automatic updates not configured"
                    fi
                    ;;
                fedora|centos|rhel)
                    if systemctl is-enabled dnf-automatic.timer &> /dev/null; then
                        log_success "DNF automatic updates enabled"
                    else
                        log_warn "DNF automatic updates not enabled"
                    fi
                    ;;
            esac
            ;;
        macos)
            if command -v brew &> /dev/null; then
                log_success "Homebrew available for package management"
            else
                log_warn "Homebrew not available"
            fi
            ;;
    esac
    
    return 0
}

# Execute component if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize platform detection
    init_platform
    
    # Run component
    run_component
fi