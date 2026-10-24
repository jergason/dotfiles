# Dotfiles

Let's get a new compy set up! Run from this checkout:

```sh
./install.sh
```

The installer prompts for incomplete steps and skips completed ones. It reuses existing checkouts and keeps correct symlinks. It installs missing Homebrew packages and backs up files before replacing them with links.

Oh My Zsh setup runs before the dotfile links and preserves an existing `.zshrc`. Claude Code, Codex, and Pi have separate install steps before shared AI configuration.

- `homebrew-packages.txt` lists command-line packages.
- `homebrew-casks.txt` lists macOS apps, including Hammerspoon.
- [Hammerspoon setup](hammerspoon/README.md#install-and-check-hammerspoon) covers permissions and window automation.

Put machine-specific shell settings in `~/.zshrc.local`.

## Open Droplet branches and PRs in Ghostty

The launcher lives in `~/code/drplt-open`. Follow that checkout's README, then run `pnpm install` and `pnpm build` there.

Open a new shell, or load the alias:

```zsh
source ~/code/dotfiles/drplt-open.zsh
drplt-open          # Browse PRs or enter a branch or URL
drplt-open --help   # Show options and keyboard controls
```

The alias runs `~/code/drplt-open/dist/cli.js`. Rebuild after launcher source changes. The Droplet app checkout is `~/code/drplt`.

## Change Ghostty themes

The `themes` helper requires Python 3 and Ghostty. Open a new shell, or run `source ~/code/dotfiles/ghostty-themes.zsh`.

```zsh
themes                                  # Open the theme browser
themes browse dark                      # Browse dark themes
themes list                             # Show favorites
themes random                           # Choose a light and a dark favorite
themes random dark                      # Change only the dark theme
themes next                             # Cycle through both lists
themes previous light                   # Move back through light favorites
themes add dark "Catppuccin Frappe"      # Add an installed theme to favorites
themes remove dark "Catppuccin Frappe"   # Remove a favorite
```

After a change, press `Ctrl+A`, then `R` to reload Ghostty.

Favorites live in `ghostty-favorites.json`. Edit it to reorder the light and dark lists. Keep at least one theme in each list. Selection skips themes missing from your Ghostty version. Random selection avoids the current theme when another favorite is available.

Commands default to both modes. Use `light` or `dark` to change one. macOS controls which mode Ghostty displays.

The helper edits this checkout's `ghostty-config`, linked to `~/.config/ghostty/config` by the installer. Theme and favorite changes appear in your Git diff. See the [Ghostty browser investigation](NEXT_STEPS.md) for a previously diagnosed freeze.

## Set up shared AI configuration

Select the AI configuration step in `install.sh`, or run it separately:

```sh
bash ai/install.sh
source ~/.zshrc
```

The installer repairs stale symlinks and backs up replaced files beside their original paths. It adds missing account wrappers to `~/.zshrc` and runs `ai/install-codex-accounts.sh`. Later runs keep correct links.

To check setup without changing files, run `bash ai/install.sh --check`. It exits with status 0 when complete and 1 when work remains.

| Tracked file | Installed links |
| --- | --- |
| `skills/.skill-lock.json` | `~/.agents/.skill-lock.json`, or `$XDG_STATE_HOME/skills/.skill-lock.json` when set |
| `ai/AGENTS.md` | `~/.claude/CLAUDE.md`, then `~/.agents/AGENTS.md`, then `~/.codex/AGENTS.md` |

Skill updates modify the tracked lockfile through its symlink. Review and commit those changes.

## Use work and personal AI accounts

The wrappers in `ai/claude_account.zsh` and `ai/codex_account.zsh` select an account by project directory. `ai/ai_account.zsh` lists work directories. All others use personal accounts.

| Command | Account selection |
| --- | --- |
| `claude`, `codex` | Current project directory |
| `claude-work`, `codex-work` | Work |
| `claude-personal`, `codex-personal` | Personal |
| `claude-whoami`, `codex-whoami` | Show the selected account directory. Codex also checks login status. |

Work accounts use `~/.claude-work` and `~/.codex-work`. Personal accounts use `~/.claude` and `~/.codex`. These wrappers apply to terminal launches. Desktop apps use their own active account.

### Sign in on a new machine

After AI setup, sign in to each account:

```zsh
claude-personal auth login
claude-work auth login
codex-work login
codex-work login status
```

Copied Claude config does not include macOS Keychain credentials. Sign in once per account on the new machine.

For Codex, choose the business workspace during work sign-in. An existing `~/.codex` login stays personal. Use `codex-personal login` to sign in to that account again. The wrapper requires ChatGPT login and stores credentials in each account directory.

### Shared settings and separate plugins

The installer links these files from each work directory to its personal directory:

| Agent | Shared files and directories |
| --- | --- |
| Claude Code | `skills/`, `settings.json`, `commands/`, `hooks/`, `CLAUDE.md` |
| Codex | `skills/`, `config.toml`, `AGENTS.md`, `rules/`, `hooks.json` when present |

Codex also shares user skills in `~/.agents/skills`. Each account keeps its own authentication, session history, and plugin state.

Install plugins separately per account. Do not symlink Claude's `plugins/` directory between accounts. Its registry stores absolute paths under `CLAUDE_CONFIG_DIR`.

Shared settings and hooks keep their absolute paths. Put Codex account-specific overrides in separate profile files within each Codex home.

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

When an account directory contains `cli.config.toml`, the Codex wrapper adds `--profile cli` for runtime commands and `codex mcp`. Utility commands such as `login` and `doctor` use the base config. An explicit `--profile` or `-p` takes precedence.
