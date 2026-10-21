#!/usr/bin/env bash
set -euo pipefail

AI_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "${AI_DIR}/link.sh"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands" "$HOME/.claude/hooks" "$HOME/.claude-work"
chmod 700 "$HOME/.claude-work"
if [[ ! -e "$HOME/.claude/settings.json" ]]; then
  printf '{}\n' > "$HOME/.claude/settings.json"
fi
for name in skills settings.json commands hooks CLAUDE.md; do
  link_file "$HOME/.claude/$name" "$HOME/.claude-work/$name"
done

LOCK_PATH="${HOME}/.agents/.skill-lock.json"
if [ -n "${XDG_STATE_HOME:-}" ]; then
  LOCK_PATH="${XDG_STATE_HOME}/skills/.skill-lock.json"
fi
link_file "${AI_DIR}/../skills/.skill-lock.json" "$LOCK_PATH"
link_file "${AI_DIR}/AGENTS.md" "${HOME}/.claude/CLAUDE.md"
link_file "${HOME}/.claude/CLAUDE.md" "${HOME}/.agents/AGENTS.md"
link_file "${HOME}/.agents/AGENTS.md" "${HOME}/.codex/AGENTS.md"

bash "${AI_DIR}/install-codex-accounts.sh"

# The full dotfiles .zshrc already loads these. Also support a minimal shell.
touch "$HOME/.zshrc"
for name in claude codex; do
  if ! grep -Fq "ai/${name}_account.zsh" "$HOME/.zshrc"; then
    printf '\n# Project-specific %s account selection (dotfiles).\nsource %q\n' \
      "$name" "$AI_DIR/${name}_account.zsh" >> "$HOME/.zshrc"
  fi
done
printf '%s\n' 'AI configuration ready. Open a new terminal or run: source ~/.zshrc'
