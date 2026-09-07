# picks the right claude config dir based on $PWD
# work dirs use ~/.claude-work, everything else uses default ~/.claude
#
# GOTCHA: not every plugin's CLI honors CLAUDE_CONFIG_DIR. evo (evo-hq/evo)
# is the known offender: `evo doctor claude-code` always reads ~/.claude/,
# so it'll report "cache up to date" against a stale version while the
# actually-running claude (using ~/.claude-work/) has a broken plugin.
#
# symptom: SessionStart hook error on claude startup —
#   "evo-hook-drain: No such file or directory"
# cause: v0.4.1+ ships the hook as a rust binary fetched from gh releases
# at install time, and that fetch never lands in the .claude-work cache.
# observed on 0.4.1 and again on 0.4.2 — assume every evo bump will repeat.
#
# fix: run `fix-evo-hook` (defined below). because the multi-claude setup has
# TWO config dirs (~/.claude personal + ~/.claude-work) and the broken plugin
# can be any cached version (the active one isn't always the newest — alpha
# tags sort weird, and personal/work pin different versions), it sweeps every
# config dir x every cached version and fetches the binary wherever it's
# missing. pass -f/--force to re-fetch even where it already exists.
fix-evo-hook() {
  local force="" found=0
  [[ "$1" == "-f" || "$1" == "--force" ]] && force=", force=True"
  for cache in "$HOME"/.claude*/plugins/cache/evo-hq-evo/evo; do
    [[ -d "$cache" ]] || continue
    for verdir in "$cache"/*/; do
      [[ -f "$verdir/pyproject.toml" ]] || continue
      if [[ -z "$force" && -f "$verdir/bin/evo-hook-drain" ]]; then continue; fi
      found=1
      echo "fixing evo hook drain in $verdir"
      ( cd "$verdir" && uv run --project . python -c "from pathlib import Path; from evo.host_install._hook_drain import ensure_hook_drain_binary; ensure_hook_drain_binary(Path('.').resolve()$force)" )
    done
  done
  [[ "$found" == 0 ]] && echo "nothing to fix (all hook binaries present; -f to force)"
  return 0
}

_claude_config_for_pwd() {
  case "$PWD" in
    "$HOME/code/drplt"|"$HOME/code/drplt"/*) echo "$HOME/.claude-work" ;;
    "$HOME/code/drplt-worktrees"|"$HOME/code/drplt-worktrees"/*) echo "$HOME/.claude-work" ;;
    "$HOME/code/hiring"|"$HOME/code/hiring"/*) echo "$HOME/.claude-work" ;;
    "$HOME/code/ai-spend"|"$HOME/code/ai-spend"/*) echo "$HOME/.claude-work" ;;
    "$HOME/code/cascade"|"$HOME/code/cascade"/*) echo "$HOME/.claude-work" ;;
    *) echo "$HOME/.claude" ;;
  esac
}

claude() {
  local dir="$(_claude_config_for_pwd)"
  local label
  case "$dir" in
    *-work) label="Droplet" ;;
    *)      label="personal" ;;
  esac
  print -P "%F{cyan}claude:%f account=$label config=$dir" >&2
  CLAUDE_CONFIG_DIR="$dir" command claude "$@"
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
