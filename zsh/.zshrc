ZSH_DIR=$HOME/Work/.dotfiles/zsh

source $ZSH_DIR/bootstrap.sh
echo 'eval "$(pyenv virtualenv-init -)"'
main
alias dc='docker-compose'
