#!/usr/bin/env bash
# Minimal Dotfiles Installation - Idempotent & DevOps Focused

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles.backup.$(date +%Y%m%d_%H%M%S)"

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Platform detection
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="linux";;
        Darwin*)    OS="macos";;
        *)          OS="unknown";;
    esac
    
    if [[ "$OS" == "linux" ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO="${ID}"
            VERSION="${VERSION_ID}"
        fi
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    
    # If target exists and is not a symlink to our source
    if [[ -e "$target" ]] && [[ ! -L "$target" || "$(readlink "$target")" != "$source" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_warn "Backing up existing $target to $BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
    fi
    
    # Create symlink if it doesn't exist
    if [[ ! -L "$target" || "$(readlink "$target")" != "$source" ]]; then
        ln -sf "$source" "$target"
        log_info "Created symlink: $target -> $source"
    else
        log_info "Symlink already exists: $target"
    fi
}

# Install essential packages
install_packages() {
    local packages="git vim tmux zsh curl wget"
    
    if [[ "$OS" == "linux" ]]; then
        if command_exists apt-get; then
            log_info "Installing packages with apt..."
            sudo apt-get update -qq
            sudo apt-get install -y -qq $packages
        elif command_exists yum; then
            log_info "Installing packages with yum..."
            sudo yum install -y -q $packages
        elif command_exists pacman; then
            log_info "Installing packages with pacman..."
            sudo pacman -Sy --noconfirm --quiet $packages
        fi
    elif [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        log_info "Installing packages with brew..."
        brew install $packages
    fi
}

# Install dotfiles
install_dotfiles() {
    log_info "Installing dotfiles..."
    
    # Create necessary directories
    mkdir -p "${HOME}/.config"
    mkdir -p "${HOME}/.local/bin"
    mkdir -p "${HOME}/.vim/undodir"
    
    # Install configuration files
    create_symlink "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
    create_symlink "${DOTFILES_DIR}/.tmux.conf" "${HOME}/.tmux.conf"
    create_symlink "${DOTFILES_DIR}/.vimrc" "${HOME}/.vimrc"
    create_symlink "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
}

# Configure shell
configure_shell() {
    # Set zsh as default shell if not already
    if [[ "$SHELL" != */zsh ]]; then
        if command_exists zsh; then
            log_info "Setting zsh as default shell..."
            if [[ "$OS" == "linux" ]]; then
                sudo chsh -s "$(which zsh)" "$USER"
            elif [[ "$OS" == "macos" ]]; then
                chsh -s "$(which zsh)"
            fi
        fi
    else
        log_info "Zsh is already the default shell"
    fi
}

# Install kubectl if not present
install_kubectl() {
    if ! command_exists kubectl; then
        log_info "Installing kubectl..."
        if [[ "$OS" == "linux" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        elif [[ "$OS" == "macos" ]]; then
            brew install kubectl
        fi
    else
        log_info "kubectl is already installed"
    fi
}

# Install additional DevOps tools
install_devops_tools() {
    log_info "Checking DevOps tools..."
    
    # Install kubectl
    install_kubectl
    
    # Install helm if not present
    if ! command_exists helm; then
        log_info "Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Install k9s if not present (optional)
    if ! command_exists k9s; then
        log_info "k9s not found (optional tool)"
    fi
}

# Main installation
main() {
    log_info "Starting minimal dotfiles installation..."
    
    # Detect OS
    detect_os
    log_info "Detected OS: $OS ${DISTRO:-} ${VERSION:-}"
    
    # Clone repository if running remotely
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_info "Cloning dotfiles repository..."
        git clone https://github.com/alamin-mahamud/dotfiles.git "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
    else
        log_info "Dotfiles directory already exists"
        cd "$DOTFILES_DIR"
        git pull --quiet
    fi
    
    # Install packages
    install_packages
    
    # Install dotfiles
    install_dotfiles
    
    # Configure shell
    configure_shell
    
    # Install DevOps tools
    install_devops_tools
    
    log_info "Installation complete!"
    log_info "Please restart your terminal or run: source ~/.zshrc"
    
    # Clean up old backups (keep last 3)
    if [[ -d "${HOME}/.dotfiles.backup"* ]]; then
        log_info "Cleaning old backups..."
        ls -dt "${HOME}"/.dotfiles.backup.* | tail -n +4 | xargs rm -rf 2>/dev/null || true
    fi
}

# Run main function
main "$@"