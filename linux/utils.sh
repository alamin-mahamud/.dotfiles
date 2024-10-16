#!/bin/bash

ARCH="arch"
UBUNTU="ubuntu"


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
update_and_upgrade() {
    echo "🔄 Updating and upgrading the system..."
    case "$OS" in
        $UBUNTU)
            sudo apt-get update -y
            sudo apt-get upgrade -y
            ;;
        $ARCH)
            if ! command_exists paru; then
                sudo paru -Syu --noconfirm
            else
                sudo pacman -Syu --noconfirm
            fi
            ;;
        *)
            echo "❌ Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}
