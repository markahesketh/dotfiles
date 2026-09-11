# Runs for EVERY zsh: interactive, non-interactive, scripts, shebangs, git hooks.
# Environment only - no prompt, no hooks, no subprocesses, no output.

typeset -U path PATH fpath

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Locale
# ------------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ------------------------------------------------------------------------------
# Path
# ------------------------------------------------------------------------------
# mise shims rather than `mise activate`: shims resolve the per-directory tool
# version at call time, so a PATH captured once (GUI apps, daemons, setup hooks)
# stays correct. `activate` bakes in version-pinned paths that freeze.
path=(
	$HOME/.local/share/mise/shims
	$HOME/bin
	$HOME/.local/bin
	$HOME/.composer/vendor/bin
	$HOME/.cargo/bin
	/opt/homebrew/bin
	/opt/homebrew/sbin
	/opt/homebrew/opt/postgresql@18/bin
	$path
)

[[ "$OSTYPE" == "darwin"* ]] && path+=(/Applications/RubyMine.app/Contents/MacOS)

# ------------------------------------------------------------------------------
# Binaries
# ------------------------------------------------------------------------------
export EDITOR=nano
export VISUAL=$EDITOR

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1

[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
