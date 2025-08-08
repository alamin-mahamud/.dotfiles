#!/bin/bash

# Enhanced Linux Desktop Installation Script
# Supports: Ubuntu, Arch Linux, and derivatives
# Features: Window managers (i3/Hyprland), development tools, modern shell

set -euo pipefail

# Import common functions from bootstrap
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utility functions if available
[[ -f "$SCRIPT_DIR/utils.sh" ]] && source "$SCRIPT_DIR/utils.sh"

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
    
    local dirs=("$DOT" "$CONFIG" "$BIN" "$SCREENSHOTS" "$FONTS")
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    print_success "Directories created"
}

# Configure sudoers for package managers
configure_sudoers() {
    print_status "Would you like to configure passwordless sudo for package managers? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        local sudoers_file="/etc/sudoers.d/package-managers"
        local commands=""
        
        case "$DISTRO_FAMILY" in
            debian)
                commands="/usr/bin/apt, /usr/bin/apt-get, /usr/bin/dpkg"
                ;;
            arch)
                commands="/usr/bin/pacman"
                [[ -f /usr/bin/paru ]] && commands="$commands, /usr/bin/paru"
                [[ -f /usr/bin/yay ]] && commands="$commands, /usr/bin/yay"
                ;;
        esac
        
        if [[ -n "$commands" ]]; then
            echo "$(whoami) ALL=(ALL) NOPASSWD: $commands" | sudo tee "$sudoers_file" > /dev/null
            print_success "Sudoers configured for package managers"
        fi
    fi
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    
    case "$DISTRO_FAMILY" in
        debian)
            sudo apt update
            sudo apt upgrade -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac
    
    print_success "System updated"
}

# Install AUR helper for Arch
install_aur_helper() {
    if [[ "$DISTRO_FAMILY" == "arch" ]] && ! command_exists paru && ! command_exists yay; then
        print_status "Installing paru AUR helper..."
        
        sudo pacman -S --needed --noconfirm base-devel git
        
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/paru
        
        print_success "Paru installed"
    fi
}

# Get package manager command
get_package_manager() {
    case "$DISTRO_FAMILY" in
        debian)
            echo "sudo apt install -y"
            ;;
        arch)
            if command_exists paru; then
                echo "paru -S --noconfirm"
            elif command_exists yay; then
                echo "yay -S --noconfirm"
            else
                echo "sudo pacman -S --noconfirm"
            fi
            ;;
    esac
}

# Install base packages
install_base_packages() {
    print_status "Installing base packages..."
    
    local packages=(
        # Core utilities
        curl wget git vim neovim
        htop btop ncdu tree
        unzip zip tar gzip
        jq yq
        
        # Build tools
        build-essential make cmake gcc g++
        pkg-config autoconf automake
        
        # Terminal tools
        zsh tmux
        fzf ripgrep fd-find bat
        
        # Network tools
        net-tools dnsutils
        openssh-client openssh-server
        
        # System tools
        software-properties-common
        apt-transport-https
        ca-certificates gnupg
        lsb-release
    )
    
    # Adjust package names for different distributions
    case "$DISTRO_FAMILY" in
        arch)
            packages=(
                # Core utilities
                curl wget git vim neovim
                htop btop ncdu tree
                unzip zip tar gzip
                jq yq
                
                # Build tools
                base-devel make cmake gcc
                pkgconf autoconf automake
                
                # Terminal tools
                zsh tmux
                fzf ripgrep fd bat
                
                # Network tools
                net-tools bind-tools
                openssh
                
                # System tools
                gnupg
            )
            ;;
    esac
    
    local pm=$(get_package_manager)
    
    for package in "${packages[@]}"; do
        if ! $pm $package; then
            print_warning "Failed to install $package"
        fi
    done
    
    print_success "Base packages installed"
}

# Install shell environment
install_shell_environment() {
    print_status "Installing shell environment..."
    
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
    
    # Install Powerlevel10k
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    fi
    
    # Link Zsh configuration
    if [[ -d "$DOTFILES_ROOT/zsh" ]]; then
        ln -sf "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"
        for file in "$DOTFILES_ROOT/zsh"/*.zsh; do
            [[ -f "$file" ]] && ln -sf "$file" "$HOME/.$(basename "$file")"
        done
    fi
    
    print_success "Shell environment installed"
}

# Install fonts
install_fonts() {
    print_status "Installing Nerd Fonts..."
    
    local fonts=(
        "FiraCode"
        "JetBrainsMono"
        "Hack"
        "Meslo"
    )
    
    local version="3.2.1"
    
    for font in "${fonts[@]}"; do
        if ! fc-list | grep -qi "$font"; then
            print_status "Installing $font Nerd Font..."
            local zip_file="${font}.zip"
            local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
            
            if wget -q "$url" -O "/tmp/${zip_file}"; then
                unzip -q -o "/tmp/${zip_file}" -d "$FONTS"
                rm "/tmp/${zip_file}"
                print_success "$font installed"
            else
                print_warning "Failed to download $font"
            fi
        fi
    done
    
    # Remove Windows compatible fonts
    find "$FONTS" -name '*Windows Compatible*' -delete
    
    # Update font cache
    fc-cache -fv
    
    print_success "Fonts installed"
}

# Install development tools
install_development_tools() {
    print_status "Installing development tools..."
    
    # Python environment
    if [[ -f "$SCRIPT_DIR/python.sh" ]]; then
        source "$SCRIPT_DIR/python.sh"
    else
        # Basic Python setup
        local pm=$(get_package_manager)
        $pm python3 python3-pip python3-venv python3-dev
        
        # Install pyenv
        if ! command_exists pyenv; then
            curl https://pyenv.run | bash
        fi
    fi
    
    # Node.js
    if ! command_exists node; then
        print_status "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        npm install -g yarn pnpm
    fi
    
    # Docker
    print_status "Would you like to install Docker? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        case "$DISTRO_FAMILY" in
            debian)
                # Remove old versions
                sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
                
                # Add Docker's official GPG key
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                
                # Add repository
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                
                # Install Docker
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
            arch)
                sudo pacman -S --noconfirm docker docker-compose
                ;;
        esac
        
        # Add user to docker group
        sudo usermod -aG docker "$USER"
        sudo systemctl enable docker
        sudo systemctl start docker
        
        print_success "Docker installed"
    fi
    
    print_success "Development tools installed"
}

# Window Manager Installation Menu
install_window_manager() {
    echo
    echo -e "${MAGENTA}Select window manager to install:${NC}"
    echo "  1) i3 (X11 tiling window manager)"
    echo "  2) Hyprland (Wayland compositor)"
    echo "  3) Both"
    echo "  4) Skip"
    echo
    read -rp "Enter your choice: " wm_choice
    
    case "$wm_choice" in
        1)
            if [[ -f "$SCRIPT_DIR/i3.sh" ]]; then
                source "$SCRIPT_DIR/i3.sh"
            else
                install_i3_wm
            fi
            ;;
        2)
            if [[ -f "$SCRIPT_DIR/hyprland.sh" ]]; then
                source "$SCRIPT_DIR/hyprland.sh"
            else
                install_hyprland
            fi
            ;;
        3)
            if [[ -f "$SCRIPT_DIR/i3.sh" ]]; then
                source "$SCRIPT_DIR/i3.sh"
            else
                install_i3_wm
            fi
            if [[ -f "$SCRIPT_DIR/hyprland.sh" ]]; then
                source "$SCRIPT_DIR/hyprland.sh"
            else
                install_hyprland
            fi
            ;;
        4)
            print_status "Skipping window manager installation"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Basic i3 installation
install_i3_wm() {
    print_status "Installing i3 window manager..."
    
    local packages=(
        i3-gaps i3blocks i3lock i3status
        polybar rofi dunst picom
        feh arandr lxappearance
        kitty alacritty
        thunar gvfs tumbler
        pavucontrol pasystray
        network-manager-applet
        blueman
        flameshot
        xclip xsel
        brightnessctl playerctl
    )
    
    case "$DISTRO_FAMILY" in
        arch)
            packages=(
                i3-gaps i3blocks i3lock i3status
                polybar rofi dunst picom
                feh arandr lxappearance-gtk3
                kitty alacritty
                thunar gvfs tumbler
                pavucontrol pasystray
                network-manager-applet
                blueman
                flameshot
                xclip xsel
                brightnessctl playerctl
            )
            ;;
    esac
    
    local pm=$(get_package_manager)
    for package in "${packages[@]}"; do
        $pm $package || print_warning "Failed to install $package"
    done
    
    # Link i3 configurations
    if [[ -d "$DOTFILES_ROOT/linux/.config/i3" ]]; then
        ln -sf "$DOTFILES_ROOT/linux/.config/i3" "$CONFIG/i3"
    fi
    
    if [[ -d "$DOTFILES_ROOT/linux/.config/polybar" ]]; then
        ln -sf "$DOTFILES_ROOT/linux/.config/polybar" "$CONFIG/polybar"
    fi
    
    print_success "i3 window manager installed"
}

# Basic Hyprland installation
install_hyprland() {
    print_status "Installing Hyprland..."
    
    case "$DISTRO_FAMILY" in
        debian)
            print_warning "Hyprland installation on Debian-based systems requires manual compilation"
            print_status "Visit: https://wiki.hyprland.org/Getting-Started/Installation/"
            ;;
        arch)
            local pm=$(get_package_manager)
            $pm hyprland waybar wofi \
                swaylock swayidle swaybg \
                grim slurp wl-clipboard \
                mako kitty \
                thunar gvfs tumbler \
                pavucontrol blueman \
                brightnessctl playerctl
            ;;
    esac
    
    # Link Hyprland configurations
    if [[ -d "$DOTFILES_ROOT/linux/.config/hypr" ]]; then
        ln -sf "$DOTFILES_ROOT/linux/.config/hypr" "$CONFIG/hypr"
    fi
    
    print_success "Hyprland installed"
}

# Create symlinks
create_symlinks() {
    print_status "Creating configuration symlinks..."
    
    if [[ -f "$SCRIPT_DIR/symlinks.sh" ]]; then
        source "$SCRIPT_DIR/symlinks.sh"
    else
        # Basic symlinks
        local configs=(
            "git/.gitconfig:$HOME/.gitconfig"
            ".tmux.conf:$HOME/.tmux.conf"
            "linux/.config/nvim:$CONFIG/nvim"
            "linux/.config/kitty:$CONFIG/kitty"
        )
        
        for config in "${configs[@]}"; do
            local src="${config%%:*}"
            local dst="${config##*:}"
            
            if [[ -e "$DOTFILES_ROOT/$src" ]]; then
                # Backup existing file
                if [[ -e "$dst" ]] && [[ ! -L "$dst" ]]; then
                    mv "$dst" "${dst}.backup"
                fi
                
                # Create symlink
                ln -sf "$DOTFILES_ROOT/$src" "$dst"
                print_success "Linked: $src -> $dst"
            fi
        done
    fi
}

# Post-installation tasks
post_installation() {
    print_status "Running post-installation tasks..."
    
    # Set Zsh as default shell
    if command_exists zsh; then
        print_status "Would you like to set Zsh as your default shell? (Y/n)"
        read -r response
        if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
            chsh -s "$(which zsh)"
            print_success "Default shell changed to Zsh"
        fi
    fi
    
    # Install tmux plugins
    if [[ -f "$HOME/.tmux.conf" ]] && command_exists tmux; then
        if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
            print_success "TPM installed. Press prefix + I in tmux to install plugins"
        fi
    fi
    
    print_success "Post-installation tasks completed"
}

# Main installation menu
show_main_menu() {
    echo
    echo -e "${CYAN}╔═══════════════════════════════════════════════════╗"
    echo -e "║          Linux Desktop Installation Menu          ║"
    echo -e "╚═══════════════════════════════════════════════════╝${NC}"
    echo
    echo "  1) Full Installation (Recommended)"
    echo "  2) Base System Only"
    echo "  3) Shell Environment Only"
    echo "  4) Development Tools Only"
    echo "  5) Window Manager Only"
    echo "  6) Fonts Only"
    echo "  q) Quit"
    echo
    read -rp "Enter your choice: " choice
    
    case "$choice" in
        1)
            update_system
            install_aur_helper
            install_base_packages
            install_shell_environment
            install_fonts
            install_development_tools
            install_window_manager
            create_symlinks
            post_installation
            ;;
        2)
            update_system
            install_aur_helper
            install_base_packages
            ;;
        3)
            install_shell_environment
            create_symlinks
            ;;
        4)
            install_development_tools
            ;;
        5)
            install_window_manager
            ;;
        6)
            install_fonts
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
    print_status "Starting Linux Desktop Installation"
    
    # Detect distribution
    detect_distro
    
    # Create directories
    create_directories
    
    # Configure sudoers
    configure_sudoers
    
    # Show main menu
    show_main_menu
    
    print_success "Installation completed!"
    echo
    print_status "Next steps:"
    echo "  1. Log out and back in for shell changes"
    echo "  2. Run 'p10k configure' to set up your prompt"
    echo "  3. Install tmux plugins: prefix + I"
    echo "  4. Review window manager configurations"
}

# Run main function
main "$@"