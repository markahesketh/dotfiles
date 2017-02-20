# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# ------------------------------------------------------------------------------
# Global settings
# ------------------------------------------------------------------------------
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

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
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# Custom prompt
if [ -f ~/.bash_prompt ]; then
  . ~/.bash_prompt
fi

# Local settings, not committed
if [ -f ~/.bash_local ]; then
  . ~/.bash_local
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f /Users/markhesketh/google-cloud-sdk/path.bash.inc ]; then
  source '/Users/markhesketh/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f /Users/markhesketh/google-cloud-sdk/completion.bash.inc ]; then
  source '/Users/markhesketh/google-cloud-sdk/completion.bash.inc'
fi
