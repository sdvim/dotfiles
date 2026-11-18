#!/bin/sh
set -eu

repo=${DOTFILES_REPO:-sdvim}
source_dir=${DOTFILES_DIR:-$HOME/Git/dotfiles}

say() { printf '\n==> %s\n' "$*"; }
ask() {
    printf '%s ' "$1" >/dev/tty
    read -r reply </dev/tty
}
pause() { ask "$1 Press Enter to continue."; }

if ! defaults read MobileMeAccounts Accounts 2>/dev/null | grep -q AccountID; then
    say "Not signed in to iCloud."
    open "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings"
    pause "Sign in to iCloud in System Settings (or skip)."
fi

if ! xcode-select -p >/dev/null 2>&1; then
    say "Installing the Xcode command-line tools"
    xcode-select --install
    until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi

if [ ! -x /opt/homebrew/bin/brew ]; then
    say "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi

current=$(scutil --get LocalHostName 2>/dev/null || true)
ask "Name for this Mac [$current]:"
name=${reply:-$current}
if [ "$name" != "$current" ]; then
    say "Renaming this Mac to $name"
    sudo scutil --set ComputerName "$name"
    sudo scutil --set LocalHostName "$name"
    sudo scutil --set HostName "$name.lan"
fi

say "Applying the dotfiles"
chezmoi init --apply --source "$source_dir" "$repo"
git -C "$source_dir" config core.hooksPath .githooks
say "Done."
