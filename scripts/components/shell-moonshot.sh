#!/usr/bin/env bash

# MOONSHOT: Shell Environment Ultra-Productivity
# TMUX-centric shell for 10x engineers
# Performance-optimized, DevOps-native, AI-powered

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Initialize environment
setup_environment

install_shell_dependencies() {
    info "Installing shell dependencies with performance focus..."
    
    local packages=()
    
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    packages=(
                        zsh git curl wget unzip build-essential
                        tmux neovim
                        # Performance monitoring
                        htop btop ncdu
                        # Modern CLI tools
                        ripgrep fd-find bat tree jq
                        # Multiplexer dependencies
                        xclip wl-clipboard
                        # Fonts for terminal
                        fontconfig
                    )
                    ;;
                dnf|yum)
                    packages=(
                        zsh git curl wget unzip gcc gcc-c++ make
                        tmux neovim
                        htop ncdu
                        ripgrep fd-find bat tree jq
                        xclip wl-clipboard
                        fontconfig
                    )
                    ;;
                pacman)
                    packages=(
                        zsh git curl wget unzip base-devel
                        tmux neovim
                        htop btop ncdu
                        ripgrep fd bat tree jq
                        xclip wl-clipboard
                        fontconfig
                    )
                    ;;
            esac
            ;;
        macos)
            packages=(zsh git curl wget tmux neovim)
            ;;
    esac
    
    update_package_lists
    install_packages "${packages[@]}"
    
    success "Shell dependencies installed"
}

install_zsh_moonshot() {
    if [[ "$SHELL" == *zsh* ]]; then
        info "Zsh is already the default shell"
        return 0
    fi
    
    info "Setting up Zsh as default shell..."
    
    local zsh_path=$(which zsh)
    
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
        success "Added $zsh_path to /etc/shells"
    fi
    
    if [[ "$SHELL" != "$zsh_path" ]]; then
        chsh -s "$zsh_path" 2>/dev/null || {
            warning "Could not change shell automatically. Please run: chsh -s $zsh_path"
        }
        success "Changed default shell to Zsh"
    fi
}

install_oh_my_zsh_moonshot() {
    local oh_my_zsh_dir="$HOME/.oh-my-zsh"
    
    if [[ -d "$oh_my_zsh_dir" ]]; then
        info "Oh My Zsh detected, updating..."
        cd "$oh_my_zsh_dir" && git pull origin master 2>/dev/null || {
            warning "Failed to update Oh My Zsh, backing up and reinstalling..."
            backup_file "$oh_my_zsh_dir"
            rm -rf "$oh_my_zsh_dir"
        }
    fi
    
    if [[ ! -d "$oh_my_zsh_dir" ]]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        success "Oh My Zsh installed"
    fi
}

install_moonshot_zsh_plugins() {
    local oh_my_zsh_custom="$HOME/.oh-my-zsh/custom"
    mkdir -p "$oh_my_zsh_custom/plugins" "$oh_my_zsh_custom/themes"
    
    info "Installing MOONSHOT Zsh plugins..."
    
    # Core plugins
    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting" 
        "zsh-users/zsh-completions"
        "Aloxaf/fzf-tab"
        "zsh-users/zsh-history-substring-search"
        "MichaelAquilina/zsh-you-should-use"
        "zdharma-continuum/fast-syntax-highlighting"
        "marlonrichert/zsh-autocomplete"
    )
    
    for plugin_repo in "${plugins[@]}"; do
        local plugin_name=$(basename "$plugin_repo")
        local plugin_dir="$oh_my_zsh_custom/plugins/$plugin_name"
        
        if [[ -d "$plugin_dir" ]]; then
            cd "$plugin_dir" && git pull 2>/dev/null || {
                backup_file "$plugin_dir"
                rm -rf "$plugin_dir"
                git clone "https://github.com/$plugin_repo" "$plugin_dir"
            }
        else
            git clone "https://github.com/$plugin_repo" "$plugin_dir"
        fi
        success "Installed/updated $plugin_name"
    done
    
    # Install Starship prompt (better than Powerlevel10k)
    install_starship_prompt
}

install_starship_prompt() {
    info "Installing Starship prompt..."
    
    if ! command_exists starship; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    # Create Starship config for DevOps workflow
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/starship.toml" <<'EOF'
# MOONSHOT Starship Configuration
# Optimized for DevOps workflows

format = """
$username$hostname$kubernetes$directory$git_branch$git_status$python$golang$nodejs$terraform$docker_context$aws$gcloud$azure
$character
"""

# Disable the blank line at the start of the prompt
add_newline = false

# Performance optimization
command_timeout = 1000

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vicmd_symbol = "[❮](bold yellow)"

[username]
style_user = "bold blue"
style_root = "bold red"
format = "[$user]($style)"
disabled = false
show_always = true

[hostname]
ssh_only = false
format = "[@$hostname](bold yellow) "
disabled = false

[directory]
truncation_length = 3
truncation_symbol = "…/"
home_symbol = "~"
read_only_style = "197"
read_only = "🔒"
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold cyan"

[git_branch]
format = "[⎇ $branch]($style) "
style = "bold purple"
truncation_length = 20
truncation_symbol = "…"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"
conflicted = "⚡"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
up_to_date = "✓"
untracked = "?${count}"
stashed = "$${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[kubernetes]
format = '[☸ $context($namespace)](bold blue) '
disabled = false
detect_files = ['k8s', 'kubernetes', 'kustomization.yaml', 'kustomization.yml', 'Chart.yaml']
detect_folders = ['k8s', 'kubernetes', '.kube']

[docker_context]
format = "[🐳 $context](bold blue) "
disabled = false

[terraform]
format = "[💠 $workspace]($style) "
style = "bold 105"
disabled = false

[aws]
format = '[☁️  $profile($region)]($style) '
style = "bold blue"
disabled = false

[gcloud]
format = '[☁️  $account(@$domain)(\($region\))]($style) '
style = "bold blue"
disabled = false

[azure]
format = "[☁️  $subscription]($style) "
style = "bold blue"  
disabled = false

[python]
format = '[🐍 $pyenv_prefix$version( \($virtualenv\))]($style) '
style = "yellow bold"
pyenv_version_name = false
python_binary = "python3"

[golang]
format = "[🐹 $version]($style) "
style = "bold cyan"

[nodejs]
format = "[⬢ $version]($style) "
style = "bold green"

[rust]
format = "[🦀 $version]($style) "
style = "bold red"

[cmd_duration]
min_time = 2000
format = "took [$duration]($style) "
style = "yellow bold"

[time]
disabled = false
format = '🕙[$time]($style) '
time_format = "%T"
style = "bright-white"

[battery]
full_symbol = "🔋"
charging_symbol = "⚡️"
discharging_symbol = "💀"

[[battery.display]]
threshold = 10
style = "bold red"

[[battery.display]]
threshold = 30
style = "bold yellow"

[memory_usage]
disabled = false
threshold = -1
symbol = "🐏"
style = "bold dimmed green"
format = "$symbol [${ram}( | ${swap})]($style) "
EOF

    success "Starship prompt configured"
}

install_tmux_moonshot() {
    info "Installing TMUX with MOONSHOT configuration..."
    
    # Install TPM (TMUX Plugin Manager)
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    mkdir -p "$(dirname "$tpm_dir")"
    
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    else
        cd "$tpm_dir" && git pull 2>/dev/null || true
    fi
    
    # Create MOONSHOT tmux config
    backup_file "$HOME/.tmux.conf"
    cat > "$HOME/.tmux.conf" <<'EOF'
# MOONSHOT TMUX Configuration
# Ultra-productive terminal multiplexer setup

# ===== PERFORMANCE OPTIMIZATIONS =====
set -g escape-time 0
set -g repeat-time 600
set -g focus-events on
set -g aggressive-resize on
set -g set-clipboard on
set -g history-limit 50000

# ===== PREFIX AND BASIC SETTINGS =====
# Change prefix to Ctrl-a (easier on fingers)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# True color support
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -ag terminal-overrides ",alacritty:RGB"
set -ag terminal-overrides ",*:Tc"

# Mouse support
set -g mouse on

# Start windows and panes at 1
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# ===== KEYBINDINGS =====
# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Better pane splitting
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
unbind '"'
unbind %

# Smart pane switching with awareness of Vim splits
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

# Pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Window navigation
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4
bind -n M-5 select-window -t 5
bind -n M-6 select-window -t 6
bind -n M-7 select-window -t 7
bind -n M-8 select-window -t 8
bind -n M-9 select-window -t 9

# Session navigation
bind C-f command-prompt -p find-session 'switch-client -t %%'

# Copy mode improvements
setw -g mode-keys vi
bind Enter copy-mode
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind-key -T copy-mode-vi Escape send-keys -X cancel

# Quick sessions for common workflows
bind-key M-d new-session -d -s docker \; send-keys 'lazydocker' Enter
bind-key M-k new-session -d -s k8s \; send-keys 'k9s' Enter
bind-key M-g new-session -d -s git \; send-keys 'lazygit' Enter
bind-key M-m new-session -d -s monitoring \; send-keys 'htop' Enter

# ===== THEME & STATUS BAR =====
# Tokyo Night color scheme
set -g status on
set -g status-interval 1
set -g status-position top
set -g status-justify centre
set -g status-left-length 100
set -g status-right-length 100

# Colors
set -g status-style 'bg=#1a1b26 fg=#c0caf5'
set -g window-status-current-style 'fg=#1a1b26 bg=#7aa2f7 bold'
set -g window-status-style 'fg=#565f89 bg=#1a1b26'
set -g window-status-separator ''

# Pane borders
set -g pane-border-style 'fg=#414868'
set -g pane-active-border-style 'fg=#7aa2f7'

# Message colors
set -g message-style 'bg=#7aa2f7 fg=#1a1b26 bold'
set -g message-command-style 'bg=#414868 fg=#c0caf5'

# Status bar components
set -g status-left '#[bg=#7aa2f7,fg=#1a1b26,bold] #S #[bg=#414868,fg=#7aa2f7]#[bg=#414868,fg=#c0caf5] #{session_windows} #[bg=#1a1b26,fg=#414868]'

set -g status-right '#[bg=#1a1b26,fg=#414868]#[bg=#414868,fg=#c0caf5] %H:%M #[bg=#414868,fg=#7aa2f7]#[bg=#7aa2f7,fg=#1a1b26,bold] %d-%b #[bg=#7aa2f7,fg=#bb9af7]#[bg=#bb9af7,fg=#1a1b26,bold] #{user}@#{host} '

# Window status
set -g window-status-format '#[bg=#1a1b26,fg=#565f89] #I:#W '
set -g window-status-current-format '#[bg=#7aa2f7,fg=#1a1b26,bold] #I:#W #[bg=#1a1b26,fg=#7aa2f7]'

# ===== PLUGINS =====
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-copycat'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-open'
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
set -g @plugin 'fcsonline/tmux-thumbs'
set -g @plugin 'sainnhe/tmux-fzf'
set -g @plugin 'wfxr/tmux-fzf-url'
set -g @plugin 'schasse/tmux-jump'

# Plugin configurations
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '5'
set -g @continuum-boot 'on'

set -g @prefix_highlight_fg 'black'
set -g @prefix_highlight_bg 'yellow'
set -g @prefix_highlight_copy_mode_attr 'fg=black,bg=yellow,bold'
set -g @prefix_highlight_prefix_prompt 'Wait'
set -g @prefix_highlight_copy_prompt 'Copy'

set -g @thumbs-key F
set -g @thumbs-command 'echo -n {} | xclip -selection clipboard'
set -g @thumbs-upcase-command 'tmux set-buffer {} && tmux paste-buffer'

set -g @fzf-url-bind 'u'

set -g @jump-key 's'

# ===== SESSION MANAGEMENT =====
# Auto-create work sessions
new-session -d -s main -x $(tput cols) -y $(tput lines)
new-window -t main:2 -n 'nvim' 'nvim'
new-window -t main:3 -n 'git' 
new-window -t main:4 -n 'docker'
new-window -t main:5 -n 'k8s'
new-window -t main:6 -n 'logs'
new-window -t main:7 -n 'monitoring'
new-window -t main:8 -n 'ssh'
new-window -t main:9 -n 'misc'

select-window -t main:1

# Initialize TMUX plugin manager (keep this line at the very bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF
    
    # Install plugins
    if [[ -d "$tpm_dir" ]]; then
        "$tpm_dir/bin/install_plugins"
        success "TMUX plugins installed"
    fi
    
    success "MOONSHOT TMUX configuration created"
}

configure_moonshot_zsh() {
    info "Creating MOONSHOT Zsh configuration..."
    
    backup_file "$HOME/.zshrc"
    
    cat > "$HOME/.zshrc" <<'EOF'
# MOONSHOT Zsh Configuration
# Ultra-productive shell for DevOps engineers

# ===== PERFORMANCE OPTIMIZATIONS =====
# Disable auto-update checks for faster startup
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Skip the verification of insecure directories
ZSH_DISABLE_COMPFIX="true"

# ===== OH MY ZSH CONFIGURATION =====
export ZSH="$HOME/.oh-my-zsh"

# Add custom completions to fpath before Oh My Zsh loads
if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src" ]]; then
    fpath=($HOME/.oh-my-zsh/custom/plugins/zsh-completions/src $fpath)
fi

# Add system completions
if [[ -d "/usr/local/share/zsh/site-functions" ]]; then
    fpath=(/usr/local/share/zsh/site-functions $fpath)
fi

# Add Homebrew completions (macOS)
if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
    fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# Essential plugins only for maximum performance
plugins=(
    git
    docker
    kubectl
    terraform
    aws
    gcloud
    azure
    ansible
    python
    golang
    nodejs
    rust
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    zsh-history-substring-search
    you-should-use
    fast-syntax-highlighting
    fzf-tab
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ===== ENVIRONMENT VARIABLES =====
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export MANPAGER='nvim +Man!'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export TERM=xterm-256color

# History configuration - optimized for DevOps workflows
HISTSIZE=100000
SAVEHIST=100000
export HISTFILE="$HOME/.zsh_history"
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion system
autoload -Uz compinit
# Security-conscious completion initialization
for dump in ~/.zcompdump(N.mh+24); do
    compinit
done
compinit -C

setopt COMPLETE_ALIASES
setopt GLOB_COMPLETE
setopt MENU_COMPLETE
setopt AUTO_MENU
setopt ALWAYS_TO_END
setopt COMPLETE_IN_WORD

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format 'No matches found'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' completer _extensions _complete _approximate

# ===== KEYBINDINGS =====
# Vim-style line editing
bindkey -v
export KEYTIMEOUT=1

# History search
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Edit command line in editor
bindkey '^X^E' edit-command-line

# Quick navigation
bindkey '^[[1;5C' forward-word  # Ctrl+Right
bindkey '^[[1;5D' backward-word # Ctrl+Left

# ===== MODERN CLI TOOLS =====
# eza (modern ls)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=always --group-directories-first'
    alias la='eza -la --color=always --group-directories-first'
    alias ll='eza -la --color=always --group-directories-first --git'
    alias tree='eza --tree --color=always --group-directories-first'
    alias lt='eza --tree --level=2 --color=always --group-directories-first'
fi

# bat (modern cat)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias less='bat --paging=always'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi

# ripgrep (modern grep)
if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
    export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
fi

# fd (modern find)
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

# bottom (modern top)
if command -v btm >/dev/null 2>&1; then
    alias top='btm'
    alias htop='btm'
fi

# Modern diff
if command -v delta >/dev/null 2>&1; then
    export GIT_PAGER="delta"
fi

# ===== GIT ALIASES =====
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpl='git pull'
alias gr='git remote'
alias grv='git remote -v'
alias gs='git status --short'
alias gst='git stash'
alias gstp='git stash pop'
alias gw='git worktree'

# Advanced git workflows
alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gundo='git reset HEAD~1 --mixed'
alias gwipe='git add -A && git commit -qm "WIPE SAVEPOINT" && git reset HEAD~1 --hard'

# ===== DOCKER ALIASES =====
alias d='docker'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'
alias dex='docker exec -it'
alias drun='docker run --rm -it'
alias dclean='docker system prune -af'
alias dstop='docker stop $(docker ps -q)'

# ===== KUBERNETES ALIASES =====
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias ke='kubectl edit'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kpf='kubectl port-forward'
alias kdel='kubectl delete'
alias kctx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'

# Kubernetes shortcuts
alias kpods='kubectl get pods --all-namespaces'
alias ksvc='kubectl get svc --all-namespaces'
alias kingress='kubectl get ingress --all-namespaces'
alias knodes='kubectl get nodes -o wide'

# ===== TERRAFORM ALIASES =====
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfs='terraform show'
alias tfv='terraform validate'
alias tff='terraform fmt'
alias tfo='terraform output'
alias tfw='terraform workspace'

# ===== AWS ALIASES =====
alias awsprofile='export AWS_PROFILE=$(aws configure list-profiles | fzf)'
alias awsregion='export AWS_DEFAULT_REGION=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text | tr "\t" "\n" | fzf)'

# ===== PRODUCTIVITY ALIASES =====
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Directory operations
alias md='mkdir -pv'
alias rd='rmdir'

# System aliases
alias h='history'
alias c='clear'
alias reload='source ~/.zshrc'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# Network
alias ping='ping -c 5'
alias fastping='ping -c 100 -s 2'
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias localip="hostname -I | awk '{print \$1}'"

# Process management
alias psa='ps aux'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias topcpu='/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'
alias topmem='/bin/ps -eo pmem,pid,user,args | sort -k 1 -r | head -10'

# Development
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'
alias json='python3 -m json.tool'
alias weather='curl wttr.in'
alias cheat='curl cht.sh'

# ===== CUSTOM FUNCTIONS =====
# Create directory and cd into it
mkcd() {
    mkdir -pv "$1" && cd "$1"
}

# Extract archives
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        unxz "$1"        ;;
            *.lzma)      unlzma "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find and edit files quickly
fe() {
    local file
    file=$(fzf --height 40% --reverse --preview 'bat --style=numbers --color=always {}')
    [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

# Kubernetes context switching
kctx() {
    local context
    context=$(kubectl config get-contexts -o name | fzf --height 40% --reverse)
    [[ -n "$context" ]] && kubectl config use-context "$context"
}

# Kubernetes namespace switching  
kns() {
    local namespace
    namespace=$(kubectl get namespaces -o name | cut -d/ -f2 | fzf --height 40% --reverse)
    [[ -n "$namespace" ]] && kubectl config set-context --current --namespace="$namespace"
}

# Quick SSH with fuzzy finding
ssh-fzf() {
    local host
    host=$(grep "^Host " ~/.ssh/config | cut -d' ' -f2 | fzf --height 40% --reverse)
    [[ -n "$host" ]] && ssh "$host"
}

# Docker container management
dsh() {
    local container
    container=$(docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2 | fzf --height 40% --reverse | awk '{print $1}')
    [[ -n "$container" ]] && docker exec -it "$container" /bin/bash
}

# Git branch switching
gfb() {
    local branch
    branch=$(git branch --all | grep -v HEAD | sed 's/remotes\/origin\///' | sort -u | fzf --height 40% --reverse)
    [[ -n "$branch" ]] && git checkout "$branch"
}

# Process killer with fuzzy finding
kill-fzf() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --height 40% --reverse | awk '{print $2}')
    [[ -n "$pid" ]] && kill -${1:-9} $pid
}

# ===== DEVELOPMENT ENVIRONMENT SETUP =====
# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python development
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

# Go development
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$GOBIN"

# Rust development
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ===== CLOUD PROVIDER CONFIGURATIONS =====
# AWS CLI completion
[[ -f "/usr/local/bin/aws_completer" ]] && complete -C '/usr/local/bin/aws_completer' aws

# Google Cloud SDK
if [[ -d "$HOME/google-cloud-sdk" ]]; then
    source "$HOME/google-cloud-sdk/path.zsh.inc"
    source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# Azure CLI completion
[[ -f "/etc/bash_completion.d/azure-cli" ]] && source "/etc/bash_completion.d/azure-cli"

# ===== FZF CONFIGURATION =====
# Setup fzf
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi

# FZF configuration for better DevOps experience
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

export FZF_DEFAULT_OPTS='
--height 40% --layout=reverse --border
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6ac,pointer:#f5e0dc
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6ac,hl+:#f38ba8
--prompt="❯ " --pointer="❯" --marker="❯"
--bind="ctrl-u:preview-up,ctrl-d:preview-down"
'

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# ===== TMUX INTEGRATION =====
# Auto-start tmux session if not already in one
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
    if tmux has-session -t main 2>/dev/null; then
        exec tmux attach-session -t main
    else
        exec tmux new-session -s main
    fi
fi

# ===== PROMPT CONFIGURATION =====
# Initialize Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ===== PLUGIN CONFIGURATIONS =====
# zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086,underline"

# zsh-history-substring-search
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=white,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'

# you-should-use
export YSU_MESSAGE_POSITION="after"
export YSU_MODE=ALL

# fzf-tab
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# ===== RIPGREP CONFIGURATION =====
if command -v rg >/dev/null 2>&1; then
    cat > "$HOME/.ripgreprc" <<'RIPGREP_EOF'
# Search hidden files and directories
--hidden

# Don't search in git directories
--glob=!.git/*

# Don't search in node_modules
--glob=!node_modules/*

# Don't search in target directory (Rust)
--glob=!target/*

# Don't search in build directories
--glob=!build/*
--glob=!dist/*

# Don't search in cache directories
--glob=!.cache/*
--glob=!__pycache__/*

# Use colors
--colors=line:fg:yellow
--colors=line:style:bold
--colors=path:fg:green
--colors=path:style:bold
--colors=match:fg:red
--colors=match:style:bold

# Show line numbers
--line-number

# Search case insensitively if pattern is all lowercase
--smart-case

# Sort by path
--sort=path
RIPGREP_EOF
fi

# ===== PERFORMANCE MONITORING =====
# Load profiling (uncomment to debug startup time)
# zmodload zsh/zprof

# ===== LOCAL CUSTOMIZATIONS =====
# Load local customizations if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# Load secrets and API keys (keep separate from version control)
[[ -f ~/.zsh_secrets ]] && source ~/.zsh_secrets

# ===== FINAL OPTIMIZATIONS =====
# Rehash on completion
zstyle ':completion:*' rehash true

# Speed up git completion
__git_files () { 
    _wanted files expl 'local files' _files     
}

# Print welcome message for new shells
if [[ -z "$TMUX" ]] && [[ -o interactive ]]; then
    echo "🚀 MOONSHOT Shell Environment Loaded"
    echo "💡 Use Ctrl+R for history search, Ctrl+T for file search, Alt+C for directory search"
    echo "🔍 Try: fe (edit file), kctx (k8s context), gfb (git branch), dsh (docker shell)"
fi
EOF
    
    success "MOONSHOT Zsh configuration created"
}

install_modern_cli_tools() {
    info "Installing modern CLI tools for ultra-productivity..."
    
    # Install via package manager first
    case "${DOTFILES_OS}" in
        linux)
            case "$(detect_package_manager)" in
                apt)
                    install_packages ripgrep fd-find bat tree jq ncdu htop || true
                    ;;
                pacman)
                    install_packages ripgrep fd bat tree jq ncdu htop || true
                    ;;
            esac
            ;;
        macos)
            install_packages ripgrep fd bat tree jq ncdu htop || true
            ;;
    esac
    
    # Install advanced tools via binaries
    local tools=(
        "sharkdp/bat"
        "ogham/exa"
        "BurntSushi/ripgrep" 
        "sharkdp/fd"
        "junegunn/fzf"
        "jesseduffield/lazygit"
        "jesseduffield/lazydocker"
        "derailed/k9s"
        "ClementTsang/bottom"
        "bootandy/dust"
        "ajeetdsouza/zoxide"
        "starship/starship"
    )
    
    for tool in "${tools[@]}"; do
        local tool_name=$(basename "$tool")
        if ! command_exists "$tool_name"; then
            info "Installing $tool_name..."
            local latest_url=$(curl -s "https://api.github.com/repos/$tool/releases/latest" | grep -o '"browser_download_url": "[^"]*linux.*x86_64[^"]*"' | head -1 | cut -d'"' -f4)
            if [[ -n "$latest_url" ]]; then
                local temp_file="/tmp/${tool_name}.tar.gz"
                curl -Lo "$temp_file" "$latest_url"
                
                if [[ "$latest_url" == *.zip ]]; then
                    unzip -q "$temp_file" -d /tmp/
                else
                    tar -xzf "$temp_file" -C /tmp/
                fi
                
                # Find the binary and install it
                find /tmp -name "$tool_name" -type f -executable 2>/dev/null | head -1 | xargs -I {} sudo mv {} /usr/local/bin/
                sudo chmod +x "/usr/local/bin/$tool_name" 2>/dev/null || true
                rm -f "$temp_file"
            fi
        fi
    done
    
    # Install zoxide for smart directory jumping
    if ! command_exists zoxide; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    fi
    
    success "Modern CLI tools installed"
}

create_productivity_scripts() {
    info "Creating productivity scripts..."
    
    mkdir -p "$HOME/.local/bin"
    
    # DevOps workflow script
    cat > "$HOME/.local/bin/devops-session" <<'EOF'
#!/usr/bin/env bash
# MOONSHOT DevOps Session Manager

set -e

session_name="devops-$(date +%Y%m%d)"

if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Attaching to existing session: $session_name"
    tmux attach-session -t "$session_name"
else
    echo "Creating new DevOps session: $session_name"
    
    # Create main session
    tmux new-session -d -s "$session_name" -x $(tput cols) -y $(tput lines)
    
    # Window 1: Main work
    tmux rename-window -t "$session_name":1 'main'
    tmux send-keys -t "$session_name":1 'nvim .' Enter
    
    # Window 2: Git operations
    tmux new-window -t "$session_name":2 -n 'git'
    tmux send-keys -t "$session_name":2 'lazygit' Enter
    
    # Window 3: Kubernetes
    tmux new-window -t "$session_name":3 -n 'k8s'
    tmux send-keys -t "$session_name":3 'k9s' Enter
    
    # Window 4: Docker
    tmux new-window -t "$session_name":4 -n 'docker'
    tmux send-keys -t "$session_name":4 'lazydocker' Enter
    
    # Window 5: Logs and monitoring
    tmux new-window -t "$session_name":5 -n 'logs'
    tmux split-window -h -t "$session_name":5
    tmux send-keys -t "$session_name":5.1 'tail -f /var/log/syslog' Enter
    tmux send-keys -t "$session_name":5.2 'btm' Enter
    
    # Window 6: Terminal
    tmux new-window -t "$session_name":6 -n 'term'
    
    # Return to main window
    tmux select-window -t "$session_name":1
    tmux attach-session -t "$session_name"
fi
EOF
    
    chmod +x "$HOME/.local/bin/devops-session"
    
    # Quick project switcher
    cat > "$HOME/.local/bin/project-switch" <<'EOF'
#!/usr/bin/env bash
# Quick project switcher with tmux integration

set -e

# Find project directories
projects=$(find ~/projects ~/work ~/dev -maxdepth 2 -type d -name ".git" 2>/dev/null | sed 's/\/.git$//' | sort)

if [[ -z "$projects" ]]; then
    echo "No git projects found in ~/projects, ~/work, or ~/dev"
    exit 1
fi

# Use fzf to select project
selected=$(echo "$projects" | fzf --height 40% --reverse --preview 'ls -la {}' --prompt="Select project: ")

if [[ -z "$selected" ]]; then
    echo "No project selected"
    exit 0
fi

project_name=$(basename "$selected")
session_name=$(echo "$project_name" | tr . _)

# Change to project directory
cd "$selected"

# Create or attach to tmux session
if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux attach-session -t "$session_name"
else
    tmux new-session -d -s "$session_name" -c "$selected"
    tmux rename-window -t "$session_name":1 'editor'
    tmux send-keys -t "$session_name":1 'nvim .' Enter
    
    tmux new-window -t "$session_name":2 -n 'terminal' -c "$selected"
    tmux new-window -t "$session_name":3 -n 'git' -c "$selected"
    tmux send-keys -t "$session_name":3 'lazygit' Enter
    
    tmux select-window -t "$session_name":1
    tmux attach-session -t "$session_name"
fi
EOF
    
    chmod +x "$HOME/.local/bin/project-switch"
    
    # Add local bin to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
    
    success "Productivity scripts created"
}

verify_moonshot_installation() {
    info "Verifying MOONSHOT installation..."
    
    local tools=(zsh tmux nvim starship lazygit k9s lazydocker bat exa rg fd fzf)
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            success "✓ $tool"
        else
            warning "✗ $tool not found"
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        warning "Missing tools: ${missing_tools[*]}"
        warning "Some features may not work optimally"
    else
        success "All MOONSHOT tools verified!"
    fi
    
    # Check tmux plugins
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        success "✓ TMUX Plugin Manager installed"
    else
        warning "✗ TMUX Plugin Manager not found"
    fi
    
    # Check Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "✓ Oh My Zsh installed"
    else
        warning "✗ Oh My Zsh not found"
    fi
}

main() {
    print_header "MOONSHOT Shell Environment Ultra-Productivity"
    
    info "Creating the ultimate terminal experience for DevOps engineers"
    info "TMUX + ZSH + Modern Tools = 🚀"
    
    # Install dependencies
    install_shell_dependencies
    
    # Configure Zsh
    install_zsh_moonshot
    install_oh_my_zsh_moonshot
    install_moonshot_zsh_plugins
    
    # Configure TMUX
    install_tmux_moonshot
    
    # Configure shell
    configure_moonshot_zsh
    
    # Install modern tools
    install_modern_cli_tools
    
    # Create productivity scripts
    create_productivity_scripts
    
    # Verify installation
    verify_moonshot_installation
    
    success "MOONSHOT Shell Environment installed! 🚀"
    
    echo
    info "=== NEXT STEPS ==="
    info "1. Restart your terminal or run: exec zsh"
    info "2. Press Ctrl+A then I in tmux to install plugins"
    info "3. Run 'devops-session' to start a complete DevOps workspace"
    info "4. Run 'project-switch' to quickly switch between projects"
    info ""
    info "=== KEY BINDINGS ==="
    info "• Ctrl+A: TMUX prefix key"
    info "• Ctrl+R: History search with fzf"
    info "• Ctrl+T: File search with fzf"  
    info "• Alt+C: Directory search with fzf"
    info "• Ctrl+A + |: Split window vertically"
    info "• Ctrl+A + -: Split window horizontally"
    info "• Alt+1-9: Switch to TMUX window 1-9"
    info ""
    info "=== PRODUCTIVITY COMMANDS ==="
    info "• fe: Edit file with fzf"
    info "• kctx: Switch Kubernetes context"
    info "• kns: Switch Kubernetes namespace"
    info "• gfb: Switch Git branch with fzf"
    info "• dsh: Shell into Docker container"
    info "• ssh-fzf: Connect to SSH host with fzf"
    info ""
    info "Your terminal is now a productivity powerhouse! 💪"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi