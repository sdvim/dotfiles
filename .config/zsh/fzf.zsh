#!/usr/bin/env zsh

# fzf widgets for interactive shell

# History search (Ctrl+R)
fzf-history() {
  local selected=$(fc -ln 1 | fzf --tac --no-sort --query="$LBUFFER")
  if [[ -n "$selected" ]]; then
    LBUFFER="$selected"
  fi
  zle redisplay
}
zle -N fzf-history
bindkey '^R' fzf-history

# Change directory (Alt+C)
fzf-cd() {
  local dir=$(find . -type d -not -path '*/\.*' 2>/dev/null | fzf --preview 'ls -la {}')
  if [[ -n "$dir" ]]; then
    cd "$dir"
    zle accept-line
  else
    zle redisplay
  fi
}
zle -N fzf-cd
bindkey '^[c' fzf-cd

# Insert file path (Ctrl+T)
fzf-file() {
  local file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}')
  if [[ -n "$file" ]]; then
    LBUFFER+="$file"
  fi
  zle redisplay
}
zle -N fzf-file
bindkey '^T' fzf-file

# Git branch checkout (Ctrl+G Ctrl+B)
fzf-git-branch() {
  git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch=$(git branch -a --color=always | grep -v '/HEAD\s' | fzf --ansi --preview 'git log --oneline --graph --color=always $(echo {} | sed "s/.* //" | sed "s#remotes/##")' | sed 's/.* //' | sed 's#remotes/[^/]*/##')
  if [[ -n "$branch" ]]; then
    LBUFFER="git checkout $branch"
    zle accept-line
  else
    zle redisplay
  fi
}
zle -N fzf-git-branch
bindkey '^g^b' fzf-git-branch

# Kill process (Ctrl+G Ctrl+K)
fzf-kill() {
  local pid=$(ps -ef | sed 1d | fzf --multi --preview 'echo {}' | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    LBUFFER="kill -9 $pid"
    zle accept-line
  else
    zle redisplay
  fi
}
zle -N fzf-kill
bindkey '^g^k' fzf-kill
