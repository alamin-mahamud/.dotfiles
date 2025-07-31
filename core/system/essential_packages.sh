#!/bin/bash
# core/system/essential_packages.sh - Essential system packages installation

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/platform.sh"

# Component metadata
COMPONENT_META[name]="essential_packages"
COMPONENT_META[description]="Essential system packages for development and operations"
COMPONENT_META[version]="1.0.0"
COMPONENT_META[category]="core"
COMPONENT_META[platforms]="linux macos"

# Load component framework
source "$SCRIPT_DIR/../utils/component.sh"

# Essential packages by category
declare -A LINUX_PACKAGES=(
    # Build essentials
    ["build"]="build-essential cmake automake autoconf libtool pkg-config"
    # Version control
    ["vcs"]="git git-lfs subversion mercurial"
    # Network tools
    ["network"]="curl wget netcat-openbsd net-tools dnsutils iputils-ping traceroute nmap"
    # File operations
    ["file"]="rsync unzip zip p7zip-full tar gzip bzip2 xz-utils"
    # Text processing
    ["text"]="sed gawk grep findutils coreutils diffutils patch"
    # System monitoring
    ["monitor"]="htop iotop sysstat lsof strace ltrace"
    # Security tools
    ["security"]="gnupg2 openssh-client openssl ca-certificates apt-transport-https"
    # Development tools
    ["dev"]="vim nano tmux screen jq yq shellcheck"
    # Python essentials
    ["python"]="python3 python3-pip python3-venv python3-dev"
)

declare -A MACOS_PACKAGES=(
    # Core tools
    ["core"]="coreutils findutils gnu-tar gnu-sed gawk grep"
    # Version control
    ["vcs"]="git git-lfs"
    # Network tools
    ["network"]="curl wget netcat nmap"
    # File operations
    ["file"]="rsync unzip zip p7zip"
    # Text processing
    ["text"]="jq yq"
    # System monitoring
    ["monitor"]="htop lsof"
    # Development tools
    ["dev"]="vim tmux screen shellcheck"
    # Security tools
    ["security"]="gnupg openssh openssl"
)

component_install() {
    log_info "Installing essential packages..."
    
    case "$DOTFILES_OS" in
        linux)
            install_linux_packages
            ;;
        macos)
            install_macos_packages
            ;;
        *)
            log_error "Essential packages not supported on $DOTFILES_OS"
            return 1
            ;;
    esac
    
    # Configure installed tools
    configure_tools
}

install_linux_packages() {
    local package_manager
    package_manager=$(get_package_manager) || return 1
    
    # Update package lists first
    log_info "Updating package lists..."
    case "$package_manager" in
        apt)
            sudo apt-get update -qq || {
                log_error "Failed to update package lists"
                return 1
            }
            ;;
        dnf)
            sudo dnf check-update || true
            ;;
        pacman)
            sudo pacman -Sy || {
                log_error "Failed to update package lists"
                return 1
            }
            ;;
    esac
    
    # Install packages by category
    local category packages failed_packages=""
    for category in "${!LINUX_PACKAGES[@]}"; do
        packages="${LINUX_PACKAGES[$category]}"
        log_info "Installing $category packages..."
        
        for package in $packages; do
            if ! is_package_installed "$package"; then
                if ! install_package "$package"; then
                    log_warn "Failed to install package: $package"
                    failed_packages="$failed_packages $package"
                else
                    log_debug "Installed: $package"
                fi
            else
                log_debug "Already installed: $package"
            fi
        done
    done
    
    # Handle distribution-specific packages
    install_distro_specific_packages
    
    if [[ -n "$failed_packages" ]]; then
        log_warn "Some packages failed to install:$failed_packages"
        log_warn "You may need to install them manually"
    fi
    
    log_success "Essential packages installation completed"
}

install_macos_packages() {
    # Ensure Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is required but not installed"
        log_info "Install Homebrew from https://brew.sh"
        return 1
    fi
    
    log_info "Updating Homebrew..."
    brew update || {
        log_warn "Failed to update Homebrew"
    }
    
    # Install packages by category
    local category packages failed_packages=""
    for category in "${!MACOS_PACKAGES[@]}"; do
        packages="${MACOS_PACKAGES[$category]}"
        log_info "Installing $category packages..."
        
        for package in $packages; do
            if ! brew list "$package" &> /dev/null; then
                if ! brew install "$package"; then
                    log_warn "Failed to install package: $package"
                    failed_packages="$failed_packages $package"
                else
                    log_debug "Installed: $package"
                fi
            else
                log_debug "Already installed: $package"
            fi
        done
    done
    
    # Install Mac-specific tools
    install_macos_specific_tools
    
    if [[ -n "$failed_packages" ]]; then
        log_warn "Some packages failed to install:$failed_packages"
    fi
    
    log_success "Essential packages installation completed"
}

install_distro_specific_packages() {
    case "$DOTFILES_DISTRO" in
        ubuntu|debian)
            # Ubuntu/Debian specific packages
            local extra_packages="software-properties-common lsb-release"
            for package in $extra_packages; do
                install_package "$package" || true
            done
            ;;
        fedora|centos|rhel)
            # Fedora/RHEL specific packages
            local extra_packages="dnf-plugins-core redhat-lsb-core"
            for package in $extra_packages; do
                install_package "$package" || true
            done
            ;;
        arch)
            # Arch specific packages
            local extra_packages="base-devel lsb-release"
            for package in $extra_packages; do
                install_package "$package" || true
            done
            ;;
    esac
}

install_macos_specific_tools() {
    # Install useful macOS command line tools
    local tools="mas trash"
    
    for tool in $tools; do
        if ! brew list "$tool" &> /dev/null; then
            brew install "$tool" || log_warn "Failed to install: $tool"
        fi
    done
}

configure_tools() {
    log_info "Configuring installed tools..."
    
    # Git configuration
    if command -v git &> /dev/null; then
        # Set up global gitignore
        local gitignore_global="$HOME/.gitignore_global"
        if [[ ! -f "$gitignore_global" ]]; then
            cat > "$gitignore_global" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
*.swp
*.swo
*~
.idea/
.vscode/
*.sublime-project
*.sublime-workspace

# Compiled files
*.pyc
__pycache__/
*.class
*.o
*.so

# Temporary files
*.tmp
*.temp
*.log
EOF
            git config --global core.excludesfile "$gitignore_global"
            log_debug "Created global gitignore"
        fi
        
        # Enable Git LFS if installed
        if command -v git-lfs &> /dev/null; then
            git lfs install --skip-repo
            log_debug "Git LFS initialized"
        fi
    fi
    
    # Create common directories
    local dirs=(
        "$HOME/.local/bin"
        "$HOME/.config"
        "$HOME/.cache"
        "$HOME/.local/share"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "Created directory: $dir"
        fi
    done
    
    # Add .local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_info "Add $HOME/.local/bin to your PATH for user-installed binaries"
    fi
}

component_validate() {
    log_info "Validating essential packages..."
    
    local validation_failed=0
    
    # Check critical commands
    local critical_commands="git curl wget tar gzip"
    for cmd in $critical_commands; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Critical command not found: $cmd"
            ((validation_failed++))
        else
            log_debug "Found: $cmd"
        fi
    done
    
    # Check Python installation
    if ! command -v python3 &> /dev/null; then
        log_warn "Python 3 not found"
    else
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_debug "Python version: $python_version"
    fi
    
    # Check Git configuration
    if command -v git &> /dev/null; then
        if git config --global core.excludesfile &> /dev/null; then
            log_debug "Git global excludes configured"
        else
            log_warn "Git global excludes not configured"
        fi
    fi
    
    if [[ $validation_failed -eq 0 ]]; then
        log_success "Essential packages validation passed"
        return 0
    else
        log_error "Essential packages validation failed"
        return 1
    fi
}

# Execute component if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize platform detection
    init_platform
    
    # Run component
    run_component
fi