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
    ".claude/settings.json"
    ".claude/skills"
    ".claude/statusline-command.sh"
    ".config/atuin/config.toml"
    ".config/tmux/is-dark-mode.sh"
    ".config/tmux/on-session-created.sh"
    ".config/tmux/run-tests.sh"
    ".config/workmux/config.yaml"
    ".gemini/settings.json"
    ".gitconfig"
    ".gitignore"
    ".hushlogin"
    ".tmux.conf"
    ".vimrc"
    ".zprofile"
    ".zshrc"
)

AGENT_MIRRORS=(
    "agents"
    "skills"
)

# ------------------------------------------------------------------------------
# Create dotfiles symlinks
# ------------------------------------------------------------------------------
echo "This script will create the following dotfiles:"
for i in "${DOTFILES[@]}"
do
    echo "- ~/$i"
done
for i in "${AGENT_MIRRORS[@]}"
do
    echo "- ~/.codex/$i (from ~/.claude/$i)"
done

echo ""

read -p "Create these files? They will be overwritten if they exist [y/N]: " CONT
if [ "$CONT" == "y" ]; then
    create_symlink() {
        local source_path="$1"
        local target_path="$2"

        rm -rf "$target_path"

        local parent_dir
        parent_dir=$(dirname "$target_path")
        if [ "$parent_dir" != "$HOME" ] && [ ! -d "$parent_dir" ]; then
            mkdir -p "$parent_dir"
        fi

        ln -nfs "$source_path" "$target_path"
    }

    for i in "${DOTFILES[@]}"
    do
        echo "Creating $i ..."
        create_symlink "${BASEDIR}/home/$i" "$HOME/$i"
    done

    for i in "${AGENT_MIRRORS[@]}"
    do
        echo "Creating .codex/$i ..."
        create_symlink "${BASEDIR}/home/.claude/$i" "$HOME/.codex/$i"
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
