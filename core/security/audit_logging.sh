#!/bin/bash
# core/security/audit_logging.sh - System audit and logging configuration

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="audit_logging"
COMPONENT_META[description]="System audit logging and monitoring configuration"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="security"
COMPONENT_META[platforms]="linux"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# Audit configuration paths
AUDITD_CONFIG="/etc/audit/auditd.conf"
AUDIT_RULES="/etc/audit/rules.d/dotfiles-audit.rules"
RSYSLOG_CONFIG="/etc/rsyslog.d/50-dotfiles-security.conf"

component_install() {
    log_info "Configuring audit logging..."
    
    # Check if we're on a supported platform
    if [[ "$DOTFILES_OS" != "linux" ]]; then
        log_info "Audit logging is only supported on Linux"
        return 0
    fi
    
    # Skip in container environments
    if [[ "$DOTFILES_ENV" == "container" ]]; then
        log_info "Skipping audit logging in container environment"
        return 0
    fi
    
    # Configure based on available audit systems
    local configured=false
    
    # Configure auditd if available or install it
    if command -v auditctl &> /dev/null || install_auditd; then
        configure_auditd
        configured=true
    fi
    
    # Configure rsyslog for security logging
    if command -v rsyslogd &> /dev/null; then
        configure_rsyslog
        configured=true
    fi
    
    # Configure systemd journal security
    if command -v journalctl &> /dev/null; then
        configure_systemd_journal
        configured=true
    fi
    
    if [[ "$configured" == "false" ]]; then
        log_warn "No audit logging system could be configured"
        return 0
    fi
    
    log_success "Audit logging configuration completed"
}

install_auditd() {
    log_info "Installing auditd..."
    
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            install_package auditd
            install_package audispd-plugins
            ;;
        fedora|centos|rhel)
            install_package audit
            install_package audit-libs
            ;;
        arch)
            install_package audit
            ;;
        *)
            log_error "auditd installation not supported on $DOTFILES_DISTRO"
            return 1
            ;;
    esac
}

configure_auditd() {
    log_info "Configuring auditd..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for auditd configuration"
        return 0
    fi
    
    # Create audit rules directory
    sudo mkdir -p /etc/audit/rules.d
    
    # Create comprehensive audit rules
    cat << 'EOF' | sudo tee "$AUDIT_RULES" > /dev/null
# Audit rules for security monitoring - Managed by dotfiles

# Remove any existing rules
-D

# Buffer size
-b 8192

# Failure mode (1 = printk, 2 = panic)
-f 1

# System calls audit
# Unauthorized file access attempts
-a always,exit -F arch=b64 -S open,openat -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access_denied
-a always,exit -F arch=b64 -S open,openat -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access_denied

# File deletion
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=4294967295 -k file_deletion

# Admin commands
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k sudo_commands
-a always,exit -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k su_commands

# System configuration changes
-w /etc/passwd -p wa -k identity_changes
-w /etc/group -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/gshadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes

# SSH configuration
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/ssh/sshd_config.d/ -p wa -k ssh_config

# System executables
-w /usr/bin/ -p wa -k system_executables
-w /usr/sbin/ -p wa -k system_executables

# Kernel modules
-w /sbin/insmod -p x -k kernel_modules
-w /sbin/rmmod -p x -k kernel_modules
-w /sbin/modprobe -p x -k kernel_modules
-a always,exit -F arch=b64 -S init_module,delete_module -k kernel_modules

# Network configuration
-a always,exit -F arch=b64 -S setsockopt,connect,accept,bind -F auid>=1000 -F auid!=4294967295 -k network_changes
-w /etc/hosts -p wa -k network_config
-w /etc/network/ -p wa -k network_config
-w /etc/netplan/ -p wa -k network_config

# Process tracking
-a always,exit -F arch=b64 -S kill -F a1!=0 -k process_kill
-a always,exit -F arch=b64 -S ptrace -k process_trace

# Time changes
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time_change
-a always,exit -F arch=b64 -S clock_settime -F a0=0 -k time_change

# Cron configuration
-w /etc/cron.allow -p wa -k cron_config
-w /etc/cron.deny -p wa -k cron_config
-w /etc/cron.d/ -p wa -k cron_config
-w /etc/cron.daily/ -p wa -k cron_config
-w /etc/cron.hourly/ -p wa -k cron_config
-w /etc/cron.monthly/ -p wa -k cron_config
-w /etc/cron.weekly/ -p wa -k cron_config
-w /etc/crontab -p wa -k cron_config
-w /var/spool/cron/ -p wa -k cron_config

# Login/Logout events
-w /var/log/faillog -p wa -k login_failures
-w /var/log/lastlog -p wa -k login_records
-w /var/log/tallylog -p wa -k login_failures

# Make configuration immutable
-e 2
EOF
    
    # Configure auditd.conf for better performance and retention
    if [[ -f "$AUDITD_CONFIG" ]]; then
        sudo cp "$AUDITD_CONFIG" "$AUDITD_CONFIG.backup"
        
        # Update key settings
        sudo sed -i 's/^num_logs =.*/num_logs = 5/' "$AUDITD_CONFIG"
        sudo sed -i 's/^max_log_file =.*/max_log_file = 100/' "$AUDITD_CONFIG"
        sudo sed -i 's/^max_log_file_action =.*/max_log_file_action = ROTATE/' "$AUDITD_CONFIG"
        sudo sed -i 's/^space_left =.*/space_left = 1000/' "$AUDITD_CONFIG"
        sudo sed -i 's/^space_left_action =.*/space_left_action = SYSLOG/' "$AUDITD_CONFIG"
        sudo sed -i 's/^admin_space_left =.*/admin_space_left = 500/' "$AUDITD_CONFIG"
        sudo sed -i 's/^admin_space_left_action =.*/admin_space_left_action = SUSPEND/' "$AUDITD_CONFIG"
        sudo sed -i 's/^disk_full_action =.*/disk_full_action = SUSPEND/' "$AUDITD_CONFIG"
        sudo sed -i 's/^disk_error_action =.*/disk_error_action = SUSPEND/' "$AUDITD_CONFIG"
    fi
    
    # Enable and restart auditd
    manage_service enable auditd
    manage_service restart auditd
    
    # Load rules
    if command -v augenrules &> /dev/null; then
        sudo augenrules --load
    elif command -v auditctl &> /dev/null; then
        sudo auditctl -R "$AUDIT_RULES"
    fi
}

configure_rsyslog() {
    log_info "Configuring rsyslog for security logging..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for rsyslog configuration"
        return 0
    fi
    
    # Create rsyslog configuration for security events
    cat << 'EOF' | sudo tee "$RSYSLOG_CONFIG" > /dev/null
# Security logging configuration - Managed by dotfiles

# Create separate log files for security events
# Authentication messages
auth,authpriv.*                 /var/log/auth.log

# Sudo logs
:programname, isequal, "sudo"   /var/log/sudo.log
& stop

# SSH logs
:programname, isequal, "sshd"   /var/log/ssh.log
& stop

# Kernel messages
kern.*                          /var/log/kern.log

# Security audit logs
:msg, contains, "audit:"        /var/log/audit-syslog.log
& stop

# Failed login attempts
:msg, contains, "authentication failure"  /var/log/auth-failures.log
:msg, contains, "Failed password"         /var/log/auth-failures.log
& stop

# System changes
:msg, contains, "password changed"        /var/log/system-changes.log
:msg, contains, "user added"              /var/log/system-changes.log
:msg, contains, "group added"             /var/log/system-changes.log
& stop
EOF
    
    # Create log rotation configuration
    cat << 'EOF' | sudo tee /etc/logrotate.d/dotfiles-security > /dev/null
/var/log/auth.log
/var/log/sudo.log
/var/log/ssh.log
/var/log/kern.log
/var/log/audit-syslog.log
/var/log/auth-failures.log
/var/log/system-changes.log
{
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 syslog adm
    sharedscripts
    postrotate
        /usr/bin/systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
    
    # Restart rsyslog
    manage_service restart rsyslog
}

configure_systemd_journal() {
    log_info "Configuring systemd journal for security..."
    
    if ! has_sudo; then
        log_warn "Sudo access required for systemd journal configuration"
        return 0
    fi
    
    # Create journal configuration directory
    sudo mkdir -p /etc/systemd/journald.conf.d
    
    # Configure journal for security logging
    cat << 'EOF' | sudo tee /etc/systemd/journald.conf.d/security.conf > /dev/null
# Systemd journal security configuration - Managed by dotfiles
[Journal]
# Storage
Storage=persistent
Compress=yes
Seal=yes

# Retention
SystemMaxUse=1G
SystemMaxFileSize=100M
MaxRetentionSec=90d

# Forward to syslog for additional processing
ForwardToSyslog=yes

# Rate limiting (prevent log flooding)
RateLimitIntervalSec=30s
RateLimitBurst=10000

# Audit fields
Audit=yes
EOF
    
    # Create script for security event monitoring
    cat << 'EOF' | sudo tee /usr/local/bin/security-journal-monitor > /dev/null
#!/bin/bash
# Monitor journal for security events

# Failed authentication attempts
echo "=== Recent Authentication Failures ==="
journalctl -p warning -t sshd -t sudo -t su --since "1 hour ago" | grep -i "fail\|error\|invalid"

# Successful sudo usage
echo -e "\n=== Recent Sudo Usage ==="
journalctl -t sudo --since "1 hour ago" | grep "COMMAND"

# SSH connections
echo -e "\n=== Recent SSH Connections ==="
journalctl -t sshd --since "1 hour ago" | grep "Accepted\|Failed"

# System changes
echo -e "\n=== Recent System Changes ==="
journalctl --since "1 hour ago" | grep -E "(password changed|user added|group added|systemctl)"
EOF
    
    sudo chmod +x /usr/local/bin/security-journal-monitor
    
    # Restart systemd-journald
    manage_service restart systemd-journald
}

component_validate() {
    log_info "Validating audit logging configuration..."
    
    local validation_failed=0
    
    # Check auditd
    if command -v auditctl &> /dev/null; then
        if systemctl is-active auditd &> /dev/null || service auditd status &> /dev/null; then
            log_success "auditd is active"
            
            # Check if rules are loaded
            local rule_count=$(sudo auditctl -l | grep -c "^-" || echo "0")
            if [[ $rule_count -gt 0 ]]; then
                log_success "Audit rules are loaded ($rule_count rules)"
            else
                log_warn "No audit rules loaded"
            fi
        else
            log_warn "auditd is installed but not running"
        fi
    else
        log_info "auditd not installed"
    fi
    
    # Check rsyslog
    if command -v rsyslogd &> /dev/null; then
        if systemctl is-active rsyslog &> /dev/null || service rsyslog status &> /dev/null; then
            log_success "rsyslog is active"
        else
            log_warn "rsyslog is installed but not running"
        fi
    fi
    
    # Check systemd journal
    if command -v journalctl &> /dev/null; then
        if journalctl --verify &> /dev/null; then
            log_success "systemd journal is functioning"
        else
            log_warn "systemd journal has issues"
        fi
    fi
    
    # Check log files exist
    local important_logs=(
        "/var/log/auth.log"
        "/var/log/syslog"
        "/var/log/kern.log"
    )
    
    for logfile in "${important_logs[@]}"; do
        if [[ -f "$logfile" ]]; then
            log_debug "Found log file: $logfile"
        else
            log_debug "Log file not found: $logfile (may be normal)"
        fi
    done
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "Audit logging validation passed"
        return 0
    else
        log_error "Audit logging validation failed"
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