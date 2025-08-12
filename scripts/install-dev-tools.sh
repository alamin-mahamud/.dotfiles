#!/bin/bash

# Development Tools Standalone Installation Script
# DRY orchestrator for installing common development tools across Linux and macOS
# Provides comprehensive development environment setup for modern DevOps workflows
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-dev-tools.sh | bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/dev-tools-install-$(date +%Y%m%d_%H%M%S).log"
INTERACTIVE=${INTERACTIVE:-true}

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_status "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected macOS"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        print_success "Detected $PRETTY_NAME"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
}

# Prompt for optional installation
prompt_install() {
    local tool="$1"
    local description="$2"
    
    if [[ "$INTERACTIVE" == "false" ]]; then
        return 0
    fi
    
    print_status "Would you like to install $description? (Y/n)"
    read -r response
    if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        return 0
    else
        return 1
    fi
}

# Install Git (idempotent)
install_git() {
    print_status "Checking Git installation..."
    
    if command -v git &> /dev/null; then
        print_success "Git is already installed ($(git --version))"
        return 0
    fi
    
    print_status "Installing Git..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y git git-lfs
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y git git-lfs || sudo yum install -y git git-lfs
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm git git-lfs
            ;;
        alpine)
            sudo apk add --no-cache git git-lfs
            ;;
        opensuse*|sles)
            sudo zypper install -y git git-lfs
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                print_warning "Homebrew not found. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git git-lfs
            ;;
        *)
            print_error "Unsupported OS for Git installation: $OS"
            return 1
            ;;
    esac
    
    # Configure Git with reasonable defaults
    print_status "Configuring Git defaults..."
    git config --global init.defaultBranch main
    git config --global core.editor "${EDITOR:-vim}"
    git config --global pull.rebase false
    
    print_success "Git installed and configured"
}

# Install Docker (idempotent)
install_docker() {
    print_status "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed ($(docker --version))"
        return 0
    fi
    
    if ! prompt_install "docker" "Docker container platform"; then
        print_status "Skipping Docker installation"
        return 0
    fi
    
    print_status "Installing Docker..."
    case "$OS" in
        ubuntu|debian)
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Install prerequisites
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Add repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Add user to docker group
            sudo usermod -aG docker "$USER"
            print_warning "Log out and back in for docker group changes to take effect"
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y docker docker-compose || sudo yum install -y docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
        macos)
            brew install --cask docker
            print_status "Please start Docker Desktop from Applications"
            ;;
        *)
            print_error "Unsupported OS for Docker installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Docker installed"
}

# Install Node.js (idempotent)
install_nodejs() {
    print_status "Checking Node.js installation..."
    
    if command -v node &> /dev/null; then
        print_success "Node.js is already installed ($(node --version))"
        return 0
    fi
    
    if ! prompt_install "nodejs" "Node.js JavaScript runtime"; then
        print_status "Skipping Node.js installation"
        return 0
    fi
    
    print_status "Installing Node.js..."
    case "$OS" in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        fedora|centos|rhel|rocky|almalinux)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo dnf install -y nodejs || sudo yum install -y nodejs
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm nodejs npm
            ;;
        alpine)
            sudo apk add --no-cache nodejs npm
            ;;
        opensuse*|sles)
            sudo zypper install -y nodejs npm
            ;;
        macos)
            brew install node
            ;;
        *)
            print_error "Unsupported OS for Node.js installation: $OS"
            return 1
            ;;
    esac
    
    # Install global packages
    print_status "Installing global npm packages..."
    npm install -g yarn pnpm 2>/dev/null || true
    
    print_success "Node.js installed"
}

# Install Python environment (idempotent)
install_python() {
    print_status "Checking Python installation..."
    
    if command -v python3 &> /dev/null; then
        print_success "Python3 is already installed ($(python3 --version))"
    else
        if ! prompt_install "python" "Python development environment"; then
            print_status "Skipping Python installation"
            return 0
        fi
        
        print_status "Installing Python..."
        case "$OS" in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y \
                    python3 python3-pip python3-venv python3-dev \
                    build-essential libssl-dev libffi-dev
                ;;
            fedora|centos|rhel|rocky|almalinux)
                sudo dnf install -y python3 python3-pip python3-devel || \
                sudo yum install -y python3 python3-pip python3-devel
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm python python-pip
                ;;
            alpine)
                sudo apk add --no-cache python3 py3-pip python3-dev
                ;;
            opensuse*|sles)
                sudo zypper install -y python3 python3-pip python3-devel
                ;;
            macos)
                brew install python@3.11
                ;;
            *)
                print_error "Unsupported OS for Python installation: $OS"
                return 1
                ;;
        esac
    fi
    
    # Install pyenv (idempotent)
    if ! command -v pyenv &> /dev/null; then
        print_status "Installing pyenv..."
        
        # Install dependencies first
        case "$OS" in
            ubuntu|debian)
                sudo apt-get install -y \
                    build-essential libssl-dev zlib1g-dev \
                    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                    libffi-dev liblzma-dev
                ;;
        esac
        
        curl -s https://pyenv.run | bash 2>/dev/null || true
        
        # Add to shell config
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    
    # Install pipx (idempotent)
    if ! command -v pipx &> /dev/null; then
        print_status "Installing pipx..."
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
    fi
    
    # Install common Python tools
    print_status "Installing Python development tools..."
    pipx install black 2>/dev/null || true
    pipx install flake8 2>/dev/null || true
    pipx install mypy 2>/dev/null || true
    pipx install poetry 2>/dev/null || true
    pipx install pipenv 2>/dev/null || true
    
    print_success "Python environment configured"
}

# Install Rust (idempotent)
install_rust() {
    print_status "Checking Rust installation..."
    
    if command -v rustc &> /dev/null; then
        print_success "Rust is already installed ($(rustc --version))"
        return 0
    fi
    
    if ! prompt_install "rust" "Rust programming language"; then
        print_status "Skipping Rust installation"
        return 0
    fi
    
    print_status "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    # Install common Rust tools
    print_status "Installing Rust tools..."
    cargo install ripgrep fd-find bat exa tokei 2>/dev/null || true
    
    print_success "Rust installed"
}

# Install Go (idempotent)
install_golang() {
    print_status "Checking Go installation..."
    
    if command -v go &> /dev/null; then
        print_success "Go is already installed ($(go version))"
        return 0
    fi
    
    if ! prompt_install "golang" "Go programming language"; then
        print_status "Skipping Go installation"
        return 0
    fi
    
    print_status "Installing Go..."
    case "$OS" in
        ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|alpine|opensuse*|sles)
            GO_VERSION="1.21.5"
            ARCH=$(uname -m)
            case "$ARCH" in
                x86_64) ARCH="amd64" ;;
                aarch64) ARCH="arm64" ;;
            esac
            
            wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz"
            rm "go${GO_VERSION}.linux-${ARCH}.tar.gz"
            
            # Add to PATH
            export PATH="/usr/local/go/bin:$PATH"
            ;;
        macos)
            brew install go
            ;;
        *)
            print_error "Unsupported OS for Go installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Go installed"
}

# Install Neovim (idempotent)
install_neovim() {
    print_status "Checking Neovim installation..."
    
    if command -v nvim &> /dev/null; then
        print_success "Neovim is already installed ($(nvim --version | head -n1))"
        return 0
    fi
    
    if ! prompt_install "neovim" "Neovim modern editor"; then
        print_status "Skipping Neovim installation"
        return 0
    fi
    
    print_status "Installing Neovim..."
    case "$OS" in
        ubuntu|debian)
            # Install from AppImage for latest version
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage
            sudo mv nvim.appimage /usr/local/bin/nvim
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y neovim || sudo yum install -y neovim
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm neovim
            ;;
        alpine)
            sudo apk add --no-cache neovim
            ;;
        opensuse*|sles)
            sudo zypper install -y neovim
            ;;
        macos)
            brew install neovim
            ;;
        *)
            print_error "Unsupported OS for Neovim installation: $OS"
            return 1
            ;;
    esac
    
    # Install providers
    if command -v pip3 &> /dev/null; then
        pip3 install --user pynvim 2>/dev/null || true
    fi
    if command -v npm &> /dev/null; then
        npm install -g neovim 2>/dev/null || true
    fi
    
    print_success "Neovim installed"
}

# Install VS Code (idempotent)
install_vscode() {
    print_status "Checking VS Code installation..."
    
    if command -v code &> /dev/null; then
        print_success "VS Code is already installed"
        return 0
    fi
    
    if ! prompt_install "vscode" "Visual Studio Code"; then
        print_status "Skipping VS Code installation"
        return 0
    fi
    
    print_status "Installing VS Code..."
    case "$OS" in
        ubuntu|debian)
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt-get update
            sudo apt-get install -y code
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf install -y code || sudo yum install -y code
            ;;
        arch|manjaro)
            yay -S --noconfirm visual-studio-code-bin 2>/dev/null || \
            print_warning "Please install VS Code from AUR manually"
            ;;
        macos)
            brew install --cask visual-studio-code
            ;;
        *)
            print_error "Unsupported OS for VS Code installation: $OS"
            return 1
            ;;
    esac
    
    print_success "VS Code installed"
}

# Install database tools (idempotent)
install_database_tools() {
    print_status "Checking database tools..."
    
    if ! prompt_install "database-tools" "PostgreSQL, MySQL, and Redis clients"; then
        print_status "Skipping database tools installation"
        return 0
    fi
    
    print_status "Installing database tools..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y postgresql-client mysql-client redis-tools
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y postgresql mysql redis || \
            sudo yum install -y postgresql mysql redis
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm postgresql-libs mysql-clients redis
            ;;
        alpine)
            sudo apk add --no-cache postgresql-client mysql-client redis
            ;;
        opensuse*|sles)
            sudo zypper install -y postgresql mysql redis
            ;;
        macos)
            brew install postgresql mysql redis
            ;;
        *)
            print_warning "Skipping database tools for unsupported OS: $OS"
            ;;
    esac
    
    print_success "Database tools installed"
}

# Install cloud CLI tools (idempotent)
install_cloud_tools() {
    print_status "Checking cloud CLI tools..."
    
    if ! prompt_install "cloud-tools" "AWS CLI, kubectl, and Terraform"; then
        print_status "Skipping cloud tools installation"
        return 0
    fi
    
    print_status "Installing cloud CLI tools..."
    
    # AWS CLI
    if ! command -v aws &> /dev/null; then
        print_status "Installing AWS CLI..."
        case "$OS" in
            ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|alpine|opensuse*|sles)
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                sudo ./aws/install
                rm -rf awscliv2.zip aws/
                ;;
            macos)
                brew install awscli
                ;;
        esac
    fi
    
    # kubectl
    if ! command -v kubectl &> /dev/null; then
        print_status "Installing kubectl..."
        case "$OS" in
            ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|alpine|opensuse*|sles)
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
                ;;
            macos)
                brew install kubectl
                ;;
        esac
    fi
    
    # Terraform
    if ! command -v terraform &> /dev/null; then
        print_status "Installing Terraform..."
        case "$OS" in
            ubuntu|debian)
                wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                sudo apt-get update && sudo apt-get install -y terraform
                ;;
            fedora|centos|rhel|rocky|almalinux)
                sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || \
                sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
                sudo dnf install -y terraform || sudo yum install -y terraform
                ;;
            macos)
                brew tap hashicorp/tap
                brew install hashicorp/tap/terraform
                ;;
            *)
                print_warning "Please install Terraform manually for $OS"
                ;;
        esac
    fi
    
    print_success "Cloud tools installed"
}

# Show installation menu
show_menu() {
    echo
    echo "========================================"
    echo "Development Tools Installation Menu"
    echo "========================================"
    echo
    echo "Select tools to install:"
    echo "  1) All tools (recommended)"
    echo "  2) Core tools (Git, Docker, Node.js, Python)"
    echo "  3) Programming languages (Rust, Go)"
    echo "  4) Editors (Neovim, VS Code)"
    echo "  5) Database tools"
    echo "  6) Cloud CLI tools"
    echo "  7) Custom selection"
    echo "  q) Quit"
    echo
    read -rp "Enter your choice: " choice
    
    case "$choice" in
        1)
            install_all_tools
            ;;
        2)
            install_git
            install_docker
            install_nodejs
            install_python
            ;;
        3)
            install_rust
            install_golang
            ;;
        4)
            install_neovim
            install_vscode
            ;;
        5)
            install_database_tools
            ;;
        6)
            install_cloud_tools
            ;;
        7)
            custom_installation
            ;;
        q|Q)
            print_status "Installation cancelled"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            show_menu
            ;;
    esac
}

# Install all tools
install_all_tools() {
    INTERACTIVE=false
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
}

# Custom installation
custom_installation() {
    echo
    echo "Select tools to install (space-separated numbers):"
    echo "  1) Git"
    echo "  2) Docker"
    echo "  3) Node.js"
    echo "  4) Python"
    echo "  5) Rust"
    echo "  6) Go"
    echo "  7) Neovim"
    echo "  8) VS Code"
    echo "  9) Database tools"
    echo "  10) Cloud tools"
    echo
    read -rp "Enter numbers: " selections
    
    INTERACTIVE=false
    for num in $selections; do
        case "$num" in
            1) install_git ;;
            2) install_docker ;;
            3) install_nodejs ;;
            4) install_python ;;
            5) install_rust ;;
            6) install_golang ;;
            7) install_neovim ;;
            8) install_vscode ;;
            9) install_database_tools ;;
            10) install_cloud_tools ;;
            *) print_warning "Invalid selection: $num" ;;
        esac
    done
}

# Show summary
show_summary() {
    echo
    echo "========================================"
    echo "Development Tools Installation Summary"
    echo "========================================"
    echo
    print_status "📋 Installation complete!"
    echo
    print_status "📁 Log file: $LOG_FILE"
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Restart your shell to load new PATH entries"
    echo "  2. Configure tools as needed for your projects"
    echo "  3. For Docker: Log out and back in for group changes"
    echo
    print_status "🚀 Your development environment is ready!"
}

# Main installation
main() {
    clear
    echo "========================================"
    echo "Development Tools Installer"
    echo "========================================"
    echo
    
    # Pre-flight checks
    check_root
    detect_os
    
    # Show menu or install all
    if [[ "${1:-}" == "--all" ]]; then
        install_all_tools
    else
        show_menu
    fi
    
    # Show summary
    show_summary
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi