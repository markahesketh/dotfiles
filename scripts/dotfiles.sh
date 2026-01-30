#!/bin/bash

# ------------------------------------------------------------------------------
# Dotfiles Management Script
# ------------------------------------------------------------------------------
# This script manages dotfiles symlinks and can be run independently
# or as part of the main install.sh script.

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

DOTFILES=(
    ".aliases"
    ".claude/agents"
    ".claude/commands"
    ".claude/skills"
    ".gitconfig"
    ".gitignore"
    ".hushlogin"
    ".vimrc"
    ".zprofile"
    ".zshrc"
    "bin"
)

# ------------------------------------------------------------------------------
# Create dotfiles symlinks
# ------------------------------------------------------------------------------
echo "This script will create the following dotfiles:"
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

    echo "Dotfiles symlinks created successfully!"
else
    echo "Dotfiles setup skipped."
    exit 0
fi
echo ""

# If this script is being run standalone (not sourced), reload the shell
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Reloading shell..."
    exec $SHELL -l
fi