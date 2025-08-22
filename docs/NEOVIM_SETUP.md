# Neovim Setup

## Quick Install
```bash
./scripts/components/neovim-env.sh
```

## Features
- **LazyVim**: Modern Neovim configuration
- **Python**: LSP, debugging, testing (pyright, ruff, debugpy)
- **DevOps**: Terraform, Docker, Kubernetes, Ansible support
- **Go**: Full Go development environment
- **REST Client**: API testing with kulala.nvim (compatible with nvim 0.9.5)

## Key Bindings
### Python
- `<leader>pr` - Run Python file
- `<leader>pv` - Select virtual environment
- `<F5>` - Debug start/continue

### DevOps
- `<leader>ti` - Terraform init
- `<leader>tp` - Terraform plan
- `<leader>rr` - Run REST request
- `<leader>ys` - YAML schema

## Post-Install
1. Open `nvim` - plugins auto-install
2. Run `:checkhealth` to verify setup
3. Use `:Mason` for language servers