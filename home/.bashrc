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

# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
# User binaries
PATH=$PATH:/usr/local/sbin:~/bin

# Composer global binaries
PATH=$PATH:~/.composer/vendor/bin
PATH=$PATH:~/.config/composer/vendor/bin

# ------------------------------------------------------------------------------
# Includes
# ------------------------------------------------------------------------------
# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Custom prompt
[[ -f ~/.bash_prompt ]] && source ~/.bash_prompt

# Local config
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local