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

function setup_alacritty() {
    echo "🔗 Configuring alacritty ..."
    mkdir -p $HOME/.config/alacritty
    cp $SCRIPT_DIR/.config/alacritty/alacritty.yml $HOME/.config/alacritty/alacritty.yml

    echo "🔗 Configuring alacritty color theme ..."
    git clone https://github.com/catppuccin/alacritty.git ~/.config/alacritty/catppuccin
}

function setup_kitty(){
    echo "🔗 Configuring kitty ..."
    cp $SCRIPT_DIR/.config/kitty $HOME/.config/kitty
}

# Function to install i3 and related tools
function setup_i3() {
    echo "🖥️ Installing i3 and related tools..."
    sudo apt install -y i3                      \
                        i3status                \
                        i3lock                  \
                        rofi                    \
                        kitty                    \
                        alacritty               \
                        maim                    \
                        picom                   \
                        slop                    \
                        feh                     \
                        thunar
    echo "🔗 Setting up i3 symlinks..."
    setup_i3_symlink

    setup_alacritty
    setup_kitty

    echo "🔗 Configuring dunst ..."
    cp $SCRIPT_DIR/.config/dunst $HOME/.config/dunst

    echo "🔗 Configuring rofi ..."
    cp $SCRIPT_DIR/.config/rofi $HOME/.config/rofi

}

function setup_fonts() {
    echo "🔠 Installing fonts..."
    sudo apt install -y fonts-firacode fonts-font-awesome
    echo "🔗 Setting up fonts symlinks..."
    sudo mkdir -p /usr/local/share/fonts
    sudo cp -r $SCRIPT_DIR/.fonts/* /usr/local/share/fonts/
    echo "🔗 Updating font cache..."
    sudo fc-cache -f -v
}

# Main script execution
echo "🚀 Starting system setup..."

update_and_upgrade
setup_curl
setup_git
setup_zsh
setup_python
setup_i3
setup_fonts

echo "✅ System setup completed successfully."
