# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

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
# Set Zed as the editor
export VISUAL="zed --wait"
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
# Set TERM only if not already set by the terminal emulator
[[ -z "$TERM" || "$TERM" == "dumb" ]] && export TERM='xterm-256color'

# History
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# cd case insensitivity + autocomplete
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Terminal title (used by tmux pane-border-format via #{pane_title})
_title_precmd() { printf '\033]0;zsh\007' }
_title_preexec() { printf '\033]0;%s\007' "${1%% *}" }
precmd_functions+=(_title_precmd)
preexec_functions+=(_title_preexec)

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

if command_exists fzf; then
    eval "$(fzf --zsh)"
fi

if command_exists atuin; then
    eval "$(atuin init zsh)"
fi

if command_exists workmux; then
    eval "$(workmux completions zsh)"
fi

if command_exists opencode; then
    export PATH=/Users/markhesketh/.opencode/bin:$PATH
fi
