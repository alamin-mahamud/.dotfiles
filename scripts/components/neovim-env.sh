#!/usr/bin/env bash

# Neovim + LazyVim Environment Installer
# Installs Neovim and sets up LazyVim configuration
# Supports both desktop and server environments

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Configuration
NVIM_CONFIG_DIR="$HOME/.config/nvim"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
DOTFILES_NVIM_CONFIG="$DOTFILES_ROOT/nvim"

install_neovim_dependencies() {
    info "Installing Neovim dependencies..."
    
    local packages=()
    
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    packages=(git curl unzip tar gzip wget build-essential)
                    # Add newer Neovim PPA for Ubuntu/Debian
                    if ! apt-cache policy neovim 2>/dev/null | grep -q "neovim-ppa"; then
                        add_repository ppa:neovim-ppa/unstable 2>/dev/null || {
                            warning "Could not add neovim PPA, using system version"
                        }
                    fi
                    packages+=(neovim)
                    ;;
                dnf|yum)
                    packages=(git curl unzip tar gzip wget gcc gcc-c++ make neovim)
                    ;;
                pacman)
                    packages=(git curl unzip tar gzip wget base-devel neovim)
                    ;;
                apk)
                    packages=(git curl unzip tar gzip wget build-base neovim)
                    ;;
                *)
                    packages=(git curl unzip tar gzip wget)
                    ;;
            esac
            ;;
        macos)
            packages=(git curl neovim)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        update_package_lists
        install_packages "${packages[@]}"
    fi
    
    log_execution "Install Neovim dependencies" "Completed"
}

install_neovim_from_source() {
    if command_exists nvim; then
        local version
        version=$(nvim --version | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        info "Neovim already installed: $version"
        return 0
    fi
    
    info "Installing Neovim from GitHub releases..."
    
    local nvim_dir="/opt/nvim"
    local download_url=""
    
    case "${DOTFILES_OS}" in
        linux)
            case "${DOTFILES_ARCH}" in
                amd64|x86_64)
                    download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
                    ;;
                arm64|aarch64)
                    download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
                    ;;
            esac
            ;;
        macos)
            download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-macos.tar.gz"
            ;;
    esac
    
    if [[ -z "$download_url" ]]; then
        warning "No prebuilt Neovim binary available for ${DOTFILES_OS}/${DOTFILES_ARCH}"
        return 1
    fi
    
    # Download and install
    local temp_dir
    temp_dir=$(mktemp -d)
    
    info "Downloading Neovim..."
    if ! download_file "$download_url" "$temp_dir/nvim.tar.gz"; then
        error "Failed to download Neovim"
        return 1
    fi
    
    info "Installing Neovim to $nvim_dir..."
    sudo mkdir -p "$nvim_dir"
    sudo tar -xzf "$temp_dir/nvim.tar.gz" -C "$nvim_dir" --strip-components=1
    
    # Create symlink
    if [[ -f "$nvim_dir/bin/nvim" ]]; then
        sudo ln -sf "$nvim_dir/bin/nvim" /usr/local/bin/nvim
        success "Neovim installed successfully"
    else
        error "Neovim installation failed"
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_execution "Install Neovim from source" "Completed"
}

setup_lazyvim() {
    info "Setting up LazyVim configuration..."
    
    # Backup existing Neovim config
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        backup_file "$NVIM_CONFIG_DIR"
    fi
    
    # Clone LazyVim starter template
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        rm -rf "$NVIM_CONFIG_DIR"
    fi
    
    info "Cloning LazyVim starter configuration..."
    git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
    
    # Remove .git directory from starter template
    rm -rf "$NVIM_CONFIG_DIR/.git"
    
    success "LazyVim configuration installed"
    log_execution "Setup LazyVim configuration" "Completed"
}

install_language_servers() {
    info "Installing language servers and tools..."
    
    local tools=(
        # Language servers
        "lua-language-server"
        "bash-language-server"
        "typescript-language-server"
        "pyright"
        "rust-analyzer"
        
        # Formatters and linters
        "prettier"
        "eslint_d"
        "stylua"
        "shfmt"
        "shellcheck"
    )
    
    # Install Node.js tools via npm/yarn if available
    if command_exists npm; then
        info "Installing Node.js-based tools..."
        npm install -g typescript-language-server bash-language-server prettier eslint_d 2>/dev/null || true
    fi
    
    # Install via package manager if available
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages shellcheck || true
                    ;;
                pacman)
                    install_packages shellcheck shfmt || true
                    ;;
            esac
            ;;
        macos)
            if command_exists brew; then
                brew install shellcheck shfmt lua-language-server || true
            fi
            ;;
    esac
    
    log_execution "Install language servers" "Completed"
}

configure_neovim_integration() {
    info "Configuring Neovim shell integration..."
    
    # Add Neovim aliases to shell configuration
    local shell_config=""
    
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
    fi
    
    if [[ -n "$shell_config" ]]; then
        # Add EDITOR environment variable
        if ! grep -q "export EDITOR.*nvim" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Neovim configuration" >> "$shell_config"
            echo "export EDITOR='nvim'" >> "$shell_config"
            echo "export VISUAL='nvim'" >> "$shell_config"
            echo "" >> "$shell_config"
            
            # Add useful aliases
            echo "# Neovim aliases" >> "$shell_config"
            echo "alias v='nvim'" >> "$shell_config"
            echo "alias vi='nvim'" >> "$shell_config"
            echo "alias vim='nvim'" >> "$shell_config"
            echo "alias vimdiff='nvim -d'" >> "$shell_config"
            echo "" >> "$shell_config"
        fi
        
        success "Shell integration configured"
    fi
    
    log_execution "Configure Neovim shell integration" "Completed"
}

create_custom_lazyvim_config() {
    info "Creating custom LazyVim configuration..."
    
    # Create custom configuration files
    local lua_dir="$NVIM_CONFIG_DIR/lua"
    local config_dir="$lua_dir/config"
    
    ensure_directory "$config_dir"
    
    # Create options.lua with sensible defaults
    cat > "$lua_dir/config/options.lua" << 'EOF'
-- Custom options for LazyVim
local opt = vim.opt

-- Better defaults
opt.relativenumber = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.colorcolumn = "80,120"

-- Better search
opt.ignorecase = true
opt.smartcase = true

-- Better formatting
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Better files
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true

-- Better UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cmdheight = 1
opt.updatetime = 300
opt.timeoutlen = 500
EOF
    
    # Create keymaps.lua with additional key bindings
    cat > "$lua_dir/config/keymaps.lua" << 'EOF'
-- Custom keymaps for LazyVim
local map = vim.keymap.set

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Better buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Better line movement
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Quick save
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
EOF
    
    success "Custom LazyVim configuration created"
    log_execution "Create custom LazyVim config" "Completed"
}

# ============================================================================
# KEYBOARD SETUP INTEGRATION (Caps Lock → Escape for vim/neovim workflow)
# ============================================================================

install_keyboard_dependencies() {
    info "Installing keyboard configuration dependencies..."
    
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages xkb-data console-setup || true
                    if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
                dnf|yum)
                    install_packages xkeyboard-config || true
                    if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                        install_packages keyd || true
                    fi
                    ;;
                pacman)
                    install_packages xkeyboard-config || true
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
    
    log_execution "Install keyboard dependencies" "Completed"
}

setup_caps_to_escape() {
    info "Setting up Caps Lock → Escape mapping (essential for vim/neovim)..."
    
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
    
    log_execution "Setup Caps Lock to Escape" "Completed"
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
    info "Configuring Caps Lock → Escape for X11..."
    
    # Create temporary Xmodmap content instead of relying on config files
    local xmodmap_content="clear lock
clear control
keycode 66 = Escape NoSymbol Escape
add control = Control_L Control_R"
    
    local xmodmap_file="$HOME/.Xmodmap"
    
    # Write Xmodmap configuration
    echo "$xmodmap_content" > "$xmodmap_file"
    success "Created .Xmodmap configuration"
    
    # Apply immediately if in X11 session
    if command_exists xmodmap && [[ -n "${DISPLAY:-}" ]]; then
        xmodmap "$xmodmap_file"
        success "Applied Xmodmap configuration"
    fi
    
    # Add to X11 startup files
    local xinitrc="$HOME/.xinitrc"
    local xprofile="$HOME/.xprofile"
    local xmodmap_line="[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap"
    
    for file in "$xinitrc" "$xprofile"; do
        if [[ ! -f "$file" ]] || ! grep -q "xmodmap.*Xmodmap" "$file" 2>/dev/null; then
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
        warning "Could not configure Caps Lock → Escape for Wayland"
        return 1
    fi
    
    success "Configured Caps Lock → Escape for Wayland using $method"
}

setup_caps_wayland_keyd() {
    if ! command_exists keyd; then
        debug "keyd not available, skipping"
        return 1
    fi
    
    info "Setting up Caps Lock → Escape for Wayland using keyd..."
    
    # Create keyd configuration inline
    local keyd_config_content="[ids]

*

[main]

# Map caps lock to escape
capslock = escape

# Optional: make escape also work as caps lock when held
# escape = overload(control, escape)"
    
    local keyd_system_config="/etc/keyd/default.conf"
    
    sudo mkdir -p /etc/keyd
    echo "$keyd_config_content" | sudo tee "$keyd_system_config" > /dev/null
    success "Created keyd configuration"
    
    # Enable and start keyd service
    if command_exists systemctl; then
        sudo systemctl enable keyd 2>/dev/null || true
        sudo systemctl restart keyd 2>/dev/null || true
        success "Enabled and started keyd service"
    fi
    
    return 0
}

setup_caps_wayland_gnome() {
    if ! command_exists gsettings; then
        debug "gsettings not available, skipping GNOME configuration"
        return 1
    fi
    
    info "Setting up Caps Lock → Escape for GNOME/Wayland..."
    
    # Try both old and new GNOME settings paths
    if gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" 2>/dev/null; then
        success "Configured GNOME to map Caps Lock → Escape"
        return 0
    elif gsettings set org.gnome.desktop.input-sources xkb-options '["caps:escape"]' 2>/dev/null; then
        success "Configured GNOME to map Caps Lock → Escape"
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
    
    info "Setting up Caps Lock → Escape for KDE/Wayland..."
    
    if command_exists kwriteconfig6; then
        kwriteconfig6 --file kxkbrc --group Layout --key Options caps:escape
    elif command_exists kwriteconfig5; then
        kwriteconfig5 --file kxkbrc --group Layout --key Options caps:escape
    fi
    
    success "Configured KDE to map Caps Lock → Escape"
    return 0
}

setup_caps_console() {
    info "Setting up Caps Lock → Escape for TTY/Console..."
    
    # For systemd-based systems
    if command_exists localectl; then
        sudo localectl set-x11-keymap us pc105 "" caps:escape 2>/dev/null || true
        success "Configured console keymap with localectl"
    fi
    
    # Using loadkeys for immediate effect
    if command_exists loadkeys; then
        echo "keycode 58 = Escape" | sudo loadkeys 2>/dev/null || true
        success "Applied console keymap with loadkeys"
    fi
}

setup_caps_macos() {
    info "Setting up Caps Lock → Escape for macOS..."
    
    # Using hidutil for macOS Sierra and later
    if command_exists hidutil; then
        # Map Caps Lock (0x700000039) to Escape (0x700000029)
        hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
        success "Mapped Caps Lock → Escape using hidutil"
        
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
    local keybinding_source="$DOTFILES_ROOT/macos/DefaultKeyBinding.dict"
    local keybinding_dest="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
    
    if [[ -f "$keybinding_source" ]]; then
        mkdir -p "$HOME/Library/KeyBindings"
        cp "$keybinding_source" "$keybinding_dest"
        success "Copied DefaultKeyBinding.dict"
    fi
}

optimize_keyboard_for_vim() {
    info "Optimizing keyboard settings for vim/neovim workflow..."
    
    case "${DOTFILES_OS}" in
        linux)
            # Set reasonable keyboard repeat rate for vim navigation
            if command_exists xset && [[ -n "${DISPLAY:-}" ]]; then
                xset r rate 300 50  # 300ms delay, 50 chars/sec
                success "Set keyboard repeat rate for vim navigation"
            fi
            ;;
        macos)
            # Set reasonable keyboard repeat rate for vim navigation
            defaults write NSGlobalDomain KeyRepeat -int 2
            defaults write NSGlobalDomain InitialKeyRepeat -int 15
            success "Set keyboard repeat rate for vim navigation"
            ;;
    esac
    
    log_execution "Optimize keyboard for vim" "Completed"
}

verify_neovim_installation() {
    info "Verifying Neovim installation..."
    
    if ! command_exists nvim; then
        error "Neovim not found in PATH"
        return 1
    fi
    
    local version
    version=$(nvim --version | head -1)
    success "Neovim installed: $version"
    
    # Check if LazyVim config exists
    if [[ -f "$NVIM_CONFIG_DIR/init.lua" ]]; then
        success "LazyVim configuration found"
    else
        warning "LazyVim configuration not found"
    fi
    
    # Test basic Neovim functionality
    if nvim --headless -c "q" 2>/dev/null; then
        success "Neovim basic functionality verified"
    else
        warning "Neovim may have configuration issues"
    fi
    
    log_execution "Verify Neovim installation" "Completed"
}

show_neovim_next_steps() {
    print_header "Neovim + Keyboard Setup Complete"
    
    info "Next steps:"
    info "1. Run 'nvim' to start Neovim with LazyVim"
    info "2. LazyVim will automatically install plugins on first run"
    info "3. Use :LazyHealth to check plugin status"
    info "4. Use :Lazy to manage plugins"
    info "5. Check :help LazyVim for documentation"
    
    if [[ "${DOTFILES_OS}" == "macos" ]]; then
        info "6. Consider installing a Nerd Font for better icons"
    fi
    
    echo
    info "Keyboard optimizations:"
    info "  • Caps Lock → Escape (essential for vim workflow)"
    info "  • Optimized key repeat rate for vim navigation"
    info "  • You may need to restart your session for full effect"
    
    echo
    info "Key shortcuts:"
    info "  <leader> = Space key (thanks to Caps Lock → Escape!)"
    info "  <leader>ff = Find files"
    info "  <leader>fg = Live grep"
    info "  <leader>e = Toggle file explorer"
    info "  <leader>/ = Toggle comment"
    
    echo
    success "Neovim with LazyVim and optimized keyboard layout is ready!"
}

main() {
    local marker="neovim-env-$(date +%Y%m%d)"
    
    if is_completed "$marker"; then
        info "Neovim environment already set up today"
        return 0
    fi
    
    init_script "Neovim + LazyVim Environment Installer"
    
    # Planning phase
    reset_installation_state
    add_to_plan "Install Neovim dependencies and build tools"
    add_to_plan "Install latest Neovim from package manager or source"
    add_to_plan "Setup LazyVim configuration framework"
    add_to_plan "Install language servers and development tools"
    add_to_plan "Configure shell integration (EDITOR, aliases)"
    add_to_plan "Create custom LazyVim configuration files"
    add_to_plan "Install keyboard dependencies for vim workflow"
    add_to_plan "Setup Caps Lock → Escape mapping (essential for vim)"
    add_to_plan "Optimize keyboard settings for vim navigation"
    add_to_plan "Verify installation and functionality"
    
    show_installation_plan "Neovim + LazyVim + Keyboard Environment"
    
    # Execution phase
    execute_step "Install Neovim dependencies" "install_neovim_dependencies"
    
    # Try package manager first, fallback to source installation
    if ! command_exists nvim; then
        execute_step "Install Neovim" "install_neovim_from_source"
    fi
    
    execute_step "Setup LazyVim configuration" "setup_lazyvim"
    execute_step "Install language servers" "install_language_servers"  
    execute_step "Configure shell integration" "configure_neovim_integration"
    execute_step "Create custom configuration" "create_custom_lazyvim_config"
    execute_step "Install keyboard dependencies" "install_keyboard_dependencies"
    execute_step "Setup Caps Lock → Escape mapping" "setup_caps_to_escape"
    execute_step "Optimize keyboard for vim" "optimize_keyboard_for_vim"
    execute_step "Verify installation" "verify_neovim_installation"
    
    mark_completed "$marker"
    
    show_installation_summary "Neovim + LazyVim + Keyboard Environment"
    show_neovim_next_steps
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi