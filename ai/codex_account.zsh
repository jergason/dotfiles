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

_codex_uses_runtime_config() {
  while (( $# )); do
    case "$1" in
      --) return 0 ;;
      -c|--config|-C|--cd|-m|--model|-i|--image|-s|--sandbox|-a|--ask-for-approval|--add-dir|--enable|--disable|--remote|--remote-auth-token-env)
        (( $# > 1 )) || return 0
        shift 2 ;;
      -*) shift ;;
      login|logout|doctor|features|agents|plugin|app|app-server|remote-control|completion|update|exec-server|apply|migrate-rollouts|cloud|help)
        return 1 ;;
      debug) [[ "$2" == prompt-input ]]; return ;;
      *) return 0 ;;
    esac
  done
  return 0
}

_codex_run_account() {
  local account="$1" dir arg
  local -a profile_args
  shift
  dir="$(_codex_account_home "$account")" || return
  if [[ ! -d "$dir" ]]; then
    print -u2 -- "codex: missing $dir; run bash ~/code/dotfiles/ai/install.sh"
    return 1
  fi
  print -ru2 -- "codex: account=$account home=$dir (selected login store)"
  # CLI settings are a named layer; Codex does not load cli.config.toml by default.
  profile_args=()
  if [[ -f "$dir/cli.config.toml" ]] && _codex_uses_runtime_config "$@"; then
    profile_args=(--profile cli)
  fi
  for arg in "$@"; do
    case "$arg" in
      --) break ;;
      -p|--profile|--profile=*|-p?*) profile_args=(); break ;;
    esac
  done
  # File storage keeps each login in its own home. Require subscription login.
  CODEX_HOME="$dir" command codex "${profile_args[@]}" \
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
