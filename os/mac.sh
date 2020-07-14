#!/bin/zsh


echo "Running Mac-specific setup"


echo
echo "[Xcode Command Line Tools]"
echo "Installing Xcode Command Line Tools..."
xcode-select --install 2> /dev/null
read -p "Please press Enter once the Xcode Command Line Tools are installed. [enter]" IGNORE


echo
echo "[Homebrew]"
if [ -d /usr/local/Cellar ]; then
	echo "Homebrew appears to be already installed. Updating..."
	brew update
	brew upgrade
else
	echo "Installing Homebrew"
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || exit 1
	#brew tap Homebrew/bundle
	brew bundle --file os/mac-brewfile
fi


echo
echo "[Python]"
export PYENV_ROOT="$HOME/.pyenv"

source utils/sanity_checks.sh

if [ ! -d $PYENV_ROOT ]; then
	echo "Installing pyenv via Homebrew..."
	brew install pyenv
	check_installation_of "pyenv"
fi

# Check to see if pyenv is on the $PATH like it should be...
PYENV_FOUND=`echo $PATH | grep "${PYENV_ROOT}"`

if [[ "${PYENV_FOUND}" == "" ]]; then
    echo "Adding pyenv to your PATH..."
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init -)"
else
    echo
    echo
    print_error "Failed to initialize pyenv within your shell."
    echo
    echo
fi

echo "Installing Python 2.7 via pyenv..."
pyenv install --skip-existing 2.7.16
pyenv global 2.7.16

echo "Installing global python packages..."
export PYENV_VERSION=2.7.16
pip install -U -q ipython virtualenv pudb pipenv || exit 1

echo
echo "[Direnv]"
if ! command -v direnv 1>/dev/null 2>&1; then
  echo
  echo "[direnv]"
  echo "Installing direnv via Homebrew..."
  brew install direnv
  check_installation_of "direnv"
fi


echo
echo "[Man Pages]"
echo "Fixing man page paths..."
sudo ln -s -f /usr/local/share/man /usr/local/man || exit 1


echo
echo "[Setting Mac Defaults]"
source os/mac-defaults.sh


echo
echo "[Zsh]"
source zsh/install.sh


echo
echo "[Tmux]"
source tmux/install.sh


source utils/ssh.sh
source utils/aws.sh


source custom/britecore.sh
