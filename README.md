# dotfiles

Chezmoi-managed macOS dotfiles for `sdvim`.

## Bootstrap

On a fresh Mac:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
chezmoi init --apply sdvim/dotfiles --branch chezmoi-reboot
```

## Local validation

```sh
chezmoi diff --source ~/Git/dotfiles
chezmoi status --source ~/Git/dotfiles
chezmoi apply --source ~/Git/dotfiles --dry-run --verbose
chezmoi doctor --source ~/Git/dotfiles
brew bundle check --file ~/Git/dotfiles/Brewfile
```

This branch replaces the old Stow layout with a clean chezmoi source tree. It is intended to be validated on the current Nix-managed machine with dry-run only, then applied on a fresh macOS install.
