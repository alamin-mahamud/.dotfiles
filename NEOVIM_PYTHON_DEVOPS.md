# Neovim Configuration for Python & DevOps

Your neovim-env.sh script has been enhanced with comprehensive support for Python development and DevOps tools.

## What's Been Added

### Python Development Support
- **Language Servers**: 
  - `pyright` - Microsoft's fast Python LSP
  - `python-lsp-server` - Alternative Python LSP with plugin support
  - `ruff-lsp` - Extremely fast Python linter
  - `pylsp-mypy` - Type checking support

- **Formatters & Linters**:
  - `black` - The uncompromising Python formatter
  - `isort` - Import sorting
  - `flake8` - Style guide enforcement
  - `pylint` - Code analysis
  - `mypy` - Static type checker
  - `ruff` - Fast Python linter

- **Debugging**:
  - `debugpy` - Python debugger protocol implementation
  - DAP (Debug Adapter Protocol) integration
  - Breakpoints, step through, variable inspection

- **Testing**:
  - `neotest-python` - Run pytest tests from Neovim
  - Virtual environment detection and selection

### DevOps Tools Support

- **Infrastructure as Code**:
  - Terraform LSP with auto-completion
  - HCL syntax highlighting
  - Terraform format/validate keybindings

- **Configuration Management**:
  - Ansible language server
  - YAML schema validation
  - Ansible-vim plugin for playbook support

- **Containerization**:
  - Docker language server
  - Dockerfile syntax highlighting
  - Docker Compose support

- **Kubernetes**:
  - YAML companion for K8s manifests
  - Schema validation for K8s resources
  - kubectl integration keybindings

- **Cloud Native Development**:
  - Go language server (gopls)
  - Go debugging support (delve)
  - REST client for API testing

### Enhanced LazyVim Configuration

- **File Type Specific Settings**:
  - Python: 4 spaces (PEP8 compliant)
  - YAML/JSON: 2 spaces
  - Terraform/HCL: 2 spaces

- **Custom Keybindings**:
  - Python execution and debugging
  - Terraform workflow commands
  - Docker/K8s operations
  - Git operations

### Tools Installation

The script will automatically install:
- All Python development tools via pip3
- Node.js based language servers via npm
- System tools via package manager (apt/brew/pacman)
- Terraform Language Server from GitHub releases

## Usage

Run the installer:
```bash
cd ~/.dotfiles
./scripts/components/neovim-env.sh
```

Or via bootstrap:
```bash
./bootstrap.sh
# Select option 3: Neovim + LazyVim + Keyboard Setup
```

## Key Shortcuts

### Python Development
- `<leader>pr` - Run current Python file
- `<leader>pv` - Select Python virtual environment
- `<leader>pd` - Debug Python method
- `<leader>pf` - Debug Python class
- `<F5>` - Start/Continue debugging
- `<F10>` - Step over
- `<F11>` - Step into
- `<leader>db` - Toggle breakpoint

### DevOps Tools
- `<leader>ti` - Terraform init
- `<leader>tp` - Terraform plan
- `<leader>tf` - Terraform format
- `<leader>tv` - Terraform validate
- `<leader>dk` - Apply K8s manifest
- `<leader>dd` - Docker build
- `<leader>ys` - Select YAML schema
- `<leader>rr` - Run REST request

### Git Integration
- `<leader>gp` - Git push
- `<leader>gpu` - Git pull
- `<leader>gc` - Git commit

## Plugin Files Created

The installer creates these plugin configuration files:
- `~/.config/nvim/lua/plugins/python.lua` - Python development plugins
- `~/.config/nvim/lua/plugins/devops.lua` - DevOps tools plugins
- `~/.config/nvim/lua/plugins/productivity.lua` - Productivity enhancements
- `~/.config/nvim/lua/plugins/dap-config.lua` - Debugger configuration

## Requirements

- Python 3 with pip3
- Node.js with npm (for some language servers)
- Git
- Internet connection for downloading tools

## Post-Installation

1. Open Neovim: `nvim`
2. LazyVim will automatically install all plugins
3. Run `:Mason` to verify language servers
4. Run `:checkhealth` to verify setup
5. Configure Python interpreter: `:VenvSelect`

## Troubleshooting

If language servers aren't working:
1. Run `:LspInfo` to check LSP status
2. Run `:Mason` to manually install servers
3. Check `:checkhealth lsp` for issues

For Python issues:
1. Ensure Python 3 is installed
2. Check pip3 is available
3. Verify virtual environment is activated
4. Run `:checkhealth provider.python`

## Next Steps

1. Install a Nerd Font for better icons
2. Configure your Python virtual environments
3. Set up your cloud credentials for terraform/kubectl
4. Customize keybindings in `~/.config/nvim/lua/config/keymaps.lua`