#!/usr/bin/env zsh

# General
alias cat="bat"
alias find="fd"
alias grep="rg"
alias ls="eza --icons=always -a"
alias tree="eza -T -L 4 -a --git-ignore --color=always"

# Navigation
alias cd="z"

# Config
alias alias_edit="nvim $ZDOTDIR/aliases.zsh"
alias config_reload="source $ZDOTDIR/.zshrc && aerospace reload-config && echo 'Reloaded: zsh, aerospace'"
alias config_edit="nvim $ZDOTDIR/.zshrc"

# Git
alias ga="git add ."
alias gb="git branch"
alias gc="git commit"
alias gca="git commit --amend"
alias gco="git checkout"
alias gd="git diff"
alias gl="git log --pretty=format:'%C(yellow)%h%C(reset)%C(red)%d%C(reset)%n%C(cyan)%ar%C(reset) %C(green)<%an>%C(reset)%n%s%n' --no-merges --max-count 5"
alias gp="git push"
alias gpo="git pull origin"
alias gpom="git pull origin main"
alias gr="git rebase"
alias grm="git rebase origin/main"
alias gs="git status -s"

alias undo="git reset HEAD~1"
alias wip="git add . && git commit -m 'WIP'"

# Music
alias loop='pymusiclooper play --path "$(fd -e mp3 -e wav -e ogg -e flac | fzf)"'

# Claude
alias c="claude --dangerously-skip-permissions"
