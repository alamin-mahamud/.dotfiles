# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive, modular dotfiles repository optimized for DevOps professionals working with Linux servers. The repository features standalone installation scripts, embedded configurations, and specialized DevOps tooling focused on Zsh + Tmux + LazyVim + Kitty environments.

## Key Commands

### Main Installation
- `./bootstrap.sh` - Enhanced main entry point with interactive menu and environment detection
- `chmod +x ./bootstrap.sh` - Make bootstrap script executable before running

### DevOps Standalone Installers (can be run independently via curl)
- `./scripts/devops-shell.sh` - Complete DevOps shell environment (Zsh + Tmux + Kitty + modern CLI tools)
- `./scripts/devops-tools.sh` - DevOps tools (Docker + Kubernetes + Terraform + AWS CLI + Python + Node.js)
- `./scripts/ubuntu-server-setup.sh` - Ubuntu Server setup orchestrator
- `./scripts/install-dev-tools.sh` - Development tools installation
- `./scripts/custom-install.sh` - Component-based custom installation

### One-liner Installation (DevOps-focused)
```bash
# Complete DevOps shell environment
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/devops-shell.sh | bash

# DevOps tools and infrastructure
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/devops-tools.sh | bash

# Ubuntu Server complete setup
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/ubuntu-server-setup.sh | bash
```

### Platform-Specific Setup (DRY orchestrators)
- Linux Desktop: `./linux/install.sh` - DRY Linux desktop orchestrator
- macOS: `./macos/install.sh` - DRY macOS orchestrator  
- Ubuntu Server: `./scripts/ubuntu-server-setup.sh` - DRY Ubuntu Server orchestrator

## DRY Architecture Principles

This repository follows DRY (Don't Repeat Yourself) principles with idempotent, standalone installers:

- **Idempotent Scripts**: All installers can be run multiple times safely without causing issues
- **Standalone Design**: Each script is self-contained with embedded configurations and dependencies
- **Individual Component Scripts**: Each tool/service has its own specialized installer with comprehensive OS support
- **Platform Orchestrators**: Platform-specific scripts call individual component installers  
- **GitHub Raw URLs**: All installers can be called remotely to avoid code duplication
- **Modular Design**: Users can install individual components or complete environments
- **Single Source of Truth**: Component logic lives in one place, referenced by orchestrators
- **Comprehensive Logging**: All scripts provide detailed logging and backup functionality

## Architecture

### DRY Directory Structure
```
.dotfiles/
├── bootstrap.sh                    # Main entry point with environment detection
├── scripts/                        # DRY component installers
│   ├── ubuntu-server-setup.sh     # Ubuntu Server orchestrator (DRY)
│   ├── install-shell.sh           # Enhanced shell environment (includes tmux)
│   ├── vim-installer.sh            # Enhanced vim configuration
│   ├── install-dev-tools.sh       # Development environment setup
│   ├── custom-install.sh          # Component-based custom installation
│   └── tmux-installer.sh           # (Deprecated - integrated into install-shell.sh)
├── docs/                           # Comprehensive documentation
│   ├── UBUNTU_DESKTOP.md          # Ubuntu desktop installation guide
│   ├── UBUNTU_SERVER.md           # Ubuntu server installation guide
│   └── MACOS.md                   # macOS installation guide
├── configs/                        # Shared configuration files
├── linux/                          # Linux-specific configurations
│   ├── install.sh                 # DRY Linux desktop orchestrator
│   ├── .config/                   # Application configuration files
│   └── .local/                    # User scripts and binaries
├── macos/                          # macOS-specific configurations
│   ├── install.sh                 # DRY macOS orchestrator
│   └── iterm/                     # iTerm2 configurations
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
- **Core Tools**: Git (with sensible defaults), comprehensive multi-OS support
- **Languages**: Python (pyenv, pipx, poetry, pipenv), Node.js (yarn, pnpm), Rust, Go
- **Containers**: Docker with compose plugins, user group management
- **Cloud Tools**: AWS CLI v2, kubectl, Terraform (HashiCorp official repos)
- **Editors**: Neovim (AppImage for latest), VS Code (official repos)
- **Databases**: PostgreSQL, MySQL, Redis clients across all platforms
- **Interactive Mode**: Menu-driven selection or --all flag for batch installation

#### Shell Environment (`install-shell.sh`)
- **Shell**: Zsh with Oh My Zsh framework (idempotent installation/updates)
- **Theme**: Powerlevel10k with embedded configuration
- **Plugins**: autosuggestions, syntax-highlighting, completions, fzf-tab (auto-updating)
- **Tools**: FZF, Z directory jumper, ripgrep, bat, eza, modern CLI tools
- **Terminal**: Kitty with Tokyo Night Moon theme
- **Multiplexer**: Tmux with Tokyo Night Moon theme (matching Kitty)
- **Editor**: Neovim with LazyVim configuration
- **Configuration**: Embedded .zshrc with comprehensive DevOps aliases and functions
- **Fonts**: Nerd Fonts support with automatic installation

#### Server-Specific Features (`ubuntu-server-setup.sh`)
- **Security**: UFW firewall, fail2ban with detailed SSH protection, comprehensive configuration
- **Monitoring**: htop, iotop, nethogs, system stats, modern CLI tools
- **Maintenance**: Automated update scripts with logging, system maintenance cron jobs
- **Enhanced Integration**: Calls specialized installers for shell, tmux, vim with server-appropriate defaults
- **Minimal GUI**: No desktop environment components, optimized for server workflows

#### Tmux Environment (now part of `install-shell.sh`)
- **Comprehensive Setup**: Enhanced tmux with extensive OS support and configuration
- **Plugin Manager**: TPM (Tmux Plugin Manager) with automatic plugin installation
- **Theme**: Tokyo Night Moon (consistent with Kitty terminal)
- **Key Bindings**: Vim-style navigation with Ctrl-a prefix
- **Mouse Support**: Full mouse integration with clipboard support
- **Session Management**: Persistent sessions with tmux-resurrect and tmux-continuum

#### Vim Environment (`vim-installer.sh`)
- **Modern Setup**: vim-plug plugin manager with curated DevOps-focused plugins
- **DevOps Configuration**: YAML, JSON, Python, Shell script optimizations with proper indentation
- **Practice Resources**: Interactive practice file and comprehensive cheat sheet
- **Plugin Integration**: NERDTree, CtrlP, GitGutter, Airline, Commentary, and more
- **Beginner Friendly**: Extensive documentation and helpful shortcuts embedded in configuration
- **Cross-Platform**: Comprehensive OS support with intelligent plugin installation

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