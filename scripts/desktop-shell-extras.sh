#!/bin/bash

# Desktop Shell Environment Extra Components
# Additional tools and configurations for desktop/workstation environments
# These are separated from the main install-shell.sh to keep server installs lean
# Usage: ./desktop-shell-extras.sh

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/desktop-shell-extras-$(date +%Y%m%d_%H%M%S).log"

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

# Install LazyVim (idempotent) - Advanced IDE-like Neovim setup
install_lazyvim() {
  print_status "Setting up LazyVim..."

  # Check Neovim version
  if ! command -v nvim &>/dev/null; then
    print_error "Neovim is not installed. Please install Neovim first."
    return 1
  fi

  local nvim_version=$(nvim --version | head -n1 | cut -d' ' -f2)
  print_status "Found Neovim version: $nvim_version"

  # Backup existing Neovim config
  if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
    local backup_dir="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backing up existing Neovim config to $backup_dir"
    mv "$HOME/.config/nvim" "$backup_dir"
  fi

  # Clone LazyVim starter if not exists
  if [[ ! -d "$HOME/.config/nvim" ]]; then
    print_status "Installing LazyVim starter template..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" --depth 1
    rm -rf "$HOME/.config/nvim/.git"
    print_success "LazyVim starter template installed"
  else
    print_success "LazyVim already installed"
  fi

  # Install language servers and tools based on OS
  print_status "Installing language servers and development tools..."

  case "$OS" in
  ubuntu | debian)
    # Node.js for many LSPs
    if ! command -v node &>/dev/null; then
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo apt-get install -y nodejs
    fi
    # Python tools
    command -v pip3 &>/dev/null && pip3 install --user pynvim || true
    # Ripgrep for telescope
    command -v rg &>/dev/null || sudo apt-get install -y ripgrep
    # fd for telescope file finder
    command -v fd &>/dev/null || sudo apt-get install -y fd-find
    ;;
  fedora | centos | rhel | rocky | almalinux)
    # Node.js for many LSPs
    if ! command -v node &>/dev/null; then
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
      sudo dnf install -y nodejs || sudo yum install -y nodejs
    fi
    # Python tools
    command -v pip3 &>/dev/null && pip3 install --user pynvim || true
    # Ripgrep for telescope
    command -v rg &>/dev/null || sudo dnf install -y ripgrep || sudo yum install -y ripgrep
    # fd for telescope file finder
    command -v fd &>/dev/null || sudo dnf install -y fd-find || true
    ;;
  arch | manjaro)
    # Node.js for many LSPs
    command -v node &>/dev/null || sudo pacman -S --noconfirm nodejs npm
    # Python tools
    command -v pip3 &>/dev/null && pip3 install --user pynvim || true
    # Ripgrep for telescope
    command -v rg &>/dev/null || sudo pacman -S --noconfirm ripgrep
    # fd for telescope file finder
    command -v fd &>/dev/null || sudo pacman -S --noconfirm fd
    ;;
  macos)
    # Node.js for many LSPs
    command -v node &>/dev/null || brew install node
    # Python tools
    command -v pip3 &>/dev/null && pip3 install --user pynvim || true
    # Ripgrep for telescope
    command -v rg &>/dev/null || brew install ripgrep
    # fd for telescope file finder
    command -v fd &>/dev/null || brew install fd
    ;;
  *)
    print_warning "Package installation not configured for $OS"
    ;;
  esac

  print_success "LazyVim setup complete"
  print_status "Run 'nvim' and LazyVim will install plugins automatically on first launch"
}

# Install Nerd Fonts (idempotent) - Enhanced fonts for terminal icons
install_fonts() {
  print_status "Installing Nerd Fonts..."

  case "$OS" in
  ubuntu | debian | fedora | centos | rhel | rocky | almalinux | arch | manjaro | opensuse* | sles)
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
  if ls "$FONT_DIR"/*Nerd* &>/dev/null 2>&1; then
    print_success "Nerd Fonts already installed"
    return 0
  fi

  # Install multiple Nerd Fonts for better coverage
  local fonts=("SourceCodePro" "FiraCode" "JetBrainsMono" "Iosevka")
  
  for font in "${fonts[@]}"; do
    print_status "Installing $font Nerd Font..."
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
    
    if curl -L -o "/tmp/${font}.zip" "$font_url" 2>/dev/null; then
      unzip -q -o "/tmp/${font}.zip" -d "$FONT_DIR" 2>/dev/null
      rm "/tmp/${font}.zip"
      print_success "$font Nerd Font installed"
    else
      print_warning "Failed to download $font Nerd Font"
    fi
  done

  # Update font cache on Linux
  if [[ "$OS" != "macos" ]]; then
    if command -v fc-cache &>/dev/null; then
      print_status "Updating font cache..."
      fc-cache -fv >/dev/null 2>&1
      print_success "Font cache updated"
    fi
  fi

  print_success "Nerd Fonts installation complete"
}

# Install Powerlevel10k theme with instant prompt
install_powerlevel10k() {
  print_status "Installing Powerlevel10k theme..."

  local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  if [[ -d "$P10K_DIR" ]]; then
    print_status "Updating Powerlevel10k..."
    cd "$P10K_DIR" && git pull --rebase --quiet
    print_success "Powerlevel10k updated"
  else
    print_status "Cloning Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    print_success "Powerlevel10k installed"
  fi
}

# Configure Powerlevel10k with instant prompt
configure_powerlevel10k() {
  print_status "Configuring Powerlevel10k..."

  # Create comprehensive P10k configuration
  cat >"$HOME/.p10k.zsh" <<'EOF'
# Generated by desktop-shell-extras.sh - Powerlevel10k configuration

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k configuration
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

# Prompt elements
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  dir
  vcs
  newline
  prompt_char
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  virtualenv
  nodeenv
  goenv
  rustenv
  aws
  azure
  kubectl_context
  terraform
  docker_context
  time
)

# Visual customization
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{blue}❯%f '

# Directory customization
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3
typeset -g POWERLEVEL9K_DIR_PATH_SEPARATOR=' %F{blue}/%f '
typeset -g POWERLEVEL9K_DIR_PATH_HIGHLIGHT_BOLD=true
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique

# VCS (Git) configuration
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='green'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='yellow'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='red'

# Command execution time
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=2

# Background jobs
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false

# Context (user@host) - show only when in SSH or root
typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION=
typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false

# Time format
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_TIME_FOREGROUND='white'

# Status
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='red'

# Colors
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND='cyan'
typeset -g POWERLEVEL9K_DIR_FOREGROUND='blue'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND='green'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND='red'

# Transient prompt
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

# Instant prompt mode
typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

# Hot reload function
function p10k-reload() {
  source ~/.p10k.zsh
  echo "Powerlevel10k configuration reloaded!"
}
EOF

  print_success "Powerlevel10k configured with instant prompt"
}

# Install additional GUI-friendly tools
install_desktop_tools() {
  print_status "Installing desktop-oriented tools..."

  case "$OS" in
  ubuntu | debian)
    # GUI developer tools
    sudo apt-get update
    sudo apt-get install -y \
      gitk \
      gitg \
      meld \
      tkdiff \
      2>/dev/null || true
    ;;
  fedora | centos | rhel | rocky | almalinux)
    sudo dnf install -y \
      gitk \
      meld \
      2>/dev/null || sudo yum install -y gitk meld 2>/dev/null || true
    ;;
  arch | manjaro)
    sudo pacman -S --noconfirm \
      gitk \
      meld \
      2>/dev/null || true
    ;;
  macos)
    # GUI developer tools for macOS
    brew install --cask \
      sourcetree \
      beyond-compare \
      2>/dev/null || true
    ;;
  *)
    print_warning "Desktop tools installation not configured for $OS"
    ;;
  esac

  print_success "Desktop tools installation complete"
}

# Main installation function
main() {
  clear
  echo "========================================"
  echo "Desktop Shell Environment Extras Installer"
  echo "========================================"
  echo "Enhanced components for desktop/workstation use"
  echo

  # Detect OS
  detect_os

  # Check if base shell environment is installed
  if ! command -v zsh &>/dev/null || [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    print_error "Base shell environment not found!"
    print_status "Please run install-shell.sh first to install the base environment."
    exit 1
  fi

  # Install desktop components
  echo
  print_status "Installing desktop enhancements..."
  echo

  # LazyVim for advanced Neovim IDE features
  install_lazyvim

  # Nerd Fonts for terminal icons
  install_fonts

  # Powerlevel10k theme with full features
  install_powerlevel10k
  configure_powerlevel10k

  # Additional desktop tools
  install_desktop_tools

  # Summary
  echo
  echo "========================================"
  print_success "Desktop shell extras installation complete!"
  echo "========================================"
  echo
  echo "Installed components:"
  echo "  • LazyVim - Advanced Neovim IDE configuration"
  echo "  • Nerd Fonts - Enhanced terminal fonts with icons"
  echo "  • Powerlevel10k - Advanced Zsh theme with instant prompt"
  echo "  • Desktop developer tools - GUI diff/merge tools"
  echo
  echo "Next steps:"
  echo "  1. Restart your terminal to load the new configuration"
  echo "  2. Run 'nvim' to let LazyVim install its plugins"
  echo "  3. Configure your terminal to use a Nerd Font (e.g., 'SauceCodePro Nerd Font')"
  echo "  4. Run 'p10k configure' to customize your Powerlevel10k prompt"
  echo
  echo "Installation log: $LOG_FILE"
  echo
}

# Run main function
main "$@"