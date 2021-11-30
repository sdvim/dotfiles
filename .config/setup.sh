#!/usr/bin/env bash

# Install homebrew
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Use "sensible hacker defaults for macOS"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/mathiasbynens/dotfiles/main/.macos)"

# Set iterm2 preferences folder to read from .config
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "~/.config/iterm2"

# Make a symlink for Amethyst settings
ln -s ~/.config/amethyst/com.amethyst.Amethyst.plist ~/Library/Preferences/com.amethyst.Amethyst.plist

# Make a symlink for VS Code settings
ln -s ~/.config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# Install oh-my-zsh plugins
git clone git://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone git://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

#
# Overrides for sensible hacker defaults
# --------------------------------------

# Hide Spotlight tray-icon
sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search

