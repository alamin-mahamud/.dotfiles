#!/bin/bash

# Custom Installation Script
# Allows users to select specific components to install

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$DOTFILES_ROOT/bootstrap.sh" 2>/dev/null || true

# Available components
declare -A COMPONENTS=(
    ["zsh"]="Zsh shell with Oh My Zsh"
    ["tmux"]="Terminal multiplexer"
    ["neovim"]="Modern Vim editor"
    ["git"]="Git version control"
    ["docker"]="Container platform"
    ["nodejs"]="Node.js JavaScript runtime"
    ["python"]="Python development environment"
    ["rust"]="Rust programming language"
    ["golang"]="Go programming language"
    ["fonts"]="Nerd Fonts collection"
    ["fzf"]="Fuzzy finder"
    ["ripgrep"]="Fast search tool"
    ["bat"]="Cat with syntax highlighting"
    ["starship"]="Cross-shell prompt"
    ["vscode"]="Visual Studio Code"
)

# Component installation functions
install_component_zsh() {
    print_status "Installing Zsh with Oh My Zsh..."
    
    case "$DOTFILES_OS" in
        linux)
            case "$DISTRO_FAMILY" in
                debian)
                    sudo apt install -y zsh
                    ;;
                arch)
                    sudo pacman -S --noconfirm zsh
                    ;;
            esac
            ;;
        macos)
            brew install zsh
            ;;
    esac
    
    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Install plugins
    local custom_plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    [[ ! -d "$custom_plugins/zsh-autosuggestions" ]] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
    [[ ! -d "$custom_plugins/zsh-syntax-highlighting" ]] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_plugins/zsh-syntax-highlighting"
    
    print_success "Zsh installed"
}

install_component_tmux() {
    print_status "Installing tmux..."
    
    case "$DOTFILES_OS" in
        linux)
            case "$DISTRO_FAMILY" in
                debian)
                    sudo apt install -y tmux
                    ;;
                arch)
                    sudo pacman -S --noconfirm tmux
                    ;;
            esac
            ;;
        macos)
            brew install tmux
            ;;
    esac
    
    # Install TPM
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
    
    # Link configuration
    [[ -f "$DOTFILES_ROOT/.tmux.conf" ]] && ln -sf "$DOTFILES_ROOT/.tmux.conf" "$HOME/.tmux.conf"
    
    print_success "tmux installed"
}

install_component_neovim() {
    print_status "Installing Neovim..."
    
    case "$DOTFILES_OS" in
        linux)
            case "$DISTRO_FAMILY" in
                debian)
                    # Install from AppImage for latest version
                    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                    chmod u+x nvim.appimage
                    sudo mv nvim.appimage /usr/local/bin/nvim
                    ;;
                arch)
                    sudo pacman -S --noconfirm neovim
                    ;;
            esac
            ;;
        macos)
            brew install neovim
            ;;
    esac
    
    # Install providers
    pip3 install --user pynvim
    npm install -g neovim
    
    print_success "Neovim installed"
}

install_component_git() {
    print_status "Installing Git..."
    
    case "$DOTFILES_OS" in
        linux)
            case "$DISTRO_FAMILY" in
                debian)
                    sudo apt install -y git git-lfs
                    ;;
                arch)
                    sudo pacman -S --noconfirm git git-lfs
                    ;;
            esac
            ;;
        macos)
            brew install git git-lfs
            ;;
    esac
    
    # Link configuration
    [[ -f "$DOTFILES_ROOT/git/.gitconfig" ]] && ln -sf "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
    
    print_success "Git installed"
}

install_component_docker() {
    print_status "Installing Docker..."
    
    case "$DOTFILES_OS" in
        linux)
            # Use the docker installation from dev-tools script
            source "$SCRIPT_DIR/install-dev-tools.sh"
            install_docker
            ;;
        macos)
            brew install --cask docker
            ;;
    esac
    
    print_success "Docker installed"
}

install_component_nodejs() {
    print_status "Installing Node.js..."
    
    case "$DOTFILES_OS" in
        linux)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        macos)
            brew install node
            ;;
    esac
    
    npm install -g yarn pnpm
    
    print_success "Node.js installed"
}

install_component_python() {
    print_status "Installing Python environment..."
    
    # Install Python
    case "$DOTFILES_OS" in
        linux)
            sudo apt install -y python3 python3-pip python3-venv python3-dev
            ;;
        macos)
            brew install python@3.11
            ;;
    esac
    
    # Install pyenv
    if ! command -v pyenv &> /dev/null; then
        curl https://pyenv.run | bash
    fi
    
    # Install pipx
    pip3 install --user pipx
    pipx ensurepath
    
    print_success "Python environment installed"
}

install_component_rust() {
    print_status "Installing Rust..."
    
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    print_success "Rust installed"
}

install_component_golang() {
    print_status "Installing Go..."
    
    case "$DOTFILES_OS" in
        linux)
            GO_VERSION="1.21.5"
            wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
            rm "go${GO_VERSION}.linux-amd64.tar.gz"
            ;;
        macos)
            brew install go
            ;;
    esac
    
    print_success "Go installed"
}

install_component_fonts() {
    print_status "Installing fonts..."
    
    case "$DOTFILES_OS" in
        linux)
            source "$DOTFILES_ROOT/linux/install-enhanced.sh"
            install_fonts
            ;;
        macos)
            brew tap homebrew/cask-fonts
            brew install --cask font-fira-code-nerd-font
            brew install --cask font-jetbrains-mono-nerd-font
            brew install --cask font-hack-nerd-font
            ;;
    esac
    
    print_success "Fonts installed"
}

install_component_fzf() {
    print_status "Installing FZF..."
    
    case "$DOTFILES_OS" in
        linux)
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
            "$HOME/.fzf/install" --all --no-bash --no-fish
            ;;
        macos)
            brew install fzf
            $(brew --prefix)/opt/fzf/install --all --no-bash --no-fish
            ;;
    esac
    
    print_success "FZF installed"
}

install_component_ripgrep() {
    print_status "Installing ripgrep..."
    
    case "$DOTFILES_OS" in
        linux)
            case "$DISTRO_FAMILY" in
                debian)
                    sudo apt install -y ripgrep
                    ;;
                arch)
                    sudo pacman -S --noconfirm ripgrep
                    ;;
            esac
            ;;
        macos)
            brew install ripgrep
            ;;
    esac
    
    print_success "ripgrep installed"
}

install_component_bat() {
    print_status "Installing bat..."
    
    case "$DOTFILES_OS" in
        linux)
            case "$DISTRO_FAMILY" in
                debian)
                    sudo apt install -y bat
                    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
                    ;;
                arch)
                    sudo pacman -S --noconfirm bat
                    ;;
            esac
            ;;
        macos)
            brew install bat
            ;;
    esac
    
    print_success "bat installed"
}

install_component_starship() {
    print_status "Installing Starship prompt..."
    
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    print_success "Starship installed"
}

install_component_vscode() {
    print_status "Installing Visual Studio Code..."
    
    case "$DOTFILES_OS" in
        linux)
            # Add Microsoft GPG key
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            
            sudo apt update
            sudo apt install -y code
            ;;
        macos)
            brew install --cask visual-studio-code
            ;;
    esac
    
    print_success "VS Code installed"
}

# Show component selection menu
show_component_menu() {
    local selected_components=()
    local sorted_keys=($(printf '%s\n' "${!COMPONENTS[@]}" | sort))
    
    echo
    echo -e "${CYAN}Select components to install:${NC}"
    echo -e "${YELLOW}(Use space to select, Enter to confirm)${NC}"
    echo
    
    # Simple selection (without dialog)
    local i=1
    for key in "${sorted_keys[@]}"; do
        printf "  %2d) %-15s - %s\n" "$i" "$key" "${COMPONENTS[$key]}"
        ((i++))
    done
    
    echo
    echo "  a) Select all"
    echo "  n) Select none"
    echo "  q) Quit"
    echo
    
    while true; do
        read -rp "Enter numbers separated by spaces (or a/n/q): " selection
        
        case "$selection" in
            q|Q)
                print_status "Installation cancelled"
                exit 0
                ;;
            a|A)
                selected_components=("${sorted_keys[@]}")
                break
                ;;
            n|N)
                selected_components=()
                break
                ;;
            *)
                # Parse number selections
                selected_components=()
                for num in $selection; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && (( num > 0 )) && (( num <= ${#sorted_keys[@]} )); then
                        selected_components+=("${sorted_keys[$((num-1))]}")
                    fi
                done
                
                if [[ ${#selected_components[@]} -gt 0 ]]; then
                    break
                else
                    print_warning "Invalid selection. Please try again."
                fi
                ;;
        esac
    done
    
    # Confirm selection
    if [[ ${#selected_components[@]} -gt 0 ]]; then
        echo
        print_status "Selected components:"
        for component in "${selected_components[@]}"; do
            echo "  - $component: ${COMPONENTS[$component]}"
        done
        echo
        read -rp "Proceed with installation? (Y/n) " confirm
        if [[ "$confirm" =~ ^([nN][oO]|[nN])$ ]]; then
            print_status "Installation cancelled"
            exit 0
        fi
    else
        print_warning "No components selected"
        exit 0
    fi
    
    # Install selected components
    for component in "${selected_components[@]}"; do
        if declare -f "install_component_$component" > /dev/null; then
            "install_component_$component"
        else
            print_warning "Installation function for $component not found"
        fi
    done
}

# Main execution
main() {
    print_status "Custom Component Installation"
    
    # Detect OS if not already set
    if [[ -z "${DOTFILES_OS:-}" ]]; then
        case "$OSTYPE" in
            linux-gnu*)
                DOTFILES_OS="linux"
                source /etc/os-release
                DISTRO_FAMILY=""
                case "$ID" in
                    ubuntu|debian) DISTRO_FAMILY="debian" ;;
                    arch|manjaro) DISTRO_FAMILY="arch" ;;
                esac
                ;;
            darwin*)
                DOTFILES_OS="macos"
                ;;
        esac
    fi
    
    # Show component menu
    show_component_menu
    
    print_success "Custom installation completed!"
    echo
    print_status "Remember to:"
    echo "  - Restart your shell for changes to take effect"
    echo "  - Configure installed applications as needed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi