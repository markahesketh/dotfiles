# ------------------------------------------------------------------------------
# PATH
# ------------------------------------------------------------------------------
PATH=$PATH:~/.composer/vendor/bin

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
eval "$(/opt/homebrew/bin/brew shellenv)"

# Stop Homebrew automatically updating all packages
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

# Setup Orbstack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Setup Mise
eval "$(/Users/markhesketh/.local/bin/mise activate zsh)"

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

# Local config
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local
