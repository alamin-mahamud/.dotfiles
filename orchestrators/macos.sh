#!/usr/bin/env bash
# macOS platform orchestrator
# Following Python's Zen: "Complex is better than complicated"

# Get the orchestrator directory
ORCHESTRATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$ORCHESTRATOR_DIR/.." && pwd)"
LIB_DIR="$DOTFILES_ROOT/lib"
RECIPES_DIR="$DOTFILES_ROOT/recipes"

# Import ingredients
source "$LIB_DIR/core.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/package.sh"

# macOS-specific orchestration
main() {
    info "=== macOS Platform Orchestrator ==="
    
    # Check prerequisites
    if ! check_internet; then
        die "Internet connection required"
    fi
    
    # Install or update Homebrew
    install_homebrew
    
    # Install build essentials (Xcode Command Line Tools)
    install_build_essentials
    
    # Run recipes in order
    local recipes=(
        "$RECIPES_DIR/shell.sh"
        "$RECIPES_DIR/python.sh"
        "$RECIPES_DIR/desktop.sh"
    )
    
    # Execute all recipes
    for recipe in "${recipes[@]}"; do
        if [[ -x "$recipe" ]]; then
            info "Running recipe: $(basename "$recipe")"
            "$recipe"
        else
            warning "Recipe not found or not executable: $recipe"
        fi
    done
    
    # macOS-specific post-installation
    post_install_macos
    
    success "=== macOS setup complete! ==="
}

# Install Homebrew
install_homebrew() {
    if command_exists brew; then
        info "Updating Homebrew..."
        brew update
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon
        local arch
        arch=$(detect_arch)
        if [[ "$arch" == "arm64" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
            echo 'export PATH="/opt/homebrew/bin:$PATH"' >> "${HOME}/.zprofile"
        fi
    fi
    
    # Install essential Homebrew packages
    install_homebrew_essentials
    
    success "Homebrew ready"
}

# Install essential Homebrew packages
install_homebrew_essentials() {
    info "Installing essential Homebrew packages..."
    
    local packages=(
        "git"
        "curl"
        "wget"
        "tree"
        "htop"
        "jq"
        "gnu-sed"
        "gnu-tar"
        "coreutils"
        "findutils"
        "grep"
    )
    
    install_packages "${packages[@]}"
    
    success "Homebrew essentials installed"
}

# macOS-specific post-installation tasks
post_install_macos() {
    info "Running macOS-specific post-installation tasks..."
    
    # Install additional macOS apps
    install_macos_apps
    
    # Configure macOS settings
    configure_macos_settings
    
    success "macOS post-installation complete"
}

# Install macOS applications
install_macos_apps() {
    info "Installing macOS applications..."
    
    # Install cask applications if user wants them
    if confirm "Install GUI applications (iTerm2, VSCode, etc.)?"; then
        local cask_apps=(
            "iterm2"
            "visual-studio-code"
            "docker"
            "firefox"
            "google-chrome"
        )
        
        for app in "${cask_apps[@]}"; do
            if ! brew list --cask "$app" &>/dev/null; then
                info "Installing $app..."
                brew install --cask "$app"
            else
                debug "$app already installed"
            fi
        done
    fi
    
    success "macOS applications ready"
}

# Configure macOS settings
configure_macos_settings() {
    info "Configuring macOS settings..."
    
    # Disable the sound effects on boot
    sudo nvram SystemAudioVolume=" "
    
    # Enable full keyboard access for all controls
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    
    # Set a blazingly fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 1
    defaults write NSGlobalDomain InitialKeyRepeat -int 10
    
    # Show filename extensions by default
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    # Show hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Show path bar in Finder
    defaults write com.apple.finder ShowPathbar -bool true
    
    # Show status bar in Finder
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # Use list view in all Finder windows by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Disable the warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    
    # Enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    
    # Map caps lock to escape
    hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
    
    info "Configured macOS settings. Some changes require restart."
    
    success "macOS settings configured"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi