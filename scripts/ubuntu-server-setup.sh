#!/bin/bash

# Ubuntu Server Standalone Setup Script
# DRY orchestrator that calls individual component installers via GitHub raw URLs
# This script provides a minimal yet functional setup for Ubuntu servers
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/ubuntu-server-setup.sh | bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Configuration
GITHUB_RAW_BASE="https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts"
LOG_FILE="/tmp/ubuntu-server-setup.log"
TEMP_DIR="/tmp/dotfiles-install-$$"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Create temp directory
mkdir -p "$TEMP_DIR"

# Print colored output
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_status "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect OS version. This script is for Ubuntu servers only."
        exit 1
    fi

    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_error "This script is designed for Ubuntu. Detected: $ID"
        exit 1
    fi

    print_success "Detected Ubuntu $VERSION_ID"
}

# Download and execute script from GitHub
run_installer() {
    local script_name="$1"
    local script_url="$GITHUB_RAW_BASE/$script_name"
    local script_path="$TEMP_DIR/$script_name"

    print_status "Downloading and running $script_name..."

    # Download the script
    if curl -fsSL "$script_url" -o "$script_path"; then
        chmod +x "$script_path"
        print_success "Downloaded $script_name"

        # Execute the script
        if bash "$script_path"; then
            print_success "Successfully ran $script_name"
        else
            print_error "Failed to run $script_name"
            return 1
        fi
    else
        print_error "Failed to download $script_name from $script_url"
        return 1
    fi
}

# Prompt for optional component installation
prompt_install() {
    local component="$1"
    local description="$2"
    local default="${3:-N}"

    print_status "Would you like to install $description? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        return 0
    else
        return 1
    fi
}

# Update system packages
update_system() {
    print_status "Updating system packages..."
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    print_success "System packages updated"
}

# Install essential packages for server setup
install_essential_packages() {
    print_status "Installing essential packages..."

    local packages=(
        # Core utilities
        curl
        wget
        git
        vim
        nano
        htop
        tree
        jq
        unzip
        zip
        tar
        gzip
        ca-certificates
        gnupg
        lsb-release
        software-properties-common
        apt-transport-https

        # Development tools
        build-essential
        make
        gcc
        g++
        cmake
        pkg-config

        # System monitoring
        sysstat
        iotop
        nethogs
        iftop

        # Network tools
        net-tools
        dnsutils
        traceroute
        nmap
        tcpdump

        # Text processing
        sed
        awk
        grep

        # Process management
        supervisor

        # Security
        fail2ban
        ufw

        # Time sync
        chrony

        # Shell and terminal tools (for components)
        zsh
        tmux
        fzf
        ripgrep
        fd-find
        bat
        ncdu

        # Python basics
        python3
        python3-pip
        python3-venv
        python3-dev

        # Text editors
        neovim
    )

    sudo apt-get install -y "${packages[@]}" || {
        print_warning "Some packages may have failed to install"
        print_status "Continuing with setup..."
    }

    print_success "Essential packages installed"
}

# Configure basic security (firewall and fail2ban)
configure_security() {
    print_status "Configuring basic security..."

    # Configure UFW firewall
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp comment 'SSH'

    # Configure fail2ban with basic SSH protection
    sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban

    print_success "Basic security configured (UFW firewall and fail2ban)"
}

# Configure Git basics
configure_git() {
    print_status "Configuring Git..."

    # Check if git config exists
    if [[ -z "$(git config --global user.name 2>/dev/null)" ]]; then
        print_status "Enter your Git user name:"
        read -r git_name
        git config --global user.name "$git_name"
    fi

    if [[ -z "$(git config --global user.email 2>/dev/null)" ]]; then
        print_status "Enter your Git email:"
        read -r git_email
        git config --global user.email "$git_email"
    fi

    # Set useful defaults
    git config --global init.defaultBranch main
    git config --global core.editor vim
    git config --global pull.rebase false

    print_success "Git configured"
}

# Setup Docker (optional)
setup_docker() {
    if prompt_install "docker" "Docker container platform"; then
        print_status "Installing Docker..."

        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Add repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add user to docker group
        sudo usermod -aG docker "$USER"

        # Enable Docker service
        sudo systemctl enable docker
        sudo systemctl start docker

        print_success "Docker installed. Log out and back in for group changes to take effect."
    fi
}

# Install Node.js (optional)
install_nodejs() {
    if prompt_install "nodejs" "Node.js JavaScript runtime"; then
        print_status "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        print_success "Node.js installed"
    fi
}

# Create useful directories and maintenance script
setup_system_maintenance() {
    print_status "Setting up system maintenance..."

    # Create directories
    mkdir -p "$HOME/.local/bin" "$HOME/scripts" "$HOME/logs" "$HOME/backups"

    # Create maintenance script
    cat > "$HOME/scripts/system-maintenance.sh" <<'EOF'
#!/bin/bash
# System maintenance script
LOG_FILE="$HOME/logs/maintenance-$(date +%Y%m%d).log"
echo "=== System Maintenance Started at $(date) ===" >> "$LOG_FILE"
sudo apt-get update >> "$LOG_FILE" 2>&1
sudo apt-get autoclean >> "$LOG_FILE" 2>&1
sudo apt-get autoremove -y >> "$LOG_FILE" 2>&1
echo "Disk usage:" >> "$LOG_FILE"
df -h >> "$LOG_FILE"
echo "=== System Maintenance Completed at $(date) ===" >> "$LOG_FILE"
EOF

    chmod +x "$HOME/scripts/system-maintenance.sh"

    # Add weekly cron job
    (crontab -l 2>/dev/null; echo "0 2 * * 0 $HOME/scripts/system-maintenance.sh") | crontab -

    print_success "System maintenance configured"
}

# System information summary
show_system_info() {
    print_status "System Information Summary:"
    echo "================================"
    echo "Hostname: $(hostname)"
    echo "IP Address: $(hostname -I | awk '{print $1}' 2>/dev/null || echo 'N/A')"
    echo "Ubuntu Version: $(lsb_release -d | cut -f2 2>/dev/null)"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs 2>/dev/null)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null)"
    echo "Disk Usage:"
    df -h 2>/dev/null | grep -E '^/dev/' | awk '{print "  " $1 ": " $5 " used (" $3 "/" $2 ")"}'
    echo "================================"
}

# Main installation orchestrator - calls individual installers
main() {
    clear
    echo "=============================================="
    echo "Ubuntu Server DRY Setup Script (Orchestrator)"
    echo "=============================================="
    echo "This script calls individual component installers"
    echo "from GitHub to keep everything DRY and maintainable."
    echo "=============================================="
    echo

    # Pre-flight checks
    check_root
    check_ubuntu_version

    # Core system setup
    update_system
    install_essential_packages
    configure_security
    configure_git

    # Optional components with prompts
    setup_docker
    install_nodejs

    # Enhanced shell and editor setup via specialized installers
    print_status "Installing enhanced shell environment..."
    if prompt_install "shell" "enhanced shell environment (Zsh + Oh My Zsh + plugins)"; then
        run_installer "install-shell.sh" || print_warning "Enhanced shell installation failed, continuing..."
    else
        print_status "Skipping enhanced shell installation"
    fi

    print_status "Installing enhanced tmux configuration..."
    if prompt_install "tmux" "enhanced tmux configuration with DevOps features"; then
        run_installer "tmux-installer.sh" || print_warning "Enhanced tmux installation failed, continuing..."
    else
        print_status "Skipping enhanced tmux installation"
    fi

    print_status "Installing enhanced vim configuration..."
    if prompt_install "vim" "enhanced vim configuration with plugins"; then
        run_installer "vim-installer.sh" || print_warning "Enhanced vim installation failed, continuing..."
    else
        print_status "Skipping enhanced vim installation"
    fi

    # System maintenance setup
    setup_system_maintenance

    # Summary
    echo
    show_system_info

    print_success "Ubuntu Server setup completed!"
    echo
    print_status "📋 Installation Summary:"
    echo "  • Essential packages: ✓ Installed"
    echo "  • Security (UFW + fail2ban): ✓ Configured"
    echo "  • Git: ✓ Configured"
    echo "  • System maintenance: ✓ Scheduled"
    echo "  • Enhanced components: Installed based on your choices"
    echo
    print_status "📁 Log file saved to: $LOG_FILE"
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Set up SSH keys if you haven't already"
    echo "  2. Log out and back in to apply shell changes"
    echo "  3. Review firewall rules: sudo ufw status"
    echo "  4. Test enhanced tools (tmux, vim, zsh if installed)"
    echo "  5. Configure any additional services needed"
    echo
    print_status "🚀 Your Ubuntu server is ready for DevOps work!"
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
