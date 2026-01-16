# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

personal dotfiles repo for macos. symlinks config files to home directory via `install.sh`.

## Structure

- `.zshrc` - zsh config, uses oh-my-zsh with lambda theme, vi-mode plugin
- `.gitconfig` - git aliases (co, ci, st, br, lg, grog)
- `ghostty-config` - terminal config for ghostty, includes optional shader support
- `tmux.conf` - tmux config, ctrl-a prefix, vi keys, mouse support
- `alias_reminder.zsh` - preexec hook that suggests aliases when you type full commands
- `shaders/` - submodule/collection of glsl shaders for ghostty terminal effects
- `homebrew-packages.txt` - list of brew packages to install
- `install.sh` - interactive setup script, prompts for each component

## Installation

```bash
./install.sh
```

the script is interactive - it asks before each step (dotfiles, homebrew, neovim, nvm, fonts, ohmyzsh, rust, atuin).

symlinks created:
- `~/.zshrc` -> this repo's `.zshrc`
- `~/.gitconfig` -> this repo's `.gitconfig`
- `~/.config/ghostty/config` -> this repo's `ghostty-config`
- `~/.tmux.conf` -> this repo's `tmux.conf`

## Key Aliases

shell (in .zshrc):
- `gpu` - `git push -u origin head`
- `gpf` - `git push -f origin head`
- `gca` - `git commit --amend --no-edit`
- `gitclean` - delete merged branches

git (in .gitconfig):
- `co`, `ci`, `st`, `br` - standard shortcuts
- `lg`, `grog` - pretty log graphs

## Local Overrides

put machine-specific stuff in `~/.zshrc.local` - it gets sourced if it exists.
