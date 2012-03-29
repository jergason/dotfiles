#Dotfiles

This is the repo for all my dotfiles. Tired of manually changing stuff
on multiple machines.

Install the files by running `rake`, and it will create
symbolic links to any matching dotfiles in this directory. Old dotfiles
are moved aside with the prefix of `old`, so if you already have a
`.bashrc` and there is one in the dotfiles repo, it will become
`old.bashrc`.

The Rake task will download and install a choice set of Vim plugins, so
I don't have to worry about keeping them in my repository.


## TODO:
* Fix some problems on Mac OS X systems without homebrew
* Fix some problems with systems without RVM
