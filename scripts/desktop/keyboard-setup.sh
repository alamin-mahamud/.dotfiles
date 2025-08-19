#!/usr/bin/env bash

# Desktop Keyboard Setup
# Configures keyboard settings for desktop environments including Caps Lock to Escape

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

install_keyboard_dependencies() {
    info "Installing keyboard configuration dependencies..."
    
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages xkb-data console-setup
                    if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
                dnf|yum)
                    install_packages xkeyboard-config
                    if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
                pacman)
                    install_packages xkeyboard-config
                    if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
            esac
            ;;
        macos)
            # macOS has built-in keyboard configuration
            debug "macOS keyboard configuration uses system preferences"
            ;;
    esac
}

setup_caps_to_escape() {
    info "Setting up Caps Lock to Escape mapping..."
    
    case "${DOTFILES_OS}" in
        linux)
            setup_caps_linux
            ;;
        macos)
            setup_caps_macos
            ;;
        *)
            error "Unsupported OS for keyboard setup: ${DOTFILES_OS}"
            ;;
    esac
}

setup_caps_linux() {
    local display_server="${DOTFILES_DISPLAY}"
    
    case "$display_server" in
        x11)
            setup_caps_x11
            ;;
        wayland)
            setup_caps_wayland
            ;;
        console)
            setup_caps_console
            ;;
        *)
            # Setup for all possible scenarios
            setup_caps_x11
            setup_caps_wayland || true
            setup_caps_console
            ;;
    esac
}

setup_caps_x11() {
    info "Setting up Caps Lock to Escape for X11..."
    
    local xmodmap_config="${DOTFILES_ROOT}/configs/xmodmap/.Xmodmap"
    local xmodmap_file="$HOME/.Xmodmap"
    
    # Create symlink to Xmodmap config
    if [[ -f "$xmodmap_config" ]]; then
        safe_symlink "$xmodmap_config" "$xmodmap_file"
        success "Created symlink to .Xmodmap configuration"
        
        # Apply immediately if in X11 session
        if command_exists xmodmap && [[ -n "${DISPLAY:-}" ]]; then
            xmodmap "$xmodmap_file"
            success "Applied Xmodmap configuration"
        fi
    else
        error "Xmodmap config not found at $xmodmap_config"
    fi
    
    # Add to X11 startup files
    local xinitrc="$HOME/.xinitrc"
    local xprofile="$HOME/.xprofile"
    local xmodmap_line="[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap"
    
    for file in "$xinitrc" "$xprofile"; do
        if ! grep -q "xmodmap.*Xmodmap" "$file" 2>/dev/null; then
            echo "$xmodmap_line" >> "$file"
            success "Added Xmodmap to $(basename "$file")"
        fi
    done
}

setup_caps_wayland() {
    local method="none"
    
    # Try different methods in order of preference
    if setup_caps_wayland_keyd; then
        method="keyd"
    elif setup_caps_wayland_gnome; then
        method="gnome"
    elif setup_caps_wayland_kde; then
        method="kde"
    else
        warning "Could not configure Caps Lock to Escape for Wayland"
        return 1
    fi
    
    success "Configured Caps Lock to Escape for Wayland using $method"
}

setup_caps_wayland_keyd() {
    if ! command_exists keyd; then
        debug "keyd not available, skipping"
        return 1
    fi
    
    info "Setting up Caps Lock to Escape for Wayland using keyd..."
    
    local keyd_config="${DOTFILES_ROOT}/configs/keyd/default.conf"
    local keyd_system_config="/etc/keyd/default.conf"
    
    if [[ -f "$keyd_config" ]]; then
        sudo mkdir -p /etc/keyd
        sudo cp "$keyd_config" "$keyd_system_config"
        success "Copied keyd configuration to system"
        
        # Enable and start keyd service
        if command_exists systemctl; then
            sudo systemctl enable keyd
            sudo systemctl restart keyd
            success "Enabled and started keyd service"
        fi
        
        return 0
    else
        warning "keyd config not found at $keyd_config"
        return 1
    fi
}

setup_caps_wayland_gnome() {
    if ! command_exists gsettings; then
        debug "gsettings not available, skipping GNOME configuration"
        return 1
    fi
    
    info "Setting up Caps Lock to Escape for GNOME/Wayland..."
    
    # Try both old and new GNOME settings paths
    if gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" 2>/dev/null; then
        success "Configured GNOME to map Caps Lock to Escape"
        return 0
    elif gsettings set org.gnome.desktop.input-sources xkb-options '["caps:escape"]' 2>/dev/null; then
        success "Configured GNOME to map Caps Lock to Escape"
        return 0
    else
        debug "Could not configure GNOME settings"
        return 1
    fi
}

setup_caps_wayland_kde() {
    if ! command_exists kwriteconfig5 && ! command_exists kwriteconfig6; then
        debug "KDE configuration tools not available, skipping"
        return 1
    fi
    
    info "Setting up Caps Lock to Escape for KDE/Wayland..."
    
    if command_exists kwriteconfig6; then
        kwriteconfig6 --file kxkbrc --group Layout --key Options caps:escape
    elif command_exists kwriteconfig5; then
        kwriteconfig5 --file kxkbrc --group Layout --key Options caps:escape
    fi
    
    success "Configured KDE to map Caps Lock to Escape"
    return 0
}

setup_caps_console() {
    info "Setting up Caps Lock to Escape for TTY/Console..."
    
    # For systemd-based systems
    if command_exists localectl; then
        sudo localectl set-x11-keymap us pc105 "" caps:escape
        success "Configured console keymap with localectl"
    fi
    
    # Using loadkeys for immediate effect
    if command_exists loadkeys; then
        echo "keycode 58 = Escape" | sudo loadkeys
        success "Applied console keymap with loadkeys"
    fi
    
    # Create vconsole.conf for persistence
    if [[ -d "/etc" ]]; then
        echo 'KEYMAP_TOGGLE="caps:escape"' | sudo tee -a /etc/vconsole.conf > /dev/null
        success "Updated /etc/vconsole.conf"
    fi
}

setup_caps_macos() {
    info "Setting up Caps Lock to Escape for macOS..."
    
    # Using hidutil for macOS Sierra and later
    if command_exists hidutil; then
        # Map Caps Lock (0x700000039) to Escape (0x700000029)
        hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
        success "Mapped Caps Lock to Escape using hidutil"
        
        # Create LaunchAgent to persist on restart
        setup_macos_launch_agent
        
        info "Note: You can also configure this in System Preferences > Keyboard > Modifier Keys"
    else
        error "hidutil not found. Please configure manually in System Preferences > Keyboard > Modifier Keys"
    fi
    
    # Copy DefaultKeyBinding.dict for additional bindings
    setup_macos_key_bindings
}

setup_macos_launch_agent() {
    local launch_agent_dir="$HOME/Library/LaunchAgents"
    local launch_agent_plist="$launch_agent_dir/com.user.capsToEscape.plist"
    
    mkdir -p "$launch_agent_dir"
    
    cat > "$launch_agent_plist" << 'EOF'
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
    
    launchctl load "$launch_agent_plist" 2>/dev/null || true
    success "Created LaunchAgent for persistence"
}

setup_macos_key_bindings() {
    local keybinding_source="${DOTFILES_ROOT}/macos/DefaultKeyBinding.dict"
    local keybinding_dest="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
    
    if [[ -f "$keybinding_source" ]]; then
        mkdir -p "$HOME/Library/KeyBindings"
        cp "$keybinding_source" "$keybinding_dest"
        success "Copied DefaultKeyBinding.dict"
    fi
}

configure_additional_keyboard_settings() {
    info "Configuring additional keyboard settings..."
    
    case "${DOTFILES_OS}" in
        linux)
            configure_linux_keyboard
            ;;
        macos)
            configure_macos_keyboard
            ;;
    esac
}

configure_linux_keyboard() {
    # Set reasonable keyboard repeat rate
    if command_exists xset && [[ -n "${DISPLAY:-}" ]]; then
        xset r rate 300 50  # 300ms delay, 50 chars/sec
        success "Set keyboard repeat rate"
    fi
    
    # Configure compose key for special characters
    if [[ "${DOTFILES_DISPLAY}" == "x11" ]]; then
        local xmodmap_file="$HOME/.Xmodmap"
        if [[ -f "$xmodmap_file" ]] && ! grep -q "compose" "$xmodmap_file"; then
            echo "keycode 135 = Multi_key" >> "$xmodmap_file"
            success "Configured Right Alt as compose key"
        fi
    fi
}

configure_macos_keyboard() {
    # Set reasonable keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    success "Set keyboard repeat rate"
}

verify_keyboard_setup() {
    info "Verifying keyboard setup..."
    
    case "${DOTFILES_OS}" in
        linux)
            case "${DOTFILES_DISPLAY}" in
                x11)
                    if [[ -f "$HOME/.Xmodmap" ]]; then
                        success "X11 keyboard configuration: ✓"
                    fi
                    ;;
                wayland)
                    if [[ -f "/etc/keyd/default.conf" ]] || \
                       gsettings get org.gnome.desktop.input-sources xkb-options 2>/dev/null | grep -q caps; then
                        success "Wayland keyboard configuration: ✓"
                    fi
                    ;;
            esac
            ;;
        macos)
            if [[ -f "$HOME/Library/LaunchAgents/com.user.capsToEscape.plist" ]]; then
                success "macOS keyboard configuration: ✓"
            fi
            ;;
    esac
    
    info "Keyboard setup verification complete"
    info "You may need to restart your session for all changes to take effect"
}

main() {
    init_script "Desktop Keyboard Setup"
    
    # Check if desktop environment is available
    if ! is_desktop_environment && [[ "${DOTFILES_OS}" != "macos" ]]; then
        warning "No desktop environment detected. Limited keyboard configuration available."
    fi
    
    install_keyboard_dependencies
    setup_caps_to_escape
    configure_additional_keyboard_settings
    verify_keyboard_setup
    
    success "Keyboard setup complete!"
    info "Caps Lock has been mapped to Escape"
    info "Additional keyboard optimizations have been applied"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi