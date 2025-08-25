#!/usr/bin/env bash

# Linux Desktop Installation Orchestrator
# Comprehensive desktop environment setup using modular components
# Supports: Ubuntu, Arch Linux, Fedora, and derivatives
# Usage: ./install.sh

set -euo pipefail

LINUX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LINUX_SCRIPT_DIR/../scripts/lib/common.sh"
source "$LINUX_SCRIPT_DIR/../scripts/lib/package-managers.sh"

# Configuration
COMPONENTS_DIR="$LINUX_SCRIPT_DIR/../scripts/components"

install_system_packages() {
    info "Installing essential system packages for Linux..."
    
    case "$(detect_package_manager)" in
        apt)
            install_packages \
                curl wget git build-essential software-properties-common \
                apt-transport-https ca-certificates gnupg lsb-release \
                fonts-noto-color-emoji
            ;;
        dnf)
            install_packages \
                curl wget git @development-tools
            ;;
        pacman)
            install_packages \
                curl wget git base-devel
            ;;
        *)
            warning "Unknown package manager, skipping system packages"
            ;;
    esac
}

setup_directories() {
    info "Setting up directory structure..."
    
    local dirs=(
        "$HOME/Projects"
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/Pictures/Screenshots"
        "$HOME/.local/share/fonts"
    )
    
    for dir in "${dirs[@]}"; do
        ensure_directory "$dir"
    done
}

clone_dotfiles() {
    install_or_update_git_repo "https://github.com/alamin-mahamud/.dotfiles.git" "$HOME/.dotfiles" "master"
}

run_component_installer() {
    local component="$1"
    local script_path="$COMPONENTS_DIR/$component"
    
    if [[ -x "$script_path" ]]; then
        info "Running component installer: $component"
        if "$script_path"; then
            success "Completed: $component"
        else
            error "Failed: $component"
        fi
    else
        warning "Component installer not found or not executable: $component"
    fi
}

# Desktop installer function removed - no desktop directory exists

setup_symlinks() {
    info "Setting up configuration symlinks..."
    
    local dotfiles_dir="$HOME/.dotfiles"
    
    # Git configuration
    safe_symlink "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
    
    # Powerlevel10k configuration (if exists)
    if [[ -f "$dotfiles_dir/configs/p10k-lean.zsh" ]]; then
        safe_symlink "$dotfiles_dir/configs/p10k-lean.zsh" "$HOME/.p10k.zsh"
    fi
    
    # Desktop configuration files (only if they exist)
    local config_dirs=("kitty" "alacritty" "rofi" "i3" "sway")
    for config in "${config_dirs[@]}"; do
        if [[ -d "$dotfiles_dir/linux/.config/$config" ]]; then
            safe_symlink "$dotfiles_dir/linux/.config/$config" "$HOME/.config/$config"
        fi
    done
    
    success "Symlinks created"
}

install_fonts() {
    if is_completed "fonts-installed"; then
        debug "Fonts already installed"
        return 0
    fi
    
    info "Installing fonts..."
    
    local fonts_dir="$HOME/.local/share/fonts"
    ensure_directory "$fonts_dir"
    local nerd_fonts=("FiraCode" "JetBrainsMono" "Iosevka")
    
    for font in "${nerd_fonts[@]}"; do
        local font_dir="$fonts_dir/$font"
        if [[ ! -d "$font_dir" ]]; then
            info "Installing $font Nerd Font..."
            local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
            local temp_file="/tmp/${font}.zip"
            
            if download_file "$font_url" "$temp_file"; then
                mkdir -p "$font_dir"
                unzip -q "$temp_file" -d "$font_dir"
                rm "$temp_file"
                success "Installed $font font"
            else
                warning "Failed to download $font font"
            fi
        else
            debug "$font font already installed"
        fi
    done
    
    # Refresh font cache
    if command_exists fc-cache; then
        fc-cache -fv >/dev/null 2>&1
        success "Font cache updated"
    fi
    
    mark_completed "fonts-installed"
}

configure_desktop_environment() {
    if is_completed "desktop-configured"; then
        debug "Desktop environment already configured"
        return 0
    fi
    
    info "Configuring desktop environment..."
    
    # Set default browser if firefox is installed
    if command_exists firefox; then
        xdg-settings set default-web-browser firefox.desktop 2>/dev/null || true
    fi
    
    # Set default terminal if kitty is installed
    if command_exists kitty; then
        # Create desktop entry for kitty if it doesn't exist
        local desktop_file="$HOME/.local/share/applications/kitty.desktop"
        if [[ ! -f "$desktop_file" ]]; then
            ensure_directory "$(dirname "$desktop_file")"
            cat > "$desktop_file" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Kitty
Comment=The fast, featureful, GPU based terminal emulator
Exec=kitty
Icon=kitty
Categories=System;TerminalEmulator;
EOF
            debug "Created kitty desktop entry"
        fi
    fi
    
    mark_completed "desktop-configured"
    success "Desktop environment configured"
}

main() {
    init_script "Linux Desktop Installation"
    
    # Verify we're on Linux
    if [[ "${DOTFILES_OS}" != "linux" ]]; then
        error "This script is only for Linux systems"
    fi
    
    # Check if we have a desktop environment
    if ! is_desktop_environment; then
        warning "No desktop environment detected. Some features may not work."
    fi
    
    print_header "Linux Desktop Environment Setup"
    info "This will install a comprehensive desktop development environment"
    info "Components: Shell, Python, Development tools, Desktop applications"
    
    if ! ask_yes_no "Continue with installation?" "yes"; then
        info "Installation cancelled"
        exit 0
    fi
    
    # Core setup
    setup_directories
    install_system_packages
    clone_dotfiles
    
    # Component installations
    run_component_installer "shell-env.sh"
    run_component_installer "python-env.sh"
    run_component_installer "devops-tools.sh"
    run_component_installer "networking-tools.sh"
    
    # Configuration
    setup_symlinks
    install_fonts
    configure_desktop_environment
    
    success "Linux desktop environment setup complete!"
    
    print_header "Next Steps"
    info "1. Restart your terminal or run: exec zsh"
    info "2. Run 'p10k configure' to set up your prompt"
    info "3. Open tmux and press Ctrl-a + I to install plugins"
    info "4. Install additional packages as needed"
    info ""
    info "Log file: $LOG_FILE"
    info "Backup directory (if created): Look for .dotfiles-backup-* in your home directory"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi