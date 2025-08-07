#!/bin/bash

# Standalone vim/neovim installer
# Simple, idempotent, atomic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_vim() {
    # Check if vim is already installed
    if command -v vim &> /dev/null; then
        echo "vim is already installed ($(vim --version | head -1))"
    else
        echo "Installing vim..."
        
        case "$OSTYPE" in
            linux-gnu*)
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y vim
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S --noconfirm vim
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y vim
                fi
                ;;
            darwin*)
                if command -v brew &> /dev/null; then
                    brew install vim
                fi
                ;;
        esac
        
        echo "vim installed successfully"
    fi
}

install_neovim() {
    # Check if neovim is already installed
    if command -v nvim &> /dev/null; then
        echo "neovim is already installed ($(nvim --version | head -1))"
        return 0
    fi
    
    echo "Installing neovim..."
    
    case "$OSTYPE" in
        linux-gnu*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y neovim
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm neovim
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y neovim
            else
                # Install from AppImage as fallback
                echo "Installing neovim from AppImage..."
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x nvim.appimage
                sudo mv nvim.appimage /usr/local/bin/nvim
            fi
            ;;
        darwin*)
            if command -v brew &> /dev/null; then
                brew install neovim
            else
                echo "Homebrew not found. Please install it first."
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac
    
    echo "neovim installed successfully"
}

configure_vim() {
    echo "Configuring vim..."
    
    # Create config directories
    mkdir -p "$HOME/.vim"
    
    # Link vimrc if it exists in dotfiles
    if [[ -f "$SCRIPT_DIR/vim/.vimrc" ]]; then
        ln -sf "$SCRIPT_DIR/vim/.vimrc" "$HOME/.vimrc"
        echo "Linked vim configuration"
    elif [[ -f "$SCRIPT_DIR/configs/.vimrc" ]]; then
        ln -sf "$SCRIPT_DIR/configs/.vimrc" "$HOME/.vimrc"
        echo "Linked vim configuration"
    else
        # Create minimal vimrc
        cat > "$HOME/.vimrc" << 'EOF'
" Minimal vim configuration
set number
set relativenumber
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent
set incsearch
set hlsearch
set ignorecase
set smartcase
syntax enable
filetype plugin indent on
EOF
        echo "Created minimal vim configuration"
    fi
}

configure_neovim() {
    echo "Configuring neovim..."
    
    # Create config directories
    mkdir -p "$HOME/.config/nvim"
    
    # Link or create neovim config
    if [[ -d "$SCRIPT_DIR/nvim" ]]; then
        ln -sf "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
        echo "Linked neovim configuration"
    elif [[ -f "$SCRIPT_DIR/configs/init.vim" ]]; then
        ln -sf "$SCRIPT_DIR/configs/init.vim" "$HOME/.config/nvim/init.vim"
        echo "Linked neovim configuration"
    else
        # Create minimal init.vim that sources vimrc
        cat > "$HOME/.config/nvim/init.vim" << 'EOF'
" Source vim configuration
if filereadable(expand("~/.vimrc"))
  source ~/.vimrc
endif

" Neovim specific settings
set termguicolors
EOF
        echo "Created minimal neovim configuration"
    fi
}

main() {
    # Ask what to install
    echo "Select editor to install:"
    echo "1) vim only"
    echo "2) neovim only"
    echo "3) both vim and neovim"
    read -p "Choice (1-3): " choice
    
    case "$choice" in
        1)
            install_vim
            configure_vim
            ;;
        2)
            install_neovim
            configure_neovim
            ;;
        3)
            install_vim
            configure_vim
            install_neovim
            configure_neovim
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
    
    echo "vim/neovim setup complete"
}

main "$@"