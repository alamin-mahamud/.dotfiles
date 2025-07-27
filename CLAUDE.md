# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive, modular dotfiles repository for automated development environment setup across Ubuntu Desktop, Ubuntu Server, and macOS. The repository features enhanced installation scripts, comprehensive documentation, and support for multiple environment types.

## Key Commands

### Main Installation
- `./bootstrap.sh` - Enhanced main entry point with interactive menu and environment detection
- `./ubuntu-server-setup.sh` - Standalone minimal server installation script
- `chmod +x ./bootstrap.sh` - Make bootstrap script executable before running

### Modular Installation Scripts
- `./scripts/install-dev-tools.sh` - Development tools installation (Python, Node.js, Docker, etc.)
- `./scripts/install-shell.sh` - Shell environment setup (Zsh, Oh My Zsh, tmux)
- `./scripts/custom-install.sh` - Custom component selection installation

### Platform-Specific Setup
- Linux Desktop: `./linux/install-enhanced.sh` (called automatically by bootstrap)
- macOS: `./macos/install-enhanced.sh` (called automatically by bootstrap)
- Ubuntu Server: `./ubuntu-server-setup.sh` (standalone script)

### Legacy Support
- `./linux/install.sh` - Delegates to enhanced version
- `./macos/install.sh` - Delegates to enhanced version

## Architecture

### Enhanced Directory Structure
```
.dotfiles/
├── bootstrap.sh                    # Enhanced main entry point with environment detection
├── ubuntu-server-setup.sh          # Standalone server installation
├── scripts/                        # Modular installation scripts
│   ├── install-dev-tools.sh       # Development environment setup
│   ├── install-shell.sh           # Shell and terminal configuration
│   └── custom-install.sh          # Component-based custom installation
├── docs/                           # Comprehensive documentation
│   ├── UBUNTU_DESKTOP.md          # Ubuntu desktop installation guide
│   ├── UBUNTU_SERVER.md           # Ubuntu server installation guide
│   └── MACOS.md                   # macOS installation guide
├── configs/                        # Shared configuration files
├── linux/                          # Linux-specific configurations
│   ├── install.sh                 # Delegates to enhanced version
│   ├── install-enhanced.sh        # Full Linux desktop installation
│   ├── .config/                   # Application configuration files
│   └── .local/                    # User scripts and binaries
├── macos/                          # macOS-specific configurations
│   ├── install.sh                 # Delegates to enhanced version
│   └── install-enhanced.sh        # Full macOS installation with Homebrew
├── zsh/                            # Zsh shell configuration
│   ├── .zshrc                     # Main zsh configuration
│   └── *.zsh                      # Modular configuration files
└── git/                            # Git configuration
    └── .gitconfig                 # Global Git configuration
```

### Installation Modes

#### Bootstrap Script Options
The enhanced bootstrap script provides multiple installation options:

**Linux:**
1. Full Installation (Desktop with GUI) - Complete desktop environment
2. Server Installation (Minimal, no GUI) - Uses standalone server script
3. Development Tools Only - Programming languages and tools
4. Shell Configuration Only - Zsh, tmux, and productivity tools
5. Custom Installation - Component selection

**macOS:**
1. Full Installation - Complete development environment
2. Development Tools Only - Programming languages and tools
3. Shell Configuration Only - Terminal and shell setup
4. Custom Installation - Component selection

#### Environment Detection
The system automatically detects:
- **Operating System**: Linux, macOS, Windows (WSL)
- **Environment Type**: Desktop, Server, WSL
- **Distribution**: Ubuntu, Debian, Arch, macOS version
- **Package Manager**: apt, pacman, homebrew

### Component Architecture

#### Development Tools (`install-dev-tools.sh`)
- **Languages**: Python (pyenv, pipx, pipenv), Node.js, Rust, Go
- **Containers**: Docker, docker-compose
- **Cloud Tools**: AWS CLI, kubectl, Terraform
- **Editors**: Neovim, VS Code
- **Databases**: PostgreSQL, MySQL, Redis clients

#### Shell Environment (`install-shell.sh`)
- **Shell**: Zsh with Oh My Zsh framework
- **Theme**: Powerlevel10k with custom configuration
- **Plugins**: autosuggestions, syntax-highlighting, completions, fzf-tab
- **Terminal**: tmux with TPM (Tmux Plugin Manager)
- **Tools**: FZF, ripgrep, bat, eza, zoxide

#### Server-Specific Features (`ubuntu-server-setup.sh`)
- **Security**: UFW firewall, fail2ban, SSH hardening
- **Monitoring**: htop, iotop, nethogs, system stats
- **Maintenance**: Automated update scripts, log rotation
- **Minimal GUI**: No desktop environment components

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