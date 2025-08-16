#!/bin/bash

# DevOps Shell Environment Standalone Installer
# Installs Zsh + Oh My Zsh + Tmux + Kitty + modern CLI tools for DevOps workflows
# Embedded configurations - no external dependencies
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/devops-shell.sh | bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/devops-shell-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

exec > >(tee -a "$LOG_FILE") 2>&1

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         DevOps Shell Environment Setup           ║"
    echo "║       Zsh + Tmux + Kitty + Modern CLI Tools     ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

check_root() {
    [[ $EUID -eq 0 ]] && { print_error "Don't run as root!"; exit 1; }
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
    else
        print_error "Unsupported OS"
        exit 1
    fi
    print_success "Detected $OS"
}

backup_configs() {
    local files=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/kitty/kitty.conf")
    local backup_needed=false
    
    for file in "${files[@]}"; do
        [[ -f "$file" && ! -L "$file" ]] && backup_needed=true && break
    done
    
    if [[ "$backup_needed" == true ]]; then
        print_status "Backing up existing configs..."
        mkdir -p "$BACKUP_DIR"
        for file in "${files[@]}"; do
            [[ -f "$file" && ! -L "$file" ]] && cp "$file" "$BACKUP_DIR/" 2>/dev/null
        done
        print_success "Backup saved to $BACKUP_DIR"
    fi
}

install_packages() {
    print_status "Installing packages..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y zsh tmux kitty git curl wget unzip \
                ripgrep fd-find bat fzf htop tree jq build-essential \
                python3-pip nodejs npm
            ;;
        fedora|centos|rhel)
            sudo dnf install -y zsh tmux kitty git curl wget unzip \
                ripgrep fd-find bat fzf htop tree jq \
                python3-pip nodejs npm || \
            sudo yum install -y zsh tmux kitty git curl wget unzip \
                htop tree jq python3-pip nodejs npm
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm zsh tmux kitty git curl wget unzip \
                ripgrep fd bat fzf htop tree jq python-pip nodejs npm
            ;;
        macos)
            command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install zsh tmux kitty git curl wget unzip \
                ripgrep fd bat fzf htop tree jq python nodejs npm
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "Packages installed"
}

install_modern_tools() {
    print_status "Installing modern CLI tools..."
    
    # Install eza (modern ls)
    case "$OS" in
        ubuntu|debian)
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo apt update && sudo apt install -y eza
            ;;
        fedora|centos|rhel)
            sudo dnf install -y eza || cargo install eza
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm eza
            ;;
        macos)
            brew install eza
            ;;
    esac
    
    print_success "Modern tools installed"
}

setup_zsh() {
    print_status "Setting up Zsh with Oh My Zsh..."
    
    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install Powerlevel10k theme
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    [[ ! -d "$theme_dir" ]] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
    
    # Install plugins
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    [[ ! -d "$custom_dir/zsh-autosuggestions" ]] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions"
    [[ ! -d "$custom_dir/zsh-syntax-highlighting" ]] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting"
    
    # Set Zsh as default
    sudo chsh -s $(which zsh) $USER 2>/dev/null || true
    
    print_success "Zsh setup complete"
}

setup_tmux() {
    print_status "Setting up Tmux..."
    
    # Install TPM
    [[ ! -d "$HOME/.tmux/plugins/tpm" ]] && \
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    
    print_success "Tmux setup complete"
}

create_zshrc() {
    print_status "Creating .zshrc configuration..."
    
cat > "$HOME/.zshrc" << 'EOF'
# DevOps-focused Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git docker kubectl terraform aws ansible
    zsh-autosuggestions zsh-syntax-highlighting fzf
)

source $ZSH/oh-my-zsh.sh

# Environment
export EDITOR='nvim'
export VISUAL='nvim'
export TERM='xterm-256color'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'
alias dclean='docker system prune -af'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdesc='kubectl describe'
alias klogs='kubectl logs -f'
alias kexec='kubectl exec -it'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
alias gd='git diff'

# System aliases
alias ll='eza -la --icons'
alias la='eza -la --icons'
alias ls='eza --icons'
alias tree='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tmux aliases
alias t='tmux'
alias ta='tmux attach'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'

# Network tools
alias ports='netstat -tulpn'
alias myip='curl -s http://whatismyip.akamai.com/'

# DevOps functions
tf() {
    case $1 in
        init) terraform init ;;
        plan) terraform plan ;;
        apply) terraform apply ;;
        destroy) terraform destroy ;;
        *) terraform "$@" ;;
    esac
}

server-info() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"' || echo 'Unknown')"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory: $(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}' || echo 'N/A')"
    echo "Disk: $(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}' || echo 'N/A')"
}

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# History
HISTSIZE=50000
SAVEHIST=50000
setopt appendhistory sharehistory incappendhistory

# Auto-completion
autoload -U compinit && compinit

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

    print_success ".zshrc created"
}

create_tmux_conf() {
    print_status "Creating .tmux.conf configuration..."
    
cat > "$HOME/.tmux.conf" << 'EOF'
# DevOps-focused Tmux configuration
set -g default-terminal "screen-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Prefix
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Pane management
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# Vim-style navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Vim-style resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Mouse support
set -g mouse on

# Window numbering
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on

# Tokyo Night Moon theme
set -g status-style 'bg=#1e2030 fg=#c8d3f5'
set -g status-left '#[bg=#82aaff,fg=#1e2030,bold] #S #[bg=#1e2030,fg=#82aaff]'
set -g status-right '#[fg=#86e1fc]#[bg=#86e1fc,fg=#1e2030] %H:%M #[bg=#1e2030,fg=#c099ff]#[bg=#c099ff,fg=#1e2030] %d-%b '
setw -g window-status-format ' #I:#W '
setw -g window-status-current-format '#[bg=#82aaff,fg=#1e2030,bold] #I:#W #[bg=#1e2030,fg=#82aaff]'

# Pane borders
set -g pane-border-style 'fg=#3b4261'
set -g pane-active-border-style 'fg=#82aaff'

# Copy mode
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# History
set -g history-limit 10000
set -sg escape-time 0

# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Plugin settings
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'

# Initialize TPM
run '~/.tmux/plugins/tpm/tpm'
EOF

    print_success ".tmux.conf created"
}

create_kitty_conf() {
    print_status "Creating Kitty configuration..."
    
    mkdir -p "$HOME/.config/kitty"
    
cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# DevOps-focused Kitty configuration
font_family JetBrains Mono Nerd Font
font_size 12.0
cursor_shape block
scrollback_lines 10000
mouse_hide_wait 3.0

# Performance
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Window
remember_window_size yes
initial_window_width 1200
initial_window_height 800
window_padding_width 5

# Tabs
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted

# Tokyo Night Moon colors
background #1e2030
foreground #c8d3f5
cursor #c8d3f5
selection_background #2d3f76

# Black
color0 #1b1d2b
color8 #444a73

# Red
color1 #ff757f
color9 #ff757f

# Green
color2 #c3e88d
color10 #c3e88d

# Yellow
color3 #ffc777
color11 #ffc777

# Blue
color4 #82aaff
color12 #82aaff

# Magenta
color5 #c099ff
color13 #c099ff

# Cyan
color6 #86e1fc
color14 #86e1fc

# White
color7 #c8d3f5
color15 #c8d3f5

# Key mappings
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+t new_tab
map ctrl+shift+w close_tab
map ctrl+equal increase_font_size
map ctrl+minus decrease_font_size
EOF

    print_success "Kitty configuration created"
}

main() {
    print_banner
    check_root
    detect_os
    backup_configs
    
    install_packages
    install_modern_tools
    setup_zsh
    setup_tmux
    create_zshrc
    create_tmux_conf
    create_kitty_conf
    
    echo
    print_success "DevOps shell environment setup complete!"
    echo -e "${YELLOW}Log: $LOG_FILE${NC}"
    echo
    echo "Next steps:"
    echo "1. Restart shell: exec zsh"
    echo "2. Configure Powerlevel10k: p10k configure"
    echo "3. Install Tmux plugins: tmux and press Ctrl-a + I"
    echo "4. Reboot for all changes to take effect"
}

main "$@"