#!/bin/bash

# ============================================================================
# Desktop Terminal Environment Installer
# ============================================================================
# This script installs desktop-specific terminal components:
# - Nerd Fonts for proper icon support
# - Kitty terminal emulator with Tokyo Night Moon theme
# 
# For server environments, use install-shell.sh instead.
#
# Usage:
#   ./install-desktop-terminal.sh
#   curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-desktop-terminal.sh | bash
# ============================================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# Global Configuration
# ────────────────────────────────────────────────────────────────────────────

SCRIPT_NAME="Desktop Terminal Installer"
LOG_FILE="/tmp/desktop-terminal-install-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ────────────────────────────────────────────────────────────────────────────
# Utility Functions
# ────────────────────────────────────────────────────────────────────────────

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# OS Detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v lsb_release >/dev/null 2>&1; then
            local distro
            distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
            echo "$distro"
        elif [[ -f /etc/os-release ]]; then
            local distro
            distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
            echo "$distro"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Font Installation
# ────────────────────────────────────────────────────────────────────────────

install_fonts() {
    print_status "Installing Nerd Fonts..."

    local FONT_DIR
    case "$OS" in
        ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|opensuse*|sles)
            FONT_DIR="$HOME/.local/share/fonts"
            ;;
        macos)
            FONT_DIR="$HOME/Library/Fonts"
            ;;
        *)
            print_warning "Skipping font installation for unsupported OS: $OS"
            return 0
            ;;
    esac

    mkdir -p "$FONT_DIR"

    # Check if fonts are already installed
    if ls "$FONT_DIR"/*Nerd* &> /dev/null; then
        print_success "Nerd Fonts already installed"
        return 0
    fi

    # Install multiple Nerd Fonts for better compatibility
    local fonts=("FiraCode" "JetBrainsMono" "Iosevka" "SourceCodePro")
    
    for font in "${fonts[@]}"; do
        print_status "Installing $font Nerd Font..."
        
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
        if curl -L -o "/tmp/${font}.zip" "$font_url"; then
            unzip -q -o "/tmp/${font}.zip" -d "$FONT_DIR" 2>/dev/null || true
            rm "/tmp/${font}.zip"
            print_success "$font Nerd Font installed"
        else
            print_warning "Failed to download $font Nerd Font"
        fi
    done

    # Update font cache on Linux
    if [[ "$OS" != "macos" ]]; then
        fc-cache -fv > /dev/null 2>&1 || true
    fi

    print_success "Nerd Fonts installation completed"
}

# ────────────────────────────────────────────────────────────────────────────
# Kitty Terminal Installation
# ────────────────────────────────────────────────────────────────────────────

install_kitty() {
    print_status "Installing Kitty terminal..."

    if command -v kitty &> /dev/null; then
        print_success "Kitty is already installed ($(kitty --version))"
        return 0
    fi

    case "$OS" in
        ubuntu|debian)
            # Install via official binary for latest version
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

            # Create desktop integration
            sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
            sudo ln -sf ~/.local/kitty.app/bin/kitten /usr/local/bin/

            # Create desktop entry
            mkdir -p ~/.local/share/applications
            cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
            cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/

            # Update icon paths
            sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
                ~/.local/share/applications/kitty*.desktop
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y kitty || {
                # Fallback to official installer
                curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
                sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
                sudo ln -sf ~/.local/kitty.app/bin/kitten /usr/local/bin/
            }
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm kitty
            ;;
        macos)
            if command -v brew &> /dev/null; then
                brew install --cask kitty
            else
                print_error "Homebrew not found. Please install Homebrew first."
                return 1
            fi
            ;;
        *)
            print_error "Unsupported OS for Kitty installation: $OS"
            return 1
            ;;
    esac

    print_success "Kitty terminal installed"
}

configure_kitty() {
    print_status "Configuring Kitty terminal..."

    # Create kitty config directory
    mkdir -p "$HOME/.config/kitty"

    # Backup existing config
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]] && [[ ! -L "$HOME/.config/kitty/kitty.conf" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$HOME/.config/kitty/kitty.conf" "$BACKUP_DIR/kitty.conf" 2>/dev/null || true
        print_status "Backed up existing kitty.conf"
    fi

    # Create kitty configuration
    cat > "$HOME/.config/kitty/kitty.conf" << 'KITTY_EOF'
# Kitty Configuration
# Documentation: https://sw.kovidgoyal.net/kitty/conf/

# Theme
include current-theme.conf

# Fonts
font_family      FiraCode Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        14.0

# Window
remember_window_size  yes
initial_window_width  1200
initial_window_height 800
window_padding_width  8
hide_window_decorations yes

# Tab bar
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
active_tab_font_style bold
inactive_tab_font_style normal

# Terminal bell
enable_audio_bell no
visual_bell_duration 0.0

# Mouse
mouse_hide_wait 3.0
url_color #4fd6be
url_style curly

# Performance tuning
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Advanced
allow_remote_control yes
listen_on unix:/tmp/mykitty

# Shell integration
shell_integration enabled

# Keyboard shortcuts
map ctrl+shift+enter launch --cwd=current
map cmd+enter       launch --cwd=current
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+q     close_window
map ctrl+shift+]     next_window
map ctrl+shift+[     previous_window

# Clipboard
map ctrl+shift+c   copy_to_clipboard
map ctrl+shift+v   paste_from_clipboard
KITTY_EOF

    # Create Tokyo Night Moon theme file
    cat > "$HOME/.config/kitty/current-theme.conf" << 'THEME_EOF'
# Tokyo Night Moon theme for Kitty

# Basic colors
background #222436
foreground #c8d3f5
selection_background #2d3f76
selection_foreground #c8d3f5
url_color #4fd6be
cursor #c8d3f5
cursor_text_color #222436

# Border colors
active_border_color #82aaff
inactive_border_color #27354c
bell_border_color #e0af68

# Tab bar colors
active_tab_background #82aaff
active_tab_foreground #1e2030
inactive_tab_background #2f334d
inactive_tab_foreground #545c7e
tab_bar_background #1e2030

# Normal colors
color0 #1b1d2b
color1 #ff757f
color2 #c3e88d
color3 #ffc777
color4 #82aaff
color5 #c099ff
color6 #86e1fc
color7 #c8d3f5

# Bright colors
color8 #444a73
color9 #ff757f
color10 #c3e88d
color11 #ffc777
color12 #82aaff
color13 #c099ff
color14 #86e1fc
color15 #c8d3f5

# Extended colors
color16 #ff966c
color17 #c53b53
THEME_EOF

    print_success "Kitty configured with Tokyo Night Moon theme"
}

# ────────────────────────────────────────────────────────────────────────────
# Summary and Next Steps
# ────────────────────────────────────────────────────────────────────────────

show_summary() {
    echo
    echo "========================================"
    echo "Desktop Terminal Installation Summary"
    echo "========================================"
    echo
    print_success "✓ Nerd Fonts installed (FiraCode, JetBrainsMono, Iosevka, SourceCodePro)"
    print_success "✓ Kitty terminal installed and configured"
    echo
    print_status "📋 Configuration files:"
    echo "  • ~/.config/kitty/kitty.conf - Kitty terminal config"
    echo "  • ~/.config/kitty/current-theme.conf - Tokyo Night Moon theme"
    echo
    print_status "📁 Log file: $LOG_FILE"
    if [[ -d "$BACKUP_DIR" ]]; then
        print_status "📁 Backup directory: $BACKUP_DIR"
    fi
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Close current terminal and open Kitty"
    echo "  2. Fonts should be automatically detected"
    echo "  3. Run 'kitty +kitten themes' to browse more themes"
    echo "  4. For shell configuration, run install-shell.sh"
    echo
    print_success "Desktop terminal environment setup complete!"
    echo
}

# ────────────────────────────────────────────────────────────────────────────
# Main Installation Function
# ────────────────────────────────────────────────────────────────────────────

main() {
    echo "========================================"
    echo "$SCRIPT_NAME"
    echo "========================================"
    echo

    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    print_status "Installation started at $(date)"
    print_status "Log file: $LOG_FILE"
    
    # Detect OS
    OS=$(detect_os)
    print_status "Detected OS: $OS"

    # Check for desktop environment
    if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$OS" != "macos" ]]; then
        print_warning "No desktop environment detected. This installer is for desktop systems."
        print_warning "For server environments, use install-shell.sh instead."
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installation cancelled"
            exit 0
        fi
    fi

    # Install components
    install_fonts
    install_kitty
    configure_kitty

    # Show summary
    show_summary
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi