_reload_pending_targets() {
  local line target

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "${line[2]}" == " " ]] && continue

    target="${line[4,-1]}"
    [[ -n "$target" ]] && print -r -- "$target"
  done
}

function reload {
  if ! command -v chezmoi >/dev/null 2>&1; then
    print -u2 'reload: chezmoi was not found'
    return 127
  fi

  local source_dir="${CHEZMOI_SOURCE_DIR:-}"
  if [[ -z "$source_dir" ]]; then
    source_dir="$(chezmoi source-path 2>/dev/null || print -r -- "$HOME/Git/dotfiles")"
  fi

  local status_output
  status_output="$(chezmoi status --source "$source_dir" --path-style relative "$@" 2>/dev/null)"

  local -a changed_targets
  changed_targets=()

  if [[ -n "$status_output" ]]; then
    local pending_targets
    pending_targets="$(print -r -- "$status_output" | _reload_pending_targets)"
    [[ -n "$pending_targets" ]] && changed_targets=("${(@f)pending_targets}")
  fi

  chezmoi apply --source "$source_dir" --parent-dirs "$@" || return

  local reload_shell=0
  local reload_tmux=0
  local reload_ghostty=0
  local reload_aerospace=0
  local target

  for target in "${changed_targets[@]}"; do
    case "$target" in
      .zprofile|.zshrc|.config/zsh|.config/zsh/*)
        reload_shell=1
        ;;
      .tmux.conf)
        reload_tmux=1
        ;;
      .config/ghostty|.config/ghostty/*)
        reload_ghostty=1
        ;;
      .config/aerospace|.config/aerospace/*)
        reload_aerospace=1
        ;;
    esac
  done

  if (( reload_shell )); then
    [[ -r "$HOME/.zprofile" ]] && source "$HOME/.zprofile"
    [[ -r "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
  fi

  if (( reload_tmux )) && command -v tmux >/dev/null 2>&1 && [[ -r "$HOME/.tmux.conf" ]]; then
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
  fi

  local reload_failed=0

  if (( reload_ghostty )); then
    reload-ghostty || reload_failed=1
  fi

  if (( reload_aerospace )); then
    reload-aerospace || reload_failed=1
  fi

  return "$reload_failed"
}
