#!/bin/bash

# Enhanced macOS Installation Script
# Features: Homebrew, development tools, modern shell, productivity apps

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print functions
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║           macOS Dotfiles Installation             ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install Xcode Command Line Tools
install_xcode_cli() {
    if ! xcode-select -p &> /dev/null; then
        print_status "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        # Wait for installation to complete
        until xcode-select -p &> /dev/null; do
            sleep 5
        done
        
        print_success "Xcode Command Line Tools installed"
    else
        print_success "Xcode Command Line Tools already installed"
    fi
}

# Install Homebrew
install_homebrew() {
    if ! command_exists brew; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f /opt/homebrew/bin/brew ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
        brew update
    fi
}

# Install essential packages
install_essential_packages() {
    print_status "Installing essential packages..."
    
    # CLI tools
    local cli_packages=(
        # Core utilities
        coreutils
        findutils
        gnu-tar
        gnu-sed
        gawk
        gnutls
        gnu-indent
        gnu-getopt
        grep
        
        # Modern CLI tools
        git
        wget
        curl
        jq
        yq
        tree
        htop
        ncdu
        
        # Shell and terminal
        zsh
        tmux
        starship
        
        # Search and file tools
        ripgrep
        fd
        bat
        eza
        fzf
        zoxide
        
        # Development tools
        neovim
        vim
        gh
        git-lfs
        
        # System tools
        mas  # Mac App Store CLI
        trash  # Better than rm
        tldr
        
        # Fonts
        font-fira-code-nerd-font
        font-jetbrains-mono-nerd-font
        font-hack-nerd-font
        font-meslo-lg-nerd-font
    )
    
    for package in "${cli_packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            print_status "$package is already installed"
        else
            print_status "Installing $package..."
            brew install "$package" || print_warning "Failed to install $package"
        fi
    done
    
    print_success "Essential packages installed"
}

# Install GUI applications
install_gui_applications() {
    print_status "Would you like to install GUI applications? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Installing GUI applications..."
        
        local gui_apps=(
            # Browsers
            google-chrome
            firefox
            
            # Development
            visual-studio-code
            iterm2
            docker
            
            # Productivity
            rectangle  # Window manager
            alfred
            obsidian
            notion
            
            # Communication
            slack
            discord
            zoom
            
            # Utilities
            the-unarchiver
            appcleaner
            stats  # System monitor
            raycast  # Spotlight replacement
            
            # Media
            vlc
            spotify
        )
        
        for app in "${gui_apps[@]}"; do
            if brew list --cask "$app" &>/dev/null; then
                print_status "$app is already installed"
            else
                print_status "Installing $app..."
                brew install --cask "$app" || print_warning "Failed to install $app"
            fi
        done
        
        print_success "GUI applications installed"
    fi
}

# Install development environments
install_development_tools() {
    print_status "Installing development tools..."
    
    # Programming languages and tools
    local dev_packages=(
        # Python
        python@3.11
        pyenv
        pipx
        
        # Node.js
        node
        yarn
        pnpm
        
        # Go
        go
        
        # Rust
        rustup-init
        
        # Database tools
        postgresql
        mysql
        redis
        sqlite
        
        # Cloud tools
        awscli
        kubectl
        terraform
        helm
        
        # Container tools
        docker
        docker-compose
        colima  # Docker Desktop alternative
    )
    
    for package in "${dev_packages[@]}"; do
        if brew list "$package" &>/dev/null || brew list --cask "$package" &>/dev/null; then
            print_status "$package is already installed"
        else
            print_status "Installing $package..."
            brew install "$package" || print_warning "Failed to install $package"
        fi
    done
    
    # Initialize Rust if installed
    if command_exists rustup-init && ! command_exists rustc; then
        print_status "Initializing Rust..."
        rustup-init -y
        source "$HOME/.cargo/env"
    fi
    
    # Install global Python packages
    if command_exists pipx; then
        pipx ensurepath
        pipx install black
        pipx install flake8
        pipx install mypy
        pipx install poetry
        pipx install pipenv
    fi
    
    # Install global Node packages
    if command_exists npm; then
        npm install -g typescript
        npm install -g eslint
        npm install -g prettier
        npm install -g @vue/cli
        npm install -g create-react-app
    fi
    
    print_success "Development tools installed"
}

# Configure shell environment
configure_shell() {
    print_status "Configuring shell environment..."
    
    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install Zsh plugins
    local custom_plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # zsh-autosuggestions
    if [[ ! -d "$custom_plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$custom_plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_plugins/zsh-syntax-highlighting"
    fi
    
    # Install Powerlevel10k theme
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    fi
    
    # Link shell configurations
    if [[ -d "$DOTFILES_ROOT/zsh" ]]; then
        ln -sf "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"
        for file in "$DOTFILES_ROOT/zsh"/*.zsh; do
            [[ -f "$file" ]] && ln -sf "$file" "$HOME/.$(basename "$file")"
        done
    fi
    
    # Configure FZF
    if command_exists fzf; then
        $(brew --prefix)/opt/fzf/install --all --no-bash --no-fish
    fi
    
    print_success "Shell environment configured"
}

# Configure macOS system preferences
configure_macos_preferences() {
    print_status "Would you like to configure macOS system preferences? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Configuring macOS preferences..."
        
        # Show hidden files in Finder
        defaults write com.apple.finder AppleShowAllFiles -bool true
        
        # Show path bar in Finder
        defaults write com.apple.finder ShowPathbar -bool true
        
        # Show status bar in Finder
        defaults write com.apple.finder ShowStatusBar -bool true
        
        # Keep folders on top when sorting by name
        defaults write com.apple.finder _FXSortFoldersFirst -bool true
        
        # Disable the warning when changing a file extension
        defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
        
        # Use list view in all Finder windows by default
        defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
        
        # Show the ~/Library folder
        chflags nohidden ~/Library
        
        # Show the /Volumes folder
        sudo chflags nohidden /Volumes
        
        # Expand save panel by default
        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
        defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
        
        # Expand print panel by default
        defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
        defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
        
        # Save to disk (not to iCloud) by default
        defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
        
        # Automatically quit printer app once the print jobs complete
        defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
        
        # Disable automatic spelling correction
        defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
        
        # Enable full keyboard access for all controls
        defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
        
        # Enable subpixel font rendering on non-Apple LCDs
        defaults write NSGlobalDomain AppleFontSmoothing -int 2
        
        # Enable HiDPI display modes (requires restart)
        sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
        
        # Speed up Mission Control animations
        defaults write com.apple.dock expose-animation-duration -float 0.1
        
        # Don't automatically rearrange Spaces based on most recent use
        defaults write com.apple.dock mru-spaces -bool false
        
        # Hot corners
        # Bottom right screen corner → Start screen saver
        defaults write com.apple.dock wvous-br-corner -int 5
        defaults write com.apple.dock wvous-br-modifier -int 0
        
        # Restart affected applications
        killall Finder
        killall Dock
        
        print_success "macOS preferences configured"
    fi
}

# Create symlinks
create_symlinks() {
    print_status "Creating configuration symlinks..."
    
    # Git configuration
    if [[ -f "$DOTFILES_ROOT/git/.gitconfig" ]]; then
        ln -sf "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
    fi
    
    # Tmux configuration
    if [[ -f "$DOTFILES_ROOT/.tmux.conf" ]]; then
        ln -sf "$DOTFILES_ROOT/.tmux.conf" "$HOME/.tmux.conf"
    fi
    
    # Vim/Neovim configuration
    if [[ -d "$DOTFILES_ROOT/nvim" ]]; then
        mkdir -p "$HOME/.config"
        ln -sf "$DOTFILES_ROOT/nvim" "$HOME/.config/nvim"
    fi
    
    print_success "Symlinks created"
}

# Install tmux plugin manager
install_tmux_plugins() {
    if command_exists tmux; then
        print_status "Installing Tmux Plugin Manager..."
        
        if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
            print_success "TPM installed. Press prefix + I in tmux to install plugins"
        else
            print_status "TPM already installed"
        fi
    fi
}

# Post-installation summary
show_summary() {
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
    echo -e "║        macOS Installation Completed!              ║"
    echo -e "╚═══════════════════════════════════════════════════╝${NC}"
    echo
    print_status "Next steps:"
    echo "  1. Restart your terminal for shell changes"
    echo "  2. Run 'p10k configure' to set up Powerlevel10k"
    echo "  3. Install tmux plugins: prefix + I"
    echo "  4. Configure your Git credentials"
    echo "  5. Sign in to GUI applications"
    echo
    
    if command_exists mas; then
        print_status "Recommended Mac App Store apps:"
        echo "  - Amphetamine (keep Mac awake)"
        echo "  - Magnet (window management)"
        echo "  - Pixelmator Pro (image editing)"
        echo "  - Things 3 (task management)"
    fi
}

# Main installation menu
show_main_menu() {
    clear
    print_banner
    
    echo "Select installation option:"
    echo "  1) Full Installation (Recommended)"
    echo "  2) Essential Tools Only"
    echo "  3) Development Tools Only"
    echo "  4) GUI Applications Only"
    echo "  5) Shell Configuration Only"
    echo "  6) macOS Preferences Only"
    echo "  q) Quit"
    echo
    read -rp "Enter your choice: " choice
    
    case "$choice" in
        1)
            install_xcode_cli
            install_homebrew
            install_essential_packages
            install_development_tools
            install_gui_applications
            configure_shell
            create_symlinks
            install_tmux_plugins
            configure_macos_preferences
            ;;
        2)
            install_xcode_cli
            install_homebrew
            install_essential_packages
            ;;
        3)
            install_xcode_cli
            install_homebrew
            install_development_tools
            ;;
        4)
            install_homebrew
            install_gui_applications
            ;;
        5)
            install_homebrew
            configure_shell
            create_symlinks
            install_tmux_plugins
            ;;
        6)
            configure_macos_preferences
            ;;
        q|Q)
            print_status "Installation cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    print_status "Detected macOS $macos_version"
    
    # Show main menu
    show_main_menu
    
    # Show summary
    show_summary
}

# Run main function
main "$@"