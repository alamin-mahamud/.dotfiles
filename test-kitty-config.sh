#!/usr/bin/env bash

# Test Kitty Configuration
# Validates kitty.conf for common issues

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

config_dir="/Users/alamin/work/.dotfiles/linux/.config/kitty"

echo "Testing Kitty configuration..."

# Test 1: Check for float values that might cause issues
echo -n "Checking for problematic float values... "
if grep -r "\.0[^0-9]" "$config_dir" >/dev/null 2>&1; then
    echo -e "${RED}FAIL${NC}"
    echo "Found float values that might cause issues:"
    grep -rn "\.0[^0-9]" "$config_dir"
else
    echo -e "${GREEN}PASS${NC}"
fi

# Test 2: Check for duplicate key mappings
echo -n "Checking for duplicate key mappings... "
duplicates=$(grep "^map " "$config_dir/mappings.conf" | awk '{print $2}' | sort | uniq -d)
if [[ -n "$duplicates" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "Found duplicate key mappings:"
    echo "$duplicates"
else
    echo -e "${GREEN}PASS${NC}"
fi

# Test 3: Check if remote control is enabled
echo -n "Checking remote control configuration... "
if grep -q "allow_remote_control.*yes" "$config_dir/kitty.conf"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARNING${NC} - Remote control not enabled, font size changes may not work"
fi

# Test 4: Validate font size commands
echo -n "Checking font size commands... "
invalid_font_cmds=$(grep "change_font_size" "$config_dir/mappings.conf" | grep -E "\+[0-9]*\.[0-9]+|-[0-9]*\.[0-9]+")
if [[ -n "$invalid_font_cmds" ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "Found invalid font size commands with float values:"
    echo "$invalid_font_cmds"
else
    echo -e "${GREEN}PASS${NC}"
fi

# Test 5: Check if config can be parsed by kitty
echo -n "Testing kitty config syntax... "
if command -v kitty >/dev/null 2>&1; then
    if kitty --config "$config_dir/kitty.conf" --check-config >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        echo "Kitty config syntax check failed"
    fi
else
    echo -e "${YELLOW}SKIP${NC} - Kitty not installed"
fi

echo ""
echo "Font size key bindings:"
echo "  Ctrl+Shift+= or Ctrl+Shift++ : Increase font size"
echo "  Ctrl+Shift+-                 : Decrease font size"
echo "  Ctrl+Shift+Backspace         : Reset to default size"