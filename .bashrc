#Detect the platform we are running on for some platform-specific stuff.
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == "Linux" ]]; then
  platform='linux'
elif [[ "$unamestr" == "Darwin" ]]; then
  platform='freebsd'
fi

# Add homebrew binaries to path
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# add homebrew python path
export PATH=/usr/local/share/python:$PATH

export EDITOR=vim
export GNUTERM='x11'

# history setup

# append to history immediately after each command is executed
# this apparently fixes issues with tmux wiping out history files
shopt -s histappend
# replaces ~/.bash_history with ~/.history/year/month/
export HISTFILE="${HOME}/.history/$(date -u +%Y/%m/%d)_${HOSTNAME_SHORT}_$$"
# unlimited history file size
export HISTSIZE="NOTHING"
export HISTFILESIZE="NOTHING"
# write new lines to history file after running each command instead of when shell exists
export PROMPT_COMMAND="history -a;$PROMPT_COMMAND"



# Use local ackrc files if they exist
export ACKRC=".ackrc"

# Ansible Vault password file location
export ANSIBLE_VAULT_PASSWORD_FILE=~/code/mdisc/.ansible-vault-pass.txt

# set file limit
ulimit -n 65536
ulimit -u 2048


# Aliases for awesomeness
alias ll="ls -alh"
alias ls="ls -G" # colors in ls
alias pp='python -mjson.tool' #json pretty printing
alias nis='npm i --save' # install and save npm modules woo
alias diary='cd ~/code/journal/kualico-work && vim `date +"%Y-%m-%d"`.md'
alias journal='cd ~/code/journal/fivestack && vim `date +"%Y-%m-%d"`.md'
alias tcp='tmux show-buffer | pbcopy'
# highlight source code
alias hl='highlight -O rtf --font "Source Code Pro" --font-size=30'
alias gitclean='git branch --merged | grep -v "\*" | grep -v master | grep -v dev | grep -v yours-master | xargs -n 1 git branch -d'
alias search_history="history | awk '{print $2}' | sort | uniq -c | sort -rn | head -10"

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

# behold my very own quote server
curl --silent localhost:4041 | fmt -t 80 | ponysay -W 80
# fortune | ponysay
