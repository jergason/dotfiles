#!/usr/bin/env bash

set -eo pipefail

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

link_dotfile() {
  local source=$1 target=$2 backup
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "$target is already linked."
    return
  fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup=$(mktemp -d "${target}.bak.XXXXXX")
    mv "$target" "$backup/$(basename "$target")"
    echo "Backed up $target to $backup"
  fi
  ln -s "$source" "$target"
}

clone_if_missing() {
  local repo=$1 target=$2
  shift 2
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "$target already exists. Skipping clone."
  else
    mkdir -p "$(dirname "$target")"
    git clone "$@" "$repo" "$target"
  fi
}

nerd_fonts_installed() {
  local font_dir font_file
  for font_dir in "$HOME/Library/Fonts" /Library/Fonts \
    "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" "$HOME/.fonts" \
    /usr/local/share/fonts /usr/share/fonts; do
    [ -d "$font_dir" ] || continue
    font_file=$(find "$font_dir" -type f \( -iname '*nerd*.ttf' -o -iname '*nerd*.otf' \) -print -quit)
    if [ -n "$font_file" ]; then
      return 0
    fi
  done
  return 1
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
CODE_DIR=~/code
mkdir -p "$CODE_DIR"
# Also detect installs that this non-interactive shell has not added to PATH.
export PATH="$PATH:$HOME/neovim/bin:${CARGO_HOME:-$HOME/.cargo}/bin:$HOME/.local/bin:$HOME/bin:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin"

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [ -s "$ZSH_DIR/oh-my-zsh.sh" ]; then
  echo "Oh My Zsh is already installed."
elif get_confirmation "install Oh My Zsh"; then
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
    | ZSH="$ZSH_DIR" KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh
fi

if [ -d "$HOME/.config/ghostty/shaders" ] && [ -d "$HOME/.config/ghostty/ghostty-shader-playground" ]; then
  echo "Ghostty shaders are already installed."
elif get_confirmation "get ghostty shaders"; then
  clone_if_missing git@github.com:hackr-sh/ghostty-shaders.git "$HOME/.config/ghostty/shaders"
  clone_if_missing git@github.com:KroneCorylus/ghostty-shader-playground.git "$HOME/.config/ghostty/ghostty-shader-playground"
fi


if get_confirmation "install dotfiles"; then
  link_dotfile "${SCRIPT_DIR}/.zshrc" "$HOME/.zshrc"
  link_dotfile "${SCRIPT_DIR}/.gitconfig" "$HOME/.gitconfig"
  link_dotfile "${SCRIPT_DIR}/ghostty-config" "$HOME/.config/ghostty/config"
fi


if get_confirmation "install OpenCode plugins"; then
  for plugin_path in "${SCRIPT_DIR}"/opencode/plugins/*; do
    [ -f "$plugin_path" ] || continue
    plugin_name=$(basename "$plugin_path")
    plugin_target="${HOME}/.config/opencode/plugins/${plugin_name}"
    link_dotfile "$plugin_path" "$plugin_target"
  done
fi


if command -v brew >/dev/null 2>&1; then
  echo "Homebrew is already installed."
elif get_confirmation "install homebrew"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if command -v brew >/dev/null 2>&1 && get_confirmation "install homebrew packages"; then
  xargs brew install < "${SCRIPT_DIR}/homebrew-packages.txt"
fi

# remember to set up java
# sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk


if command -v nvim >/dev/null 2>&1; then
  echo "Neovim is already installed."
elif get_confirmation "install neovim"; then
  NEOVIM_INSTALL_DIR="$HOME/neovim"
  mkdir -p "$NEOVIM_INSTALL_DIR"

  clone_if_missing git@github.com:neovim/neovim.git "$CODE_DIR/neovim"
  (
    cd "$CODE_DIR/neovim"
    git checkout main
    git pull --ff-only
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${NEOVIM_INSTALL_DIR}"
    make install
  )
fi

if [ -d "$CODE_DIR/nvim-config" ]; then
  echo "Neovim configuration is already checked out."
elif get_confirmation "get neovim configuration"; then
  clone_if_missing git@github.com:jergason/nvim-config.git "$CODE_DIR/nvim-config"
fi

if [ -z "${NVM_DIR:-}" ]; then
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    NVM_DIR="$XDG_CONFIG_HOME/nvm"
  else
    NVM_DIR="$HOME/.nvm"
  fi
fi
export NVM_DIR
if [ -s "$NVM_DIR/nvm.sh" ]; then
  echo "nvm is already installed."
elif get_confirmation "install nvm"; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  nvm install --lts
  # allow managing yarn/pnpm/etc versions
  corepack enable
fi

if command -v claude >/dev/null 2>&1; then
  echo "Claude Code is already installed."
elif get_confirmation "install Claude Code"; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

if command -v codex >/dev/null 2>&1; then
  echo "Codex is already installed."
elif get_confirmation "install Codex"; then
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

if command -v pi >/dev/null 2>&1; then
  echo "Pi is already installed."
elif get_confirmation "install Pi"; then
  (
    # Make an existing nvm-managed Node installation available to Pi's installer.
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      . "$NVM_DIR/nvm.sh"
    fi
    curl -fsSL https://pi.dev/install.sh | sh
  )
fi

if get_confirmation "install AI instructions, skill lockfile, and Codex account links"; then
  bash "${SCRIPT_DIR}/ai/install.sh"
fi

if nerd_fonts_installed; then
  echo "Nerd Fonts are already installed."
elif get_confirmation "install fonts"; then
  clone_if_missing git@github.com:ryanoasis/nerd-fonts.git "$CODE_DIR/nerd-fonts" --depth=1
  (
    cd "$CODE_DIR/nerd-fonts"
    ./install.sh
  )
fi

if command -v rustc >/dev/null 2>&1 || command -v rustup >/dev/null 2>&1; then
  echo "Rust is already installed."
elif get_confirmation "install rust"; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

if command -v atuin >/dev/null 2>&1; then
  echo "Atuin is already installed."
elif get_confirmation "install atuin (shell history fanciness)"; then
  /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)"
fi
