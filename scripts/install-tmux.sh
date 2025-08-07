#!/bin/bash

# Standalone tmux installer
# Simple, idempotent, atomic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_tmux() {
    # Check if tmux is already installed
    if command -v tmux &> /dev/null; then
        echo "tmux is already installed ($(tmux -V))"
        return 0
    fi
    
    echo "Installing tmux..."
    
    # Detect OS and install
    case "$OSTYPE" in
        linux-gnu*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y tmux
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm tmux
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y tmux
            else
                echo "Unsupported package manager"
                exit 1
            fi
            ;;
        darwin*)
            if command -v brew &> /dev/null; then
                brew install tmux
            else
                echo "Homebrew not found. Please install it first."
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac
    
    echo "tmux installed successfully"
}

configure_tmux() {
    echo "Configuring tmux..."
    
    # Create config directory
    mkdir -p "$HOME/.config/tmux"
    
    # Link tmux config if it exists in dotfiles
    if [[ -f "$SCRIPT_DIR/configs/.tmux.conf" ]]; then
        ln -sf "$SCRIPT_DIR/configs/.tmux.conf" "$HOME/.tmux.conf"
        echo "Linked tmux configuration"
    elif [[ -f "$SCRIPT_DIR/tmux/.tmux.conf" ]]; then
        ln -sf "$SCRIPT_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
        echo "Linked tmux configuration"
    fi
    
    # Install TPM (Tmux Plugin Manager) if not present
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
        echo "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        echo "TPM installed"
    else
        echo "TPM already installed"
    fi
}

main() {
    install_tmux
    configure_tmux
    echo "tmux setup complete"
}

main "$@"