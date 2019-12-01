#!/bin/bash

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES=(
    ".aliases"
    ".bash_profile"
    ".bash_prompt"
    ".bashrc"
    ".gitconfig"
    ".gitignore"
    ".inputrc"
    ".myxkbmap"
    ".vimrc"
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

read -p "Create these files? They will be overwritten if they exist [y/N]: " CONT
if [ "$CONT" == "y" ]; then
    for i in "${DOTFILES[@]}"
    do
        echo "Creating $i ..."
        rm -f ~/$i
        ln -nfs ${BASEDIR}/home/$i ~/$i
    done
fi

# ------------------------------------------------------------------------------
# Download third-party scripts
# ------------------------------------------------------------------------------
echo "Downloading git autocomplete"
GIT_COMPLETION_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
if command_exists curl; then
    curl -o ~/.git-completion.bash ${GIT_COMPLETION_URL}
elif command_exists wget; then
    wget -O ~/.git-completion.bash ${GIT_COMPLETION_URL}
fi

echo "Downloading Docker autocomplete"
DOCKER_COMPLETION_URL="https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker"
if command_exists curl; then
    curl -L -o ~/.docker-completion.bash ${DOCKER_COMPLETION_URL}
elif command_exists wget; then
    wget -O ~/.docker-completion.bash ${DOCKER_COMPLETION_URL}
fi

echo "Downloading Docker Compose autocomplete"
DOCKER_COMPLETION_URL="https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose"
if command_exists curl; then
    curl -L -o ~/.docker-compose-completion.bash ${DOCKER_COMPLETION_URL}
elif command_exists wget; then
    wget -O ~/.docker-compose-completion.bash ${DOCKER_COMPLETION_URL}
fi

# ------------------------------------------------------------------------------
# Finish
# ------------------------------------------------------------------------------
clear
echo "Installation complete!"
exec $SHELL -l