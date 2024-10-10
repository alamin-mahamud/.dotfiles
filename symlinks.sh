DOT=$HOME/Work/.dotfiles

function setup_zsh_symlink() {
    ln -sf $DOT/zsh/.zshrc $HOME/.zshrc
}

function setup_git_symlink() {
    ln -sf $DOT/git/.gitconfig $HOME/.gitconfig
    ln -sf $DOT/git/.gitmessage $HOME/.gitmessage
}

function setup_fonts_symlink() {
    ln -sf $DOT/.fonts $HOME/.fonts
}

function setup_i3_symlink() {
    ln -sf $DOT/i3 $HOME/.config/i3
    ln -sf $DOT/.config/i3lock ~/.config/
}
