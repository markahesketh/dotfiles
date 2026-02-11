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

DOCKER_COMPLETION_URL="https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"
if [ ! -f ~/.docker-completion.zsh ]; then
    echo "Downloading Docker autocomplete"
    if command_exists curl; then
        curl -fL -o ~/.docker-completion.zsh ${DOCKER_COMPLETION_URL}
    elif command_exists wget; then
        wget -O ~/.docker-completion.zsh ${DOCKER_COMPLETION_URL}
    fi
    echo ""
else
    echo "Docker autocomplete already installed, skipping."
fi

if ! command_exists atuin; then
    echo "Installing Atuin"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    echo ""
fi

source scripts/macos.sh

# ------------------------------------------------------------------------------
# Finish
# ------------------------------------------------------------------------------
echo "Installation complete!"
exec $SHELL -l
