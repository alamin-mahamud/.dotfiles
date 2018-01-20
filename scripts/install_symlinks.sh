#!/bin/bash

DROPBOX=$HOME/Dropbox
DOT=$HOME/dotfiles

ln -sf $DROPBOX/dotfiles
ln -sf $DROPBOX/work/

ln -sf $DOT/zsh/.zshrc

ln -sf $DOT/.emacs.d

ln -sf $DOT/git/.gitconfig
ln -sf $DOT/git/.gitignore
ln -sf $DOT/git/.gitmessage

ln -sf $DOT/scripts

ln -sf $DOT/.fonts

ln -sf $DOT/.i3

ln -sf $DOT/.xinitrc
ln -sf $DOT/.xprofile
ln -sf $DOT/.Xresources

ln -sf $DOT/.config/dunst ~/.config/
ln -sf $DOT/.config/i3blocks ~/.config/
ln -sf $DOT/.config/i3lock ~/.config/
ln -sf $DOT/.config/dunst ~/.config/
ln -sf $DOT/.config/neofetch ~/.config
ln -sf $DOT/.config/terminator ~/.config/
ln -sf $DOT/.config/wallpapers ~/.config/

ln -sf $DOT/tmux/.tmux.conf
ln -sf $DOT/tmux/.tmux.conf.local
