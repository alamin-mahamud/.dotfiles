#!/bin/bash

ARCH="arch"
UBUNTU="ubuntu"

# Define console output variables
GREEN="$(tput setaf 2)[✅ OK]$(tput sgr0)"
RED="$(tput setaf 1)[❌ ERROR]$(tput sgr0)"
YELLOW="$(tput setaf 3)[💡 NOTE]$(tput sgr0)"
ACT="$(tput setaf 6)[🔧 ACTION]$(tput sgr0)"
LOG="/tmp/install.log"



print_error() {
    printf " %s%s\n" "$RED" "$1" "$NC" >&2
}

# Function to print success messages
print_success() {
    printf "%s%s%s\n" "$GREEN" "$1" "$NC"
}

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
        echo "${RED} Unable to detect operating system."
        exit 1
    fi
}


# Function to update and upgrade the system
update_and_upgrade() {
    echo "${YELLOW}🔄 Updating and upgrading the system..."
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
            echo "${RED}Unsupported operating system: $OS"
            exit 1
            ;;
    esac
}
