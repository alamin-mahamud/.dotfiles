#!/usr/bin/env bash

# macOS Installation Orchestrator - Apple Silicon Optimized
# Comprehensive macOS development environment setup using modular components
# Automatically detects architecture (Apple Silicon vs Intel)
# Usage: ./install.sh

set -euo pipefail

MACOS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MACOS_SCRIPT_DIR/../scripts/lib/common.sh"
source "$MACOS_SCRIPT_DIR/../scripts/lib/package-managers.sh"

# Configuration
COMPONENTS_DIR="$MACOS_SCRIPT_DIR/../scripts/components"

install_xcode_cli_tools() {
    if xcode-select --print-path &> /dev/null; then
        debug "Xcode Command Line Tools already installed"
        return 0
    fi
    
    info "Installing Xcode Command Line Tools (this may take a while)..."
    xcode-select --install
    
    # Wait for installation to complete
    info "Waiting for Xcode Command Line Tools installation to complete..."
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done
    
    success "Xcode Command Line Tools installed"
}

setup_homebrew() {
    if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ "${DOTFILES_ARCH}" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        success "Homebrew installed"
    else
        debug "Homebrew already installed"
        # Update only if package lists haven't been updated recently
        update_package_lists
    fi
}

install_essential_packages() {
    info "Installing essential macOS packages..."
    
    local packages=(
        # Development tools
        "git" "curl" "wget" "jq" "tree" "htop"
        
        # Modern CLI tools
        "ripgrep" "fd" "bat" "eza" "fzf" "tmux" "neovim"
        
        # Development applications
        "docker"
    )
    
    install_packages "${packages[@]}"
}

install_mac_app_store_apps() {
    info "Skipping Mac App Store apps (can be installed manually if needed)"
    # Uncomment below to install specific apps:
    # mas install 497799835  # Xcode
}

configure_macos_settings() {
    if is_completed "macos-settings-configured"; then
        debug "macOS settings already configured"
        return 0
    fi
    
    info "Configuring macOS system settings..."
    
    # Dock settings
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock show-recents -bool false
    
    # Finder settings
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    
    # Screenshots location
    local screenshots_dir="$HOME/Pictures/Screenshots"
    ensure_directory "$screenshots_dir"
    defaults write com.apple.screencapture location "$screenshots_dir"
    
    # Keyboard settings
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Trackpad settings
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    
    # Menu bar settings
    defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  h:mm:ss a"
    
    # Energy settings
    sudo pmset -a standby 0
    sudo pmset -a autopoweroff 0
    
    mark_completed "macos-settings-configured"
    success "macOS settings configured"
}

setup_directories() {
    info "Setting up directory structure..."
    
    local dirs=(
        "$HOME/Projects"
        "$HOME/Pictures/Screenshots"
        "$HOME/.config"
        "$HOME/.local/bin"
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
    
    # macOS-specific configurations (only if they exist)
    if [[ -d "$dotfiles_dir/macos/.config" ]]; then
        local config_dirs
        config_dirs=($(ls "$dotfiles_dir/macos/.config" 2>/dev/null || true))
        for config in "${config_dirs[@]}"; do
            if [[ -d "$dotfiles_dir/macos/.config/$config" ]]; then
                safe_symlink "$dotfiles_dir/macos/.config/$config" "$HOME/.config/$config"
            fi
        done
    fi
    
    # iTerm2 configuration (only if it exists)
    if [[ -f "$dotfiles_dir/macos/iterm/com.googlecode.iterm2.plist" ]]; then
        local iterm_dir="$HOME/Library/Preferences"
        safe_symlink "$dotfiles_dir/macos/iterm/com.googlecode.iterm2.plist" "$iterm_dir/com.googlecode.iterm2.plist"
    fi
    
    success "Symlinks created"
}

install_fonts() {
    if is_completed "fonts-installed"; then
        debug "Fonts already installed"
        return 0
    fi
    
    info "Installing fonts..."
    
    local fonts_dir="$HOME/Library/Fonts"
    local nerd_fonts=("FiraCode" "JetBrainsMono" "Iosevka")
    
    for font in "${nerd_fonts[@]}"; do
        if [[ ! -f "$fonts_dir/${font}NerdFont-Regular.ttf" ]]; then
            info "Installing $font Nerd Font..."
            local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
            local temp_file="/tmp/${font}.zip"
            local temp_dir="/tmp/${font}"
            
            if download_file "$font_url" "$temp_file"; then
                mkdir -p "$temp_dir"
                unzip -q "$temp_file" -d "$temp_dir"
                cp "$temp_dir"/*.ttf "$fonts_dir/" 2>/dev/null || true
                cp "$temp_dir"/*.otf "$fonts_dir/" 2>/dev/null || true
                rm -rf "$temp_file" "$temp_dir"
                success "Installed $font font"
            else
                warning "Failed to download $font font"
            fi
        else
            debug "$font font already installed"
        fi
    done
    
    mark_completed "fonts-installed"
    success "Font installation complete"
}

restart_affected_services() {
    info "Restarting affected services..."
    
    # Restart Dock to apply changes
    killall Dock 2>/dev/null || true
    
    # Restart Finder to apply changes
    killall Finder 2>/dev/null || true
    
    # Restart SystemUIServer for menu bar changes
    killall SystemUIServer 2>/dev/null || true
    
    success "Services restarted"
}

main() {
    init_script "macOS Installation"
    
    # Verify we're on macOS
    if [[ "${DOTFILES_OS}" != "macos" ]]; then
        error "This script is only for macOS systems"
    fi
    
    print_header "macOS Development Environment Setup"
    info "This will install a comprehensive macOS development environment"
    info "Architecture: ${DOTFILES_ARCH}"
    info "Components: Homebrew, Shell, Python, Development tools, Applications"
    
    if ! ask_yes_no "Continue with installation?" "yes"; then
        info "Installation cancelled"
        exit 0
    fi
    
    # Core setup
    install_xcode_cli_tools
    setup_homebrew
    setup_directories
    clone_dotfiles
    
    # Package installation
    install_essential_packages
    install_mac_app_store_apps
    
    # Component installations
    run_component_installer "shell-env.sh"
    run_component_installer "python-env.sh"
    run_component_installer "devops-tools.sh"
    run_component_installer "networking-tools.sh"
    
    # Configuration
    setup_symlinks
    install_fonts
    configure_macos_settings
    restart_affected_services
    
    success "macOS development environment setup complete!"
    
    print_header "Next Steps"
    info "1. Restart your terminal or run: exec zsh"
    info "2. Run 'p10k configure' to set up your prompt"
    info "3. Open tmux and press Ctrl-a + I to install plugins"
    info "4. Configure your applications (VS Code, browsers, etc.)"
    info "5. Sign in to your accounts (iCloud, GitHub, etc.)"
    info ""
    info "Log file: $LOG_FILE"
    info "Some settings require a restart to take full effect"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi