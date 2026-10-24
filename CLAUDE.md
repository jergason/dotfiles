# Repository guide

Personal macOS dotfiles. `install.sh` links config files into the home directory. See [README.md](README.md) for setup and account login commands.

## Files

| Path | Purpose |
| --- | --- |
| `.zshrc` | Zsh config with Oh My Zsh, the lambda theme, and vi-mode |
| `.gitconfig` | Git aliases and defaults |
| `ghostty-config` | Ghostty config and optional shaders |
| `ghostty-themes.zsh` | Loads the `themes` command from `bin/ghostty-themes` |
| `alias_reminder.zsh` | Suggests aliases before commands run |
| `gitclean.zsh` | Defines the `gitclean` branch cleanup command |
| `shaders/` | GLSL shaders for Ghostty |
| `homebrew-packages.txt` | Homebrew formulae |
| `homebrew-casks.txt` | macOS apps |
| `hammerspoon/` | Window layouts and agent browser placement |
| `ai/` | Shared agent instructions, account wrappers, and installers |
| `install.sh` | Interactive setup |

## Commands

`.zshrc` defines these commands:

| Command | Expansion or behavior |
| --- | --- |
| `gpu` | `git push -u origin HEAD` |
| `gpf` | `git push --force-with-lease origin HEAD` |
| `gca` | `git commit --amend --no-edit` |
| `gitclean` | Reports branches safe to delete. Add `--apply` to delete them. |

`.gitconfig` defines `co`, `ci`, and `st` for checkout, commit, and status. `lg` and `grog` show log graphs.

## Local overrides

`.zshrc` loads `~/.zshrc.local` when it exists. Put machine-specific settings there.
