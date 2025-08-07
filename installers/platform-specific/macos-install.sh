#!/bin/bash

# macOS Installation Script
# This script now delegates to the enhanced installation script

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the enhanced installation script
if [[ -f "$SCRIPT_DIR/install-enhanced.sh" ]]; then
    exec "$SCRIPT_DIR/install-enhanced.sh" "$@"
else
    echo "Error: Enhanced installation script not found!"
    echo "Please ensure install-enhanced.sh exists in the same directory."
    exit 1
fi

# Legacy configuration (kept for reference)
DOT=$HOME/Work/.dotfiles
OS=macos

# Function to check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "🍺 Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "🍺 Homebrew is already installed."
    fi
}

# Function to install packages using Homebrew
install_packages() {
    echo "📦 Installing packages..."
    brew install zsh zsh-autosuggestions zsh-syntax-highlighting
    echo "Install the zsh-autosuggestions and zsh-syntax-highlighting plugins manually."
    echo "https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df"
}

# Function to set up Zsh as the default shell
setup_zsh() {
    echo "🔧 Setting up Zsh as the default shell..."
    chsh -s /bin/zsh
}

# Function to create symlinks for configuration files
setup_zsh_symlink() {
    echo "🔗 Creating symlinks for Zsh configuration..."
    ln -sf $DOT/.zshrc ~/.zshrc
    # Add other symlinks you need here
}

# Function to set up Python and relevant tools
function setup_python() {
    echo "🐍 Install python and relevant tools"
    source $DOT/$OS/python.sh
}

# Main script execution
echo "🚀 Starting setup for macOS..."

check_homebrew
install_packages
setup_zsh
setup_zsh_symlink
setup_python

echo "✅ Setup completed successfully."
