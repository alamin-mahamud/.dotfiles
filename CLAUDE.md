# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive, modular dotfiles repository optimized for DevOps professionals and developers. The repository features a clean DRY architecture with shared libraries, component-based installers, and platform-specific orchestrators. It supports Zsh + Tmux + Neovim + modern CLI tools across Linux, macOS, and server environments.

## Key Commands

### Main Installation
- `./bootstrap.sh` - Main entry point with interactive menu and environment detection
- `chmod +x ./bootstrap.sh` - Make bootstrap script executable before running

### Platform-Specific Orchestrators
- **Linux Desktop**: `./linux/install.sh` - Complete Linux desktop environment
- **macOS**: `./macos/install.sh` - Complete macOS development environment
- **Server**: Use component installers directly for minimal installations

### Component Installers (Standalone)
- `./scripts/components/shell-env.sh` - Shell environment (Zsh + Oh My Zsh + Tmux + CLI tools)
- `./scripts/components/python-env.sh` - Python development environment (pyenv + poetry + pipx)

### Desktop Features
- `./scripts/desktop/keyboard-setup.sh` - Keyboard configuration including Caps Lock to Escape

### One-liner Installation
```bash
# Linux Desktop
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/linux/install.sh | bash

# macOS Desktop
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/macos/install.sh | bash

# Shell environment only
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env.sh | bash
```

## Architecture

### Clean DRY Directory Structure
```
.dotfiles/
├── bootstrap.sh                    # Main entry point with environment detection
├── scripts/                        # Organized installation scripts
│   ├── lib/                        # Shared libraries (DRY principle)
│   │   ├── common.sh              # Common utilities, logging, OS detection
│   │   └── package-managers.sh    # Unified package management
│   ├── components/                 # Component-specific installers
│   │   ├── shell-env.sh           # Shell environment (Zsh + Tmux + CLI tools)
│   │   └── python-env.sh          # Python development environment
│   ├── desktop/                   # Desktop-specific features
│   │   └── keyboard-setup.sh      # Keyboard configuration
│   └── features/                  # Feature-specific installers
├── configs/                       # Shared configuration files
│   ├── xmodmap/                   # X11 keyboard configurations
│   ├── keyd/                      # Wayland keyboard configurations
│   └── tmux/                      # Tmux configurations
├── linux/                         # Linux-specific configurations
│   ├── install.sh                 # Linux desktop orchestrator
│   └── .config/                   # Application configuration files
├── macos/                         # macOS-specific configurations
│   ├── install.sh                 # macOS orchestrator
│   ├── DefaultKeyBinding.dict     # macOS keyboard bindings
│   └── iterm/                     # iTerm2 configurations
├── zsh/                           # Zsh shell configuration
│   └── .zshrc                     # Main zsh configuration
└── git/                           # Git configuration
    └── .gitconfig                 # Global Git configuration
```

## DRY Architecture Principles

This repository follows strict DRY (Don't Repeat Yourself) principles with a clean, modular architecture:

- **Shared Libraries**: Common functionality centralized in `/scripts/lib/`
- **Component-Based**: Individual installers for each major component
- **Platform Orchestrators**: High-level scripts that coordinate component installations
- **Idempotent Scripts**: All installers can be run multiple times safely
- **Single Source of Truth**: No duplicate code across the codebase
- **Comprehensive Logging**: Unified logging system across all scripts
- **Environment Detection**: Automatic OS, distro, and architecture detection

### Shared Libraries

#### `scripts/lib/common.sh`
- **Logging Functions**: `info()`, `success()`, `error()`, `warning()`, `debug()`
- **OS Detection**: `detect_os()`, `detect_distro()`, `detect_arch()`
- **Environment Detection**: `is_desktop_environment()`, `is_wsl()`, `is_ssh_session()`
- **File Operations**: `backup_file()`, `safe_symlink()`
- **Network Utilities**: `check_internet()`, `download_file()`
- **User Interaction**: `ask_yes_no()`

#### `scripts/lib/package-managers.sh`
- **Unified Package Management**: Works with apt, dnf, pacman, brew, etc.
- **Multi-Package Installation**: `install_packages_multi()` with OS-specific names
- **Repository Management**: `add_repository()` with key handling
- **Build Essentials**: `install_build_essentials()` for each platform

### Component Architecture

#### Shell Environment (`components/shell-env.sh`)
- **Shell**: Zsh with Oh My Zsh framework
- **Theme**: Powerlevel10k with instant prompt
- **Plugins**: autosuggestions, syntax-highlighting, completions, fzf-tab
- **Tools**: ripgrep, fd, bat, exa/eza, fzf, tmux, neovim
- **Configuration**: Comprehensive .zshrc with aliases and functions
- **Tmux Integration**: Full tmux setup with TPM and Tokyo Night theme

#### Python Environment (`components/python-env.sh`)
- **Version Management**: pyenv with multiple Python versions
- **Package Managers**: pip, pipx, poetry, pipenv
- **Development Tools**: black, isort, flake8, mypy, pytest
- **Virtual Environments**: Automated setup and configuration
- **Shell Integration**: Aliases and completions

#### Desktop Features (`desktop/keyboard-setup.sh`)
- **Caps Lock to Escape**: Universal mapping across X11, Wayland, macOS
- **Display Server Detection**: Automatic configuration method selection
- **Persistence**: Launch agents (macOS) and system configurations (Linux)
- **Multiple Methods**: keyd, GNOME, KDE, X11 support

### Enhanced Script Features

#### Idempotent Design
- **Safe Re-execution**: All scripts can be run multiple times without causing conflicts
- **State Checking**: Scripts detect existing installations and update appropriately
- **Backup Strategy**: Automatic backup of existing configurations before changes
- **Update Capability**: Git repositories and plugins are updated when scripts are re-run

#### Comprehensive OS Support
- **Linux Distributions**: Ubuntu, Debian, Fedora, CentOS, RHEL, Rocky, AlmaLinux, Arch, Manjaro, Alpine, openSUSE
- **macOS**: Full Homebrew integration with Apple Silicon support
- **Package Managers**: Automatic detection and use of apt, dnf, yum, pacman, apk, zypper, brew
- **Architecture Support**: x86_64 and arm64 (Apple Silicon) where applicable

#### Logging and Monitoring
- **Detailed Logging**: All operations logged with timestamps to `/tmp/` files
- **Progress Tracking**: Clear status messages with color-coded output
- **Error Handling**: Graceful error handling with informative messages
- **Summary Reports**: Comprehensive installation summaries with next steps

#### Professional DevOps Features
- **Security-First**: Proper user permissions, group management, firewall configuration
- **Production Ready**: Server hardening, fail2ban configuration, SSH security
- **Modern Toolchain**: Latest versions via official repositories and releases
- **Workflow Integration**: Seamless integration between tmux, vim, shell, and development tools

### Configuration Strategy

#### Symlink-Based Approach
1. Dotfiles remain in the repository directory
2. Setup scripts create symlinks from `$HOME` to repository files
3. Backup functionality for existing configurations
4. Version control of all configurations

#### Environment Variables
- `DOTFILES_ROOT` - Repository root directory
- `DOTFILES_OS` - Detected operating system (linux/macos)
- `DOTFILES_ENV` - Environment type (desktop/server/wsl)
- `DOTFILES_DISTRO` - Linux distribution (ubuntu/arch/etc.)
- `DOTFILES_VERSION` - OS version

#### Modular Design
- Independent component installation
- Dependency management between components
- Error handling and rollback capabilities
- Logging and debugging support

### Security Features

#### Server Hardening
- **Firewall**: UFW with default deny incoming
- **Intrusion Prevention**: fail2ban with SSH protection
- **SSH Security**: Key-based authentication, connection limits
- **System Updates**: Automated security updates
- **User Permissions**: Sudo configuration for package managers

#### macOS Security
- **System Preferences**: Privacy and security configurations
- **Code Signing**: Support for application signing
- **Keychain Integration**: Secure credential storage

### Modern Toolchain

#### Python Environment
- **pyenv**: Python version management with multiple versions
- **pipx**: Isolated global package installation
- **pipenv**: Project-specific virtual environments with Pipfile
- **poetry**: Modern dependency management and packaging

#### Shell Productivity
- **Oh My Zsh**: Framework with extensive plugin ecosystem
- **Powerlevel10k**: Fast, customizable prompt with Git integration
- **FZF**: Fuzzy finding for files, history, and processes
- **Modern CLI tools**: ripgrep, fd, bat, eza for enhanced productivity

#### Development Integration
- **Git**: Enhanced configuration with GitHub CLI integration
- **Docker**: Container development with compose support
- **Cloud Native**: kubectl, helm, terraform for infrastructure
- **Multiple Language Support**: Node.js, Python, Rust, Go environments

## Important Notes

- The repository expects to be cloned to `$HOME/Work/.dotfiles`
- Linux scripts include sudoers configuration for passwordless package management
- Font installation includes Nerd Fonts (FiraCode, JetBrainsMono, Iosevka)
- Zsh configuration depends on Oh My Zsh framework
- Git configuration includes personal user details that should be updated