#!/usr/bin/env bash

# Shell Environment Installer
# Comprehensive shell setup: Zsh + Oh My Zsh + Tmux + CLI tools
# Supports both server and desktop environments

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Initialize environment variables
setup_environment

# Configuration
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

install_shell_dependencies() {
    info "Installing shell dependencies..."
    
    local packages=()
    
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    packages=(zsh git curl wget unzip build-essential)
                    ;;
                dnf|yum)
                    packages=(zsh git curl wget unzip gcc gcc-c++ make)
                    ;;
                pacman)
                    packages=(zsh git curl wget unzip base-devel)
                    ;;
                apk)
                    packages=(zsh git curl wget unzip build-base)
                    ;;
            esac
            ;;
        macos)
            packages=(zsh git curl wget)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        update_package_lists
        install_packages "${packages[@]}"
    fi
}

install_zsh() {
    if [[ "$SHELL" == *zsh* ]]; then
        info "Zsh is already the default shell"
        return 0
    fi
    
    info "Setting up Zsh as default shell..."
    
    # Ensure zsh is in /etc/shells
    local zsh_path
    zsh_path=$(which zsh)
    
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
        success "Added $zsh_path to /etc/shells"
    fi
    
    # Change default shell
    if [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path" 2>/dev/null || {
            warning "Could not change shell automatically. Please run: chsh -s $zsh_path"
        }
        success "Changed default shell to Zsh"
        info "Please log out and log back in for the shell change to take effect"
    fi
}

install_oh_my_zsh() {
    local oh_my_zsh_dir="$HOME/.oh-my-zsh"
    
    # Always ensure parent directory exists
    mkdir -p "$(dirname "$oh_my_zsh_dir")" 2>/dev/null || true
    
    if [[ -d "$oh_my_zsh_dir" ]]; then
        info "Oh My Zsh already installed, updating..."
        if [[ -d "$oh_my_zsh_dir/.git" ]]; then
            cd "$oh_my_zsh_dir" && git pull origin master 2>/dev/null || {
                warning "Failed to update Oh My Zsh, backing up and reinstalling..."
                backup_file "$oh_my_zsh_dir"
                rm -rf "$oh_my_zsh_dir"
            }
        else
            warning "Oh My Zsh directory exists but not a git repo, backing up and reinstalling..."
            backup_file "$oh_my_zsh_dir"
            rm -rf "$oh_my_zsh_dir"
        fi
        
        if [[ -d "$oh_my_zsh_dir" ]]; then
            success "Updated Oh My Zsh"
            return 0
        fi
    fi
    
    info "Installing Oh My Zsh..."
    
    # Download and install Oh My Zsh
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || {
        error "Failed to install Oh My Zsh"
        return 1
    }
    
    success "Oh My Zsh installed"
}

install_zsh_plugins() {
    local oh_my_zsh_custom="$HOME/.oh-my-zsh/custom"
    
    # Ensure Oh My Zsh custom directories exist
    mkdir -p "$oh_my_zsh_custom/plugins" "$oh_my_zsh_custom/themes" 2>/dev/null || true
    
    info "Installing Zsh plugins..."
    
    # zsh-autosuggestions
    local autosuggestions_dir="$oh_my_zsh_custom/plugins/zsh-autosuggestions"
    if [[ ! -d "$autosuggestions_dir" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir" 2>/dev/null || {
            warning "Failed to clone zsh-autosuggestions"
            return 0
        }
        success "Installed zsh-autosuggestions"
    else
        if [[ -d "$autosuggestions_dir/.git" ]]; then
            cd "$autosuggestions_dir" && git pull 2>/dev/null || {
                warning "Failed to update zsh-autosuggestions, backing up and reinstalling..."
                backup_file "$autosuggestions_dir"
                rm -rf "$autosuggestions_dir"
                git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir" 2>/dev/null || true
            }
        else
            warning "zsh-autosuggestions exists but not a git repo, backing up and reinstalling..."
            backup_file "$autosuggestions_dir"
            rm -rf "$autosuggestions_dir"
            git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir" 2>/dev/null || true
        fi
        info "Updated zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    local highlighting_dir="$oh_my_zsh_custom/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$highlighting_dir" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$highlighting_dir" 2>/dev/null || {
            warning "Failed to clone zsh-syntax-highlighting"
            return 0
        }
        success "Installed zsh-syntax-highlighting"
    else
        if [[ -d "$highlighting_dir/.git" ]]; then
            cd "$highlighting_dir" && git pull 2>/dev/null || {
                warning "Failed to update zsh-syntax-highlighting, backing up and reinstalling..."
                backup_file "$highlighting_dir"
                rm -rf "$highlighting_dir"
                git clone https://github.com/zsh-users/zsh-syntax-highlighting "$highlighting_dir" 2>/dev/null || true
            }
        else
            warning "zsh-syntax-highlighting exists but not a git repo, backing up and reinstalling..."
            backup_file "$highlighting_dir"
            rm -rf "$highlighting_dir"
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "$highlighting_dir" 2>/dev/null || true
        fi
        info "Updated zsh-syntax-highlighting"
    fi
    
    # zsh-completions
    local completions_dir="$oh_my_zsh_custom/plugins/zsh-completions"
    if [[ ! -d "$completions_dir" ]]; then
        git clone https://github.com/zsh-users/zsh-completions "$completions_dir" 2>/dev/null || {
            warning "Failed to clone zsh-completions"
            return 0
        }
        success "Installed zsh-completions"
    else
        if [[ -d "$completions_dir/.git" ]]; then
            cd "$completions_dir" && git pull 2>/dev/null || {
                warning "Failed to update zsh-completions, backing up and reinstalling..."
                backup_file "$completions_dir"
                rm -rf "$completions_dir"
                git clone https://github.com/zsh-users/zsh-completions "$completions_dir" 2>/dev/null || true
            }
        else
            warning "zsh-completions exists but not a git repo, backing up and reinstalling..."
            backup_file "$completions_dir"
            rm -rf "$completions_dir"
            git clone https://github.com/zsh-users/zsh-completions "$completions_dir" 2>/dev/null || true
        fi
        info "Updated zsh-completions"
    fi
    
    # fzf-tab (if desktop environment)
    if is_desktop_environment; then
        local fzf_tab_dir="$oh_my_zsh_custom/plugins/fzf-tab"
        if [[ ! -d "$fzf_tab_dir" ]]; then
            git clone https://github.com/Aloxaf/fzf-tab "$fzf_tab_dir" 2>/dev/null || {
                warning "Failed to clone fzf-tab"
                return 0
            }
            success "Installed fzf-tab"
        else
            if [[ -d "$fzf_tab_dir/.git" ]]; then
                cd "$fzf_tab_dir" && git pull 2>/dev/null || {
                    warning "Failed to update fzf-tab, backing up and reinstalling..."
                    backup_file "$fzf_tab_dir"
                    rm -rf "$fzf_tab_dir"
                    git clone https://github.com/Aloxaf/fzf-tab "$fzf_tab_dir" 2>/dev/null || true
                }
            else
                warning "fzf-tab exists but not a git repo, backing up and reinstalling..."
                backup_file "$fzf_tab_dir"
                rm -rf "$fzf_tab_dir"
                git clone https://github.com/Aloxaf/fzf-tab "$fzf_tab_dir" 2>/dev/null || true
            fi
            info "Updated fzf-tab"
        fi
    fi
}

install_powerlevel10k() {
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    # Ensure themes directory exists
    mkdir -p "$(dirname "$p10k_dir")" 2>/dev/null || true
    
    if [[ -d "$p10k_dir" ]]; then
        info "Powerlevel10k already installed, updating..."
        if [[ -d "$p10k_dir/.git" ]]; then
            cd "$p10k_dir" && git pull 2>/dev/null || {
                warning "Failed to update Powerlevel10k, backing up and reinstalling..."
                backup_file "$p10k_dir"
                rm -rf "$p10k_dir"
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" 2>/dev/null || true
            }
        else
            warning "Powerlevel10k exists but not a git repo, backing up and reinstalling..."
            backup_file "$p10k_dir"
            rm -rf "$p10k_dir"
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" 2>/dev/null || true
        fi
        success "Updated Powerlevel10k"
    else
        info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" 2>/dev/null || {
            warning "Failed to clone Powerlevel10k"
            return 0
        }
        success "Powerlevel10k installed"
    fi
    
    # Install default p10k configuration if none exists
    if [[ ! -f "$HOME/.p10k.zsh" ]]; then
        info "Installing default lean p10k configuration..."
        if [[ -f "$DOTFILES_ROOT/configs/p10k-lean.zsh" ]]; then
            cp "$DOTFILES_ROOT/configs/p10k-lean.zsh" "$HOME/.p10k.zsh"
            success "Installed default p10k configuration"
        else
            # Fallback: download lean config from GitHub
            curl -fsSL https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh -o "$HOME/.p10k.zsh" 2>/dev/null || {
                warning "Could not install default p10k configuration"
            }
        fi
    fi
}

install_cli_tools() {
    info "Installing modern CLI tools..."
    
    case "${DOTFILES_OS}" in
        linux)
            install_linux_cli_tools
            ;;
        macos)
            install_macos_cli_tools
            ;;
    esac
}

install_linux_cli_tools() {
    local pm="$(detect_package_manager)"
    
    # Install via package manager where available
    case "$pm" in
        apt)
            install_packages \
                ripgrep fd-find bat eza tree jq htop curl wget git \
                tmux neovim 
            ;;
        dnf|yum)
            install_packages \
                ripgrep fd-find bat eza tree jq htop curl wget git \
                tmux neovim fzf
            ;;
        pacman)
            install_packages \
                ripgrep fd bat eza tree jq htop curl wget git \
                tmux neovim fzf
            ;;
        apk)
            install_packages \
                ripgrep fd bat tree jq htop curl wget git \
                tmux neovim fzf
            # eza not available in Alpine, will install via cargo
            ;;
    esac
    
    # Install tools that may not be in package managers
    install_additional_tools
}

install_macos_cli_tools() {
    install_packages \
        ripgrep fd bat eza tree jq htop curl wget git \
        tmux neovim fzf
    
    install_additional_tools
}

install_additional_tools() {
    # Install eza if not available
    if ! command_exists eza; then
        info "Installing eza (modern ls replacement)..."
        if command_exists cargo; then
            cargo install eza 2>/dev/null || {
                warning "Failed to install eza via cargo"
            }
        else
            warning "eza requires Rust. Install Rust first or use ls"
        fi
    fi
    
    # Install fzf if not available
    if ! command_exists fzf; then
        info "Installing fzf (cmd-line fuzzy finder)..."
        local fzf_dir="$HOME/.fzf"
        
        # Ensure parent directory exists
        mkdir -p "$(dirname "$fzf_dir")" 2>/dev/null || true
        
        if [[ -d "$fzf_dir" ]]; then
            if [[ -d "$fzf_dir/.git" ]]; then
                cd "$fzf_dir" && git pull 2>/dev/null || {
                    warning "Failed to update fzf, backing up and reinstalling..."
                    backup_file "$fzf_dir"
                    rm -rf "$fzf_dir"
                }
            else
                backup_file "$fzf_dir"
                rm -rf "$fzf_dir"
            fi
        fi
        
        if [[ ! -d "$fzf_dir" ]]; then
            git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir" 2>/dev/null || {
                warning "Failed to clone fzf"
                return 0
            }
        fi
        
        "$fzf_dir/install" --all 2>/dev/null || { 
            warning "Failed to install fzf"
        }
    fi
 
    # Install delta (git diff tool)
    if ! command_exists delta; then
        info "Installing delta (git diff tool)..."
        case "${DOTFILES_OS}" in
            linux)
                local arch
                arch="$(detect_arch)"
                local delta_version="0.16.5"
                local delta_url="https://github.com/dandavison/delta/releases/download/${delta_version}/git-delta_${delta_version}_${arch}.deb"
                
                if [[ "$(detect_package_manager)" == "apt" ]]; then
                    install_package_from_url "$delta_url" 2>/dev/null || {
                        warning "Failed to install delta from URL"
                    }
                fi
                ;;
            macos)
                install_packages git-delta
                ;;
        esac
    fi
}

cleanup_zsh_completions() {
    info "Cleaning up Zsh completions..."
    
    # Remove broken symlinks from zsh site-functions directories
    local dirs=(
        "/usr/local/share/zsh/site-functions"
        "/opt/homebrew/share/zsh/site-functions"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # Find and remove broken symlinks
            find "$dir" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
        fi
    done
    
    # Clean up zcompdump files
    rm -rf "$HOME"/.zcompdump* 2>/dev/null || true
    
    success "Cleaned up Zsh completions"
}

configure_zsh() {
    info "Configuring Zsh..."
    
    # Clean up any broken completions first
    cleanup_zsh_completions
    
    backup_file "$HOME/.zshrc"
    
    # Create comprehensive .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Zsh configuration generated by dotfiles

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Add zsh-completions to fpath before oh-my-zsh loads
if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src" ]]; then
    fpath=($HOME/.oh-my-zsh/custom/plugins/zsh-completions/src $fpath)
fi

# Add Homebrew completions to fpath
if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
    fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
elif [[ -d "/usr/local/share/zsh/site-functions" ]]; then
    fpath=(/usr/local/share/zsh/site-functions $fpath)
fi

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins - Essential only, add more as needed
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    docker
    sudo
    history-substring-search
    colored-man-pages
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User configuration

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

# History configuration
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
autoload -Uz compinit
# Ignore insecure directories and suppress errors from broken symlinks
compinit -i 2>/dev/null || compinit -u
setopt COMPLETE_ALIASES
setopt GLOB_COMPLETE
setopt MENU_COMPLETE
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Key bindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^R' history-incremental-search-backward

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Modern CLI tool aliases
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la'
    alias tree='eza --tree'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph'
alias gp='git push'
alias gs='git status'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'

# System aliases
alias h='history'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Network aliases
alias ping='ping -c 5'
alias ports='netstat -tulanp'

# Process aliases
alias psa='ps aux'
alias psg='ps aux | grep'

# Development aliases
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'
alias json='python3 -m json.tool'

# Editor aliases (if neovim is available)
if command -v nvim >/dev/null 2>&1; then
    alias vim='nvim'
    alias vi='nvim'
    alias vimdiff='nvim -d'
fi

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Load additional configurations
[ -f ~/.zsh_local ] && source ~/.zsh_local
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Disable Powerlevel10k configuration wizard
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load p10k configuration if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    
    success "Created comprehensive .zshrc configuration"
}

install_tmux() {
    info "Setting up Tmux..."
    
    # Ensure tmux is installed
    if ! command_exists tmux; then
        error "tmux installation failed"
        return 1
    fi
    
    # Install TPM (Tmux Plugin Manager)
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    # Ensure .tmux/plugins directory exists
    mkdir -p "$(dirname "$tpm_dir")" 2>/dev/null || true
    
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null || {
            error "Failed to clone TPM"
            return 1
        }
        success "Installed TPM (Tmux Plugin Manager)"
    else
        if [[ -d "$tpm_dir/.git" ]]; then
            cd "$tpm_dir" && git pull 2>/dev/null || {
                warning "Failed to update TPM, backing up and reinstalling..."
                backup_file "$tpm_dir"
                rm -rf "$tpm_dir"
                git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null || true
            }
        else
            warning "TPM exists but not a git repo, backing up and reinstalling..."
            backup_file "$tpm_dir"
            rm -rf "$tpm_dir"
            git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null || true
        fi
        info "Updated TPM"
    fi
    
    configure_tmux
}

configure_tmux() {
    backup_file "$HOME/.tmux.conf"
    
    cat > "$HOME/.tmux.conf" << 'EOF'
# Tmux configuration

# Change prefix to Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse mode
set -g mouse on

# Improve colors
set -g default-terminal "screen-256color"
set-option -ga terminal-overrides ",*256col*:Tc"

# Start window and pane numbering at 1
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity on

# Increase scrollback buffer size
set -g history-limit 10000

# Decrease command delay (increases vim responsiveness)
set -sg escape-time 1

# Increase repeat time for repeatable commands
set -g repeat-time 1000

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Vim-like pane switching
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Vim-like pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Copy mode using 'v' and 'y'
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

# Enable vi mode
setw -g mode-keys vi

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-copycat'

# Theme
set -g @plugin 'folke/tokyonight.nvim'

# Plugin configurations
set -g @resurrect-strategy-nvim 'session'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Status bar
set -g status-position top
set -g status-justify left
set -g status-style 'bg=#1a1b26 fg=#c0caf5'
set -g status-left '#[bg=#7aa2f7,fg=#1a1b26,bold] #S '
set -g status-right '#[bg=#414868,fg=#c0caf5] %Y-%m-%d #[bg=#7aa2f7,fg=#1a1b26,bold] %H:%M '
set -g status-right-length 50
set -g status-left-length 20

# Window status
setw -g window-status-current-style 'bg=#7aa2f7 fg=#1a1b26 bold'
setw -g window-status-current-format ' #I#[fg=#1a1b26]:#[fg=#1a1b26]#W#[fg=#1a1b26]#F '
setw -g window-status-style 'bg=#414868 fg=#c0caf5'
setw -g window-status-format ' #I#[fg=#c0caf5]:#[fg=#c0caf5]#W#[fg=#c0caf5]#F '

# Pane borders
set -g pane-border-style 'fg=#414868'
set -g pane-active-border-style 'fg=#7aa2f7'

# Message text
set -g message-style 'bg=#7aa2f7 fg=#1a1b26 bold'

# Initialize TMUX plugin manager (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF
    
    success "Created tmux configuration"
    
    # Install plugins
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        "$HOME/.tmux/plugins/tpm/bin/install_plugins"
        success "Installed tmux plugins"
    fi
}

configure_fzf() {
    if command_exists fzf; then
        info "Configuring FZF..."
        
        # Install fzf key bindings and fuzzy completion
        if [[ "${DOTFILES_OS}" == "linux" ]]; then
            /usr/share/doc/fzf/examples/install --all 2>/dev/null || \
            ~/.fzf/install --all 2>/dev/null || \
            fzf --version >/dev/null # fallback
        elif [[ "${DOTFILES_OS}" == "macos" ]]; then
            $(brew --prefix)/opt/fzf/install --all
        fi
        
        success "FZF configured"
    fi
}

create_shell_aliases() {
    local alias_file="$HOME/.zsh_local"
    
    if [[ ! -f "$alias_file" ]]; then
        cat > "$alias_file" << 'EOF'
# Local Zsh configuration
# Add your custom aliases and functions here

# Quick navigation
alias work="cd ~/Work"
alias docs="cd ~/Documents"
alias down="cd ~/Downloads"

# System shortcuts
alias reload="source ~/.zshrc"
alias bashrc="$EDITOR ~/.bashrc"
alias zshrc="$EDITOR ~/.zshrc"
alias vimrc="$EDITOR ~/.vimrc"

# Improved defaults
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias mkdir="mkdir -pv"

# Network tools
alias myip="curl http://ipecho.net/plain; echo"
alias localip="ipconfig getifaddr en0"
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"

# System info
alias sysinfo="uname -a"
alias diskspace="df -h"
alias meminfo="free -h"
alias cpuinfo="lscpu"

# Process management
alias top="htop"
alias ps="ps aux"
alias killall="killall"

# Custom functions
weather() {
    curl wttr.in/$1
}

cheat() {
    curl cht.sh/$1
}
EOF
        
        success "Created local shell aliases"
    fi
}

verify_installation() {
    info "Verifying shell installation..."
    
    # Check Zsh
    if command_exists zsh; then
        success "Zsh: $(zsh --version)"
    else
        warning "Zsh not found"
    fi
    
    # Check Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "Oh My Zsh: installed"
    else
        warning "Oh My Zsh not found"
    fi
    
    # Check tmux
    if command_exists tmux; then
        success "Tmux: $(tmux -V)"
    else
        warning "Tmux not found"
    fi
    
    # Check modern CLI tools
    local tools=("rg" "fd" "bat" "eza" "fzf" "jq")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            debug "$tool: ✓"
        fi
    done
}

main() {
    local marker="shell-env-$(date +%Y%m%d)"
    
    if is_completed "$marker"; then
        info "Shell environment already set up today"
        return 0
    fi
    
    init_script "Shell Environment Installer"
    
    # Check for required tools
    require_command git
    require_command curl
    
    # Planning phase
    reset_installation_state
    add_to_plan "Install shell dependencies (zsh, git, curl, build tools)"
    add_to_plan "Configure Zsh as default shell"
    add_to_plan "Install Oh My Zsh framework"
    add_to_plan "Install Zsh plugins (autosuggestions, syntax-highlighting)"
    add_to_plan "Install Powerlevel10k theme"
    add_to_plan "Install modern CLI tools (fzf, ripgrep, fd, bat, eza)"
    add_to_plan "Create comprehensive .zshrc configuration"
    add_to_plan "Configure Tmux with Tokyo Night theme and plugins"
    add_to_plan "Configure FZF key bindings and fuzzy search"
    add_to_plan "Create local shell aliases and functions"
    add_to_plan "Verify installation and functionality"
    
    show_installation_plan "Shell Environment"
    
    # Execution phase with enhanced logging
    execute_step "Install shell dependencies" "install_shell_dependencies"
    execute_step "Configure Zsh as default shell" "install_zsh"
    execute_step "Install Oh My Zsh framework" "install_oh_my_zsh"
    execute_step "Install Zsh plugins" "install_zsh_plugins"
    execute_step "Install Powerlevel10k theme" "install_powerlevel10k"
    execute_step "Install modern CLI tools" "install_cli_tools"
    execute_step "Create comprehensive .zshrc configuration" "configure_zsh"
    execute_step "Configure Tmux with plugins" "install_tmux"
    execute_step "Configure FZF key bindings" "configure_fzf"
    execute_step "Create local shell aliases and functions" "create_shell_aliases"
    execute_step "Verify installation" "verify_installation"
    
    mark_completed "$marker"
    
    show_installation_summary "Shell Environment"
    
    print_header "Shell Environment Setup Complete!"
    info "Next steps:"
    info "1. Restart your terminal or run: exec zsh"
    info "2. Run 'p10k configure' to set up Powerlevel10k theme"
    info "3. Tmux prefix key is Ctrl-a"
    info "4. Use 'fzf' for interactive file search"
    
    if [[ "$SHELL" != *zsh* ]]; then
        warning "Default shell is not Zsh. Please log out and log back in."
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
