# Shared project routing for Claude Code and Codex.
_ai_account_for_dir() {
  local code_dir="${HOME:A}/code"
  case "${1:A}" in
    "$code_dir/drplt"|"$code_dir/drplt"/*|\
    "$code_dir/drplt-worktrees"|"$code_dir/drplt-worktrees"/*|\
    "$code_dir/hiring"|"$code_dir/hiring"/*|\
    "$code_dir/ai-spend"|"$code_dir/ai-spend"/*|\
    "$code_dir/cascade"|"$code_dir/cascade"/*) print -r -- work ;;
    *) print -r -- personal ;;
  esac
}
