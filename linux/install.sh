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
DESKTOP_DIR="$LINUX_SCRIPT_DIR/../scripts/desktop"

install_system_packages() {
    info "Installing system packages for Linux desktop..."
    
    case "$(detect_package_manager)" in
        apt)
            install_packages \
                curl wget git build-essential software-properties-common \
                apt-transport-https ca-certificates gnupg lsb-release \
                ubuntu-restricted-extras fonts-noto-color-emoji \
                firefox chromium-browser vlc gimp libreoffice \
                code terminator kitty
            ;;
        dnf)
            install_packages \
                curl wget git @development-tools \
                firefox chromium vlc gimp libreoffice \
                code terminator kitty
            ;;
        pacman)
            install_packages \
                curl wget git base-devel \
                firefox chromium vlc gimp libreoffice \
                code terminator kitty
            ;;
        *)
            warning "Unknown package manager, skipping system packages"
            ;;
    esac
}

setup_directories() {
    info "Setting up directory structure..."
    
    local dirs=(
        "$HOME/Work"
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/Pictures/Screenshots"
        "$HOME/.local/share/fonts"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        debug "Created directory: $dir"
    done
}

clone_dotfiles() {
    if [[ -d "$HOME/Work/.dotfiles" ]]; then
        info "Dotfiles already cloned, updating..."
        cd "$HOME/Work/.dotfiles" && git pull
    else
        info "Cloning dotfiles repository..."
        git clone https://github.com/alamin-mahamud/.dotfiles.git "$HOME/Work/.dotfiles"
    fi
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

run_desktop_installer() {
    local installer="$1"
    local script_path="$DESKTOP_DIR/$installer"
    
    if [[ -x "$script_path" ]]; then
        info "Running desktop installer: $installer"
        if "$script_path"; then
            success "Completed: $installer"
        else
            error "Failed: $installer"
        fi
    else
        warning "Desktop installer not found or not executable: $installer"
    fi
}

setup_symlinks() {
    info "Setting up configuration symlinks..."
    
    local dotfiles_dir="$HOME/Work/.dotfiles"
    
    # Zsh configuration
    safe_symlink "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
    
    # Git configuration
    safe_symlink "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
    
    # Tmux configuration
    safe_symlink "$dotfiles_dir/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
    
    # Vim configuration
    if [[ -f "$dotfiles_dir/vim/.vimrc" ]]; then
        safe_symlink "$dotfiles_dir/vim/.vimrc" "$HOME/.vimrc"
    fi
    
    # Neovim configuration
    if [[ -d "$dotfiles_dir/nvim" ]]; then
        safe_symlink "$dotfiles_dir/nvim" "$HOME/.config/nvim"
    fi
    
    # Desktop configuration files
    local config_dirs=("kitty" "alacritty" "rofi" "i3" "sway")
    for config in "${config_dirs[@]}"; do
        if [[ -d "$dotfiles_dir/linux/.config/$config" ]]; then
            safe_symlink "$dotfiles_dir/linux/.config/$config" "$HOME/.config/$config"
        fi
    done
    
    success "Symlinks created"
}

install_fonts() {
    info "Installing fonts..."
    
    local fonts_dir="$HOME/.local/share/fonts"
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
        fi
    done
    
    # Refresh font cache
    if command_exists fc-cache; then
        fc-cache -fv >/dev/null 2>&1
        success "Font cache updated"
    fi
}

configure_desktop_environment() {
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
            mkdir -p "$(dirname "$desktop_file")"
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
        fi
    fi
    
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
    
    # Desktop-specific installations
    run_desktop_installer "keyboard-setup.sh"
    
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