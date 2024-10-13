#!/bin/bash

# Determine the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Function to detect the operating system
detect_os() {
    case "$OSTYPE" in
        linux-gnu*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu)
                        echo "🐧 Detected Ubuntu OS."
                        source "$SCRIPT_DIR/ubuntu/install.sh"
                        ;;
                    arch)
                        echo "🐧 Detected Arch Linux OS."
                        source "$SCRIPT_DIR/arch/install.sh"
                        ;;
                    *)
                        echo "❌ Unsupported Linux distribution: $ID"
                        exit 1
                        ;;
                esac
            else
                echo "❌ Unable to detect Linux distribution."
                exit 1
            fi
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
