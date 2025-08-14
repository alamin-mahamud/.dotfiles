#!/bin/bash

# DRY macOS Installation Orchestrator
# Calls individual component installers from GitHub to avoid code duplication
# Features: Homebrew, development tools, modern shell, productivity apps
# Usage: ./install.sh or curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/macos/install.sh | bash

set -euo pipefail

# Configuration
GITHUB_RAW_BASE="https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
TEMP_DIR="/tmp/dotfiles-macos-install-$$"
LOG_FILE="/tmp/macos-setup.log"

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Create temp directory
mkdir -p "$TEMP_DIR"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print functions
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

# Download and execute script from GitHub
run_installer() {
    local script_name="$1"
    local script_url="$GITHUB_RAW_BASE/$script_name"
    local script_path="$TEMP_DIR/$script_name"
    
    print_status "Downloading and running $script_name..."
    
    # Download the script
    if curl -fsSL "$script_url" -o "$script_path"; then
        chmod +x "$script_path"
        print_success "Downloaded $script_name"
        
        # Execute the script
        if bash "$script_path"; then
            print_success "Successfully ran $script_name"
        else
            print_error "Failed to run $script_name"
            return 1
        fi
    else
        print_error "Failed to download $script_name from $script_url"
        return 1
    fi
}

# Prompt for optional component installation
prompt_install() {
    local component="$1"
    local description="$2"
    local default="${3:-N}"
    
    print_status "Would you like to install $description? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        return 0
    else
        return 1
    fi
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
        print_status "Please follow the installation prompts..."
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

# Install essential macOS packages via Homebrew
install_essential_packages() {
    print_status "Installing essential macOS packages..."
    
    # Essential CLI tools (DRY approach - let specialized installers handle specific tools)
    local packages="coreutils findutils gnu-tar gnu-sed git wget curl"
    
    brew install $packages || {
        print_warning "Some packages may have failed to install"
        print_status "Continuing with setup..."
    }
    
    print_success "Essential macOS packages installed"
}

# Install essential macOS GUI applications
install_gui_applications() {
    if prompt_install "gui-apps" "essential GUI applications (browsers, productivity tools)"; then
        print_status "Installing GUI applications..."
        
        # Essential GUI apps via Homebrew cask  
        local apps="google-chrome firefox rectangle the-unarchiver"
        
        brew install --cask $apps || {
            print_warning "Some GUI applications may have failed to install"
            print_status "Continuing with setup..."
        }
        
        print_success "GUI applications installed"
    fi
}

# Configure basic macOS preferences
configure_macos_preferences() {
    if prompt_install "macos-prefs" "macOS system preferences tweaks (Finder, Dock, etc.)"; then
        print_status "Configuring macOS preferences..."
        
        # Show hidden files and improve Finder
        defaults write com.apple.finder AppleShowAllFiles -bool true
        defaults write com.apple.finder ShowPathbar -bool true
        defaults write com.apple.finder ShowStatusBar -bool true
        defaults write com.apple.finder _FXSortFoldersFirst -bool true
        
        # System improvements
        defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
        defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
        defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
        
        # Show Library folder
        chflags nohidden ~/Library
        
        # Restart Finder
        killall Finder 2>/dev/null || true
        
        print_success "macOS preferences configured"
    fi
}

# Main DRY orchestrator for macOS
main() {
    clear
    echo "=========================================================="
    echo "macOS Development Environment DRY Installer"
    echo "=========================================================="
    echo "Installs essential tools and calls specialized installers:"
    echo "• Enhanced Shell (Zsh, Neovim, LazyVim, Kitty)"
    echo "• Enhanced Tmux & Vim configurations"
    echo "• Optional development tools & GUI apps"
    echo "=========================================================="
    echo
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    print_status "Detected macOS $macos_version"
    
    # Core setup
    install_xcode_cli
    install_homebrew
    install_essential_packages
    
    # Optional GUI applications
    install_gui_applications
    
    # Core components via specialized installers (DRY approach)
    print_status "Installing enhanced shell environment (includes Neovim, Kitty, and LazyVim)..."
    run_installer "install-shell.sh" || print_warning "Enhanced shell installation failed, continuing..."
    
    print_status "Installing enhanced tmux configuration..."
    run_installer "tmux-installer.sh" || print_warning "Enhanced tmux installation failed, continuing..."
    
    print_status "Installing enhanced vim configuration..."
    run_installer "vim-installer.sh" || print_warning "Enhanced vim installation failed, continuing..."
    
    # Optional development tools
    if prompt_install "dev-tools" "development tools and programming languages"; then
        run_installer "install-dev-tools.sh" || print_warning "Development tools installation failed, continuing..."
    fi
    
    # macOS-specific configuration
    configure_macos_preferences
    
    # Create basic symlinks if running from repo
    if [[ -d "$DOTFILES_ROOT/macos" ]]; then
        print_status "Creating configuration symlinks from repository..."
        [[ -f "$DOTFILES_ROOT/git/.gitconfig" ]] && ln -sf "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
        [[ -f "$DOTFILES_ROOT/.tmux.conf" ]] && ln -sf "$DOTFILES_ROOT/.tmux.conf" "$HOME/.tmux.conf"
    fi
    
    echo
    print_success "macOS setup completed!"
    echo
    print_status "📋 Installation Summary:"
    echo "  • Xcode Command Line Tools: ✓ Installed"
    echo "  • Homebrew: ✓ Installed"  
    echo "  • Essential packages: ✓ Installed"
    echo "  • Enhanced shell (Zsh, Neovim, LazyVim, Kitty): ✓ Installed"
    echo "  • Enhanced tmux: ✓ Installed"
    echo "  • Enhanced vim: ✓ Installed"
    echo "  • Development tools: Installed if selected"
    echo "  • GUI apps: Installed if selected"
    echo "  • macOS preferences: Configured if selected"
    echo
    print_status "📁 Log file saved to: $LOG_FILE"
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Restart your terminal for shell changes"
    echo "  2. Run 'p10k configure' to set up Powerlevel10k theme"
    echo "  3. Open Kitty terminal and run 'nvim' to complete LazyVim setup"
    echo "  4. Run 'kitty +kitten themes' to browse terminal themes"
    echo "  5. Sign in to GUI applications if installed"
    echo "  6. Configure Git credentials"
    echo
    print_status "🍎 Your macOS development environment is ready!"
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi