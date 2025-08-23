#!/usr/bin/env bash

# MOONSHOT: Ultimate Productivity Installer
# One script to rule them all - TMUX + NeoVim + DevOps = 🚀
# The most advanced terminal setup for 10x engineers

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/package-managers.sh"

# Initialize environment
setup_environment

# Configuration
MOONSHOT_VERSION="3.0.0"
BACKUP_EXISTING=true
INSTALL_ALL=true
INSTALL_SHELL=false
INSTALL_NEOVIM=false
INSTALL_DEVOPS=false

# Colors for output
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [NC]='\033[0m'
)

print_moonshot_banner() {
    clear
    echo -e "${COLORS[PURPLE]}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗███████╗██╗  ██╗ ██████╗ ████████╗ ║
║    ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║██╔════╝██║  ██║██╔═══██╗╚══██╔══╝ ║
║    ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║███████╗███████║██║   ██║   ██║    ║
║    ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║╚════██║██╔══██║██║   ██║   ██║    ║
║    ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║███████║██║  ██║╚██████╔╝   ██║    ║
║    ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝    ║
║                                                                              ║
║                    🚀 ULTIMATE PRODUCTIVITY ENVIRONMENT 🚀                   ║
║                                                                              ║
║                    TMUX + NEOVIM + DEVOPS = SECOND NATURE                   ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${COLORS[NC]}"
    echo -e "${COLORS[CYAN]}Version: $MOONSHOT_VERSION${COLORS[NC]}"
    echo -e "${COLORS[YELLOW]}Making you a 10x engineer, one keystroke at a time...${COLORS[NC]}"
    echo
}

show_installation_menu() {
    echo -e "${COLORS[WHITE]}🎯 MOONSHOT Installation Options:${COLORS[NC]}"
    echo
    echo -e "${COLORS[GREEN]}1) 🚀 Full MOONSHOT Stack${COLORS[NC]} - Everything optimized for maximum productivity"
    echo -e "   → Shell Environment (Zsh + TMUX + Starship + Modern CLI)"
    echo -e "   → NeoVim Ultra (AI-powered, DevOps-native, <50ms startup)"
    echo -e "   → DevOps Arsenal (K8s + Monitoring + Multi-cloud + IaC + Security)"
    echo -e "   → Productivity Workflows (Custom scripts + Integrations)"
    echo
    echo -e "${COLORS[BLUE]}2) 🐚 Shell Environment Only${COLORS[NC]} - TMUX-centric productivity shell"
    echo -e "   → Zsh + Oh-My-Zsh + TMUX with Tokyo Night theme"
    echo -e "   → Modern CLI tools (rg, fd, bat, eza, fzf, starship)"
    echo -e "   → Productivity aliases and functions"
    echo
    echo -e "${COLORS[PURPLE]}3) ⚡ NeoVim Ultra Only${COLORS[NC]} - Next-gen editor for 10x engineers"  
    echo -e "   → NeoVim nightly with LazyVim + AI completion"
    echo -e "   → DevOps plugins (K8s, Terraform, Docker, REST client)"
    echo -e "   → Advanced debugging and testing integration"
    echo
    echo -e "${COLORS[CYAN]}4) ☸️  DevOps Arsenal Only${COLORS[NC]} - Complete cloud-native toolkit"
    echo -e "   → Kubernetes ecosystem (k9s, helm, kustomize, stern)"
    echo -e "   → Multi-cloud CLIs (AWS, Azure, GCP, DigitalOcean)"
    echo -e "   → Infrastructure as Code (Terraform, Pulumi, Ansible)"
    echo -e "   → Monitoring stack (Prometheus, Grafana, OpenTelemetry)"
    echo -e "   → Container security (Trivy, Grype, Falco, Cosign)"
    echo
    echo -e "${COLORS[YELLOW]}5) ℹ️  System Information${COLORS[NC]} - Check current installation"
    echo -e "${COLORS[RED]}6) 🚪 Exit${COLORS[NC]}"
    echo
}

get_user_choice() {
    local choice
    while true; do
        echo -n -e "${COLORS[WHITE]}Select your destiny (1-6): ${COLORS[NC]}"
        read -r choice
        
        case $choice in
            1)
                INSTALL_ALL=true
                INSTALL_SHELL=true
                INSTALL_NEOVIM=true
                INSTALL_DEVOPS=true
                break
                ;;
            2)
                INSTALL_ALL=false
                INSTALL_SHELL=true
                break
                ;;
            3)
                INSTALL_ALL=false
                INSTALL_NEOVIM=true
                break
                ;;
            4)
                INSTALL_ALL=false
                INSTALL_DEVOPS=true
                break
                ;;
            5)
                show_system_info
                return 1
                ;;
            6)
                echo -e "${COLORS[YELLOW]}🚪 Exiting MOONSHOT installer...${COLORS[NC]}"
                exit 0
                ;;
            *)
                echo -e "${COLORS[RED]}❌ Invalid choice. Please select 1-6.${COLORS[NC]}"
                ;;
        esac
    done
    return 0
}

show_system_info() {
    echo -e "${COLORS[CYAN]}📊 SYSTEM INFORMATION${COLORS[NC]}"
    echo "════════════════════════════════════════"
    echo -e "🖥️  OS: ${COLORS[GREEN]}${DOTFILES_OS} ${DOTFILES_DISTRO}${COLORS[NC]}"
    echo -e "🏗️  Architecture: ${COLORS[GREEN]}${DOTFILES_ARCH}${COLORS[NC]}"
    echo -e "🏠 Environment: ${COLORS[GREEN]}${DOTFILES_ENV}${COLORS[NC]}"
    echo -e "🖼️  Display: ${COLORS[GREEN]}${DOTFILES_DISPLAY:-console}${COLORS[NC]}"
    echo
    
    echo -e "${COLORS[PURPLE]}🔧 INSTALLED TOOLS${COLORS[NC]}"
    echo "════════════════════════════════════════"
    
    local tools=(
        "zsh:Shell"
        "tmux:Terminal Multiplexer" 
        "nvim:NeoVim Editor"
        "git:Version Control"
        "docker:Container Runtime"
        "kubectl:Kubernetes CLI"
        "helm:Kubernetes Package Manager"
        "terraform:Infrastructure as Code"
        "aws:AWS CLI"
        "az:Azure CLI"
        "gcloud:Google Cloud CLI"
        "k9s:Kubernetes TUI"
        "lazygit:Git TUI"
        "lazydocker:Docker TUI"
        "rg:Modern Grep"
        "fd:Modern Find"
        "bat:Modern Cat"
        "eza:Modern LS"
        "fzf:Fuzzy Finder"
        "starship:Shell Prompt"
    )
    
    for tool_info in "${tools[@]}"; do
        local cmd="${tool_info%%:*}"
        local desc="${tool_info##*:}"
        if command_exists "$cmd"; then
            echo -e "✅ $desc: ${COLORS[GREEN]}$(command -v "$cmd")${COLORS[NC]}"
        else
            echo -e "❌ $desc: ${COLORS[RED]}Not installed${COLORS[NC]}"
        fi
    done
    
    echo
    echo -e "${COLORS[YELLOW]}💡 Press Enter to return to main menu...${COLORS[NC]}"
    read -r
}

confirm_installation() {
    echo -e "${COLORS[WHITE]}🎯 INSTALLATION SUMMARY${COLORS[NC]}"
    echo "════════════════════════════════════════"
    
    if [[ "$INSTALL_ALL" == "true" ]]; then
        echo -e "📦 Installing: ${COLORS[GREEN]}Full MOONSHOT Stack${COLORS[NC]}"
        echo -e "   → Shell Environment with TMUX optimization"
        echo -e "   → NeoVim with AI-powered productivity features"
        echo -e "   → Complete DevOps arsenal"
        echo -e "   → Integrated productivity workflows"
    else
        [[ "$INSTALL_SHELL" == "true" ]] && echo -e "📦 Installing: ${COLORS[BLUE]}Shell Environment${COLORS[NC]}"
        [[ "$INSTALL_NEOVIM" == "true" ]] && echo -e "📦 Installing: ${COLORS[PURPLE]}NeoVim Ultra${COLORS[NC]}"
        [[ "$INSTALL_DEVOPS" == "true" ]] && echo -e "📦 Installing: ${COLORS[CYAN]}DevOps Arsenal${COLORS[NC]}"
    fi
    
    echo
    echo -e "🗂️  Backup directory: ${COLORS[YELLOW]}$BACKUP_DIR${COLORS[NC]}"
    echo -e "📝 Log file: ${COLORS[YELLOW]}$LOG_FILE${COLORS[NC]}"
    echo
    
    local warning_shown=false
    if [[ -f ~/.zshrc ]]; then
        echo -e "${COLORS[YELLOW]}⚠️  Existing .zshrc will be backed up${COLORS[NC]}"
        warning_shown=true
    fi
    if [[ -d ~/.config/nvim ]]; then
        echo -e "${COLORS[YELLOW]}⚠️  Existing NeoVim config will be backed up${COLORS[NC]}"
        warning_shown=true
    fi
    if [[ -f ~/.tmux.conf ]]; then
        echo -e "${COLORS[YELLOW]}⚠️  Existing TMUX config will be backed up${COLORS[NC]}"
        warning_shown=true
    fi
    
    [[ "$warning_shown" == "true" ]] && echo
    
    while true; do
        echo -n -e "${COLORS[WHITE]}🚀 Ready to transform your terminal? (y/N): ${COLORS[NC]}"
        read -r response
        case $response in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                echo -e "${COLORS[YELLOW]}🚪 Installation cancelled.${COLORS[NC]}"
                exit 0
                ;;
            *)
                echo -e "${COLORS[RED]}❌ Please answer yes (y) or no (n).${COLORS[NC]}"
                ;;
        esac
    done
}

install_prerequisites() {
    print_header "Installing Prerequisites"
    
    # Update system
    info "Updating system packages..."
    update_package_lists
    
    # Install base requirements
    local base_packages=()
    case "${DOTFILES_OS}" in
        linux)
            base_packages=(curl wget git build-essential ca-certificates gnupg lsb-release)
            ;;
        macos)
            base_packages=(curl wget git)
            ;;
    esac
    
    install_packages "${base_packages[@]}"
    
    # Install package managers if needed
    case "${DOTFILES_OS}" in
        linux)
            if ! command_exists snap; then
                install_packages snapd || true
            fi
            ;;
        macos)
            if ! command_exists brew; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            ;;
    esac
    
    success "Prerequisites installed"
}

execute_shell_installation() {
    print_header "🐚 Installing Shell Environment"
    
    info "Running MOONSHOT Shell installer..."
    bash "$SCRIPT_DIR/components/shell-moonshot.sh"
    
    success "Shell Environment installation completed"
}

execute_neovim_installation() {
    print_header "⚡ Installing NeoVim Ultra"
    
    info "Running MOONSHOT NeoVim installer..."
    bash "$SCRIPT_DIR/components/neovim-moonshot.sh"
    
    success "NeoVim Ultra installation completed"
}

execute_devops_installation() {
    print_header "☸️  Installing DevOps Arsenal"
    
    info "Running MOONSHOT DevOps installer..."
    bash "$SCRIPT_DIR/components/devops-moonshot.sh"
    
    success "DevOps Arsenal installation completed"
}

create_integration_scripts() {
    print_header "🔗 Creating Integration Scripts"
    
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.config/moonshot"
    
    # Main MOONSHOT launcher
    cat > "$HOME/.local/bin/moonshot" <<'EOF'
#!/usr/bin/env bash
# MOONSHOT Main Launcher

set -e

# Colors
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [PURPLE]='\033[0;35m'
    [CYAN]='\033[0;36m'
    [WHITE]='\033[1;37m'
    [NC]='\033[0m'
)

show_status() {
    echo -e "${COLORS[PURPLE]}🚀 MOONSHOT Status Dashboard${COLORS[NC]}"
    echo "════════════════════════════════════════"
    
    # System info
    echo -e "${COLORS[CYAN]}🖥️  System:${COLORS[NC]} $(uname -s) $(uname -r)"
    echo -e "${COLORS[CYAN]}⏰ Uptime:${COLORS[NC]} $(uptime | awk '{print $3,$4}' | sed 's/,//')"
    echo -e "${COLORS[CYAN]}💾 Memory:${COLORS[NC]} $(free -h 2>/dev/null | awk '/^Mem:/ {print $3"/"$2}' || echo 'N/A')"
    echo
    
    # Git status (if in git repo)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${COLORS[GREEN]}📁 Git Status:${COLORS[NC]}"
        echo -e "   Branch: $(git branch --show-current 2>/dev/null || echo 'detached')"
        echo -e "   Changes: $(git status --porcelain 2>/dev/null | wc -l) files"
        echo -e "   Remote: $(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/.git$//' || echo 'none')"
        echo
    fi
    
    # Docker status
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo -e "${COLORS[BLUE]}🐳 Docker:${COLORS[NC]} $(docker ps -q | wc -l) containers running"
    fi
    
    # Kubernetes status
    if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
        local ctx=$(kubectl config current-context 2>/dev/null || echo 'none')
        local ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo 'default')
        echo -e "${COLORS[YELLOW]}☸️  Kubernetes:${COLORS[NC]} $ctx ($ns namespace)"
    fi
    
    echo
    echo -e "${COLORS[WHITE]}Quick Actions:${COLORS[NC]}"
    echo "  k9s           - Kubernetes TUI"
    echo "  lazydocker    - Docker TUI"
    echo "  lazygit       - Git TUI"
    echo "  nvim          - NeoVim editor"
    echo "  moonshot-logs - View logs"
    echo "  moonshot-deploy - Deploy tools"
}

case "${1:-status}" in
    status|dashboard)
        show_status
        ;;
    logs)
        moonshot-logs
        ;;
    deploy)
        moonshot-deploy
        ;;
    update)
        echo "🔄 Updating MOONSHOT components..."
        cd ~/.dotfiles && git pull && echo "✅ Updated!"
        ;;
    backup)
        echo "💾 Creating MOONSHOT backup..."
        tar -czf "moonshot-backup-$(date +%Y%m%d-%H%M%S).tar.gz" ~/.dotfiles ~/.config/nvim ~/.tmux.conf ~/.zshrc
        echo "✅ Backup created!"
        ;;
    help|--help|-h)
        echo "MOONSHOT Command Center"
        echo ""
        echo "Usage: moonshot [command]"
        echo ""
        echo "Commands:"
        echo "  status     - Show system and tool status (default)"
        echo "  logs       - Open log viewer"
        echo "  deploy     - Open deployment helper"
        echo "  update     - Update MOONSHOT components"
        echo "  backup     - Create configuration backup"
        echo "  help       - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'moonshot help' for available commands"
        exit 1
        ;;
esac
EOF
    
    # Productivity workspace creator
    cat > "$HOME/.local/bin/moonshot-workspace" <<'EOF'
#!/usr/bin/env bash
# MOONSHOT Workspace Creator

set -e

create_workspace() {
    local workspace_name="${1:-moonshot}"
    local workspace_type="${2:-dev}"
    
    if tmux has-session -t "$workspace_name" 2>/dev/null; then
        echo "Attaching to existing workspace: $workspace_name"
        tmux attach-session -t "$workspace_name"
        return
    fi
    
    echo "Creating workspace: $workspace_name ($workspace_type)"
    
    # Create main session
    tmux new-session -d -s "$workspace_name" -x $(tput cols) -y $(tput lines)
    
    case "$workspace_type" in
        dev|development)
            tmux rename-window -t "$workspace_name":1 'editor'
            tmux send-keys -t "$workspace_name":1 'nvim .' Enter
            
            tmux new-window -t "$workspace_name":2 -n 'terminal'
            tmux new-window -t "$workspace_name":3 -n 'git'
            tmux send-keys -t "$workspace_name":3 'lazygit' Enter
            
            tmux new-window -t "$workspace_name":4 -n 'logs'
            ;;
            
        devops)
            tmux rename-window -t "$workspace_name":1 'k8s'
            tmux send-keys -t "$workspace_name":1 'k9s' Enter
            
            tmux new-window -t "$workspace_name":2 -n 'docker'
            tmux send-keys -t "$workspace_name":2 'lazydocker' Enter
            
            tmux new-window -t "$workspace_name":3 -n 'terraform'
            tmux new-window -t "$workspace_name":4 -n 'monitoring'
            tmux send-keys -t "$workspace_name":4 'htop' Enter
            
            tmux new-window -t "$workspace_name":5 -n 'logs'
            ;;
            
        full)
            tmux rename-window -t "$workspace_name":1 'editor'
            tmux send-keys -t "$workspace_name":1 'nvim .' Enter
            
            tmux new-window -t "$workspace_name":2 -n 'git'
            tmux send-keys -t "$workspace_name":2 'lazygit' Enter
            
            tmux new-window -t "$workspace_name":3 -n 'k8s'
            tmux send-keys -t "$workspace_name":3 'k9s' Enter
            
            tmux new-window -t "$workspace_name":4 -n 'docker'
            tmux send-keys -t "$workspace_name":4 'lazydocker' Enter
            
            tmux new-window -t "$workspace_name":5 -n 'terraform'
            tmux new-window -t "$workspace_name":6 -n 'monitoring'
            tmux new-window -t "$workspace_name":7 -n 'logs'
            tmux new-window -t "$workspace_name":8 -n 'terminal'
            ;;
    esac
    
    tmux select-window -t "$workspace_name":1
    tmux attach-session -t "$workspace_name"
}

case "${1:-}" in
    ""|dev|development)
        create_workspace "$(basename $PWD 2>/dev/null || echo 'moonshot')" "dev"
        ;;
    devops)
        create_workspace "devops-$(date +%Y%m%d)" "devops"
        ;;
    full)
        create_workspace "$(basename $PWD 2>/dev/null || echo 'moonshot')" "full"
        ;;
    *)
        create_workspace "$1" "${2:-dev}"
        ;;
esac
EOF
    
    # Make scripts executable
    chmod +x "$HOME/.local/bin/moonshot"*
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
    
    # Create MOONSHOT config
    cat > "$HOME/.config/moonshot/config.yaml" <<EOF
# MOONSHOT Configuration
version: "$MOONSHOT_VERSION"
installed_components:
  shell: $INSTALL_SHELL
  neovim: $INSTALL_NEOVIM
  devops: $INSTALL_DEVOPS
installation_date: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
backup_directory: "$BACKUP_DIR"
log_file: "$LOG_FILE"
EOF
    
    success "Integration scripts created"
}

create_completion_notice() {
    print_header "🎉 MOONSHOT Installation Complete!"
    
    local install_summary=""
    [[ "$INSTALL_SHELL" == "true" ]] && install_summary+="🐚 Shell Environment "
    [[ "$INSTALL_NEOVIM" == "true" ]] && install_summary+="⚡ NeoVim Ultra "
    [[ "$INSTALL_DEVOPS" == "true" ]] && install_summary+="☸️  DevOps Arsenal "
    
    echo -e "${COLORS[GREEN]}✅ Successfully installed: $install_summary${COLORS[NC]}"
    echo
    echo -e "${COLORS[YELLOW]}📋 POST-INSTALLATION CHECKLIST:${COLORS[NC]}"
    echo "════════════════════════════════════════"
    
    if [[ "$INSTALL_SHELL" == "true" ]]; then
        echo -e "🐚 ${COLORS[BLUE]}Shell Environment:${COLORS[NC]}"
        echo "   • Restart terminal or run: exec zsh"
        echo "   • Press Ctrl+A then I in TMUX to install plugins"
        echo "   • Run 'moonshot-workspace' to create productivity workspace"
        echo
    fi
    
    if [[ "$INSTALL_NEOVIM" == "true" ]]; then
        echo -e "⚡ ${COLORS[PURPLE]}NeoVim Ultra:${COLORS[NC]}"
        echo "   • Open nvim and wait for plugins to install automatically"
        echo "   • Run :Mason to check LSP servers"
        echo "   • Run :Copilot setup for AI assistance"
        echo "   • Set OPENAI_API_KEY for ChatGPT integration"
        echo
    fi
    
    if [[ "$INSTALL_DEVOPS" == "true" ]]; then
        echo -e "☸️  ${COLORS[CYAN]}DevOps Arsenal:${COLORS[NC]}"
        echo "   • Configure cloud providers: aws configure, az login, gcloud init"
        echo "   • Set up Kubernetes contexts"
        echo "   • Run 'moonshot' for the main dashboard"
        echo
    fi
    
    echo -e "${COLORS[WHITE]}🚀 MOONSHOT COMMANDS:${COLORS[NC]}"
    echo "════════════════════════════════════════"
    echo "• moonshot              - Main dashboard"
    echo "• moonshot-workspace    - Create productivity workspace"  
    echo "• moonshot-logs         - Log viewer"
    echo "• moonshot-deploy       - Deployment helper"
    echo "• k9s                   - Kubernetes TUI"
    echo "• lazygit               - Git TUI"
    echo "• lazydocker            - Docker TUI"
    echo
    
    echo -e "${COLORS[GREEN]}🎯 KEY BINDINGS TO MEMORIZE:${COLORS[NC]}"
    echo "════════════════════════════════════════"
    echo "• Ctrl+A        - TMUX prefix"
    echo "• Ctrl+A + |    - Split vertical"
    echo "• Ctrl+A + -    - Split horizontal"
    echo "• Ctrl+R        - History search (fzf)"
    echo "• Ctrl+T        - File search (fzf)"
    echo "• Alt+C         - Directory search (fzf)"
    echo "• Space         - NeoVim leader key"
    echo "• Space + ff    - Find files in NeoVim"
    echo "• Space + gg    - LazyGit in NeoVim"
    echo
    
    echo -e "${COLORS[PURPLE]}💡 PRODUCTIVITY TIPS:${COLORS[NC]}"
    echo "════════════════════════════════════════"
    echo "• Use 'fe' to edit files with fuzzy search"
    echo "• Use 'kctx' to switch Kubernetes contexts"
    echo "• Use 'gfb' to switch Git branches with fzf"
    echo "• Use 'dsh' to shell into Docker containers"
    echo "• All configs are in ~/.dotfiles (version controlled)"
    echo
    
    echo -e "${COLORS[YELLOW]}📚 CONFIGURATION LOCATIONS:${COLORS[NC]}"
    echo "════════════════════════════════════════"
    echo "• Zsh config:     ~/.zshrc"
    echo "• TMUX config:    ~/.tmux.conf"
    echo "• NeoVim config:  ~/.config/nvim/"
    echo "• Starship:       ~/.config/starship.toml"
    echo "• MOONSHOT:       ~/.config/moonshot/"
    echo "• Backups:        $BACKUP_DIR"
    echo "• Logs:           $LOG_FILE"
    echo
    
    # Final message
    local total_time=$((SECONDS / 60))
    echo -e "${COLORS[GREEN]}🎊 CONGRATULATIONS! 🎊${COLORS[NC]}"
    echo -e "Your terminal is now a ${COLORS[PURPLE]}PRODUCTIVITY POWERHOUSE${COLORS[NC]}!"
    echo -e "Installation completed in ${COLORS[YELLOW]}${total_time} minutes${COLORS[NC]}."
    echo
    echo -e "${COLORS[WHITE]}Welcome to the ${COLORS[PURPLE]}MOONSHOT${COLORS[WHITE]} experience! 🚀${COLORS[NC]}"
    echo -e "You are now ready to operate at ${COLORS[GREEN]}10x engineer${COLORS[NC]} levels."
    echo
    
    # Ask if user wants to start MOONSHOT now
    while true; do
        echo -n -e "${COLORS[WHITE]}🚀 Start MOONSHOT workspace now? (y/N): ${COLORS[NC]}"
        read -r response
        case $response in
            [Yy]|[Yy][Ee][Ss])
                echo -e "${COLORS[GREEN]}🚀 Launching MOONSHOT...${COLORS[NC]}"
                exec zsh -c "moonshot-workspace full"
                ;;
            [Nn]|[Nn][Oo]|"")
                echo -e "${COLORS[YELLOW]}💡 Run 'moonshot-workspace' when you're ready!${COLORS[NC]}"
                break
                ;;
            *)
                echo -e "${COLORS[RED]}❌ Please answer yes (y) or no (n).${COLORS[NC]}"
                ;;
        esac
    done
}

main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${COLORS[RED]}❌ Please don't run this script as root!${COLORS[NC]}"
        exit 1
    fi
    
    # Show banner
    print_moonshot_banner
    
    # Interactive menu loop
    while true; do
        show_installation_menu
        
        if get_user_choice; then
            break
        fi
        
        clear
        print_moonshot_banner
    done
    
    # Confirm installation
    if ! confirm_installation; then
        exit 0
    fi
    
    # Start timer
    local start_time=$SECONDS
    
    # Run installations
    echo -e "${COLORS[CYAN]}🚀 Starting MOONSHOT installation...${COLORS[NC]}"
    echo
    
    # Prerequisites
    install_prerequisites
    
    # Install components based on selection
    if [[ "$INSTALL_SHELL" == "true" ]]; then
        execute_shell_installation
    fi
    
    if [[ "$INSTALL_NEOVIM" == "true" ]]; then
        execute_neovim_installation
    fi
    
    if [[ "$INSTALL_DEVOPS" == "true" ]]; then
        execute_devops_installation
    fi
    
    # Create integrations
    create_integration_scripts
    
    # Show completion notice
    create_completion_notice
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --shell-only)
            INSTALL_ALL=false
            INSTALL_SHELL=true
            shift
            ;;
        --neovim-only)
            INSTALL_ALL=false
            INSTALL_NEOVIM=true
            shift
            ;;
        --devops-only)
            INSTALL_ALL=false
            INSTALL_DEVOPS=true
            shift
            ;;
        --no-backup)
            BACKUP_EXISTING=false
            shift
            ;;
        --help|-h)
            echo "MOONSHOT Installer"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --shell-only     Install only shell environment"
            echo "  --neovim-only    Install only NeoVim Ultra"
            echo "  --devops-only    Install only DevOps arsenal"
            echo "  --no-backup      Don't create config backups"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "If no options provided, interactive menu will be shown."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi