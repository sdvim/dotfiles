#!/usr/bin/env zsh

generate_completions() {
    local comp_dir="$ZDOTDIR/completions"
    mkdir -p "$comp_dir"

    echo "Generating completions in $comp_dir..."

    # fzf
    if command -v fzf &>/dev/null; then
        fzf --zsh > "$comp_dir/_fzf"
        echo "  Generated _fzf"
    fi

    # GitHub CLI
    if command -v gh &>/dev/null; then
        gh completion -s zsh > "$comp_dir/_gh"
        echo "  Generated _gh"
    fi

    # fnm (Node version manager)
    if command -v fnm &>/dev/null; then
        fnm completions --shell zsh > "$comp_dir/_fnm"
        echo "  Generated _fnm"
    fi

    # Docker
    if command -v docker &>/dev/null; then
        docker completion zsh > "$comp_dir/_docker" 2>/dev/null
        echo "  Generated _docker"
    fi

    # Bun
    if command -v bun &>/dev/null; then
        bun completions > "$comp_dir/_bun" 2>/dev/null
        echo "  Generated _bun"
    fi

    echo "Done. Run 'exec zsh' to reload completions."
}
