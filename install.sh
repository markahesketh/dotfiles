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
# Finish
# ------------------------------------------------------------------------------
exec $SHELL -l