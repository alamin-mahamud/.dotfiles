#!/usr/bin/env zsh
# Minimal ZSH Configuration - DevOps Focused

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select

# Key bindings
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Prompt - minimal with git info
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{yellow}${vcs_info_msg_0_}%f %# '

# Environment
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export LESS='-R'

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Aliases - DevOps focused
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'
alias tf='terraform'
alias tg='terragrunt'
alias d='docker'
alias dc='docker-compose'
alias g='git'
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph'

# System aliases
alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tmux
alias ta='tmux attach || tmux new'
alias tl='tmux ls'
alias tn='tmux new -s'

# Network tools
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias dig='dig +short'
alias ss='ss -tulpn'

# Functions
function mkcd() { mkdir -p "$1" && cd "$1" }
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.tar.xz) tar xJf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Kubernetes helpers
function kpods() { kubectl get pods ${1:+-n $1} }
function klogs() { kubectl logs -f "$@" }
function kexec() { kubectl exec -it "$1" -- "${2:-/bin/bash}" }

# SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent -s)
fi

# Load local config if exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# FZF if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh