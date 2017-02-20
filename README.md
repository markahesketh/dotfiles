# [Mark Hesketh](https://www.markhesketh.co.uk)'s dotfiles

A collection of dotfiles and configuration from my dev environment.

![Terminal window](https://i.imgur.com/WgyW5lu.png)

## Installation

    git clone https://github.com/heskethm/dotfiles.git
    cd dotfiles
    chmod +x install.sh
    ./install.sh
    
This will:

* Confirm and remove existing dotfiles
* Create symlinks to this repo's [dotfiles](/home)
* Create a `~/.bash_local` file for [local settings](#local-settings)

## Usage

### Local settings

The installation script will create a `~/.bash_local` file in your home 
directory.

The `~/.bash_local` is sourced after all other dotfiles, and so can be used 
to override existing bash configuration such as aliases, $PATH and 
environment variables.

## License

Available under the [MIT license](LICENSE).