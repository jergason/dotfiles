#Detect the platform we are running on for some platform-specific stuff.
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]; then
  platform='linux'
elif [[ "$unamestr" == "Darwin" ]]; then
  platform='freebsd'
fi

# golang env vars setup
export GOPATH=~/golang
export GOROOT=$GOPATH/go
export GOBIN=$GOPATH/bin

# add GOBIN to path
export PATH=$GOBIN:$PATH
export PATH=$GOROOT/bin:$PATH

export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# add homebrew python path
export PATH=/usr/local/share/python:$PATH

if [[ "$platform" == 'freebsd' ]]; then
  export EDITOR=mvim
else
  export EDITOR=vim
fi
export GNUTERM='x11'

# Use local ackrc files if they exist
export ACKRC=".ackrc"

# set file limit
ulimit -n 65536
ulimit -u 2048


# Aliases for awesomeness
alias ll="ls -alh"
alias ls="ls -G" # colors in ls
alias pp='python -mjson.tool' #json pretty printing
alias nis='npm i --save' # install and save npm modules woo
alias diary='cd ~/code/journal/kualico-work && vim `date +"%Y-%m-%d"`.md'
alias tcp='tmux show-buffer | pbcopy'
# highlight source code
alias hl='highlight -O rtf --font "Source Code Pro" --font-size=30'

# tmux alias to make sure it supports 256 colors
alias tmux="TERM=screen-256color tmux"


# bash completion
if [[ "$platform" == 'freebsd' ]]; then
  if [[ -f `brew --prefix`/etc/bash_completion ]]; then source `brew --prefix`/etc/bash_completion; fi # for Git completion
elif [[ "$platform" == 'linux' ]]; then
  if [[ -e "/etc/bash_completion.d/git" ]]; then
    source /etc/bash_completion.d/git
  fi
fi

export PS1="\`if [ \$? = 0 ]; then echo \[\e[33m\]^_^\[\e[0m\]; else echo \[\e[31m\]ಠ_ಠ\[\e[0m\]; fi\` \[\033[01;34m\] \[\033[01;32m\]\w\[\033[00;33m\]\$(__git_ps1 \" (%s)\") \[\033[01;36m\]λ\[\033[00m\] "

# rbenv setup
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

set keymap vi
set -o vi

# nvm setup
NVMPATH=~/.nvm/nvm.sh
if [[ -r $NVMPATH ]]; then
  source $NVMPATH
fi

# for badoop (https://github.com/jergason/badoop)
export TODO=~/Dropbox/todo.txt

#Optionally include a .bashrc.local for some local stuff
if [[ -f ~/.bashrc.local ]]; then
  source ~/.bashrc.local
fi

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"


export LUA_PATH='/Users/jergason/.luarocks/share/lua/5.1/?.lua;/Users/jergason/.luarocks/share/lua/5.1/?/init.lua;/Users/jergason/torch/install/share/lua/5.1/?.lua;/Users/jergason/torch/install/share/lua/5.1/?/init.lua;./?.lua;/Users/jergason/torch/install/share/luajit-2.1.0-alpha/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua'
export LUA_CPATH='/Users/jergason/.luarocks/lib/lua/5.1/?.so;/Users/jergason/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so'
export PATH=/Users/jergason/torch/install/bin:$PATH  # Added automatically by torch-dist
export LD_LIBRARY_PATH=/Users/jergason/torch/install/lib:$LD_LIBRARY_PATH  # Added automatically by torch-dist
export DYLD_LIBRARY_PATH=/Users/jergason/torch/install/lib:$DYLD_LIBRARY_PATH  # Added automatically by torch-dist
