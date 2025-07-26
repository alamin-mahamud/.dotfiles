alias asp='export AWS_PROFILE=sandbox-poweruser && aws sso login --profile sandbox-poweruser'
alias asa='export AWS_PROFILE=sandbox-admin && aws sso login --profile sandbox-admin'
alias vim='nvim'

source <(kubectl completion zsh)
