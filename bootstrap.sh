#!/bin/bash

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Function to detect the operating system
detect_os() {
    case "$OSTYPE" in
        linux-gnu*)
            echo "🐧 Detected Linux."
            source "$SCRIPT_DIR/linux/install.sh"
            ;;
        darwin*)
            echo "🍏 Detected macOS."
            source "$SCRIPT_DIR/macos/install.sh"
            ;;
        *)
            echo "❌ Unsupported OS: $OSTYPE"
            exit 1
            ;;
    esac
}

# Main script execution
echo "🔍 Starting OS detection..."

detect_os

echo "✅ Script execution completed."
