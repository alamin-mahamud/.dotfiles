#!/bin/bash

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source other scripts using the determined directory
source "$SCRIPT_DIR/symlinks.sh"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to update and upgrade the system
function update_and_upgrade() {
    echo "🔄 Updating and upgrading the system..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
}

# Function to install curl
function setup_curl() {
    if ! command_exists curl; then
        echo "🌐 Installing curl..."
        sudo apt install -y curl
    else
        echo "🌐 curl is already installed."
    fi
}

# Function to install git and set up symlinks
function setup_git() {
    if ! command_exists git; then
        echo "🔧 Installing git..."
        sudo apt install -y git
    else
        echo "🔧 git is already installed."
    fi
    echo "🔗 Setting up git symlinks..."
    setup_git_symlink
}

# Function to install zsh and oh-my-zsh, and set up symlinks
function setup_zsh() {
    if ! command_exists zsh; then
        echo "🐚 Installing zsh..."
        sudo apt install -y zsh
        sudo chsh -s $(which zsh) $USER
    else
        echo "🐚 zsh is already installed."
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "🐚 Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    else
        echo "🐚 oh-my-zsh is already installed."
    fi

    echo "🔗 Setting up zsh symlinks..."
    setup_zsh_symlink
}

# Function to install Python and relevant tools
function setup_python() {
    echo "🐍 Installing Python and relevant tools..."
    source "$SCRIPT_DIR/python.sh"
}

# Function to install i3 and related tools
function setup_i3() {
    echo "🖥️ Installing i3 and related tools..."
    sudo apt install -y i3                      \
                        i3status                \
                        i3lock                  \
                        rofi                    \
                        terminator              \
                        maim                    \
                        picom                   \
                        slop                    \
                        thunar
    echo "🔗 Setting up i3 symlinks..."
    setup_i3_symlink
}

# Main script execution
echo "🚀 Starting system setup..."

update_and_upgrade
setup_curl
setup_git
setup_zsh
setup_python
setup_i3

echo "✅ System setup completed successfully."
