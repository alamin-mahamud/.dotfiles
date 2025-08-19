#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/tmp/caps-to-escape-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

success() {
    log "${GREEN}✓ $1${NC}"
}

info() {
    log "${YELLOW}→ $1${NC}"
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Detect display server on Linux
detect_display_server() {
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "wayland"
    elif [ -n "${DISPLAY:-}" ]; then
        echo "x11"
    else
        echo "console"
    fi
}

# Setup for X11
setup_x11() {
    info "Setting up Caps Lock to Escape for X11..."
    
    XMODMAP_FILE="$HOME/.Xmodmap"
    XMODMAP_CONFIG="${DOTFILES_ROOT:-$HOME/Work/.dotfiles}/configs/xmodmap/.Xmodmap"
    
    # Create symlink to Xmodmap config
    if [ -f "$XMODMAP_CONFIG" ]; then
        if [ -e "$XMODMAP_FILE" ] && [ ! -L "$XMODMAP_FILE" ]; then
            cp "$XMODMAP_FILE" "$XMODMAP_FILE.backup"
            info "Backed up existing .Xmodmap to .Xmodmap.backup"
        fi
        ln -sf "$XMODMAP_CONFIG" "$XMODMAP_FILE"
        success "Created symlink to .Xmodmap configuration"
        
        # Apply immediately if in X11 session
        if command -v xmodmap &> /dev/null && [ -n "${DISPLAY:-}" ]; then
            xmodmap "$XMODMAP_FILE"
            success "Applied Xmodmap configuration"
        fi
    else
        error "Xmodmap config not found at $XMODMAP_CONFIG"
    fi
    
    # Add to X11 startup files
    XINITRC="$HOME/.xinitrc"
    XPROFILE="$HOME/.xprofile"
    XMODMAP_LINE="[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap"
    
    for file in "$XINITRC" "$XPROFILE"; do
        if ! grep -q "xmodmap.*Xmodmap" "$file" 2>/dev/null; then
            echo "$XMODMAP_LINE" >> "$file"
            success "Added Xmodmap to $(basename $file)"
        fi
    done
}

# Setup for Wayland with keyd
setup_wayland_keyd() {
    info "Setting up Caps Lock to Escape for Wayland using keyd..."
    
    # Check if keyd is installed
    if ! command -v keyd &> /dev/null; then
        info "keyd not installed. Installing..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y keyd
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm keyd
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y keyd
        else
            error "Could not install keyd. Please install manually."
        fi
    fi
    
    KEYD_CONFIG="${DOTFILES_ROOT:-$HOME/Work/.dotfiles}/configs/keyd/default.conf"
    KEYD_SYSTEM_CONFIG="/etc/keyd/default.conf"
    
    if [ -f "$KEYD_CONFIG" ]; then
        sudo mkdir -p /etc/keyd
        sudo cp "$KEYD_CONFIG" "$KEYD_SYSTEM_CONFIG"
        success "Copied keyd configuration to system"
        
        # Enable and start keyd service
        if command -v systemctl &> /dev/null; then
            sudo systemctl enable keyd
            sudo systemctl restart keyd
            success "Enabled and started keyd service"
        fi
    else
        error "keyd config not found at $KEYD_CONFIG"
    fi
}

# Setup for Wayland with GNOME
setup_wayland_gnome() {
    info "Setting up Caps Lock to Escape for GNOME/Wayland..."
    
    if command -v gsettings &> /dev/null; then
        # GNOME 3.30+
        gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" 2>/dev/null || \
        # Older GNOME versions
        gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" 2>/dev/null
        
        success "Configured GNOME to map Caps Lock to Escape"
    else
        info "gsettings not available, skipping GNOME configuration"
    fi
}

# Setup for Wayland with KDE
setup_wayland_kde() {
    info "Setting up Caps Lock to Escape for KDE/Wayland..."
    
    if command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kxkbrc --group Layout --key Options caps:escape
        success "Configured KDE to map Caps Lock to Escape"
    else
        info "KDE configuration tools not available, skipping"
    fi
}

# Setup for macOS
setup_macos() {
    info "Setting up Caps Lock to Escape for macOS..."
    
    # Using hidutil for macOS Sierra and later
    if command -v hidutil &> /dev/null; then
        # Map Caps Lock (0x700000039) to Escape (0x700000029)
        hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
        success "Mapped Caps Lock to Escape using hidutil"
        
        # Create LaunchAgent to persist on restart
        LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
        LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/com.user.capsToEscape.plist"
        
        mkdir -p "$LAUNCH_AGENT_DIR"
        
        cat > "$LAUNCH_AGENT_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.capsToEscape</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
        
        launchctl load "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
        success "Created LaunchAgent for persistence"
        
        info "Note: You can also configure this in System Preferences > Keyboard > Modifier Keys"
    else
        error "hidutil not found. Please configure manually in System Preferences > Keyboard > Modifier Keys"
    fi
    
    # Copy DefaultKeyBinding.dict for additional bindings
    KEYBINDING_SOURCE="${DOTFILES_ROOT:-$HOME/Work/.dotfiles}/macos/DefaultKeyBinding.dict"
    KEYBINDING_DEST="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
    
    if [ -f "$KEYBINDING_SOURCE" ]; then
        mkdir -p "$HOME/Library/KeyBindings"
        cp "$KEYBINDING_SOURCE" "$KEYBINDING_DEST"
        success "Copied DefaultKeyBinding.dict"
    fi
}

# Setup for TTY/Console
setup_console() {
    info "Setting up Caps Lock to Escape for TTY/Console..."
    
    # For systemd-based systems
    if command -v localectl &> /dev/null; then
        sudo localectl set-x11-keymap us pc105 "" caps:escape
        success "Configured console keymap with localectl"
    fi
    
    # Using loadkeys for immediate effect
    if command -v loadkeys &> /dev/null; then
        echo "keycode 58 = Escape" | sudo loadkeys
        success "Applied console keymap with loadkeys"
    fi
    
    # Create vconsole.conf for persistence
    if [ -d "/etc" ]; then
        echo 'KEYMAP_TOGGLE="caps:escape"' | sudo tee -a /etc/vconsole.conf > /dev/null
        success "Updated /etc/vconsole.conf"
    fi
}

# Main installation
main() {
    info "Caps Lock to Escape Installer"
    info "Log file: $LOG_FILE"
    
    OS=$(detect_os)
    
    case $OS in
        linux)
            info "Detected Linux system"
            DISPLAY_SERVER=$(detect_display_server)
            info "Display server: $DISPLAY_SERVER"
            
            case $DISPLAY_SERVER in
                x11)
                    setup_x11
                    ;;
                wayland)
                    # Try multiple methods for Wayland
                    setup_wayland_keyd || setup_wayland_gnome || setup_wayland_kde
                    ;;
                console)
                    setup_console
                    ;;
                *)
                    # Setup for all possible scenarios
                    setup_x11
                    setup_wayland_keyd || true
                    setup_console
                    ;;
            esac
            ;;
        macos)
            info "Detected macOS system"
            setup_macos
            ;;
        *)
            error "Unsupported operating system: $OSTYPE"
            ;;
    esac
    
    success "Caps Lock to Escape setup complete!"
    info "You may need to restart your session or system for changes to take full effect"
}

# Run main function
main "$@"