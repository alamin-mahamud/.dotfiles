DOT=$HOME/Work/.dotfiles
DOT_UBUNTU=$DOT/ubuntu

function setup_zsh_symlink() {
    ln -sf $DOT/zsh/.zshrc $HOME/.zshrc
}

function setup_git_symlink() {
    ln -sf $DOT/git/.gitconfig $HOME/.gitconfig
    ln -sf $DOT/git/.gitmessage $HOME/.gitmessage
}

function setup_i3_symlink() {
    ln -sf $DOT_UBUNTU/.config/i3 $HOME/.config/i3
    ln -sf $DOT_UBUNTU/.config/i3lock ~/.config/
    ln -sf $DOT_UBUNTU/.config/picom.conf ~/.config/
    ln -sf $DOT_UBUNTU/.config/.Xresources $HOME/.Xresources
}

function setup_util_scripts() {
    ln -sf $DOT_UBUNTU/scripts/ $HOME/.local/bin/
}