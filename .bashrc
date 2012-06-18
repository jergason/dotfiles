#Detect the platform we are running on for some platform-specific stuff.
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]; then
  platform='linux'
elif [[ "$unamestr" == "Darwin" ]]; then
  platform='freebsd'
fi

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
if [[ "$platform" == 'freebsd' ]]; then
  export EDITOR=mvim
else
  export EDITOR=vim
fi
export GNUTERM='x11'
export NODE_PATH=/usr/local/lib/node_modules:/usr/local/lib/node:$NODE_PATH

export TODO=~/Dropbox/todo.txt

# Aliases for awesomeness
alias ll="ls -alh"
alias ls="ls -G" # colors in ls
alias pp='python -mjson.tool' #json pretty printing

#TODO: put guards on rvm and brew stuff
# See http://collectiveidea.com/blog/archives/2011/08/02/command-line-feedback-from-rvm-and-git/ for where this came from
[[ -r $rvm_path/scripts/completion ]] && . $rvm_path/scripts/completion # for RVM completion

# Git completion
if [[ "$platform" == 'freebsd' ]]; then
  if [[ -f `brew --prefix`/etc/bash_completion.d/git-completion.bash ]]; then source `brew --prefix`/etc/bash_completion.d/git-completion.bash; fi # for Git completion
elif [[ "$platform" == 'linux' ]]; then
  if [[ -e "/etc/bash_completion.d/git" ]]; then
    source /etc/bash_completion.d/git
  fi
fi

export PS1="\`if [ \$? = 0 ]; then echo \[\e[33m\]^_^\[\e[0m\]; else echo \[\e[31m\]ಠ_ಠ\[\e[0m\]; fi\` \[\033[01;34m\]\$(~/.rvm/bin/rvm-prompt) \[\033[01;32m\]\w\[\033[00;33m\]\$(__git_ps1 \" (%s)\") \[\033[01;36m\]λ\[\033[00m\] "

set keymap vi
set -o vi

if [[ -f ~/.rvm/scripts/rvm ]]; then
  [[ -s ~/.rvm/scripts/rvm ]] && source ~/.rvm/scripts/rvm  # This loads RVM into a shell session.
fi

function todo() {
  # $# is the number of parameters passed in
  if [[ $# == "0" ]];
    then
      cat $TODO;
    else
      # $@ is a string containing all parameters
      echo "• $@" >> $TODO;
  fi
}

function todone() {
  # $@ is all the arguments passed in.
  # not sure what d is. Flag to delete anything that matches?
  sed -i -e "/$@/d" $TODO;
}


#Optionally include a .bashrc.local for some local stuff
if [[ -f ~/.bashrc.local ]]; then
  source ~/.bashrc.local
fi

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
