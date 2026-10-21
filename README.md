# Dotfiles

Let's get a new compy set up! To run, execute `install.sh`.

The installer skips tools and Nerd Fonts that are already installed. It reuses existing source checkouts and leaves correct configuration links in place. Homebrew package installation remains a separate option.

Oh My Zsh setup runs before the dotfile links and preserves an existing `.zshrc`. Claude Code, Codex, and the Pi coding agent each have an optional install step, followed by shared AI configuration. These steps use the official [Oh My Zsh installer](https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh), [Claude Code installer](https://code.claude.com/docs/en/setup), [Codex installer](https://learn.chatgpt.com/docs/codex/cli), and [Pi installer](https://pi.dev/docs/latest/quickstart).

## Try Ghostty themes

Open a new shell, or run `source ~/code/dotfiles/ghostty-themes.zsh` in your current shell. The helper requires Python 3 and Ghostty.

```sh
themes                                  # Open the interactive browser
themes browse dark                      # Browse dark themes
themes list                             # Show favorites
themes random                           # Choose a light and a dark favorite
themes random dark                      # Change only the dark theme
themes next                             # Move through both lists in order
themes previous light                   # Move back through light favorites
themes add dark "Catppuccin Frappe"      # Save an installed theme as a favorite
themes remove dark "Catppuccin Frappe"   # Remove a favorite
```

After a theme change, press `Ctrl+A`, then `R` in Ghostty to reload the config.

Favorites are in `ghostty-favorites.json`, with separate light and dark lists. Edit the file to reorder them. Each list must retain at least one theme. Random selection skips the current theme when another installed favorite is available. Cycling skips favorites that are absent from the installed Ghostty version.

The helper updates the `theme` line in this checkout's `ghostty-config`. The dotfiles installer links that file to `~/.config/ghostty/config`. Theme choices and favorites appear in your Git diff. Commands default to both modes, while `light` or `dark` changes only that mode. macOS still controls which mode Ghostty displays.

## Shared AI configuration

Run `bash ai/install.sh` to install the Claude and Codex configuration links independently, or select the AI step in `install.sh`. This also runs `ai/install-codex-accounts.sh`. The installer repairs copied symlinks and backs up each replaced file, directory, or link beside its original path. Running it again leaves correct links in place. It also loads the account wrappers from `~/.zshrc` when they are absent.

- `skills/.skill-lock.json` tracks the agent skills. The installer links it from `~/.agents/.skill-lock.json`, or `$XDG_STATE_HOME/skills/.skill-lock.json` when that variable is set.
- `ai/AGENTS.md` contains the shared global instructions. `~/.claude/CLAUDE.md` points to it. `~/.agents/AGENTS.md` and `~/.codex/AGENTS.md` retain their links through that file.

Skill updates modify the tracked lockfile through the symlink. Review and commit those changes when you update skills.

## Claude Code and Codex multi-account setup

`ai/claude_account.zsh` and `ai/codex_account.zsh` wrap their CLIs to select an account directory based on `$PWD`.

Work-related directories, as listed in `ai/ai_account.zsh`, go to the business account. Others go to the personal account.

Each config dir holds its own auth, session history, projects, memory, todos, usage clock, and plugin registry. Shared bits (`skills/`, `settings.json`, `commands/`, `hooks/`, `CLAUDE.md`) are symlinked from `~/.claude-work` back to `~/.claude` so changes apply to both accounts.

Do not symlink `plugins/` between config dirs. Claude Code stores absolute marketplace and plugin install paths under the active `CLAUDE_CONFIG_DIR`, so a shared plugin registry will look corrupted from the other account.

### One-time setup on a new machine

```bash
bash ~/code/dotfiles/ai/install.sh
source ~/.zshrc
claude-personal auth login
claude-work auth login
```

Copied Claude configuration does not include macOS Keychain credentials. Sign in once per account on the new machine.

Install plugins separately per account with `claude-personal ...` or `claude-work ...`.

## Codex multi-account setup

`ai/codex_account.zsh` selects `~/.codex-work` for business projects and `~/.codex` elsewhere.

Run the setup, then sign in once with your business seat:

```bash
bash ~/code/dotfiles/ai/install.sh
source ~/code/dotfiles/ai/codex_account.zsh
codex-work login
codex-work login status
```

Choose the business workspace during sign-in. Your existing `~/.codex` login remains personal. Use `codex-personal login` if you need to sign in again with your personal seat.

- `codex` selects the account for the project.
- `codex-work` and `codex-personal` select an account regardless of directory.
- `codex-whoami` prints the selected account directory and checks its login status.

The installer links `skills/`, `config.toml`, `AGENTS.md`, `rules/`, and `hooks.json` from the business directory to `~/.codex`. User skills in `~/.agents/skills` are also shared automatically. Install plugins separately in each account directory if you need their bundled skills in both. Authentication, session history, and plugin state remain separate. The wrapper selects file-based credentials and ChatGPT login so each directory has its own subscription login. Settings and hooks that contain absolute paths keep those paths when shared. Store account-specific overrides in separate profile files within each Codex home.

### Check account routing

```zsh
cd ~/code/drplt
claude-whoami
codex-whoami
cd ~/code/dotfiles
claude-whoami
codex-whoami
```

The first directory selects work. The second selects personal. `codex -C ~/code/drplt` also selects work.
Shell wrappers apply to terminal launches. Desktop apps use their own active account.
When an account directory contains `cli.config.toml`, the wrapper selects `--profile cli` for runtime commands and `codex mcp`.
Utility commands such as `login` and `doctor` use the base configuration because Codex rejects profiles for those commands.
An explicit `--profile` or `-p` selects that profile instead.
