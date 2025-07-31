#!/bin/bash
# core/system/timezone_config.sh - System timezone configuration

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="timezone_config"
COMPONENT_META[description]="System timezone configuration and NTP setup"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="core"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# Default timezone (can be overridden)
DEFAULT_TIMEZONE="${DOTFILES_TIMEZONE:-America/New_York}"

component_install() {
    log_info "Configuring system timezone..."
    
    # Detect current timezone
    local current_timezone=$(get_current_timezone)
    log_debug "Current timezone: $current_timezone"
    
    # Determine target timezone
    local target_timezone="${DOTFILES_TIMEZONE:-$DEFAULT_TIMEZONE}"
    log_info "Target timezone: $target_timezone"
    
    # Validate timezone
    if ! validate_timezone "$target_timezone"; then
        log_error "Invalid timezone: $target_timezone"
        return 1
    fi
    
    # Set timezone if different
    if [[ "$current_timezone" != "$target_timezone" ]]; then
        set_system_timezone "$target_timezone"
    else
        log_info "Timezone already set to: $target_timezone"
    fi
    
    # Configure NTP
    configure_ntp
    
    # Configure hardware clock
    configure_hardware_clock
    
    log_success "Timezone configuration completed"
}

get_current_timezone() {
    local timezone=""
    
    case "$DOTFILES_OS" in
        linux)
            if [[ -f /etc/timezone ]]; then
                timezone=$(cat /etc/timezone)
            elif command -v timedatectl &> /dev/null; then
                timezone=$(timedatectl show --property=Timezone --value 2>/dev/null)
            elif [[ -L /etc/localtime ]]; then
                timezone=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
            fi
            ;;
        macos)
            if command -v systemsetup &> /dev/null; then
                timezone=$(systemsetup -gettimezone 2>/dev/null | awk '{print $3}')
            fi
            ;;
    esac
    
    echo "${timezone:-UTC}"
}

validate_timezone() {
    local timezone=$1
    
    # Check if timezone exists in zoneinfo database
    case "$DOTFILES_OS" in
        linux)
            if [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
                return 0
            fi
            ;;
        macos)
            if [[ -f "/usr/share/zoneinfo/$timezone" ]] || \
               [[ -f "/var/db/timezone/zoneinfo/$timezone" ]]; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

set_system_timezone() {
    local timezone=$1
    
    log_info "Setting timezone to: $timezone"
    
    case "$DOTFILES_OS" in
        linux)
            set_linux_timezone "$timezone"
            ;;
        macos)
            set_macos_timezone "$timezone"
            ;;
    esac
}

set_linux_timezone() {
    local timezone=$1
    
    # Try using timedatectl first (systemd systems)
    if command -v timedatectl &> /dev/null; then
        sudo timedatectl set-timezone "$timezone" || {
            log_error "Failed to set timezone using timedatectl"
            return 1
        }
        log_debug "Timezone set using timedatectl"
        return 0
    fi
    
    # Fall back to manual configuration
    # Set /etc/timezone
    echo "$timezone" | sudo tee /etc/timezone > /dev/null
    
    # Update /etc/localtime
    sudo rm -f /etc/localtime
    sudo ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
    
    # Reconfigure tzdata if available
    if command -v dpkg-reconfigure &> /dev/null; then
        sudo dpkg-reconfigure -f noninteractive tzdata
    fi
    
    log_debug "Timezone set manually"
}

set_macos_timezone() {
    local timezone=$1
    
    if command -v systemsetup &> /dev/null; then
        sudo systemsetup -settimezone "$timezone" || {
            log_error "Failed to set timezone"
            return 1
        }
    else
        log_error "systemsetup command not found"
        return 1
    fi
    
    log_debug "Timezone set using systemsetup"
}

configure_ntp() {
    log_info "Configuring NTP time synchronization..."
    
    case "$DOTFILES_OS" in
        linux)
            configure_linux_ntp
            ;;
        macos)
            configure_macos_ntp
            ;;
    esac
}

configure_linux_ntp() {
    # Check for systemd-timesyncd (modern systems)
    if command -v timedatectl &> /dev/null; then
        # Enable NTP synchronization
        sudo timedatectl set-ntp true || {
            log_warn "Failed to enable NTP synchronization"
        }
        
        # Check NTP status
        local ntp_status=$(timedatectl show --property=NTP --value)
        if [[ "$ntp_status" == "yes" ]]; then
            log_debug "NTP synchronization enabled via systemd-timesyncd"
        fi
        
        # Configure NTP servers if needed
        configure_systemd_timesyncd
        
    # Check for chrony (modern alternative to ntpd)
    elif command -v chronyd &> /dev/null; then
        configure_chrony
        
    # Check for traditional ntpd
    elif command -v ntpd &> /dev/null; then
        configure_ntpd
        
    else
        log_warn "No NTP service found. Time synchronization may not be configured."
        
        # Try to install a time sync service
        case "$DOTFILES_DISTRO" in
            ubuntu|debian)
                install_package systemd-timesyncd || install_package chrony
                ;;
            fedora|centos|rhel)
                install_package chrony
                ;;
            arch)
                install_package ntp
                ;;
        esac
    fi
}

configure_systemd_timesyncd() {
    local config_file="/etc/systemd/timesyncd.conf"
    local config_dir="/etc/systemd/timesyncd.conf.d"
    
    # Create drop-in directory
    sudo mkdir -p "$config_dir"
    
    # Create custom configuration
    cat << 'EOF' | sudo tee "$config_dir/10-dotfiles.conf" > /dev/null
# Dotfiles NTP configuration
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
FallbackNTP=time.google.com time.cloudflare.com
EOF
    
    # Restart timesyncd
    manage_service restart systemd-timesyncd
    
    log_debug "Configured systemd-timesyncd"
}

configure_chrony() {
    local config_file="/etc/chrony/chrony.conf"
    
    if [[ -f "$config_file" ]]; then
        # Check if our servers are already configured
        if ! grep -q "# Dotfiles NTP servers" "$config_file"; then
            # Add our NTP servers
            cat << 'EOF' | sudo tee -a "$config_file" > /dev/null

# Dotfiles NTP servers
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst
EOF
        fi
        
        # Enable and start chrony
        manage_service enable chronyd
        manage_service start chronyd
        
        log_debug "Configured chrony"
    fi
}

configure_ntpd() {
    local config_file="/etc/ntp.conf"
    
    if [[ -f "$config_file" ]]; then
        # Backup original config
        sudo cp "$config_file" "$config_file.backup"
        
        # Check if our servers are already configured
        if ! grep -q "# Dotfiles NTP servers" "$config_file"; then
            # Add our NTP servers
            cat << 'EOF' | sudo tee -a "$config_file" > /dev/null

# Dotfiles NTP servers
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst
EOF
        fi
        
        # Enable and start ntpd
        manage_service enable ntpd
        manage_service start ntpd
        
        log_debug "Configured ntpd"
    fi
}

configure_macos_ntp() {
    # macOS uses timed for NTP synchronization
    # Check if automatic time is enabled
    local auto_time=$(systemsetup -getusingnetworktime 2>/dev/null | awk '{print $3}')
    
    if [[ "$auto_time" != "On" ]]; then
        log_info "Enabling automatic time synchronization..."
        sudo systemsetup -setusingnetworktime on
    else
        log_debug "Automatic time synchronization already enabled"
    fi
    
    # Set NTP server (optional)
    local current_server=$(systemsetup -getnetworktimeserver 2>/dev/null | awk '{print $4}')
    local target_server="time.apple.com"
    
    if [[ "$current_server" != "$target_server" ]]; then
        sudo systemsetup -setnetworktimeserver "$target_server" || {
            log_warn "Failed to set NTP server"
        }
    fi
}

configure_hardware_clock() {
    log_info "Configuring hardware clock..."
    
    case "$DOTFILES_OS" in
        linux)
            if command -v hwclock &> /dev/null; then
                # Sync system time to hardware clock
                sudo hwclock --systohc || {
                    log_warn "Failed to sync hardware clock"
                }
                
                # Set hardware clock to UTC (recommended)
                if command -v timedatectl &> /dev/null; then
                    sudo timedatectl set-local-rtc 0 || {
                        log_warn "Failed to set RTC to UTC"
                    }
                    log_debug "Hardware clock set to UTC"
                fi
            fi
            ;;
        macos)
            # macOS handles this automatically
            log_debug "Hardware clock managed by macOS"
            ;;
    esac
}

component_validate() {
    log_info "Validating timezone configuration..."
    
    local validation_failed=0
    
    # Check current timezone
    local current_timezone=$(get_current_timezone)
    if [[ -z "$current_timezone" ]] || [[ "$current_timezone" == "UTC" ]]; then
        log_warn "Timezone not configured or set to UTC"
    else
        log_debug "Current timezone: $current_timezone"
    fi
    
    # Check NTP synchronization
    case "$DOTFILES_OS" in
        linux)
            if command -v timedatectl &> /dev/null; then
                local ntp_status=$(timedatectl show --property=NTP --value 2>/dev/null)
                if [[ "$ntp_status" == "yes" ]]; then
                    log_debug "NTP synchronization enabled"
                else
                    log_warn "NTP synchronization not enabled"
                fi
            elif pgrep -x "chronyd|ntpd" > /dev/null; then
                log_debug "NTP service running"
            else
                log_warn "No NTP service detected"
            fi
            ;;
        macos)
            local auto_time=$(systemsetup -getusingnetworktime 2>/dev/null | awk '{print $3}')
            if [[ "$auto_time" == "On" ]]; then
                log_debug "Automatic time synchronization enabled"
            else
                log_warn "Automatic time synchronization disabled"
            fi
            ;;
    esac
    
    # Check time accuracy
    if command -v ntpdate &> /dev/null; then
        # Check time offset (informational only)
        local offset=$(ntpdate -q pool.ntp.org 2>/dev/null | grep "offset" | awk '{print $6}' | head -1)
        if [[ -n "$offset" ]]; then
            log_debug "Time offset from NTP: $offset seconds"
        fi
    fi
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "Timezone configuration validation passed"
        return 0
    else
        log_error "Timezone configuration validation failed"
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