#!/bin/bash

# Ubuntu Server Standalone Setup Script
# This script provides a minimal yet functional setup for Ubuntu servers
# It includes essential tools and configurations without GUI components

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/tmp/ubuntu-server-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Script directory (in case this is run from the repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print colored output
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_status "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect OS version. This script is for Ubuntu servers only."
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_error "This script is designed for Ubuntu. Detected: $ID"
        exit 1
    fi
    
    print_success "Detected Ubuntu $VERSION_ID"
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    print_success "System packages updated"
}

# Install essential packages
install_essential_packages() {
    print_status "Installing essential packages..."
    
    local packages=(
        # Core utilities
        curl
        wget
        git
        vim
        nano
        htop
        tree
        jq
        unzip
        zip
        tar
        gzip
        ca-certificates
        gnupg
        lsb-release
        software-properties-common
        apt-transport-https
        
        # Development tools
        build-essential
        make
        gcc
        g++
        cmake
        pkg-config
        
        # System monitoring
        sysstat
        iotop
        nethogs
        iftop
        
        # Network tools
        net-tools
        dnsutils
        traceroute
        nmap
        tcpdump
        
        # Text processing
        sed
        awk
        grep
        
        # Process management
        supervisor
        
        # Security
        fail2ban
        ufw
        
        # Time sync
        chrony
        
        # Shell
        zsh
        
        # Python
        python3
        python3-pip
        python3-venv
        python3-dev
        
        # Additional utilities
        ncdu
        ripgrep
        fd-find
        bat
        fzf
        tmux
        neovim
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            print_status "$package is already installed"
        else
            print_status "Installing $package..."
            sudo apt-get install -y "$package" || print_warning "Failed to install $package"
        fi
    done
    
    print_success "Essential packages installed"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring UFW firewall..."
    
    # Enable UFW
    sudo ufw --force enable
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (configure port if needed)
    sudo ufw allow 22/tcp comment 'SSH'
    
    # Allow common ports (uncomment as needed)
    # sudo ufw allow 80/tcp comment 'HTTP'
    # sudo ufw allow 443/tcp comment 'HTTPS'
    
    sudo ufw status verbose
    print_success "Firewall configured"
}

# Configure fail2ban
configure_fail2ban() {
    print_status "Configuring fail2ban..."
    
    # Create local jail configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
    
    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    print_success "fail2ban configured"
}

# Setup Docker (optional)
setup_docker() {
    print_status "Would you like to install Docker? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Installing Docker..."
        
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
        
        # Add user to docker group
        sudo usermod -aG docker "$USER"
        
        # Enable and start Docker
        sudo systemctl enable docker
        sudo systemctl start docker
        
        print_success "Docker installed. Please log out and back in for group changes to take effect."
    fi
}

# Configure Git
configure_git() {
    print_status "Configuring Git..."
    
    # Check if git config exists
    if [[ -z "$(git config --global user.name)" ]]; then
        print_status "Enter your Git user name:"
        read -r git_name
        git config --global user.name "$git_name"
    fi
    
    if [[ -z "$(git config --global user.email)" ]]; then
        print_status "Enter your Git email:"
        read -r git_email
        git config --global user.email "$git_email"
    fi
    
    # Set useful defaults
    git config --global init.defaultBranch main
    git config --global core.editor vim
    git config --global pull.rebase false
    
    print_success "Git configured"
}

# Setup minimal Zsh configuration
setup_zsh() {
    print_status "Setting up Zsh..."
    
    # Create .zshrc with minimal configuration
    cat > "$HOME/.zshrc" <<'EOF'
# Minimal Zsh Configuration for Ubuntu Server

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# Key bindings
bindkey -e  # Emacs key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'

# Colored output
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System aliases
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop'

# Docker aliases (if Docker is installed)
if command -v docker &> /dev/null; then
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dl='docker logs'
    alias dprune='docker system prune -a'
fi

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f %F{yellow}${vcs_info_msg_0_}%f$ '

# FZF integration (if installed)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load local configuration if it exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Export paths
export PATH="$HOME/.local/bin:$PATH"
export EDITOR='vim'
export VISUAL='vim'
EOF
    
    # Change default shell to zsh
    print_status "Would you like to change your default shell to Zsh? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        chsh -s "$(which zsh)"
        print_success "Default shell changed to Zsh. Please log out and back in for changes to take effect."
    fi
    
    print_success "Zsh configuration created"
}

# Setup tmux configuration
setup_tmux() {
    print_status "Setting up tmux configuration..."
    
    # Check if .tmux.conf already exists in the repo
    if [[ -f "$SCRIPT_DIR/.tmux.conf" ]]; then
        print_status "Using tmux configuration from repository"
        cp "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
    else
        # Create minimal tmux configuration
        cat > "$HOME/.tmux.conf" <<'EOF'
# Minimal tmux configuration for Ubuntu Server

# Set prefix to Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable 256 colors
set -g default-terminal "screen-256color"

# Status bar
set -g status-style 'bg=colour235 fg=colour136'
set -g status-left '#[fg=colour235,bg=colour214] #S '
set -g status-right '#[fg=colour235,bg=colour214] %Y-%m-%d %H:%M '

# History limit
set -g history-limit 10000

# Vim key bindings in copy mode
setw -g mode-keys vi

# Copy to system clipboard
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
EOF
    fi
    
    print_success "tmux configuration created"
}

# Setup vim configuration
setup_vim() {
    print_status "Setting up Vim configuration..."
    
    # Create minimal .vimrc
    cat > "$HOME/.vimrc" <<'EOF'
" Minimal Vim configuration for Ubuntu Server

" Basic settings
set nocompatible
set encoding=utf-8
set number
set relativenumber
set cursorline
set showmatch
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set incsearch
set hlsearch
set ignorecase
set smartcase
set wildmenu
set wildmode=list:longest
set scrolloff=5
set backspace=indent,eol,start
set ruler
set laststatus=2

" Syntax highlighting
syntax on
filetype plugin indent on

" Color scheme
set background=dark
colorscheme desert

" Key mappings
let mapleader = ","
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>/ :nohlsearch<CR>

" File type specific settings
autocmd FileType python setlocal tabstop=4 shiftwidth=4
autocmd FileType javascript,html,css setlocal tabstop=2 shiftwidth=2
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2

" Remember last position
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif
EOF
    
    print_success "Vim configuration created"
}

# Setup SSH hardening
harden_ssh() {
    print_status "Would you like to harden SSH configuration? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Hardening SSH configuration..."
        
        # Backup original sshd_config
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        
        # Apply hardening settings
        sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<EOF
# SSH Hardening Configuration

# Disable root login
PermitRootLogin no

# Disable password authentication (ensure you have SSH keys set up first!)
# PasswordAuthentication no
# PubkeyAuthentication yes

# Limit user logins
AllowUsers $USER

# Use strong ciphers
Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256

# Other security settings
Protocol 2
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
TCPKeepAlive no
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
EOF
        
        # Test SSH configuration
        sudo sshd -t
        if [[ $? -eq 0 ]]; then
            sudo systemctl restart sshd
            print_success "SSH configuration hardened"
            print_warning "Make sure you have SSH key access before disabling password authentication!"
        else
            print_error "SSH configuration test failed. Reverting changes..."
            sudo rm /etc/ssh/sshd_config.d/99-hardening.conf
        fi
    fi
}

# Create useful directories
create_directories() {
    print_status "Creating useful directories..."
    
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/scripts"
    mkdir -p "$HOME/logs"
    mkdir -p "$HOME/backups"
    
    print_success "Directories created"
}

# Setup cron jobs for system maintenance
setup_cron_jobs() {
    print_status "Setting up system maintenance cron jobs..."
    
    # Create a maintenance script
    cat > "$HOME/scripts/system-maintenance.sh" <<'EOF'
#!/bin/bash
# System maintenance script

LOG_FILE="$HOME/logs/maintenance-$(date +%Y%m%d).log"

echo "=== System Maintenance Started at $(date) ===" >> "$LOG_FILE"

# Update package lists
echo "Updating package lists..." >> "$LOG_FILE"
sudo apt-get update >> "$LOG_FILE" 2>&1

# Clean apt cache
echo "Cleaning apt cache..." >> "$LOG_FILE"
sudo apt-get autoclean >> "$LOG_FILE" 2>&1
sudo apt-get autoremove -y >> "$LOG_FILE" 2>&1

# Log disk usage
echo "Disk usage:" >> "$LOG_FILE"
df -h >> "$LOG_FILE"

echo "=== System Maintenance Completed at $(date) ===" >> "$LOG_FILE"
EOF
    
    chmod +x "$HOME/scripts/system-maintenance.sh"
    
    # Add to crontab (runs weekly on Sunday at 2 AM)
    (crontab -l 2>/dev/null; echo "0 2 * * 0 $HOME/scripts/system-maintenance.sh") | crontab -
    
    print_success "Cron jobs configured"
}

# Install Node.js (optional)
install_nodejs() {
    print_status "Would you like to install Node.js? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Installing Node.js via NodeSource..."
        
        # Install NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        
        # Install yarn
        npm install -g yarn
        
        print_success "Node.js and Yarn installed"
    fi
}

# System information summary
show_system_info() {
    print_status "System Information Summary:"
    echo "================================"
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I | awk '{print $1}')"
    echo "Ubuntu Version: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk Usage:"
    df -h | grep -E '^/dev/' | awk '{print "  " $1 ": " $5 " used (" $3 "/" $2 ")"}'
    echo "================================"
}

# Main installation flow
main() {
    clear
    echo "======================================"
    echo "Ubuntu Server Setup Script"
    echo "======================================"
    echo
    
    # Pre-flight checks
    check_root
    check_ubuntu_version
    
    # Core setup
    update_system
    install_essential_packages
    
    # Security
    configure_firewall
    configure_fail2ban
    harden_ssh
    
    # Development tools
    configure_git
    setup_docker
    install_nodejs
    
    # Shell and editor setup
    setup_zsh
    setup_tmux
    setup_vim
    
    # System configuration
    create_directories
    setup_cron_jobs
    
    # Summary
    show_system_info
    
    print_success "Ubuntu Server setup completed!"
    print_status "Log file saved to: $LOG_FILE"
    print_warning "Remember to:"
    echo "  1. Set up SSH keys if you haven't already"
    echo "  2. Configure any additional firewall rules needed"
    echo "  3. Review and adjust the cron jobs as needed"
    echo "  4. Log out and back in for shell changes to take effect"
}

# Run main function
main "$@"