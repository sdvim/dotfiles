#!/usr/bin/env zsh
# .zshenv - Environment variables (loaded first, for all shells)

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export HISTFILE="$ZDOTDIR/.zhistory"
export HISTSIZE=10000
export SAVEHIST=10000

export EDITOR="nvim"
export VISUAL="nvim"

export GPG_TTY=$(tty)

# uv
export PATH="/Users/steve/.config/local/bin:$PATH"

# dotfiles scripts
export PATH="$HOME/dotfiles/scripts:$PATH"

# VIP directories for SSH tmux picker
export VIP_DIRS="$HOME/dotfiles:$HOME/Git"

# Source local secrets (not tracked in git)
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
