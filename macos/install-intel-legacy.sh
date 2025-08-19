#!/bin/bash

# Intel-specific macOS Installation (Legacy/Backup)
# This file contains Intel-specific configurations that were separated
# from the main install.sh when transitioning to Apple Silicon support
# Created: $(date)
# Original source: macos/install.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/macos-intel-setup.log"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if running on Intel Mac
check_intel_architecture() {
    local arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]]; then
        print_error "This script is for Intel Macs only. Detected architecture: $arch"
        print_status "Please use the main install.sh for Apple Silicon Macs"
        exit 1
    fi
    print_success "Detected Intel Mac (x86_64)"
}

# Intel-specific Homebrew installation
install_homebrew_intel() {
    if ! command -v brew &> /dev/null; then
        print_status "Installing Homebrew for Intel Mac..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Intel Macs use /usr/local
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
        
        print_success "Homebrew installed at /usr/local"
    else
        print_success "Homebrew already installed"
        brew update
    fi
}

# Intel-specific packages (includes Rosetta-only apps)
install_intel_specific_packages() {
    print_status "Installing Intel-specific packages..."
    
    # Intel-optimized tools
    local packages="
        gcc
        llvm
        cmake
        boost
        opencv
        qt
    "
    
    brew install $packages || {
        print_warning "Some Intel-specific packages may have failed to install"
        print_status "Continuing with setup..."
    }
    
    print_success "Intel-specific packages installed"
}

# Intel-specific GUI applications
install_intel_gui_apps() {
    print_status "Installing Intel-specific GUI applications..."
    
    # Apps that may not have native Apple Silicon versions
    local intel_apps="
        virtualbox
        virtualbox-extension-pack
        docker
        parallels
    "
    
    brew install --cask $intel_apps || {
        print_warning "Some Intel-specific apps may have failed to install"
        print_status "Continuing with setup..."
    }
    
    print_success "Intel-specific GUI applications installed"
}

# Intel-specific performance optimizations
configure_intel_optimizations() {
    print_status "Configuring Intel-specific optimizations..."
    
    # Enable Intel Power Gadget if available
    if [[ -d "/Applications/Intel Power Gadget" ]]; then
        print_status "Intel Power Gadget detected"
    else
        print_status "Installing Intel Power Gadget..."
        brew install --cask intel-power-gadget || print_warning "Intel Power Gadget installation failed"
    fi
    
    # Configure compiler flags for Intel
    export CFLAGS="-march=native -O2"
    export CXXFLAGS="-march=native -O2"
    
    # Add to shell profile
    echo '# Intel-specific compiler optimizations' >> "$HOME/.zprofile"
    echo 'export CFLAGS="-march=native -O2"' >> "$HOME/.zprofile"
    echo 'export CXXFLAGS="-march=native -O2"' >> "$HOME/.zprofile"
    
    print_success "Intel optimizations configured"
}

# Intel-specific developer tools
install_intel_dev_tools() {
    print_status "Installing Intel-specific developer tools..."
    
    # Intel MKL for numerical computing
    brew install intel-oneapi-mkl || print_warning "Intel MKL installation failed"
    
    # Intel compilers (if needed)
    # brew install intel-oneapi-compilers || print_warning "Intel compilers installation failed"
    
    print_success "Intel developer tools installed"
}

# Main function for Intel setup
main() {
    clear
    echo "=========================================================="
    echo "Intel Mac Legacy Installation Script"
    echo "=========================================================="
    echo "This script contains Intel-specific configurations"
    echo "For Apple Silicon Macs, please use the main install.sh"
    echo "=========================================================="
    echo
    
    # Verify Intel architecture
    check_intel_architecture
    
    # Intel-specific setup
    install_homebrew_intel
    install_intel_specific_packages
    
    # Optional components
    read -p "Install Intel-specific GUI applications? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_intel_gui_apps
    fi
    
    read -p "Configure Intel-specific optimizations? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_intel_optimizations
    fi
    
    read -p "Install Intel-specific developer tools? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_intel_dev_tools
    fi
    
    echo
    print_success "Intel Mac setup completed!"
    echo
    print_status "📋 Installation Summary:"
    echo "  • Homebrew: ✓ Installed at /usr/local"
    echo "  • Intel-specific packages: ✓ Installed"
    echo "  • GUI applications: Installed if selected"
    echo "  • Intel optimizations: Configured if selected"
    echo "  • Developer tools: Installed if selected"
    echo
    print_status "📁 Log file saved to: $LOG_FILE"
    echo
    print_warning "📝 Note: This is a legacy script for Intel Macs"
    echo "  For the latest features, consider upgrading to Apple Silicon"
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi