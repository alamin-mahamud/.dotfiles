#!/bin/bash

# Server Shell Environment Standalone Installer
# Installs Zsh + Oh My Zsh + Tmux + essential CLI tools for server environments
# Lightweight setup focused on server/SSH workflows without GUI components
# Embedded configurations - no external dependencies
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-shell.sh | bash
#
# For desktop enhancements (LazyVim, Nerd Fonts, Powerlevel10k), run:
#   ./desktop-shell-extras.sh

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/shell-install-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

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

# Detect operating system
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_success "Detected macOS"
  elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS=$ID
    print_success "Detected $PRETTY_NAME"
  else
    print_error "Unsupported operating system"
    exit 1
  fi
}

# Backup existing configuration files
backup_existing_configs() {
  local files_to_backup=(
    "$HOME/.zshrc"
    "$HOME/.zsh_functions"
    "$HOME/.z.sh"
  )

  local backup_needed=false
  for file in "${files_to_backup[@]}"; do
    if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
      backup_needed=true
      break
    fi
  done

  if [[ "$backup_needed" == true ]]; then
    print_status "Backing up existing configuration files..."
    mkdir -p "$BACKUP_DIR"

    for file in "${files_to_backup[@]}"; do
      if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
        cp "$file" "$BACKUP_DIR/" 2>/dev/null || true
        print_status "Backed up $(basename "$file")"
      fi
    done
    print_success "Backups saved to $BACKUP_DIR"
  fi
}

# Install Zsh (idempotent)
install_zsh() {
  print_status "Checking Zsh installation..."

  if command -v zsh &>/dev/null; then
    print_success "Zsh is already installed ($(zsh --version))"
    return 0
  fi

  print_status "Installing Zsh..."
  case "$OS" in
  ubuntu | debian)
    sudo apt-get update
    sudo apt-get install -y zsh
    ;;
  fedora | centos | rhel | rocky | almalinux)
    sudo dnf install -y zsh || sudo yum install -y zsh
    ;;
  arch | manjaro)
    sudo pacman -S --noconfirm zsh
    ;;
  alpine)
    sudo apk add --no-cache zsh
    ;;
  opensuse* | sles)
    sudo zypper install -y zsh
    ;;
  macos)
    if ! command -v brew &>/dev/null; then
      print_warning "Homebrew not found. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh
    ;;
  *)
    print_error "Unsupported OS for Zsh installation: $OS"
    return 1
    ;;
  esac

  print_success "Zsh installed successfully"
}

# Install Oh My Zsh (idempotent)
install_oh_my_zsh() {
  print_status "Checking Oh My Zsh installation..."

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_success "Oh My Zsh is already installed"
    # Update to latest version
    print_status "Updating Oh My Zsh..."
    cd "$HOME/.oh-my-zsh" && git pull --quiet && cd - >/dev/null
    return 0
  fi

  print_status "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  print_success "Oh My Zsh installed"
}

# Install Zsh plugins (idempotent)
install_zsh_plugins() {
  print_status "Installing Zsh plugins..."

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # zsh-autosuggestions
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    print_status "Installing zsh-autosuggestions..."
    git clone --quiet https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    print_status "Updating zsh-autosuggestions..."
    cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull --quiet && cd - >/dev/null
  fi

  # zsh-syntax-highlighting
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    print_status "Installing zsh-syntax-highlighting..."
    git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    print_status "Updating zsh-syntax-highlighting..."
    cd "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && git pull --quiet && cd - >/dev/null
  fi

  # zsh-completions
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    print_status "Installing zsh-completions..."
    git clone --quiet https://github.com/zsh-users/zsh-completions \
      "$ZSH_CUSTOM/plugins/zsh-completions"
  else
    print_status "Updating zsh-completions..."
    cd "$ZSH_CUSTOM/plugins/zsh-completions" && git pull --quiet && cd - >/dev/null
  fi

  # fzf-tab
  if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
    print_status "Installing fzf-tab..."
    git clone --quiet https://github.com/Aloxaf/fzf-tab \
      "$ZSH_CUSTOM/plugins/fzf-tab"
  else
    print_status "Updating fzf-tab..."
    cd "$ZSH_CUSTOM/plugins/fzf-tab" && git pull --quiet && cd - >/dev/null
  fi

  print_success "Zsh plugins installed"
}

# Install Powerlevel10k theme (idempotent)
# Simple prompt theme setup for servers
setup_prompt_theme() {
  print_status "Setting up simple prompt theme..."
  
  # Use a simple, fast theme for servers
  # robbyrussell is lightweight and shows git info
  if [[ -f "$HOME/.zshrc" ]]; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$HOME/.zshrc" 2>/dev/null || \
    sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$HOME/.zshrc" 2>/dev/null || true
  fi
  
  print_success "Simple prompt theme configured"
}

# Removed configure_powerlevel10k - moved to desktop-shell-extras.sh
# For advanced prompt themes, run desktop-shell-extras.sh


# Configure Zsh (idempotent)
configure_zsh() {
  print_status "Configuring Zsh..."

  # Create embedded .zshrc configuration
  cat >"$HOME/.zshrc" <<'ZSHRC_EOF'
# Enhanced Zsh Configuration - Generated by install-shell.sh

# System detection
if [[ $(uname) = 'Linux' ]]; then
    IS_LINUX=1
fi

if [[ $(uname) = 'Darwin' ]]; then
    IS_MAC=1
fi

# Environment variables
export LANG=en_US.UTF-8
export TERM=xterm-256color
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH:/usr/local/go/bin"

# History configuration
HISTSIZE=10000
SAVEHIST=9000
HISTFILE=~/.zsh_history

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="robbyrussell"

# Plugins (fzf-tab must be last)
plugins=(
    git
    docker
    kubectl
    terraform
    aws
    vi-mode
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf-tab
)

source $ZSH/oh-my-zsh.sh

# Vim Mode Configuration
# Enable vim mode
bindkey -v

# Reduce key timeout for mode switching (default is 0.4s)
export KEYTIMEOUT=1

# Better searching in vim mode
bindkey -M vicmd '/' history-incremental-search-backward
bindkey -M vicmd '?' history-incremental-search-forward

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Edit line in vim with ctrl-e
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^e' edit-command-line

# Common emacs-style keybindings in insert mode
bindkey -M viins '^a' beginning-of-line
bindkey -M viins '^e' end-of-line
bindkey -M viins '^k' kill-line
bindkey -M viins '^r' history-incremental-search-backward
bindkey -M viins '^s' history-incremental-search-forward
bindkey -M viins '^p' up-line-or-history
bindkey -M viins '^n' down-line-or-history
bindkey -M viins '^y' yank
bindkey -M viins '^w' backward-kill-word
bindkey -M viins '^u' backward-kill-line
bindkey -M viins '^h' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^_' undo
bindkey -M viins '^x^r' redisplay
bindkey -M viins '\eOH' beginning-of-line  # Home
bindkey -M viins '\eOF' end-of-line        # End
bindkey -M viins '\e[H' beginning-of-line   # Home
bindkey -M viins '\e[F' end-of-line         # End

# Better undo/redo
bindkey -M vicmd 'u' undo
bindkey -M vicmd '^r' redo

# Backspace and Delete keys
bindkey -M viins '^?' backward-delete-char
bindkey -M viins "^[[3~" delete-char

# Visual mode indicator in prompt (if not using Powerlevel10k)
# Powerlevel10k already shows vim mode, so this is optional
# function zle-keymap-select {
#   if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
#     echo -ne '\e[1 q'  # Block cursor
#   elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
#     echo -ne '\e[5 q'  # Beam cursor
#   fi
# }
# zle -N zle-keymap-select

# Start in insert mode with beam cursor
# echo -ne '\e[5 q'

# Use beam cursor on startup
# preexec() { echo -ne '\e[5 q' }

# Change cursor shape for different vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Use beam cursor on startup and after each command
function zle-line-init {
  echo -ne '\e[5 q'
}
zle -N zle-line-init

echo -ne '\e[5 q' # Use beam cursor on startup
preexec() { echo -ne '\e[5 q' } # Use beam cursor for each new prompt

# Python environment
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

export PIPENV_PYTHON="$HOME/.pyenv/shims/python"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules --exclude .cache'

# FZF default options with preview
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout reverse
  --border rounded
  --info inline
  --prompt '󰍉 '
  --pointer '▶'
  --marker '┃'
  --bind 'ctrl-a:select-all'
  --bind 'ctrl-d:deselect-all'
  --bind 'ctrl-t:toggle-all'
  --bind 'ctrl-s:toggle-sort'
  --bind 'ctrl-p:toggle-preview'
  --bind 'alt-up:preview-up'
  --bind 'alt-down:preview-down'
  --bind 'ctrl-u:preview-page-up'
  --bind 'ctrl-d:preview-page-down'
  --color 'fg:#f7768e,bg:#1a1b26,hl:#7aa2f7'
  --color 'fg+:#c0caf5,bg+:#283457,hl+:#7dcfff'
  --color 'info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7'
  --color 'marker:#9ece6a,spinner:#bb9af7,header:#73daca'
"

# FZF preview options
export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --tree --level=1 --color=always {} 2>/dev/null || ls -la {}'
  --preview-window 'right:50%:wrap'
"

export FZF_ALT_C_OPTS="
  --preview 'eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}'
  --preview-window 'right:50%:wrap'
"

# Enhanced history search
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window down:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'
"

# Z directory jumping
[ -f ~/.z.sh ] && source ~/.z.sh

# Load custom functions
[ -f ~/.zsh_functions ] && source ~/.zsh_functions

# Docker-style random name generator for tmux sessions
tmux_random_name() {
    # Adjectives (Docker-style)
    local adjectives=(
        "admiring" "adoring" "affectionate" "agitated" "amazing" "angry" "awesome"
        "beautiful" "blissful" "bold" "boring" "brave" "busy" "charming" "clever"
        "cool" "compassionate" "competent" "condescending" "confident" "cranky"
        "crazy" "dazzling" "determined" "distracted" "dreamy" "eager" "ecstatic"
        "elastic" "elated" "elegant" "eloquent" "epic" "exciting" "fervent"
        "festive" "flamboyant" "focused" "friendly" "frosty" "funny" "gallant"
        "gifted" "goofy" "gracious" "great" "happy" "hardcore" "heuristic"
        "hopeful" "hungry" "infallible" "inspiring" "intelligent" "interesting"
        "jolly" "jovial" "keen" "kind" "laughing" "loving" "lucid" "magical"
        "mystifying" "modest" "musing" "naughty" "nervous" "nice" "nifty"
        "nostalgic" "objective" "optimistic" "peaceful" "pedantic" "pensive"
        "practical" "priceless" "quirky" "quizzical" "recursing" "relaxed"
        "reverent" "romantic" "sad" "serene" "sharp" "silly" "sleepy" "stoic"
        "strange" "stupefied" "suspicious" "sweet" "tender" "thirsty" "trusting"
        "unruffled" "upbeat" "vibrant" "vigilant" "vigorous" "wizardly" "wonderful"
        "xenodochial" "youthful" "zealous" "zen"
    )
    
    # Names (famous scientists and hackers, Docker-style)
    local names=(
        "albattani" "allen" "almeida" "antonelli" "agnesi" "archimedes" "ardinghelli"
        "aryabhata" "austin" "babbage" "banach" "bardeen" "bartik" "bassi" "beaver"
        "bell" "benz" "bhabha" "bhaskara" "black" "blackburn" "blackwell" "bohr"
        "booth" "borg" "bose" "bouman" "boyd" "brahmagupta" "brattain" "brown"
        "buck" "burnell" "cannon" "carson" "cartwright" "cerf" "chandrasekhar"
        "chaplygin" "chatelet" "chatterjee" "chebyshev" "cohen" "chaum" "clarke"
        "colden" "cori" "cray" "curran" "curie" "darwin" "davinci" "dewdney" "dhawan"
        "diffie" "dijkstra" "dirac" "driscoll" "dubinsky" "easley" "edison" "einstein"
        "elbakyan" "elgamal" "elion" "ellis" "engelbart" "euclid" "euler" "faraday"
        "feistel" "fermat" "fermi" "feynman" "franklin" "gagarin" "galileo" "galois"
        "gandhi" "gauss" "germain" "goldberg" "goldstine" "goldwasser" "golick"
        "goodall" "gould" "greider" "grothendieck" "haibt" "hamilton" "haslett"
        "hawking" "hellman" "heisenberg" "hermann" "herschel" "hertz" "heyrovsky"
        "hodgkin" "hofstadter" "hoover" "hopper" "hugle" "hypatia" "ishizaka"
        "jackson" "jang" "jennings" "jepsen" "johnson" "joliot" "jones" "kalam"
        "kapitsa" "kare" "keldysh" "keller" "kepler" "kilby" "kirch" "knuth"
        "kowalevski" "lalande" "lamarr" "lamport" "leakey" "leavitt" "lederberg"
        "lehmann" "lewin" "lichterman" "liskov" "lovelace" "lumiere" "mahavira"
        "margulis" "matsumoto" "maxwell" "mayer" "mccarthy" "mcclintock" "mclaren"
        "mclean" "mcnulty" "mendel" "mendeleev" "meitner" "meninsky" "merkle"
        "mestorf" "mirzakhani" "montalcini" "moore" "morse" "murdock" "moser"
        "napier" "nash" "neumann" "newton" "nightingale" "nobel" "noether" "northcutt"
        "noyce" "panini" "pare" "pascal" "pasteur" "payne" "perlman" "pike" "poincare"
        "poitras" "proskuriakova" "ptolemy" "raman" "ramanujan" "ride" "ritchie"
        "rhodes" "robinson" "roentgen" "rosalind" "rubin" "saha" "sammet" "sanderson"
        "satoshi" "shamir" "shannon" "shaw" "shirley" "shockley" "shtern" "sinoussi"
        "snyder" "solomon" "spence" "stonebraker" "sutherland" "swanson" "swartz"
        "swirles" "taussig" "tereshkova" "tesla" "tharp" "thompson" "torvalds" "tu"
        "turing" "varahamihira" "vaughan" "visvesvaraya" "volhard" "villani" "wescoff"
        "wilbur" "wiles" "williams" "williamson" "wilson" "wing" "wozniak" "wright"
        "wu" "yalow" "yonath" "zhukovsky"
    )
    
    # Generate random indices
    local adj_index=$((RANDOM % ${#adjectives[@]}))
    local name_index=$((RANDOM % ${#names[@]}))
    
    echo "${adjectives[$adj_index]}_${names[$name_index]}"
}

# Smart tmux function - creates new session with random name or attaches to existing
tm() {
    if [[ $# -eq 0 ]]; then
        # No arguments - create new session with random name or attach to existing
        if tmux list-sessions &>/dev/null; then
            # Sessions exist, try to attach to most recent detached session
            local detached_session=$(tmux list-sessions -F '#{session_name}:#{session_attached}' | grep ':0$' | head -n1 | cut -d: -f1)
            if [[ -n "$detached_session" ]]; then
                tmux attach-session -t "$detached_session"
            else
                # All sessions attached, create new one with random name
                local session_name=$(tmux_random_name)
                tmux new-session -s "$session_name"
            fi
        else
            # No sessions exist, create new one with random name
            local session_name=$(tmux_random_name)
            tmux new-session -s "$session_name"
        fi
    elif [[ $1 == "new" ]] || [[ $1 == "n" ]]; then
        # Explicitly request new session with random name
        local session_name=$(tmux_random_name)
        tmux new-session -s "$session_name"
    else
        # Session name provided, use standard tmux behavior
        tmux "$@"
    fi
}

# Vim function - prefer nvim if available
# Remove any existing vim alias first
unalias vim 2>/dev/null || true
vim() {
    if command -v nvim &> /dev/null; then
        nvim "$@"
    else
        command vim "$@"
    fi
}

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Tmux aliases (tm is now a function with Docker-style random names)
alias tma='tmux attach-session -t'
alias tmn='tm new'  # Creates new session with random name
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'
alias tmka='tmux kill-server'  # Kill all sessions

# FZF + Git aliases
alias gb='gco'           # Git branch checkout (using gco function below)
alias gl='gshow'         # Git log with FZF
alias ga='gadd'          # Git add with FZF
alias gr='greset'        # Git reset with FZF
alias gs='gstash'        # Git stash with FZF
alias gbd='gbdel'        # Git branch delete
alias gh='ghistory'      # Git file history
alias gt='gtags'         # Git tags with FZF
alias gf='gsearch'       # Git search commits

# Enhanced FZF aliases
alias f='fe'             # Find and edit files
alias fd='fcd'           # Find and cd to directory
alias fk='fkill'         # Find and kill process
alias fv='fenv'          # Browse environment variables

# FZF-tab configuration
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no

# Enhanced FZF-tab previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'if [[ -d $realpath ]]; then eza --color=always $realpath; else bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath; fi'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath'

# Git-specific FZF-tab previews
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/\\.\\*// <<< "$group[$word]") 2>/dev/null'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-add:*' fzf-preview 'git diff --color=always $realpath 2>/dev/null || bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:git-diff:*' fzf-preview 'git diff --color=always $word 2>/dev/null || git diff --color=always --cached $word 2>/dev/null'

# Process completion
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o pid,ppid,user,comm,args'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'

# Environment variables
zstyle ':fzf-tab:complete:export:*' fzf-preview 'echo $word'
zstyle ':fzf-tab:complete:unset:*' fzf-preview 'echo $word: ${(P)word}'

# Systemctl services
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Man pages
zstyle ':fzf-tab:complete:man:*' fzf-preview 'man $word | col -bx'

# Docker completion
zstyle ':fzf-tab:complete:docker:*' fzf-preview 'docker inspect $word 2>/dev/null'
zstyle ':fzf-tab:complete:docker-container:*' fzf-preview 'docker inspect $word 2>/dev/null'
zstyle ':fzf-tab:complete:docker-image:*' fzf-preview 'docker inspect $word 2>/dev/null'

# General options
zstyle ':fzf-tab:*' switch-group F1 F2
zstyle ':fzf-tab:*' fzf-flags '--color=fg:#f7768e,bg:#1a1b26,hl:#7aa2f7' '--color=fg+:#c0caf5,bg+:#283457,hl+:#7dcfff' '--color=info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7'

# Enable kubectl completion if available
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# Simple prompt configuration for servers
# For advanced themes (Powerlevel10k), run desktop-shell-extras.sh
ZSHRC_EOF

  # Create custom functions file
  cat >"$HOME/.zsh_functions" <<'FUNCTIONS_EOF'
# Custom Zsh Functions

# Display formatted PATH
path() {
    echo $PATH | tr ":" "\n" | nl
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)          echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ============================================================================
# FZF + Git Integration Functions
# ============================================================================

# Git checkout branch/tag with FZF
unalias gco 2>/dev/null # Unaliasing gco to avoid duplicate reference
gco() {
    local branches branch
    branches=$(git --no-pager branch -a \
        --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
        | sed '/^$/d') || return
    branch=$(echo "$branches" |
        fzf --height=50% --ansi --border --preview "git --no-pager log -150 --pretty=format:%s '..{2}'") &&
    git checkout $(echo "$branch" | awk '{print $NF}' | sed "s#remotes/[^/]*/##")
}

# Git show commits with FZF (interactive log)
gshow() {
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
        --bind "ctrl-m:execute:
            (grep -o '[a-f0-9]\{7\}' | head -1 |
            xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
            {}
FZF-EOF"
}

# Git add files with FZF (interactive add)
gadd() {
    local files
    files=$(git -c color.status=always status --short |
        fzf --ansi --multi --nth 2..,.. \
            --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
        cut -c4- | sed 's/.* -> //')
    [[ -n "$files" ]] && echo "$files" | xargs git add --verbose
}

# Git reset files with FZF (interactive reset)
greset() {
    local files
    files=$(git diff --cached --name-only |
        fzf --multi --preview 'git diff --cached --color=always -- {} | head -500')
    [[ -n "$files" ]] && echo "$files" | xargs git reset HEAD --
}

# Git stash show with FZF
gstash() {
    local stash
    stash=$(git stash list --pretty=format:"%C(red)%h%C(reset) - %C(dim yellow)(%C(bold magenta)%gd%C(dim yellow))%C(reset) %<(70,trunc)%s %C(green)(%cr) %C(bold blue)<%an>%C(reset)" |
        fzf --ansi --no-sort --header="Enter: show, Ctrl-D: diff, Ctrl-A: apply, Ctrl-X: drop" \
            --preview 'git stash show --color=always -p $(echo {} | cut -d" " -f1)' \
            --bind 'enter:execute(git stash show --color=always -p $(echo {} | cut -d" " -f1) | less -r > /dev/tty)' \
            --bind 'ctrl-d:execute(git diff --color=always $(echo {} | cut -d" " -f1) | less -r > /dev/tty)' \
            --bind 'ctrl-a:execute(git stash apply $(echo {} | cut -d" " -f1))' \
            --bind 'ctrl-x:execute(git stash drop $(echo {} | cut -d" " -f1))')
}

# Git branch delete with FZF
gbdel() {
    local branches branch
    branches=$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | 
        awk '$1 != "master" && $1 != "main" && $1 != "develop"') || return
    branch=$(echo "$branches" | fzf --multi --header="Select branches to delete" |
        awk '{print $1}')
    [[ -n "$branch" ]] && echo "$branch" | xargs git branch -D
}

# Git file history with FZF
ghistory() {
    local file
    file="$1"
    [[ -z "$file" ]] && file=$(git ls-files | fzf --header="Select file to view history")
    [[ -n "$file" ]] && git log --follow --color=always --oneline -- "$file" |
        fzf --ansi --no-sort --reverse --tiebreak=index \
            --preview "git show --color=always {1}:$file" \
            --bind "enter:execute(git show --color=always {1} -- $file | less -R > /dev/tty)"
}

# Git worktree with FZF
gwtree() {
    local worktrees
    worktrees=$(git worktree list --porcelain | awk '/^worktree/ {print $2}' | 
        fzf --header="Select worktree to switch to" --preview 'ls -la {}')
    [[ -n "$worktrees" ]] && cd "$worktrees"
}

# Git tags with FZF
gtags() {
    local tags tag
    tags=$(git tag --sort=-version:refname) || return
    tag=$(echo "$tags" | 
        fzf --header="Select tag" --preview 'git show --color=always {}')
    [[ -n "$tag" ]] && git checkout "$tag"
}

# Git search in commits with FZF
gsearch() {
    local query="$1"
    [[ -z "$query" ]] && echo "Usage: gsearch <search-term>" && return
    git log --oneline --color=always -S "$query" |
        fzf --ansi --no-sort --reverse --tiebreak=index \
            --preview "git show --color=always {1}" \
            --bind "enter:execute(git show --color=always {1} | less -R > /dev/tty)"
}

# ============================================================================
# Enhanced FZF Functions
# ============================================================================

# Find and edit files with FZF
fe() {
    local files
    files=$(fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules |
        fzf --multi --preview 'bat --color=always --style=numbers --line-range=:500 {}')
    [[ -n "$files" ]] && ${EDITOR:-nvim} $files
}

# Find directories and cd with FZF
fcd() {
    local dir
    dir=$(fd --type d --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules |
        fzf --preview 'eza --tree --level=2 --color=always {} || ls -la {}')
    [[ -n "$dir" ]] && cd "$dir"
}

# Process finder and killer with FZF
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header="Select process to kill" |
        awk '{print $2}')
    [[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-9}
}

# Environment variable browser with FZF
fenv() {
    env | fzf --preview 'echo {}'
}

# Command history search with context
fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | 
        fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}
FUNCTIONS_EOF

  print_success "Zsh configuration created"
}

# Install FZF (idempotent)
install_fzf() {
  print_status "Installing FZF..."

  local FZF_VERSION="0.65.0"
  local INSTALL_DIR="$HOME/.local/bin"
  local CURRENT_VERSION=""

  # Create install directory if it doesn't exist
  mkdir -p "$INSTALL_DIR"

  # Check if fzf is already installed and get version
  if command -v fzf &>/dev/null; then
    CURRENT_VERSION=$(fzf --version 2>/dev/null | cut -d' ' -f1)
    print_status "FZF is already installed (version $CURRENT_VERSION)"

    # Compare versions - if current is >= desired, skip installation
    if [[ "$CURRENT_VERSION" == "$FZF_VERSION" ]] || [[ "$CURRENT_VERSION" > "$FZF_VERSION" ]]; then
      print_success "FZF $CURRENT_VERSION is up to date"

      # Ensure shell integration is set up
      if [[ ! -f "$HOME/.fzf.zsh" ]]; then
        print_status "Setting up FZF shell integration..."
        setup_fzf_shell_integration
      fi
      return 0
    else
      print_status "Upgrading FZF from $CURRENT_VERSION to $FZF_VERSION..."
    fi
  fi

  # Detect OS and architecture
  local OS=""
  local ARCH=""

  case "$(uname -s)" in
  Linux*) OS="linux" ;;
  Darwin*) OS="darwin" ;;
  *)
    print_error "Unsupported OS: $(uname -s)"
    return 1
    ;;
  esac

  case "$(uname -m)" in
  x86_64) ARCH="amd64" ;;
  aarch64 | arm64) ARCH="arm64" ;;
  armv7l) ARCH="armv7" ;;
  *)
    print_error "Unsupported architecture: $(uname -m)"
    return 1
    ;;
  esac

  # Download the latest FZF binary
  local DOWNLOAD_URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-${OS}_${ARCH}.tar.gz"
  local TEMP_DIR=$(mktemp -d)

  print_status "Downloading FZF ${FZF_VERSION} for ${OS}_${ARCH}..."

  if command -v curl &>/dev/null; then
    curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/fzf.tar.gz" || {
      print_error "Failed to download FZF"
      rm -rf "$TEMP_DIR"
      return 1
    }
  elif command -v wget &>/dev/null; then
    wget -qO "$TEMP_DIR/fzf.tar.gz" "$DOWNLOAD_URL" || {
      print_error "Failed to download FZF"
      rm -rf "$TEMP_DIR"
      return 1
    }
  else
    print_error "Neither curl nor wget is available"
    rm -rf "$TEMP_DIR"
    return 1
  fi

  # Extract and install
  print_status "Installing FZF binary..."
  tar -xzf "$TEMP_DIR/fzf.tar.gz" -C "$TEMP_DIR" || {
    print_error "Failed to extract FZF"
    rm -rf "$TEMP_DIR"
    return 1
  }

  # Move the binary to the install directory
  mv "$TEMP_DIR/fzf" "$INSTALL_DIR/fzf" || {
    print_error "Failed to install FZF binary"
    rm -rf "$TEMP_DIR"
    return 1
  }

  # Make it executable
  chmod +x "$INSTALL_DIR/fzf"

  # Clean up
  rm -rf "$TEMP_DIR"

  # Add to PATH if not already there
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    export PATH="$INSTALL_DIR:$PATH"
  fi

  # Setup shell integration
  setup_fzf_shell_integration

  print_success "FZF ${FZF_VERSION} installed successfully"
}

# Setup FZF shell integration
setup_fzf_shell_integration() {
  local FZF_BASE="$HOME/.fzf"

  # Clone the FZF repository for shell integration scripts if not present
  if [[ ! -d "$FZF_BASE" ]]; then
    print_status "Cloning FZF repository for shell integration..."
    git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "$FZF_BASE"
  fi

  # Setup key bindings and completion for Zsh using fzf --zsh
  if command -v fzf &>/dev/null; then
    # Use fzf's built-in shell integration command
    print_status "Generating FZF shell integration..."
    fzf --zsh >"$HOME/.fzf.zsh" 2>/dev/null || {
      # Fallback to manual setup if fzf --zsh doesn't work
      print_status "Using fallback FZF configuration..."
      cat >"$HOME/.fzf.zsh" <<'FZF_ZSH_EOF'
# Setup fzf
# ---------
if [[ ! "$PATH" == *$HOME/.local/bin* ]]; then
  export PATH="${PATH:+${PATH}:}$HOME/.local/bin"
fi

# Auto-completion
# ---------------
if [[ $- == *i* ]]; then
  source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null
fi

# Key bindings
# ------------
source "$HOME/.fzf/shell/key-bindings.zsh" 2> /dev/null
FZF_ZSH_EOF
    }
  fi

  print_success "FZF shell integration configured"
}

# Install Z directory jumper (idempotent)
install_z() {
  print_status "Installing Z directory jumper..."

  if [[ -f "$HOME/.z.sh" ]]; then
    print_success "Z is already installed"
    return 0
  fi

  curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o "$HOME/.z.sh"
  chmod +x "$HOME/.z.sh"
  print_success "Z installed"
}

# Install Neovim (idempotent)
install_neovim() {
  print_status "Installing Neovim..."

  if command -v nvim &>/dev/null; then
    local nvim_version=$(nvim --version | head -n1)
    print_success "Neovim is already installed ($nvim_version)"

    # Check if version is >= 0.9.0 for LazyVim
    local version_num=$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    if [[ $(echo "$version_num" | cut -d. -f2) -lt 9 ]]; then
      print_warning "LazyVim requires Neovim 0.9.0+. Current version: $version_num"
      print_status "Attempting to update Neovim..."
    else
      return 0
    fi
  fi

  case "$OS" in
  ubuntu | debian)
    # Use AppImage for latest version
    print_status "Installing Neovim via AppImage for latest version..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mkdir -p /opt/nvim
    sudo mv nvim.appimage /opt/nvim/
    sudo ln -sf /opt/nvim/nvim.appimage /usr/local/bin/nvim
    ;;
  fedora | centos | rhel | rocky | almalinux)
    sudo dnf install -y neovim || {
      # Fallback to AppImage
      print_status "Installing Neovim via AppImage..."
      curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
      chmod u+x nvim.appimage
      sudo mkdir -p /opt/nvim
      sudo mv nvim.appimage /opt/nvim/
      sudo ln -sf /opt/nvim/nvim.appimage /usr/local/bin/nvim
    }
    ;;
  arch | manjaro)
    sudo pacman -S --noconfirm neovim
    ;;
  alpine)
    sudo apk add --no-cache neovim
    ;;
  opensuse* | sles)
    sudo zypper install -y neovim
    ;;
  macos)
    brew install neovim
    ;;
  *)
    print_error "Unsupported OS for Neovim installation: $OS"
    return 1
    ;;
  esac

  print_success "Neovim installed successfully"
}

# LazyVim installation moved to desktop-shell-extras.sh
# For advanced Neovim IDE setup, run desktop-shell-extras.sh

# Kitty installation moved to separate kitty-installer.sh script
# This keeps install-shell.sh lightweight and server-focused

# Install shell tools (idempotent)
install_shell_tools() {
  print_status "Installing additional shell tools..."

  case "$OS" in
  ubuntu | debian)
    sudo apt-get update
    sudo apt-get install -y \
      curl wget git \
      htop tree jq \
      ripgrep fd-find bat \
      ncdu tldr \
      2>/dev/null || true

    # Create symlinks for renamed packages
    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

    # Install eza if not present
    if ! command -v eza &>/dev/null; then
      print_status "Installing eza..."
      local EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
      curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
      sudo tar -xzf /tmp/eza.tar.gz -C /usr/local/bin
      rm /tmp/eza.tar.gz
    fi
    ;;
  fedora | centos | rhel | rocky | almalinux)
    sudo dnf install -y \
      curl wget git \
      htop tree jq \
      ripgrep fd-find bat \
      ncdu \
      2>/dev/null || sudo yum install -y \
      curl wget git \
      htop tree jq \
      2>/dev/null || true
    ;;
  arch | manjaro)
    sudo pacman -S --noconfirm \
      curl wget git \
      htop tree jq \
      ripgrep fd bat eza \
      ncdu \
      2>/dev/null || true
    ;;
  macos)
    brew install \
      htop tree jq \
      ripgrep fd bat eza \
      ncdu tldr \
      zoxide starship \
      2>/dev/null || true
    ;;
  esac

  print_success "Shell tools installed"
}

# Nerd Fonts installation moved to desktop-shell-extras.sh
# For enhanced terminal fonts, run desktop-shell-extras.sh

# Install tmux (idempotent)
install_tmux() {
  print_status "Installing tmux..."

  if command -v tmux &>/dev/null; then
    local tmux_version=$(tmux -V | cut -d' ' -f2)
    print_success "Tmux is already installed (version $tmux_version)"
    return 0
  fi

  print_status "Installing tmux package..."
  case "$OS" in
  ubuntu | debian)
    sudo apt-get update
    sudo apt-get install -y tmux
    ;;
  fedora | centos | rhel | rocky | almalinux)
    sudo dnf install -y tmux || sudo yum install -y tmux
    ;;
  arch | manjaro)
    sudo pacman -S --noconfirm tmux
    ;;
  alpine)
    sudo apk add --no-cache tmux
    ;;
  opensuse* | sles)
    sudo zypper install -y tmux
    ;;
  macos)
    if ! command -v brew &>/dev/null; then
      print_warning "Homebrew not found. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install tmux
    ;;
  *)
    print_error "Unsupported OS for tmux installation: $OS"
    return 1
    ;;
  esac

  print_success "Tmux installed successfully"
}

# Install TPM (Tmux Plugin Manager)
install_tpm() {
  print_status "Installing Tmux Plugin Manager (TPM)..."

  local tpm_path="$HOME/.tmux/plugins/tpm"

  if [[ ! -d "$tpm_path" ]]; then
    print_status "Cloning TPM repository..."
    git clone --quiet https://github.com/tmux-plugins/tpm "$tpm_path"
    print_success "TPM installed"
  else
    print_status "TPM already installed, updating..."
    cd "$tpm_path" && git pull --quiet
    cd - >/dev/null
    print_success "TPM updated"
  fi

  mkdir -p "$HOME/.tmux/plugins"
}

# Configure tmux with Catppuccin Frappe theme (idempotent)
configure_tmux() {
  print_status "Configuring tmux..."

  # Backup existing config
  if [[ -f "$HOME/.tmux.conf" ]] && [[ ! -L "$HOME/.tmux.conf" ]]; then
    cp "$HOME/.tmux.conf" "$BACKUP_DIR/tmux.conf" 2>/dev/null || true
    print_status "Backed up existing tmux.conf"
  fi

  # Create tmux configuration with Catppuccin Frappe theme
  cat >"$HOME/.tmux.conf" <<'TMUX_EOF'
# Enhanced Tmux Configuration - Generated by install-shell.sh
# Catppuccin Frappe Theme (matching Kitty terminal)

# General Settings
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color*:Tc"
set -g mouse on
set -g set-clipboard on
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g focus-events on
set -s escape-time 10
set -g repeat-time 600

# Prefix key (Ctrl-a instead of Ctrl-b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Window splitting
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# New window in current path
bind c new-window -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Window navigation
bind -r C-h select-window -t :-
bind -r C-l select-window -t :+

# Copy mode vim bindings
setw -g mode-keys vi
bind [ copy-mode
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind -T copy-mode-vi Escape send-keys -X cancel

# Catppuccin Frappe Theme - Status Bar
set -g status-bg "#232634"
set -g status-fg "#c6d0f5"
set -g status-interval 5
set -g status-position bottom
set -g status-left-length 50
set -g status-right-length 150

# Status bar content with slanted design (matching Kitty)
set -g status-left "#[fg=#232634,bg=#8caaee,bold] #S #[fg=#8caaee,bg=#414559]#[fg=#c6d0f5,bg=#414559] #I:#P #[fg=#414559,bg=#232634]"
set -g status-right "#[fg=#414559,bg=#232634]#[fg=#c6d0f5,bg=#414559] #(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1 || echo 'No IP') #[fg=#51576d,bg=#414559]#[fg=#a6d189,bg=#51576d] %H:%M #[fg=#626880,bg=#51576d]#[fg=#e5c890,bg=#626880] %d-%b #[fg=#8caaee,bg=#626880]#[fg=#232634,bg=#8caaee] #(whoami)@#h #{?client_prefix,#[fg=#e78284] ●,}"

# Window status with slanted design
setw -g window-status-format "#[fg=#232634,bg=#51576d]#[fg=#737994,bg=#51576d] #I:#W #[fg=#51576d,bg=#232634]"
setw -g window-status-current-format "#[fg=#232634,bg=#8caaee]#[fg=#232634,bg=#8caaee,bold] #I:#W #[fg=#8caaee,bg=#232634]"
setw -g monitor-activity on
set -g visual-activity off
setw -g window-status-activity-style "fg=#e78284,bg=#232634,bold"

# Pane borders
set -g pane-border-style "fg=#414559"
set -g pane-active-border-style "fg=#8caaee"

# Message styling
set -g message-style "fg=#c6d0f5,bg=#414559,bold"
set -g message-command-style "fg=#c6d0f5,bg=#414559,bold"

# Tmux Plugin Manager
# TPM - Plugin manager for tmux (required for all plugins below)
set -g @plugin 'tmux-plugins/tpm'

# Essential plugins for better tmux experience
set -g @plugin 'tmux-plugins/tmux-sensible'       # Sensible defaults for tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'      # Save/restore tmux sessions manually (Ctrl-s/Ctrl-r)
set -g @plugin 'tmux-plugins/tmux-continuum'      # Auto-save sessions periodically (uses resurrect)
set -g @plugin 'tmux-plugins/tmux-yank'           # Copy to system clipboard
set -g @plugin 'tmux-plugins/tmux-copycat'        # Regex searches with predefined patterns (URLs, IPs, etc)
set -g @plugin 'tmux-plugins/tmux-open'           # Open files/URLs directly from tmux

# Session persistence configuration
# Resurrect: Core save/restore functionality
set -g @resurrect-capture-pane-contents 'on'      # Save pane contents (scrollback)
set -g @resurrect-strategy-nvim 'session'         # Restore nvim sessions if available

# Continuum: Automation for resurrect
set -g @continuum-restore 'off'                   # Manual restore only - start fresh by default
set -g @continuum-save-interval '10'              # Auto-save every 10 minutes for safety

# Usage tips:
# - Save session: prefix + Ctrl-s
# - Restore session: prefix + Ctrl-r (when you want old sessions back)
# - Search: prefix + / (copycat - search for URLs, files, IPs, etc)
# - Open URL/file: prefix + o (open highlighted text)
# - Copy: prefix + y (copy to system clipboard)

# Initialize TPM (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
TMUX_EOF

  print_success "Tmux configuration created"
}

# Install tmux plugins
install_tmux_plugins() {
  print_status "Installing tmux plugins..."

  if [[ ! -f ~/.tmux/plugins/tpm/bin/install_plugins ]]; then
    print_warning "TPM plugin installer not found. Plugins will install on first tmux start."
    return 0
  fi

  # Start temporary tmux server to install plugins
  tmux new-session -d -s __temp_plugin_install__ 2>/dev/null || true
  sleep 2

  ~/.tmux/plugins/tpm/bin/install_plugins 2>/dev/null || true

  # Kill temporary session
  tmux kill-session -t __temp_plugin_install__ 2>/dev/null || true

  print_success "Tmux plugins installed"
}

# Change default shell to Zsh
change_shell() {
  print_status "Checking default shell..."

  if [[ "$SHELL" == *"zsh"* ]]; then
    print_success "Zsh is already the default shell"
    return 0
  fi

  print_status "Would you like to change your default shell to Zsh? (Y/n)"
  read -r response
  if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
    if command -v zsh &>/dev/null; then
      local zsh_path="$(command -v zsh)"

      # Add zsh to /etc/shells if not already there
      if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
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

# Show summary
show_summary() {
  echo
  echo "========================================"
  echo "Shell Environment Installation Summary"
  echo "========================================"
  echo
  print_success "✓ Zsh installed and configured"
  print_success "✓ Oh My Zsh framework installed"
  print_success "✓ Plugins: autosuggestions, syntax-highlighting, completions, fzf-tab"
  print_success "✓ Simple prompt theme configured (robbyrussell)"
  print_success "✓ FZF fuzzy finder installed"
  print_success "✓ Z directory jumper installed"
  print_success "✓ Additional shell tools installed"
  print_success "✓ Server-optimized configuration (no GUI fonts)"
  print_success "✓ Server-optimized shell environment (no GUI terminal)"
  print_success "✓ Neovim installed (run desktop-shell-extras.sh for LazyVim IDE)
  print_success "✓ Tmux installed with Catppuccin Frappe theme"
  echo
  print_status "📋 Configuration files:"
  echo "  • ~/.zshrc - Main configuration"
  echo "  • ~/.zsh_functions - Custom functions"
  echo "  • ~/.z.sh - Directory jumper"
  echo "  • Terminal: Use kitty-installer.sh for GUI terminal setup"
  echo "  • Desktop extras: Run desktop-shell-extras.sh for LazyVim, fonts, and themes"
  echo "  • ~/.config/nvim/ - Neovim configuration (run desktop-shell-extras.sh for LazyVim IDE)"
  echo "  • ~/.tmux.conf - Tmux config (Catppuccin Frappe theme, matching Kitty)"
  echo
  print_status "📁 Log file: $LOG_FILE"
  echo
  print_warning "📝 Next Steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. For GUI terminal: Run kitty-installer.sh script"
  echo "  3. Start tmux with: tmux (Catppuccin Frappe theme pre-configured)"
  echo "  4. Run 'nvim' to start Neovim (or run desktop-shell-extras.sh for LazyVim IDE)"
  echo "  5. Run 'kitty +kitten themes' to browse more themes (Catppuccin Frappe is default)"
  echo "  6. Optional: Run desktop-shell-extras.sh for advanced prompt themes (Powerlevel10k)"
  echo "  7. Try these commands:"
  echo "     • Ctrl+T - Fuzzy find files with preview"
  echo "     • Ctrl+R - Enhanced history search"
  echo "     • Alt+C - Fuzzy find directories"
  echo "     • z <partial-path> - Jump to directory"
  echo "     • cd <TAB> - Browse directories with preview"
  echo ""
  echo "  8. Git + FZF integration:"
  echo "     • gb - Interactive branch checkout"
  echo "     • gl - Interactive git log viewer"
  echo "     • ga - Interactive git add"
  echo "     • gs - Interactive git stash"
  echo "     • gh - File history viewer"
  echo "     • gf <term> - Search commits"
  echo ""
  echo "  9. Enhanced FZF functions:"
  echo "     • f - Find and edit files"
  echo "     • fd - Find and cd to directory"
  echo "     • fk - Find and kill processes"
  echo "     • fv - Browse environment variables"
  echo ""
  echo "  10. Other tools:"
  echo "     • nvim - Launch Neovim"
  echo "     • tmux - Start terminal multiplexer"
  echo "     • Prefix+r - Reload tmux config (Prefix is Ctrl+a)"
  echo
  print_status "🚀 Your enhanced shell environment is ready!"
}

# Main installation
main() {
  clear
  echo "========================================"
  echo "Server-Focused Shell Environment Installer"
  echo "========================================"
  echo "Lightweight setup without GUI components"
  echo

  # Pre-flight checks
  check_root
  detect_os

  # Backup existing configs
  backup_existing_configs

  # Core installations
  install_zsh
  install_oh_my_zsh
  install_zsh_plugins
  setup_prompt_theme  # Simple theme for servers
  configure_zsh

  # Additional tools
  install_fzf
  install_z
  install_shell_tools

  # Basic editor (advanced IDE setup in desktop-shell-extras.sh)
  install_neovim

  # Tmux installation and configuration
  install_tmux
  install_tpm
  configure_tmux
  install_tmux_plugins

  # Optionally change default shell
  change_shell

  # Show summary
  show_summary
  
  # Offer to install desktop extras
  offer_desktop_extras
}

# Offer to install desktop extras
offer_desktop_extras() {
  echo
  print_status "Would you like to install desktop enhancements? (Y/n)"
  print_status "This includes: LazyVim IDE, Nerd Fonts, Powerlevel10k theme"
  read -r response
  
  if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
    local desktop_script="$(dirname "$0")/desktop-shell-extras.sh"
    
    if [[ -f "$desktop_script" ]]; then
      print_status "Installing desktop enhancements..."
      bash "$desktop_script"
    else
      print_warning "Desktop extras script not found at: $desktop_script"
      print_status "You can install it later by running:"
      echo "  curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/desktop-shell-extras.sh | bash"
    fi
  else
    print_status "Skipping desktop enhancements. You can install them later with:"
    echo "  ./scripts/desktop-shell-extras.sh"
  fi
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
