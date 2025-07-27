# Dotfiles

A comprehensive, modular dotfiles repository for automated development environment setup across Ubuntu Desktop, Ubuntu Server, and macOS.

## Features

- **Multi-platform support**: Ubuntu Desktop, Ubuntu Server, macOS
- **Modular installation**: Choose only what you need
- **Automated setup**: One-command installation with interactive menu
- **Environment detection**: Automatically detects OS and environment type
- **Backup functionality**: Safely backs up existing configurations
- **Standalone server script**: Minimal setup for production servers
- **Development tools**: Modern toolchain for multiple languages
- **Shell configuration**: Zsh with Oh My Zsh, tmux, and productivity tools

## Quick Start

### Prerequisites

- Git
- Curl
- Internet connection
- sudo/admin privileges (for package installation)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dotfiles.git ~/Work/.dotfiles
cd ~/Work/.dotfiles
```

2. Make the bootstrap script executable:
```bash
chmod +x ./bootstrap.sh
```

3. Run the bootstrap script:
```bash
./bootstrap.sh
```

The script will:
- Detect your operating system and environment
- Present an interactive menu with installation options
- Guide you through the setup process

### Standalone Ubuntu Server Installation

For Ubuntu servers, use the standalone script for a minimal setup:

```bash
wget https://raw.githubusercontent.com/yourusername/dotfiles/main/ubuntu-server-setup.sh
chmod +x ubuntu-server-setup.sh
./ubuntu-server-setup.sh
```

This script includes:
- Essential system packages
- Security hardening (UFW, fail2ban)
- Development tools (Git, Python, Node.js)
- Shell enhancements (Zsh, tmux)
- Optional Docker installation
- System maintenance automation

## Installation Options

### 1. Full Installation (Desktop)
Includes everything needed for a complete development workstation:
- Window manager configurations (i3/Hyprland)
- GUI applications (Kitty, Rofi, etc.)
- All development tools
- Shell and terminal enhancements
- Fonts and themes

### 2. Server Installation
Minimal setup optimized for servers:
- Core utilities and monitoring tools
- Security configurations
- Shell enhancements
- Development basics
- No GUI components

### 3. Development Tools Only
Just the development environment:
- Programming languages (Python, Node.js, Rust, Go)
- Version managers (pyenv, nvm)
- Docker and container tools
- Cloud CLI tools (AWS, kubectl, Terraform)
- Code editors (Neovim, VS Code)

### 4. Shell Configuration Only
Terminal and shell setup:
- Zsh with Oh My Zsh
- Powerlevel10k theme
- Tmux with plugins
- Modern CLI tools (fzf, ripgrep, bat)
- Nerd Fonts

## Directory Structure

```
.dotfiles/
├── bootstrap.sh          # Main entry point with OS detection
├── ubuntu-server-setup.sh # Standalone server installation
├── scripts/              # Modular installation scripts
│   ├── install-dev-tools.sh
│   ├── install-shell.sh
│   └── custom-install.sh
├── configs/              # Shared configuration files
├── linux/                # Linux-specific configurations
│   ├── install.sh        # Main Linux setup
│   ├── .config/          # Application configs
│   └── .local/           # User scripts
├── macos/                # macOS-specific configurations
│   └── install.sh        # Homebrew-based setup
├── zsh/                  # Zsh configuration modules
│   ├── .zshrc           # Main config
│   ├── aliases.zsh      # Shell aliases
│   ├── exports.zsh      # Environment variables
│   └── functions.zsh    # Shell functions
└── git/                  # Git configuration
    └── .gitconfig       # Global git config
```

## Configuration Details

### Shell Environment

The setup includes a modular Zsh configuration with:
- **Oh My Zsh**: Framework for managing Zsh configuration
- **Plugins**: autosuggestions, syntax-highlighting, completions
- **Theme**: Powerlevel10k for a beautiful, informative prompt
- **Aliases**: Productivity shortcuts for common commands
- **Functions**: Custom shell functions for workflow optimization

### Development Environment

#### Python
- **pyenv**: Python version management
- **pipenv**: Virtual environment and dependency management
- **pipx**: Global Python application installation
- **Tools**: black, flake8, mypy, poetry

#### Node.js
- **nvm** or **system Node.js**: Version management
- **Package managers**: npm, yarn, pnpm
- **Global tools**: TypeScript, ESLint, Prettier

#### Other Languages
- **Rust**: Via rustup with cargo tools
- **Go**: Latest stable version
- **Docker**: Container development
- **Cloud tools**: AWS CLI, kubectl, Terraform

### Terminal & Editor

- **Tmux**: Terminal multiplexer with custom configuration
- **Neovim**: Modern Vim with LSP support
- **VS Code**: Optional GUI editor
- **Kitty**: GPU-accelerated terminal (Linux desktop)
- **Modern CLI tools**: ripgrep, fd, bat, exa, fzf

## Python Workflow

Here's how to use the Python setup effectively:

### Install & Manage Python Versions with pyenv

```bash
# Install a specific Python version
pyenv install 3.11.0
pyenv global 3.11.0

# Set version for a specific project
cd my-project
pyenv local 3.11.0
```

### Project Dependencies with pipenv

```bash
# Create virtual environment with pyenv's Python
pipenv install --python $(pyenv which python)

# Install project dependencies
pipenv install requests pandas

# Install dev dependencies
pipenv install --dev pytest black flake8

# Activate the virtual environment
pipenv shell

# Lock dependencies
pipenv lock
```

### Global Tools with pipx

```bash
# Install tools globally
pipx install black
pipx install httpie
pipx install youtube-dl

# List installed tools
pipx list

# Upgrade tools
pipx upgrade black
```

## Customization

### Adding Your Own Configurations

1. Fork this repository
2. Update personal information in:
   - `git/.gitconfig` (name, email)
   - `zsh/exports.zsh` (environment variables)
3. Add your custom scripts to `scripts/`
4. Commit and push your changes

### Extending the Setup

To add new tools or configurations:

1. Create a new script in `scripts/`
2. Add it to the appropriate installation menu
3. Update the documentation

## Troubleshooting

### Common Issues

1. **Permission denied errors**
   - Ensure you're not running as root
   - Check file permissions on scripts

2. **Package installation failures**
   - Update package lists: `sudo apt update`
   - Check internet connection
   - Review log files in `/tmp/`

3. **Shell not changing**
   - Log out and back in
   - Verify shell is in `/etc/shells`

### Logs

Installation logs are saved to:
- Bootstrap: `/tmp/dotfiles-bootstrap-[timestamp].log`
- Server setup: `/tmp/ubuntu-server-setup.log`

## Security Considerations

The server setup includes several security enhancements:
- UFW firewall configuration
- fail2ban for intrusion prevention
- SSH hardening options
- Automated security updates
- Minimal package installation

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Oh My Zsh community
- Tmux Plugin Manager developers
- Nerd Fonts project
- All the open source tool maintainers

---

For more detailed information about specific configurations, check the `docs/` directory or the inline documentation in each script.