#!/usr/bin/env bash
set -euo pipefail

personal_dir="$HOME/.codex"
work_dir="$HOME/.codex-work"
mkdir -p "$personal_dir/skills" "$work_dir"
chmod 700 "$work_dir"

# Refuse conflicts rather than overwrite existing account settings.
shared=(skills config.toml AGENTS.md rules hooks.json)
for name in "${shared[@]}"; do
  target="$work_dir/$name"
  if [[ -L "$target" && "$(readlink "$target")" == "$personal_dir/$name" ]]; then
    continue
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'Cannot link %s: path already exists. Move it aside and rerun.\n' "$target" >&2
    exit 1
  fi
done
for name in "${shared[@]}"; do
  target="$work_dir/$name"
  [[ -L "$target" ]] || ln -s "$personal_dir/$name" "$target"
done
printf '%s\n' 'Codex account directories ready. Run codex-work login to sign in with your business seat.'
