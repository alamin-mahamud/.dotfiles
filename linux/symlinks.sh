#!/bin/bash

DOT=$HOME/Work/.dotfiles
DOT_LINUX=$DOT/linux

# Function to create symlinks for Zsh configuration
setup_zsh_symlink() {
    echo "🔗 Creating symlink for .zshrc..."
    ln -sf "$DOT/zsh/.zshrc" "$HOME/.zshrc"
    echo "✅ Symlink for .zshrc created."
}

# Function to create symlinks for Git configuration
setup_git_symlink() {
    echo "🔗 Creating symlinks for Git configuration..."
    ln -sf "$DOT/git/.gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOT/git/.gitmessage" "$HOME/.gitmessage"
    echo "✅ Symlinks for Git configuration created."
}

# Function to create symlinks for .config dir
setup_config() {
    # Define the base directories
    SOURCE_DIR="$DOT_LINUX/.config"
    DEST_DIR="$HOME/.config"

    # Define common items
    common_items=(
        "alacritty"
        "kitty"
    )

    # Define items for i3
    i3_items=(
        "i3"
        "picom.conf"
        "dunst"
        "rofi"
        "polybar"
    )

    # Define items for hyprland
    hyprland_items=(
        "hypr"
        "waybar"
        "swaylock"
        "wofi"
    )

    echo "${CAT} 🔗 Creating symlinks for .config dir..."
    mkdir -p "$DEST_DIR"

    # Create symlinks for common items
    for item in "${common_items[@]}"; do
        ln -sf "$SOURCE_DIR/$item" "$DEST_DIR/$item"
    done
    echo "${GREEN} ✅ Symlinks for common configuration created."

    # Check the user's choice and create symlinks accordingly
    if [ "$1" == "i3" ]; then
        for item in "${i3_items[@]}"; do
            ln -sf "$SOURCE_DIR/$item" "$DEST_DIR/$item"
        done
        echo "${GREEN} ✅ Symlinks for i3 configuration created."

    elif [ "$1" == "hyprland" ]; then
        for item in "${hyprland_items[@]}"; do
            ln -sf "$SOURCE_DIR/$item" "$DEST_DIR/$item"
        done
        echo "${GREEN} ✅ Symlinks for hyprland configuration created."

    else
        echo "${RED} ❌ Invalid window manager choice. No symlinks created."
    fi
}

setup_local(){
    echo "🔗 Creating symlinks for .local dir..."
    mkdir -p "$HOME/.local"
    ln -sf "$DOT_LINUX/.local/bin/" "$HOME/.local/"
    ln -sf "$DOT_LINUX/.local/share/" "$HOME/.local/"
}


# Function to create and configure .xinitrc for i3
setup_xinitrc() {
    echo "🔧 Creating and configuring .xinitrc for i3..."
    ln -sf "$DOT_LINUX/.config/.xinitrc" "$HOME/.xinitrc"
    chmod +x "$HOME/.xinitrc"
    echo "✅ .xinitrc configured successfully."
}

main() {
    # Main script execution
    echo "🚀 Starting symlink setup..."

    setup_zsh_symlink
    setup_git_symlink
    setup_config
    setup_local
    setup_xinitrc

    echo "✅ Symlink setup completed successfully."
}

# Execute the main function
# main
