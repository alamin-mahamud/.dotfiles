#!/bin/bash

# Enhanced Kitty Terminal Installer with Display Detection
# Standalone installer for Kitty terminal with comprehensive OS support
# Includes dynamic font sizing based on display configuration
# Features: Kitty installation, theme support, display detection, font management
# Usage: ./kitty-installer.sh or curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/kitty-installer.sh | bash

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/kitty-installer-$(date +%Y%m%d_%H%M%S).log"

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

# Detect OS and distro
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    DISTRO="macos"
    DISTRO_VERSION=$(sw_vers -productVersion)
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS="${ID,,}"
    DISTRO="${ID,,}"
    DISTRO_VERSION="${VERSION_ID}"
    
    # Normalize distro families
    case "$OS" in
    ubuntu | debian | linuxmint | pop | kali | parrot)
      DISTRO_FAMILY="debian"
      ;;
    fedora | centos | rhel | rocky | almalinux)
      DISTRO_FAMILY="redhat"
      ;;
    arch | manjaro | endeavouros)
      DISTRO_FAMILY="arch"
      ;;
    opensuse* | sles)
      DISTRO_FAMILY="suse"
      ;;
    alpine)
      DISTRO_FAMILY="alpine"
      ;;
    *)
      DISTRO_FAMILY="unknown"
      ;;
    esac
  else
    print_error "Unsupported operating system"
    exit 1
  fi
  
  print_success "Detected OS: $OS ($DISTRO $DISTRO_VERSION)"
}

# Check if command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Install Kitty terminal
install_kitty() {
  print_status "Installing Kitty terminal..."

  if command -v kitty &>/dev/null; then
    print_success "Kitty is already installed ($(kitty --version))"
    return 0
  fi

  case "$OS" in
  ubuntu | debian)
    # Install via official binary
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

    # Create desktop integration
    sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
    sudo ln -sf ~/.local/kitty.app/bin/kitten /usr/local/bin/

    # Create desktop entry
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
    cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/

    # Update icon cache
    sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
      ~/.local/share/applications/kitty*.desktop
    ;;
  fedora | centos | rhel | rocky | almalinux)
    sudo dnf install -y kitty || {
      # Fallback to official installer
      curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
      sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
      sudo ln -sf ~/.local/kitty.app/bin/kitten /usr/local/bin/
    }
    ;;
  arch | manjaro)
    sudo pacman -S --noconfirm kitty
    ;;
  macos)
    if command_exists brew; then
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

# Install Nerd Fonts for Kitty
install_fonts() {
  print_status "Installing Nerd Fonts for Kitty..."
  
  case "$OS" in
  ubuntu | debian | fedora | centos | rhel | rocky | almalinux | arch | manjaro | opensuse* | sles)
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
  if ls "$FONT_DIR"/*Nerd* &>/dev/null; then
    print_success "Nerd Fonts already installed"
    return 0
  fi
  
  # Install JetBrains Mono Nerd Font (preferred for Kitty)
  local font="JetBrainsMono"
  print_status "Installing $font Nerd Font..."
  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
  
  if curl -L -o "/tmp/${font}.zip" "$font_url"; then
    unzip -q -o "/tmp/${font}.zip" -d "$FONT_DIR"
    rm "/tmp/${font}.zip"
    print_success "$font Nerd Font installed"
  else
    print_warning "Failed to download $font Nerd Font"
  fi
  
  # Update font cache on Linux
  if [[ "$OS" != "macos" ]]; then
    fc-cache -fv >/dev/null 2>&1
  fi
  
  print_success "Fonts installed for Kitty"
}

# Create display detection script
create_display_detector() {
  print_status "Creating display detection script..."
  
  mkdir -p "$HOME/.config/kitty"
  
  # Create the display detector script (same as before but now part of kitty-installer)
  cat > "$HOME/.config/kitty/display-detector.sh" <<'DETECTOR_EOF'
#!/bin/bash

# Kitty Display Detector - Automatically adjusts font size based on connected displays
# Usage: ./display-detector.sh [--verbose]

KITTY_CONFIG_DIR="$HOME/.config/kitty"
KITTY_CONFIG="$KITTY_CONFIG_DIR/kitty.conf"
DISPLAY_CONFIG="$KITTY_CONFIG_DIR/display.conf"
VERBOSE=false

if [[ "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

# Detect display configuration on macOS
detect_displays_macos() {
    local display_info=$(system_profiler SPDisplaysDataType 2>/dev/null)
    local resolutions=$(echo "$display_info" | grep "Resolution:" | sed 's/.*Resolution: //')
    local display_count=$(echo "$resolutions" | wc -l | tr -d ' ')
    
    log "Detected $display_count display(s)"
    
    # Parse display information
    local primary_resolution=$(echo "$resolutions" | head -1)
    local primary_width=$(echo "$primary_resolution" | awk '{print $1}')
    local primary_height=$(echo "$primary_resolution" | awk '{print $3}')
    
    log "Primary display: ${primary_width}x${primary_height}"
    
    # Determine display type and recommended font size
    local font_size=11.0
    local display_type="unknown"
    
    if [[ $display_count -eq 1 ]]; then
        # Single display
        if [[ "$primary_resolution" == *"Retina"* ]]; then
            # MacBook internal display
            display_type="laptop"
            font_size=11.0
        elif [[ $primary_width -ge 3440 ]]; then
            # Ultra-wide monitor (34" or larger)
            display_type="ultrawide"
            font_size=15.0
        elif [[ $primary_width -ge 2560 && $primary_width -lt 3440 ]]; then
            # 27" 4K or 1440p monitor
            display_type="external-27"
            font_size=13.0
        elif [[ $primary_width -ge 1920 ]]; then
            # Standard 1080p monitor
            display_type="external-1080p"
            font_size=12.0
        fi
    else
        # Multiple displays - check if laptop is closed (clamshell mode)
        local laptop_display=$(echo "$display_info" | grep -B5 "Built-in" | grep "Resolution:" | head -1)
        
        if [[ -z "$laptop_display" ]] || [[ "$display_info" == *"Mirror: On"* ]]; then
            # Laptop closed or mirroring - use external display settings
            if [[ $primary_width -ge 3440 ]]; then
                display_type="ultrawide-clamshell"
                font_size=16.0
            elif [[ $primary_width -ge 2560 ]]; then
                display_type="external-clamshell"
                font_size=14.0
            else
                display_type="external-clamshell"
                font_size=13.0
            fi
        else
            # Multiple active displays - use medium size for balance
            display_type="multi-display"
            font_size=13.0
        fi
    fi
    
    echo "$display_type:$font_size"
}

# Detect display configuration on Linux
detect_displays_linux() {
    if command -v xrandr &>/dev/null; then
        local connected_displays=$(xrandr | grep " connected" | wc -l)
        local primary_display=$(xrandr | grep "primary" | awk '{print $4}' | cut -d'+' -f1)
        
        if [[ -z "$primary_display" ]]; then
            primary_display=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d'+' -f1)
        fi
        
        local primary_width=$(echo "$primary_display" | cut -d'x' -f1)
        local primary_height=$(echo "$primary_display" | cut -d'x' -f2)
        
        log "Detected $connected_displays display(s)"
        log "Primary display: ${primary_width}x${primary_height}"
        
        # Similar logic to macOS
        local font_size=11.0
        local display_type="unknown"
        
        if [[ $connected_displays -eq 1 ]]; then
            if [[ $primary_width -le 1920 ]]; then
                display_type="laptop"
                font_size=11.0
            elif [[ $primary_width -ge 3440 ]]; then
                display_type="ultrawide"
                font_size=15.0
            elif [[ $primary_width -ge 2560 ]]; then
                display_type="external-27"
                font_size=13.0
            else
                display_type="external-1080p"
                font_size=12.0
            fi
        else
            display_type="multi-display"
            font_size=13.0
        fi
        
        echo "$display_type:$font_size"
    else
        log "xrandr not available - using defaults"
        echo "unknown:11.0"
    fi
}

# Apply font size to Kitty config
apply_font_size() {
    local font_size=$1
    local display_type=$2
    
    # Create display-specific config
    cat > "$DISPLAY_CONFIG" << EOF
# Auto-generated by display-detector.sh
# Display Type: $display_type
# Generated: $(date)

font_size $font_size

# Display-specific adjustments
EOF
    
    # Add display-specific settings
    case "$display_type" in
        ultrawide*)
            echo "# Ultra-wide display optimizations" >> "$DISPLAY_CONFIG"
            echo "window_padding_width 15" >> "$DISPLAY_CONFIG"
            ;;
        laptop)
            echo "# Laptop display optimizations" >> "$DISPLAY_CONFIG"
            echo "window_padding_width 8" >> "$DISPLAY_CONFIG"
            ;;
        external-27)
            echo "# 27-inch display optimizations" >> "$DISPLAY_CONFIG"
            echo "window_padding_width 12" >> "$DISPLAY_CONFIG"
            ;;
    esac
    
    log "Applied font size $font_size for $display_type"
}

# Reload Kitty configuration
reload_kitty() {
    if pgrep -x "kitty" > /dev/null; then
        # Send remote control command to reload config
        kitty @ load-config 2>/dev/null || true
        log "Kitty configuration reloaded"
    fi
}

# Main execution
main() {
    # Detect OS
    OS=$(uname -s)
    
    case "$OS" in
        Darwin)
            result=$(detect_displays_macos)
            ;;
        Linux)
            result=$(detect_displays_linux)
            ;;
        *)
            log "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    display_type=$(echo "$result" | cut -d':' -f1)
    font_size=$(echo "$result" | cut -d':' -f2)
    
    log "Display type: $display_type, Font size: $font_size"
    
    # Apply the configuration
    apply_font_size "$font_size" "$display_type"
    
    # Reload Kitty if running
    reload_kitty
    
    if [[ "$VERBOSE" == true ]]; then
        echo "Display configuration applied:"
        echo "  Type: $display_type"
        echo "  Font size: $font_size"
    fi
}

main "$@"
DETECTOR_EOF

  chmod +x "$HOME/.config/kitty/display-detector.sh"
  print_success "Display detector script created"
}

# Create display-specific configurations
create_display_configs() {
  print_status "Creating display-specific Kitty configurations..."
  
  mkdir -p "$HOME/.config/kitty"
  
  # Laptop configuration
  cat > "$HOME/.config/kitty/laptop.conf" <<'EOF'
# Kitty configuration for laptop display (13" MacBook Pro)
# Optimized for 2560x1600 Retina display

font_size 11.0
window_padding_width 8
window_margin_width 2

# Smaller UI elements for laptop screen
tab_bar_min_tabs 2
tab_title_template "{index}: {title[:15]}"

# Optimize for battery life on laptop
repaint_delay 10
input_delay 3
sync_to_monitor yes
EOF

  # External 34" ultra-wide configuration
  cat > "$HOME/.config/kitty/external-34.conf" <<'EOF'
# Kitty configuration for 34" ultra-wide monitor
# Optimized for 3440x1440 resolution

font_size 15.0
window_padding_width 15
window_margin_width 5

# Larger UI elements for big screen
tab_bar_min_tabs 1
tab_title_template "{index}: {title}"

# More space for ultra-wide
remember_window_size no
initial_window_width  2400
initial_window_height 1200

# Better performance for external display
repaint_delay 8
input_delay 2
EOF

  # 4K display configuration
  cat > "$HOME/.config/kitty/external-4k.conf" <<'EOF'
# Kitty configuration for 4K displays
# Optimized for 3840x2160 or higher resolution

font_size 18.0
window_padding_width 20
window_margin_width 8

# Scaled UI for 4K
tab_bar_min_tabs 1
tab_title_template "{index}: {title}"
tab_bar_edge bottom
tab_bar_style powerline

# Window sizing for 4K
remember_window_size no
initial_window_width  2560
initial_window_height 1440

# Optimize for high resolution
repaint_delay 6
input_delay 2
EOF

  # Dual display configuration
  cat > "$HOME/.config/kitty/dual-display.conf" <<'EOF'
# Kitty configuration for dual display setup
# Balanced settings for mixed display environments

font_size 13.0
window_padding_width 12
window_margin_width 4

# Moderate UI sizing
tab_bar_min_tabs 2
tab_title_template "{index}: {title[:20]}"

# Balanced window size
remember_window_size no
initial_window_width  2000
initial_window_height 1100

# Balanced performance
repaint_delay 8
input_delay 2
EOF

  print_success "Display-specific configurations created"
}

# Configure Kitty with display detection support
configure_kitty() {
  print_status "Configuring Kitty terminal with display detection..."

  # Create kitty config directory
  mkdir -p "$HOME/.config/kitty"

  # Backup existing config
  if [[ -f "$HOME/.config/kitty/kitty.conf" ]] && [[ ! -L "$HOME/.config/kitty/kitty.conf" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$HOME/.config/kitty/kitty.conf" "$BACKUP_DIR/kitty.conf" 2>/dev/null || true
    print_status "Backed up existing kitty.conf"
  fi

  # Create main kitty configuration with display detection support
  cat >"$HOME/.config/kitty/kitty.conf" <<'KITTY_EOF'
# ───────────────────────────────────────────────────────────────
# Kitty Terminal Configuration with Display Detection
# ───────────────────────────────────────────────────────────────

# ─── Display-specific Configuration ───────────────────────────
# Auto-generated display configuration (created by display-detector.sh)
# Run ~/.config/kitty/display-detector.sh to auto-detect display
include display.conf

# ─── Appearance ────────────────────────────────────────────────
font_family      JetBrains Mono
bold_font        auto
italic_font      auto
bold_italic_font auto

# Default font_size (overridden by display.conf)
font_size        11.0

background_opacity 0.95
background_blur    0

enable_audio_bell no

cursor_shape block
cursor_blink_interval 0
cursor_stop_blinking_after 0

# ─── Window & Layout ───────────────────────────────────────────
window_padding_width 10
window_margin_width 2
hide_window_decorations no

remember_window_size no
initial_window_width  1800
initial_window_height 1100

tab_bar_edge bottom
tab_bar_align left
tab_bar_style powerline
tab_powerline_style slanted
active_tab_font_style bold
inactive_tab_font_style normal

# ─── Scrolling & History ───────────────────────────────────────
scrollback_lines     10000
wheel_scroll_multiplier 3.0
scrollback_pager bash -c 'less -R'

# ─── Mouse & URL handling ─────────────────────────────────────
mouse_hide_wait -1
map ctrl+left click open_url
mouse_map ctrl+left press ungrabbed,grabbed mouse_click_url

# ─── Font Size Quick Presets ──────────────────────────────────
map cmd+0           remote_control set-font-size 0     # Reset to default
map cmd+1           remote_control set-font-size 11    # Laptop size
map cmd+2           remote_control set-font-size 13    # Medium size
map cmd+3           remote_control set-font-size 15    # Large (34" monitor)
map cmd+4           remote_control set-font-size 17    # Extra large
map cmd+5           remote_control set-font-size 19    # 4K display
map cmd+equal       change_font_size all +1.0          # Increase
map cmd+minus       change_font_size all -1.0          # Decrease

# Linux font size shortcuts
map ctrl+shift+equal    change_font_size all +1.0
map ctrl+shift+minus    change_font_size all -1.0
map ctrl+shift+0        change_font_size all 0

# ─── Keyboard Shortcuts (macOS + Linux) ───────────────────────
map ctrl+shift+enter launch --cwd=current          # open new window
map cmd+enter       launch --cwd=current           # macOS-specific
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+q     close_window
map ctrl+shift+]     next_window
map ctrl+shift+[     previous_window
map ctrl+shift+l     next_layout

# ─── Clipboard & Copy/Paste ──────────────────────────────────
map ctrl+shift+c   copy_to_clipboard
map ctrl+shift+v   paste_from_clipboard

# ─── Remote control ───────────────────────────────────────────
# enables `kitty @` commands for display detection
allow_remote_control yes

# ─── Theme ─────────────────────────────────────────────────────
# Tokyo Night theme (can be changed with `kitty +kitten themes`)
include current-theme.conf
KITTY_EOF

  # Create a default theme file (Tokyo Night)
  cat >"$HOME/.config/kitty/current-theme.conf" <<'THEME_EOF'
# Tokyo Night theme for Kitty

background #1a1b26
foreground #c0caf5
selection_background #33467c
selection_foreground #c0caf5
url_color #73daca
cursor #c0caf5

# Tab bar
active_tab_background #7aa2f7
active_tab_foreground #1f2335
inactive_tab_background #292e42
inactive_tab_foreground #545c7e
tab_bar_background #15161e

# Normal colors
color0 #15161e
color1 #f7768e
color2 #9ece6a
color3 #e0af68
color4 #7aa2f7
color5 #bb9af7
color6 #7dcfff
color7 #a9b1d6

# Bright colors
color8 #414868
color9 #f7768e
color10 #9ece6a
color11 #e0af68
color12 #7aa2f7
color13 #bb9af7
color14 #7dcfff
color15 #c0caf5
THEME_EOF

  # Create initial display.conf with default settings
  cat >"$HOME/.config/kitty/display.conf" <<'EOF'
# Default display configuration
# Run ~/.config/kitty/display-detector.sh to auto-detect your display
font_size 11.0
window_padding_width 10
EOF

  print_success "Kitty configuration created with display detection support"
}

# Add shell aliases and functions
add_shell_aliases() {
  print_status "Adding Kitty display management aliases to shell..."
  
  # Determine shell config file
  local shell_config=""
  if [[ -f "$HOME/.zshrc" ]]; then
    shell_config="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    shell_config="$HOME/.bashrc"
  else
    print_warning "No shell configuration file found, skipping aliases"
    return 0
  fi
  
  # Check if aliases already exist
  if grep -q "Kitty Display Management" "$shell_config" 2>/dev/null; then
    print_success "Kitty aliases already configured"
    return 0
  fi
  
  # Add aliases to shell config
  cat >> "$shell_config" <<'ALIASES_EOF'

# ─── Kitty Display Management ──────────────────────────────────
# Auto-detect display on shell startup (optional - uncomment to enable)
# [[ -x "$HOME/.config/kitty/display-detector.sh" ]] && "$HOME/.config/kitty/display-detector.sh"

# Quick font size switching aliases
alias kitty-laptop='kitty @ set-font-size 11 && echo "Switched to laptop font size (11pt)"'
alias kitty-medium='kitty @ set-font-size 13 && echo "Switched to medium font size (13pt)"'
alias kitty-external='kitty @ set-font-size 15 && echo "Switched to external monitor font size (15pt)"'
alias kitty-4k='kitty @ set-font-size 18 && echo "Switched to 4K display font size (18pt)"'
alias kitty-detect='~/.config/kitty/display-detector.sh --verbose'

# Quick config switching function
kitty-config() {
    local config="$1"
    if [[ -z "$config" ]]; then
        echo "Usage: kitty-config [laptop|external-34|external-4k|dual-display]"
        return 1
    fi
    
    local config_file="$HOME/.config/kitty/${config}.conf"
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$HOME/.config/kitty/display.conf"
        kitty @ load-config
        echo "Switched to $config configuration"
    else
        echo "Configuration not found: $config_file"
        return 1
    fi
}
ALIASES_EOF

  print_success "Shell aliases added to $shell_config"
}

# Print usage instructions
print_usage_instructions() {
  echo
  echo "════════════════════════════════════════════════════════════════"
  echo "                 🎨 Kitty Display Detection Setup Complete!"
  echo "════════════════════════════════════════════════════════════════"
  echo
  echo "📺 DISPLAY DETECTION FEATURES:"
  echo "────────────────────────────────────────────────────────────────"
  echo
  echo "🔍 Automatic Display Detection:"
  echo "   • Run: kitty-detect"
  echo "   • Automatically detects your display and adjusts font size"
  echo "   • Supports laptop, external, ultra-wide, and 4K displays"
  echo
  echo "⌨️  Quick Font Size Shortcuts (in Kitty):"
  echo "   • Cmd+1 → Laptop size (11pt)"
  echo "   • Cmd+2 → Medium size (13pt)"
  echo "   • Cmd+3 → Large size (15pt) - Great for 34\" monitors"
  echo "   • Cmd+4 → Extra large (17pt)"
  echo "   • Cmd+5 → 4K display (19pt)"
  echo "   • Cmd+0 → Reset to auto-detected size"
  echo "   • Cmd+= → Increase font size"
  echo "   • Cmd+- → Decrease font size"
  echo
  echo "   Linux users: Replace 'Cmd' with 'Ctrl+Shift'"
  echo
  echo "🖥️  Shell Aliases (use in any terminal):"
  echo "   • kitty-laptop    → Switch to laptop font (11pt)"
  echo "   • kitty-medium    → Switch to medium font (13pt)"
  echo "   • kitty-external  → Switch to external monitor font (15pt)"
  echo "   • kitty-4k        → Switch to 4K display font (18pt)"
  echo "   • kitty-detect    → Run display auto-detection"
  echo
  echo "🎯 Configuration Profiles:"
  echo "   • kitty-config laptop       → Load laptop profile"
  echo "   • kitty-config external-34  → Load 34\" monitor profile"
  echo "   • kitty-config external-4k  → Load 4K display profile"
  echo "   • kitty-config dual-display → Load dual monitor profile"
  echo
  echo "📁 Configuration Files:"
  echo "   • Main config: ~/.config/kitty/kitty.conf"
  echo "   • Display detector: ~/.config/kitty/display-detector.sh"
  echo "   • Current display config: ~/.config/kitty/display.conf"
  echo "   • Profile configs: ~/.config/kitty/[laptop|external-34|external-4k|dual-display].conf"
  echo
  echo "🔧 Advanced Usage:"
  echo "   • Auto-detect on terminal start: Uncomment the line in ~/.zshrc"
  echo "   • Manual detection: ~/.config/kitty/display-detector.sh --verbose"
  echo "   • Edit profiles: Modify configs in ~/.config/kitty/"
  echo
  echo "🎨 Themes:"
  echo "   • Browse themes: kitty +kitten themes"
  echo "   • Current theme: Tokyo Night (in current-theme.conf)"
  echo
  echo "💡 Tips:"
  echo "   • Font sizes are optimized for different display types"
  echo "   • Display detection works on both macOS and Linux"
  echo "   • Settings persist across terminal restarts"
  echo "   • Use keyboard shortcuts for quick adjustments"
  echo
  echo "════════════════════════════════════════════════════════════════"
  echo "         Restart your terminal to apply all changes!"
  echo "════════════════════════════════════════════════════════════════"
  echo
}

# Main installation function
main() {
  print_status "Starting Kitty terminal installation with display detection..."
  echo "This installer will:"
  echo "  • Install Kitty terminal"
  echo "  • Set up automatic display detection"
  echo "  • Configure font size profiles for different displays"
  echo "  • Add convenient shell aliases"
  echo

  # Detect OS
  detect_os

  # Install Kitty
  install_kitty

  # Install fonts
  install_fonts

  # Create display detection system
  create_display_detector
  create_display_configs

  # Configure Kitty
  configure_kitty

  # Add shell aliases
  add_shell_aliases

  # Run initial display detection
  if [[ -x "$HOME/.config/kitty/display-detector.sh" ]]; then
    print_status "Running initial display detection..."
    "$HOME/.config/kitty/display-detector.sh" --verbose
  fi

  # Print usage instructions
  print_usage_instructions

  print_success "Installation completed successfully!"
  print_status "Log file: $LOG_FILE"
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi