# dotfiles

A collection of dotfiles and configuration from my dev environment.

![Terminal window](https://i.ibb.co/pxrZG4T/terminal.png)

## Installation

    ./install.sh
    
This will:

* Confirm and remove existing dotfiles
* Create symlinks to this repo's [dotfiles](/home)
* Download Git and Docker autocomplete bash scripts

## Usage

Symlinks from your home directory to this repository's files will be created, meaning all changes to 
dotfiles can be tracked in version control.

### Local settings

Each dotfile will check for a `*.local` file matching its own name.

This is useful for overwriting or supplementing configs on a specific environment outside of 
version control. 

For example:

* Local `.alias` file would be `~/.aliases.local`
* Local `.zprofile` file would be `~/.zprofile.local`
* etc.

## License

[MIT](LICENSE).
