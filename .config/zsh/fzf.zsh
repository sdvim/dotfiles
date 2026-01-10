#!/usr/bin/env zsh

# Reload config (F5)
config-reload() {
  source $ZDOTDIR/.zshrc && aerospace reload-config && echo 'Reloaded: zsh, aerospace'
  zle redisplay
}
zle -N config-reload
bindkey '\e[15~' config-reload

# fzf widgets for interactive shell

# History search (Ctrl+R)
fzf-history() {
  local selected=$(cat "$HISTFILE" | sed 's/^: [0-9]*:[0-9]*;//' | fzf --tac --no-sort --query="$LBUFFER")
  if [[ -n "$selected" ]]; then
    LBUFFER="$selected"
  fi
  zle redisplay
}
zle -N fzf-history
bindkey '^R' fzf-history

# Change directory (Alt+C)
fzf-cd() {
  local last_word="${LBUFFER##* }"
  last_word="${last_word/#\~/$HOME}"

  local dir
  if [[ -d "$last_word" ]]; then
    dir=$(fd --type d --hidden --exclude .git . "$last_word" 2>/dev/null | sed "s|$HOME|~|g" | fzf --preview 'eza -la --icons=always {} 2>/dev/null || ls -la {}')
  else
    dir=$({ zoxide query -l 2>/dev/null; fd --type d --hidden --exclude .git 2>/dev/null; } | awk '!seen[$0]++' | sed "s|$HOME|~|g" | fzf --preview 'eza -la --icons=always {} 2>/dev/null || ls -la {}')
  fi

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
  local file=$({ fd --type f --hidden --exclude .git 2>/dev/null || find . -type f 2>/dev/null; } | sed "s|$HOME|~|g" | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}')
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
  local pid=$(ps -ef | sed 1d | fzf --multi --preview 'ps -p $(echo {} | awk "{print \$2}") -o pid,ppid,user,%cpu,%mem,start,time,command 2>/dev/null' | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    LBUFFER="kill -9 $pid"
    zle accept-line
  else
    zle redisplay
  fi
}
zle -N fzf-kill
bindkey '^g^k' fzf-kill
