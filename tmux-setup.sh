#!/usr/bin/env bash

# Tmux Setup Script for DevOps Engineer
# Installs tmux, plugins, and configures the environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up tmux for DevOps workflow...${NC}"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Unsupported operating system${NC}"
    exit 1
fi

# Install tmux
install_tmux() {
    echo -e "${YELLOW}Installing tmux...${NC}"
    
    case $OS in
        "macos")
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}Homebrew not found. Please install Homebrew first.${NC}"
                exit 1
            fi
            brew install tmux
            ;;
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y tmux
            ;;
        "fedora"|"centos"|"rhel")
            sudo dnf install -y tmux
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm tmux
            ;;
        *)
            echo -e "${RED}Unsupported OS: $OS${NC}"
            exit 1
            ;;
    esac
}

# Install additional tools useful for DevOps
install_devops_tools() {
    echo -e "${YELLOW}Installing additional DevOps tools...${NC}"
    
    case $OS in
        "macos")
            brew install fzf htop watch jq yq
            ;;
        "ubuntu"|"debian")
            sudo apt install -y fzf htop procps jq
            # Install yq
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo chmod +x /usr/local/bin/yq
            ;;
        "fedora"|"centos"|"rhel")
            sudo dnf install -y fzf htop procps-ng jq
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo chmod +x /usr/local/bin/yq
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm fzf htop procps-ng jq yq
            ;;
    esac
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    echo -e "${YELLOW}Installing Tmux Plugin Manager...${NC}"
    
    if [[ ! -d ~/.tmux/plugins/tpm ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        echo -e "${GREEN}TPM installed successfully${NC}"
    else
        echo -e "${YELLOW}TPM already installed${NC}"
    fi
}

# Create symlinks
create_symlinks() {
    echo -e "${YELLOW}Creating symlinks...${NC}"
    
    # Backup existing config if it exists
    if [[ -f ~/.tmux.conf ]]; then
        mv ~/.tmux.conf ~/.tmux.conf.backup
        echo -e "${YELLOW}Backed up existing .tmux.conf to .tmux.conf.backup${NC}"
    fi
    
    # Create symlinks
    ln -sf "$PWD/.tmux.conf" ~/.tmux.conf
    ln -sf "$PWD/tmux-sessionizer" ~/.local/bin/tmux-sessionizer 2>/dev/null || \
    ln -sf "$PWD/tmux-sessionizer" /usr/local/bin/tmux-sessionizer 2>/dev/null || \
    echo -e "${YELLOW}Could not create symlink in system PATH. Add $PWD to your PATH or copy scripts manually.${NC}"
    
    ln -sf "$PWD/tmux-project-manager" ~/.local/bin/tmux-project-manager 2>/dev/null || \
    ln -sf "$PWD/tmux-project-manager" /usr/local/bin/tmux-project-manager 2>/dev/null || \
    echo -e "${YELLOW}Could not create symlink in system PATH. Add $PWD to your PATH or copy scripts manually.${NC}"
    
    echo -e "${GREEN}Symlinks created successfully${NC}"
}

# Install plugins
install_plugins() {
    echo -e "${YELLOW}Installing tmux plugins...${NC}"
    
    # Start tmux server in the background to install plugins
    tmux new-session -d -s plugin_install
    tmux send-keys -t plugin_install '~/.tmux/plugins/tpm/bin/install_plugins' C-m
    sleep 5
    tmux kill-session -t plugin_install 2>/dev/null || true
    
    echo -e "${GREEN}Plugins installed successfully${NC}"
}

# Create project directory structure
create_project_structure() {
    echo -e "${YELLOW}Creating project directory structure...${NC}"
    
    mkdir -p ~/Work
    mkdir -p ~/.local/bin
    
    echo -e "${GREEN}Project structure created${NC}"
}

# Add shell aliases
add_shell_aliases() {
    echo -e "${YELLOW}Adding shell aliases...${NC}"
    
    local shell_config=""
    if [[ -f ~/.zshrc ]]; then
        shell_config=~/.zshrc
    elif [[ -f ~/.bashrc ]]; then
        shell_config=~/.bashrc
    else
        echo -e "${YELLOW}No shell configuration file found. Skipping aliases.${NC}"
        return
    fi
    
    # Add aliases if they don't exist
    if ! grep -q "alias tm=" "$shell_config" 2>/dev/null; then
        cat >> "$shell_config" << 'EOF'

# Tmux aliases
alias tm='tmux'
alias tma='tmux attach-session -t'
alias tmn='tmux new-session -s'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'
alias tmks='tmux kill-server'
alias tms='tmux-sessionizer'
alias tmp='tmux-project-manager'
EOF
        echo -e "${GREEN}Shell aliases added to $shell_config${NC}"
    else
        echo -e "${YELLOW}Tmux aliases already exist in $shell_config${NC}"
    fi
}

# Main installation
main() {
    echo -e "${BLUE}Starting tmux setup...${NC}"
    
    # Check if tmux is already installed
    if ! command -v tmux &> /dev/null; then
        install_tmux
    else
        echo -e "${GREEN}tmux is already installed${NC}"
    fi
    
    install_devops_tools
    install_tpm
    create_project_structure
    create_symlinks
    install_plugins
    add_shell_aliases
    
    echo -e "${GREEN}✅ Tmux setup completed successfully!${NC}"
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  ${YELLOW}tmux-sessionizer${NC}     - Quick project session selection"
    echo -e "  ${YELLOW}tmux-project-manager${NC} - Full project management"
    echo -e "  ${YELLOW}tm${NC}                   - Start tmux"
    echo -e "  ${YELLOW}tms${NC}                  - Run sessionizer"
    echo -e "  ${YELLOW}tmp${NC}                  - Run project manager"
    echo ""
    echo -e "${BLUE}Key bindings:${NC}"
    echo -e "  ${YELLOW}Prefix: Ctrl-a${NC}"
    echo -e "  ${YELLOW}Prefix + |${NC}     - Split horizontally"
    echo -e "  ${YELLOW}Prefix + -${NC}     - Split vertically"
    echo -e "  ${YELLOW}Prefix + h/j/k/l${NC} - Navigate panes (vim-style)"
    echo -e "  ${YELLOW}Prefix + r${NC}     - Reload config"
    echo -e "  ${YELLOW}Prefix + P/O/M/D${NC} - Create project sessions"
    echo ""
    echo -e "${GREEN}Restart your shell or run 'source ~/.zshrc' (or ~/.bashrc) to use new aliases${NC}"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi