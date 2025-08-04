#!/bin/bash

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES=(
    ".aliases"
    ".claude/commands"
    ".gitconfig"
    ".gitignore"
    ".hushlogin"
    ".prompt"
    ".vimrc"
    ".zshrc"
)

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Create dotfiles symlinks
# ------------------------------------------------------------------------------
echo "This script will create the following files:"
for i in "${DOTFILES[@]}"
do
    echo "- ~/$i"
done
echo ""

read -p "Create these files? They will be overwritten if they exist [y/N]: " CONT
if [ "$CONT" == "y" ]; then
    for i in "${DOTFILES[@]}"
    do
        echo "Creating $i ..."
        rm -rf ~/$i
        
        # Create parent directory if it doesn't exist
        parent_dir=$(dirname ~/$i)
        if [ "$parent_dir" != "$HOME" ] && [ ! -d "$parent_dir" ]; then
            mkdir -p "$parent_dir"
        fi
        
        ln -nfs ${BASEDIR}/home/$i ~/$i
    done
fi
echo ""

if [ ! -d "$HOME/home" ]; then
    echo "Creating bin folder in home directory (e.g. ~/bin)"
    mkdir -p $HOME/bin
fi

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
