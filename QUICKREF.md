# Quick Reference

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/dotfiles/main/install.sh | bash
```

## Essential Commands

### TMUX (Prefix: Ctrl-a)
```
|         Split vertical
-         Split horizontal  
h,j,k,l   Navigate panes
H,J,K,L   Resize panes
r         Reload config
S         Sync panes
c         New window
n/p       Next/previous window
d         Detach session
```

### ZSH Aliases
```
# Kubernetes
k         kubectl
kx        kubectx
kn        kubens
kpods     kubectl get pods
klogs     kubectl logs -f
kexec     kubectl exec -it

# Docker
d         docker
dc        docker-compose

# Git
g         git
gs        git status
gp        git pull
gc        git commit
gl        git log --oneline --graph
gd        git diff

# System
ll        ls -alh
ta        tmux attach || tmux new
mkcd      mkdir && cd
myip      curl -s ifconfig.me
ports     netstat -tulanp
```

### VIM Essentials
```
<Space>   Leader key
<Leader>w Save file
<Leader>q Quit
<Leader>v Vertical split
<Leader>s Horizontal split
Ctrl-h/j/k/l Navigate splits
```

## Structure
```
~/.dotfiles/
├── .zshrc          # Shell config
├── .tmux.conf      # Tmux config
├── .vimrc          # Vim config
├── .gitconfig      # Git config
├── install.sh      # Installer
└── README.md       # Documentation
```

## Customization
- `~/.zshrc.local` - Local ZSH overrides
- `~/.gitconfig.local` - Local Git config

## Troubleshooting
```bash
# Reload configs
source ~/.zshrc
tmux source ~/.tmux.conf

# Check symlinks
ls -la ~ | grep "\.dotfiles"

# Reinstall
cd ~/.dotfiles && ./install.sh
```