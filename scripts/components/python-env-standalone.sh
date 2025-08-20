#!/usr/bin/env bash

# Standalone Python Environment Installer
# Installs: pyenv, Python versions, pip, pipx, poetry, pipenv
# No external dependencies - can be run with:
# curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/python-env-standalone.sh | bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Configuration
PYTHON_VERSIONS=("3.11" "3.12")
DEFAULT_PYTHON_VERSION="3.12"
LOG_FILE="/tmp/python-env-install-$(date +%Y%m%d_%H%M%S).log"

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

print_header() {
    log "${WHITE}${1}${NC}"
    log "${WHITE}$(printf '%.0s=' {1..${#1}})${NC}"
}

# OS Detection
detect_os() {
    case "$OSTYPE" in
        linux-gnu*) echo "linux" ;;
        darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}

detect_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_packages() {
    local packages=("$@")
    local pm
    pm=$(detect_package_manager)
    
    info "Installing packages: ${packages[*]} (using $pm)"
    
    case "$pm" in
        apt)
            sudo apt update >/dev/null 2>&1
            sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        apk)
            sudo apk add "${packages[@]}"
            ;;
        brew)
            brew install "${packages[@]}"
            ;;
        *)
            error "Unknown package manager: $pm"
            ;;
    esac
}

install_python_dependencies() {
    info "Installing Python build dependencies..."
    
    local os
    os=$(detect_os)
    
    case "$os" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages \
                        make build-essential libssl-dev zlib1g-dev \
                        libbz2-dev libreadline-dev libsqlite3-dev wget \
                        curl llvm libncurses5-dev libncursesw5-dev \
                        xz-utils tk-dev libffi-dev liblzma-dev \
                        python3-openssl git
                    ;;
                dnf|yum)
                    install_packages \
                        gcc gcc-c++ make git patch openssl-devel \
                        zlib-devel bzip2-devel readline-devel \
                        sqlite-devel wget curl llvm ncurses-devel \
                        xz tk-devel libffi-devel xz-devel
                    ;;
                pacman)
                    install_packages \
                        base-devel openssl zlib xz tk libffi git
                    ;;
                apk)
                    install_packages \
                        git bash build-base libffi-dev openssl-dev \
                        bzip2-dev zlib-dev xz-dev readline-dev \
                        sqlite-dev tk-dev
                    ;;
            esac
            ;;
        macos)
            # macOS has most dependencies via Xcode Command Line Tools
            info "Using Xcode Command Line Tools for Python dependencies"
            ;;
    esac
}

install_pyenv() {
    if command_exists pyenv; then
        info "pyenv already installed, updating..."
        if [[ -d "$HOME/.pyenv" ]]; then
            cd "$HOME/.pyenv" && git pull
        fi
        success "Updated pyenv"
    else
        info "Installing pyenv..."
        curl https://pyenv.run | bash
        success "Installed pyenv"
    fi
    
    # Add pyenv to PATH for this session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
}

install_python_versions() {
    info "Installing Python versions: ${PYTHON_VERSIONS[*]}"
    
    for version in "${PYTHON_VERSIONS[@]}"; do
        if pyenv versions | grep -q "$version"; then
            info "Python $version already installed"
        else
            info "Installing Python $version..."
            pyenv install "$version"
            success "Installed Python $version"
        fi
    done
    
    # Set global Python version
    pyenv global "$DEFAULT_PYTHON_VERSION"
    success "Set Python $DEFAULT_PYTHON_VERSION as global default"
}

install_pip_tools() {
    info "Installing pip tools..."
    
    # Upgrade pip
    python -m pip install --upgrade pip
    
    # Install pipx
    if ! command_exists pipx; then
        python -m pip install --user pipx
        python -m pipx ensurepath
        success "pipx installed"
    else
        info "pipx already installed"
    fi
    
    # Install poetry via pipx
    if ! command_exists poetry; then
        pipx install poetry
        success "poetry installed via pipx"
    else
        info "poetry already installed"
    fi
    
    # Install pipenv
    if ! command_exists pipenv; then
        pipx install pipenv
        success "pipenv installed via pipx"
    else
        info "pipenv already installed"
    fi
}

install_development_tools() {
    info "Installing Python development tools..."
    
    local tools=(
        "black"      # Code formatter
        "isort"      # Import sorter
        "flake8"     # Linter
        "mypy"       # Type checker
        "pytest"     # Testing framework
        "ipython"    # Enhanced REPL
        "jupyter"    # Notebooks
    )
    
    for tool in "${tools[@]}"; do
        if ! pipx list | grep -q "$tool"; then
            pipx install "$tool"
        fi
    done
    
    success "Installed Python development tools"
}

configure_poetry() {
    if command_exists poetry; then
        info "Configuring poetry..."
        
        # Configure poetry to create virtual environments in project directories
        poetry config virtualenvs.in-project true
        poetry config virtualenvs.prefer-active-python true
        
        success "Configured poetry"
    fi
}

configure_shell_integration() {
    info "Configuring shell integration..."
    
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc")
    
    for shell_config in "${shell_configs[@]}"; do
        if [[ -f "$shell_config" ]]; then
            # Add pyenv initialization
            if ! grep -q 'pyenv init' "$shell_config"; then
                cat >> "$shell_config" << 'EOF'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
                info "Added pyenv configuration to $shell_config"
            fi
            
            # Add poetry completions
            if command_exists poetry && ! grep -q 'poetry completions' "$shell_config"; then
                case "$shell_config" in
                    *zshrc)
                        mkdir -p ~/.zfunc
                        poetry completions zsh > ~/.zfunc/_poetry
                        ;;
                    *bashrc)
                        poetry completions bash >> "$shell_config"
                        ;;
                esac
                info "Added poetry completions"
            fi
        fi
    done
    
    # Create Python aliases
    local aliases_file="$HOME/.python_aliases"
    cat > "$aliases_file" << 'EOF'
# Python aliases for enhanced productivity

# Python
alias py='python'
alias py3='python3'
alias ipy='ipython'
alias jup='jupyter'
alias nb='jupyter notebook'
alias lab='jupyter lab'

# Poetry aliases
alias po='poetry'
alias poi='poetry install'
alias poa='poetry add'
alias por='poetry remove'
alias pos='poetry shell'
alias pob='poetry build'
alias pop='poetry publish'
alias pou='poetry update'

# pipenv aliases
alias penv='pipenv'
alias penvs='pipenv shell'
alias penvi='pipenv install'
alias penvu='pipenv uninstall'
alias penvr='pipenv run'
alias penvg='pipenv graph'

# Virtual environment
alias venv='python -m venv'
alias activate='source venv/bin/activate'

# Package management
alias pip='python -m pip'
alias pipi='python -m pip install'
alias pipu='python -m pip install --upgrade'
alias pipf='python -m pip freeze'
alias pipl='python -m pip list'

# Development tools
alias pf='python -m flake8'
alias pb='python -m black'
alias pi='python -m isort'
alias pm='python -m mypy'
alias pt='python -m pytest'

# Quick commands
alias pyserver='python -m http.server'
alias pyjson='python -m json.tool'
alias pyhelp='python -c "help()"'
EOF
    
    success "Created Python aliases"
}

verify_installation() {
    info "Verifying Python installation..."
    
    # Check pyenv
    if command_exists pyenv; then
        local pyenv_version
        pyenv_version=$(pyenv --version)
        success "pyenv: $pyenv_version"
    else
        error "pyenv not found"
    fi
    
    # Check Python versions
    info "Available Python versions:"
    pyenv versions
    
    # Check pip tools
    local tools=("pipx" "poetry" "pipenv")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local version
            version=$("$tool" --version 2>/dev/null || echo "installed")
            success "$tool: $version"
        else
            warning "$tool: not found"
        fi
    done
    
    # Check Python packages
    info "Checking Python packages..."
    python -c "
import sys
print(f'Python: {sys.version}')

packages = ['pip', 'setuptools', 'wheel']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✓ {pkg}: available')
    except ImportError:
        print(f'✗ {pkg}: not available')
"
}

main() {
    print_header "Python Environment Installer"
    info "Starting at $(date)"
    info "Log file: $LOG_FILE"
    
    install_python_dependencies
    install_pyenv
    install_python_versions
    install_pip_tools
    install_development_tools
    configure_poetry
    configure_shell_integration
    
    verify_installation
    
    success "Python environment setup complete!"
    info "Please restart your terminal or run: source ~/.zshrc"
    info "Available Python versions: ${PYTHON_VERSIONS[*]}"
    info "Default Python version: $DEFAULT_PYTHON_VERSION"
    
    info "Script finished at $(date)"
}

# Handle script interruption
trap 'echo; warning "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"