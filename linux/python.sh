#!/bin/sh

# Detect the operating system
OS=$(uname -s)
UBUNTU="Linux"
ARCH="Arch"

DEFAULT_PYTHON_VERSION="3.12.7"
PYTHON_VERSION="${1:-$DEFAULT_PYTHON_VERSION}"

install_python_deps() {
    echo "📦 Installing dependencies for python and relevant tools..."
    if [ "$OS" = "$UBUNTU" ]; then
        sudo apt install -y make libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev wget llvm \
            libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
            liblzma-dev openssl
    elif [ "$OS" = "$ARCH" ]; then
        sudo paru -S --noconfirm --needed openssl zlib bzip2 readline \
                                          sqlite wget llvm \
                                          ncurses xz tk libffi lzma
    else
        echo "❌ Unsupported operating system: $OS"
        exit 1
    fi
}

configure_pyenv_in_shells() {
    echo "🔧 Configuring pyenv in shell ..."
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    echo "✅ pyenv configured in shell. Sync .zshrc to persist changes."
}

install_pyenv() {
    if ! command_exists pyenv; then
        echo "📥 Installing pyenv..."
        curl https://pyenv.run | sh
        echo "✅ pyenv installed successfully."
    else
        echo "✅ pyenv is already installed."
    fi

    configure_pyenv_in_shells
}

install_python_version() {
    echo "📥 Installing Python $PYTHON_VERSION..."

    if pyenv versions | grep -q "$PYTHON_VERSION"; then
        echo "✅ Python $PYTHON_VERSION is already installed."
    else
        echo "📥 Installing Python $PYTHON_VERSION using pyenv..."
        pyenv install "$PYTHON_VERSION"
        pyenv global "$PYTHON_VERSION"
    fi
}

install_pip() {
    if ! command_exists pip; then
        echo "📥 Installing pip..."
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python get-pip.py --user
        rm get-pip.py
    fi
    python -m pip install --upgrade pip
}

install_pipx() {
    if ! command_exists pipx; then
        echo "📥 Installing pipx..."
        python -m pip install --user pipx
        python -m pipx ensurepath

        # Check if $HOME/.local/bin is already in PATH
        case ":$PATH:" in
            *":$HOME/.local/bin:"*) ;;
            *) export PATH="$HOME/.local/bin:$PATH"; echo "$HOME/.local/bin has been added to PATH." ;;
        esac
    else
        echo "✅ pipx is already installed."
    fi
}

install_pipenv() {
    if ! command_exists pipenv; then
        echo "📥 Installing pipenv..."
        pipx install pipenv
        export PIPENV_PYTHON="$HOME/.pyenv/shims/python"
    else
        echo "✅ pipenv is already installed."
    fi
}

display_installation_summary() {
    echo "🔍 Installation Summary:"
    echo "🐍 Python Version: $(python --version)"
    echo "📦 pip Version: $(pip --version)"
    echo "📦 pipx Version: $(pipx --version)"
    echo "📦 pipenv Version: $(pipenv --version)"
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
