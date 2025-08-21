# .dotfiles

Modular dotfiles for DevOps professionals. Pure shell-based architecture with enhanced logging, planning, and modular components.

## Quick Install

```bash
# Clone
git clone https://github.com/alamin-mahamud/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Interactive installer with planning and progress tracking
./bootstrap.sh

# Component-specific installations
./scripts/components/shell-env.sh      # Shell environment only
./scripts/components/neovim-env.sh     # Neovim + LazyVim
./scripts/components/python-env.sh     # Python development environment
```

## Commands

### Main Scripts
```bash
./bootstrap.sh              # Interactive menu with component selection
./linux/install.sh          # Complete Linux desktop environment
./macos/install.sh           # Complete macOS development environment
```

### Component Installers (Modular)
```bash
./scripts/components/shell-env.sh      # Zsh + Tmux + CLI tools + Planning
./scripts/components/neovim-env.sh     # Neovim + LazyVim + Keyboard Setup
./scripts/components/python-env.sh     # Python development environment
```

### Component Installers
```bash
./scripts/install-shell.sh                    # Zsh + Tmux + CLI tools
./scripts/install-desktop-terminal.sh         # Fonts + Kitty terminal
./scripts/vim-installer.sh                    # Vim + plugins
./scripts/install-dev-tools.sh                # Dev tools (Git, Docker, Node, Python, etc.)
./scripts/components/shell-env.sh             # Shell environment only
./scripts/components/python-env.sh            # Python environment
./scripts/desktop/keyboard-setup.sh           # Caps Lock → Escape
```

### One-liner Components
```bash
# Shell environment (server-friendly)
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-shell.sh | bash

# Desktop terminal setup
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-desktop-terminal.sh | bash

# Vim configuration
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/vim-installer.sh | bash

# All dev tools
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-dev-tools.sh | bash

# Shell environment only
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env.sh | bash
```

### Dev Tools Options
```bash
./scripts/install-dev-tools.sh --all           # Install everything
./scripts/install-dev-tools.sh --docker        # Docker only
./scripts/install-dev-tools.sh --node          # Node.js only
./scripts/install-dev-tools.sh --python        # Python only
./scripts/install-dev-tools.sh --rust          # Rust only
./scripts/install-dev-tools.sh --go            # Go only
```

## What Gets Installed

**Shell Environment**: 
- Zsh + Oh My Zsh + Powerlevel10k theme
- Tmux with Tokyo Night theme and plugin manager
- Modern CLI tools: fzf, ripgrep, fd, bat, eza, jq

**Neovim Environment**:
- Latest Neovim with LazyVim configuration framework
- Language servers for multiple languages
- Formatters, linters, and development tools
- Custom keybindings and configurations
- Integrated keyboard setup (Caps Lock → Escape)

**Development Tools**:
- Python environment (pyenv + poetry + pipx)
- Git configuration with enhanced settings
- Build tools and dependencies

**Desktop Features** (Linux/macOS):
- Terminal emulator setup (Kitty/Alacritty)
- System-specific optimizations
- Keyboard optimizations (integrated with Neovim setup)

## Features

✅ **Enhanced Logging**: Detailed installation plans and execution summaries  
✅ **Progress Tracking**: Step-by-step progress with timing and status  
✅ **Modular Architecture**: Install only what you need  
✅ **Idempotent Scripts**: Safe to run multiple times  
✅ **Cross-Platform**: Linux, macOS, and server support  
✅ **v1.0.0 Compatible**: Preserves existing configurations  

## Architecture Highlights

- **DRY Principles**: No code duplication, shared libraries
- **Planning Phase**: Shows what will be changed before execution
- **Execution Tracking**: Real-time progress with detailed logging
- **Summary Reports**: Comprehensive installation summaries
- **Modular Components**: Mix and match components as needed

## Usage

```bash
# Interactive installation with planning
./bootstrap.sh

# Direct component installation
./scripts/components/shell-env.sh      # Shows plan, then installs
./scripts/components/neovim-env.sh     # Shows plan, then installs

# Enable debug logging for detailed execution info
DEBUG=1 ./bootstrap.sh
```

All scripts are idempotent - safe to run multiple times.  
Repository expects to be at `~/.dotfiles`.  
Configurations are symlinked from the repository.

## Requirements

- Git
- Curl  
- Internet connection
- Admin/sudo access (for package installation)