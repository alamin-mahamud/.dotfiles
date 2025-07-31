#!/bin/bash
# core/system/user_management.sh - User and group management

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="user_management"
COMPONENT_META[description]="User configuration and group management"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="core"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

component_install() {
    log_info "Configuring user management..."
    
    # Get current user information
    local current_user="$USER"
    local current_uid=$(id -u)
    local current_gid=$(id -g)
    local home_dir="$HOME"
    
    log_debug "Current user: $current_user (UID: $current_uid, GID: $current_gid)"
    log_debug "Home directory: $home_dir"
    
    # Configure user groups
    configure_user_groups
    
    # Set up sudo configuration
    configure_sudo_access
    
    # Configure shell
    configure_user_shell
    
    # Set up user directories
    setup_user_directories
    
    # Configure user environment
    configure_user_environment
    
    log_success "User management configuration completed"
}

configure_user_groups() {
    log_info "Configuring user groups..."
    
    case "$DOTFILES_OS" in
        linux)
            configure_linux_groups
            ;;
        macos)
            configure_macos_groups
            ;;
    esac
}

configure_linux_groups() {
    # Common development groups
    local dev_groups="docker lxd kvm libvirt"
    
    # System administration groups
    local admin_groups="sudo adm systemd-journal"
    
    # Hardware access groups
    local hw_groups="dialout plugdev"
    
    # All groups to check
    local all_groups="$admin_groups $dev_groups $hw_groups"
    
    for group in $all_groups; do
        # Check if group exists
        if getent group "$group" &> /dev/null; then
            # Check if user is already in group
            if ! groups "$USER" | grep -q "\b$group\b"; then
                log_info "Adding user to group: $group"
                sudo usermod -aG "$group" "$USER" || {
                    log_warn "Failed to add user to group: $group"
                }
            else
                log_debug "User already in group: $group"
            fi
        else
            log_debug "Group does not exist: $group"
        fi
    done
    
    # Distribution-specific groups
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            # Debian-based specific groups
            check_and_add_group "netdev"
            ;;
        fedora|centos|rhel)
            # Red Hat-based specific groups
            check_and_add_group "wheel"
            ;;
        arch)
            # Arch-specific groups
            check_and_add_group "wheel"
            check_and_add_group "uucp"  # For serial port access
            ;;
    esac
    
    log_info "Note: You may need to log out and back in for group changes to take effect"
}

configure_macos_groups() {
    # macOS uses different group management
    log_info "Checking macOS group memberships..."
    
    # Check admin group
    if ! dscl . -read /Groups/admin | grep -q "$USER"; then
        log_warn "User is not in admin group. Some operations may require admin access."
    else
        log_debug "User is in admin group"
    fi
    
    # Check staff group
    if ! dscl . -read /Groups/staff | grep -q "$USER"; then
        log_warn "User is not in staff group"
    else
        log_debug "User is in staff group"
    fi
}

check_and_add_group() {
    local group=$1
    
    if getent group "$group" &> /dev/null; then
        if ! groups "$USER" | grep -q "\b$group\b"; then
            sudo usermod -aG "$group" "$USER" || {
                log_warn "Failed to add user to group: $group"
            }
        fi
    fi
}

configure_sudo_access() {
    log_info "Configuring sudo access..."
    
    # Check if user has sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "User does not have passwordless sudo access"
        
        # Create sudoers.d entry for package management (if requested)
        if [[ "${DOTFILES_PASSWORDLESS_SUDO:-false}" == "true" ]]; then
            configure_passwordless_sudo
        fi
    else
        log_debug "User has sudo access"
    fi
    
    # Configure sudo settings
    configure_sudo_settings
}

configure_passwordless_sudo() {
    log_info "Configuring passwordless sudo for package management..."
    
    local sudoers_file="/etc/sudoers.d/99-dotfiles-$USER"
    local sudo_content=""
    
    case "$DOTFILES_OS" in
        linux)
            case "$DOTFILES_DISTRO" in
                ubuntu|debian)
                    sudo_content="$USER ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/dpkg, /usr/bin/snap"
                    ;;
                fedora|centos|rhel)
                    sudo_content="$USER ALL=(ALL) NOPASSWD: /usr/bin/dnf, /usr/bin/yum, /usr/bin/rpm"
                    ;;
                arch)
                    sudo_content="$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/yay, /usr/bin/makepkg"
                    ;;
            esac
            ;;
        macos)
            sudo_content="$USER ALL=(ALL) NOPASSWD: /usr/bin/softwareupdate"
            ;;
    esac
    
    if [[ -n "$sudo_content" ]]; then
        echo "$sudo_content" | sudo tee "$sudoers_file" > /dev/null
        sudo chmod 440 "$sudoers_file"
        log_success "Passwordless sudo configured for package management"
    fi
}

configure_sudo_settings() {
    # Configure sudo to preserve certain environment variables
    local sudo_env_file="/etc/sudoers.d/98-dotfiles-env"
    
    if [[ ! -f "$sudo_env_file" ]]; then
        cat << 'EOF' | sudo tee "$sudo_env_file" > /dev/null
# Preserve environment variables for dotfiles
Defaults env_keep += "DOTFILES_ROOT DOTFILES_OS DOTFILES_ENV DOTFILES_DISTRO"
Defaults env_keep += "LANG LC_* LANGUAGE"
Defaults env_keep += "HOME USER LOGNAME"
EOF
        sudo chmod 440 "$sudo_env_file"
        log_debug "Sudo environment preservation configured"
    fi
}

configure_user_shell() {
    log_info "Configuring user shell..."
    
    local current_shell=$(basename "$SHELL")
    log_debug "Current shell: $current_shell"
    
    # Check if zsh is available and set as default
    if command -v zsh &> /dev/null; then
        local zsh_path=$(command -v zsh)
        
        # Check if zsh is in /etc/shells
        if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
            log_info "Adding zsh to /etc/shells"
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
        fi
        
        # Set zsh as default shell if not already
        if [[ "$current_shell" != "zsh" ]]; then
            if [[ "${DOTFILES_CHANGE_SHELL:-true}" == "true" ]]; then
                log_info "Changing default shell to zsh"
                if [[ "$DOTFILES_OS" == "macos" ]]; then
                    chsh -s "$zsh_path" "$USER"
                else
                    sudo chsh -s "$zsh_path" "$USER"
                fi
                log_success "Default shell changed to zsh"
                log_info "Please log out and back in for the change to take effect"
            else
                log_info "Zsh available but not setting as default (DOTFILES_CHANGE_SHELL=false)"
            fi
        else
            log_debug "Zsh is already the default shell"
        fi
    else
        log_warn "Zsh not found. Install zsh for better shell experience"
    fi
}

setup_user_directories() {
    log_info "Setting up user directories..."
    
    # Standard XDG directories
    local xdg_dirs=(
        "$HOME/.config"
        "$HOME/.cache"
        "$HOME/.local/share"
        "$HOME/.local/state"
        "$HOME/.local/bin"
    )
    
    # Development directories
    local dev_dirs=(
        "$HOME/Work"
        "$HOME/Work/projects"
        "$HOME/Work/scratch"
        "$HOME/.ssh"
    )
    
    # Create all directories
    local dir
    for dir in "${xdg_dirs[@]}" "${dev_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "Created directory: $dir"
        fi
    done
    
    # Set appropriate permissions
    chmod 700 "$HOME/.ssh" 2>/dev/null || true
    chmod 755 "$HOME/.local/bin" 2>/dev/null || true
    
    # Create common config subdirectories
    local config_dirs=(
        "$HOME/.config/git"
        "$HOME/.config/systemd/user"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "Created config directory: $dir"
        fi
    done
}

configure_user_environment() {
    log_info "Configuring user environment..."
    
    # Create or update .profile for environment variables
    local profile_file="$HOME/.profile"
    local profile_marker="# Dotfiles environment configuration"
    
    # Check if we've already configured the profile
    if ! grep -q "$profile_marker" "$profile_file" 2>/dev/null; then
        log_debug "Adding dotfiles environment to .profile"
        
        cat >> "$profile_file" << EOF

$profile_marker
# Added by dotfiles user_management component

# XDG Base Directory Specification
export XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-\$HOME/.config}"
export XDG_CACHE_HOME="\${XDG_CACHE_HOME:-\$HOME/.cache}"
export XDG_DATA_HOME="\${XDG_DATA_HOME:-\$HOME/.local/share}"
export XDG_STATE_HOME="\${XDG_STATE_HOME:-\$HOME/.local/state}"

# Add user's private bin to PATH
if [ -d "\$HOME/.local/bin" ] && [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
    PATH="\$HOME/.local/bin:\$PATH"
fi

# Set default editor
export EDITOR="\${EDITOR:-vim}"
export VISUAL="\${VISUAL:-\$EDITOR}"

# Set default pager
export PAGER="\${PAGER:-less}"
export LESS="-FRX"

# Locale settings
export LANG="\${LANG:-en_US.UTF-8}"
export LC_ALL="\${LC_ALL:-en_US.UTF-8}"

# Dotfiles root
export DOTFILES_ROOT="\${DOTFILES_ROOT:-\$HOME/Work/.dotfiles}"

EOF
    else
        log_debug "Profile already configured for dotfiles"
    fi
    
    # Create user-specific environment file
    local env_file="$HOME/.config/dotfiles/user.env"
    if [[ ! -f "$env_file" ]]; then
        mkdir -p "$(dirname "$env_file")"
        cat > "$env_file" << EOF
# User-specific environment variables
# This file is sourced by dotfiles components

# User information
DOTFILES_USER="$USER"
DOTFILES_HOME="$HOME"

# Customization flags
DOTFILES_THEME="default"
DOTFILES_POWERLINE="true"

# Development settings
DOTFILES_GIT_NAME=""
DOTFILES_GIT_EMAIL=""

# Cloud settings
AWS_DEFAULT_REGION="us-east-1"
GCP_DEFAULT_REGION="us-central1"
AZURE_DEFAULT_LOCATION="eastus"

EOF
        log_info "Created user environment file: $env_file"
        log_info "Edit this file to customize your dotfiles installation"
    fi
}

component_validate() {
    log_info "Validating user management configuration..."
    
    local validation_failed=0
    
    # Check user information
    if [[ -z "$USER" ]] || [[ -z "$HOME" ]]; then
        log_error "User environment variables not set"
        ((validation_failed++))
    fi
    
    # Check required directories exist
    local required_dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Required directory missing: $dir"
            ((validation_failed++))
        fi
    done
    
    # Check shell configuration
    if [[ -z "$SHELL" ]]; then
        log_warn "SHELL environment variable not set"
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_info "Passwordless sudo not configured (this is optional)"
    fi
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "User management validation passed"
        return 0
    else
        log_error "User management validation failed"
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