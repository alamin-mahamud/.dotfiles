#!/bin/bash

# Enhanced Shell Environment Standalone Installer
# DRY orchestrator that installs and configures Zsh, Oh My Zsh, and shell tools
# This script provides a modern shell environment with productivity enhancements
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-shell.sh | bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/shell-install-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected macOS"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        print_success "Detected $PRETTY_NAME"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
}

# Backup existing configuration files
backup_existing_configs() {
    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zsh_functions"
        "$HOME/.z.sh"
        "$HOME/.p10k.zsh"
    )
    
    local backup_needed=false
    for file in "${files_to_backup[@]}"; do
        if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
            backup_needed=true
            break
        fi
    done
    
    if [[ "$backup_needed" == true ]]; then
        print_status "Backing up existing configuration files..."
        mkdir -p "$BACKUP_DIR"
        
        for file in "${files_to_backup[@]}"; do
            if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
                cp "$file" "$BACKUP_DIR/" 2>/dev/null || true
                print_status "Backed up $(basename "$file")"
            fi
        done
        print_success "Backups saved to $BACKUP_DIR"
    fi
}

# Install Zsh (idempotent)
install_zsh() {
    print_status "Checking Zsh installation..."
    
    if command -v zsh &> /dev/null; then
        print_success "Zsh is already installed ($(zsh --version))"
        return 0
    fi
    
    print_status "Installing Zsh..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y zsh
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y zsh || sudo yum install -y zsh
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm zsh
            ;;
        alpine)
            sudo apk add --no-cache zsh
            ;;
        opensuse*|sles)
            sudo zypper install -y zsh
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                print_warning "Homebrew not found. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install zsh
            ;;
        *)
            print_error "Unsupported OS for Zsh installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Zsh installed successfully"
}

# Install Oh My Zsh (idempotent)
install_oh_my_zsh() {
    print_status "Checking Oh My Zsh installation..."
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh is already installed"
        # Update to latest version
        print_status "Updating Oh My Zsh..."
        cd "$HOME/.oh-my-zsh" && git pull --quiet && cd - > /dev/null
        return 0
    fi
    
    print_status "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    print_success "Oh My Zsh installed"
}

# Install Zsh plugins (idempotent)
install_zsh_plugins() {
    print_status "Installing Zsh plugins..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        print_status "Installing zsh-autosuggestions..."
        git clone --quiet https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
        print_status "Updating zsh-autosuggestions..."
        cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull --quiet && cd - > /dev/null
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        print_status "Installing zsh-syntax-highlighting..."
        git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    else
        print_status "Updating zsh-syntax-highlighting..."
        cd "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && git pull --quiet && cd - > /dev/null
    fi
    
    # zsh-completions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
        print_status "Installing zsh-completions..."
        git clone --quiet https://github.com/zsh-users/zsh-completions \
            "$ZSH_CUSTOM/plugins/zsh-completions"
    else
        print_status "Updating zsh-completions..."
        cd "$ZSH_CUSTOM/plugins/zsh-completions" && git pull --quiet && cd - > /dev/null
    fi
    
    # fzf-tab
    if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
        print_status "Installing fzf-tab..."
        git clone --quiet https://github.com/Aloxaf/fzf-tab \
            "$ZSH_CUSTOM/plugins/fzf-tab"
    else
        print_status "Updating fzf-tab..."
        cd "$ZSH_CUSTOM/plugins/fzf-tab" && git pull --quiet && cd - > /dev/null
    fi
    
    print_success "Zsh plugins installed"
}

# Install Powerlevel10k theme (idempotent)
install_powerlevel10k() {
    print_status "Installing Powerlevel10k theme..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$ZSH_CUSTOM/themes/powerlevel10k"
    else
        print_status "Updating Powerlevel10k..."
        cd "$ZSH_CUSTOM/themes/powerlevel10k" && git pull --quiet && cd - > /dev/null
    fi
    
    print_success "Powerlevel10k installed"
}

# Configure Zsh (idempotent)
configure_zsh() {
    print_status "Configuring Zsh..."
    
    # Create embedded .zshrc configuration
    cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Enhanced Zsh Configuration - Generated by install-shell.sh

# System detection
if [[ $(uname) = 'Linux' ]]; then
    IS_LINUX=1
fi

if [[ $(uname) = 'Darwin' ]]; then
    IS_MAC=1
fi

# Environment variables
export LANG=en_US.UTF-8
export TERM=xterm-256color
export EDITOR=vim
export VISUAL=vim
export PATH="$HOME/.local/bin:$PATH:/usr/local/go/bin"

# History configuration
HISTSIZE=10000
SAVEHIST=9000
HISTFILE=~/.zsh_history

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (fzf-tab must be last)
plugins=(
    git
    docker
    kubectl
    terraform
    aws
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf-tab
)

source $ZSH/oh-my-zsh.sh

# Python environment
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

export PIPENV_PYTHON="$HOME/.pyenv/shims/python"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Z directory jumping
[ -f ~/.z.sh ] && source ~/.z.sh

# Load custom functions
[ -f ~/.zsh_functions ] && source ~/.zsh_functions

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim 2>/dev/null || vim'
alias tm='tmux'
alias tma='tmux attach-session -t'
alias tmn='tmux new-session -s'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'

# FZF-tab configuration
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:*' switch-group F1 F2

# Enable kubectl completion if available
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC_EOF
    
    # Create custom functions file
    cat > "$HOME/.zsh_functions" << 'FUNCTIONS_EOF'
# Custom Zsh Functions

# Display formatted PATH
path() {
    echo $PATH | tr ":" "\n" | nl
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
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
            *)          echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
FUNCTIONS_EOF
    
    print_success "Zsh configuration created"
}

# Install FZF (idempotent)
install_fzf() {
    print_status "Installing FZF..."
    
    if command -v fzf &> /dev/null; then
        print_success "FZF is already installed ($(fzf --version))"
        return 0
    fi
    
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    
    "$HOME/.fzf/install" --all --no-bash --no-fish --no-update-rc
    print_success "FZF installed"
}

# Install Z directory jumper (idempotent)
install_z() {
    print_status "Installing Z directory jumper..."
    
    if [[ -f "$HOME/.z.sh" ]]; then
        print_success "Z is already installed"
        return 0
    fi
    
    curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o "$HOME/.z.sh"
    chmod +x "$HOME/.z.sh"
    print_success "Z installed"
}

# Install shell tools (idempotent)
install_shell_tools() {
    print_status "Installing additional shell tools..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y \
                curl wget git \
                htop tree jq \
                ripgrep fd-find bat \
                ncdu tldr \
                2>/dev/null || true
            
            # Create symlinks for renamed packages
            sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
            
            # Install eza if not present
            if ! command -v eza &> /dev/null; then
                print_status "Installing eza..."
                local EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
                curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
                sudo tar -xzf /tmp/eza.tar.gz -C /usr/local/bin
                rm /tmp/eza.tar.gz
            fi
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y \
                curl wget git \
                htop tree jq \
                ripgrep fd-find bat \
                ncdu \
                2>/dev/null || sudo yum install -y \
                curl wget git \
                htop tree jq \
                2>/dev/null || true
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm \
                curl wget git \
                htop tree jq \
                ripgrep fd bat eza \
                ncdu \
                2>/dev/null || true
            ;;
        macos)
            brew install \
                htop tree jq \
                ripgrep fd bat eza \
                ncdu tldr \
                zoxide starship \
                2>/dev/null || true
            ;;
    esac
    
    print_success "Shell tools installed"
}

# Install fonts (idempotent)
install_fonts() {
    print_status "Installing Nerd Fonts..."
    
    case "$OS" in
        ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|opensuse*|sles)
            FONT_DIR="$HOME/.local/share/fonts"
            ;;
        macos)
            FONT_DIR="$HOME/Library/Fonts"
            ;;
        *)
            print_warning "Skipping font installation for unsupported OS: $OS"
            return 0
            ;;
    esac
    
    mkdir -p "$FONT_DIR"
    
    # Check if fonts are already installed
    if ls "$FONT_DIR"/*Nerd* &> /dev/null; then
        print_success "Nerd Fonts already installed"
        return 0
    fi
    
    # Install SourceCodePro Nerd Font
    local font="SourceCodePro"
    print_status "Installing $font Nerd Font..."
    
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
    if curl -L -o "/tmp/${font}.zip" "$font_url"; then
        unzip -q -o "/tmp/${font}.zip" -d "$FONT_DIR"
        rm "/tmp/${font}.zip"
        print_success "$font Nerd Font installed"
    else
        print_warning "Failed to download $font Nerd Font"
    fi
    
    # Update font cache on Linux
    if [[ "$OS" != "macos" ]]; then
        fc-cache -fv > /dev/null 2>&1
    fi
    
    print_success "Fonts installed"
}

# Change default shell to Zsh
change_shell() {
    print_status "Checking default shell..."
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_success "Zsh is already the default shell"
        return 0
    fi
    
    print_status "Would you like to change your default shell to Zsh? (Y/n)"
    read -r response
    if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        if command -v zsh &> /dev/null; then
            local zsh_path="$(command -v zsh)"
            
            # Add zsh to /etc/shells if not already there
            if ! grep -q "$zsh_path" /etc/shells; then
                echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
            fi
            
            # Change shell
            chsh -s "$zsh_path"
            print_success "Default shell changed to Zsh"
            print_warning "Please log out and back in for the change to take effect"
        else
            print_error "Zsh not found. Please install it first."
        fi
    fi
}

# Show summary
show_summary() {
    echo
    echo "========================================"
    echo "Shell Environment Installation Summary"
    echo "========================================"
    echo
    print_success "✓ Zsh installed and configured"
    print_success "✓ Oh My Zsh framework installed"
    print_success "✓ Plugins: autosuggestions, syntax-highlighting, completions, fzf-tab"
    print_success "✓ Powerlevel10k theme installed"
    print_success "✓ FZF fuzzy finder installed"
    print_success "✓ Z directory jumper installed"
    print_success "✓ Additional shell tools installed"
    print_success "✓ Nerd Fonts installed"
    echo
    print_status "📋 Configuration files:"
    echo "  • ~/.zshrc - Main configuration"
    echo "  • ~/.zsh_functions - Custom functions"
    echo "  • ~/.z.sh - Directory jumper"
    echo
    print_status "📁 Log file: $LOG_FILE"
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Run 'p10k configure' to set up Powerlevel10k theme"
    echo "  2. Restart your terminal or run: source ~/.zshrc"
    echo "  3. Try these commands:"
    echo "     • fzf - Fuzzy find files"
    echo "     • z <partial-path> - Jump to directory"
    echo "     • cd <TAB> - Browse directories with preview"
    echo
    print_status "🚀 Your enhanced shell environment is ready!"
}

# Main installation
main() {
    clear
    echo "========================================"
    echo "Enhanced Shell Environment Installer"
    echo "========================================"
    echo
    
    # Pre-flight checks
    check_root
    detect_os
    
    # Backup existing configs
    backup_existing_configs
    
    # Core installations
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_powerlevel10k
    configure_zsh
    
    # Additional tools
    install_fzf
    install_z
    install_shell_tools
    install_fonts
    
    # Optionally change default shell
    change_shell
    
    # Show summary
    show_summary
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi