# dotfiles

A collection of dotfiles and configuration from my dev environment.

![Terminal window](https://i.ibb.co/pxrZG4T/terminal.png)

## Installation

    bin/setup

This will:

* Create symlinks from `~/` to files in this repo's [home/](/home) directory
* Download Docker autocomplete
* Install Homebrew packages from [Brewfile](/Brewfile) (macOS only)
* Apply macOS system preferences

## Usage

Symlinks from your home directory to this repository's files are created, meaning all changes to dotfiles can be tracked in version control.

### Updating symlinks

After adding or changing dotfiles, refresh symlinks with:

    bin/dotfiles

Or from anywhere using the shell function:

    dotfiles

### Reloading the shell

    reload

### Local settings

Each dotfile checks for a `*.local` file matching its own name. Use these for machine-specific config outside of version control.

For example:

* `~/.aliases.local`
* `~/.zprofile.local`
* etc.

## What's included

| File/Directory | Description |
|---|---|
| `.zshenv` | Environment variables and PATH for every zsh process |
| `.zprofile` | Login environment, including Homebrew |
| `.zshrc` | Interactive prompt, completions, key bindings, and tool hooks |
| `.aliases` | Shell aliases and Rails helpers |
| `.gitconfig` | Git configuration and aliases |
| `.gitignore` | Global gitignore |
| `.vimrc` | Vim configuration |
| `.tmux.conf` | Tmux configuration |
| `.hushlogin` | Suppresses login message |
| `.config/ghostty/` | Ghostty terminal config |
| `.config/tmux/` | Tmux scripts (dark mode, session hooks, test runner) |
| `.config/herdr/` | Herdr config and local plugins |
| `.config/atuin/` | Atuin shell history config |
| `.config/direnv/` | Direnv whitelist config |
| `.config/workmux/` | Workmux workspace config |
| `.config/zed/` | Zed editor config |
| `.claude/` | Claude Code settings, hooks, and media |
| `.codex/` | Codex config |
| `.agents/` | Shared AI agent definitions and skills (symlinked into both `.claude/` and `.codex/`) |
| `bin/` | Utility scripts |
| `Library/` | macOS app config (lazygit) |

### AI agent resources

`home/.agents/` is the source of truth for shared AI resources. The install script creates symlinks so both `~/.claude/` and `~/.codex/` point into it:

* `~/.claude/agents` and `~/.codex/agents` → `home/.agents/agents/`
* `~/.claude/skills` and `~/.codex/skills` → `home/.agents/skills/`

## License

[MIT](LICENSE).
