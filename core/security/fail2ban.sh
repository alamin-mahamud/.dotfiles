#!/bin/bash
# core/security/fail2ban.sh - Intrusion prevention with fail2ban

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="fail2ban"
COMPONENT_META[description]="Intrusion prevention system using fail2ban"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="security"
COMPONENT_META[platforms]="linux"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# Fail2ban configuration paths
FAIL2BAN_CONFIG_DIR="/etc/fail2ban"
FAIL2BAN_JAIL_LOCAL="$FAIL2BAN_CONFIG_DIR/jail.local"
FAIL2BAN_JAIL_D="$FAIL2BAN_CONFIG_DIR/jail.d"

component_install() {
    log_info "Setting up fail2ban intrusion prevention..."
    
    # Check if we're on a supported platform
    if [[ "$DOTFILES_OS" != "linux" ]]; then
        log_info "fail2ban is only supported on Linux"
        return 0
    fi
    
    # Check for container environment
    if [[ "$DOTFILES_ENV" == "container" ]]; then
        log_info "Skipping fail2ban in container environment"
        return 0
    fi
    
    # Install fail2ban if not present
    if ! command -v fail2ban-server &> /dev/null; then
        install_fail2ban || return 1
    fi
    
    # Configure fail2ban
    configure_fail2ban
    
    # Set up custom jails
    setup_jails
    
    # Start and enable fail2ban
    start_fail2ban
    
    log_success "fail2ban configuration completed"
}

install_fail2ban() {
    log_info "Installing fail2ban..."
    
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            install_package fail2ban
            install_package python3-pyinotify  # For better performance
            install_package python3-systemd    # For systemd journal support
            ;;
        fedora|centos|rhel)
            install_package fail2ban
            install_package fail2ban-systemd
            ;;
        arch)
            install_package fail2ban
            ;;
        *)
            log_error "fail2ban installation not supported on $DOTFILES_DISTRO"
            return 1
            ;;
    esac
}

configure_fail2ban() {
    log_info "Configuring fail2ban..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for fail2ban configuration"
        return 0
    fi
    
    # Create jail.local with base configuration
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_LOCAL" > /dev/null
# Fail2Ban jail configuration - Managed by dotfiles
# This file overrides settings in jail.conf

[DEFAULT]
# Ban time and retry settings
bantime  = 1h
findtime = 10m
maxretry = 5

# Ban time increments for repeat offenders
bantime.increment = true
bantime.factor = 1
bantime.formula = ban.Time * (1<<(ban.Count if ban.Count<20 else 20)) * banFactor
bantime.multipliers = 1 2 4 8 16 32 64
bantime.maxtime = 4w
bantime.overalljails = false

# Miscellaneous options
ignoreip = 127.0.0.1/8 ::1
ignoreself = true

# Email notifications (configure if needed)
destemail = root@localhost
sender = root@localhost
mta = sendmail

# Action to take when banning
action = %(action_mwl)s

# Backend for monitoring logs
backend = auto

# Logging
loglevel = INFO
logtarget = /var/log/fail2ban.log

# Socket location
socket = /var/run/fail2ban/fail2ban.sock

# PID file
pidfile = /var/run/fail2ban/fail2ban.pid

# Database for persistent bans
dbfile = /var/lib/fail2ban/fail2ban.sqlite3
dbpurgeage = 1d
EOF
    
    # Create jail.d directory for custom jails
    sudo mkdir -p "$FAIL2BAN_JAIL_D"
}

setup_jails() {
    log_info "Setting up fail2ban jails..."
    
    # SSH jail (enhanced)
    setup_ssh_jail
    
    # Set up additional jails based on installed services
    
    # Nginx
    if command -v nginx &> /dev/null; then
        setup_nginx_jails
    fi
    
    # Apache
    if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        setup_apache_jails
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        setup_docker_jail
    fi
    
    # Mail servers
    if command -v postfix &> /dev/null; then
        setup_postfix_jail
    fi
    
    # Custom application jails
    setup_custom_jails
}

setup_ssh_jail() {
    log_info "Setting up SSH jail..."
    
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_D/sshd.conf" > /dev/null
# SSH jail configuration
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 4h
findtime = 10m

# Aggressive mode for repeat offenders
[sshd-aggressive]
enabled = true
port = ssh
filter = sshd[mode=aggressive]
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 2
bantime = 1d
findtime = 1d

# DDoS protection
[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 10
bantime = 1w
findtime = 1m
EOF
    
    # Create custom filter for SSH DDoS
    cat << 'EOF' | sudo tee "$FAIL2BAN_CONFIG_DIR/filter.d/sshd-ddos.conf" > /dev/null
# SSH DDoS filter
[Definition]
failregex = ^%(__prefix_line)sDid not receive identification string from <HOST>
            ^%(__prefix_line)sConnection closed by <HOST> port \d+ \[preauth\]$
            ^%(__prefix_line)sConnection reset by <HOST> port \d+ \[preauth\]$
            ^%(__prefix_line)sReceived disconnect from <HOST> port \d+:\d+: .*\[preauth\]$
ignoreregex =
EOF
}

setup_nginx_jails() {
    log_info "Setting up Nginx jails..."
    
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_D/nginx.conf" > /dev/null
# Nginx jail configurations

# Basic auth failures
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/*error.log
maxretry = 3
bantime = 1h

# 404 errors (potential scanners)
[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/*access.log
maxretry = 10
bantime = 1h
findtime = 1m

# Request limit exceeded
[nginx-req-limit]
enabled = true
filter = nginx-req-limit
port = http,https
logpath = /var/log/nginx/*error.log
maxretry = 5
bantime = 1h
findtime = 1m

# Bad bots
[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/*access.log
maxretry = 2
bantime = 1d
findtime = 1d
EOF
    
    # Create bad bots filter
    cat << 'EOF' | sudo tee "$FAIL2BAN_CONFIG_DIR/filter.d/nginx-badbots.conf" > /dev/null
# Nginx bad bots filter
[Definition]
badbots = Aggressive|360Spider|AhrefsBot|Baiduspider|DotBot|EasouSpider|Exabot|Gigabot|MJ12bot|SemrushBot|YandexBot|ZoominfoBot
failregex = ^<HOST> .* "(GET|POST|HEAD).*" .* ".*(?:%(badbots)s).*"$
ignoreregex =
EOF
}

setup_apache_jails() {
    log_info "Setting up Apache jails..."
    
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_D/apache.conf" > /dev/null
# Apache jail configurations

# Auth failures
[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache*/*error.log
maxretry = 3
bantime = 1h

# Overflows
[apache-overflows]
enabled = true
port = http,https
filter = apache-overflows
logpath = /var/log/apache*/*error.log
maxretry = 2
bantime = 1d

# 404 scan
[apache-noscript]
enabled = true
port = http,https
filter = apache-noscript
logpath = /var/log/apache*/*access.log
maxretry = 10
bantime = 1h
findtime = 1m

# Bad bots
[apache-badbots]
enabled = true
port = http,https
filter = apache-badbots
logpath = /var/log/apache*/*access.log
maxretry = 2
bantime = 1d
EOF
}

setup_docker_jail() {
    log_info "Setting up Docker jail..."
    
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_D/docker.conf" > /dev/null
# Docker unauthorized access attempts
[docker-auth]
enabled = true
filter = docker-auth
port = 2375,2376
logpath = /var/log/docker.log
         /var/log/syslog
maxretry = 3
bantime = 1h
EOF
    
    # Create Docker filter
    cat << 'EOF' | sudo tee "$FAIL2BAN_CONFIG_DIR/filter.d/docker-auth.conf" > /dev/null
# Docker authentication failures
[Definition]
failregex = .*authentication failure.*dockerd.*<HOST>
            .*Failed to authenticate.*<HOST>
ignoreregex =
EOF
}

setup_postfix_jail() {
    log_info "Setting up Postfix jail..."
    
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_D/postfix.conf" > /dev/null
# Postfix/SMTP jails

[postfix]
enabled = true
port = smtp,ssmtp,submission
filter = postfix
logpath = /var/log/mail.log
maxretry = 3
bantime = 1h

[postfix-sasl]
enabled = true
port = smtp,ssmtp,submission,imap,imaps,pop3,pop3s
filter = postfix-sasl
logpath = /var/log/mail.log
maxretry = 3
bantime = 1h
EOF
}

setup_custom_jails() {
    log_info "Setting up custom application jails..."
    
    # Create a template for custom jails
    cat << 'EOF' | sudo tee "$FAIL2BAN_JAIL_D/custom-template.conf.disabled" > /dev/null
# Custom jail template - rename to .conf and modify as needed

# Example: Custom web application
#[webapp-auth]
#enabled = true
#port = 8080
#filter = webapp-auth
#logpath = /var/log/webapp/auth.log
#maxretry = 5
#bantime = 1h
#findtime = 10m

# Create corresponding filter in /etc/fail2ban/filter.d/webapp-auth.conf:
# [Definition]
# failregex = ^.*Failed login attempt from <HOST>.*$
# ignoreregex =
EOF
}

start_fail2ban() {
    log_info "Starting fail2ban service..."
    
    # Enable fail2ban service
    manage_service enable fail2ban
    
    # Start/restart fail2ban
    manage_service restart fail2ban
    
    # Wait a moment for service to start
    sleep 2
    
    # Check status
    if systemctl is-active fail2ban &> /dev/null || service fail2ban status &> /dev/null; then
        log_success "fail2ban is running"
        
        # Show active jails
        if command -v fail2ban-client &> /dev/null; then
            log_info "Active jails:"
            sudo fail2ban-client status | grep "Jail list" || true
        fi
    else
        log_error "fail2ban failed to start"
        return 1
    fi
}

component_validate() {
    log_info "Validating fail2ban configuration..."
    
    local validation_failed=0
    
    # Check if fail2ban is installed
    if ! command -v fail2ban-server &> /dev/null; then
        log_error "fail2ban is not installed"
        ((validation_failed++))
    fi
    
    # Check if service is running
    if systemctl is-active fail2ban &> /dev/null || service fail2ban status &> /dev/null; then
        log_success "fail2ban service is active"
    else
        log_error "fail2ban service is not running"
        ((validation_failed++))
    fi
    
    # Validate configuration
    if command -v fail2ban-client &> /dev/null && has_sudo; then
        if sudo fail2ban-client -t &> /dev/null; then
            log_success "fail2ban configuration is valid"
        else
            log_error "fail2ban configuration has errors"
            ((validation_failed++))
        fi
        
        # Check active jails
        local jail_count=$(sudo fail2ban-client status | grep -c "Number of jail" || echo "0")
        if [[ $jail_count -gt 0 ]]; then
            log_success "fail2ban has active jails"
        else
            log_warn "No active fail2ban jails"
        fi
    fi
    
    # Check log file
    if [[ -f /var/log/fail2ban.log ]]; then
        log_debug "fail2ban log file exists"
    else
        log_warn "fail2ban log file not found"
    fi
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "fail2ban validation passed"
        return 0
    else
        log_error "fail2ban validation failed"
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