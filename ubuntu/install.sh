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

function setup_i3_lock_color() {
    echo "🔧 Installing dependencies for i3lock-color..."
    sudo apt install -y autoconf automake pkg-config libpam0g-dev libcairo2-dev \
                        libxcb1-dev libxcb-composite0-dev libxcb-xinerama0-dev \
                        libxcb-randr0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev \
                        libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev \
                        libxcb-cursor-dev libxkbcommon-dev libxkbcommon-x11-dev \
                        libjpeg-dev

    echo "🔧 Cloning and installing i3lock-color..."
    git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color
    cd /tmp/i3lock-color
    ./install-i3lock-color.sh

    echo "✅ i3lock-color installed successfully."
}

# Function to install i3 and related tools
function setup_i3() {
    echo "🖥️ Installing i3 and related tools..."
    sudo apt install -y i3 i3status                                             \
                        polybar                                                 \
                        rofi                                                    \
                        dunst                                                   \
                        kitty                                                   \
                        alacritty                                               \
                        maim                                                    \
                        picom                                                   \
                        feh                                                     \
                        thunar                                                  \
                        alsa alsa-utils volumeicon-alsa                                         \
                        brightnessctl                                           \
                        bluetoothctl                                            \
                        network-manager-gnome                                   \
                        xclip                                                   \
                        pulseaudio pulseaudio-utils pulseaudio-module-bluetooth \
                        xbacklight                                              \
                        x11-utils                                               \
                        xfce4-power-manager

    echo "🔗 Setting up i3 symlinks..."

    setup_i3_lock_color
    setup_i3_symlink
}

function setup_fonts() {
    # TODO: Install Maple Mono Nerd Font


    declare -a fonts=(
        FiraCode
        FiraMono
        Hack
        JetBrainsMono
        Iosevka
    )

    fonts_dir="${HOME}/.local/share/fonts"
    if [[ ! -d "$fonts_dir" ]]; then
        mkdir -p "$fonts_dir"
    fi

    echo "🔗 Setting up fonts symlinks..."
    cp -r $SCRIPT_DIR/.fonts/* $fonts_dir

    echo "🔗 Downloading Nerd Fonts..."
    version='3.2.1'

    for font in "${fonts[@]}"; do
        zip_file="${font}.zip"
        download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
        echo "Downloading $download_url"
        wget "$download_url"
        unzip "$zip_file" -d "$fonts_dir"
        rm "$zip_file"
    done

    find "$fonts_dir" -name '*Windows Compatible*' -delete

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
