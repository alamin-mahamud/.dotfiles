#!/bin/bash

# System Wide Constants
# Ubuntu Code Name Ex:- zesty for Ubuntu 17.04
CODE_NAME=$(lsb_release -cs)

echo "Hi ALAMIN!"

echo "A shell script to install all required applications and dependencies required to setup working environment after fresh install ubuntu ."

## Install basic libraries required for ubuntu environment
sudo apt-get -qq install libcurl4-openssl-dev libssl-dev -y
sudo apt-get -qq install zsh -y
sudo apt-get -qq install python-software-properties -y
sudo apt-get -qq install ruby ruby-dev -y
sudo apt-get -qq install build-essential checkinstall -y
sudo apt-get -qq install python-pip python-tk python-dev -y
sudo apt-get -qq install git git-core -y
sudo apt-get -qq install ppa-purge -y
sudo apt-get -qq install vim -y
sudo apt-get -qq install unity-tweak-tool -y
sudo apt-get -qq install libzmq3 -y
sudo apt-get -qq install build-essential autoconf libtool pkg-config python-opengl python-imaging python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev -y
sudo apt-get -qq install libjpeg-dev -y
sudo apt-get -qq install software-properties-common -y

echo "Installed basic libraries required for ubuntu environment" 

## Add all ppa required for installation of applications
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo add-apt-repository ppa:gnome-terminator -y
sudo add-apt-repository ppa:numix/ppa -y
sudo add-apt-repository ppa:webupd8team/y-ppa-manager -y
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt-add-repository ppa:me-davidsansome/clementine -y
sudo add-apt-repository ppa:noobslab/macbuntu -y
sudo add-apt-repository -y ppa:webupd8team/sublime-text-3 -y
sudo add-apt-repository ppa:tualatrix/ppa -y
sudo apt-add-repository ppa:ansible/ansible -y
sudo add-apt-repository ppa:shutter/ppa -y
sudo sh -c "echo \"deb http://archive.getdeb.net/ubuntu ${CODE_NAME}-getdeb apps\" >> /etc/apt/sources.list.d/vuze.list"
sudo sh -c "echo \"deb http://packages.erlang-solutions.com/ubuntu ${CODE_NAME} contrib\" >> /etc/apt/sources.list.d/erlang-solutions.list"
sudo sh -c "echo \"deb https://apt.dockerproject.org/repo ubuntu-${CODE_NAME} main\" >> /etc/apt/sources.list.d/docker.list"
sudo sh -c "echo \"deb http://apt.postgresql.org/pub/repos/apt/ ${CODE_NAME}-pgdg main\" >> /etc/apt/sources.list.d/pgdg.list"

echo "Added all ppa required for installation of applications"

## Add all keys required for ppa
wget -q -O- http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -
wget -q -O- http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
# docker GPG key
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo "Added all keys required for ppa"

# update apt cache
sudo apt-get -qq update
echo "Updated apt cache" 

# Install all applications
sudo apt-get -qq install linux-image-extra-$(uname -r) -y
sudo apt-get -qq install openjdk-8-jdk openjdk-8-jre -y
sudo apt-get -qq install terminator -y
sudo apt-get -qq install numix-gtk-theme numix-icon-theme-circle -y
sudo apt-get -qq install libmysqlclient-dev mysql-client mysql-server -y
sudo apt-get -qq install nginx nginx-extras -y
sudo apt-get -qq install mysql-workbench -y
sudo apt-get -qq install y-ppa-manager -y
sudo apt-get -qq install grub-customizer -y
sudo apt-get -qq install azureus -y
sudo apt-get -qq install vlc -y
sudo apt-get -qq install clementine -y
sudo apt-get -qq install gnome-panel -y
sudo apt-get -qq install erlang erlang-doc erlang-manpages elixir -y
sudo apt-get -qq install ultracopier -y
sudo apt-get -qq install xchat -y
sudo apt-get -qq install irssi irssi-scripts screen openssh-server -y
sudo apt-get -qq install multitail -y
sudo apt-get -qq install libevent-dev -y
sudo apt-get -qq install libzmq-dev -y
sudo apt-get -qq install python-virtualenv -y
sudo apt-get -qq install python-mysqldb -y
sudo apt-get -qq install ansible -y
sudo apt-get -qq install docker-engine -y
sudo apt-get -qq install iftop -y
sudo apt-get -qq install libffi-dev -y
sudo apt-get -qq install albert -y
# sudo apt-get install plank -y
sudo apt-get install glances -y
sudo apt-get install zenity -y # Nylas N1 requires for desktop notifications
sudo apt-get install cmake -y
sudo apt-get install whois -y
sudo apt-get install sublime-text-installer -y
sudo apt-get install postgresql postgresql-contrib pgadmin3 -y
sudo apt-get install mysql-server -y
sudo apt-get install php-fpm php-mysql php-xdebug php-db -y
sudo apt-get install ubuntu-tweak dconf-editor -y
sudo apt-get install ansible -y
sudo apt-get install shutter -y
sudo apt-get install shellcheck -y
sudo apt-get install android-tools-adb -y
sudo apt-get install tmux

echo "Installed all applications"

# add current user in docker group
sudo gpasswd -a ${USER} docker
sudo service docker restart
echo "added current user in docker group"

# install docker compose
DOCKER_COMPOSE_LATEST_VERSION=$(curl -Ls  -o /dev/null -w %{url_effective} https://github.com/creationix/nvm/releases/latest | awk -F'/' '{print $8}')
curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_LATEST_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
echo "installed docker compose"


# Installation of latest nvm
NVM_LATEST_VERSION=$(curl -Ls  -o /dev/null -w %{url_effective} https://github.com/creationix/nvm/releases/latest | awk -F'/' '{print $8}')
curl -o- https://raw.githubusercontent.com/creationix/nvm/${NVM_LATEST_VERSION}/install.sh | bash
echo "Installation of latest nvm Complete"

# Python pip dependencies
sudo pip install ipython jupyter requests Flask gunicorn
echo "Python pip dependencies" 

# Oh-my-zsh
sudo sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo "Oh-my-zsh installed"

# Install Rust compiler
curl -sSf https://static.rust-lang.org/rustup.sh | sh

echo "Installing base packages..."
sudo apt-get install \
  termite-git \
  bash-completion -y

echo "Installing Python dependencies..."
sudo apt-get install \
  python-basiciw \
  python-netifaces \
  python-yaml \
  python-pillow \
  python-urllib3 \
  python2-suds -y

echo "Installing window manager dependencies..."
sudo apt-get install \
  xcb-util-keysyms \
  xcb-util-wm \
  xcb-util-cursor \
  yajl \
  startup-notification \
  libev -y

# I3
echo "Installing Window Manager - i3"

# EMACS
echo "Installing Emacs"
sudo apt-get install emacs24

echo "Installing tools..."
sudo apt-get install \
  i3 \
  i3lock \
  i3blocks-gaps-git \
  i3status-git \
  gsimplecal \
  thunderbird \
  lxappearance \
  thunderbird-enigmail-bin \
  feh \
  acpi \
  xdotool \
  pulseaudio-ctl \
  pavucontrol \
  network-manager-applet \
  networkmanager-openvpn \
  imagemagick \
  dunst \
  python \
  python-pip \
  python2-pip \
  compton-git \
  ttf-font-awesome \
  ohsnap \
  ttf-hack \
  powerline-fonts-git \
  thunar \
  thunar-archive-plugin \
  file-roller \
  tumbler \
  eog \
  numix-gtk-theme \
  numix-icon-theme-git \
  tk \
  aspell-en \
  evince \
  rofi \
  libmtp \
  gvfs-mtp \
  vim-airline \
  vim-fugitive \
  vim-gruvbox-git \
  vim-airline-gruvbox-git \
  vim-youcompleteme-git \
  vim-gitgutter-git \
  xtitle-git \
  openssh \
  arandr \
  xclip \
  xedgewarp-git \
  unclutter-xfixes-git \
  thefuck \
  youtube-dl \
  slop \
  maim \
  neofetch-git \
  w3m \
  htop \
  bluez \
  bluez-utils \
  pulseaudio-bluetooth \
  blueman \
  redshift \
  google-chrome \
  firefox \
  lm_sensors -y

echo "Installing some python stuff..."
sudo apt-get install \
  python-pillow \
  python-urllib3 -y

echo "Installing some i3 python stuff"
pip install i3-py

echo "Installing some perl stuff..."
sudo apt-get install \
  perl-anyevent-i3 \
  perl-json-xs -y


echo "Installing TERMTE"
/bin/bash ./install_termite.sh
