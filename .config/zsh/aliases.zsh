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
    if tmux has-session -t "=$session_name" 2>/dev/null; then
      tmux attach -d -t "=$session_name" \; set status off
    else
      tmux new-session -s "$session_name" "claude --dangerously-skip-permissions --fork-session $*" \; set status off
    fi
  fi
}
alias cr="tmux rename-session"
alias commit='claude -p "/commit"'
summ() { summarize "$1" --cli claude --format md --prompt "tldr outline"; }

# Obsidian log helpers
_log_append() {
  local header="$1" item="$2"
  local file="$OBSIDIAN_LOG/$(date +%Y-%m).md"
  sed -i '' "/^## $header$/a\\
$item
" "$file"
}

todo()   { _log_append "TODO"    "- [ ] $*"; }
want()   { _log_append "Want"    "- [ ] $*"; }
errand() { _log_append "Errands" "- [ ] $*"; }
chore()  { _log_append "Chores"  "- [ ] $*"; }
idea()   { _log_append "Ideas"   "- $*"; }

# Ghostty theme picker
_map_ghostty_to_vhs() {
  local ghostty_theme="$1"
  case "$ghostty_theme" in
    "GitHub Dark High Contrast") echo "GitHub Dark" ;;
    "Nord") echo "nord" ;;
    "TokyoNight Night") echo "tokyonight" ;;
    "TokyoNight Storm") echo "tokyonight-storm" ;;
    "Gruvbox Dark") echo "GruvboxDark" ;;
    "Gruvbox Dark Hard") echo "GruvboxDarkHard" ;;
    *) echo "$ghostty_theme" ;;
  esac
}

theme-picker() {
  local config="$HOME/.config/ghostty/config"
  local tape="$HOME/dotfiles/demo.tape"
  local original=$(grep "^theme = " "$config" | cut -d' ' -f3-)

  local selected=$(ghostty +list-themes | sed 's/ (resources)//' | fzf \
    --preview-window=hidden \
    --bind="focus:execute-silent(
      sed -i '' 's/^theme = .*/theme = {}/' $config
      osascript -e 'tell app \"System Events\" to keystroke \"5\" using shift down' 2>/dev/null
    )" \
    --header="↑/↓ to browse (live preview), Enter to confirm, Esc to cancel"
  )

  if [[ -n "$selected" ]]; then
    sed -i '' "s/^theme = .*/theme = $selected/" "$config"
    local vhs_theme=$(_map_ghostty_to_vhs "$selected")
    sed -i '' "s/^Set Theme .*/Set Theme \"$vhs_theme\"/" "$tape"
    echo "Theme set: $selected (VHS: $vhs_theme)"
  else
    sed -i '' "s/^theme = .*/theme = $original/" "$config"
    osascript -e 'tell app "System Events" to keystroke "5" using shift down' 2>/dev/null
    echo "Cancelled, restored: $original"
  fi
}
