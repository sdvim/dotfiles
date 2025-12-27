#!/usr/bin/env zsh

# General
alias cat="bat"
alias find="fd"
alias grep="rg"
alias ls="eza --icons=always -a"
alias tree="eza -T -L 4 -a --git-ignore"

# Navigation
alias cd="z"

# Config
alias config_reload="source $ZDOTDIR/.zshrc"
alias config_edit="nvim $ZDOTDIR/.zshrc"

# Git
alias ga="git add"
alias gb="git branch"
alias gc="git commit"
alias gca="git commit --amend"
alias gco="git checkout"
alias gd="git diff"
alias gp="git push"
alias gpo="git push origin"
alias gs="git status"
alias gss="git status -s"

alias undo="git reset --soft HEAD~1"
alias wip="git add . && git commit -m 'WIP'"
