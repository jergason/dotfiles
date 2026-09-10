# Separate login/session stores, with shared settings and skills.
source "${${(%):-%N}:A:h}/ai_account.zsh"

_codex_account_for_args() {
  local dir="$PWD" arg
  while (( $# )); do
    arg="$1"
    shift
    case "$arg" in
      --) break ;;
      -C|--cd)
        (( $# )) || { print -u2 -- "codex: $arg needs a directory"; return 2; }
        dir="$1"
        shift ;;
      --cd=*) dir="${arg#--cd=}" ;;
      -C?*) dir="${arg#-C}" ;;
    esac
  done
  _ai_account_for_dir "$dir"
}

_codex_account_home() {
  case "$1" in
    work) print -r -- "$HOME/.codex-work" ;;
    personal) print -r -- "$HOME/.codex" ;;
    *) print -u2 -- "codex: unknown account: $1"; return 2 ;;
  esac
}

_codex_run_account() {
  local account="$1" dir
  shift
  dir="$(_codex_account_home "$account")" || return
  if [[ ! -d "$dir" ]]; then
    print -u2 -- "codex: missing $dir; run bash ~/code/dotfiles/ai/install.sh"
    return 1
  fi
  print -ru2 -- "codex: account=$account home=$dir (selected login store)"
  # File storage keeps each login in its own home. Require subscription login.
  CODEX_HOME="$dir" command codex \
    -c 'cli_auth_credentials_store="file"' -c 'forced_login_method="chatgpt"' "$@"
}

codex() {
  local account
  account="$(_codex_account_for_args "$@")" || return
  _codex_run_account "$account" "$@"
}

codex-work() { _codex_run_account work "$@"; }
codex-personal() { _codex_run_account personal "$@"; }

codex-whoami() {
  local account dir
  account="$(_codex_account_for_args "$@")" || return
  dir="$(_codex_account_home "$account")" || return
  print -r -- "account: $account (selected login store)"
  print -r -- "Codex home: $dir"
  [[ -d "$dir" ]] || return 1
  CODEX_HOME="$dir" command codex login status -c 'cli_auth_credentials_store="file"'
}
