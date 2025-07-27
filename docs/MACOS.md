# macOS Installation Guide

This guide covers the complete setup of dotfiles for macOS development environments.

## Prerequisites

- macOS 11.0 (Big Sur) or newer
- Internet connection
- Administrator privileges
- Xcode Command Line Tools (installed automatically)

## Quick Installation

### One-line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/bootstrap.sh | bash
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dotfiles.git ~/Work/.dotfiles
cd ~/Work/.dotfiles
```

2. Run the bootstrap script:
```bash
chmod +x ./bootstrap.sh
./bootstrap.sh
```

3. Select option `1) Full Installation` from the menu

## What Gets Installed

### System Tools
- **Xcode Command Line Tools**: Development essentials
- **Homebrew**: Package manager for macOS
- **mas**: Mac App Store command line interface

### Core Utilities
Modern replacements for built-in tools:
- **GNU Core Utilities**: Better versions of common commands
- **ripgrep**: Fast text search
- **fd**: Fast file finder
- **bat**: Cat with syntax highlighting
- **eza**: Modern ls replacement
- **fzf**: Fuzzy finder
- **zoxide**: Smart cd replacement
- **tree**: Directory tree visualization
- **htop**: Better process monitor
- **ncdu**: Disk usage analyzer

### Development Environment

#### Shell & Terminal
- **Zsh** with Oh My Zsh framework
- **Powerlevel10k** theme
- **iTerm2**: Advanced terminal emulator
- **Tmux**: Terminal multiplexer
- **Starship**: Cross-shell prompt (alternative)

#### Programming Languages
- **Python 3.11** with pyenv, pipx, pipenv
- **Node.js** with npm, yarn, pnpm
- **Go**: Google's programming language
- **Rust**: Systems programming language (via rustup)

#### Development Tools
- **Git** with GitHub CLI
- **Neovim**: Modern Vim
- **Visual Studio Code**: Popular code editor
- **Docker Desktop**: Container platform
- **PostgreSQL, MySQL, Redis**: Database systems

#### Cloud & DevOps
- **AWS CLI**: Amazon Web Services
- **kubectl**: Kubernetes CLI
- **Terraform**: Infrastructure as code
- **Helm**: Kubernetes package manager

### GUI Applications

#### Browsers
- **Google Chrome**: Web browser
- **Firefox**: Alternative browser

#### Productivity
- **Rectangle**: Window management
- **Alfred**: Spotlight replacement and automation
- **Raycast**: Modern launcher and productivity tool
- **Obsidian**: Knowledge management
- **Notion**: All-in-one workspace

#### Communication
- **Slack**: Team communication
- **Discord**: Gaming and community chat
- **Zoom**: Video conferencing

#### Utilities
- **The Unarchiver**: Archive extraction
- **AppCleaner**: Application removal
- **Stats**: System monitor in menu bar
- **VLC**: Media player
- **Spotify**: Music streaming

### Fonts
- **Nerd Fonts**: Programming fonts with icons
  - FiraCode Nerd Font
  - JetBrains Mono Nerd Font
  - Hack Nerd Font
  - Meslo LG Nerd Font

## Installation Options

The bootstrap script offers several installation modes:

### 1. Full Installation (Recommended)
Installs everything listed above for a complete development setup.

### 2. Essential Tools Only
Just the core utilities and shell environment without GUI apps.

### 3. Development Tools Only
Programming languages, development tools, and databases.

### 4. GUI Applications Only
Just the GUI applications without development tools.

### 5. Shell Configuration Only
Terminal setup with Zsh, tmux, and productivity tools.

### 6. macOS Preferences Only
System preference configurations without installing software.

## Configuration Details

### Shell Environment

#### Zsh Configuration
- **Oh My Zsh** framework with useful plugins
- **Powerlevel10k** theme for beautiful, informative prompts
- **Plugins**: autosuggestions, syntax-highlighting, completions, fzf-tab
- **Custom aliases** for productivity
- **Environment variables** for development

#### Tmux Setup
- **Prefix key**: Ctrl-a (more ergonomic than Ctrl-b)
- **Mouse support** for easy pane management
- **Plugin manager** with useful plugins
- **Session management** with resurrection
- **Copy-paste integration** with system clipboard

### macOS System Preferences

The script can configure various macOS settings:
- Show hidden files in Finder
- Enable path and status bars in Finder
- Disable file extension warnings
- Expand save/print dialogs by default
- Configure hot corners
- Speed up animations
- Improve font rendering

### Development Environment

#### Python Setup
- **pyenv**: Python version management
- **pipx**: Global package installation
- **pipenv**: Project virtual environments
- **Common tools**: black, flake8, mypy, poetry

#### Node.js Setup
- **Latest LTS version** via Homebrew
- **Global packages**: TypeScript, ESLint, Prettier
- **Package managers**: npm, yarn, pnpm

#### Git Configuration
- **Global settings**: User name, email, default branch
- **GitHub CLI**: For repository management
- **Git LFS**: Large file support

## Post-Installation Steps

### 1. Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Set up GitHub CLI
```bash
gh auth login
```

### 3. Configure Powerlevel10k
```bash
p10k configure
```
Follow the interactive setup to customize your prompt.

### 4. Install Tmux Plugins
Open tmux and press `Ctrl-a + I` (prefix + I) to install plugins.

### 5. Configure iTerm2
- Import color scheme from dotfiles
- Set font to a Nerd Font (e.g., "JetBrainsMono Nerd Font")
- Configure key mappings

### 6. Set up VS Code
Install recommended extensions:
```bash
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension rust-lang.rust-analyzer
code --install-extension bradlc.vscode-tailwindcss
```

### 7. Configure Dock and Menu Bar
- Remove unused applications from Dock
- Add frequently used applications
- Configure menu bar apps (Stats, etc.)

## Customization

### Personal Configuration Files

Create local configuration files that won't be overwritten:

1. **Zsh local config** (`~/.zshrc.local`):
```bash
# Personal aliases
alias work="cd ~/Work"
alias personal="cd ~/Personal"

# Environment variables
export EDITOR="code"
export BROWSER="open -a 'Google Chrome'"
```

2. **Git local config** (`~/.gitconfig.local`):
```bash
[user]
    name = Your Name
    email = your.email@example.com

[github]
    user = your-github-username
```

3. **Tmux local config** (`~/.tmux.conf.local`):
```bash
# Personal tmux settings
set -g status-position top
```

### Development Workflow

#### Python Projects
```bash
cd ~/Work/my-project
pyenv local 3.11.0
pipenv install --python $(pyenv which python)
pipenv install requests flask
pipenv shell
```

#### Node.js Projects
```bash
cd ~/Work/my-project
npm init
npm install express
# or
yarn init
yarn add express
```

#### Docker Projects
```bash
# Start Docker Desktop
open -a Docker

# Use Docker
docker run hello-world
docker-compose up
```

## macOS-Specific Tips

### Keyboard Shortcuts
- **Spotlight**: Cmd+Space (or use Alfred/Raycast)
- **App Switcher**: Cmd+Tab
- **Window Management**: Use Rectangle for tiling
- **Terminal**: Cmd+T for new tab, Cmd+D for split pane

### System Maintenance
```bash
# Update Homebrew packages
brew update && brew upgrade

# Clean up old versions
brew cleanup

# Update Mac App Store apps
mas upgrade

# Check system health
brew doctor
```

### File Management
```bash
# Show/hide hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder

# Quick Look from terminal
qlmanage -p filename
```

## Troubleshooting

### Common Issues

1. **Homebrew installation fails**
   ```bash
   # Check Xcode Command Line Tools
   xcode-select --install
   
   # Reset Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   ```

2. **Permission issues**
   ```bash
   # Fix Homebrew permissions
   sudo chown -R $(whoami) $(brew --prefix)/*
   ```

3. **Shell not changing to Zsh**
   ```bash
   # Check available shells
   cat /etc/shells
   
   # Change shell
   chsh -s $(which zsh)
   ```

4. **Font issues in terminal**
   - Install Nerd Fonts via the script
   - Set terminal font to a Nerd Font
   - Restart terminal application

### Performance Issues

1. **Slow shell startup**
   ```bash
   # Profile shell startup
   zsh -xvs
   
   # Check plugin loading times
   time zsh -i -c exit
   ```

2. **High memory usage**
   - Check Activity Monitor
   - Disable unnecessary startup items
   - Consider lighter alternatives for resource-heavy apps

### Log Files
- Installation log: `/tmp/dotfiles-bootstrap-[timestamp].log`
- Homebrew logs: `~/Library/Logs/Homebrew/`
- System logs: Console app or `log show --last 1h`

## Advanced Configuration

### Custom Homebrew Formulas
Create a personal tap for custom formulas:
```bash
brew tap your-username/homebrew-tap
brew install your-username/tap/your-formula
```

### Development Environment Isolation
Use tools like:
- **pyenv** for Python versions
- **nvm** for Node.js versions
- **rbenv** for Ruby versions
- **Docker** for complete environment isolation

### Automation with Shortcuts
Create macOS Shortcuts for common tasks:
- Open development environment
- Start/stop services
- Deploy applications

## Production Workflow

### Code Signing and Notarization
For distributing macOS applications:
```bash
# Sign application
codesign --sign "Developer ID Application: Your Name" MyApp.app

# Notarize application
xcrun notarytool submit MyApp.zip --keychain-profile "notarytool-password"
```

### CI/CD Integration
Use GitHub Actions or other CI/CD tools with:
- macOS runners for native builds
- Homebrew for dependency management
- Automated testing and deployment

## Support

For macOS-specific issues:
1. Check macOS version compatibility
2. Review Homebrew installation
3. Verify Xcode Command Line Tools
4. Check system permissions
5. Consult the main repository documentation
6. Use `brew doctor` for Homebrew issues