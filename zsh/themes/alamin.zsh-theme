local green="%{$fg_bold[green]%}"
local red="%{$fg_bold[red]%}"
local cyan="%{$fg_bold[cyan]%}"
local yellow="%{$fg_bold[yellow]%}"
local blue="%{$fg_bold[blue]%}"
local magenta="%{$fg_bold[magenta]%}"
local white="%{$fg_bold[white]%}"
local black="%{$fg_bold[black]%}"
local reset="%{$reset_color%}"

function preexec() {
  timer=${timer:-$SECONDS}
}

function precmd() {
  if [ $timer ]; then
    timer_show=$(($SECONDS - $timer))
    export RPROMPT="%B$cyan${timer_show}s $black%@%B$reset"
    unset timer
  fi
}


local last_command_exit_code="(%?%)"
local last_command_output="%(?:$green➜:$red$last_command_exit_code)"
local current_dir_output="$cyan%c$reset"

PROMPT="$last_command_output $current_dir_output"
PROMPT+=' $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="${blue}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$reset "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
