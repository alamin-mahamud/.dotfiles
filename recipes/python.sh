#!/usr/bin/env bash
# Python development environment recipe
# Following Python's Zen: "Readability counts"

# Get the recipe root directory
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$RECIPE_DIR/../lib" && pwd)"

# Import ingredients
source "$LIB_DIR/core.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/package.sh"

# Configuration
readonly PYTHON_VERSIONS=("3.12" "3.11" "3.10")
readonly DEFAULT_PYTHON="3.12"
readonly PYTHON_TOOLS=(
    "black"
    "isort"
    "flake8"
    "mypy"
    "pytest"
    "ipython"
    "jupyter"
    "httpie"
    "tldr"
    "cookiecutter"
)

# Install pyenv
install_pyenv() {
    info "Installing pyenv..."
    
    local pyenv_root="${HOME}/.pyenv"
    
    if [[ -d "$pyenv_root" ]]; then
        info "Updating pyenv..."
        (cd "$pyenv_root" && git pull --rebase)
    else
        info "Installing pyenv..."
        git clone https://github.com/pyenv/pyenv.git "$pyenv_root"
    fi
    
    # Install pyenv-virtualenv plugin
    local virtualenv_dir="$pyenv_root/plugins/pyenv-virtualenv"
    if [[ -d "$virtualenv_dir" ]]; then
        (cd "$virtualenv_dir" && git pull --rebase)
    else
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$virtualenv_dir"
    fi
    
    # Install pyenv-update plugin
    local update_dir="$pyenv_root/plugins/pyenv-update"
    if [[ -d "$update_dir" ]]; then
        (cd "$update_dir" && git pull --rebase)
    else
        git clone https://github.com/pyenv/pyenv-update.git "$update_dir"
    fi
    
    success "pyenv ready"
}

# Install Python build dependencies
install_python_build_deps() {
    info "Installing Python build dependencies..."
    
    local os distro
    os=$(detect_os)
    distro=$(detect_distro)
    
    case "$os" in
        macos)
            install_packages openssl readline sqlite3 xz zlib
            ;;
        linux)
            case "$distro" in
                debian)
                    install_packages \
                        build-essential libssl-dev zlib1g-dev \
                        libbz2-dev libreadline-dev libsqlite3-dev \
                        libncursesw5-dev xz-utils tk-dev \
                        libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
                    ;;
                redhat)
                    install_packages \
                        gcc zlib-devel bzip2 bzip2-devel \
                        readline-devel sqlite sqlite-devel \
                        openssl-devel tk-devel libffi-devel xz-devel
                    ;;
                arch)
                    install_packages \
                        base-devel openssl zlib xz tk
                    ;;
            esac
            ;;
    esac
    
    success "Python build dependencies installed"
}

# Install Python versions
install_python_versions() {
    info "Installing Python versions..."
    
    # Setup pyenv environment
    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    for version in "${PYTHON_VERSIONS[@]}"; do
        # Get latest patch version
        local full_version
        full_version=$(pyenv install --list | grep -E "^  ${version}\.[0-9]+$" | tail -1 | xargs)
        
        if [[ -z "$full_version" ]]; then
            warning "No version found for Python $version"
            continue
        fi
        
        if pyenv versions | grep -q "$full_version"; then
            info "Python $full_version already installed"
        else
            info "Installing Python $full_version..."
            pyenv install "$full_version"
        fi
    done
    
    # Set default Python version
    local default_full
    default_full=$(pyenv install --list | grep -E "^  ${DEFAULT_PYTHON}\.[0-9]+$" | tail -1 | xargs)
    
    if [[ -n "$default_full" ]]; then
        pyenv global "$default_full"
        success "Set Python $default_full as default"
    fi
}

# Install pipx
install_pipx() {
    info "Installing pipx..."
    
    # Ensure pip is updated
    python -m pip install --upgrade pip
    
    # Install pipx
    python -m pip install --user pipx
    python -m pipx ensurepath
    
    success "pipx ready"
}

# Install poetry
install_poetry() {
    info "Installing poetry..."
    
    if command_exists poetry; then
        info "Updating poetry..."
        poetry self update
    else
        curl -sSL https://install.python-poetry.org | python3 -
    fi
    
    # Configure poetry
    export PATH="${HOME}/.local/bin:$PATH"
    poetry config virtualenvs.in-project true
    
    success "poetry ready"
}

# Install Python tools with pipx
install_python_tools() {
    info "Installing Python tools..."
    
    # Ensure pipx is in PATH
    export PATH="${HOME}/.local/bin:$PATH"
    
    for tool in "${PYTHON_TOOLS[@]}"; do
        if pipx list | grep -q "^   $tool "; then
            info "Upgrading $tool..."
            pipx upgrade "$tool"
        else
            info "Installing $tool..."
            pipx install "$tool"
        fi
    done
    
    success "Python tools ready"
}

# Configure shell integration
configure_shell_integration() {
    info "Configuring shell integration..."
    
    local shell_config="${HOME}/.zshrc"
    local pyenv_root="${HOME}/.pyenv"
    
    # Create shell configuration snippet
    local config_snippet="${HOME}/.python_env"
    
    cat > "$config_snippet" << 'EOF'
# Python environment configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.poetry/bin:$PATH"

# Initialize pyenv
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Python aliases
alias py="python"
alias py3="python3"
alias pip="python -m pip"
alias venv="python -m venv"
alias activate="source venv/bin/activate"
alias deactivate="deactivate 2>/dev/null || true"

# Poetry aliases
alias p="poetry"
alias prun="poetry run"
alias pshell="poetry shell"
alias pinstall="poetry install"
alias pupdate="poetry update"

# IPython as default Python REPL
alias python="ipython --no-banner 2>/dev/null || python"
EOF
    
    # Add to shell config if not already present
    if [[ -f "$shell_config" ]] && ! grep -q "/.python_env" "$shell_config"; then
        echo "" >> "$shell_config"
        echo "# Python environment" >> "$shell_config"
        echo "[[ -f \"\$HOME/.python_env\" ]] && source \"\$HOME/.python_env\"" >> "$shell_config"
    fi
    
    success "Shell integration configured"
}

# Main recipe execution
run_recipe() {
    info "=== Python Development Recipe ==="
    
    # Check prerequisites
    if ! check_internet; then
        die "Internet connection required"
    fi
    
    # Execute recipe steps
    install_python_build_deps
    install_pyenv
    install_python_versions
    install_pipx
    install_poetry
    install_python_tools
    configure_shell_integration
    
    success "=== Python environment ready! ==="
    info "Please restart your shell or run: source ~/.python_env"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_recipe "$@"
fi