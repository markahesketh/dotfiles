# ------------------------------------------------------------------------------
# Preferences
# ------------------------------------------------------------------------------
# Set TERM only if not already set by the terminal emulator
[[ -z "$TERM" || "$TERM" == "dumb" ]] && export TERM='xterm-256color'

# History
HISTSIZE=50000
if (( $+commands[atuin] )); then
	# Atuin owns persistent history; zsh history remains in memory for widgets.
	HISTFILE=
	SAVEHIST=0
	unsetopt SHARE_HISTORY
else
	HISTFILE="$HOME/.zsh_history"
	SAVEHIST=50000
	setopt SHARE_HISTORY
fi
setopt HIST_IGNORE_DUPS
# Atuin applies its own secret filter.
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Add completion paths before compinit.
[[ -d "$HOME/.zsh/completions" ]] && fpath=("$HOME/.zsh/completions" "${fpath[@]}")

if [[ -r "$HOME/.orbstack/shell/init.zsh" ]]; then
	source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null
fi

autoload -Uz compinit && compinit

# Custom prompt, with git branch
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
typeset -ga precmd_functions
if (( ! ${precmd_functions[(I)precmd_vcs_info]} )); then
	precmd_functions+=( precmd_vcs_info )
fi
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
[[ -r "$HOME/.aliases" ]] && source "$HOME/.aliases"

if (( $+commands[fzf] )); then
    eval "$(fzf --zsh)"
fi

if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi

# Deliberately NOT `mise activate` - the shims in .zshenv cover every shell,
# and activate bakes version-pinned paths into any environment that captures it.

if (( $+commands[wt] )); then
    eval "$(command wt config shell init zsh)"
fi

if (( $+commands[direnv] )); then
    eval "$(direnv hook zsh)"
fi

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
