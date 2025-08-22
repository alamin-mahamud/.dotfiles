#!/usr/bin/env bash

# Go Development Environment Setup
# Installs latest Go version and sets up environment

set -euo pipefail

# Source libraries from GitHub
GITHUB_RAW_URL="https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master"
source <(curl -fsSL "$GITHUB_RAW_URL/scripts/lib/common.sh")
source <(curl -fsSL "$GITHUB_RAW_URL/scripts/lib/package-managers.sh")

main() {
    print_header "Go Development Environment Setup"
    
    local os
    os=$(detect_os)
    
    info "Setting up Go environment for $os"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    install_go "$os"
    setup_go_environment
    install_go_tools
    
    success "Go development environment setup completed!"
    info "Please restart your shell or run: source ~/.zshrc"
}

install_go() {
    local os="$1"
    
    print_header "Installing Go"
    
    # Check if Go is already installed and get version
    if command -v go >/dev/null 2>&1; then
        local current_version
        current_version=$(go version | awk '{print $3}' | sed 's/go//')
        warning "Go ${current_version} already installed, upgrading to latest..."
        
        # Remove existing Go installation
        if [[ -d "/usr/local/go" ]]; then
            sudo rm -rf /usr/local/go
        fi
    fi
    
    # Get latest Go version
    local go_version
    go_version=$(curl -s https://golang.org/VERSION?m=text)
    
    info "Installing Go ${go_version}..."
    
    case "$os" in
        linux)
            local arch
            arch=$(detect_arch)
            
            # Map architecture names for Go
            case "$arch" in
                amd64) go_arch="amd64" ;;
                arm64) go_arch="arm64" ;;
                *) error "Unsupported architecture: $arch" ;;
            esac
            
            curl -L "https://golang.org/dl/${go_version}.linux-${go_arch}.tar.gz" -o "/tmp/${go_version}.linux-${go_arch}.tar.gz"
            sudo tar -C /usr/local -xzf "/tmp/${go_version}.linux-${go_arch}.tar.gz"
            rm "/tmp/${go_version}.linux-${go_arch}.tar.gz"
            ;;
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install go
            else
                local arch
                arch=$(uname -m)
                case "$arch" in
                    x86_64) go_arch="amd64" ;;
                    arm64) go_arch="arm64" ;;
                    *) error "Unsupported architecture: $arch" ;;
                esac
                
                curl -L "https://golang.org/dl/${go_version}.darwin-${go_arch}.tar.gz" -o "/tmp/${go_version}.darwin-${go_arch}.tar.gz"
                sudo tar -C /usr/local -xzf "/tmp/${go_version}.darwin-${go_arch}.tar.gz"
                rm "/tmp/${go_version}.darwin-${go_arch}.tar.gz"
            fi
            ;;
        *)
            error "Unsupported OS for Go installation: $os"
            ;;
    esac
    
    success "Go ${go_version} installed successfully"
}

setup_go_environment() {
    print_header "Setting up Go Environment"
    
    local shell_config="$HOME/.zshrc"
    
    # Backup existing config if it exists
    if [[ -f "$shell_config" ]]; then
        backup_file "$shell_config"
    fi
    
    # Create Go workspace directories
    mkdir -p "$HOME/go/{bin,src,pkg}"
    
    # Add Go configuration to shell
    if [[ ! -f "$shell_config" ]] || ! grep -q "GOPATH" "$shell_config"; then
        cat >> "$shell_config" << 'EOF'

# Go Configuration
export GOPATH="$HOME/go"
export GOROOT="/usr/local/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Go module proxy (for faster downloads)
export GOPROXY="https://proxy.golang.org,direct"
export GOSUMDB="sum.golang.org"

# Go development settings
export GO111MODULE=on
export CGO_ENABLED=1
EOF
        
        info "Added Go environment configuration to $shell_config"
    else
        debug "Go environment already configured in $shell_config"
    fi
    
    # Source the configuration for current session
    export GOPATH="$HOME/go"
    export GOROOT="/usr/local/go"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
    export GO111MODULE=on
    
    info "Go environment configuration completed"
}

install_go_tools() {
    print_header "Installing Go Development Tools"
    
    # Source the configuration
    export GOPATH="$HOME/go"
    export GOROOT="/usr/local/go"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
    
    if ! command -v go >/dev/null 2>&1; then
        error "Go not found in PATH. Please restart your shell and try again."
    fi
    
    info "Installing essential Go tools..."
    
    # Language server and development tools
    local tools=(
        "golang.org/x/tools/gopls@latest"                    # Go language server
        "github.com/go-delve/delve/cmd/dlv@latest"          # Debugger
        "honnef.co/go/tools/cmd/staticcheck@latest"         # Static analyzer
        "golang.org/x/tools/cmd/goimports@latest"           # Import organizer
        "golang.org/x/tools/cmd/godoc@latest"               # Documentation
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"  # Linter
        "golang.org/x/vuln/cmd/govulncheck@latest"          # Vulnerability checker
    )
    
    for tool in "${tools[@]}"; do
        info "Installing $(basename ${tool%@*})..."
        if go install "$tool" 2>/dev/null; then
            success "Installed $(basename ${tool%@*})"
        else
            warning "Failed to install $(basename ${tool%@*})"
        fi
    done
    
    success "Go development tools installation completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi