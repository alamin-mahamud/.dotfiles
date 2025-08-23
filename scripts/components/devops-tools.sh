#!/usr/bin/env bash

# DevOps Tools Installation Script for Ubuntu 24.04 and macOS
# Installs Docker, Terraform/OpenTofu, Kubernetes tools, and cloud CLIs

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Parse command line arguments
INSTALL_ALL=true
CONTAINERS_ONLY=false
IAC_ONLY=false
CLOUD_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --containers-only)
            INSTALL_ALL=false
            CONTAINERS_ONLY=true
            shift
            ;;
        --iac-only)
            INSTALL_ALL=false
            IAC_ONLY=true
            shift
            ;;
        --cloud-only)
            INSTALL_ALL=false
            CLOUD_ONLY=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

main() {
    print_header "DevOps Tools Installation"
    
    local os
    os=$(detect_os)
    
    info "Installing DevOps tools for $os"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    if [[ "$INSTALL_ALL" == "true" || "$CONTAINERS_ONLY" == "true" ]]; then
        install_container_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$IAC_ONLY" == "true" ]]; then
        install_iac_tools "$os"
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$CLOUD_ONLY" == "true" ]]; then
        install_cloud_tools "$os"
    fi
    
    setup_environment
    
    success "DevOps tools installation completed!"
    info "Please restart your shell or run: source ~/.zshrc"
}

install_container_tools() {
    local os="$1"
    
    print_header "Installing Container & Orchestration Tools"
    
    # Docker
    info "Installing Docker..."
    if command -v docker >/dev/null 2>&1; then
        warning "Docker already installed, upgrading..."
    fi
    
    case "$os" in
        linux)
            install_docker_linux
            ;;
        macos)
            install_docker_macos
            ;;
        *)
            error "Unsupported OS for Docker installation: $os"
            ;;
    esac
    
    # Docker Compose (standalone)
    install_docker_compose "$os"
    
    # Kubernetes tools
    install_kubectl "$os"
    install_helm "$os"
}

install_docker_linux() {
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker repository
    install_packages_multi "ca-certificates curl gnupg lsb-release"
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    # Add user to docker group
    sudo usermod -aG docker "$USER"
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    success "Docker installed successfully"
}

install_docker_macos() {
    if [[ -d "/Applications/Docker.app" ]]; then
        success "Docker Desktop already installed at /Applications/Docker.app"
        return 0
    fi
    
    if command -v brew >/dev/null 2>&1; then
        brew install --cask docker
        success "Docker Desktop installed via Homebrew"
    else
        warning "Homebrew not found. Please install Docker Desktop manually from https://docker.com"
    fi
}

install_docker_compose() {
    local os="$1"
    local compose_version
    
    info "Installing Docker Compose..."
    
    # Check if docker-compose is already installed
    if command -v docker-compose >/dev/null 2>&1; then
        local current_version
        current_version=$(docker-compose --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        info "Docker Compose $current_version already installed"
        
        # Get latest version to check for updates
        compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        
        if [[ "$current_version" == "$compose_version" ]]; then
            success "Docker Compose is up to date ($current_version)"
            return 0
        else
            info "Updating Docker Compose from $current_version to $compose_version"
        fi
    else
        # Get latest version from GitHub API
        compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    fi
    
    case "$os" in
        linux)
            local arch
            arch=$(detect_arch)
            curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}" -o /tmp/docker-compose
            sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        macos)
            # Docker Desktop includes compose
            info "Docker Compose included with Docker Desktop"
            return 0
            ;;
    esac
    
    success "Docker Compose ${compose_version} installed"
}

install_kubectl() {
    local os="$1"
    
    info "Installing kubectl..."
    
    # Check if kubectl is already installed
    if command -v kubectl >/dev/null 2>&1; then
        local current_version
        current_version=$(kubectl version --client -o json 2>/dev/null | grep '"gitVersion"' | cut -d'"' -f4 || echo "unknown")
        
        info "kubectl $current_version already installed"
        
        # For macOS with brew, just upgrade if needed
        if [[ "$os" == "macos" ]] && command -v brew >/dev/null 2>&1; then
            brew upgrade kubernetes-cli 2>/dev/null || true
            success "kubectl updated via brew"
            return 0
        fi
        
        success "kubectl is already installed"
        return 0
    fi
    
    case "$os" in
        linux)
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo mv kubectl /usr/local/bin/kubectl
            sudo chmod +x /usr/local/bin/kubectl
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install kubernetes-cli || brew upgrade kubernetes-cli
            else
                error "Homebrew is required to install kubectl on macOS"
                return 1
            fi
            ;;
    esac
    
    success "kubectl installed successfully"
}

install_helm() {
    local os="$1"
    
    info "Installing Helm..."
    
    # Check if helm is already installed
    if command -v helm >/dev/null 2>&1; then
        local current_version
        current_version=$(helm version --short 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || helm version --template='{{.Version}}' 2>/dev/null)
        info "Helm $current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for Helm updates via Homebrew..."
                    brew upgrade helm 2>/dev/null || true
                    success "Helm is up to date"
                    return 0
                fi
                ;;
        esac
        
        # For Linux or non-brew macOS, the installer script handles updates
        info "Running Helm installer to check for updates..."
    fi
    
    case "$os" in
        linux)
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install helm
            else
                curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
            fi
            ;;
    esac
    
    success "Helm installed successfully"
}

install_iac_tools() {
    local os="$1"
    
    print_header "Installing Infrastructure as Code Tools"
    
    install_terraform "$os"
    install_opentofu "$os"
    install_terragrunt "$os"
}

install_terraform() {
    local os="$1"
    
    info "Installing Terraform..."
    
    # Check if terraform is already installed
    if command -v terraform >/dev/null 2>&1; then
        local current_version
        current_version=$(terraform version | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "Terraform $current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for Terraform updates via Homebrew..."
                    brew upgrade hashicorp/tap/terraform 2>/dev/null || true
                    success "Terraform is up to date"
                    return 0
                fi
                ;;
            linux)
                info "Checking for Terraform updates via package manager..."
                sudo apt-get update >/dev/null 2>&1
                sudo apt-get install -y terraform 2>/dev/null || success "Terraform is up to date"
                return 0
                ;;
        esac
    fi
    
    case "$os" in
        linux)
            # Add HashiCorp repository
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
            sudo apt-get update
            sudo apt-get install -y terraform
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew tap hashicorp/tap
                brew install hashicorp/tap/terraform
            else
                error "Homebrew required for Terraform installation on macOS"
            fi
            ;;
    esac
    
    success "Terraform installed successfully"
}

install_opentofu() {
    local os="$1"
    
    info "Installing OpenTofu..."
    
    # Check if tofu is already installed
    if command -v tofu >/dev/null 2>&1; then
        local current_version
        current_version=$(tofu version | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "OpenTofu $current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for OpenTofu updates via Homebrew..."
                    brew upgrade opentofu 2>/dev/null || true
                    success "OpenTofu is up to date"
                    return 0
                fi
                ;;
        esac
        
        # For Linux or non-brew macOS, check latest version
        local latest_version
        latest_version=$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        
        if [[ "$current_version" == "$latest_version" ]]; then
            success "OpenTofu is up to date ($current_version)"
            return 0
        else
            info "Updating OpenTofu from $current_version to $latest_version"
        fi
    fi
    
    case "$os" in
        linux)
            # Download latest OpenTofu
            local tofu_version
            tofu_version=$(curl -s https://api.github.com/repos/opentofu/opentofu/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
            local arch
            arch=$(detect_arch)
            
            curl -L "https://github.com/opentofu/opentofu/releases/download/${tofu_version}/tofu_${tofu_version#v}_linux_${arch}.tar.gz" -o /tmp/tofu.tar.gz
            tar -xzf /tmp/tofu.tar.gz -C /tmp
            sudo mv /tmp/tofu /usr/local/bin/tofu
            sudo chmod +x /usr/local/bin/tofu
            rm /tmp/tofu.tar.gz
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install opentofu
            else
                error "Homebrew required for OpenTofu installation on macOS"
            fi
            ;;
    esac
    
    success "OpenTofu installed successfully"
}

install_terragrunt() {
    local os="$1"
    
    info "Installing Terragrunt..."
    
    # Check if terragrunt is already installed
    if command -v terragrunt >/dev/null 2>&1; then
        local current_version
        current_version=$(terragrunt --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        current_version="v${current_version}"  # Add 'v' prefix for consistency
        info "Terragrunt $current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for Terragrunt updates via Homebrew..."
                    brew upgrade terragrunt 2>/dev/null || true
                    success "Terragrunt is up to date"
                    return 0
                fi
                ;;
        esac
        
        # Check latest version
        local latest_version
        latest_version=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        
        if [[ "$current_version" == "$latest_version" ]]; then
            success "Terragrunt is up to date ($current_version)"
            return 0
        else
            info "Updating Terragrunt from $current_version to $latest_version"
        fi
    fi
    
    local tg_version
    tg_version=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    case "$os" in
        linux)
            curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/${tg_version}/terragrunt_linux_amd64" -o /tmp/terragrunt
            sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
            sudo chmod +x /usr/local/bin/terragrunt
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install terragrunt
            else
                curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/${tg_version}/terragrunt_darwin_amd64" -o /tmp/terragrunt
                sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
                sudo chmod +x /usr/local/bin/terragrunt
            fi
            ;;
    esac
    
    success "Terragrunt installed successfully"
}

install_cloud_tools() {
    local os="$1"
    
    print_header "Installing Cloud CLI Tools"
    
    install_aws_cli "$os"
    install_azure_cli "$os"
    install_gcloud_cli "$os"
}

install_aws_cli() {
    local os="$1"
    
    info "Installing AWS CLI v2..."
    
    # Check if aws is already installed
    if command -v aws >/dev/null 2>&1; then
        local current_version
        current_version=$(aws --version 2>&1 | grep -o 'aws-cli/[0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d'/' -f2)
        info "AWS CLI v$current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for AWS CLI updates via Homebrew..."
                    brew upgrade awscli 2>/dev/null || true
                    success "AWS CLI is up to date"
                    return 0
                fi
                ;;
        esac
        
        info "AWS CLI v2 installer will handle updates automatically"
    fi
    
    case "$os" in
        linux)
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
            cd /tmp && unzip -o awscliv2.zip
            sudo ./aws/install --update
            rm -rf /tmp/awscliv2.zip /tmp/aws
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install awscli
            else
                curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "/tmp/AWSCLIV2.pkg"
                sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
                rm /tmp/AWSCLIV2.pkg
            fi
            ;;
    esac
    
    success "AWS CLI installed successfully"
}

install_azure_cli() {
    local os="$1"
    
    info "Installing Azure CLI..."
    
    # Check if az is already installed
    if command -v az >/dev/null 2>&1; then
        local current_version
        current_version=$(az version --output tsv --query '"azure-cli"' 2>/dev/null || az --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "Azure CLI v$current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for Azure CLI updates via Homebrew..."
                    brew upgrade azure-cli 2>/dev/null || true
                    success "Azure CLI is up to date"
                    return 0
                fi
                ;;
            linux)
                info "Checking for Azure CLI updates..."
                az upgrade --yes 2>/dev/null || success "Azure CLI is up to date"
                return 0
                ;;
        esac
    fi
    
    case "$os" in
        linux)
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install azure-cli
            else
                error "Homebrew required for Azure CLI installation on macOS"
            fi
            ;;
    esac
    
    success "Azure CLI installed successfully"
}

install_gcloud_cli() {
    local os="$1"
    
    info "Installing Google Cloud CLI..."
    
    # Check if gcloud is already installed
    if command -v gcloud >/dev/null 2>&1; then
        local current_version
        current_version=$(gcloud version --format='value(Google Cloud SDK)' 2>/dev/null || gcloud --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        info "Google Cloud CLI v$current_version already installed"
        
        case "$os" in
            macos)
                if command -v brew >/dev/null 2>&1; then
                    info "Checking for Google Cloud CLI updates via Homebrew..."
                    brew upgrade google-cloud-sdk 2>/dev/null || true
                    success "Google Cloud CLI is up to date"
                    return 0
                fi
                ;;
            linux)
                info "Checking for Google Cloud CLI updates..."
                gcloud components update --quiet 2>/dev/null || success "Google Cloud CLI is up to date"
                return 0
                ;;
        esac
    fi
    
    case "$os" in
        linux)
            # Add Google Cloud repository
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
            sudo apt-get update
            sudo apt-get install -y google-cloud-cli
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install google-cloud-sdk
            else
                error "Homebrew required for Google Cloud CLI installation on macOS"
            fi
            ;;
    esac
    
    success "Google Cloud CLI installed successfully"
}

setup_environment() {
    print_header "Setting up Environment"
    
    # Add /usr/local/bin to PATH if not already there
    local shell_config="$HOME/.zshrc"
    if [[ -f "$shell_config" ]]; then
        if ! grep -q 'export PATH="/usr/local/bin:$PATH"' "$shell_config"; then
            echo 'export PATH="/usr/local/bin:$PATH"' >> "$shell_config"
            info "Added /usr/local/bin to PATH in $shell_config"
        fi
    fi
    
    # Docker completion for Zsh
    if command -v docker >/dev/null 2>&1 && [[ -d "$HOME/.oh-my-zsh" ]]; then
        mkdir -p "$HOME/.oh-my-zsh/completions"
        if [[ ! -f "$HOME/.oh-my-zsh/completions/_docker" ]]; then
            curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker -o "$HOME/.oh-my-zsh/completions/_docker"
            info "Added Docker completion for Zsh"
        fi
    fi
    
    success "Environment setup completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi