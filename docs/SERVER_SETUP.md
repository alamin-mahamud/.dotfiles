# Server Setup Guide

## Quick Setup

```bash
# Ubuntu 24.04 Server (minimal)
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/ubuntu-server-setup.sh | bash

# Shell environment only
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/shell-env.sh | bash

# DevOps tools
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/devops-tools.sh | bash

# Programming languages
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/components/languages.sh | bash
```

## Components

- **Shell Environment**: Zsh + Tmux + modern CLI tools
- **DevOps Tools**: Docker, Terraform/Tofu, Kubernetes CLI
- **Languages**: Python (pyenv), Node.js (nvm), Go (latest)
- **Security**: UFW firewall, fail2ban, SSH hardening

## Backup Policy

All existing configurations backed up to `/tmp/dotfiles-backup-$(date)`