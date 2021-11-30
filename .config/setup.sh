#!/usr/bin/env bash

# Install homebrew
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Use "sensible hacker defaults for macOS"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/mathiasbynens/dotfiles/main/.macos)"

# Set iterm2 preferences folder to read from .config
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "~/.config/iterm2"

#
# Overrides for sensible hacker defaults
# --------------------------------------

# Hide Spotlight tray-icon
sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search

