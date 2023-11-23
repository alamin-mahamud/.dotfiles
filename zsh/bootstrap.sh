DOTFILES_DIR=$HOME/Work/.dotfiles
ZSH_DIR=$DOTFILES_DIR/zsh


function oh_my_zsh() {
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME="random"
    plugins=(git colored-man-pages colorize pip python brew macos zsh-syntax-highlighting zsh-autosuggestions)
    source $ZSH/oh-my-zsh.sh
}


function set_path() {
  export PATH=/usr/local/bin:$PATH
}


function allow_utf8_local() {
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
}


function remember_my_paths() {
  source $ZSH_DIR/z.sh
}


function load_git_aliases() {
  alias ga='git add'

  alias gl='git log'
  alias gpl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

  alias gp='git push'
  alias gpm='git push origin master'

  alias gs='git status'
  alias gd='git diff'
  alias gcm='git commit -m'

  alias gb='git branch'
  alias gc='git checkout'
  alias gcb='git checkout -b'

  alias gra='git remote add'
  alias grr='git remote rm'

  alias gpu='git pull'
  alias gcl='git clone'

  alias gta='git tag -a -m'
  alias gf='git reflog'
  alias gv='git log --pretty=format:'%s' | cut -d " " -f 1 | sort | uniq -c | sort -nr'

  # leverage aliases from ~/.gitconfig
  alias gh='git hist'
  alias gt='git today'

  # curiosities
  # gsh shows the number of commits for the current repos for all developers
  alias gsh="git shortlog | grep -E '^[ ]+\w+' | wc -l"

  # gu shows a list of all developers and the number of commits they've made
  alias gu="git shortlog | grep -E '^[^ ]'"
}


function load_c14n_aliases() {
    alias dc='docker-compose'
    alias k='kubectl'
}

function load_aliases() {
  load_git_aliases
  load_c14n_aliases
}


function load_britedevenv() {
    # Since 'docker-compose' will now be working across multiple repositories,
    # we'll export a ENV variable that it can read to figure out where all our
    # repos are checked out at.
    export REPO_DIR="$HOME/Work/britecore"
    export BRITEDEVENV_PATH=$REPO_DIR/BriteDevEnv


    case "$(uname -s)" in
        Darwin*)
            # On macOS, the default number of file descriptors is far too
            # low ('256'). That would cause Docker to run out of available
            # file handles, so let's bump it up.
            ulimit -n 2048
            ;;
        Linux)
            # Ubuntu & other Linux variants tend to have a plenty high
            # `ulimit` (number of file descriptors available, in this case
            # to a shell process), so nothing to do here.
            ;;
    esac

    # A shortcut for working with client Docker Compose setups.
    function bc() {
        cd ${BRITEDEVENV_PATH}
        pipenv shell "docker-compose -f clients-${1}.yml -p ${1} ${2}"
    }

    # As it's not built into bash, a function for checking if a function
    # exists. :yodawg:
    function function_exists() {
        # Returns `0` on the function being present, non-zero on it not
        # being present.
        # Sample usage: `function_exists "bc"; echo $?`
        declare -f "${1}" > /dev/null; return $?
    }

}


function bc-id {
    if ! [ $1 ]; then
        echo "Please Pass Instance ID"
    else
        export GH_USERNAME='alamin-mahamud'
        SERVER_NAME=$(tsh ls | grep "$1" | cut -d' ' -f1)
        echo "Accessing client with instance id : i-$1"
        echo ""
        tsh ssh "$GH_USERNAME@$SERVER_NAME"
    fi
}


function bc-ip {
    if ! [ $1 ]; then
        echo "Please Pass Instance's Private IP"
    else
        export GH_USERNAME='alamin-mahamud'
        echo "Accessing client with private IP : $1"
        echo ""
        tsh ssh "$GH_USERNAME@$1"
    fi
}


function bc-ssh {
    if ! [ $1 ]; then
        echo "Please pass BC site name"
    else
        export GH_USERNAME='alamin-mahamud'
        SERVER_NAME=($(tsh ls | grep "^$1-" | cut -d' ' -f1))
        echo "Accessing client $1"
        echo ""
        tsh ssh "$GH_USERNAME@$SERVER_NAME"
    fi
}


function bc-consul {
    if ! [ $1 ]; then
        echo "Please Pass BC site name"
    else
        export GH_USERNAME='alamin-mahamud'
        SERVER_NAME=($(tsh ls | grep "^$1-" | cut -d' ' -f1))
        echo "Tunneling $1s in Consul at port 8500"
        echo ""
        tsh ssh -L 8500:consul.britecorepro.com:8500 $GH_USERNAME@$SERVER_NAME
    fi
}


function load_direnv() {
    eval "$(direnv hook zsh)"
}


function load_pyenv() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
    fi
}


function load_pyenv_virtualenv() {
    if command -v pyenv-virtualenv 1>/dev/null 2>&1; then
        eval "$(pyenv virtualenv-init -)"
    fi
}


function load_gcloud() {
    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/Users/alamin/Work/.source/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/alamin/Work/.source/google-cloud-sdk/path.zsh.inc'; fi

    # The next line enables shell command completion for gcloud.
    if [ -f '/Users/alamin/Work/.source/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/alamin/Work/.source/google-cloud-sdk/completion.zsh.inc'; fi
}


function main() {
    oh_my_zsh
    set_path
    allow_utf8_local
    remember_my_paths

    load_aliases
    load_direnv
    load_pyenv
    load_pyenv_virtualenv

    #load_gcloud

    # TODO: BriteCore
    #load_britedevenv
}
