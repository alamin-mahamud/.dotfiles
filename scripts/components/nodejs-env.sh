#!/usr/bin/env bash

# Node.js Development Environment Setup
# Installs NVM, Node.js LTS, npm, and yarn

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

main() {
    print_header "Node.js Development Environment Setup"
    
    local os
    os=$(detect_os)
    
    info "Setting up Node.js environment for $os"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    install_nvm
    install_nodejs
    install_yarn
    setup_nodejs_environment
    
    success "Node.js development environment setup completed!"
    info "Please restart your shell or run: source ~/.zshrc"
}

install_nvm() {
    print_header "Installing NVM (Node Version Manager)"
    
    # Check if NVM is already installed
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        warning "NVM already installed, updating..."
    fi
    
    # Get latest NVM version
    local nvm_version
    nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    # Download and install NVM
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    
    success "NVM ${nvm_version} installed successfully"
}

install_nodejs() {
    print_header "Installing Node.js LTS"
    
    # Source NVM if available
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    
    if ! command -v nvm >/dev/null 2>&1; then
        error "NVM not found. Please ensure NVM is properly installed."
    fi
    
    # Install latest LTS version
    info "Installing Node.js LTS version..."
    nvm install --lts
    nvm use --lts
    nvm alias default "lts/*"
    
    # Update npm to latest
    info "Updating npm to latest version..."
    npm install -g npm@latest
    
    local node_version
    node_version=$(node --version)
    local npm_version
    npm_version=$(npm --version)
    
    success "Node.js ${node_version} and npm ${npm_version} installed successfully"
}

install_yarn() {
    print_header "Installing Yarn Package Manager"
    
    # Check if yarn is already installed
    if command -v yarn >/dev/null 2>&1; then
        warning "Yarn already installed, upgrading..."
    fi
    
    # Install yarn globally via npm
    npm install -g yarn
    
    local yarn_version
    yarn_version=$(yarn --version)
    
    success "Yarn ${yarn_version} installed successfully"
}

setup_nodejs_environment() {
    print_header "Setting up Node.js Environment"
    
    local shell_config="$HOME/.zshrc"
    
    # Backup existing config if it exists
    if [[ -f "$shell_config" ]]; then
        backup_file "$shell_config"
    fi
    
    # Add NVM configuration to shell
    if [[ ! -f "$shell_config" ]] || ! grep -q "NVM_DIR" "$shell_config"; then
        cat >> "$shell_config" << 'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Node.js and npm configuration
export PATH="$HOME/.npm-global/bin:$PATH"

# Yarn configuration
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
EOF
        
        info "Added Node.js environment configuration to $shell_config"
    else
        debug "Node.js environment already configured in $shell_config"
    fi
    
    # Create npm global directory to avoid permission issues
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"
    
    # Configure npm for faster installs
    npm config set fund false
    npm config set audit false
    
    info "Node.js environment configuration completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi