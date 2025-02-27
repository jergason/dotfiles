#!/usr/bin/env zsh

# Enable extended glob patterns for zsh
setopt extendedglob

# Function to build a mapping of commands to their aliases
build_alias_map() {
  # Loop through all aliases and extract the command part
  alias | while read -r alias_def; do
    # Remove 'alias ' prefix
    local def=${alias_def#alias }
    
    # Split at the equals sign
    local name=${def%%=*}
    local cmd=${def#*=}
    
    # Remove surrounding quotes
    cmd=${cmd#\'}
    cmd=${cmd%\'}
    
    # Output in a format we can parse later
    echo "$cmd:$name"
  done
}

# Initialize the alias map
typeset -A ALIAS_MAP
ALIAS_MAP=()

# Function to update the alias map
update_alias_map() {
  # Clear existing map
  ALIAS_MAP=()

  # Build the map
  while IFS=: read -r cmd name; do
    ALIAS_MAP["$cmd"]="$name"
  done < <(build_alias_map)
}

# Function to check if a command has an alias
alias_reminder() {
  local cmd="$1"

  # Skip if command is too short (likely not a full command)
  if [[ ${#cmd} -lt 5 ]]; then
    return
  fi

  # Check if the command matches any known alias
  for full_cmd in "${!ALIAS_MAP[@]}"; do
    # If the command starts with the full command that has an alias
    if [[ "$cmd" == "$full_cmd"* || "$cmd" == "$full_cmd" ]]; then
      echo -e "\033[33mTIP: You could have used the alias \033[1m${ALIAS_MAP[$full_cmd]}\033[0;33m instead of \033[1m$full_cmd\033[0m"
      return
    fi
  done
}

# Set up the preexec hook to check commands before execution
if [[ -n "$ZSH_VERSION" ]]; then
  # ZSH specific setup
  autoload -U add-zsh-hook
  add-zsh-hook preexec alias_reminder
else
  # Bash fallback using PROMPT_COMMAND
  if [[ -z "$PROMPT_COMMAND" ]]; then
    PROMPT_COMMAND="alias_reminder \"\$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//g')\""
  else
    PROMPT_COMMAND="$PROMPT_COMMAND; alias_reminder \"\$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//g')\""
  fi
fi
