#!/usr/bin/env zsh

bindkey -e

# Window title: show "pwd: command" when running, "pwd" at prompt
precmd() { print -Pn "\e]0;%~\a" }
preexec() { print -Pn "\e]0;%~: $1\a" }

fpath+=$ZDOTDIR/completions

autoload -U compinit
compinit -i

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd --shell zsh)"

setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_VERIFY

source $ZDOTDIR/ssh-tmux.zsh
source $ZDOTDIR/aliases.zsh
source $ZDOTDIR/completions.zsh
source $ZDOTDIR/fzf.zsh
