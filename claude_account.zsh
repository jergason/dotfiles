# picks the right claude config dir based on $PWD
# work dirs use ~/.claude-work, everything else uses default ~/.claude

_claude_config_for_pwd() {
  case "$PWD" in
    "$HOME/code/drplt"|"$HOME/code/drplt"/*) echo "$HOME/.claude-work" ;;
    "$HOME/code/hiring"|"$HOME/code/hiring"/*) echo "$HOME/.claude-work" ;;
    *) echo "$HOME/.claude" ;;
  esac
}

claude() {
  CLAUDE_CONFIG_DIR="$(_claude_config_for_pwd)" command claude "$@"
}

# manual overrides for when cwd-detection isn't right
alias claude-work="CLAUDE_CONFIG_DIR=$HOME/.claude-work command claude"
alias claude-personal="CLAUDE_CONFIG_DIR=$HOME/.claude command claude"

# sanity check which account the current dir resolves to
claude-whoami() {
  local d="$(_claude_config_for_pwd)"
  case "$d" in
    *-work) echo "account: WORK (drplt/hiring)" ;;
    *)      echo "account: personal" ;;
  esac
  echo "config dir: $d"
}
