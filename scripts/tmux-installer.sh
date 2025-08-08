#!/usr/bin/env bash

# ============================================================================
# STANDALONE TMUX INSTALLER AND CONFIGURATION SCRIPT
# ============================================================================
# Purpose: Comprehensive tmux installation for DevOps engineers and developers
# Supports: Ubuntu, Debian, Fedora, CentOS, RHEL, Rocky, AlmaLinux, Arch,
#           Manjaro, Alpine, openSUSE, SLES, macOS
# Features:
#   - Automatic OS detection and package manager selection
#   - TPM (Tmux Plugin Manager) installation
#   - Enhanced tmux configuration with mouse support
#   - DevOps-focused keyboard shortcuts
#   - Utility scripts (sessionizer, project manager)
#   - Shell integration with useful aliases
#
# Usage Examples:
#   1. Direct download and run:
#      curl -fsSL https://your-domain.com/tmux-installer.sh | bash
#      wget -qO- https://your-domain.com/tmux-installer.sh | bash
#
#   2. Local execution:
#      chmod +x tmux-installer.sh
#      ./tmux-installer.sh
#
#   3. With options:
#      ./tmux-installer.sh --skip-tools    # Skip additional tools
#      ./tmux-installer.sh --config-only   # Only update configuration
#      ./tmux-installer.sh --help          # Show help
#
# Test Cases:
#   Test OS detection:    ./tmux-installer.sh --test-os
#   Test installation:    ./tmux-installer.sh --dry-run
#   Verify installation:  ./tmux-installer.sh --verify
# ============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

# ============================================================================
# CONFIGURATION VARIABLES
# ============================================================================

# Colors for terminal output - ANSI escape codes for better visibility
RED='\033[0;31m'     # Error messages
GREEN='\033[0;32m'   # Success messages
YELLOW='\033[1;33m'  # Warnings and info
BLUE='\033[0;34m'    # Headers and important info
MAGENTA='\033[0;35m' # Special features
CYAN='\033[0;36m'    # Commands and code
NC='\033[0m'         # No Color - reset to default

# Script configuration
SCRIPT_VERSION="2.0.0"
DRY_RUN=false
SKIP_TOOLS=false
CONFIG_ONLY=false
VERBOSE=false

# Default project directories for sessionizer
DEFAULT_PROJECT_DIRS=(
    "$HOME"
    "$HOME/Work"
    "$HOME/Projects"
    "$HOME/Dev"
    "$HOME/Code"
    "$HOME/Documents"
    "/opt"
    "/var/www"
    "/srv"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Print formatted messages with timestamps
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✅ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

print_info() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ℹ️  $1"
}

# Display help message
show_help() {
    cat << EOF
${BLUE}Standalone Tmux Installer v${SCRIPT_VERSION}${NC}

Usage: $0 [OPTIONS]

Options:
    --help, -h           Show this help message
    --version, -v        Show script version
    --skip-tools         Skip installation of additional tools (fzf, htop, etc.)
    --config-only        Only update tmux configuration (skip installations)
    --dry-run            Show what would be done without making changes
    --verbose            Enable verbose output
    --test-os            Test OS detection and exit
    --verify             Verify tmux installation and configuration
    --uninstall          Remove tmux configuration (keeps tmux installed)

Examples:
    # Standard installation
    $0

    # Update configuration only
    $0 --config-only

    # Test what would be installed
    $0 --dry-run

    # Verify installation
    $0 --verify

For more information, visit: https://github.com/yourusername/dotfiles
EOF
    exit 0
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                ;;
            --version|-v)
                echo "Tmux Installer v${SCRIPT_VERSION}"
                exit 0
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            --config-only)
                CONFIG_ONLY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                set -x  # Enable bash debug mode
                shift
                ;;
            --test-os)
                detect_os
                echo "OS Detection Results:"
                echo "  OS: $OS"
                echo "  Package Manager: $(get_package_manager)"
                echo "  Architecture: $(uname -m)"
                exit 0
                ;;
            --verify)
                verify_installation
                exit 0
                ;;
            --uninstall)
                uninstall_tmux_config
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

# Display installation banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         Standalone Tmux Installer v${SCRIPT_VERSION}              ║"
    echo "║           Enhanced for DevOps Engineers                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================================================
# OS DETECTION AND PACKAGE MANAGEMENT
# ============================================================================

# Detect operating system and distribution
# Sets global variable: OS
# Returns: 0 on success, 1 on failure
detect_os() {
    print_status "Detecting operating system..."

    # Check for macOS using OSTYPE environment variable
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
        print_success "Detected macOS $OS_VERSION"

    # Check for Linux distributions using /etc/os-release
    elif [[ -f /etc/os-release ]]; then
        # Source the os-release file to get distribution info
        . /etc/os-release
        OS=$ID  # Distribution ID (ubuntu, debian, fedora, etc.)
        OS_VERSION="${VERSION_ID:-unknown}"
        OS_PRETTY="${PRETTY_NAME:-$ID}"
        print_success "Detected $OS_PRETTY"

    # Fallback for older systems without os-release
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        OS_VERSION=$(rpm -E %{rhel})
        print_success "Detected RHEL/CentOS $OS_VERSION"

    else
        print_error "Unable to detect operating system"
        print_info "Supported systems: Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, Alpine, openSUSE, macOS"
        exit 1
    fi

    # Validate detected OS is supported
    case $OS in
        ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|alpine|opensuse*|sles|macos)
            [[ "$VERBOSE" == true ]] && print_info "OS validation passed"
            ;;
        *)
            print_warning "Uncommon OS detected: $OS"
            print_info "Installation will attempt to continue with generic Linux commands"
            ;;
    esac

    # Force output flush to prevent hanging
    exec 2>&1
}

# Get the appropriate package manager for the detected OS
# Returns: Package manager command (apt, dnf, yum, pacman, etc.)
get_package_manager() {
    case $OS in
        ubuntu|debian)
            echo "apt"
            ;;
        fedora|centos|rhel|rocky|almalinux)
            # Prefer dnf over yum on newer systems
            if command -v dnf &> /dev/null; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        arch|manjaro)
            echo "pacman"
            ;;
        alpine)
            echo "apk"
            ;;
        opensuse*|sles)
            echo "zypper"
            ;;
        macos)
            echo "brew"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if running with sufficient privileges
# Some operations may require sudo
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended."
        print_info "Consider running as a regular user with sudo privileges."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

# Install tmux using the appropriate package manager
# Handles all supported operating systems
# Returns: 0 on success, 1 on failure
install_tmux() {
    print_status "Installing tmux..."

    # Skip if doing dry run
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install tmux using $(get_package_manager)"
        return 0
    fi

    # Check if tmux is already installed
    if command -v tmux &> /dev/null; then
        local tmux_version=$(tmux -V | cut -d' ' -f2)
        print_success "Tmux is already installed (version $tmux_version)"

        # Check for minimum version (2.1 for mouse support)
        if [[ $(echo "$tmux_version < 2.1" | bc -l 2>/dev/null) == "1" ]]; then
            print_warning "Tmux version is old. Consider upgrading for better features."
        fi
        return 0
    fi

    # Install based on operating system
    print_info "Using package manager: $(get_package_manager)"

    case $OS in
        "macos")
            # macOS uses Homebrew package manager
            # Install Homebrew if not present
            if ! command -v brew &> /dev/null; then
                print_warning "Homebrew not found. Installing Homebrew first..."
                print_info "This may take a few minutes and require your password"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Add Homebrew to PATH for Apple Silicon Macs
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            brew install tmux git curl
            ;;

        "ubuntu"|"debian")
            # Debian-based distributions use APT
            print_info "Updating package lists..."
            sudo apt update
            print_info "Installing tmux and dependencies..."
            sudo apt install -y tmux git curl
            ;;

        "fedora"|"centos"|"rhel"|"rocky"|"almalinux")
            # Red Hat-based distributions use DNF or YUM
            if command -v dnf &> /dev/null; then
                # Modern versions use DNF
                sudo dnf install -y tmux git curl
            else
                # Older versions use YUM
                sudo yum install -y tmux git curl
            fi
            ;;

        "arch"|"manjaro")
            # Arch-based distributions use Pacman
            # Update package database first
            sudo pacman -Sy
            sudo pacman -S --noconfirm tmux git curl
            ;;

        "alpine")
            # Alpine Linux uses APK
            # Note: Alpine uses ash by default, we need bash for this script
            sudo apk update
            sudo apk add --no-cache tmux git curl bash
            ;;

        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed"|"sles")
            # openSUSE and SLES use Zypper
            sudo zypper refresh
            sudo zypper install -y tmux git curl
            ;;

        *)
            print_error "Unsupported OS: $OS"
            print_info "Please install tmux manually using your package manager"
            print_info "Required packages: tmux, git, curl"
            exit 1
            ;;
    esac

    # Verify installation
    if command -v tmux &> /dev/null; then
        print_success "Tmux installed successfully ($(tmux -V))"
    else
        print_error "Tmux installation failed"
        exit 1
    fi
}

# Install additional tools useful for DevOps workflows
# Includes: fzf (fuzzy finder), htop (process viewer),
#           jq (JSON processor), watch (command repeater)
# Returns: 0 on success (even if some tools fail)
install_additional_tools() {
    print_status "Installing additional DevOps tools..."

    if [[ "$SKIP_TOOLS" == true ]]; then
        print_info "Skipping additional tools installation (--skip-tools flag set)"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install: fzf, htop, watch, jq, ripgrep, fd"
        return 0
    fi

    # List of tools to install with descriptions
    local tools_to_install=(
        "fzf:Fuzzy finder for quick file/history search"
        "htop:Interactive process viewer"
        "jq:Command-line JSON processor"
        "ripgrep:Fast text search tool"
        "fd:Modern find alternative"
        "bat:Cat alternative with syntax highlighting"
        "tree:Directory structure viewer"
        "ncdu:Disk usage analyzer"
    )

    print_info "Installing tools for enhanced productivity..."

    case $OS in
        "macos")
            # macOS with Homebrew
            brew install fzf htop watch jq ripgrep fd bat tree ncdu || true
            # Install fzf key bindings
            $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash 2>/dev/null || true
            ;;

        "ubuntu"|"debian")
            # Install available tools from APT
            sudo apt install -y fzf htop procps jq ripgrep fd-find bat tree ncdu 2>/dev/null || {
                # Some tools might not be available in older versions
                print_warning "Some tools may not be available in your repository"
                sudo apt install -y htop procps jq tree ncdu 2>/dev/null || true

                # Install fzf manually if not available
                if ! command -v fzf &> /dev/null; then
                    print_info "Installing fzf from git..."
                    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                    ~/.fzf/install --all --no-update-rc --no-bash
                fi
            }
            ;;

        "fedora"|"centos"|"rhel"|"rocky"|"almalinux")
            if command -v dnf &> /dev/null; then
                # Modern Red Hat systems with DNF
                sudo dnf install -y fzf htop procps-ng jq ripgrep fd-find bat tree ncdu 2>/dev/null || {
                    # Install core tools only if advanced ones fail
                    sudo dnf install -y htop procps-ng jq tree ncdu 2>/dev/null || true
                }
            else
                # Older systems with YUM
                sudo yum install -y htop procps-ng jq tree ncdu 2>/dev/null || true

                # Install fzf manually for older systems
                if ! command -v fzf &> /dev/null; then
                    print_info "Installing fzf from git..."
                    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                    ~/.fzf/install --all --no-update-rc --no-bash
                fi
            fi
            ;;

        "arch"|"manjaro")
            # Arch Linux with Pacman
            sudo pacman -S --noconfirm fzf htop procps-ng jq ripgrep fd bat tree ncdu 2>/dev/null || {
                # Install core tools if some are missing
                sudo pacman -S --noconfirm htop procps-ng jq tree ncdu 2>/dev/null || true
            }
            ;;

        "alpine")
            # Alpine Linux with APK
            sudo apk add --no-cache fzf htop procps jq ripgrep fd bat tree ncdu 2>/dev/null || {
                # Install core tools only
                sudo apk add --no-cache htop procps jq tree 2>/dev/null || true
            }
            ;;

        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed"|"sles")
            # openSUSE with Zypper
            sudo zypper install -y fzf htop procps jq ripgrep fd bat tree ncdu 2>/dev/null || {
                # Install core tools only
                sudo zypper install -y htop procps jq tree ncdu 2>/dev/null || true
            }
            ;;
    esac

    # Report installed tools
    print_success "Additional tools installation completed"

    # List which tools were successfully installed
    if [[ "$VERBOSE" == true ]]; then
        print_info "Checking installed tools:"
        for tool_desc in "${tools_to_install[@]}"; do
            local tool=$(echo $tool_desc | cut -d: -f1)
            if command -v $tool &> /dev/null; then
                echo "  ✓ $tool_desc"
            else
                echo "  ✗ $tool (not installed)"
            fi
        done
    fi
}

# Install TPM (Tmux Plugin Manager)
# TPM allows easy installation and management of tmux plugins
# Repository: https://github.com/tmux-plugins/tpm
install_tpm() {
    print_status "Installing Tmux Plugin Manager (TPM)..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install TPM to ~/.tmux/plugins/tpm"
        return 0
    fi

    local tpm_path="$HOME/.tmux/plugins/tpm"

    if [[ ! -d "$tpm_path" ]]; then
        # Clone TPM repository
        print_info "Cloning TPM repository..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_path" || {
            print_error "Failed to clone TPM repository"
            print_info "Please check your internet connection and git configuration"
            return 1
        }
        print_success "TPM installed successfully"
    else
        # Update existing TPM installation
        print_info "TPM already installed, checking for updates..."
        cd "$tpm_path" && git pull --quiet
        cd - > /dev/null
        print_success "TPM updated to latest version"
    fi

    # Create plugins directory if it doesn't exist
    mkdir -p "$HOME/.tmux/plugins"
}

# Create tmux configuration file
# Uses the comprehensive configuration from configs/tmux-standalone.conf
# Includes mouse support, vim bindings, and DevOps shortcuts
create_tmux_config() {
    print_status "Creating tmux configuration..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would create ~/.tmux.conf with enhanced configuration"
        return 0
    fi

    # Backup existing config if it exists
    if [[ -f ~/.tmux.conf ]]; then
        local backup_file="$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
        cp ~/.tmux.conf "$backup_file"
        print_info "Backed up existing config to $backup_file"
    fi

    # Create new tmux configuration
    # This configuration is optimized for DevOps workflows
    cat > ~/.tmux.conf << 'EOF'
# Standalone Tmux Configuration
# Optimized for productivity and DevOps workflows with enhanced mouse support
# Reload with: Prefix + r

# ============================================================================
# GENERAL SETTINGS
# ============================================================================

# Set default terminal to support 256 colors and true color (Tc)
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color*:Tc"

# Enable mouse support for selecting, scrolling, resizing
set -g mouse on

# Set clipboard integration for seamless copy/paste
set -g set-clipboard on

# Increase scrollback buffer size (default: 2000)
set -g history-limit 50000

# Start window and pane indexing at 1 (more intuitive)
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows sequentially after closing any of them
set -g renumber-windows on

# Enable focus events for vim/nvim autoread
set -g focus-events on

# Faster command sequences (default: 500ms)
set -s escape-time 10

# Increase repeat timeout for key sequences
set -g repeat-time 600

# ============================================================================
# KEY BINDINGS - PREFIX AND BASIC OPERATIONS
# ============================================================================

# Change prefix key to Ctrl-a (easier to reach than Ctrl-b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload configuration file with prefix + r
bind r source-file ~/.tmux.conf \; display-message "🔄 Config reloaded!"

# Better window splitting with visual characters
bind | split-window -h -c "#{pane_current_path}"  # Split vertically with |
bind - split-window -v -c "#{pane_current_path}"  # Split horizontally with -
unbind '"'
unbind %

# New window in current path
bind c new-window -c "#{pane_current_path}"

# ============================================================================
# NAVIGATION - VIM-STYLE MOVEMENTS
# ============================================================================

# Vim-like pane navigation (prefix + hjkl)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing with vim keys (prefix + HJKL)
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Window navigation with Ctrl+h/l
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+

# Quick session switching
bind S choose-session

# Kill session with confirmation
bind X confirm-before -p "Kill session #S? (y/n)" kill-session


# ============================================================================
# COPY MODE CONFIGURATION - VIM BINDINGS
# ============================================================================

# Use vim keybindings in copy mode
setw -g mode-keys vi

# Enter copy mode with prefix + [ or Alt + [
bind [ copy-mode
bind -n M-[ copy-mode

# Copy mode key bindings
bind -T copy-mode-vi v send-keys -X begin-selection     # Start selection with v
bind -T copy-mode-vi r send-keys -X rectangle-toggle    # Rectangle selection with r
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle  # Rectangle selection with Ctrl-v
bind -T copy-mode-vi q send-keys -X cancel              # Exit with q
bind -T copy-mode-vi Escape send-keys -X cancel         # Exit with Escape

# Platform-specific copy commands (y to copy)
if-shell "uname | grep -q Darwin" \
    "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'" \
    "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'"

# ============================================================================
# MOUSE CONFIGURATION - SCROLLING, SELECTING, COPYING
# ============================================================================

# Mouse wheel scrolling - enters copy mode automatically
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M

# Scroll 3 lines at a time (adjust for faster/slower scrolling)
bind -T copy-mode-vi WheelUpPane send-keys -X -N 3 scroll-up
bind -T copy-mode-vi WheelDownPane send-keys -X -N 3 scroll-down

# Mouse selection - start selection on drag
bind -T copy-mode-vi MouseDrag1Pane select-pane \; send-keys -X begin-selection

# Platform-specific mouse copy on release (stays in copy mode)
if-shell "uname | grep -q Darwin" {
    # macOS
    bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "pbcopy"
    bind -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X copy-pipe "pbcopy"
    bind -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X copy-pipe "pbcopy"
} {
    # Linux - auto-detect clipboard utility
    if-shell "command -v xclip > /dev/null" {
        bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "xclip -in -selection clipboard"
        bind -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X copy-pipe "xclip -in -selection clipboard"
        bind -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X copy-pipe "xclip -in -selection clipboard"
    } {
        bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "xsel -ib"
        bind -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; send-keys -X copy-pipe "xsel -ib"
        bind -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; send-keys -X copy-pipe "xsel -ib"
    }
}

# Clear selection on single click
bind -T copy-mode-vi MouseDown1Pane select-pane \; send-keys -X clear-selection

# Middle click to paste from tmux buffer
bind -n MouseDown2Pane paste-buffer

# Right click context menu (optional)
bind -n MouseDown3Pane display-menu -x M -y M \
    "Copy" c "copy-mode" \
    "Paste" p "paste-buffer" \
    "Cancel" q ""

# Shift+MouseDrag to bypass tmux (useful for selecting in vim)
bind -n S-MouseDrag1Pane set -q @mouse-orig-status $status \; set -g mouse off
bind -n S-MouseDragEnd1Pane set -g mouse on \; display-message "Mouse re-enabled"

# ============================================================================
# STATUS BAR CONFIGURATION
# ============================================================================

# Status bar colors and styling
set -g status-bg colour235
set -g status-fg colour255
set -g status-interval 5

# Status bar position
set -g status-position bottom

# Status bar format
set -g status-left-length 50
set -g status-right-length 100

# Left side: session name with icon
set -g status-left "#[fg=colour39,bg=colour235,bold] #S #[fg=colour245]| "

# Right side: prefix indicator, time, date, user@host
set -g status-right "#[fg=colour245]#{?client_prefix,🔴 ,}#[fg=colour39]%H:%M #[fg=colour245]| #[fg=colour39]%d-%b #[fg=colour245]| #[fg=colour39]#(whoami)@#h"

# Window status format
setw -g window-status-format "#[fg=colour245] #I:#W "
setw -g window-status-current-format "#[fg=colour39,bg=colour238,bold] #I:#W "

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off
setw -g window-status-activity-style "fg=colour196,bg=colour235"

# ============================================================================
# PANE STYLING
# ============================================================================

# Pane borders
set -g pane-border-style "fg=colour238"
set -g pane-active-border-style "fg=colour39"

# Message styling
set -g message-style "fg=colour255,bg=colour238,bold"
set -g message-command-style "fg=colour255,bg=colour238,bold"

# ============================================================================
# DEVOPS SHORTCUTS
# ============================================================================

# Quick system monitoring with htop/top
bind-key -r i split-window -h "htop || top"

# Docker container monitoring (uppercase D to avoid conflict with detach)
bind-key -r D split-window -h "if command -v docker &> /dev/null; then docker ps -a; echo ''; echo 'Press Enter to monitor containers:'; read; docker stats; else echo 'Docker not installed'; fi"

# System log monitoring (auto-detects available log system)
bind-key -r L split-window -h "if [ -f /var/log/syslog ]; then tail -f /var/log/syslog; elif [ -f /var/log/messages ]; then tail -f /var/log/messages; else journalctl -f; fi"

# Kubernetes shortcuts (if kubectl is available)
bind-key -r K new-window -n "k8s" "if command -v kubectl &> /dev/null; then kubectl get pods --all-namespaces; else echo 'kubectl not found'; fi"

# Network connections monitoring
bind-key -r N split-window -h "if command -v ss &> /dev/null; then watch -n 1 'ss -tunap | grep ESTABLISHED'; else watch -n 1 'netstat -tunap | grep ESTABLISHED'; fi"

# ============================================================================
# PLUGIN CONFIGURATION
# ============================================================================

# List of plugins
set -g @plugin 'tmux-plugins/tpm'              # Tmux Plugin Manager
set -g @plugin 'tmux-plugins/tmux-sensible'    # Sensible defaults
set -g @plugin 'tmux-plugins/tmux-resurrect'   # Session persistence
set -g @plugin 'tmux-plugins/tmux-continuum'   # Automatic save/restore
set -g @plugin 'tmux-plugins/tmux-yank'        # Enhanced copy/paste

# Plugin configurations
# Resurrect - save/restore sessions across restarts
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'

# Continuum - automatic session saves
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# ============================================================================
# MOUSE OPERATIONS QUICK REFERENCE
# ============================================================================
# Scroll up/down       - Mouse wheel (enters copy mode automatically)
# Select text          - Click and drag (copies on release)
# Select word          - Double-click
# Select line          - Triple-click
# Rectangle select     - Enter copy mode, press 'r', then drag
# Paste                - Middle-click
# Clear selection      - Single click
# Exit copy mode       - q or Escape
# Bypass tmux          - Hold Shift while selecting (for vim/app selection)
# Toggle mouse         - Prefix + m (custom binding below)
# ============================================================================

# Toggle mouse on/off (useful for terminal app selection)
bind m set -g mouse \; display-message "Mouse #{?mouse,on,off}"

# Initialize TMUX plugin manager (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF

    print_success "Tmux configuration created successfully"
}

# Create utility scripts for tmux workflow enhancement
# Includes: sessionizer (quick session switcher)
#           project-manager (DevOps project layouts)
create_scripts() {
    print_status "Creating utility scripts..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would create tmux-sessionizer and tmux-project-manager scripts"
        return 0
    fi

    # Create local bin directory for user scripts
    mkdir -p ~/.local/bin

    # Ensure ~/.local/bin is in PATH
    if [[ ! "$PATH" == *"$HOME/.local/bin"* ]]; then
        print_warning "~/.local/bin is not in PATH. Will add to shell config later."
    fi

    # ============================================================================
    # TMUX SESSIONIZER SCRIPT
    # Quick project navigation and session management
    # ============================================================================
    cat > ~/.local/bin/tmux-sessionizer << 'EOF'
#!/usr/bin/env bash

# ============================================================================
# TMUX SESSIONIZER - Quick Project Session Management
# ============================================================================
# Purpose: Quickly switch between project directories in tmux sessions
# Usage: tmux-sessionizer [directory]
#
# Features:
#   - Fuzzy search through common project directories
#   - Automatic session creation/attachment
#   - Smart session naming (replaces dots with underscores)
#   - Works both inside and outside tmux
#
# Example:
#   tmux-sessionizer              # Interactive directory selection
#   tmux-sessionizer ~/Work/app   # Direct session creation for specific path
# ============================================================================

# Check if a specific directory was provided as argument
if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Define common project directories to search
    # Customize this list based on your workflow
    dirs=(
        "$HOME"
        "$HOME/Work"
        "$HOME/Projects"
        "$HOME/Dev"
        "$HOME/Development"
        "$HOME/Code"
        "$HOME/Documents/Projects"
        "$HOME/src"
        "/opt"
        "/var/www"
        "/srv"
        "$HOME/.config"
        "$HOME/.dotfiles"
    )

    # Find directories that exist
    existing_dirs=()
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            existing_dirs+=("$dir")
        fi
    done

    if command -v fzf &> /dev/null && [[ ${#existing_dirs[@]} -gt 0 ]]; then
        selected=$(find "${existing_dirs[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf)
    else
        echo "Available directories:"
        for i in "${!existing_dirs[@]}"; do
            echo "$((i+1)). ${existing_dirs[$i]}"
        done
        read -p "Select directory (1-${#existing_dirs[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#existing_dirs[@]}" ]]; then
            selected="${existing_dirs[$((choice-1))]}"
        else
            echo "Invalid selection"
            exit 1
        fi
    fi
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -d -s "$selected_name" -c "$selected"
fi

if [[ -z $TMUX ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
EOF

    chmod +x ~/.local/bin/tmux-sessionizer

    # ============================================================================
    # TMUX PROJECT MANAGER SCRIPT
    # Advanced project session management with DevOps layouts
    # ============================================================================
    cat > ~/.local/bin/tmux-project-manager << 'EOF'
#!/usr/bin/env bash

# ============================================================================
# TMUX PROJECT MANAGER - DevOps Project Session Management
# ============================================================================
# Purpose: Manage complex project sessions with predefined layouts
# Usage: tmux-project-manager [COMMAND] [PROJECT_NAME]
#
# Commands:
#   create <name>     Create a new project session with DevOps layout
#   list              List all active tmux sessions
#   attach <name>     Attach to existing project session
#   kill <name>       Kill a specific project session
#   killall           Kill all tmux sessions
#   layout <name>     Apply DevOps layout to existing session
#   save <name>       Save session layout for later restoration
#   restore <name>    Restore previously saved session layout
#
# Example:
#   tmux-project-manager create myapp
#   tmux-project-manager layout myapp
#   tmux-project-manager attach myapp
# ============================================================================

# Configuration
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Work}"
SESSIONS_CONFIG="$HOME/.tmux-projects.conf"
LAYOUTS_DIR="$HOME/.tmux-layouts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Display usage information
usage() {
    echo -e "${CYAN}Tmux Project Manager${NC}"
    echo -e "${CYAN}====================${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [PROJECT_NAME]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}create${NC} <name>     Create a new project session"
    echo -e "  ${GREEN}list${NC}              List all active sessions"
    echo -e "  ${GREEN}attach${NC} <name>     Attach to existing session"
    echo -e "  ${GREEN}kill${NC} <name>       Kill a project session"
    echo -e "  ${GREEN}killall${NC}           Kill all sessions"
    echo -e "  ${GREEN}layout${NC} <name>     Setup DevOps layout"
    echo -e "  ${GREEN}save${NC} <name>       Save session layout"
    echo -e "  ${GREEN}restore${NC} <name>    Restore session layout"
    echo -e "  ${GREEN}help${NC}              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create my-app"
    echo "  $0 attach my-app"
    echo "  $0 layout my-app"
    echo ""
    echo "Project Directory: $PROJECTS_DIR"
}

# Create a new project session with standard DevOps layout
create_session() {
    local project_name="$1"
    local project_path="$PROJECTS_DIR/$project_name"

    # Check if session already exists
    if tmux has-session -t "$project_name" 2>/dev/null; then
        echo -e "${YELLOW}⚠ Session '$project_name' already exists${NC}"
        read -p "Attach to it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            attach_session "$project_name"
        fi
        return
    fi

    echo -e "${GREEN}Creating session: $project_name${NC}"

    # Create project directory if it doesn't exist
    if [[ ! -d "$project_path" ]]; then
        echo -e "${YELLOW}Creating project directory: $project_path${NC}"
        mkdir -p "$project_path"
    fi

    # Create base session with multiple windows
    tmux new-session -d -s "$project_name" -c "$project_path" -n "editor"

    # Window 2: Terminal (with splits for multiple terminals)
    tmux new-window -t "$project_name:2" -n "terminal" -c "$project_path"
    tmux split-window -t "$project_name:terminal" -h -c "$project_path"
    tmux split-window -t "$project_name:terminal.1" -v -c "$project_path"

    # Window 3: Logs (for monitoring application and system logs)
    tmux new-window -t "$project_name:3" -n "logs" -c "$project_path"

    # Window 4: Monitoring (for system monitoring tools)
    tmux new-window -t "$project_name:4" -n "monitoring" -c "$project_path"

    # Window 5: Docker/K8s (for container management)
    tmux new-window -t "$project_name:5" -n "containers" -c "$project_path"

    # Window 6: Database (for database connections)
    tmux new-window -t "$project_name:6" -n "database" -c "$project_path"

    # Window 7: API Testing (for curl, httpie, etc.)
    tmux new-window -t "$project_name:7" -n "api" -c "$project_path"

    # Window 8: Git (for version control)
    tmux new-window -t "$project_name:8" -n "git" -c "$project_path"

    # Setup initial commands in windows
    setup_window_commands "$project_name" "$project_path"

    # Focus on editor window
    tmux select-window -t "$project_name:editor"

    echo -e "${GREEN}✓ Session '$project_name' created successfully${NC}"
    echo -e "${CYAN}Run '$0 attach $project_name' to enter the session${NC}"
}

# Setup initial commands in windows
setup_window_commands() {
    local project_name="$1"
    local project_path="$2"

    # Editor window - clear and show project info
    tmux send-keys -t "$project_name:editor" "clear" C-m
    tmux send-keys -t "$project_name:editor" "echo 'Project: $project_name'" C-m
    tmux send-keys -t "$project_name:editor" "echo 'Path: $project_path'" C-m
    tmux send-keys -t "$project_name:editor" "echo ''" C-m
    tmux send-keys -t "$project_name:editor" "# Start coding here or open your editor" C-m

    # Monitoring window - start htop if available
    if command -v htop &> /dev/null; then
        tmux send-keys -t "$project_name:monitoring" "htop" C-m
    else
        tmux send-keys -t "$project_name:monitoring" "top" C-m
    fi

    # Docker window - show docker status
    if command -v docker &> /dev/null; then
        tmux send-keys -t "$project_name:containers" "docker ps -a" C-m
    else
        tmux send-keys -t "$project_name:containers" "echo 'Docker not installed'" C-m
    fi

    # Git window - show git status
    tmux send-keys -t "$project_name:git" "git status 2>/dev/null || echo 'Not a git repository'" C-m
}

# Setup advanced DevOps layout for existing session
setup_devops_layout() {
    local project_name="$1"
    local project_path="$PROJECTS_DIR/$project_name"

    if ! tmux has-session -t "$project_name" 2>/dev/null; then
        echo -e "${RED}✗ Session '$project_name' does not exist${NC}"
        echo -e "${CYAN}Creating it first...${NC}"
        create_session "$project_name"
        return
    fi

    echo -e "${GREEN}Setting up DevOps layout for: $project_name${NC}"

    # Logs window - split for multiple log streams
    tmux select-window -t "$project_name:logs"
    tmux split-window -t "$project_name:logs" -h -c "$project_path"

    # Left pane: Application logs
    tmux send-keys -t "$project_name:logs.0" "clear" C-m
    tmux send-keys -t "$project_name:logs.0" "# Application logs" C-m
    tmux send-keys -t "$project_name:logs.0" "tail -f *.log 2>/dev/null || echo 'No log files found'" C-m

    # Right pane: System logs
    tmux send-keys -t "$project_name:logs.1" "# System logs" C-m
    if [[ -f /var/log/syslog ]]; then
        tmux send-keys -t "$project_name:logs.1" "tail -f /var/log/syslog" C-m
    elif command -v journalctl &> /dev/null; then
        tmux send-keys -t "$project_name:logs.1" "journalctl -f" C-m
    else
        tmux send-keys -t "$project_name:logs.1" "echo 'No system logs accessible'" C-m
    fi

    # Monitoring window - split for different monitoring tools
    tmux select-window -t "$project_name:monitoring"
    tmux split-window -t "$project_name:monitoring" -h -c "$project_path"
    tmux split-window -t "$project_name:monitoring.1" -v -c "$project_path"

    # Top-left: htop/top
    # Already set up in create_session

    # Top-right: Docker stats
    if command -v docker &> /dev/null; then
        tmux send-keys -t "$project_name:monitoring.1" "watch -n 2 'docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\"'" C-m
    fi

    # Bottom-right: Network connections
    if command -v ss &> /dev/null; then
        tmux send-keys -t "$project_name:monitoring.2" "watch -n 5 'ss -tunlp 2>/dev/null | head -20'" C-m
    else
        tmux send-keys -t "$project_name:monitoring.2" "watch -n 5 'netstat -tunlp 2>/dev/null | head -20'" C-m
    fi

    echo -e "${GREEN}✓ DevOps layout configured for '$project_name'${NC}"
}

# List all active tmux sessions
list_sessions() {
    echo -e "${BLUE}Active tmux sessions:${NC}"
    echo -e "${BLUE}====================${NC}"

    if tmux list-sessions 2>/dev/null; then
        echo ""
        echo -e "${CYAN}Tip: Use '$0 attach <name>' to connect to a session${NC}"
    else
        echo "No active sessions"
        echo ""
        echo -e "${CYAN}Tip: Use '$0 create <name>' to create a new session${NC}"
    fi
}

# Attach to existing session
attach_session() {
    local project_name="$1"

    if tmux has-session -t "$project_name" 2>/dev/null; then
        if [[ -z $TMUX ]]; then
            # Not inside tmux, attach normally
            tmux attach-session -t "$project_name"
        else
            # Inside tmux, switch to the session
            tmux switch-client -t "$project_name"
        fi
    else
        echo -e "${RED}✗ Session '$project_name' does not exist${NC}"
        echo ""
        list_sessions
    fi
}

# Kill a specific session
kill_session() {
    local project_name="$1"

    if tmux has-session -t "$project_name" 2>/dev/null; then
        echo -e "${YELLOW}⚠ Killing session '$project_name'...${NC}"
        tmux kill-session -t "$project_name"
        echo -e "${GREEN}✓ Session '$project_name' killed${NC}"
    else
        echo -e "${RED}✗ Session '$project_name' does not exist${NC}"
    fi
}

# Kill all tmux sessions
kill_all_sessions() {
    echo -e "${YELLOW}⚠ This will kill ALL tmux sessions!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmux kill-server 2>/dev/null || echo "No sessions to kill"
        echo -e "${GREEN}✓ All sessions killed${NC}"
    else
        echo "Cancelled"
    fi
}

# Save session layout
save_layout() {
    local project_name="$1"

    if ! tmux has-session -t "$project_name" 2>/dev/null; then
        echo -e "${RED}✗ Session '$project_name' does not exist${NC}"
        return 1
    fi

    mkdir -p "$LAYOUTS_DIR"
    local layout_file="$LAYOUTS_DIR/${project_name}.layout"

    echo -e "${YELLOW}Saving layout for session '$project_name'...${NC}"

    # Save window list and layouts
    tmux list-windows -t "$project_name" -F "#{window_index}:#{window_name}:#{window_layout}" > "$layout_file"

    echo -e "${GREEN}✓ Layout saved to $layout_file${NC}"
}

# Restore session layout
restore_layout() {
    local project_name="$1"
    local layout_file="$LAYOUTS_DIR/${project_name}.layout"

    if [[ ! -f "$layout_file" ]]; then
        echo -e "${RED}✗ No saved layout found for '$project_name'${NC}"
        return 1
    fi

    echo -e "${YELLOW}Restoring layout for session '$project_name'...${NC}"

    # Create session if it doesn't exist
    if ! tmux has-session -t "$project_name" 2>/dev/null; then
        create_session "$project_name"
    fi

    # Restore window layouts
    while IFS=: read -r index name layout; do
        tmux select-window -t "$project_name:$index" 2>/dev/null
        tmux select-layout -t "$project_name:$index" "$layout" 2>/dev/null
    done < "$layout_file"

    echo -e "${GREEN}✓ Layout restored for '$project_name'${NC}"
}

# Main script logic
case "${1:-help}" in
    create)
        if [[ -z "$2" ]]; then
            echo -e "${RED}✗ Error: Project name required${NC}"
            usage
            exit 1
        fi
        create_session "$2"
        ;;
    list|ls)
        list_sessions
        ;;
    attach|a)
        if [[ -z "$2" ]]; then
            echo -e "${RED}✗ Error: Project name required${NC}"
            usage
            exit 1
        fi
        attach_session "$2"
        ;;
    kill|k)
        if [[ -z "$2" ]]; then
            echo -e "${RED}✗ Error: Project name required${NC}"
            usage
            exit 1
        fi
        kill_session "$2"
        ;;
    killall|ka)
        kill_all_sessions
        ;;
    layout|l)
        if [[ -z "$2" ]]; then
            echo -e "${RED}✗ Error: Project name required${NC}"
            usage
            exit 1
        fi
        setup_devops_layout "$2"
        ;;
    save|s)
        if [[ -z "$2" ]]; then
            echo -e "${RED}✗ Error: Project name required${NC}"
            usage
            exit 1
        fi
        save_layout "$2"
        ;;
    restore|r)
        if [[ -z "$2" ]]; then
            echo -e "${RED}✗ Error: Project name required${NC}"
            usage
            exit 1
        fi
        restore_layout "$2"
        ;;
    help|--help|-h|"")
        usage
        ;;
    *)
        echo -e "${RED}✗ Error: Unknown command '$1'${NC}"
        usage
        exit 1
        ;;
esac
EOF

    chmod +x ~/.local/bin/tmux-project-manager

    print_success "Utility scripts created successfully"

    # List created scripts
    print_info "Created scripts:"
    echo "  • tmux-sessionizer - Quick session switching"
    echo "  • tmux-project-manager - Advanced project management"
}

# Install tmux plugins using TPM
# This function installs all plugins defined in .tmux.conf
install_plugins() {
    print_status "Installing tmux plugins..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install tmux plugins via TPM"
        return 0
    fi

    # Check if TPM is installed
    if [[ ! -d ~/.tmux/plugins/tpm ]]; then
        print_warning "TPM not found. Installing TPM first..."
        install_tpm
    fi

    # Start a temporary tmux server to install plugins
    print_info "Starting tmux server for plugin installation..."
    tmux new-session -d -s __temp_plugin_install__ 2>/dev/null || true
    sleep 2

    # Install plugins
    if [[ -f ~/.tmux/plugins/tpm/bin/install_plugins ]]; then
        ~/.tmux/plugins/tpm/bin/install_plugins
        print_success "Plugins installed successfully"
    else
        print_warning "TPM plugin installer not found. Plugins will install on first tmux start."
    fi

    # Kill temporary session
    tmux kill-session -t __temp_plugin_install__ 2>/dev/null || true
}

# Setup shell integration (aliases, PATH, completions)
# Adds tmux aliases and ensures scripts are in PATH
setup_shell() {
    print_status "Setting up shell integration..."

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would add tmux aliases and PATH configuration"
        return 0
    fi

    # Detect user's shell
    local user_shell=$(basename "$SHELL")
    local shell_configs=()

    # Determine which shell config files to update
    case "$user_shell" in
        bash)
            shell_configs=(~/.bashrc ~/.bash_profile)
            ;;
        zsh)
            shell_configs=(~/.zshrc)
            ;;
        fish)
            shell_configs=(~/.config/fish/config.fish)
            ;;
        *)
            # Fallback to common configs
            shell_configs=(~/.bashrc ~/.zshrc ~/.profile)
            ;;
    esac

    local config_added=false

    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            print_info "Updating $config..."

            # Add ~/.local/bin to PATH if not already there
            if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$config" 2>/dev/null; then
                echo '' >> "$config"
                echo '# Added by tmux installer' >> "$config"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$config"
            fi

            # Add tmux aliases if they don't exist
            if ! grep -q "alias tm=" "$config" 2>/dev/null; then
                cat >> "$config" << 'ALIASES'

# ============================================================================
# TMUX ALIASES - Added by tmux installer
# ============================================================================
# Basic tmux commands
alias tm='tmux'                           # Start tmux
alias tma='tmux attach-session -t'        # Attach to session by name
alias tmn='tmux new-session -s'           # Create new session with name
alias tml='tmux list-sessions'            # List all sessions
alias tmk='tmux kill-session -t'          # Kill session by name
alias tmks='tmux kill-server'             # Kill all sessions

# Custom scripts
alias tms='tmux-sessionizer'              # Quick session switcher
alias tmp='tmux-project-manager'          # Project manager
alias tmpl='tmux-project-manager list'    # List projects
alias tmpc='tmux-project-manager create'  # Create project
alias tmpa='tmux-project-manager attach'  # Attach to project

# Window and pane management
alias tmw='tmux list-windows'             # List windows
alias tmpn='tmux list-panes'              # List panes

# Quick session switching function
tmux-switch() {
    local session
    session=$(tmux list-sessions -F "#S" 2>/dev/null | fzf --height=10 --border --header="Select session:")
    [[ -n "$session" ]] && tmux switch-client -t "$session" || tmux attach-session -t "$session"
}
alias tmsw='tmux-switch'
ALIASES
                config_added=true
                print_success "Added tmux aliases to $config"
            fi

            # Add tmux completion for bash
            if [[ "$user_shell" == "bash" ]] && [[ "$config" == *bashrc* ]]; then
                if ! grep -q "_tmux_completion" "$config" 2>/dev/null; then
                    cat >> "$config" << 'COMPLETION'

# Tmux bash completion
if [ -f /usr/share/bash-completion/completions/tmux ]; then
    . /usr/share/bash-completion/completions/tmux
elif [ -f /etc/bash_completion.d/tmux ]; then
    . /etc/bash_completion.d/tmux
fi
COMPLETION
                fi
            fi
        fi
    done

    if [[ "$config_added" == "true" ]]; then
        print_warning "Shell configuration updated. Restart your shell or run:"
        echo "         source ${shell_configs[0]}"
    else
        print_info "Shell aliases already configured"
    fi
}

# Verify tmux installation and configuration
verify_installation() {
    print_status "Verifying tmux installation..."
    echo ""

    local checks_passed=0
    local checks_failed=0

    # Check tmux installation
    echo -n "Checking tmux binary... "
    if command -v tmux &> /dev/null; then
        echo -e "${GREEN}✓${NC} $(tmux -V)"
        ((checks_passed++))
    else
        echo -e "${RED}✗${NC} Not found"
        ((checks_failed++))
    fi

    # Check TPM installation
    echo -n "Checking TPM installation... "
    if [[ -d ~/.tmux/plugins/tpm ]]; then
        echo -e "${GREEN}✓${NC} Installed"
        ((checks_passed++))
    else
        echo -e "${RED}✗${NC} Not found"
        ((checks_failed++))
    fi

    # Check tmux config
    echo -n "Checking tmux configuration... "
    if [[ -f ~/.tmux.conf ]]; then
        echo -e "${GREEN}✓${NC} Found"
        ((checks_passed++))
    else
        echo -e "${RED}✗${NC} Not found"
        ((checks_failed++))
    fi

    # Check utility scripts
    echo -n "Checking tmux-sessionizer... "
    if [[ -x ~/.local/bin/tmux-sessionizer ]]; then
        echo -e "${GREEN}✓${NC} Installed"
        ((checks_passed++))
    else
        echo -e "${RED}✗${NC} Not found"
        ((checks_failed++))
    fi

    echo -n "Checking tmux-project-manager... "
    if [[ -x ~/.local/bin/tmux-project-manager ]]; then
        echo -e "${GREEN}✓${NC} Installed"
        ((checks_passed++))
    else
        echo -e "${RED}✗${NC} Not found"
        ((checks_failed++))
    fi

    # Check PATH
    echo -n "Checking PATH configuration... "
    if [[ "$PATH" == *"$HOME/.local/bin"* ]]; then
        echo -e "${GREEN}✓${NC} Configured"
        ((checks_passed++))
    else
        echo -e "${YELLOW}⚠${NC} Not in current PATH (will be added on next shell start)"
    fi

    # Check for additional tools
    echo ""
    echo "Additional tools:"
    local tools=("fzf" "htop" "jq" "ripgrep" "fd" "bat")
    for tool in "${tools[@]}"; do
        echo -n "  $tool: "
        if command -v $tool &> /dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}-${NC} (optional)"
        fi
    done

    # Summary
    echo ""
    echo "====================================="
    echo "Verification Summary:"
    echo "  Checks passed: ${GREEN}$checks_passed${NC}"
    if [[ $checks_failed -gt 0 ]]; then
        echo "  Checks failed: ${RED}$checks_failed${NC}"
        echo ""
        echo "Run '$0' to complete installation"
        return 1
    else
        echo ""
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo ""
        echo "Quick start:"
        echo "  tmux              - Start tmux"
        echo "  tms               - Quick session switcher"
        echo "  tmp create myapp  - Create project session"
        return 0
    fi
}

# Uninstall tmux configuration (keeps tmux installed)
uninstall_tmux_config() {
    print_warning "This will remove tmux configuration files"
    print_info "Tmux itself will remain installed"
    echo ""
    read -p "Continue with uninstall? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled"
        return 0
    fi

    print_status "Removing tmux configuration..."

    # Backup before removing
    local backup_dir="$HOME/.tmux-uninstall-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Move files to backup
    [[ -f ~/.tmux.conf ]] && mv ~/.tmux.conf "$backup_dir/"
    [[ -d ~/.tmux ]] && mv ~/.tmux "$backup_dir/"
    [[ -f ~/.local/bin/tmux-sessionizer ]] && mv ~/.local/bin/tmux-sessionizer "$backup_dir/"
    [[ -f ~/.local/bin/tmux-project-manager ]] && mv ~/.local/bin/tmux-project-manager "$backup_dir/"

    print_success "Configuration removed. Backup saved to: $backup_dir"
    print_info "To restore: cp -r $backup_dir/.* ~/"
}

# Main installation function
main() {
    # Parse command line arguments first
    parse_arguments "$@"

    # Show banner
    show_banner

    print_status "Starting tmux installation..."
    echo ""

    # Detect operating system
    detect_os

    # Check privileges
    check_privileges

    # Skip installations if config-only mode
    if [[ "$CONFIG_ONLY" == false ]]; then
        # Install tmux if not present
        if ! command -v tmux &> /dev/null; then
            install_tmux
        else
            local tmux_version=$(tmux -V | cut -d' ' -f2)
            print_success "Tmux is already installed (version $tmux_version)"
        fi

        # Install additional tools
        install_additional_tools
    else
        print_info "Skipping installations (--config-only mode)"
    fi

    # Install TPM
    install_tpm

    # Create configuration
    create_tmux_config

    # Create utility scripts
    create_scripts

    # Install plugins
    install_plugins

    # Setup shell integration
    setup_shell

    echo ""
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     🎉 Tmux Installation Completed Successfully!        ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${CYAN}Quick Start Guide:${NC}"
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│ ${YELLOW}Basic Commands:${NC}                                        │"
    echo "│   ${GREEN}tmux${NC}                    Start new tmux session       │"
    echo "│   ${GREEN}tm${NC}                      Tmux shortcut alias          │"
    echo "│   ${GREEN}tml${NC}                     List all sessions            │"
    echo "│   ${GREEN}tma <name>${NC}             Attach to session            │"
    echo "│                                                        │"
    echo "│ ${YELLOW}Advanced Tools:${NC}                                       │"
    echo "│   ${GREEN}tms${NC}                     Quick session switcher       │"
    echo "│   ${GREEN}tmp create <name>${NC}      Create project with layout   │"
    echo "│   ${GREEN}tmp list${NC}               List all project sessions    │"
    echo "│   ${GREEN}tmp attach <name>${NC}      Attach to project            │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""

    echo -e "${CYAN}Essential Key Bindings:${NC}"
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│ ${YELLOW}Prefix Key: ${MAGENTA}Ctrl-a${NC}                                    │"
    echo "│                                                        │"
    echo "│ ${YELLOW}Pane Management:${NC}                                      │"
    echo "│   ${GREEN}Prefix + |${NC}             Split pane vertically        │"
    echo "│   ${GREEN}Prefix + -${NC}             Split pane horizontally      │"
    echo "│   ${GREEN}Prefix + h/j/k/l${NC}       Navigate panes (vim-style)   │"
    echo "│   ${GREEN}Prefix + H/J/K/L${NC}       Resize panes                 │"
    echo "│                                                        │"
    echo "│ ${YELLOW}Window Management:${NC}                                    │"
    echo "│   ${GREEN}Prefix + c${NC}             Create new window            │"
    echo "│   ${GREEN}Prefix + n/p${NC}           Next/Previous window         │"
    echo "│   ${GREEN}Prefix + [0-9]${NC}         Switch to window by number   │"
    echo "│                                                        │"
    echo "│ ${YELLOW}Session Management:${NC}                                   │"
    echo "│   ${GREEN}Prefix + d${NC}             Detach from session          │"
    echo "│   ${GREEN}Prefix + S${NC}             Switch sessions              │"
    echo "│   ${GREEN}Prefix + X${NC}             Kill session (with confirm)  │"
    echo "│                                                        │"
    echo "│ ${YELLOW}Copy Mode (vim bindings):${NC}                             │"
    echo "│   ${GREEN}Prefix + [${NC}             Enter copy mode              │"
    echo "│   ${GREEN}v${NC}                      Start selection              │"
    echo "│   ${GREEN}y${NC}                      Copy selection               │"
    echo "│   ${GREEN}q${NC}                      Exit copy mode               │"
    echo "│                                                        │"
    echo "│ ${YELLOW}DevOps Shortcuts:${NC}                                     │"
    echo "│   ${GREEN}Prefix + i${NC}             Open htop/top                │"
    echo "│   ${GREEN}Prefix + D${NC}             Docker container monitor     │"
    echo "│   ${GREEN}Prefix + L${NC}             System log viewer            │"
    echo "│   ${GREEN}Prefix + K${NC}             Kubernetes pods view         │"
    echo "│   ${GREEN}Prefix + N${NC}             Network connections          │"
    echo "│                                                        │"
    echo "│ ${YELLOW}Mouse Operations:${NC}                                     │"
    echo "│   ${GREEN}Scroll${NC}                 Enter copy mode & scroll     │"
    echo "│   ${GREEN}Click & Drag${NC}           Select text                  │"
    echo "│   ${GREEN}Middle Click${NC}           Paste                        │"
    echo "│   ${GREEN}Prefix + m${NC}             Toggle mouse on/off          │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""

    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "  2. Run '${GREEN}tmux${NC}' to start your first session"
    echo "  3. Run '${GREEN}$0 --verify${NC}' to check installation"
    echo "  4. Run '${GREEN}$0 --help${NC}' for more options"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Note: This was a dry run. No changes were made.${NC}"
        echo -e "      Run without --dry-run to perform actual installation."
    fi
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================
# Run main function if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
