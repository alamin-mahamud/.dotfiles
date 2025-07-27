#!/bin/bash

# Development Tools Installation Script
# Installs common development tools across Linux and macOS

set -euo pipefail

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap.sh" 2>/dev/null || true

# Development tools to install
install_git() {
    print_status "Installing and configuring Git..."
    
    case "$DOTFILES_OS" in
        linux)
            sudo apt-get install -y git git-lfs
            ;;
        macos)
            brew install git git-lfs
            ;;
    esac
    
    # Configure Git
    if [[ -f "$DOTFILES_ROOT/git/.gitconfig" ]]; then
        ln -sf "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
        print_success "Git configuration linked"
    fi
}

install_docker() {
    print_status "Installing Docker..."
    
    case "$DOTFILES_OS" in
        linux)
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
            
            # Install prerequisites
            sudo apt-get update
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Add repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Add user to docker group
            sudo usermod -aG docker "$USER"
            ;;
        macos)
            brew install --cask docker
            ;;
    esac
    
    print_success "Docker installed"
}

install_nodejs() {
    print_status "Installing Node.js..."
    
    case "$DOTFILES_OS" in
        linux)
            # Install via NodeSource
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            
            # Install yarn and pnpm
            sudo npm install -g yarn pnpm
            ;;
        macos)
            brew install node
            npm install -g yarn pnpm
            ;;
    esac
    
    print_success "Node.js installed"
}

install_python() {
    print_status "Installing Python development environment..."
    
    case "$DOTFILES_OS" in
        linux)
            # Install pyenv dependencies
            sudo apt-get update
            sudo apt-get install -y \
                build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev
            
            # Install pyenv
            curl https://pyenv.run | bash
            
            # Install Python tools
            sudo apt-get install -y python3 python3-pip python3-venv
            ;;
        macos)
            brew install pyenv python@3.11
            ;;
    esac
    
    # Install global Python packages
    pip3 install --user pipx
    pipx ensurepath
    
    # Install common Python tools
    pipx install black
    pipx install flake8
    pipx install mypy
    pipx install poetry
    pipx install pipenv
    
    print_success "Python development environment installed"
}

install_rust() {
    print_status "Installing Rust..."
    
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        print_status "Rust is already installed"
    fi
    
    # Install common Rust tools
    cargo install ripgrep fd-find bat exa tokei
    
    print_success "Rust and tools installed"
}

install_golang() {
    print_status "Installing Go..."
    
    case "$DOTFILES_OS" in
        linux)
            # Download and install Go
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

install_neovim() {
    print_status "Installing Neovim..."
    
    case "$DOTFILES_OS" in
        linux)
            # Install from AppImage for latest version
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage
            sudo mv nvim.appimage /usr/local/bin/nvim
            ;;
        macos)
            brew install neovim
            ;;
    esac
    
    # Install Neovim providers
    pip3 install --user pynvim
    npm install -g neovim
    
    print_success "Neovim installed"
}

install_vscode() {
    print_status "Would you like to install Visual Studio Code? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        case "$DOTFILES_OS" in
            linux)
                # Add Microsoft GPG key
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
                sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
                
                sudo apt-get update
                sudo apt-get install -y code
                ;;
            macos)
                brew install --cask visual-studio-code
                ;;
        esac
        
        print_success "Visual Studio Code installed"
    fi
}

install_database_tools() {
    print_status "Installing database tools..."
    
    case "$DOTFILES_OS" in
        linux)
            # PostgreSQL client
            sudo apt-get install -y postgresql-client
            
            # MySQL client
            sudo apt-get install -y mysql-client
            
            # Redis tools
            sudo apt-get install -y redis-tools
            ;;
        macos)
            brew install postgresql mysql redis
            ;;
    esac
    
    print_success "Database tools installed"
}

install_cloud_tools() {
    print_status "Installing cloud CLI tools..."
    
    # AWS CLI
    case "$DOTFILES_OS" in
        linux)
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf awscliv2.zip aws/
            ;;
        macos)
            brew install awscli
            ;;
    esac
    
    # kubectl
    case "$DOTFILES_OS" in
        linux)
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        macos)
            brew install kubectl
            ;;
    esac
    
    # Terraform
    case "$DOTFILES_OS" in
        linux)
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt-get update && sudo apt-get install -y terraform
            ;;
        macos)
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
            ;;
    esac
    
    print_success "Cloud tools installed"
}

# Main installation menu
show_dev_tools_menu() {
    echo
    echo "Select development tools to install:"
    echo "  1) All tools (recommended)"
    echo "  2) Git"
    echo "  3) Docker"
    echo "  4) Node.js"
    echo "  5) Python development environment"
    echo "  6) Rust"
    echo "  7) Go"
    echo "  8) Neovim"
    echo "  9) Visual Studio Code"
    echo "  10) Database tools"
    echo "  11) Cloud CLI tools"
    echo "  q) Back to main menu"
    echo
    read -rp "Enter your choice: " choice
    
    case "$choice" in
        1)
            install_git
            install_docker
            install_nodejs
            install_python
            install_rust
            install_golang
            install_neovim
            install_vscode
            install_database_tools
            install_cloud_tools
            ;;
        2) install_git ;;
        3) install_docker ;;
        4) install_nodejs ;;
        5) install_python ;;
        6) install_rust ;;
        7) install_golang ;;
        8) install_neovim ;;
        9) install_vscode ;;
        10) install_database_tools ;;
        11) install_cloud_tools ;;
        q|Q) return ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Main execution
main() {
    print_status "Development Tools Installation"
    show_dev_tools_menu
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi