# Shared project routing for Claude Code and Codex.
_ai_account_for_dir() {
  local code_dir="${HOME:A}/code"
  case "${1:A}" in
    "$code_dir/drplt"|"$code_dir/drplt"/*|\
    "$code_dir/drplt-worktrees"|"$code_dir/drplt-worktrees"/*|\
    "$code_dir/hiring"|"$code_dir/hiring"/*|\
    "$code_dir/ai-spend"|"$code_dir/ai-spend"/*|\
    "$code_dir/skills"|"$code_dir/skills"/*|\
    "$code_dir/skills-internal"|"$code_dir/skills-internal"/*|\
    "$code_dir/Cascade"|"$code_dir/Cascade"/*) print -r -- work ;;
    *) print -r -- personal ;;
  esac
}
