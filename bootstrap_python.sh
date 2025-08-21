#!/usr/bin/env bash

# Bootstrap wrapper for Python implementation
# Maintains backward compatibility while using new Python-based installer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Dotfiles Bootstrap - Python Implementation     ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${NC}"
echo

# Check Python availability
check_python() {
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}✓ Python 3 found: $(python3 --version)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Python 3 not found, installing...${NC}"
        
        # Detect OS and install Python
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y python3
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y python3
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm python
            else
                echo -e "${RED}✗ Unable to install Python automatically${NC}"
                echo "Please install Python 3 manually and run this script again"
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install python3
            else
                echo -e "${YELLOW}Installing Homebrew first...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install python3
            fi
        fi
        
        # Verify installation
        if command -v python3 &> /dev/null; then
            echo -e "${GREEN}✓ Python 3 installed successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to install Python 3${NC}"
            exit 1
        fi
    fi
}

# Main execution
main() {
    # Check and install Python if needed
    check_python
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Run Python installer
    echo -e "${CYAN}→ Starting Python-based installer...${NC}"
    echo
    
    # Pass all arguments to Python script
    python3 "$SCRIPT_DIR/dotfiles.py" "$@"
}

# Run main function
main "$@"