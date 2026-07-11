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

open-github-pr-widget() {
  emulate -L zsh

  zle -I
  if ! open-github-pr; then
    zle -M 'open-github-pr failed'
    return 1
  fi

  zle reset-prompt
}
