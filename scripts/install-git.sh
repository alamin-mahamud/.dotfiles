#!/bin/bash

# Standalone git installer
# Simple, idempotent, atomic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_git() {
    # Check if git is already installed
    if command -v git &> /dev/null; then
        echo "git is already installed ($(git --version))"
        return 0
    fi
    
    echo "Installing git..."
    
    # Detect OS and install
    case "$OSTYPE" in
        linux-gnu*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y git
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm git
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y git
            else
                echo "Unsupported package manager"
                exit 1
            fi
            ;;
        darwin*)
            if command -v brew &> /dev/null; then
                brew install git
            else
                # git comes with Xcode Command Line Tools
                echo "Installing Xcode Command Line Tools..."
                xcode-select --install
            fi
            ;;
        *)
            echo "Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac
    
    echo "git installed successfully"
}

configure_git() {
    echo "Configuring git..."
    
    # Link gitconfig if it exists in dotfiles
    if [[ -f "$SCRIPT_DIR/git/.gitconfig" ]]; then
        ln -sf "$SCRIPT_DIR/git/.gitconfig" "$HOME/.gitconfig"
        echo "Linked git configuration"
    elif [[ -f "$SCRIPT_DIR/configs/.gitconfig" ]]; then
        ln -sf "$SCRIPT_DIR/configs/.gitconfig" "$HOME/.gitconfig"
        echo "Linked git configuration"
    fi
    
    # Link gitignore global if it exists
    if [[ -f "$SCRIPT_DIR/git/.gitignore_global" ]]; then
        ln -sf "$SCRIPT_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
        git config --global core.excludesfile "$HOME/.gitignore_global"
        echo "Linked global gitignore"
    fi
    
    # Set up basic git config if not already set
    setup_git_basics
}

setup_git_basics() {
    # Check if user name is set
    if [[ -z "$(git config --global user.name || true)" ]]; then
        read -p "Enter your Git name: " git_name
        git config --global user.name "$git_name"
    fi
    
    # Check if user email is set
    if [[ -z "$(git config --global user.email || true)" ]]; then
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
    fi
    
    # Set some sensible defaults
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global fetch.prune true
    git config --global diff.colorMoved zebra
    git config --global rebase.autoStash true
    
    echo "Basic git configuration complete"
}

install_git_extras() {
    read -p "Install GitHub CLI? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v gh &> /dev/null; then
            echo "Installing GitHub CLI..."
            case "$OSTYPE" in
                linux-gnu*)
                    if command -v apt-get &> /dev/null; then
                        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                        sudo apt update && sudo apt install -y gh
                    elif command -v pacman &> /dev/null; then
                        sudo pacman -S --noconfirm github-cli
                    fi
                    ;;
                darwin*)
                    brew install gh
                    ;;
            esac
            echo "GitHub CLI installed"
        else
            echo "GitHub CLI already installed"
        fi
    fi
}

main() {
    install_git
    configure_git
    install_git_extras
    echo "git setup complete"
}

main "$@"