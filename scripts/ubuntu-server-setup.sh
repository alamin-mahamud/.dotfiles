#!/usr/bin/env bash

# Ubuntu Server Setup Script for Ubuntu 24.04 LTS
# Comprehensive server setup with security hardening and development tools

set -euo pipefail

# Get script directory and source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/package-managers.sh"

# Parse command line arguments
MINIMAL_INSTALL=false
SKIP_SECURITY=false
SKIP_DEVTOOLS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)
            MINIMAL_INSTALL=true
            shift
            ;;
        --skip-security)
            SKIP_SECURITY=true
            shift
            ;;
        --skip-devtools)
            SKIP_DEVTOOLS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --minimal       Minimal installation (shell only)"
            echo "  --skip-security Skip security hardening"
            echo "  --skip-devtools Skip development tools"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

main() {
    print_header "Ubuntu 24.04 LTS Server Setup"
    
    # Verify Ubuntu version
    verify_ubuntu_version
    
    info "Starting Ubuntu server setup"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    # Update system
    update_system
    
    # Install shell environment (always)
    install_shell_environment
    
    if [[ "$MINIMAL_INSTALL" == "false" ]]; then
        # Security hardening
        if [[ "$SKIP_SECURITY" == "false" ]]; then
            setup_security
        fi
        
        # Development tools
        if [[ "$SKIP_DEVTOOLS" == "false" ]]; then
            install_development_tools
        fi
    fi
    
    # Post-installation tasks
    cleanup_and_summary
    
    success "Ubuntu server setup completed!"
    info "Please reboot the system to ensure all changes take effect"
}

verify_ubuntu_version() {
    local version_id
    
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect OS version. This script requires Ubuntu 24.04 LTS."
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        error "This script is designed for Ubuntu. Detected: $ID"
    fi
    
    version_id="${VERSION_ID:-unknown}"
    
    case "$version_id" in
        "24.04"|"22.04"|"20.04")
            info "Detected Ubuntu $version_id - supported version"
            ;;
        *)
            warning "Ubuntu $version_id detected - this script is optimized for 24.04 LTS"
            if ! ask_yes_no "Continue anyway?"; then
                exit 1
            fi
            ;;
    esac
}

update_system() {
    print_header "System Update"
    
    info "Updating package lists and upgrading system..."
    sudo apt-get update
    sudo apt-get upgrade -y
    
    # Install essential packages
    install_packages_multi \
        "curl:curl" \
        "wget:wget" \
        "git:git" \
        "unzip:unzip" \
        "software-properties-common:software-properties-common" \
        "apt-transport-https:apt-transport-https" \
        "ca-certificates:ca-certificates" \
        "gnupg:gnupg" \
        "lsb-release:lsb-release"
    
    success "System update completed"
}

install_shell_environment() {
    print_header "Installing Shell Environment"
    
    if [[ -f "$SCRIPT_DIR/components/shell-env.sh" ]]; then
        info "Running shell environment installer..."
        bash "$SCRIPT_DIR/components/shell-env.sh"
    else
        error "Shell environment installer not found: $SCRIPT_DIR/components/shell-env.sh"
    fi
}

setup_security() {
    print_header "Security Hardening"
    
    setup_firewall
    setup_fail2ban
    configure_ssh_security
    setup_automatic_updates
}

setup_firewall() {
    info "Setting up UFW firewall..."
    
    # Install UFW if not present
    install_packages_multi "ufw:ufw"
    
    # Reset UFW to default
    sudo ufw --force reset
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (be careful not to lock yourself out)
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS for web servers
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Enable UFW
    sudo ufw --force enable
    
    success "UFW firewall configured"
}

setup_fail2ban() {
    info "Setting up fail2ban..."
    
    # Install fail2ban
    install_packages_multi "fail2ban:fail2ban"
    
    # Backup original config
    if [[ -f /etc/fail2ban/jail.conf ]]; then
        backup_file /etc/fail2ban/jail.conf
    fi
    
    # Create local jail configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = auto
banaction = ufw

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
    
    # Enable and start fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    
    success "fail2ban configured for SSH protection"
}

configure_ssh_security() {
    info "Configuring SSH security..."
    
    local ssh_config="/etc/ssh/sshd_config"
    backup_file "$ssh_config"
    
    # Create temporary config with security improvements
    sudo tee /tmp/sshd_security_config > /dev/null << 'EOF'
# Security configurations
PasswordAuthentication yes
PermitRootLogin no
Protocol 2
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers *
UsePAM yes
EOF
    
    # Append security config to SSH config (if not already present)
    if ! sudo grep -q "MaxAuthTries" "$ssh_config"; then
        sudo tee -a "$ssh_config" < /tmp/sshd_security_config > /dev/null
        info "SSH security configuration added"
    else
        debug "SSH security configuration already present"
    fi
    
    # Test SSH configuration
    sudo sshd -t
    
    # Restart SSH service
    sudo systemctl restart ssh
    
    rm /tmp/sshd_security_config
    success "SSH security configured"
}

setup_automatic_updates() {
    info "Setting up automatic security updates..."
    
    # Install unattended-upgrades
    install_packages_multi "unattended-upgrades:unattended-upgrades"
    
    # Configure automatic updates for security packages only
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id} ESMApps:${distro_codename}-apps-security";
    "${distro_id} ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::SyslogEnable "true";
EOF
    
    # Enable automatic updates
    echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
    echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
    
    # Enable and start unattended-upgrades
    sudo systemctl enable unattended-upgrades
    sudo systemctl start unattended-upgrades
    
    success "Automatic security updates configured"
}

install_development_tools() {
    print_header "Installing Development Tools"
    
    # Install basic development packages
    install_packages_multi \
        "build-essential:build-essential" \
        "make:make" \
        "cmake:cmake" \
        "pkg-config:pkg-config" \
        "libtool:libtool" \
        "autoconf:autoconf" \
        "automake:automake"
    
    # Install DevOps tools if script exists
    if [[ -f "$SCRIPT_DIR/components/devops-tools.sh" ]]; then
        info "Installing DevOps tools..."
        bash "$SCRIPT_DIR/components/devops-tools.sh"
    fi
    
    # Install programming languages if script exists
    if [[ -f "$SCRIPT_DIR/components/languages.sh" ]]; then
        info "Installing programming languages..."
        bash "$SCRIPT_DIR/components/languages.sh"
    fi
    
    success "Development tools installation completed"
}

cleanup_and_summary() {
    print_header "Cleanup and Summary"
    
    # Clean package cache
    info "Cleaning package cache..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    # Update locate database
    if command -v updatedb >/dev/null 2>&1; then
        sudo updatedb
    fi
    
    # Display summary
    info "Installation Summary:"
    info "- System updated to latest packages"
    info "- Shell environment (Zsh + Tmux + CLI tools) installed"
    
    if [[ "$SKIP_SECURITY" == "false" ]]; then
        info "- Security hardening applied (UFW, fail2ban, SSH)"
    fi
    
    if [[ "$SKIP_DEVTOOLS" == "false" ]]; then
        info "- Development tools and languages installed"
    fi
    
    info "- Log file: $LOG_FILE"
    info "- Backup directory: $BACKUP_DIR"
    
    success "Setup completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi