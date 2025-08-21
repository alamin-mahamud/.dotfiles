#!/usr/bin/env bash
# Shell environment recipe - Combines ingredients to create shell setup
# Following Python's Zen: "Flat is better than nested"

# Get the recipe root directory
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$RECIPE_DIR/../lib" && pwd)"

# Import ingredients
source "$LIB_DIR/core.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/package.sh"

# Recipe configuration
readonly SHELL_PACKAGES=(
    "zsh"
    "tmux"
    "git"
    "curl"
    "wget"
    "htop"
    "tree"
    "jq"
)

readonly MODERN_TOOLS=(
    "ripgrep"
    "fd-find"
    "bat"
    "fzf"
    "eza"
    "delta"
    "zoxide"
)

# Install Zsh
install_zsh() {
    info "Installing Zsh..."
    
    # OS-specific package names
    declare -A zsh_package=(
        [default]="zsh"
    )
    
    install_package_multi zsh_package
    
    # Set as default shell if not already
    if [[ "$SHELL" != */zsh ]]; then
        if confirm "Set Zsh as default shell?"; then
            local zsh_path
            zsh_path=$(command -v zsh)
            
            # Add to /etc/shells if needed
            if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
            fi
            
            chsh -s "$zsh_path"
            success "Zsh set as default shell"
        fi
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    local omz_dir="${HOME}/.oh-my-zsh"
    
    if [[ -d "$omz_dir" ]]; then
        info "Updating Oh My Zsh..."
        (cd "$omz_dir" && git pull --rebase)
    else
        info "Installing Oh My Zsh..."
        export RUNZSH=no
        export KEEP_ZSHRC=yes
        sh -c "$(download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    success "Oh My Zsh ready"
}

# Install Powerlevel10k theme
install_p10k() {
    local p10k_dir="${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
    
    if [[ -d "$p10k_dir" ]]; then
        info "Updating Powerlevel10k..."
        (cd "$p10k_dir" && git pull --rebase)
    else
        info "Installing Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi
    
    success "Powerlevel10k ready"
}

# Install Zsh plugins
install_zsh_plugins() {
    local custom_dir="${HOME}/.oh-my-zsh/custom"
    
    # Plugin list with repo URLs
    declare -A plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
        ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    )
    
    for plugin in "${!plugins[@]}"; do
        local plugin_dir="$custom_dir/plugins/$plugin"
        
        if [[ -d "$plugin_dir" ]]; then
            info "Updating $plugin..."
            (cd "$plugin_dir" && git pull --rebase)
        else
            info "Installing $plugin..."
            git clone --depth=1 "${plugins[$plugin]}" "$plugin_dir"
        fi
    done
    
    success "Zsh plugins ready"
}

# Install Tmux
install_tmux() {
    info "Installing Tmux..."
    
    declare -A tmux_package=(
        [default]="tmux"
    )
    
    install_package_multi tmux_package
    
    # Install TPM (Tmux Plugin Manager)
    local tpm_dir="${HOME}/.tmux/plugins/tpm"
    
    if [[ -d "$tpm_dir" ]]; then
        info "Updating TPM..."
        (cd "$tpm_dir" && git pull --rebase)
    else
        info "Installing TPM..."
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi
    
    success "Tmux ready"
}

# Install modern CLI tools
install_modern_tools() {
    info "Installing modern CLI tools..."
    
    local os
    os=$(detect_os)
    
    # ripgrep
    declare -A rg_package=(
        [macos]="ripgrep"
        [debian]="ripgrep"
        [redhat]="ripgrep"
        [arch]="ripgrep"
        [default]="ripgrep"
    )
    install_package_multi rg_package || true
    
    # fd
    declare -A fd_package=(
        [macos]="fd"
        [debian]="fd-find"
        [redhat]="fd-find"
        [arch]="fd"
        [default]="fd-find"
    )
    install_package_multi fd_package || true
    
    # bat
    declare -A bat_package=(
        [macos]="bat"
        [debian]="bat"
        [arch]="bat"
        [default]="bat"
    )
    install_package_multi bat_package || true
    
    # eza (modern ls)
    if [[ "$os" == "macos" ]] || command_exists cargo; then
        if command_exists brew; then
            install_package "eza"
        elif command_exists cargo; then
            cargo install eza
        fi
    fi
    
    # fzf
    if ! command_exists fzf; then
        info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-bash --no-fish
    fi
    
    success "Modern tools ready"
}

# Install fonts
install_fonts() {
    info "Installing Nerd Fonts..."
    
    local font_dir
    local os
    os=$(detect_os)
    
    if [[ "$os" == "macos" ]]; then
        font_dir="${HOME}/Library/Fonts"
    else
        font_dir="${HOME}/.local/share/fonts"
    fi
    
    ensure_dir "$font_dir"
    
    # Download popular Nerd Fonts
    local fonts=("FiraCode" "JetBrainsMono" "Iosevka")
    
    for font in "${fonts[@]}"; do
        if ! ls "$font_dir"/*"$font"* &>/dev/null; then
            info "Downloading $font Nerd Font..."
            local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
            local temp_file="/tmp/${font}.zip"
            
            if download "$url" "$temp_file"; then
                unzip -q -o "$temp_file" -d "$font_dir"
                rm "$temp_file"
                success "Installed $font"
            else
                warning "Failed to download $font"
            fi
        else
            debug "$font already installed"
        fi
    done
    
    # Update font cache on Linux
    if [[ "$os" == "linux" ]] && command_exists fc-cache; then
        fc-cache -fv "$font_dir" >/dev/null 2>&1
    fi
    
    success "Fonts ready"
}

# Link shell configuration files
link_shell_configs() {
    info "Linking shell configuration files..."
    
    local dotfiles_root
    dotfiles_root=$(get_dotfiles_root)
    
    # Zsh configuration
    if [[ -f "$dotfiles_root/zsh/.zshrc" ]]; then
        create_symlink "$dotfiles_root/zsh/.zshrc" "${HOME}/.zshrc"
    fi
    
    if [[ -f "$dotfiles_root/zsh/.p10k.zsh" ]]; then
        create_symlink "$dotfiles_root/zsh/.p10k.zsh" "${HOME}/.p10k.zsh"
    fi
    
    # Tmux configuration
    if [[ -f "$dotfiles_root/configs/tmux/.tmux.conf" ]]; then
        create_symlink "$dotfiles_root/configs/tmux/.tmux.conf" "${HOME}/.tmux.conf"
    fi
    
    success "Configuration files linked"
}

# Main recipe execution
run_recipe() {
    info "=== Shell Environment Recipe ==="
    
    # Check prerequisites
    if ! check_internet; then
        die "Internet connection required"
    fi
    
    # Execute recipe steps
    install_build_essentials
    install_packages "${SHELL_PACKAGES[@]}"
    install_zsh
    install_oh_my_zsh
    install_p10k
    install_zsh_plugins
    install_tmux
    install_modern_tools
    install_fonts
    link_shell_configs
    
    success "=== Shell environment ready! ==="
    info "Please restart your terminal or run: exec zsh"
}

# Allow sourcing or direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_recipe "$@"
fi