function gdu {
  local pager
  pager="${GIT_PAGER:-$(git config --get core.pager 2>/dev/null)}"
  [[ -n "$pager" ]] || pager="${PAGER:-less}"

  {
    git --no-pager diff --diff-filter=d "$@"
    git --no-pager diff --diff-filter=D --name-status "$@"
    git ls-files --others --exclude-standard -z -- "$@" | while IFS= read -r -d '' file; do
      git --no-pager diff --no-index -- /dev/null "$file" || true
    done
  } | ${(z)pager}
}

function _gdl_sum_numstat {
  awk '
    $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ {
      additions += $1
      deletions += $2
    }
    END { printf "+%d -%d\n", additions + 0, deletions + 0 }
  '
}

function _gdl_untracked_numstat {
  local file

  git ls-files --others --exclude-standard -z -- "$@" |
    while IFS= read -r -d '' file; do
      git diff --no-index --numstat -- /dev/null "$file" 2>/dev/null || true
    done
}

function gdl {
  emulate -L zsh

  local base="${GDL_BASE:-origin/main}"
  local merge_base
  local staged unstaged untracked local_total committed pr_total

  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    print -u2 'gdl: not inside a git repository'
    return 1
  fi

  if [[ "${1-}" == '--' ]]; then
    shift
  fi

  staged="$(git diff --cached --numstat -- "$@" | _gdl_sum_numstat)"
  unstaged="$(git diff --numstat -- "$@" | _gdl_sum_numstat)"
  untracked="$(_gdl_untracked_numstat "$@" | _gdl_sum_numstat)"
  local_total="$(
    {
      git diff HEAD --numstat -- "$@"
      _gdl_untracked_numstat "$@"
    } | _gdl_sum_numstat
  )"

  print 'Local working tree'
  printf '  %-30s %s\n' 'staged (HEAD -> index)' "$staged"
  printf '  %-30s %s\n' 'unstaged (index -> tree)' "$unstaged"
  printf '  %-30s %s\n' 'untracked' "$untracked"
  printf '  %-30s %s\n' 'total (HEAD -> tree)' "$local_total"

  if ! merge_base="$(git merge-base "$base" HEAD 2>/dev/null)"; then
    print -u2 "gdl: cannot resolve PR base '$base'; local report shown"
    return 1
  fi

  committed="$(git diff "$merge_base...HEAD" --numstat -- "$@" | _gdl_sum_numstat)"
  pr_total="$(
    {
      git diff "$merge_base" --numstat -- "$@"
      _gdl_untracked_numstat "$@"
    } | _gdl_sum_numstat
  )"

  print
  print "PR view ($base merge-base -> working tree)"
  printf '  %-30s %s\n' 'committed (merge-base -> HEAD)' "$committed"
  printf '  %-30s %s\n' 'total (merge-base -> tree)' "$pr_total"
}

swt() {
  if (( $# == 0 )); then
    print -u2 'usage: swt <suffix> [suffix ...]'
    return 2
  fi

  local repo_root parent repo_name suffix branch worktree_path failed=0
  if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    print -u2 'swt: not inside a git repository'
    return 1
  fi

  repo_root="${repo_root:A}"
  parent="${repo_root:h}"
  repo_name="${repo_root:t}"

  git -C "$repo_root" fetch origin main || return

  for suffix in "$@"; do
    if [[ -z "$suffix" ]]; then
      print -u2 'swt: empty suffix'
      failed=1
      continue
    fi

    branch="main-$suffix"
    worktree_path="$parent/$repo_name-$suffix"

    if [[ -e "$worktree_path" ]]; then
      print -u2 "swt: target already exists: $worktree_path"
      failed=1
      continue
    fi

    if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
      git -C "$repo_root" worktree add "$worktree_path" "$branch" || failed=1
    else
      git -C "$repo_root" worktree add -b "$branch" "$worktree_path" origin/main || failed=1
    fi
  done

  return "$failed"
}
