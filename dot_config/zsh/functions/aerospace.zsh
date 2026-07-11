_aerospace_source_dir() {
  local source_dir="${CHEZMOI_SOURCE_DIR:-}"
  if [[ -z "$source_dir" ]]; then
    source_dir="$(chezmoi source-path 2>/dev/null || print -r -- "$HOME/Git/dotfiles")"
  fi

  print -r -- "$source_dir"
}

_apply_aerospace_config() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    print -u2 'apply-aerospace-config: chezmoi was not found'
    return 127
  fi

  chezmoi apply --source "$(_aerospace_source_dir)" --parent-dirs -- "$HOME/.config/aerospace/aerospace.toml"
}

function reload-aerospace {
  if ! command -v aerospace >/dev/null 2>&1; then
    print -u2 'reload-aerospace: aerospace was not found'
    return 0
  fi

  aerospace reload-config --dry-run --warnings-as-errors && aerospace reload-config
}

function edit-aerospace {
  if ! command -v nvim >/dev/null 2>&1; then
    print -u2 'edit-aerospace: nvim was not found'
    return 127
  fi

  local config="$(_aerospace_source_dir)/dot_config/aerospace/aerospace.toml"
  if [[ ! -e "$config" ]]; then
    print -u2 "edit-aerospace: config not found: $config"
    return 1
  fi

  local taplo_lsp='if vim.fn.executable("taplo") == 1 then local client_id = vim.lsp.start({ name = "taplo", cmd = { "taplo", "lsp", "stdio" }, root_dir = vim.fs.root(0, { ".git" }) or vim.fn.getcwd() }); if client_id and vim.lsp.completion then vim.lsp.completion.enable(true, client_id, 0, { autotrigger = true }) end end'

  nvim +"setlocal filetype=toml" +"lua $taplo_lsp" +"autocmd BufWritePost <buffer> silent !zsh -ic '_apply_aerospace_config && reload-aerospace'" "$config"
}
