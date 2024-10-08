DOT=$HOME/Work/.dotfiles

function setup_zsh_symlink() {
    ln -sf $DOT/zsh/.zshrc $HOME/.zshrc
}

function setup_git_symlink() {
    ln -sf $DOT/git/.gitconfig $HOME/.gitconfig
    ln -sf $DOT/git/.gitmessage $HOME/.gitmessage
}

setup_zsh_symlink