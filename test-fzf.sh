#!/bin/bash

echo "==================================="
echo "FZF Configuration Test"
echo "==================================="
echo

# Check fzf installation
echo "1. FZF Installation:"
if command -v fzf >/dev/null 2>&1; then
    echo "   ✓ FZF installed: $(fzf --version)"
else
    echo "   ✗ FZF not found"
    exit 1
fi
echo

# Check key files
echo "2. Configuration Files:"
if [[ -f ~/.fzf.zsh ]]; then
    echo "   ✓ ~/.fzf.zsh exists"
else
    echo "   ✗ ~/.fzf.zsh missing"
fi

if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    echo "   ✓ System key-bindings.zsh exists"
elif [[ -f ~/.fzf/shell/key-bindings.zsh ]]; then
    echo "   ✓ User key-bindings.zsh exists"
else
    echo "   ✗ No key-bindings.zsh found"
fi
echo

# Check ZSH bindings
echo "3. ZSH Key Bindings:"
echo "   Testing in new ZSH session..."
zsh_output=$(zsh -c 'source ~/.zshrc 2>/dev/null; bindkey "^R" 2>/dev/null')
if echo "$zsh_output" | grep -q "fzf-history-widget"; then
    echo "   ✓ Ctrl+R bound to: fzf-history-widget"
else
    echo "   ⚠ Ctrl+R bound to: $zsh_output"
    echo "   Note: You may need to restart your shell"
fi
echo

# Check environment variables
echo "4. FZF Environment Variables:"
zsh -c 'source ~/.zshrc 2>/dev/null; [[ -n "$FZF_DEFAULT_OPTS" ]] && echo "   ✓ FZF_DEFAULT_OPTS is set" || echo "   ✗ FZF_DEFAULT_OPTS not set"'
zsh -c 'source ~/.zshrc 2>/dev/null; [[ -n "$FZF_CTRL_R_OPTS" ]] && echo "   ✓ FZF_CTRL_R_OPTS is set" || echo "   ✗ FZF_CTRL_R_OPTS not set"'
echo

# Check helper tools
echo "5. Helper Tools (optional but recommended):"
command -v fd >/dev/null 2>&1 && echo "   ✓ fd installed" || echo "   ○ fd not installed (install with: sudo apt install fd-find)"
command -v rg >/dev/null 2>&1 && echo "   ✓ ripgrep installed" || echo "   ○ ripgrep not installed (install with: sudo apt install ripgrep)"
command -v bat >/dev/null 2>&1 && echo "   ✓ bat installed" || echo "   ○ bat not installed (install with: sudo apt install bat)"
command -v tree >/dev/null 2>&1 && echo "   ✓ tree installed" || echo "   ○ tree not installed (install with: sudo apt install tree)"
echo

echo "==================================="
echo "Instructions to use FZF:"
echo "==================================="
echo
echo "Key Bindings (after restarting shell):"
echo "  • Ctrl+R  - Search command history"
echo "  • Ctrl+T  - Search files in current directory"
echo "  • Alt+C   - Navigate to directory"
echo
echo "Custom Functions (defined in .zshrc):"
echo "  • fkill   - Kill process with fuzzy search"
echo "  • fbr     - Switch git branches"
echo "  • fshow   - Browse git commits"
echo "  • fe      - Open files in vim"
echo "  • fcd     - cd to directory with fuzzy search"
echo "  • fh      - Search and execute from history"
echo
echo "To apply changes immediately:"
echo "  exec zsh"
echo
echo "Or open a new terminal window/tab"
echo