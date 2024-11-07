#!/bin/bash

dots="$HOME/Work/.dotfiles"
config="$HOME/.config"
bin="$HOME/.local/bin"
screenshots="$HOME/Pictures/Screenshots"
fonts="${HOME}/.local/share/fonts"

dir="$dots $config $bin $fonts $screenshots"

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/symlinks.sh"
source "$SCRIPT_DIR/python.sh"
source "$SCRIPT_DIR/i3.sh"
source "$SCRIPT_DIR/hyprland.sh"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to configure sudoers for package managers
configure_sudoers() {
    echo "🔧 Configuring sudoers for package managers..."
    local sudoers_file="/etc/sudoers"

    if command_exists xbps-install; then
        sudo sh -c "echo '$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/xbps-install' >> $sudoers_file"
        echo "✅ Added xbps-install to sudoers."
    fi

    if command_exists pacman; then
        sudo sh -c "echo '$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/pacman' >> $sudoers_file"
        echo "✅ Added pacman to sudoers."
    fi

    if command_exists paru; then
        sudo sh -c "echo '$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/paru' >> $sudoers_file"
        echo "✅ Added paru to sudoers."
    fi

    if command_exists apt; then
        sudo sh -c "echo '$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get' >> $sudoers_file"
        echo "✅ Added apt to sudoers."
    fi
}

# Function to ensure paru is installed
setup_paru() {
    if ! command_exists paru; then
        echo "🌐 Installing paru..."
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si
        cd -
        rm -rf /tmp/paru
        echo "✅ paru installed."
    else
        echo "✅ paru is already installed."
    fi
}

# Function to install build-essential
setup_build_essential() {
    echo "🔧 Installing build-essential..."
    case "$OS" in
        $UBUNTU)
            sudo apt install -y build-essential git xorg curl
            ;;
        $ARCH)
            sudo pacman -S --noconfirm --needed base-devel git xorg curl
            setup_paru
            ;;
    esac
}

# Function to install zsh and oh-my-zsh, and set up symlinks
setup_zsh() {
    if ! command_exists zsh; then
        echo "🐚 Installing zsh..."
        case "$OS" in
            $UBUNTU)
                sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting
                ;;
            $ARCH)
                paru -S --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting
                ;;
        esac

        echo "Install the zsh-autosuggestions and zsh-syntax-highlighting plugins manually."
        echo "https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df"
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
setup_python() {
    echo "-----------------------------------------"
    echo "🐍 Installing Python and relevant tools..."
    echo "-----------------------------------------"
    install_python_deps
    install_pyenv
    install_python_version
    install_pip
    install_pipx
    install_pipenv
    display_installation_summary
}

setup_go() {
    echo "-----------------------------------------"
    echo "🐹 Installing Go and relevant tools..."
    echo "-----------------------------------------"

    # Provide the necessary commands to install Go and relevant tools
    case "$OS" in
        $UBUNTU)
            echo "🔧 Installing Go..."
            ;;
        $ARCH)
            echo "🔧 Installing Go..."
            ;;
    esac
}

setup_grub_theme() {
    grub_theme_dir=/usr/share/grub/themes
    sudo mkdir -p $grub_theme_dir
    sudo cp -r $dots/linux/grub/themes/* $grub_theme_dir/
}

setup_tmux() {
    sudo apt install -y tmux
    # Theme
    mkdir -p ~/.config/tmux/plugins/catppuccin
    git clone -b v2.1.0 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
}

# Function to install fonts
setup_fonts() {
    declare -a fonts=(
        FiraCode
        JetBrainsMono
        Iosevka
    )

    # install maple fonts
    echo "🔧 Installing Maple fonts..."
    case "$OS" in
        $UBUNTU) sudo apt install -y ttf-maple ;;
        $ARCH) paru -S --noconfirm ttf-maple ;;
    esac

    # Ensure unzip is installed
    if ! command_exists unzip; then
        echo "🔧 Installing unzip..."
        case "$OS" in
            $UBUNTU) sudo apt install -y unzip ;;
            $ARCH) sudo pacman -S --noconfirm unzip ;;
        esac
    fi

    echo "🔗 Downloading Nerd Fonts..."
    version='3.2.1'

    for font in "${fonts[@]}"; do
        if fc-list | grep -qi "$font"; then
            echo "Font $font already exists, skipping download."
        else
            # Download and unzip the font
            zip_file="${font}.zip"
            download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
            echo "Downloading $download_url"
            wget "$download_url"
            unzip -o "$zip_file" -d "$fonts"
            rm "$zip_file"
            echo "Font $font installed successfully."
        fi
    done

    find "$fonts" -name '*Windows Compatible*' -delete

    echo "🔗 Updating font cache..."
    sudo fc-cache -f -v
}

# Function to change the default shell to zsh
change_default_shell_to_zsh() {
    echo "🔄 Changing the default shell to zsh..."
    sudo chsh -s "$(which zsh)" "$USER"
}

create_dirs() {
    for a in $dir; do
        mkdir -p "$a"
    done
}

# Function to detect the operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s)
    fi
}

# Function to update and upgrade the system
update_and_upgrade() {
    echo "🔄 Updating and upgrading the system..."
    case "$OS" in
        ubuntu)
            sudo apt update && sudo apt upgrade -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac
}

# Main script execution
main () {
    echo "🚀 Starting system setup..."

    echo "🔧 Would you like to install the packages? (y/n)"
    read inst
    echo

    case "$inst" in
        [Nn])
            echo "💡 No packages installed. Goodbye! \n"
            exit 1
            ;;
        [Yy])
            echo "🔧 Installing packages..."
            detect_os
            update_and_upgrade
            create_dirs
            configure_sudoers
            setup_build_essential
            setup_python
            setup_go
            setup_tmux
            setup_fonts

            # Prompt the user for their choice
            echo "Which window manager would you like to install?"
            echo "1) i3"
            echo "2) hyprland"
            echo "Enter the number of your choice: "
            read choice

            # Install based on user choice
            case $choice in
                1)
                    echo "🔧 Installing i3..."
                    setup_i3
                    ;;
                2)
                    echo "🔧 Installing hyprland..."
                    setup_hyprland
                    ;;
                *)
                    echo "❌ Invalid choice. Exiting."
                    exit 1
                    ;;
            esac

            setup_zsh
            change_default_shell_to_zsh

            echo "✅ System setup completed"
            ;;
        *)
            echo "❌ Invalid input. Exiting."
            exit 1
            ;;
    esac
}

main
