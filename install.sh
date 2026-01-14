#!/bin/bash

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Setup dotfiles
# ------------------------------------------------------------------------------
source "${BASEDIR}/scripts/dotfiles.sh"

echo "Downloading Docker autocomplete"
DOCKER_COMPLETION_URL="https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"
if command_exists curl; then
    curl -L -o ~/.docker-completion.zsh ${DOCKER_COMPLETION_URL}
elif command_exists wget; then
    wget -O ~/.docker-completion.zsh ${DOCKER_COMPLETION_URL}
fi
echo ""

source scripts/macos.sh

# ------------------------------------------------------------------------------
# Finish
# ------------------------------------------------------------------------------
echo "Installation complete!"
exec $SHELL -l
