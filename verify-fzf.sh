#!/usr/bin/env zsh

# This script must be sourced, not executed
# Usage: source verify-fzf.sh

echo "==================================="
echo "FZF Ctrl+R Test"
echo "==================================="
echo

# Check current binding
echo "Current Ctrl+R binding:"
bindkey "^R"
echo

# Source the configuration
echo "Loading FZF key bindings..."
source ~/.zshrc 2>/dev/null

# Check binding after loading
echo "After loading configuration:"
bindkey "^R"
echo

# Check if fzf-history-widget function exists
if typeset -f fzf-history-widget > /dev/null; then
    echo "✓ fzf-history-widget function is defined"
else
    echo "✗ fzf-history-widget function NOT found"
fi
echo

echo "==================================="
echo "To test Ctrl+R:"
echo "==================================="
echo "1. Press Ctrl+R in your terminal"
echo "2. You should see an interactive fuzzy search"
echo "3. Type to filter your command history"
echo "4. Use arrow keys to select"
echo "5. Press Enter to execute the command"
echo
echo "If it doesn't work, run: exec zsh"
echo "Then try Ctrl+R again"