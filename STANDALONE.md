# Standalone Installation Scripts

This document describes the standalone installation scripts available in this repository.

## Overview

While the main dotfiles installation uses a modular architecture with shared libraries, we also provide **standalone scripts** that can be run independently without any external dependencies.

## Available Standalone Scripts

### 1. Shell Environment (`shell-env-standalone.sh`)

**Complete shell setup with Zsh + Oh My Zsh + Tmux + modern CLI tools**

```bash
# One-liner installation
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env-standalone.sh | bash

# Or download and run
wget https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env-standalone.sh
chmod +x shell-env-standalone.sh
./shell-env-standalone.sh
```

**Includes:**
- Zsh with Oh My Zsh framework
- Powerlevel10k theme with instant prompt
- Essential plugins (autosuggestions, syntax-highlighting, completions)
- Modern CLI tools (ripgrep, fd, bat, eza, fzf, etc.)
- Tmux with TPM and Tokyo Night theme
- Comprehensive aliases and keybindings
- Automatic completion cleanup and error handling

### 2. Python Environment (`python-env-standalone.sh`)

**Complete Python development environment with version management**

```bash
# One-liner installation
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/python-env-standalone.sh | bash

# Or download and run
wget https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/python-env-standalone.sh
chmod +x python-env-standalone.sh
./python-env-standalone.sh
```

**Includes:**
- pyenv for Python version management
- Python 3.11 and 3.12 installations
- pipx for isolated package installations
- poetry for dependency management
- pipenv for virtual environments
- Development tools (black, isort, flake8, mypy, pytest)
- IPython and Jupyter for interactive development
- Shell integration and aliases

### 3. Keyboard Setup (`keyboard-setup-standalone.sh`)

**Cross-platform keyboard configuration (Caps Lock to Escape)**

```bash
# One-liner installation
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/desktop/keyboard-setup-standalone.sh | bash

# Or download and run
wget https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/desktop/keyboard-setup-standalone.sh
chmod +x keyboard-setup-standalone.sh
./keyboard-setup-standalone.sh
```

**Features:**
- **Linux**: Supports both X11 (Xmodmap) and Wayland (keyd/GNOME)
- **macOS**: Uses hidutil with launch agent for persistence
- Automatic display server detection
- Persistent configuration across reboots
- Verification and testing helpers

## Comparison: Modular vs Standalone

| Feature | Modular Architecture | Standalone Scripts |
|---------|---------------------|-------------------|
| **Dependencies** | Requires shared libraries | Zero dependencies |
| **Installation** | Clone repo first | Direct curl/wget |
| **Customization** | Easy to modify | Self-contained |
| **Maintenance** | DRY principle | Duplicated code |
| **Use Case** | Development setup | Quick deployments |
| **CI/CD** | Requires repo access | Single URL |

## When to Use Standalone Scripts

✅ **Use standalone scripts when:**
- Quick server setup without cloning the repository
- CI/CD pipeline installations
- One-off environment setups
- Testing installations on clean systems
- Sharing with others who don't need the full repo

✅ **Use modular architecture when:**
- Full development environment setup
- Customizing and maintaining configurations
- Contributing to the dotfiles repository
- Need the complete desktop environment

## Architecture Details

### Embedded Functions
Each standalone script includes embedded versions of:
- **Logging**: `info()`, `success()`, `error()`, `warning()`
- **OS Detection**: `detect_os()`, `detect_package_manager()`
- **Package Management**: `install_packages()` with cross-platform support
- **Utilities**: `command_exists()`, `backup_file()`

### Cross-Platform Support
- **Linux**: Ubuntu, Debian, Fedora, Arch, Alpine
- **macOS**: Intel and Apple Silicon
- **Package Managers**: apt, dnf, yum, pacman, apk, brew

### Error Handling
- Comprehensive error checking and recovery
- Graceful degradation when optional packages fail
- Detailed logging to `/tmp/` files
- Interrupt handling with cleanup

## Examples

### Shell Environment Only
```bash
# Install just the shell environment
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env-standalone.sh | bash
```

### Python Development Setup
```bash
# Install Python environment
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/python-env-standalone.sh | bash
```

### Combined Installation
```bash
# Install both shell and Python environments
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env-standalone.sh | bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/python-env-standalone.sh | bash
```

### Keyboard Configuration
```bash
# Configure keyboard (after GUI environment is set up)
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/desktop/keyboard-setup-standalone.sh | bash
```

## Notes

- Scripts are idempotent - safe to run multiple times
- Existing configurations are backed up automatically
- Logs are saved to `/tmp/` with timestamps
- All scripts support both interactive and non-interactive execution
- No sudo password required for Homebrew on macOS
- Linux scripts may require sudo for package installation

## Contributing

When updating the main modular scripts, please also update the corresponding standalone versions to maintain feature parity.