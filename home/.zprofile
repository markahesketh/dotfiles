if (( $+commands[brew] )); then
	eval "$(command brew shellenv)"
fi

(( $+functions[_dotfiles_reset_path] )) && _dotfiles_reset_path

[[ -r "$HOME/.zprofile.local" ]] && source "$HOME/.zprofile.local"
