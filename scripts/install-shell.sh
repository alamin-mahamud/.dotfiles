#!/bin/bash

# Shell Configuration Installation Script
# Installs and configures Zsh, Oh My Zsh, and Tmux

set -euo pipefail

# Import common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap.sh" 2>/dev/null || true

# Install Zsh
install_zsh() {
    print_status "Installing Zsh..."
    
    case "$DOTFILES_OS" in
        linux)
            sudo apt-get update
            sudo apt-get install -y zsh
            ;;
        macos)
            brew install zsh
            ;;
    esac
    
    print_success "Zsh installed"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    print_status "Installing Oh My Zsh..."
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_status "Oh My Zsh is already installed"
    else
        # Install Oh My Zsh without switching shell yet
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    print_status "Installing Zsh plugins..."
    
    # zsh-autosuggestions
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    fi
    
    # zsh-completions
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]]; then
        git clone https://github.com/zsh-users/zsh-completions \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
    fi
    
    # fzf-tab
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]]; then
        git clone https://github.com/Aloxaf/fzf-tab \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
    fi
    
    print_success "Zsh plugins installed"
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    print_status "Installing Powerlevel10k theme..."
    
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    fi
    
    print_success "Powerlevel10k installed"
}

# Configure Zsh
configure_zsh() {
    print_status "Configuring Zsh..."
    
    # Link Zsh configuration files
    if [[ -d "$DOTFILES_ROOT/zsh" ]]; then
        # Backup existing .zshrc
        if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
            mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
        fi
        
        # Link main .zshrc
        ln -sf "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"
        
        # Link other zsh config files
        for file in "$DOTFILES_ROOT/zsh"/*.zsh; do
            if [[ -f "$file" ]]; then
                ln -sf "$file" "$HOME/.$(basename "$file")"
            fi
        done
        
        print_success "Zsh configuration linked"
    else
        print_warning "Zsh configuration directory not found in dotfiles"
    fi
}

# Install Tmux
install_tmux() {
    print_status "Installing Tmux..."
    
    case "$DOTFILES_OS" in
        linux)
            sudo apt-get update
            sudo apt-get install -y tmux
            ;;
        macos)
            brew install tmux
            ;;
    esac
    
    print_success "Tmux installed"
}

# Install Tmux Plugin Manager
install_tpm() {
    print_status "Installing Tmux Plugin Manager..."
    
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        print_success "TPM installed"
    else
        print_status "TPM is already installed"
    fi
}

# Configure Tmux
configure_tmux() {
    print_status "Configuring Tmux..."
    
    # Use existing tmux config if available
    if [[ -f "$DOTFILES_ROOT/.tmux.conf" ]]; then
        ln -sf "$DOTFILES_ROOT/.tmux.conf" "$HOME/.tmux.conf"
        print_success "Tmux configuration linked"
    elif [[ -f "$DOTFILES_ROOT/configs/.tmux.conf" ]]; then
        ln -sf "$DOTFILES_ROOT/configs/.tmux.conf" "$HOME/.tmux.conf"
        print_success "Tmux configuration linked"
    else
        # Create a default tmux configuration
        cat > "$HOME/.tmux.conf" <<'EOF'
# Tmux configuration

# Set prefix to Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable 256 colors
set -g default-terminal "screen-256color"
set-option -sa terminal-overrides ',xterm-256color:RGB'

# Status bar
set -g status-position bottom
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[fg=#1e1e2e,bg=#89b4fa,bold] #S '
set -g status-right '#[fg=#1e1e2e,bg=#f38ba8] %Y-%m-%d %H:%M '

# History limit
set -g history-limit 50000

# Vim key bindings in copy mode
setw -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'christoomey/vim-tmux-navigator'

# Plugin settings
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF
        print_success "Default Tmux configuration created"
    fi
    
    # Install/update tmux plugins
    if [[ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
        "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    fi
}

# Install FZF
install_fzf() {
    print_status "Installing FZF..."
    
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all --no-bash --no-fish
    else
        print_status "FZF is already installed"
    fi
    
    print_success "FZF installed"
}

# Install additional shell tools
install_shell_tools() {
    print_status "Installing additional shell tools..."
    
    case "$DOTFILES_OS" in
        linux)
            # Install from apt
            sudo apt-get update
            sudo apt-get install -y \
                bat \
                fd-find \
                ripgrep \
                htop \
                ncdu \
                tree \
                jq \
                tldr
            
            # Create symlinks for different names
            sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
            ;;
        macos)
            brew install \
                bat \
                fd \
                ripgrep \
                htop \
                ncdu \
                tree \
                jq \
                tldr \
                eza \
                zoxide \
                starship
            ;;
    esac
    
    print_success "Shell tools installed"
}

# Install fonts
install_fonts() {
    print_status "Installing Nerd Fonts..."
    
    # Create fonts directory
    case "$DOTFILES_OS" in
        linux)
            FONT_DIR="$HOME/.local/share/fonts"
            ;;
        macos)
            FONT_DIR="$HOME/Library/Fonts"
            ;;
    esac
    
    mkdir -p "$FONT_DIR"
    
    # Download and install popular Nerd Fonts
    local fonts=(
        "FiraCode"
        "JetBrainsMono"
        "Hack"
        "SourceCodePro"
    )
    
    for font in "${fonts[@]}"; do
        print_status "Installing $font Nerd Font..."
        
        # Download font
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
        if curl -L -o "/tmp/${font}.zip" "$font_url"; then
            # Extract to font directory
            unzip -q -o "/tmp/${font}.zip" -d "$FONT_DIR"
            rm "/tmp/${font}.zip"
            print_success "$font Nerd Font installed"
        else
            print_warning "Failed to download $font Nerd Font"
        fi
    done
    
    # Update font cache on Linux
    if [[ "$DOTFILES_OS" == "linux" ]]; then
        fc-cache -fv
    fi
    
    print_success "Fonts installed"
}

# Change default shell to Zsh
change_shell_to_zsh() {
    print_status "Would you like to change your default shell to Zsh? (Y/n)"
    read -r response
    if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        if command -v zsh &> /dev/null; then
            local zsh_path="$(command -v zsh)"
            
            # Add zsh to /etc/shells if not already there
            if ! grep -q "$zsh_path" /etc/shells; then
                echo "$zsh_path" | sudo tee -a /etc/shells
            fi
            
            # Change shell
            chsh -s "$zsh_path"
            print_success "Default shell changed to Zsh"
            print_warning "Please log out and back in for the change to take effect"
        else
            print_error "Zsh not found. Please install it first."
        fi
    fi
}

# Main installation flow
main() {
    print_status "Shell Configuration Installation"
    echo
    
    # Install shells and tools
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_powerlevel10k
    configure_zsh
    
    # Install and configure tmux
    install_tmux
    install_tpm
    configure_tmux
    
    # Install additional tools
    install_fzf
    install_shell_tools
    install_fonts
    
    # Change default shell
    change_shell_to_zsh
    
    print_success "Shell configuration completed!"
    echo
    print_status "Next steps:"
    echo "  1. Log out and back in to use Zsh as default shell"
    echo "  2. Run 'p10k configure' to set up Powerlevel10k theme"
    echo "  3. Install tmux plugins: prefix + I (Ctrl-a then Shift-i)"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi