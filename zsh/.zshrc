ZSH_FOLDER=$HOME/Work/.dotfiles/zsh

source $ZSH_FOLDER/checks.zsh
source $ZSH_FOLDER/exports.zsh
source $ZSH_FOLDER/aliases.zsh
source $ZSH_FOLDER/functions.zsh
source $ZSH_FOLDER/history.zsh
source $ZSH_FOLDER/z.sh
source $ZSH_FOLDER/python.zsh
source $ZSH_FOLDER/omz.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Tmux aliases
alias tm='tmux'
alias tma='tmux attach-session -t'
alias tmn='tmux new-session -s'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'
alias tmks='tmux kill-server'
alias tms='tmux-sessionizer'
alias tmp='tmux-project-manager'
