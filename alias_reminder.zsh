#!/usr/bin/env zsh

# Map full commands to the shortest alias that expands to that command.
typeset -gA ALIAS_MAP
ALIAS_MAP=()

build_alias_map() {
  local alias_name full_cmd existing_alias

  for alias_name full_cmd in "${(@kv)aliases}"; do
    [[ -z "$alias_name" || -z "$full_cmd" ]] && continue

    existing_alias="${ALIAS_MAP[$full_cmd]}"
    if [[ -z "$existing_alias" || ${#alias_name} -lt ${#existing_alias} ]]; then
      ALIAS_MAP["$full_cmd"]="$alias_name"
    fi
  done
}

update_alias_map() {
  ALIAS_MAP=()
  build_alias_map
}

refresh_aliases() {
  update_alias_map
  printf "alias reminder: refreshed %d aliases\n" "${#ALIAS_MAP}"
}

alias_reminder() {
  local typed_cmd="$1"
  local full_cmd alias_name
  local best_full_cmd=""
  local best_alias=""

  [[ -z "$typed_cmd" ]] && return

  # Trim leading whitespace from the command line.
  typed_cmd="${typed_cmd#"${typed_cmd%%[![:space:]]*}"}"

  for full_cmd alias_name in "${(@Qkv)ALIAS_MAP}"; do
    if [[ "$typed_cmd" == "$full_cmd" || "$typed_cmd" == "$full_cmd "* ]]; then
      if (( ${#full_cmd} > ${#best_full_cmd} )); then
        best_full_cmd="$full_cmd"
        best_alias="$alias_name"
      fi
    fi
  done

  [[ -z "$best_alias" ]] && return

  printf '\033[33mTIP:\033[0m use \033[1m%s\033[0m instead of \033[1m%s\033[0m\n' "$best_alias" "$best_full_cmd"
}

if [[ -n "$ZSH_VERSION" ]]; then
  autoload -U add-zsh-hook
  add-zsh-hook -d preexec alias_reminder 2>/dev/null
  add-zsh-hook preexec alias_reminder
  update_alias_map
fi
