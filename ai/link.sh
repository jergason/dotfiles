#!/usr/bin/env bash

# Keep replaced files and stale links so an installation can be undone.
link_file() {
  local source=$1 target=$2 backup
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi
  if [[ "${CHECK_ONLY:-false}" == true ]]; then
    return 1
  fi
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    backup=$(mktemp -d "${target}.bak.XXXXXX")
    mv "$target" "$backup/$(basename "$target")"
    printf 'Backed up %s to %s\n' "$target" "$backup"
  fi
  ln -s "$source" "$target"
}
