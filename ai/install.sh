#!/usr/bin/env bash
set -euo pipefail

AI_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

link_file() {
  local source=$1 target=$2 backup
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup=$(mktemp "${target}.bak.XXXXXX")
    mv "$target" "$backup"
    echo "Backed up $target to $backup"
  fi
  ln -s "$source" "$target"
}

LOCK_PATH="${HOME}/.agents/.skill-lock.json"
if [ -n "${XDG_STATE_HOME:-}" ]; then
  LOCK_PATH="${XDG_STATE_HOME}/skills/.skill-lock.json"
fi
link_file "${AI_DIR}/../skills/.skill-lock.json" "$LOCK_PATH"
link_file "${AI_DIR}/AGENTS.md" "${HOME}/.claude/CLAUDE.md"
link_file "${HOME}/.claude/CLAUDE.md" "${HOME}/.agents/AGENTS.md"
link_file "${HOME}/.agents/AGENTS.md" "${HOME}/.codex/AGENTS.md"

bash "${AI_DIR}/install-codex-accounts.sh"
