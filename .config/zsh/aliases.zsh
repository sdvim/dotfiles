#!/usr/bin/env zsh

# General
alias cat="bat"
alias find="fd"
alias grep="rg"
alias ls="eza --icons=always -a"
alias tree="eza -T -L 4 -a --git-ignore --color=always"
head() { bat --line-range :${2:-15} "$1"; }

# Global aliases (can be used anywhere in a command)

# Redirect to /dev/null
# example: echo test > DN
alias -g DN='/dev/null'

# Suppress stderr
# example: cmd NE
alias -g NE='2>/dev/null'

# Suppress all output
# example: cmd NUL
alias -g NUL='>/dev/null 2>&1'

# Pipe to grep
# example: ls G pattern
alias -g G='| grep'

# Pipe to less
# example: cat file L
alias -g L='| less'

# Pipe to head
# example: ps aux H
alias -g H='| head'

# Pipe to tail
# example: tail -f log T
alias -g T='| tail'

# Count lines
# example: ls C
alias -g C='| wc -l'

# Navigation
alias cd="z"

# Config
alias restow="cd ~/dotfiles && stow -R ."

edit() {
  local editor="${EDITOR:-nvim}"
  case "$1" in
    aliases) $editor "$ZDOTDIR/aliases.zsh" ;;
    config) $editor "$ZDOTDIR/.zshrc" ;;
    *) $editor "$@" ;;
  esac
}

# Git
alias g="git"
alias ga="git add ."
alias gb="git branch"
alias gc="git commit"
alias gca="git commit --amend"
alias gco="git checkout"
alias gcom="git checkout main"
gd() { git status -s && echo && git diff "$@"; }
alias gf="git fetch --prune"
alias gl="git log --pretty=format:'%C(yellow)%h%C(reset)%C(red)%d%C(reset)%n%C(cyan)%ar%C(reset) %C(green)<%an>%C(reset)%n%s%n' --no-merges --max-count 5"
alias gp="git pull"
alias gpush="git push"
alias gpo="git pull origin"
alias gpom="git pull origin main"
alias gr="git rebase"
alias grom="git rebase origin/main"
alias gs="git status -s"

alias undo="git reset HEAD~1"
alias wip="git add . && git commit -m 'WIP'"

# Claude
c() {
  local session_name="${PWD##*/}"

  if [[ -n "$TMUX" ]]; then
    claude --dangerously-skip-permissions --fork-session "$@"
  else
    if tmux has-session -t "$session_name" 2>/dev/null; then
      tmux attach -d -t "$session_name"
    else
      tmux new-session -s "$session_name" "claude --dangerously-skip-permissions --fork-session $*; exec zsh"
    fi
  fi
}
alias cr="tmux rename-session"
summ() { summarize "$1" --cli claude --format md --prompt "tldr outline"; }
