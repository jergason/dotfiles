#Detect the platform we are running on for some platform-specific stuff.
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]; then
  platform='linux'
elif [[ "$unamestr" == "Darwin" ]]; then
  platform='freebsd'
fi

export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# add homebrew python path
export PATH=/usr/local/share/python:$PATH

if [[ "$platform" == 'freebsd' ]]; then
  export EDITOR=mvim
else
  export EDITOR=vim
fi
export GNUTERM='x11'
export NODE_PATH=/usr/local/lib/node_modules:/usr/local/lib/node:$NODE_PATH


# Aliases for awesomeness
alias ll="ls -alh"
alias ls="ls -G" # colors in ls
alias pp='python -mjson.tool' #json pretty printing

# See http://collectiveidea.com/blog/archives/2011/08/02/command-line-feedback-from-rvm-and-git/ for where this came from
[[ -r $rvm_path/scripts/completion ]] && . $rvm_path/scripts/completion # for RVM completion

# tmux alias to make sure it supports 256 colors
alias tmux="TERM=screen-256color tmux"


# Git completion
if [[ "$platform" == 'freebsd' ]]; then
  if [[ -f `brew --prefix`/etc/bash_completion.d/git-completion.bash ]]; then source `brew --prefix`/etc/bash_completion.d/git-completion.bash; fi # for Git completion
elif [[ "$platform" == 'linux' ]]; then
  if [[ -e "/etc/bash_completion.d/git" ]]; then
    source /etc/bash_completion.d/git
  fi
fi

# RVM version info in path
if [[ -r ~/.rvm/bin/rvm-prompt ]]; then
  promptChunk="\$(~/.rvm/bin/rvm-prompt)"
else
  promptChunk=""
fi

export PS1="\`if [ \$? = 0 ]; then echo \[\e[33m\]^_^\[\e[0m\]; else echo \[\e[31m\]ಠ_ಠ\[\e[0m\]; fi\` \[\033[01;34m\]$promptChunk \[\033[01;32m\]\w\[\033[00;33m\]\$(__git_ps1 \" (%s)\") \[\033[01;36m\]λ\[\033[00m\] "

set keymap vi
set -o vi

if [[ -f ~/.rvm/scripts/rvm ]]; then
  [[ -s ~/.rvm/scripts/rvm ]] && source ~/.rvm/scripts/rvm  # This loads RVM into a shell session.
fi

# nvm setup
if [[ -r ~/nvm/nvm.sh ]]; then
  source ~/nvm/nvm.sh
fi

# for badoop (https://github.com/jergason/badoop
export TODO=~/Dropbox/todo.txt

#Optionally include a .bashrc.local for some local stuff
if [[ -f ~/.bashrc.local ]]; then
  source ~/.bashrc.local
fi

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
