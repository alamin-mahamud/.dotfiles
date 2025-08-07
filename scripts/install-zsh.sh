#!/bin/bash

# Standalone zsh installer
# Simple, idempotent, atomic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_zsh() {
    # Check if zsh is already installed
    if command -v zsh &> /dev/null; then
        echo "zsh is already installed ($(zsh --version))"
        return 0
    fi
    
    echo "Installing zsh..."
    
    # Detect OS and install
    case "$OSTYPE" in
        linux-gnu*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y zsh
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm zsh
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y zsh
            else
                echo "Unsupported package manager"
                exit 1
            fi
            ;;
        darwin*)
            if command -v brew &> /dev/null; then
                brew install zsh
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
    
    echo "zsh installed successfully"
}

install_oh_my_zsh() {
    # Check if Oh My Zsh is already installed
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh is already installed"
        return 0
    fi
    
    echo "Installing Oh My Zsh..."
    
    # Install Oh My Zsh unattended
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    echo "Oh My Zsh installed successfully"
}

configure_zsh() {
    echo "Configuring zsh..."
    
    # Backup existing .zshrc if it exists and is not a symlink
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
        echo "Backed up existing .zshrc"
    fi
    
    # Link zsh config if it exists in dotfiles
    if [[ -f "$SCRIPT_DIR/zsh/.zshrc" ]]; then
        ln -sf "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
        echo "Linked zsh configuration"
    elif [[ -f "$SCRIPT_DIR/configs/.zshrc" ]]; then
        ln -sf "$SCRIPT_DIR/configs/.zshrc" "$HOME/.zshrc"
        echo "Linked zsh configuration"
    fi
    
    # Install zsh plugins
    install_zsh_plugins
}

install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    local AUTOSUGGESTIONS_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    if [[ ! -d "$AUTOSUGGESTIONS_DIR" ]]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR"
    else
        echo "zsh-autosuggestions already installed"
    fi
    
    # zsh-syntax-highlighting
    local SYNTAX_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    if [[ ! -d "$SYNTAX_DIR" ]]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_DIR"
    else
        echo "zsh-syntax-highlighting already installed"
    fi
    
    # powerlevel10k theme
    local P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        echo "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    else
        echo "Powerlevel10k already installed"
    fi
}

set_default_shell() {
    # Only change shell if it's not already zsh
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        echo "Setting zsh as default shell..."
        
        # Add zsh to /etc/shells if not present
        if ! grep -q "$(which zsh)" /etc/shells; then
            echo "$(which zsh)" | sudo tee -a /etc/shells
        fi
        
        # Change default shell
        chsh -s "$(which zsh)"
        echo "Default shell changed to zsh"
    else
        echo "zsh is already the default shell"
    fi
}

main() {
    install_zsh
    install_oh_my_zsh
    configure_zsh
    
    # Ask about setting as default shell
    read -p "Set zsh as default shell? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        set_default_shell
    fi
    
    echo "zsh setup complete"
}

main "$@"