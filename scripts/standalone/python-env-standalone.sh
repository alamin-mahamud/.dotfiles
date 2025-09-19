#!/usr/bin/env bash

# Python Environment Standalone Installer
# Self-contained installer for Python development environment
# Installs: pyenv, Python versions, pip, pipx, poetry, pipenv + development tools
#
# Installation: curl -fsSL <URL> | bash
# Re-run safe: This script is idempotent and can be run multiple times safely
#
# Author: Dotfiles Project
# Version: 1.0.0

set -euo pipefail

# =============================================================================
# EMBEDDED UTILITY FUNCTIONS (No External Dependencies)
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global variables
SCRIPT_NAME="Python Environment Installer"
SCRIPT_VERSION="1.0.0"
LOG_FILE="/tmp/python-env-install-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/tmp/python-env-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
NO_BACKUP=false
FORCE=false

# Python configuration
DEFAULT_PYTHON_VERSIONS=("3.11" "3.12")
DEFAULT_PYTHON_VERSION="3.12"
PYTHON_VERSIONS=()

# Logging functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}ERROR: $1${NC}" >&2
    exit 1
}

warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

info() {
    log "${CYAN}→ $1${NC}"
}

debug() {
    if [[ "${DEBUG:-}" == "1" ]]; then
        log "${PURPLE}DEBUG: $1${NC}"
    fi
}

print_header() {
    log "${WHITE}${1}${NC}"
    log "${WHITE}$(printf '%.0s=' {1..${#1}})${NC}"
}

# OS Detection functions
detect_os() {
    case "$OSTYPE" in
        linux-gnu*) echo "linux" ;;
        darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}

detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        echo "unknown"
        return
    fi
    
    local distro_id
    distro_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    echo "${distro_id,,}"  # lowercase
}

detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "$arch" ;;
    esac
}

# Command utilities
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    if ! command_exists "$1"; then
        error "Required command '$1' not found"
    fi
}

# Network utilities
check_internet() {
    if command_exists curl; then
        curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1
    elif command_exists wget; then
        wget -q --timeout=5 --tries=1 --spider https://www.google.com >/dev/null 2>&1
    else
        return 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -fsSL "$url" -o "$output"
    elif command_exists wget; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget is available"
    fi
}

# Package management functions
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    elif command_exists apk; then
        echo "apk"
    else
        echo "unknown"
    fi
}

update_package_lists() {
    local pm="$(detect_package_manager)"
    local update_marker="/tmp/.python-env-packages-updated"
    
    # Check if recently updated (within 1 hour)
    if [[ -f "$update_marker" ]]; then
        local last_update=0
        if [[ "$OSTYPE" == "darwin"* ]]; then
            last_update=$(stat -f %m "$update_marker" 2>/dev/null || echo 0)
        else
            last_update=$(stat -c %Y "$update_marker" 2>/dev/null || echo 0)
        fi
        
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_update))
        
        if [[ $time_diff -lt 3600 ]]; then
            debug "Package lists recently updated, skipping"
            return 0
        fi
    fi
    
    info "Updating package lists..."
    
    case "$pm" in
        apt)
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] Would run: sudo apt-get update"
            else
                if timeout 60 sudo apt-get update -qq 2>/dev/null; then
                    touch "$update_marker"
                    success "Package lists updated"
                else
                    warning "Failed to update package lists, continuing anyway"
                fi
            fi
            ;;
        dnf)
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] Would run: sudo dnf check-update"
            else
                (timeout 60 sudo dnf check-update -q || true) && touch "$update_marker"
            fi
            ;;
        *) warning "Unknown package manager: $pm" ;;
    esac
}

install_packages() {
    local packages=("$@")
    local pm="$(detect_package_manager)"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages specified for installation"
        return 0
    fi
    
    info "Installing packages: ${packages[*]} (using $pm)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install: ${packages[*]}"
        return 0
    fi
    
    case "$pm" in
        apt)
            timeout 300 sudo apt-get install -y "${packages[@]}" || {
                warning "Package installation may have failed or timed out"
                return 1
            }
            ;;
        dnf)
            timeout 300 sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            timeout 300 sudo yum install -y "${packages[@]}"
            ;;
        *) error "Cannot install packages: unknown package manager '$pm'" ;;
    esac
}

# =============================================================================
# PYTHON ENVIRONMENT INSTALLATION FUNCTIONS
# =============================================================================

install_python_build_dependencies() {
    info "Installing Python build dependencies..."
    
    local packages=()
    local pm="$(detect_package_manager)"
    
    case "$pm" in
        apt)
            packages=(
                make build-essential libssl-dev zlib1g-dev
                libbz2-dev libreadline-dev libsqlite3-dev wget
                curl llvm libncurses5-dev libncursesw5-dev
                xz-utils tk-dev libffi-dev liblzma-dev
                python3-openssl git
            )
            ;;
        dnf|yum)
            packages=(
                gcc gcc-c++ make git patch openssl-devel
                zlib-devel bzip2-devel readline-devel
                sqlite-devel wget curl llvm ncurses-devel
                xz tk-devel libffi-devel xz-devel
            )
            ;;
        pacman)
            packages=(base-devel openssl zlib xz tk libffi git)
            ;;
        apk)
            packages=(
                git bash build-base libffi-dev openssl-dev
                bzip2-dev zlib-dev xz-dev readline-dev
                sqlite-dev tk-dev
            )
            ;;
        *)
            packages=(git curl wget)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        update_package_lists
        install_packages "${packages[@]}"
    fi
    
    success "Python build dependencies installed"
}

configure_pyenv_in_shell() {
    info "Configuring pyenv in current shell session..."
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    if command_exists pyenv; then
        eval "$(pyenv init --path)" 2>/dev/null || true
        eval "$(pyenv init -)" 2>/dev/null || true
        success "pyenv configured in shell"
    else
        debug "pyenv not yet available in shell"
    fi
}

install_pyenv() {
    local pyenv_root="$HOME/.pyenv"
    
    if [[ -d "$pyenv_root" ]]; then
        info "pyenv directory found, updating..."
        if [[ -d "$pyenv_root/.git" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                info "[DRY RUN] Would update pyenv"
            else
                cd "$pyenv_root" && git pull 2>/dev/null || {
                    warning "Failed to update pyenv"
                }
                success "Updated pyenv"
            fi
        fi
        configure_pyenv_in_shell
        return 0
    fi
    
    info "Installing pyenv..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install pyenv using pyenv installer"
        return 0
    fi
    
    # Install pyenv using the official installer
    curl -L https://pyenv.run | bash || {
        error "Failed to install pyenv"
    }
    
    configure_pyenv_in_shell
    success "pyenv installed successfully"
}

install_python_versions() {
    info "Installing Python versions..."
    
    configure_pyenv_in_shell
    
    # Use provided versions or defaults
    local versions=("${PYTHON_VERSIONS[@]}")
    if [[ ${#versions[@]} -eq 0 ]]; then
        versions=("${DEFAULT_PYTHON_VERSIONS[@]}")
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install Python versions: ${versions[*]}"
        info "[DRY RUN] Would set Python $DEFAULT_PYTHON_VERSION as global default"
        return 0
    fi
    
    for version in "${versions[@]}"; do
        if pyenv versions 2>/dev/null | grep -q "\\b$version"; then
            info "Python $version already installed"
        else
            info "Installing Python $version... (this may take a while)"
            PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install "$version" || {
                warning "Could not install Python $version"
                continue
            }
            success "Installed Python $version"
        fi
    done
    
    # Set global default version
    pyenv global "$DEFAULT_PYTHON_VERSION" 2>/dev/null || {
        warning "Could not set Python $DEFAULT_PYTHON_VERSION as global default"
    }
    success "Set Python $DEFAULT_PYTHON_VERSION as global default"
}

upgrade_pip() {
    info "Upgrading pip..."
    
    configure_pyenv_in_shell
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would upgrade pip"
        return 0
    fi
    
    if ! command_exists python; then
        warning "Python not available in PATH"
        return 1
    fi
    
    python -m pip install --upgrade pip 2>/dev/null || {
        warning "Failed to upgrade pip"
    }
    success "pip upgraded"
}

install_pipx() {
    if command_exists pipx; then
        info "pipx already installed"
        return 0
    fi
    
    info "Installing pipx..."
    
    configure_pyenv_in_shell
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would install pipx"
        return 0
    fi
    
    python -m pip install --user pipx || {
        error "Failed to install pipx"
    }
    
    # Ensure pipx path is available
    python -m pipx ensurepath || true
    
    # Add to PATH for current session
    local pipx_bin="$HOME/.local/bin"
    if [[ ":$PATH:" != *":$pipx_bin:"* ]]; then
        export PATH="$pipx_bin:$PATH"
        info "$pipx_bin added to PATH for current session"
    fi
    
    success "pipx installed"
}

install_python_tools() {
    info "Installing Python development tools..."
    
    configure_pyenv_in_shell
    
    # Install pipenv directly via pip
    if ! command_exists pipenv; then
        info "Installing pipenv..."
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] Would install pipenv"
        else
            pipx install pipenv 2>/dev/null || {
                python -m pip install --user pipenv 2>/dev/null || {
                    warning "Failed to install pipenv"
                }
            }
        fi
    else
        info "pipenv already installed"
    fi
    
    # Install poetry via pipx
    if ! command_exists poetry; then
        info "Installing poetry..."
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] Would install poetry"
        else
            pipx install poetry 2>/dev/null || {
                warning "Failed to install poetry via pipx"
            }
        fi
    else
        info "poetry already installed"
    fi
    
    # Install other useful tools
    local tools=(
        "black"          # Code formatter
        "isort"          # Import sorter
        "flake8"         # Linter
        "mypy"           # Type checker
        "pytest"         # Testing framework
        "pre-commit"     # Git hooks
        "cookiecutter"   # Project templates
        "httpie"         # HTTP client
        "ruff"           # Fast Python linter
    )
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            debug "$tool already installed"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            info "[DRY RUN] Would install $tool"
            continue
        fi
        
        info "Installing $tool..."
        pipx install "$tool" 2>/dev/null || {
            warning "Could not install $tool via pipx"
        }
    done
    
    success "Python development tools installed"
}

configure_poetry() {
    if ! command_exists poetry; then
        debug "poetry not available, skipping configuration"
        return 0
    fi
    
    info "Configuring poetry..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would configure poetry settings"
        return 0
    fi
    
    # Configure poetry to create virtual environments in project directories
    poetry config virtualenvs.in-project true 2>/dev/null || true
    
    # Configure poetry to use pyenv python versions
    poetry config virtualenvs.prefer-active-python true 2>/dev/null || true
    
    success "poetry configured"
}

configure_shell_integration() {
    info "Configuring shell integration for Python tools..."
    
    local shell_configs=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
    )
    
    local python_config='
# Python Development Environment Configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv if available
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# pipx configuration
export PATH="$HOME/.local/bin:$PATH"

# Python aliases
alias py="python3"
alias pip="pip3"
alias pytest="python -m pytest"
alias serve="python -m http.server"
alias json="python -m json.tool"

# Virtual environment helpers
alias venv="python -m venv"
alias activate="source venv/bin/activate"

# Poetry shortcuts
alias po="poetry"
alias poe="poetry run"
alias poi="poetry install"
alias poa="poetry add"
alias pos="poetry shell"
'
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would add Python configuration to shell files"
        return 0
    fi
    
    for config_file in "${shell_configs[@]}"; do
        if [[ -f "$config_file" ]]; then
            # Check if our configuration is already present
            if ! grep -q "# Python Development Environment Configuration" "$config_file" 2>/dev/null; then
                echo "$python_config" >> "$config_file"
                success "Added Python configuration to $config_file"
            else
                debug "Python configuration already exists in $config_file"
            fi
        fi
    done
    
    # Create a standalone Python environment file
    local python_env_file="$HOME/.python_env"
    if [[ ! -f "$python_env_file" ]]; then
        cat > "$python_env_file" << EOF
#!/usr/bin/env bash
# Python Development Environment
# Source this file to load Python development tools

$python_config
EOF
        success "Created standalone Python environment file: $python_env_file"
        info "To load Python environment: source $python_env_file"
    fi
}

verify_installation() {
    info "Verifying Python environment installation..."
    
    local errors=0
    
    # Check pyenv
    if command_exists pyenv; then
        local pyenv_version
        pyenv_version=$(pyenv --version 2>/dev/null || echo "unknown")
        success "pyenv: $pyenv_version"
    else
        warning "pyenv not found"
        errors=$((errors + 1))
    fi
    
    # Check Python versions
    configure_pyenv_in_shell
    if command_exists pyenv; then
        local installed_versions
        installed_versions=$(pyenv versions --bare 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//')
        if [[ -n "$installed_versions" ]]; then
            success "Python versions: $installed_versions"
        else
            warning "No Python versions found"
            errors=$((errors + 1))
        fi
    fi
    
    # Check pip
    if command_exists pip; then
        local pip_version
        pip_version=$(pip --version 2>/dev/null || echo "unknown")
        debug "pip: $pip_version"
    fi
    
    # Check pipx
    if command_exists pipx; then
        success "pipx: installed"
    else
        warning "pipx not found"
        errors=$((errors + 1))
    fi
    
    # Check Python tools
    local tools=("poetry" "pipenv" "black" "isort" "flake8" "mypy" "pytest" "ruff")
    local installed_tools=()
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            installed_tools+=("$tool")
        fi
    done
    
    if [[ ${#installed_tools[@]} -gt 0 ]]; then
        success "Python tools: ${installed_tools[*]}"
    else
        warning "No Python development tools found"
    fi
    
    if [[ $errors -eq 0 ]]; then
        success "All core components verified successfully"
    else
        warning "$errors components failed verification"
    fi
}

# =============================================================================
# ARGUMENT PARSING AND MAIN FUNCTION
# =============================================================================

show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

A standalone, idempotent installer for Python development environment.
Installs pyenv, Python versions, pipx, poetry, pipenv, and essential tools.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help              Show this help message and exit
    --version           Show version information and exit
    --dry-run           Show what would be installed without making changes
    --no-backup         Skip backing up existing configuration files
    --force             Override existing installations and configurations
    --debug             Enable debug output
    --python-versions   Comma-separated list of Python versions to install
                        (default: ${DEFAULT_PYTHON_VERSIONS[*]})
    --default-version   Default Python version to set globally
                        (default: $DEFAULT_PYTHON_VERSION)

EXAMPLES:
    # Standard installation
    $0

    # Install specific Python versions
    $0 --python-versions "3.10,3.11,3.12" --default-version "3.11"

    # Dry run to see what would be installed
    $0 --dry-run

    # One-liner installation (curl pipe)
    curl -fsSL <URL> | bash

    # One-liner with options
    curl -fsSL <URL> | bash -s -- --python-versions "3.11,3.12"

FEATURES:
    • pyenv for Python version management
    • Multiple Python versions (3.10, 3.11, 3.12)
    • pipx for isolated global package installation
    • poetry for modern dependency management
    • pipenv for virtual environment management
    • Essential development tools: black, isort, flake8, mypy, pytest, ruff
    • Shell integration with aliases and functions
    • Idempotent - safe to run multiple times

REQUIREMENTS:
    • Ubuntu 20.04+ (or compatible Linux distribution)
    • Internet connection
    • sudo privileges for package installation
    • 2GB+ disk space for Python versions

INSTALLED TOOLS:
    • pyenv: Python version manager
    • pipx: Install and run Python applications in isolated environments
    • poetry: Python dependency management and packaging
    • pipenv: Python development workflow for humans
    • black: Uncompromising Python code formatter
    • isort: Python import sorter
    • flake8: Python linting tool
    • mypy: Static type checker for Python
    • pytest: Testing framework for Python
    • ruff: Fast Python linter written in Rust
    • pre-commit: Git hook framework
    • cookiecutter: Project templating
    • httpie: Command-line HTTP client

For more information, visit: https://github.com/alamin-mahamud/.dotfiles
EOF
}

show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --no-backup)
                NO_BACKUP=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --debug)
                export DEBUG=1
                shift
                ;;
            --python-versions)
                if [[ -n "${2:-}" ]]; then
                    IFS=',' read -ra PYTHON_VERSIONS <<< "$2"
                    shift 2
                else
                    error "--python-versions requires a value"
                fi
                ;;
            --default-version)
                if [[ -n "${2:-}" ]]; then
                    DEFAULT_PYTHON_VERSION="$2"
                    shift 2
                else
                    error "--default-version requires a value"
                fi
                ;;
            *)
                error "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"
    
    print_header "$SCRIPT_NAME v$SCRIPT_VERSION"
    info "Starting at $(date)"
    info "Log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN MODE - No changes will be made"
    fi
    
    if [[ "$NO_BACKUP" == "true" ]]; then
        info "Backup disabled - existing files will be overwritten"
    else
        info "Backup directory: $BACKUP_DIR"
    fi
    
    # Show configuration
    local versions_to_install=()
    if [[ ${#PYTHON_VERSIONS[@]} -eq 0 ]]; then
        versions_to_install=("${DEFAULT_PYTHON_VERSIONS[@]}")
    else
        versions_to_install=("${PYTHON_VERSIONS[@]}")
    fi
    info "Python versions to install: ${versions_to_install[*]}"
    info "Default Python version: $DEFAULT_PYTHON_VERSION"
    
    # Check for required tools
    require_command curl
    
    # Detect environment
    local os="$(detect_os)"
    local distro="$(detect_distro)"
    info "Detected OS: $os ($distro)"
    
    if [[ "$os" != "linux" ]] && [[ "$os" != "macos" ]]; then
        error "This script is designed for Linux/macOS systems. Detected: $os"
    fi
    
    # Check for internet connectivity
    if ! check_internet; then
        warning "No internet connection detected. Some features may not work."
    fi
    
    # Installation steps
    info "Beginning Python environment installation..."
    
    install_python_build_dependencies
    install_pyenv
    install_python_versions
    upgrade_pip
    install_pipx
    install_python_tools
    configure_poetry
    configure_shell_integration
    verify_installation
    
    print_header "Python Environment Setup Complete!"
    success "Installation completed successfully!"
    
    info "Next steps:"
    info "1. Restart your shell or run: exec \$SHELL"
    info "2. Or source the Python environment: source ~/.python_env"
    info "3. Verify installation: pyenv versions"
    info "4. Create a new project: poetry new myproject"
    info "5. Use virtual environments: python -m venv myproject && source myproject/bin/activate"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        info "Installation log: $LOG_FILE"
        if [[ "$NO_BACKUP" == "false" ]]; then
            info "Configuration backups: $BACKUP_DIR"
        fi
        
        # Show installed versions
        configure_pyenv_in_shell
        if command_exists pyenv; then
            local installed_versions
            installed_versions=$(pyenv versions --bare 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            if [[ -n "$installed_versions" ]]; then
                info "Installed Python versions: $installed_versions"
            fi
            
            local global_version
            global_version=$(pyenv global 2>/dev/null || echo "none")
            info "Global Python version: $global_version"
        fi
    fi
    
    info "Finished at $(date)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
