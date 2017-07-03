# [Mark Hesketh](https://www.markhesketh.co.uk)'s dotfiles

A collection of dotfiles and configuration from my dev environment.

![Terminal window](https://i.imgur.com/WgyW5lu.png)

## Installation

    chmod +x install.sh
    ./install.sh
    
This will:

* Confirm and remove existing dotfiles
* Create symlinks to this repo's [dotfiles](/home)
* Download Git and Docker autocomplete bash scripts

## Usage

### Local settings

Each dotfile will check for a `*.local` file matching its own name.

For example:

* Local alias file would be `~/.aliases.local`
* Local bashrc file would be `~/.bashrc.local`
* etc.

## License

Available under the [MIT License](LICENSE).