#!/usr/bin/env bash

# Standalone Shell Environment Installer
# Comprehensive shell setup: Zsh + Oh My Zsh + Tmux + CLI tools
# No external dependencies - can be run with:
# curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env-standalone.sh | bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/shell-env-install-$(date +%Y%m%d_%H%M%S).log"

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
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup.$(date +%Y%m%d-%H%M%S)"
        info "Backed up $file to $BACKUP_DIR"
    fi
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
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        apk)
            sudo apk add "${packages[@]}"
            ;;
        brew)
            brew install "${packages[@]}"
            ;;
        *)
            error "Unknown package manager: $pm"
            ;;
    esac
}

install_shell_dependencies() {
    info "Installing shell dependencies..."
    
    local packages=()
    local os
    os=$(detect_os)
    
    case "$os" in
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
        install_packages "${packages[@]}"
    fi
}

install_zsh() {
    if [[ "$SHELL" == *zsh* ]]; then
        success "Zsh is already the default shell"
        return
    fi
    
    info "Setting Zsh as default shell..."
    
    local zsh_path
    zsh_path=$(which zsh)
    
    if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    
    if [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
        success "Zsh set as default shell (restart terminal to take effect)"
    fi
}

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh already installed, updating..."
        cd "$HOME/.oh-my-zsh" && git pull
        success "Updated Oh My Zsh"
    else
        info "Installing Oh My Zsh..."
        export RUNZSH=no
        export KEEP_ZSHRC=yes
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        success "Installed Oh My Zsh"
    fi
}

install_zsh_plugins() {
    info "Installing Zsh plugins..."
    
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    # zsh-autosuggestions
    if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
        cd "$plugins_dir/zsh-autosuggestions" && git pull
        info "Updated zsh-autosuggestions"
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        cd "$plugins_dir/zsh-syntax-highlighting" && git pull
        info "Updated zsh-syntax-highlighting"
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
    fi
    
    # zsh-completions
    if [[ -d "$plugins_dir/zsh-completions" ]]; then
        cd "$plugins_dir/zsh-completions" && git pull
        info "Updated zsh-completions"
    else
        git clone https://github.com/zsh-users/zsh-completions "$plugins_dir/zsh-completions"
    fi
    
    # fzf-tab
    if [[ -d "$plugins_dir/fzf-tab" ]]; then
        cd "$plugins_dir/fzf-tab" && git pull
        info "Updated fzf-tab"
    else
        git clone https://github.com/Aloxaf/fzf-tab "$plugins_dir/fzf-tab"
    fi
}

install_powerlevel10k() {
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    
    if [[ -d "$p10k_dir" ]]; then
        info "Powerlevel10k already installed, updating..."
        cd "$p10k_dir" && git pull
        success "Updated Powerlevel10k"
    else
        info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        success "Installed Powerlevel10k"
    fi
}

install_cli_tools() {
    info "Installing modern CLI tools..."
    local os
    os=$(detect_os)
    
    case "$os" in
        linux)
            install_linux_cli_tools
            ;;
        macos)
            install_macos_cli_tools
            ;;
    esac
    
    install_additional_tools
}

install_linux_cli_tools() {
    case "$(detect_package_manager)" in
        apt)
            install_packages \
                ripgrep fd-find bat eza tree jq htop curl wget git \
                tmux neovim fzf
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
}

install_macos_cli_tools() {
    install_packages \
        ripgrep fd bat eza tree jq htop curl wget git \
        tmux neovim fzf
    
    # Install delta (git diff tool)
    info "Installing delta (git diff tool)..."
    install_packages git-delta
}

install_additional_tools() {
    # Install eza if not available
    if ! command_exists eza; then
        info "Installing eza (modern ls replacement)..."
        if command_exists cargo; then
            cargo install eza
        elif command_exists brew; then
            brew install eza
        else
            warning "Could not install eza - cargo or brew required"
        fi
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
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline'
alias gp='git push'
alias gpl='git pull'
alias gs='git status'
alias gb='git branch'

# Development aliases
alias vim='nvim'
alias vi='nvim'

# System shortcuts
alias reload="source ~/.zshrc"
alias bashrc="$EDITOR ~/.bashrc"
alias zshrc="$EDITOR ~/.zshrc"
alias vimrc="$EDITOR ~/.vimrc"

# Load additional configurations
[ -f ~/.zsh_local ] && source ~/.zsh_local
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    
    success "Created comprehensive .zshrc configuration"
}

install_tmux() {
    info "Setting up Tmux..."
    
    # Install TPM (Tmux Plugin Manager)
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        cd "$tpm_dir" && git pull
        info "Updated TPM"
    else
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi
    
    configure_tmux
}

configure_tmux() {
    backup_file "$HOME/.tmux.conf"
    
    # Create tmux configuration
    cat > "$HOME/.tmux.conf" << 'EOF'
# Tmux configuration

# Set true color
set-option -sa terminal-overrides ",xterm*:Tc"

# Set prefix key to Ctrl-a (more ergonomic than Ctrl-b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Don't rename windows automatically
set-option -g allow-rename off

# Increase scrollback buffer
set -g history-limit 10000

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-copycat'
set -g @plugin 'folke/tokyonight.nvim'

# Tokyo Night theme
set -g @theme_variant 'night'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF
    
    success "Created tmux configuration"
    
    # Install plugins
    info "Installing tmux plugins..."
    "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" >/dev/null 2>&1
    success "Installed tmux plugins"
}

configure_fzf() {
    info "Configuring FZF..."
    
    # Install fzf with key bindings and fuzzy completion
    if command_exists fzf; then
        # Run fzf install script
        if [[ -f /opt/homebrew/opt/fzf/install ]]; then
            /opt/homebrew/opt/fzf/install --all
        elif [[ -f /usr/share/doc/fzf/examples/install ]]; then
            /usr/share/doc/fzf/examples/install --all
        elif [[ -f ~/.fzf/install ]]; then
            ~/.fzf/install --all
        fi
        
        success "FZF configured"
    else
        warning "FZF not found, skipping configuration"
    fi
}

create_shell_aliases() {
    local aliases_file="$HOME/.shell_aliases"
    
    cat > "$aliases_file" << 'EOF'
# Shell aliases for enhanced productivity

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# List directory contents
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
alias ls='ls --color=tty'

# Shortcuts
alias h='history'
alias j='jobs -l'
alias c='clear'
alias path='echo -e ${PATH//:/\\n}'

# Date and time
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# Network
alias ping='ping -c 5'
alias fastping='ping -c 100 -s.2'
alias ports='netstat -tulanp'

# Make commands safer
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Process management
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias myps='ps -f'

# Disk usage
alias du='du -kh'
alias df='df -kTh'

# System info
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
alias cpuinfo='lscpu'

# Archive extraction
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
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
EOF
    
    success "Created local shell aliases"
}

verify_installation() {
    info "Verifying shell installation..."
    
    # Check Zsh
    if command_exists zsh; then
        local zsh_version
        zsh_version=$(zsh --version)
        success "Zsh: $zsh_version"
    else
        error "Zsh not found"
    fi
    
    # Check Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "Oh My Zsh: installed"
    else
        error "Oh My Zsh not found"
    fi
    
    # Check Tmux
    if command_exists tmux; then
        local tmux_version
        tmux_version=$(tmux -V)
        success "Tmux: $tmux_version"
    else
        warning "Tmux not found"
    fi
    
    # Check modern CLI tools
    local tools=("rg" "fd" "bat" "eza" "fzf" "jq")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            success "$tool: installed"
        else
            warning "$tool: not found"
        fi
    done
}

main() {
    print_header "Shell Environment Installer"
    info "Starting at $(date)"
    info "Log file: $LOG_FILE"
    
    install_shell_dependencies
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_powerlevel10k
    install_cli_tools
    configure_zsh
    install_tmux
    configure_fzf
    create_shell_aliases
    
    verify_installation
    
    success "Shell environment setup complete!"
    info "Please restart your terminal or run: exec zsh"
    info "Run 'p10k configure' to set up Powerlevel10k theme"
    info "Tmux prefix key is Ctrl-a"
    
    info "Script finished at $(date)"
}

# Handle script interruption
trap 'echo; warning "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"