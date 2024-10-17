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
source "$SCRIPT_DIR/i3.sh"
source "$SCRIPT_DIR/hyprland.sh"

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
    if ! command -v paru &> /dev/null; then
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
                sudo apt install -y zsh
                ;;
            $ARCH)
                sudo paru -S --noconfirm zsh
                ;;
        esac
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


# Function to install fonts
setup_fonts() {
    declare -a fonts=(
        FiraCode
        FiraMono
        Hack
        JetBrainsMono
        Iosevka
    )

    # install maple fonts
    echo "🔧 Installing Maple fonts..."
    case "$OS" in
        $UBUNTU) sudo apt install y- ttf-maple ;;
        $ARCH) sudo paru -S --noconfirm ttf-maple ;;
    esac

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
            unzip "$zip_file" -d "$fonts"
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

# Main script execution
main () {
    echo "${YELLOW} 🚀 Starting system setup..."

    read -n1 -rep "${ACT} Would you like to install the packages? (y/n)" inst
    echo

    case "$inst" in
        [Nn])
            echo "${YELLOW} No packages installed. Goodbye! \n"
            exit 1
            ;;
        [Yy])
            echo "${ACT} Installing packages..."
            detect_os
            update_and_upgrade
            create_dirs
            configure_sudoers
            setup_build_essential
            setup_python
            setup_fonts

            # Prompt the user for their choice
            echo "Which window manager would you like to install?"
            echo "1) i3"
            echo "2) hyperland"
            read -p "Enter the number of your choice: " choice

            # Install based on user choice
            case $choice in
                1)
                    echo "${YELLOW} Installing i3..."
                    setup_i3
                    ;;
                2)
                    echo "${YELLOW} Installing hyperland..."
                    setup_hyprland
                    ;;
                *)
                    echo "${RED} Invalid choice. Exiting."
                    exit 1
                    ;;
            esac

            setup_zsh
            change_default_shell_to_zsh

            echo "${GREEN} System setup completed"
            ;;
        *)
            echo "${RED} Invalid input. Exiting."
            exit 1
            ;;
    esac
}

