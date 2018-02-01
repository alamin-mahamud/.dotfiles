# Currently this path is appended to dynamically when picking a ruby version
# zshenv has already started PATH with rbenv so append only here
PATH=$PATH:~/Downloads/Linux/node/bin
PATH=$PATH:~/Downloads/Linux/elasticsearch/bin
PATH=$PATH:~/.local/bin
PATH=$PATH:~/work/python/python-scripts
PATH=$PATH:~/mongodb/mongodb-linux-x86_64-3.6.2/bin
export PATH=$PATH:~/bin:/usr/local/bin:/usr/local/sbin:~/bin

# Set default console Java to 1.6
export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home

# Setup terminal, and turn on colors
export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad

# Enable color in grep
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='3;33'

# This resolves issues install the mysql, postgres, and other gems with native non universal binary extensions
export ARCHFLAGS='-arch x86_64'

export LESS='--ignore-case --raw-control-chars'
export PAGER='less'
export EDITOR='emacsclient'

#export NODE_PATH=/opt/github/homebrew/lib/node_modules
#export PYTHONPATH=/usr/local/lib/python2.6/site-packages
# CTAGS Sorting in VIM/Emacs is better behaved with this in place
export LC_COLLATE=C

# Virtual Environment Stuff
export VIRTUALENVWRAPPER_PYTHON='/usr/bin/python3'
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/work/python/django
source ~/.local/bin/virtualenvwrapper.sh

# pip
export PIP_REQUIRE_VIRTUALENV=true
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
gpip() {
    PIP_REQUIRE_VIRTUALENV="" pip "$@"
}
