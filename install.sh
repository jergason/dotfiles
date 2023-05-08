#!/usr/bin/env bash

set -e

# use with get_confirmation "install rust" etc
get_confirmation() {
  echo "Do you want to $1? ([y]/n)"
  read -r user_input

  if [ -z "$user_input" ] || [ "$user_input" == "y" ] || [ "$user_input" == "Y" ]; then
    return 0
  else
    return 1
  fi
}

function backup_dotfile_if_exists() {
  if [ -e "$1" ]; then
    mv "$1" "${1}.bak"
  fi
}

echo ""
echo "┌────────────────────────┐"
echo "│                        │"
echo "│💻 Let's Get Set Up 💻  │"
echo "│                        │"
echo "└────────────────────────┘"
echo ""

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "dotfiles dir is ${SCRIPT_DIR}"
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

# we do this first so we don't mess up our about-to-be-fresh dotfiles
if get_confirmation "install ohmyzsh"; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if get_confirmation "install dotfiles"; then
  # symlink .zshrc and .git_config
  backup_dotfile_if_exists ~/.zshrc
  ln -s "${SCRIPT_DIR}/.zshrc" ~/.zshrc
  backup_dotfile_if_exists ~/.gitconfig
  ln -s "${SCRIPT_DIR}/.gitconfig" ~/.gitconfig
fi


if get_confirmation "install rust"; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
