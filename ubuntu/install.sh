#!/bin/bash

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source other scripts using the determined directory
source "$SCRIPT_DIR/ubuntu/symlinks.sh"

# Function to update and upgrade the system
function update_and_upgrade() {
    echo "🔄 Updating and upgrading the system..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
}

# Function to install curl
function setup_curl() {
    echo "🌐 Installing curl..."
    sudo apt install -y curl
}

# Function to install git and set up symlinks
function setup_git() {
    echo "🔧 Installing git..."
    sudo apt install -y git
    echo "🔗 Setting up git symlinks..."
    setup_git_symlink
}

# Function to install zsh and oh-my-zsh, and set up symlinks
function setup_zsh() {
    echo "🐚 Installing zsh and oh-my-zsh..."
    sudo apt install -y zsh
    sudo chsh -s $(which zsh) $USER
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
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
    sudo apt install -y i3                      \ # i3 window manager
                        i3status                \ # i3 status bar
                        i3lock                  \ # i3 lock page
                        rofi                    \ # application launcher
                        terminator              \ # terminal
                        maim                    \ # screenshot tool
                        picom                   \ # compositor
                        slop                    \ # selection tool
                        thunar                  \ # File Manager
                        ;
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
