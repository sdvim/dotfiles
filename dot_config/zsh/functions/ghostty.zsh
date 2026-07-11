_ghostty_source_dir() {
  local source_dir="${CHEZMOI_SOURCE_DIR:-}"
  if [[ -z "$source_dir" ]]; then
    source_dir="$(chezmoi source-path 2>/dev/null || print -r -- "$HOME/Git/dotfiles")"
  fi

  print -r -- "$source_dir"
}

_apply_ghostty_config() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    print -u2 'apply-ghostty-config: chezmoi was not found'
    return 127
  fi

  chezmoi apply --source "$(_ghostty_source_dir)" --parent-dirs -- "$HOME/.config/ghostty/config.ghostty"
}

function reload-ghostty {
  if ! command -v ghostty >/dev/null 2>&1; then
    print -u2 'reload-ghostty: ghostty was not found'
    return 0
  fi

  ghostty +validate-config --config-file="$HOME/.config/ghostty/config.ghostty" || return

  if [[ "$(osascript -e 'tell application "System Events" to exists (first process whose bundle identifier is "com.mitchellh.ghostty")' 2>/dev/null)" != "true" ]]; then
    return 0
  fi

  if ! command -v hs >/dev/null 2>&1; then
    print -u2 'reload-ghostty: hs was not found'
    return 127
  fi

  hs -A -c 'return reloadGhosttyConfig()' || {
    print -u2 'reload-ghostty: failed to trigger Ghostty config reload'
    return 1
  }
}

function edit-ghostty {
  if ! command -v nvim >/dev/null 2>&1; then
    print -u2 'edit-ghostty: nvim was not found'
    return 127
  fi

  local config="$(_ghostty_source_dir)/dot_config/ghostty/config.ghostty"
  if [[ ! -e "$config" ]]; then
    print -u2 "edit-ghostty: config not found: $config"
    return 1
  fi

  local ghostty_nvim_site='/Applications/Ghostty.app/Contents/Resources/nvim/site'
  local -a nvim_args=()
  if [[ -d "$ghostty_nvim_site" ]]; then
    nvim_args+=(--cmd "set runtimepath^=$ghostty_nvim_site")
    nvim_args+=(+"setlocal filetype=ghostty")
  fi

  nvim "${nvim_args[@]}" +"autocmd BufWritePost <buffer> silent !zsh -ic '_apply_ghostty_config && reload-ghostty'" "$config"
}
