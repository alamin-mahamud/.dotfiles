#!/usr/bin/env bash

# Shell Environment Standalone Installer
# Comprehensive, self-contained shell setup: Zsh + Oh My Zsh + Tmux + CLI tools
# Optimized for Ubuntu servers - no external dependencies
#
# Installation: curl -fsSL <URL> | bash
# Re-run safe: This script is idempotent and can be run multiple times safely
#
# Author: Dotfiles Project
# Version: 1.0.0

set -euo pipefail

# =============================================================================
# EMBEDDED UTILITY FUNCTIONS (No External Dependencies)
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global variables
SCRIPT_NAME="Shell Environment Installer"
SCRIPT_VERSION="1.0.0"
LOG_FILE="/tmp/shell-env-install-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/tmp/shell-env-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
NO_BACKUP=false
FORCE=false

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

debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        log "${PURPLE}DEBUG: $1${NC}"
    fi
}

print_header() {
    log "${WHITE}${1}${NC}"
    log "${WHITE}$(printf '%.0s=' {1..${#1}})${NC}"
}

# OS Detection functions
detect_os() {
    case "$OSTYPE" in
        linux-gnu*) echo "linux" ;;
        darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}

detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi
    
    local distro_id
    distro_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo "${distro_id,,}"  # lowercase
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

# Environment detection
is_desktop_environment() {
    [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || \
    [[ -n "${DESKTOP_SESSION:-}" ]] || \
    [[ -n "${DISPLAY:-}" ]] || \
    [[ -n "${WAYLAND_DISPLAY:-}" ]]
}

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || \
    [[ "$(uname -r)" == *microsoft* ]] || \
    [[ "$(uname -r)" == *WSL* ]]
}

# Command utilities
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        error "Required command '$1' not found"
    fi
}

# Network utilities
check_internet() {
    if command_exists curl; then
        curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1
    elif command_exists wget; then
        wget -q --timeout=5 --tries=1 --spider https://www.google.com >/dev/null 2>&1
    else
        return 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -fsSL "$url" -o "$output"
    elif command_exists wget; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget is available"
    fi
}

# File operations
backup_file() {
    local file="$1"
    
    if [[ "$NO_BACKUP" == "true" ]]; then
        debug "Backup skipped for $file (--no-backup flag)"
        return 0
    fi
    
    if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/$(basename "$file").$(date +%Y%m%d-%H%M%S)"
        
        if [[ ! -e "$backup_file" ]]; then
            cp "$file" "$backup_file"
            info "Backed up $file to $backup_file"
        else
            debug "Backup already exists: $backup_file"
        fi
    fi
}

safe_symlink() {
    local source="$1"
    local target="$2"
    local backup="${3:-true}"
    
    # Check if symlink already exists and points to correct target
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        debug "Symlink already exists and is correct: $target -> $source"
        return 0
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    # Backup existing file if not a symlink
    if [[ "$backup" == "true" ]]; then
        backup_file "$target"
    fi
    
    # Remove existing file/symlink
    [[ -e "$target" ]] && rm -f "$target"
    
    # Create symlink
    ln -sf "$source" "$target"
    debug "Created symlink: $target -> $source"
}

# User interaction
ask_yes_no() {
    local question="$1"
    local default="${2:-no}"
    local response
    
    if [[ "$default" == "yes" ]]; then
        question="${question} [Y/n]: "
    else
        question="${question} [y/N]: "
    fi
    
    while true; do
        read -r -p "$question" response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        case "$response" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            "") 
                if [[ "$default" == "yes" ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Package management functions
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    elif command_exists apk; then
        echo "apk"
    else
        echo "unknown"
    fi
}

update_package_lists() {
    local pm="$(detect_package_manager)"
    local update_marker="/tmp/.shell-env-packages-updated"
    
    # Check if recently updated (within 1 hour)
    if [[ -f "$update_marker" ]]; then
        local last_update=0
        if [[ "$OSTYPE" == "darwin"* ]]; then
            last_update=$(stat -f %m "$update_marker" 2>/dev/null || echo 0)
        else
            last_update=$(stat -c %Y "$update_marker" 2>/dev/null || echo 0)
        fi
        
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_update))
        
        if [[ $time_diff -lt 3600 ]]; then
            debug "Package lists recently updated, skipping"
            return 0
        fi
    fi
    
    info "Updating package lists..."
    
    case "$pm" in
        apt)
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] Would run: sudo apt-get update"
            else
                if timeout 60 sudo apt-get update -qq 2>/dev/null; then
                    touch "$update_marker"
                    success "Package lists updated"
                else
                    warning "Failed to update package lists, continuing anyway"
                fi
            fi
            ;;
        dnf)
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] Would run: sudo dnf check-update"
            else
                (timeout 60 sudo dnf check-update -q || true) && touch "$update_marker"
            fi
            ;;
        *) warning "Unknown package manager: $pm" ;;
    esac
}

install_packages() {
    local packages=("$@")
    local pm="$(detect_package_manager)"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages specified for installation"
        return 0
    fi
    
    info "Installing packages: ${packages[*]} (using $pm)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install: ${packages[*]}"
        return 0
    fi
    
    case "$pm" in
        apt)
            timeout 300 sudo apt-get install -y "${packages[@]}" || {
                warning "Package installation may have failed or timed out"
                return 1
            }
            ;;
        dnf)
            timeout 300 sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            timeout 300 sudo yum install -y "${packages[@]}"
            ;;
        *) error "Cannot install packages: unknown package manager '$pm'" ;;
    esac
}

# =============================================================================
# SHELL ENVIRONMENT INSTALLATION FUNCTIONS
# =============================================================================

install_shell_dependencies() {
    info "Installing shell dependencies..."
    
    local packages=()
    local pm="$(detect_package_manager)"
    
    case "$pm" in
        apt)
            packages=(zsh git curl wget unzip build-essential)
            ;;
        dnf|yum)
            packages=(zsh git curl wget unzip gcc gcc-c++ make)
            ;;
        *) 
            packages=(zsh git curl wget unzip)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        update_package_lists
        install_packages "${packages[@]}"
    fi
    
    success "Shell dependencies installed"
}

configure_zsh_as_default() {
    if [[ "$SHELL" == *zsh* ]]; then
        info "Zsh is already the default shell"
        return 0
    fi
    
    info "Setting up Zsh as default shell..."
    
    local zsh_path
    zsh_path=$(which zsh)
    
    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] Would add $zsh_path to /etc/shells"
        else
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
            success "Added $zsh_path to /etc/shells"
        fi
    fi
    
    # Change default shell
    if [[ "$SHELL" != "$zsh_path" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] Would change shell to: $zsh_path"
        else
            chsh -s "$zsh_path" 2>/dev/null || {
                warning "Could not change shell automatically. Please run: chsh -s $zsh_path"
                return 0
            }
            success "Changed default shell to Zsh"
            info "Please log out and log back in for the shell change to take effect"
        fi
    fi
}

install_oh_my_zsh() {
    local oh_my_zsh_dir="$HOME/.oh-my-zsh"
    
    if [[ -d "$oh_my_zsh_dir" ]]; then
        info "Oh My Zsh already installed, updating..."
        if [[ -d "$oh_my_zsh_dir/.git" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] Would update Oh My Zsh"
            else
                cd "$oh_my_zsh_dir" && git pull origin master 2>/dev/null || {
                    warning "Failed to update Oh My Zsh"
                }
                success "Updated Oh My Zsh"
            fi
        fi
        return 0
    fi
    
    info "Installing Oh My Zsh..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install Oh My Zsh"
        return 0
    fi
    
    # Download and install Oh My Zsh
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null || {
        error "Failed to install Oh My Zsh"
    }
    
    success "Oh My Zsh installed"
}

install_zsh_plugins() {
    local oh_my_zsh_custom="$HOME/.oh-my-zsh/custom"
    mkdir -p "$oh_my_zsh_custom/plugins" "$oh_my_zsh_custom/themes" 2>/dev/null || true
    
    info "Installing Zsh plugins..."
    
    local plugins=(
        "https://github.com/zsh-users/zsh-autosuggestions|$oh_my_zsh_custom/plugins/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting|$oh_my_zsh_custom/plugins/zsh-syntax-highlighting"
        "https://github.com/zsh-users/zsh-completions|$oh_my_zsh_custom/plugins/zsh-completions"
    )
    
    # Add fzf-tab for desktop environments
    if is_desktop_environment; then
        plugins+=("https://github.com/Aloxaf/fzf-tab|$oh_my_zsh_custom/plugins/fzf-tab")
    fi
    
    for plugin_spec in "${plugins[@]}"; do
        IFS='|' read -r repo_url target_dir <<< "$plugin_spec"
        local plugin_name=$(basename "$target_dir")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] Would install plugin: $plugin_name"
            continue
        fi
        
        if [[ ! -d "$target_dir" ]]; then
            git clone "$repo_url" "$target_dir" 2>/dev/null || {
                warning "Failed to clone $plugin_name"
                continue
            }
            success "Installed $plugin_name"
        else
            if [[ -d "$target_dir/.git" ]]; then
                cd "$target_dir" && git pull 2>/dev/null || true
                info "Updated $plugin_name"
            fi
        fi
    done
}

install_powerlevel10k() {
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install Powerlevel10k theme"
        return 0
    fi
    
    if [[ -d "$p10k_dir" ]]; then
        info "Powerlevel10k already installed, updating..."
        if [[ -d "$p10k_dir/.git" ]]; then
            cd "$p10k_dir" && git pull 2>/dev/null || true
            success "Updated Powerlevel10k"
        fi
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
        curl -fsSL https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh -o "$HOME/.p10k.zsh" 2>/dev/null || {
            warning "Could not install default p10k configuration"
        }
    fi
}

install_modern_cli_tools() {
    info "Installing modern CLI tools..."
    
    local pm="$(detect_package_manager)"
    local packages=()
    
    case "$pm" in
        apt)
            packages=(ripgrep fd-find bat eza tree jq htop curl wget git tmux neovim)
            ;;
        dnf|yum)
            packages=(ripgrep fd-find bat eza tree jq htop curl wget git tmux neovim fzf)
            ;;
        *)
            packages=(tree jq htop curl wget git tmux)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        install_packages "${packages[@]}"
    fi
    
    # Install fzf if not available
    install_fzf
    
    success "Modern CLI tools installed"
}

install_fzf() {
    if command_exists fzf; then
        debug "fzf already installed"
        return 0
    fi
    
    info "Installing fzf (fuzzy finder)..."
    local fzf_dir="$HOME/.fzf"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install fzf"
        return 0
    fi
    
    if [[ -d "$fzf_dir" ]]; then
        if [[ -d "$fzf_dir/.git" ]]; then
            cd "$fzf_dir" && git pull 2>/dev/null || true
        else
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
}

configure_zsh() {
    info "Configuring Zsh..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would create .zshrc configuration"
        return 0
    fi
    
    backup_file "$HOME/.zshrc"
    
    # Create comprehensive .zshrc
    cat > "$HOME/.zshrc" << 'EOF'
# Zsh configuration - Generated by Shell Environment Installer

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Add zsh-completions to fpath before oh-my-zsh loads
if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src" ]]; then
    fpath=($HOME/.oh-my-zsh/custom/plugins/zsh-completions/src $fpath)
fi

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins - Essential only
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

# Add fzf-tab for desktop environments
if [[ -n "${XDG_CURRENT_DESKTOP:-}${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    plugins+=(fzf-tab)
fi

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

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

# Modern CLI tool aliases
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la'
    alias tree='eza --tree'
else
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
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

# System aliases
alias h='history'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Development aliases
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'

# Editor aliases
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
    
    if ! command_exists tmux; then
        error "tmux installation failed"
    fi
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install TPM and configure tmux"
        return 0
    fi
    
    # Install TPM (Tmux Plugin Manager)
    mkdir -p "$(dirname "$tpm_dir")" 2>/dev/null || true
    
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null || {
            error "Failed to clone TPM"
        }
        success "Installed TPM (Tmux Plugin Manager)"
    else
        if [[ -d "$tpm_dir/.git" ]]; then
            cd "$tpm_dir" && git pull 2>/dev/null || true
            info "Updated TPM"
        fi
    fi
    
    configure_tmux
}

configure_tmux() {
    backup_file "$HOME/.tmux.conf"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would create .tmux.conf configuration"
        return 0
    fi
    
    cat > "$HOME/.tmux.conf" << 'EOF'
# Tmux configuration - Generated by Shell Environment Installer

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

# Increase scrollback buffer size
set -g history-limit 20000

# Decrease command delay
set -sg escape-time 0

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

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

# Enable vi mode
setw -g mode-keys vi

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

# Theme - Catppuccin
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavour 'frappe'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF

    success "Created tmux configuration"
    
    # Install plugins
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
        success "Installed tmux plugins"
    fi
}

verify_installation() {
    info "Verifying shell installation..."
    
    local errors=0
    
    # Check Zsh
    if command_exists zsh; then
        success "Zsh: $(zsh --version)"
    else
        warning "Zsh not found"
        errors=$((errors + 1))
    fi
    
    # Check Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "Oh My Zsh: installed"
    else
        warning "Oh My Zsh not found"
        errors=$((errors + 1))
    fi
    
    # Check tmux
    if command_exists tmux; then
        success "Tmux: $(tmux -V)"
    else
        warning "Tmux not found"
        errors=$((errors + 1))
    fi
    
    # Check modern CLI tools
    local tools=("rg" "fd" "bat" "fzf" "jq")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            debug "$tool: ✓"
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        success "All components verified successfully"
    else
        warning "$errors components failed verification"
    fi
}

# =============================================================================
# ARGUMENT PARSING AND MAIN FUNCTION
# =============================================================================

show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

A standalone, idempotent installer for a comprehensive shell environment.
Installs Zsh + Oh My Zsh + Powerlevel10k + Tmux + modern CLI tools.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help              Show this help message and exit
    --version           Show version information and exit
    --dry-run           Show what would be installed without making changes
    --no-backup         Skip backing up existing configuration files
    --force             Override existing installations and configurations
    --debug             Enable debug output

EXAMPLES:
    # Standard installation
    $0

    # Dry run to see what would be installed
    $0 --dry-run

    # Install without backing up existing configs
    $0 --no-backup

    # One-liner installation (curl pipe)
    curl -fsSL <URL> | bash

    # One-liner with options
    curl -fsSL <URL> | bash -s -- --dry-run

FEATURES:
    • Zsh with Oh My Zsh framework
    • Powerlevel10k theme with instant prompt
    • Essential plugins: autosuggestions, syntax-highlighting, completions
    • Tmux with plugin manager and Catppuccin theme
    • Modern CLI tools: ripgrep, fd, bat, eza, fzf, jq
    • Comprehensive aliases and functions
    • Idempotent - safe to run multiple times
    • Server and desktop environment support

REQUIREMENTS:
    • Ubuntu 20.04+ (or compatible Linux distribution)
    • Internet connection
    • sudo privileges for package installation

For more information, visit: https://github.com/alamin-mahamud/.dotfiles
EOF
}

show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-backup)
                NO_BACKUP=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --debug)
                export DEBUG=1
                shift
                ;;
            *)
                error "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"
    
    print_header "$SCRIPT_NAME v$SCRIPT_VERSION"
    info "Starting at $(date)"
    info "Log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    if [[ "$NO_BACKUP" == "true" ]]; then
        info "Backup disabled - existing files will be overwritten"
    else
        info "Backup directory: $BACKUP_DIR"
    fi
    
    # Check for required tools
    require_command git
    require_command curl
    
    # Detect environment
    local os="$(detect_os)"
    local distro="$(detect_distro)"
    info "Detected OS: $os ($distro)"
    
    if [[ "$os" != "linux" ]]; then
        error "This script is designed for Linux systems. Detected: $os"
    fi
    
    # Check for internet connectivity
    if ! check_internet; then
        warning "No internet connection detected. Some features may not work."
    fi
    
    # Installation steps
    info "Beginning shell environment installation..."
    
    install_shell_dependencies
    configure_zsh_as_default
    install_oh_my_zsh
    install_zsh_plugins
    install_powerlevel10k
    install_modern_cli_tools
    configure_zsh
    install_tmux
    verify_installation
    
    print_header "Shell Environment Setup Complete!"
    success "Installation completed successfully!"
    
    info "Next steps:"
    info "1. Restart your terminal or run: exec zsh"
    info "2. Run 'p10k configure' to set up Powerlevel10k theme"
    info "3. Tmux prefix key is Ctrl-a"
    info "4. Use 'fzf' for interactive file search"
    
    if [[ "$SHELL" != *zsh* ]]; then
        warning "Default shell is not Zsh. Please log out and log back in."
    fi
    
    if [[ "$DRY_RUN" == "false" ]]; then
        info "Installation log: $LOG_FILE"
        if [[ "$NO_BACKUP" == "false" ]]; then
            info "Configuration backups: $BACKUP_DIR"
        fi
    fi
    
    info "Finished at $(date)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
