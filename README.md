# Dotfiles

Let's get a new compy set up! To run, execute `install.sh`.

## Shared AI configuration

Run `bash ai/install.sh` to install the AI configuration links independently, or select the AI step in `install.sh`. This also runs `ai/install-codex-accounts.sh`. The AI installer backs up existing instruction and lockfile paths; the Codex account installer stops if a shared link would replace an existing file.

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
mkdir -p ~/.claude-work
cd ~/.claude-work
for x in skills settings.json commands hooks CLAUDE.md; do
  ln -s ~/.claude/$x $x
done
cd ~/code/drplt && claude   # log in with the business account
```

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
