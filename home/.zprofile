# Setup Mise
if [ -f $HOME/.local/bin/mise ]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
elif [ -f /opt/homebrew/bin/mise ]; then
    eval "$(/opt/homebrew/bin/mise activate zsh)"
fi
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Setup atuin
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# Local config
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local