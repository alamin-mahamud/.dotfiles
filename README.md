# Dotfiles

Modern, modular dotfiles for DevOps professionals. Idempotent scripts with progress tracking.

## Quick Start

```bash
git clone https://github.com/alamin-mahamud/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

## Installation Options

### Interactive Menu
```bash
./bootstrap.sh  # Choose from menu
```

### Ubuntu 24.04 Server Setup
```bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/ubuntu-server-setup.sh | bash
```

### Direct Component Installation
```bash
./scripts/components/shell-env.sh    # Shell (Zsh + Tmux + CLI tools)
./scripts/components/neovim-env.sh   # Neovim + LazyVim
./scripts/components/devops-tools.sh # Docker, Terraform, Kubernetes
./scripts/components/languages.sh   # Python, Node.js, Go
```

## What's Installed

**Shell Environment**
- Zsh + Oh My Zsh + Powerlevel10k
- Tmux with Tokyo Night theme
- Modern CLI: fzf, ripgrep, fd, bat, eza

**Development Tools**
- Neovim with LazyVim (Python, Go, DevOps support)
- Python (pyenv + poetry + pipx)
- Node.js (nvm + npm + yarn)
- Go (latest + development tools)

**DevOps Tools**
- Docker + Docker Compose + Kubernetes CLI
- Terraform + OpenTofu + Terragrunt
- Cloud CLIs (AWS, Azure, GCP)
- Infrastructure as Code support

## Features

- ✅ Idempotent - safe to run multiple times
- ✅ Progress tracking with detailed logging
- ✅ Cross-platform (Linux/macOS/WSL)
- ✅ Modular - install only what you need
- ✅ Auto-recovery from failures

## System Requirements

- Git, curl
- Internet connection
- Sudo access (for packages)

## Debug Mode

```bash
DEBUG=1 ./bootstrap.sh  # Verbose output
```

All scripts tested on Ubuntu 24.04 LTS and macOS 14+.

## Documentation

- [Server Setup](docs/SERVER_SETUP.md) - Ubuntu server configuration
- [DevOps Tools](docs/DEVOPS_TOOLS.md) - Container and IaC tools
- [Languages](docs/LANGUAGES.md) - Programming language environments
- [Neovim Setup](docs/NEOVIM_SETUP.md) - Editor configuration