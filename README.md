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

### Direct Component Installation
```bash
DOTFILES_AUTO_CONFIRM=1 ./scripts/components/shell-env.sh   # Shell (Zsh + Tmux + CLI tools)
DOTFILES_AUTO_CONFIRM=1 ./scripts/components/neovim-env.sh  # Neovim + LazyVim
DOTFILES_AUTO_CONFIRM=1 ./scripts/components/python-env.sh  # Python environment
```

## What's Installed

**Shell Environment**
- Zsh + Oh My Zsh + Powerlevel10k
- Tmux with Tokyo Night theme
- Modern CLI: fzf, ripgrep, fd, bat, eza

**Development Tools**
- Neovim with LazyVim
- Python (pyenv + poetry + pipx)
- Language servers and formatters

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

All scripts tested on Ubuntu 22.04+ and macOS 12+.