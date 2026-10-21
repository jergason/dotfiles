#!/usr/bin/env bash
set -euo pipefail

AI_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "${AI_DIR}/link.sh"

personal_dir="$HOME/.codex"
work_dir="$HOME/.codex-work"
mkdir -p "$personal_dir/skills" "$personal_dir/rules" "$work_dir"
touch "$personal_dir/config.toml"
chmod 700 "$work_dir"

# Repair copied links and preserve any replaced settings in backups.
shared=(skills config.toml AGENTS.md rules hooks.json)
for name in "${shared[@]}"; do
  target="$work_dir/$name"
  [[ -e "$personal_dir/$name" ]] || continue
  link_file "$personal_dir/$name" "$target"
done
printf '%s\n' 'Codex account directories ready. Run codex-work login to sign in with your business seat.'
