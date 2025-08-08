# FZF Setup Documentation

## Overview
FZF (Fuzzy Finder) is now configured for enhanced command-line productivity with ZSH.

## Installation Status
- **FZF Version**: 0.44.1 (debian)
- **Configuration Files**: 
  - `~/.fzf.zsh` - Main FZF configuration loader
  - `~/.zshrc` - Contains FZF settings and custom functions
  - `/usr/share/doc/fzf/examples/key-bindings.zsh` - System key bindings

## Configuration Details

### Load Order (Important!)
The FZF configuration is loaded AFTER Oh My Zsh to ensure proper key binding overrides:
1. Oh My Zsh loads first (line 60 in .zshrc)
2. FZF configuration loads immediately after (lines 62-75)
3. FZF environment variables and custom functions follow

### Key Bindings
After restarting your shell or running `exec zsh`:

| Key Binding | Function | Description |
|------------|----------|-------------|
| **Ctrl+R** | History Search | Fuzzy search through command history |
| **Ctrl+T** | File Search | Find and insert files in current directory |
| **Alt+C** | Directory Navigation | Change to selected directory |

### Within FZF Interface
| Key | Action |
|-----|--------|
| **Ctrl+/** | Toggle preview window |
| **Ctrl+A** | Select all items |
| **Ctrl+Y** | Copy to clipboard |
| **Tab/Shift+Tab** | Multi-select items |
| **Enter** | Execute/Select |
| **Esc** | Cancel |

## Custom Functions
The following helper functions are available in your shell:

### Process Management
- `fkill` - Kill processes with fuzzy search
  ```bash
  fkill     # Select and kill with SIGKILL
  fkill 15  # Select and kill with SIGTERM
  ```

### Git Integration
- `fbr` - Switch git branches interactively
  ```bash
  fbr  # Shows all branches with details
  ```

- `fshow` - Browse git commits with preview
  ```bash
  fshow  # Interactive commit browser
  ```

### File Operations
- `fe` - Open files in editor with fuzzy search
  ```bash
  fe          # Search all files
  fe query    # Search with initial query
  ```

- `fcd` - Change directory with fuzzy search
  ```bash
  fcd         # Search from current directory
  fcd /path   # Search from specific path
  ```

### History
- `fh` - Search and execute from history
  ```bash
  fh  # Select and run command from history
  ```

## Enhanced Features

### File Preview
- Files show content preview using `bat` (with syntax highlighting)
- Directories show tree structure
- Git commands show diffs and commit details

### Performance Optimizations
- Uses `fd` for faster file finding (when available)
- Uses `ripgrep` as fallback for file listing
- Hidden files are included but `.git` is excluded

### Visual Theme
- Catppuccin-inspired color scheme
- Rounded borders
- Reverse layout (results at top)
- 40% height by default

## Troubleshooting

### If Ctrl+R doesn't work:

1. **Restart your shell**:
   ```bash
   exec zsh
   ```

2. **Verify key binding**:
   ```bash
   bindkey "^R"
   # Should show: "^R" fzf-history-widget
   ```

3. **Check if function exists**:
   ```bash
   typeset -f fzf-history-widget > /dev/null && echo "Function exists" || echo "Function missing"
   ```

4. **Manually source key bindings**:
   ```bash
   source /usr/share/doc/fzf/examples/key-bindings.zsh
   ```

5. **Test FZF directly**:
   ```bash
   history | fzf
   ```

### Common Issues

**Issue**: Ctrl+R shows default ZSH history search
**Solution**: The FZF key bindings aren't loaded. Run `exec zsh` to reload shell.

**Issue**: Preview windows don't show content
**Solution**: Install optional tools:
```bash
sudo apt install bat tree fd-find ripgrep
```

**Issue**: FZF command not found
**Solution**: Reinstall FZF:
```bash
cd ~/.fzf && ./install
```

## Testing
Run the test script to verify installation:
```bash
~/src/.dotfiles/test-fzf.sh
```

Or source the verification script in an interactive shell:
```bash
source ~/src/.dotfiles/verify-fzf.sh
```

## Additional Resources
- [FZF GitHub](https://github.com/junegunn/fzf)
- [FZF Wiki](https://github.com/junegunn/fzf/wiki)
- [Advanced FZF Examples](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)