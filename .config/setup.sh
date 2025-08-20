#!/bin/bash

# 1. Add Fish shell to allowed shells and set it as default
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

# 2. Remove all persistent Dock apps (except downloads stack)
defaults write com.apple.dock persistent-apps -array

# 3. Set Dock to autohide with 3s delay and 0s reveal time
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 3
defaults write com.apple.dock autohide-time-modifier -float 0

# Don’t animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false


# 4. Restart Dock to apply changes
killall Dock

# 5. Remap Caps Lock to Control (session only, run again on reboot)
hidutil property --set '{"UserKeyMapping":[
  {
    "HIDKeyboardModifierMappingSrc": 0x700000039,
    "HIDKeyboardModifierMappingDst": 0x7000000E0
  }
]}'

# 6. Create LaunchAgent to persist remapping across reboots
mkdir -p ~/Library/LaunchAgents
cat <<EOF > ~/Library/LaunchAgents/com.user.remap_capslock.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.remap_capslock</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

# 7. Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.remap_capslock.plist

# Disable login message
touch ~/.hushlogin

# Install fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Symlink dotfiles to VS Code
rm -r ~/Library/Application\ Support/Code/User
ln -s ~/.config/code/user ~/Library/Application\ Support/Code/User

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Set home as the default location for new Finder windows
# For other paths, use `PfLo` and `file:///full/path/here/`
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true