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
    echo "🔗 Creating symlinks for i3 configuration..."
    mkdir -p $HOME/.config
    ln -sf $DOT_UBUNTU/.config/i3 $HOME/.config/i3
    ln -sf $DOT_UBUNTU/.config/i3lock $HOME/.config/i3lock
    ln -sf $DOT_UBUNTU/.config/picom.conf $HOME/.config/picom.conf
    ln -sf $DOT_UBUNTU/.config/dunst $HOME/.config/dunst
    ln -sf $DOT_UBUNTU/.config/rofi $HOME/.config/rofi
    ln -sf $DOT_UBUNTU/.config/alacritty $HOME/.config/alacritty
    ln -sf $DOT_UBUNTU/.config/kitty $HOME/.config/kitty

    echo "🔗 Configuring alacritty color theme ..."
    git clone https://github.com/catppuccin/alacritty.git ~/.config/alacritty/catppuccin

    echo "✅ Symlinks for i3 configuration created."
}

# Function to create symlinks for utility scripts
function setup_util_scripts() {
    echo "🔗 Creating symlinks for utility scripts..."
    mkdir -p $HOME/.local/bin
    ln -sf $DOT_UBUNTU/scripts/* $HOME/.local/bin/
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
