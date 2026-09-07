# `gitclean` keeps local Git branches tidy without treating squash merges as
# unmerged work. Source this from .zshrc; it defines a dry-run-first command.

function gitclean() {
  local apply=false
  local remote=origin
  local base=main
  local pr_limit=1000

  while (( $# > 0 )); do
    case "$1" in
      --apply) apply=true ;;
      --remote)
        (( $# >= 2 )) || { print -u2 'gitclean: --remote needs a value'; return 1; }
        remote=$2
        shift
        ;;
      --base)
        (( $# >= 2 )) || { print -u2 'gitclean: --base needs a value'; return 1; }
        base=$2
        shift
        ;;
      --pr-limit)
        (( $# >= 2 )) || { print -u2 'gitclean: --pr-limit needs a value'; return 1; }
        [[ $2 == <-> ]] && (( $2 > 0 )) || { print -u2 'gitclean: --pr-limit must be a positive integer'; return 1; }
        pr_limit=$2
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: gitclean [--apply] [--remote REMOTE] [--base BRANCH] [--pr-limit COUNT]

Find local branches that are safe to remove.

Without --apply, prints a dry-run report. With --apply, force-deletes only
branches verified by either Git ancestry or a patch match to a merged GitHub PR.

Options:
  --apply             Delete verified branches after printing the report.
  --remote REMOTE     Git remote to fetch and compare. Default: origin.
  --base BRANCH       Base branch and PR base. Default: main.
  --pr-limit COUNT    Number of recent merged PRs to inspect. Default: 1000.
  -h, --help          Show this help.

Requires: git, gh, jq. Branches checked out by another worktree are skipped.
EOF
        return 0
        ;;
      *)
        print -u2 -- "gitclean: unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { print -u2 'gitclean: run this inside a Git worktree'; return 1; }
  command -v gh >/dev/null || { print -u2 'gitclean: gh is required'; return 1; }
  command -v jq >/dev/null || { print -u2 'gitclean: jq is required'; return 1; }
  git remote get-url "$remote" >/dev/null 2>&1 || { print -u2 -- "gitclean: missing remote $remote"; return 1; }

  print "Refreshing $remote..."
  git fetch "$remote" --prune || { print -u2 -- "gitclean: could not refresh $remote"; return 1; }

  local base_ref="$remote/$base"
  git show-ref --verify --quiet "refs/remotes/$base_ref" || { print -u2 -- "gitclean: missing $base_ref"; return 1; }

  local current_branch
  current_branch=$(git branch --show-current)

  local pr_data
  pr_data=$(gh pr list --state merged --base "$base" --limit "$pr_limit" --json number,headRefName,mergeCommit) || { print -u2 'gitclean: could not read merged GitHub PRs'; return 1; }

  # Head name, PR number, and squash-merge commit. A name can occur in many PRs.
  local pr_table
  pr_table=$(print -r -- "$pr_data" | jq -r '.[] | select(.mergeCommit != null) | [.headRefName, (.number | tostring), .mergeCommit.oid] | @tsv') || { print -u2 'gitclean: could not parse merged GitHub PRs'; return 1; }

  local -A candidate_reasons
  local -a local_branches candidate_branches checked_out skipped deleted failed
  local_branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads | sort)}")

  local branch pr_records branch_base branch_patch pr_branch pr_number merge_commit merge_parent merge_patch
  for branch in "${local_branches[@]}"; do
    [[ $branch == "$current_branch" || $branch == "$base" ]] && continue

    if git merge-base --is-ancestor "$branch" "$base_ref"; then
      candidate_reasons[$branch]='already reachable from base'
      continue
    fi

    pr_records=$(print -r -- "$pr_table" | awk -F '\t' -v branch="$branch" '$1 == branch { print }')
    [[ -n $pr_records ]] || continue

    branch_base=$(git merge-base "$base_ref" "$branch") || continue
    branch_patch=$(git diff "$branch_base" "$branch" | git patch-id --stable | awk '{ print $1 }')
    [[ -n $branch_patch ]] || continue

    while IFS=$'\t' read -r pr_branch pr_number merge_commit; do
      merge_parent=$(git rev-parse "$merge_commit^" 2>/dev/null) || continue
      merge_patch=$(git diff "$merge_parent" "$merge_commit" | git patch-id --stable | awk '{ print $1 }')
      if [[ $branch_patch == "$merge_patch" ]]; then
        candidate_reasons[$branch]="matches squash-merged PR #$pr_number"
        break
      fi
    done <<< "$pr_records"
  done

  candidate_branches=("${(@ok)candidate_reasons}")
  if (( ${#candidate_branches} == 0 )); then
    print 'No verified local branches found. The coop is already tidy.'
    return 0
  fi

  print
  print "Verified local branches (${#candidate_branches}):"
  for branch in "${candidate_branches[@]}"; do
    print "  $branch  (${candidate_reasons[$branch]})"
  done

  if [[ $apply != true ]]; then
    print
    print 'Dry run only. Re-run with --apply to delete these branches.'
    return 0
  fi

  checked_out=("${(@f)$(git worktree list --porcelain | awk '$1 == "branch" { sub("refs/heads/", "", $2); print $2 }')}")
  for branch in "${candidate_branches[@]}"; do
    if (( ${checked_out[(Ie)$branch]} )); then
      skipped+=("$branch")
      continue
    fi

    if git branch -D -- "$branch"; then
      deleted+=("$branch")
    else
      failed+=("$branch")
    fi
  done

  print
  print "Deleted ${#deleted} verified local branches."
  (( ${#skipped} == 0 )) || print "Skipped ${#skipped} branch(es) checked out by another worktree: ${skipped[*]}"
  (( ${#failed} == 0 )) || print -u2 "Could not delete ${#failed} branch(es): ${failed[*]}"
  (( ${#failed} == 0 ))
}
