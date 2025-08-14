#!/bin/bash

# Enhanced Shell Environment Standalone Installer
# DRY orchestrator that installs and configures Zsh, Oh My Zsh, and shell tools
# This script provides a modern shell environment with productivity enhancements
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/install-shell.sh | bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/shell-install-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_status "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected macOS"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        print_success "Detected $PRETTY_NAME"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
}

# Backup existing configuration files
backup_existing_configs() {
    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zsh_functions"
        "$HOME/.z.sh"
        "$HOME/.p10k.zsh"
    )
    
    local backup_needed=false
    for file in "${files_to_backup[@]}"; do
        if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
            backup_needed=true
            break
        fi
    done
    
    if [[ "$backup_needed" == true ]]; then
        print_status "Backing up existing configuration files..."
        mkdir -p "$BACKUP_DIR"
        
        for file in "${files_to_backup[@]}"; do
            if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
                cp "$file" "$BACKUP_DIR/" 2>/dev/null || true
                print_status "Backed up $(basename "$file")"
            fi
        done
        print_success "Backups saved to $BACKUP_DIR"
    fi
}

# Install Zsh (idempotent)
install_zsh() {
    print_status "Checking Zsh installation..."
    
    if command -v zsh &> /dev/null; then
        print_success "Zsh is already installed ($(zsh --version))"
        return 0
    fi
    
    print_status "Installing Zsh..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y zsh
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y zsh || sudo yum install -y zsh
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm zsh
            ;;
        alpine)
            sudo apk add --no-cache zsh
            ;;
        opensuse*|sles)
            sudo zypper install -y zsh
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                print_warning "Homebrew not found. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install zsh
            ;;
        *)
            print_error "Unsupported OS for Zsh installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Zsh installed successfully"
}

# Install Oh My Zsh (idempotent)
install_oh_my_zsh() {
    print_status "Checking Oh My Zsh installation..."
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh is already installed"
        # Update to latest version
        print_status "Updating Oh My Zsh..."
        cd "$HOME/.oh-my-zsh" && git pull --quiet && cd - > /dev/null
        return 0
    fi
    
    print_status "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    print_success "Oh My Zsh installed"
}

# Install Zsh plugins (idempotent)
install_zsh_plugins() {
    print_status "Installing Zsh plugins..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        print_status "Installing zsh-autosuggestions..."
        git clone --quiet https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
        print_status "Updating zsh-autosuggestions..."
        cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull --quiet && cd - > /dev/null
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        print_status "Installing zsh-syntax-highlighting..."
        git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    else
        print_status "Updating zsh-syntax-highlighting..."
        cd "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && git pull --quiet && cd - > /dev/null
    fi
    
    # zsh-completions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
        print_status "Installing zsh-completions..."
        git clone --quiet https://github.com/zsh-users/zsh-completions \
            "$ZSH_CUSTOM/plugins/zsh-completions"
    else
        print_status "Updating zsh-completions..."
        cd "$ZSH_CUSTOM/plugins/zsh-completions" && git pull --quiet && cd - > /dev/null
    fi
    
    # fzf-tab
    if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
        print_status "Installing fzf-tab..."
        git clone --quiet https://github.com/Aloxaf/fzf-tab \
            "$ZSH_CUSTOM/plugins/fzf-tab"
    else
        print_status "Updating fzf-tab..."
        cd "$ZSH_CUSTOM/plugins/fzf-tab" && git pull --quiet && cd - > /dev/null
    fi
    
    print_success "Zsh plugins installed"
}

# Install Powerlevel10k theme (idempotent)
install_powerlevel10k() {
    print_status "Installing Powerlevel10k theme..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$ZSH_CUSTOM/themes/powerlevel10k"
    else
        print_status "Updating Powerlevel10k..."
        cd "$ZSH_CUSTOM/themes/powerlevel10k" && git pull --quiet && cd - > /dev/null
    fi
    
    print_success "Powerlevel10k installed"
}

# Configure Powerlevel10k with sane defaults (idempotent)
configure_powerlevel10k() {
    print_status "Configuring Powerlevel10k with default settings..."
    
    # Create p10k configuration with sane defaults
    cat > "$HOME/.p10k.zsh" << 'P10K_EOF'
# Generated by Powerlevel10k configuration wizard.
# Based on romkatv/powerlevel10k/config/p10k-lean.zsh.
# Wizard options: nerdfont-complete + powerline, small icons, lean, 2 lines, solid,
# no frame, lightest-ornaments, sparse, few icons, concise, yes.

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options. This allows you to apply configuration changes
  # without restarting zsh. Edit ~/.p10k.zsh and type `source ~/.p10k.zsh`.
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh >= 5.1 is required.
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # The list of segments shown on the left. Fill it with the most important segments.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # =========================[ Line #1 ]=========================
    dir                     # current directory
    vcs                     # git status
    # =========================[ Line #2 ]=========================
    newline                 # \n
    prompt_char             # prompt symbol
  )

  # The list of segments shown on the right. Fill it with less important segments.
  # Right prompt on the last prompt line (where you are typing your commands) gets
  # automatically hidden when the input line reaches it. Right prompt above the
  # last prompt line gets hidden if it would overlap with left prompt.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # =========================[ Line #1 ]=========================
    status                  # exit code of the last command
    command_execution_time  # duration of the last command
    background_jobs         # presence of background jobs
    direnv                  # direnv status (https://direnv.net/)
    asdf                    # asdf version manager (https://github.com/asdf-vm/asdf)
    virtualenv              # python virtual environment (https://docs.python.org/3/library/venv.html)
    anaconda                # conda environment (https://conda.io/)
    pyenv                   # python environment (https://github.com/pyenv/pyenv)
    goenv                   # go environment (https://github.com/syndbg/goenv)
    nodenv                  # node.js version from nodenv (https://github.com/nodenv/nodenv)
    nvm                     # node.js version from nvm (https://github.com/nvm-sh/nvm)
    nodeenv                 # node.js environment (https://github.com/ekalinin/nodeenv)
    # node_version          # node.js version
    # go_version            # go version (https://golang.org)
    # rust_version          # rustc version (https://www.rust-lang.org)
    # dotnet_version        # .NET version (https://dotnet.microsoft.com)
    # php_version           # php version (https://www.php.net/)
    # laravel_version       # laravel php framework version (https://laravel.com/)
    # java_version          # java version (https://www.java.com/)
    # package               # name@version from package.json (https://docs.npmjs.com/files/package.json)
    rbenv                   # ruby version from rbenv (https://github.com/rbenv/rbenv)
    rvm                     # ruby version from rvm (https://rvm.io)
    fvm                     # flutter version management (https://github.com/leoafarias/fvm)
    luaenv                  # lua version from luaenv (https://github.com/cehoffman/luaenv)
    jenv                    # java version from jenv (https://github.com/jenv/jenv)
    plenv                   # perl version from plenv (https://github.com/tokuhirom/plenv)
    phpenv                  # php version from phpenv (https://github.com/phpenv/phpenv)
    scalaenv                # scala version from scalaenv (https://github.com/scalaenv/scalaenv)
    haskell_stack           # haskell version from stack (https://haskellstack.org/)
    kubecontext             # current kubernetes context (https://kubernetes.io/)
    terraform               # terraform workspace (https://www.terraform.io)
    aws                     # aws profile (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
    aws_eb_env              # aws elastic beanstalk environment (https://aws.amazon.com/elasticbeanstalk/)
    azure                   # azure account name (https://docs.microsoft.com/en-us/cli/azure)
    gcloud                  # google cloud cli account and project (https://cloud.google.com/)
    google_app_cred         # google application credentials (https://cloud.google.com/docs/authentication/production)
    context                 # user@hostname
    nordvpn                 # nordvpn connection status, linux only (https://nordvpn.com/)
    ranger                  # ranger shell (https://github.com/ranger/ranger)
    nnn                     # nnn shell (https://github.com/jarun/nnn)
    vim_shell               # vim shell indicator (:sh)
    midnight_commander      # midnight commander shell (https://midnight-commander.org/)
    nix_shell               # nix shell (https://nixos.org/nixos/nix-pills/developing-with-nix-shell.html)
    # vi_mode               # vi mode (you don't need this if you've enabled prompt_char)
    # =========================[ Line #2 ]=========================
    newline
    # ip                    # ip address and bandwidth usage for a specified network interface
    # public_ip             # public IP address
    # proxy                 # system-wide http/https/ftp proxy
    # battery               # internal battery
    # wifi                  # wifi speed
    # example               # example user-defined segment (see prompt_example function below)
  )

  # Defines character set used by powerlevel10k. It's best to let `p10k configure` set it for you.
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  # When set to `moderate`, some icons will have an extra space after them. This is meant to avoid
  # icon overlap when using non-monospace fonts. When set to `none`, spaces are not added.
  typeset -g POWERLEVEL9K_ICON_PADDING=none

  # Basic style options that define the overall look of your prompt. You probably don't want to
  # change them.
  typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no surrounding whitespace
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # separate segments with a space
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no end-of-line symbol

  # When set to true, icons appear before content on both sides of the prompt. When set
  # to false, icons go after content. If empty or not set, icons go before content in the left
  # prompt and after content in the right prompt.
  #
  # You can also override it for a specific segment:
  #
  #   POWERLEVEL9K_STATUS_ICON_BEFORE_CONTENT=false
  #
  # Or for a specific segment in specific state:
  #
  #   POWERLEVEL9K_DIR_NOT_WRITABLE_ICON_BEFORE_CONTENT=false
  typeset -g POWERLEVEL9K_ICON_BEFORE_CONTENT=true

  # Add an empty line before each prompt.
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

  # Connect left and right prompts.
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

  # The color of the filler. You'll probably want to match the color of POWERLEVEL9K_MULTILINE
  # ornaments defined above.
  typeset -g POWERLEVEL9K_FILLER_BACKGROUND_COLOR=
  typeset -g POWERLEVEL9K_FILLER_FOREGROUND_COLOR=

  # Separator between same-color segments on the left.
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='%246F\uE0B1'
  # Separator between same-color segments on the right.
  typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR='%246F\uE0B3'
  # Separator between different-color segments on the left.
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0B0'
  # Separator between different-color segments on the right.
  typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0B2'

  #################################[ os_icon: os identifier ]##################################
  # OS identifier color.
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=232
  typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=7
  # Custom icon.
  # typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='⭐'

  ################################[ prompt_char: prompt symbol ]################################
  # Green prompt symbol if the last command succeeded.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
  # Red prompt symbol if the last command failed.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  # Default prompt symbol.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  # Prompt symbol in command vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  # Prompt symbol in visual vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  # Prompt symbol in overwrite vi mode.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  # No line terminator if prompt_char is the last segment.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
  # No line introducer if prompt_char is the first segment.
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=

  ##################################[ dir: current directory ]##################################
  # Default current directory color.
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
  # If directory is too long, shorten some of its segments to the shortest possible unique
  # prefix. The shortened directory can be tab-completed to the original.
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  # Replace removed segment suffixes with this symbol.
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  # Color of the shortened directory segments.
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103
  # Color of the anchor directory segments. Anchor segments are never shortened. The first
  # segment is always an anchor.
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=39
  # Display anchor directory segments in bold.
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  # Don't shorten directories that contain any of these files. They are anchors.
  local anchor_files=(
    .bzr
    .citc
    .git
    .hg
    .node-version
    .python-version
    .go-version
    .ruby-version
    .lua-version
    .java-version
    .perl-version
    .php-version
    .tool-version
    .shorten_folder_marker
    .svn
    .terraform
    CVS
    Cargo.toml
    composer.json
    go.mod
    package.json
    stack.yaml
  )
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"
  # If set to "first" ("last"), remove everything before the first (last) subdirectory that contains
  # any of the anchor files. If set to "first:N" or "last:N", remove everything before the first N
  # or after the last N occurrences of anchor files. Anchor files are detected by examining
  # POWERLEVEL9K_SHORTEN_FOLDER_MARKER. This option has no effect when POWERLEVEL9K_SHORTEN_STRATEGY
  # is not set to "truncate_with_folder_marker".
  # typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  # Don't shorten this many last directory segments. They are anchors.
  # typeset -g POWERLEVEL9K_SHORTEN_DIR_TRAILING_LENGTH=1

  # Custom icon.
  # typeset -g POWERLEVEL9K_DIR_CONTENT_EXPANSION='⭐'

  #####################################[ vcs: git status ]#####################################
  # Branch icon. Set this parameter to '\uF126 ' for the popular Powerline branch icon.
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '

  # Untracked files icon. It's really a question mark, your font isn't broken.
  # Change the value of this parameter to show a different icon.
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

  # Formatter for Git status.
  #
  # Example output: master wip ⇣42⇡42 *42 merge ~42 +42 !42 ?42.
  #
  # VCS_STATUS_* parameters are set by gitstatus plugin. See reference:
  # https://github.com/romkatv/gitstatus/blob/master/gitstatus.plugin.zsh.
  function my_git_formatter() {
    emulate -L zsh

    if [[ -n $P9K_CONTENT ]]; then
      # If P9K_CONTENT is not empty, use it. It's either "loading" or from vcs_info (not from
      # gitstatus plugin). VCS_STATUS_* parameters are not available in this case.
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    if (( $1 )); then
      # Styling for up-to-date Git status.
      local       meta='%f'     # default foreground
      local      clean='%76F'   # green foreground
      local   modified='%178F'  # yellow foreground
      local  untracked='%39F'   # blue foreground
      local conflicted='%196F'  # red foreground
    else
      # Styling for incomplete and stale Git status.
      local       meta='%244F'  # grey foreground
      local      clean='%244F'  # grey foreground
      local   modified='%244F'  # grey foreground
      local  untracked='%244F'  # grey foreground
      local conflicted='%244F'  # grey foreground
    fi

    local res
    local where  # branch or tag
    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}"
      where=${(V)VCS_STATUS_LOCAL_BRANCH}
    elif [[ -n $VCS_STATUS_TAG ]]; then
      res+="${meta}#"
      where=${(V)VCS_STATUS_TAG}
    fi

    # If local branch name or tag is at most 32 characters long, show it in full.
    # Otherwise show the first 12 … the last 12.
    (( $#where > 32 )) && where[13,-13]="…"
    res+="${clean}${where//\%/%%}"  # escape %

    # Display the current Git commit if there is no branch or tag.
    # Tip: To always display the current Git commit, remove the next line.
    [[ -z $where ]] && res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    # Show tracking branch name if it differs from local branch.
    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"  # escape %
    fi

    # Display "wip" if the latest commit's summary contains "wip" or "WIP".
    if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])wip([^[:alnum:]]*|) ]]; then
      res+=" ${modified}wip"
    fi

    # ⇣42 if behind the remote.
    (( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
    # ⇡42 if ahead of the remote.
    (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
    # ⇕42 if diverged with the remote.
    (( VCS_STATUS_COMMITS_AHEAD && VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇕${VCS_STATUS_COMMITS_AHEAD}"

    # *42 if have stashes.
    (( VCS_STATUS_STASHES        )) && res+=" ${clean}*${VCS_STATUS_STASHES}"
    # merge if the repository is in a merge state.
    [[ -n $VCS_STATUS_ACTION     ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
    # ~42 if have merge conflicts.
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
    # +42 if have staged changes.
    (( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
    # !42 if have unstaged changes.
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
    # ?42 if have untracked files. It's really a question mark, your font isn't broken.
    # See POWERLEVEL9K_VCS_UNTRACKED_ICON above if you want to use a different icon.
    # Remove the next line if you don't want to see untracked files at all.
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    # "─" if the number of unstaged files is unknown. This can happen due to
    # POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY (see below) being set to a non-negative number lower
    # than the number of files in the Git index, or due to bash.showDirtyState being set to false
    # in the repository config. The number of staged and untracked files may also be unknown
    # in this case.
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null

  # Don't count the number of unstaged, untracked and conflicted files in Git repositories with
  # more than this many files in the index. Negative value means infinity.
  #
  # If you are working in Git repositories with tens of millions of files and seeing performance
  # sagging, try setting POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY to a number lower than the output
  # of `git ls-files | wc -l`. Don't set it too low or you'll lose most of the functionality of
  # Git prompt. Alternatively, add `bash.showDirtyState = false` to the repository's config:
  # `git config bash.showDirtyState false`.
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1

  # Don't show Git status in prompt for repositories whose workdir matches this pattern.
  # For example, if set to '~', the Git repository at $HOME/.git will be ignored.
  # Multiple patterns can be combined with '|': '~(|/foo)|/bar/baz/*'.
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # Disable the default Git status formatting.
  typeset -g POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=true
  # Install our own Git status formatter.
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter(1)))+${my_git_format}}'
  typeset -g POWERLEVEL9K_VCS_LOADING_CONTENT_EXPANSION='${$((my_git_formatter(0)))+${my_git_format}}'
  # Enable counters for staged, unstaged, etc.
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

  # Custom icon.
  # typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # Custom prefix.
  # typeset -g POWERLEVEL9K_VCS_PREFIX='%fon '

  # Show status of repositories of these types. You can add svn and/or hg if you are
  # using them. If you do, your prompt may become slow even when your current directory
  # isn't in an svn or hg reposiory, because prompt will be making network calls to a remote
  # server. See https://github.com/romkatv/gitstatus#why-gitstatus-and-not-vcs_info.
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

  ##########################[ status: exit code of the last command ]#########################
  # Enable OK_PIPE, ERROR_PIPE and ERROR_SIGNAL status states to allow us to enable, disable and
  # style them independently from the regular OK and ERROR state.
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true

  # Status on success. No content, just an icon. No need to show it if prompt_char is enabled as
  # it will signify success by turning green.
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✓'

  # Status when some part of a pipe command fails but the overall exit status is zero. It may look
  # like this: 1|0.
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION='✓'

  # Status when it's just an error code (e.g., '1'). No need to show it if prompt_char is enabled as
  # it will signify error by turning red.
  typeset -g POWERLEVEL9K_STATUS_ERROR=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✗'

  # Status when the command was terminated by a signal.
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=160
  # Use terse signal names: "INT" instead of "SIGINT(2)".
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='✗'

  # Status when some part of a pipe command fails and the overall exit status is also non-zero.
  # It may look like this: 1|2.
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='✗'

  ###################[ command_execution_time: duration of the last command ]###################
  # Execution time color.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101
  # Show duration of the last command if takes at least this many seconds.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  # Show this many fractional digits. Zero means round to seconds.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  # Duration format: 1d 2h 3m 4s.
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  # Custom icon.
  # typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION='⭐'
  # Custom prefix.
  # typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%ftook '

  #######################[ background_jobs: presence of background jobs ]#######################
  # Background jobs color.
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=37
  # Don't show the number of background jobs.
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false
  # Custom icon.
  # typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='⭐'

  # Transient prompt works similarly to the builtin transient_rprompt option. It trims down prompt
  # when accepting a command line. Supported values:
  #
  #   - off:      Don't change prompt when accepting a command line.
  #   - always:   Trim down prompt when accepting a command line.
  #   - same-dir: Trim down prompt when accepting a command line unless this is the first command
  #               typed after changing current working directory.
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off

  # Instant prompt mode.
  #   - off:     Disable instant prompt. Choose this if you've tried instant prompt and found
  #              it incompatible with your zsh configuration files.
  #   - quiet:   Enable instant prompt and don't print warnings when detecting console output
  #              during zsh initialization. Choose this if you've read and understood
  #              https://github.com/romkatv/powerlevel10k/blob/master/README.md#instant-prompt.
  #   - verbose: Enable instant prompt and print a warning when detecting console output during
  #              zsh initialization. Choose this if you've never tried instant prompt, haven't
  #              seen the warning, or if you are unsure what this all means.
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

  # Hot reload allows you to change POWERLEVEL9K options after Powerlevel10k has been initialized.
  # For example, you can type POWERLEVEL9K_BACKGROUND=red and see your prompt background turn red.
  # Hot reload can slow down prompt by 1-2 milliseconds, so it's better to keep it turned off
  # unless you really need it.
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  # If p10k is already loaded, reload configuration.
  # This works even with POWERLEVEL9K_DISABLE_HOT_RELOAD=true.
  (( ! $+functions[p10k] )) || p10k reload
}

# Tell `p10k configure` which file it should overwrite.
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
P10K_EOF
    
    print_success "Powerlevel10k configured with default settings"
}

# Configure Zsh (idempotent)
configure_zsh() {
    print_status "Configuring Zsh..."
    
    # Create embedded .zshrc configuration
    cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Enhanced Zsh Configuration - Generated by install-shell.sh

# System detection
if [[ $(uname) = 'Linux' ]]; then
    IS_LINUX=1
fi

if [[ $(uname) = 'Darwin' ]]; then
    IS_MAC=1
fi

# Environment variables
export LANG=en_US.UTF-8
export TERM=xterm-256color
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH:/usr/local/go/bin"

# History configuration
HISTSIZE=10000
SAVEHIST=9000
HISTFILE=~/.zsh_history

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (fzf-tab must be last)
plugins=(
    git
    docker
    kubectl
    terraform
    aws
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf-tab
)

source $ZSH/oh-my-zsh.sh

# Python environment
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

export PIPENV_PYTHON="$HOME/.pyenv/shims/python"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# FZF integration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Z directory jumping
[ -f ~/.z.sh ] && source ~/.z.sh

# Load custom functions
[ -f ~/.zsh_functions ] && source ~/.zsh_functions

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim 2>/dev/null || vim'
alias tm='tmux'
alias tma='tmux attach-session -t'
alias tmn='tmux new-session -s'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'

# FZF-tab configuration
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -la $realpath'
zstyle ':fzf-tab:*' switch-group F1 F2

# Enable kubectl completion if available
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion zsh)
fi

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC_EOF
    
    # Create custom functions file
    cat > "$HOME/.zsh_functions" << 'FUNCTIONS_EOF'
# Custom Zsh Functions

# Display formatted PATH
path() {
    echo $PATH | tr ":" "\n" | nl
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)          echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
FUNCTIONS_EOF
    
    print_success "Zsh configuration created"
}

# Install FZF (idempotent)
install_fzf() {
    print_status "Installing FZF..."
    
    if command -v fzf &> /dev/null; then
        print_success "FZF is already installed ($(fzf --version))"
        return 0
    fi
    
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    
    "$HOME/.fzf/install" --all --no-bash --no-fish --no-update-rc
    print_success "FZF installed"
}

# Install Z directory jumper (idempotent)
install_z() {
    print_status "Installing Z directory jumper..."
    
    if [[ -f "$HOME/.z.sh" ]]; then
        print_success "Z is already installed"
        return 0
    fi
    
    curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o "$HOME/.z.sh"
    chmod +x "$HOME/.z.sh"
    print_success "Z installed"
}

# Install Neovim (idempotent)
install_neovim() {
    print_status "Installing Neovim..."
    
    if command -v nvim &> /dev/null; then
        local nvim_version=$(nvim --version | head -n1)
        print_success "Neovim is already installed ($nvim_version)"
        
        # Check if version is >= 0.9.0 for LazyVim
        local version_num=$(nvim --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        if [[ $(echo "$version_num" | cut -d. -f2) -lt 9 ]]; then
            print_warning "LazyVim requires Neovim 0.9.0+. Current version: $version_num"
            print_status "Attempting to update Neovim..."
        else
            return 0
        fi
    fi
    
    case "$OS" in
        ubuntu|debian)
            # Use AppImage for latest version
            print_status "Installing Neovim via AppImage for latest version..."
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage
            sudo mkdir -p /opt/nvim
            sudo mv nvim.appimage /opt/nvim/
            sudo ln -sf /opt/nvim/nvim.appimage /usr/local/bin/nvim
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y neovim || {
                # Fallback to AppImage
                print_status "Installing Neovim via AppImage..."
                curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
                chmod u+x nvim.appimage
                sudo mkdir -p /opt/nvim
                sudo mv nvim.appimage /opt/nvim/
                sudo ln -sf /opt/nvim/nvim.appimage /usr/local/bin/nvim
            }
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm neovim
            ;;
        alpine)
            sudo apk add --no-cache neovim
            ;;
        opensuse*|sles)
            sudo zypper install -y neovim
            ;;
        macos)
            brew install neovim
            ;;
        *)
            print_error "Unsupported OS for Neovim installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Neovim installed successfully"
}

# Install LazyVim (idempotent)
install_lazyvim() {
    print_status "Setting up LazyVim..."
    
    # Check Neovim version
    if ! command -v nvim &> /dev/null; then
        print_error "Neovim is not installed. Please install Neovim first."
        return 1
    fi
    
    # Backup existing Neovim config
    if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
        print_status "Backing up existing Neovim configuration..."
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Remove existing symlink or directory
    rm -rf "$HOME/.config/nvim"
    
    # Clone LazyVim starter
    print_status "Installing LazyVim starter template..."
    git clone --quiet https://github.com/LazyVim/starter "$HOME/.config/nvim"
    
    # Remove .git folder to make it your own
    rm -rf "$HOME/.config/nvim/.git"
    
    # Install dependencies for LazyVim
    print_status "Installing LazyVim dependencies..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get install -y \
                build-essential \
                unzip \
                python3-pip \
                nodejs npm \
                2>/dev/null || true
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y \
                gcc gcc-c++ make \
                unzip \
                python3-pip \
                nodejs npm \
                2>/dev/null || sudo yum install -y \
                gcc gcc-c++ make \
                unzip \
                python3-pip \
                nodejs npm \
                2>/dev/null || true
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm \
                base-devel \
                unzip \
                python-pip \
                nodejs npm \
                2>/dev/null || true
            ;;
        macos)
            brew install \
                python3 \
                node \
                2>/dev/null || true
            ;;
    esac
    
    print_success "LazyVim installed. Run 'nvim' to complete setup."
}

# Install Kitty terminal (idempotent)
install_kitty() {
    print_status "Installing Kitty terminal..."
    
    if command -v kitty &> /dev/null; then
        print_success "Kitty is already installed ($(kitty --version))"
        return 0
    fi
    
    case "$OS" in
        ubuntu|debian)
            # Install via official binary
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
            
            # Create desktop integration
            sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
            sudo ln -sf ~/.local/kitty.app/bin/kitten /usr/local/bin/
            
            # Create desktop entry
            cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
            cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
            
            # Update icon cache
            sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
                ~/.local/share/applications/kitty*.desktop
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y kitty || {
                # Fallback to official installer
                curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
                sudo ln -sf ~/.local/kitty.app/bin/kitty /usr/local/bin/
                sudo ln -sf ~/.local/kitty.app/bin/kitten /usr/local/bin/
            }
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm kitty
            ;;
        macos)
            brew install --cask kitty
            ;;
        *)
            print_error "Unsupported OS for Kitty installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Kitty terminal installed"
}

# Configure Kitty (idempotent)
configure_kitty() {
    print_status "Configuring Kitty terminal..."
    
    # Create kitty config directory
    mkdir -p "$HOME/.config/kitty"
    
    # Backup existing config
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]] && [[ ! -L "$HOME/.config/kitty/kitty.conf" ]]; then
        cp "$HOME/.config/kitty/kitty.conf" "$BACKUP_DIR/kitty.conf" 2>/dev/null || true
        print_status "Backed up existing kitty.conf"
    fi
    
    # Create kitty configuration
    cat > "$HOME/.config/kitty/kitty.conf" << 'KITTY_EOF'
# ───────────────────────────────────────────────────────────────
# Theme support via built-in kitten
# First time: run `kitty +kitten themes` and choose a theme.
# Kitten will manage theme inclusion to current-theme.conf
# include current-theme.conf

# OS-specific overrides (optional per sytranvn.dev approach)
# include ${KITTY_OS}.conf

# ─── Appearance ────────────────────────────────────────────────
# font_family      FiraCode Nerd Font
# bold_font        auto
# italic_font      auto
# bold_italic_font auto
font_size        18.0
background #1d1f21
foreground #c5c8c6

background_opacity 0.95

# macOS does not support blur natively
background_blur    0     

enable_audio_bell no

cursor_shape block
cursor_blink_interval 0
cursor_stop_blinking_after 0

# ─── Window & Layout ───────────────────────────────────────────
window_padding_width 10
window_margin_width 2
hide_window_decorations no

remember_window_size no
initial_window_width  1800
initial_window_height 1100

tab_bar_edge bottom
tab_bar_align left
tab_bar_style powerline
tab_powerline_style slanted
active_tab_font_style bold
inactive_tab_font_style normal

# ─── Scrolling & History ───────────────────────────────────────
scrollback_lines     10000
wheel_scroll_multiplier 3.0
scrollback_pager bash -c 'less -R'

# ─── Mouse & URL handling ─────────────────────────────────────
mouse_hide_wait -1
map ctrl+left click open_url
mouse_map ctrl+left press ungrabbed,grabbed mouse_click_url  # Mac reverse link-click

# ─── Keyboard Shortcuts (macOS + Linux) ───────────────────────
map ctrl+shift+enter launch --cwd=current          # open new window
map cmd+enter       launch --cwd=current           # macOS-specific
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+q     close_window
map ctrl+shift+]     next_window
map ctrl+shift+[     previous_window
map ctrl+shift+l     next_layout

# ─── Clipboard & Copy/Paste ──────────────────────────────────
map ctrl+shift+c   copy_to_clipboard
map ctrl+shift+v   paste_from_clipboard

# ─── Remote control (optional) ───────────────────────────────
# enables `kitty @` commands
allow_remote_control yes                             

# ───────────────────────────────────────────────────────────────

# BEGIN_KITTY_THEME
# Tokyo Night Moon
include current-theme.conf
# END_KITTY_THEME

# BEGIN_KITTY_FONTS
font_family      family='MesloLGL Nerd Font Mono' postscript_name=MesloLGLNFM-Regular
bold_font        auto
italic_font      auto
bold_italic_font auto
# END_KITTY_FONTS
KITTY_EOF
    
    # Create a default theme file (Tokyo Night Moon)
    cat > "$HOME/.config/kitty/current-theme.conf" << 'THEME_EOF'
# Tokyo Night Moon theme for Kitty
# Based on Tokyo Night color scheme

background #222436
foreground #c8d3f5
selection_background #2d3f76
selection_foreground #c8d3f5
url_color #4fd6be
cursor #c8d3f5
cursor_text_color #222436

# Tabs
active_tab_background #82aaff
active_tab_foreground #1e2030
inactive_tab_background #2f334d
inactive_tab_foreground #545c7e
tab_bar_background #1e2030

# Normal colors
color0 #1b1d2b
color1 #ff757f
color2 #c3e88d
color3 #ffc777
color4 #82aaff
color5 #c099ff
color6 #86e1fc
color7 #828bb8

# Bright colors
color8 #444a73
color9 #ff757f
color10 #c3e88d
color11 #ffc777
color12 #82aaff
color13 #c099ff
color14 #86e1fc
color15 #c8d3f5

# Extended colors
color16 #ff966c
color17 #c53b53
THEME_EOF
    
    print_success "Kitty configuration created"
}

# Install shell tools (idempotent)
install_shell_tools() {
    print_status "Installing additional shell tools..."
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y \
                curl wget git \
                htop tree jq \
                ripgrep fd-find bat \
                ncdu tldr \
                2>/dev/null || true
            
            # Create symlinks for renamed packages
            sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
            
            # Install eza if not present
            if ! command -v eza &> /dev/null; then
                print_status "Installing eza..."
                local EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
                curl -Lo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
                sudo tar -xzf /tmp/eza.tar.gz -C /usr/local/bin
                rm /tmp/eza.tar.gz
            fi
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y \
                curl wget git \
                htop tree jq \
                ripgrep fd-find bat \
                ncdu \
                2>/dev/null || sudo yum install -y \
                curl wget git \
                htop tree jq \
                2>/dev/null || true
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm \
                curl wget git \
                htop tree jq \
                ripgrep fd bat eza \
                ncdu \
                2>/dev/null || true
            ;;
        macos)
            brew install \
                htop tree jq \
                ripgrep fd bat eza \
                ncdu tldr \
                zoxide starship \
                2>/dev/null || true
            ;;
    esac
    
    print_success "Shell tools installed"
}

# Install fonts (idempotent)
install_fonts() {
    print_status "Installing Nerd Fonts..."
    
    case "$OS" in
        ubuntu|debian|fedora|centos|rhel|rocky|almalinux|arch|manjaro|opensuse*|sles)
            FONT_DIR="$HOME/.local/share/fonts"
            ;;
        macos)
            FONT_DIR="$HOME/Library/Fonts"
            ;;
        *)
            print_warning "Skipping font installation for unsupported OS: $OS"
            return 0
            ;;
    esac
    
    mkdir -p "$FONT_DIR"
    
    # Check if fonts are already installed
    if ls "$FONT_DIR"/*Nerd* &> /dev/null; then
        print_success "Nerd Fonts already installed"
        return 0
    fi
    
    # Install SourceCodePro Nerd Font
    local font="SourceCodePro"
    print_status "Installing $font Nerd Font..."
    
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
    if curl -L -o "/tmp/${font}.zip" "$font_url"; then
        unzip -q -o "/tmp/${font}.zip" -d "$FONT_DIR"
        rm "/tmp/${font}.zip"
        print_success "$font Nerd Font installed"
    else
        print_warning "Failed to download $font Nerd Font"
    fi
    
    # Update font cache on Linux
    if [[ "$OS" != "macos" ]]; then
        fc-cache -fv > /dev/null 2>&1
    fi
    
    print_success "Fonts installed"
}

# Change default shell to Zsh
change_shell() {
    print_status "Checking default shell..."
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        print_success "Zsh is already the default shell"
        return 0
    fi
    
    print_status "Would you like to change your default shell to Zsh? (Y/n)"
    read -r response
    if [[ ! "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        if command -v zsh &> /dev/null; then
            local zsh_path="$(command -v zsh)"
            
            # Add zsh to /etc/shells if not already there
            if ! grep -q "$zsh_path" /etc/shells; then
                echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
            fi
            
            # Change shell
            chsh -s "$zsh_path"
            print_success "Default shell changed to Zsh"
            print_warning "Please log out and back in for the change to take effect"
        else
            print_error "Zsh not found. Please install it first."
        fi
    fi
}

# Show summary
show_summary() {
    echo
    echo "========================================"
    echo "Shell Environment Installation Summary"
    echo "========================================"
    echo
    print_success "✓ Zsh installed and configured"
    print_success "✓ Oh My Zsh framework installed"
    print_success "✓ Plugins: autosuggestions, syntax-highlighting, completions, fzf-tab"
    print_success "✓ Powerlevel10k theme installed"
    print_success "✓ FZF fuzzy finder installed"
    print_success "✓ Z directory jumper installed"
    print_success "✓ Additional shell tools installed"
    print_success "✓ Nerd Fonts installed"
    print_success "✓ Kitty terminal installed and configured"
    print_success "✓ Neovim installed with LazyVim"
    echo
    print_status "📋 Configuration files:"
    echo "  • ~/.zshrc - Main configuration"
    echo "  • ~/.zsh_functions - Custom functions"
    echo "  • ~/.z.sh - Directory jumper"
    echo "  • ~/.config/kitty/kitty.conf - Kitty terminal config"
    echo "  • ~/.config/nvim/ - Neovim/LazyVim configuration"
    echo
    print_status "📁 Log file: $LOG_FILE"
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Open a new Kitty terminal window"
    echo "  3. Run 'nvim' to complete LazyVim setup"
    echo "  4. Run 'kitty +kitten themes' to browse more themes"
    echo "  5. Optional: Run 'p10k configure' to customize prompt theme"
    echo "  6. Try these commands:"
    echo "     • fzf - Fuzzy find files"
    echo "     • z <partial-path> - Jump to directory"
    echo "     • cd <TAB> - Browse directories with preview"
    echo "     • nvim - Launch Neovim with LazyVim"
    echo
    print_status "🚀 Your enhanced shell environment is ready!"
}

# Main installation
main() {
    clear
    echo "========================================"
    echo "Enhanced Shell Environment Installer"
    echo "========================================"
    echo
    
    # Pre-flight checks
    check_root
    detect_os
    
    # Backup existing configs
    backup_existing_configs
    
    # Core installations
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_powerlevel10k
    configure_powerlevel10k
    configure_zsh
    
    # Additional tools
    install_fzf
    install_z
    install_shell_tools
    install_fonts
    
    # Terminal and editor
    install_kitty
    configure_kitty
    install_neovim
    install_lazyvim
    
    # Optionally change default shell
    change_shell
    
    # Show summary
    show_summary
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi