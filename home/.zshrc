# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

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
[[ -f ~/.aliases ]] && source ~/.aliases

if command_exists fzf; then
    eval "$(fzf --zsh)"
fi

if command_exists atuin; then
    eval "$(atuin init zsh)"
fi

# Deliberately NOT `mise activate` - the shims in .zshenv cover every shell,
# and activate bakes version-pinned paths into any environment that captures it.

# Homebrew here rather than .zshenv: .zshenv already has the bin dirs, this is
# only for MANPATH/INFOPATH/HOMEBREW_PREFIX, and it costs a subprocess.
if command_exists brew; then
    eval "$(brew shellenv)"
    # shellenv prepends its bin dirs; keep shims ahead so a brewed node/python
    # never shadows the mise-managed one.
    path=($HOME/.local/share/mise/shims $path)
fi

if [[ -f ~/.orbstack/shell/init.zsh ]]; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null
fi

if command_exists wt; then
    eval "$(command wt config shell init zsh)"
fi

if command_exists direnv; then
    eval "$(direnv hook zsh)"
fi

if command_exists opencode; then
    export PATH=/Users/markhesketh/.opencode/bin:$PATH
fi

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local