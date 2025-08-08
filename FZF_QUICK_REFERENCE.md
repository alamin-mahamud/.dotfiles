# FZF Quick Reference Card

## Main Key Bindings

```
┌─────────────────────────────────────────────────────────┐
│ FZF Key Bindings (Custom Configuration)                 │
├─────────────────────────────────────────────────────────┤
│ Ctrl+R         → Reverse History Search                 │
│ Ctrl+F         → Find Files                             │
│ Ctrl+Shift+D   → Find Directories                       │
└─────────────────────────────────────────────────────────┘
```

## fzf-tab Enhanced Completions

```
┌─────────────────────────────────────────────────────────┐
│ TAB Completions with FZF (fzf-tab plugin)              │
├─────────────────────────────────────────────────────────┤
│ TAB/Shift-TAB  → Navigate completion options            │
│ Ctrl-Space     → Multi-select items                     │
│ /              → Incremental search in results         │
│ F1/F2          → Switch completion groups               │
│ Enter          → Select option                          │
│ Esc            → Cancel completion                      │
└─────────────────────────────────────────────────────────┘
```

## Inside FZF Interface

```
┌─────────────────────────────────────────────────────────┐
│ Navigation & Selection                                  │
├─────────────────────────────────────────────────────────┤
│ ↑/↓ or Ctrl+P/N   → Move up/down                       │
│ Tab/Shift+Tab     → Multi-select items                 │
│ Ctrl+A            → Select all                         │
│ Enter             → Confirm selection                  │
│ Esc               → Cancel                             │
├─────────────────────────────────────────────────────────┤
│ Preview & Display                                       │
├─────────────────────────────────────────────────────────┤
│ Ctrl+/            → Toggle preview window              │
│ Alt+↑/↓           → Scroll preview                     │
├─────────────────────────────────────────────────────────┤
│ Special Actions                                         │
├─────────────────────────────────────────────────────────┤
│ Ctrl+Y            → Copy to clipboard                  │
│ Ctrl+E            → Open in editor                     │
└─────────────────────────────────────────────────────────┘
```

## Custom Helper Functions

```bash
# Process Management
fkill              # Kill process interactively

# Git Operations
fbr                # Switch git branches
fshow              # Browse git commits

# File Operations
fe [query]         # Find and edit files
fcd [path]         # Change directory with fuzzy search
fh                 # Execute from history
```

## fzf-tab Usage Examples

```bash
# File Navigation with Preview
cd <TAB>           # Browse directories with preview
vim <TAB>          # Open files with content preview

# Git Commands with fzf-tab
git checkout <TAB> # Switch branches with commit preview
git add <TAB>      # Stage files with diff preview (Ctrl-Space for multiple)
git diff <TAB>     # View diffs with preview

# System Operations
kill <TAB>         # Select process with command preview
systemctl <TAB>    # Manage services with status preview
ssh <TAB>          # Connect to hosts from history/config

# Docker Operations
docker run <TAB>   # Select images with details
docker exec <TAB>  # Select containers with info
```

## Examples

### Find and edit multiple files

```bash
# Press Ctrl+F, use Tab to select multiple files, Enter to open all in vim
```

### Navigate to a deep directory

```bash
# Press Ctrl+Shift+D, type part of directory name, Enter to cd
```

### Search and rerun a complex command

```bash
# Press Ctrl+R, type keywords from the command, Enter to execute
```

### fzf-tab Multi-selection

```bash
# Use Ctrl-Space in any tab completion to select multiple items:
rm <TAB>           # Select multiple files to delete
git add <TAB>      # Stage multiple files at once
docker stop <TAB>  # Stop multiple containers
```

## Troubleshooting

### FZF Key Bindings Issues

If key bindings don't work:

```bash
# Reload shell configuration
exec zsh

# Or manually source the config
source ~/.zshrc

# Test FZF directly
history | fzf

# Check if function exists
typeset -f fzf-history-widget > /dev/null && echo "Function exists" || echo "Function missing"
```

### fzf-tab Issues

If tab completions aren't using FZF:

```bash
# Check if plugin is loaded
echo $plugins | grep fzf-tab

# Verify fzf-tab is last in plugin list (must load after other completions)
# Edit ~/.zshrc and ensure fzf-tab is the last plugin

# Test with a simple completion
cd <TAB>  # Should show fuzzy completion interface
```

## Tips

### FZF Interface Tips

1. **Multi-selection**: Use Tab to select multiple items in file/directory search
2. **Preview**: Always use Ctrl+/ to toggle preview for better visibility
3. **Search syntax**:
   - `^prefix` - Items starting with prefix
   - `suffix$` - Items ending with suffix
   - `'exact` - Exact match
   - `!exclude` - Exclude items

### fzf-tab Tips

4. **Enhanced completions**: Use TAB for any command to get FZF-powered completions
5. **Multi-select in completions**: Use Ctrl-Space in tab completions for multiple items
6. **Search within results**: Press `/` after TAB to search within completion options
7. **Group navigation**: Use F1/F2 to switch between completion categories

### Performance Tips

8. **Dependencies**: Install `fd`, `bat`, `eza`, and `delta` for enhanced previews
9. **tmux integration**: fzf-tab automatically uses tmux popup for better display

## Terminal Compatibility Note

**Ctrl+Shift+D** might not work in all terminals. If it doesn't:

- Try using the original Alt+C binding
- Or define a custom binding in your terminal emulator
- Test with: `cat -v` then press Ctrl+Shift+D to see the key code

## Testing Commands

To verify your FZF setup:

```bash
# Run the comprehensive test
~/src/.dotfiles/test-fzf.sh

# Interactive verification (must be sourced)
source ~/src/.dotfiles/verify-fzf.sh
```
