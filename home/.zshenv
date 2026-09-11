# Runs for EVERY zsh: interactive, non-interactive, scripts, shebangs, git hooks.
# Environment only - no prompt, no hooks, no subprocesses, no output.

typeset -U path PATH fpath

# ------------------------------------------------------------------------------
# Path
# ------------------------------------------------------------------------------
# mise shims rather than `mise activate`: shims resolve the per-directory tool
# version at call time, so a PATH captured once (GUI apps, daemons, setup hooks)
# stays correct. `activate` bakes in version-pinned paths that freeze.
# macOS runs path_helper between .zshenv and .zprofile.
_dotfiles_reset_path() {
	local -a inherited_path
	inherited_path=("${path[@]}")

	path=(
		"$HOME/.local/share/mise/shims"
		"$HOME/bin"
		"$HOME/.local/bin"
	)

	[[ -d "$HOME/.opencode/bin" ]] && path+=("$HOME/.opencode/bin")

	path+=(
		"$HOME/.composer/vendor/bin"
		"$HOME/.cargo/bin"
	)

	if [[ "$OSTYPE" == "darwin"* ]]; then
		[[ -d /opt/homebrew/bin ]] && path+=(/opt/homebrew/bin /opt/homebrew/sbin)
		[[ -d /usr/local/bin ]] && path+=(/usr/local/bin)
		[[ -d /Applications/RubyMine.app/Contents/MacOS ]] && path+=(/Applications/RubyMine.app/Contents/MacOS)
	fi

	path+=("${inherited_path[@]}")
}

_dotfiles_reset_path

# ------------------------------------------------------------------------------
# Binaries
# ------------------------------------------------------------------------------
export EDITOR=nano
export VISUAL=$EDITOR

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

[[ -r "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
