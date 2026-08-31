# Dotfiles

## Bootstrap

Homebrew is the only manual prerequisite. On a fresh Mac:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
chezmoi init \
  --source "$HOME/Git/dotfiles" \
  --apply \
  --verbose \
  "https://github.com/$GITHUB_USERNAME/dotfiles.git"
```

Chezmoi stores the repository in `~/Git/dotfiles`, installs the packages in
`Brewfile`, and then imports the Git signing key from 1Password. Sign in to
1Password or enable its CLI integration before the key import runs. Homebrew
may request an administrator password while installing system-level casks such
as Karabiner-Elements.

## Keyboard Automation

- Karabiner handles low-level keyboard remaps: Caps Lock as Control, external keyboard Command/Option swapping, app-switcher suppression, and small app-scoped key remaps.

## Removed Hammerspoon Automation

- `cmd+1` through `cmd+9` no longer focus numbered Ghostty panes. Ghostty's native behavior is restored: `cmd+1` through `cmd+8` select numbered tabs, and `cmd+9` selects the last tab.
- `cmd+r` no longer detects the focused Ghostty terminal's working directory and opens its GitHub pull request. Run `open-github-pr` from a repository directory until it is bound through tmux, herdr, or another terminal workflow.
- `edit-ghostty` and `reload-ghostty` still validate, apply, and reload the Ghostty config without Hammerspoon.
