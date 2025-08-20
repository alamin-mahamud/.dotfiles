#!/usr/bin/env bash

# Standalone Keyboard Setup Script
# Configures keyboard settings including Caps Lock to Escape mapping
# Supports: Linux (X11/Wayland), macOS
# No external dependencies - can be run with:
# curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/desktop/keyboard-setup-standalone.sh | bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

LOG_FILE="/tmp/keyboard-setup-$(date +%Y%m%d_%H%M%S).log"

# Logging functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $1${NC}" >&2
    exit 1
}

warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

info() {
    log "${CYAN}→ $1${NC}"
}

print_header() {
    log "${WHITE}${1}${NC}"
    log "${WHITE}$(printf '%.0s=' {1..${#1}})${NC}"
}

# OS Detection
detect_os() {
    case "$OSTYPE" in
        linux-gnu*) echo "linux" ;;
        darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}

detect_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

detect_display_server() {
    if [[ "$(detect_os)" != "linux" ]]; then
        echo "none"
        return
    fi
    
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        echo "wayland"
    elif [[ -n "${DISPLAY:-}" ]]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_packages() {
    local packages=("$@")
    local pm
    pm=$(detect_package_manager)
    
    info "Installing packages: ${packages[*]} (using $pm)"
    
    case "$pm" in
        apt)
            sudo apt update >/dev/null 2>&1
            sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        brew)
            brew install "${packages[@]}"
            ;;
        *)
            warning "Unknown package manager: $pm, skipping package installation"
            ;;
    esac
}

install_keyboard_dependencies() {
    info "Installing keyboard configuration dependencies..."
    
    local os
    os=$(detect_os)
    local display_server
    display_server=$(detect_display_server)
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages xkb-data console-setup || true
                    if [[ "$display_server" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
                dnf)
                    install_packages xkeyboard-config || true
                    if [[ "$display_server" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
                pacman)
                    install_packages xkeyboard-config || true
                    if [[ "$display_server" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
            esac
            ;;
        macos)
            info "macOS uses built-in keyboard configuration"
            ;;
    esac
}

configure_caps_to_escape_linux() {
    local display_server
    display_server=$(detect_display_server)
    
    info "Configuring Caps Lock to Escape for Linux ($display_server)..."
    
    case "$display_server" in
        wayland)
            configure_caps_to_escape_wayland
            ;;
        x11)
            configure_caps_to_escape_x11
            ;;
        *)
            warning "Unknown display server, trying both X11 and Wayland methods"
            configure_caps_to_escape_x11
            configure_caps_to_escape_wayland
            ;;
    esac
}

configure_caps_to_escape_wayland() {
    info "Setting up Caps Lock to Escape for Wayland..."
    
    # Try keyd first (modern solution)
    if command_exists keyd; then
        configure_keyd
    else
        # Try GNOME settings
        if command_exists gsettings; then
            configure_gnome_caps_to_escape
        else
            warning "No Wayland keyboard configuration method available"
        fi
    fi
}

configure_keyd() {
    info "Configuring keyd..."
    
    local keyd_config="/etc/keyd/default.conf"
    sudo mkdir -p /etc/keyd
    
    sudo tee "$keyd_config" > /dev/null << 'EOF'
[ids]
*

[main]
# Map caps lock to escape
capslock = esc

# Optional: Map escape to caps lock for those who want to swap
# esc = capslock
EOF
    
    # Enable and start keyd
    if command_exists systemctl; then
        sudo systemctl enable keyd || true
        sudo systemctl start keyd || true
        success "keyd configured and started"
    else
        warning "systemctl not available, keyd may not start automatically"
    fi
}

configure_gnome_caps_to_escape() {
    info "Configuring GNOME Caps Lock to Escape..."
    
    # Set caps lock to escape in GNOME
    gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" 2>/dev/null || true
    success "GNOME keyboard settings configured"
}

configure_caps_to_escape_x11() {
    info "Setting up Caps Lock to Escape for X11..."
    
    # Create .Xmodmap file
    local xmodmap_file="$HOME/.Xmodmap"
    cat > "$xmodmap_file" << 'EOF'
! Map Caps Lock to Escape
clear Lock
keycode 66 = Escape NoSymbol Escape
EOF
    
    # Apply immediately
    if command_exists xmodmap; then
        xmodmap "$xmodmap_file" 2>/dev/null || true
        success "Applied X11 keyboard mapping"
    fi
    
    # Make it persistent by adding to shell profiles
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]] && ! grep -q "xmodmap.*Xmodmap" "$config"; then
            echo "" >> "$config"
            echo "# Apply keyboard mappings" >> "$config"
            echo "[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap 2>/dev/null || true" >> "$config"
            info "Added Xmodmap to $config"
        fi
    done
    
    # Create autostart entry for desktop environments
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    cat > "$autostart_dir/xmodmap.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Xmodmap
Comment=Apply custom keyboard mappings
Exec=xmodmap %h/.Xmodmap
StartupNotify=false
NoDisplay=true
EOF
    
    success "Created X11 autostart entry"
}

configure_caps_to_escape_macos() {
    info "Configuring Caps Lock to Escape for macOS..."
    
    # Use hidutil to remap caps lock to escape
    local hidutil_command="hidutil property --set '{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":0x700000039,\"HIDKeyboardModifierMappingDst\":0x700000029}]}'"
    
    # Apply immediately
    eval "$hidutil_command" 2>/dev/null || warning "Failed to apply keyboard mapping immediately"
    
    # Create launch agent for persistence
    local launch_agents_dir="$HOME/Library/LaunchAgents"
    mkdir -p "$launch_agents_dir"
    
    local plist_file="$launch_agents_dir/com.local.KeyRemapping.plist"
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.KeyRemapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
    
    # Load the launch agent
    launchctl unload "$plist_file" 2>/dev/null || true
    launchctl load "$plist_file" 2>/dev/null || true
    
    success "macOS keyboard mapping configured and will persist after reboot"
    
    # Also create DefaultKeyBinding.dict for better compatibility
    local keybindings_dir="$HOME/Library/KeyBindings"
    mkdir -p "$keybindings_dir"
    
    cat > "$keybindings_dir/DefaultKeyBinding.dict" << 'EOF'
{
    "^@\UF701" = "noop:";
    "^@\UF702" = "noop:";
    "^@\UF703" = "noop:";
    "^@\UF700" = "noop:";
}
EOF
    
    info "Created DefaultKeyBinding.dict for enhanced compatibility"
}

verify_keyboard_setup() {
    info "Verifying keyboard configuration..."
    
    local os
    os=$(detect_os)
    
    case "$os" in
        linux)
            local display_server
            display_server=$(detect_display_server)
            case "$display_server" in
                wayland)
                    if command_exists keyd && systemctl is-active keyd >/dev/null 2>&1; then
                        success "keyd is running"
                    elif command_exists gsettings; then
                        local xkb_options
                        xkb_options=$(gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null || echo "not set")
                        info "GNOME XKB options: $xkb_options"
                    else
                        warning "Could not verify Wayland keyboard configuration"
                    fi
                    ;;
                x11)
                    if [[ -f "$HOME/.Xmodmap" ]]; then
                        success ".Xmodmap file exists"
                    fi
                    if [[ -f "$HOME/.config/autostart/xmodmap.desktop" ]]; then
                        success "X11 autostart entry exists"
                    fi
                    ;;
            esac
            ;;
        macos)
            local plist_file="$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist"
            if [[ -f "$plist_file" ]]; then
                success "macOS launch agent exists"
                if launchctl list | grep -q "com.local.KeyRemapping"; then
                    success "macOS launch agent is loaded"
                else
                    warning "macOS launch agent is not loaded"
                fi
            fi
            ;;
    esac
}

test_caps_lock_mapping() {
    info "Testing Caps Lock to Escape mapping..."
    info "Please test your Caps Lock key - it should now act as Escape"
    info "If you're using a terminal, try pressing Caps Lock in vim/nano to test"
    
    read -p "Press Enter after testing the mapping..."
    success "Keyboard mapping test completed"
}

main() {
    print_header "Keyboard Setup"
    info "Starting at $(date)"
    info "Log file: $LOG_FILE"
    
    local os
    os=$(detect_os)
    
    info "Detected OS: $os"
    
    case "$os" in
        linux)
            local display_server
            display_server=$(detect_display_server)
            info "Display server: $display_server"
            
            install_keyboard_dependencies
            configure_caps_to_escape_linux
            ;;
        macos)
            configure_caps_to_escape_macos
            ;;
        *)
            error "Unsupported operating system: $os"
            ;;
    esac
    
    verify_keyboard_setup
    
    success "Keyboard setup complete!"
    
    case "$os" in
        linux)
            info "Please log out and log back in for full effect"
            ;;
        macos)
            info "The mapping is active immediately and will persist after reboot"
            ;;
    esac
    
    info "Script finished at $(date)"
}

# Handle script interruption
trap 'echo; warning "Setup interrupted"; exit 1' INT TERM

# Run main function
main "$@"