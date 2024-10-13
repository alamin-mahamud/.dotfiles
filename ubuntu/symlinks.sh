#!/bin/bash

DOT=$HOME/Work/.dotfiles
DOT_UBUNTU=$DOT/ubuntu

# Function to create symlinks for Zsh configuration
function setup_zsh_symlink() {
    echo "🔗 Creating symlink for .zshrc..."
    ln -sf $DOT/zsh/.zshrc $HOME/.zshrc
    echo "✅ Symlink for .zshrc created."
}

# Function to create symlinks for Git configuration
function setup_git_symlink() {
    echo "🔗 Creating symlinks for Git configuration..."
    ln -sf $DOT/git/.gitconfig $HOME/.gitconfig
    ln -sf $DOT/git/.gitmessage $HOME/.gitmessage
    echo "✅ Symlinks for Git configuration created."
}

# Function to create symlinks for i3 configuration
function setup_i3_symlink() {

    # Define the base directories
    SOURCE_DIR="$DOT_UBUNTU/.config"
    DEST_DIR="$HOME/.config"

    items=(
        "i3"
        "picom.conf"
        "dunst"
        "rofi"
        "alacritty"
        "kitty"
        "polybar"
    )

    echo "🔗 Creating symlinks for i3 configuration..."
    mkdir -p $DEST_DIR

    # Loop through the items and create symlinks
    for item in "${items[@]}"; do
        ln -sf "$SOURCE_DIR/$item" "$DEST_DIR/$item"
        if [ "$item" == "polybar" ]; then
            chmod +x $DEST_DIR/$item/*.sh
        fi
        if [ "$item" == "rofi" ]; then
            chmod +x $DEST_DIR/$item/bin/*.sh
        fi
    done


    echo "✅ Symlinks for i3 configuration created."
}

# Function to create symlinks for utility scripts
function setup_util_scripts() {
    echo "🔗 Creating symlinks for utility scripts..."
    mkdir -p $HOME/.local/bin
    ln -sf $DOT_UBUNTU/scripts/* $HOME/.local/bin/

    echo "🔗 Copy rofi-bluetooth script to /usr/local/bin"
    sudo cp $DOT_UBUNTU/rofi-bluetooth /usr/local/bin/
    sudo chmod +x /usr/local/bin/rofi-bluetooth

    echo "🔗 Setting up permissions for utility scripts..."
    chmod +x $HOME/.local/bin/*
    echo "✅ Symlinks for utility scripts created."
}

main() {
    # Main script execution
    echo "🚀 Starting symlink setup..."

    setup_zsh_symlink
    setup_git_symlink
    setup_i3_symlink
    setup_util_scripts

    echo "✅ Symlink setup completed successfully."
}
