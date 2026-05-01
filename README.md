# Dotfiles

Let's get a new compy set up!

Mostly optimized for macos.

To run, execute `install.sh`.

## Claude Code multi-account setup

`claude_account.zsh` wraps the `claude` CLI so it auto-picks a config dir based on `$PWD`:

- inside `~/code/drplt` or `~/code/hiring` (and subdirs) → uses `~/.claude-work` (business account)
- everywhere else → uses `~/.claude` (personal account)

Each config dir holds its own auth, session history, projects, memory, todos, and usage clock. Shared bits (`skills/`, `settings.json`, `commands/`, `hooks/`, `plugins/`, `CLAUDE.md`) are symlinked from `~/.claude-work` back to `~/.claude` so changes apply to both accounts.

### One-time setup on a new machine

```bash
mkdir -p ~/.claude-work
cd ~/.claude-work
for x in skills settings.json commands hooks plugins CLAUDE.md; do
  ln -s ~/.claude/$x $x
done
cd ~/code/drplt && claude   # log in with the business account
```

### Commands

- `claude` — directory-aware, picks the right account automatically
- `claude-work` — force the business account regardless of cwd
- `claude-personal` — force the personal account regardless of cwd
- `claude-whoami` — print which account the current dir resolves to

### How it works

`CLAUDE_CONFIG_DIR` env var redirects everything Claude Code stores (including `.claude.json`) into the named directory. The shell function sets that var before invoking `command claude`, so each launch lands in the right config dir without polluting the other account's state.

## TO DO
