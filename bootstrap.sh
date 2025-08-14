#!/bin/bash

# Enhanced Bootstrap Script for Dotfiles
# Supports: Ubuntu Desktop, Ubuntu Server, macOS
# Author: dotfiles repository
# Version: 2.0

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$SCRIPT_DIR"

# Log file
LOG_FILE="/tmp/dotfiles-bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Print functions
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║           Dotfiles Installation Script            ║"
    echo "║                   Version 2.0                     ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

# Detect environment type
detect_environment() {
    local os_type=""
    local env_type=""
    local distro=""
    local version=""

    # Detect OS
    case "$OSTYPE" in
        linux-gnu*)
            os_type="linux"

            # Check if it's WSL
            if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
                env_type="wsl"
            else
                # Check for desktop environment
                if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || [[ -n "${DESKTOP_SESSION:-}" ]]; then
                    env_type="desktop"
                else
                    env_type="server"
                fi
            fi

            # Get distribution info
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                distro="$ID"
                version="$VERSION_ID"
            fi
            ;;
        darwin*)
            os_type="macos"
            env_type="desktop"
            version="$(sw_vers -productVersion)"
            ;;
        *)
            print_error "Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac

    # Export environment variables
    export DOTFILES_OS="$os_type"
    export DOTFILES_ENV="$env_type"
    export DOTFILES_DISTRO="${distro:-unknown}"
    export DOTFILES_VERSION="${version:-unknown}"

    print_success "Detected environment:"
    echo "  OS: $DOTFILES_OS"
    echo "  Environment: $DOTFILES_ENV"
    [[ -n "$distro" ]] && echo "  Distribution: $DOTFILES_DISTRO $DOTFILES_VERSION"
    [[ "$os_type" == "macos" ]] && echo "  macOS Version: $version"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check for required commands
    local required_commands=("git" "curl")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_status "Please install them before running this script."
        exit 1
    fi

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended."
        print_status "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            exit 0
        fi
    fi

    print_success "Prerequisites check passed"
}

# Installation menu
show_installation_menu() {
    echo
    echo -e "${MAGENTA}Select installation type:${NC}"
    echo

    case "$DOTFILES_OS" in
        linux)
            echo "  1) Full Installation (Desktop with GUI)"
            echo "  2) Server Installation (Minimal, no GUI)"
            echo "  3) Development Tools Only"
            echo "  4) Shell Configuration Only (Zsh + Tmux)"
            echo "  5) Custom Installation"
            ;;
        macos)
            echo "  1) Full Installation"
            echo "  2) Development Tools Only"
            echo "  3) Shell Configuration Only (Zsh + Tmux)"
            echo "  4) Custom Installation"
            ;;
    esac

    echo "  q) Quit"
    echo
    read -rp "Enter your choice: " choice
    echo

    case "$choice" in
        q|Q)
            print_status "Installation cancelled."
            exit 0
            ;;
        *)
            return "$choice"
            ;;
    esac
}

# Run installation based on selection
run_installation() {
    local choice=$1

    case "$DOTFILES_OS" in
        linux)
            case "$choice" in
                1)
                    print_status "Starting full Linux desktop installation..."
                    source "$SCRIPT_DIR/linux/install.sh"
                    ;;
                2)
                    print_status "Starting Linux server installation..."
                    # Ubuntu server setup script is in the root directory
                    if [[ -f "$SCRIPT_DIR/ubuntu-server-setup.sh" ]]; then
                        bash "$SCRIPT_DIR/ubuntu-server-setup.sh"
                    else
                        print_error "Server setup script not found at $SCRIPT_DIR/ubuntu-server-setup.sh"
                        print_status "Please ensure ubuntu-server-setup.sh is in the repository root"
                        exit 1
                    fi
                    ;;
                3)
                    print_status "Installing shell configuration only..."
                    source "$SCRIPT_DIR/scripts/install-shell.sh"
                    ;;
                *)
                    print_error "Invalid choice"
                    exit 1
                    ;;
            esac
            ;;
        macos)
            case "$choice" in
                1)
                    print_status "Starting full macOS installation..."
                    source "$SCRIPT_DIR/macos/install.sh"
                    ;;
                2)
                    print_status "Installing shell configuration only..."
                    source "$SCRIPT_DIR/scripts/install-shell.sh"
                    ;;
                *)
                    print_error "Invalid choice"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

# Create backup of existing dotfiles
backup_existing_dotfiles() {
    print_status "Would you like to backup existing dotfiles? (Y/n)"
    read -r response
    if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        local backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"

        local dotfiles=(
            ".bashrc" ".zshrc" ".vimrc" ".tmux.conf"
            ".gitconfig" ".config/nvim" ".config/kitty"
        )

        for file in "${dotfiles[@]}"; do
            if [[ -e "$HOME/$file" ]]; then
                print_status "Backing up $file..."
                cp -r "$HOME/$file" "$backup_dir/" 2>/dev/null || true
            fi
        done

        print_success "Backup created at: $backup_dir"
    fi
}

# Post-installation summary
show_summary() {
    echo
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗"
    echo -e "║         Installation Completed Successfully!       ║"
    echo -e "╚═══════════════════════════════════════════════════╝${NC}"
    echo
    print_status "Installation log saved to: $LOG_FILE"
    echo
    print_status "Next steps:"
    echo "  1. Review the installation log for any warnings"
    echo "  2. Restart your shell or run: source ~/.zshrc"
    echo "  3. Check the README for usage instructions"
    echo

    if [[ "$DOTFILES_ENV" == "server" ]]; then
        print_warning "Server installation notes:"
        echo "  - Remember to set up SSH keys"
        echo "  - Configure firewall rules as needed"
        echo "  - Review security settings"
    fi
}

# Main execution
main() {
    # Clear screen and show banner
    clear
    print_banner

    # Detect environment
    detect_environment

    # Check prerequisites
    check_prerequisites

    # Backup existing dotfiles
    backup_existing_dotfiles

    # Show installation menu and get choice
    show_installation_menu
    local choice=$?

    # Run selected installation
    run_installation "$choice"

    # Show summary
    show_summary
}

# Trap errors
trap 'print_error "An error occurred on line $LINENO. Check the log file: $LOG_FILE"' ERR

# Run main function
main "$@"
