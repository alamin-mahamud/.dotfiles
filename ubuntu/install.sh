source ./ubuntu/symlinks.sh

function update_and_upgrade() {
    sudo apt-get update -y
    sudo apt-get upgrade -y
}

function setup_curl() {
    sudo apt install -y curl
}

function setup_git() {
    sudo apt install -y git
    setup_git_symlink
}

function setup_zsh() {
    echo "install zsh & clone ohmyzsh"
    sudo apt install -y zsh
    sudo chsh -s $(which zsh) $USER
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    setup_zsh_symlink
}

function setup_python() {
    echo "Install python and relevant tools"
    source ./python.sh
}

update_and_upgrade
setup_curl
setup_git
setup_zsh
setup_python
