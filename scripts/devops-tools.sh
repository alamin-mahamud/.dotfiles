#!/bin/bash

# DevOps Tools Standalone Installer
# Installs Docker, Kubernetes, Terraform, AWS CLI, Python, Node.js, and other DevOps essentials
# Embedded configurations - no external dependencies
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/devops-tools.sh | bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
LOG_FILE="/tmp/devops-tools-$(date +%Y%m%d_%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║            DevOps Tools Installer                ║"
    echo "║   Docker • K8s • Terraform • AWS • Languages    ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

check_root() {
    [[ $EUID -eq 0 ]] && { print_error "Don't run as root!"; exit 1; }
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
    else
        print_error "Unsupported OS"
        exit 1
    fi
    print_success "Detected $OS"
}

install_docker() {
    print_status "Installing Docker..."
    
    case "$OS" in
        ubuntu|debian)
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Install dependencies
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            
            # Add Docker GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Add repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        fedora|centos|rhel)
            sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm docker docker-compose
            ;;
        macos)
            brew install --cask docker
            ;;
    esac
    
    # Add user to docker group (Linux only)
    if [[ "$OS" != "macos" ]]; then
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
    fi
    
    print_success "Docker installed"
}

install_kubernetes_tools() {
    print_status "Installing Kubernetes tools..."
    
    case "$OS" in
        ubuntu|debian)
            # kubectl
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            
            # helm
            curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
            sudo apt-get update
            sudo apt-get install -y helm
            ;;
        fedora|centos|rhel)
            # kubectl
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            
            # helm
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm kubectl helm
            ;;
        macos)
            brew install kubectl helm
            ;;
    esac
    
    print_success "Kubernetes tools installed"
}

install_terraform() {
    print_status "Installing Terraform..."
    
    case "$OS" in
        ubuntu|debian)
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install -y terraform
            ;;
        fedora|centos|rhel)
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
            sudo dnf install -y terraform
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm terraform
            ;;
        macos)
            brew install terraform
            ;;
    esac
    
    print_success "Terraform installed"
}

install_aws_cli() {
    print_status "Installing AWS CLI..."
    
    case "$OS" in
        ubuntu|debian|fedora|centos|rhel|arch|manjaro)
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip -q awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
            ;;
        macos)
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
            ;;
    esac
    
    print_success "AWS CLI installed"
}

install_python_tools() {
    print_status "Installing Python development tools..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y python3 python3-pip python3-venv python3-dev
            ;;
        fedora|centos|rhel)
            sudo dnf install -y python3 python3-pip python3-devel
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm python python-pip
            ;;
        macos)
            brew install python
            ;;
    esac
    
    # Install Python tools
    pip3 install --user --upgrade pip
    pip3 install --user pipenv poetry black flake8 mypy ansible ansible-lint
    
    print_success "Python tools installed"
}

install_nodejs() {
    print_status "Installing Node.js..."
    
    # Install via NodeSource repository for consistent versions
    case "$OS" in
        ubuntu|debian)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        fedora|centos|rhel)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo dnf install -y nodejs
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm nodejs npm
            ;;
        macos)
            brew install node
            ;;
    esac
    
    # Install global packages
    npm install -g yarn pnpm typescript @angular/cli @vue/cli create-react-app
    
    print_success "Node.js installed"
}

install_additional_tools() {
    print_status "Installing additional DevOps tools..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y jq yq htop tree curl wget git vim neovim
            ;;
        fedora|centos|rhel)
            sudo dnf install -y jq htop tree curl wget git vim neovim
            pip3 install --user yq
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm jq python-yq htop tree curl wget git vim neovim
            ;;
        macos)
            brew install jq yq htop tree curl wget git vim neovim
            ;;
    esac
    
    # Install GitHub CLI
    case "$OS" in
        ubuntu|debian)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update && sudo apt install -y gh
            ;;
        fedora|centos|rhel)
            sudo dnf install -y gh
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm github-cli
            ;;
        macos)
            brew install gh
            ;;
    esac
    
    print_success "Additional tools installed"
}

setup_git_config() {
    print_status "Setting up Git configuration..."
    
    # Check if git config already exists
    if ! git config --global user.name >/dev/null 2>&1; then
        cat > ~/.gitconfig << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = nvim
    autocrlf = input

[init]
    defaultBranch = main

[push]
    default = simple
    autoSetupRemote = true

[pull]
    rebase = true

[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    sync = !git pull && git push

[color]
    ui = auto
EOF
        
        print_warning "Update ~/.gitconfig with your name and email"
    fi
    
    print_success "Git configuration created"
}

main() {
    print_banner
    check_root
    detect_os
    
    print_status "Installing DevOps tools..."
    
    install_docker
    install_kubernetes_tools
    install_terraform
    install_aws_cli
    install_python_tools
    install_nodejs
    install_additional_tools
    setup_git_config
    
    echo
    print_success "DevOps tools installation complete!"
    echo -e "${YELLOW}Log: $LOG_FILE${NC}"
    echo
    echo "Installed tools:"
    echo "• Docker & Docker Compose"
    echo "• Kubernetes (kubectl, helm)"
    echo "• Terraform"
    echo "• AWS CLI v2"
    echo "• Python (pip, pipenv, poetry, ansible)"
    echo "• Node.js (npm, yarn, pnpm)"
    echo "• GitHub CLI"
    echo "• Additional utilities (jq, yq, htop, etc.)"
    echo
    echo "Next steps:"
    echo "1. Restart terminal or run: newgrp docker"
    echo "2. Configure AWS: aws configure"
    echo "3. Login to GitHub: gh auth login"
    echo "4. Update Git config with your details"
    echo "5. Reboot to ensure all changes take effect"
}

main "$@"