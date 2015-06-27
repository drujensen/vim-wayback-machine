# Git Wayback Machine in VIM

Adapted from Nikolay Nemshilov's [MadRabbit/git-wayback-machine](https://github.com/MadRabbit/git-wayback-machine).

This VIM plugin provides the ability to easily navigate through the history of git commits 
and see the progression of changes.  The plugin is written in Ruby.  

## Requirements

- vim >= 7.2 with Ruby support (check with `:version` and look for `+ruby`)

## Installation

- Get [Pathogen](httsp://github.com/tpope/vim-pathogen)
- clone this repository in your /vim/bundle directory


## How to use it?

`:WaybackMachine` - opens the Wayback Machine based on the current file being
viewed. You will see the Git Log in a buffer.  You can navigate up and down
through time and watch the file change.

When you close the Wayback Machine window, this will `git reset` to the latest
version.

`<leader>w` maps to the Wayback Machine.

### Issues

- This utility uses `git reset --hard {sha}`. You've been warned!

## Copyright & License

All code in this repository is released under the terms of the MIT License

