#!/usr/bin/env bash

# Bootstrap Script for Dotfiles
# Enhanced modular installation with DRY architecture
# Supports: Linux Desktop, macOS, Server environments
# Version: 3.0

set -euo pipefail

# Script directory
BOOTSTRAP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$BOOTSTRAP_SCRIPT_DIR"

# Load shared libraries
if [[ -z "${DOTFILES_COMMON_LOADED:-}" ]]; then
    source "$BOOTSTRAP_SCRIPT_DIR/scripts/lib/common.sh"
fi
source "$BOOTSTRAP_SCRIPT_DIR/scripts/lib/package-managers.sh"

# Configuration - use BOOTSTRAP_SCRIPT_DIR instead of SCRIPT_DIR which gets overwritten
ORCHESTRATORS_DIR="$BOOTSTRAP_SCRIPT_DIR"
COMPONENTS_DIR="$BOOTSTRAP_SCRIPT_DIR/scripts/components"

# Flag-based deployment variables
INSTALL_MODE="interactive"  # interactive, server, desktop, custom
INSTALL_SHELL=false
INSTALL_NEOVIM=false
INSTALL_PYTHON=false
INSTALL_NODEJS=false
INSTALL_GOLANG=false
INSTALL_DEVOPS=false
INSTALL_ALL=false
SKIP_CONFIRM=false
VERBOSE=false

print_usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Dotfiles Bootstrap Script - Flag-based deployment for automated installations

OPTIONS:
  -m, --mode MODE      Installation mode: interactive|server|desktop|custom (default: interactive)
  -s, --shell          Install shell environment (Zsh + Oh My Zsh + Tmux + CLI tools)
  -n, --neovim         Install Neovim + LazyVim + keyboard setup
  -p, --python         Install Python development environment (pyenv + poetry + pipx)
  -j, --nodejs         Install Node.js development environment (nvm + npm + yarn)
  -g, --golang         Install Go development environment
  -d, --devops         Install DevOps tools (Docker, Terraform, Kubernetes, Cloud CLIs)
  -a, --all            Install all components
  -y, --yes            Skip confirmation prompts (non-interactive mode)
  -v, --verbose        Enable verbose output
  -h, --help           Show this help message

EXAMPLES:
  # Interactive mode (default)
  ./bootstrap.sh

  # Server mode with default components (shell + neovim)
  ./bootstrap.sh --mode server

  # Server with specific components
  ./bootstrap.sh --mode server --shell --neovim --python

  # Install everything without prompts
  ./bootstrap.sh --all --yes

  # Custom installation with specific components
  ./bootstrap.sh --mode custom --shell --neovim --devops --yes

NOTES:
  - Server mode defaults to installing shell + neovim if no components specified
  - Desktop mode installs all components by default
  - Use --yes for CI/CD and automated deployments

EOF
  exit 0
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -m|--mode)
        INSTALL_MODE="$2"
        shift 2
        ;;
      -s|--shell)
        INSTALL_SHELL=true
        shift
        ;;
      -n|--neovim)
        INSTALL_NEOVIM=true
        shift
        ;;
      -p|--python)
        INSTALL_PYTHON=true
        shift
        ;;
      -j|--nodejs)
        INSTALL_NODEJS=true
        shift
        ;;
      -g|--golang)
        INSTALL_GOLANG=true
        shift
        ;;
      -d|--devops)
        INSTALL_DEVOPS=true
        shift
        ;;
      -a|--all)
        INSTALL_ALL=true
        shift
        ;;
      -y|--yes)
        SKIP_CONFIRM=true
        export DOTFILES_AUTO_CONFIRM=1
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        export DOTFILES_VERBOSE=1
        shift
        ;;
      -h|--help)
        print_usage
        ;;
      *)
        error "Unknown option: $1"
        print_usage
        ;;
    esac
  done

  # Validate mode
  case "$INSTALL_MODE" in
    interactive|server|desktop|custom)
      ;;
    *)
      error "Invalid mode: $INSTALL_MODE"
      print_usage
      ;;
  esac

  # Set defaults based on mode
  if [[ "$INSTALL_MODE" == "server" ]]; then
    # If no specific components selected, default to shell + neovim for server
    if [[ "$INSTALL_SHELL" == false && "$INSTALL_NEOVIM" == false && \
          "$INSTALL_PYTHON" == false && "$INSTALL_NODEJS" == false && \
          "$INSTALL_GOLANG" == false && "$INSTALL_DEVOPS" == false && \
          "$INSTALL_ALL" == false ]]; then
      INSTALL_SHELL=true
      INSTALL_NEOVIM=true
    fi
  elif [[ "$INSTALL_MODE" == "desktop" ]]; then
    # Desktop mode defaults to all components
    if [[ "$INSTALL_ALL" == false ]]; then
      INSTALL_ALL=true
    fi
  fi

  # If --all is set, enable all components
  if [[ "$INSTALL_ALL" == true ]]; then
    INSTALL_SHELL=true
    INSTALL_NEOVIM=true
    INSTALL_PYTHON=true
    INSTALL_NODEJS=true
    INSTALL_GOLANG=true
    INSTALL_DEVOPS=true
  fi
}

print_banner() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════╗"
  echo "║          Dotfiles Bootstrap Script v3.0          ║"
  echo "║         DRY Architecture • Modular Design        ║"
  echo "╚═══════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

show_system_info() {
  print_header "System Information"
  info "Operating System: ${DOTFILES_OS}"
  info "Distribution: ${DOTFILES_DISTRO}"
  info "Architecture: ${DOTFILES_ARCH}"
  info "Environment: ${DOTFILES_ENV}"
  info "Display Server: ${DOTFILES_DISPLAY}"
  info "Package Manager: $(detect_package_manager)"

  if is_wsl; then
    info "WSL Environment detected"
  fi

  if is_ssh_session; then
    info "SSH Session detected"
  fi
}

show_main_menu() {
  print_header "Dotfiles Installation Options"

  case "${DOTFILES_OS}" in
  linux)
    if is_desktop_environment; then
      show_linux_desktop_menu
    else
      show_linux_server_menu
    fi
    ;;
  macos)
    show_macos_menu
    ;;
  *)
    error "Unsupported operating system: ${DOTFILES_OS}"
    ;;
  esac
}

show_linux_desktop_menu() {
  echo "Linux Desktop Installation Options:"
  echo "1) Full Desktop Installation (Everything)"
  echo "2) Shell Environment (Zsh + Tmux + CLI tools)"
  echo "3) Neovim + LazyVim + Keyboard Setup (Caps Lock → Escape)"
  echo "4) Python Development Environment"
  echo "5) Individual Component Selection"
  echo "q) Quit"
  echo
  read -p "Choose an option [1-5, q]: " choice

  case $choice in
  1) run_orchestrator "linux/install.sh" && show_completion_message ;;
  2) run_component "shell-env.sh" && show_completion_message ;;
  3) run_component "neovim-env.sh" && show_completion_message ;;
  4) run_component "python-env.sh" && show_completion_message ;;
  5) show_component_menu ;;
  q | Q) exit 0 ;;
  *)
    warning "Invalid option. Please try again."
    show_main_menu
    ;;
  esac
}

show_linux_server_menu() {
  echo "Linux Server Installation Options:"
  echo "1) Essential Server Setup"
  echo "2) Shell Environment (Zsh + Tmux + CLI tools)"
  echo "3) Neovim + LazyVim + Keyboard Setup (Console/SSH optimized)"
  echo "4) Python Development Environment"
  echo "5) Individual Component Selection"
  echo "q) Quit"
  echo
  read -p "Choose an option [1-5, q]: " choice

  case $choice in
  1) run_server_essentials && show_completion_message ;;
  2) run_component "shell-env.sh" && show_completion_message ;;
  3) run_component "neovim-env.sh" && show_completion_message ;;
  4) run_component "python-env.sh" && show_completion_message ;;
  5) show_component_menu ;;
  q | Q) exit 0 ;;
  *)
    warning "Invalid option. Please try again."
    show_main_menu
    ;;
  esac
}

show_macos_menu() {
  echo "macOS Installation Options:"
  echo "1) Full macOS Development Environment"
  echo "2) Shell Environment (Zsh + Tmux + CLI tools)"
  echo "3) Neovim + LazyVim + Keyboard Setup (Caps Lock → Escape)"
  echo "4) Python Development Environment"
  echo "5) Individual Component Selection"
  echo "q) Quit"
  echo
  read -p "Choose an option [1-5, q]: " choice

  case $choice in
  1) run_orchestrator "macos/install.sh" && show_completion_message ;;
  2) run_component "shell-env.sh" && show_completion_message ;;
  3) run_component "neovim-env.sh" && show_completion_message ;;
  4) run_component "python-env.sh" && show_completion_message ;;
  5) show_component_menu ;;
  q | Q) exit 0 ;;
  *)
    warning "Invalid option. Please try again."
    show_main_menu
    ;;
  esac
}

show_component_menu() {
  print_header "Individual Components"
  echo "Available components:"
  echo "1) Shell Environment (Zsh + Oh My Zsh + Tmux + CLI tools)"
  echo "2) Neovim + LazyVim + Keyboard Setup (Editor + Caps Lock → Escape)"
  echo "3) Python Environment (pyenv + poetry + pipx)"
  echo "b) Back to main menu"
  echo "q) Quit"
  echo
  read -p "Choose a component [1-3, b, q]: " choice

  case $choice in
  1) run_component "shell-env.sh" && show_completion_message ;;
  2) run_component "neovim-env.sh" && show_completion_message ;;
  3) run_component "python-env.sh" && show_completion_message ;;
  b | B) show_main_menu ;;
  q | Q) exit 0 ;;
  *)
    warning "Invalid option. Please try again."
    show_component_menu
    ;;
  esac
}

run_orchestrator() {
  local orchestrator="$1"
  
  # Special handling for macOS since it doesn't have an orchestrator file
  if [[ "$orchestrator" == "macos/install.sh" ]]; then
    run_macos_full_installation
    return
  fi
  
  local script_path="$ORCHESTRATORS_DIR/$orchestrator"
  local title="${orchestrator%.*}"

  if [[ -x "$script_path" ]]; then
    info "Running orchestrator: $orchestrator"
    if "$script_path"; then
      success "Completed: $orchestrator"
      show_completion_message
    else
      error "Failed: $orchestrator"
    fi
  else
    error "Orchestrator not found or not executable: $orchestrator"
  fi
}

run_component() {
  local component="$1"
  local script_path="$COMPONENTS_DIR/$component"

  if [[ -x "$script_path" ]]; then
    info "Running component: $component"
    if DOTFILES_AUTO_CONFIRM=1 "$script_path"; then
      success "Completed: $component"
    else
      error "Failed: $component"
    fi
  else
    error "Component not found or not executable: $component"
  fi
}


run_server_essentials() {
  info "Installing server essentials..."

  # Install minimal server components
  run_component "shell-env.sh"

  # Basic security setup for servers
  if [[ "${DOTFILES_DISTRO}" == "ubuntu" ]]; then
    info "Setting up basic server security..."
    setup_package_manager
    update_package_lists
    install_packages ufw fail2ban htop iotop nethogs

    # Configure UFW (idempotent)
    if command_exists ufw; then
      if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw --force enable >/dev/null 2>&1 || true
        success "UFW firewall enabled"
      else
        debug "UFW firewall already enabled"
      fi
    fi
  fi

  success "Server essentials installation complete"
}

run_macos_full_installation() {
  info "Starting full macOS development environment installation..."
  
  # Check for Xcode Command Line Tools
  if ! xcode-select --print-path &> /dev/null; then
    info "Installing Xcode Command Line Tools (this may take a while)..."
    xcode-select --install
    info "Please complete Xcode installation and run this script again"
    exit 1
  fi
  
  # Install Homebrew if not present
  if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session
    if [[ "${DOTFILES_ARCH}" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  else
    debug "Homebrew already installed"
  fi
  
  # Update package manager
  setup_package_manager
  update_package_lists
  
  # Install essential packages
  info "Installing essential macOS packages..."
  install_packages git curl wget jq tree htop ripgrep fd bat eza fzf tmux neovim
  
  # Run component installers
  info "Installing shell environment..."
  run_component "shell-env.sh"
  
  info "Installing Neovim environment..."
  run_component "neovim-env.sh"
  
  info "Installing Python development environment..."
  run_component "python-env.sh"
  
  info "Installing Node.js development environment..."  
  run_component "nodejs-env.sh"
  
  info "Installing Go development environment..."
  run_component "golang-env.sh"
  
  info "Installing DevOps tools..."
  run_component "devops-tools.sh"
  
  # Setup configuration symlinks
  info "Setting up configuration symlinks..."
  local dotfiles_dir="$DOTFILES_ROOT"
  
  # Git configuration
  if [[ -f "$dotfiles_dir/git/.gitconfig" ]]; then
    safe_symlink "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
  fi
  
  # Configure macOS settings
  if ! is_completed "macos-settings-configured"; then
    info "Configuring macOS system settings..."
    
    # Dock settings
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock show-recents -bool false
    
    # Finder settings
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    
    # Keyboard settings
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Restart affected services
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    
    mark_completed "macos-settings-configured"
    success "macOS settings configured"
  fi
  
  success "macOS full installation complete"
}

show_completion_message() {
  print_header "Installation Complete!"

  case "${DOTFILES_OS}" in
  linux | macos)
    info "Next steps:"
    info "1. Restart your terminal or run: exec zsh"
    info "2. Run 'p10k configure' to set up your prompt theme"
    info "3. Open tmux and press Ctrl-a + I to install plugins"
    ;;
  esac

  info ""
  info "Log file: $LOG_FILE"
  info ""

  if ask_yes_no "Run another installation?" "no"; then
    show_main_menu
  else
    info "Thank you for using the dotfiles installer!"
    exit 0
  fi
}


run_automated_installation() {
  print_header "Automated Installation"
  
  info "Installation mode: ${INSTALL_MODE}"
  info "Components to install:"
  
  local components_to_install=()
  
  [[ "$INSTALL_SHELL" == true ]] && components_to_install+=("Shell Environment") && info "  • Shell Environment (Zsh + Oh My Zsh + Tmux + CLI tools)"
  [[ "$INSTALL_NEOVIM" == true ]] && components_to_install+=("Neovim Environment") && info "  • Neovim + LazyVim + Keyboard Setup"
  [[ "$INSTALL_PYTHON" == true ]] && components_to_install+=("Python Development") && info "  • Python Development Environment"
  [[ "$INSTALL_NODEJS" == true ]] && components_to_install+=("Node.js Development") && info "  • Node.js Development Environment"
  [[ "$INSTALL_GOLANG" == true ]] && components_to_install+=("Go Development") && info "  • Go Development Environment"
  [[ "$INSTALL_DEVOPS" == true ]] && components_to_install+=("DevOps Tools") && info "  • DevOps Tools (Docker, Terraform, K8s, Cloud CLIs)"
  
  if [[ ${#components_to_install[@]} -eq 0 ]]; then
    warning "No components selected for installation"
    info "Use --help to see available options"
    exit 1
  fi
  
  # Confirm installation unless --yes is provided
  if [[ "$SKIP_CONFIRM" == false ]]; then
    echo
    if ! ask_yes_no "Proceed with installation?" "yes"; then
      info "Installation cancelled"
      exit 0
    fi
  fi
  
  echo
  info "Starting automated installation..."
  
  # Run installations based on flags
  local install_success=true
  
  if [[ "$INSTALL_SHELL" == true ]]; then
    info "Installing Shell Environment..."
    if ! run_component "shell-env.sh"; then
      error "Failed to install Shell Environment"
      install_success=false
    fi
  fi
  
  if [[ "$INSTALL_NEOVIM" == true ]]; then
    info "Installing Neovim Environment..."
    if ! run_component "neovim-env.sh"; then
      error "Failed to install Neovim Environment"
      install_success=false
    fi
  fi
  
  if [[ "$INSTALL_PYTHON" == true ]]; then
    info "Installing Python Development Environment..."
    if ! run_component "python-env.sh"; then
      error "Failed to install Python Development Environment"
      install_success=false
    fi
  fi
  
  if [[ "$INSTALL_NODEJS" == true ]]; then
    info "Installing Node.js Development Environment..."
    if ! run_component "nodejs-env.sh"; then
      error "Failed to install Node.js Development Environment"
      install_success=false
    fi
  fi
  
  if [[ "$INSTALL_GOLANG" == true ]]; then
    info "Installing Go Development Environment..."
    if ! run_component "golang-env.sh"; then
      error "Failed to install Go Development Environment"
      install_success=false
    fi
  fi
  
  if [[ "$INSTALL_DEVOPS" == true ]]; then
    info "Installing DevOps Tools..."
    if ! run_component "devops-tools.sh"; then
      error "Failed to install DevOps Tools"
      install_success=false
    fi
  fi
  
  # Show completion message
  if [[ "$install_success" == true ]]; then
    print_header "Installation Complete!"
    success "All selected components installed successfully"
    
    info ""
    info "Next steps:"
    [[ "$INSTALL_SHELL" == true ]] && info "  1. Restart your terminal or run: exec zsh"
    [[ "$INSTALL_SHELL" == true ]] && info "  2. Run 'p10k configure' to set up your prompt theme"
    [[ "$INSTALL_SHELL" == true ]] && info "  3. Open tmux and press Ctrl-a + I to install plugins"
    [[ "$INSTALL_NEOVIM" == true ]] && info "  4. Open Neovim to complete LazyVim setup"
    
    info ""
    info "Log file: $LOG_FILE"
  else
    error "Some components failed to install. Check the log file: $LOG_FILE"
    exit 1
  fi
}

check_prerequisites() {
  info "Checking prerequisites..."

  # Check for required commands
  local required_commands=("git" "curl")
  local missing_commands=()
  
  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done
  
  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    info "Installing missing prerequisites: ${missing_commands[*]}"
    case "${DOTFILES_OS}" in
    linux)
      setup_package_manager
      update_package_lists
      install_packages "${missing_commands[@]}"
      ;;
    macos)
      for cmd in "${missing_commands[@]}"; do
        if [[ "$cmd" == "git" ]] && ! command_exists xcode-select; then
          info "Installing Xcode Command Line Tools..."
          xcode-select --install
          info "Please complete Xcode installation and run this script again"
          exit 1
        fi
      done
      ;;
    esac
  else
    debug "All prerequisites already available"
  fi

  # Check internet connectivity
  if ! check_internet; then
    error "Internet connection required for installation"
  fi

  success "Prerequisites check passed"
}

main() {
  # Parse command line arguments first
  parse_arguments "$@"
  
  # Initialize
  init_script "Dotfiles Bootstrap"

  print_banner

  # Show system information
  show_system_info

  # Check prerequisites
  check_prerequisites

  # Run based on mode
  case "$INSTALL_MODE" in
    interactive)
      # Show installation options menu
      show_main_menu
      ;;
    server|desktop|custom)
      # Run automated installation based on flags
      run_automated_installation
      ;;
    *)
      error "Invalid installation mode: $INSTALL_MODE"
      exit 1
      ;;
  esac
}

# Handle script interruption
trap 'echo; warning "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"

