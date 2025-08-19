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
DESKTOP_DIR="$BOOTSTRAP_SCRIPT_DIR/scripts/desktop"

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
  print_header "Installation Options"

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
  echo "1) Full Desktop Installation"
  echo "2) Shell Environment Only"
  echo "3) Python Development Environment"
  echo "4) Individual Component Selection"
  echo "5) Keyboard Setup (Caps Lock to Escape)"
  echo "q) Quit"
  echo
  read -p "Choose an option [1-5, q]: " choice

  case $choice in
  1) run_orchestrator "linux/install.sh" ;;
  2) run_component "shell-env.sh" ;;
  3) run_component "python-env.sh" ;;
  4) show_component_menu ;;
  5) run_desktop_feature "keyboard-setup.sh" ;;
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
  echo "2) Shell Environment Only"
  echo "3) Python Development Environment"
  echo "4) Individual Component Selection"
  echo "q) Quit"
  echo
  read -p "Choose an option [1-4, q]: " choice

  case $choice in
  1) run_server_essentials ;;
  2) run_component "shell-env.sh" ;;
  3) run_component "python-env.sh" ;;
  4) show_component_menu ;;
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
  echo "2) Shell Environment Only"
  echo "3) Python Development Environment"
  echo "4) Individual Component Selection"
  echo "5) Keyboard Setup (Caps Lock to Escape)"
  echo "q) Quit"
  echo
  read -p "Choose an option [1-5, q]: " choice

  case $choice in
  1) run_orchestrator "macos/install.sh" ;;
  2) run_component "shell-env.sh" ;;
  3) run_component "python-env.sh" ;;
  4) show_component_menu ;;
  5) run_desktop_feature "keyboard-setup.sh" ;;
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
  echo "2) Python Environment (pyenv + poetry + pipx)"
  echo "3) Keyboard Setup (Caps Lock to Escape)"
  echo "b) Back to main menu"
  echo "q) Quit"
  echo
  read -p "Choose a component [1-3, b, q]: " choice

  case $choice in
  1) run_component "shell-env.sh" ;;
  2) run_component "python-env.sh" ;;
  3) run_desktop_feature "keyboard-setup.sh" ;;
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
  local script_path="$ORCHESTRATORS_DIR/$orchestrator"

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
    if "$script_path"; then
      success "Completed: $component"
      show_completion_message
    else
      error "Failed: $component"
    fi
  else
    error "Component not found or not executable: $component"
  fi
}

run_desktop_feature() {
  local feature="$1"
  local script_path="$DESKTOP_DIR/$feature"

  if [[ -x "$script_path" ]]; then
    info "Running desktop feature: $feature"
    if "$script_path"; then
      success "Completed: $feature"
      show_completion_message
    else
      error "Failed: $feature"
    fi
  else
    error "Desktop feature not found or not executable: $feature"
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

    # Configure UFW
    if command_exists ufw; then
      sudo ufw --force enable >/dev/null 2>&1 || true
      success "UFW firewall enabled"
    fi
  fi

  success "Server essentials installation complete"
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

check_prerequisites() {
  info "Checking prerequisites..."

  # Check for required commands
  local required_commands=("git" "curl")
  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      warning "$cmd not found, installing..."
      case "${DOTFILES_OS}" in
      linux)
        setup_package_manager
        update_package_lists
        install_packages "$cmd"
        ;;
      macos)
        if [[ "$cmd" == "git" ]] && ! command_exists xcode-select; then
          info "Installing Xcode Command Line Tools..."
          xcode-select --install
          info "Please complete Xcode installation and run this script again"
          exit 1
        fi
        ;;
      esac
    fi
  done

  # Check internet connectivity
  if ! check_internet; then
    error "Internet connection required for installation"
  fi

  success "Prerequisites check passed"
}

main() {
  # Initialize
  init_script "Dotfiles Bootstrap"

  print_banner

  # Show system information
  show_system_info

  # Check prerequisites
  check_prerequisites

  # Show installation options
  show_main_menu
}

# Handle script interruption
trap 'echo; warning "Installation interrupted"; exit 1' INT TERM

# Run main function
main "$@"

