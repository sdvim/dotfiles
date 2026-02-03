#!/usr/bin/env bash
# Converts simple zsh aliases to fish format
# Skips global aliases (-g) and functions

set -euo pipefail

input="$HOME/dotfiles/.config/zsh/aliases.zsh"
output="$HOME/dotfiles/.config/fish/conf.d/aliases.fish"

mkdir -p "$(dirname "$output")"

{
    echo "# Auto-generated from zsh aliases"
    echo "# Run: scripts/generate-fish-aliases.sh"
    echo ""

    while IFS= read -r line; do
        # Skip global aliases (zsh-only)
        if [[ "$line" =~ ^alias\ -g ]]; then
            continue
        fi

        # Match simple alias: alias name="value" or alias name='value'
        if [[ "$line" =~ ^alias\ ([a-zA-Z0-9_-]+)=\"(.*)\"$ ]]; then
            name="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            echo "alias $name \"$value\""
        elif [[ "$line" =~ ^alias\ ([a-zA-Z0-9_-]+)=\'(.*)\'$ ]]; then
            name="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            echo "alias $name \"$value\""
        fi
    done < "$input"
} > "$output"

echo "Generated: $output"
