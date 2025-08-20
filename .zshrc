# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# completion using vim keys
bindkey '^k' history-search-backward
bindkey '^j' history-search-forward

# Source zsh plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Alias / keyboard shortcuts
# Only set aliases in interactive shells (not for Claude)
if [[ $- == *i* ]] && [[ -z "$CLAUDE_CODE" ]]; then
    alias cd="z"
    alias ls="eza --icons=always"
    alias tree='eza -T -L 4 -a'
    alias ai="aichat"
    alias o='claude -p "$(cat "/Users/steve/Library/Mobile Documents/iCloud~md~obsidian/Documents/core/$(date +%Y-%m).md")"'
    alias find="fd"
    alias grep="rg"
fi

# Exports
export BAT_THEME="ansi"

# Setup zoxide and starship
eval "$(zoxide init zsh)"

# Conditional Starship config based on terminal
if [[ "$TERM_PROGRAM" == "Terminus" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-unicode.toml"
else
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi

eval "$(starship init zsh)"

export PATH="/Users/steve/.local/state/fnm_multishells/1341_1752387704520/bin":$PATH
export FNM_MULTISHELL_PATH="/Users/steve/.local/state/fnm_multishells/1341_1752387704520"
export FNM_VERSION_FILE_STRATEGY="local"
export FNM_DIR="/Users/steve/.local/share/fnm"
export FNM_LOGLEVEL="info"
export FNM_NODE_DIST_MIRROR="https://nodejs.org/dist"
export FNM_COREPACK_ENABLED="false"
export FNM_RESOLVE_ENGINES="true"
export FNM_ARCH="arm64"
rehash

# Claude tmux integration
source ~/.bashrc_claude_tmux

# Auto-attach tmux for SSH sessions
if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] || [[ "$SSH_CONNECTION" ]]; then
    if command -v tmux &> /dev/null && [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
        # Try to attach to existing session, or create new one
        tmux -u attach-session -t home 2>/dev/null || tmux -u new-session -s home
    fi
fi

export GOPATH="$HOME/go"; export GOROOT="$HOME/.go"; export PATH="$GOPATH/bin:$PATH"; # g-install: do NOT edit, see https://github.com/stefanmaric/g

# Change to dotfiles directory on login
if [[ $- == *i* ]] && [[ -z "$CLAUDE_CODE" ]]; then
    if [[ "$PWD" == "$HOME" ]] && [[ -d "$HOME/dotfiles" ]]; then
        cd "$HOME/dotfiles"
    fi
fi

# Auto-apply dotfiles on login with change detection
if [[ $- == *i* ]] && [[ -z "$CLAUDE_CODE" ]]; then
    if [[ -d "$HOME/dotfiles" ]]; then
        dotfiles_output=$(cd "$HOME/dotfiles" && stow . 2>&1)
        if [[ -n "$dotfiles_output" ]]; then
            echo "Dotfiles updated:"
            echo "$dotfiles_output" | grep -E "(LINK|UNLINK)" | sed 's/^/  /'
        fi
    fi
fi
