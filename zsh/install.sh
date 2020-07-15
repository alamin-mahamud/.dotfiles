# install omz

#sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
#git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

DOT_DIR=$HOME/Work/personal/.dotfiles
DOT_ZSH_DIR=$DOT_DIR/zsh
OMZ_DIR=$HOME/.oh-my-zsh

ln -sf $DOT_ZSH_DIR/themes/alamin.zsh-theme ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/alamin.zsh-theme
ln -sf $DOT_ZSH_DIR/.zshrc ~/.zshrc
