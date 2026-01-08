#!/bin/bash

# macOS Setup Script

# Clear all dock items
defaults write com.apple.dock persistent-apps -array

# Set dock auto-hide delay to 20 seconds
defaults write com.apple.dock autohide-delay -float 20

# Apply dock changes
killall Dock

echo "macOS setup complete"
