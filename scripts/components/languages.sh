#!/usr/bin/env bash

# Programming Languages Installation Script
# Installs Python, Node.js, and Go development environments

set -euo pipefail

# Get script directory and source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Parse command line arguments
INSTALL_ALL=true
PYTHON_ONLY=false
NODEJS_ONLY=false
GO_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --python-only)
            INSTALL_ALL=false
            PYTHON_ONLY=true
            shift
            ;;
        --nodejs-only)
            INSTALL_ALL=false
            NODEJS_ONLY=true
            shift
            ;;
        --go-only)
            INSTALL_ALL=false
            GO_ONLY=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

main() {
    print_header "Programming Languages Installation"
    
    local os
    os=$(detect_os)
    
    info "Installing programming languages for $os"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"
    
    if [[ "$INSTALL_ALL" == "true" || "$PYTHON_ONLY" == "true" ]]; then
        install_python_env
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$NODEJS_ONLY" == "true" ]]; then
        install_nodejs_env
    fi
    
    if [[ "$INSTALL_ALL" == "true" || "$GO_ONLY" == "true" ]]; then
        install_go_env
    fi
    
    success "Programming languages installation completed!"
    info "Please restart your shell or run: source ~/.zshrc"
}

install_python_env() {
    print_header "Installing Python Environment"
    
    if [[ -f "$SCRIPT_DIR/python-env.sh" ]]; then
        info "Running Python environment installer..."
        bash "$SCRIPT_DIR/python-env.sh"
    else
        error "Python environment installer not found: $SCRIPT_DIR/python-env.sh"
    fi
}

install_nodejs_env() {
    print_header "Installing Node.js Environment"
    
    if [[ -f "$SCRIPT_DIR/nodejs-env.sh" ]]; then
        info "Running Node.js environment installer..."
        bash "$SCRIPT_DIR/nodejs-env.sh"
    else
        error "Node.js environment installer not found: $SCRIPT_DIR/nodejs-env.sh"
    fi
}

install_go_env() {
    print_header "Installing Go Environment"
    
    if [[ -f "$SCRIPT_DIR/golang-env.sh" ]]; then
        info "Running Go environment installer..."
        bash "$SCRIPT_DIR/golang-env.sh"
    else
        error "Go environment installer not found: $SCRIPT_DIR/golang-env.sh"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi