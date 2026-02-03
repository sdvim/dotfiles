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

export PATH="$HOME/.local/bin/:$PATH"

# uv
export PATH="$HOME/.config/local/bin:$PATH"

# dotfiles scripts
export PATH="$HOME/dotfiles/scripts:$PATH"

# VIP directories for SSH tmux picker
export VIP_DIRS="$HOME/dotfiles:$HOME/Git"

# Obsidian log vault
export OBSIDIAN_LOG="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/log"

# Pull Request + Reset: creates PR from last session, resets branch, starts fresh
prr() {
    # Run /pr using the previous session's context
    claude -c -p "/pr"

    # Determine target branch based on current directory
    local target_branch="main"
    local dir="${PWD##*/}"
    if [[ "$dir" =~ -aaa$ ]]; then
        target_branch="main-aaa"
    elif [[ "$dir" =~ -bbb$ ]]; then
        target_branch="main-bbb"
    elif [[ "$dir" =~ -ccc$ ]]; then
        target_branch="main-ccc"
    elif [[ "$dir" =~ -ddd$ ]]; then
        target_branch="main-ddd"
    fi

    # Reset branch to origin/<target>
    git fetch origin
    git reset --hard "origin/$target_branch"

    # Start fresh Claude session
    c
}

# Source local secrets (not tracked in git)
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
