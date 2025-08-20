# Default to micro
set -Ux EDITOR micro
set -Ux VISUAL micro

# Detect if running inside VS Code terminal
if set -q VSCODE_GIT_ASKPASS_NODE || string match -q "*Microsoft*" $TERM_PROGRAM
    set -Ux EDITOR "code --wait"
    set -Ux VISUAL "code --wait"
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Obsidian vault path
set -U CORE "/Users/steve/Library/Mobile Documents/iCloud~md~obsidian/Documents/core"
set -U YEARMONTH (date +%Y-%m)
set -U NOTE "$CORE/$YEARMONTH.md"

# Starship init
starship init fish | source

# Zoxide init; replace cd with z
zoxide init --cmd cd fish | source

# Bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# venv
set VIRTUAL_ENV "/Users/steve/.local/lib/python"
