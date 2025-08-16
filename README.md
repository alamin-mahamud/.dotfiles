# DevOps-Focused Dotfiles

Standalone scripts for DevOps professionals. Optimized for Linux servers with Zsh + Tmux + LazyVim + Kitty.

## Quick Setup

### DevOps Shell Environment
```bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/devops-shell.sh | bash
```
Installs: Zsh + Oh My Zsh + Powerlevel10k + Tmux + Kitty + modern CLI tools

### DevOps Tools
```bash  
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/devops-tools.sh | bash
```
Installs: Docker + Kubernetes + Terraform + AWS CLI + Python + Node.js + GitHub CLI

### Complete Interactive Setup
```bash
git clone https://github.com/alamin-mahamud/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && chmod +x bootstrap.sh && ./bootstrap.sh
```

## What's Included

**Shell Environment:**
- Zsh with Oh My Zsh framework
- Powerlevel10k theme
- Essential plugins (autosuggestions, syntax-highlighting)
- Tmux with Tokyo Night Moon theme
- Kitty terminal with optimized config
- Modern CLI tools: ripgrep, fd, bat, eza, fzf, jq

**DevOps Tools:**
- Docker & Docker Compose
- Kubernetes (kubectl, helm)  
- Terraform
- AWS CLI v2
- Python (pip, pipenv, poetry, ansible)
- Node.js (npm, yarn, pnpm)
- GitHub CLI

**Key Aliases:**
```bash
# Docker: d, dc, dps, dexec, dlogs, dclean
# Kubernetes: k, kgp, kgs, kgd, kdesc, klogs, kexec  
# Git: g, gs, ga, gc, gp, gl, glog, gd
# Modern tools: ll/la/ls (eza), cat (bat), grep (rg), find (fd)
# Tmux: t, ta, ts, tl
```

## Post-Setup

1. Restart shell: `exec zsh`
2. Configure Powerlevel10k: `p10k configure`  
3. Install Tmux plugins: `tmux` → `Ctrl-a + I`
4. Setup Neovim: `nvim` (LazyVim auto-installs)
5. Configure tools: `aws configure`, `gh auth login`

## Requirements

- Ubuntu 20.04+ or similar Linux distribution
- Sudo privileges
- Internet connection

Built for DevOps engineers who live in the terminal.