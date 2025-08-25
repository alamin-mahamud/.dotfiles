# 🚀 Warp Terminal + Superfile + Tmux Enhanced Workflow Guide

## Overview

Your dotfiles have been enhanced with a professional DevOps workflow that integrates Warp Terminal, tmux, and superfile for maximum productivity. This configuration provides:

- **Warp-optimized tmux** with Catppuccin Frappe theme
- **Superfile integration** for rapid file navigation
- **DevOps popup tools** for Docker, Kubernetes, and Git workflows
- **Intelligent session management** with automatic naming and restoration

## 🎨 Visual Theme

**Unified Catppuccin Frappe palette** across all tools:
- 🟢 Active pane border: `#a6e3a1` (green)
- 🟣 Popup borders: `#f4b8e4` (mauve) 
- 🟡 Copy mode highlight: `#f9e2af` (yellow)
- ⚫ Inactive borders: `#4c566a` (dark grey)

## ⌨️  New Keybindings

### Tmux Productivity Popups (Prefix: `Ctrl-a`)

| Key | Command | Description |
|-----|---------|-------------|
| `f` | `superfile` | 📁 Modern file manager with tree view |
| `g` | `lazygit` | 🌿 Interactive Git client |
| `d` | `lazydocker` | 🐳 Docker containers & images dashboard |
| `k` | `k9s` | ☸️  Kubernetes cluster manager |
| `p` | `htop` | 📊 System process monitor |

### Enhanced Navigation

| Key | Command | Description |
|-----|---------|-------------|
| `F` | `tmux-thumbs` | 👆 Quick copy paths/URLs from terminal |
| `Alt+arrows` | Pane navigation | Switch panes without prefix |
| `Ctrl-a + h/j/k/l` | Vim-style panes | Vim-like pane navigation |

### Smart Clipboard Integration

- ✅ **Warp Terminal Detection**: Automatic clipboard sharing
- ✅ **System Integration**: `set-clipboard on` for seamless copy/paste
- ✅ **Vi Mode**: `v` to select, `y` to copy in tmux copy mode

## 🔧 Warp-Specific Optimizations

When running in Warp Terminal (`$TERM_PROGRAM = "WarpTerminal"`):

```bash
# Enhanced color support
set -g default-terminal "xterm-256color"
set -as terminal-features ',*:RGB'

# Allow Warp-specific features
set -g allow-passthrough on
set -g set-clipboard on
```

## 📂 Superfile Integration

**Quick Access**: `Ctrl-a f` opens superfile in an 80% popup window

**Features**:
- 🎯 Fast directory navigation
- 🔍 Built-in file search
- 📋 Drag & drop file operations
- ⚡ Vim-like keybindings

## 🔄 Enhanced Session Management

### Auto-Naming
- **Git repos**: Window automatically named after repository
- **Directory-based**: Falls back to current directory name
- **Manual override**: Set custom names that persist

### Session Restoration
- **Auto-save**: Every 10 seconds (faster than default)
- **Neovim sessions**: Automatically restored with cursor position
- **Persistent history**: 20,000 lines scrollback buffer

## 🐳 DevOps Workflow Examples

### Quick Docker Management
```bash
Ctrl-a d  # Opens lazydocker popup
# - View all containers
# - Check logs in real-time  
# - Start/stop containers
# - Image management
```

### Kubernetes Operations
```bash
Ctrl-a k  # Opens k9s popup
# - Pod management across namespaces
# - Real-time resource monitoring
# - Log streaming
# - Port forwarding setup
```

### Git Workflow
```bash
Ctrl-a g  # Opens lazygit popup
# - Stage changes interactively
# - Create commits with ease
# - Branch management
# - Push/pull operations
```

## 🎯 Shell Aliases (Enhanced)

### DevOps Shortcuts
```bash
# Quick tools
alias lg='lazygit'      # Git UI
alias ld='lazydocker'   # Docker UI  
alias kd='k9s'          # Kubernetes UI
alias spf='superfile'   # File manager

# Tmux session management
alias tms='tmux new-session -s'    # Create session
alias tma='tmux attach-session -t' # Attach session
alias tml='tmux list-sessions'     # List sessions
```

### Modern CLI Tools
```bash
alias ls='eza'          # Better ls with icons
alias cat='bat'         # Syntax-highlighted cat
alias grep='rg'         # Faster grep (ripgrep)
alias find='fd'         # Faster find
```

## ⚡ Performance Optimizations

### Warp Terminal
- ✅ **Zero escape time**: `set -sg escape-time 0`
- ✅ **True color support**: Full RGB color palette
- ✅ **Native clipboard**: Seamless copy/paste integration

### Tmux Plugins
- 📦 **TPM**: Plugin manager with auto-updates
- 🎨 **Catppuccin**: Consistent theme across tools
- 🔧 **Better Mouse Mode**: Enhanced scrolling
- 👆 **Thumbs**: Quick text copying
- 📊 **Prefix Highlight**: Visual feedback for prefix key

## 🚀 Quick Start Guide

### 1. Apply Configuration
```bash
# Run the updated shell environment installer
./scripts/components/shell-env.sh

# Or apply tmux config only
tmux source-file ~/.tmux.conf
```

### 2. Install Tmux Plugins
```bash
# Inside tmux session
Ctrl-a + I  # Install plugins (TPM will handle this)
```

### 3. Verify Installation
```bash
# Check tools are available
which spf lazygit lazydocker k9s
tmux -V  # Should be ≥3.2 for popup support
```

### 4. Start Development Session
```bash
# Create named development session
tmux new-session -s dev

# Open your project
cd ~/your-project
nvim .

# Use popups for quick DevOps tasks
Ctrl-a f  # Browse files with superfile
Ctrl-a g  # Git operations with lazygit
Ctrl-a d  # Docker management
```

## 🔥 Pro Tips

### 1. Window Management
- Tmux automatically renames windows to Git repo names
- Use `Ctrl-a c` to create new windows in current directory
- Use `Ctrl-a |` and `Ctrl-a -` for intuitive pane splitting

### 2. Copy & Paste Workflow
- Select text with mouse or `Ctrl-a [` then `v` 
- Copy with `y` - automatically syncs to system clipboard
- Use `F` key for quick URL/path copying with tmux-thumbs

### 3. Session Restoration
- Sessions auto-save every 10 seconds
- Neovim sessions restore with exact cursor positions
- Close terminal completely - everything restores on reconnect

### 4. Color Consistency
- All tools use Catppuccin Frappe palette
- Status bar shows prefix key state with color coding
- Active pane has bright green border for clarity

## 🛠️ Troubleshooting

### Colors Not Displaying Correctly
```bash
# Check true color support
printf '\e[38;2;255;100;0mTRUECOLOR\n'

# Verify Warp detection
echo $TERM_PROGRAM  # Should be "WarpTerminal"
```

### Popup Windows Not Working
```bash
# Check tmux version (needs ≥3.2)
tmux -V

# Test popup manually
tmux display-popup -E "echo 'Popup works!'"
```

### Superfile Not Found
```bash
# Install superfile
brew install superfile
# or
curl -sL https://superfile.netlify.app/install.sh | bash
```

## 📚 Additional Resources

- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [Catppuccin Theme](https://github.com/catppuccin/tmux)  
- [Superfile Documentation](https://github.com/MHNightCat/superfile)
- [Warp Terminal Features](https://docs.warp.dev/)

---

**🎉 Your development environment is now optimized for maximum productivity with Warp, tmux, and modern DevOps tools!**
