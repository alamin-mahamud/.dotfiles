# ├── aliases.zsh
# ├── bindkeys.zsh
# ├── oh-my-zsh.zsh
# ├── colors.zsh
# ├── completion.zsh
# ├── exports.zsh
# ├── functions.zsh
# ├── history.zsh
# ├── prompt.zsh
# ├── setopt.zsh
# ├── zsh_hooks.zsh
# └── .zshrc

ZSH_FOLDER=$HOME/Dropbox/dotfiles/zsh

source $ZSH_FOLDER/checks.zsh
source $ZSH_FOLDER/colors.zsh
source $ZSH_FOLDER/setopt.zsh
source $ZSH_FOLDER/exports.zsh
source $ZSH_FOLDER/prompt.zsh
source $ZSH_FOLDER/completion.zsh
source $ZSH_FOLDER/aliases.zsh
source $ZSH_FOLDER/bindkeys.zsh
source $ZSH_FOLDER/functions.zsh
source $ZSH_FOLDER/history.zsh
source $ZSH_FOLDER/z.sh
#source $ZSH_FOLDER/om.zsh
#source $ZSH_FOLDER/zsh_hooks.zsh

tmux a
clear
neofetch --ascii_distro redhat --ascii_colors distro
