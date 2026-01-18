# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
PATH=~/bin:$PATH
PATH=~/.composer/vendor/bin:$PATH
PATH=~/.local/bin:$PATH

if [[ "$OSTYPE" == "darwin"* ]]; then
    PATH=$PATH:/Applications/RubyMine.app/Contents/MacOS
fi

# ------------------------------------------------------------------------------
# Binaries
# ------------------------------------------------------------------------------
# Set VIM as the editor
export VISUAL=vim
export EDITOR="$VISUAL"

# Setup Homebrew
if command -v brew >/dev/null 2>&1; then
    eval "$($(which brew) shellenv)"
fi

# Stop Homebrew automatically updating all packages
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

# Setup Orbstack
if command -v orbstack >/dev/null 2>&1; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
fi

# ------------------------------------------------------------------------------
# Preferences
# ------------------------------------------------------------------------------
# Set term even on reloads
export TERM='xterm-256color'

# cd case insensitivity + autocomplete
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Custom prompt, with git branch
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
zstyle ':vcs_info:git:*' formats 'on %F{red}%b%f' enable git
NEWLINE=$'\n'
PROMPT='%F{blue}%~%f ${vcs_info_msg_0_}${NEWLINE}$ '

# Keybindings
bindkey -e
bindkey '\e[1;9D' backward-word    # Option + left arrow
bindkey '\e[1;9C' forward-word     # Option + right arrow

# ------------------------------------------------------------------------------
# Includes
# ------------------------------------------------------------------------------
# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

