#!/bin/bash
# core/security/firewall_basic.sh - Basic firewall configuration

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="firewall_basic"
COMPONENT_META[description]="Basic firewall configuration for system security"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="security"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# Default allowed ports
declare -A DEFAULT_ALLOWED_PORTS=(
    ["ssh"]="22/tcp"
    ["http"]="80/tcp"
    ["https"]="443/tcp"
)

component_install() {
    log_info "Configuring firewall..."
    
    case "$DOTFILES_OS" in
        linux)
            configure_linux_firewall
            ;;
        macos)
            configure_macos_firewall
            ;;
        *)
            log_error "Firewall configuration not supported on $DOTFILES_OS"
            return 1
            ;;
    esac
    
    log_success "Firewall configuration completed"
}

configure_linux_firewall() {
    # Detect and configure appropriate firewall
    if command -v ufw &> /dev/null; then
        configure_ufw
    elif command -v firewall-cmd &> /dev/null; then
        configure_firewalld
    elif command -v iptables &> /dev/null; then
        configure_iptables
    else
        log_info "No supported firewall found. Installing UFW..."
        install_and_configure_ufw
    fi
}

install_and_configure_ufw() {
    # Install UFW based on distribution
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            install_package ufw || {
                log_error "Failed to install UFW"
                return 1
            }
            ;;
        fedora|centos|rhel)
            # These distros typically use firewalld
            install_package firewalld || {
                log_error "Failed to install firewalld"
                return 1
            }
            configure_firewalld
            return
            ;;
        arch)
            install_package ufw || {
                log_error "Failed to install UFW"
                return 1
            }
            ;;
        *)
            log_error "Cannot install firewall on $DOTFILES_DISTRO"
            return 1
            ;;
    esac
    
    configure_ufw
}

configure_ufw() {
    log_info "Configuring UFW (Uncomplicated Firewall)..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for firewall configuration"
        return 0
    fi
    
    # Reset UFW to defaults (if requested)
    if [[ "${DOTFILES_FIREWALL_RESET:-false}" == "true" ]]; then
        log_warn "Resetting UFW to defaults..."
        sudo ufw --force reset
    fi
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw default deny forward
    
    # Allow SSH (critical - prevent lockout)
    log_info "Allowing SSH access..."
    sudo ufw allow 22/tcp comment "SSH"
    
    # Allow additional ports based on environment
    configure_environment_ports "ufw"
    
    # Allow common services if installed
    configure_service_ports "ufw"
    
    # Enable logging
    sudo ufw logging low
    
    # Enable UFW
    if [[ "${DOTFILES_ENV}" == "server" ]] || [[ "${DOTFILES_FIREWALL_ENABLE:-true}" == "true" ]]; then
        log_info "Enabling UFW..."
        sudo ufw --force enable
        
        # Show status
        sudo ufw status verbose
    else
        log_info "UFW configured but not enabled (desktop environment)"
        log_info "To enable: sudo ufw enable"
    fi
}

configure_firewalld() {
    log_info "Configuring firewalld..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for firewall configuration"
        return 0
    fi
    
    # Ensure firewalld is running
    manage_service start firewalld
    manage_service enable firewalld
    
    # Set default zone
    sudo firewall-cmd --set-default-zone=public
    
    # Configure services
    log_info "Configuring firewall services..."
    
    # Allow SSH
    sudo firewall-cmd --permanent --add-service=ssh
    
    # Allow additional services based on environment
    configure_environment_ports "firewalld"
    
    # Allow common services if installed
    configure_service_ports "firewalld"
    
    # Enable logging
    sudo firewall-cmd --permanent --set-log-denied=all
    
    # Reload firewall
    sudo firewall-cmd --reload
    
    # Show configuration
    log_info "Firewall zones:"
    sudo firewall-cmd --get-active-zones
    log_info "Allowed services:"
    sudo firewall-cmd --list-services
}

configure_iptables() {
    log_info "Configuring iptables..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for firewall configuration"
        return 0
    fi
    
    # Save current rules as backup
    sudo iptables-save > "/tmp/iptables.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Create basic rules script
    local rules_script="/etc/iptables/rules.v4"
    sudo mkdir -p /etc/iptables
    
    cat << 'EOF' | sudo tee "$rules_script" > /dev/null
*filter
# Default policies
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow loopback
-A INPUT -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT

# Allow established connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
-A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# Allow ping
-A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Additional rules will be added here

# Log dropped packets
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-dropped: " --log-level 7

COMMIT
EOF
    
    # Apply rules
    sudo iptables-restore < "$rules_script"
    
    # Install iptables-persistent to save rules
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            install_package iptables-persistent
            ;;
        *)
            log_info "Remember to save iptables rules for persistence"
            ;;
    esac
}

configure_macos_firewall() {
    log_info "Configuring macOS firewall..."
    
    # Check if we have admin access
    if ! sudo -n true 2>/dev/null; then
        log_warn "Admin access required for firewall configuration"
        return 0
    fi
    
    # Enable firewall
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    
    # Set firewall to block all incoming connections except allowed
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
    
    # Allow signed applications
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
    
    # Enable stealth mode
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
    
    # Enable logging
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
    
    # Add specific applications if needed
    configure_macos_app_firewall
    
    # Show current settings
    log_info "macOS firewall status:"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode
}

configure_macos_app_firewall() {
    # Allow specific applications through firewall
    local apps=(
        "/usr/libexec/sshd-keygen-wrapper"  # SSH
        "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/MacOS/ARDAgent"  # Remote Desktop
    )
    
    for app in "${apps[@]}"; do
        if [[ -f "$app" ]]; then
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$app"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$app"
        fi
    done
}

configure_environment_ports() {
    local fw_type=$1
    
    case "$DOTFILES_ENV" in
        desktop)
            # Desktop environment - allow more services
            allow_port "$fw_type" "5900/tcp" "VNC"
            allow_port "$fw_type" "3389/tcp" "RDP"
            ;;
        server)
            # Server environment - minimal ports
            # SSH already allowed
            ;;
        container)
            # Container environment - managed by container runtime
            log_debug "Container environment - firewall managed by runtime"
            ;;
    esac
}

configure_service_ports() {
    local fw_type=$1
    
    # Check for common services and allow if installed
    
    # Web server
    if command -v nginx &> /dev/null || command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        allow_port "$fw_type" "80/tcp" "HTTP"
        allow_port "$fw_type" "443/tcp" "HTTPS"
    fi
    
    # Database servers
    if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        # Only allow from localhost by default
        log_info "MySQL/MariaDB detected - configure access manually if needed"
    fi
    
    if command -v psql &> /dev/null; then
        # Only allow from localhost by default
        log_info "PostgreSQL detected - configure access manually if needed"
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        log_info "Docker detected - it manages its own firewall rules"
    fi
    
    # Kubernetes
    if command -v kubectl &> /dev/null; then
        # API server
        allow_port "$fw_type" "6443/tcp" "Kubernetes API"
    fi
}

allow_port() {
    local fw_type=$1
    local port=$2
    local comment=$3
    
    case "$fw_type" in
        ufw)
            sudo ufw allow "$port" comment "$comment"
            ;;
        firewalld)
            sudo firewall-cmd --permanent --add-port="$port"
            ;;
        iptables)
            # Would need to modify the rules file
            log_debug "Port $port ($comment) - configure manually for iptables"
            ;;
    esac
}

component_validate() {
    log_info "Validating firewall configuration..."
    
    local validation_failed=0
    
    case "$DOTFILES_OS" in
        linux)
            # Check which firewall is active
            if command -v ufw &> /dev/null && sudo ufw status &> /dev/null; then
                local ufw_status=$(sudo ufw status | head -1)
                if [[ "$ufw_status" =~ "active" ]]; then
                    log_success "UFW is active"
                else
                    log_info "UFW is installed but inactive"
                fi
            elif systemctl is-active firewalld &> /dev/null; then
                log_success "firewalld is active"
            elif command -v iptables &> /dev/null; then
                if sudo iptables -L -n | grep -q "Chain INPUT"; then
                    log_success "iptables rules are configured"
                else
                    log_warn "iptables present but no rules configured"
                fi
            else
                log_warn "No firewall is configured"
            fi
            ;;
        macos)
            if sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
                log_success "macOS firewall is enabled"
            else
                log_warn "macOS firewall is disabled"
            fi
            ;;
    esac
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "Firewall validation passed"
        return 0
    else
        log_error "Firewall validation failed"
        return 1
    fi
}

# Execute component if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize platform detection
    init_platform
    
    # Run component
    run_component
fi