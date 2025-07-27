# Ubuntu Desktop Installation Guide

This guide covers the installation and configuration of dotfiles for Ubuntu Desktop environments.

## Prerequisites

- Ubuntu 20.04 LTS or newer
- Internet connection
- User account with sudo privileges
- Git installed

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

3. Select option `1) Full Installation (Desktop with GUI)` from the menu

## What Gets Installed

### Base System
- Essential development tools (build-essential, git, curl, wget)
- Modern CLI utilities (ripgrep, fd, bat, fzf, htop, ncdu)
- System monitoring tools (htop, btop, iotop)
- Network utilities (net-tools, dnsutils, traceroute)

### Shell Environment
- **Zsh** with Oh My Zsh framework
- **Powerlevel10k** theme for beautiful prompts
- **Plugins**: autosuggestions, syntax-highlighting, completions
- **Tmux** with custom configuration and plugin manager
- **FZF** for fuzzy finding

### Development Tools
- **Python** ecosystem (pyenv, pipx, pipenv, common packages)
- **Node.js** with npm, yarn, and pnpm
- **Rust** toolchain with cargo
- **Go** programming language
- **Docker** with docker-compose
- **Git** with custom configuration
- **Neovim** with modern configuration

### Window Managers (Optional)
Choose between:
- **i3-gaps**: Tiling window manager with polybar, rofi, dunst
- **Hyprland**: Modern Wayland compositor with waybar, wofi

### GUI Applications
- **Kitty**: GPU-accelerated terminal emulator
- **Thunar**: File manager with plugins
- **VS Code**: Optional code editor
- **Various utilities**: screenshot tools, clipboard managers, etc.

### Fonts
- Nerd Fonts collection (FiraCode, JetBrainsMono, Hack, Meslo)
- Proper font cache configuration

## Configuration Details

### i3 Window Manager Setup

If you choose i3, you get:
- **i3-gaps**: Tiling window manager with gaps
- **Polybar**: Status bar with system information
- **Rofi**: Application launcher and switcher
- **Dunst**: Notification daemon
- **Picom**: Compositor for transparency and effects
- **Custom keybindings** for productivity

Key bindings (Mod = Super key):
- `Mod + Enter`: Open terminal
- `Mod + d`: Application launcher (rofi)
- `Mod + Shift + q`: Close window
- `Mod + 1-9`: Switch workspaces
- `Mod + Shift + 1-9`: Move window to workspace

### Hyprland Setup

If you choose Hyprland, you get:
- **Hyprland**: Wayland compositor with animations
- **Waybar**: Wayland-compatible status bar
- **Wofi**: Wayland application launcher
- **Grim/Slurp**: Screenshot utilities for Wayland
- **Custom animations** and workspace management

### Shell Configuration

The Zsh setup includes:
- **Custom aliases** for productivity
- **Environment variables** for development
- **Functions** for common tasks
- **History optimization** with search
- **Auto-completion** enhancements

## Post-Installation Steps

### 1. Configure Git (Required)
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Set up Powerlevel10k
```bash
p10k configure
```
Follow the interactive setup to customize your prompt.

### 3. Install Tmux Plugins
Open tmux and press `Ctrl-a + I` (prefix + I) to install plugins.

### 4. Window Manager Setup
- **For i3**: Log out and select i3 from the login screen
- **For Hyprland**: Log out and select Hyprland from the login screen

### 5. Configure Your IDE
If you installed VS Code, install recommended extensions:
```bash
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension rust-lang.rust-analyzer
```

## Customization

### Adding Custom Configurations

1. Personal aliases in `~/.aliases.local`:
```bash
# Custom aliases
alias myproject="cd ~/Projects/my-important-project"
alias server="ssh user@myserver.com"
```

2. Environment variables in `~/.exports.local`:
```bash
# Custom environment variables
export MY_API_KEY="your-api-key"
export CUSTOM_PATH="/opt/my-tool/bin"
```

3. Custom functions in `~/.functions.local`:
```bash
# Custom functions
myfunction() {
    echo "This is my custom function"
}
```

### Modifying Window Manager Configs

- **i3 config**: `~/.config/i3/config`
- **Polybar config**: `~/.config/polybar/config.ini`
- **Hyprland config**: `~/.config/hypr/hyprland.conf`

## Troubleshooting

### Common Issues

1. **Fonts not displaying correctly**
   ```bash
   fc-cache -fv
   ```

2. **i3 not starting**
   - Check `.xsession-errors` in your home directory
   - Ensure display manager is configured correctly

3. **Tmux plugins not working**
   - Press `prefix + I` to install plugins
   - Check `~/.tmux.conf` for correct TPM path

4. **Zsh not the default shell**
   ```bash
   chsh -s $(which zsh)
   ```
   Log out and back in.

### Log Files

Check these locations for troubleshooting:
- Installation log: `/tmp/dotfiles-bootstrap-[timestamp].log`
- i3 log: `~/.local/share/xorg/Xorg.0.log`
- System log: `journalctl -u display-manager`

## Development Workflow

### Python Projects
```bash
cd my-project
pyenv local 3.11.0
pipenv install --python $(pyenv which python)
pipenv install requests pandas
pipenv shell
```

### Node.js Projects
```bash
cd my-project
npm init
npm install express
# or
yarn init
yarn add express
```

### Rust Projects
```bash
cargo new my-project
cd my-project
cargo run
```

## Updating

To update your dotfiles:
```bash
cd ~/Work/.dotfiles
git pull origin main
./bootstrap.sh
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review log files
3. Open an issue on the GitHub repository
4. Check the main README for additional information