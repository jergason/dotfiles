#Dotfiles

This is the repo for all my dotfiles. Tired of manually changing stuff
on multiple machines.

Install the files by running `rake install_dotfiles`, and it will create
symbolic links to any matching dotfiles in this directory. Old dotfiles
are moved aside with the prefix of `old`, so if you already have a
`.bashrc` and there is one in the dotfiles repo, it will become
`old.bashrc`.

Used Ruby for the install stuff becaus I am not enough of a Bash wizard
to do it just in Bash, but moving to just a bash script is a goal
somtime to reduce dependencies.
