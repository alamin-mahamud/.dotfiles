#!/usr/bin/env bash

# Standalone Tmux Installer and Configuration Script
# This script can be downloaded and run on any Linux/macOS system
# Usage: curl -fsSL https://your-domain.com/standalone-tmux-installer.sh | bash
#   or: wget -qO- https://your-domain.com/standalone-tmux-installer.sh | bash
#   or: ./standalone-tmux-installer.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Standalone Tmux Installer & Configuration${NC}"
echo -e "${BLUE}================================================${NC}"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${RED}❌ Unsupported operating system${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Detected OS: $OS${NC}"
}

# Install tmux
install_tmux() {
    echo -e "${YELLOW}📦 Installing tmux...${NC}"
    
    case $OS in
        "macos")
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}❌ Homebrew not found. Installing Homebrew first...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install tmux
            ;;
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y tmux git curl
            ;;
        "fedora"|"centos"|"rhel"|"rocky"|"almalinux")
            if command -v dnf &> /dev/null; then
                sudo dnf install -y tmux git curl
            else
                sudo yum install -y tmux git curl
            fi
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm tmux git curl
            ;;
        "alpine")
            sudo apk add --no-cache tmux git curl bash
            ;;
        "opensuse"|"sles")
            sudo zypper install -y tmux git curl
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $OS${NC}"
            echo -e "${YELLOW}💡 Please install tmux manually and re-run this script${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✅ Tmux installed successfully${NC}"
}

# Install additional useful tools
install_additional_tools() {
    echo -e "${YELLOW}🔧 Installing additional tools...${NC}"
    
    case $OS in
        "macos")
            brew install fzf htop watch jq
            ;;
        "ubuntu"|"debian")
            sudo apt install -y fzf htop procps jq
            ;;
        "fedora"|"centos"|"rhel"|"rocky"|"almalinux")
            if command -v dnf &> /dev/null; then
                sudo dnf install -y fzf htop procps-ng jq
            else
                sudo yum install -y htop procps-ng jq
                # Install fzf manually for older systems
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                ~/.fzf/install --all --no-update-rc
            fi
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm fzf htop procps-ng jq
            ;;
        "alpine")
            sudo apk add --no-cache fzf htop procps jq
            ;;
        "opensuse"|"sles")
            sudo zypper install -y fzf htop procps jq
            ;;
    esac
    echo -e "${GREEN}✅ Additional tools installed${NC}"
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    echo -e "${YELLOW}🔌 Installing Tmux Plugin Manager...${NC}"
    
    if [[ ! -d ~/.tmux/plugins/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        echo -e "${GREEN}✅ TPM installed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  TPM already installed, updating...${NC}"
        cd ~/.tmux/plugins/tpm && git pull
        cd - > /dev/null
    fi
}

# Create tmux configuration
create_tmux_config() {
    echo -e "${YELLOW}⚙️  Creating tmux configuration...${NC}"
    
    # Backup existing config if it exists
    if [[ -f ~/.tmux.conf ]]; then
        mv ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)
        echo -e "${YELLOW}📁 Backed up existing .tmux.conf${NC}"
    fi
    
    # Create new tmux configuration
    cat > ~/.tmux.conf << 'EOF'
# Standalone Tmux Configuration
# Optimized for productivity and DevOps workflows

# ============================================================================
# GENERAL SETTINGS
# ============================================================================

# Set default terminal to support 256 colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color*:Tc"

# Enable mouse support
set -g mouse on

# Increase scrollback buffer size
set -g history-limit 50000

# Start window and pane indexing at 1
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Enable focus events for vim/nvim
set -g focus-events on

# Faster command sequences
set -s escape-time 10

# Increase repeat timeout
set -g repeat-time 600

# ============================================================================
# KEY BINDINGS
# ============================================================================

# Change prefix key to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload configuration file
bind r source-file ~/.tmux.conf \; display-message "🔄 Config reloaded!"

# Better window splitting
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# New window in current path
bind c new-window -c "#{pane_current_path}"

# Vim-like pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing with vim keys
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Window navigation
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+

# Copy mode with vim keys
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi r send-keys -X rectangle-toggle

# Platform-specific copy commands
if-shell "uname | grep -q Darwin" \
    "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'" \
    "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'"

# Quick session switching
bind S choose-session

# Kill session
bind X confirm-before -p "Kill session #S? (y/n)" kill-session

# ============================================================================
# STATUS BAR CONFIGURATION
# ============================================================================

# Status bar colors and styling
set -g status-bg colour235
set -g status-fg colour255
set -g status-interval 5

# Status bar position
set -g status-position bottom

# Status bar format
set -g status-left-length 50
set -g status-right-length 100

# Left side: session name
set -g status-left "#[fg=colour39,bg=colour235,bold] #S #[fg=colour245]| "

# Right side: system info
set -g status-right "#[fg=colour245]#{?client_prefix,🔴 ,}#[fg=colour39]%H:%M #[fg=colour245]| #[fg=colour39]%d-%b #[fg=colour245]| #[fg=colour39]#(whoami)@#h"

# Window status format
setw -g window-status-format "#[fg=colour245] #I:#W "
setw -g window-status-current-format "#[fg=colour39,bg=colour238,bold] #I:#W "

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off
setw -g window-status-activity-style "fg=colour196,bg=colour235"

# ============================================================================
# PANE STYLING
# ============================================================================

# Pane borders
set -g pane-border-style "fg=colour238"
set -g pane-active-border-style "fg=colour39"

# Message styling
set -g message-style "fg=colour255,bg=colour238,bold"
set -g message-command-style "fg=colour255,bg=colour238,bold"

# ============================================================================
# PLUGIN CONFIGURATION
# ============================================================================

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

# Plugin configurations
# Resurrect settings for session persistence
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'

# Continuum settings for automatic session save/restore
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# ============================================================================
# USEFUL KEY BINDINGS FOR DEVOPS
# ============================================================================

# Quick system monitoring
bind-key -r i split-window -h "htop"
bind-key -r I split-window -h "top"

# Docker shortcuts (if docker is available)
bind-key -r d split-window -h "if command -v docker &> /dev/null; then docker ps; else echo 'Docker not installed'; fi"

# System log monitoring
bind-key -r L split-window -h "if [ -f /var/log/syslog ]; then tail -f /var/log/syslog; elif [ -f /var/log/messages ]; then tail -f /var/log/messages; else journalctl -f; fi"

# Initialize TMUX plugin manager (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF

    echo -e "${GREEN}✅ Tmux configuration created${NC}"
}

# Create useful scripts
create_scripts() {
    echo -e "${YELLOW}📝 Creating utility scripts...${NC}"
    
    # Create local bin directory
    mkdir -p ~/.local/bin
    
    # Create tmux sessionizer script
    cat > ~/.local/bin/tmux-sessionizer << 'EOF'
#!/usr/bin/env bash

# Tmux Sessionizer - Quick project session management
# Usage: tmux-sessionizer [directory]

if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Common project directories
    dirs=(
        "$HOME"
        "$HOME/Work"
        "$HOME/Projects"
        "$HOME/Dev"
        "$HOME/Code"
        "/opt"
        "/var/www"
        "/srv"
    )
    
    # Find directories that exist
    existing_dirs=()
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            existing_dirs+=("$dir")
        fi
    done
    
    if command -v fzf &> /dev/null && [[ ${#existing_dirs[@]} -gt 0 ]]; then
        selected=$(find "${existing_dirs[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf)
    else
        echo "Available directories:"
        for i in "${!existing_dirs[@]}"; do
            echo "$((i+1)). ${existing_dirs[$i]}"
        done
        read -p "Select directory (1-${#existing_dirs[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#existing_dirs[@]}" ]]; then
            selected="${existing_dirs[$((choice-1))]}"
        else
            echo "Invalid selection"
            exit 1
        fi
    fi
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -d -s "$selected_name" -c "$selected"
fi

if [[ -z $TMUX ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
EOF

    chmod +x ~/.local/bin/tmux-sessionizer
    
    echo -e "${GREEN}✅ Utility scripts created${NC}"
}

# Install plugins
install_plugins() {
    echo -e "${YELLOW}🔌 Installing tmux plugins...${NC}"
    
    # Start tmux server and install plugins
    tmux new-session -d -s __plugin_install__ 2>/dev/null || true
    sleep 2
    ~/.tmux/plugins/tpm/bin/install_plugins
    tmux kill-session -t __plugin_install__ 2>/dev/null || true
    
    echo -e "${GREEN}✅ Plugins installed successfully${NC}"
}

# Add shell aliases and PATH
setup_shell() {
    echo -e "${YELLOW}🐚 Setting up shell integration...${NC}"
    
    local shell_configs=(~/.bashrc ~/.zshrc ~/.profile)
    local config_added=false
    
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            # Add ~/.local/bin to PATH if not already there
            if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$config" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$config"
            fi
            
            # Add tmux aliases if they don't exist
            if ! grep -q "alias tm=" "$config" 2>/dev/null; then
                cat >> "$config" << 'ALIASES'

# Tmux aliases
alias tm='tmux'
alias tma='tmux attach-session -t'
alias tmn='tmux new-session -s'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'
alias tmks='tmux kill-server'
alias tms='tmux-sessionizer'
ALIASES
                config_added=true
                echo -e "${GREEN}✅ Added aliases to $config${NC}"
            fi
        fi
    done
    
    if [[ "$config_added" == "true" ]]; then
        echo -e "${YELLOW}💡 Restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to use new aliases${NC}"
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}Starting standalone tmux installation...${NC}"
    echo ""
    
    detect_os
    
    # Check if tmux is already installed
    if ! command -v tmux &> /dev/null; then
        install_tmux
    else
        echo -e "${GREEN}✅ tmux is already installed ($(tmux -V))${NC}"
    fi
    
    install_additional_tools
    install_tpm
    create_tmux_config
    create_scripts
    install_plugins
    setup_shell
    
    echo ""
    echo -e "${GREEN}🎉 Standalone tmux installation completed successfully!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${GREEN}tmux${NC}                    - Start tmux"
    echo -e "  ${GREEN}tmux-sessionizer${NC}        - Quick project session selection"
    echo -e "  ${GREEN}tm${NC}                      - Tmux alias"
    echo -e "  ${GREEN}tms${NC}                     - Run sessionizer"
    echo ""
    echo -e "${YELLOW}Key bindings:${NC}"
    echo -e "  ${GREEN}Prefix: Ctrl-a${NC}"
    echo -e "  ${GREEN}Prefix + |${NC}              - Split horizontally"
    echo -e "  ${GREEN}Prefix + -${NC}              - Split vertically"
    echo -e "  ${GREEN}Prefix + h/j/k/l${NC}        - Navigate panes (vim-style)"
    echo -e "  ${GREEN}Prefix + r${NC}              - Reload config"
    echo -e "  ${GREEN}Prefix + i${NC}              - Open htop in new pane"
    echo -e "  ${GREEN}Prefix + d${NC}              - Show docker containers"
    echo ""
    echo -e "${BLUE}Run 'tmux' to start your first session!${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi