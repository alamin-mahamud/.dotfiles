#!/bin/bash

# DRY Linux Desktop Installation Orchestrator
# Calls individual component installers from GitHub to avoid code duplication
# Supports: Ubuntu, Arch Linux, and derivatives
# Usage: ./install.sh or curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/linux/install.sh | bash

set -euo pipefail

# Configuration
GITHUB_RAW_BASE="https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
TEMP_DIR="/tmp/dotfiles-linux-install-$$"
LOG_FILE="/tmp/linux-desktop-setup.log"

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

# Directories
DOT="$HOME/Work/.dotfiles"
CONFIG="$HOME/.config"
BIN="$HOME/.local/bin"
SCREENSHOTS="$HOME/Pictures/Screenshots"
FONTS="${HOME}/.local/share/fonts"

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

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        DISTRO_VERSION="$VERSION_ID"
        DISTRO_FAMILY=""
        
        case "$ID" in
            ubuntu|debian|linuxmint|pop)
                DISTRO_FAMILY="debian"
                ;;
            arch|manjaro|endeavouros)
                DISTRO_FAMILY="arch"
                ;;
            fedora|centos|rhel)
                DISTRO_FAMILY="redhat"
                ;;
            *)
                DISTRO_FAMILY="unknown"
                ;;
        esac
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
    
    print_success "Detected: $DISTRO ($DISTRO_FAMILY family)"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    local dirs=(
        "$HOME/Work/.dotfiles"
        "$HOME/.config" 
        "$HOME/.local/bin"
        "$HOME/Pictures/Screenshots"
        "$HOME/.local/share/fonts"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    print_success "Directories created"
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    
    case "$DISTRO_FAMILY" in
        debian)
            sudo apt update && sudo apt upgrade -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac
    
    print_success "System updated"
}

# Install essential Linux desktop packages
install_desktop_essentials() {
    print_status "Installing essential desktop packages..."
    
    local packages=""
    
    case "$DISTRO_FAMILY" in
        debian)
            packages="curl wget git vim neovim htop btop tree unzip zip build-essential cmake zsh tmux fzf ripgrep fd-find bat software-properties-common apt-transport-https ca-certificates gnupg lsb-release"
            sudo apt install -y $packages
            ;;
        arch)
            # Install AUR helper first
            if ! command_exists paru && ! command_exists yay; then
                sudo pacman -S --needed --noconfirm base-devel git
                git clone https://aur.archlinux.org/paru.git /tmp/paru
                cd /tmp/paru && makepkg -si --noconfirm && cd - && rm -rf /tmp/paru
            fi
            
            packages="curl wget git vim neovim htop btop tree unzip zip base-devel cmake zsh tmux fzf ripgrep fd bat gnupg"
            sudo pacman -S --noconfirm $packages
            ;;
    esac
    
    print_success "Essential desktop packages installed"
}

# Install Linux window manager packages
install_window_manager_packages() {
    print_status "Installing window manager and desktop packages..."
    
    case "$DISTRO_FAMILY" in
        debian)
            sudo apt install -y \
                i3-gaps i3blocks i3lock i3status \
                polybar rofi dunst picom \
                feh arandr lxappearance \
                kitty alacritty firefox \
                thunar gvfs-backends tumbler \
                pavucontrol network-manager-applet \
                blueman flameshot \
                xclip xsel brightnessctl playerctl
            ;;
        arch)
            if command_exists paru; then
                paru -S --noconfirm \
                    i3-gaps i3blocks i3lock i3status \
                    polybar rofi dunst picom \
                    feh arandr lxappearance-gtk3 \
                    kitty alacritty firefox \
                    thunar gvfs tumbler \
                    pavucontrol network-manager-applet \
                    blueman flameshot \
                    xclip xsel brightnessctl playerctl
            else
                sudo pacman -S --noconfirm \
                    i3-gaps i3blocks i3lock i3status \
                    rofi dunst picom \
                    feh arandr lxappearance-gtk3 \
                    kitty alacritty firefox \
                    thunar gvfs tumbler \
                    pavucontrol network-manager-applet \
                    blueman flameshot \
                    xclip xsel brightnessctl playerctl
            fi
            ;;
    esac
    
    print_success "Window manager packages installed"
}

# Main DRY orchestrator for Linux desktop
main() {
    clear
    echo "=========================================================="
    echo "Linux Desktop DRY Installation Orchestrator"
    echo "=========================================================="
    echo "This script calls individual component installers from"
    echo "GitHub to keep everything DRY and maintainable."
    echo "=========================================================="
    echo
    
    # Pre-flight checks
    detect_distro
    create_directories
    
    # Core system setup
    update_system
    install_desktop_essentials
    
    # Enhanced components via specialized installers
    print_status "Installing enhanced shell environment..."
    if prompt_install "shell" "enhanced shell environment (Zsh + Oh My Zsh + plugins)"; then
        run_installer "install-shell.sh" || print_warning "Enhanced shell installation failed, continuing..."
    fi
    
    print_status "Installing enhanced tmux configuration..."
    if prompt_install "tmux" "enhanced tmux configuration with DevOps features"; then
        run_installer "tmux-installer.sh" || print_warning "Enhanced tmux installation failed, continuing..."
    fi
    
    print_status "Installing enhanced vim configuration..."
    if prompt_install "vim" "enhanced vim configuration with plugins"; then
        run_installer "vim-installer.sh" || print_warning "Enhanced vim installation failed, continuing..."
    fi
    
    # Desktop-specific components
    if prompt_install "desktop" "desktop environment packages (window managers, GUI apps)"; then
        install_window_manager_packages
    fi
    
    # Optional development tools
    if prompt_install "dev-tools" "development tools installer"; then
        run_installer "install-dev-tools.sh" || print_warning "Development tools installation failed, continuing..."
    fi
    
    # Create basic symlinks if running from repo
    if [[ -d "$DOTFILES_ROOT/linux" ]]; then
        print_status "Creating configuration symlinks from repository..."
        [[ -f "$DOTFILES_ROOT/linux/symlinks.sh" ]] && source "$DOTFILES_ROOT/linux/symlinks.sh"
    fi
    
    echo
    print_success "Linux Desktop setup completed!"
    echo
    print_status "📋 Installation Summary:"
    echo "  • Essential desktop packages: ✓ Installed"  
    echo "  • Enhanced components: Installed based on your choices"
    echo "  • Configuration symlinks: Created if repo available"
    echo
    print_status "📁 Log file saved to: $LOG_FILE"
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Log out and back in to apply shell changes"
    echo "  2. Run 'p10k configure' if you installed enhanced shell"
    echo "  3. Test window manager: Alt+Enter for terminal"
    echo "  4. Configure display settings if needed"
    echo "  5. Install additional packages as needed"
    echo
    print_status "🚀 Your Linux desktop is ready for development!"
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi