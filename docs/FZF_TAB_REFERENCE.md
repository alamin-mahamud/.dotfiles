# fzf-tab Quick Reference Guide

## Overview
fzf-tab brings fuzzy completion to your zsh tab completions, providing interactive selection with live previews.

## Key Bindings

| Key | Action |
|-----|--------|
| `TAB` / `Shift-TAB` | Navigate through options |
| `Enter` | Select current option |
| `Ctrl-Space` | Multi-select (mark multiple items) |
| `/` | Start incremental search |
| `Ctrl-/` | Toggle preview window |
| `F1` / `F2` | Switch between completion groups |
| `Esc` | Cancel completion |

## Common Usage Examples

### File Navigation
```bash
cd <TAB>              # Browse directories with preview
ls <TAB>              # Browse files with content preview
vim <TAB>             # Open files with preview
cat <TAB>             # View files with preview
```

### Git Commands
```bash
git checkout <TAB>    # Switch branches with commit preview
git add <TAB>         # Stage files with diff preview (Ctrl-Space for multiple)
git diff <TAB>        # View diffs with preview
git log <TAB>         # Browse commits with details
git show <TAB>        # Show commits/tags with smart preview
```

### Process Management
```bash
kill <TAB>            # Select process with command preview
ps aux | grep <TAB>   # Filter processes
```

### System Commands
```bash
systemctl <TAB>       # Manage services with status preview
systemctl status <TAB> # View service status with preview
ssh <TAB>             # Connect to hosts from history/config
man <TAB>             # Browse man pages with descriptions
```

### Docker
```bash
docker run <TAB>      # Select images with details
docker exec <TAB>     # Select containers with info
docker ps <TAB>       # List containers
```

### Package Management (Ubuntu/Debian)
```bash
apt install <TAB>     # Browse packages with descriptions
apt remove <TAB>      # Select installed packages
```

## Advanced Features

### Multiple Selection
Use `Ctrl-Space` to select multiple items:
```bash
rm <TAB>              # Select multiple files to delete
git add <TAB>         # Stage multiple files at once
docker stop <TAB>     # Stop multiple containers
```

### Continuous Completion
Complete paths segment by segment:
```bash
cd /us<TAB>/lo<TAB>/bi<TAB>  # Navigate to /usr/local/bin
```

### Smart Context
```bash
$<TAB>                # Show environment variable values
~<TAB>                # Expand user directories
kill -<TAB>           # Show signal options
export <TAB>          # Set environment variables with preview
```

## Preview Control Aliases

The following aliases are available to control preview behavior:
```bash
fzf-preview-on        # Enable preview window
fzf-preview-off       # Disable preview window
fzf-preview-toggle    # Toggle preview visibility with Ctrl-/
```

## Tips

1. **Search within results**: After pressing TAB, type `/` to search
2. **Group navigation**: Use F1/F2 to switch between different completion groups (e.g., commands vs options)
3. **Preview scrolling**: In preview window, use mouse or configure additional keys
4. **Tmux users**: fzf-tab automatically uses tmux popup for better display

## Troubleshooting

If fzf-tab isn't working:
1. Ensure fzf is installed: `command -v fzf`
2. Check plugin is loaded: `echo $plugins | grep fzf-tab`
3. Verify it's last in plugin list (must load after other completions)
4. Source your zshrc: `source ~/.zshrc`

## Configuration Location

All fzf-tab configurations are in your `~/.zshrc` file, look for the section:
```
# fzf-tab configuration - Enhanced Tab Completion with FZF
```

## Dependencies

- **fzf**: Core fuzzy finder
- **eza**: Enhanced directory previews (falls back to ls)
- **delta**: Git diff highlighting (falls back to standard diff)
- **bat**: Syntax highlighting for file previews (optional)