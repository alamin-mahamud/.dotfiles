# Minimal Dotfiles

Lightning-fast, idempotent dotfiles for DevOps engineers. Optimized for Ubuntu Server, Ubuntu Desktop, and macOS.

## Features

- **Ultra-Minimal**: ~40KB total size (vs typical 100MB+ dotfiles)
- **Idempotent**: Run safely multiple times without side effects
- **DevOps First**: Built-in k8s, Docker, Terraform workflows
- **Terminal Focused**: tmux + zsh + vim optimized for productivity
- **Cross-Platform**: Unified experience across Linux and macOS
- **Zero Dependencies**: No frameworks, just POSIX shell

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/dotfiles/main/install.sh | bash
```

Or clone and install:

```bash
git clone https://github.com/alamin-mahamud/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh
```

## What's Included

### Core Configurations

| File | Purpose | Size |
|------|---------|------|
| `.zshrc` | Shell with DevOps aliases | 2.5KB |
| `.tmux.conf` | Terminal multiplexer | 2.1KB |
| `.vimrc` | Editor configuration | 2.0KB |
| `.gitconfig` | Version control | 0.8KB |

### Key Bindings

#### TMUX (Prefix: `Ctrl-a`)
- `|` - Split vertical
- `-` - Split horizontal
- `h/j/k/l` - Navigate panes (vim-style)
- `H/J/K/L` - Resize panes
- `r` - Reload config
- `S` - Synchronize panes

#### ZSH Aliases
```bash
# Kubernetes
k         # kubectl
kx        # kubectx
kn        # kubens
kpods     # kubectl get pods
klogs     # kubectl logs -f
kexec     # kubectl exec -it

# Infrastructure
tf        # terraform
tg        # terragrunt
d         # docker
dc        # docker-compose

# Git
g         # git
gs        # git status
gl        # git log --oneline --graph
gp        # git pull
gc        # git commit
gd        # git diff

# Productivity
ta        # tmux attach || tmux new
mkcd      # mkdir && cd
extract   # Universal archive extractor
myip      # Show public IP
ports     # Show listening ports
```

## Installation Details

The installer:
1. Detects OS (Linux/macOS) and distribution
2. Installs core packages (git, vim, tmux, zsh)
3. Creates symlinks (backs up existing configs)
4. Sets zsh as default shell
5. Installs kubectl and helm for Kubernetes
6. Cleans up old backups (keeps last 3)

## Customization

Add local overrides without modifying core configs:

```bash
# Local ZSH customizations
~/.zshrc.local

# Machine-specific git config
git config --global --add include.path ~/.gitconfig.local
```

## Manual Setup

```bash
# Clone repository
git clone https://github.com/alamin-mahamud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run installation
./install.sh

# Reload shell
exec zsh
```

## Platform Notes

### Ubuntu Server
- Minimal package installation
- No GUI dependencies
- Optimized for remote SSH sessions

### Ubuntu Desktop
- Same as server with desktop integration
- Terminal-focused workflow

### macOS
- Homebrew auto-installation
- Native macOS keyboard support
- Unified Linux/macOS experience

## Philosophy

- **Simplicity**: If it's not essential, it's not included
- **Speed**: Sub-second shell startup
- **Portability**: Works everywhere with minimal dependencies
- **Maintainability**: Simple enough to understand and modify

## Requirements

- POSIX-compliant shell (bash/zsh)
- Git
- Internet connection (for package installation)
- sudo access (for package management)

## Troubleshooting

### Shell not changing
```bash
chsh -s $(which zsh)
# Then logout and login again
```

### Symlinks not working
```bash
# Check for broken links
find ~ -maxdepth 1 -type l -exec test ! -e {} \; -print

# Reinstall
cd ~/.dotfiles && ./install.sh
```

### Tmux key bindings not working
```bash
# Inside tmux
tmux source-file ~/.tmux.conf
```

## Contributing

Keep it minimal. PRs that add complexity without significant value will be declined.

## License

MIT - Use freely, modify as needed.