# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# ------------------------------------------------------------------------------
# System
# ------------------------------------------------------------------------------
if [ -n "$(which apt-get)" ]; then
    alias upgrade="sudo apt-get update && sudo apt-get upgrade"
    alias clipboard="xclip -se c"
fi

# ------------------------------------------------------------------------------
# Directory listing
# ------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls="ls -GA"
else
    alias ls="ls -A --color=auto"
fi
alias ll="ls -lh"

# ------------------------------------------------------------------------------
# Navigation
# ------------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# ------------------------------------------------------------------------------
# Confirmation messages
# ------------------------------------------------------------------------------
alias rm='rm -iv'
alias mv='mv -iv'

# ------------------------------------------------------------------------------
# Grep
# ------------------------------------------------------------------------------
alias h="history | grep "
alias f="find .  | grep "
alias p="ps aux  | grep "

# ------------------------------------------------------------------------------
# Workflow
# ------------------------------------------------------------------------------
alias c="composer"
alias gae="dev_appserver.py --php_executable_path=$(which php-cgi)"
alias robo="./vendor/bin/robo"
alias t="./vendor/bin/phpunit"

# ------------------------------------------------------------------------------
# Misc
# ------------------------------------------------------------------------------
# Clean useless files
alias clean='rm -rf "#"* "."*~ *~ *.bak *.dvi *.aux *.nfo'

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"