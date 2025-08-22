#!/usr/bin/env bash

# Python Environment Installer
# Consolidated installer for Python development environment across all platforms
# Installs: pyenv, Python versions, pip, pipx, poetry, pipenv

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Configuration
PYTHON_VERSIONS=("3.11" "3.12")
DEFAULT_PYTHON_VERSION="3.12"

install_python_dependencies() {
    info "Installing Python build dependencies..."
    
    case "${DOTFILES_OS}" in
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
            # Xcode command line tools should provide most dependencies
            if ! command_exists git; then
                install_packages git
            fi
            ;;
    esac
}

install_pyenv() {
    # Check if pyenv is installed (might not be in PATH yet)
    if [[ -d "$HOME/.pyenv/bin" ]]; then
        info "pyenv already installed, updating..."
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        if [[ -d "$HOME/.pyenv/.git" ]]; then
            cd "$HOME/.pyenv" && git pull 2>/dev/null || true
        fi
        return 0
    fi
    
    info "Installing pyenv..."
    
    # Install pyenv
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash 2>/dev/null || {
        # If that fails, try alternative installation method
        if [[ ! -d "$HOME/.pyenv" ]]; then
            git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv" || {
                error "Failed to install pyenv"
                return 1
            }
        fi
    }
    
    # Add to shell configuration
    local shell_config=""
    case "${SHELL##*/}" in
        zsh) shell_config="$HOME/.zshrc" ;;
        bash) shell_config="$HOME/.bashrc" ;;
        *) shell_config="$HOME/.profile" ;;
    esac
    
    if [[ -f "$shell_config" ]] && ! grep -q 'pyenv' "$shell_config"; then
        {
            echo ''
            echo '# pyenv configuration'
            echo 'export PYENV_ROOT="$HOME/.pyenv"'
            echo 'export PATH="$PYENV_ROOT/bin:$PATH"'
            echo 'if command -v pyenv 1>/dev/null 2>&1; then'
            echo '  eval "$(pyenv init -)"'
            echo 'fi'
        } >> "$shell_config"
        info "Added pyenv configuration to $shell_config"
    fi
    
    # Load pyenv in current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
    fi
    
    success "pyenv installed successfully"
}

install_python_versions() {
    info "Installing Python versions..."
    
    # Ensure pyenv is in PATH
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    for version in "${PYTHON_VERSIONS[@]}"; do
        if pyenv versions | grep -q "$version"; then
            info "Python $version already installed"
        else
            info "Installing Python $version..."
            # Use -s flag to skip if already installed
            pyenv install -s "$version" || {
                warning "Could not install Python $version (may already be installed)"
            }
        fi
    done
    
    # Set global default version
    pyenv global "$DEFAULT_PYTHON_VERSION"
    success "Set Python $DEFAULT_PYTHON_VERSION as global default"
}

install_pip_tools() {
    info "Installing pip tools..."
    
    # Ensure we're using the pyenv Python
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    # Upgrade pip
    python -m pip install --upgrade pip
    
    # Install pipx for isolated global packages
    if ! command_exists pipx; then
        python -m pip install --user pipx
        python -m pipx ensurepath
        
        # Add pipx to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
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
    )
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            pipx install "$tool" 2>/dev/null || {
                warning "Could not install $tool via pipx"
            }
        else
            debug "$tool already installed"
        fi
    done
    
    success "Python development tools installed"
}

configure_poetry() {
    if command_exists poetry; then
        info "Configuring poetry..."
        
        # Configure poetry to create virtual environments in project directories
        poetry config virtualenvs.in-project true 2>/dev/null || {
            warning "Could not configure poetry settings"
        }
        
        # Enable tab completion for bash/zsh
        local shell_config=""
        case "${SHELL##*/}" in
            zsh) shell_config="$HOME/.zshrc" ;;
            bash) shell_config="$HOME/.bashrc" ;;
        esac
        
        if [[ -n "$shell_config" ]] && [[ -f "$shell_config" ]]; then
            if ! grep -q 'poetry completions' "$shell_config"; then
                echo '' >> "$shell_config"
                echo '# Poetry completions' >> "$shell_config"
                if [[ "${SHELL##*/}" == "zsh" ]]; then
                    echo 'fpath+=~/.zfunc' >> "$shell_config"
                    mkdir -p ~/.zfunc
                    poetry completions zsh > ~/.zfunc/_poetry 2>/dev/null || true
                else
                    poetry completions bash >> "$shell_config" 2>/dev/null || true
                fi
                info "Added poetry completions"
            fi
        fi
        
        success "Poetry configured"
    fi
}

create_python_aliases() {
    local alias_file="$HOME/.dotfiles_python_aliases"
    
    cat > "$alias_file" << 'EOF'
# Python development aliases
alias py='python'
alias py3='python3'
alias pip3='python -m pip'
alias venv='python -m venv'
alias serve='python -m http.server'
alias json='python -m json.tool'

# pyenv aliases
alias pyv='pyenv version'
alias pyvs='pyenv versions'
alias pyvi='pyenv install'
alias pyvl='pyenv install --list'

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
EOF
    
    # Source aliases in shell config
    local shell_config=""
    case "${SHELL##*/}" in
        zsh) shell_config="$HOME/.zshrc" ;;
        bash) shell_config="$HOME/.bashrc" ;;
    esac
    
    if [[ -n "$shell_config" ]] && [[ -f "$shell_config" ]]; then
        if ! grep -q 'dotfiles_python_aliases' "$shell_config"; then
            echo '' >> "$shell_config"
            echo '# Python development aliases' >> "$shell_config"
            echo "source '$alias_file'" >> "$shell_config"
            info "Added Python aliases to $shell_config"
        fi
    fi
    
    success "Python aliases created"
}

verify_installation() {
    info "Verifying Python installation..."
    
    # Ensure pyenv is in PATH
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    # Check pyenv
    if [[ -d "$HOME/.pyenv/bin" ]] && command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        local pyenv_version=$(pyenv --version)
        success "pyenv: $pyenv_version"
        
        # Check Python versions
        local python_version=$(python --version)
        success "Python: $python_version"
    else
        error "pyenv installation failed"
    fi
    
    # Check pip tools
    export PATH="$HOME/.local/bin:$PATH"
    
    local tools=("pipx" "poetry" "pipenv")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local tool_version=$($tool --version 2>/dev/null || echo "installed")
            success "$tool: $tool_version"
        else
            warning "$tool not found"
        fi
    done
}

main() {
    init_script "Python Environment Installer"
    
    # Check if running on supported OS
    case "${DOTFILES_OS}" in
        linux|macos) ;;
        *) error "Unsupported operating system: ${DOTFILES_OS}" ;;
    esac
    
    install_python_dependencies
    install_pyenv
    install_python_versions
    install_pip_tools
    configure_poetry
    create_python_aliases
    verify_installation
    
    success "Python environment setup complete!"
    info "Please restart your shell or run: source ~/.${SHELL##*/}rc"
    info "Available Python versions: ${PYTHON_VERSIONS[*]}"
    info "Default Python version: $DEFAULT_PYTHON_VERSION"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi