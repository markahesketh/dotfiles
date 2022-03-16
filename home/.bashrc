# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# ------------------------------------------------------------------------------
# Global settings
# ------------------------------------------------------------------------------
[[ -f /etc/bashrc ]] && source /etc/bashrc

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Bash won't get SIGWINCH if another process is in the foreground.
# Enable checkwinsize so that bash will check the terminal size when
# it regains control.
shopt -s checkwinsize

# Get some colour
export TERM=xterm-256color
export CLICOLOR=1
export LSCOLORS=exfxcxdxbxegedabagacad

# Silence bash deprecation notice from macOS Catalina
export BASH_SILENCE_DEPRECATION_WARNING=1

# ------------------------------------------------------------------------------
# EDITOR
# ------------------------------------------------------------------------------
export VISUAL=vim
export EDITOR="$VISUAL"

# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
# User binaries
PATH=$PATH:/usr/local/sbin:~/bin

# Composer global binaries
PATH=$PATH:~/.composer/vendor/bin
PATH=$PATH:~/.config/composer/vendor/bin
PATH=$PATH:/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin
PATH=$PATH:/usr/local/opt/mysql-client/bin

# ------------------------------------------------------------------------------
# Includes
# ------------------------------------------------------------------------------
# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Custom prompt
[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

# Local config
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# Git auto-completion
# Download from https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
[[ -f ~/.git-completion.bash ]] && source ~/.git-completion.bash

# Docker auto-completion
# Download from https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker
[[ -f ~/.docker-completion.bash ]] && source ~/.docker-completion.bash

# Docker Compose auto-completion
# Download from https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose
[[ -f ~/.docker-compose-completion.bash ]] && source ~/.docker-compose-completion.bash

# WP CLI auto-completion
# Download from https://raw.githubusercontent.com/wp-cli/wp-cli/v2.4.0/utils/wp-completion.bash
[[ -f ~/.wp-completion.bash ]] && source ~/.wp-completion.bash

# Load rbenv
eval "$(rbenv init -)"
