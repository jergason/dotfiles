#!/usr/bin/env bash

set -e
set -x

# use with get_confirmation "install rust" etc
get_confirmation() {
  cecho "Do you want to $1? ([y]/n)" "$red"
  read -r user_input

  if [ -z "$user_input" ] || [ "$user_input" == "y" ] || [ "$user_input" == "Y" ]; then
    return 0
  else
    return 1
  fi
}

# Set the colours you can use
red='\033[0;31m'
green='\033[0;32m'


#  Reset text attributes to normal + without clearing screen.
alias Reset="tput sgr0"

# Color-echo.
# arg $1 = message
# arg $2 = Color
cecho() {
  echo "${2}${1}"
  Reset # Reset to normal.
  return
}

echo ""
cecho "┌────────────────────────┐" "$green"
cecho "│                        │" "$green"
cecho "│💻 Let's Get Set Up 💻  │" "$green"
cecho "│                        │" "$green"
cecho "└────────────────────────┘" "$green"
echo ""

DOTFILES_DIR=$(dirname "$0")
CODE_DIR=~/code
mkdir -p "$CODE_DIR"


if get_confirmation "install homebrew"; then
  # install homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # install core packages
  xargs brew install < ./homebrew-packages.txt

  # remember to set up java
  # sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
fi


if get_confirmation "install neovim"; then
  NEOVIM_INSTALL_DIR=~/neovim
  mkdir -p "$NEOVIM_INSTALL_DIR"

  cd "$CODE_DIR"
  git clone git@github.com:neovim/neovim.git
  git clone git@github.com:jergason/nvim-config.git
  cd neovim
  git checkout main && git pull && git checkout stable
  make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${NEOVIM_INSTALL_DIR}" && make install
fi

if get_confirmation "install nvm"; then
  cd ~
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  nvm install --lts
fi

if get_confirmation "install fonts"; then
  cd "$CODE_DIR"
  git clone git@github.com:ryanoasis/nerd-fonts.git && cd nerd-fonts && ./install.sh
fi

if get_confirmation "install dotfiles"; then
  cd "$DOTFILES_DIR"
  # symlink .zshrc and .git_config
  ln -s .zshrc ~/.zshrc
  ln -s .gitcofig ~/.gitconfig
fi


if get_confirmation "install rust"; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
