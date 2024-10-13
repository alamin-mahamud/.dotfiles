#!/bin/bash

ARCH="arch"
UBUNTU="ubuntu"

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source other scripts using the determined directory
source "$SCRIPT_DIR/symlinks.sh"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect the operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "❌ Unable to detect operating system."
        exit 1
    fi
}

# Function to update and upgrade the system
function update_and_upgrade() {
    echo "🔄 Updating and upgrading the system..."
    if [ "$OS" == $UBUNTU ]; then
        sudo apt-get update -y
        sudo apt-get upgrade -y
    elif [ "$OS" == $ARCH ]; then
        sudo pacman -Syu --noconfirm
    else
        echo "❌ Unsupported operating system: $OS"
        exit 1
    fi
}

# Function to configure sudoers for package managers
function configure_sudoers() {
    echo "🔧 Configuring sudoers for package managers..."

    if command -v xbps-install >/dev/null 2>&1; then
        sudo sh -c 'echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/xbps-install" >> /etc/sudoers'
        echo "✅ Added xbps-install to sudoers."
    fi

    if command -v pacman >/dev/null 2>&1; then
        sudo sh -c 'echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/pacman" >> /etc/sudoers'
        echo "✅ Added pacman to sudoers."
    fi

    if command -v apt >/dev/null 2>&1; then
        sudo sh -c 'echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get" >> /etc/sudoers'
        echo "✅ Added apt to sudoers."
    fi
}

# Function to install curl
function setup_curl() {
    if ! command_exists curl; then
        echo "🌐 Installing curl..."
        if [ "$OS" == $UBUNTU ]; then
            sudo apt install -y curl
        elif [ "$OS" == $ARCH ]; then
            sudo pacman -S --noconfirm curl
        fi
    else
        echo "🌐 curl is already installed."
    fi
}

# Function to install git and set up symlinks
function setup_git() {
    if ! command_exists git; then
        echo "🔧 Installing git..."
        if [ "$OS" == $UBUNTU ]; then
            sudo apt install -y git
        elif [ "$OS" == $ARCH ]; then
            sudo pacman -S --noconfirm git
        fi
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
        if [ "$OS" == $UBUNTU ]; then
            sudo apt install -y zsh
        elif [ "$OS" == $ARCH ]; then
            sudo pacman -S --noconfirm zsh
        fi
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
    if [ "$OS" == $UBUNTU ]; then
        sudo apt install -y autoconf automake pkg-config libpam0g-dev libcairo2-dev \
                            libxcb1-dev libxcb-composite0-dev libxcb-xinerama0-dev \
                            libxcb-randr0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev \
                            libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev \
                            libxcb-cursor-dev libxkbcommon-dev libxkbcommon-x11-dev \
                            libjpeg-dev
    elif [ "$OS" == $ARCH ]; then
        sudo pacman -S --noconfirm autoconf automake pkg-config pam-devel cairo \
                            xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil \
                            xcb-util-wm xcb-util-xrm xcb-util-cursor xcb-util-xinerama \
                            libev xcb-util-xrandr xcb-util-xkb xkbcommon xkbcommon-x11 \
                            libjpeg-turbo
    fi

    echo "🔧 Cloning and installing i3lock-color..."
    git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color
    cd /tmp/i3lock-color
    ./install-i3lock-color.sh

    echo "✅ i3lock-color installed successfully."
}

# Function to install i3 and related tools
function setup_i3() {
    echo "🖥️ Installing i3 and related tools..."
    if [ "$OS" == $UBUNTU ]; then
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
    elif [ "$OS" == $ARCH ]; then
        sudo pacman -S --noconfirm i3-wm i3status i3lock \
                            polybar rofi dunst kitty alacritty maim picom feh thunar \
                            alsa-utils volumeicon brightnessctl bluez-utils network-manager-applet \
                            xclip pulseaudio pulseaudio-alsa pulseaudio-bluetooth xorg-xbacklight \
                            xorg-xprop xfce4-power-manager
    fi

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
        if fc-list | grep -qi "$font"; then
            echo "Font $font already exists, skipping download."
        else
            zip_file="${font}.zip"
            download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
            echo "Downloading $download_url"
            wget "$download_url"
            unzip "$zip_file" -d "$fonts_dir"
            rm "$zip_file"
            echo "Font $font installed successfully."
        fi
    done

    find "$fonts_dir" -name '*Windows Compatible*' -delete

    echo "🔗 Updating font cache..."
    sudo fc-cache -f -v
}

# Main script execution
echo "🚀 Starting system setup..."

detect_os
update_and_upgrade
configure_sudoers
setup_curl
setup_git
setup_zsh
setup_python
setup_i3
setup_fonts

echo "✅ System setup completed successfully."
