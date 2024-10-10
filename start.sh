#!/bin/bash

# Function to detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Detected Linux OS."
        ./install_ubuntu.sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Detected macOS."
        ./install_macos.sh
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
}

# Main script execution
echo "Starting OS detection..."

detect_os

echo "Script execution completed."
