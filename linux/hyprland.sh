#!/bin/bash

# Function to install hyprland and its dependencies
setup_hyprland() {
    echo "${ACT} Installing hyprland and its dependencies..."

    # Update package list and install dependencies
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm hyprland waybar swaylock wofi alacritty kitty

    if [ $? -eq 0 ]; then
        echo "$GREEN hyprland and its dependencies installed successfully."
    else
        echo "$RED Failed to install hyprland and its dependencies."
        exit 1
    fi

    echo "${ACT} 🔗 Setting up hyprland symlinks..."
    setup_config hyprland
}
