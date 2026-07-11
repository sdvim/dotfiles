if command -v eza >/dev/null 2>&1; then
  alias tree='eza -T -L 4 -a --git-ignore --color=always'
fi

if command -v zoxide >/dev/null 2>&1; then
  if ! whence -w z >/dev/null 2>&1; then
    eval "$(zoxide init zsh --hook none)"
  fi

  alias zdf='z dotfiles'
  alias za='z aaa'
  alias zb='z bbb'
  alias zc='z ccc'
  alias zd='z ddd'
fi
