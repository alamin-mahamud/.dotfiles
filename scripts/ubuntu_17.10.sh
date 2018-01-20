# fresh install ubuntu 17.10

# 1. switch to main server
sudo nano /etc/apt/sources.list
sudo apt-get update

# install chrome -> Dropbox

sudo apt-get install -y \
	   curl \
    	   git  \
	   zsh  \
	   terminator \
	   tmux \
	   filezilla

# skypeforlinux \ messengerfordesktop \ spotify

# python
sudo apt-get install -y \
	   python3 \
	   python3-pip 
sudo pip3 install virtualenvwrapper

# i3		
sudo apt install -y \
	i3-wm \
	i3blocks \
	rofi \
	thunar \
	arandr \
	pavucontrol \
	compton \
	feh \
	ranger \
	unclutter \
	htop \
	arandr

# 8. install i3 gaps
# install dependencies first
sudo apt install -y \
libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf libxcb-xrm0 libxcb-xrm-dev automake

# install from airblader github repo
mkdir ~/Downloads/Linux
cd ~/Downloads/Linux

## clone the repo
git clone https://www.github.com/Airblader/i3 i3-gaps
cd i3-gaps
rm -rf build/
mkdir -p build && cd build/

## compile and install
autoreconf --force --install

# Disabling sanitizers is important for release versions!
# The prefix and sysconfdir are, obviously, dependent on the distribution.
../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers
make 
sudo make install

# 9. install i3blocks gaps 
git clone https://github.com/Airblader/i3blocks-gaps.git i3blocks-gaps
cd i3blocks-gaps
make
sudo make install

# 10. create dotfiles symlinks
ln -s ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/dotfiles/git/.gitignore ~/.gitignore

ln -s ~/dotfiles/.compton.conf ~/
ln -s ~/dotfiles/.xinitrc ~/
ln -s ~/dotfiles/.Xresources ~/

ln -s ~/dotfiles/.config/dunst ~/.config/
ln -s ~/dotfiles/.config/i3blocks ~/.config/
ln -s ~/dotfiles/.config/i3lock ~/.config/

ln -s ~/dotfiles/scripts/scripts ~/
ln -s ~/dotfiles/.fonts ~/

# 11. install fonts from git
git clone https://github.com/gabrielelana/awesome-terminal-fonts.git
cd awesome-terminal-fonts

# install zsh & clone ohmyzsh
sudo apt install -y zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# install python3 and pip and virtualenvwrapper
sudo apt-get install -y python3-pip
pip3 install virtualenvwrapper

# 12. install emacs from source
## install dep
sudo apt-get install libtiff5-dev libpng12-dev libjpeg-dev libgif-dev libgnutls-dev libxml2-dev libxpm-dev libtinfo-dev

## install GTK3
sudo apt-get install libgtk-3-dev libgtk-3-common libgtk-3-0

## unpack emacs
cd ~/Downloads
tar xvf emacs-*.tar.gz

cd emacs-<version>*
./autogen.sh

## intstall libXpm [if needed]

./configure --with-x-toolkit=gtk3 [--prefix=/path/to/dir]
make 
sudo make install

# 13. Install NodeJS
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

## helps to reload
npm install -g nodemon

## js-beautify for emacs editing
npm install -g js-beautify

# 13. install numix theme
sudo apt install numix-gtk-theme
sudo add-apt-repository ppa:numix/ppa
sudo apt-get update
sudo apt-get install numix-icon-theme

# 14. install heroku
# Run this from your terminal.
# The following will add our apt repository and install the CLI:
sudo add-apt-repository "deb https://cli-assets.heroku.com/branches/stable/apt ./"
curl -L https://cli-assets.heroku.com/apt/release.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install heroku

# 15. zsh && oh-my-zsh && powerline
sudo apt-get install zsh
sudo chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
#in .zshrc file
ZSH_THEME="powerlevel9k/powerlevel9k"

# 16. install tmux & fortune
sudo apt install tmux fortune

# 17. install neofetch
#Add PPA
sudo add-apt-repository ppa:dawidd0811/neofetch
#Update repositories
sudo apt update
#Install the package
sudo apt install neofetch 


# 18. change lightdm to console login

#Edit /etc/default/grub with your favourite editor, e.g. nano:
sudo nano /etc/default/grub

#Find this line:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

#Change it to:
GRUB_CMDLINE_LINUX_DEFAULT="text"

#Change GRUB_TIMEOUT=1

#Update GRUB:
sudo update-grub

#To boot to console:
sudo systemctl set-default multi-user.target

#To get to the Unity desktop from the console, you must enter the command:
sudo systemctl start lightdm.service

#(The usual startx command doesn't work with Unity.)
#To restore boot to GUI:
sudo systemctl set-default graphical.target

# 19. install nitrogen
sudo apt-get install nitrogen -y

# 20. get rid of nautilus desktop window
gsettings set org.gnome.desktop.background show-desktop-icons false
